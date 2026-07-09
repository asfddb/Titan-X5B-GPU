// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
// Testbench wrapper for titan_x6_banked_l2 at small scale (2 slices, tiny sets)
// so array reset and simulation stay fast. The cocotb test drives/observes the
// req and mem interfaces hierarchically via dut.u_l2.*.
`timescale 1ns / 1ps
module tb_l2_top;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

    titan_x6_banked_l2 #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(256),
        .LINE_SIZE(16),     // 128-bit lines
        .WAYS(8),           // production associativity (slice replace_way is 3-bit)
        .NUM_SLICES(2),
        .SLICE_SETS(16)     // 16 sets / 4 banks = 4 sets per bank
    ) u_l2 (.clk(clk), .rst_n(rst_n));
endmodule
