// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

// Verification wrapper: 4 x titan_x5_l1_cache + titan_x5_coherent_xbar.
// Deliberately tiny caches (16-byte lines, 4 sets, 2 ways) so randomized
// stimulus produces heavy eviction/writeback/coherence traffic.
// The L2 port is exposed so the cocotb memory model has full visibility.
module tb_mesi_top #(
    parameter LINE_BYTES = 16,
    parameter SETS       = 4,
    parameter WAYS       = 2
)(
    input  wire clk,
    input  wire rst_n,

    // master 0 core port
    input  wire         m0_req_valid,
    output wire         m0_req_ready,
    input  wire         m0_req_write,
    input  wire [31:0]  m0_req_addr,
    input  wire [LINE_BYTES*8-1:0] m0_req_wdata,
    input  wire [LINE_BYTES-1:0]   m0_req_be,
    output wire         m0_resp_valid,
    output wire [LINE_BYTES*8-1:0] m0_resp_rdata,
    output wire [1:0]   m0_dbg_mesi,

    // master 1 core port
    input  wire         m1_req_valid,
    output wire         m1_req_ready,
    input  wire         m1_req_write,
    input  wire [31:0]  m1_req_addr,
    input  wire [LINE_BYTES*8-1:0] m1_req_wdata,
    input  wire [LINE_BYTES-1:0]   m1_req_be,
    output wire         m1_resp_valid,
    output wire [LINE_BYTES*8-1:0] m1_resp_rdata,
    output wire [1:0]   m1_dbg_mesi,

    // master 2 core port
    input  wire         m2_req_valid,
    output wire         m2_req_ready,
    input  wire         m2_req_write,
    input  wire [31:0]  m2_req_addr,
    input  wire [LINE_BYTES*8-1:0] m2_req_wdata,
    input  wire [LINE_BYTES-1:0]   m2_req_be,
    output wire         m2_resp_valid,
    output wire [LINE_BYTES*8-1:0] m2_resp_rdata,
    output wire [1:0]   m2_dbg_mesi,

    // master 3 core port
    input  wire         m3_req_valid,
    output wire         m3_req_ready,
    input  wire         m3_req_write,
    input  wire [31:0]  m3_req_addr,
    input  wire [LINE_BYTES*8-1:0] m3_req_wdata,
    input  wire [LINE_BYTES-1:0]   m3_req_be,
    output wire         m3_resp_valid,
    output wire [LINE_BYTES*8-1:0] m3_resp_rdata,
    output wire [1:0]   m3_dbg_mesi,

    // shared MESI debug lookup address
    input  wire [31:0]  dbg_addr,

    // L2 port (driven by the cocotb memory model)
    output wire         l2_req_valid,
    input  wire         l2_req_ready,
    output wire         l2_req_write,
    output wire [31:0]  l2_req_addr,
    output wire [LINE_BYTES*8-1:0] l2_req_wdata,
    input  wire         l2_resp_valid,
    input  wire [LINE_BYTES*8-1:0] l2_resp_rdata
);

    wire [3:0]                    bus_req_valid, bus_req_ready, bus_resp_valid;
    wire [4*2-1:0]                bus_req_type;
    wire [4*32-1:0]               bus_req_addr;
    wire [4*LINE_BYTES*8-1:0]     bus_req_wdata;
    wire [LINE_BYTES*8-1:0]       bus_resp_rdata;
    wire                          bus_resp_shared;
    wire [3:0]                    snp_req_valid, snp_resp_valid;
    wire [3:0]                    snp_resp_hit, snp_resp_dirty;
    wire [1:0]                    snp_req_type;
    wire [31:0]                   snp_req_addr;
    wire [4*LINE_BYTES*8-1:0]     snp_resp_data;

    wire [3:0]                 c_req_valid, c_req_ready, c_req_write;
    wire [4*32-1:0]            c_req_addr;
    wire [4*LINE_BYTES*8-1:0]  c_req_wdata;
    wire [4*LINE_BYTES-1:0]    c_req_be;
    wire [3:0]                 c_resp_valid;
    wire [4*LINE_BYTES*8-1:0]  c_resp_rdata;
    wire [4*2-1:0]             c_dbg_mesi;

    assign c_req_valid  = {m3_req_valid, m2_req_valid, m1_req_valid, m0_req_valid};
    assign c_req_write  = {m3_req_write, m2_req_write, m1_req_write, m0_req_write};
    assign c_req_addr   = {m3_req_addr, m2_req_addr, m1_req_addr, m0_req_addr};
    assign c_req_wdata  = {m3_req_wdata, m2_req_wdata, m1_req_wdata, m0_req_wdata};
    assign c_req_be     = {m3_req_be, m2_req_be, m1_req_be, m0_req_be};

    assign {m3_req_ready,  m2_req_ready,  m1_req_ready,  m0_req_ready}  = c_req_ready;
    assign {m3_resp_valid, m2_resp_valid, m1_resp_valid, m0_resp_valid} = c_resp_valid;
    assign m0_resp_rdata = c_resp_rdata[0*LINE_BYTES*8 +: LINE_BYTES*8];
    assign m1_resp_rdata = c_resp_rdata[1*LINE_BYTES*8 +: LINE_BYTES*8];
    assign m2_resp_rdata = c_resp_rdata[2*LINE_BYTES*8 +: LINE_BYTES*8];
    assign m3_resp_rdata = c_resp_rdata[3*LINE_BYTES*8 +: LINE_BYTES*8];
    assign m0_dbg_mesi = c_dbg_mesi[0*2 +: 2];
    assign m1_dbg_mesi = c_dbg_mesi[1*2 +: 2];
    assign m2_dbg_mesi = c_dbg_mesi[2*2 +: 2];
    assign m3_dbg_mesi = c_dbg_mesi[3*2 +: 2];

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : l1_gen
            titan_x5_l1_cache #(
                .ADDR_WIDTH(32),
                .LINE_BYTES(LINE_BYTES),
                .WAYS(WAYS),
                .SETS(SETS)
            ) u_l1 (
                .clk(clk),
                .rst_n(rst_n),

                .core_req_valid(c_req_valid[gi]),
                .core_req_ready(c_req_ready[gi]),
                .core_req_write(c_req_write[gi]),
                .core_req_addr(c_req_addr[gi*32 +: 32]),
                .core_req_wdata(c_req_wdata[gi*LINE_BYTES*8 +: LINE_BYTES*8]),
                .core_req_be(c_req_be[gi*LINE_BYTES +: LINE_BYTES]),
                .core_resp_valid(c_resp_valid[gi]),
                .core_resp_rdata(c_resp_rdata[gi*LINE_BYTES*8 +: LINE_BYTES*8]),

                .bus_req_valid(bus_req_valid[gi]),
                .bus_req_ready(bus_req_ready[gi]),
                .bus_req_type(bus_req_type[gi*2 +: 2]),
                .bus_req_addr(bus_req_addr[gi*32 +: 32]),
                .bus_req_wdata(bus_req_wdata[gi*LINE_BYTES*8 +: LINE_BYTES*8]),
                .bus_resp_valid(bus_resp_valid[gi]),
                .bus_resp_rdata(bus_resp_rdata),
                .bus_resp_shared(bus_resp_shared),

                .snp_req_valid(snp_req_valid[gi]),
                .snp_req_type(snp_req_type),
                .snp_req_addr(snp_req_addr),
                .snp_resp_valid(snp_resp_valid[gi]),
                .snp_resp_hit(snp_resp_hit[gi]),
                .snp_resp_dirty(snp_resp_dirty[gi]),
                .snp_resp_data(snp_resp_data[gi*LINE_BYTES*8 +: LINE_BYTES*8]),

                .dbg_addr(dbg_addr),
                .dbg_mesi(c_dbg_mesi[gi*2 +: 2])
            );
        end
    endgenerate

    titan_x5_coherent_xbar #(
        .NUM_MASTERS(4),
        .ADDR_WIDTH(32),
        .LINE_BYTES(LINE_BYTES)
    ) u_xbar (
        .clk(clk),
        .rst_n(rst_n),
        .m_req_valid(bus_req_valid),
        .m_req_ready(bus_req_ready),
        .m_req_type(bus_req_type),
        .m_req_addr(bus_req_addr),
        .m_req_wdata(bus_req_wdata),
        .m_resp_valid(bus_resp_valid),
        .m_resp_rdata(bus_resp_rdata),
        .m_resp_shared(bus_resp_shared),
        .snp_req_valid(snp_req_valid),
        .snp_req_type(snp_req_type),
        .snp_req_addr(snp_req_addr),
        .snp_resp_valid(snp_resp_valid),
        .snp_resp_hit(snp_resp_hit),
        .snp_resp_dirty(snp_resp_dirty),
        .snp_resp_data(snp_resp_data),
        .l2_req_valid(l2_req_valid),
        .l2_req_ready(l2_req_ready),
        .l2_req_write(l2_req_write),
        .l2_req_addr(l2_req_addr),
        .l2_req_wdata(l2_req_wdata),
        .l2_resp_valid(l2_resp_valid),
        .l2_resp_rdata(l2_resp_rdata)
    );

endmodule
