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
 * Module: titan_x5_command_processor
 * Description: Fetches commands (dispatch, draw, dma, fence) from memory 
 * and generates interrupts. Exposes vertex coordinates for Rasterizer.
 */
module titan_x5_command_processor (
    input  wire        clk,
    input  wire        rst_n,
    
    // ring buffer interface
    input wire [31:0] ring_base_addr,
    input wire [31:0] ring_write_ptr,
    output reg [31:0] ring_read_ptr,
    
    // memory interface
    output reg [31:0] mem_addr,
    output reg         mem_req,
    input  wire        mem_ack,
    input  wire        mem_valid,
    input wire [63:0] mem_data, // 64-bit command packets
    
    // dispatch/execution interface
    output reg         cmd_valid,
    output reg [7:0] cmd_opcode,
    output reg [55:0] cmd_payload,
    input  wire        cmd_ready,
    
    // unified shader architecture: output full payload to vertex transformer
    output reg [511:0] vt_payload,
    
    // interrupt
    output reg         intr_req
);

    localparam CMD_DRAW     = 8'h01;
    localparam CMD_DISPATCH = 8'h02;
    localparam CMD_DMA      = 8'h03;
    localparam CMD_FENCE    = 8'h04;

    reg [2:0] state;
    localparam S_IDLE       = 3'd0;
    localparam S_FETCH_CMD  = 3'd1;
    localparam S_FETCH_PAY  = 3'd2;
    localparam S_EXEC       = 3'd3;
    
    reg [4:0] payload_word_cnt;
    reg [511:0] full_payload;
    reg         waiting_for_data;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ring_read_ptr <= 32'd0;
            mem_req <= 1'b0;
            cmd_valid <= 1'b0;
            intr_req <= 1'b0;
            vt_payload <= 512'd0;
            waiting_for_data <= 1'b0;
            state <= S_IDLE;
        end else begin
            intr_req <= 1'b0; // pulse interrupt
            
            case (state)
                S_IDLE: begin
                    if (ring_read_ptr != ring_write_ptr) begin
                        mem_addr <= ring_base_addr + (ring_read_ptr * 4); // 4 bytes per command word
                        mem_req <= 1'b1;
                        state <= S_FETCH_CMD;
                    end
                end
                S_FETCH_CMD: begin
                    if (mem_ack) begin
                        mem_req <= 1'b0;
                    end
                    if (mem_valid) begin
                        cmd_opcode <= mem_data[7:0]; // Lower 8 bits of first word is opcode
                        cmd_payload <= mem_data[63:8]; // Upper 56 bits for payload
                        payload_word_cnt <= 0;
                        ring_read_ptr <= (ring_read_ptr + 1) & 32'h000000FF; // Wrap at 256
                        state <= S_FETCH_PAY;
                    end
                end
                S_FETCH_PAY: begin
                    if (payload_word_cnt < 16) begin
                        if (!mem_req && !waiting_for_data) begin
                            mem_addr <= ring_base_addr + (ring_read_ptr * 4);
                            mem_req <= 1'b1;
                            waiting_for_data <= 1'b1;
                        end
                        if (mem_ack) begin
                            mem_req <= 1'b0;
                        end
                        if (mem_valid && waiting_for_data) begin
                            full_payload[payload_word_cnt * 32 +: 32] <= mem_data[31:0];
                            ring_read_ptr <= (ring_read_ptr + 1) & 32'h000000FF;
                            payload_word_cnt <= payload_word_cnt + 1;
                            waiting_for_data <= 1'b0;
                        end
                    end else begin
                        vt_payload <= full_payload;
                        cmd_valid <= 1'b1;
                        state <= S_EXEC;
                    end
                end
                S_EXEC: begin
                    if (cmd_ready) begin
                        cmd_valid <= 1'b0;
                        if (cmd_opcode == CMD_FENCE) begin
                            intr_req <= 1'b1; // generate interrupt on fence completion
                        end
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
