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
 * Self-checking testbench for the Tiny Tapeout FMA wrapper.
 *
 * This tests the WRAPPER, not the arithmetic - tb/test_fpu.py already drives
 * the FMA core against an IEEE oracle. What can break here is the plumbing:
 * byte order, the start pulse, the done handshake, and the result shift-out.
 * Those are exactly the things that turn a correct adder into a dead chip,
 * and they are invisible until someone tries to talk to the pins.
 */
module tb_tt_um_titan_fma;

    reg        clk = 0, rst_n = 0, ena = 1;
    reg  [7:0] ui_in = 8'h00;
    reg  [7:0] uio_drive = 8'h00;
    wire [7:0] uo_out, uio_out, uio_oe;

    integer errors = 0;

    always #5 clk = ~clk;   // 100 MHz

    tt_um_titan_fma dut (
        .ui_in   (ui_in),
        .uo_out  (uo_out),
        .uio_in  (uio_drive),
        .uio_out (uio_out),
        .uio_oe  (uio_oe),
        .ena     (ena),
        .clk     (clk),
        .rst_n   (rst_n)
    );

    wire done = uio_out[7];

    // --- bus-functional model ----------------------------------------------
    task wr_byte(input [7:0] b);
        begin
            @(negedge clk);
            ui_in     = b;
            uio_drive = 8'b0000_0001;      // wr
            @(negedge clk);
            uio_drive = 8'b0000_0000;
        end
    endtask

    task load_operands(input [31:0] a, input [31:0] b, input [31:0] c);
        begin
            wr_byte(a[31:24]); wr_byte(a[23:16]);
            wr_byte(a[15:8]);  wr_byte(a[7:0]);
            wr_byte(b[31:24]); wr_byte(b[23:16]);
            wr_byte(b[15:8]);  wr_byte(b[7:0]);
            wr_byte(c[31:24]); wr_byte(c[23:16]);
            wr_byte(c[15:8]);  wr_byte(c[7:0]);
        end
    endtask

    task pulse_start(input [1:0] rm);
        begin
            @(negedge clk);
            uio_drive = {3'b000, 1'b0, rm, 1'b1, 1'b0};  // rm, start
            @(negedge clk);
            uio_drive = 8'b0000_0000;
        end
    endtask

    task rd_byte(output [7:0] b);
        begin
            @(negedge clk);
            b = uo_out;                    // current byte is already presented
            uio_drive = 8'b0001_0000;      // rd -> advance
            @(negedge clk);
            uio_drive = 8'b0000_0000;
        end
    endtask

    task run_case(input [31:0] a, input [31:0] b, input [31:0] c,
                  input [31:0] expect_result,
                  input [8*24:1] label);
        reg [7:0] r3, r2, r1, r0, fl;
        reg [31:0] got;
        integer guard;
        begin
            load_operands(a, b, c);
            pulse_start(2'b00);            // round-nearest-even

            guard = 0;
            while (!done && guard < 100) begin
                @(posedge clk);
                guard = guard + 1;
            end

            if (!done) begin
                $display("  [FAIL] %0s: done never asserted", label);
                errors = errors + 1;
            end else begin
                rd_byte(r3); rd_byte(r2); rd_byte(r1); rd_byte(r0);
                rd_byte(fl);
                got = {r3, r2, r1, r0};
                if (got !== expect_result) begin
                    $display("  [FAIL] %0s: got %h, expected %h",
                             label, got, expect_result);
                    errors = errors + 1;
                end else begin
                    $display("  [PASS] %0s = %h  (flags %b)",
                             label, got, fl[3:0]);
                end
            end
        end
    endtask

    initial begin
        $display("================================================");
        $display(" Tiny Tapeout wrapper: titan_x5_fp32_fma");
        $display("================================================");

        repeat (4) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);

        // a*b + c, all exact in binary so the expected value is unambiguous
        // and a rounding difference cannot mask a byte-order bug.
        run_case(32'h3F800000, 32'h40000000, 32'h40400000,
                 32'h40A00000, "1.0*2.0+3.0 = 5.0");

        run_case(32'h40000000, 32'h40400000, 32'h3F800000,
                 32'h40E00000, "2.0*3.0+1.0 = 7.0");

        run_case(32'h3FC00000, 32'h3FC00000, 32'h3E800000,
                 32'h40200000, "1.5*1.5+0.25 = 2.5");

        // Asymmetric operands: catches a wrapper that swaps a and b, which
        // the symmetric cases above cannot detect.
        run_case(32'h41200000, 32'h40800000, 32'h00000000,
                 32'h42200000, "10.0*4.0+0.0 = 40.0");

        // Negative result, and c dominating the product.
        run_case(32'h3F800000, 32'hC0000000, 32'h3F800000,
                 32'hBF800000, "1.0*-2.0+1.0 = -1.0");

        $display("================================================");
        if (errors == 0)
            $display(" ALL TESTS PASSED");
        else
            $display(" %0d FAILURES", errors);
        $display("================================================");
        $finish;
    end

    initial begin
        #200000;
        $display(" [FAIL] global timeout");
        $finish;
    end

endmodule
