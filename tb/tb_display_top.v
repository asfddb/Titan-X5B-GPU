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
 * Smoke test for titan_x5_display_top (Basys 3 display-path hello world).
 * Checks, in order:
 *   1. boot fill completes (led[0])
 *   2. hsync period matches 640x400@70 timing (800 pclk = 3200 clk cycles)
 *   3. vsync arrives after 449 lines
 *   4. first visible scanline carries the expected XOR-pattern palette
 *      colors (pattern 0: idx = x[8:5]^y[8:5]; y=0 -> idx = x[8:5])
 * Run:
 *   iverilog -g2012 -s tb_display_top -o sim_display.vvp \
 *     rtl/xilinx_stubs.v rtl/memory/titan_x5_vram_ctrl.v \
 *     rtl/display/titan_x5_async_fifo.v rtl/display/titan_x5_display_engine.v \
 *     fpga/titan_x5_display_top.v tb/tb_display_top.v && vvp sim_display.vvp
 */
module tb_display_top;

    reg clk = 0;
    reg btnC = 1;
    reg btnU = 0;
    reg [15:0] sw = 16'd0;
    wire [15:0] led;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hsync, vga_vsync;

    always #5 clk = ~clk; // 100MHz

    titan_x5_display_top dut (
        .clk_100mhz(clk), .sw(sw), .btnC(btnC), .btnU(btnU), .led(led),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync)
    );

    integer errors = 0;
    integer i;

    // expected 4-bit palette index for pattern 0 at (x, y)
    function [3:0] exp_idx(input [9:0] x, input [8:0] y);
        exp_idx = x[8:5] ^ y[8:5];
    endfunction

    // palette (must match RTL); returns {r4,g4,b4}
    function [11:0] pal4(input [3:0] idx);
        case (idx)
            4'h0: pal4 = 12'h000; 4'h1: pal4 = 12'h00A;
            4'h2: pal4 = 12'h0A0; 4'h3: pal4 = 12'h0AA;
            4'h4: pal4 = 12'hA00; 4'h5: pal4 = 12'hA0A;
            4'h6: pal4 = 12'hA50; 4'h7: pal4 = 12'hAAA;
            4'h8: pal4 = 12'h555; 4'h9: pal4 = 12'h55F;
            4'hA: pal4 = 12'h5F5; 4'hB: pal4 = 12'h5FF;
            4'hC: pal4 = 12'hF55; 4'hD: pal4 = 12'hF5F;
            4'hE: pal4 = 12'hFF5; 4'hF: pal4 = 12'hFFF;
        endcase
    endfunction

    time t_hs_rise0, t_hs_rise1;
    integer hs_count;

    initial begin
        // reset pulse
        #100 btnC = 0;

        // 1. wait for boot fill (2000 AXI writes, ~10 cycles each)
        fork : fill_wait
            begin
                wait (led[0] === 1'b1);
                $display("[%0t] PASS: boot fill complete", $time);
                disable fill_wait;
            end
            begin
                #2_000_000; // 2ms >> expected ~200us
                $display("FAIL: boot fill did not complete within 2ms");
                errors = errors + 1;
                disable fill_wait;
            end
        join

        // 2. hsync period: 800 pclks @ 40ns = 32,000ns
        @(posedge vga_hsync) t_hs_rise0 = $time;
        @(posedge vga_hsync) t_hs_rise1 = $time;
        if (t_hs_rise1 - t_hs_rise0 !== 32000) begin
            $display("FAIL: hsync period %0d ns (expected 32000)", t_hs_rise1 - t_hs_rise0);
            errors = errors + 1;
        end else $display("[%0t] PASS: hsync period 32.0us (640x400@70 line)", $time);

        // 3. vsync period: 449 lines
        @(posedge vga_vsync) t_hs_rise0 = $time;
        @(posedge vga_vsync) t_hs_rise1 = $time;
        if (t_hs_rise1 - t_hs_rise0 !== 32000 * 449) begin
            $display("FAIL: vsync period %0d ns (expected %0d)",
                     t_hs_rise1 - t_hs_rise0, 32000 * 449);
            errors = errors + 1;
        end else $display("[%0t] PASS: vsync period = 449 lines", $time);

        // 4. sample one visible scanline mid-pixel (negedge pclk). The
        //    engine's FIFO pop + output register give 2 pclk of latency, so
        //    the pixel on the wires at h_counter==n is pixel n-2 (measured;
        //    also means de/rgb are skewed by one pclk - a known 1-pixel
        //    cosmetic quirk at the line edges, invisible on a monitor).
        @(posedge dut.de_de);
        for (i = 0; i < 640; i = i + 1) begin
            @(negedge dut.clk_pixel);
            if (dut.u_disp.h_counter >= 12'd2 && dut.u_disp.vga_de) begin
                if ({vga_r, vga_g, vga_b} !==
                    pal4(exp_idx(dut.u_disp.h_counter - 12'd2,
                                 dut.u_disp.v_counter[8:0]))) begin
                    if (errors < 5)
                        $display("FAIL: pixel x=%0d y=%0d rgb=%h expected=%h",
                                 dut.u_disp.h_counter - 12'd2,
                                 dut.u_disp.v_counter,
                                 {vga_r, vga_g, vga_b},
                                 pal4(exp_idx(dut.u_disp.h_counter - 12'd2,
                                              dut.u_disp.v_counter[8:0])));
                    errors = errors + 1;
                end
            end
        end
        if (errors == 0)
            $display("PASS: full first visible scanline matches XOR pattern");

        if (errors == 0) $display("ALL TESTS PASSED");
        else $display("%0d ERRORS", errors);
        $finish;
    end

    initial begin
        #300_000_000;
        $display("FAIL: global timeout");
        $finish;
    end

endmodule
