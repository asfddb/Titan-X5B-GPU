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
 * Titan X7 GPU - warp-aware branch predictor: gshare + BTB.
 *
 * - 1024-entry shared PHT of 2-bit saturating counters, indexed by
 *   pc[11:2] XOR the 8-bit per-warp global history (folded in).
 * - 64-entry direct-mapped BTB (valid + tag + target). A predict port
 *   only signals "taken" when both the PHT counter is taken AND the BTB
 *   hits: without a target there is nothing useful to redirect to.
 * - Two predict ports (the SM fetches instruction pairs).
 * - One update port, driven at branch resolution. Updates both
 *   structures and the warp's history register.
 *
 * All predict logic is combinational on registered state: one short
 * logic level after the RAM/flop read, suitable for a dedicated F0 stage.
 */
module titan_x7_branch_predictor #(
    parameter NUM_WARPS = 8,
    parameter WARP_W    = 3,
    parameter PHT_BITS  = 10,
    parameter BTB_BITS  = 6
)(
    input  wire              clk,
    input  wire              rst_n,

    // predict port 0 / 1
    input  wire [WARP_W-1:0] p_warp,
    input  wire [31:0]       p_pc0,
    input  wire [31:0]       p_pc1,
    output wire              p_taken0,
    output wire [31:0]       p_target0,
    output wire              p_taken1,
    output wire [31:0]       p_target1,

    // resolve/update port
    input  wire              u_valid,
    input  wire [WARP_W-1:0] u_warp,
    input  wire [31:0]       u_pc,
    input  wire              u_taken,
    input  wire [31:0]       u_target
);

    localparam PHT_N = 1 << PHT_BITS;
    localparam BTB_N = 1 << BTB_BITS;
    localparam TAG_W = 32 - BTB_BITS - 2;

    reg [1:0]        pht [0:PHT_N-1];
    reg              btb_v   [0:BTB_N-1];
    reg [TAG_W-1:0]  btb_tag [0:BTB_N-1];
    reg [31:0]       btb_tgt [0:BTB_N-1];
    reg [7:0]        ghr [0:NUM_WARPS-1];

    integer i;

    function [PHT_BITS-1:0] pht_idx;
        input [31:0] pc;
        input [7:0]  h;
        begin
            pht_idx = pc[PHT_BITS+1:2] ^ {{(PHT_BITS-8){1'b0}}, h};
        end
    endfunction

    wire [PHT_BITS-1:0] i0 = pht_idx(p_pc0, ghr[p_warp]);
    wire [PHT_BITS-1:0] i1 = pht_idx(p_pc1, ghr[p_warp]);
    wire [BTB_BITS-1:0] b0 = p_pc0[BTB_BITS+1:2];
    wire [BTB_BITS-1:0] b1 = p_pc1[BTB_BITS+1:2];

    wire hit0 = btb_v[b0] && (btb_tag[b0] == p_pc0[31:BTB_BITS+2]);
    wire hit1 = btb_v[b1] && (btb_tag[b1] == p_pc1[31:BTB_BITS+2]);

    assign p_taken0  = hit0 && pht[i0][1];
    assign p_target0 = btb_tgt[b0];
    assign p_taken1  = hit1 && pht[i1][1];
    assign p_target1 = btb_tgt[b1];

    wire [PHT_BITS-1:0] ui = pht_idx(u_pc, ghr[u_warp]);
    wire [BTB_BITS-1:0] ub = u_pc[BTB_BITS+1:2];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < PHT_N; i = i + 1) pht[i] <= 2'b01;    // weakly NT
            for (i = 0; i < BTB_N; i = i + 1) btb_v[i] <= 1'b0;
            for (i = 0; i < NUM_WARPS; i = i + 1) ghr[i] <= 8'd0;
        end else if (u_valid) begin
            // 2-bit saturating counter
            if (u_taken  && pht[ui] != 2'b11) pht[ui] <= pht[ui] + 2'd1;
            if (!u_taken && pht[ui] != 2'b00) pht[ui] <= pht[ui] - 2'd1;
            // BTB allocate/refresh on taken branches
            if (u_taken) begin
                btb_v[ub]   <= 1'b1;
                btb_tag[ub] <= u_pc[31:BTB_BITS+2];
                btb_tgt[ub] <= u_target;
            end
            ghr[u_warp] <= {ghr[u_warp][6:0], u_taken};
        end
    end

endmodule
