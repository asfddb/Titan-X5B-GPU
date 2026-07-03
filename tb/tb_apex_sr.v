// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

module tb_apex_sr();
    reg clk;
    reg rst_n;
    
    // Ingress
    reg in_valid;
    wire in_ready;
    reg [7:0] in_warp_id;
    reg [12:0] in_pixel_x;
    reg [12:0] in_pixel_y;
    reg signed [11:0] in_motion_x;
    reg signed [11:0] in_motion_y;
    reg [31:0] in_frame_hash_seed;
    
    // Egress
    wire out_valid;
    reg out_ready;
    wire cache_hit;
    wire cache_miss;
    wire [31:0] reproj_tag;
    wire [15:0] confidence;

    titan_x5_apex_sr_engine u_sr (
        .clk(clk), .rst_n(rst_n),
        .in_valid(in_valid), .in_ready(in_ready),
        .in_warp_id(in_warp_id), .in_pixel_x(in_pixel_x), .in_pixel_y(in_pixel_y),
        .in_motion_x(in_motion_x), .in_motion_y(in_motion_y), .in_frame_hash_seed(in_frame_hash_seed),
        .out_valid(out_valid), .out_ready(out_ready),
        .cache_hit(cache_hit), .cache_miss(cache_miss),
        .reproj_tag(reproj_tag), .confidence(confidence)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Task to push a descriptor
    task push_descriptor(
        input [7:0] w_id,
        input [12:0] p_x,
        input [12:0] p_y,
        input signed [11:0] m_x,
        input signed [11:0] m_y
    );
        begin
            @(negedge clk);
            in_valid = 1;
            in_warp_id = w_id;
            in_pixel_x = p_x;
            in_pixel_y = p_y;
            in_motion_x = m_x;
            in_motion_y = m_y;
            
            // Wait until accepted
            while (in_ready !== 1'b1) @(negedge clk);
            
            @(negedge clk);
            in_valid = 0;
            
            // Wait for it to pop out
            while (out_valid !== 1'b1) @(negedge clk);
        end
    endtask

    initial begin
        $dumpfile("waves_sr.vcd");
        $dumpvars(0, tb_apex_sr);
        
        // Monitor egress
        $monitor("TIME:%0t | HIT:%b MISS:%b TAG:%h CONFIDENCE:%h", $time, cache_hit, cache_miss, reproj_tag, confidence);

        rst_n = 0;
        in_valid = 0;
        out_ready = 1;
        in_frame_hash_seed = 32'hBEEF_CAFE;
        #25 rst_n = 1;
        
        $display("\n--- Test 1: First time descriptor (Expect MISS) ---");
        push_descriptor(8'd1, 13'd100, 13'd200, 12'd5, -12'd3);
        
        $display("\n--- Test 2: Identical temporal descriptor (Expect HIT) ---");
        push_descriptor(8'd1, 13'd100, 13'd200, 12'd5, -12'd3);
        
        $display("\n--- Test 3: New coordinates (Expect MISS) ---");
        push_descriptor(8'd1, 13'd101, 13'd200, 12'd5, -12'd3);
        
        $display("\n--- Test 4: Extreme motion vector (Expect low confidence) ---");
        push_descriptor(8'd2, 13'd500, 13'd500, 12'd2000, 12'd2000);
        
        #50;
        $display("\n--- APEX SR ENGINE VERIFICATION COMPLETE ---");
        $finish;
    end

endmodule
