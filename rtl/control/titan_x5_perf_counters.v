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
 * Module: titan_x5_perf_counters
 * Description: 32x 48-bit hardware performance counters for tracking 
 * cycles, instructions, cache hits/misses, etc.
 */
module titan_x5_perf_counters (
    input  wire        clk,
    input  wire        rst_n,
    
    // events mapping
    input wire [31:0] event_pulses, // 32 distinct events
    
    // apb/axi-lite style read interface
    input  wire        read_en,
    input wire [4:0] read_addr, // selects 1 of 32 counters
    output reg [47:0] read_data
);

    // 32 x 48-bit counters
    reg [47:0] counters [0:31];
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 32; i = i + 1) begin
                counters[i] <= 48'd0;
            end
            read_data <= 48'd0;
        end else begin
            // increment counters on event pulses
            for (i = 0; i < 32; i = i + 1) begin
                if (event_pulses[i]) begin
                    counters[i] <= counters[i] + 1;
                end
            end
            
            // read interface
            if (read_en) begin
                read_data <= counters[read_addr];
            end
        end
    end

endmodule
