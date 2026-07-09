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
 * Module: titan_x5_noc_mesh
 * Description: MESH_X x MESH_Y grid of titan_x5_noc_router with all
 * neighbour links wired; the local ports are exposed flattened, indexed
 * node = y*MESH_X + x. Edge ports are tied off (XY routing never uses
 * them). Each hop is one register stage, so a flit travels
 * (|dx| + |dy| + 1) cycles under zero load.
 *
 * Local-port contract (per node, VC v):
 *   inject: drive lcl_in_flit/lcl_in_valid/lcl_in_vc only when you hold
 *           credit; one credit per flit, returned on lcl_in_credit.
 *           Initial credit = BUF_DEPTH per VC.
 *   eject:  flits appear on lcl_out_*; return one credit pulse on
 *           lcl_out_credit per flit consumed (backpressure by holding it).
 */
module titan_x5_noc_mesh #(
    parameter MESH_X    = 4,
    parameter MESH_Y    = 4,
    parameter PAYLOAD_W = 64,
    parameter N_VC      = 2,
    parameter BUF_DEPTH = 4,
    parameter FLIT_W    = PAYLOAD_W + 12,
    parameter N_NODE    = MESH_X * MESH_Y
)(
    input  wire                        clk,
    input  wire                        rst_n,

    input  wire [N_NODE*FLIT_W-1:0]    lcl_in_flit,
    input  wire [N_NODE-1:0]           lcl_in_valid,
    input  wire [N_NODE*N_VC-1:0]      lcl_in_vc,
    output wire [N_NODE*N_VC-1:0]      lcl_in_credit,

    output wire [N_NODE*FLIT_W-1:0]    lcl_out_flit,
    output wire [N_NODE-1:0]           lcl_out_valid,
    output wire [N_NODE*N_VC-1:0]      lcl_out_vc,
    input  wire [N_NODE*N_VC-1:0]      lcl_out_credit
);

    // per-router port buses
    wire [5*FLIT_W-1:0] r_in_flit   [0:N_NODE-1];
    wire [4:0]          r_in_valid  [0:N_NODE-1];
    wire [5*N_VC-1:0]   r_in_vc     [0:N_NODE-1];
    wire [5*N_VC-1:0]   r_in_credit [0:N_NODE-1];
    wire [5*FLIT_W-1:0] r_out_flit  [0:N_NODE-1];
    wire [4:0]          r_out_valid [0:N_NODE-1];
    wire [5*N_VC-1:0]   r_out_vc    [0:N_NODE-1];
    wire [5*N_VC-1:0]   r_out_credit[0:N_NODE-1];

    localparam P_N = 0, P_E = 1, P_S = 2, P_W = 3, P_L = 4;

    genvar x, y;
    generate
        for (y = 0; y < MESH_Y; y = y + 1) begin : g_y
            for (x = 0; x < MESH_X; x = x + 1) begin : g_x
                localparam NODE = y*MESH_X + x;

                titan_x5_noc_router #(
                    .X_ID(x), .Y_ID(y),
                    .PAYLOAD_W(PAYLOAD_W),
                    .N_VC(N_VC),
                    .BUF_DEPTH(BUF_DEPTH)
                ) u_router (
                    .clk(clk), .rst_n(rst_n),
                    .in_flit  (r_in_flit[NODE]),
                    .in_valid (r_in_valid[NODE]),
                    .in_vc    (r_in_vc[NODE]),
                    .in_credit(r_in_credit[NODE]),
                    .out_flit  (r_out_flit[NODE]),
                    .out_valid (r_out_valid[NODE]),
                    .out_vc    (r_out_vc[NODE]),
                    .out_credit(r_out_credit[NODE])
                );

                // ---- north neighbour (y-1): our N input <- their S output
                if (y > 0) begin : g_n
                    localparam NB = (y-1)*MESH_X + x;
                    assign r_in_flit[NODE][P_N*FLIT_W +: FLIT_W] = r_out_flit[NB][P_S*FLIT_W +: FLIT_W];
                    assign r_in_valid[NODE][P_N]                 = r_out_valid[NB][P_S];
                    assign r_in_vc[NODE][P_N*N_VC +: N_VC]       = r_out_vc[NB][P_S*N_VC +: N_VC];
                    assign r_out_credit[NODE][P_N*N_VC +: N_VC]  = r_in_credit[NB][P_S*N_VC +: N_VC];
                end else begin : g_n_edge
                    assign r_in_flit[NODE][P_N*FLIT_W +: FLIT_W] = {FLIT_W{1'b0}};
                    assign r_in_valid[NODE][P_N]                 = 1'b0;
                    assign r_in_vc[NODE][P_N*N_VC +: N_VC]       = {N_VC{1'b0}};
                    assign r_out_credit[NODE][P_N*N_VC +: N_VC]  = {N_VC{1'b0}};
                end

                // ---- south neighbour (y+1): our S input <- their N output
                if (y < MESH_Y-1) begin : g_s
                    localparam NB = (y+1)*MESH_X + x;
                    assign r_in_flit[NODE][P_S*FLIT_W +: FLIT_W] = r_out_flit[NB][P_N*FLIT_W +: FLIT_W];
                    assign r_in_valid[NODE][P_S]                 = r_out_valid[NB][P_N];
                    assign r_in_vc[NODE][P_S*N_VC +: N_VC]       = r_out_vc[NB][P_N*N_VC +: N_VC];
                    assign r_out_credit[NODE][P_S*N_VC +: N_VC]  = r_in_credit[NB][P_N*N_VC +: N_VC];
                end else begin : g_s_edge
                    assign r_in_flit[NODE][P_S*FLIT_W +: FLIT_W] = {FLIT_W{1'b0}};
                    assign r_in_valid[NODE][P_S]                 = 1'b0;
                    assign r_in_vc[NODE][P_S*N_VC +: N_VC]       = {N_VC{1'b0}};
                    assign r_out_credit[NODE][P_S*N_VC +: N_VC]  = {N_VC{1'b0}};
                end

                // ---- west neighbour (x-1): our W input <- their E output
                if (x > 0) begin : g_w
                    localparam NB = y*MESH_X + (x-1);
                    assign r_in_flit[NODE][P_W*FLIT_W +: FLIT_W] = r_out_flit[NB][P_E*FLIT_W +: FLIT_W];
                    assign r_in_valid[NODE][P_W]                 = r_out_valid[NB][P_E];
                    assign r_in_vc[NODE][P_W*N_VC +: N_VC]       = r_out_vc[NB][P_E*N_VC +: N_VC];
                    assign r_out_credit[NODE][P_W*N_VC +: N_VC]  = r_in_credit[NB][P_E*N_VC +: N_VC];
                end else begin : g_w_edge
                    assign r_in_flit[NODE][P_W*FLIT_W +: FLIT_W] = {FLIT_W{1'b0}};
                    assign r_in_valid[NODE][P_W]                 = 1'b0;
                    assign r_in_vc[NODE][P_W*N_VC +: N_VC]       = {N_VC{1'b0}};
                    assign r_out_credit[NODE][P_W*N_VC +: N_VC]  = {N_VC{1'b0}};
                end

                // ---- east neighbour (x+1): our E input <- their W output
                if (x < MESH_X-1) begin : g_e
                    localparam NB = y*MESH_X + (x+1);
                    assign r_in_flit[NODE][P_E*FLIT_W +: FLIT_W] = r_out_flit[NB][P_W*FLIT_W +: FLIT_W];
                    assign r_in_valid[NODE][P_E]                 = r_out_valid[NB][P_W];
                    assign r_in_vc[NODE][P_E*N_VC +: N_VC]       = r_out_vc[NB][P_W*N_VC +: N_VC];
                    assign r_out_credit[NODE][P_E*N_VC +: N_VC]  = r_in_credit[NB][P_W*N_VC +: N_VC];
                end else begin : g_e_edge
                    assign r_in_flit[NODE][P_E*FLIT_W +: FLIT_W] = {FLIT_W{1'b0}};
                    assign r_in_valid[NODE][P_E]                 = 1'b0;
                    assign r_in_vc[NODE][P_E*N_VC +: N_VC]       = {N_VC{1'b0}};
                    assign r_out_credit[NODE][P_E*N_VC +: N_VC]  = {N_VC{1'b0}};
                end

                // ---- local port
                assign r_in_flit[NODE][P_L*FLIT_W +: FLIT_W] = lcl_in_flit[NODE*FLIT_W +: FLIT_W];
                assign r_in_valid[NODE][P_L]                 = lcl_in_valid[NODE];
                assign r_in_vc[NODE][P_L*N_VC +: N_VC]       = lcl_in_vc[NODE*N_VC +: N_VC];
                assign lcl_in_credit[NODE*N_VC +: N_VC]      = r_in_credit[NODE][P_L*N_VC +: N_VC];

                assign lcl_out_flit[NODE*FLIT_W +: FLIT_W]   = r_out_flit[NODE][P_L*FLIT_W +: FLIT_W];
                assign lcl_out_valid[NODE]                   = r_out_valid[NODE][P_L];
                assign lcl_out_vc[NODE*N_VC +: N_VC]         = r_out_vc[NODE][P_L*N_VC +: N_VC];
                assign r_out_credit[NODE][P_L*N_VC +: N_VC]  = lcl_out_credit[NODE*N_VC +: N_VC];
            end
        end
    endgenerate

endmodule
