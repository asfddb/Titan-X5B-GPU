// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
// Testbench wrapper for titan_x6_vram_ctrl. Instantiates the controller twice
// with different line sizes so a single elaboration proves BEATS_PER_LINE
// generality:
//   u_dut2 : LINE_BYTES=128 -> 1024b line / 512b bus = 2 beats
//   u_dut4 : LINE_BYTES=256 -> 2048b line / 512b bus = 4 beats
// The cocotb test drives/observes each instance's ports hierarchically
// (dut.u_dut2.*, dut.u_dut4.*); all ports are left unconnected here.
`timescale 1ns / 1ps
module tb_vram_top;
    reg clk = 1'b0;
    reg rst_n = 1'b0;

    titan_x6_vram_ctrl #(
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(512),
        .AXI_ID_WIDTH(4),
        .ID_WIDTH(5),
        .LINE_BYTES(128)
    ) u_dut2 (.clk(clk), .rst_n(rst_n));

    titan_x6_vram_ctrl #(
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(512),
        .AXI_ID_WIDTH(4),
        .ID_WIDTH(5),
        .LINE_BYTES(256)
    ) u_dut4 (.clk(clk), .rst_n(rst_n));
endmodule
