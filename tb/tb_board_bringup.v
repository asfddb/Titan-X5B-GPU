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
 * Testbench: tb_board_bringup
 * Description: Basys 3 bring-up for titan_x5_display_top, run against the
 *              board connectors instead of against the RTL.
 *
 *              THE RULE THIS FILE KEEPS: there is not one hierarchical
 *              reference into the DUT. No dut.u_disp.h_counter, no
 *              dut.clk_pixel, no vga_de -- none of those exist on a board.
 *              Everything asserted here is derived from the 100 MHz clock
 *              pin, the buttons, the switches, the 16 LEDs and the five
 *              wires in the VGA connector. If a check cannot be made from
 *              those, it does not belong in a bring-up test.
 *
 *              tb/tb_display_top.v is the RTL-level counterpart and stays --
 *              it reads the DUT's own counters to check pixels, which is the
 *              right thing for a unit test and the wrong thing here.
 *
 *              The same file drives the RTL build and the post-synthesis
 *              netlist build; only the DUT source changes.
 *
 * Plusargs:
 *   +outdir=<path>   where frames and the timing report are written
 *   +quick           power-on frame only; skip the button tests
 */
module tb_board_bringup;

    // ------------------------------------------------------------------
    // The board
    // ------------------------------------------------------------------
    wire        clk_100mhz;
    wire        btnC, btnU;
    wire [15:0] sw;
    wire        cfg_done;

    basys3_board board (
        .clk_100mhz (clk_100mhz),
        .btnC       (btnC),
        .btnU       (btnU),
        .sw         (sw),
        .cfg_done   (cfg_done)
    );

    // ------------------------------------------------------------------
    // The device under test, wired exactly as the XDC wires it
    // ------------------------------------------------------------------
    wire [15:0] led;
    wire [3:0]  vga_r, vga_g, vga_b;
    wire        vga_hsync, vga_vsync;

    titan_x5_display_top dut (
        .clk_100mhz (clk_100mhz),
        .sw         (sw),
        .btnC       (btnC),
        .btnU       (btnU),
        .led        (led),
        .vga_r      (vga_r),
        .vga_g      (vga_g),
        .vga_b      (vga_b),
        .vga_hsync  (vga_hsync),
        .vga_vsync  (vga_vsync)
    );

    // ------------------------------------------------------------------
    // The monitor on the end of the cable
    // ------------------------------------------------------------------
    vga_monitor #(
        .H_VISIBLE(640), .H_FRONT(16), .H_SYNC(96), .H_BACK(48),
        .V_VISIBLE(400), .V_FRONT(12), .V_SYNC(2),  .V_BACK(35)
    ) mon (
        .r(vga_r), .g(vga_g), .b(vga_b),
        .hsync(vga_hsync), .vsync(vga_vsync)
    );

    // ------------------------------------------------------------------
    // Bookkeeping
    // ------------------------------------------------------------------
    integer errors;
    integer checks;
    reg [1023:0] outdir;
    reg [1023:0] fname;
    reg          quick;

    task check;
        input        cond;
        input [1023:0] what;
        begin
            checks = checks + 1;
            if (cond) $display("  PASS  %0s", what);
            else begin
                $display("  FAIL  %0s", what);
                errors = errors + 1;
            end
            // Flushed on purpose. A gate-level run takes hours, and stdout
            // redirected to a file is block-buffered, so without this the log
            // is empty until the run ends -- and empty if it is interrupted.
            $fflush;
        end
    endtask

    // Wait for a bit of the LED bus to reach a value, or time out.
    // This is the only visibility a bring-up has into what the design is
    // doing, which is exactly the point of putting status on LEDs.
    task wait_led;
        input integer bitn;
        input         value;
        input real    timeout_ns;
        output        ok;
        real          deadline;
        begin
            deadline = $realtime + timeout_ns;
            ok = 1'b0;
            while ($realtime < deadline) begin
                if (led[bitn] === value) begin
                    ok = 1'b1;
                    deadline = $realtime;   // exit
                end else #1000;
            end
        end
    endtask

    reg ok;
    reg [3:0] frame_cnt_a, frame_cnt_b;
    reg [1:0] pat_led;
    integer   hs_at_start;
    integer   blank_bad, check_blanking_lines, jitter_lines;
    real      jitter_ns, cold_window_ns;
    reg       gate_profile;

    // ------------------------------------------------------------------
    // Bring-up sequence
    // ------------------------------------------------------------------
    initial begin
        errors = 0;
        checks = 0;
        outdir = "bringup_out";
        quick  = 1'b0;
        void_plusargs;

        $display("");
        $display("================================================================");
        $display(" Titan X5 display path -- Basys 3 bring-up (no board attached)");
        $display("================================================================");

        // ---------------- 1. cold boot, hands off ----------------
        // This is what happens when the board is plugged in: configuration
        // finishes and the design is expected to run. Nothing presses reset.
        $display("");
        $display("[1] Cold power-on. Nothing is pressed.");
        board.power_on;

        wait_led(0, 1'b1, 5_000_000.0, ok);   // led[0] = fill_done
        check(ok, "cold boot: core domain fills VRAM with no button pressed");
        if (ok) $display("        (fill done at %0.0f ns)", $realtime);

        // Is anything coming out of the VGA connector at all? A line is 32 us,
        // so even the short window is 31 lines -- if sync has not started by
        // then it is not going to.
        hs_at_start = mon.hs_rises;
        cold_window_ns = gate_profile ? 1_000_000.0 : 5_000_000.0;
        #(cold_window_ns);
        check(mon.hs_rises > hs_at_start,
              "cold boot: video present on the VGA connector with no button pressed");
        $display("        hsync edges in %0.0f ms after cold boot: %0d",
                 cold_window_ns / 1_000_000.0, mon.hs_rises - hs_at_start);

        // ---------------- 2. press reset, as a user would ----------------
        // Skipped in the gate profile: the netlist comes up with video on its
        // own, so the picture captured below is the one the board shows when
        // it is plugged in, with nothing touched. Pressing reset there would
        // only cost a frame of the hours this run takes.
        if (!gate_profile) begin
            $display("");
            $display("[2] Pressing btnC -- an undebounced mechanical contact, so");
            $display("    the FPGA sees every chatter edge.");
            board.press_btnC(2_000_000.0);
            wait_led(0, 1'b1, 10_000_000.0, ok);
            check(ok, "design refills after a bouncing reset press");
        end else begin
            $display("");
            $display("[2] Skipped -- gate profile captures the cold-boot picture.");
        end

        $display("");
        $display("[3] Plugging in the monitor.");
        mon.wait_for_lock(80_000_000.0);
        check(mon.locked, "monitor locks to sync on the VGA connector");

        // ---------------- 4. capture what the monitor shows ----------------
        // Captured before the timing is reported, deliberately. Lock needs
        // only one vertical pulse rather than two full frames, and the frame
        // period the checks below need is measured during the capture itself.
        // That ordering saves a frame, which at gate-level speed is an hour.
        $display("");
        $display("[4] Capturing a frame off the connector.");
        mon.capture_frame;
        check(mon.x_pixels() == 0,
              "no undriven pixels on the DAC pins during the visible window");
        if (mon.x_pixels() != 0)
            $display("        %0d of %0d pixels sampled as X",
                     mon.x_pixels(), 640*400);
        $sformat(fname, "%0s/frame_boot.ppm", outdir);
        mon.dump_ppm(fname);

        // ---------------- 5. sync against the mode standard ----------------
        $display("");
        $display("[5] Holding the signal to the 640x400@70 standard.");
        mon.wait_for_timing(20_000_000.0);
        mon.report_timing;
        check(mon.timing_ready,
              "a full frame period was observed end to end");
        check(mon.measured_lines == 449,
              "449 lines per frame");
        check(mon.hs_period_ns == 32000.0,
              "line period 32.000 us (800 pixels at 25.000 MHz)");
        check(mon.hs_width_ns == 96.0 * 40.0,
              "hsync pulse 96 pixels");
        check(mon.vs_width_ns == 2.0 * 32000.0,
              "vsync pulse 2 lines");
        check(mon.vs_period_ns == 449.0 * 32000.0,
              "frame period 14.368 ms");
        // IBM VGA assigns 640x400@70 negative hsync and positive vsync; the
        // polarity pair is how a monitor tells this mode from 640x350 and
        // 720x400, which share the 31.5 kHz line rate.
        check(mon.hs_active_high == 1'b0,
              "hsync polarity NEGATIVE as the 640x400@70 standard requires");
        check(mon.vs_active_high == 1'b1,
              "vsync polarity POSITIVE as the 640x400@70 standard requires");

        $sformat(fname, "%0s/timing.txt", outdir);
        mon.write_timing_file(fname);

        // ---------------- 5b. what the pins do outside the picture --------
        check_blanking_lines = 40;
        mon.check_blanking(check_blanking_lines, blank_bad);
        check(blank_bad == 0,
              "DAC pins sit at black through sync and both porches");
        if (blank_bad != 0)
            $display("        %0d non-black samples over %0d lines",
                     blank_bad, check_blanking_lines);

        jitter_lines = gate_profile ? 20 : 200;
        mon.check_line_jitter(jitter_lines, jitter_ns);
        check(jitter_ns == 0.0, "line period is stable across consecutive lines");
        $display("        worst deviation over %0d lines: %0.3f ns",
                 jitter_lines, jitter_ns);

        // ---------------- 6. is it actually scanning ----------------
        // Costs three whole frames, so it is left out of the gate profile --
        // a complete frame was just captured off the connector, which is
        // stronger evidence of scanning than the counter is.
        if (!gate_profile) begin
            $display("");
            $display("[6] Frame counter on led[15:12] should advance.");
            frame_cnt_a = led[15:12];
            repeat (3) @(posedge vga_vsync);
            frame_cnt_b = led[15:12];
            check(frame_cnt_a !== frame_cnt_b,
                  "frame counter LEDs advance while scanning");
            $display("        led[15:12] %h -> %h", frame_cnt_a, frame_cnt_b);
        end

        if (!quick) begin
            // ---------------- 7. reset while it is running ----------------
            // Different from the power-on press: the pixel counters are live
            // and mid-frame when the contact closes, so this exercises reset
            // assertion into a running pixel domain rather than out of one.
            $display("");
            $display("[7] Pressing btnC again, mid-scan.");
            board.press_btnC(2_000_000.0);
            wait_led(0, 1'b1, 10_000_000.0, ok);
            check(ok, "design recovers from a reset press taken mid-scan");

            mon.capture_frame;
            check(mon.x_pixels() == 0,
                  "no undriven pixels after the mid-scan reset");
            $sformat(fname, "%0s/frame_after_reset.ppm", outdir);
            mon.dump_ppm(fname);

            // ---------------- 8. switches and the load button ----------------
            $display("");
            $display("[8] Selecting patterns on sw[1:0] and pressing btnU,");
            $display("    reading the selection back off led[3:2].");

            board.set_switches(16'h0001);
            board.press_btnU(2_000_000.0);
            wait_led(0, 1'b1, 10_000_000.0, ok);
            check(ok, "pattern 1 reload completes");
            pat_led = led[3:2];
            check(pat_led == 2'd1, "led[3:2] reads back pattern 1");
            mon.capture_frame;
            $sformat(fname, "%0s/frame_pattern1.ppm", outdir);
            mon.dump_ppm(fname);

            board.set_switches(16'h0002);
            board.press_btnU(2_000_000.0);
            wait_led(0, 1'b1, 10_000_000.0, ok);
            check(ok, "pattern 2 reload completes");
            pat_led = led[3:2];
            check(pat_led == 2'd2, "led[3:2] reads back pattern 2");
            mon.capture_frame;
            $sformat(fname, "%0s/frame_pattern2.ppm", outdir);
            mon.dump_ppm(fname);

            board.set_switches(16'h0003);
            board.press_btnU(2_000_000.0);
            wait_led(0, 1'b1, 10_000_000.0, ok);
            check(ok, "pattern 3 reload completes");
            pat_led = led[3:2];
            check(pat_led == 2'd3, "led[3:2] reads back pattern 3");
            mon.capture_frame;
            $sformat(fname, "%0s/frame_pattern3.ppm", outdir);
            mon.dump_ppm(fname);
        end

        // ---------------- summary ----------------
        $display("");
        $display("================================================================");
        if (errors == 0)
            $display(" BRING-UP PASSED -- %0d checks, 0 failures", checks);
        else
            $display(" BRING-UP FAILED -- %0d checks, %0d failures", checks, errors);
        $display("================================================================");
        $display("");
        $finish;
    end

    task void_plusargs;
        begin
            if ($value$plusargs("outdir=%s", outdir))
                $display("  outdir = %0s", outdir);
            gate_profile = $test$plusargs("gate");
            quick = $test$plusargs("quick") || gate_profile;
            if (gate_profile)
                $display("  gate profile: cold-boot picture only, no button presses");
            else if (quick)
                $display("  quick mode: power-on frame only");
        end
    endtask

    // Global backstop. Long, because two frames of lock plus five captures
    // is most of a second of modelled time.
    initial begin
        #900_000_000;
        $display("");
        $display(" BRING-UP FAILED -- global timeout at %0.0f ns", $realtime);
        $finish;
    end

endmodule
