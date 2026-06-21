// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module cocotb_graphics_top(
    input clk,
    input rst_n,
    
    // Rasterizer Inputs
    input i_valid,
    output i_ready,
    input signed [15:0] v0_x, input signed [15:0] v0_y,
    input signed [15:0] v1_x, input signed [15:0] v1_y,
    input signed [15:0] v2_x, input signed [15:0] v2_y,
    
    // SR Engine Control
    input [7:0] sr_warp_id,
    input signed [11:0] sr_motion_x,
    input signed [11:0] sr_motion_y,
    input [31:0] sr_seed,
    
    // Final SR Engine Outputs
    output sr_out_valid,
    input  sr_out_ready,
    output sr_cache_hit,
    output sr_cache_miss,
    output [31:0] sr_reproj_tag,
    output [15:0] sr_confidence,
    
    // Exporting rasterizer output for monitoring
    output signed [15:0] rast_x,
    output signed [15:0] rast_y
);

    wire rast_valid;
    wire rast_ready;
    wire signed [31:0] rast_w0, rast_w1, rast_w2;
    
    // SR Engine Inputs
    wire sr_valid = rast_valid;
    wire sr_ready;
    wire [12:0] sr_pixel_x = rast_x[12:0];
    wire [12:0] sr_pixel_y = rast_y[12:0];
    
    assign rast_ready = sr_ready;
    
    titan_x5_rasterizer #(
        .COORD_W(16),
        .WEIGHT_W(32)
    ) u_rasterizer (
        .clk(clk),
        .rst_n(rst_n),
        .i_valid(i_valid),
        .i_ready(i_ready),
        .v0_x(v0_x), .v0_y(v0_y),
        .v1_x(v1_x), .v1_y(v1_y),
        .v2_x(v2_x), .v2_y(v2_y),
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
    
    // Dump waves for GTKWave viewing
    initial begin
        $dumpfile("cocotb_graphics_pipeline.vcd");
        $dumpvars(0, cocotb_graphics_top);
    end

endmodule
