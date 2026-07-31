// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// TITAN APEX-X: dynamic-precision multiply-accumulate.
//
// WHY
//
// syn/gt2n/results/apex_x_throughput.txt: at 40,000 lanes and the measured
// 2.49 GHz, an FP16-width tensor PE reaches 398 TOPS FP8 and 797 TOPS FP4
// against an RTX 5090's 838 / 1,676 dense -- a 2x loss. The extra MACs have
// to come from segmenting an FP32-width multiplier, which is what
// titan_apex_mult_seg does. This is the accumulator around it.
//
// MACs per cycle, by mode:
//
//   MODE_FULL  1  x 24x24     one full-width product
//   MODE_HALF  4  x 12x12     2x2 outer product of the operand halves
//   MODE_TILE  16 x  6x6      every tile independent
//
// which meets or exceeds the 4x / 8x / 16x the architecture spec asks for.
//
// EXACTNESS
//
// Accumulation is INTEGER and exact. Products are sign-extended to the
// accumulator width and summed; nothing is rounded, saturated or truncated
// anywhere in the loop, so a dot product of any length is exact provided it
// fits ACC_W. That is the same Kulisch argument titan_x7_tensor_pe uses for
// its fixed-point frame, minus the floating-point framing.
//
// ACC_W defaults to 48 + $clog2 headroom: a 24x24 signed product needs 48
// bits, and GUARD extra bits allow 2^GUARD accumulations without overflow.
// At the default GUARD=16 that is 65,536 terms, well past any tile depth.
//
// SIGNEDNESS
//
// `is_signed` selects two's-complement operands. The segmented multiplier is
// unsigned, so signed operands are corrected after the fact with the standard
// identity: for W-bit values, signed(a)*signed(b) = unsigned(a)*unsigned(b)
// - a_sign*b*2^W - b_sign*a*2^W. Doing it this way keeps ONE multiplier array
// shared by both modes rather than duplicating it, which is the entire point
// of segmenting in the first place.
//
// WHAT THIS IS NOT
//
// This is the integer datapath. FP8/FP4 tensor formats additionally need an
// exponent path -- in practice a per-block scale factor (block floating
// point), which is how production FP4 inference works, rather than a full
// per-element exponent. That layer sits ON TOP of this MAC and is not built
// here. The FP16 path with real per-element exponents already exists
// separately as titan_x7_tensor_pe.
module titan_apex_dp_mac #(
    parameter TILE  = 6,
    parameter NT    = 4,                    // NT*TILE = 24
    parameter GUARD = 16,
    parameter ACC_W = 2*NT*TILE + GUARD     // 64
) (
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     mac_valid,
    input  wire [1:0]               mode,
    input  wire                     is_signed,
    input  wire [NT*TILE-1:0]       a,
    input  wire [NT*TILE-1:0]       b,

    // acc_clear zeroes the accumulator on the same cycle it is read, so a
    // new tile can start immediately after a drain with no dead cycle.
    input  wire                     acc_clear,
    output reg  signed [ACC_W-1:0]  acc,
    output reg                      acc_valid
);

    localparam W = NT*TILE;                 // 24

    localparam MODE_FULL = 2'd0;
    localparam MODE_HALF = 2'd1;
    localparam MODE_TILE = 2'd2;

    // ---- the shared multiplier array ------------------------------------
    wire [2*W-1:0]         m_full;
    wire [4*4*TILE-1:0]    m_half;          // 4 x 24-bit
    wire [NT*NT*2*TILE-1:0] m_tile;         // 16 x 12-bit

    titan_apex_mult_seg #(.TILE(TILE), .NT(NT)) u_mult (
        .a(a), .b(b), .mode(mode),
        .full(m_full), .half(m_half), .tile(m_tile)
    );

    integer k;

    // ---- signed correction ----------------------------------------------
    // Applied per active product at its own width. For a P-bit slice pair,
    // subtracting a_sign*b*2^P and b_sign*a*2^P converts the unsigned
    // product into the two's-complement one.
    function signed [ACC_W-1:0] fix_signed;
        input [2*W-1:0] prod;               // unsigned product, right-aligned
        input [W-1:0]   av;                 // operand slice a
        input [W-1:0]   bv;                 // operand slice b
        input integer   p;                  // slice width in bits
        reg signed [ACC_W-1:0] r;
        begin
            // (ua - sa*2^p)(ub - sb*2^p)
            //   = ua*ub - sa*2^p*ub - sb*2^p*ua + sa*sb*2^2p
            // All four terms are required. Dropping the last one is only
            // invisible while at most one operand is negative, which is why
            // the suite drives both-negative cases explicitly.
            r = $signed({{(ACC_W-2*W){1'b0}}, prod});
            if (is_signed) begin
                if (av[p-1]) r = r - ($signed({{(ACC_W-W){1'b0}}, bv}) <<< p);
                if (bv[p-1]) r = r - ($signed({{(ACC_W-W){1'b0}}, av}) <<< p);
                if (av[p-1] && bv[p-1])
                    r = r + ($signed({{(ACC_W-1){1'b0}}, 1'b1}) <<< (2*p));
            end
            fix_signed = r;
        end
    endfunction

    // ---- per-mode product sum -------------------------------------------
    // A balanced tree would be preferable at 16 terms; the sum is written as
    // a loop here because the enclosing PE registers `sum_c` and the array is
    // what dominates area, not this adder. If this becomes the critical path
    // it should be re-expressed with titan_x7_prefix_add, exactly as the FMA
    // and tensor PE were.
    reg signed [ACC_W-1:0] sum_c;
    reg [W-1:0] as, bs;

    always @(*) begin
        sum_c = {ACC_W{1'b0}};
        case (mode)
            MODE_FULL: begin
                sum_c = fix_signed(m_full, a, b, W);
            end
            MODE_HALF: begin
                for (k = 0; k < 4; k = k + 1) begin
                    as = (a >> ((k >> 1) * 2*TILE)) & ((1 << (2*TILE)) - 1);
                    bs = (b >> ((k & 1)  * 2*TILE)) & ((1 << (2*TILE)) - 1);
                    sum_c = sum_c + fix_signed(
                        {{(2*W-4*TILE){1'b0}}, m_half[k*4*TILE +: 4*TILE]},
                        as, bs, 2*TILE);
                end
            end
            MODE_TILE: begin
                for (k = 0; k < NT*NT; k = k + 1) begin
                    as = (a >> ((k / NT) * TILE)) & ((1 << TILE) - 1);
                    bs = (b >> ((k % NT) * TILE)) & ((1 << TILE) - 1);
                    sum_c = sum_c + fix_signed(
                        {{(2*W-2*TILE){1'b0}}, m_tile[k*2*TILE +: 2*TILE]},
                        as, bs, TILE);
                end
            end
            default: sum_c = {ACC_W{1'b0}};
        endcase
    end

    // ---- accumulator ------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc       <= {ACC_W{1'b0}};
            acc_valid <= 1'b0;
        end else begin
            acc_valid <= mac_valid;
            if (acc_clear)
                acc <= mac_valid ? sum_c : {ACC_W{1'b0}};
            else if (mac_valid)
                acc <= acc + sum_c;
        end
    end

endmodule
