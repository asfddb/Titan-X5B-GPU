// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Module: basys3_board
 * Description: The board the DUT is plugged into -- everything on a Digilent
 *              Basys 3 that is outside the FPGA.
 *
 *              What this exists to model, versus a testbench that just wiggles
 *              the reset wire:
 *
 *              1. The 100 MHz crystal free-runs from power-on. It does not
 *                 start when the test is ready.
 *              2. The FPGA spends a while in configuration. Its logic is not
 *                 running during that time, and when configuration finishes
 *                 the global set/reset releases every flop at once from its
 *                 bitstream INIT value. A `reg x = 0;` declaration in the RTL
 *                 is that INIT value -- on Xilinx it is real silicon behaviour,
 *                 not a simulation convenience.
 *              3. Nothing presses reset for you. A design that only works
 *                 because the testbench asserted a reset wire at t=0 is a
 *                 design that comes up dead on the bench. The bring-up test
 *                 therefore never touches btnC before the first frame.
 *              4. The push buttons are mechanical and they bounce. Basys 3
 *                 buttons are undebounced in hardware -- the FPGA sees every
 *                 contact chatter edge. Bounce is generated from a fixed LFSR
 *                 so every run is byte-identical.
 *              5. The switches are slide switches: they are already at
 *                 whatever position they were left in when power came up.
 */
module basys3_board #(
    parameter real    CLK_PERIOD_NS = 10.0,      // 100 MHz crystal
    parameter real    CONFIG_NS     = 20000.0,   // FPGA configuration time
    parameter real    BOUNCE_NS     = 800000.0,  // contact chatter, ~0.8 ms
    parameter real    BOUNCE_STEP_NS = 12000.0   // chatter interval
) (
    output reg        clk_100mhz,
    output reg        btnC,
    output reg        btnU,
    output reg [15:0] sw,
    output reg        cfg_done
);

    // ------------------------------------------------------------------
    // 100 MHz crystal -- free-running from the instant power is applied.
    //
    // The pin the fabric sees is held quiet until configuration completes.
    // That stands in for GSR holding every flop at its bitstream INIT value
    // while the bitstream loads; it is a model of the effect, not of the
    // mechanism, since plain Verilog RTL has no GSR to drive. What it buys
    // is that "the design came out of reset on its own after configuration"
    // is an event that actually happens during the run, rather than
    // something that already happened at time zero.
    // ------------------------------------------------------------------
    reg xtal;
    initial begin
        xtal = 1'b0;
        forever #(CLK_PERIOD_NS/2.0) xtal = ~xtal;
    end

    always @(*) clk_100mhz = xtal & cfg_done;

    // ------------------------------------------------------------------
    // Buttons and switches at power-on. Buttons are open (Basys 3 buttons
    // are active high with a pulldown), switches hold their last position.
    // ------------------------------------------------------------------
    initial begin
        btnC     = 1'b0;
        btnU     = 1'b0;
        sw       = 16'h0000;
        cfg_done = 1'b0;
    end

    // ------------------------------------------------------------------
    // Configuration: the bitstream loads, then GSR releases.
    // ------------------------------------------------------------------
    task power_on;
        begin
            $display("  BOARD: power applied, FPGA configuring...");
            #(CONFIG_NS);
            cfg_done = 1'b1;
            $display("  BOARD: configuration done at %0.0f ns, GSR released",
                     $realtime);
        end
    endtask

    // ------------------------------------------------------------------
    // Deterministic contact bounce. Fixed 16-bit LFSR, reseeded per press,
    // so the chatter pattern is identical on every run and identical
    // between the RTL and gate-level builds.
    // ------------------------------------------------------------------
    reg [15:0] lfsr;
    integer    bounce_target;   // 0 = btnC, 1 = btnU
    initial    bounce_target = 0;

    function [15:0] lfsr_next;
        input [15:0] s;
        begin
            lfsr_next = {s[14:0], s[15] ^ s[13] ^ s[12] ^ s[10]};
        end
    endfunction

    // Chatter towards `settle`, then hold it.
    task bounce_to;
        input        settle;
        input [15:0] seed;
        real         t_end;
        begin
            lfsr  = seed;
            t_end = $realtime + BOUNCE_NS;
            while ($realtime < t_end) begin
                lfsr = lfsr_next(lfsr);
                #(BOUNCE_STEP_NS);
                if (bounce_target == 0) btnC = lfsr[0];
                else                    btnU = lfsr[0];
            end
            if (bounce_target == 0) btnC = settle;
            else                    btnU = settle;
        end
    endtask

    // A press: chatter to closed, hold, chatter to open.
    task press_btnC;
        input real hold_ns;
        begin
            $display("  BOARD: btnC pressed at %0.0f ns", $realtime);
            bounce_target = 0;
            bounce_to(1'b1, 16'hACE1);
            #(hold_ns);
            bounce_to(1'b0, 16'h1234);
            $display("  BOARD: btnC released at %0.0f ns", $realtime);
        end
    endtask

    task press_btnU;
        input real hold_ns;
        begin
            $display("  BOARD: btnU pressed at %0.0f ns", $realtime);
            bounce_target = 1;
            bounce_to(1'b1, 16'hBEEF);
            #(hold_ns);
            bounce_to(1'b0, 16'h5A5A);
            $display("  BOARD: btnU released at %0.0f ns", $realtime);
        end
    endtask

    task set_switches;
        input [15:0] value;
        begin
            sw = value;
            $display("  BOARD: switches set to %h", value);
        end
    endtask

endmodule
