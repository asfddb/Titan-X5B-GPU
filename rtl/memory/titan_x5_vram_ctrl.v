// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

module titan_x5_vram_ctrl (
    input  wire         clk,
    input  wire         rst_n,
    // AW
    input  wire [3:0]   s_axi_awid,
    input  wire [31:0]  s_axi_awaddr,
    input  wire [7:0]   s_axi_awlen,
    input  wire [2:0]   s_axi_awsize,
    input  wire [1:0]   s_axi_awburst,
    input  wire         s_axi_awvalid,
    output reg          s_axi_awready,
    // W
    input  wire [511:0] s_axi_wdata,
    input  wire [63:0]  s_axi_wstrb,
    input  wire         s_axi_wlast,
    input  wire         s_axi_wvalid,
    output reg          s_axi_wready,
    // B
    output reg  [3:0]   s_axi_bid,
    output reg  [1:0]   s_axi_bresp,
    output reg          s_axi_bvalid,
    input  wire         s_axi_bready,
    // AR
    input  wire [3:0]   s_axi_arid,
    input  wire [31:0]  s_axi_araddr,
    input  wire [7:0]   s_axi_arlen,
    input  wire [2:0]   s_axi_arsize,
    input  wire [1:0]   s_axi_arburst,
    input  wire         s_axi_arvalid,
    output reg          s_axi_arready,
    // R
    output reg  [3:0]   s_axi_rid,
    output reg  [511:0] s_axi_rdata,
    output reg  [1:0]   s_axi_rresp,
    output reg          s_axi_rlast,
    output reg          s_axi_rvalid,
    input  wire         s_axi_rready
);

    // 2048 entries x 512 bits = 128KB (fits in Basys 3's 225KB BRAM)
    reg [511:0] bram [0:2047];
    
    // Address extraction: VRAM is nominally mapped to 0x00000000 to 0x007FFFFF.
    // Since our BRAM is small, we just take bits [16:6] (11 bits) of the address.
    // 512 bits = 64 bytes = 2^6 bytes, so address [5:0] is the byte offset.
    wire [10:0] aw_idx = s_axi_awaddr[16:6];
    wire [10:0] ar_idx = s_axi_araddr[16:6];

    // Read FSM
    reg [7:0] r_len_cnt;
    reg [3:0] r_id;
    reg [10:0] r_addr;
    reg reading;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            s_axi_rid     <= 4'd0;
            reading       <= 1'b0;
            r_addr        <= 11'd0;
            r_len_cnt     <= 8'd0;
            s_axi_rdata   <= 512'd0;
        end else begin
            // Accept new read address
            if (!reading && !s_axi_arready) begin
                s_axi_arready <= 1'b1;
            end else if (s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b0;
                reading       <= 1'b1;
                r_addr        <= ar_idx;
                r_len_cnt     <= s_axi_arlen;
                r_id          <= s_axi_arid;
            end
            
            // Output data
            if (reading && (!s_axi_rvalid || s_axi_rready)) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rdata  <= bram[r_addr];
                s_axi_rid    <= r_id;
                s_axi_rresp  <= 2'b00;
                s_axi_rlast  <= (r_len_cnt == 0);
                
                if (r_len_cnt == 0) begin
                    reading <= 1'b0;
                end else begin
                    r_len_cnt <= r_len_cnt - 1;
                    r_addr    <= r_addr + 1; // Basic INCR burst assumption
                end
            end else if (s_axi_rvalid && s_axi_rready && s_axi_rlast) begin
                s_axi_rvalid <= 1'b0;
                s_axi_rlast  <= 1'b0;
            end
        end
    end

    // Write FSM
    reg [7:0] w_len_cnt;
    reg [3:0] w_id;
    reg [10:0] w_addr;
    reg writing;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bid     <= 4'd0;
            writing       <= 1'b0;
            w_addr        <= 11'd0;
            w_len_cnt     <= 8'd0;
            w_id          <= 4'd0;
        end else begin
            // Accept new write address
            if (!writing && !s_axi_awready && !s_axi_bvalid) begin
                s_axi_awready <= 1'b1;
            end else if (s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b0;
                writing       <= 1'b1;
                w_addr        <= aw_idx;
                w_len_cnt     <= s_axi_awlen;
                w_id          <= s_axi_awid;
                s_axi_wready  <= 1'b1;
            end
            
            // Accept write data
            if (writing && s_axi_wready && s_axi_wvalid) begin
                for (i = 0; i < 64; i = i + 1) begin
                    if (s_axi_wstrb[i]) begin
                        bram[w_addr][i*8 +: 8] <= s_axi_wdata[i*8 +: 8];
                    end
                end
                
                if (w_len_cnt == 0 || s_axi_wlast) begin
                    writing       <= 1'b0;
                    s_axi_wready  <= 1'b0;
                    s_axi_bvalid  <= 1'b1;
                    s_axi_bid     <= w_id;
                    s_axi_bresp   <= 2'b00;
                end else begin
                    w_len_cnt <= w_len_cnt - 1;
                    w_addr    <= w_addr + 1; // INCR burst
                end
            end
            
            // Clear bvalid when accepted
            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

endmodule
