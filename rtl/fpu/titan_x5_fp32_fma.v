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
 * Titan X5 GPU - IEEE-754 Single-Precision Fused Multiply-Add
 *
 * Computes round(a*b + c) with a SINGLE rounding (true fused FMA),
 * replacing the previous round(round(a*b) + c) cascade. 6-stage pipeline:
 *   S1: unpack, classify specials, subnormal pre-normalization (CLZ).
 *   S2: 24x24 mantissa multiply; addend alignment-shift computation.
 *   S3: align the addend into a 104-bit fixed-point frame anchored on the
 *       exact product (product ULP at frame bit 28), collecting sticky for
 *       bits shifted below the frame. The shift saturates at [-24, +80]:
 *       beyond either bound the smaller operand only contributes to the
 *       round/sticky bits, which the saturated placement preserves exactly.
 *   S4: signed magnitude add/subtract over the {frame, sticky} pair.
 *   S5: count leading zeros over the 106-bit sum and normalize.
 *   S6: denormalize-on-underflow, round (4 IEEE modes), pack, flags.
 *
 * Special-value rules (mirrored by the tb/uvm/fp_ref.py oracle):
 *   - any NaN in -> canonical qNaN; invalid if any sNaN.
 *   - 0*Inf raises invalid and returns qNaN even when the addend is a
 *     quiet NaN (RISC-V convention).
 *   - Inf product + opposite-signed Inf addend -> qNaN + invalid.
 *   - exact zero sum (cancellation or 0+0 of opposite signs): +0, or -0
 *     under RDN.
 *
 * Latency: 6 cycles when en=1. `en` gates all pipeline registers (stall).
 */
module titan_x5_fp32_fma (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire        valid_in,
    input  wire [1:0]  rm,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,
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
    wire        sa = a[31],       sb = b[31],       sc = c[31];
    wire [7:0]  ea = a[30:23],    eb = b[30:23],    ec = c[30:23];
    wire [22:0] fa = a[22:0],     fb = b[22:0],     fc = c[22:0];

    wire a_nan  = (ea == 8'hFF) && (fa != 0);
    wire b_nan  = (eb == 8'hFF) && (fb != 0);
    wire c_nan  = (ec == 8'hFF) && (fc != 0);
    wire a_snan = a_nan && !fa[22];
    wire b_snan = b_nan && !fb[22];
    wire c_snan = c_nan && !fc[22];
    wire a_inf  = (ea == 8'hFF) && (fa == 0);
    wire b_inf  = (eb == 8'hFF) && (fb == 0);
    wire c_inf  = (ec == 8'hFF) && (fc == 0);
    wire a_zero = (ea == 0) && (fa == 0);
    wire b_zero = (eb == 0) && (fb == 0);
    wire c_zero = (ec == 0) && (fc == 0);

    wire ps = sa ^ sb;              // product sign
    wire mul_inv_pair = (a_inf && b_zero) || (a_zero && b_inf);

    reg        s1_special;
    reg [31:0] s1_special_res;
    reg        s1_invalid;
    always @(*) begin
        s1_special     = 1'b0;
        s1_special_res = 32'd0;
        s1_invalid     = 1'b0;
        if (a_nan || b_nan || c_nan) begin
            s1_special     = 1'b1;
            s1_special_res = QNAN;
            s1_invalid     = a_snan || b_snan || c_snan || mul_inv_pair;
        end else if (mul_inv_pair) begin
            s1_special     = 1'b1;
            s1_special_res = QNAN;
            s1_invalid     = 1'b1;
        end else if (a_inf || b_inf) begin
            s1_special = 1'b1;
            if (c_inf && (sc != ps)) begin
                s1_special_res = QNAN;
                s1_invalid     = 1'b1;
            end else begin
                s1_special_res = {ps, 8'hFF, 23'd0};
            end
        end else if (c_inf) begin
            s1_special     = 1'b1;
            s1_special_res = {sc, 8'hFF, 23'd0};
        end else if (a_zero || b_zero) begin
            // exact-zero product: the sum is exactly c (or a signed zero)
            s1_special = 1'b1;
            if (c_zero)
                s1_special_res = (ps == sc) ? {ps, 31'd0}
                               : {(rm == RM_RDN), 31'd0};
            else
                s1_special_res = c;
        end
    end

    // subnormal pre-normalization (CLZ + shift), as in titan_x5_fp32_mul
    wire [23:0] ma_raw = {(ea != 0), fa};
    wire [23:0] mb_raw = {(eb != 0), fb};
    wire [23:0] mc_raw = {(ec != 0), fc};

    integer i;
    reg [4:0] clz_a, clz_b, clz_c;
    always @(*) begin
        clz_a = 5'd0;
        for (i = 0; i <= 23; i = i + 1)
            if (ma_raw[i]) clz_a = 5'd23 - i[4:0];
        clz_b = 5'd0;
        for (i = 0; i <= 23; i = i + 1)
            if (mb_raw[i]) clz_b = 5'd23 - i[4:0];
        clz_c = 5'd0;
        for (i = 0; i <= 23; i = i + 1)
            if (mc_raw[i]) clz_c = 5'd23 - i[4:0];
    end

    wire [23:0] ma_n = ma_raw << clz_a;
    wire [23:0] mb_n = mb_raw << clz_b;
    wire [23:0] mc_n = mc_raw << clz_c;

    // effective exponents: normal e, subnormal 1 - clz
    wire signed [11:0] ea_eff = (ea == 0) ? (12'sd1 - {7'd0, clz_a}) : {4'd0, ea};
    wire signed [11:0] eb_eff = (eb == 0) ? (12'sd1 - {7'd0, clz_b}) : {4'd0, eb};
    wire signed [11:0] ec_eff = (ec == 0) ? (12'sd1 - {7'd0, clz_c}) : {4'd0, ec};

    // ULP weights: product ULP = 2^Ep, addend ULP = 2^Ec
    wire signed [11:0] w_Ep = ea_eff + eb_eff - 12'sd300;
    wire signed [11:0] w_Ec = ec_eff - 12'sd150;

    reg               p1_valid;
    reg               p1_special, p1_invalid;
    reg  [31:0]       p1_special_res;
    reg               p1_ps, p1_sc;
    reg signed [11:0] p1_Ep, p1_Ec;
    reg  [23:0]       p1_ma, p1_mb, p1_mc;
    reg  [1:0]        p1_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p1_valid <= 1'b0;
            p1_special <= 1'b0; p1_invalid <= 1'b0; p1_special_res <= 32'd0;
            p1_ps <= 1'b0; p1_sc <= 1'b0;
            p1_Ep <= 12'sd0; p1_Ec <= 12'sd0;
            p1_ma <= 24'd0; p1_mb <= 24'd0; p1_mc <= 24'd0;
            p1_rm <= 2'd0;
        end else if (en) begin
            p1_valid       <= valid_in;
            p1_special     <= s1_special;
            p1_invalid     <= s1_invalid;
            p1_special_res <= s1_special_res;
            p1_ps          <= ps;
            p1_sc          <= sc;
            p1_Ep          <= w_Ep;
            p1_Ec          <= w_Ec;
            p1_ma          <= ma_n;
            p1_mb          <= mb_n;
            p1_mc          <= (ec == 0 && fc == 0) ? 24'd0 : mc_n;
            p1_rm          <= rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 2: mantissa multiply + alignment-shift computation
    // ------------------------------------------------------------------
    wire [47:0] prod = p1_ma * p1_mb;

    // addend position in the frame (product ULP anchored at frame bit 28)
    wire signed [11:0] s_raw = 12'sd28 - (p1_Ep - p1_Ec);
    wire signed [11:0] s_sat = (s_raw < -12'sd24) ? -12'sd24 :
                               (s_raw >  12'sd80) ?  12'sd80 : s_raw;

    // weight of frame bit 0: anchored on the product ULP, except when the
    // high-side saturation re-bases the frame on the (dominant) addend --
    // the product then only contributes round/sticky bits and its exact
    // in-frame position no longer carries exponent information.
    wire signed [11:0] w_frame0 = (s_raw > 12'sd80) ? (p1_Ec - 12'sd80)
                                                    : (p1_Ep - 12'sd28);

    reg               p2_valid;
    reg               p2_special, p2_invalid;
    reg  [31:0]       p2_special_res;
    reg               p2_ps, p2_sc;
    reg signed [11:0] p2_Ep;
    reg signed [7:0]  p2_s;
    reg  [47:0]       p2_prod;
    reg  [23:0]       p2_mc;
    reg  [1:0]        p2_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p2_valid <= 1'b0;
            p2_special <= 1'b0; p2_invalid <= 1'b0; p2_special_res <= 32'd0;
            p2_ps <= 1'b0; p2_sc <= 1'b0;
            p2_Ep <= 12'sd0; p2_s <= 8'sd0;
            p2_prod <= 48'd0; p2_mc <= 24'd0; p2_rm <= 2'd0;
        end else if (en) begin
            p2_valid       <= p1_valid;
            p2_special     <= p1_special;
            p2_invalid     <= p1_invalid;
            p2_special_res <= p1_special_res;
            p2_ps          <= p1_ps;
            p2_sc          <= p1_sc;
            p2_Ep          <= w_frame0;
            p2_s           <= s_sat[7:0];
            p2_prod        <= prod;
            p2_mc          <= p1_mc;
            p2_rm          <= p1_rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 3: align the addend into the 104-bit frame
    // ------------------------------------------------------------------
    reg [103:0] c_frame;
    reg         c_sticky;
    reg [4:0]   rsh;
    integer     k;
    always @(*) begin
        c_frame  = 104'd0;
        c_sticky = 1'b0;
        rsh      = 5'd0;
        if (p2_s >= 0) begin
            c_frame = {80'd0, p2_mc} << p2_s[6:0];
        end else begin
            rsh = (-p2_s < 8'sd25) ? (-p2_s) : 5'd24;
            c_frame = {80'd0, p2_mc >> rsh};
            for (k = 0; k < 24; k = k + 1)
                if (k < rsh) c_sticky = c_sticky | p2_mc[k];
        end
    end

    reg               p3_valid;
    reg               p3_special, p3_invalid;
    reg  [31:0]       p3_special_res;
    reg               p3_ps, p3_sc;
    reg signed [11:0] p3_Ep;
    reg  [103:0]      p3_pfr, p3_cfr;
    reg               p3_cst;
    reg  [1:0]        p3_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p3_valid <= 1'b0;
            p3_special <= 1'b0; p3_invalid <= 1'b0; p3_special_res <= 32'd0;
            p3_ps <= 1'b0; p3_sc <= 1'b0; p3_Ep <= 12'sd0;
            p3_pfr <= 104'd0; p3_cfr <= 104'd0; p3_cst <= 1'b0;
            p3_rm <= 2'd0;
        end else if (en) begin
            p3_valid       <= p2_valid;
            p3_special     <= p2_special;
            p3_invalid     <= p2_invalid;
            p3_special_res <= p2_special_res;
            p3_ps          <= p2_ps;
            p3_sc          <= p2_sc;
            p3_Ep          <= p2_Ep;
            p3_pfr         <= {28'd0, p2_prod, 28'd0}; // product ULP at bit 28
            p3_cfr         <= c_frame;
            p3_cst         <= c_sticky;
            p3_rm          <= p2_rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 4: signed magnitude add/subtract over {frame, sticky}
    // ------------------------------------------------------------------
    // one extra low bit carries the addend's shifted-out sticky exactly
    // through effective subtraction (borrow + forced sticky).
    wire [104:0] mag_p = {p3_pfr, 1'b0};
    wire [104:0] mag_c = {p3_cfr, p3_cst};

    reg  [105:0] sum_mag;
    reg          sum_sign;
    always @(*) begin
        if (p3_ps == p3_sc) begin
            sum_mag  = {1'b0, mag_p} + {1'b0, mag_c};
            sum_sign = p3_ps;
        end else if (mag_p >= mag_c) begin
            sum_mag  = {1'b0, mag_p} - {1'b0, mag_c};
            sum_sign = p3_ps;
        end else begin
            sum_mag  = {1'b0, mag_c} - {1'b0, mag_p};
            sum_sign = p3_sc;
        end
    end

    reg               p4_valid;
    reg               p4_special, p4_invalid;
    reg  [31:0]       p4_special_res;
    reg               p4_sign;
    reg signed [11:0] p4_Ep;
    reg  [105:0]      p4_sum;
    reg  [1:0]        p4_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p4_valid <= 1'b0;
            p4_special <= 1'b0; p4_invalid <= 1'b0; p4_special_res <= 32'd0;
            p4_sign <= 1'b0; p4_Ep <= 12'sd0; p4_sum <= 106'd0; p4_rm <= 2'd0;
        end else if (en) begin
            p4_valid       <= p3_valid;
            p4_special     <= p3_special;
            p4_invalid     <= p3_invalid;
            p4_special_res <= p3_special_res;
            p4_sign        <= sum_sign;
            p4_Ep          <= p3_Ep;
            p4_sum         <= sum_mag;
            p4_rm          <= p3_rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 5: leading-zero count + normalize
    // ------------------------------------------------------------------
    reg [6:0] msb_idx;
    always @(*) begin
        msb_idx = 7'd0;
        for (i = 0; i <= 105; i = i + 1)
            if (p4_sum[i]) msb_idx = i[6:0];
    end

    wire [105:0] norm = p4_sum << (7'd105 - msb_idx);
    // sum bit k has value 2^(w_frame0 + k - 1); biased msb exponent:
    wire signed [11:0] exp_norm = p4_Ep + {5'd0, msb_idx} + 12'sd126;

    reg               p5_valid;
    reg               p5_special, p5_invalid;
    reg  [31:0]       p5_special_res;
    reg               p5_sign, p5_zero;
    reg  [23:0]       p5_mant;
    reg               p5_g, p5_st;
    reg signed [11:0] p5_exp;
    reg  [1:0]        p5_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p5_valid <= 1'b0;
            p5_special <= 1'b0; p5_invalid <= 1'b0; p5_special_res <= 32'd0;
            p5_sign <= 1'b0; p5_zero <= 1'b0;
            p5_mant <= 24'd0; p5_g <= 1'b0; p5_st <= 1'b0;
            p5_exp <= 12'sd0; p5_rm <= 2'd0;
        end else if (en) begin
            p5_valid       <= p4_valid;
            p5_special     <= p4_special;
            p5_invalid     <= p4_invalid;
            p5_special_res <= p4_special_res;
            p5_sign        <= p4_sign;
            p5_zero        <= (p4_sum == 106'd0);
            p5_mant        <= norm[105:82];
            p5_g           <= norm[81];
            p5_st          <= |norm[80:0];
            p5_exp         <= exp_norm;
            p5_rm          <= p4_rm;
        end
    end

    // ------------------------------------------------------------------
    // Stage 6: denormalize / round / pack / flags
    // ------------------------------------------------------------------
    reg  [25:0]       den_src, den_shifted;
    reg signed [11:0] den_amt;
    reg  [23:0]       mant_d;
    reg               rb, st;
    reg               rnd_inc;
    reg  [24:0]       mant_r;
    reg signed [11:0] exp_r;
    reg  [31:0]       res_c;
    reg               inv_c, ovf_c, unf_c, inx_c;
    reg               tiny;
    integer           j;

    always @(*) begin
        den_src = 26'd0; den_shifted = 26'd0; den_amt = 12'sd0;
        mant_d = 24'd0; rb = 1'b0; st = 1'b0; rnd_inc = 1'b0;
        mant_r = 25'd0; exp_r = 12'sd0;
        res_c = 32'd0; inv_c = 1'b0; ovf_c = 1'b0; unf_c = 1'b0; inx_c = 1'b0;
        tiny = 1'b0;

        if (p5_special) begin
            res_c = p5_special_res;
            inv_c = p5_invalid;
        end else if (p5_zero) begin
            // exact cancellation: +0, or -0 under round-down
            res_c = {(p5_rm == RM_RDN), 31'd0};
        end else begin
            tiny = (p5_exp < 12'sd1);
            if (tiny) begin
                // gradual underflow: shift right by (1 - exp), collect sticky
                den_amt = 12'sd1 - p5_exp;
                if (den_amt > 12'sd26) den_amt = 12'sd26;
                den_src = {p5_mant, p5_g, p5_st};
                den_shifted = den_src >> den_amt[4:0];
                st = p5_st;
                for (j = 0; j < 26; j = j + 1) begin
                    if (j < den_amt) st = st | den_src[j];
                end
                mant_d = den_shifted[25:2];
                rb     = den_shifted[1];
                st     = st | den_shifted[0];
                exp_r  = 12'sd1;
            end else begin
                mant_d = p5_mant;
                rb     = p5_g;
                st     = p5_st;
                exp_r  = p5_exp;
            end

            case (p5_rm)
                RM_RNE: rnd_inc = rb && (st || mant_d[0]);
                RM_RTZ: rnd_inc = 1'b0;
                RM_RDN: rnd_inc = p5_sign && (rb || st);
                RM_RUP: rnd_inc = !p5_sign && (rb || st);
                default: rnd_inc = 1'b0;
            endcase
            mant_r = {1'b0, mant_d} + {24'd0, rnd_inc};
            if (mant_r[24]) begin
                mant_r = mant_r >> 1;
                exp_r  = exp_r + 12'sd1;
            end

            inx_c = rb | st;

            if (exp_r >= 12'sd255 && mant_r[23]) begin
                ovf_c = 1'b1;
                inx_c = 1'b1;
                case (p5_rm)
                    RM_RNE: res_c = {p5_sign, 8'hFF, 23'd0};
                    RM_RTZ: res_c = {p5_sign, 8'hFE, {23{1'b1}}};
                    RM_RDN: res_c = p5_sign ? {1'b1, 8'hFF, 23'd0}
                                            : {1'b0, 8'hFE, {23{1'b1}}};
                    default: res_c = p5_sign ? {1'b1, 8'hFE, {23{1'b1}}}
                                             : {1'b0, 8'hFF, 23'd0};
                endcase
            end else begin
                res_c = {p5_sign,
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
            valid_out      <= p5_valid;
            result         <= res_c;
            flag_invalid   <= inv_c;
            flag_overflow  <= ovf_c;
            flag_underflow <= unf_c;
            flag_inexact   <= inx_c;
        end
    end

endmodule
