// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Per-warp vector register file.
//
// Storage is NUM_REGS x NUM_WARPS entries of DATA_WIDTH bits. In the SM
// DATA_WIDTH is 1024 (32 lanes x 32 bits), so one entry is one architectural
// register across the whole warp.
//
// This file previously had NO warp dimension: NUM_REGS entries shared by every
// warp. Warps could not hold independent state -- eight warps running
// `ADD r6, r6, r3` accumulated into the same r6 eight times -- which is why
// LAUNCH_WARP_MASK in titan_x5_gpu_top was pinned to a single warp. The warp
// index below is what lifts that restriction.
//
// Register r maps to bank r[1:0] and bank entry r[5:2] (low-order interleave,
// chosen by the SM); the warp index selects which bank of REGS_PER_BANK
// entries within that bank's memory. Layout is warp-major:
//
//     bank_mem[warp * REGS_PER_BANK + entry]
//
// so warp w owns the contiguous range [w*REGS_PER_BANK, (w+1)*REGS_PER_BANK).
// Testbench backdoor deposits rely on that layout.
module titan_x5_register_file #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS = 64, // 64 registers per warp
    parameter NUM_BANKS = 4, // 4 banks, so 16 registers per bank
    parameter NUM_WARPS = 8, // independent register sets, one per warp
    // Derived, not intended to be overridden. Declared as a parameter rather
    // than a localparam because the port list below needs it, and localparams
    // in the module body are not visible there. $clog2(1) is 0, which would
    // make a zero-width port, so a single-warp build keeps one bit.
    parameter WARP_WIDTH = (NUM_WARPS <= 1) ? 1 : $clog2(NUM_WARPS)
) (
    input  wire clk,
    input  wire rst_n,

    // read ports (3 per bank for fma support)
    // Each port carries its own warp index. The SM drives all three from the
    // ID-stage warp, since one instruction reads all three operands, but the
    // ports are kept independent so the file does not constrain the pipeline.
    input wire [NUM_BANKS-1:0] rd_en_0,
    input wire [NUM_BANKS-1:0] rd_en_1,
    input wire [NUM_BANKS-1:0] rd_en_2,
    input wire [NUM_BANKS*4-1:0] rd_addr_0,
    input wire [NUM_BANKS*4-1:0] rd_addr_1,
    input wire [NUM_BANKS*4-1:0] rd_addr_2,
    input wire [WARP_WIDTH-1:0] rd_warp_0,
    input wire [WARP_WIDTH-1:0] rd_warp_1,
    input wire [WARP_WIDTH-1:0] rd_warp_2,
    output wire [NUM_BANKS*DATA_WIDTH-1:0] rd_data_0,
    output wire [NUM_BANKS*DATA_WIDTH-1:0] rd_data_1,
    output wire [NUM_BANKS*DATA_WIDTH-1:0] rd_data_2,

    // write ports (1 per bank), all writing the warp in the WB stage
    input wire [NUM_BANKS-1:0] wr_en,
    input wire [NUM_BANKS*4-1:0] wr_addr,
    input wire [WARP_WIDTH-1:0] wr_warp,
    input wire [NUM_BANKS*DATA_WIDTH-1:0] wr_data
);

    localparam REGS_PER_BANK = NUM_REGS / NUM_BANKS;
    localparam ADDR_WIDTH = 4;
    localparam TOTAL_ENTRIES = REGS_PER_BANK * NUM_WARPS;

    genvar b;
    generate
        for (b = 0; b < NUM_BANKS; b = b + 1) begin : bank_gen
            reg [DATA_WIDTH-1:0] bank_mem [0:TOTAL_ENTRIES-1];
            integer i;

            // Warp-major flattening: warp*REGS_PER_BANK + entry. REGS_PER_BANK
            // is a power of two in every configuration used here, so this
            // reduces to a concatenation rather than a real multiplier.
            wire [31:0] wr_slot = wr_warp * REGS_PER_BANK + wr_addr[b*ADDR_WIDTH +: ADDR_WIDTH];
            wire [31:0] rd_slot_0 = rd_warp_0 * REGS_PER_BANK + rd_addr_0[b*ADDR_WIDTH +: ADDR_WIDTH];
            wire [31:0] rd_slot_1 = rd_warp_1 * REGS_PER_BANK + rd_addr_1[b*ADDR_WIDTH +: ADDR_WIDTH];
            wire [31:0] rd_slot_2 = rd_warp_2 * REGS_PER_BANK + rd_addr_2[b*ADDR_WIDTH +: ADDR_WIDTH];

            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (i = 0; i < TOTAL_ENTRIES; i = i + 1) begin
                        bank_mem[i] <= {DATA_WIDTH{1'b0}};
                    end
                end else if (wr_en[b]) begin
                    bank_mem[wr_slot] <= wr_data[b*DATA_WIDTH +: DATA_WIDTH];
                end
            end

            assign rd_data_0[b*DATA_WIDTH +: DATA_WIDTH] = rd_en_0[b] ? bank_mem[rd_slot_0] : {DATA_WIDTH{1'b0}};
            assign rd_data_1[b*DATA_WIDTH +: DATA_WIDTH] = rd_en_1[b] ? bank_mem[rd_slot_1] : {DATA_WIDTH{1'b0}};
            assign rd_data_2[b*DATA_WIDTH +: DATA_WIDTH] = rd_en_2[b] ? bank_mem[rd_slot_2] : {DATA_WIDTH{1'b0}};
        end
    endgenerate

endmodule
