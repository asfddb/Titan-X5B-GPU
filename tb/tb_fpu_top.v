// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

// Verification wrapper: exposes the FP32 adder, FP32 multiplier, FP16
// multiplier and a complete ALU (for end-to-end FP pipeline integration)
// to the cocotb FPU test suite.
module tb_fpu_top (
    input  wire        clk,
    input  wire        rst_n,

    // fp32 adder
    input  wire        add_valid_in,
    input  wire [1:0]  add_rm,
    input  wire [31:0] add_a,
    input  wire [31:0] add_b,
    output wire        add_valid_out,
    output wire [31:0] add_result,
    output wire        add_invalid,
    output wire        add_overflow,
    output wire        add_underflow,
    output wire        add_inexact,

    // fp32 multiplier
    input  wire        mul_valid_in,
    input  wire [1:0]  mul_rm,
    input  wire [31:0] mul_a,
    input  wire [31:0] mul_b,
    output wire        mul_valid_out,
    output wire [31:0] mul_result,
    output wire        mul_invalid,
    output wire        mul_overflow,
    output wire        mul_underflow,
    output wire        mul_inexact,

    // fp16 multiplier (combinational)
    input  wire [15:0] h_a,
    input  wire [15:0] h_b,
    output wire [15:0] h_result,

    // full ALU (FP pipeline integration: FADD/FMUL/FMA, 6-cycle latency)
    input  wire        alu_valid_in,
    input  wire [4:0]  alu_opcode,
    input  wire [31:0] alu_src1,
    input  wire [31:0] alu_src2,
    input  wire [31:0] alu_src3,
    input  wire [1:0]  alu_fp_rm,
    output wire        alu_valid_out,
    output wire [31:0] alu_result,
    output wire [3:0]  alu_fp_flags
);

    titan_x5_fp32_add u_add (
        .clk(clk), .rst_n(rst_n), .en(1'b1),
        .valid_in(add_valid_in), .rm(add_rm),
        .a(add_a), .b(add_b),
        .valid_out(add_valid_out), .result(add_result),
        .flag_invalid(add_invalid), .flag_overflow(add_overflow),
        .flag_underflow(add_underflow), .flag_inexact(add_inexact)
    );

    titan_x5_fp32_mul u_mul (
        .clk(clk), .rst_n(rst_n), .en(1'b1),
        .valid_in(mul_valid_in), .rm(mul_rm),
        .a(mul_a), .b(mul_b),
        .valid_out(mul_valid_out), .result(mul_result),
        .flag_invalid(mul_invalid), .flag_overflow(mul_overflow),
        .flag_underflow(mul_underflow), .flag_inexact(mul_inexact)
    );

    titan_x5_fp16_mul u_h_mul (
        .a(h_a), .b(h_b), .result(h_result)
    );

    titan_x5_alu #(.DATA_WIDTH(32)) u_alu (
        .clk(clk), .rst_n(rst_n),
        .valid_in(alu_valid_in), .opcode(alu_opcode),
        .src1(alu_src1), .src2(alu_src2), .src3(alu_src3),
        .fp_rm(alu_fp_rm),
        .stall_in(1'b0),
        .valid_out(alu_valid_out), .result_out(alu_result),
        .ready_out(), .fp_flags_out(alu_fp_flags),
        .branch_valid_out(), .branch_taken_out(), .branch_target_out()
    );

endmodule
