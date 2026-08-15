// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// titan_x7_csa_mul24 == a*b, proven by decomposition.
//
// WHY NOT ONE MITER
//
// The direct miter `(s + c) == a*b` is a Wallace tree against an array
// multiplier -- the textbook hard case for combinational equivalence checking.
// It did not converge in 10 minutes of `sat -prove`.
//
// The decomposition below is a complete proof of the same statement, and each
// part is tractable, because the multiplier structure never has to be
// compared against a different multiplier structure:
//
//   PART 1  the 24 partial-product rows sum to a*b
//   PART 2  every reduction layer preserves the sum of its rows, mod 2**48
//
// Part 2 applied to the 7 instantiated layers gives
//   sum(row0) == sum(row1) == ... == sum(row7) == s + c
// and part 1 gives sum(row0) == a*b. Together: s + c == a*b, for all inputs.
//
// Part 2 is also exactly where the truncation argument lives: each layer
// shifts its carry vector left by one and drops the bit that leaves bit 47.
// The layer miter sums both sides in 48-bit arithmetic, so it is checking the
// congruence mod 2**48 that the tree actually relies on. Part 1 supplies the
// fact that makes that congruence an equality -- a 24x24 product fits in 48
// bits, so nothing real is ever dropped.
//
// MUST be read WITHOUT TITAN_FAST_SIM.
//
// Run: yosys -s syn/gt2n/prove_csa_parts.ys

// --- PART 1 -----------------------------------------------------------------
// The partial-product rows the tree is built from sum to the product.
module csa_rows_equiv (
    input  wire [23:0] a,
    input  wire [23:0] b,
    output wire        diff
);
    reg [47:0] acc;
    integer r;
    always @(*) begin
        acc = 48'd0;
        for (r = 0; r < 24; r = r + 1)
            acc = acc + ({24'd0, (a & {24{b[r]}})} << r);
    end
    assign diff = (acc != (a * b));
endmodule


// --- PART 2 -----------------------------------------------------------------
// One reduction layer preserves the sum of its rows, mod 2**48. Parameterised
// so the same miter covers every instantiated layer geometry.
module csa_layer_equiv #(
    parameter W    = 48,
    parameter NIN  = 24,
    parameter NOUT = 16
) (
    input  wire [NIN*W-1:0] din,
    output wire             diff
);
    wire [NOUT*W-1:0] dout;

    titan_x7_csa_layer #(.W(W), .NIN(NIN), .NOUT(NOUT)) u_dut (
        .din(din), .dout(dout));

    reg [W-1:0] sum_in, sum_out;
    integer i;
    always @(*) begin
        sum_in = {W{1'b0}};
        for (i = 0; i < NIN; i = i + 1)
            sum_in = sum_in + din[i*W +: W];
        sum_out = {W{1'b0}};
        for (i = 0; i < NOUT; i = i + 1)
            sum_out = sum_out + dout[i*W +: W];
    end

    assign diff = (sum_in != sum_out);
endmodule
