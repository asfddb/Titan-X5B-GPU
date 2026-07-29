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
 * Differential harness: the proven 6-stage titan_x5_fp32_fma (GDSII-hardened,
 * oracle-verified) and the new 8-stage titan_x7_fp32_fma_pipe run in lockstep
 * on identical stimulus. The cocotb side (tb/uvm/test_fma_x7.py) compares the
 * two ordered output streams bit-for-bit, flags included.
 */
module tb_fma_x7 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        valid_in,
    input  wire [1:0]  rm,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,

    output wire        ref_valid,
    output wire [31:0] ref_result,
    output wire        ref_invalid,
    output wire        ref_overflow,
    output wire        ref_underflow,
    output wire        ref_inexact,

    output wire        dut_valid,
    output wire [31:0] dut_result,
    output wire        dut_invalid,
    output wire        dut_overflow,
    output wire        dut_underflow,
    output wire        dut_inexact
);

    titan_x5_fp32_fma u_ref (
        .clk(clk), .rst_n(rst_n), .en(en),
        .valid_in(valid_in), .rm(rm),
        .a(a), .b(b), .c(c),
        .valid_out(ref_valid),
        .result(ref_result),
        .flag_invalid(ref_invalid),
        .flag_overflow(ref_overflow),
        .flag_underflow(ref_underflow),
        .flag_inexact(ref_inexact)
    );

    titan_x7_fp32_fma_pipe u_dut (
        .clk(clk), .rst_n(rst_n), .en(en),
        .valid_in(valid_in), .rm(rm),
        .a(a), .b(b), .c(c),
        .valid_out(dut_valid),
        .result(dut_result),
        .flag_invalid(dut_invalid),
        .flag_overflow(dut_overflow),
        .flag_underflow(dut_underflow),
        .flag_inexact(dut_inexact)
    );

endmodule
