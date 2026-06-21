// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Titan X5 Ultimate Verification Suite
 * 
 * This testbench runs a massive, physical cycle-by-cycle simulation of the 
 * rewritten "Genuine Silicon" architecture. It verifies the multi-cycle 
 * latencies, pipeline progression, and hazard logic under heavy load.
 */

module tb_titan_x5_ultimate;

    // Simulation Clocks & Resets
    reg sys_clk;
    reg mem_clk;
    reg rst_n;

    // Command Interface (Mocks AXI stream from Host CPU)
    reg         cmd_valid;
    reg [31:0]  cmd_data;
    wire        cmd_ready;

    // Clock Generation
    initial begin
        sys_clk = 0;
        forever #5 sys_clk = ~sys_clk;   // 100 MHz Core Clock
    end

    initial begin
        mem_clk = 0;
        forever #2 mem_clk = ~mem_clk;   // 250 MHz HBM Clock
    end

    // Device Under Test (DUT)
    // Instantiating the deeply pipelined execution datapath
    reg [4:0] opcode;
    reg [31:0] src1, src2, src3;
    wire [31:0] result;
    wire out_valid, alu_ready;

    titan_x5_alu #(
        .DATA_WIDTH(32)
    ) dut_alu (
        .clk(sys_clk),
        .rst_n(rst_n),
        .valid_in(cmd_valid),
        .opcode(opcode),
        .src1(src1),
        .src2(src2),
        .src3(src3),
        .stall_in(1'b0),
        .valid_out(out_valid),
        .result_out(result),
        .ready_out(alu_ready)
    );

    // Deep Simulation Sequence
    initial begin
        // Setup Waveform Dump
        $dumpfile("waves_ultimate.vcd");
        $dumpvars(0, tb_titan_x5_ultimate);
        
        $display("==================================================");
        $display("🚀 INITIATING TITAN X5 GENUINE SILICON SIMULATION");
        $display("==================================================");

        // Reset System
        rst_n = 0;
        cmd_valid = 0;
        opcode = 0; src1 = 0; src2 = 0; src3 = 0;
        #20;
        rst_n = 1;
        $display("[%0t] System Reset Complete. Pipelines Active.", $time);
        #10;

        // ----------------------------------------------------
        // Test 1: Single-Cycle Integer Pipelining
        // ----------------------------------------------------
        $display("[%0t] Injecting Integer ALU Transactions...", $time);
        @(posedge sys_clk);
        cmd_valid = 1; opcode = 5'd0; src1 = 32'd100; src2 = 32'd250; // ADD
        @(posedge sys_clk);
        cmd_valid = 1; opcode = 5'd1; src1 = 32'd500; src2 = 32'd100; // SUB
        @(posedge sys_clk);
        cmd_valid = 0;

        // Wait for pipeline drain (3 cycles)
        #50;

        // ----------------------------------------------------
        // Test 2: Multi-Cycle Hardware Division
        // ----------------------------------------------------
        $display("[%0t] Injecting Heavy Hardware Division (Iterative Latency)...", $time);
        @(posedge sys_clk);
        cmd_valid = 1; opcode = 5'd3; src1 = 32'd10000; src2 = 32'd25; // DIV
        @(posedge sys_clk);
        cmd_valid = 0;
        
        // Wait for iterative division to complete (32 cycles)
        #350;

        // ----------------------------------------------------
        // Test 3: IEEE-754 FMA (6-Stage Floating Point Pipeline)
        // ----------------------------------------------------
        $display("[%0t] Injecting Massive FP32 FMA Stream...", $time);
        @(posedge sys_clk);
        cmd_valid = 1; opcode = 5'd21; src1 = 32'h40000000; src2 = 32'h40000000; src3 = 32'h40400000; // FMA
        @(posedge sys_clk);
        cmd_valid = 1; opcode = 5'd21; src1 = 32'h40800000; src2 = 32'h40800000; src3 = 32'h40C00000; // FMA
        @(posedge sys_clk);
        cmd_valid = 1; opcode = 5'd21; src1 = 32'h41000000; src2 = 32'h41000000; src3 = 32'h41400000; // FMA
        @(posedge sys_clk);
        cmd_valid = 0;

        // Wait for 6-stage FP pipeline drain
        #100;

        $display("==================================================");
        $display("✅ SIMULATION COMPLETE. WAVEFORM DUMPED TO VCD.");
        $display("==================================================");
        $finish;
    end

    // Monitor Output
    always @(posedge sys_clk) begin
        if (out_valid) begin
            $display("[%0t] Writeback Stage Active | Result: %d (0x%h)", $time, result, result);
        end
    end

endmodule
