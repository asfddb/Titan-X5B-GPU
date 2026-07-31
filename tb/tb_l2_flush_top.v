// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
// Testbench wrapper exposing titan_x5_l2_cache's own ports, including the
// flush/writeback-all interface. The existing `l2` suite drives the BANKED
// wrapper (titan_x6_banked_l2) hierarchically; this one talks to a single L2
// directly, because the property under test is about this module's walk over
// its own (bank, set, way) arrays.
//
// Scaled down so the walk simulates quickly while keeping the dimension that
// matters: BANKS=4 is not reducible here (the design fixes it, and the bank
// counter is the outermost loop of the flush walk, so a walk bug that skips
// banks is exactly what this must be able to see). WAYS stays at 8 because
// titan_x5_l2_cache's `replace_way` is a hardcoded 3-bit counter -- at WAYS<8
// it indexes past the end of the arrays, which is a pre-existing limitation
// of the module, not something this testbench should paper over.
`timescale 1ns / 1ps
module tb_l2_flush_top #(
    parameter ADDR_WIDTH = 32,
    parameter LINE_SIZE  = 16,   // 128-bit lines: 8x smaller than the chip's
    parameter WAYS       = 8,
    parameter SETS       = 16,   // 16 / 4 banks = 4 sets per bank
    parameter BANKS      = 4
)(
    input  wire                    clk,
    input  wire                    rst_n,

    input  wire                    req_valid,
    input  wire [ADDR_WIDTH-1:0]   req_addr,
    input  wire [LINE_SIZE*8-1:0]  req_wdata,
    input  wire                    req_write,
    output wire                    req_ready,

    output wire                    resp_valid,
    output wire [LINE_SIZE*8-1:0]  resp_rdata,

    input  wire                    flush_req,
    output wire                    flush_done,

    output wire                    mem_req_valid,
    output wire [ADDR_WIDTH-1:0]   mem_req_addr,
    output wire                    mem_req_write,
    output wire [LINE_SIZE*8-1:0]  mem_req_wdata,
    input  wire                    mem_req_ready,

    input  wire                    mem_resp_valid,
    input  wire [LINE_SIZE*8-1:0]  mem_resp_rdata,

    // ---- residency probe --------------------------------------------------
    // Direct read of one (bank, set, way) entry's valid/dirty bits. "The
    // cache holds nothing after a flush" is the half of the contract that
    // cannot be checked from the request port alone: a line left valid but
    // clean is still re-fetched on a read (the refill overwrites it), so a
    // read-misses check cannot distinguish it from a properly invalidated
    // one. Measured -- a mutation that wrote lines back without invalidating
    // them survived a behavioural-only version of this suite.
    input  wire [1:0]              dbg_bank,
    input  wire [1:0]              dbg_set,
    input  wire [2:0]              dbg_way,
    output wire                    dbg_valid,
    output wire                    dbg_dirty
);

    assign dbg_valid = u_l2.valid_array[dbg_bank][dbg_set][dbg_way];
    assign dbg_dirty = u_l2.dirty_array[dbg_bank][dbg_set][dbg_way];


    titan_x5_l2_cache #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(256),
        .LINE_SIZE(LINE_SIZE),
        .WAYS(WAYS),
        .SETS(SETS),
        .BANKS(BANKS)
    ) u_l2 (
        .clk(clk),
        .rst_n(rst_n),

        .req_valid(req_valid),
        .req_addr(req_addr),
        .req_wdata(req_wdata),
        .req_write(req_write),
        .req_ready(req_ready),

        .resp_valid(resp_valid),
        .resp_rdata(resp_rdata),

        .flush_req(flush_req),
        .flush_done(flush_done),

        .mem_req_valid(mem_req_valid),
        .mem_req_addr(mem_req_addr),
        .mem_req_write(mem_req_write),
        .mem_req_wdata(mem_req_wdata),
        .mem_req_ready(mem_req_ready),

        .mem_resp_valid(mem_resp_valid),
        .mem_resp_rdata(mem_resp_rdata)
    );

endmodule
