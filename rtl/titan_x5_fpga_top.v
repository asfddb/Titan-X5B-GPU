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
 * Module: titan_x5_fpga_top
 * Description: FPGA wrapper for the Titan X5 GPU, specifically optimized for
 *              the Digilent Basys 3 board (Artix-7 FPGA).
 *              Hooks up the core GPU to onboard clock, switches, LEDs, and VGA out.
 */
module titan_x5_fpga_top (
    input  wire        clk_100mhz, // 100MHz onboard clock (W5)
    input wire [15:0] sw, // 16 onboard switches (V17..R2)
    input  wire        btnC,       // center button (u18) for reset
    input  wire        btnU,       // up button (t18) for manual trigger
    
    output wire [15:0] led, // 16 onboard LEDs (U16..L1)
    
    // vga interface
    output wire [3:0] vga_r, // vga red 4-bit dac
    output wire [3:0] vga_g, // vga green 4-bit dac
    output wire [3:0] vga_b, // vga blue 4-bit dac
    output wire        vga_hsync,  // vga hsync
    output wire        vga_vsync   // vga vsync
);

    // clock generation (mmcm / pll)
    // generate 50mhz core clock and 148.5mhz (or closest) pixel clock for 1080p
    // for basys 3 (100mhz in), we will generate a simplified 25mhz pixel clock 
    // for standard 640x480@60Hz VGA output to guarantee timing closure.
    wire clk_core;
    wire clk_pixel;
    wire locked;
    
    // in a real vivado project, this would be an ip catalog clocking wizard.
    // here we simulate it with simple dividers/buffers for the synthesis tool.
    BUFG bufg_core (.I(clk_100mhz), .O(clk_core)); // core runs at 100mhz
    
    // simple clock divider for 25mhz pixel clock (100mhz / 4)
    reg [1:0] pclk_div;
    always @(posedge clk_100mhz) begin
        if (btnC) pclk_div <= 0;
        else pclk_div <= pclk_div + 1'b1;
    end
    BUFG bufg_pixel (.I(pclk_div[1]), .O(clk_pixel));

    wire sys_rst_n = ~btnC; // active low reset

    // host ring buffer emulation
    // since we don't have a pcie host, we emulate host commands via bram.
    wire [31:0] host_ring_base = 32'h1000_0000;
    reg  [31:0] host_ring_wptr;
    wire [31:0] host_ring_rptr;
    wire        host_intr;
    
    // manual trigger via button to write a draw command
    reg btnU_prev;
    always @(posedge clk_core or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            host_ring_wptr <= 32'd0;
            btnU_prev <= 1'b0;
        end else begin
            btnU_prev <= btnU;
            if (btnU && !btnU_prev) begin // rising edge
                host_ring_wptr <= host_ring_wptr + 1'b1; // enqueue a command
            end
        end
    end
    
    // status leds
    assign led[3:0]   = host_ring_wptr[3:0];
    assign led[7:4]   = host_ring_rptr[3:0];
    assign led[14:8]  = 7'd0;
    assign led[15]    = host_intr;

    // titan x5 gpu core instantiation
    // internal vga 8-bit color signals
    wire [7:0] core_vga_r;
    wire [7:0] core_vga_g;
    wire [7:0] core_vga_b;
    wire       core_vga_de;
    
    // truncate 8-bit color down to basys 3's 4-bit resistor ladder dac
    assign vga_r = core_vga_r[7:4];
    assign vga_g = core_vga_g[7:4];
    assign vga_b = core_vga_b[7:4];

    // dummy vram axi wires (vram memory controller handles internal bram/ddr)
    wire [3:0]   vram_arid; wire [31:0]  vram_araddr; wire [7:0]   vram_arlen;
    wire [2:0]   vram_arsize; wire [1:0]   vram_arburst; wire         vram_arvalid;
    wire         vram_arready;
    wire [3:0]   vram_rid; wire [511:0] vram_rdata;
    wire [1:0]   vram_rresp; wire         vram_rlast;
    wire         vram_rvalid; wire         vram_rready;
    
    wire [3:0]   vram_awid; wire [31:0]  vram_awaddr; wire [7:0]   vram_awlen;
    wire [2:0]   vram_awsize; wire [1:0]   vram_awburst; wire         vram_awvalid;
    wire         vram_awready;
    wire [511:0] vram_wdata; wire [63:0]  vram_wstrb; wire         vram_wlast;
    wire         vram_wvalid; wire         vram_wready;
    wire [3:0]   vram_bid; wire [1:0]   vram_bresp;
    wire         vram_bvalid; wire         vram_bready;
    
    titan_x5_vram_ctrl u_vram_ctrl (
        .clk(clk_core),
        .rst_n(sys_rst_n),
        .s_axi_awid(vram_awid), .s_axi_awaddr(vram_awaddr), .s_axi_awlen(vram_awlen),
        .s_axi_awsize(vram_awsize), .s_axi_awburst(vram_awburst), .s_axi_awvalid(vram_awvalid), .s_axi_awready(vram_awready),
        .s_axi_wdata(vram_wdata), .s_axi_wstrb(vram_wstrb), .s_axi_wlast(vram_wlast),
        .s_axi_wvalid(vram_wvalid), .s_axi_wready(vram_wready),
        .s_axi_bid(vram_bid), .s_axi_bresp(vram_bresp), .s_axi_bvalid(vram_bvalid), .s_axi_bready(vram_bready),
        .s_axi_arid(vram_arid), .s_axi_araddr(vram_araddr), .s_axi_arlen(vram_arlen),
        .s_axi_arsize(vram_arsize), .s_axi_arburst(vram_arburst), .s_axi_arvalid(vram_arvalid), .s_axi_arready(vram_arready),
        .s_axi_rid(vram_rid), .s_axi_rdata(vram_rdata), .s_axi_rresp(vram_rresp),
        .s_axi_rlast(vram_rlast), .s_axi_rvalid(vram_rvalid), .s_axi_rready(vram_rready)
    );

    titan_x5_gpu_top #(
        // Basys 3 drives a 640x480@60Hz panel from the 25MHz pixel clock;
        // the 1920x1080 default would generate out-of-spec sync timing.
        .VGA_H_VISIBLE   (12'd640),
        .VGA_V_VISIBLE   (12'd480),
        // 128 per-lane WMMA arrays exceed any Artix-7 several times over;
        // WMMA ops return zero in the FPGA build.
        .ENABLE_TENSOR   (0)
    ) u_gpu_core (
        .clk             (clk_core),
        // VRAM is on-chip BRAM, so the memory side shares the core clock
        // (the internal CDC FIFOs tolerate a 1:1 clock ratio).
        .mem_clk         (clk_core),
        .pclk            (clk_pixel),
        .rst_n           (sys_rst_n),
        .host_ring_base  (host_ring_base),
        .host_ring_wptr  (host_ring_wptr),
        .host_ring_rptr  (host_ring_rptr),
        .host_intr       (host_intr),
        
        .vram_arid       (vram_arid), .vram_araddr(vram_araddr), .vram_arlen(vram_arlen),
        .vram_arsize     (vram_arsize), .vram_arburst(vram_arburst), .vram_arvalid(vram_arvalid),
        .vram_arready    (vram_arready), .vram_rid(vram_rid), .vram_rdata(vram_rdata),
        .vram_rresp      (vram_rresp), .vram_rlast(vram_rlast), .vram_rvalid(vram_rvalid),
        .vram_rready     (vram_rready), .vram_awid(vram_awid), .vram_awaddr(vram_awaddr),
        .vram_awlen      (vram_awlen), .vram_awsize(vram_awsize), .vram_awburst(vram_awburst),
        .vram_awvalid    (vram_awvalid), .vram_awready(vram_awready), .vram_wdata(vram_wdata),
        .vram_wstrb      (vram_wstrb), .vram_wlast(vram_wlast), .vram_wvalid(vram_wvalid),
        .vram_wready     (vram_wready), .vram_bid(vram_bid), .vram_bresp(vram_bresp),
        .vram_bvalid     (vram_bvalid), .vram_bready(vram_bready),
        
        .vga_hsync       (vga_hsync),
        .vga_vsync       (vga_vsync),
        .vga_r           (core_vga_r),
        .vga_g           (core_vga_g),
        .vga_b           (core_vga_b),
        .vga_de          (core_vga_de)
    );

endmodule
