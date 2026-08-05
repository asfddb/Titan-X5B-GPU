// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// Miter: titan_x7_lzc == the linear priority scan it replaced, for ALL inputs.
//
// E6 of the FMA was documented as a "106-bit CLZ tree" and was not a tree --
// it was ~106 chained conditional overwrites, which became the dominant path
// once E5's adders were made parallel-prefix. The reduction tree that
// replaced it is only a valid substitution if it agrees with the scan
// everywhere, including the all-zero case (both leave idx at 0, which is why
// `nz` exists to tell "index 0" from "empty" apart).
//
// The reference below is deliberately written as the ORIGINAL loop rather
// than as a cleaner formulation: what needs proving is equivalence to the
// code that was actually deleted.
//
// MUST be read WITHOUT TITAN_FAST_SIM, or this proves the behavioural
// fallback against itself -- the fallback IS this loop, so the proof would
// be vacuous and would still pass. That trap is the whole reason this note
// is here.
//
// Run: yosys -s syn/gt2n/prove_lzc.ys
module lzc_equiv #(
    parameter W  = 128,
    parameter LW = 7
) (
    input  wire [W-1:0] vec,
    output wire         diff
);

    wire [LW-1:0] idx_dut;
    wire          nz_dut;

    titan_x7_lzc #(.W(W), .LW(LW)) u_dut (
        .vec(vec), .idx(idx_dut), .nz(nz_dut)
    );

    // The linear priority scan this module replaced: last assignment wins as
    // bi rises, so it lands on the index of the highest set bit.
    integer bi;
    reg [LW-1:0] ref_idx;
    always @(*) begin
        ref_idx = {LW{1'b0}};
        for (bi = 0; bi < W; bi = bi + 1)
            if (vec[bi]) ref_idx = bi[LW-1:0];
    end

    assign diff = (idx_dut != ref_idx) || (nz_dut != (|vec));

endmodule
