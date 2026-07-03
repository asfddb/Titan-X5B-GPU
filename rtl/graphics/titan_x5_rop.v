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
    
    // shader interface
    input wire        shader_wb_valid,
    input wire [5:0]  shader_wb_reg,
    input wire [1023:0] shader_wb_data,

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

    reg [511:0] latched_shader_color;

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
            latched_shader_color <= 0;
            flush_idx <= 0;
            flush_state <= FLUSH_IDLE;
            mem_req <= 0;
            mem_we <= 0;
            tile_active <= 0;
            current_tile_x <= 0;
            current_tile_y <= 0;
            idle_timeout <= 0;
        end else begin
            if (shader_wb_valid && shader_wb_reg == 6'd63) begin
                latched_shader_color <= {
                    shader_wb_data[15*32 +: 32], shader_wb_data[14*32 +: 32], shader_wb_data[13*32 +: 32], shader_wb_data[12*32 +: 32],
                    shader_wb_data[11*32 +: 32], shader_wb_data[10*32 +: 32], shader_wb_data[9*32 +: 32],  shader_wb_data[8*32 +: 32],
                    shader_wb_data[7*32 +: 32],  shader_wb_data[6*32 +: 32],  shader_wb_data[5*32 +: 32],  shader_wb_data[4*32 +: 32],
                    shader_wb_data[3*32 +: 32],  shader_wb_data[2*32 +: 32],  shader_wb_data[1*32 +: 32],  shader_wb_data[0*32 +: 32]
                };
            end
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
                            for (i = 0; i < 16; i = i + 1) begin : pixel_loop
                                if (i_valid[i]) begin : valid_pixel_block
                                    // 16x16 index = (local_y * 16) + local_x
                                    // Use | instead of + to avoid overflow, since inputs are 4-aligned
                                    reg [7:0] tile_idx;
                                    reg [31:0] cur_z;
                                    reg [31:0] new_z;
                                    reg [31:0] cur_c;
                                    reg [31:0] new_c;
                                    reg [7:0] alpha, inv_alpha;
                                    reg [31:0] final_c;
                                    
                                    tile_idx = {i_y[3:2], i[3:2], i_x[3:2], i[1:0]};
                                    cur_z = depth_tile_sram[tile_idx];
                                    new_z = i_z[i*32 +: 32];
                                    
                                    if (new_z <= cur_z || !tile_dirty[tile_idx]) begin
                                        cur_c = color_tile_sram[tile_idx];
                                        // use the latched color from the shader instead of i_color if shader computed it (non-zero)
                                        // or just default to latched_shader_color since the prompt requires fragment shader output
                                        new_c = latched_shader_color[i*32 +: 32];
                                        alpha = new_c[31:24];
                                        inv_alpha = 255 - alpha;
                                        
                                        if (cfg_blend_en) begin
                                            final_c = {8'hFF, 
                                                (new_c[23:16]*alpha + cur_c[23:16]*inv_alpha) >> 8,
                                                (new_c[15:8]*alpha  + cur_c[15:8]*inv_alpha)  >> 8,
                                                (new_c[7:0]*alpha   + cur_c[7:0]*inv_alpha)   >> 8};
                                        end else begin
                                            final_c = new_c;
                                        end
                                        
                                        color_tile_sram[tile_idx] <= final_c;
                                        depth_tile_sram[tile_idx] <= new_z;
                                        tile_dirty[tile_idx] <= 1'b1;
                                    end
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
