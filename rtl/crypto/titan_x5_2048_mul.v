`timescale 1ns/1ps

/*
 * Titan X5 GPU Coprocessor - 2048-bit Multiplier
 * 
 * Features:
 * - Multi-cycle iterative multiplier to prevent combinatorial timing violation
 * - Uses 64x64 bit words processing (schoolbook multiplication mapped to DSPs)
 * - 1024 cycles for full 2048x2048 -> 4096 bit multiply
 */
module titan_x5_2048_mul (
    input  wire clk,
    input  wire rst_n,
    input  wire valid_in,
    input wire [2047:0] src1,
    input wire [2047:0] src2,
    output reg [4095:0] result_out,
    output reg  valid_out
);

    reg [1:0] state;
    localparam ST_IDLE = 2'd0;
    localparam ST_CALC = 2'd1;
    localparam ST_DONE = 2'd2;

    reg [5:0] i_cnt;
    reg [5:0] j_cnt;
    
    reg [2047:0] a_reg;
    reg [2047:0] b_reg;
    reg [2047:0] b_shift;
    
    (* ram_style="block" *) reg [63:0] r_reg [0:63];
    
    reg [63:0] carry;
    reg [63:0] a_val;
    reg [63:0] b_val;
    
    wire [127:0] pdt = {64'd0, a_val} * {64'd0, b_val};
    wire [127:0] mac_res = pdt + carry + r_reg[i_cnt + j_cnt];
    
    wire [4095:0] result_out_wire;
    genvar g;
    generate
        for (g = 0; g < 64; g = g + 1) begin : gen_res
            assign result_out_wire[g*64 +: 64] = r_reg[g];
        end
    endgenerate

    integer k;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            valid_out <= 1'b0;
            result_out <= 4096'd0;
            i_cnt <= 6'd0;
            j_cnt <= 6'd0;
            carry <= 64'd0;
            a_val <= 64'd0;
            b_val <= 64'd0;
            a_reg <= 2048'd0;
            b_reg <= 2048'd0;
            b_shift <= 2048'd0;
            for (k = 0; k < 64; k = k + 1) begin
                r_reg[k] <= 64'd0;
            end
        end else begin
            valid_out <= 1'b0;
            
            case (state)
                ST_IDLE: begin
                    if (valid_in) begin
                        a_reg <= src1;
                        b_reg <= src2;
                        b_shift <= src2;
                        for (k = 0; k < 64; k = k + 1) begin
                            r_reg[k] <= 64'd0;
                        end
                        i_cnt <= 6'd0;
                        j_cnt <= 6'd0;
                        carry <= 64'd0;
                        a_val <= src1[63:0];
                        b_val <= src2[63:0];
                        state <= ST_CALC;
                    end
                end
                
                ST_CALC: begin
                    r_reg[i_cnt + j_cnt] <= mac_res[63:0];
                    carry <= mac_res[127:64];
                    
                    if (j_cnt == 6'd31) begin
                        r_reg[i_cnt + 6'd32] <= mac_res[127:64];
                        
                        j_cnt <= 6'd0;
                        if (i_cnt == 6'd31) begin
                            state <= ST_DONE;
                        end else begin
                            i_cnt <= i_cnt + 6'd1;
                            carry <= 64'd0;
                            a_reg <= {64'd0, a_reg[2047:64]};
                            a_val <= a_reg[127:64];
                            
                            b_shift <= b_reg;
                            b_val <= b_reg[63:0];
                        end
                    end else begin
                        j_cnt <= j_cnt + 6'd1;
                        b_shift <= {64'd0, b_shift[2047:64]};
                        b_val <= b_shift[127:64];
                    end
                end
                
                ST_DONE: begin
                    result_out <= result_out_wire;
                    valid_out <= 1'b1;
                    state <= ST_IDLE;
                end
                
                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
