// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// cocotb wrapper for titan_x5_l2_mem_adapter (suite: tb/uvm/test_l2_adapter.py).
//
// DW is overridden by the regression runner so the same test can exercise the
// narrow (32-bit) and wide (512-bit) memory paths. cfg_* expose the build
// configuration to the test so it never has to assume a width.
// ============================================================================
`timescale 1ns/1ps

module tb_l2_adapter_top #(
    parameter ADDR_WIDTH = 37,     // 128 GiB physical address space
    parameter LINE_BYTES = 128,    // 1024-bit L2 line
    parameter DW         = 32      // beat width of the memory path
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     l2m_req_valid,
    input  wire [ADDR_WIDTH-1:0]    l2m_req_addr,
    input  wire                     l2m_req_write,
    input  wire [LINE_BYTES*8-1:0]  l2m_req_wdata,
    output wire                     l2m_req_ready,
    output wire                     l2m_resp_valid,
    output wire [LINE_BYTES*8-1:0]  l2m_resp_rdata,

    output wire                     xbar_req_valid,
    output wire [ADDR_WIDTH-1:0]    xbar_req_addr,
    output wire [DW-1:0]            xbar_req_wdata,
    output wire                     xbar_req_write,
    input  wire                     xbar_req_ready,
    input  wire                     xbar_resp_valid,
    input  wire [DW-1:0]            xbar_resp_rdata,

    // build configuration, readable from the testbench
    output wire [15:0]              cfg_data_width,
    output wire [15:0]              cfg_line_bytes,
    output wire [15:0]              cfg_beats
);

    assign cfg_data_width = DW[15:0];
    assign cfg_line_bytes = LINE_BYTES[15:0];
    assign cfg_beats      = (LINE_BYTES * 8) / DW;

    titan_x5_l2_mem_adapter #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .LINE_BYTES(LINE_BYTES),
        .DATA_WIDTH(DW)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .l2m_req_valid(l2m_req_valid),
        .l2m_req_addr(l2m_req_addr),
        .l2m_req_write(l2m_req_write),
        .l2m_req_wdata(l2m_req_wdata),
        .l2m_req_ready(l2m_req_ready),
        .l2m_resp_valid(l2m_resp_valid),
        .l2m_resp_rdata(l2m_resp_rdata),
        .xbar_req_valid(xbar_req_valid),
        .xbar_req_addr(xbar_req_addr),
        .xbar_req_wdata(xbar_req_wdata),
        .xbar_req_write(xbar_req_write),
        .xbar_req_ready(xbar_req_ready),
        .xbar_resp_valid(xbar_resp_valid),
        .xbar_resp_rdata(xbar_resp_rdata)
    );

endmodule
