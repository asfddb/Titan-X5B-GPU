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
 * Module: titan_x5_ray_box_isect
 * Description: Fully pipelined ray-AABB slab test. Q16.16 fixed point.
 *
 * Accepts one new ray-box test EVERY clock cycle; the answer emerges
 * LATENCY (= 4) cycles later, in order, with the caller's tag.
 *
 * The caller supplies precomputed reciprocal directions inv_d = 1/d in
 * Q16.16 (saturate to 0x7FFFFFFF for zero components). t_max_in is the
 * current closest-hit distance, used to prune boxes entirely behind the
 * best hit so far.
 *
 * Pipeline:
 *   1  d0 = bmin - o, d1 = bmax - o        (subtract)
 *   2  t1 = d0 * inv_d, t2 = d1 * inv_d    (six Q16.16 multiplies)
 *   3  per-axis slab min/max               (compare/select)
 *   4  tmin = max of mins, tmax = min of maxes,
 *      hit = tmin <= tmax && tmax >= 0 && tmin <= t_max
 */
module titan_x5_ray_box_isect #(
    parameter W     = 32,   // Q16.16 fixed point
    parameter TAG_W = 8
)(
    input  wire                clk,
    input  wire                rst_n,

    input  wire                valid_in,
    input  wire [TAG_W-1:0]    tag_in,

    input  wire signed [W-1:0] ray_o_x,     ray_o_y,     ray_o_z,
    input  wire signed [W-1:0] ray_inv_d_x, ray_inv_d_y, ray_inv_d_z,
    input  wire signed [W-1:0] t_max_in,

    input  wire signed [W-1:0] box_min_x, box_min_y, box_min_z,
    input  wire signed [W-1:0] box_max_x, box_max_y, box_max_z,

    output reg                 valid_out,
    output reg  [TAG_W-1:0]    tag_out,
    output reg                 box_hit,
    output reg  signed [W-1:0] t_entry_out   // slab entry distance (tmin)
);

    localparam LATENCY = 4;

    function automatic signed [W-1:0] fx_mul;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        reg signed [2*W-1:0] p;
        begin
            p = a * b;
            fx_mul = p[W+15:16];
        end
    endfunction

    function automatic signed [W-1:0] min2;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        begin
            min2 = (a < b) ? a : b;
        end
    endfunction

    function automatic signed [W-1:0] max2;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        begin
            max2 = (a > b) ? a : b;
        end
    endfunction

    reg             vld [1:LATENCY-1];
    reg [TAG_W-1:0] tag [1:LATENCY-1];

    // stage 1
    reg signed [W-1:0] s1_d0x, s1_d0y, s1_d0z;
    reg signed [W-1:0] s1_d1x, s1_d1y, s1_d1z;
    reg signed [W-1:0] s1_ix, s1_iy, s1_iz;
    reg signed [W-1:0] s1_tmax;

    // stage 2
    reg signed [W-1:0] s2_t1x, s2_t1y, s2_t1z;
    reg signed [W-1:0] s2_t2x, s2_t2y, s2_t2z;
    reg signed [W-1:0] s2_tmax;

    // stage 3
    reg signed [W-1:0] s3_minx, s3_miny, s3_minz;
    reg signed [W-1:0] s3_maxx, s3_maxy, s3_maxz;
    reg signed [W-1:0] s3_tmax;

    wire signed [W-1:0] tmin_c = max2(max2(s3_minx, s3_miny), s3_minz);
    wire signed [W-1:0] tmax_c = min2(min2(s3_maxx, s3_maxy), s3_maxz);
    wire                hit_c  = (tmin_c <= tmax_c) &&
                                 !tmax_c[W-1] &&
                                 (tmin_c <= s3_tmax);

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 1; j <= LATENCY-1; j = j + 1) begin
                vld[j] <= 1'b0;
                tag[j] <= {TAG_W{1'b0}};
            end
            valid_out   <= 1'b0;
            tag_out     <= {TAG_W{1'b0}};
            box_hit     <= 1'b0;
            t_entry_out <= {W{1'b0}};
        end else begin
            vld[1] <= valid_in;
            tag[1] <= tag_in;
            for (j = 2; j <= LATENCY-1; j = j + 1) begin
                vld[j] <= vld[j-1];
                tag[j] <= tag[j-1];
            end

            // stage 1
            s1_d0x <= box_min_x - ray_o_x;
            s1_d0y <= box_min_y - ray_o_y;
            s1_d0z <= box_min_z - ray_o_z;
            s1_d1x <= box_max_x - ray_o_x;
            s1_d1y <= box_max_y - ray_o_y;
            s1_d1z <= box_max_z - ray_o_z;
            s1_ix  <= ray_inv_d_x;
            s1_iy  <= ray_inv_d_y;
            s1_iz  <= ray_inv_d_z;
            s1_tmax <= t_max_in;

            // stage 2
            s2_t1x <= fx_mul(s1_d0x, s1_ix);
            s2_t1y <= fx_mul(s1_d0y, s1_iy);
            s2_t1z <= fx_mul(s1_d0z, s1_iz);
            s2_t2x <= fx_mul(s1_d1x, s1_ix);
            s2_t2y <= fx_mul(s1_d1y, s1_iy);
            s2_t2z <= fx_mul(s1_d1z, s1_iz);
            s2_tmax <= s1_tmax;

            // stage 3
            s3_minx <= min2(s2_t1x, s2_t2x);
            s3_maxx <= max2(s2_t1x, s2_t2x);
            s3_miny <= min2(s2_t1y, s2_t2y);
            s3_maxy <= max2(s2_t1y, s2_t2y);
            s3_minz <= min2(s2_t1z, s2_t2z);
            s3_maxz <= max2(s2_t1z, s2_t2z);
            s3_tmax <= s2_tmax;

            // stage 4
            valid_out   <= vld[LATENCY-1];
            tag_out     <= tag[LATENCY-1];
            box_hit     <= hit_c;
            t_entry_out <= tmin_c;
        end
    end

endmodule
