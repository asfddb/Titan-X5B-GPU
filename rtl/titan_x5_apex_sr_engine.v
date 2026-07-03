// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

/*
 * Titan X5 Apex SR Engine
 * Document ID: TX5-SR-IP-DS-001
 * Description: Temporal Reprojection Cache IP for Advanced GPU Pipelines
 * 
 * Pipeline:
 * Stage 1: Ingress & Canonicalize
 * Stage 2: FNV-1a Hash Computation
 * Stage 3: Cache Tag Match & Metadata output
 */
module titan_x5_apex_sr_engine #(
    parameter CACHE_ADDR_BITS = 8 // 256-entry direct mapped cache
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // ingress channel
    input  wire        in_valid,
    output wire        in_ready,
    input wire [7:0] in_warp_id,
    input wire [12:0] in_pixel_x,
    input wire [12:0] in_pixel_y,
    input  wire signed [11:0] in_motion_x,
    input  wire signed [11:0] in_motion_y,
    input wire [31:0] in_frame_hash_seed,
    
    // egress channel
    output wire        out_valid,
    input  wire        out_ready,
    output wire        cache_hit,
    output wire        cache_miss,
    output wire [31:0] reproj_tag,
    output wire [15:0] confidence
);

    // fnv-1a 32-bit constants
    localparam FNV_PRIME  = 32'h01000193;
    localparam FNV_OFFSET = 32'h811c9dc5;

    // --- PIPELINE STAGE 1: INGRESS ---
    reg s1_valid;
    reg [7:0]  s1_warp_id;
    reg [12:0] s1_pixel_x, s1_pixel_y;
    reg signed [11:0] s1_motion_x, s1_motion_y;
    reg [31:0] s1_seed;

    // backpressure logic: ready if downstream is ready or stage 1 is empty
    wire s1_ready = !s1_valid || s2_ready;
    assign in_ready = s1_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
        end else if (in_ready) begin
            s1_valid <= in_valid;
            if (in_valid) begin
                s1_warp_id <= in_warp_id;
                s1_pixel_x <= in_pixel_x;
                s1_pixel_y <= in_pixel_y;
                s1_motion_x <= in_motion_x;
                s1_motion_y <= in_motion_y;
                s1_seed <= in_frame_hash_seed;
            end
        end
    end

    // --- PIPELINE STAGE 2: HASH COMPUTATION ---
    // combine coordinates into 32-bit blocks
    wire [31:0] s1_coord_block  = {6'b0, s1_pixel_x, s1_pixel_y};
    wire [31:0] s1_motion_block = {8'b0, s1_motion_x, s1_motion_y};
    
    // simplified 1-cycle fnv-1a mixing for timing closure in fpga
    // (A true multi-cycle FNV would pipeline these multiplications)
    wire [31:0] hash_p1 = (FNV_OFFSET ^ s1_seed) * FNV_PRIME;
    wire [31:0] hash_p2 = (hash_p1 ^ s1_coord_block) * FNV_PRIME;
    wire [31:0] hash_p3 = (hash_p2 ^ s1_motion_block) * FNV_PRIME;
    wire [31:0] hash_final = (hash_p3 ^ {24'b0, s1_warp_id}) * FNV_PRIME;

    reg s2_valid;
    reg [31:0] s2_tag;
    reg [15:0] s2_confidence;
    
    // simple motion-based confidence: high motion = low confidence
    wire [11:0] abs_motion_x = (s1_motion_x < 0) ? -s1_motion_x : s1_motion_x;
    wire [11:0] abs_motion_y = (s1_motion_y < 0) ? -s1_motion_y : s1_motion_y;
    wire [15:0] computed_confidence = 16'hFFFF - {4'b0, (abs_motion_x + abs_motion_y)};

    wire s2_ready = !s2_valid || out_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 1'b0;
        end else if (s2_ready) begin
            s2_valid <= s1_valid;
            if (s1_valid) begin
                s2_tag <= hash_final;
                s2_confidence <= computed_confidence;
            end
        end
    end

    // --- PIPELINE STAGE 3: CACHE MATCH & EGRESS ---
    // direct mapped temporal cache
    localparam CACHE_DEPTH = 1 << CACHE_ADDR_BITS;
    (* ram_style="block" *) reg [31:0] cache_tags [0:CACHE_DEPTH-1];
    reg [CACHE_DEPTH-1:0] cache_valid;

    wire [CACHE_ADDR_BITS-1:0] cache_index = s2_tag[CACHE_ADDR_BITS-1:0];
    
    reg is_hit;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cache_valid <= {CACHE_DEPTH{1'b0}};
        end else if (s2_valid && s2_ready) begin
            // update cache unconditionally on tag computation
            cache_tags[cache_index] <= s2_tag;
            cache_valid[cache_index] <= 1'b1;
        end
    end
    
    // combinatorial hit detection for the current tag
    always @(*) begin
        if (cache_valid[cache_index] && (cache_tags[cache_index] == s2_tag))
            is_hit = 1'b1;
        else
            is_hit = 1'b0;
    end

    assign out_valid = s2_valid;
    assign cache_hit = s2_valid ? is_hit : 1'b0;
    assign cache_miss = s2_valid ? !is_hit : 1'b0;
    assign reproj_tag = s2_tag;
    assign confidence = s2_confidence;

endmodule
