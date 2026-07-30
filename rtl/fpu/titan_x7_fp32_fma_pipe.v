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
 * Titan X7 GPU - IEEE-754 FP32 Fused Multiply-Add, high-frequency pipeline.
 *
 * Bit-exact re-partition of titan_x5_fp32_fma (single-rounding true FMA,
 * 4 IEEE rounding modes, full subnormal support) into 8 short stages so
 * that no stage carries more than one "heavy" structure (multiplier half,
 * wide shifter, wide adder, CLZ tree, rounder). Target: ~333 ps/stage on
 * ASAP7 with register retiming enabled; verified cycle-accurate against
 * the proven 6-stage unit by tb/uvm/test_fma_x7.py (differential).
 *
 *   E1: unpack, classify specials, subnormal CLZ (3 x 24-bit CLZ trees)
 *   E2: subnormal pre-normalization shifts; exponent math; alignment
 *       shift computation (saturation to [-24,+80])
 *   E3: multiplier half 1: two 24x12 partial products
 *   E4: multiplier half 2: partial-product CPA; addend 104-bit align
 *       shift + sticky collection
 *   E5: 105-bit signed-magnitude add/subtract (both directions computed
 *       in parallel, late select)
 *   E6: 106-bit CLZ tree; normalized-exponent computation
 *   E7: 106-bit normalization left shift; guard/sticky extraction
 *   E8: gradual-underflow denormalization, rounding, pack, flags
 *
 * Latency: 8 cycles at II=1 when en=1. `en` gates every pipeline register.
 */
module titan_x7_fp32_fma_pipe (
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

    // private loop variable per always block (processes may interleave;
    // a shared index can be clobbered mid-loop by another block)
    integer i, j, k, m;

    // ------------------------------------------------------------------
    // E1: unpack / classify / subnormal CLZ
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

    wire ps = sa ^ sb;
    wire mul_inv_pair = (a_inf && b_zero) || (a_zero && b_inf);

    reg        e1_special_c;
    reg [31:0] e1_special_res_c;
    reg        e1_invalid_c;
    always @(*) begin
        e1_special_c     = 1'b0;
        e1_special_res_c = 32'd0;
        e1_invalid_c     = 1'b0;
        if (a_nan || b_nan || c_nan) begin
            e1_special_c     = 1'b1;
            e1_special_res_c = QNAN;
            e1_invalid_c     = a_snan || b_snan || c_snan || mul_inv_pair;
        end else if (mul_inv_pair) begin
            e1_special_c     = 1'b1;
            e1_special_res_c = QNAN;
            e1_invalid_c     = 1'b1;
        end else if (a_inf || b_inf) begin
            e1_special_c = 1'b1;
            if (c_inf && (sc != ps)) begin
                e1_special_res_c = QNAN;
                e1_invalid_c     = 1'b1;
            end else begin
                e1_special_res_c = {ps, 8'hFF, 23'd0};
            end
        end else if (c_inf) begin
            e1_special_c     = 1'b1;
            e1_special_res_c = {sc, 8'hFF, 23'd0};
        end else if (a_zero || b_zero) begin
            e1_special_c = 1'b1;
            if (c_zero)
                e1_special_res_c = (ps == sc) ? {ps, 31'd0}
                                 : {(rm == RM_RDN), 31'd0};
            else
                e1_special_res_c = c;
        end
    end

    wire [23:0] ma_raw = {(ea != 0), fa};
    wire [23:0] mb_raw = {(eb != 0), fb};
    wire [23:0] mc_raw = {(ec != 0), fc};

    // Leading-zero counts, as log-depth trees rather than the 24-deep linear
    // priority scans these replace (see titan_x7_lzc). clz = 23 - msb_index.
    //
    // The `nz ? ... : 0` guard reproduces the replaced loop EXACTLY: with an
    // all-zero mantissa no iteration fired, so the accumulator kept its 5'd0
    // initialiser rather than yielding 23. That case may well be unreachable
    // -- a zero mantissa with a zero exponent is classified as a special
    // before this is used -- but matching the old behaviour outright is
    // cheaper than depending on the argument being true.
    wire [4:0] msb_a, msb_b, msb_c;
    wire       nz_a, nz_b, nz_c;
    titan_x7_lzc #(.W(32), .LW(5)) u_clz_a (
        .vec({8'd0, ma_raw}), .idx(msb_a), .nz(nz_a));
    titan_x7_lzc #(.W(32), .LW(5)) u_clz_b (
        .vec({8'd0, mb_raw}), .idx(msb_b), .nz(nz_b));
    titan_x7_lzc #(.W(32), .LW(5)) u_clz_c (
        .vec({8'd0, mc_raw}), .idx(msb_c), .nz(nz_c));

    wire [4:0] clz_a_c = nz_a ? (5'd23 - msb_a) : 5'd0;
    wire [4:0] clz_b_c = nz_b ? (5'd23 - msb_b) : 5'd0;
    wire [4:0] clz_c_c = nz_c ? (5'd23 - msb_c) : 5'd0;

    reg        e1_valid;
    reg        e1_special, e1_invalid;
    reg [31:0] e1_special_res;
    reg        e1_ps, e1_sc;
    reg [7:0]  e1_ea, e1_eb, e1_ec;
    reg [23:0] e1_ma_raw, e1_mb_raw, e1_mc_raw;
    reg [4:0]  e1_clz_a, e1_clz_b, e1_clz_c;
    reg        e1_c_true_zero;
    reg [1:0]  e1_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e1_valid <= 1'b0;
            e1_special <= 1'b0; e1_invalid <= 1'b0; e1_special_res <= 32'd0;
            e1_ps <= 1'b0; e1_sc <= 1'b0;
            e1_ea <= 8'd0; e1_eb <= 8'd0; e1_ec <= 8'd0;
            e1_ma_raw <= 24'd0; e1_mb_raw <= 24'd0; e1_mc_raw <= 24'd0;
            e1_clz_a <= 5'd0; e1_clz_b <= 5'd0; e1_clz_c <= 5'd0;
            e1_c_true_zero <= 1'b0;
            e1_rm <= 2'd0;
        end else if (en) begin
            e1_valid       <= valid_in;
            e1_special     <= e1_special_c;
            e1_invalid     <= e1_invalid_c;
            e1_special_res <= e1_special_res_c;
            e1_ps          <= ps;
            e1_sc          <= sc;
            e1_ea          <= ea;
            e1_eb          <= eb;
            e1_ec          <= ec;
            e1_ma_raw      <= ma_raw;
            e1_mb_raw      <= mb_raw;
            e1_mc_raw      <= mc_raw;
            e1_clz_a       <= clz_a_c;
            e1_clz_b       <= clz_b_c;
            e1_clz_c       <= clz_c_c;
            e1_c_true_zero <= c_zero;
            e1_rm          <= rm;
        end
    end

    // ------------------------------------------------------------------
    // E2: pre-normalize shifts, exponent math, alignment computation
    // ------------------------------------------------------------------
    wire [23:0] ma_n = e1_ma_raw << e1_clz_a;
    wire [23:0] mb_n = e1_mb_raw << e1_clz_b;
    wire [23:0] mc_n = e1_mc_raw << e1_clz_c;

    wire signed [11:0] ea_eff = (e1_ea == 0) ? (12'sd1 - {7'd0, e1_clz_a}) : {4'd0, e1_ea};
    wire signed [11:0] eb_eff = (e1_eb == 0) ? (12'sd1 - {7'd0, e1_clz_b}) : {4'd0, e1_eb};
    wire signed [11:0] ec_eff = (e1_ec == 0) ? (12'sd1 - {7'd0, e1_clz_c}) : {4'd0, e1_ec};

    wire signed [11:0] w_Ep = ea_eff + eb_eff - 12'sd300;
    wire signed [11:0] w_Ec = ec_eff - 12'sd150;

    wire signed [11:0] s_raw = 12'sd28 - (w_Ep - w_Ec);
    wire signed [11:0] s_sat = (s_raw < -12'sd24) ? -12'sd24 :
                               (s_raw >  12'sd80) ?  12'sd80 : s_raw;
    wire signed [11:0] w_frame0 = (s_raw > 12'sd80) ? (w_Ec - 12'sd80)
                                                    : (w_Ep - 12'sd28);

    reg               e2_valid;
    reg               e2_special, e2_invalid;
    reg  [31:0]       e2_special_res;
    reg               e2_ps, e2_sc;
    reg signed [11:0] e2_Ep;         // frame-bit-0 weight (w_frame0)
    reg signed [7:0]  e2_s;
    reg  [23:0]       e2_ma, e2_mb, e2_mc;
    reg  [1:0]        e2_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e2_valid <= 1'b0;
            e2_special <= 1'b0; e2_invalid <= 1'b0; e2_special_res <= 32'd0;
            e2_ps <= 1'b0; e2_sc <= 1'b0;
            e2_Ep <= 12'sd0; e2_s <= 8'sd0;
            e2_ma <= 24'd0; e2_mb <= 24'd0; e2_mc <= 24'd0;
            e2_rm <= 2'd0;
        end else if (en) begin
            e2_valid       <= e1_valid;
            e2_special     <= e1_special;
            e2_invalid     <= e1_invalid;
            e2_special_res <= e1_special_res;
            e2_ps          <= e1_ps;
            e2_sc          <= e1_sc;
            e2_Ep          <= w_frame0;
            e2_s           <= s_sat[7:0];
            e2_ma          <= ma_n;
            e2_mb          <= mb_n;
            e2_mc          <= e1_c_true_zero ? 24'd0 : mc_n;
            e2_rm          <= e1_rm;
        end
    end

    // ------------------------------------------------------------------
    // E3: multiplier half 1 - two 24x12 partial products
    // ------------------------------------------------------------------
    wire [35:0] pp_lo = e2_ma * e2_mb[11:0];
    wire [35:0] pp_hi = e2_ma * e2_mb[23:12];

    reg               e3_valid;
    reg               e3_special, e3_invalid;
    reg  [31:0]       e3_special_res;
    reg               e3_ps, e3_sc;
    reg signed [11:0] e3_Ep;
    reg signed [7:0]  e3_s;
    reg  [35:0]       e3_pp_lo, e3_pp_hi;
    reg  [23:0]       e3_mc;
    reg  [1:0]        e3_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e3_valid <= 1'b0;
            e3_special <= 1'b0; e3_invalid <= 1'b0; e3_special_res <= 32'd0;
            e3_ps <= 1'b0; e3_sc <= 1'b0;
            e3_Ep <= 12'sd0; e3_s <= 8'sd0;
            e3_pp_lo <= 36'd0; e3_pp_hi <= 36'd0;
            e3_mc <= 24'd0; e3_rm <= 2'd0;
        end else if (en) begin
            e3_valid       <= e2_valid;
            e3_special     <= e2_special;
            e3_invalid     <= e2_invalid;
            e3_special_res <= e2_special_res;
            e3_ps          <= e2_ps;
            e3_sc          <= e2_sc;
            e3_Ep          <= e2_Ep;
            e3_s           <= e2_s;
            e3_pp_lo       <= pp_lo;
            e3_pp_hi       <= pp_hi;
            e3_mc          <= e2_mc;
            e3_rm          <= e2_rm;
        end
    end

    // ------------------------------------------------------------------
    // E4: multiplier half 2 (partial-product CPA) + addend alignment
    // ------------------------------------------------------------------
    // Partial-product CPA, prefix rather than ripple (see E5 note below).
    wire [47:0] prod;
    titan_x7_prefix_add #(.W(48), .LEVELS(6)) u_e4_cpa (
        .a({12'd0, e3_pp_lo}), .b({e3_pp_hi, 12'd0}), .cin(1'b0),
        .sum(prod), .cout());

    reg [103:0] c_frame_c;
    reg         c_sticky_c;
    reg [4:0]   rsh;
    always @(*) begin
        c_frame_c  = 104'd0;
        c_sticky_c = 1'b0;
        rsh        = 5'd0;
        if (e3_s >= 0) begin
            c_frame_c = {80'd0, e3_mc} << e3_s[6:0];
        end else begin
            rsh = (-e3_s < 8'sd25) ? (-e3_s) : 5'd24;
            c_frame_c = {80'd0, e3_mc >> rsh};
            // Sticky = OR of the bits shifted out, i.e. bits [rsh-1:0].
            //
            // MEASURED, do not "optimise" this into the mask form
            // |(e3_mc & ~(~0 << rsh)) that the tensor PE's D3 sticky uses.
            // That rewrite is a 2x win at 137 bits, where it removes a ripple
            // decrement -- and a LOSS here at 24 bits: 401.81 -> 460.39 ps on
            // GT2N elvt/w31. At this width the per-bit `k < rsh` comparisons
            // synthesise in parallel and feed a balanced OR, whereas the mask
            // form puts a barrel shift in series ahead of the same OR.
            for (k = 0; k < 24; k = k + 1)
                if (k < rsh) c_sticky_c = c_sticky_c | e3_mc[k];
        end
    end

    reg               e4_valid;
    reg               e4_special, e4_invalid;
    reg  [31:0]       e4_special_res;
    reg               e4_ps, e4_sc;
    reg signed [11:0] e4_Ep;
    reg  [103:0]      e4_pfr, e4_cfr;
    reg               e4_cst;
    reg  [1:0]        e4_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e4_valid <= 1'b0;
            e4_special <= 1'b0; e4_invalid <= 1'b0; e4_special_res <= 32'd0;
            e4_ps <= 1'b0; e4_sc <= 1'b0; e4_Ep <= 12'sd0;
            e4_pfr <= 104'd0; e4_cfr <= 104'd0; e4_cst <= 1'b0;
            e4_rm <= 2'd0;
        end else if (en) begin
            e4_valid       <= e3_valid;
            e4_special     <= e3_special;
            e4_invalid     <= e3_invalid;
            e4_special_res <= e3_special_res;
            e4_ps          <= e3_ps;
            e4_sc          <= e3_sc;
            e4_Ep          <= e3_Ep;
            e4_pfr         <= {28'd0, prod, 28'd0};
            e4_cfr         <= c_frame_c;
            e4_cst         <= c_sticky_c;
            e4_rm          <= e3_rm;
        end
    end

    // ------------------------------------------------------------------
    // E5: signed-magnitude add/subtract (parallel both-ways, late select)
    // ------------------------------------------------------------------
    wire [104:0] mag_p = {e4_pfr, 1'b0};
    wire [104:0] mag_c = {e4_cfr, e4_cst};

    // Parallel-prefix rather than `+`/`-`: on GT2N a bare operator on a
    // 106-bit vector becomes a ripple chain, because the library has no
    // adder cells (docs/GT2N_2NM_SYNTHESIS.md). titan_x7_prefix_add is
    // SAT-proven equivalent to a+b+cin, so this is a structural change only.
    wire [105:0] sum_add, sub_pc, sub_cp;

    titan_x7_prefix_add #(.W(106), .LEVELS(7)) u_e5_add (
        .a({1'b0, mag_p}), .b({1'b0, mag_c}), .cin(1'b0),
        .sum(sum_add), .cout());

    // a - b == a + ~b + 1
    titan_x7_prefix_add #(.W(106), .LEVELS(7)) u_e5_sub_pc (
        .a({1'b0, mag_p}), .b(~{1'b0, mag_c}), .cin(1'b1),
        .sum(sub_pc), .cout());

    titan_x7_prefix_add #(.W(106), .LEVELS(7)) u_e5_sub_cp (
        .a({1'b0, mag_c}), .b(~{1'b0, mag_p}), .cin(1'b1),
        .sum(sub_cp), .cout());

    // `mag_p >= mag_c` was a fourth 106-bit carry chain. It is redundant:
    // both operands are 105 bits zero-extended to 106, so sub_pc stays below
    // 2^105 exactly when mag_p >= mag_c, and borrows into bit 105 otherwise.
    // Reusing that bit deletes the comparator outright.
    wire         p_ge_c  = ~sub_pc[105];

    reg  [105:0] sum_mag_c;
    reg          sum_sign_c;
    always @(*) begin
        if (e4_ps == e4_sc) begin
            sum_mag_c  = sum_add;
            sum_sign_c = e4_ps;
        end else if (p_ge_c) begin
            sum_mag_c  = sub_pc;
            sum_sign_c = e4_ps;
        end else begin
            sum_mag_c  = sub_cp;
            sum_sign_c = e4_sc;
        end
    end

    reg               e5_valid;
    reg               e5_special, e5_invalid;
    reg  [31:0]       e5_special_res;
    reg               e5_sign;
    reg signed [11:0] e5_Ep;
    reg  [105:0]      e5_sum;
    reg  [1:0]        e5_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e5_valid <= 1'b0;
            e5_special <= 1'b0; e5_invalid <= 1'b0; e5_special_res <= 32'd0;
            e5_sign <= 1'b0; e5_Ep <= 12'sd0; e5_sum <= 106'd0; e5_rm <= 2'd0;
        end else if (en) begin
            e5_valid       <= e4_valid;
            e5_special     <= e4_special;
            e5_invalid     <= e4_invalid;
            e5_special_res <= e4_special_res;
            e5_sign        <= sum_sign_c;
            e5_Ep          <= e4_Ep;
            e5_sum         <= sum_mag_c;
            e5_rm          <= e4_rm;
        end
    end

    // ------------------------------------------------------------------
    // E6: 106-bit CLZ + normalized-exponent computation
    // ------------------------------------------------------------------
    // Was a 106-deep linear priority scan despite the "CLZ tree" in the
    // header; it became the dominant critical path once E5's adders were
    // made parallel-prefix. Now log-depth, and SAT-proven identical to the
    // scan it replaces (including its all-zero-reads-0 behaviour).
    wire [6:0] msb_idx_c;
    titan_x7_lzc #(.W(128), .LW(7)) u_e6_lzc (
        .vec({22'd0, e5_sum}), .idx(msb_idx_c), .nz());

    wire signed [11:0] exp_norm = e5_Ep + {5'd0, msb_idx_c} + 12'sd126;

    reg               e6_valid;
    reg               e6_special, e6_invalid;
    reg  [31:0]       e6_special_res;
    reg               e6_sign, e6_zero;
    reg  [105:0]      e6_sum;
    reg  [6:0]        e6_msb_idx;
    reg signed [11:0] e6_exp;
    reg  [1:0]        e6_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e6_valid <= 1'b0;
            e6_special <= 1'b0; e6_invalid <= 1'b0; e6_special_res <= 32'd0;
            e6_sign <= 1'b0; e6_zero <= 1'b0;
            e6_sum <= 106'd0; e6_msb_idx <= 7'd0;
            e6_exp <= 12'sd0; e6_rm <= 2'd0;
        end else if (en) begin
            e6_valid       <= e5_valid;
            e6_special     <= e5_special;
            e6_invalid     <= e5_invalid;
            e6_special_res <= e5_special_res;
            e6_sign        <= e5_sign;
            e6_zero        <= (e5_sum == 106'd0);
            e6_sum         <= e5_sum;
            e6_msb_idx     <= msb_idx_c;
            e6_exp         <= exp_norm;
            e6_rm          <= e5_rm;
        end
    end

    // ------------------------------------------------------------------
    // E7: normalization shift + guard/sticky extraction
    // ------------------------------------------------------------------
    wire [105:0] norm = e6_sum << (7'd105 - e6_msb_idx);

    reg               e7_valid;
    reg               e7_special, e7_invalid;
    reg  [31:0]       e7_special_res;
    reg               e7_sign, e7_zero;
    reg  [23:0]       e7_mant;
    reg               e7_g, e7_st;
    reg signed [11:0] e7_exp;
    reg  [1:0]        e7_rm;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            e7_valid <= 1'b0;
            e7_special <= 1'b0; e7_invalid <= 1'b0; e7_special_res <= 32'd0;
            e7_sign <= 1'b0; e7_zero <= 1'b0;
            e7_mant <= 24'd0; e7_g <= 1'b0; e7_st <= 1'b0;
            e7_exp <= 12'sd0; e7_rm <= 2'd0;
        end else if (en) begin
            e7_valid       <= e6_valid;
            e7_special     <= e6_special;
            e7_invalid     <= e6_invalid;
            e7_special_res <= e6_special_res;
            e7_sign        <= e6_sign;
            e7_zero        <= e6_zero;
            e7_mant        <= norm[105:82];
            e7_g           <= norm[81];
            e7_st          <= |norm[80:0];
            e7_exp         <= e6_exp;
            e7_rm          <= e6_rm;
        end
    end

    // ------------------------------------------------------------------
    // E8: denormalize / round / pack / flags
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

    always @(*) begin
        den_src = 26'd0; den_shifted = 26'd0; den_amt = 12'sd0;
        mant_d = 24'd0; rb = 1'b0; st = 1'b0; rnd_inc = 1'b0;
        mant_r = 25'd0; exp_r = 12'sd0;
        res_c = 32'd0; inv_c = 1'b0; ovf_c = 1'b0; unf_c = 1'b0; inx_c = 1'b0;
        tiny = 1'b0;

        if (e7_special) begin
            res_c = e7_special_res;
            inv_c = e7_invalid;
        end else if (e7_zero) begin
            res_c = {(e7_rm == RM_RDN), 31'd0};
        end else begin
            tiny = (e7_exp < 12'sd1);
            if (tiny) begin
                den_amt = 12'sd1 - e7_exp;
                if (den_amt > 12'sd26) den_amt = 12'sd26;
                den_src = {e7_mant, e7_g, e7_st};
                den_shifted = den_src >> den_amt[4:0];
                st = e7_st;
                for (j = 0; j < 26; j = j + 1) begin
                    if (j < den_amt) st = st | den_src[j];
                end
                mant_d = den_shifted[25:2];
                rb     = den_shifted[1];
                st     = st | den_shifted[0];
                exp_r  = 12'sd1;
            end else begin
                mant_d = e7_mant;
                rb     = e7_g;
                st     = e7_st;
                exp_r  = e7_exp;
            end

            case (e7_rm)
                RM_RNE: rnd_inc = rb && (st || mant_d[0]);
                RM_RTZ: rnd_inc = 1'b0;
                RM_RDN: rnd_inc = e7_sign && (rb || st);
                RM_RUP: rnd_inc = !e7_sign && (rb || st);
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
                case (e7_rm)
                    RM_RNE: res_c = {e7_sign, 8'hFF, 23'd0};
                    RM_RTZ: res_c = {e7_sign, 8'hFE, {23{1'b1}}};
                    RM_RDN: res_c = e7_sign ? {1'b1, 8'hFF, 23'd0}
                                            : {1'b0, 8'hFE, {23{1'b1}}};
                    default: res_c = e7_sign ? {1'b1, 8'hFE, {23{1'b1}}}
                                             : {1'b0, 8'hFF, 23'd0};
                endcase
            end else begin
                res_c = {e7_sign,
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
            valid_out      <= e7_valid;
            result         <= res_c;
            flag_invalid   <= inv_c;
            flag_overflow  <= ovf_c;
            flag_underflow <= unf_c;
            flag_inexact   <= inx_c;
        end
    end

endmodule
