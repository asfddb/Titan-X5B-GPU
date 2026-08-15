// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// Miter: titan_x7_csa_mul24's two output vectors SUM to a*b, for ALL inputs.
//
// The carry-save tree replaced two `*` operators in the FMA's E3 stage, each
// of which was building an array multiplier that ended in its own internal
// carry-propagate adder. The substitution is only safe if the (sum, carry)
// pair is an exact carry-save decomposition of the product on every input --
// not on sampled vectors.
//
// This is also where the mod-2**48 truncation argument gets checked: every
// layer shifts its carry vector left by one and truncates to 48 bits, which
// is exact only because a 24x24 product cannot exceed 2**48-1.
//
// MUST be read WITHOUT TITAN_FAST_SIM, or this proves `(a*b, 0)` against
// `a*b`, which is a tautology and proves nothing about the tree.
//
// Run: yosys -s syn/gt2n/prove_csa_mul.ys
module csa_mul_equiv (
    input  wire [23:0] a,
    input  wire [23:0] b,
    output wire        diff
);

    wire [47:0] s, c;

    titan_x7_csa_mul24 u_dut (.a(a), .b(b), .s(s), .c(c));

    // The reference is the operator the tree replaced.
    assign diff = ((s + c) != (a * b));

endmodule
