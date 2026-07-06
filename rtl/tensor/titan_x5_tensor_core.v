// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Module: titan_x5_tensor_core
 * Description: 4x4 Systolic Matrix Multiply-Accumulate Array.
 * Supports INT8 and FP16 modes.
 */
module titan_x5_tensor_core #(
    parameter DATA_W = 16,
    parameter ACC_W = 32
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       en,
    input  wire                       clear,
    input  wire                       mode_fp16, // 0 = INT8, 1 = FP16
    input wire [4*DATA_W-1:0] a_in, // left input (4 elements)
    input wire [4*DATA_W-1:0] b_in, // top input (4 elements)
    
    // wmma datapath from pipeline
    input  wire                       wmma_valid,
    input wire [31:0] wmma_a,
    input wire [31:0] wmma_b,

    output wire [16*ACC_W-1:0] c_out // 4x4 Output
);

    // internal wires for systolic array connections
    // a flows right (col index reaches 4), b flows down (row index reaches 4)
    wire [DATA_W-1:0] a_wire [0:3][0:4];
    wire [DATA_W-1:0] b_wire [0:4][0:3];
    reg  [ACC_W-1:0]  acc_reg [0:3][0:3];

    // assign inputs
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : assign_inputs
            assign a_wire[i][0] = a_in[(i*DATA_W) +: DATA_W];
            assign b_wire[0][i] = b_in[(i*DATA_W) +: DATA_W];
        end
    endgenerate

    // 4x4 MAC array
    generate
        for (i = 0; i < 4; i = i + 1) begin : row
            for (j = 0; j < 4; j = j + 1) begin : col
                // pipeline registers for a and b
                reg [DATA_W-1:0] a_reg;
                reg [DATA_W-1:0] b_reg;

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        a_reg <= {DATA_W{1'b0}};
                        b_reg <= {DATA_W{1'b0}};
                    end else if (en) begin
                        a_reg <= a_wire[i][j];
                        b_reg <= b_wire[i][j];
                    end
                end

                assign a_wire[i][j+1] = a_reg;
                assign b_wire[i+1][j] = b_reg;

                // mac operation
                wire signed [15:0] a_int8 = $signed(a_wire[i][j][7:0]);
                wire signed [15:0] b_int8 = $signed(b_wire[i][j][7:0]);
                wire signed [31:0] prod_int8 = a_int8 * b_int8;

                // real fp16 multiplier instantiated for fp16 mac accuracy
                wire [15:0] prod_fp16_real;
                titan_x5_fp16_mul u_fp16_mul (
                    .a(a_wire[i][j]),
                    .b(b_wire[i][j]),
                    .result(prod_fp16_real)
                );

                wire [31:0] fp32_prod_converted = (prod_fp16_real == 16'b0) ? 32'b0 : 
                                                  {prod_fp16_real[15], prod_fp16_real[14:10] + 8'd127 - 8'd15, prod_fp16_real[9:0], 13'b0};

                // throughput optimization: pipeline product calculation
                reg [31:0] prod_pipeline_reg;
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        prod_pipeline_reg <= 32'd0;
                    end else if (en) begin
                        prod_pipeline_reg <= mode_fp16 ? fp32_prod_converted : prod_int8;
                    end
                end

                // combinational IEEE-754 adder (same-cycle accumulate);
                // the previous instance referenced a nonexistent `fp32_add`
                wire [31:0] next_acc_fp32;
                titan_x5_fp32_add_comb u_fp32_add (
                    .a(acc_reg[i][j]),
                    .b(prod_pipeline_reg),
                    .result(next_acc_fp32)
                );

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        acc_reg[i][j] <= {ACC_W{1'b0}};
                    end else if (clear) begin
                        acc_reg[i][j] <= {ACC_W{1'b0}};
                    end else if (en) begin
                        // accumulate from pipelined register
                        acc_reg[i][j] <= mode_fp16 ? next_acc_fp32 : (acc_reg[i][j] + prod_pipeline_reg);
                    end
                end
                
                assign c_out[((i*4+j)*ACC_W) +: ACC_W] = acc_reg[i][j];
            end
        end
    endgenerate

endmodule
