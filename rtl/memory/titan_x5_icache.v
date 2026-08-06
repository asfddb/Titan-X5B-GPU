// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

/*
 * titan_x5_icache - direct-mapped instruction cache, one per SM.
 *
 * WHY THIS EXISTS
 *
 * Until now there was no instruction cache at all. Every SM fetched single
 * 32-bit words straight onto the shared word crossbar (masters 9-12), one
 * outstanding at a time, so EVERY instruction cost a full crossbar round
 * trip: request, arbitrate, grant, wait for the memory controller, rvalid.
 * docs/HANDOFF_NEXT_SESSION.md calls this "measurably the dominant cost":
 * eight warps rather than one pushed the full-chip render test from 8,009 to
 * 10,009 cycles purely on fetch contention, and the X7 SM measured 1-7%
 * SLOWER than x5 on every single-warp kernel because its dual-issue front end
 * was being starved by exactly this port.
 *
 * WHERE IT SITS, AND WHY THAT SHAPE
 *
 *     titan_x5_sm.l1_icache_*  ->  [ this ]  ->  crossbar master 9+i
 *
 * It presents the SM's existing fetch port unchanged and speaks the same
 * word-read protocol to the crossbar, so **the SM does not change at all**.
 * That is deliberate and it is the whole point of this shape:
 *
 *   titan_x5_pipeline's wrong-path epoch is ONE BIT, and its own comment says
 *   that is sound "*only because there is a single outstanding fetch per SM*",
 *   because that keeps FIFO push order equal to fetch-accept order. Widening
 *   fetch to several outstanding requests would let a warp's stale entries be
 *   separated by a fresh one, the epoch could alias (ABA), and wrong-path
 *   instructions would retire.
 *
 * So this cache does NOT widen the SM's outstanding-fetch count. It keeps it
 * at exactly one and attacks the LATENCY of that one instead: a hit answers
 * in a single cycle with no crossbar traffic at all. A miss pays one line
 * fill and the next LINE_BYTES/4 - 1 sequential instructions are then free.
 * Straight-line code therefore drops from one crossbar transaction per
 * instruction to one per line.
 *
 * The epoch can be widened later, on its own, with its own test. It is not
 * entangled with this change.
 *
 * NO COHERENCE, DELIBERATELY. The code segment is read-only to the device --
 * nothing in this design writes to instruction memory once a kernel is
 * loaded -- so there is no snoop port and no invalidate. If self-modifying
 * code is ever wanted, this needs an invalidate path and a fence.
 */
module titan_x5_icache #(
    parameter ADDR_WIDTH = 32,
    parameter LINE_BYTES = 64,          // 16 instructions per line
    parameter SETS       = 64           // 64 x 64 B = 4 KiB, direct-mapped
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // ---- core side: titan_x5_sm's fetch port, unchanged ------------------
    // core_gnt is a single-cycle accept (the SM's PC unit advances on it), and
    // core_rvalid returns the word later. One request outstanding.
    input  wire [ADDR_WIDTH-1:0]   core_addr,
    input  wire                    core_req,
    output wire                    core_gnt,
    output reg  [31:0]             core_rdata,
    output reg                     core_rvalid,

    // ---- memory side: a 32-bit word master on titan_x5_crossbar ----------
    output wire [ADDR_WIDTH-1:0]   mem_addr,
    output wire                    mem_req,
    input  wire                    mem_gnt,
    input  wire [31:0]             mem_rdata,
    input  wire                    mem_rvalid,

    // ---- observability ---------------------------------------------------
    output reg  [31:0]             dbg_hits,
    output reg  [31:0]             dbg_misses
);

    localparam WORDS      = LINE_BYTES / 4;
    localparam WORD_BITS  = $clog2(WORDS);
    localparam SET_BITS   = $clog2(SETS);
    localparam OFF_BITS   = WORD_BITS + 2;               // byte offset in line
    localparam TAG_BITS   = ADDR_WIDTH - SET_BITS - OFF_BITS;

    // ---- storage ---------------------------------------------------------
    reg [31:0]         data_mem [0:SETS*WORDS-1];
    reg [TAG_BITS-1:0] tag_mem  [0:SETS-1];
    reg                valid    [0:SETS-1];

    integer i;

    // ---- request latch ---------------------------------------------------
    reg [ADDR_WIDTH-1:0] req_addr;
    reg                  req_live;

    wire [SET_BITS-1:0]  req_set  = req_addr[OFF_BITS +: SET_BITS];
    wire [TAG_BITS-1:0]  req_tag  = req_addr[ADDR_WIDTH-1 -: TAG_BITS];
    wire [WORD_BITS-1:0] req_word = req_addr[2 +: WORD_BITS];
    wire                 req_hit  = valid[req_set] && (tag_mem[req_set] == req_tag);

    // Combinational lookup on the incoming address, so a hit can be answered
    // without first parking the request.
    wire [SET_BITS-1:0]  in_set = core_addr[OFF_BITS +: SET_BITS];
    wire [TAG_BITS-1:0]  in_tag = core_addr[ADDR_WIDTH-1 -: TAG_BITS];
    wire                 in_hit = valid[in_set] && (tag_mem[in_set] == in_tag);

    // ---- fill state ------------------------------------------------------
    localparam S_IDLE = 2'd0,
               S_REQ  = 2'd1,   // driving a word request at the crossbar
               S_WAIT = 2'd2,   // request accepted, waiting for rvalid
               S_DONE = 2'd3;   // line complete, answer the core

    reg [1:0]            st;
    reg [WORD_BITS-1:0]  fill_idx;

    // Accept a new request only while idle and not already holding one.
    assign core_gnt = core_req && (st == S_IDLE) && !req_live;

    // Fill address: base of the line, plus the word being fetched.
    assign mem_addr = {req_addr[ADDR_WIDTH-1:OFF_BITS], fill_idx, 2'b00};
    assign mem_req  = (st == S_REQ);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st          <= S_IDLE;
            req_live    <= 1'b0;
            req_addr    <= {ADDR_WIDTH{1'b0}};
            fill_idx    <= {WORD_BITS{1'b0}};
            core_rvalid <= 1'b0;
            core_rdata  <= 32'd0;
            dbg_hits    <= 32'd0;
            dbg_misses  <= 32'd0;
            for (i = 0; i < SETS; i = i + 1) begin
                valid[i]   <= 1'b0;
                tag_mem[i] <= {TAG_BITS{1'b0}};
            end
        end else begin
            core_rvalid <= 1'b0;

            case (st)
                S_IDLE: begin
                    if (core_gnt) begin
                        req_addr <= core_addr;
                        if (in_hit) begin
                            // Answer next cycle straight out of the array.
                            core_rdata  <= data_mem[{in_set, core_addr[2 +: WORD_BITS]}];
                            core_rvalid <= 1'b1;
                            dbg_hits    <= dbg_hits + 32'd1;
                        end else begin
                            req_live   <= 1'b1;
                            fill_idx   <= {WORD_BITS{1'b0}};
                            st         <= S_REQ;
                            dbg_misses <= dbg_misses + 32'd1;
                            // Drop the old line's validity for the whole fill:
                            // a partially-filled line must never look like a
                            // hit to a request arriving mid-fill.
                            valid[in_set] <= 1'b0;
                        end
                    end
                end

                S_REQ: begin
                    if (mem_gnt) st <= S_WAIT;
                end

                S_WAIT: begin
                    if (mem_rvalid) begin
                        data_mem[{req_set, fill_idx}] <= mem_rdata;
                        // NOT `WORDS[WORD_BITS-1:0] - 1`. WORDS is 16 and
                        // WORD_BITS is 4, so that part-select is 16[3:0] = 0,
                        // and `0 - 1` then promotes to 32 bits (the integer
                        // literal's width) giving 32'hFFFFFFFF -- which a
                        // 4-bit fill_idx can never equal. The fill ran
                        // forever, cycling fill_idx 0..15 and re-requesting
                        // the same line until the test timed out. Comparing
                        // against the plain integer keeps both sides in a
                        // 32-bit context and compares 15 == 15.
                        if (fill_idx == (WORDS - 1)) begin
                            st <= S_DONE;
                        end else begin
                            fill_idx <= fill_idx + 1'b1;
                            st       <= S_REQ;
                        end
                    end
                end

                S_DONE: begin
                    // Publish the line, then answer the word that missed.
                    tag_mem[req_set] <= req_tag;
                    valid[req_set]   <= 1'b1;
                    core_rdata       <= data_mem[{req_set, req_word}];
                    core_rvalid      <= 1'b1;
                    req_live         <= 1'b0;
                    st               <= S_IDLE;
                end

                default: st <= S_IDLE;
            endcase
        end
    end

`ifdef TITAN_ICACHE_TRACE
    // Diagnostic only, never built by default. Prints the core-side handshake
    // so the fetch stream through the cache can be diffed against the stream
    // the crossbar produces with the cache bypassed.
    always @(posedge clk) if (rst_n) begin
        if (core_gnt)
            $display("ICTRACE %0t GNT  addr=%08x hit=%0d", $time, core_addr, in_hit);
        if (core_rvalid)
            $display("ICTRACE %0t RVAL data=%08x", $time, core_rdata);
    end
`endif

endmodule
