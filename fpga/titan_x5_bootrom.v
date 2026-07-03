// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

module titan_x5_bootrom (
    input  wire        clk,
    input  wire        rst_n,

    // AXI4 Slave interface (connects to GPU's vram master)
    input  wire [3:0]  vram_arid,
    input  wire [31:0] vram_araddr,
    input  wire [7:0]  vram_arlen,
    input  wire [2:0]  vram_arsize,
    input  wire [1:0]  vram_arburst,
    input  wire        vram_arvalid,
    output wire        vram_arready,
    
    output wire [3:0]  vram_rid,
    output wire [511:0] vram_rdata,
    output wire [1:0]  vram_rresp,
    output wire        vram_rlast,
    output wire        vram_rvalid,
    input  wire        vram_rready,
    
    input  wire [3:0]  vram_awid,
    input  wire [31:0] vram_awaddr,
    input  wire [7:0]  vram_awlen,
    input  wire [2:0]  vram_awsize,
    input  wire [1:0]  vram_awburst,
    input  wire        vram_awvalid,
    output wire        vram_awready,
    
    input  wire [511:0] vram_wdata,
    input  wire [63:0] vram_wstrb,
    input  wire        vram_wlast,
    input  wire        vram_wvalid,
    output wire        vram_wready,
    
    output wire [3:0]  vram_bid,
    output wire [1:0]  vram_bresp,
    output wire        vram_bvalid,
    input  wire        vram_bready,

    // Host ring control outputs
    output wire [31:0] host_ring_base,
    output reg  [31:0] host_ring_wptr
);

    reg [511:0] mem_0x1000_0000;
    reg [511:0] mem_0x1000_0040;
    
    assign host_ring_base = 32'h1000_0000;
    
    // Boot sequence: initialize command memory, then bump wptr
    reg [3:0] boot_state;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            boot_state <= 0;
            host_ring_wptr <= 0;
            mem_0x1000_0000 <= 0;
            mem_0x1000_0040 <= 0;
        end else begin
            if (boot_state == 0) begin
                // Command OP: DRAW (0x01)
                mem_0x1000_0000[7:0] <= 8'h01;
                
                // Weights: Identity matrix
                mem_0x1000_0000[4*8 + 15 : 4*8] <= 16'd1;
                mem_0x1000_0000[14*8 + 15 : 14*8] <= 16'd1;
                mem_0x1000_0000[24*8 + 15 : 24*8] <= 16'd1;
                mem_0x1000_0000[34*8 + 15 : 34*8] <= 16'd1;
                
                // v0
                mem_0x1000_0000[36*8 + 15 : 36*8] <= 16'd0;
                mem_0x1000_0000[38*8 + 15 : 38*8] <= 16'd0;
                mem_0x1000_0000[42*8 + 15 : 42*8] <= 16'd1;
                
                // v1
                mem_0x1000_0000[44*8 + 15 : 44*8] <= 16'd20;
                mem_0x1000_0000[46*8 + 15 : 46*8] <= 16'd0;
                mem_0x1000_0000[50*8 + 15 : 50*8] <= 16'd1;
                
                // v2
                mem_0x1000_0000[52*8 + 15 : 52*8] <= 16'd5;
                mem_0x1000_0000[54*8 + 15 : 54*8] <= 16'd5;
                mem_0x1000_0000[58*8 + 15 : 58*8] <= 16'd1;
                
                // v3 x and y are 0, just need w
                boot_state <= 1;
            end else if (boot_state == 1) begin
                mem_0x1000_0040[2*8 + 15 : 2*8] <= 16'd1; // v3_w
                boot_state <= 2;
            end else if (boot_state == 2) begin
                host_ring_wptr <= 17; // Notify GPU of 17 words
                boot_state <= 3;
            end
        end
    end

    // AXI Read State Machine
    reg vram_arready_reg;
    reg vram_rvalid_reg;
    reg [511:0] vram_rdata_reg;
    reg [3:0] vram_rid_reg;
    reg vram_rlast_reg;
    
    assign vram_arready = vram_arready_reg;
    assign vram_rvalid = vram_rvalid_reg;
    assign vram_rdata = vram_rdata_reg;
    assign vram_rid = vram_rid_reg;
    assign vram_rresp = 2'b00;
    assign vram_rlast = vram_rlast_reg;
    
    reg [31:0] read_addr;
    reg [7:0]  read_len;
    reg        reading;
    wire [31:0] next_read_addr = read_addr + 64;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_arready_reg <= 1'b1;
            vram_rvalid_reg <= 1'b0;
            reading <= 1'b0;
        end else begin
            if (vram_arready_reg && vram_arvalid) begin
                vram_arready_reg <= 1'b0;
                read_addr <= vram_araddr;
                read_len <= vram_arlen;
                vram_rid_reg <= vram_arid;
                reading <= 1'b1;
                vram_rvalid_reg <= 1'b1;
                
                if (vram_araddr[31:12] == 20'h10000) begin
                    if (vram_araddr[11:6] == 6'd0) vram_rdata_reg <= mem_0x1000_0000;
                    else if (vram_araddr[11:6] == 6'd1) vram_rdata_reg <= mem_0x1000_0040;
                    else vram_rdata_reg <= 512'h0;
                end else begin
                    vram_rdata_reg <= {512{1'b1}}; // Return all 1s (white) for textures/fb
                end
                
                vram_rlast_reg <= (vram_arlen == 0);
            end else if (vram_rvalid_reg && vram_rready) begin
                if (read_len == 0) begin
                    vram_rvalid_reg <= 1'b0;
                    vram_arready_reg <= 1'b1;
                    reading <= 1'b0;
                end else begin
                    read_len <= read_len - 1;
                    read_addr <= next_read_addr;
                    vram_rlast_reg <= (read_len == 1);
                    
                    if (next_read_addr[31:12] == 20'h10000) begin
                        if (next_read_addr[11:6] == 6'd0) vram_rdata_reg <= mem_0x1000_0000;
                        else if (next_read_addr[11:6] == 6'd1) vram_rdata_reg <= mem_0x1000_0040;
                        else vram_rdata_reg <= 512'h0;
                    end else begin
                        vram_rdata_reg <= {512{1'b1}};
                    end
                end
            end
        end
    end
    
    // AXI Write State Machine (Blackhole/Ignore writes)
    reg vram_awready_reg;
    reg vram_wready_reg;
    reg vram_bvalid_reg;
    reg [3:0] vram_bid_reg;
    
    assign vram_awready = vram_awready_reg;
    assign vram_wready = vram_wready_reg;
    assign vram_bvalid = vram_bvalid_reg;
    assign vram_bid = vram_bid_reg;
    assign vram_bresp = 2'b00;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_awready_reg <= 1'b1;
            vram_wready_reg <= 1'b0;
            vram_bvalid_reg <= 1'b0;
        end else begin
            if (vram_awready_reg && vram_awvalid) begin
                vram_awready_reg <= 1'b0;
                vram_wready_reg <= 1'b1;
                vram_bid_reg <= vram_awid;
            end
            
            if (vram_wready_reg && vram_wvalid) begin
                if (vram_wlast) begin
                    vram_wready_reg <= 1'b0;
                    vram_bvalid_reg <= 1'b1;
                end
            end
            
            if (vram_bvalid_reg && vram_bready) begin
                vram_bvalid_reg <= 1'b0;
                vram_awready_reg <= 1'b1;
            end
        end
    end

endmodule
