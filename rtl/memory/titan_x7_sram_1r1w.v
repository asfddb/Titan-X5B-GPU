// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Behavioral model of a compiled 1R1W SRAM macro.
//
// This is written to the contract a REAL macro offers, not to whatever is
// convenient in simulation. Getting that contract wrong is the usual reason
// a design that simulates fine turns out to be unbuildable:
//
//   1. READS ARE REGISTERED. The address is sampled on a clock edge and the
//      data appears the cycle AFTER. A compiled SRAM cannot give you
//      combinational reads at any node. Every flop-array register file in
//      this repo (titan_x5_register_file.v, and the `rf` array inside
//      titan_x7_sm.v) reads combinationally, which is exactly why they
//      cannot be swapped for macros without a pipeline change.
//
//   2. THERE IS NO RESET ON THE ARRAY. A compiled SRAM powers up undefined;
//      no signal clears it. titan_x5_register_file.v clears all 512 entries
//      on async reset -- 524,288 flops with a reset pin, which is both a
//      huge area cost and a giant reset fanout. Modelling the array as X
//      until written is what catches RTL that silently depends on a zeroed
//      register file.
//
//   3. A SAME-CYCLE READ AND WRITE TO THE SAME ADDRESS RETURNS OLD DATA
//      (read-before-write). Some macros offer write-first, many do not.
//      Assuming the conservative behaviour here means the surrounding logic
//      must supply its own bypass -- and if it does, it works on either kind
//      of macro. Assuming write-first would silently break on half of them.
//
// Byte/lane write enables are per-lane rather than per-byte because the
// register file's natural granularity is a SIMT lane (32 bits).
module titan_x7_sram_1r1w #(
    parameter LANES = 8,          // 32-bit lanes per entry
    parameter DEPTH = 64,
    parameter ADDR_W = 6          // must satisfy 2**ADDR_W >= DEPTH
) (
    input  wire                  clk,

    // read port: address in, data out one cycle later
    input  wire                  re,
    input  wire [ADDR_W-1:0]     raddr,
    output reg  [LANES*32-1:0]   rdata,

    // write port: per-lane enables
    input  wire                  we,
    input  wire [ADDR_W-1:0]     waddr,
    input  wire [LANES-1:0]      wmask,
    input  wire [LANES*32-1:0]   wdata
);

    reg [LANES*32-1:0] mem [0:DEPTH-1];

    integer L;

    // Deliberately no `rst_n`: see note 2 above. The array holds X until
    // written, so a consumer that reads an unwritten register gets X rather
    // than a convenient zero.
    always @(posedge clk) begin
        // Read is sampled before the write below takes effect in the same
        // block, giving read-before-write on an address collision (note 3).
        if (re)
            rdata <= mem[raddr];

        if (we) begin
            for (L = 0; L < LANES; L = L + 1) begin
                if (wmask[L])
                    mem[waddr][L*32 +: 32] <= wdata[L*32 +: 32];
            end
        end
    end

endmodule
