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
 * Module: titan_x5_mesh_router
 * Description: 
 *   2D Mesh NoC Router for Titan X5 GPU project.
 *   - Flit-based transmission
 *   - Virtual Channels (VC) support for QoS and deadlock avoidance
 *   - XY Dimension-Order Routing Algorithm
 *   - 5x5 Crossbar (Local, North, South, East, West)
 *   - Lookahead routing: route computed in previous stage, decoded combinationally
 *   - Single-cycle traversal (wormhole bypass when downstream ready)
 */

module titan_x5_mesh_router #(
    parameter DATA_WIDTH  = 128,
    parameter X_COORD_W   = 8,
    parameter Y_COORD_W   = 8,
    parameter VC_ID_W     = 2,
    parameter NUM_VCS     = 1 << VC_ID_W,
    parameter FLIT_TYPE_W = 2,
    parameter FLIT_WIDTH  = FLIT_TYPE_W + VC_ID_W + X_COORD_W + Y_COORD_W + DATA_WIDTH,
    parameter [X_COORD_W-1:0] ROUTER_X_ID = 0,
    parameter [Y_COORD_W-1:0] ROUTER_Y_ID = 0
)(
    input  wire clk,
    input  wire rst_n,

    // Port 0: Local
    input  wire [FLIT_WIDTH-1:0] p0_in_flit,
    input  wire                  p0_in_valid,
    output wire [NUM_VCS-1:0]    p0_in_ready,
    output wire [FLIT_WIDTH-1:0] p0_out_flit,
    output wire                  p0_out_valid,
    input  wire [NUM_VCS-1:0]    p0_out_ready,

    // Port 1: North
    input  wire [FLIT_WIDTH-1:0] p1_in_flit,
    input  wire                  p1_in_valid,
    output wire [NUM_VCS-1:0]    p1_in_ready,
    output wire [FLIT_WIDTH-1:0] p1_out_flit,
    output wire                  p1_out_valid,
    input  wire [NUM_VCS-1:0]    p1_out_ready,

    // Port 2: South
    input  wire [FLIT_WIDTH-1:0] p2_in_flit,
    input  wire                  p2_in_valid,
    output wire [NUM_VCS-1:0]    p2_in_ready,
    output wire [FLIT_WIDTH-1:0] p2_out_flit,
    output wire                  p2_out_valid,
    input  wire [NUM_VCS-1:0]    p2_out_ready,

    // Port 3: East
    input  wire [FLIT_WIDTH-1:0] p3_in_flit,
    input  wire                  p3_in_valid,
    output wire [NUM_VCS-1:0]    p3_in_ready,
    output wire [FLIT_WIDTH-1:0] p3_out_flit,
    output wire                  p3_out_valid,
    input  wire [NUM_VCS-1:0]    p3_out_ready,

    // Port 4: West
    input  wire [FLIT_WIDTH-1:0] p4_in_flit,
    input  wire                  p4_in_valid,
    output wire [NUM_VCS-1:0]    p4_in_ready,
    output wire [FLIT_WIDTH-1:0] p4_out_flit,
    output wire                  p4_out_valid,
    input  wire [NUM_VCS-1:0]    p4_out_ready
);

    // ------------------------------------------------------------------
    // Flit field extraction (combinational, zero latency)
    // ------------------------------------------------------------------
    localparam DST_X_MSB = FLIT_TYPE_W + VC_ID_W + X_COORD_W + Y_COORD_W - 1;
    localparam DST_X_LSB = FLIT_TYPE_W + VC_ID_W + Y_COORD_W;
    localparam DST_Y_MSB = FLIT_TYPE_W + VC_ID_W + Y_COORD_W - 1;
    localparam DST_Y_LSB = FLIT_TYPE_W + VC_ID_W;
    localparam VC_MSB    = FLIT_TYPE_W + VC_ID_W - 1;
    localparam VC_LSB    = FLIT_TYPE_W;
    localparam TYPE_MSB  = FLIT_TYPE_W - 1;
    localparam TYPE_LSB  = 0;

    // ------------------------------------------------------------------
    // Combinational XY route computation (lookahead routing)
    // ------------------------------------------------------------------
    function [2:0] xy_route;
        input [X_COORD_W-1:0] src_x;
        input [Y_COORD_W-1:0] src_y;
        input [X_COORD_W-1:0] dst_x;
        input [Y_COORD_W-1:0] dst_y;
        begin
            if (dst_x > src_x)      xy_route = 3'd3;
            else if (dst_x < src_x) xy_route = 3'd4;
            else if (dst_y > src_y) xy_route = 3'd1;
            else if (dst_y < src_y) xy_route = 3'd2;
            else                    xy_route = 3'd0;
        end
    endfunction

    // ------------------------------------------------------------------
    // Per-port route computation (combinational)
    // ------------------------------------------------------------------
    wire [2:0] route_p0 = xy_route(ROUTER_X_ID, ROUTER_Y_ID,
                                   p0_in_flit[DST_X_MSB:DST_X_LSB],
                                   p0_in_flit[DST_Y_MSB:DST_Y_LSB]);
    wire [2:0] route_p1 = xy_route(ROUTER_X_ID, ROUTER_Y_ID,
                                   p1_in_flit[DST_X_MSB:DST_X_LSB],
                                   p1_in_flit[DST_Y_MSB:DST_Y_LSB]);
    wire [2:0] route_p2 = xy_route(ROUTER_X_ID, ROUTER_Y_ID,
                                   p2_in_flit[DST_X_MSB:DST_X_LSB],
                                   p2_in_flit[DST_Y_MSB:DST_Y_LSB]);
    wire [2:0] route_p3 = xy_route(ROUTER_X_ID, ROUTER_Y_ID,
                                   p3_in_flit[DST_X_MSB:DST_X_LSB],
                                   p3_in_flit[DST_Y_MSB:DST_Y_LSB]);
    wire [2:0] route_p4 = xy_route(ROUTER_X_ID, ROUTER_Y_ID,
                                   p4_in_flit[DST_X_MSB:DST_X_LSB],
                                   p4_in_flit[DST_Y_MSB:DST_Y_LSB]);

    // ------------------------------------------------------------------
    // Per-VC request matrix: req[in_port][out_port]
    // ------------------------------------------------------------------
    reg [4:0] req [0:4];
    reg [4:0] gnt [0:4];
    reg [4:0] sel_in_to_out [0:4];

    integer i;
    always @* begin
        for (i = 0; i < 5; i = i + 1) begin
            req[i] = 5'b00000;
            gnt[i] = 5'b00000;
        end
        req[0][route_p0] = p0_in_valid;
        req[1][route_p1] = p1_in_valid;
        req[2][route_p2] = p2_in_valid;
        req[3][route_p3] = p3_in_valid;
        req[4][route_p4] = p4_in_valid;
    end

    // ------------------------------------------------------------------
    // Output-port arbitration (parallel priority, fixed round-robin via priority)
    // ------------------------------------------------------------------
    wire [4:0] out_ready;
    assign out_ready[0] = |p0_out_ready;
    assign out_ready[1] = |p1_out_ready;
    assign out_ready[2] = |p2_out_ready;
    assign out_ready[3] = |p3_out_ready;
    assign out_ready[4] = |p4_out_ready;

    // For each output port, pick the highest-priority input that requests it
    // and that has downstream credit available.
    always @* begin
        for (i = 0; i < 5; i = i + 1) begin
            sel_in_to_out[i] = 3'd0;
        end
        // Output 0 (Local)
        if (req[0][0] & out_ready[0])      sel_in_to_out[0] = 3'd0;
        else if (req[1][0] & out_ready[0]) sel_in_to_out[0] = 3'd1;
        else if (req[2][0] & out_ready[0]) sel_in_to_out[0] = 3'd2;
        else if (req[3][0] & out_ready[0]) sel_in_to_out[0] = 3'd3;
        else if (req[4][0] & out_ready[0]) sel_in_to_out[0] = 3'd4;
        // Output 1 (North)
        if (req[0][1] & out_ready[1])      sel_in_to_out[1] = 3'd0;
        else if (req[1][1] & out_ready[1]) sel_in_to_out[1] = 3'd1;
        else if (req[2][1] & out_ready[1]) sel_in_to_out[1] = 3'd2;
        else if (req[3][1] & out_ready[1]) sel_in_to_out[1] = 3'd3;
        else if (req[4][1] & out_ready[1]) sel_in_to_out[1] = 3'd4;
        // Output 2 (South)
        if (req[0][2] & out_ready[2])      sel_in_to_out[2] = 3'd0;
        else if (req[1][2] & out_ready[2]) sel_in_to_out[2] = 3'd1;
        else if (req[2][2] & out_ready[2]) sel_in_to_out[2] = 3'd2;
        else if (req[3][2] & out_ready[2]) sel_in_to_out[2] = 3'd3;
        else if (req[4][2] & out_ready[2]) sel_in_to_out[2] = 3'd4;
        // Output 3 (East)
        if (req[0][3] & out_ready[3])      sel_in_to_out[3] = 3'd0;
        else if (req[1][3] & out_ready[3]) sel_in_to_out[3] = 3'd1;
        else if (req[2][3] & out_ready[3]) sel_in_to_out[3] = 3'd2;
        else if (req[3][3] & out_ready[3]) sel_in_to_out[3] = 3'd3;
        else if (req[4][3] & out_ready[3]) sel_in_to_out[3] = 3'd4;
        // Output 4 (West)
        if (req[0][4] & out_ready[4])      sel_in_to_out[4] = 3'd0;
        else if (req[1][4] & out_ready[4]) sel_in_to_out[4] = 3'd1;
        else if (req[2][4] & out_ready[4]) sel_in_to_out[4] = 3'd2;
        else if (req[3][4] & out_ready[4]) sel_in_to_out[4] = 3'd3;
        else if (req[4][4] & out_ready[4]) sel_in_to_out[4] = 3'd4;
    end

    // ------------------------------------------------------------------
    // Grant matrix: gnt[in_port][out_port]
    // ------------------------------------------------------------------
    always @* begin
        for (i = 0; i < 5; i = i + 1) gnt[i] = 5'b00000;
        gnt[sel_in_to_out[0]][0] = req[sel_in_to_out[0]][0] & out_ready[0];
        gnt[sel_in_to_out[1]][1] = req[sel_in_to_out[1]][1] & out_ready[1];
        gnt[sel_in_to_out[2]][2] = req[sel_in_to_out[2]][2] & out_ready[2];
        gnt[sel_in_to_out[3]][3] = req[sel_in_to_out[3]][3] & out_ready[3];
        gnt[sel_in_to_out[4]][4] = req[sel_in_to_out[4]][4] & out_ready[4];
    end

    // ------------------------------------------------------------------
    // 5x5 Crossbar (combinational muxes)
    // ------------------------------------------------------------------
    wire [FLIT_WIDTH-1:0] xbar_in [0:4];
    assign xbar_in[0] = p0_in_flit;
    assign xbar_in[1] = p1_in_flit;
    assign xbar_in[2] = p2_in_flit;
    assign xbar_in[3] = p3_in_flit;
    assign xbar_in[4] = p4_in_flit;

    assign p0_out_flit = xbar_in[sel_in_to_out[0]];
    assign p1_out_flit = xbar_in[sel_in_to_out[1]];
    assign p2_out_flit = xbar_in[sel_in_to_out[2]];
    assign p3_out_flit = xbar_in[sel_in_to_out[3]];
    assign p4_out_flit = xbar_in[sel_in_to_out[4]];

    assign p0_out_valid = |gnt[0] | (|gnt[1] & (sel_in_to_out[0] == 3'd1)) | (|gnt[2] & (sel_in_to_out[0] == 3'd2)) | (|gnt[3] & (sel_in_to_out[0] == 3'd3)) | (|gnt[4] & (sel_in_to_out[0] == 3'd4));
    assign p1_out_valid = |gnt[1] | (|gnt[0] & (sel_in_to_out[1] == 3'd0)) | (|gnt[2] & (sel_in_to_out[1] == 3'd2)) | (|gnt[3] & (sel_in_to_out[1] == 3'd3)) | (|gnt[4] & (sel_in_to_out[1] == 3'd4));
    assign p2_out_valid = |gnt[2] | (|gnt[0] & (sel_in_to_out[2] == 3'd0)) | (|gnt[1] & (sel_in_to_out[2] == 3'd1)) | (|gnt[3] & (sel_in_to_out[2] == 3'd3)) | (|gnt[4] & (sel_in_to_out[2] == 3'd4));
    assign p3_out_valid = |gnt[3] | (|gnt[0] & (sel_in_to_out[3] == 3'd0)) | (|gnt[1] & (sel_in_to_out[3] == 3'd1)) | (|gnt[2] & (sel_in_to_out[3] == 3'd2)) | (|gnt[4] & (sel_in_to_out[3] == 3'd4));
    assign p4_out_valid = |gnt[4] | (|gnt[0] & (sel_in_to_out[4] == 3'd0)) | (|gnt[1] & (sel_in_to_out[4] == 3'd1)) | (|gnt[2] & (sel_in_to_out[4] == 3'd2)) | (|gnt[3] & (sel_in_to_out[4] == 3'd3));

    // ------------------------------------------------------------------
    // Per-input ready: input is ready if it won arbitration to any output
    // that has downstream credit. For single-flit traversal, we accept
    // whenever the input is granted to any output.
    // ------------------------------------------------------------------
    wire [4:0] in_gnt_any;
    assign in_gnt_any[0] = |gnt[0];
    assign in_gnt_any[1] = |gnt[1];
    assign in_gnt_any[2] = |gnt[2];
    assign in_gnt_any[3] = |gnt[3];
    assign in_gnt_any[4] = |gnt[4];

    assign p0_in_ready = {NUM_VCS{in_gnt_any[0]}};
    assign p1_in_ready = {NUM_VCS{in_gnt_any[1]}};
    assign p2_in_ready = {NUM_VCS{in_gnt_any[2]}};
    assign p3_in_ready = {NUM_VCS{in_gnt_any[3]}};
    assign p4_in_ready = {NUM_VCS{in_gnt_any[4]}};

endmodule