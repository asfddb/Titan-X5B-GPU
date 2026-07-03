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
 * Module: titan_x5_tmu
 * Description: Texture Mapping Unit. Bilinear filtering, address generation 
 * (clamp/wrap modes), direct-mapped 4KB cache, 8/16/32-bit format support.
 */
module titan_x5_tmu (
    input  wire clk,
    input  wire rst_n,
    
    // request interface
    input  wire i_valid,
    output wire i_ready,
    input wire [31:0] i_u, // 16.16 fixed point
    input wire [31:0] i_v, // 16.16 fixed point
    input wire [15:0] i_tex_width,
    input wire [15:0] i_tex_height,
    input  wire        i_wrap_mode, // 0: wrap, 1: clamp
    input wire [1:0] i_format, // 00: 8-bit, 01: 16-bit, 10: 32-bit
    input wire [31:0] i_tex_base_addr,
    
    // result interface
    output wire        o_valid,
    input  wire        o_ready,
    output wire [31:0] o_color, // output 32-bit rgba
    output wire [15:0] o_x,
    output wire [15:0] o_y,
    
    // memory interface (for cache miss)
    output wire        mem_req,
    input  wire        mem_gnt,
    output wire [31:0] mem_addr,
    input  wire        mem_valid,
    input wire [31:0] mem_rdata,
    
    output wire [2:0] dbg_state
);

    localparam S_IDLE       = 3'd0;
    localparam S_ADDR_CALC  = 3'd1;
    localparam S_CACHE_READ = 3'd2;
    localparam S_MEM_WAIT   = 3'd3;
    localparam S_FILTER_1   = 3'd4;
    localparam S_FILTER_2   = 3'd5;
    localparam S_OUTPUT     = 3'd6;

    reg [31:0] tex_base_reg;
    reg [2:0]  state;
    reg [15:0] x_reg;
    reg [15:0] y_reg;
    reg [1:0]  texel_idx;

    // L1 Cache instantiation replaces internal primitive cache
    wire cache_req_valid;
    wire [31:0] cache_req_addr;
    wire cache_req_ready;
    wire cache_resp_valid;
    wire [31:0] cache_resp_rdata;

    reg [31:0] t_addr [0:3];
    reg [31:0] c_data [0:3];
    
    reg [7:0] uf_reg, vf_reg;
    reg [1:0] fmt_reg;

    // mem_req and mem_addr are now driven by the L1 cache
    assign cache_req_valid = (state == S_CACHE_READ);
    assign cache_req_addr = {t_addr[texel_idx][31:2], 2'b00};

    reg o_valid_reg;
    reg [31:0] o_color_reg;
    assign o_valid = o_valid_reg;
    assign o_color = o_color_reg;
    assign o_x = x_reg;
    assign o_y = y_reg;
    assign dbg_state = state;

    assign i_ready = (state == S_IDLE);

    wire [15:0] ui = i_u[31:16];
    wire [15:0] vi = i_v[31:16];
    wire [7:0]  uf = i_u[15:8];
    wire [7:0]  vf = i_v[15:8];

    // wrap/clamp logic
    reg [15:0] u_0, u_1, v_0, v_1;
    always @(*) begin
        if (i_wrap_mode == 1'b1) begin // clamp
            u_0 = (ui >= i_tex_width) ? i_tex_width - 1 : ui;
            u_1 = (ui + 1 >= i_tex_width) ? i_tex_width - 1 : ui + 1;
            v_0 = (vi >= i_tex_height) ? i_tex_height - 1 : vi;
            v_1 = (vi + 1 >= i_tex_height) ? i_tex_height - 1 : vi + 1;
        end else begin // wrap 
            u_0 = ui;
            u_1 = (ui + 1 == i_tex_width) ? 16'd0 : ui + 1;
            v_0 = vi;
            v_1 = (vi + 1 == i_tex_height) ? 16'd0 : vi + 1;
        end
    end

    wire [2:0] bpp_shift = (i_format == 2'b10) ? 2 : (i_format == 2'b01) ? 1 : 0;

    function [31:0] extract_color;
    input [31:0] word;
    input [1:0] offset;
    input [1:0] fmt;
        begin
            if (fmt == 2'b10) begin
                extract_color = word;
            end else if (fmt == 2'b01) begin
                extract_color = (offset[1]) ? {16'd0, word[31:16]} : {16'd0, word[15:0]};
            end else begin
                case (offset)
                    2'b00: extract_color = {24'd0, word[7:0]};
                    2'b01: extract_color = {24'd0, word[15:8]};
                    2'b10: extract_color = {24'd0, word[23:16]};
                    2'b11: extract_color = {24'd0, word[31:24]};
                endcase
            end
        end
    endfunction

    function [7:0] lerp;
    input [7:0] a;
    input [7:0] b;
    input [7:0] f;
        reg [15:0] diff;
        begin
            if (a > b) begin
                diff = (a - b) * f;
                lerp = a - (diff >> 8);
            end else begin
                diff = (b - a) * f;
                lerp = a + (diff >> 8);
            end
        end
    endfunction

    reg [31:0] top_mix, bot_mix;
    integer i;
    
    titan_x5_l1_cache #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .LINE_SIZE(4),
        .WAYS(4),
        .SETS(128),
        .MSHR_ENTRIES(4)
    ) u_l1_cache (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(cache_req_valid),
        .req_addr(cache_req_addr),
        .req_wdata(32'd0),
        .req_write(1'b0),
        .req_ready(cache_req_ready),
        .resp_valid(cache_resp_valid),
        .resp_rdata(cache_resp_rdata),
        
        .m_axi_awaddr(),
        .m_axi_awvalid(),
        .m_axi_awready(1'b1),
        .m_axi_wdata(),
        .m_axi_wvalid(),
        .m_axi_wready(1'b1),
        .m_axi_bresp(2'b00),
        .m_axi_bvalid(1'b0),
        .m_axi_bready(),
        
        .m_axi_araddr(mem_addr),
        .m_axi_arvalid(mem_req),
        .m_axi_arready(mem_gnt),
        .m_axi_rdata(mem_rdata),
        .m_axi_rvalid(mem_valid),
        .m_axi_rready() // Internal logic relies on ready=1 implicitly
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            texel_idx <= 2'd0;
            o_valid_reg <= 1'b0;
            o_color_reg <= 32'd0;
            x_reg <= 16'd0; y_reg <= 16'd0;
            uf_reg <= 8'd0; vf_reg <= 8'd0;
            fmt_reg <= 2'd0;
            top_mix <= 32'd0; bot_mix <= 32'd0;
            for (i = 0; i < 4; i = i + 1) begin t_addr[i] <= 32'd0; c_data[i] <= 32'd0; end
        end else begin
            case (state)
                S_IDLE: begin
                    if (o_ready) o_valid_reg <= 1'b0;
                    if (i_valid) begin
                        uf_reg <= uf;
                        vf_reg <= vf;
                        fmt_reg <= i_format;
                        x_reg <= i_u[31:16];
                        y_reg <= i_v[31:16];
                        
                        t_addr[0] <= i_tex_base_addr + ((v_0 * i_tex_width + u_0) << bpp_shift);
                        t_addr[1] <= i_tex_base_addr + ((v_0 * i_tex_width + u_1) << bpp_shift);
                        t_addr[2] <= i_tex_base_addr + ((v_1 * i_tex_width + u_0) << bpp_shift);
                        t_addr[3] <= i_tex_base_addr + ((v_1 * i_tex_width + u_1) << bpp_shift);
                        
                        texel_idx <= 2'd0;
                        state <= S_CACHE_READ;
                    end
                end
                
                S_CACHE_READ: begin
                    if (cache_req_ready) begin
                        state <= S_MEM_WAIT; // acts as S_CACHE_WAIT
                    end
                end
                
                S_MEM_WAIT: begin
                    if (cache_resp_valid) begin
                        c_data[texel_idx] <= extract_color(cache_resp_rdata, t_addr[texel_idx][1:0], fmt_reg);
                        if (texel_idx == 3) state <= S_FILTER_1;
                        else begin
                            texel_idx <= texel_idx + 1;
                            state <= S_CACHE_READ;
                        end
                    end
                end
                
                S_FILTER_1: begin
                    top_mix[7:0]   <= lerp(c_data[0][7:0],   c_data[1][7:0],   uf_reg);
                    top_mix[15:8]  <= lerp(c_data[0][15:8],  c_data[1][15:8],  uf_reg);
                    top_mix[23:16] <= lerp(c_data[0][23:16], c_data[1][23:16], uf_reg);
                    top_mix[31:24] <= lerp(c_data[0][31:24], c_data[1][31:24], uf_reg);
                    
                    bot_mix[7:0]   <= lerp(c_data[2][7:0],   c_data[3][7:0],   uf_reg);
                    bot_mix[15:8]  <= lerp(c_data[2][15:8],  c_data[3][15:8],  uf_reg);
                    bot_mix[23:16] <= lerp(c_data[2][23:16], c_data[3][23:16], uf_reg);
                    bot_mix[31:24] <= lerp(c_data[2][31:24], c_data[3][31:24], uf_reg);
                    
                    state <= S_FILTER_2;
                end
                
                S_FILTER_2: begin
                    o_color_reg[7:0]   <= lerp(top_mix[7:0],   bot_mix[7:0],   vf_reg);
                    o_color_reg[15:8]  <= lerp(top_mix[15:8],  bot_mix[15:8],  vf_reg);
                    o_color_reg[23:16] <= lerp(top_mix[23:16], bot_mix[23:16], vf_reg);
                    o_color_reg[31:24] <= lerp(top_mix[31:24], bot_mix[31:24], vf_reg);
                    
                    o_valid_reg <= 1'b1;
                    state <= S_OUTPUT;
                end
                
                S_OUTPUT: begin
                    if (o_ready) begin
                        o_valid_reg <= 1'b0;
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
