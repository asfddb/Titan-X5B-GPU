// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// TITAN APEX execution lane: operand isolation + clock-enable gating around
// the 8-stage FP32 FMA.
//
// WHY: dynamic power is alpha*C*Vdd^2*f, and `alpha` is the term RTL can
// actually attack. The FMA's E2-E5 logic cloud is ~10k cells wide (24x24
// multiply, 104-bit alignment shifter, 106-bit prefix adder). Left
// unisolated, that cloud re-evaluates whenever its inputs move -- including
// on cycles when this lane is idle and the operand buses are simply carrying
// another lane's traffic. Those transitions do no work and cost full
// switching energy.
//
// Isolation clamps the operands to zero on any cycle the lane is not
// launching an operation, so the cloud sees a constant and does not toggle.
//
// CORRECTNESS ARGUMENT
//
// The FMA is strictly feed-forward: each operation occupies its own set of
// pipeline slots and no state is carried between operations (the only
// cross-cycle signals are the per-stage valid bits and the `en` stall). An
// operation launched with valid_in=1 therefore cannot be affected by the
// operand values presented on any other cycle. Clamping the operands on
// !valid_in cycles changes only the contents of pipeline slots whose
// valid bit is 0, and those never reach valid_out.
//
// That argument is checked, not assumed: tb/uvm/test_apex_lane.py runs the
// gated lane against a bare FMA on identical valid streams with randomised
// idle gaps and stalls, and the bounded sequential SAT check in
// syn/gt2n/prove_isolation.ys proves result equality on every cycle where
// valid_out is high.
//
// CLOCK GATING -- WHAT GT2N CANNOT DO
//
// The spec calls for integrated clock-gating (ICG) cells at every pipeline
// register. GT2N has no ICG cell, and no latch cell either: its entire
// sequential offering is dffasync_x1/x2/x4 (verified across all five Vt
// libraries). So on this PDK:
//
//   - `en`-based gating (already present inside titan_x7_fp32_fma_pipe, and
//     driven from here) saves the REGISTER's internal switching and the
//     downstream cloud, because the flop simply reloads its own value.
//   - It does NOT save clock-tree power. Reaching the clock tree needs an
//     ICG, and building one from an AND gate is a glitch hazard on the clock
//     -- exactly the thing an ICG's latch exists to prevent. It is not done
//     here.
//
// `TITAN_HAS_ICG` instantiates a real ICG on a PDK that ships one. Left
// undefined -- as it must be for GT2N -- the enable path is used alone.
module titan_apex_fma_lane #(
    // Set to 0 to build the lane without isolation, for the A/B area and
    // toggle comparison rather than as a production option.
    parameter ISOLATE = 1
) (
    input  wire        clk,
    input  wire        rst_n,

    // Lane-level power control. `lane_active` is the coarse knob (this lane
    // is participating in the current warp at all); valid_in is the
    // per-cycle one.
    input  wire        lane_active,

    input  wire        valid_in,
    input  wire [1:0]  rm,
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,

    output wire        valid_out,
    output wire [31:0] result,
    output wire        flag_invalid,
    output wire        flag_overflow,
    output wire        flag_underflow,
    output wire        flag_inexact,

    // Observability: high on cycles the operand cloud was held constant.
    output wire        dbg_isolated
);

    // One AND per operand bit. GT2N has and2 but no latch, so this is a
    // clamp-to-zero rather than a hold-last-value; both stop the cloud
    // toggling, and the clamp needs no sequential element.
    wire launch = valid_in & lane_active;
    wire iso_en = (ISOLATE != 0) ? launch : 1'b1;

    wire [31:0] a_iso = a & {32{iso_en}};
    wire [31:0] b_iso = b & {32{iso_en}};
    wire [31:0] c_iso = c & {32{iso_en}};
    wire [1:0]  rm_iso = rm & {2{iso_en}};

    assign dbg_isolated = ~iso_en;

    // Pipeline advance. Holding `en` low on a bubble stops every pipeline
    // register in the FMA from reloading.
    //
    // NOTE this is a correctness-relevant simplification, kept deliberately
    // conservative: `en` must stay high while ANY in-flight operation still
    // needs to advance, not merely when a new one launches. Gating it on
    // `launch` alone would stall operations already in the pipe behind an
    // idle cycle. The shift register below tracks occupancy over the FMA's
    // 8 stages and keeps the pipe running until it has drained.
    localparam FMA_LAT = 8;
    reg [FMA_LAT-1:0] occupancy;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            occupancy <= {FMA_LAT{1'b0}};
        else
            occupancy <= {occupancy[FMA_LAT-2:0], launch};
    end

    wire pipe_busy = |occupancy;
    wire en_int    = launch | pipe_busy;

`ifdef TITAN_HAS_ICG
    // On a PDK with a real integrated clock gate, the enable additionally
    // reaches the clock tree. GT2N has no such cell; see the header.
    wire gclk;
    TITAN_ICG u_icg (.CLK(clk), .EN(en_int), .GCLK(gclk));
    localparam FMA_CLK_IS_GATED = 1;
`else
    wire gclk = clk;
    localparam FMA_CLK_IS_GATED = 0;
`endif

    titan_x7_fp32_fma_pipe u_fma (
        .clk            (gclk),
        .rst_n          (rst_n),
        .en             (en_int),
        .valid_in       (launch),
        .rm             (rm_iso),
        .a              (a_iso),
        .b              (b_iso),
        .c              (c_iso),
        .valid_out      (valid_out),
        .result         (result),
        .flag_invalid   (flag_invalid),
        .flag_overflow  (flag_overflow),
        .flag_underflow (flag_underflow),
        .flag_inexact   (flag_inexact)
    );

endmodule
