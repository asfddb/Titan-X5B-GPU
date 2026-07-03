// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

module fpga_top (
    input  wire        clk_100mhz,
    input  wire [15:0] sw,
    output wire [15:0] led,
    input  wire        btnC,
    input  wire        btnU,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire        vga_hsync,
    output wire        vga_vsync
);

    wire clk = clk_100mhz;
    wire rst_n = ~btnC; // active high button maps to active low reset
    
    // AXI wires from GPU to Bootrom (VRAM placeholder)
    wire [3:0]   vram_arid;
    wire [31:0]  vram_araddr;
    wire [7:0]   vram_arlen;
    wire [2:0]   vram_arsize;
    wire [1:0]   vram_arburst;
    wire         vram_arvalid;
    wire         vram_arready;
    wire [3:0]   vram_rid;
    wire [511:0] vram_rdata;
    wire [1:0]   vram_rresp;
    wire         vram_rlast;
    wire         vram_rvalid;
    wire         vram_rready;
    wire [3:0]   vram_awid;
    wire [31:0]  vram_awaddr;
    wire [7:0]   vram_awlen;
    wire [2:0]   vram_awsize;
    wire [1:0]   vram_awburst;
    wire         vram_awvalid;
    wire         vram_awready;
    wire [511:0] vram_wdata;
    wire [63:0]  vram_wstrb;
    wire         vram_wlast;
    wire         vram_wvalid;
    wire         vram_wready;
    wire [3:0]   vram_bid;
    wire [1:0]   vram_bresp;
    wire         vram_bvalid;
    wire         vram_bready;

    // Host ring buffer pointers driven by BootROM
    wire [31:0] host_ring_base;
    wire [31:0] host_ring_wptr;
    wire [31:0] host_ring_rptr;
    wire        host_intr;

    // Internal 8-bit VGA signals from GPU
    wire [7:0] vga_r_int;
    wire [7:0] vga_g_int;
    wire [7:0] vga_b_int;
    wire       vga_de_int;

    // Output assignment (truncating to 4 bits for Basys3)
    assign vga_r = vga_r_int[7:4];
    assign vga_g = vga_g_int[7:4];
    assign vga_b = vga_b_int[7:4];
    
    // Status LEDs
    assign led = {15'd0, host_intr};

    // Instantiate GPU Top
    titan_x5_gpu_top #(
        .VGA_H_VISIBLE(12'd640),
        .VGA_V_VISIBLE(12'd480)
    ) u_gpu (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .host_ring_base (host_ring_base),
        .host_ring_wptr (host_ring_wptr),
        .host_ring_rptr (host_ring_rptr),
        .host_intr      (host_intr),
        
        .vram_arid      (vram_arid),
        .vram_araddr    (vram_araddr),
        .vram_arlen     (vram_arlen),
        .vram_arsize    (vram_arsize),
        .vram_arburst   (vram_arburst),
        .vram_arvalid   (vram_arvalid),
        .vram_arready   (vram_arready),
        .vram_rid       (vram_rid),
        .vram_rdata     (vram_rdata),
        .vram_rresp     (vram_rresp),
        .vram_rlast     (vram_rlast),
        .vram_rvalid    (vram_rvalid),
        .vram_rready    (vram_rready),
        .vram_awid      (vram_awid),
        .vram_awaddr    (vram_awaddr),
        .vram_awlen     (vram_awlen),
        .vram_awsize    (vram_awsize),
        .vram_awburst   (vram_awburst),
        .vram_awvalid   (vram_awvalid),
        .vram_awready   (vram_awready),
        .vram_wdata     (vram_wdata),
        .vram_wstrb     (vram_wstrb),
        .vram_wlast     (vram_wlast),
        .vram_wvalid    (vram_wvalid),
        .vram_wready    (vram_wready),
        .vram_bid       (vram_bid),
        .vram_bresp     (vram_bresp),
        .vram_bvalid    (vram_bvalid),
        .vram_bready    (vram_bready),
        
        .vga_hsync      (vga_hsync),
        .vga_vsync      (vga_vsync),
        .vga_r          (vga_r_int),
        .vga_g          (vga_g_int),
        .vga_b          (vga_b_int),
        .vga_de         (vga_de_int)
    );

    // Instantiate Boot ROM
    titan_x5_bootrom u_bootrom (
        .clk            (clk),
        .rst_n          (rst_n),
        
        .vram_arid      (vram_arid),
        .vram_araddr    (vram_araddr),
        .vram_arlen     (vram_arlen),
        .vram_arsize    (vram_arsize),
        .vram_arburst   (vram_arburst),
        .vram_arvalid   (vram_arvalid),
        .vram_arready   (vram_arready),
        .vram_rid       (vram_rid),
        .vram_rdata     (vram_rdata),
        .vram_rresp     (vram_rresp),
        .vram_rlast     (vram_rlast),
        .vram_rvalid    (vram_rvalid),
        .vram_rready    (vram_rready),
        .vram_awid      (vram_awid),
        .vram_awaddr    (vram_awaddr),
        .vram_awlen     (vram_awlen),
        .vram_awsize    (vram_awsize),
        .vram_awburst   (vram_awburst),
        .vram_awvalid   (vram_awvalid),
        .vram_awready   (vram_awready),
        .vram_wdata     (vram_wdata),
        .vram_wstrb     (vram_wstrb),
        .vram_wlast     (vram_wlast),
        .vram_wvalid    (vram_wvalid),
        .vram_wready    (vram_wready),
        .vram_bid       (vram_bid),
        .vram_bresp     (vram_bresp),
        .vram_bvalid    (vram_bvalid),
        .vram_bready    (vram_bready),
        
        .host_ring_base (host_ring_base),
        .host_ring_wptr (host_ring_wptr)
    );

endmodule
