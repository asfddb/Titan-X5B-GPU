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
               STATE_REFILL = 3'd4;

    reg [2:0] state;
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
            for (b = 0; b < BANKS; b = b + 1) begin
                for (s = 0; s < SETS_PER_BANK; s = s + 1) begin
                    for (w = 0; w < WAYS; w = w + 1) begin
                        valid_array[b][s][w] <= 1'b0;
                        dirty_array[b][s][w] <= 1'b0;
                    end
                end
            end
        end else begin
            resp_valid_reg <= 1'b0;
            mem_req_valid_reg <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    req_ready_reg <= 1'b1;
                    if (req_valid && req_ready_reg) begin
                        req_ready_reg <= 1'b0;
                        state <= STATE_COMPARE;
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
                        req_ready_reg <= 1'b1;
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
