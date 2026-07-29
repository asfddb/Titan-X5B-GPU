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
 * Titan X7 GPU - per-warp register scoreboard for the dual-issue SM.
 *
 * One busy bit per (warp, architectural register). Registers are marked
 * busy at issue and cleared by any of the three writeback ports (INT pipe,
 * FP pipe, LSU). Two combinational lookup ports serve the two issue slots;
 * clears are forwarded into the same-cycle lookups so a dependent can
 * issue in the cycle its producer writes back.
 */
module titan_x7_scoreboard #(
    parameter NUM_WARPS = 8,
    parameter WARP_W    = 3
)(
    input  wire              clk,
    input  wire              rst_n,

    // issue-side set ports (slot 0 / slot 1)
    input  wire              set0_en,
    input  wire [WARP_W-1:0] set0_warp,
    input  wire [5:0]        set0_reg,
    input  wire              set1_en,
    input  wire [WARP_W-1:0] set1_warp,
    input  wire [5:0]        set1_reg,

    // writeback clear ports
    input  wire              clr0_en,
    input  wire [WARP_W-1:0] clr0_warp,
    input  wire [5:0]        clr0_reg,
    input  wire              clr1_en,
    input  wire [WARP_W-1:0] clr1_warp,
    input  wire [5:0]        clr1_reg,
    input  wire              clr2_en,
    input  wire [WARP_W-1:0] clr2_warp,
    input  wire [5:0]        clr2_reg,

    // full busy state, flattened: the issue unit computes per-warp
    // readiness for every warp in parallel (GTO needs global visibility).
    // Same-cycle clear forwarding is applied by the consumer.
    output wire [NUM_WARPS*64-1:0] busy_flat
);

    reg [63:0] busy [0:NUM_WARPS-1];

    integer i;

    genvar g;
    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : g_flat
            assign busy_flat[g*64 +: 64] = busy[g];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_WARPS; i = i + 1)
                busy[i] <= 64'd0;
        end else begin
            // clears before sets: if a slot re-allocates a just-cleared
            // register in the same cycle, it must end up busy
            if (clr0_en) busy[clr0_warp][clr0_reg] <= 1'b0;
            if (clr1_en) busy[clr1_warp][clr1_reg] <= 1'b0;
            if (clr2_en) busy[clr2_warp][clr2_reg] <= 1'b0;
            if (set0_en) busy[set0_warp][set0_reg] <= 1'b1;
            if (set1_en) busy[set1_warp][set1_reg] <= 1'b1;
        end
    end

endmodule
