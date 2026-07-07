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
 * Module: titan_x5_ray_triangle_isect
 * Description: Fully pipelined Möller-Trumbore ray-triangle intersection.
 *
 * Q16.16 signed fixed point throughout. One new ray-triangle test may be
 * issued every clock; results emerge LATENCY cycles later in order.
 *
 * The hit decision is division-free: with
 *   e1 = v1-v0, e2 = v2-v0, s = o-v0
 *   h  = d x e2, q = s x e1
 *   det = e1.h, u_num = s.h, v_num = d.q, t_num = e2.q
 * the ray hits iff (after negating everything when det < 0)
 *   det != 0, u_num >= 0, v_num >= 0, u_num+v_num <= det, t_num > 0.
 * Triangles are treated as double-sided (no backface culling).
 *
 * t/u/v are then recovered as num * (1/det) using a pipelined reciprocal:
 * normalize det to m in [1,2) (1.31), seed r0 = 24/17 - (8/17)m (max rel
 * error 1/17), three Newton-Raphson steps r' = r(2 - m r) -> ~1e-10 rel
 * error, denormalize, multiply. All products truncate like fx_mul so the
 * unit is exactly reproducible in software.
 *
 * Pipeline (14 stages, one 32x32 multiply level per stage):
 *   1  edge/offset subtract           8  NR1 r1 = r0(2-p)
 *   2  h = d x e2                     9  NR2 p = m*r1
 *   3  det, u_num, q = s x e1        10  NR2 r2
 *   4  v_num, t_num                  11  NR3 p = m*r2
 *   5  sign-normalize, hit test,     12  NR3 r3
 *      clz/normalize det             13  recip = (r3 << k) >> 29 (saturating)
 *   6  seed r0                       14  t/u/v = num * recip >> 16 (saturating)
 *   7  NR1 p = m*r0
 */
module titan_x5_ray_triangle_isect #(
    parameter W     = 32,   // Q16.16 fixed point
    parameter TAG_W = 8     // pass-through tag (ray slot id etc.)
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    valid_in,
    input  wire [TAG_W-1:0]        tag_in,

    // ray
    input  wire signed [W-1:0]     ray_o_x, ray_o_y, ray_o_z,
    input  wire signed [W-1:0]     ray_d_x, ray_d_y, ray_d_z,

    // triangle
    input  wire signed [W-1:0]     v0_x, v0_y, v0_z,
    input  wire signed [W-1:0]     v1_x, v1_y, v1_z,
    input  wire signed [W-1:0]     v2_x, v2_y, v2_z,

    output reg                     valid_out,
    output reg  [TAG_W-1:0]        tag_out,
    output reg                     is_hit,
    output reg  signed [W-1:0]     t_out,   // Q16.16 distance
    output reg  signed [W-1:0]     u_out,   // barycentric u
    output reg  signed [W-1:0]     v_out    // barycentric v
);

    localparam LATENCY = 14;

    // Newton-Raphson seed r0 = 24/17 - (8/17)*m, constants in 2.30
    localparam [31:0] NR_C1 = 32'd1515870810;  // round(24/17 * 2^30)
    localparam [31:0] NR_C2 = 32'd505290270;   // round( 8/17 * 2^30)

    // Q16.16 multiply: truncating, wrap-on-overflow (documented, and
    // reproduced exactly by the verification golden model).
    function automatic signed [W-1:0] fx_mul;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        reg signed [2*W-1:0] p;
        begin
            p = a * b;
            fx_mul = p[W+15:16];
        end
    endfunction

    // count leading zeros of a 32-bit value (32 when zero)
    function automatic [5:0] clz32;
        input [31:0] x;
        integer i;
        reg found;
        begin
            clz32 = 6'd32;
            found = 1'b0;
            for (i = 31; i >= 0; i = i - 1) begin
                if (!found && x[i]) begin
                    clz32 = 6'd31 - i[5:0];
                    found = 1'b1;
                end
            end
        end
    endfunction

    // ------------------------------------------------------------------
    // valid/tag pipeline
    // ------------------------------------------------------------------
    reg              vld [1:LATENCY-1];
    reg [TAG_W-1:0]  tag [1:LATENCY-1];

    // ------------------------------------------------------------------
    // stage 1: edges and ray offset
    // ------------------------------------------------------------------
    reg signed [W-1:0] s1_e1x, s1_e1y, s1_e1z;
    reg signed [W-1:0] s1_e2x, s1_e2y, s1_e2z;
    reg signed [W-1:0] s1_sx,  s1_sy,  s1_sz;
    reg signed [W-1:0] s1_dx,  s1_dy,  s1_dz;

    // stage 2: h = d x e2
    reg signed [W-1:0] s2_hx, s2_hy, s2_hz;
    reg signed [W-1:0] s2_e1x, s2_e1y, s2_e1z;
    reg signed [W-1:0] s2_e2x, s2_e2y, s2_e2z;
    reg signed [W-1:0] s2_sx, s2_sy, s2_sz;
    reg signed [W-1:0] s2_dx, s2_dy, s2_dz;

    // stage 3: det, u_num, q = s x e1
    reg signed [W-1:0] s3_det, s3_unum;
    reg signed [W-1:0] s3_qx, s3_qy, s3_qz;
    reg signed [W-1:0] s3_e2x, s3_e2y, s3_e2z;
    reg signed [W-1:0] s3_dx, s3_dy, s3_dz;

    // stage 4: v_num, t_num
    reg signed [W-1:0] s4_det, s4_unum, s4_vnum, s4_tnum;

    // stage 5: sign-normalized numerators, hit decision, det normalization
    reg                s5_hit;
    reg        [W-1:0] s5_unum, s5_vnum, s5_tnum;  // non-negative on hits
    reg        [W-1:0] s5_m;                       // det normalized to 1.31
    reg        [5:0]   s5_k;                       // clz(|det|)

    // stages 6..12: Newton-Raphson reciprocal of m (2.30)
    reg                s6_hit;  reg [W-1:0] s6_unum, s6_vnum, s6_tnum, s6_m;  reg [5:0] s6_k;  reg [W-1:0] s6_r;
    reg                s7_hit;  reg [W-1:0] s7_unum, s7_vnum, s7_tnum, s7_m;  reg [5:0] s7_k;  reg [W-1:0] s7_r, s7_p;
    reg                s8_hit;  reg [W-1:0] s8_unum, s8_vnum, s8_tnum, s8_m;  reg [5:0] s8_k;  reg [W-1:0] s8_r;
    reg                s9_hit;  reg [W-1:0] s9_unum, s9_vnum, s9_tnum, s9_m;  reg [5:0] s9_k;  reg [W-1:0] s9_r, s9_p;
    reg                s10_hit; reg [W-1:0] s10_unum, s10_vnum, s10_tnum, s10_m; reg [5:0] s10_k; reg [W-1:0] s10_r;
    reg                s11_hit; reg [W-1:0] s11_unum, s11_vnum, s11_tnum;        reg [5:0] s11_k; reg [W-1:0] s11_r, s11_p;
    reg                s12_hit; reg [W-1:0] s12_unum, s12_vnum, s12_tnum;        reg [5:0] s12_k; reg [W-1:0] s12_r;

    // stage 13: reciprocal in Q16.16 (saturating)
    reg                s13_hit;
    reg        [W-1:0] s13_unum, s13_vnum, s13_tnum;
    reg        [W-1:0] s13_recip;

    // ------------------------------------------------------------------
    // stage 5 combinational: normalize sign, hit test, clz
    // ------------------------------------------------------------------
    wire               det_neg  = s4_det[W-1];
    wire signed [W-1:0] n_det   = det_neg ? -s4_det  : s4_det;
    wire signed [W-1:0] n_unum  = det_neg ? -s4_unum : s4_unum;
    wire signed [W-1:0] n_vnum  = det_neg ? -s4_vnum : s4_vnum;
    wire signed [W-1:0] n_tnum  = det_neg ? -s4_tnum : s4_tnum;
    wire signed [W:0]   uv_sum  = n_unum + n_vnum;   // 33-bit, no overflow
    wire                hit_c   = (s4_det != {W{1'b0}}) &&
                                  !n_unum[W-1] && !n_vnum[W-1] &&
                                  (uv_sum <= {1'b0, n_det}) &&
                                  (n_tnum > 0);
    wire [5:0]          k_c     = clz32(n_det);

    // NR helper products (each one 32x32 multiply level)
    wire [63:0] seed_prod = NR_C2 * s5_m;                       // 2.30 * 1.31
    wire [31:0] seed_r0   = NR_C1 - seed_prod[62:31];
    wire [63:0] p1_prod   = s6_m * s6_r;
    wire [63:0] r1_prod   = s7_r * (32'h8000_0000 - s7_p);      // r*(2-p), 2 in 2.30 = 2^31
    wire [63:0] p2_prod   = s8_m * s8_r;
    wire [63:0] r2_prod   = s9_r * (32'h8000_0000 - s9_p);
    wire [63:0] p3_prod   = s10_m * s10_r;
    wire [63:0] r3_prod   = s11_r * (32'h8000_0000 - s11_p);

    // stage 13: recip_q16 = (r3 << k) >> 29, saturating to 32 bits
    wire [63:0] recip_wide = ({32'b0, s12_r} << s12_k) >> 29;
    wire [31:0] recip_sat  = (|recip_wide[63:32]) ? 32'hFFFF_FFFF : recip_wide[31:0];

    // stage 14: outputs = num * recip >> 16, saturating to Q16.16 positive
    wire [63:0] t_wide = ({32'b0, s13_tnum} * {32'b0, s13_recip}) >> 16;
    wire [63:0] u_wide = ({32'b0, s13_unum} * {32'b0, s13_recip}) >> 16;
    wire [63:0] v_wide = ({32'b0, s13_vnum} * {32'b0, s13_recip}) >> 16;
    wire [31:0] t_sat  = (|t_wide[63:31]) ? 32'h7FFF_FFFF : t_wide[31:0];
    wire [31:0] u_sat  = (|u_wide[63:31]) ? 32'h7FFF_FFFF : u_wide[31:0];
    wire [31:0] v_sat  = (|v_wide[63:31]) ? 32'h7FFF_FFFF : v_wide[31:0];

    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (j = 1; j <= LATENCY-1; j = j + 1) begin
                vld[j] <= 1'b0;
                tag[j] <= {TAG_W{1'b0}};
            end
            valid_out <= 1'b0;
            tag_out   <= {TAG_W{1'b0}};
            is_hit    <= 1'b0;
            t_out     <= {W{1'b0}};
            u_out     <= {W{1'b0}};
            v_out     <= {W{1'b0}};
        end else begin
            // valid/tag conveyor
            vld[1] <= valid_in;
            tag[1] <= tag_in;
            for (j = 2; j <= LATENCY-1; j = j + 1) begin
                vld[j] <= vld[j-1];
                tag[j] <= tag[j-1];
            end

            // stage 1
            s1_e1x <= v1_x - v0_x;  s1_e1y <= v1_y - v0_y;  s1_e1z <= v1_z - v0_z;
            s1_e2x <= v2_x - v0_x;  s1_e2y <= v2_y - v0_y;  s1_e2z <= v2_z - v0_z;
            s1_sx  <= ray_o_x - v0_x;
            s1_sy  <= ray_o_y - v0_y;
            s1_sz  <= ray_o_z - v0_z;
            s1_dx  <= ray_d_x;  s1_dy <= ray_d_y;  s1_dz <= ray_d_z;

            // stage 2: h = d x e2
            s2_hx <= fx_mul(s1_dy, s1_e2z) - fx_mul(s1_dz, s1_e2y);
            s2_hy <= fx_mul(s1_dz, s1_e2x) - fx_mul(s1_dx, s1_e2z);
            s2_hz <= fx_mul(s1_dx, s1_e2y) - fx_mul(s1_dy, s1_e2x);
            s2_e1x <= s1_e1x; s2_e1y <= s1_e1y; s2_e1z <= s1_e1z;
            s2_e2x <= s1_e2x; s2_e2y <= s1_e2y; s2_e2z <= s1_e2z;
            s2_sx  <= s1_sx;  s2_sy  <= s1_sy;  s2_sz  <= s1_sz;
            s2_dx  <= s1_dx;  s2_dy  <= s1_dy;  s2_dz  <= s1_dz;

            // stage 3: det = e1.h, u_num = s.h, q = s x e1
            s3_det  <= fx_mul(s2_e1x, s2_hx) + fx_mul(s2_e1y, s2_hy) + fx_mul(s2_e1z, s2_hz);
            s3_unum <= fx_mul(s2_sx,  s2_hx) + fx_mul(s2_sy,  s2_hy) + fx_mul(s2_sz,  s2_hz);
            s3_qx <= fx_mul(s2_sy, s2_e1z) - fx_mul(s2_sz, s2_e1y);
            s3_qy <= fx_mul(s2_sz, s2_e1x) - fx_mul(s2_sx, s2_e1z);
            s3_qz <= fx_mul(s2_sx, s2_e1y) - fx_mul(s2_sy, s2_e1x);
            s3_e2x <= s2_e2x; s3_e2y <= s2_e2y; s3_e2z <= s2_e2z;
            s3_dx  <= s2_dx;  s3_dy  <= s2_dy;  s3_dz  <= s2_dz;

            // stage 4: v_num = d.q, t_num = e2.q
            s4_det  <= s3_det;
            s4_unum <= s3_unum;
            s4_vnum <= fx_mul(s3_dx,  s3_qx) + fx_mul(s3_dy,  s3_qy) + fx_mul(s3_dz,  s3_qz);
            s4_tnum <= fx_mul(s3_e2x, s3_qx) + fx_mul(s3_e2y, s3_qy) + fx_mul(s3_e2z, s3_qz);

            // stage 5: sign-normalize + hit decision + det normalization
            s5_hit  <= hit_c;
            s5_unum <= n_unum;
            s5_vnum <= n_vnum;
            s5_tnum <= n_tnum;
            if (n_det == {W{1'b0}}) begin
                s5_m <= 32'h8000_0000;  // benign value, hit already 0
                s5_k <= 6'd0;
            end else begin
                s5_m <= n_det << k_c;
                s5_k <= k_c;
            end

            // stage 6: NR seed
            s6_hit <= s5_hit; s6_unum <= s5_unum; s6_vnum <= s5_vnum; s6_tnum <= s5_tnum;
            s6_m <= s5_m; s6_k <= s5_k;
            s6_r <= seed_r0;

            // stages 7..12: three Newton-Raphson iterations
            s7_hit <= s6_hit; s7_unum <= s6_unum; s7_vnum <= s6_vnum; s7_tnum <= s6_tnum;
            s7_m <= s6_m; s7_k <= s6_k; s7_r <= s6_r;
            s7_p <= p1_prod[62:31];

            s8_hit <= s7_hit; s8_unum <= s7_unum; s8_vnum <= s7_vnum; s8_tnum <= s7_tnum;
            s8_m <= s7_m; s8_k <= s7_k;
            s8_r <= r1_prod[61:30];

            s9_hit <= s8_hit; s9_unum <= s8_unum; s9_vnum <= s8_vnum; s9_tnum <= s8_tnum;
            s9_m <= s8_m; s9_k <= s8_k; s9_r <= s8_r;
            s9_p <= p2_prod[62:31];

            s10_hit <= s9_hit; s10_unum <= s9_unum; s10_vnum <= s9_vnum; s10_tnum <= s9_tnum;
            s10_m <= s9_m; s10_k <= s9_k;
            s10_r <= r2_prod[61:30];

            s11_hit <= s10_hit; s11_unum <= s10_unum; s11_vnum <= s10_vnum; s11_tnum <= s10_tnum;
            s11_k <= s10_k; s11_r <= s10_r;
            s11_p <= p3_prod[62:31];

            s12_hit <= s11_hit; s12_unum <= s11_unum; s12_vnum <= s11_vnum; s12_tnum <= s11_tnum;
            s12_k <= s11_k;
            s12_r <= r3_prod[61:30];

            // stage 13: denormalized reciprocal
            s13_hit <= s12_hit; s13_unum <= s12_unum; s13_vnum <= s12_vnum; s13_tnum <= s12_tnum;
            s13_recip <= recip_sat;

            // stage 14: outputs
            valid_out <= vld[LATENCY-1];
            tag_out   <= tag[LATENCY-1];
            is_hit    <= s13_hit;
            t_out     <= s13_hit ? t_sat : {W{1'b0}};
            u_out     <= s13_hit ? u_sat : {W{1'b0}};
            v_out     <= s13_hit ? v_sat : {W{1'b0}};
        end
    end

endmodule
