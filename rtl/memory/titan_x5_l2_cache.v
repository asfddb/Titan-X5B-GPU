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
 * Titan X5 GPU - 256KB Unified L2 Cache
 * - 8-way associative
 * - 128B lines
 * - Banked design (4 banks)
 */
module titan_x5_l2_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 256,
    parameter LINE_SIZE  = 128,
    parameter WAYS       = 8,
    parameter SETS       = 256, // 256KB total -> 64KB per bank -> 64 sets per bank
    parameter BANKS      = 4
)(
    input  wire clk,
    input  wire rst_n,

    // L1 Interface (Multiplexed or single for now)
    input  wire                    req_valid,
    input wire [ADDR_WIDTH-1:0] req_addr,
    input wire [LINE_SIZE*8-1:0] req_wdata,
    input  wire                    req_write,
    output wire                    req_ready,

    output wire                    resp_valid,
    output wire [LINE_SIZE*8-1:0] resp_rdata,

    // ---- flush / writeback-all -------------------------------------------
    // Raise flush_req and hold it until flush_done pulses. Every dirty line
    // is written back to the memory controller and EVERY line is
    // invalidated, so after flush_done this cache holds nothing and memory
    // holds the architectural state.
    //
    // L1 has had this since the flush suite was written, but L1 flushes to
    // the coherent bus, which terminates HERE -- the dirty line simply moves
    // from a Modified L1 line into a dirty L2 line and still never reaches
    // VRAM. A device-level flush that a host can rely on needs both, in that
    // order: every L1 first, then L2 once the L1 writebacks have landed.
    input  wire                    flush_req,
    output reg                     flush_done,

    // memory controller interface
    output wire                    mem_req_valid,
    output wire [ADDR_WIDTH-1:0] mem_req_addr,
    output wire                    mem_req_write,
    output wire [LINE_SIZE*8-1:0] mem_req_wdata,
    input  wire                    mem_req_ready,

    input  wire                    mem_resp_valid,
    input wire [LINE_SIZE*8-1:0] mem_resp_rdata
);

    localparam BANK_BITS   = $clog2(BANKS);
    localparam OFFSET_BITS = $clog2(LINE_SIZE);
    localparam SETS_PER_BANK = SETS / BANKS;
    localparam INDEX_BITS  = $clog2(SETS_PER_BANK);
    localparam TAG_BITS    = ADDR_WIDTH - INDEX_BITS - BANK_BITS - OFFSET_BITS;

    // address decoding
    wire [BANK_BITS-1:0]   req_bank  = (BANKS > 1) ? req_addr[OFFSET_BITS+BANK_BITS-1 : OFFSET_BITS] : 0;
    wire [INDEX_BITS-1:0]  req_index = req_addr[OFFSET_BITS+BANK_BITS+INDEX_BITS-1 : OFFSET_BITS+BANK_BITS];
    wire [TAG_BITS-1:0]    req_tag   = req_addr[ADDR_WIDTH-1 : OFFSET_BITS+BANK_BITS+INDEX_BITS];

    // cache storage
    reg [LINE_SIZE*8-1:0] data_array [0:BANKS-1][0:SETS_PER_BANK-1][0:WAYS-1];
    reg [TAG_BITS-1:0]    tag_array  [0:BANKS-1][0:SETS_PER_BANK-1][0:WAYS-1];
    reg                   valid_array[0:BANKS-1][0:SETS_PER_BANK-1][0:WAYS-1];
    reg                   dirty_array[0:BANKS-1][0:SETS_PER_BANK-1][0:WAYS-1];

    // Simple state machine for cache controller
    localparam STATE_IDLE = 3'd0,
               STATE_COMPARE = 3'd1,
               STATE_ALLOCATE = 3'd2,
               STATE_WRITEBACK = 3'd3,
               STATE_REFILL = 3'd4,
               // Flush walks every (bank, set, way). STATE_FLUSH inspects the
               // current entry; STATE_FLUSH_WB waits for the memory
               // controller to accept a dirty line's writeback.
               STATE_FLUSH = 3'd5,
               STATE_FLUSH_WB = 3'd6;

    reg [2:0] state;

    // ---- flush walk position ---------------------------------------------
    // One extra bit on the outermost (bank) counter so the walk can run past
    // the last bank to signal completion without wrapping back to 0.
    localparam WAY_BITS = (WAYS > 1) ? $clog2(WAYS) : 1;

    reg [BANK_BITS:0]    fl_bank;
    reg [INDEX_BITS-1:0] fl_set;
    reg [WAY_BITS-1:0]   fl_way;

    // One assertion of flush_req must produce exactly ONE walk. Without this
    // the walk restarts: flush_req is a level, the requester cannot drop it
    // until it has seen flush_done, and by then the FSM is back in IDLE
    // seeing flush_req still high. The extra walk is idempotent, so nothing
    // is corrupted -- but it costs a full BANKS*SETS*WAYS sweep on every
    // fence, and it runs concurrently with whatever the requester does next.
    // Measured: it made a testbench's post-flush residency check read state
    // that a second, unrequested walk was still clearing underneath it.
    reg flush_seen;

    wire [BANK_BITS-1:0] fl_b = fl_bank[BANK_BITS-1:0];

    // Next position, way-then-set-then-bank. Computed once and used by both
    // walk exits (clean entry dropped, dirty entry written back) so the two
    // cannot drift apart.
    wire fl_way_last = (fl_way == WAYS - 1);
    wire fl_set_last = (fl_set == SETS_PER_BANK - 1);

    wire [WAY_BITS-1:0]   fl_way_n  = fl_way_last ? {WAY_BITS{1'b0}} : fl_way + 1'b1;
    wire [INDEX_BITS-1:0] fl_set_n  = fl_way_last ? (fl_set_last ? {INDEX_BITS{1'b0}}
                                                                 : fl_set + 1'b1)
                                                  : fl_set;
    wire [BANK_BITS:0]    fl_bank_n = (fl_way_last && fl_set_last) ? fl_bank + 1'b1
                                                                  : fl_bank;

    wire fl_entry_dirty = valid_array[fl_b][fl_set][fl_way] &&
                          dirty_array[fl_b][fl_set][fl_way];
    reg [2:0] replace_way; // pseudo-random replacement
    reg [2:0] victim_way;  // latched at COMPARE so it is stable across
                           // WRITEBACK/ALLOCATE/REFILL

    reg mem_req_valid_reg;
    reg mem_req_write_reg;
    reg [ADDR_WIDTH-1:0] mem_req_addr_reg;
    reg [LINE_SIZE*8-1:0] mem_req_wdata_reg;

    reg resp_valid_reg;
    reg [LINE_SIZE*8-1:0] resp_rdata_reg;
    reg req_ready_reg;

    // Hit logic
    reg hit;
    reg [2:0] hit_way;
    integer i;

    always @(*) begin
        hit = 1'b0;
        hit_way = 0;
        for (i = 0; i < WAYS; i = i + 1) begin
            if (valid_array[req_bank][req_index][i] && (tag_array[req_bank][req_index][i] == req_tag)) begin
                hit = 1'b1;
                hit_way = i[2:0];
            end
        end
    end

    integer b, s, w;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            replace_way <= 0;
            victim_way <= 0;
            mem_req_valid_reg <= 0;
            resp_valid_reg <= 0;
            req_ready_reg <= 1;
            flush_done <= 1'b0;
            flush_seen <= 1'b0;
            fl_bank <= 0;
            fl_set <= 0;
            fl_way <= 0;
            for (b = 0; b < BANKS; b = b + 1) begin
                for (s = 0; s < SETS_PER_BANK; s = s + 1) begin
                    for (w = 0; w < WAYS; w = w + 1) begin
                        // blocking assigns: reset-only array init; Verilator
                        // cannot unroll a 2048-iteration NBA loop (BLKLOOPINIT)
                        valid_array[b][s][w] = 1'b0;
                        dirty_array[b][s][w] = 1'b0;
                    end
                end
            end
        end else begin
            resp_valid_reg <= 1'b0;
            mem_req_valid_reg <= 1'b0;
            flush_done <= 1'b0;   // single-cycle pulse
            if (!flush_req) flush_seen <= 1'b0;   // rearm for the next fence

            case (state)
                STATE_IDLE: begin
                    // Stop accepting as soon as a flush is asked for, but
                    // still honour a request that handshook THIS cycle --
                    // req_ready is registered here, so the requester has
                    // already seen ready=1 and considers it accepted.
                    // Dropping it would lose a transaction.
                    req_ready_reg <= !(flush_req && !flush_seen);
                    if (req_valid && req_ready_reg) begin
                        req_ready_reg <= 1'b0;
                        state <= STATE_COMPARE;
                    end else if (flush_req && !flush_seen) begin
                        fl_bank <= 0;
                        fl_set  <= 0;
                        fl_way  <= 0;
                        state   <= STATE_FLUSH;
                    end
                end

                STATE_COMPARE: begin
                    if (hit) begin
                        if (req_write) begin
                            data_array[req_bank][req_index][hit_way] <= req_wdata;
                            dirty_array[req_bank][req_index][hit_way] <= 1'b1;
                        end else begin
                            resp_rdata_reg <= data_array[req_bank][req_index][hit_way];
                            resp_valid_reg <= 1'b1;
                        end
                        // !flush_req, not 1: returning to IDLE with ready
                        // high would let the next request in ahead of a
                        // pending flush, and under continuous traffic the
                        // flush would never start.
                        req_ready_reg <= !(flush_req && !flush_seen);
                        state <= STATE_IDLE;
                    end else begin
                        // Miss: latch the victim now so it stays stable for
                        // the whole WRITEBACK/ALLOCATE/REFILL sequence
                        victim_way <= replace_way;
                        replace_way <= replace_way + 1; // advance once per allocation
                        if (valid_array[req_bank][req_index][replace_way] && dirty_array[req_bank][req_index][replace_way]) begin
                            state <= STATE_WRITEBACK;
                        end else begin
                            state <= STATE_ALLOCATE;
                        end
                    end
                end

                STATE_WRITEBACK: begin
                    mem_req_valid_reg <= 1'b1;
                    mem_req_write_reg <= 1'b1;
                    mem_req_addr_reg <= {tag_array[req_bank][req_index][victim_way], req_index[INDEX_BITS-1:0], req_bank[BANK_BITS-1:0], {OFFSET_BITS{1'b0}}};
                    mem_req_wdata_reg <= data_array[req_bank][req_index][victim_way];
                    if (mem_req_valid_reg && mem_req_ready) begin
                        state <= STATE_ALLOCATE;
                        mem_req_valid_reg <= 1'b0;
                    end
                end

                STATE_ALLOCATE: begin
                    mem_req_valid_reg <= 1'b1;
                    mem_req_write_reg <= 1'b0;
                    mem_req_addr_reg <= {req_tag, req_index[INDEX_BITS-1:0], req_bank[BANK_BITS-1:0], {OFFSET_BITS{1'b0}}};
                    if (mem_req_valid_reg && mem_req_ready) begin
                        state <= STATE_REFILL;
                        mem_req_valid_reg <= 1'b0;
                    end
                end

                STATE_REFILL: begin
                    if (mem_resp_valid) begin
                        valid_array[req_bank][req_index][victim_way] <= 1'b1;
                        tag_array[req_bank][req_index][victim_way] <= req_tag;
                        data_array[req_bank][req_index][victim_way] <= mem_resp_rdata;
                        dirty_array[req_bank][req_index][victim_way] <= 1'b0;
                        state <= STATE_COMPARE; // Retry compare
                    end
                end

                // ---- flush walk ------------------------------------------
                // Write back every dirty line, invalidate every line. Clean
                // and already-invalid entries are dropped silently: L2 is
                // write-back, so a clean line means memory already holds its
                // data. Invalidating them too is what makes the flush a
                // writeback-ALL rather than a writeback-dirty -- a host that
                // reads memory after this must not be able to hit a stale
                // cached copy on its next access.
                STATE_FLUSH: begin
                    if (fl_bank == BANKS[BANK_BITS:0]) begin
                        flush_done    <= 1'b1;
                        flush_seen    <= 1'b1;
                        req_ready_reg <= 1'b1;
                        state         <= STATE_IDLE;
                    end else if (fl_entry_dirty) begin
                        mem_req_valid_reg <= 1'b1;
                        mem_req_write_reg <= 1'b1;
                        mem_req_addr_reg  <= {tag_array[fl_b][fl_set][fl_way],
                                              fl_set, fl_b, {OFFSET_BITS{1'b0}}};
                        mem_req_wdata_reg <= data_array[fl_b][fl_set][fl_way];
                        state             <= STATE_FLUSH_WB;
                    end else begin
                        valid_array[fl_b][fl_set][fl_way] <= 1'b0;
                        dirty_array[fl_b][fl_set][fl_way] <= 1'b0;
                        fl_way  <= fl_way_n;
                        fl_set  <= fl_set_n;
                        fl_bank <= fl_bank_n;
                    end
                end

                // Hold the writeback until the memory controller takes it.
                // addr/wdata were latched on entry and are not re-driven, so
                // they stay stable across an arbitrarily long stall.
                STATE_FLUSH_WB: begin
                    mem_req_valid_reg <= 1'b1;
                    mem_req_write_reg <= 1'b1;
                    if (mem_req_valid_reg && mem_req_ready) begin
                        mem_req_valid_reg <= 1'b0;
                        valid_array[fl_b][fl_set][fl_way] <= 1'b0;
                        dirty_array[fl_b][fl_set][fl_way] <= 1'b0;
                        fl_way  <= fl_way_n;
                        fl_set  <= fl_set_n;
                        fl_bank <= fl_bank_n;
                        state   <= STATE_FLUSH;
                    end
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

    assign mem_req_valid = mem_req_valid_reg;
    assign mem_req_addr = mem_req_addr_reg;
    assign mem_req_write = mem_req_write_reg;
    assign mem_req_wdata = mem_req_wdata_reg;
    assign resp_valid = resp_valid_reg;
    assign resp_rdata = resp_rdata_reg;
    assign req_ready = req_ready_reg;

endmodule
