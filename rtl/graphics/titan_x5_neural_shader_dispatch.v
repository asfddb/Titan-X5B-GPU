`timescale 1ns / 1ps

/*
 * Titan X5-B: Neural Shader Dispatcher
 * 
 * This module interfaces the Graphics Pipeline (SM Shaders) directly to the 
 * 5th-Gen Tensor Cores. It mimics the DirectX Cooperative Vectors API, allowing 
 * traditional math shaders to offload lighting calculations to trained Neural 
 * Networks via Matrix-Vector Inference.
 */

module titan_x5_neural_shader_dispatch (
    input  wire         clk,
    input  wire         rst_n,
    
    // interface from shader execution (sm)
    input  wire         i_shader_valid,
    input wire [31:0] i_material_id, // which neural material to invoke
    input wire [127:0] i_spatial_vector, // (x, y, z) normals, incoming light vectors
    output wire         o_shader_ready,
    
    // dispatch to tensor cores (transformer engine 2.0)
    output reg          o_tensor_req,
    output reg [31:0] o_tensor_opcode, // e.g., NVFP4_MMA
    output reg [511:0] o_tensor_payload, // packed parameters for inference
    input  wire         i_tensor_ack,
    
    // result from tensor cores
    input  wire         i_tensor_done,
    input wire [63:0] i_tensor_result, // output inferred pixel color (fp16 rgb)
    
    // interface back to graphics pipeline (rop/tmu)
    output reg          o_pixel_valid,
    output reg [63:0] o_pixel_color
);

    // neural shading state machine
    localparam IDLE       = 2'd0;
    localparam DISPATCH   = 2'd1;
    localparam WAIT_INFER = 2'd2;

    reg [1:0] state, next_state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (i_shader_valid) next_state = DISPATCH;
            end
            DISPATCH: begin
                if (i_tensor_ack) next_state = WAIT_INFER;
            end
            WAIT_INFER: begin
                if (i_tensor_done) next_state = IDLE;
            end
        endcase
    end

    // dispatch logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            o_tensor_req <= 0;
            o_pixel_valid <= 0;
        end else begin
            o_tensor_req <= (state == DISPATCH);
            o_pixel_valid <= (state == WAIT_INFER && i_tensor_done);
            
            if (state == IDLE && i_shader_valid) begin
                o_tensor_opcode <= 32'h0000_0004; // request fp4 inference
                o_tensor_payload <= {352'b0, i_material_id, i_spatial_vector};
            end
            
            if (state == WAIT_INFER && i_tensor_done) begin
                o_pixel_color <= i_tensor_result; // the neural net "hallucinated" the lighting
            end
        end
    end

    assign o_shader_ready = (state == IDLE);

endmodule
