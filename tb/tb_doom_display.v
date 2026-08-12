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
 * Testbench: tb_doom_display
 * Description: Put the raycast frame on the monitor, through the real
 *              hardware.
 *
 *              `compiler/kernels/doom_raycast.py` is compiled to Titan ISA and
 *              executed by tools/doom_titan.py, which writes the framebuffer
 *              out as a VRAM image. This loads that image and lets
 *              titan_x5_display_top scan it out: the real timing generator,
 *              the real line-buffer shim, the real palette, the real 4-bit
 *              DAC pins. `tb/board/vga_monitor.v` then captures what a monitor
 *              plugged into the board would show, off the connector.
 *
 *              HONEST SCOPE. Unlike tb/tb_board_bringup.v this testbench does
 *              reach into the DUT -- it deposits the framebuffer straight into
 *              the VRAM array, which stands in for a host DMA writing the
 *              framebuffer over a link the board does not have. Everything
 *              downstream of that deposit is the design. Nothing here renders
 *              anything; the picture was already computed by the kernel.
 *
 *              btnC is pressed before loading because the display path does
 *              not come out of configuration reset on its own -- see finding 1
 *              in docs/FPGA_BRINGUP_NO_BOARD.md. That is the bug this rig
 *              found, and this file has to work around it.
 *
 * Plusargs:
 *   +vram=<path>    $readmemh image, 2048 lines of 512 bits
 *   +outdir=<path>  where the captured frame is written
 */
module tb_doom_display;

    wire        clk_100mhz;
    wire        btnC, btnU;
    wire [15:0] sw;
    wire        cfg_done;

    basys3_board board (
        .clk_100mhz(clk_100mhz), .btnC(btnC), .btnU(btnU),
        .sw(sw), .cfg_done(cfg_done)
    );

    wire [15:0] led;
    wire [3:0]  vga_r, vga_g, vga_b;
    wire        vga_hsync, vga_vsync;

    titan_x5_display_top dut (
        .clk_100mhz(clk_100mhz), .sw(sw), .btnC(btnC), .btnU(btnU),
        .led(led), .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync)
    );

    vga_monitor #(
        .H_VISIBLE(640), .H_FRONT(16), .H_SYNC(96), .H_BACK(48),
        .V_VISIBLE(400), .V_FRONT(12), .V_SYNC(2),  .V_BACK(35)
    ) mon (
        .r(vga_r), .g(vga_g), .b(vga_b),
        .hsync(vga_hsync), .vsync(vga_vsync)
    );

    reg [1023:0] vram_file, outdir, fname;
    integer      pa;
    reg          ok;
    real         deadline;

    initial begin
        vram_file = "doom_out/doom_vram.hex";
        outdir    = "doom_out";
        pa = $value$plusargs("vram=%s", vram_file);
        pa = $value$plusargs("outdir=%s", outdir);

        $display("");
        $display("================================================================");
        $display(" Titan X5 -- raycast frame out of the real display path");
        $display("================================================================");

        board.power_on;

        // The display path needs a reset press to start scanning; see the
        // header. Wait for the boot fill so the writer is finished and will
        // not overwrite what we are about to deposit.
        board.press_btnC(2_000_000.0);
        deadline = $realtime + 10_000_000.0;
        ok = 1'b0;
        while (!ok && $realtime < deadline) begin
            if (led[0] === 1'b1) ok = 1'b1;
            else #1000;
        end
        if (!ok) begin
            $display("  FAIL: boot fill never completed");
            $finish;
        end
        $display("  boot fill done at %0.0f ns; loading the raycast frame",
                 $realtime);

        // Deposit the rendered framebuffer. The boot writer has finished, so
        // nothing else touches VRAM from here on.
        $readmemh(vram_file, dut.u_vram.bram);
        $display("  loaded %0s into VRAM", vram_file);

        // Let the line-buffer shim turn over -- it caches one 64-byte line and
        // is not invalidated by a VRAM change (see finding 4).
        @(posedge vga_vsync);

        mon.wait_for_lock(80_000_000.0);
        if (!mon.locked) begin
            $display("  FAIL: no signal on the VGA connector");
            $finish;
        end
        mon.capture_frame;
        mon.report_timing;

        if (mon.x_pixels() != 0)
            $display("  WARNING: %0d pixels sampled as X", mon.x_pixels());

        $sformat(fname, "%0s/doom_from_rtl.ppm", outdir);
        mon.dump_ppm(fname);

        $display("");
        $display(" Captured off the connector at %0.0f ns", $realtime);
        $display("================================================================");
        $finish;
    end



    initial begin
        #400_000_000;
        $display(" FAIL: global timeout");
        $finish;
    end

endmodule
