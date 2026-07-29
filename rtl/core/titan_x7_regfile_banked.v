// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Banked SRAM register file with an operand collector.
//
// WHY THIS EXISTS
//
// Every register file in this repo so far is a flop array with combinational
// reads:
//
//   titan_x5_register_file.v : 64 regs x 8 warps x 1024 bits = 524,288 flops
//                              per SM, three combinational read ports, and an
//                              async reset that clears all 512 entries.
//   titan_x7_sm.v:136        : `reg [LANES*32-1:0] rf [0:NUM_WARPS*64-1]`,
//                              read combinationally 8 times per cycle (two
//                              issue slots x {rs1,rs2,rs3}, plus the store
//                              data read at line 832) and written from 3
//                              writeback ports.
//
// An 8-read/3-write flop array is buildable at 130 nm and pointless at an
// advanced node: the storage is flops rather than bitcells (roughly an order
// of magnitude worse area per bit), the eight read muxes are long wires in a
// regime where wire delay dominates gate delay, and clearing every bit on
// reset costs a reset pin per flop plus an enormous reset fanout.
//
// Real GPU register files are banked single-ported SRAM plus an operand
// collector, and that is what this module is. The trade is explicit: a
// compiled SRAM gives one read and one write per bank per cycle with the
// read data arriving a cycle late, so an instruction's operands are gathered
// over several cycles into a collector unit and issued when complete. Bank
// conflicts cost latency, not correctness, and with many warps in flight the
// machine has other work to run meanwhile -- which is the entire reason SIMT
// tolerates this structure.
//
// STRUCTURE
//
//   - NUM_BANKS banks, each a titan_x7_sram_1r1w macro. Bank index is the
//     LOW bits of the register number, so the rs1/rs2/rs3 of a typical
//     instruction land in different banks and collect in one pass.
//   - Address map: bank = reg[BANK_W-1:0], row = {warp, reg[5:BANK_W]}.
//   - NUM_CU collector units. Each holds one instruction's operand requests
//     and its gathered data. A unit is allocated at issue and freed when its
//     operands are handed off.
//   - Per bank, one read is arbitrated per cycle across all outstanding
//     operand requests, and one write is arbitrated per cycle across the
//     writeback ports.
//
// WRITE PORT CONTRACT
//
// Writes are arbitrated, not queued: `wr_ready[p]` deasserts when port p
// loses its bank that cycle, and the caller must hold the write. Rotating
// priority prevents starvation. This keeps the bypass logic to a single
// comparison per bank (see below) and puts the buffering where it belongs --
// at the end of the producing pipe, whose depth is that pipe's business.
//
// ORDERING CONTRACT (write-first)
//
// A read requested in cycle T observes every write accepted in cycles <= T,
// including one to the same register in cycle T itself. The SRAM macro is
// read-before-write, so the write accepted in cycle T is NOT in the array
// when the read data emerges in cycle T+1; `wprev_*` below registers that
// write and merges it per lane on the way out. Assuming a write-first macro
// instead would have been one line shorter and would break on every macro
// that does not offer it.
module titan_x7_regfile_banked #(
    parameter LANES     = 8,
    parameter NUM_WARPS = 8,
    parameter NUM_REGS  = 64,
    parameter NUM_BANKS = 8,
    parameter NUM_CU    = 4,      // operand collector units
    parameter NUM_WP    = 3,      // writeback ports (INT / FP / MEM)
    parameter ID_W      = 8,      // caller tag, returned unmodified
    // Derived. Declared as parameters because the port list needs them.
    parameter WARP_W    = 3,      // $clog2(NUM_WARPS)
    parameter BANK_W    = 3,      // $clog2(NUM_BANKS)
    parameter ROW_W     = 6       // WARP_W + (6 - BANK_W)
) (
    input  wire                          clk,
    input  wire                          rst_n,

    // ---- allocate a collector unit for one instruction ------------------
    input  wire                          alloc_valid,
    output wire                          alloc_ready,
    input  wire [WARP_W-1:0]             alloc_warp,
    input  wire [5:0]                    alloc_rs1,
    input  wire [5:0]                    alloc_rs2,
    input  wire [5:0]                    alloc_rs3,
    input  wire [2:0]                    alloc_need,   // one bit per operand
    input  wire [ID_W-1:0]               alloc_id,

    // ---- operands issue out once every requested one has arrived --------
    // Issue order is NOT allocation order: a unit whose operands land in
    // separate banks completes before one that conflicts. Match on `id`.
    output wire                          issue_valid,
    input  wire                          issue_ready,
    output wire [ID_W-1:0]               issue_id,
    output wire [WARP_W-1:0]             issue_warp,
    output wire [LANES*32-1:0]           issue_o1,
    output wire [LANES*32-1:0]           issue_o2,
    output wire [LANES*32-1:0]           issue_o3,

    // ---- writeback ports -------------------------------------------------
    input  wire [NUM_WP-1:0]             wr_valid,
    output wire [NUM_WP-1:0]             wr_ready,
    input  wire [NUM_WP*WARP_W-1:0]      wr_warp,
    input  wire [NUM_WP*6-1:0]           wr_reg,
    input  wire [NUM_WP*LANES-1:0]       wr_mask,
    input  wire [NUM_WP*LANES*32-1:0]    wr_data
);

    localparam DW   = LANES*32;
    localparam ROWS = (NUM_WARPS*NUM_REGS)/NUM_BANKS;
    localparam NOP  = NUM_CU*3;        // total operand slots

    integer i, b, k, p;
    genvar  gb;

    // ====================================================================
    // collector unit state
    //
    // Operand slot k belongs to unit k/3, operand k%3.
    // ====================================================================
    reg              cu_valid [0:NUM_CU-1];
    reg [ID_W-1:0]   cu_id    [0:NUM_CU-1];
    reg [WARP_W-1:0] cu_warp  [0:NUM_CU-1];

    reg              op_need  [0:NOP-1];
    reg              op_got   [0:NOP-1];
    reg              op_infl  [0:NOP-1];   // a read is outstanding for it
    reg [5:0]        op_reg   [0:NOP-1];
    reg [DW-1:0]     op_data  [0:NOP-1];

    // ====================================================================
    // write arbitration: at most one write per bank per cycle
    // ====================================================================
    reg [NUM_WP-1:0]  wp_grant;
    reg               bank_we    [0:NUM_BANKS-1];
    reg [ROW_W-1:0]   bank_waddr [0:NUM_BANKS-1];
    reg [LANES-1:0]   bank_wmask [0:NUM_BANKS-1];
    reg [DW-1:0]      bank_wdata [0:NUM_BANKS-1];

    // Rotating base so a low-numbered port cannot starve the others.
    reg [1:0] wr_rr;

    always @(*) begin
        wp_grant = {NUM_WP{1'b0}};
        for (b = 0; b < NUM_BANKS; b = b + 1) begin
            bank_we[b]    = 1'b0;
            bank_waddr[b] = {ROW_W{1'b0}};
            bank_wmask[b] = {LANES{1'b0}};
            bank_wdata[b] = {DW{1'b0}};
        end
        // Visit ports in rotating order; first one to claim a bank wins it.
        for (i = 0; i < NUM_WP; i = i + 1) begin
            p = (i + wr_rr) % NUM_WP;
            if (wr_valid[p]) begin
                b = wr_reg[p*6 +: BANK_W];
                if (!bank_we[b]) begin
                    bank_we[b]    = 1'b1;
                    bank_waddr[b] = {wr_warp[p*WARP_W +: WARP_W],
                                     wr_reg[p*6 + BANK_W +: (6-BANK_W)]};
                    bank_wmask[b] = wr_mask[p*LANES +: LANES];
                    bank_wdata[b] = wr_data[p*DW +: DW];
                    wp_grant[p]   = 1'b1;
                end
            end
        end
    end

    assign wr_ready = wp_grant;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) wr_rr <= 2'd0;
        else        wr_rr <= (wr_rr == NUM_WP-1) ? 2'd0 : wr_rr + 2'd1;
    end

    // The write accepted last cycle. It is not yet visible to a read issued
    // last cycle (read-before-write), so it is merged on the way out.
    reg             wprev_we    [0:NUM_BANKS-1];
    reg [ROW_W-1:0] wprev_addr  [0:NUM_BANKS-1];
    reg [LANES-1:0] wprev_mask  [0:NUM_BANKS-1];
    reg [DW-1:0]    wprev_data  [0:NUM_BANKS-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_BANKS; i = i + 1) wprev_we[i] <= 1'b0;
        end else begin
            for (i = 0; i < NUM_BANKS; i = i + 1) begin
                wprev_we[i]   <= bank_we[i];
                wprev_addr[i] <= bank_waddr[i];
                wprev_mask[i] <= bank_wmask[i];
                wprev_data[i] <= bank_wdata[i];
            end
        end
    end

    // ====================================================================
    // read arbitration: at most one operand read per bank per cycle
    // ====================================================================
    reg                 bank_re    [0:NUM_BANKS-1];
    reg [ROW_W-1:0]     bank_raddr [0:NUM_BANKS-1];
    reg [NOP-1:0]       sel_onehot;          // which slot each bank chose

    // slot -> bank / row helpers
    wire [BANK_W-1:0] slot_bank [0:NOP-1];
    wire [ROW_W-1:0]  slot_row  [0:NOP-1];
    generate
        for (gb = 0; gb < NOP; gb = gb + 1) begin : slot_map
            assign slot_bank[gb] = op_reg[gb][BANK_W-1:0];
            assign slot_row[gb]  = {cu_warp[gb/3], op_reg[gb][5:BANK_W]};
        end
    endgenerate

    reg [31:0] chosen;      // slot index chosen for the bank under test

    always @(*) begin
        sel_onehot = {NOP{1'b0}};
        for (b = 0; b < NUM_BANKS; b = b + 1) begin
            bank_re[b]    = 1'b0;
            bank_raddr[b] = {ROW_W{1'b0}};
            chosen        = 32'hFFFF_FFFF;
            for (k = 0; k < NOP; k = k + 1) begin
                if (chosen == 32'hFFFF_FFFF &&
                    cu_valid[k/3] && op_need[k] && !op_got[k] && !op_infl[k] &&
                    slot_bank[k] == b[BANK_W-1:0]) begin
                    chosen = k;
                end
            end
            if (chosen != 32'hFFFF_FFFF) begin
                bank_re[b]         = 1'b1;
                bank_raddr[b]      = slot_row[chosen];
                sel_onehot[chosen] = 1'b1;
            end
        end
    end

    // in-flight read bookkeeping, one per bank
    reg             rd_pend      [0:NUM_BANKS-1];
    reg [31:0]      rd_pend_slot [0:NUM_BANKS-1];
    reg [ROW_W-1:0] rd_pend_row  [0:NUM_BANKS-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_BANKS; i = i + 1) rd_pend[i] <= 1'b0;
        end else begin
            for (i = 0; i < NUM_BANKS; i = i + 1) begin
                rd_pend[i] <= bank_re[i];
                if (bank_re[i]) begin
                    rd_pend_row[i] <= bank_raddr[i];
                    for (k = 0; k < NOP; k = k + 1)
                        if (sel_onehot[k] && slot_bank[k] == i[BANK_W-1:0])
                            rd_pend_slot[i] <= k;
                end
            end
        end
    end

    // ====================================================================
    // the banks
    // ====================================================================
    wire [DW-1:0] bank_rdata [0:NUM_BANKS-1];

    generate
        for (gb = 0; gb < NUM_BANKS; gb = gb + 1) begin : bank_gen
            titan_x7_sram_1r1w #(
                .LANES  (LANES),
                .DEPTH  (ROWS),
                .ADDR_W (ROW_W)
            ) u_sram (
                .clk    (clk),
                .re     (bank_re[gb]),
                .raddr  (bank_raddr[gb]),
                .rdata  (bank_rdata[gb]),
                .we     (bank_we[gb]),
                .waddr  (bank_waddr[gb]),
                .wmask  (bank_wmask[gb]),
                .wdata  (bank_wdata[gb])
            );
        end
    endgenerate

    // Returned data with the one-cycle-stale write merged in per lane.
    reg [DW-1:0] bank_ret [0:NUM_BANKS-1];
    always @(*) begin
        for (b = 0; b < NUM_BANKS; b = b + 1) begin
            bank_ret[b] = bank_rdata[b];
            if (wprev_we[b] && wprev_addr[b] == rd_pend_row[b]) begin
                for (i = 0; i < LANES; i = i + 1)
                    if (wprev_mask[b][i])
                        bank_ret[b][i*32 +: 32] = wprev_data[b][i*32 +: 32];
            end
        end
    end

    // ====================================================================
    // issue select: lowest ready unit
    // ====================================================================
    reg               iss_v;
    reg [31:0]        iss_cu;
    always @(*) begin
        iss_v  = 1'b0;
        iss_cu = 32'd0;
        for (i = NUM_CU-1; i >= 0; i = i - 1) begin
            if (cu_valid[i] &&
                (op_got[i*3+0] || !op_need[i*3+0]) &&
                (op_got[i*3+1] || !op_need[i*3+1]) &&
                (op_got[i*3+2] || !op_need[i*3+2])) begin
                iss_v  = 1'b1;
                iss_cu = i;
            end
        end
    end

    assign issue_valid = iss_v;
    assign issue_id    = cu_id[iss_cu];
    assign issue_warp  = cu_warp[iss_cu];
    assign issue_o1    = op_data[iss_cu*3+0];
    assign issue_o2    = op_data[iss_cu*3+1];
    assign issue_o3    = op_data[iss_cu*3+2];

    wire issue_fire = issue_valid && issue_ready;

    // ====================================================================
    // allocate: lowest free unit
    // ====================================================================
    reg        alc_v;
    reg [31:0] alc_cu;
    always @(*) begin
        alc_v  = 1'b0;
        alc_cu = 32'd0;
        for (i = NUM_CU-1; i >= 0; i = i - 1) begin
            // A unit being handed off this cycle frees up for reuse.
            if (!cu_valid[i] || (issue_fire && iss_cu == i)) begin
                alc_v  = 1'b1;
                alc_cu = i;
            end
        end
    end

    assign alloc_ready = alc_v;
    wire alloc_fire = alloc_valid && alloc_ready;

    // ====================================================================
    // state update
    // ====================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < NUM_CU; i = i + 1) cu_valid[i] <= 1'b0;
            for (k = 0; k < NOP; k = k + 1) begin
                op_need[k] <= 1'b0;
                op_got[k]  <= 1'b0;
                op_infl[k] <= 1'b0;
            end
        end else begin
            // reads issued this cycle become in-flight
            for (k = 0; k < NOP; k = k + 1)
                if (sel_onehot[k]) op_infl[k] <= 1'b1;

            // reads returning this cycle land in their slot
            for (b = 0; b < NUM_BANKS; b = b + 1) begin
                if (rd_pend[b]) begin
                    op_data[rd_pend_slot[b]] <= bank_ret[b];
                    op_got [rd_pend_slot[b]] <= 1'b1;
                    op_infl[rd_pend_slot[b]] <= 1'b0;
                end
            end

            // hand-off frees the unit
            if (issue_fire) cu_valid[iss_cu] <= 1'b0;

            // allocation claims one. Ordered after the hand-off clear above
            // so allocating into the unit being freed this cycle wins.
            if (alloc_fire) begin
                cu_valid[alc_cu] <= 1'b1;
                cu_id   [alc_cu] <= alloc_id;
                cu_warp [alc_cu] <= alloc_warp;

                op_reg [alc_cu*3+0] <= alloc_rs1;
                op_reg [alc_cu*3+1] <= alloc_rs2;
                op_reg [alc_cu*3+2] <= alloc_rs3;

                op_need[alc_cu*3+0] <= alloc_need[0];
                op_need[alc_cu*3+1] <= alloc_need[1];
                op_need[alc_cu*3+2] <= alloc_need[2];

                for (k = 0; k < 3; k = k + 1) begin
                    op_got [alc_cu*3+k] <= 1'b0;
                    op_infl[alc_cu*3+k] <= 1'b0;
                    op_data[alc_cu*3+k] <= {DW{1'b0}};
                end
            end
        end
    end

endmodule
