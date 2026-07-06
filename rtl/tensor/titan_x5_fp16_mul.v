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
 * Module: titan_x5_fp16_mul
 * Description: IEEE 754 Half-Precision Floating Point Multiplier.
 *
 * Fully compliant combinational FP16 multiply with:
 *   - subnormal inputs (pre-normalization) and subnormal outputs
 *     (gradual underflow),
 *   - NaN propagation (canonical qNaN 0x7E00), Inf * 0 -> qNaN,
 *   - round-to-nearest-even.
 *
 * Port-compatible with the original module (a, b, result), used by the
 * tensor cores.
 */
module titan_x5_fp16_mul (
    input  wire [15:0] a,
    input  wire [15:0] b,
    output reg  [15:0] result
);

    localparam [15:0] QNAN16 = 16'h7E00;

    wire       sa = a[15],      sb = b[15];
    wire [4:0] ea = a[14:10],   eb = b[14:10];
    wire [9:0] fa = a[9:0],     fb = b[9:0];

    wire a_nan  = (ea == 5'h1F) && (fa != 0);
    wire b_nan  = (eb == 5'h1F) && (fb != 0);
    wire a_inf  = (ea == 5'h1F) && (fa == 0);
    wire b_inf  = (eb == 5'h1F) && (fb == 0);
    wire a_zero = (ea == 0) && (fa == 0);
    wire b_zero = (eb == 0) && (fb == 0);

    wire sign_res = sa ^ sb;

    // subnormal pre-normalization
    wire [10:0] ma_raw = {(ea != 0), fa};
    wire [10:0] mb_raw = {(eb != 0), fb};

    integer i, j;
    reg [3:0] clz_a, clz_b;
    always @(*) begin
        clz_a = 4'd0;
        for (i = 0; i <= 10; i = i + 1)
            if (ma_raw[i]) clz_a = 4'd10 - i[3:0];
        clz_b = 4'd0;
        for (i = 0; i <= 10; i = i + 1)
            if (mb_raw[i]) clz_b = 4'd10 - i[3:0];
    end

    wire [10:0] ma_n = ma_raw << clz_a;
    wire [10:0] mb_n = mb_raw << clz_b;

    wire signed [7:0] ea_eff = (ea == 0) ? (8'sd1 - {4'd0, clz_a}) : {3'd0, ea};
    wire signed [7:0] eb_eff = (eb == 0) ? (8'sd1 - {4'd0, clz_b}) : {3'd0, eb};
    wire signed [7:0] exp_sum = ea_eff + eb_eff - 8'sd15;

    wire [21:0] prod = ma_n * mb_n;

    reg  [10:0]       mant_n;
    reg               g_n, st_n;
    reg signed [7:0]  exp_n;
    reg  [12:0]       den_src, den_shifted;
    reg signed [7:0]  den_amt;
    reg  [10:0]       mant_d;
    reg               rb, st;
    reg               rnd_inc;
    reg  [11:0]       mant_r;
    reg signed [7:0]  exp_r;

    always @(*) begin
        result = 16'd0;
        mant_n = 11'd0; g_n = 1'b0; st_n = 1'b0; exp_n = 8'sd0;
        den_src = 13'd0; den_shifted = 13'd0; den_amt = 8'sd0;
        mant_d = 11'd0; rb = 1'b0; st = 1'b0; rnd_inc = 1'b0;
        mant_r = 12'd0; exp_r = 8'sd0;

        if (a_nan || b_nan) begin
            result = QNAN16;
        end else if ((a_inf && b_zero) || (a_zero && b_inf)) begin
            result = QNAN16;
        end else if (a_inf || b_inf) begin
            result = {sign_res, 5'h1F, 10'd0};
        end else if (a_zero || b_zero) begin
            result = {sign_res, 15'd0};
        end else begin
            // product of two normalized 11-bit mantissas: [2^20, 2^22)
            if (prod[21]) begin
                mant_n = prod[21:11];
                g_n    = prod[10];
                st_n   = |prod[9:0];
                exp_n  = exp_sum + 8'sd1;
            end else begin
                mant_n = prod[20:10];
                g_n    = prod[9];
                st_n   = |prod[8:0];
                exp_n  = exp_sum;
            end

            if (exp_n < 8'sd1) begin
                // gradual underflow
                den_amt = 8'sd1 - exp_n;
                if (den_amt > 8'sd13) den_amt = 8'sd13;
                den_src = {mant_n, g_n, st_n};
                den_shifted = den_src >> den_amt[3:0];
                st = st_n;
                for (j = 0; j < 13; j = j + 1) begin
                    if (j < den_amt) st = st | den_src[j];
                end
                mant_d = den_shifted[12:2];
                rb     = den_shifted[1];
                st     = st | den_shifted[0];
                exp_r  = 8'sd1;
            end else begin
                mant_d = mant_n;
                rb     = g_n;
                st     = st_n;
                exp_r  = exp_n;
            end

            // round to nearest even
            rnd_inc = rb && (st || mant_d[0]);
            mant_r  = {1'b0, mant_d} + {10'd0, rnd_inc};
            if (mant_r[11]) begin
                mant_r = mant_r >> 1;
                exp_r  = exp_r + 8'sd1;
            end

            if (exp_r >= 8'sd31 && mant_r[10]) begin
                result = {sign_res, 5'h1F, 10'd0};  // overflow -> Inf (RNE)
            end else begin
                // hidden-bit encoding: subnormal when MSB is 0 (exp_r == 1)
                result = {sign_res,
                          mant_r[10] ? exp_r[4:0] : 5'd0,
                          mant_r[9:0]};
            end
        end
    end

endmodule
