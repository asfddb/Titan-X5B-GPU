// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
//
// Per-warp program counter file.
//
// Until this module existed the SM had no program counter of its own: the
// warp scheduler took `warp_pc` as an *input*, and titan_x5_gpu_top tied it
// to a constant (`.warp_pc_in(256'h0)`). Every warp therefore refetched
// instruction 0 forever, `is_branch` was decoded and discarded, and a kernel
// had no way to terminate. This block supplies the missing state.
//
// PC semantics follow the software contract in driver/titan_x6_gpu_model.c
// exactly, so the RTL can be differentially tested against that functional
// model:
//
//   * the PC is an *instruction index*, not a byte address
//     (the model reads `vram_rd32(gpu, code_addr + pc * 4)`)
//   * straight-line execution advances `pc + 1`
//   * TX6_OP_BRANCH writes an absolute instruction index (`next_pc = imm`)
//   * TX6_OP_BARRIER with use_imm && imm == 0xFFF retires the thread
//
// Byte-address formation (`code_base + pc*4`) belongs to the fetch stage,
// not here, so this unit stays independent of the memory map.
//
// Same-cycle priority for one warp is: retire > redirect > sequential
// advance. A branch resolved in the same cycle that its own fetch is
// accepted must win, otherwise the redirect would be silently overwritten
// by the increment of the instruction that caused it.
// ============================================================================
`timescale 1ns/1ps

module titan_x5_pc_unit #(
    parameter NUM_WARPS = 8,
    parameter WARP_ID_W = 3
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // ---- kernel launch -------------------------------------------------
    // Activates every warp selected by launch_mask at launch_pc. The
    // command processor drives this at kernel dispatch.
    input  wire                     launch_valid,
    input  wire [NUM_WARPS-1:0]     launch_mask,
    input  wire [31:0]              launch_pc,

    // ---- sequential advance --------------------------------------------
    // Asserted for one cycle when the fetch of `fetch_warp` is accepted by
    // the interconnect (if_req && if_gnt in titan_x5_pipeline).
    input  wire                     fetch_accept,
    input  wire [WARP_ID_W-1:0]     fetch_warp,

    // ---- redirect ------------------------------------------------------
    // Taken branch, or a reconvergence-stack pop supplying the deferred PC.
    input  wire                     redirect_valid,
    input  wire [WARP_ID_W-1:0]     redirect_warp,
    input  wire [31:0]              redirect_pc,

    // ---- retire (EXIT) --------------------------------------------------
    input  wire                     retire_valid,
    input  wire [WARP_ID_W-1:0]     retire_warp,

    // ---- state out -------------------------------------------------------
    output wire [NUM_WARPS*32-1:0]  warp_pc,
    output wire [NUM_WARPS-1:0]     warp_active,
    output wire                     all_retired
);

    reg [31:0]          pc     [0:NUM_WARPS-1];
    reg [NUM_WARPS-1:0] active;
    reg                 launched;   // qualifies all_retired before first launch

    integer w;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (w = 0; w < NUM_WARPS; w = w + 1)
                pc[w] <= 32'd0;
            active   <= {NUM_WARPS{1'b0}};
            launched <= 1'b0;
        end else begin
            // ---- launch ------------------------------------------------
            if (launch_valid) begin
                for (w = 0; w < NUM_WARPS; w = w + 1) begin
                    if (launch_mask[w]) begin
                        pc[w]     <= launch_pc;
                        active[w] <= 1'b1;
                    end
                end
                launched <= launched | (|launch_mask);
            end

            // ---- per-warp PC update -------------------------------------
            // Written after the launch block so that a launch in the same
            // cycle as a stale fetch/redirect for the same warp still wins:
            // launching a warp resets its control flow unconditionally.
            for (w = 0; w < NUM_WARPS; w = w + 1) begin
                if (!(launch_valid && launch_mask[w])) begin
                    if (redirect_valid && redirect_warp == w[WARP_ID_W-1:0]
                        && active[w]) begin
                        pc[w] <= redirect_pc;
                    end else if (fetch_accept && fetch_warp == w[WARP_ID_W-1:0]
                                 && active[w]) begin
                        pc[w] <= pc[w] + 32'd1;
                    end
                end
            end

            // ---- retire --------------------------------------------------
            // Highest priority: a retiring warp stops fetching regardless of
            // any redirect or advance targeting it this cycle.
            if (retire_valid && !(launch_valid && launch_mask[retire_warp]))
                active[retire_warp] <= 1'b0;
        end
    end

    genvar g;
    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : pc_flatten
            assign warp_pc[g*32 +: 32] = pc[g];
        end
    endgenerate

    assign warp_active = active;
    assign all_retired = launched && (active == {NUM_WARPS{1'b0}});

endmodule
