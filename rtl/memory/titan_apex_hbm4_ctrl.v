// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// TITAN APEX-X: multi-channel HBM4 memory controller front-end.
//
// WHY MULTI-CHANNEL, AND NOT ONE WIDE BUS
//
// The architecture spec asked for an 8192-bit interface (4 stacks x 2048).
// A single bus that wide does not work, and this is measured rather than
// argued: titan_x5_l2_mem_adapter computes WORDS = LINE_BYTES*8/DATA_WIDTH,
// so with the design's 128-byte line anything above 1024 bits truncates
// WORDS to 0 and the transfer never terminates. 1024 bits is already one
// full line per beat -- there is nothing left to widen.
//
// Real HBM has never been one wide bus either. Bandwidth comes from many
// INDEPENDENT channels, each with its own row buffers and command stream,
// so 8192 bits means 8 x 1024-bit channels, not one 8192-bit one. That is
// what this module presents.
//
// INTERLEAVING
//
// channel = addr[OFFSET + CH_BITS - 1 : OFFSET]
//
// i.e. the line-address bits immediately above the line offset. Consecutive
// cache lines therefore land in DIFFERENT channels, which is what makes a
// streaming access pattern use all of them at once. Interleaving on higher
// bits instead would put a whole contiguous region in one channel and
// serialise exactly the access pattern a GPU generates most.
//
// ORDERING
//
// Channels are independent, so responses come back OUT OF ORDER. Every
// request carries a caller-supplied TAG which is returned with its response;
// the caller matches on it. Per-channel tag FIFOs preserve order WITHIN a
// channel, which is all a channel can guarantee anyway.
//
// WHAT THIS IS NOT
//
// This is the controller front-end: routing, arbitration, tagging and flow
// control. It is not the HBM PHY. A real HBM4 PHY is analog IP -- delay-
// locked loops, per-bit deskew, training state machines, differential
// signalling -- licensed rather than written, and nothing here substitutes
// for it. Nor does this model DRAM timing (tRCD/tRP/refresh); the channel
// ports are a valid/ready abstraction that a timing-accurate channel
// controller would sit behind.
module titan_apex_hbm4_ctrl #(
    parameter ADDR_WIDTH = 40,          // 1 TiB of address space
    parameter LINE_BYTES = 128,         // matches the L2 line
    parameter NUM_CH     = 8,           // 8 x 1024b = the 8192b the spec wants
    parameter TAG_WIDTH  = 8,
    parameter TAGQ_DEPTH = 4,           // outstanding requests per channel
    // derived
    parameter LINE_BITS  = LINE_BYTES*8,
    parameter OFFSET     = 7,           // $clog2(128)
    parameter CH_BITS    = 3,           // $clog2(NUM_CH)
    // Tag-FIFO pointer width. MUST cover exactly TAGQ_DEPTH entries: a
    // pointer wider than the array indexes out of bounds and the FIFO
    // returns X, which is how the first version of this module failed.
    parameter TQ_PTR_W   = 2            // $clog2(TAGQ_DEPTH)
) (
    input  wire                          clk,
    input  wire                          rst_n,

    // ---- requester side (line granular, one port) ------------------------
    input  wire                          req_valid,
    output wire                          req_ready,
    input  wire                          req_write,
    input  wire [ADDR_WIDTH-1:0]         req_addr,
    input  wire [LINE_BITS-1:0]          req_wdata,
    input  wire [TAG_WIDTH-1:0]          req_tag,

    // responses return OUT OF ORDER; match on tag
    output reg                           resp_valid,
    output reg  [TAG_WIDTH-1:0]          resp_tag,
    output reg  [LINE_BITS-1:0]          resp_rdata,

    // ---- channel side ----------------------------------------------------
    output reg  [NUM_CH-1:0]             ch_req_valid,
    input  wire [NUM_CH-1:0]             ch_req_ready,
    output reg  [NUM_CH-1:0]             ch_req_write,
    output reg  [NUM_CH*ADDR_WIDTH-1:0]  ch_req_addr,
    output reg  [NUM_CH*LINE_BITS-1:0]   ch_req_wdata,

    input  wire [NUM_CH-1:0]             ch_resp_valid,
    output reg  [NUM_CH-1:0]             ch_resp_ready,
    input  wire [NUM_CH*LINE_BITS-1:0]   ch_resp_rdata,

    // observability
    output wire [NUM_CH-1:0]             dbg_ch_busy
);

    integer i;
    genvar  gc;

    // ---- which channel does this address belong to ----------------------
    wire [CH_BITS-1:0] req_ch = req_addr[OFFSET + CH_BITS - 1 : OFFSET];

    // ---- per-channel outstanding-tag FIFOs -------------------------------
    // Order within a channel is preserved; across channels it is not, which
    // is why the tag exists.
    reg [TAG_WIDTH-1:0] tq      [0:NUM_CH-1][0:TAGQ_DEPTH-1];
    reg [TQ_PTR_W-1:0]  tq_head [0:NUM_CH-1];
    reg [TQ_PTR_W-1:0]  tq_tail [0:NUM_CH-1];
    reg [3:0]           tq_cnt  [0:NUM_CH-1];

    wire [NUM_CH-1:0] tq_full;
    wire [NUM_CH-1:0] tq_empty;
    generate
        for (gc = 0; gc < NUM_CH; gc = gc + 1) begin : g_tq
            assign tq_full[gc]  = (tq_cnt[gc] == TAGQ_DEPTH);
            assign tq_empty[gc] = (tq_cnt[gc] == 0);
            assign dbg_ch_busy[gc] = ~tq_empty[gc];
        end
    endgenerate

    // A request is accepted only when its channel can take it AND has room
    // to record the tag. Writes still occupy a tag slot: the channel must
    // report completion so the caller knows when the write is visible, and
    // dropping the slot would let writes retire silently and out of order
    // with respect to reads the caller issued after them.
    wire ch_can_take = ch_req_ready[req_ch] && !tq_full[req_ch];
    assign req_ready = ch_can_take;
    wire  req_fire   = req_valid && req_ready;

    // ---- request routing --------------------------------------------------
    always @(*) begin
        ch_req_valid = {NUM_CH{1'b0}};
        ch_req_write = {NUM_CH{1'b0}};
        ch_req_addr  = {(NUM_CH*ADDR_WIDTH){1'b0}};
        ch_req_wdata = {(NUM_CH*LINE_BITS){1'b0}};
        if (req_valid && !tq_full[req_ch]) begin
            ch_req_valid[req_ch] = 1'b1;
            ch_req_write[req_ch] = req_write;
            ch_req_addr [req_ch*ADDR_WIDTH +: ADDR_WIDTH] = req_addr;
            ch_req_wdata[req_ch*LINE_BITS  +: LINE_BITS ] = req_wdata;
        end
    end

    // ---- response arbitration --------------------------------------------
    // Round-robin over channels with a response pending. One response is
    // returned per cycle; the rest hold, which is what ch_resp_ready is for.
    reg [CH_BITS-1:0] rr;
    reg [CH_BITS-1:0] sel_ch;
    reg               sel_valid;

    always @(*) begin
        sel_valid = 1'b0;
        sel_ch    = {CH_BITS{1'b0}};
        for (i = NUM_CH-1; i >= 0; i = i - 1) begin
            // visit in rotating order; lowest priority written first so the
            // rotating-highest wins
            if (ch_resp_valid[(rr + i[CH_BITS-1:0]) & (NUM_CH-1)] &&
                !tq_empty[(rr + i[CH_BITS-1:0]) & (NUM_CH-1)]) begin
                sel_valid = 1'b1;
                sel_ch    = (rr + i[CH_BITS-1:0]) & (NUM_CH-1);
            end
        end
        ch_resp_ready = {NUM_CH{1'b0}};
        if (sel_valid) ch_resp_ready[sel_ch] = 1'b1;
    end

    // ---- sequential ------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_CH; i = i + 1) begin
                tq_head[i] <= {TQ_PTR_W{1'b0}};
                tq_tail[i] <= {TQ_PTR_W{1'b0}};
                tq_cnt [i] <= 4'd0;
            end
            rr         <= {CH_BITS{1'b0}};
            resp_valid <= 1'b0;
            resp_tag   <= {TAG_WIDTH{1'b0}};
            resp_rdata <= {LINE_BITS{1'b0}};
        end else begin
            resp_valid <= 1'b0;

            // record the tag of an accepted request
            if (req_fire) begin
                tq[req_ch][tq_tail[req_ch]] <= req_tag;
                tq_tail[req_ch] <= tq_tail[req_ch] + {{(TQ_PTR_W-1){1'b0}}, 1'b1};
            end

            // return one response, oldest-first within its channel
            if (sel_valid) begin
                resp_valid <= 1'b1;
                resp_tag   <= tq[sel_ch][tq_head[sel_ch]];
                resp_rdata <= ch_resp_rdata[sel_ch*LINE_BITS +: LINE_BITS];
                tq_head[sel_ch] <= tq_head[sel_ch] + {{(TQ_PTR_W-1){1'b0}}, 1'b1};
                rr <= sel_ch + 1'b1;      // rotate so no channel starves
            end

            // Occupancy is updated per channel from BOTH events at once.
            // Writing it inside the two branches above would let the later
            // assignment win when a request and a response hit the same
            // channel in one cycle -- the net there is zero, not +1.
            for (i = 0; i < NUM_CH; i = i + 1) begin
                case ({req_fire && (req_ch == i[CH_BITS-1:0]),
                       sel_valid && (sel_ch == i[CH_BITS-1:0])})
                    2'b10:   tq_cnt[i] <= tq_cnt[i] + 4'd1;
                    2'b01:   tq_cnt[i] <= tq_cnt[i] - 4'd1;
                    default: tq_cnt[i] <= tq_cnt[i];   // 2'b11 nets to zero
                endcase
            end
        end
    end

endmodule
