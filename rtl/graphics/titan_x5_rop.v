// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

/*
 * Module: titan_x5_rop
 * Description: Tile-Based Vectorized Render Output Unit.
 * Integrates a 16x16 Localized SRAM Tile Buffer to absorb 4x4 Quad stamps
 * instantly (1 cycle), then asynchronously flushes dirty pixels to global VRAM.
 */
module titan_x5_rop #(
    parameter FB_STRIDE = 1024,
    parameter TILE_SIZE = 16 // 16x16 SRAM Tile
)(
    input  wire clk,
    input  wire rst_n,

    // fragment input (4x4 Stamp Vectorized Datapath)
    input  wire [15:0] i_valid,
    output wire i_ready,
    input wire signed [15:0] i_x, // Base X of the 4x4 stamp
    input wire signed [15:0] i_y, // Base Y of the 4x4 stamp
    input wire [16*32-1:0] i_z,
    input wire [16*32-1:0] i_color, // rgba

    // rop configuration
    input wire [2:0] cfg_depth_func,
    input  wire        cfg_depth_write,
    input wire [2:0] cfg_stencil_func,
    input wire [7:0] cfg_stencil_ref,
    input  wire        cfg_stencil_write,
    input  wire        cfg_blend_en,
    input  wire        cfg_dcc_en,

    // memory interface (scalar 32-bit via Crossbar)
    output reg         mem_req,
    output reg         mem_we,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_wdata,
    input  wire        mem_gnt,
    input  wire        mem_valid,
    input wire [31:0] mem_rdata,

    // dcc metadata interface
    output reg         dcc_req,
    output reg         dcc_we,
    output reg [31:0] dcc_addr,
    output reg [7:0] dcc_wdata,
    input  wire        dcc_gnt,
    input  wire        dcc_valid,

    // config base addresses
    input wire [31:0] base_color,
    input wire [31:0] base_depth,
    
    output wire [2:0] dbg_state
);

    // Tile Buffer SRAM (16x16 = 256 pixels)
    (* ram_style="block" *) reg [31:0] color_tile_sram [0:255];
    (* ram_style="block" *) reg [31:0] depth_tile_sram [0:255];
    reg [255:0] tile_dirty;
    
    reg [15:0] current_tile_x, current_tile_y;
    reg tile_active;

    reg [8:0] flush_idx;
    reg [2:0] flush_state;
    
    localparam FLUSH_IDLE = 0;
    localparam FLUSH_WRITE_C = 1;
    localparam FLUSH_WAIT_C = 2;
    localparam FLUSH_WRITE_Z = 3;
    localparam FLUSH_WAIT_Z = 4;
    
    // We are ready to accept stamps as long as we are not flushing, AND the current stamp doesn't trigger a flush
    assign i_ready = (flush_state == FLUSH_IDLE) && 
                     !(tile_active && ((i_x[15:4] != current_tile_x[15:4]) || (i_y[15:4] != current_tile_y[15:4])) && |tile_dirty);

    reg [3:0] idle_timeout;

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tile_dirty <= 0;
            flush_idx <= 0;
            flush_state <= FLUSH_IDLE;
            mem_req <= 0;
            mem_we <= 0;
            tile_active <= 0;
            current_tile_x <= 0;
            current_tile_y <= 0;
            idle_timeout <= 0;
        end else begin
            case (flush_state)
                FLUSH_IDLE: begin
                    if (i_valid != 16'd0) begin
                        idle_timeout <= 0;
                        // If moving to a new 16x16 tile and current tile is dirty, flush it
                        if (tile_active && ((i_x[15:4] != current_tile_x[15:4]) || (i_y[15:4] != current_tile_y[15:4])) && |tile_dirty) begin
                            flush_state <= FLUSH_WRITE_C;
                            flush_idx <= 0;
                        end else begin
                            // Update active tile coordinates if establishing new tile
                            if (!tile_active || ((i_x[15:4] != current_tile_x[15:4]) || (i_y[15:4] != current_tile_y[15:4]))) begin
                                tile_active <= 1;
                                current_tile_x <= {i_x[15:4], 4'h0};
                                current_tile_y <= {i_y[15:4], 4'h0};
                            end
                            
                            // Vectorized Write: Dump 16 pixels simultaneously into local SRAM
                            for (i = 0; i < 16; i = i + 1) begin
                                if (i_valid[i]) begin
                                    // 16x16 index = (local_y * 16) + local_x
                                    color_tile_sram[ {i_y[3:0] + i[3:2], i_x[3:0] + i[1:0]} ] <= i_color[i*32 +: 32];
                                    depth_tile_sram[ {i_y[3:0] + i[3:2], i_x[3:0] + i[1:0]} ] <= i_z[i*32 +: 32];
                                    tile_dirty[ {i_y[3:0] + i[3:2], i_x[3:0] + i[1:0]} ] <= 1'b1;
                                end
                            end
                        end
                    end else if (tile_active && |tile_dirty) begin
                        idle_timeout <= idle_timeout + 1;
                        if (idle_timeout == 15) begin
                            flush_state <= FLUSH_WRITE_C;
                            flush_idx <= 0;
                        end
                    end
                end
                
                FLUSH_WRITE_C: begin
                    if (flush_idx < 256) begin
                        if (tile_dirty[flush_idx]) begin
                            mem_req <= 1;
                            mem_we <= 1;
                            mem_addr <= base_color + ((current_tile_y + flush_idx/16) * FB_STRIDE + (current_tile_x + flush_idx%16)) * 4;
                            mem_wdata <= color_tile_sram[flush_idx];
                            if (mem_req && mem_gnt) begin
                                mem_req <= 0;
                                flush_state <= FLUSH_WAIT_C;
                            end
                        end else begin
                            flush_idx <= flush_idx + 1; // Skip clean pixels
                        end
                    end else begin
                        tile_dirty <= 0;
                        flush_state <= FLUSH_IDLE;
                        tile_active <= 0; // ready for new tile
                    end
                end
                
                FLUSH_WAIT_C: begin
                    if (mem_valid) begin
                        if (cfg_depth_write) flush_state <= FLUSH_WRITE_Z;
                        else begin
                            tile_dirty[flush_idx] <= 0;
                            flush_idx <= flush_idx + 1;
                            flush_state <= FLUSH_WRITE_C;
                        end
                    end
                end
                
                FLUSH_WRITE_Z: begin
                    mem_req <= 1;
                    mem_we <= 1;
                    mem_addr <= base_depth + ((current_tile_y + flush_idx/16) * FB_STRIDE + (current_tile_x + flush_idx%16)) * 4;
                    mem_wdata <= depth_tile_sram[flush_idx];
                    if (mem_req && mem_gnt) begin
                        mem_req <= 0;
                        flush_state <= FLUSH_WAIT_Z;
                    end
                end
                
                FLUSH_WAIT_Z: begin
                    if (mem_valid) begin
                        tile_dirty[flush_idx] <= 0;
                        flush_idx <= flush_idx + 1;
                        flush_state <= FLUSH_WRITE_C;
                    end
                end
            endcase
        end
    end

    assign dbg_state = flush_state[2:0];

endmodule
