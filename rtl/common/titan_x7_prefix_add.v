// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Kogge-Stone parallel-prefix adder.
//
// WHY THIS EXISTS
//
// docs/GT2N_2NM_SYNTHESIS.md measured the x7 FMA's critical path on the GT2N
// 2 nm PDK at 58 gate levels, and `stime -p` named the cause: alternating
// or3/nor3/nand3 then oai21/aoi21 -- ripple carry. GT2N's 69 logic cells
// contain no full adder, no half adder and no carry cell, so a bare `+` on a
// 106-bit vector leaves the synthesiser nothing to build from and it emits a
// long carry chain.
//
// A parallel-prefix adder fixes that in RTL, where the structure is explicit
// and cannot be lost. Carry depth goes from O(W) to O(log2 W): for W = 106
// that is 7 prefix levels instead of a ~106-long chain, at the cost of
// O(W log W) area.
//
// STRUCTURE
//
//   level 0     g[i] = a[i] & b[i],  p[i] = a[i] ^ b[i]
//               carry-in folded into g[0]
//   level k     (G,P)[i] = (G[i] | P[i] & G[i-2^k],  P[i] & P[i-2^k])
//   sum         sum[i] = p[i] ^ carry[i-1],  carry[i] = G_final[i]
//
// Kogge-Stone rather than Brent-Kung because it is the shallowest of the
// standard prefix forms and depth is what is being bought here; its extra
// wiring is the deliberate trade.
//
// LEVELS must satisfy 2**LEVELS >= W. It is a parameter rather than
// $clog2(W) so a caller can over-provision without editing this file; extra
// levels are harmless (they degenerate to pass-through) but cost area.
module titan_x7_prefix_add #(
    parameter W      = 106,
    parameter LEVELS = 7
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    input  wire         cin,
    output wire [W-1:0] sum,
    output wire         cout
);

    genvar l, i;

    wire [W-1:0] g0 = a & b;
    wire [W-1:0] p0 = a ^ b;

    // Flattened prefix arrays, (LEVELS+1) planes of W bits each.
    wire [(LEVELS+1)*W-1:0] gg;
    wire [(LEVELS+1)*W-1:0] pp;

    // Fold the carry-in into bit 0's generate term. Every other bit is
    // unchanged at level 0.
    assign gg[0 +: W] = g0 | (p0 & {{(W-1){1'b0}}, cin});
    assign pp[0 +: W] = p0;

    generate
        for (l = 0; l < LEVELS; l = l + 1) begin : prefix_level
            for (i = 0; i < W; i = i + 1) begin : prefix_bit
                if (i >= (1 << l)) begin : combine
                    assign gg[(l+1)*W + i] =
                        gg[l*W + i] | (pp[l*W + i] & gg[l*W + i - (1 << l)]);
                    assign pp[(l+1)*W + i] =
                        pp[l*W + i] & pp[l*W + i - (1 << l)];
                end else begin : pass
                    assign gg[(l+1)*W + i] = gg[l*W + i];
                    assign pp[(l+1)*W + i] = pp[l*W + i];
                end
            end
        end
    endgenerate

    // carry[i] is the carry OUT of bit i.
    wire [W-1:0] carry = gg[LEVELS*W +: W];

    assign sum  = p0 ^ {carry[W-2:0], cin};
    assign cout = carry[W-1];

endmodule
