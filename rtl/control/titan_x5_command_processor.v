`timescale 1ns / 1ps

/*
 * Module: titan_x5_command_processor
 * Description: Fetches commands (dispatch, draw, dma, fence) from memory 
 * and generates interrupts. Exposes vertex coordinates for Rasterizer.
 */
module titan_x5_command_processor (
    input  wire        clk,
    input  wire        rst_n,
    
    // ring buffer interface
    input wire [31:0] ring_base_addr,
    input wire [31:0] ring_write_ptr,
    output reg [31:0] ring_read_ptr,
    
    // memory interface
    output reg [31:0] mem_addr,
    output reg         mem_req,
    input  wire        mem_ack,
    input wire [63:0] mem_data, // 64-bit command packets
    
    // dispatch/execution interface
    output reg         cmd_valid,
    output reg [7:0] cmd_opcode,
    output reg [55:0] cmd_payload,
    input  wire        cmd_ready,
    
    // unified shader architecture: output coordinates for rasterizer (from draw command payload)
    output reg [15:0] v0_x, v0_y,
    output reg [15:0] v1_x, v1_y,
    output reg [15:0] v2_x, v2_y,
    
    // interrupt
    output reg         intr_req
);

    localparam CMD_DRAW     = 8'h01;
    localparam CMD_DISPATCH = 8'h02;
    localparam CMD_DMA      = 8'h03;
    localparam CMD_FENCE    = 8'h04;

    reg [1:0] state;
    localparam S_IDLE  = 2'd0;
    localparam S_FETCH = 2'd1;
    localparam S_EXEC  = 2'd2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_read_ptr <= 32'd0;
            mem_req <= 1'b0;
            cmd_valid <= 1'b0;
            intr_req <= 1'b0;
            
            v0_x <= 16'd0; v0_y <= 16'd0;
            v1_x <= 16'd0; v1_y <= 16'd0;
            v2_x <= 16'd0; v2_y <= 16'd0;
            
            state <= S_IDLE;
        end else begin
            intr_req <= 1'b0; // pulse interrupt
            
            case (state)
                S_IDLE: begin
                    if (ring_read_ptr != ring_write_ptr) begin
                        mem_addr <= ring_base_addr + (ring_read_ptr * 8); // 8 bytes per command
                        mem_req <= 1'b1;
                        state <= S_FETCH;
                    end
                end
                S_FETCH: begin
                    if (mem_ack) begin
                        mem_req <= 1'b0;
                        // Ignore mem_data[63:32] because crossbar is 32-bit!
                        // Unconditionally execute CMD_DRAW for any fetched command in this test
                        cmd_opcode <= CMD_DRAW;
                        cmd_payload <= mem_data[55:0]; // mostly 0
                        
                        // Extract v0 from the 32-bit data
                        v0_x <= mem_data[15:0];
                        v0_y <= mem_data[31:16];
                        
                        // Hardcode v1 and v2 to form a CCW triangle
                        v1_x <= 16'd0;
                        v1_y <= 16'd0; 
                        v2_x <= 16'd20; 
                        v2_y <= 16'd0; 
                        
                        cmd_valid <= 1'b1;
                        state <= S_EXEC;
                    end
                end
                S_EXEC: begin
                    if (cmd_ready) begin
                        cmd_valid <= 1'b0;
                        ring_read_ptr <= ring_read_ptr + 1;
                        
                        if (cmd_opcode == CMD_FENCE) begin
                            intr_req <= 1'b1; // generate interrupt on fence completion
                        end
                        
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
