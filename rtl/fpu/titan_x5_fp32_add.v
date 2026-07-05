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
 * Titan X5 GPU - IEEE-754 Single-Precision Floating-Point Adder
 *
 * Fully compliant FP32 addition, 3-stage pipeline:
 *   S1: unpack, classify specials, magnitude swap, alignment shift with
 *       sticky collection (subnormal inputs handled via effective exponent).
 *   S2: mantissa add / subtract (borrow-corrected sticky for subtraction).
 *   S3: normalize, round (4 IEEE modes), overflow/underflow handling, pack.
 *
 * Features:
 *   - Subnormal inputs and gradual-underflow (subnormal) outputs.
 *   - NaN propagation (canonical qNaN 0x7FC00000), sNaN raises invalid.
 *   - (+Inf) + (-Inf) -> qNaN + invalid.
 *   - Signed-zero semantics incl. exact-cancellation sign (RDN gives -0).
 *   - Rounding modes: 00 RNE (nearest-even), 01 RTZ, 10 RDN, 11 RUP.
 *   - Exception flags: invalid, overflow, underflow, inexact.
 *
 * Latency: 3 cycles when en=1. `en` gates all pipeline registers (stall).
 */
module titan_x5_fp32_add (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        valid_in,
    input  wire [1:0]  rm,
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg         valid_out,
    output reg  [31:0] result,
    output reg         flag_invalid,
    output reg         flag_overflow,
    output reg         flag_underflow,
    output reg         flag_inexact
);

    localparam RM_RNE = 2'b00;
    localparam RM_RTZ = 2'b01;
    localparam RM_RDN = 2'b10;
    localparam RM_RUP = 2'b11;

    localparam [31:0] QNAN = 32'h7FC00000;

    // ------------------------------------------------------------------
    // Stage 1: unpack / classify / swap / align
    // ------------------------------------------------------------------
    wire        sa = a[31],       sb = b[31];
    wire [7:0]  ea = a[30:23],    eb = b[30:23];
    wire [22:0] fa = a[22:0],     fb = b[22:0];

    wire a_nan  = (ea == 8'hFF) && (fa != 0);
    wire b_nan  = (eb == 8'hFF) && (fb != 0);
    wire a_snan = a_nan && !fa[22];
    wire b_snan = b_nan && !fb[22];
    wire a_inf  = (ea == 8'hFF) && (fa == 0);
    wire b_inf  = (eb == 8'hFF) && (fb == 0);
    wire a_zero = (ea == 0) && (fa == 0);
    wire b_zero = (eb == 0) && (fb == 0);

    // special-case resolution
    reg        s1_special;
    reg [31:0] s1_special_res;
    reg        s1_invalid;
    always @(*) begin
        s1_special     = 1'b0;
        s1_special_res = 32'd0;
        s1_invalid     = 1'b0;
        if (a_nan || b_nan) begin
            s1_special     = 1'b1;
            s1_special_res = QNAN;
            s1_invalid     = a_snan || b_snan;
        end else if (a_inf && b_inf) begin
            s1_special = 1'b1;
            if (sa != sb) begin
                s1_special_res = QNAN;   // Inf - Inf
                s1_invalid     = 1'b1;
            end else begin
                s1_special_res = {sa, 8'hFF, 23'd0};
            end
        end else if (a_inf) begin
            s1_special     = 1'b1;
            s1_special_res = {sa, 8'hFF, 23'd0};
        end else if (b_inf) begin
            s1_special     = 1'b1;
            s1_special_res = {sb, 8'hFF, 23'd0};
        end else if (a_zero && b_zero) begin
            s1_special = 1'b1;
            // same sign keeps it; opposite signs: +0 except RDN -> -0
            if (sa == sb)
                s1_special_res = {sa, 31'd0};
            else
                s1_special_res = {(rm == RM_RDN), 31'd0};
        end
    end

    // magnitude ordering (bit-pattern compare of {exp,frac} is monotonic)
    wire a_ge_b = {ea, fa} >= {eb, fb};

    wire        sx    = a_ge_b ? sa : sb;
    wire        sy    = a_ge_b ? sb : sa;
    wire [7:0]  ex_r  = a_ge_b ? ea : eb;
    wire [7:0]  ey_r  = a_ge_b ? eb : ea;
    wire [22:0] fx    = a_ge_b ? fa : fb;
    wire [22:0] fy    = a_ge_b ? fb : fa;

    // effective exponents (subnormals use exponent 1 with hidden bit 0)
    wire [7:0]  ex_eff = (ex_r == 0) ? 8'd1 : ex_r;
    wire [7:0]  ey_eff = (ey_r == 0) ? 8'd1 : ey_r;
    wire [23:0] mx     = {(ex_r != 0), fx};
    wire [23:0] my     = {(ey_r != 0), fy};

    wire [7:0] exp_diff = ex_eff - ey_eff;

    // 27-bit datapath: [26:3] mantissa, [2] guard, [1] round, [0] sticky pos
    // The shift is clamped at 27: for any larger exponent difference the
    // smaller operand lies entirely below the sticky position, and clamping
    // keeps every shifted-out bit inside y_wide[26:0] so the sticky is
    // never lost (a >54 shift would discard the bits entirely).
    wire [7:0]  d_clamp = (exp_diff > 8'd27) ? 8'd27 : exp_diff;
    wire [26:0] x_ext = {mx, 3'b000};
    wire [53:0] y_wide = {my, 3'b000, 27'd0} >> d_clamp;
    wire [26:0] y_ext      = y_wide[53:27];
    wire        sticky_pre = |y_wide[26:0];

    wire eff_sub = sx ^ sy;

    // S1/S2 pipeline registers
    reg         p1_valid;
    reg         p1_special, p1_invalid;
    reg  [31:0] p1_special_res;
    reg         p1_sx, p1_eff_sub, p1_sticky;
    reg  [7:0]  p1_exp;
    reg  [26:0] p1_x, p1_y;
    reg  [1:0]  p1_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p1_valid <= 1'b0;
            p1_special <= 1'b0; p1_invalid <= 1'b0; p1_special_res <= 32'd0;
            p1_sx <= 1'b0; p1_eff_sub <= 1'b0; p1_sticky <= 1'b0;
            p1_exp <= 8'd0; p1_x <= 27'd0; p1_y <= 27'd0; p1_rm <= 2'd0;
        end else if (en) begin
            p1_valid       <= valid_in;
            p1_special     <= s1_special;
            p1_invalid     <= s1_invalid;
            p1_special_res <= s1_special_res;
            p1_sx          <= sx;
            p1_eff_sub     <= eff_sub;
            p1_sticky      <= sticky_pre;
            p1_exp         <= ex_eff;
            p1_x           <= x_ext;
            p1_y           <= y_ext;
            p1_rm          <= rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 2: mantissa add/sub with borrow-corrected sticky
    // ------------------------------------------------------------------
    // For subtraction, the discarded alignment residue s (0 < s < 1 ulp of
    // bit0) makes the true result X - Y - s = (X - Y - 1) + (1 - s); the
    // datapath value is decremented and sticky stays set - exact for
    // round-bit/sticky purposes.
    wire [27:0] sum_add = {1'b0, p1_x} + {1'b0, p1_y};
    wire [27:0] sum_sub = {1'b0, p1_x} - {1'b0, p1_y} - {27'd0, p1_sticky};
    wire [27:0] sum     = p1_eff_sub ? sum_sub : sum_add;

    reg         p2_valid;
    reg         p2_special, p2_invalid;
    reg  [31:0] p2_special_res;
    reg         p2_sx, p2_sticky;
    reg  [7:0]  p2_exp;
    reg  [27:0] p2_sum;
    reg  [1:0]  p2_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p2_valid <= 1'b0;
            p2_special <= 1'b0; p2_invalid <= 1'b0; p2_special_res <= 32'd0;
            p2_sx <= 1'b0; p2_sticky <= 1'b0;
            p2_exp <= 8'd0; p2_sum <= 28'd0; p2_rm <= 2'd0;
        end else if (en) begin
            p2_valid       <= p1_valid;
            p2_special     <= p1_special;
            p2_invalid     <= p1_invalid;
            p2_special_res <= p1_special_res;
            p2_sx          <= p1_sx;
            p2_sticky      <= p1_sticky;
            p2_exp         <= p1_exp;
            p2_sum         <= sum;
            p2_rm          <= p1_rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 3: normalize / round / pack
    // ------------------------------------------------------------------
    integer i;
    reg [4:0]  lz;
    reg [26:0] norm;
    reg [9:0]  exp_n;         // signed headroom (never goes negative here)
    reg        sticky_n;
    reg [23:0] mant_n;
    reg        rb, st;
    reg        rnd_inc;
    reg [24:0] mant_r;
    reg [9:0]  exp_r;
    reg [31:0] res_c;
    reg        inv_c, ovf_c, unf_c, inx_c;
    reg        is_zero_res;
    reg [4:0]  shift_lim;

    always @(*) begin
        // defaults
        lz = 5'd0; norm = 27'd0; exp_n = {2'b00, p2_exp}; sticky_n = p2_sticky;
        mant_n = 24'd0; rb = 1'b0; st = 1'b0; rnd_inc = 1'b0;
        mant_r = 25'd0; exp_r = 10'd0;
        res_c = 32'd0; inv_c = 1'b0; ovf_c = 1'b0; unf_c = 1'b0; inx_c = 1'b0;
        is_zero_res = 1'b0; shift_lim = 5'd0;

        if (p2_special) begin
            res_c = p2_special_res;
            inv_c = p2_invalid;
        end else if (p2_sum == 28'd0 && !p2_sticky) begin
            // exact cancellation: +0, except RDN -> -0
            is_zero_res = 1'b1;
            res_c = {(p2_rm == RM_RDN), 31'd0};
        end else begin
            // normalize
            if (p2_sum[27]) begin
                norm     = p2_sum[27:1];
                sticky_n = p2_sticky | p2_sum[0];
                exp_n    = {2'b00, p2_exp} + 10'd1;
            end else begin
                // count leading zeros from bit 26 (upward loop: the final
                // assignment corresponds to the highest set bit)
                lz = 5'd0;
                for (i = 0; i <= 26; i = i + 1) begin
                    if (p2_sum[i]) lz = 5'd26 - i[4:0];
                end
                // cannot shift the exponent below 1 (subnormal floor)
                shift_lim = (({5'd0, p2_exp} - 10'd1) > 10'd26) ? 5'd26
                          : (p2_exp[4:0] - 5'd1);
                if (p2_exp > 8'd27) shift_lim = 5'd26;
                if (lz > shift_lim) lz = shift_lim;
                norm     = p2_sum[26:0] << lz;
                sticky_n = p2_sticky;
                exp_n    = {2'b00, p2_exp} - {5'd0, lz};
            end

            // rounding
            mant_n = norm[26:3];
            rb     = norm[2];
            st     = norm[1] | norm[0] | sticky_n;
            case (p2_rm)
                RM_RNE: rnd_inc = rb && (st || mant_n[0]);
                RM_RTZ: rnd_inc = 1'b0;
                RM_RDN: rnd_inc = p2_sx && (rb || st);
                RM_RUP: rnd_inc = !p2_sx && (rb || st);
                default: rnd_inc = 1'b0;
            endcase
            mant_r = {1'b0, mant_n} + {24'd0, rnd_inc};
            exp_r  = exp_n;
            if (mant_r[24]) begin
                mant_r = mant_r >> 1;
                exp_r  = exp_r + 10'd1;
            end

            inx_c = rb | st;

            if (exp_r >= 10'd255 && mant_r[23]) begin
                // overflow
                ovf_c = 1'b1;
                inx_c = 1'b1;
                case (p2_rm)
                    RM_RNE: res_c = {p2_sx, 8'hFF, 23'd0};
                    RM_RTZ: res_c = {p2_sx, 8'hFE, {23{1'b1}}};
                    RM_RDN: res_c = p2_sx ? {1'b1, 8'hFF, 23'd0}
                                          : {1'b0, 8'hFE, {23{1'b1}}};
                    default: res_c = p2_sx ? {1'b1, 8'hFE, {23{1'b1}}}
                                           : {1'b0, 8'hFF, 23'd0};
                endcase
            end else begin
                // hidden-bit encoding: subnormal when MSB is 0 (exp_r == 1)
                res_c = {p2_sx,
                         mant_r[23] ? exp_r[7:0] : 8'd0,
                         mant_r[22:0]};
                unf_c = !mant_r[23] && inx_c; // tiny and inexact
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_out      <= 1'b0;
            result         <= 32'd0;
            flag_invalid   <= 1'b0;
            flag_overflow  <= 1'b0;
            flag_underflow <= 1'b0;
            flag_inexact   <= 1'b0;
        end else if (en) begin
            valid_out      <= p2_valid;
            result         <= res_c;
            flag_invalid   <= inv_c;
            flag_overflow  <= ovf_c;
            flag_underflow <= unf_c;
            flag_inexact   <= inx_c;
        end
    end

endmodule
