// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
/*
 * Module: titan_x6_hdc_photonics
 * Description: 
 *   An ultra-low power Hyper-Dimensional Computing (HDC) engine coupled with 
 *   a conceptual photonic-to-electronic transducer interface.
 *   This module takes 32-bit standard electronic data (converted from photonics),
 *   spatially encodes it into a high-dimensional orthogonal space (e.g., 512-bit), 
 *   and calculates the similarity (cosine/Hamming) against a reference hypervector.
 *   Processing is done in chunks over multiple cycles to maintain high synthesizability,
 *   low combinational logic depth, and minimal dynamic power.
 * 
 * Features:
 *   - Verilog-2001 compliant, fully parameterizable.
 *   - Constant function based localparams for broad compatibility.
 *   - Multi-cycle pipelined popcount for ultra-low power.
 *   - LFSR-based basis hypervector generation for spatial encoding.
 */

`timescale 1ns / 1ps

module titan_x6_hdc_photonics #(
    parameter DATA_WIDTH   = 32,
    parameter HV_DIM       = 512,
    parameter METRIC_WIDTH = 16
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // photonic-to-electronic transducer interface
    input  wire                    photonics_en,
    input wire [DATA_WIDTH-1:0] data_in,
    input  wire                    data_valid,

    // reference memory interface (for similarity check)
    input wire [HV_DIM-1:0] ref_hv,

    // output
    output reg                     match_valid,
    output reg [METRIC_WIDTH-1:0] confidence_metric,
    output reg                     is_match
);

    // constant function for integer logarithm base 2
    function integer clog2;
        input integer value;
        begin
            value = value - 1;
            for (clog2 = 0; value > 0; clog2 = clog2 + 1) begin
                value = value >> 1;
            end
        end
    endfunction

    // architectural constraints (chunk-based sequential processing)
    localparam CHUNK_SIZE = 32;
    localparam NUM_CHUNKS = HV_DIM / CHUNK_SIZE;
    localparam CHUNK_BITS = clog2(NUM_CHUNKS) > 0 ? clog2(NUM_CHUNKS) : 1;

    // fsm states
    localparam STATE_IDLE   = 2'd0;
    localparam STATE_PROC   = 2'd1;
    localparam STATE_FINISH = 2'd2;

    reg [1:0]              state_q, state_d;
    reg [CHUNK_BITS:0]     chunk_cnt_q, chunk_cnt_d; // extended by 1 bit to prevent overflow
    reg [DATA_WIDTH-1:0]   data_reg_q, data_reg_d;
    reg [31:0]             lfsr_q, lfsr_d;
    reg [METRIC_WIDTH-1:0] distance_acc_q, distance_acc_d;
    
    // output pipeline registers
    reg                    match_valid_q, match_valid_d;
    reg [METRIC_WIDTH-1:0] confidence_metric_q, confidence_metric_d;
    reg                    is_match_q, is_match_d;

    always @* begin
        match_valid       = match_valid_q;
        confidence_metric = confidence_metric_q;
        is_match          = is_match_q;
    end

    // standard 32-bit popcount function for hamming distance
    function [5:0] popcount32;
    input [31:0] in;
        integer i;
        begin
            popcount32 = 6'd0;
            for (i = 0; i < 32; i = i + 1) begin
                popcount32 = popcount32 + in[i];
            end
        end
    endfunction

    // 32-bit Fibonacci LFSR for repeatable orthogonal basis generation
    function [31:0] next_lfsr;
    input [31:0] current;
        reg feedback;
        begin
            // characteristic polynomial for maximal length: x^32 + x^22 + x^2 + x + 1
            feedback = current[31] ^ current[21] ^ current[1] ^ current[0];
            next_lfsr = {current[30:0], feedback};
        end
    endfunction

    // combinatorial evaluation signals
    reg [CHUNK_SIZE-1:0] current_ref_chunk;
    reg [CHUNK_SIZE-1:0] current_hv_chunk;
    reg [CHUNK_SIZE-1:0] current_cmp_chunk;
    reg [5:0]            current_popcnt;

    always @* begin
        // retain state by default
        state_d             = state_q;
        chunk_cnt_d         = chunk_cnt_q;
        data_reg_d          = data_reg_q;
        lfsr_d              = lfsr_q;
        distance_acc_d      = distance_acc_q;
        
        // match pulse default
        match_valid_d       = 1'b0;
        confidence_metric_d = confidence_metric_q;
        is_match_d          = is_match_q;

        // combinatorial variables init
        current_ref_chunk = {CHUNK_SIZE{1'b0}};
        current_hv_chunk  = {CHUNK_SIZE{1'b0}};
        current_cmp_chunk = {CHUNK_SIZE{1'b0}};
        current_popcnt    = 6'd0;

        case (state_q)
            STATE_IDLE: begin
                if (photonics_en && data_valid) begin
                    data_reg_d     = data_in;
                    chunk_cnt_d    = 0;
                    distance_acc_d = {METRIC_WIDTH{1'b0}};
                    // seed the basis generator. for repeatable basis projection per sample.
                    lfsr_d         = 32'hACE1_0001; 
                    state_d        = STATE_PROC;
                end
            end

            STATE_PROC: begin
                if (chunk_cnt_q < NUM_CHUNKS) begin
                    // extract spatial reference chunk using verilog-2001 dynamic part-select
                    current_ref_chunk = ref_hv[chunk_cnt_q * CHUNK_SIZE +: CHUNK_SIZE];
                    
                    // spatial mapping: xor incoming 32-bit data with evolving 32-bit basis
                    current_hv_chunk  = data_reg_q ^ lfsr_q;
                    
                    // similarity match (bipolar/binary cosine via xor -> hamming distance)
                    current_cmp_chunk = current_hv_chunk ^ current_ref_chunk;
                    
                    // popcount computation
                    current_popcnt    = popcount32(current_cmp_chunk);
                    
                    // accumulate hamming distance
                    distance_acc_d    = distance_acc_q + current_popcnt;
                    
                    // advance lfsr orthogonal basis
                    lfsr_d            = next_lfsr(lfsr_q);
                    
                    if (chunk_cnt_q == (NUM_CHUNKS - 1)) begin
                        state_d = STATE_FINISH;
                    end else begin
                        chunk_cnt_d = chunk_cnt_q + 1;
                    end
                end else begin
                    state_d = STATE_FINISH;
                end
            end

            STATE_FINISH: begin
                match_valid_d       = 1'b1;
                
                // confidence metric: inversely proportional to hamming distance
                // max confidence = hv_dim (perfect match, distance 0)
                confidence_metric_d = HV_DIM - distance_acc_q;
                
                // threshold determination: match is affirmed if similarity is high
                // e.g. Distance < (HV_DIM/4) means > 75% bitwise match.
                if (distance_acc_q < (HV_DIM >> 2)) begin
                    is_match_d = 1'b1;
                end else begin
                    is_match_d = 1'b0;
                end
                
                state_d = STATE_IDLE;
            end

            default: begin
                state_d = STATE_IDLE;
            end
        endcase
    end

    // sequential register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q             <= STATE_IDLE;
            chunk_cnt_q         <= 0;
            data_reg_q          <= {DATA_WIDTH{1'b0}};
            lfsr_q              <= 32'h0;
            distance_acc_q      <= {METRIC_WIDTH{1'b0}};
            match_valid_q       <= 1'b0;
            confidence_metric_q <= {METRIC_WIDTH{1'b0}};
            is_match_q          <= 1'b0;
        end else begin
            state_q             <= state_d;
            chunk_cnt_q         <= chunk_cnt_d;
            data_reg_q          <= data_reg_d;
            lfsr_q              <= lfsr_d;
            distance_acc_q      <= distance_acc_d;
            match_valid_q       <= match_valid_d;
            confidence_metric_q <= confidence_metric_d;
            is_match_q          <= is_match_d;
        end
    end

endmodule
