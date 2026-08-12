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
 * Module: vga_monitor
 * Description: A VGA monitor, modelled at the connector.
 *
 *              This module may only look at the five signals a DE-15 cable
 *              actually carries: R, G, B, HSYNC, VSYNC. There is no pixel
 *              clock on that cable and there is no data-enable, so this model
 *              has neither. It recovers everything else the way a monitor
 *              does -- measure the sync pulses, decide their polarity from
 *              which level is the minority, divide the line period by the
 *              mode table's horizontal total to get a pixel clock, then count
 *              porches from the sync edge to find the visible window.
 *
 *              The point of the restriction: a testbench that reads the DUT's
 *              own h_counter/v_counter/vga_de is asking the design where the
 *              pixels are. It will agree with itself even when the sync
 *              pulses, the porches or the output pipeline are wrong. A
 *              monitor cannot do that, so neither can this.
 *
 *              Parameters are the monitor's mode table -- the standard the
 *              signal is being held to, not a description of the DUT. What
 *              the DUT actually produced is in the measured_* values and in
 *              the captured frame.
 */
module vga_monitor #(
    parameter integer H_VISIBLE = 640,
    parameter integer H_FRONT   = 16,
    parameter integer H_SYNC    = 96,
    parameter integer H_BACK    = 48,
    parameter integer V_VISIBLE = 400,
    parameter integer V_FRONT   = 12,
    parameter integer V_SYNC    = 2,
    parameter integer V_BACK    = 35
) (
    input wire [3:0] r,
    input wire [3:0] g,
    input wire [3:0] b,
    input wire       hsync,
    input wire       vsync
);

    localparam integer H_TOTAL = H_VISIBLE + H_FRONT + H_SYNC + H_BACK;
    localparam integer V_TOTAL = V_VISIBLE + V_FRONT + V_SYNC + V_BACK;
    localparam integer PIXELS  = H_VISIBLE * V_VISIBLE;

    // ------------------------------------------------------------------
    // Sync measurement -- from the two sync wires and nothing else
    // ------------------------------------------------------------------
    real    t_hs_rise, t_hs_fall, t_vs_rise, t_vs_fall;
    real    hs_high_ns, hs_low_ns, vs_high_ns, vs_low_ns;
    real    hs_period_ns, vs_period_ns;
    integer hs_rises, vs_rises;
    integer hs_in_frame, measured_lines;
    reg     hs_have_rise, hs_have_fall, vs_have_rise, vs_have_fall;

    initial begin
        t_hs_rise = 0.0; t_hs_fall = 0.0; t_vs_rise = 0.0; t_vs_fall = 0.0;
        hs_high_ns = 0.0; hs_low_ns = 0.0; hs_period_ns = 0.0;
        vs_high_ns = 0.0; vs_low_ns = 0.0; vs_period_ns = 0.0;
        hs_rises = 0; vs_rises = 0; hs_in_frame = 0; measured_lines = 0;
        hs_have_rise = 1'b0; hs_have_fall = 1'b0;
        vs_have_rise = 1'b0; vs_have_fall = 1'b0;
    end

    always @(posedge hsync) begin
        if (hs_have_rise) hs_period_ns = $realtime - t_hs_rise;
        if (hs_have_fall) hs_low_ns    = $realtime - t_hs_fall;
        t_hs_rise    = $realtime;
        hs_have_rise = 1'b1;
        hs_rises     = hs_rises + 1;
        hs_in_frame  = hs_in_frame + 1;
    end

    always @(negedge hsync) begin
        if (hs_have_rise) hs_high_ns = $realtime - t_hs_rise;
        t_hs_fall    = $realtime;
        hs_have_fall = 1'b1;
    end

    always @(posedge vsync) begin
        if (vs_have_rise) vs_period_ns = $realtime - t_vs_rise;
        if (vs_have_fall) vs_low_ns    = $realtime - t_vs_fall;
        t_vs_rise    = $realtime;
        vs_have_rise = 1'b1;
        vs_rises     = vs_rises + 1;
        // lines between one vsync rise and the next, however the sync is
        // polarised -- one hsync rise happens per line either way
        measured_lines = hs_in_frame;
        hs_in_frame    = 0;
    end

    always @(negedge vsync) begin
        if (vs_have_rise) vs_high_ns = $realtime - t_vs_rise;
        t_vs_fall    = $realtime;
        vs_have_fall = 1'b1;
    end

    // The sync pulse is the minority level. Rather than wait to measure both
    // levels of a period -- which for vsync means a whole frame -- classify
    // against the line period, which is known after two hsync edges. A
    // horizontal pulse is a fraction of a line; a vertical pulse is a small
    // number of lines in every VESA and IBM mode, never a majority of the
    // frame. This resolves polarity one pulse after sync appears instead of
    // one frame, which is what makes the gate-level run finish in an hour.
    wire hs_active_high = (hs_high_ns > 0.0) && (hs_period_ns > 0.0) &&
                          (hs_high_ns < 0.5 * hs_period_ns);
    wire vs_active_high = (vs_high_ns > 0.0) && (hs_period_ns > 0.0) &&
                          (vs_high_ns < 16.0 * hs_period_ns);

    // Normalised leading edges, so the capture loop does not care about
    // polarity. These glitch once when polarity is first resolved, which is
    // before lock and therefore before anything samples them.
    wire hs_lead = hs_active_high ?  hsync : ~hsync;
    wire vs_lead = vs_active_high ?  vsync : ~vsync;

    // Sync pulse width, and the pixel clock recovered the way a monitor's
    // PLL does it: the measured line period divided by the horizontal total
    // of the matched mode.
    real hs_width_ns, vs_width_ns, t_pix_ns;
    reg  locked;

    initial begin
        hs_width_ns = 0.0; vs_width_ns = 0.0; t_pix_ns = 0.0; locked = 1'b0;
    end

    reg timing_ready;   // enough edges seen to state a frame period
    initial timing_ready = 1'b0;

    always @(hs_high_ns or hs_low_ns or vs_high_ns or vs_low_ns or
             hs_period_ns or vs_period_ns or hs_rises or vs_rises) begin
        hs_width_ns = hs_active_high ? hs_high_ns : hs_low_ns;
        vs_width_ns = vs_active_high ? vs_high_ns : vs_low_ns;
        t_pix_ns    = (hs_period_ns > 0.0) ? hs_period_ns / H_TOTAL : 0.0;
        // Lock needs the line period and one complete vertical pulse. It
        // deliberately does NOT wait for a second vsync edge: that is a whole
        // frame, and the back porch after the pulse is long enough to start
        // painting in.
        locked      = (hs_rises >= 4) && (hs_period_ns > 0.0) &&
                      (hs_high_ns > 0.0) && (vs_high_ns > 0.0);
        timing_ready = locked && (vs_rises >= 2) && (vs_period_ns > 0.0);
    end


    // ------------------------------------------------------------------
    // Captured frame
    // ------------------------------------------------------------------
    reg [11:0] framebuf [0:PIXELS-1];
    integer    frames_captured;
    initial    frames_captured = 0;

    // ------------------------------------------------------------------
    // wait_for_lock: the "No Signal" check. Fails if the connector never
    // carries usable sync inside the timeout.
    // ------------------------------------------------------------------
    task wait_for_lock;
        input real timeout_ns;
        real deadline;
        begin
            deadline = $realtime + timeout_ns;
            while (!locked && $realtime < deadline) #1000;
            if (!locked) begin
                $display("  MONITOR: NO SIGNAL -- no usable sync within %0.0f ns",
                         timeout_ns);
            end else begin
                $display("  MONITOR: locked at %0.0f ns", $realtime);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // wait_for_timing: a frame *period* needs two vertical sync edges, and
    // capture_frame deliberately joins the frame already in progress, so only
    // one has been seen when it returns. This waits out the tail of that
    // frame -- front porch plus sync, not a whole frame.
    // ------------------------------------------------------------------
    task wait_for_timing;
        input real timeout_ns;
        real deadline;
        begin
            deadline = $realtime + timeout_ns;
            while (!timing_ready && $realtime < deadline) #1000;
            if (!timing_ready)
                $display("  MONITOR: no second vertical sync within %0.0f ns",
                         timeout_ns);
        end
    endtask

    // ------------------------------------------------------------------
    // capture_frame: one whole visible frame, sampled off the sync edges.
    //
    // The hsync pulse that opens a line is followed by back porch and then
    // the visible pixels, so pixel n of that line sits at
    //   t(sync leading edge) + (H_SYNC + H_BACK + n + 0.5) * t_pix
    // and the sample is taken mid-pixel. Vertically, the leading vsync edge
    // is followed by V_SYNC + V_BACK line periods before the first visible
    // row, so the (V_SYNC + V_BACK)'th hsync edge after it opens row 0.
    // ------------------------------------------------------------------
    task capture_frame;
        integer row, col, skip;
        real    t_line, t_target;
        begin
            if (!locked) begin
                $display("  MONITOR: capture_frame called before lock");
            end else begin
                // Always reference the capture off a vertical sync edge that
                // was seen with the polarity already resolved.
                //
                // An earlier version tried to join the frame in progress by
                // counting hsync edges since the last vsync, to save a frame.
                // It silently produced pictures displaced two rows: vsync
                // polarity is not decidable until the pulse ENDS, so the
                // counter reset at the end of the first pulse rather than its
                // start -- two lines late, exactly the V_SYNC width. The
                // capture still looked 93.5% correct, because a shift of two
                // rows only shows up where the test pattern changes. Speed is
                // not worth an instrument that lies quietly.
                @(posedge vs_lead);
                skip = V_SYNC + V_BACK;
                repeat (skip) @(posedge hs_lead);
                for (row = 0; row < V_VISIBLE; row = row + 1) begin
                    t_line = $realtime;
                    for (col = 0; col < H_VISIBLE; col = col + 1) begin
                        t_target = t_line +
                                   (H_SYNC + H_BACK + col + 0.5) * t_pix_ns;
                        #(t_target - $realtime);
                        framebuf[row*H_VISIBLE + col] = {r, g, b};
                    end
                    if (row != V_VISIBLE-1) @(posedge hs_lead);
                end
                frames_captured = frames_captured + 1;
                $display("  MONITOR: captured frame %0d at %0.0f ns",
                         frames_captured, $realtime);
            end
        end
    endtask

    // ------------------------------------------------------------------
    // check_blanking: the DAC pins must sit at black outside the visible
    // window. This is not cosmetic -- a monitor clamps its black level
    // during the back porch, so anything other than black there shifts the
    // brightness of the whole picture. Sampled mid-pulse and mid-porch, far
    // enough from the edges that a pixel or two of skew does not register.
    // ------------------------------------------------------------------
    task check_blanking;
        input  integer nlines;
        output integer violations;
        integer i;
        real    t_line;
        begin
            violations = 0;
            for (i = 0; i < nlines; i = i + 1) begin
                @(posedge hs_lead);
                t_line = $realtime;
                #((H_SYNC / 2.0) * t_pix_ns);
                if ({r, g, b} !== 12'h000) violations = violations + 1;
                #(t_line + (H_SYNC + H_BACK/2.0) * t_pix_ns - $realtime);
                if ({r, g, b} !== 12'h000) violations = violations + 1;
                #(t_line + (H_SYNC + H_BACK + H_VISIBLE + H_FRONT/2.0)
                  * t_pix_ns - $realtime);
                if ({r, g, b} !== 12'h000) violations = violations + 1;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // check_line_jitter: a monitor's PLL tracks the line rate, so a line
    // period that wanders means the picture tears or loses lock. Returns
    // the largest deviation from the first measured period, in ns.
    // ------------------------------------------------------------------
    task check_line_jitter;
        input  integer nlines;
        output real    worst_ns;
        integer i;
        real    t_prev, t_now, ref_ns, d;
        begin
            worst_ns = 0.0;
            @(posedge hs_lead);
            t_prev = $realtime;
            @(posedge hs_lead);
            t_now  = $realtime;
            ref_ns = t_now - t_prev;
            t_prev = t_now;
            for (i = 0; i < nlines; i = i + 1) begin
                @(posedge hs_lead);
                t_now = $realtime;
                d = (t_now - t_prev) - ref_ns;
                if (d < 0.0) d = -d;
                if (d > worst_ns) worst_ns = d;
                t_prev = t_now;
            end
        end
    endtask

    // ------------------------------------------------------------------
    // Reporting
    // ------------------------------------------------------------------
    task report_timing;
        begin
            $display("  --- measured at the connector ---");
            $display("  hsync : %-8s period %9.1f ns  pulse %8.1f ns",
                     hs_active_high ? "POSITIVE" : "NEGATIVE",
                     hs_period_ns, hs_width_ns);
            $display("  vsync : %-8s period %9.1f ns  pulse %8.1f ns",
                     vs_active_high ? "POSITIVE" : "NEGATIVE",
                     vs_period_ns, vs_width_ns);
            $display("  lines per frame : %0d", measured_lines);
            $display("  line rate       : %0.3f kHz", 1000000.0 / hs_period_ns);
            $display("  frame rate      : %0.3f Hz", 1000000000.0 / vs_period_ns);
            $display("  recovered pixel clock : %0.4f MHz (%0.2f ns)",
                     1000.0 / t_pix_ns, t_pix_ns);
        end
    endtask

    // Machine-readable, so the checker script does not have to scrape stdout.
    task write_timing_file;
        input [1023:0] fname;
        integer fd;
        begin
            fd = $fopen(fname, "w");
            if (fd == 0) begin
                $display("  MONITOR: cannot open %0s", fname);
            end else begin
                $fwrite(fd, "hsync_active_high %0d\n", hs_active_high);
                $fwrite(fd, "vsync_active_high %0d\n", vs_active_high);
                $fwrite(fd, "hsync_period_ns %0.3f\n", hs_period_ns);
                $fwrite(fd, "hsync_pulse_ns %0.3f\n",  hs_width_ns);
                $fwrite(fd, "vsync_period_ns %0.3f\n", vs_period_ns);
                $fwrite(fd, "vsync_pulse_ns %0.3f\n",  vs_width_ns);
                $fwrite(fd, "lines_per_frame %0d\n",   measured_lines);
                $fwrite(fd, "pixel_clock_ns %0.4f\n",  t_pix_ns);
                $fwrite(fd, "h_visible %0d\n", H_VISIBLE);
                $fwrite(fd, "v_visible %0d\n", V_VISIBLE);
                $fwrite(fd, "h_total %0d\n",   H_TOTAL);
                $fwrite(fd, "v_total %0d\n",   V_TOTAL);
                $fclose(fd);
            end
        end
    endtask

    // Binary PPM (P6). 4-bit DAC value scaled to 8 bits by x17, which maps
    // 0->0 and 15->255 exactly.
    task dump_ppm;
        input [1023:0] fname;
        integer fd, i;
        reg [11:0] px;
        begin
            fd = $fopen(fname, "wb");
            if (fd == 0) begin
                $display("  MONITOR: cannot open %0s", fname);
            end else begin
                $fwrite(fd, "P6\n%0d %0d\n255\n", H_VISIBLE, V_VISIBLE);
                for (i = 0; i < PIXELS; i = i + 1) begin
                    px = framebuf[i];
                    $fwrite(fd, "%c", (px[11:8] === 4'bxxxx) ? 8'd0 : px[11:8] * 8'd17);
                    $fwrite(fd, "%c", (px[7:4]  === 4'bxxxx) ? 8'd0 : px[7:4]  * 8'd17);
                    $fwrite(fd, "%c", (px[3:0]  === 4'bxxxx) ? 8'd0 : px[3:0]  * 8'd17);
                end
                $fclose(fd);
                $display("  MONITOR: wrote %0s (%0dx%0d)", fname, H_VISIBLE, V_VISIBLE);
            end
        end
    endtask

    // Count pixels that came out of the capture as X. On a real cable this
    // cannot happen -- it means the DAC pins were undriven when the monitor
    // sampled them, which is a genuine defect and not a simulation artifact.
    function integer x_pixels;
        integer i, n;
        begin
            n = 0;
            for (i = 0; i < PIXELS; i = i + 1)
                if (^framebuf[i] === 1'bx) n = n + 1;
            x_pixels = n;
        end
    endfunction

endmodule
