// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// Miter: titan_x7_prefix_add == a + b + cin, for ALL inputs.
//
// The Kogge-Stone adder replaced a bare `+` on E5's three 106-bit operations
// because GT2N has no adder cells and a plain `+` mapped to a ripple chain
// (docs/GT2N_2NM_SYNTHESIS.md section 7). That substitution is only safe if
// the replacement is exactly equal to the operator it replaced, on every
// input -- not on sampled vectors.
//
// Width 106 is the real instantiation width in titan_x7_fp32_fma_pipe.
//
// MUST be read WITHOUT TITAN_FAST_SIM, or this proves the behavioural
// fallback against `+` rather than the structural tree that synthesis builds.
//
// Run: yosys -s syn/gt2n/prove_prefix.ys
module prefix_equiv #(
    parameter W      = 106,
    parameter LEVELS = 7
) (
    input  wire [W-1:0] a,
    input  wire [W-1:0] b,
    input  wire         cin,
    output wire         diff
);

    wire [W-1:0] sum_dut;
    wire         cout_dut;

    titan_x7_prefix_add #(.W(W), .LEVELS(LEVELS)) u_dut (
        .a(a), .b(b), .cin(cin), .sum(sum_dut), .cout(cout_dut)
    );

    // The reference is the operator itself, one bit wider so the carry out
    // is captured rather than discarded.
    wire [W:0] ref = {1'b0, a} + {1'b0, b} + {{W{1'b0}}, cin};

    assign diff = (sum_dut != ref[W-1:0]) || (cout_dut != ref[W]);

endmodule
