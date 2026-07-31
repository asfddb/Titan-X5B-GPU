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
 * Module: titan_x5_flush_ctrl
 *
 * Device-level cache flush sequencer. One request in, one "memory is now
 * coherent" pulse out.
 *
 * WHY A SEQUENCER AND NOT JUST A WIRE
 * -----------------------------------
 * Both cache levels are write-back, and L1's flush writes to the coherent
 * bus -- which terminates at L2. Flushing L1 alone moves a kernel's result
 * from a Modified L1 line into a dirty L2 line and stops there; VRAM still
 * reads stale. The two levels must therefore be flushed in order, and the
 * L1 writebacks must have DRAINED THROUGH the coherent crossbar into L2
 * before the L2 walk starts -- otherwise the walk passes a set, the
 * writeback lands in it afterwards, and that line is left dirty in L2 with
 * nothing left to write it back.
 *
 * An L1's flush_done means its last writeback was ACCEPTED by the crossbar,
 * not that it reached L2: the crossbar is split-transaction with a 4-deep
 * queue behind a one-cycle grant. So the sequencer waits for the crossbar to
 * report itself quiescent (front-end idle, queue empty, engine idle) before
 * moving on.
 *
 * l1_flush_req is held for the WHOLE sequence, not just the L1 phase. Each
 * L1 holds core_req_ready low while its flush_req is asserted, so holding it
 * keeps every L1 frozen through the drain and the L2 walk. That is what
 * makes the quiescence argument sound: once flush_req is up, no L1 can
 * accept a new core request, so after the last walk finishes there is no
 * source of new bus traffic and bus_idle means genuinely drained.
 */
module titan_x5_flush_ctrl #(
    parameter NUM_L1 = 8
)(
    input  wire                clk,
    input  wire                rst_n,

    // Request. A level, not a pulse: the requester (the command processor's
    // FENCE) holds it until it sees flush_complete.
    input  wire                flush_start,
    output wire                flush_busy,
    output reg                 flush_complete,   // single-cycle pulse

    // every L1 in the device -- SM D-caches and TMU texture caches
    output reg                 l1_flush_req,
    input  wire [NUM_L1-1:0]   l1_flush_done,

    // coherent crossbar quiescent: nothing in flight anywhere in it
    input  wire                bus_idle,

    output reg                 l2_flush_req,
    input  wire                l2_flush_done
);

    localparam S_IDLE  = 3'd0,
               S_L1    = 3'd1,
               S_DRAIN = 3'd2,
               S_L2    = 3'd3,
               S_DONE  = 3'd4;

    reg [2:0]         state;
    reg [NUM_L1-1:0]  l1_done_acc;
    reg [1:0]         drain_cnt;

    // One request = one flush. flush_start is a level and the requester
    // cannot drop it until it has seen flush_complete, so without this the
    // sequence would immediately restart. Same shape, and the same reason,
    // as the flush_seen latch inside each cache.
    reg               started;

    assign flush_busy = (state != S_IDLE);

    // flush_done is a single-cycle pulse per cache and the caches finish at
    // different times (different dirty-line counts), so the pulses have to be
    // accumulated rather than ANDed live.
    wire [NUM_L1-1:0] l1_done_next = l1_done_acc | l1_flush_done;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            l1_flush_req   <= 1'b0;
            l2_flush_req   <= 1'b0;
            l1_done_acc    <= {NUM_L1{1'b0}};
            drain_cnt      <= 2'd0;
            flush_complete <= 1'b0;
            started        <= 1'b0;
        end else begin
            flush_complete <= 1'b0;                  // single-cycle pulse

            case (state)
                // `started` is rearmed HERE and only here. Clearing it
                // whenever flush_start happens to be low would clear it
                // mid-sequence too -- a requester that drops the request
                // before the flush finishes then gets a second, unasked-for
                // flush the moment the first one completes, which re-freezes
                // every L1 immediately after reporting the flush done.
                S_IDLE: begin
                    if (flush_start && !started) begin
                        l1_done_acc  <= {NUM_L1{1'b0}};
                        l1_flush_req <= 1'b1;
                        started      <= 1'b1;
                        state        <= S_L1;
                    end else if (!flush_start) begin
                        started <= 1'b0;             // rearm for the next fence
                    end
                end

                S_L1: begin
                    l1_done_acc <= l1_done_next;
                    if (l1_done_next == {NUM_L1{1'b1}}) begin
                        drain_cnt <= 2'd0;
                        state     <= S_DRAIN;
                    end
                end

                // Wait for the coherent crossbar to drain the L1 writebacks
                // into L2. bus_idle is required to hold for several cycles
                // rather than one: the crossbar hands a transaction from its
                // front-end to its queue to its engine, and this sequencer
                // should not have to depend on those handoffs never showing
                // a one-cycle gap. With every L1 frozen there is nothing to
                // re-arm the bus, so the extra cycles cost nothing.
                S_DRAIN: begin
                    if (bus_idle) begin
                        if (drain_cnt == 2'd3) state <= S_L2;
                        else                   drain_cnt <= drain_cnt + 2'd1;
                    end else begin
                        drain_cnt <= 2'd0;
                    end
                end

                S_L2: begin
                    l2_flush_req <= 1'b1;
                    if (l2_flush_done) begin
                        l2_flush_req <= 1'b0;
                        state        <= S_DONE;
                    end
                end

                S_DONE: begin
                    // Everything is written back and invalidated: release the
                    // L1s and tell the requester memory is coherent.
                    l1_flush_req   <= 1'b0;
                    flush_complete <= 1'b1;
                    state          <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
