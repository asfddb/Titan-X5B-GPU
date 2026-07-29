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
 * Titan X7 GPU - greedy-then-oldest (GTO) dual-slot warp scheduler.
 *
 * Inputs are per-warp "issueable" flags (dependences, structural hazards,
 * barrier / branch-shadow stalls already folded in by the issue unit) and
 * the execution-pipe class of each warp's oldest instruction.
 *
 * Slot 0: the last-issued warp if it is still issueable (greedy - keeps a
 * warp's run going to exploit row locality and forwarding), otherwise the
 * OLDEST issueable warp (largest age counter - GTO's anti-starvation half).
 *
 * Slot 1: an issueable warp other than slot 0 whose head targets a
 * DIFFERENT execution pipe (cross-warp dual issue: no intra-pair
 * dependences possible, which is why no slot-1 dependence check exists).
 *
 * Ages saturate; a warp's age resets when it issues.
 */
module titan_x7_warp_scheduler #(
    parameter NUM_WARPS = 8,
    parameter WARP_W    = 3
)(
    input  wire                   clk,
    input  wire                   rst_n,

    input  wire [NUM_WARPS-1:0]   issueable,      // per-warp: head may issue
    input  wire [2*NUM_WARPS-1:0] head_pipe,      // per-warp pipe class (2b:
                                                  // 0=INT 1=FP 2=MEM 3=OTHER)
    output reg                    sel0_valid,
    output reg  [WARP_W-1:0]      sel0_warp,
    output reg                    sel1_valid,
    output reg  [WARP_W-1:0]      sel1_warp
);

    reg [WARP_W-1:0] last_warp;
    reg              last_valid;
    reg [7:0]        age [0:NUM_WARPS-1];

    // private loop variable per always block (processes may interleave;
    // sharing one index across blocks corrupts in-flight loops)
    integer i, i1, i2;

    // oldest issueable warp
    reg [WARP_W-1:0] oldest_warp;
    reg [7:0]        oldest_age;
    reg              oldest_found;
    always @(*) begin
        oldest_warp  = {WARP_W{1'b0}};
        oldest_age   = 8'd0;
        oldest_found = 1'b0;
        for (i = 0; i < NUM_WARPS; i = i + 1) begin
            if (issueable[i] && (!oldest_found || age[i] > oldest_age)) begin
                oldest_found = 1'b1;
                oldest_warp  = i;
                oldest_age   = age[i];
            end
        end
    end

    // slot 0: greedy, else oldest
    always @(*) begin
        if (last_valid && issueable[last_warp]) begin
            sel0_valid = 1'b1;
            sel0_warp  = last_warp;
        end else if (oldest_found) begin
            sel0_valid = 1'b1;
            sel0_warp  = oldest_warp;
        end else begin
            sel0_valid = 1'b0;
            sel0_warp  = {WARP_W{1'b0}};
        end
    end

    // slot 1: oldest issueable warp != slot0 with a different pipe class
    wire [1:0] pipe0 = head_pipe[sel0_warp*2 +: 2];
    reg [7:0]  s1_age;
    always @(*) begin
        sel1_valid = 1'b0;
        sel1_warp  = {WARP_W{1'b0}};
        s1_age     = 8'd0;
        for (i1 = 0; i1 < NUM_WARPS; i1 = i1 + 1) begin
            if (issueable[i1] && sel0_valid && ({29'd0, sel0_warp} != i1) &&
                (head_pipe[i1*2 +: 2] != pipe0) &&
                (!sel1_valid || age[i1] > s1_age)) begin
                sel1_valid = 1'b1;
                sel1_warp  = i1;
                s1_age     = age[i1];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            last_warp  <= {WARP_W{1'b0}};
            last_valid <= 1'b0;
            for (i2 = 0; i2 < NUM_WARPS; i2 = i2 + 1) age[i2] <= 8'd0;
        end else begin
            if (sel0_valid) begin
                last_warp  <= sel0_warp;
                last_valid <= 1'b1;
            end
            for (i2 = 0; i2 < NUM_WARPS; i2 = i2 + 1) begin
                if ((sel0_valid && {29'd0, sel0_warp} == i2) ||
                    (sel1_valid && {29'd0, sel1_warp} == i2))
                    age[i2] <= 8'd0;
                else if (age[i2] != 8'hFF)
                    age[i2] <= age[i2] + 8'd1;
            end
        end
    end

endmodule
