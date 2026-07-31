// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// TITAN APEX-X: precision-scalable segmented multiplier.
//
// WHY THIS EXISTS -- the throughput arithmetic that forces it
//
// titan_x7_tensor_pe is FP16-in / FP32-out: an 11x11 mantissa multiply. At
// 40,000 lanes and the measured 2.49 GHz it delivers 199.2 TFLOPS FP16. Even
// with perfect 2x FP8 / 4x FP4 packing that is 398 / 797 TOPS, against an RTX
// 5090's 838 TFLOPS FP8 and 1,676 TOPS FP4 dense -- a 2x LOSS.
//
// Winning requires more MACs per lane, not a faster lane, and the only place
// they can come from is subdividing a wider multiplier. An FP32 mantissa
// multiply is 24x24 = 576 bit-products; FP16 needs 4x121=484, FP8 4-bit
// mantissas need 16x16=256, FP4 2-bit need 16x4=64. All fit. That is the
// whole argument for building the datapath at FP32 width and segmenting it.
//
// STRUCTURE
//
// A 4x4 grid of 6x6 unsigned multiplier tiles. Operand a is split into four
// 6-bit slices a0..a3 (a3 most significant), b likewise. Tile (i,j) computes
// a_i * b_j and carries weight 2^(6*(i+j)).
//
//   MODE_FULL : one 24x24 product. Every tile contributes at its weight --
//               the standard partial-product decomposition, exact.
//   MODE_HALF : four independent 12x12 products, one per 2x2 tile quadrant.
//               Quadrant (I,J) uses a-slices {2I,2I+1} and b-slices {2J,2J+1},
//               so the four results are the OUTER PRODUCT of two a-halves and
//               two b-halves. That is precisely what a systolic tensor tile
//               wants: two A operands against two B operands.
//   MODE_TILE : sixteen independent 6x6 products, the raw tiles. Enough for
//               a 4-bit FP8 mantissa or a 2-bit FP4 mantissa with headroom.
//
// The tiles are always evaluated; only the summation network is switched.
// That keeps the multiplier array identical in every mode -- no duplicated
// silicon -- and confines the mode logic to the adder tree.
//
// This module is the MANTISSA core only. Exponent handling, subnormals,
// specials and the accumulator frame belong to the enclosing PE, exactly as
// they do in titan_x7_tensor_pe: separating them is what let that PE keep a
// single-compressor accumulate loop.
module titan_apex_mult_seg #(
    parameter TILE = 6,                    // bits per operand slice
    parameter NT   = 4                     // slices per operand (NT*TILE = 24)
) (
    input  wire [NT*TILE-1:0]      a,
    input  wire [NT*TILE-1:0]      b,
    input  wire [1:0]              mode,

    // MODE_FULL: full[2*NT*TILE-1:0] is the exact 24x24 product.
    output wire [2*NT*TILE-1:0]    full,
    // MODE_HALF: four exact 12x12 products, quadrant-major {I,J}.
    output wire [4*2*2*TILE-1:0]   half,
    // MODE_TILE: sixteen exact 6x6 products, tile-major (i*NT + j).
    output wire [NT*NT*2*TILE-1:0] tile
);

    localparam W    = NT*TILE;             // 24
    localparam MODE_FULL = 2'd0;
    localparam MODE_HALF = 2'd1;
    localparam MODE_TILE = 2'd2;

    genvar i, j;

    // ---- the tile array: always evaluated, mode-independent -------------
    wire [2*TILE-1:0] pp [0:NT-1][0:NT-1];

    generate
        for (i = 0; i < NT; i = i + 1) begin : g_ai
            for (j = 0; j < NT; j = j + 1) begin : g_bj
                assign pp[i][j] = a[i*TILE +: TILE] * b[j*TILE +: TILE];
            end
        end
    endgenerate

    // ---- MODE_TILE: the tiles, unmodified -------------------------------
    generate
        for (i = 0; i < NT; i = i + 1) begin : g_tile_i
            for (j = 0; j < NT; j = j + 1) begin : g_tile_j
                assign tile[(i*NT + j)*2*TILE +: 2*TILE] = pp[i][j];
            end
        end
    endgenerate

    // ---- MODE_HALF: four 12x12 products from 2x2 tile quadrants ---------
    // Quadrant (I,J) multiplies {a[2I+1],a[2I]} by {b[2J+1],b[2J]}:
    //   (ah*2^T + al) * (bh*2^T + bl)
    //     = ah*bh*2^2T + (ah*bl + al*bh)*2^T + al*bl
    generate
        for (i = 0; i < 2; i = i + 1) begin : g_half_i
            for (j = 0; j < 2; j = j + 1) begin : g_half_j
                wire [4*TILE-1:0] q =
                      ({{(2*TILE){1'b0}}, pp[2*i+1][2*j+1]} << (2*TILE))
                    + ({{(2*TILE){1'b0}}, pp[2*i+1][2*j  ]} <<    TILE )
                    + ({{(2*TILE){1'b0}}, pp[2*i  ][2*j+1]} <<    TILE )
                    + ({{(2*TILE){1'b0}}, pp[2*i  ][2*j  ]});
                assign half[(i*2 + j)*4*TILE +: 4*TILE] = q;
            end
        end
    endgenerate

    // ---- MODE_FULL: every tile at weight 2^(TILE*(i+j)) -----------------
    // Each tile is zero-extended to the full product width and shifted to its
    // weight, then the 16 terms are reduced by a balanced tree (4 levels)
    // rather than a 16-deep chain. Every partial product is exact and no
    // term is truncated, so the sum is the exact 24x24 product.
    wire [2*W-1:0] term [0:NT*NT-1];

    generate
        for (i = 0; i < NT; i = i + 1) begin : g_term_i
            for (j = 0; j < NT; j = j + 1) begin : g_term_j
                assign term[i*NT + j] =
                    {{(2*W - 2*TILE){1'b0}}, pp[i][j]} << (TILE*(i+j));
            end
        end
    endgenerate

    // level 1: 16 -> 8
    wire [2*W-1:0] l1 [0:7];
    // level 2: 8 -> 4
    wire [2*W-1:0] l2 [0:3];
    // level 3: 4 -> 2
    wire [2*W-1:0] l3 [0:1];

    generate
        for (i = 0; i < 8; i = i + 1) begin : g_l1
            assign l1[i] = term[2*i] + term[2*i+1];
        end
        for (i = 0; i < 4; i = i + 1) begin : g_l2
            assign l2[i] = l1[2*i] + l1[2*i+1];
        end
        for (i = 0; i < 2; i = i + 1) begin : g_l3
            assign l3[i] = l2[2*i] + l2[2*i+1];
        end
    endgenerate

    assign full = l3[0] + l3[1];

endmodule
