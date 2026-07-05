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
 * Titan X5 GPU - Load/Store Unit with Memory Coalescing
 *
 * Accepts one warp-wide memory request (up to NUM_LANES lane addresses with
 * an active-lane mask) and coalesces the lane accesses into the minimal set
 * of LINE_BYTES-aligned line transactions toward the L1 D-cache.
 *
 * Coalescing algorithm (iterative, one line per iteration):
 *   1. Pick the lowest-numbered pending lane ("leader").
 *   2. Compute the leader's LINE_BYTES-aligned line address.
 *   3. All pending lanes whose address falls in the same line are merged
 *      into a single line transaction (byte enables mark the touched words).
 *   4. Issue the transaction; on completion, matched lanes are retired.
 *   5. Repeat until no lanes are pending, then return the warp response.
 *
 * A fully-converged warp access (all 32 lanes in one line) therefore costs
 * exactly 1 transaction instead of 32.
 *
 * Semantics / assumptions:
 *   - Lane addresses are treated as DATA_WIDTH-aligned (low addr bits within
 *     a word are ignored).
 *   - If two active lanes store to the same word, the higher-numbered lane
 *     wins (matches the reference model used in verification).
 *   - Inactive lanes return zero data on loads.
 *   - warp_resp_xactions reports how many line transactions were used, so
 *     testbenches can assert coalescing optimality.
 */
module titan_x5_lsu #(
    parameter NUM_LANES  = 32,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_BYTES = 128
)(
    input  wire                                clk,
    input  wire                                rst_n,

    // warp request (from SM pipeline MEM stage)
    input  wire                                warp_req_valid,
    output wire                                warp_req_ready,
    input  wire [2:0]                          warp_req_wid,
    input  wire                                warp_req_write,
    input  wire [NUM_LANES-1:0]                warp_req_mask,
    input  wire [NUM_LANES*ADDR_WIDTH-1:0]     warp_req_addr,
    input  wire [NUM_LANES*DATA_WIDTH-1:0]     warp_req_wdata,

    // warp response (single pulse)
    output reg                                 warp_resp_valid,
    output reg  [2:0]                          warp_resp_wid,
    output reg  [NUM_LANES*DATA_WIDTH-1:0]     warp_resp_rdata,
    output reg  [$clog2(NUM_LANES+1)-1:0]      warp_resp_xactions,

    // line interface (to L1 D-cache core port)
    output reg                                 mem_req_valid,
    input  wire                                mem_req_ready,
    output wire                                mem_req_write,
    output wire [ADDR_WIDTH-1:0]               mem_req_addr,
    output wire [LINE_BYTES*8-1:0]             mem_req_wdata,
    output wire [LINE_BYTES-1:0]               mem_req_be,
    input  wire                                mem_resp_valid,
    input  wire [LINE_BYTES*8-1:0]             mem_resp_rdata
);

    localparam OFFSET_BITS = $clog2(LINE_BYTES);
    localparam WORD_BYTES  = DATA_WIDTH / 8;
    localparam WORD_BITS   = $clog2(WORD_BYTES);
    localparam XCNT_W      = $clog2(NUM_LANES + 1);

    localparam S_IDLE  = 2'd0;
    localparam S_ISSUE = 2'd1;
    localparam S_WAIT  = 2'd2;
    localparam S_RESP  = 2'd3;

    reg [1:0]                      state;
    reg [NUM_LANES-1:0]            pending;
    reg [ADDR_WIDTH-1:0]           lane_addr  [0:NUM_LANES-1];
    reg [DATA_WIDTH-1:0]           lane_wdata [0:NUM_LANES-1];
    reg                            req_write_q;
    reg [2:0]                      req_wid_q;
    reg [NUM_LANES*DATA_WIDTH-1:0] rdata_accum;
    reg [XCNT_W-1:0]               xact_cnt;

    assign warp_req_ready = (state == S_IDLE);

    // ------------------------------------------------------------------
    // Combinational coalescer: leader select + same-line match mask
    // ------------------------------------------------------------------
    integer i;
    reg [$clog2(NUM_LANES)-1:0] leader;
    always @(*) begin
        leader = {$clog2(NUM_LANES){1'b0}};
        for (i = NUM_LANES - 1; i >= 0; i = i - 1) begin
            if (pending[i]) leader = i[$clog2(NUM_LANES)-1:0];
        end
    end

    wire [ADDR_WIDTH-1:0] leader_line = {lane_addr[leader][ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};

    reg [NUM_LANES-1:0] match;
    always @(*) begin
        for (i = 0; i < NUM_LANES; i = i + 1) begin
            match[i] = pending[i] &&
                       (lane_addr[i][ADDR_WIDTH-1:OFFSET_BITS] == leader_line[ADDR_WIDTH-1:OFFSET_BITS]);
        end
    end

    // Merge store data / byte enables for all matched lanes.
    // Ascending lane order means higher-numbered lanes overwrite lower ones
    // on same-word conflicts.
    reg [LINE_BYTES*8-1:0] line_wdata;
    reg [LINE_BYTES-1:0]   line_be;
    reg [OFFSET_BITS-WORD_BITS-1:0] word_off;
    always @(*) begin
        line_wdata = {LINE_BYTES*8{1'b0}};
        line_be    = {LINE_BYTES{1'b0}};
        word_off   = {(OFFSET_BITS-WORD_BITS){1'b0}};
        if (req_write_q) begin
            for (i = 0; i < NUM_LANES; i = i + 1) begin
                if (match[i]) begin
                    word_off = lane_addr[i][OFFSET_BITS-1:WORD_BITS];
                    line_wdata[word_off*DATA_WIDTH +: DATA_WIDTH] = lane_wdata[i];
                    line_be[word_off*WORD_BYTES +: WORD_BYTES]    = {WORD_BYTES{1'b1}};
                end
            end
        end
    end

    assign mem_req_addr  = leader_line;
    assign mem_req_write = req_write_q;
    assign mem_req_wdata = line_wdata;
    assign mem_req_be    = line_be;

    // ------------------------------------------------------------------
    // Control FSM
    // ------------------------------------------------------------------
    reg [OFFSET_BITS-WORD_BITS-1:0] rd_word_off;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state              <= S_IDLE;
            pending            <= {NUM_LANES{1'b0}};
            req_write_q        <= 1'b0;
            req_wid_q          <= 3'd0;
            rdata_accum        <= {NUM_LANES*DATA_WIDTH{1'b0}};
            xact_cnt           <= {XCNT_W{1'b0}};
            warp_resp_valid    <= 1'b0;
            warp_resp_wid      <= 3'd0;
            warp_resp_rdata    <= {NUM_LANES*DATA_WIDTH{1'b0}};
            warp_resp_xactions <= {XCNT_W{1'b0}};
            mem_req_valid      <= 1'b0;
            for (i = 0; i < NUM_LANES; i = i + 1) begin
                lane_addr[i]  <= {ADDR_WIDTH{1'b0}};
                lane_wdata[i] <= {DATA_WIDTH{1'b0}};
            end
        end else begin
            warp_resp_valid <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (warp_req_valid) begin
                        req_write_q <= warp_req_write;
                        req_wid_q   <= warp_req_wid;
                        rdata_accum <= {NUM_LANES*DATA_WIDTH{1'b0}};
                        xact_cnt    <= {XCNT_W{1'b0}};
                        for (i = 0; i < NUM_LANES; i = i + 1) begin
                            lane_addr[i]  <= warp_req_addr[i*ADDR_WIDTH +: ADDR_WIDTH];
                            lane_wdata[i] <= warp_req_wdata[i*DATA_WIDTH +: DATA_WIDTH];
                        end
                        if (warp_req_mask != {NUM_LANES{1'b0}}) begin
                            pending       <= warp_req_mask;
                            mem_req_valid <= 1'b1;
                            state         <= S_ISSUE;
                        end else begin
                            // fully-predicated-off access: complete immediately
                            state <= S_RESP;
                        end
                    end
                end

                S_ISSUE: begin
                    if (mem_req_ready) begin
                        xact_cnt <= xact_cnt + 1'b1;
                        if (req_write_q) begin
                            pending <= pending & ~match;
                            if ((pending & ~match) == {NUM_LANES{1'b0}}) begin
                                mem_req_valid <= 1'b0;
                                state         <= S_RESP;
                            end
                            // else: stay in S_ISSUE, next leader is selected
                            // combinationally from the reduced pending mask
                        end else begin
                            mem_req_valid <= 1'b0;
                            state         <= S_WAIT;
                        end
                    end
                end

                S_WAIT: begin
                    if (mem_resp_valid) begin
                        for (i = 0; i < NUM_LANES; i = i + 1) begin
                            if (match[i]) begin
                                rd_word_off = lane_addr[i][OFFSET_BITS-1:WORD_BITS];
                                rdata_accum[i*DATA_WIDTH +: DATA_WIDTH]
                                    <= mem_resp_rdata[rd_word_off*DATA_WIDTH +: DATA_WIDTH];
                            end
                        end
                        pending <= pending & ~match;
                        if ((pending & ~match) == {NUM_LANES{1'b0}}) begin
                            state <= S_RESP;
                        end else begin
                            mem_req_valid <= 1'b1;
                            state         <= S_ISSUE;
                        end
                    end
                end

                S_RESP: begin
                    warp_resp_valid    <= 1'b1;
                    warp_resp_wid      <= req_wid_q;
                    warp_resp_rdata    <= rdata_accum;
                    warp_resp_xactions <= xact_cnt;
                    state              <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
