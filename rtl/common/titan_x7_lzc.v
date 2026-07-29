// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Logarithmic-depth most-significant-set-bit detector.
//
// WHY THIS EXISTS
//
// titan_x7_fp32_fma_pipe's header describes E6 as a "106-bit CLZ tree". It
// was not a tree. It was written as
//
//     for (m = 0; m <= 105; m = m + 1)
//         if (e5_sum[m]) msb_idx_c = m[6:0];
//
// which is a linear priority scan: 106 chained conditional overwrites, i.e.
// ~106 levels of 7-bit mux, with the normalized-exponent add serialised
// behind it. After the E5 adders were made parallel-prefix, this became the
// dominant path in the GT2N 2 nm mapping (docs/GT2N_2NM_SYNTHESIS.md).
//
// The same shape appears three times in E1 as 24-bit subnormal CLZs.
//
// STRUCTURE
//
// A balanced binary reduction. Each node reports "is any bit of my range
// set" and "index of the highest set bit within my range":
//
//     nz[l+1][j] = nz[l][2j+1] | nz[l][2j]
//     ix[l+1][j] = nz[l][2j+1] ? (ix[l][2j+1] | 1<<l) : ix[l][2j]
//
// Depth is LW = log2(W) levels of one OR plus one mux, rather than W levels
// of mux.
//
// W must be a power of two and equal 2**LW; callers with a non-power-of-two
// vector zero-extend, which is harmless because zero-padding the high end
// cannot introduce a new most-significant set bit.
//
// `idx` is the bit position of the highest set bit, and reads 0 when the
// input is all zero -- matching the behaviour of the linear loops this
// replaces, which left their accumulator at its 0 initialiser. `nz`
// distinguishes "index 0" from "empty" for callers that care.
module titan_x7_lzc #(
    parameter W  = 128,
    parameter LW = 7           // must satisfy 2**LW == W
) (
    input  wire [W-1:0]  vec,
    output wire [LW-1:0] idx,
    output wire          nz
);

    genvar l, j;

    // Level l holds W>>l nodes. Flattened: node j of level l is at
    // nz_f[l*W + j] and ix_f[(l*W + j)*LW +: LW].
    wire [(LW+1)*W-1:0]    nz_f;
    wire [(LW+1)*W*LW-1:0] ix_f;

    generate
        // leaves
        for (j = 0; j < W; j = j + 1) begin : leaf
            assign nz_f[j] = vec[j];
            assign ix_f[j*LW +: LW] = {LW{1'b0}};
        end

        for (l = 0; l < LW; l = l + 1) begin : level
            for (j = 0; j < (W >> (l+1)); j = j + 1) begin : node
                wire lo_nz = nz_f[l*W + 2*j];
                wire hi_nz = nz_f[l*W + 2*j + 1];
                wire [LW-1:0] lo_ix = ix_f[(l*W + 2*j)*LW     +: LW];
                wire [LW-1:0] hi_ix = ix_f[(l*W + 2*j + 1)*LW +: LW];

                assign nz_f[(l+1)*W + j] = hi_nz | lo_nz;
                // Taking the high child when it is non-empty is what makes
                // this a MOST-significant-bit detector; bit l of the index
                // records that choice.
                assign ix_f[((l+1)*W + j)*LW +: LW] =
                    hi_nz ? (hi_ix | ({{(LW-1){1'b0}}, 1'b1} << l)) : lo_ix;
            end
        end
    endgenerate

    assign idx = ix_f[(LW*W)*LW +: LW];
    assign nz  = nz_f[LW*W];

endmodule
