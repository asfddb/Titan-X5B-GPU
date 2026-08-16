// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`default_nettype none
`timescale 1ns / 1ps

/*
 * Tiny Tapeout wrapper for the Titan X5 IEEE-754 FP32 fused multiply-add.
 *
 * WHY A WRAPPER EXISTS
 *
 * titan_x5_fp32_fma has 98 bits of input (a, b, c, rm) and 36 bits of output
 * (result + 4 exception flags). A Tiny Tapeout tile has 8 dedicated inputs,
 * 8 dedicated outputs and 8 bidirectionals. The arithmetic is unchanged and
 * untouched; everything here is the plumbing needed to get operands in and
 * results out through that pinout, one byte at a time.
 *
 * PROTOCOL
 *
 *   Load    drive a byte on ui_in with wr=1. Twelve writes fill the operand
 *           register, most-significant byte of `a` first:
 *               a[31:24] a[23:16] a[15:8] a[7:0]
 *               b[31:24] ...                b[7:0]
 *               c[31:24] ...                c[7:0]
 *   Start   pulse start=1. rm is sampled at that moment.
 *   Wait    done goes high when the result is ready (6 core cycles).
 *   Read    uo_out already holds the first byte. Each rd=1 advances to the
 *           next. Five bytes total:
 *               result[31:24] result[23:16] result[15:8] result[7:0]
 *               {4'b0, invalid, overflow, underflow, inexact}
 *
 * The load counter is deliberately free-running rather than gated at 12: the
 * shift register simply keeps shifting, so a host that loses count can clock
 * in twelve more bytes and be back in a known state without a reset.
 *
 * PINOUT
 *   ui_in  [7:0]  operand byte in
 *   uo_out [7:0]  result byte out
 *   uio[0]        wr     (in)   shift ui_in into the operand register
 *   uio[1]        start  (in)   latch operands and launch the FMA
 *   uio[3:2]      rm     (in)   00 RNE, 01 RTZ, 10 RDN, 11 RUP
 *   uio[4]        rd     (in)   advance the result shift register
 *   uio[6:5]      unused (in)
 *   uio[7]        done   (out)  result valid
 */
module tt_um_titan_fma (
    input  wire [7:0] ui_in,    // dedicated inputs
    output wire [7:0] uo_out,   // dedicated outputs
    input  wire [7:0] uio_in,   // bidirectional: input path
    output wire [7:0] uio_out,  // bidirectional: output path
    output wire [7:0] uio_oe,   // bidirectional: 1 = drive
    input  wire       ena,      // high while this design is selected
    input  wire       clk,
    input  wire       rst_n
);

    // Only uio[7] is an output; the rest are control inputs.
    assign uio_oe = 8'b1000_0000;

    wire       wr    = uio_in[0];
    wire       start = uio_in[1];
    wire [1:0] rm    = uio_in[3:2];
    wire       rd    = uio_in[4];

    // --- operand shift register --------------------------------------------
    reg [95:0] shift_in;

    // --- FMA instance -------------------------------------------------------
    reg         fma_valid_in;
    reg  [1:0]  fma_rm;
    reg  [31:0] fma_a, fma_b, fma_c;

    wire        fma_valid_out;
    wire [31:0] fma_result;
    wire        fma_invalid, fma_overflow, fma_underflow, fma_inexact;

    titan_x5_fp32_fma u_fma (
        .clk            (clk),
        .rst_n          (rst_n),
        .en             (1'b1),
        .valid_in       (fma_valid_in),
        .rm             (fma_rm),
        .a              (fma_a),
        .b              (fma_b),
        .c              (fma_c),
        .valid_out      (fma_valid_out),
        .result         (fma_result),
        .flag_invalid   (fma_invalid),
        .flag_overflow  (fma_overflow),
        .flag_underflow (fma_underflow),
        .flag_inexact   (fma_inexact)
    );

    // --- result shift register ---------------------------------------------
    reg [39:0] shift_out;
    reg        done;

    assign uo_out     = shift_out[39:32];
    assign uio_out    = {done, 7'b0};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_in     <= 96'b0;
            shift_out    <= 40'b0;
            done         <= 1'b0;
            fma_valid_in <= 1'b0;
            fma_rm       <= 2'b00;
            fma_a        <= 32'b0;
            fma_b        <= 32'b0;
            fma_c        <= 32'b0;
        end else begin
            // Single-cycle pulse: without this the core would see valid_in
            // held high and launch a new operation every cycle.
            fma_valid_in <= 1'b0;

            if (wr)
                shift_in <= {shift_in[87:0], ui_in};

            if (start) begin
                // Bytes arrive most-significant first, so the first byte
                // written has been shifted up to the top of the register.
                fma_a        <= shift_in[95:64];
                fma_b        <= shift_in[63:32];
                fma_c        <= shift_in[31:0];
                fma_rm       <= rm;
                fma_valid_in <= 1'b1;
                done         <= 1'b0;
            end

            if (fma_valid_out) begin
                shift_out <= {fma_result,
                              4'b0,
                              fma_invalid, fma_overflow,
                              fma_underflow, fma_inexact};
                done      <= 1'b1;
            end else if (rd) begin
                shift_out <= {shift_out[31:0], 8'h00};
            end
        end
    end

    // ena is supplied by the harness and is not needed here: the tile is
    // combinationally isolated when deselected. Named in a no-op so the
    // linter does not flag it as an unconnected port.
    wire _unused = &{ena, uio_in[6:5], 1'b0};

endmodule

`default_nettype wire
