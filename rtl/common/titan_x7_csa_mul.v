// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Carry-save 24x24 multiplier: a*b delivered as two vectors whose SUM is the
// product, with no carry-propagate adder anywhere inside.
//
// WHY THIS EXISTS
//
// Same root cause as titan_x7_prefix_add, third instance of it. GT2N's 69
// logic cells contain no full adder, no half adder and no carry cell, so any
// structure that ends in a carry chain is expensive. E3 was
//
//     wire [35:0] pp_lo = e2_ma * e2_mb[11:0];
//     wire [35:0] pp_hi = e2_ma * e2_mb[23:12];
//
// and each `*` makes the synthesiser build an array multiplier that finishes
// with its own internal CPA -- two ripple adders, in a stage that then hands
// its result to a prefix adder in E4 anyway. Measured: with the E8 denormal
// chain hoisted into E7, `stime -p` named `e2_ma[2]` as the start-point of the
// critical path at 406.20 ps.
//
// The fix is to never form the completed products. The 24 partial-product rows
// are reduced by 3:2 carry-save layers to a (sum, carry) pair, and E4's
// existing titan_x7_prefix_add does the single carry propagation the design
// needs. A 3:2 layer is one XOR3 plus one majority gate -- constant depth, no
// carry chain -- so 24 rows collapse in 7 layers.
//
//   rows   24 -> 16 -> 11 -> 8 -> 6 -> 4 -> 3 -> 2
//
// WHY TRUNCATING THE CARRY AT 48 BITS IS EXACT
//
// The carry vector is shifted left by one and truncated to W bits at every
// layer. That is safe because the CSA identity
//
//     x + y + z  ==  (x^y^z) + 2*((x&y)|(x&z)|(y&z))
//
// holds modulo 2**W when both sides are truncated to W bits. The tree
// therefore preserves the row total mod 2**48, and a 24x24 product is at most
// (2**24-1)**2 < 2**48, so the congruence is an equality. Proven, not argued:
// see syn/gt2n/prove_csa_mul.ys.
module titan_x7_csa_layer #(
    parameter W    = 48,
    parameter NIN  = 24,
    // Must equal 2*(NIN/3) + (NIN%3). A parameter rather than a localparam
    // because Verilog-2001 port widths may not depend on a body localparam.
    parameter NOUT = 16
) (
    input  wire [NIN*W-1:0]  din,
    output wire [NOUT*W-1:0] dout
);

    localparam NG = NIN / 3;          // full 3:2 compressor groups
    localparam NL = NIN - 3 * NG;     // 0, 1 or 2 rows that pass through

    genvar q;
    generate
        for (q = 0; q < NG; q = q + 1) begin : compress
            wire [W-1:0] x = din[(3*q    )*W +: W];
            wire [W-1:0] y = din[(3*q + 1)*W +: W];
            wire [W-1:0] z = din[(3*q + 2)*W +: W];
            wire [W-1:0] maj = (x & y) | (x & z) | (y & z);

            assign dout[(2*q    )*W +: W] = x ^ y ^ z;
            assign dout[(2*q + 1)*W +: W] = {maj[W-2:0], 1'b0};
        end
        // A layer whose row count is not a multiple of 3 carries the odd rows
        // forward untouched rather than padding with zeros; padding would cost
        // a compressor per zero row for no reduction.
        for (q = 0; q < NL; q = q + 1) begin : passthrough
            assign dout[(2*NG + q)*W +: W] = din[(3*NG + q)*W +: W];
        end
    endgenerate

endmodule


module titan_x7_csa_mul24 (
    input  wire [23:0] a,
    input  wire [23:0] b,
    output wire [47:0] s,
    output wire [47:0] c
);

`ifdef TITAN_FAST_SIM
    // ------------------------------------------------------------------
    // Behavioural form, for SIMULATION ONLY -- same argument as
    // titan_x7_prefix_add. The structural tree below is 7 layers of 48-bit
    // gates and an event-driven simulator pays per gate per event.
    //
    // (a*b, 0) is a valid carry-save decomposition of the product, and the
    // structural form is SAT-proven to be another one, so the swap is
    // licensed by proof rather than by inspection.
    //
    // Synthesis must NEVER see this branch: `TITAN_FAST_SIM` is defined only
    // by tb/run_regression.py, never by syn/gt2n/run_gt2n.sh.
    // ------------------------------------------------------------------
    assign s = a * b;
    assign c = 48'd0;
`else
    // Partial-product rows. Row r is `a` masked by b[r], weighted by 2**r.
    // r <= 23 and `a` is 24 bits, so the top live bit is 46 and nothing is
    // lost off the top of the 48-bit row.
    wire [24*48-1:0] row0;
    genvar r;
    generate
        for (r = 0; r < 24; r = r + 1) begin : ppgen
            assign row0[r*48 +: 48] = {24'd0, (a & {24{b[r]}})} << r;
        end
    endgenerate

    wire [16*48-1:0] row1;
    wire [11*48-1:0] row2;
    wire [ 8*48-1:0] row3;
    wire [ 6*48-1:0] row4;
    wire [ 4*48-1:0] row5;
    wire [ 3*48-1:0] row6;
    wire [ 2*48-1:0] row7;

    titan_x7_csa_layer #(.W(48), .NIN(24), .NOUT(16)) u_l1 (.din(row0), .dout(row1));
    titan_x7_csa_layer #(.W(48), .NIN(16), .NOUT(11)) u_l2 (.din(row1), .dout(row2));
    titan_x7_csa_layer #(.W(48), .NIN(11), .NOUT( 8)) u_l3 (.din(row2), .dout(row3));
    titan_x7_csa_layer #(.W(48), .NIN( 8), .NOUT( 6)) u_l4 (.din(row3), .dout(row4));
    titan_x7_csa_layer #(.W(48), .NIN( 6), .NOUT( 4)) u_l5 (.din(row4), .dout(row5));
    titan_x7_csa_layer #(.W(48), .NIN( 4), .NOUT( 3)) u_l6 (.din(row5), .dout(row6));
    titan_x7_csa_layer #(.W(48), .NIN( 3), .NOUT( 2)) u_l7 (.din(row6), .dout(row7));

    assign s = row7[0*48 +: 48];
    assign c = row7[1*48 +: 48];
`endif

endmodule
