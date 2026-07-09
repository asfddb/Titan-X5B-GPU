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
 * Module: titan_x5_rt_core
 * Description: Hardware BVH traversal engine, multi-ray in flight.
 *
 * N_RAYS independent rays traverse the BVH concurrently, each with a
 * private traversal stack. A round-robin scheduler issues one BVH node
 * fetch per clock; returned nodes stream into fully pipelined ray-box
 * (titan_x5_ray_box_isect, II=1) and ray-triangle
 * (titan_x5_ray_triangle_isect, II=1) units. With >= ~7 rays resident the
 * engine sustains one new ray-box test per clock cycle - the pipelines
 * never block, only per-ray dependencies (fetch -> test -> push/pop) limit
 * a single ray.
 *
 * BVH node format (384 bits, one node per fetch):
 *   header  [383:352]  bit 0 = is_leaf
 *   internal node:
 *     left child ptr   [351:320]
 *     right child ptr  [319:288]
 *     aabb min x/y/z   [287:256] [255:224] [223:192]   (Q16.16)
 *     aabb max x/y/z   [191:160] [159:128] [127:96]    (Q16.16)
 *   leaf node:
 *     triangle id      [351:320]
 *     v0 x/y/z         [287:256] [255:224] [223:192]
 *     v1 x/y/z         [191:160] [159:128] [127:96]
 *     v2 x/y/z         [95:64]   [63:32]   [31:0]
 *
 * Traversal: near child first (by ray x-direction sign), far child pushed;
 * misses pop the stack; boxes farther than the current closest hit are
 * pruned in the slab test (t_max). Triangles are double-sided.
 *
 * Interfaces:
 *   ray_*     one ray accepted per cycle into a free slot (ray_ready)
 *   node_*    pipelined tagged fetch port; responses may return in any
 *             order, tag = ray slot; at most one response per cycle
 *   res_*     one finished ray per cycle (no backpressure; consumer must
 *             accept in the cycle res_valid is high)
 */
module titan_x5_rt_core #(
    parameter W           = 32,   // Q16.16
    parameter N_RAYS      = 8,    // power of two
    parameter STACK_DEPTH = 32,   // per-ray traversal stack entries
    parameter RAY_W       = 3     // $clog2(N_RAYS)
)(
    input  wire                clk,
    input  wire                rst_n,

    // ray submission
    input  wire                ray_valid,
    output wire                ray_ready,
    input  wire [31:0]         ray_id,
    input  wire [31:0]         ray_root_ptr,
    input  wire signed [W-1:0] ray_o_x, ray_o_y, ray_o_z,
    input  wire signed [W-1:0] ray_d_x, ray_d_y, ray_d_z,
    input  wire signed [W-1:0] ray_inv_d_x, ray_inv_d_y, ray_inv_d_z,

    // BVH node fetch (pipelined, tagged, out-of-order responses allowed)
    output reg                 node_req_valid,
    output reg  [31:0]         node_req_addr,
    output reg  [RAY_W-1:0]    node_req_tag,
    input  wire                node_req_ready,
    input  wire                node_rsp_valid,
    input  wire [RAY_W-1:0]    node_rsp_tag,
    input  wire [383:0]        node_rsp_data,

    // results
    output reg                 res_valid,
    output reg  [31:0]         res_ray_id,
    output reg                 res_hit,
    output reg  [31:0]         res_tri_id,
    output reg  signed [W-1:0] res_t,
    output reg  signed [W-1:0] res_u,
    output reg  signed [W-1:0] res_v,

    output wire                busy
);

    localparam SP_W = 6;  // counts 0..STACK_DEPTH (<=32)

    // per-ray traversal state
    localparam [2:0] RS_IDLE  = 3'd0;  // slot free
    localparam [2:0] RS_READY = 3'd1;  // node ptr ready to fetch
    localparam [2:0] RS_FETCH = 3'd2;  // fetch issued, awaiting response
    localparam [2:0] RS_BOX   = 3'd3;  // slab test in flight
    localparam [2:0] RS_TRI   = 3'd4;  // triangle test in flight
    localparam [2:0] RS_DONE  = 3'd5;  // result pending output

    reg [2:0]          rstate  [0:N_RAYS-1];
    reg [31:0]         r_id    [0:N_RAYS-1];
    reg [31:0]         r_node  [0:N_RAYS-1];
    reg [31:0]         r_near  [0:N_RAYS-1];
    reg [31:0]         r_far   [0:N_RAYS-1];
    reg [SP_W-1:0]     r_sp    [0:N_RAYS-1];
    reg signed [W-1:0] r_ox [0:N_RAYS-1], r_oy [0:N_RAYS-1], r_oz [0:N_RAYS-1];
    reg signed [W-1:0] r_dx [0:N_RAYS-1], r_dy [0:N_RAYS-1], r_dz [0:N_RAYS-1];
    reg signed [W-1:0] r_ix [0:N_RAYS-1], r_iy [0:N_RAYS-1], r_iz [0:N_RAYS-1];
    reg signed [W-1:0] r_ct   [0:N_RAYS-1];  // closest t so far
    reg                r_bhit [0:N_RAYS-1];
    reg [31:0]         r_btri [0:N_RAYS-1];
    reg signed [W-1:0] r_bu   [0:N_RAYS-1], r_bv [0:N_RAYS-1];

    // per-ray traversal stacks (node pointers)
    reg [31:0] stack_mem [0:N_RAYS*STACK_DEPTH-1];

    // ------------------------------------------------------------------
    // node response decode
    // ------------------------------------------------------------------
    wire        rsp_is_leaf = node_rsp_data[352];
    wire [31:0] rsp_left    = node_rsp_data[351:320];
    wire [31:0] rsp_right   = node_rsp_data[319:288];
    wire [31:0] rsp_tri_id  = node_rsp_data[351:320];
    wire signed [W-1:0] rsp_min_x = node_rsp_data[287:256];
    wire signed [W-1:0] rsp_min_y = node_rsp_data[255:224];
    wire signed [W-1:0] rsp_min_z = node_rsp_data[223:192];
    wire signed [W-1:0] rsp_max_x = node_rsp_data[191:160];
    wire signed [W-1:0] rsp_max_y = node_rsp_data[159:128];
    wire signed [W-1:0] rsp_max_z = node_rsp_data[127:96];
    wire signed [W-1:0] rsp_v0_x  = node_rsp_data[287:256];
    wire signed [W-1:0] rsp_v0_y  = node_rsp_data[255:224];
    wire signed [W-1:0] rsp_v0_z  = node_rsp_data[223:192];
    wire signed [W-1:0] rsp_v1_x  = node_rsp_data[191:160];
    wire signed [W-1:0] rsp_v1_y  = node_rsp_data[159:128];
    wire signed [W-1:0] rsp_v1_z  = node_rsp_data[127:96];
    wire signed [W-1:0] rsp_v2_x  = node_rsp_data[95:64];
    wire signed [W-1:0] rsp_v2_y  = node_rsp_data[63:32];
    wire signed [W-1:0] rsp_v2_z  = node_rsp_data[31:0];

    wire [RAY_W-1:0] rt = node_rsp_tag;

    // ------------------------------------------------------------------
    // intersection pipelines
    // ------------------------------------------------------------------
    wire             box_vo;
    wire [RAY_W-1:0] box_tag;
    wire             box_hit;

    titan_x5_ray_box_isect #(.W(W), .TAG_W(RAY_W)) u_box (
        .clk(clk), .rst_n(rst_n),
        .valid_in(node_rsp_valid && !rsp_is_leaf),
        .tag_in(rt),
        .ray_o_x(r_ox[rt]), .ray_o_y(r_oy[rt]), .ray_o_z(r_oz[rt]),
        .ray_inv_d_x(r_ix[rt]), .ray_inv_d_y(r_iy[rt]), .ray_inv_d_z(r_iz[rt]),
        .t_max_in(r_ct[rt]),
        .box_min_x(rsp_min_x), .box_min_y(rsp_min_y), .box_min_z(rsp_min_z),
        .box_max_x(rsp_max_x), .box_max_y(rsp_max_y), .box_max_z(rsp_max_z),
        .valid_out(box_vo), .tag_out(box_tag),
        .box_hit(box_hit), .t_entry_out()
    );

    wire             tri_vo;
    wire [RAY_W-1:0] tri_tag;
    wire             tri_hit;
    wire signed [W-1:0] tri_t, tri_u, tri_v;

    titan_x5_ray_triangle_isect #(.W(W), .TAG_W(RAY_W)) u_tri (
        .clk(clk), .rst_n(rst_n),
        .valid_in(node_rsp_valid && rsp_is_leaf),
        .tag_in(rt),
        .ray_o_x(r_ox[rt]), .ray_o_y(r_oy[rt]), .ray_o_z(r_oz[rt]),
        .ray_d_x(r_dx[rt]), .ray_d_y(r_dy[rt]), .ray_d_z(r_dz[rt]),
        .v0_x(rsp_v0_x), .v0_y(rsp_v0_y), .v0_z(rsp_v0_z),
        .v1_x(rsp_v1_x), .v1_y(rsp_v1_y), .v1_z(rsp_v1_z),
        .v2_x(rsp_v2_x), .v2_y(rsp_v2_y), .v2_z(rsp_v2_z),
        .valid_out(tri_vo), .tag_out(tri_tag),
        .is_hit(tri_hit), .t_out(tri_t), .u_out(tri_u), .v_out(tri_v)
    );

    // ------------------------------------------------------------------
    // slot selection
    // ------------------------------------------------------------------
    reg [N_RAYS-1:0] idle_mask, ready_mask, done_mask;
    integer k_comb;
    integer k_seq;
    always @* begin
        for (k_comb = 0; k_comb < N_RAYS; k_comb = k_comb + 1) begin
            idle_mask[k_comb]  = (rstate[k_comb] == RS_IDLE);
            ready_mask[k_comb] = (rstate[k_comb] == RS_READY);
            done_mask[k_comb]  = (rstate[k_comb] == RS_DONE);
        end
    end

    // fixed-priority find-first-set: {found, index}
    function automatic [RAY_W:0] ffs;
        input [N_RAYS-1:0] mask;
        integer i;
        begin
            ffs = {(RAY_W+1){1'b0}};
            for (i = N_RAYS-1; i >= 0; i = i - 1)
                if (mask[i]) ffs = {1'b1, i[RAY_W-1:0]};
        end
    endfunction

    // rotating-priority find-first-set starting at 'start'
    function automatic [RAY_W:0] ffs_rot;
        input [N_RAYS-1:0] mask;
        input [RAY_W-1:0]  start;
        integer i;
        reg [RAY_W-1:0] idx;
        begin
            ffs_rot = {(RAY_W+1){1'b0}};
            for (i = N_RAYS-1; i >= 0; i = i - 1) begin
                idx = start + i[RAY_W-1:0];
                if (mask[idx]) ffs_rot = {1'b1, idx};
            end
        end
    endfunction

    reg [RAY_W-1:0] rr_ptr;

    wire [RAY_W:0] acc_pick = ffs(idle_mask);
    wire           acc_found = acc_pick[RAY_W];
    wire [RAY_W-1:0] acc_idx = acc_pick[RAY_W-1:0];

    wire [RAY_W:0] iss_pick = ffs_rot(ready_mask, rr_ptr);
    wire           iss_found = iss_pick[RAY_W];
    wire [RAY_W-1:0] iss_idx = iss_pick[RAY_W-1:0];

    wire [RAY_W:0] dn_pick = ffs(done_mask);
    wire           dn_found = dn_pick[RAY_W];
    wire [RAY_W-1:0] dn_idx = dn_pick[RAY_W-1:0];

    assign ray_ready = acc_found;
    assign busy      = ~&idle_mask;

    // fetch port free this cycle (nothing held or held request accepted)
    wire req_free = !node_req_valid || node_req_ready;

    // ------------------------------------------------------------------
    // main sequential control
    // ------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k_seq = 0; k_seq < N_RAYS; k_seq = k_seq + 1) begin
                rstate[k_seq] <= RS_IDLE;
                r_sp[k_seq]   <= {SP_W{1'b0}};
                r_ct[k_seq]   <= 32'h7FFF_FFFF;
                r_bhit[k_seq] <= 1'b0;
            end
            node_req_valid <= 1'b0;
            node_req_addr  <= 32'h0;
            node_req_tag   <= {RAY_W{1'b0}};
            res_valid      <= 1'b0;
            res_ray_id     <= 32'h0;
            res_hit        <= 1'b0;
            res_tri_id     <= 32'h0;
            res_t          <= {W{1'b0}};
            res_u          <= {W{1'b0}};
            res_v          <= {W{1'b0}};
            rr_ptr         <= {RAY_W{1'b0}};
        end else begin
            res_valid <= 1'b0;

            // 1. accept a new ray into a free slot
            if (ray_valid && acc_found) begin
                rstate[acc_idx] <= RS_READY;
                r_id[acc_idx]   <= ray_id;
                r_node[acc_idx] <= ray_root_ptr;
                r_sp[acc_idx]   <= {SP_W{1'b0}};
                r_ct[acc_idx]   <= 32'h7FFF_FFFF;
                r_bhit[acc_idx] <= 1'b0;
                r_btri[acc_idx] <= 32'h0;
                r_bu[acc_idx]   <= {W{1'b0}};
                r_bv[acc_idx]   <= {W{1'b0}};
                r_ox[acc_idx] <= ray_o_x;  r_oy[acc_idx] <= ray_o_y;  r_oz[acc_idx] <= ray_o_z;
                r_dx[acc_idx] <= ray_d_x;  r_dy[acc_idx] <= ray_d_y;  r_dz[acc_idx] <= ray_d_z;
                r_ix[acc_idx] <= ray_inv_d_x; r_iy[acc_idx] <= ray_inv_d_y; r_iz[acc_idx] <= ray_inv_d_z;
            end

            // 2. issue one node fetch per cycle (round-robin over ready rays)
            if (req_free) begin
                if (iss_found) begin
                    node_req_valid    <= 1'b1;
                    node_req_addr     <= r_node[iss_idx];
                    node_req_tag      <= iss_idx;
                    rstate[iss_idx]   <= RS_FETCH;
                    rr_ptr            <= iss_idx + 1'b1;
                end else begin
                    node_req_valid <= 1'b0;
                end
            end

            // 3. dispatch node response into the matching pipeline
            if (node_rsp_valid) begin
                if (rsp_is_leaf) begin
                    rstate[rt] <= RS_TRI;
                    r_node[rt] <= rsp_tri_id;  // stash pending tri id in r_node
                end else begin
                    rstate[rt] <= RS_BOX;
                    if (!r_dx[rt][W-1]) begin  // positive x: left first
                        r_near[rt] <= rsp_left;
                        r_far[rt]  <= rsp_right;
                    end else begin
                        r_near[rt] <= rsp_right;
                        r_far[rt]  <= rsp_left;
                    end
                end
            end

            // 4. resolve slab test
            if (box_vo) begin
                if (box_hit) begin
                    if (r_sp[box_tag] < STACK_DEPTH[SP_W-1:0]) begin
                        stack_mem[box_tag*STACK_DEPTH + r_sp[box_tag]] <= r_far[box_tag];
                        r_sp[box_tag] <= r_sp[box_tag] + 1'b1;
                    end
                    r_node[box_tag] <= r_near[box_tag];
                    rstate[box_tag] <= RS_READY;
                end else if (r_sp[box_tag] != {SP_W{1'b0}}) begin
                    r_node[box_tag] <= stack_mem[box_tag*STACK_DEPTH + r_sp[box_tag] - 1];
                    r_sp[box_tag]   <= r_sp[box_tag] - 1'b1;
                    rstate[box_tag] <= RS_READY;
                end else begin
                    rstate[box_tag] <= RS_DONE;
                end
            end

            // 5. resolve triangle test
            if (tri_vo) begin
                if (tri_hit && (tri_t < r_ct[tri_tag])) begin
                    r_ct[tri_tag]   <= tri_t;
                    r_bu[tri_tag]   <= tri_u;
                    r_bv[tri_tag]   <= tri_v;
                    r_btri[tri_tag] <= r_node[tri_tag];  // pending tri id
                    r_bhit[tri_tag] <= 1'b1;
                end
                if (r_sp[tri_tag] != {SP_W{1'b0}}) begin
                    r_node[tri_tag] <= stack_mem[tri_tag*STACK_DEPTH + r_sp[tri_tag] - 1];
                    r_sp[tri_tag]   <= r_sp[tri_tag] - 1'b1;
                    rstate[tri_tag] <= RS_READY;
                end else begin
                    rstate[tri_tag] <= RS_DONE;
                end
            end

            // 6. stream out one finished ray per cycle
            if (dn_found) begin
                res_valid  <= 1'b1;
                res_ray_id <= r_id[dn_idx];
                res_hit    <= r_bhit[dn_idx];
                res_tri_id <= r_bhit[dn_idx] ? r_btri[dn_idx] : 32'h0;
                res_t      <= r_ct[dn_idx];
                res_u      <= r_bu[dn_idx];
                res_v      <= r_bv[dn_idx];
                rstate[dn_idx] <= RS_IDLE;
            end
        end
    end

endmodule
