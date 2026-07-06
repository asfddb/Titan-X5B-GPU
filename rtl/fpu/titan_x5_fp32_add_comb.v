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
 * Titan X5 GPU - Combinational IEEE-754 FP32 Adder (round-to-nearest-even)
 *
 * Single-cycle flattening of the titan_x5_fp32_add pipeline datapath, for
 * datapaths that need a same-cycle accumulate (tensor-core MAC loop).
 * Same algorithm and special-case handling:
 *   - subnormal inputs/outputs, signed zeros (exact cancellation -> +0),
 *   - NaN -> canonical qNaN 0x7FC00000, Inf-Inf -> qNaN,
 *   - guard/round/sticky with borrow-corrected subtraction sticky,
 *   - alignment shift clamped at 27 so the sticky bit is never lost.
 * Rounding is fixed at RNE (the accumulate path has no rounding-mode CSR).
 */
module titan_x5_fp32_add_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] result
);

    localparam [31:0] QNAN = 32'h7FC00000;

    // unpack / classify
    wire        sa = a[31],       sb = b[31];
    wire [7:0]  ea = a[30:23],    eb = b[30:23];
    wire [22:0] fa = a[22:0],     fb = b[22:0];

    wire a_nan  = (ea == 8'hFF) && (fa != 0);
    wire b_nan  = (eb == 8'hFF) && (fb != 0);
    wire a_inf  = (ea == 8'hFF) && (fa == 0);
    wire b_inf  = (eb == 8'hFF) && (fb == 0);
    wire a_zero = (ea == 0) && (fa == 0);
    wire b_zero = (eb == 0) && (fb == 0);

    // magnitude ordering (bit-pattern compare of {exp,frac} is monotonic)
    wire a_ge_b = {ea, fa} >= {eb, fb};

    wire        sx    = a_ge_b ? sa : sb;
    wire        sy    = a_ge_b ? sb : sa;
    wire [7:0]  ex_r  = a_ge_b ? ea : eb;
    wire [7:0]  ey_r  = a_ge_b ? eb : ea;
    wire [22:0] fx    = a_ge_b ? fa : fb;
    wire [22:0] fy    = a_ge_b ? fb : fa;

    wire [7:0]  ex_eff = (ex_r == 0) ? 8'd1 : ex_r;
    wire [7:0]  ey_eff = (ey_r == 0) ? 8'd1 : ey_r;
    wire [23:0] mx     = {(ex_r != 0), fx};
    wire [23:0] my     = {(ey_r != 0), fy};

    wire [7:0] exp_diff = ex_eff - ey_eff;
    wire [7:0] d_clamp  = (exp_diff > 8'd27) ? 8'd27 : exp_diff;

    // 27-bit datapath: [26:3] mantissa, [2] guard, [1] round, [0] sticky pos
    wire [26:0] x_ext = {mx, 3'b000};
    wire [53:0] y_wide = {my, 3'b000, 27'd0} >> d_clamp;
    wire [26:0] y_ext      = y_wide[53:27];
    wire        sticky_pre = |y_wide[26:0];

    wire eff_sub = sx ^ sy;

    // add/sub with borrow-corrected sticky
    wire [27:0] sum_add = {1'b0, x_ext} + {1'b0, y_ext};
    wire [27:0] sum_sub = {1'b0, x_ext} - {1'b0, y_ext} - {27'd0, sticky_pre};
    wire [27:0] sum     = eff_sub ? sum_sub : sum_add;

    // normalize / round (RNE) / pack
    integer i;
    reg [4:0]  lz, shift_lim;
    reg [26:0] norm;
    reg [9:0]  exp_n;
    reg        sticky_n;
    reg [23:0] mant_n;
    reg        rb, st, rnd_inc;
    reg [24:0] mant_r;
    reg [9:0]  exp_r;

    always @(*) begin
        lz = 5'd0; shift_lim = 5'd0; norm = 27'd0; exp_n = 10'd0;
        sticky_n = 1'b0; mant_n = 24'd0; rb = 1'b0; st = 1'b0;
        rnd_inc = 1'b0; mant_r = 25'd0; exp_r = 10'd0;
        result = 32'd0;

        if (a_nan || b_nan) begin
            result = QNAN;
        end else if (a_inf && b_inf) begin
            result = (sa != sb) ? QNAN : {sa, 8'hFF, 23'd0};
        end else if (a_inf) begin
            result = {sa, 8'hFF, 23'd0};
        end else if (b_inf) begin
            result = {sb, 8'hFF, 23'd0};
        end else if (a_zero && b_zero) begin
            result = {sa & sb, 31'd0}; // opposite signs -> +0 under RNE
        end else if (sum == 28'd0 && !sticky_pre) begin
            result = 32'd0;            // exact cancellation -> +0 under RNE
        end else begin
            if (sum[27]) begin
                norm     = sum[27:1];
                sticky_n = sticky_pre | sum[0];
                exp_n    = {2'b00, ex_eff} + 10'd1;
            end else begin
                for (i = 0; i <= 26; i = i + 1)
                    if (sum[i]) lz = 5'd26 - i[4:0];
                shift_lim = (({5'd0, ex_eff} - 10'd1) > 10'd26) ? 5'd26
                          : (ex_eff[4:0] - 5'd1);
                if (ex_eff > 8'd27) shift_lim = 5'd26;
                if (lz > shift_lim) lz = shift_lim;
                norm     = sum[26:0] << lz;
                sticky_n = sticky_pre;
                exp_n    = {2'b00, ex_eff} - {5'd0, lz};
            end

            mant_n  = norm[26:3];
            rb      = norm[2];
            st      = norm[1] | norm[0] | sticky_n;
            rnd_inc = rb && (st || mant_n[0]);     // RNE
            mant_r  = {1'b0, mant_n} + {24'd0, rnd_inc};
            exp_r   = exp_n;
            if (mant_r[24]) begin
                mant_r = mant_r >> 1;
                exp_r  = exp_r + 10'd1;
            end

            if (exp_r >= 10'd255 && mant_r[23]) begin
                result = {sx, 8'hFF, 23'd0};       // overflow -> Inf (RNE)
            end else begin
                result = {sx,
                          mant_r[23] ? exp_r[7:0] : 8'd0,
                          mant_r[22:0]};
            end
        end
    end

endmodule
