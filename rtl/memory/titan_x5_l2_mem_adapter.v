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
 * Titan X5 GPU - L2 Backing-Store Adapter
 *
 * Bridges the L2 cache's line-wide (LINE_BYTES) memory-controller interface
 * onto one 32-bit master port of the legacy system crossbar. Lines are
 * serialized into LINE_BYTES/4 word transactions:
 *   - writes: fire-and-forget word stream (ordering preserved by issuing
 *     in order through the same port),
 *   - reads: one word in flight at a time; the full line is assembled and
 *     returned in a single response pulse.
 */
module titan_x5_l2_mem_adapter #(
    parameter ADDR_WIDTH = 32,
    parameter LINE_BYTES = 128,
    parameter DATA_WIDTH = 32
)(
    input  wire                        clk,
    input  wire                        rst_n,

    // L2 cache memory-controller side
    input  wire                        l2m_req_valid,
    input  wire [ADDR_WIDTH-1:0]       l2m_req_addr,
    input  wire                        l2m_req_write,
    input  wire [LINE_BYTES*8-1:0]     l2m_req_wdata,
    output wire                        l2m_req_ready,
    output reg                         l2m_resp_valid,
    output reg  [LINE_BYTES*8-1:0]     l2m_resp_rdata,

    // legacy crossbar master port (32-bit)
    output reg                         xbar_req_valid,
    output wire [ADDR_WIDTH-1:0]       xbar_req_addr,
    output wire [DATA_WIDTH-1:0]       xbar_req_wdata,
    output reg                         xbar_req_write,
    input  wire                        xbar_req_ready,
    input  wire                        xbar_resp_valid,
    input  wire [DATA_WIDTH-1:0]       xbar_resp_rdata
);

    localparam WORDS   = LINE_BYTES * 8 / DATA_WIDTH;
    localparam CNT_W   = $clog2(WORDS);

    localparam A_IDLE    = 2'd0;
    localparam A_WRITE   = 2'd1;
    localparam A_RD_REQ  = 2'd2;
    localparam A_RD_WAIT = 2'd3;

    reg [1:0]              state;
    reg [ADDR_WIDTH-1:0]   base_addr;
    reg [LINE_BYTES*8-1:0] line_buf;
    reg [CNT_W-1:0]        word_cnt;

    assign l2m_req_ready = (state == A_IDLE);
    assign xbar_req_addr  = base_addr + {{(ADDR_WIDTH-CNT_W-2){1'b0}}, word_cnt, 2'b00};
    assign xbar_req_wdata = line_buf[word_cnt*DATA_WIDTH +: DATA_WIDTH];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= A_IDLE;
            base_addr      <= {ADDR_WIDTH{1'b0}};
            line_buf       <= {LINE_BYTES*8{1'b0}};
            word_cnt       <= {CNT_W{1'b0}};
            l2m_resp_valid <= 1'b0;
            l2m_resp_rdata <= {LINE_BYTES*8{1'b0}};
            xbar_req_valid <= 1'b0;
            xbar_req_write <= 1'b0;
        end else begin
            l2m_resp_valid <= 1'b0;

            case (state)
                A_IDLE: begin
                    if (l2m_req_valid) begin
                        base_addr <= l2m_req_addr;
                        line_buf  <= l2m_req_wdata;
                        word_cnt  <= {CNT_W{1'b0}};
                        if (l2m_req_write) begin
                            xbar_req_valid <= 1'b1;
                            xbar_req_write <= 1'b1;
                            state <= A_WRITE;
                        end else begin
                            xbar_req_valid <= 1'b1;
                            xbar_req_write <= 1'b0;
                            state <= A_RD_REQ;
                        end
                    end
                end

                A_WRITE: begin
                    if (xbar_req_ready) begin
                        if (word_cnt == WORDS - 1) begin
                            xbar_req_valid <= 1'b0;
                            xbar_req_write <= 1'b0;
                            state <= A_IDLE;
                        end else begin
                            word_cnt <= word_cnt + 1'b1;
                        end
                    end
                end

                A_RD_REQ: begin
                    if (xbar_req_ready) begin
                        xbar_req_valid <= 1'b0;
                        state <= A_RD_WAIT;
                    end
                end

                A_RD_WAIT: begin
                    if (xbar_resp_valid) begin
                        line_buf[word_cnt*DATA_WIDTH +: DATA_WIDTH] <= xbar_resp_rdata;
                        if (word_cnt == WORDS - 1) begin
                            l2m_resp_valid <= 1'b1;
                            // response assembled combinationally below via
                            // registered line_buf + last word
                            l2m_resp_rdata <= line_buf;
                            l2m_resp_rdata[word_cnt*DATA_WIDTH +: DATA_WIDTH] <= xbar_resp_rdata;
                            state <= A_IDLE;
                        end else begin
                            word_cnt <= word_cnt + 1'b1;
                            xbar_req_valid <= 1'b1;
                            state <= A_RD_REQ;
                        end
                    end
                end

                default: state <= A_IDLE;
            endcase
        end
    end

endmodule
