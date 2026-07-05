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
 * Titan X5 GPU - L1 Data Cache with MESI Coherency
 *
 * - Set-associative, write-back, write-allocate.
 * - Line-wide core interface with byte enables (fed by the coalescing LSU).
 * - MESI state per line (I=0, S=1, E=2, M=3).
 * - Bus master port issuing BusRd / BusRdX / BusUpgr / BusWB transactions
 *   to the coherent crossbar.
 * - Snoop port servicing invalidations/downgrades from the crossbar; a
 *   Modified line hit by a snoop supplies its data (cache-to-cache).
 *
 * Protocol notes:
 * - The coherent crossbar serializes transactions, so between our bus grant
 *   and our bus response no foreign snoop can arrive. Snoops CAN arrive
 *   while we are still waiting for a grant; two races are handled:
 *     1. Pending BusUpgr whose line gets invalidated by a foreign BusRdX
 *        before our grant: the request is converted to BusRdX (data must
 *        be re-fetched).
 *     2. Pending BusWB (eviction) whose victim is hit by a snoop: the
 *        snoop supplies the dirty data and the crossbar updates L2, so the
 *        pending writeback is cancelled.
 * - E and S lines are evicted silently (no bus transaction), as permitted
 *   by snoop-based MESI.
 *
 * Core handshake:
 * - Requests are accepted with valid/ready. Reads complete with a
 *   core_resp_valid pulse carrying the full line. Writes complete silently
 *   (ready for the next request signals completion order).
 */
module titan_x5_l1_cache #(
    parameter ADDR_WIDTH = 32,
    parameter LINE_BYTES = 128,
    parameter WAYS       = 4,
    parameter SETS       = 64
)(
    input  wire                        clk,
    input  wire                        rst_n,

    // core (LSU) interface - line wide
    input  wire                        core_req_valid,
    output wire                        core_req_ready,
    input  wire                        core_req_write,
    input  wire [ADDR_WIDTH-1:0]       core_req_addr,
    input  wire [LINE_BYTES*8-1:0]     core_req_wdata,
    input  wire [LINE_BYTES-1:0]       core_req_be,
    output reg                         core_resp_valid,
    output reg  [LINE_BYTES*8-1:0]     core_resp_rdata,

    // bus master interface (to coherent crossbar)
    output reg                         bus_req_valid,
    input  wire                        bus_req_ready,
    output reg  [1:0]                  bus_req_type,   // 0 BusRd, 1 BusRdX, 2 BusUpgr, 3 BusWB
    output reg  [ADDR_WIDTH-1:0]       bus_req_addr,
    output reg  [LINE_BYTES*8-1:0]     bus_req_wdata,  // writeback data
    input  wire                        bus_resp_valid,
    input  wire [LINE_BYTES*8-1:0]     bus_resp_rdata,
    input  wire                        bus_resp_shared,

    // snoop interface (from coherent crossbar)
    input  wire                        snp_req_valid,
    input  wire [1:0]                  snp_req_type,   // BusRd / BusRdX / BusUpgr
    input  wire [ADDR_WIDTH-1:0]       snp_req_addr,
    output reg                         snp_resp_valid,
    output reg                         snp_resp_hit,
    output reg                         snp_resp_dirty,
    output reg  [LINE_BYTES*8-1:0]     snp_resp_data,

    // debug: MESI state lookup for verification
    input  wire [ADDR_WIDTH-1:0]       dbg_addr,
    output wire [1:0]                  dbg_mesi
);

    localparam OFFSET_BITS = $clog2(LINE_BYTES);
    localparam INDEX_BITS  = $clog2(SETS);
    localparam TAG_BITS    = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;
    localparam WAY_BITS    = (WAYS > 1) ? $clog2(WAYS) : 1;

    // MESI states
    localparam MESI_I = 2'd0;
    localparam MESI_S = 2'd1;
    localparam MESI_E = 2'd2;
    localparam MESI_M = 2'd3;

    // bus transaction types
    localparam BUS_RD   = 2'd0;
    localparam BUS_RDX  = 2'd1;
    localparam BUS_UPGR = 2'd2;
    localparam BUS_WB   = 2'd3;

    // FSM
    localparam S_IDLE   = 3'd0;
    localparam S_LOOKUP = 3'd1;
    localparam S_EVICT  = 3'd2;
    localparam S_REQ    = 3'd3;
    localparam S_FILL   = 3'd4;
    localparam S_RESP   = 3'd5;

    reg [2:0] state;

    // storage
    reg [LINE_BYTES*8-1:0] data_array [0:SETS-1][0:WAYS-1];
    reg [TAG_BITS-1:0]     tag_array  [0:SETS-1][0:WAYS-1];
    reg [1:0]              mesi_array [0:SETS-1][0:WAYS-1];
    reg [WAY_BITS-1:0]     rep_ptr    [0:SETS-1];

    // latched core request
    reg                    req_write_q;
    reg [ADDR_WIDTH-1:0]   req_addr_q;
    reg [LINE_BYTES*8-1:0] req_wdata_q;
    reg [LINE_BYTES-1:0]   req_be_q;

    wire [INDEX_BITS-1:0] req_index = req_addr_q[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]   req_tag   = req_addr_q[ADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    // pending bus transaction bookkeeping
    reg [WAY_BITS-1:0] victim_way_q;

    // ------------------------------------------------------------------
    // Hit detection (latched core request)
    // ------------------------------------------------------------------
    integer w;
    reg                hit;
    reg [WAY_BITS-1:0] hit_way;
    always @(*) begin
        hit = 1'b0;
        hit_way = {WAY_BITS{1'b0}};
        for (w = 0; w < WAYS; w = w + 1) begin
            if (mesi_array[req_index][w] != MESI_I &&
                tag_array[req_index][w] == req_tag) begin
                hit = 1'b1;
                hit_way = w[WAY_BITS-1:0];
            end
        end
    end

    // victim: first invalid way, else replacement pointer
    reg                have_inv;
    reg [WAY_BITS-1:0] inv_way;
    always @(*) begin
        have_inv = 1'b0;
        inv_way = {WAY_BITS{1'b0}};
        for (w = WAYS - 1; w >= 0; w = w - 1) begin
            if (mesi_array[req_index][w] == MESI_I) begin
                have_inv = 1'b1;
                inv_way = w[WAY_BITS-1:0];
            end
        end
    end
    wire [WAY_BITS-1:0] victim_way = have_inv ? inv_way : rep_ptr[req_index];

    // ------------------------------------------------------------------
    // Snoop lookup
    // ------------------------------------------------------------------
    wire [INDEX_BITS-1:0] snp_index = snp_req_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]   snp_tag   = snp_req_addr[ADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    reg                snp_hit;
    reg [WAY_BITS-1:0] snp_way;
    always @(*) begin
        snp_hit = 1'b0;
        snp_way = {WAY_BITS{1'b0}};
        for (w = 0; w < WAYS; w = w + 1) begin
            if (mesi_array[snp_index][w] != MESI_I &&
                tag_array[snp_index][w] == snp_tag) begin
                snp_hit = 1'b1;
                snp_way = w[WAY_BITS-1:0];
            end
        end
    end

    // snoops are serviced in states where no conflicting array write occurs
    reg snp_served;
    wire snoop_allowed = (state == S_IDLE) || (state == S_EVICT) ||
                         (state == S_REQ)  || (state == S_RESP);
    wire snoop_fire = snp_req_valid && !snp_served && snoop_allowed;

    // core accepts only when idle and no snoop is being serviced this cycle
    assign core_req_ready = (state == S_IDLE) && !snoop_fire;

    // ------------------------------------------------------------------
    // Debug MESI lookup
    // ------------------------------------------------------------------
    wire [INDEX_BITS-1:0] dbg_index = dbg_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]   dbg_tag   = dbg_addr[ADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
    reg [1:0] dbg_mesi_r;
    always @(*) begin
        dbg_mesi_r = MESI_I;
        for (w = 0; w < WAYS; w = w + 1) begin
            if (mesi_array[dbg_index][w] != MESI_I &&
                tag_array[dbg_index][w] == dbg_tag) begin
                dbg_mesi_r = mesi_array[dbg_index][w];
            end
        end
    end
    assign dbg_mesi = dbg_mesi_r;

    // ------------------------------------------------------------------
    // Byte-enable merge helper (write data into a line)
    // ------------------------------------------------------------------
    function [LINE_BYTES*8-1:0] merge_line;
        input [LINE_BYTES*8-1:0] old_line;
        input [LINE_BYTES*8-1:0] new_data;
        input [LINE_BYTES-1:0]   be;
        integer b;
        begin
            merge_line = old_line;
            for (b = 0; b < LINE_BYTES; b = b + 1) begin
                if (be[b]) merge_line[b*8 +: 8] = new_data[b*8 +: 8];
            end
        end
    endfunction

    // ------------------------------------------------------------------
    // Main FSM + snoop servicing (single always block: shared arrays)
    // ------------------------------------------------------------------
    integer s2, w2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= S_IDLE;
            core_resp_valid <= 1'b0;
            core_resp_rdata <= {LINE_BYTES*8{1'b0}};
            bus_req_valid   <= 1'b0;
            bus_req_type    <= BUS_RD;
            bus_req_addr    <= {ADDR_WIDTH{1'b0}};
            bus_req_wdata   <= {LINE_BYTES*8{1'b0}};
            snp_resp_valid  <= 1'b0;
            snp_resp_hit    <= 1'b0;
            snp_resp_dirty  <= 1'b0;
            snp_resp_data   <= {LINE_BYTES*8{1'b0}};
            snp_served      <= 1'b0;
            req_write_q     <= 1'b0;
            req_addr_q      <= {ADDR_WIDTH{1'b0}};
            req_wdata_q     <= {LINE_BYTES*8{1'b0}};
            req_be_q        <= {LINE_BYTES{1'b0}};
            victim_way_q    <= {WAY_BITS{1'b0}};
            for (s2 = 0; s2 < SETS; s2 = s2 + 1) begin
                rep_ptr[s2] <= {WAY_BITS{1'b0}};
                for (w2 = 0; w2 < WAYS; w2 = w2 + 1) begin
                    mesi_array[s2][w2] <= MESI_I;
                end
            end
        end else begin
            core_resp_valid <= 1'b0;
            snp_resp_valid  <= 1'b0;

            // snoop hand-shake bookkeeping
            if (!snp_req_valid)
                snp_served <= 1'b0;

            // ----------------------------------------------------------
            // Snoop servicing (priority over core path)
            // ----------------------------------------------------------
            if (snoop_fire) begin
                snp_served     <= 1'b1;
                snp_resp_valid <= 1'b1;
                snp_resp_hit   <= snp_hit;
                snp_resp_dirty <= snp_hit && (mesi_array[snp_index][snp_way] == MESI_M);
                snp_resp_data  <= data_array[snp_index][snp_way];

                if (snp_hit) begin
                    if (snp_req_type == BUS_RD) begin
                        // downgrade: M/E/S -> S (dirty data supplied to xbar)
                        mesi_array[snp_index][snp_way] <= MESI_S;
                    end else begin
                        // BusRdX / BusUpgr: invalidate
                        mesi_array[snp_index][snp_way] <= MESI_I;
                    end

                    // race 1: our pending BusUpgr line was invalidated before
                    // the grant - convert to BusRdX so data is re-fetched.
                    if (state == S_REQ && bus_req_type == BUS_UPGR &&
                        snp_req_type != BUS_RD &&
                        snp_req_addr[ADDR_WIDTH-1:OFFSET_BITS] == bus_req_addr[ADDR_WIDTH-1:OFFSET_BITS]) begin
                        bus_req_type <= BUS_RDX;
                    end

                    // race 2: our pending BusWB victim was snooped before the
                    // grant. The crossbar forwards the dirty data to L2, so
                    // our (now potentially stale-ordered) writeback must be
                    // cancelled; proceed straight to the line fetch.
                    if (state == S_EVICT &&
                        snp_req_addr[ADDR_WIDTH-1:OFFSET_BITS] == bus_req_addr[ADDR_WIDTH-1:OFFSET_BITS]) begin
                        bus_req_type <= req_write_q ? BUS_RDX : BUS_RD;
                        bus_req_addr <= {req_addr_q[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                        state        <= S_REQ;
                    end
                end
            end

            // ----------------------------------------------------------
            // Core request FSM
            // ----------------------------------------------------------
            case (state)
                S_IDLE: begin
                    if (core_req_valid && core_req_ready) begin
                        req_write_q <= core_req_write;
                        req_addr_q  <= core_req_addr;
                        req_wdata_q <= core_req_wdata;
                        req_be_q    <= core_req_be;
                        state       <= S_LOOKUP;
                    end
                end

                S_LOOKUP: begin
                    if (hit) begin
                        if (!req_write_q) begin
                            // read hit: M/E/S all serve locally
                            core_resp_rdata <= data_array[req_index][hit_way];
                            core_resp_valid <= 1'b1;
                            state           <= S_IDLE;
                        end else begin
                            case (mesi_array[req_index][hit_way])
                                MESI_M: begin
                                    data_array[req_index][hit_way]
                                        <= merge_line(data_array[req_index][hit_way], req_wdata_q, req_be_q);
                                    state <= S_IDLE;
                                end
                                MESI_E: begin
                                    // silent E -> M upgrade
                                    data_array[req_index][hit_way]
                                        <= merge_line(data_array[req_index][hit_way], req_wdata_q, req_be_q);
                                    mesi_array[req_index][hit_way] <= MESI_M;
                                    state <= S_IDLE;
                                end
                                default: begin
                                    // S: must broadcast BusUpgr before writing
                                    victim_way_q  <= hit_way;
                                    bus_req_valid <= 1'b1;
                                    bus_req_type  <= BUS_UPGR;
                                    bus_req_addr  <= {req_addr_q[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                                    state         <= S_REQ;
                                end
                            endcase
                        end
                    end else begin
                        // miss: allocate (write-allocate policy)
                        victim_way_q <= victim_way;
                        if (!have_inv) rep_ptr[req_index] <= rep_ptr[req_index] + 1'b1;
                        if (mesi_array[req_index][victim_way] == MESI_M) begin
                            // dirty victim: write back first. The victim
                            // deliberately stays resident (M) so snoops that
                            // arrive before our fill still hit it; the fill
                            // overwrites the way at S_FILL.
                            bus_req_valid <= 1'b1;
                            bus_req_type  <= BUS_WB;
                            bus_req_addr  <= {tag_array[req_index][victim_way], req_index, {OFFSET_BITS{1'b0}}};
                            bus_req_wdata <= data_array[req_index][victim_way];
                            state <= S_EVICT;
                        end else begin
                            // clean victim: silent eviction
                            mesi_array[req_index][victim_way] <= MESI_I;
                            bus_req_valid <= 1'b1;
                            bus_req_type  <= req_write_q ? BUS_RDX : BUS_RD;
                            bus_req_addr  <= {req_addr_q[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                            state <= S_REQ;
                        end
                    end
                end

                S_EVICT: begin
                    if (bus_req_ready) begin
                        // writeback accepted; now fetch the requested line
                        bus_req_type <= req_write_q ? BUS_RDX : BUS_RD;
                        bus_req_addr <= {req_addr_q[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                        state        <= S_REQ;
                    end
                end

                S_REQ: begin
                    if (bus_req_ready) begin
                        bus_req_valid <= 1'b0;
                        state         <= S_FILL;
                    end
                end

                S_FILL: begin
                    if (bus_resp_valid) begin
                        case (bus_req_type)
                            BUS_RD: begin
                                data_array[req_index][victim_way_q] <= bus_resp_rdata;
                                tag_array[req_index][victim_way_q]  <= req_tag;
                                mesi_array[req_index][victim_way_q] <= bus_resp_shared ? MESI_S : MESI_E;
                                core_resp_rdata <= bus_resp_rdata;
                                core_resp_valid <= 1'b1;
                                state           <= S_IDLE;
                            end
                            BUS_RDX: begin
                                data_array[req_index][victim_way_q]
                                    <= merge_line(bus_resp_rdata, req_wdata_q, req_be_q);
                                tag_array[req_index][victim_way_q]  <= req_tag;
                                mesi_array[req_index][victim_way_q] <= MESI_M;
                                state <= S_IDLE;
                            end
                            default: begin // BUS_UPGR granted
                                data_array[req_index][victim_way_q]
                                    <= merge_line(data_array[req_index][victim_way_q], req_wdata_q, req_be_q);
                                mesi_array[req_index][victim_way_q] <= MESI_M;
                                state <= S_IDLE;
                            end
                        endcase
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
