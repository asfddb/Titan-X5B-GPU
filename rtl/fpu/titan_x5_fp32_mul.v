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
 * Titan X5 GPU - IEEE-754 Single-Precision Floating-Point Multiplier
 *
 * Fully compliant FP32 multiplication, 3-stage pipeline:
 *   S1: unpack, classify specials, subnormal pre-normalization (CLZ +
 *       left-shift so downstream logic always sees a normalized mantissa),
 *       exponent computation in a signed domain.
 *   S2: 24x24 mantissa multiply.
 *   S3: normalize, denormalize-on-underflow (gradual underflow), round
 *       (4 IEEE modes), overflow handling, pack.
 *
 * Features:
 *   - Subnormal inputs (pre-normalization stage) and subnormal outputs.
 *   - NaN propagation (canonical qNaN 0x7FC00000), sNaN raises invalid.
 *   - Inf * 0 -> qNaN + invalid; Inf * finite -> Inf.
 *   - Rounding modes: 00 RNE, 01 RTZ, 10 RDN, 11 RUP.
 *   - Exception flags: invalid, overflow, underflow, inexact.
 *
 * Latency: 3 cycles when en=1. `en` gates all pipeline registers (stall).
 */
module titan_x5_fp32_mul (
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
    // Stage 1: unpack / classify / pre-normalize subnormals
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

    wire sign_res = sa ^ sb;

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
        end else if ((a_inf && b_zero) || (a_zero && b_inf)) begin
            s1_special     = 1'b1;
            s1_special_res = QNAN;
            s1_invalid     = 1'b1;
        end else if (a_inf || b_inf) begin
            s1_special     = 1'b1;
            s1_special_res = {sign_res, 8'hFF, 23'd0};
        end else if (a_zero || b_zero) begin
            s1_special     = 1'b1;
            s1_special_res = {sign_res, 31'd0};
        end
    end

    // subnormal pre-normalization: shift the mantissa up until the hidden
    // bit position is 1, compensating in the (signed) exponent
    wire [23:0] ma_raw = {(ea != 0), fa};
    wire [23:0] mb_raw = {(eb != 0), fb};

    integer i;
    reg [4:0] clz_a, clz_b;
    always @(*) begin
        clz_a = 5'd0;
        for (i = 0; i <= 23; i = i + 1)
            if (ma_raw[i]) clz_a = 5'd23 - i[4:0];
        clz_b = 5'd0;
        for (i = 0; i <= 23; i = i + 1)
            if (mb_raw[i]) clz_b = 5'd23 - i[4:0];
    end

    wire [23:0] ma_n = ma_raw << clz_a;
    wire [23:0] mb_n = mb_raw << clz_b;

    // effective exponents: normal e, subnormal 1 - clz
    wire signed [10:0] ea_eff = (ea == 0) ? (11'sd1 - {6'd0, clz_a})
                                          : {3'd0, ea};
    wire signed [10:0] eb_eff = (eb == 0) ? (11'sd1 - {6'd0, clz_b})
                                          : {3'd0, eb};
    wire signed [10:0] exp_sum = ea_eff + eb_eff - 11'sd127;

    reg               p1_valid;
    reg               p1_special, p1_invalid;
    reg  [31:0]       p1_special_res;
    reg               p1_sign;
    reg signed [10:0] p1_exp;
    reg  [23:0]       p1_ma, p1_mb;
    reg  [1:0]        p1_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p1_valid <= 1'b0;
            p1_special <= 1'b0; p1_invalid <= 1'b0; p1_special_res <= 32'd0;
            p1_sign <= 1'b0; p1_exp <= 11'sd0;
            p1_ma <= 24'd0; p1_mb <= 24'd0; p1_rm <= 2'd0;
        end else if (en) begin
            p1_valid       <= valid_in;
            p1_special     <= s1_special;
            p1_invalid     <= s1_invalid;
            p1_special_res <= s1_special_res;
            p1_sign        <= sign_res;
            p1_exp         <= exp_sum;
            p1_ma          <= ma_n;
            p1_mb          <= mb_n;
            p1_rm          <= rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 2: mantissa multiply
    // ------------------------------------------------------------------
    wire [47:0] prod = p1_ma * p1_mb;

    reg               p2_valid;
    reg               p2_special, p2_invalid;
    reg  [31:0]       p2_special_res;
    reg               p2_sign;
    reg signed [10:0] p2_exp;
    reg  [47:0]       p2_prod;
    reg  [1:0]        p2_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p2_valid <= 1'b0;
            p2_special <= 1'b0; p2_invalid <= 1'b0; p2_special_res <= 32'd0;
            p2_sign <= 1'b0; p2_exp <= 11'sd0; p2_prod <= 48'd0; p2_rm <= 2'd0;
        end else if (en) begin
            p2_valid       <= p1_valid;
            p2_special     <= p1_special;
            p2_invalid     <= p1_invalid;
            p2_special_res <= p1_special_res;
            p2_sign        <= p1_sign;
            p2_exp         <= p1_exp;
            p2_prod        <= prod;
            p2_rm          <= p1_rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 3: normalize / denormalize / round / pack
    // ------------------------------------------------------------------
    reg  [23:0]       mant_n;
    reg               g_n, st_n;
    reg signed [10:0] exp_n;
    reg  [25:0]       den_src;      // {mant, g, st} for denormal shifting
    reg  [25:0]       den_shifted;
    reg signed [10:0] den_amt;
    reg  [23:0]       mant_d;
    reg               rb, st;
    reg               rnd_inc;
    reg  [24:0]       mant_r;
    reg signed [10:0] exp_r;
    reg  [31:0]       res_c;
    reg               inv_c, ovf_c, unf_c, inx_c;
    reg               tiny;
    integer           j;

    always @(*) begin
        mant_n = 24'd0; g_n = 1'b0; st_n = 1'b0; exp_n = 11'sd0;
        den_src = 26'd0; den_shifted = 26'd0; den_amt = 11'sd0;
        mant_d = 24'd0; rb = 1'b0; st = 1'b0; rnd_inc = 1'b0;
        mant_r = 25'd0; exp_r = 11'sd0;
        res_c = 32'd0; inv_c = 1'b0; ovf_c = 1'b0; unf_c = 1'b0; inx_c = 1'b0;
        tiny = 1'b0;

        if (p2_special) begin
            res_c = p2_special_res;
            inv_c = p2_invalid;
        end else begin
            // product of two normalized 24-bit mantissas: [2^46, 2^48)
            if (p2_prod[47]) begin
                mant_n = p2_prod[47:24];
                g_n    = p2_prod[23];
                st_n   = |p2_prod[22:0];
                exp_n  = p2_exp + 11'sd1;
            end else begin
                mant_n = p2_prod[46:23];
                g_n    = p2_prod[22];
                st_n   = |p2_prod[21:0];
                exp_n  = p2_exp;
            end

            tiny = (exp_n < 11'sd1);
            if (tiny) begin
                // gradual underflow: shift right by (1 - exp), collect sticky
                den_amt = 11'sd1 - exp_n;
                if (den_amt > 11'sd26) den_amt = 11'sd26;
                den_src = {mant_n, g_n, st_n};
                den_shifted = den_src >> den_amt[4:0];
                // sticky: OR of everything shifted out
                st = st_n;
                for (j = 0; j < 26; j = j + 1) begin
                    if (j < den_amt) st = st | den_src[j];
                end
                mant_d = den_shifted[25:2];
                rb     = den_shifted[1];
                st     = st | den_shifted[0];
                exp_r  = 11'sd1;
            end else begin
                mant_d = mant_n;
                rb     = g_n;
                st     = st_n;
                exp_r  = exp_n;
            end

            case (p2_rm)
                RM_RNE: rnd_inc = rb && (st || mant_d[0]);
                RM_RTZ: rnd_inc = 1'b0;
                RM_RDN: rnd_inc = p2_sign && (rb || st);
                RM_RUP: rnd_inc = !p2_sign && (rb || st);
                default: rnd_inc = 1'b0;
            endcase
            mant_r = {1'b0, mant_d} + {24'd0, rnd_inc};
            if (mant_r[24]) begin
                mant_r = mant_r >> 1;
                exp_r  = exp_r + 11'sd1;
            end

            inx_c = rb | st;

            if (exp_r >= 11'sd255 && mant_r[23]) begin
                ovf_c = 1'b1;
                inx_c = 1'b1;
                case (p2_rm)
                    RM_RNE: res_c = {p2_sign, 8'hFF, 23'd0};
                    RM_RTZ: res_c = {p2_sign, 8'hFE, {23{1'b1}}};
                    RM_RDN: res_c = p2_sign ? {1'b1, 8'hFF, 23'd0}
                                            : {1'b0, 8'hFE, {23{1'b1}}};
                    default: res_c = p2_sign ? {1'b1, 8'hFE, {23{1'b1}}}
                                             : {1'b0, 8'hFF, 23'd0};
                endcase
            end else begin
                res_c = {p2_sign,
                         mant_r[23] ? exp_r[7:0] : 8'd0,
                         mant_r[22:0]};
                unf_c = tiny && inx_c && !mant_r[23];
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
