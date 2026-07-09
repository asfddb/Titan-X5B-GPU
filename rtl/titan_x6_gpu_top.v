// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X6 GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
`timescale 1ns / 1ps

module titan_x6_gpu_top #(
    parameter MESH_X = 2,
    parameter MESH_Y = 2,
    parameter NUM_GPCS = 4,
    parameter NUM_L2_SLICES = 4,
    parameter FLIT_WIDTH = 512
)(
    input  wire        clk,
    input  wire        mem_clk,
    input  wire        pclk,
    input  wire        rst_n,

    // host interface (drives command processor ring buffer)
    input wire [31:0] host_ring_base,
    input wire [31:0] host_ring_wptr,
    output wire [31:0] host_ring_rptr,
    output wire        host_intr,

    // axi4 vram interface (from memory controller)
    output wire [NUM_L2_SLICES*4-1:0] vram_arid,
    output wire [NUM_L2_SLICES*32-1:0] vram_araddr,
    output wire [NUM_L2_SLICES*8-1:0] vram_arlen,
    output wire [NUM_L2_SLICES*3-1:0] vram_arsize,
    output wire [NUM_L2_SLICES*2-1:0] vram_arburst,
    output wire [NUM_L2_SLICES-1:0] vram_arvalid,
    input  wire [NUM_L2_SLICES-1:0] vram_arready,
    input  wire [NUM_L2_SLICES*4-1:0] vram_rid,
    input  wire [NUM_L2_SLICES*512-1:0] vram_rdata,
    input  wire [NUM_L2_SLICES*2-1:0] vram_rresp,
    input  wire [NUM_L2_SLICES-1:0] vram_rlast,
    input  wire [NUM_L2_SLICES-1:0] vram_rvalid,
    output wire [NUM_L2_SLICES-1:0] vram_rready,
    
    output wire [NUM_L2_SLICES*4-1:0] vram_awid,
    output wire [NUM_L2_SLICES*32-1:0] vram_awaddr,
    output wire [NUM_L2_SLICES*8-1:0] vram_awlen,
    output wire [NUM_L2_SLICES*3-1:0] vram_awsize,
    output wire [NUM_L2_SLICES*2-1:0] vram_awburst,
    output wire [NUM_L2_SLICES-1:0] vram_awvalid,
    input  wire [NUM_L2_SLICES-1:0] vram_awready,
    
    output wire [NUM_L2_SLICES*512-1:0] vram_wdata,
    output wire [NUM_L2_SLICES*64-1:0] vram_wstrb,
    output wire [NUM_L2_SLICES-1:0] vram_wlast,
    output wire [NUM_L2_SLICES-1:0] vram_wvalid,
    input  wire [NUM_L2_SLICES-1:0] vram_wready,
    
    input  wire [NUM_L2_SLICES*4-1:0] vram_bid,
    input  wire [NUM_L2_SLICES*2-1:0] vram_bresp,
    input  wire [NUM_L2_SLICES-1:0] vram_bvalid,
    output wire [NUM_L2_SLICES-1:0] vram_bready,

    // video output
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [7:0] vga_r,
    output wire [7:0] vga_g,
    output wire [7:0] vga_b,
    output wire        vga_de
);

    // NoC Interconnect
    wire [MESH_X*MESH_Y*FLIT_WIDTH-1:0] noc_in_flit;
    wire [MESH_X*MESH_Y-1:0]            noc_in_valid;
    wire [MESH_X*MESH_Y*2-1:0]          noc_in_credit;
    
    wire [MESH_X*MESH_Y*FLIT_WIDTH-1:0] noc_out_flit;
    wire [MESH_X*MESH_Y-1:0]            noc_out_valid;
    wire [MESH_X*MESH_Y*2-1:0]          noc_out_credit;
    
    assign noc_out_credit = {MESH_X*MESH_Y*2{1'b1}}; // always ready
    assign noc_in_flit = 0;
    assign noc_in_valid = 0;

    titan_x6_noc_mesh #(
        .MESH_X(MESH_X),
        .MESH_Y(MESH_Y),
        .FLIT_WIDTH(FLIT_WIDTH),
        .NUM_VCS(2),
        .DEPTH(4)
    ) u_sys_noc (
        .clk(clk),
        .rst_n(rst_n),
        .local_in_flit(noc_in_flit),
        .local_in_valid(noc_in_valid),
        .local_in_credit(noc_in_credit),
        .local_out_flit(noc_out_flit),
        .local_out_valid(noc_out_valid),
        .local_out_credit(noc_out_credit)
    );

    // Graphics Processing Clusters
    localparam NUM_TPCS_PER_GPC = 4;
    localparam SMS_PER_TPC = 4;
    localparam LINE_BYTES = 128;
    localparam GPC_SMS = NUM_TPCS_PER_GPC * SMS_PER_TPC;
    
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_icache_req;
    wire [NUM_GPCS*GPC_SMS*32-1:0]       gpc_icache_addr;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_icache_gnt;
    wire [NUM_GPCS*GPC_SMS*32-1:0]       gpc_icache_rdata;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_icache_rvalid;

    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_dbus_req_valid;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_dbus_req_ready;
    wire [NUM_GPCS*GPC_SMS*2-1:0]        gpc_dbus_req_type;
    wire [NUM_GPCS*GPC_SMS*32-1:0]       gpc_dbus_req_addr;
    wire [NUM_GPCS*GPC_SMS*LINE_BYTES*8-1:0] gpc_dbus_req_wdata;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_dbus_resp_valid;
    wire [LINE_BYTES*8-1:0]              gpc_dbus_resp_rdata;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_dbus_resp_shared;
    
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_snp_req_valid;
    wire [1:0]                           gpc_snp_req_type;
    wire [31:0]                          gpc_snp_req_addr;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_snp_resp_valid;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_snp_resp_hit;
    wire [NUM_GPCS*GPC_SMS-1:0]          gpc_snp_resp_dirty;
    wire [NUM_GPCS*GPC_SMS*LINE_BYTES*8-1:0] gpc_snp_resp_data;

    genvar g;
    generate
        for (g = 0; g < NUM_GPCS; g = g + 1) begin : gpc_inst
            titan_x6_gpc #(
                .NUM_TPCS(NUM_TPCS_PER_GPC),
                .SMS_PER_TPC(SMS_PER_TPC),
                .LINE_BYTES(LINE_BYTES)
            ) u_gpc (
                .clk(clk),
                .rst_n(rst_n),
                .icache_req(gpc_icache_req[g*GPC_SMS +: GPC_SMS]),
                .icache_addr(gpc_icache_addr[g*GPC_SMS*32 +: GPC_SMS*32]),
                .icache_gnt(gpc_icache_gnt[g*GPC_SMS +: GPC_SMS]),
                .icache_rdata(gpc_icache_rdata[g*GPC_SMS*32 +: GPC_SMS*32]),
                .icache_rvalid(gpc_icache_rvalid[g*GPC_SMS +: GPC_SMS]),
                
                .dbus_req_valid(gpc_dbus_req_valid[g*GPC_SMS +: GPC_SMS]),
                .dbus_req_ready(gpc_dbus_req_ready[g*GPC_SMS +: GPC_SMS]),
                .dbus_req_type(gpc_dbus_req_type[g*GPC_SMS*2 +: GPC_SMS*2]),
                .dbus_req_addr(gpc_dbus_req_addr[g*GPC_SMS*32 +: GPC_SMS*32]),
                .dbus_req_wdata(gpc_dbus_req_wdata[g*GPC_SMS*LINE_BYTES*8 +: GPC_SMS*LINE_BYTES*8]),
                .dbus_resp_valid(gpc_dbus_resp_valid[g*GPC_SMS +: GPC_SMS]),
                .dbus_resp_rdata(gpc_dbus_resp_rdata),
                .dbus_resp_shared(gpc_dbus_resp_shared[g*GPC_SMS +: GPC_SMS]),
                
                .snp_req_valid(gpc_snp_req_valid[g*GPC_SMS +: GPC_SMS]),
                .snp_req_type(gpc_snp_req_type),
                .snp_req_addr(gpc_snp_req_addr),
                .snp_resp_valid(gpc_snp_resp_valid[g*GPC_SMS +: GPC_SMS]),
                .snp_resp_hit(gpc_snp_resp_hit[g*GPC_SMS +: GPC_SMS]),
                .snp_resp_dirty(gpc_snp_resp_dirty[g*GPC_SMS +: GPC_SMS]),
                .snp_resp_data(gpc_snp_resp_data[g*GPC_SMS*LINE_BYTES*8 +: GPC_SMS*LINE_BYTES*8])
            );
        end
    endgenerate

    // Banked L2 Cache (Massive Scale Up)
    wire [NUM_L2_SLICES-1:0]                   l2_req_valid;
    wire [NUM_L2_SLICES*32-1:0]                l2_req_addr;
    wire [NUM_L2_SLICES*LINE_BYTES*8-1:0]      l2_req_wdata;
    wire [NUM_L2_SLICES-1:0]                   l2_req_write;
    wire [NUM_L2_SLICES-1:0]                   l2_req_ready;

    wire [NUM_L2_SLICES-1:0]                   l2_resp_valid;
    wire [NUM_L2_SLICES*LINE_BYTES*8-1:0]      l2_resp_rdata;

    wire [NUM_L2_SLICES-1:0]                   l2_mem_req_valid;
    wire [NUM_L2_SLICES*32-1:0]                l2_mem_req_addr;
    wire [NUM_L2_SLICES-1:0]                   l2_mem_req_write;
    wire [NUM_L2_SLICES*LINE_BYTES*8-1:0]      l2_mem_req_wdata;
    wire [NUM_L2_SLICES-1:0]                   l2_mem_req_ready;

    wire [NUM_L2_SLICES-1:0]                   l2_mem_resp_valid;
    wire [NUM_L2_SLICES*LINE_BYTES*8-1:0]      l2_mem_resp_rdata;

    // Tie off L1 interface for this structural top-level
    assign l2_req_valid = 0;
    assign l2_req_addr = 0;
    assign l2_req_wdata = 0;
    assign l2_req_write = 0;

    titan_x6_banked_l2 #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(256),
        .LINE_SIZE(LINE_BYTES),
        .WAYS(8),
        .NUM_SLICES(NUM_L2_SLICES),
        .SLICE_SETS(4096)
    ) u_banked_l2 (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(l2_req_valid),
        .req_addr(l2_req_addr),
        .req_wdata(l2_req_wdata),
        .req_write(l2_req_write),
        .req_ready(l2_req_ready),
        .resp_valid(l2_resp_valid),
        .resp_rdata(l2_resp_rdata),
        .mem_req_valid(l2_mem_req_valid),
        .mem_req_addr(l2_mem_req_addr),
        .mem_req_write(l2_mem_req_write),
        .mem_req_wdata(l2_mem_req_wdata),
        .mem_req_ready(l2_mem_req_ready),
        .mem_resp_valid(l2_mem_resp_valid),
        .mem_resp_rdata(l2_mem_resp_rdata)
    );

    // VRAM Controllers
    generate
        for (g = 0; g < NUM_L2_SLICES; g = g + 1) begin : vram_ctrl_inst
            titan_x6_vram_ctrl #(
                .AXI_ADDR_WIDTH(32),
                .AXI_DATA_WIDTH(512),
                .AXI_ID_WIDTH(4),
                .ID_WIDTH(5),
                .LINE_BYTES(LINE_BYTES)
            ) u_vram_ctrl (
                .clk(mem_clk), // Use mem_clk for GDDR7 interface
                .rst_n(rst_n),
                
                // Note: CDC is omitted here for brevity, assuming homogeneous clock 
                // or handled inside a wrapper for Phase 4 scale-up
                .req_valid(l2_mem_req_valid[g]),
                .req_addr(l2_mem_req_addr[g*32 +: 32]),
                .req_write(l2_mem_req_write[g]),
                .req_wdata(l2_mem_req_wdata[g*LINE_BYTES*8 +: LINE_BYTES*8]),
                .req_id(5'd0),
                .req_ready(l2_mem_req_ready[g]),
                
                .resp_valid(l2_mem_resp_valid[g]),
                .resp_id(),
                .resp_rdata(l2_mem_resp_rdata[g*LINE_BYTES*8 +: LINE_BYTES*8]),
                
                .m_axi_arid(vram_arid[g*4 +: 4]),
                .m_axi_araddr(vram_araddr[g*32 +: 32]),
                .m_axi_arlen(vram_arlen[g*8 +: 8]),
                .m_axi_arsize(vram_arsize[g*3 +: 3]),
                .m_axi_arburst(vram_arburst[g*2 +: 2]),
                .m_axi_arvalid(vram_arvalid[g]),
                .m_axi_arready(vram_arready[g]),
                
                .m_axi_rid(vram_rid[g*4 +: 4]),
                .m_axi_rdata(vram_rdata[g*512 +: 512]),
                .m_axi_rresp(vram_rresp[g*2 +: 2]),
                .m_axi_rlast(vram_rlast[g]),
                .m_axi_rvalid(vram_rvalid[g]),
                .m_axi_rready(vram_rready[g]),
                
                .m_axi_awid(vram_awid[g*4 +: 4]),
                .m_axi_awaddr(vram_awaddr[g*32 +: 32]),
                .m_axi_awlen(vram_awlen[g*8 +: 8]),
                .m_axi_awsize(vram_awsize[g*3 +: 3]),
                .m_axi_awburst(vram_awburst[g*2 +: 2]),
                .m_axi_awvalid(vram_awvalid[g]),
                .m_axi_awready(vram_awready[g]),
                
                .m_axi_wdata(vram_wdata[g*512 +: 512]),
                .m_axi_wstrb(vram_wstrb[g*64 +: 64]),
                .m_axi_wlast(vram_wlast[g]),
                .m_axi_wvalid(vram_wvalid[g]),
                .m_axi_wready(vram_wready[g]),
                
                .m_axi_bid(vram_bid[g*4 +: 4]),
                .m_axi_bresp(vram_bresp[g*2 +: 2]),
                .m_axi_bvalid(vram_bvalid[g]),
                .m_axi_bready(vram_bready[g])
            );
        end
    endgenerate

    // Command Processor (Stub for Phase 4 structural integration)
    wire [7:0] cmd_opcode;
    wire [55:0] cmd_payload;
    wire cmd_valid;
    wire cmd_ready = 1'b1;

    titan_x5_command_processor u_cmd_proc (
        .clk(clk),
        .rst_n(rst_n),
        .ring_base_addr(host_ring_base),
        .ring_write_ptr(host_ring_wptr),
        .ring_read_ptr(host_ring_rptr),
        .mem_addr(),
        .mem_req(),
        .mem_ack(1'b1),
        .mem_valid(1'b1),
        .mem_data(64'h0),
        .cmd_valid(cmd_valid),
        .cmd_opcode(cmd_opcode),
        .vt_payload(),
        .cmd_ready(cmd_ready),
        .intr_req(host_intr)
    );

    // Display Engine
    assign vga_hsync = 0;
    assign vga_vsync = 0;
    assign vga_r = 0;
    assign vga_g = 0;
    assign vga_b = 0;
    assign vga_de = 0;

endmodule
