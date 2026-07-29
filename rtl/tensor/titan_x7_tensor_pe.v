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
 * Titan X7 GPU - high-frequency tensor processing element (FP16 in, FP32 out).
 *
 * The x5/x6 tensor PEs put a full combinational FP16 multiply + FP32 add in
 * the accumulate loop: that path is the array's fmax limiter. This PE removes
 * rounding from the loop entirely:
 *
 *   - FP16 x FP16 is computed EXACTLY (22-bit product, no rounding) and
 *     shifted into a 113-bit fixed-point frame covering the full FP16
 *     product range (LSB = 2^-68, guard bits for 4096-term dot products).
 *   - The accumulator is held in REDUNDANT carry-save form: the per-cycle
 *     loop dependence is one 3:2 compressor + register (a few gate delays,
 *     comfortably under 333 ps) instead of a 100+-bit carry-propagate add.
 *   - Only on drain is the accumulator resolved (CPA), normalized and
 *     rounded once (RNE) to FP32. Sum of products is therefore exact until
 *     the single final rounding - stronger than IEEE per-step FP32 FMA.
 *
 * Multiply front end (feeds the compressor, II=1, 3-stage):
 *   M1: unpack, subnormal CLZ, specials;  M2: 11x11 multiply, exponent;
 *   M3: barrel-shift product into frame position, negate if sign.
 * Drain: acc_clear latches {sum,carry}; the CPA + CLZ + round path has 3
 * dedicated stages (D1..D3) and may also be constrained as a multicycle
 * path - it is off the accumulate loop.
 *
 * Specials: any NaN input or Inf*0 poisons the tile -> qNaN out. Inf
 * products make the result +/-Inf (both signs -> qNaN), matching the
 * "single rounding of the exact sum" semantic.
 */
module titan_x7_tensor_pe #(
    parameter ACC_W = 113                 // 22 prod + 78 range + 12 guard + 1 sign
)(
    input  wire        clk,
    input  wire        rst_n,

    // multiply-accumulate stream
    input  wire        mac_valid,
    input  wire [15:0] a,
    input  wire [15:0] b,

    // drain handshake: pulse acc_drain, result_valid pulses when done;
    // accumulator clears on drain so back-to-back tiles stream cleanly
    input  wire        acc_drain,
    output reg         result_valid,
    output reg  [31:0] result,            // FP32

    // pass-through registers for systolic wiring (1-cycle delayed operands)
    output reg  [15:0] a_pass,
    output reg  [15:0] b_pass,
    output reg         v_pass
);

    localparam [31:0] QNAN32 = 32'h7FC00000;

    // private loop variable per always block (processes may interleave)
    integer i, im, id;

    // ------------------------------------------------------------------
    // M1: unpack, classify, subnormal CLZ
    // ------------------------------------------------------------------
    wire       sa = a[15],      sb = b[15];
    wire [4:0] ea = a[14:10],   eb = b[14:10];
    wire [9:0] fa = a[9:0],     fb = b[9:0];

    wire a_nan  = (ea == 5'h1F) && (fa != 0);
    wire b_nan  = (eb == 5'h1F) && (fb != 0);
    wire a_inf  = (ea == 5'h1F) && (fa == 0);
    wire b_inf  = (eb == 5'h1F) && (fb == 0);
    wire a_zero = (ea == 0) && (fa == 0);
    wire b_zero = (eb == 0) && (fb == 0);

    wire [10:0] ma_raw = {(ea != 0), fa};
    wire [10:0] mb_raw = {(eb != 0), fb};

    reg [3:0] clz_a, clz_b;
    always @(*) begin
        clz_a = 4'd0;
        for (i = 0; i <= 10; i = i + 1)
            if (ma_raw[i]) clz_a = 4'd10 - i[3:0];
        clz_b = 4'd0;
        for (i = 0; i <= 10; i = i + 1)
            if (mb_raw[i]) clz_b = 4'd10 - i[3:0];
    end

    reg        m1_valid;
    reg        m1_sign;
    reg        m1_zero, m1_nan, m1_inf;
    reg [10:0] m1_ma, m1_mb;
    reg signed [7:0] m1_k;   // product scale: value = P * 2^k, k in [-68,10]

    wire signed [7:0] ea_eff = (ea == 0) ? (8'sd1 - {4'd0, clz_a} - 8'sd10) : ({3'd0, ea} - 8'sd10);
    wire signed [7:0] eb_eff = (eb == 0) ? (8'sd1 - {4'd0, clz_b} - 8'sd10) : ({3'd0, eb} - 8'sd10);
    // value = M * 2^(e_eff - 15), M in [2^10, 2^11)
    wire signed [7:0] k_c = ea_eff + eb_eff - 8'sd30;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m1_valid <= 1'b0;
            m1_sign <= 1'b0; m1_zero <= 1'b0; m1_nan <= 1'b0; m1_inf <= 1'b0;
            m1_ma <= 11'd0; m1_mb <= 11'd0; m1_k <= 8'sd0;
            a_pass <= 16'd0; b_pass <= 16'd0; v_pass <= 1'b0;
        end else begin
            m1_valid <= mac_valid;
            m1_sign  <= sa ^ sb;
            m1_zero  <= a_zero || b_zero;
            m1_nan   <= a_nan || b_nan || (a_inf && b_zero) || (a_zero && b_inf);
            m1_inf   <= (a_inf && !b_zero && !b_nan) || (b_inf && !a_zero && !a_nan);
            m1_ma    <= ma_raw << clz_a;
            m1_mb    <= mb_raw << clz_b;
            m1_k     <= k_c;
            a_pass   <= a;
            b_pass   <= b;
            v_pass   <= mac_valid;
        end
    end

    // ------------------------------------------------------------------
    // M2: 11x11 multiply
    // ------------------------------------------------------------------
    reg        m2_valid, m2_sign, m2_zero, m2_nan, m2_inf;
    reg [21:0] m2_prod;
    reg [6:0]  m2_shift;   // frame shift = k + 68, in [0, 78]

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m2_valid <= 1'b0; m2_sign <= 1'b0; m2_zero <= 1'b0;
            m2_nan <= 1'b0; m2_inf <= 1'b0;
            m2_prod <= 22'd0; m2_shift <= 7'd0;
        end else begin
            m2_valid <= m1_valid;
            m2_sign  <= m1_sign;
            m2_zero  <= m1_zero;
            m2_nan   <= m1_nan;
            m2_inf   <= m1_inf;
            m2_prod  <= m1_ma * m1_mb;
            m2_shift <= m1_k[6:0] + 7'd68;
        end
    end

    // ------------------------------------------------------------------
    // M3: shift into frame, apply sign (two's complement)
    // ------------------------------------------------------------------
    reg               m3_valid, m3_nan, m3_inf, m3_inf_sign;
    reg [ACC_W-1:0]   m3_addend;

    wire [ACC_W-1:0] shifted = {{(ACC_W-22){1'b0}}, m2_prod} << m2_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m3_valid <= 1'b0; m3_nan <= 1'b0; m3_inf <= 1'b0; m3_inf_sign <= 1'b0;
            m3_addend <= {ACC_W{1'b0}};
        end else begin
            m3_valid    <= m2_valid && !m2_zero && !m2_nan && !m2_inf;
            m3_nan      <= m2_valid && m2_nan;
            m3_inf      <= m2_valid && m2_inf;
            m3_inf_sign <= m2_sign;
            m3_addend   <= m2_sign ? (~shifted + {{(ACC_W-1){1'b0}}, 1'b1}) : shifted;
        end
    end

    // ------------------------------------------------------------------
    // Carry-save accumulator: the only loop-carried path is a 3:2
    // compressor feeding two registers.
    // ------------------------------------------------------------------
    reg [ACC_W-1:0] acc_s, acc_c;
    reg             sticky_nan;
    reg             sticky_pinf, sticky_ninf;

    wire [ACC_W-1:0] csa_s = acc_s ^ acc_c ^ m3_addend;
    wire [ACC_W-1:0] csa_c = ((acc_s & acc_c) | (acc_s & m3_addend) | (acc_c & m3_addend)) << 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_s <= {ACC_W{1'b0}};
            acc_c <= {ACC_W{1'b0}};
            sticky_nan <= 1'b0; sticky_pinf <= 1'b0; sticky_ninf <= 1'b0;
        end else if (acc_drain) begin
            acc_s <= {ACC_W{1'b0}};
            acc_c <= {ACC_W{1'b0}};
            sticky_nan <= 1'b0; sticky_pinf <= 1'b0; sticky_ninf <= 1'b0;
        end else begin
            if (m3_valid) begin
                acc_s <= csa_s;
                acc_c <= csa_c;
            end
            if (m3_nan) sticky_nan <= 1'b1;
            if (m3_inf) begin
                if (m3_inf_sign) sticky_ninf <= 1'b1;
                else             sticky_pinf <= 1'b1;
            end
        end
    end

    // ------------------------------------------------------------------
    // Drain path D1..D3: CPA, sign/CLZ, round to FP32 (off the MAC loop;
    // may be given a multicycle constraint in synthesis)
    // ------------------------------------------------------------------
    reg               d1_valid;
    reg [ACC_W-1:0]   d1_sum;
    reg               d1_nan, d1_pinf, d1_ninf;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d1_valid <= 1'b0; d1_sum <= {ACC_W{1'b0}};
            d1_nan <= 1'b0; d1_pinf <= 1'b0; d1_ninf <= 1'b0;
        end else begin
            d1_valid <= acc_drain;
            d1_sum   <= acc_s + acc_c;            // CPA
            d1_nan   <= sticky_nan;
            d1_pinf  <= sticky_pinf;
            d1_ninf  <= sticky_ninf;
        end
    end

    reg               d2_valid, d2_sign;
    reg [ACC_W-1:0]   d2_mag;
    reg [6:0]         d2_msb;
    reg               d2_zero;
    reg               d2_nan, d2_pinf, d2_ninf;

    wire               s_neg  = d1_sum[ACC_W-1];
    wire [ACC_W-1:0]   s_mag  = s_neg ? (~d1_sum + {{(ACC_W-1){1'b0}}, 1'b1}) : d1_sum;

    reg [6:0] msb_c;
    always @(*) begin
        msb_c = 7'd0;
        for (im = 0; im < ACC_W-1; im = im + 1)
            if (s_mag[im]) msb_c = im[6:0];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            d2_valid <= 1'b0; d2_sign <= 1'b0; d2_mag <= {ACC_W{1'b0}};
            d2_msb <= 7'd0; d2_zero <= 1'b0;
            d2_nan <= 1'b0; d2_pinf <= 1'b0; d2_ninf <= 1'b0;
        end else begin
            d2_valid <= d1_valid;
            d2_sign  <= s_neg;
            d2_mag   <= s_mag;
            d2_msb   <= msb_c;
            d2_zero  <= (d1_sum == {ACC_W{1'b0}});
            d2_nan   <= d1_nan;
            d2_pinf  <= d1_pinf;
            d2_ninf  <= d1_ninf;
        end
    end

    // D3: normalize + RNE round + pack.
    // magnitude = mag * 2^-68; FP32 biased exponent of bit m: m - 68 + 127.
    reg  [23:0] mant_d;
    reg         rb_d, st_d;
    reg  [24:0] mant_rr;
    reg signed [9:0] exp_rr;
    reg  [31:0] res_c;
    reg  [ACC_W+24-1:0] mag_ext;
    reg  [6:0]  down;

    always @(*) begin
        res_c = 32'd0;
        mant_d = 24'd0; rb_d = 1'b0; st_d = 1'b0;
        mant_rr = 25'd0; exp_rr = 10'sd0;
        mag_ext = {ACC_W+24{1'b0}};
        down = 7'd0;

        if (d2_nan || (d2_pinf && d2_ninf)) begin
            res_c = QNAN32;
        end else if (d2_pinf) begin
            res_c = 32'h7F800000;
        end else if (d2_ninf) begin
            res_c = 32'hFF800000;
        end else if (d2_zero) begin
            res_c = 32'h00000000;
        end else begin
            // take 24 mantissa bits below the MSB; the rest are round/sticky
            mag_ext = {d2_mag, 24'd0};      // headroom for small msb
            down    = d2_msb;               // shift so msb sits at bit 23 of mant_d
            // mant window: bits [msb : msb-23] -> normalize via ext shift
            mant_d  = mag_ext[down + 24 -: 24];
            rb_d    = mag_ext[down];        // bit msb-24 (guard)
            st_d    = |(mag_ext & (({{ACC_W+24-1{1'b0}}, 1'b1} << down) - 1));

            mant_rr = {1'b0, mant_d} + {24'd0, rb_d && (st_d || mant_d[0])};
            exp_rr  = {3'd0, d2_msb} - 10'sd68 + 10'sd127;
            if (mant_rr[24]) begin
                mant_rr = mant_rr >> 1;
                exp_rr  = exp_rr + 10'sd1;
            end
            // accumulator range cannot underflow FP32 subnormal thresholds
            // above (min weight 2^-68 > FP32 min subnormal 2^-149) but can
            // land in the subnormal band: exp <= 0 -> gradual underflow
            if (exp_rr >= 10'sd255) begin
                res_c = {d2_sign, 8'hFF, 23'd0};
            end else if (exp_rr < 10'sd1) begin
                // rare: tiny sums; shift right and live with double rounding
                // risk being nil because bits below 2^-68 are all zero
                res_c = {d2_sign, 8'd0,
                         mant_rr[23:1] >> (10'sd1 - exp_rr)};
            end else begin
                res_c = {d2_sign, exp_rr[7:0], mant_rr[22:0]};
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result_valid <= 1'b0;
            result       <= 32'd0;
        end else begin
            result_valid <= d2_valid;
            result       <= res_c;
        end
    end

endmodule
