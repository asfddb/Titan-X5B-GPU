// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x5_warp_scheduler #(
    parameter NUM_WARPS = 8
)(
    input  wire clk,
    input  wire rst_n,
    
    input wire [NUM_WARPS-1:0] warp_active,
    input wire [NUM_WARPS*32-1:0] warp_pc,
    
    input  wire        wb_valid,
    input wire [2:0] wb_warp_id,
    input wire [5:0] wb_reg,
    
    input  wire        id_valid,
    input wire [2:0] id_warp_id,
    input wire [5:0] id_dest_reg,
    
    input wire [5:0] id_src_reg1,
    input wire [5:0] id_src_reg2,
    
    input wire       fifo_full,
    
    input  wire        barrier_req,
    input wire [2:0] barrier_warp_id,
    
    // --- Divergence Handling Interfaces ---
    input wire        div_push,
    input wire [2:0]  div_warp_id,
    input wire [31:0] div_push_mask,
    input wire [31:0] div_push_pc,
    input wire [31:0] div_new_mask,
    
    input wire        div_pop,
    input wire [2:0]  div_pop_warp_id,
    
    output wire [31:0] div_popped_pc,
    output wire        div_popped_valid,
    // --------------------------------------
    
    output reg [2:0] sched_warp_id,
    output reg         sched_valid,
    output reg [31:0] sched_pc,
    output reg [31:0] sched_active_mask,
    
    output wire [NUM_WARPS-1:0] warp_stalled,
    output wire [NUM_WARPS-1:0] warp_ready
);

    // Flattened scoreboard: 8 warps x 64 bits, stored as 8 separate 64-bit registers
    // This maps to LUTRAM/flip-flops for single-cycle access
    reg [63:0] scoreboard [0:NUM_WARPS-1];
    
    // Age counters - use small counters, threshold-based
    reg [7:0] age_counter [0:NUM_WARPS-1];
    localparam STARVATION_THRESHOLD = 8'd32;
    
    // Barrier state
    reg [NUM_WARPS-1:0] barrier_waiting;
    
    // Round-robin pointer - registered for timing
    reg [2:0] rr_ptr;
    
    // Pre-computed hazard flags per warp
    reg [NUM_WARPS-1:0] src1_hazard;
    reg [NUM_WARPS-1:0] src2_hazard;
    reg [NUM_WARPS-1:0] any_hazard;
    
    // Combinational hazard detection - parallel for all warps
    // Using generate for parallel evaluation
    genvar g;
    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : hazard_gen
            wire src1_match = scoreboard[g][id_src_reg1];
            wire src2_match = scoreboard[g][id_src_reg2];
            wire has_hazard = src1_match | src2_match | fifo_full;
        end
    endgenerate
    
    // Flattened hazard signals for output
    wire [NUM_WARPS-1:0] has_hazard_flat;
    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : hazard_flat
            assign has_hazard_flat[g] = hazard_gen[g].has_hazard;
        end
    endgenerate

    assign warp_stalled = has_hazard_flat | barrier_waiting;
    assign warp_ready   = warp_active & ~warp_stalled;

    // Scoreboard update - single write port, prioritize WB over ID for correctness
    // Use separate always blocks for clean synthesis
    reg [63:0] scoreboard_next [0:NUM_WARPS-1];
    
    integer i;
    
    // Combinational next ********************
    always @(*) begin
        for (i = 0; i < NUM_WARPS; i = i + 1) begin
            scoreboard_next[i] = scoreboard[i];
        end
        
        // WB clear takes priority (earlier in pipeline = older)
        if (wb_valid) begin
            scoreboard_next[wb_warp_id][wb_reg] = 1'b0;
        end
        
        // ID set
        if (id_valid) begin
            scoreboard_next[id_warp_id][id_dest_reg] = 1'b1;
        end
    end

    // Sequential update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_WARPS; i = i + 1) begin
                scoreboard[i]  <= 64'd0;
            end
        end else begin
            for (i = 0; i < NUM_WARPS; i = i + 1) begin
                scoreboard[i] <= scoreboard_next[i];
            end
        end
    end

    // Divergence Stack Logic
    localparam STACK_DEPTH = 8;
    reg [31:0] div_mask_stack [0:NUM_WARPS-1][0:STACK_DEPTH-1];
    reg [31:0] div_pc_stack   [0:NUM_WARPS-1][0:STACK_DEPTH-1];
    reg [2:0]  div_stack_ptr  [0:NUM_WARPS-1];
    reg [31:0] active_mask    [0:NUM_WARPS-1];
    
    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (k = 0; k < NUM_WARPS; k = k + 1) begin
                div_stack_ptr[k] <= 3'd0;
                active_mask[k]   <= 32'hFFFFFFFF; // All threads active initially
            end
        end else begin
            if (div_push) begin
                div_mask_stack[div_warp_id][div_stack_ptr[div_warp_id]] <= div_push_mask;
                div_pc_stack[div_warp_id][div_stack_ptr[div_warp_id]]   <= div_push_pc;
                div_stack_ptr[div_warp_id]                              <= div_stack_ptr[div_warp_id] + 1'b1;
                active_mask[div_warp_id]                                <= div_new_mask;
            end else if (div_pop) begin
                if (div_stack_ptr[div_pop_warp_id] != 3'd0) begin
                    active_mask[div_pop_warp_id]   <= div_mask_stack[div_pop_warp_id][div_stack_ptr[div_pop_warp_id] - 3'd1];
                    div_stack_ptr[div_pop_warp_id] <= div_stack_ptr[div_pop_warp_id] - 3'd1;
                end else begin
                    active_mask[div_pop_warp_id]   <= 32'hFFFFFFFF;
                end
            end
        end
    end
    
    wire [2:0] tos_idx = div_stack_ptr[div_pop_warp_id] - 3'd1;
    assign div_popped_pc = (div_stack_ptr[div_pop_warp_id] != 3'd0) ? div_pc_stack[div_pop_warp_id][tos_idx] : 32'd0;
    assign div_popped_valid = div_pop && (div_stack_ptr[div_pop_warp_id] != 3'd0);

    // Barrier logic - simple and fast
    wire [NUM_WARPS-1:0] barrier_release = (barrier_waiting & warp_active) == warp_active && warp_active != 0;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            barrier_waiting <= {NUM_WARPS{1'b0}};
        end else begin
            if (barrier_req) begin
                barrier_waiting[barrier_warp_id] <= 1'b1;
            end
            if (barrier_release) begin
                barrier_waiting <= {NUM_WARPS{1'b0}};
            end
        end
    end

    // Age counter update - simple saturated counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_WARPS; i = i + 1) begin
                age_counter[i] <= 8'd0;
            end
        end else begin
            for (i = 0; i < NUM_WARPS; i = i + 1) begin
                if (sched_valid && sched_warp_id == i[2:0]) begin
                    age_counter[i] <= 8'd0;
                end else if (warp_active[i] && warp_stalled[i] && age_counter[i] < 8'hFF) begin
                    age_counter[i] <= age_counter[i] + 1'b1;
                end
            end
        end
    end

    // RR pointer update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= 3'd0;
        end else begin
            rr_ptr <= rr_ptr + 1'b1;
        end
    end

    // GTO Scheduler - fully combinational with priority encoding
    // Two-level priority: starving first, then round-robin
    
    // Starving detection - parallel
    wire [NUM_WARPS-1:0] starving = warp_ready & {
        age_counter[7] >= STARVATION_THRESHOLD,
        age_counter[6] >= STARVATION_THRESHOLD,
        age_counter[5] >= STARVATION_THRESHOLD,
        age_counter[4] >= STARVATION_THRESHOLD,
        age_counter[3] >= STARVATION_THRESHOLD,
        age_counter[2] >= STARVATION_THRESHOLD,
        age_counter[1] >= STARVATION_THRESHOLD,
        age_counter[0] >= STARVATION_THRESHOLD
    };
    
    // Priority encoder for starving warps (highest index wins, or use age comparison)
    // Using tree-based priority for speed
    reg [2:0] starving_warp;
    reg       starving_valid;
    
    // Fast priority encoder - binary tree structure
    always @(*) begin
        // Level 1: pairs
        if (starving[0]) begin starving_warp = 3'd0; starving_valid = 1'b1; end
        else if (starving[1]) begin starving_warp = 3'd1; starving_valid = 1'b1; end
        else if (starving[2]) begin starving_warp = 3'd2; starving_valid = 1'b1; end
        else if (starving[3]) begin starving_warp = 3'd3; starving_valid = 1'b1; end
        else if (starving[4]) begin starving_warp = 3'd4; starving_valid = 1'b1; end
        else if (starving[5]) begin starving_warp = 3'd5; starving_valid = 1'b1; end
        else if (starving[6]) begin starving_warp = 3'd6; starving_valid = 1'b1; end
        else if (starving[7]) begin starving_warp = 3'd7; starving_valid = 1'b1; end
        else begin starving_warp = 3'd0; starving_valid = 1'b0; end
    end
    
    // Round-robin encoder - find first ready at or after rr_ptr
    reg [2:0] rr_warp;
    reg       rr_valid;
    
    // Rotated priority encoder for RR
    wire [15:0] rr_double = {warp_ready, warp_ready};
    wire [15:0] rr_masked = rr_double >> rr_ptr;
    wire [7:0]  rr_select;
    
    // Simple approach: test each position relative to rr_ptr
    always @(*) begin
        // Unrolled for speed - check rr_ptr, rr_ptr+1, ... (mod 8)
        rr_valid = 1'b0;
        rr_warp = 3'd0;
        case (1'b1)
            warp_ready[rr_ptr]: begin rr_warp = rr_ptr; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd1) & 3'd7]: begin rr_warp = (rr_ptr + 3'd1) & 3'd7; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd2) & 3'd7]: begin rr_warp = (rr_ptr + 3'd2) & 3'd7; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd3) & 3'd7]: begin rr_warp = (rr_ptr + 3'd3) & 3'd7; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd4) & 3'd7]: begin rr_warp = (rr_ptr + 3'd4) & 3'd7; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd5) & 3'd7]: begin rr_warp = (rr_ptr + 3'd5) & 3'd7; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd6) & 3'd7]: begin rr_warp = (rr_ptr + 3'd6) & 3'd7; rr_valid = 1'b1; end
            warp_ready[(rr_ptr + 3'd7) & 3'd7]: begin rr_warp = (rr_ptr + 3'd7) & 3'd7; rr_valid = 1'b1; end
        endcase
    end

    // Final selection
    always @(*) begin
        if (starving_valid) begin
            sched_warp_id = starving_warp;
            sched_valid = 1'b1;
        end else if (rr_valid) begin
            sched_warp_id = rr_warp;
            sched_valid = 1'b1;
        end else begin
            sched_warp_id = 3'd0;
            sched_valid = 1'b0;
        end
    end

    // PC output - mux from flattened input
    // Pre-arrange PC for fast mux
    wire [31:0] warp_pc_arr [0:NUM_WARPS-1];
    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : pc_arr
            assign warp_pc_arr[g] = warp_pc[g*32 +: 32];
        end
    endgenerate
    
    // Registered PC output for timing
    always @(posedge clk) begin
        sched_pc <= warp_pc_arr[sched_warp_id];
        sched_active_mask <= active_mask[sched_warp_id];
    end

endmodule