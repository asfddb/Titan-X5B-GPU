// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
// Testbench wrapper for the device-level flush sequencer. The ordering it
// enforces -- every L1 first, then a drain of the coherent crossbar, then L2
// -- is the whole reason the module exists, and it is far easier to check
// here than inside the full chip, where a violation would only show up as an
// occasional stale word.
`timescale 1ns / 1ps
module tb_flush_ctrl_top #(
    parameter NUM_L1 = 8
)(
    input  wire               clk,
    input  wire               rst_n,

    input  wire               flush_start,
    output wire               flush_busy,
    output wire               flush_complete,

    output wire               l1_flush_req,
    input  wire [NUM_L1-1:0]  l1_flush_done,

    input  wire               bus_idle,

    output wire               l2_flush_req,
    input  wire               l2_flush_done,

    // sequencer state, for diagnosing ordering failures
    output wire [2:0]         dbg_state,
    output wire               dbg_started
);

    assign dbg_state   = u_ctrl.state;
    assign dbg_started = u_ctrl.started;


    titan_x5_flush_ctrl #(.NUM_L1(NUM_L1)) u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .flush_start(flush_start),
        .flush_busy(flush_busy),
        .flush_complete(flush_complete),
        .l1_flush_req(l1_flush_req),
        .l1_flush_done(l1_flush_done),
        .bus_idle(bus_idle),
        .l2_flush_req(l2_flush_req),
        .l2_flush_done(l2_flush_done)
    );

endmodule
