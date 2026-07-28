// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// cocotb wrapper for titan_x5_pc_unit (suite: tb/uvm/test_pc_unit.py).
// ============================================================================
`timescale 1ns/1ps

module tb_pc_unit_top #(
    parameter NUM_WARPS = 8,
    parameter WARP_ID_W = 3
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     launch_valid,
    input  wire [NUM_WARPS-1:0]     launch_mask,
    input  wire [31:0]              launch_pc,

    input  wire                     fetch_accept,
    input  wire [WARP_ID_W-1:0]     fetch_warp,

    input  wire                     redirect_valid,
    input  wire [WARP_ID_W-1:0]     redirect_warp,
    input  wire [31:0]              redirect_pc,

    input  wire                     retire_valid,
    input  wire [WARP_ID_W-1:0]     retire_warp,

    output wire [NUM_WARPS*32-1:0]  warp_pc,
    output wire [NUM_WARPS-1:0]     warp_active,
    output wire                     all_retired
);

    titan_x5_pc_unit #(
        .NUM_WARPS(NUM_WARPS),
        .WARP_ID_W(WARP_ID_W)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .launch_valid(launch_valid),
        .launch_mask(launch_mask),
        .launch_pc(launch_pc),
        .fetch_accept(fetch_accept),
        .fetch_warp(fetch_warp),
        .redirect_valid(redirect_valid),
        .redirect_warp(redirect_warp),
        .redirect_pc(redirect_pc),
        .retire_valid(retire_valid),
        .retire_warp(retire_warp),
        .warp_pc(warp_pc),
        .warp_active(warp_active),
        .all_retired(all_retired)
    );

endmodule
