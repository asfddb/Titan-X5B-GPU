// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module tb_titan_x_wse();

    reg clk;
    reg rst_n;
    
    // 4 cores for a 2x2 grid
    reg [3:0] defect_fuses;
    
    // 2 columns * 32 bits = 64 bits for top/bottom
    reg  [63:0] io_in_top;
    wire [63:0] io_out_top;
    reg  [63:0] io_in_bottom;
    wire [63:0] io_out_bottom;
    
    // 2 rows * 32 bits = 64 bits for left/right
    reg  [63:0] io_in_left;
    wire [63:0] io_out_left;
    reg  [63:0] io_in_right;
    wire [63:0] io_out_right;

    titan_x_infinity_wse u_wse (
        .clk(clk),
        .rst_n(rst_n),
        .defect_fuses(defect_fuses),
        
        .io_in_top(io_in_top),
        .io_out_top(io_out_top),
        .io_in_bottom(io_in_bottom),
        .io_out_bottom(io_out_bottom),
        
        .io_in_left(io_in_left),
        .io_out_left(io_out_left),
        .io_in_right(io_in_right),
        .io_out_right(io_out_right)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Setup VCD dumping
        $dumpfile("waves_wse.vcd");
        $dumpvars(0, tb_titan_x_wse);
        
        // Initialize
        rst_n = 0;
        defect_fuses = 4'b0000; // All cores alive
        io_in_top = 64'd0;
        io_in_bottom = 64'd0;
        io_in_left = 64'd0;
        io_in_right = 64'd0;
        
        #20 rst_n = 1;
        
        $display("[%0t] Starting Wafer-Scale Engine 2D Mesh NoC Test...", $time);
        
        // Feed data into the Top edge (Column 0 gets 0xAAAA, Column 1 gets 0xBBBB)
        @(posedge clk);
        io_in_top[31:0]  = 32'h0000AAAA;
        io_in_top[63:32] = 32'h0000BBBB;
        
        // Let it ripple through the 2D mesh
        #50;
        
        $display("[%0t] Output at Bottom Edge Col 0: %h", $time, io_out_bottom[31:0]);
        $display("[%0t] Output at Bottom Edge Col 1: %h", $time, io_out_bottom[63:32]);
        
        // Test Defect Bypass Hardware
        $display("[%0t] Simulating a massive manufacturing defect in Core 1...", $time);
        @(posedge clk);
        defect_fuses = 4'b0010; // Core index 1 (Row 0, Col 1) is dead!
        
        // Feed new data to see it bypass the dead core
        io_in_top[31:0]  = 32'h0000CCCC;
        io_in_top[63:32] = 32'h0000DDDD;
        
        #50;
        $display("[%0t] Output at Bottom Edge Col 1 after bypass: %h", $time, io_out_bottom[63:32]);
        
        #100;
        $display("GTKWave Simulation Complete! VCD file generated.");
        $finish; // EXPLICIT FINISH to prevent infinite looping and massive file sizes!
    end

endmodule
