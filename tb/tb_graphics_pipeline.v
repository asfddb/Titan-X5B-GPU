// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

module tb_graphics_pipeline;

    reg clk;
    reg rst_n;
    
    // Rasterizer inputs
    reg i_valid;
    wire i_ready;
    reg signed [15:0] i_x0, i_y0;
    reg signed [15:0] i_x1, i_y1;
    reg signed [15:0] i_x2, i_y2;
    
    // Rasterizer outputs
    wire rast_valid;
    wire rast_ready;
    wire signed [15:0] rast_x, rast_y;
    wire signed [31:0] rast_w0, rast_w1, rast_w2;
    
    // SR Engine inputs
    wire sr_valid = rast_valid;
    wire sr_ready;
    wire [7:0] sr_warp_id = 8'd1;
    wire [12:0] sr_pixel_x = rast_x[12:0];
    wire [12:0] sr_pixel_y = rast_y[12:0];
    wire signed [11:0] sr_motion_x = 12'd5;
    wire signed [11:0] sr_motion_y = -12'd3;
    wire [31:0] sr_seed = 32'hA5A5A5A5;
    
    // SR Engine outputs
    wire sr_out_valid;
    reg sr_out_ready;
    wire sr_cache_hit;
    wire sr_cache_miss;
    wire [31:0] sr_reproj_tag;
    wire [15:0] sr_confidence;
    
    // Connect backpressure from SR engine to Rasterizer
    assign rast_ready = sr_ready;
    
    titan_x5_rasterizer #(
        .COORD_W(16),
        .WEIGHT_W(32)
    ) u_rasterizer (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .i_ready(i_ready),
        .i_x0(i_x0), .i_y0(i_y0),
        .i_x1(i_x1), .i_y1(i_y1),
        .i_x2(i_x2), .i_y2(i_y2),
        .o_valid(rast_valid),
        .o_ready(rast_ready),
        .o_x(rast_x), .o_y(rast_y),
        .o_w0(rast_w0), .o_w1(rast_w1), .o_w2(rast_w2)
    );
    
    titan_x5_apex_sr_engine #(
        .CACHE_ADDR_BITS(8)
    ) u_sr_engine (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(sr_valid),
        .in_ready(sr_ready),
        .in_warp_id(sr_warp_id),
        .in_pixel_x(sr_pixel_x),
        .in_pixel_y(sr_pixel_y),
        .in_motion_x(sr_motion_x),
        .in_motion_y(sr_motion_y),
        .in_frame_hash_seed(sr_seed),
        .out_valid(sr_out_valid),
        .out_ready(sr_out_ready),
        .cache_hit(sr_cache_hit),
        .cache_miss(sr_cache_miss),
        .reproj_tag(sr_reproj_tag),
        .confidence(sr_confidence)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    integer pixel_count;
    
    initial begin
        // Initialize
        rst_n = 0;
        i_valid = 0;
        i_x0 = 0; i_y0 = 0;
        i_x1 = 0; i_y1 = 0;
        i_x2 = 0; i_y2 = 0;
        sr_out_ready = 1;
        pixel_count = 0;
        
        $dumpfile("tb_graphics_pipeline.vcd");
        $dumpvars(0, tb_graphics_pipeline);
        
        #20 rst_n = 1;
        
        // Wait for rasterizer to be ready
        wait(i_ready);
        @(posedge clk);
        
        // Send a triangle: right-angled, (10, 10), (20, 10), (10, 20)
        i_valid = 1;
        i_x0 = 10; i_y0 = 10;
        i_x1 = 20; i_y1 = 10;
        i_x2 = 10; i_y2 = 20;
        
        @(posedge clk);
        i_valid = 0;
        
        // Wait for rasterizer to finish its traversal
        wait(!i_ready);
        wait(i_ready);
        
        // Give some extra cycles for SR Engine to flush its pipeline
        #100;
        
        $display("Simulation finished. Total pixels generated: %0d", pixel_count);
        $finish;
    end
    
    // Monitor SR engine egress channel
    always @(posedge clk) begin
        if (sr_out_valid && sr_out_ready) begin
            $display("Time=%0t | Pixel: (x=%0d, y=%0d) | SR Tag: %h | Hit: %b | Miss: %b | Conf: %h",
                     $time, u_rasterizer.o_x, u_rasterizer.o_y, 
                     sr_reproj_tag, sr_cache_hit, sr_cache_miss, sr_confidence);
            pixel_count = pixel_count + 1;
        end
    end

endmodule
