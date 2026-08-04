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
 * Titan X7 GPU - dual-issue, scoreboarded, deep-pipeline SIMT SM.
 *
 * Major upgrades over titan_x5_sm:
 *   - DUAL ISSUE, cross-warp: two instructions from two different warps
 *     enter two different execution pipes (INT / FP / MEM) each cycle.
 *     Cross-warp pairing makes intra-pair hazards structurally impossible.
 *   - Per-warp instruction buffers (8 deep) decoupling fetch from issue;
 *     pair-fetch (64-bit) interface to the I-cache.
 *   - gshare+BTB branch prediction steering fetch down the predicted
 *     path; misprediction recovery by per-warp epoch flush (no issued
 *     instruction is ever killed: issue stalls in the branch shadow while
 *     OTHER warps keep both pipes busy - the SIMT way to hide it).
 *   - Scoreboard (RAW/WAW) dependency tracking with 3 writeback clear
 *     ports; out-of-order COMPLETION across pipes of different latency
 *     (INT 2-stage, FP 8-stage FMA, variable-latency memory).
 *   - GTO (greedy-then-oldest) warp scheduling with per-warp aging.
 *
 * Pipeline: F0 predict/arb | F1 I$ req | F2 I$ resp -> IBUF | IS decode+
 * scoreboard+GTO | RF read | EX (INT: X1/X2 - FP: 8-stage FMA - MEM:
 * AGU/REQ/RESP) | WB (3 ports).
 *
 * ISA: Titan X5 v2 (shared decoder titan_x5_decoder). Notes:
 *   - BRANCH: UNCONDITIONAL, gated only by its predicate. rs1 is not read.
 *     target = absolute instruction index (imm12), scaled <<2 to a byte PC.
 *   - LOAD/STORE: addr(lane) = rs1(lane) + (use_imm ? zext(imm) : rs2);
 *     STORE data = rs3.
 *   - SETP: rd = {cond[2:0], pdst[1:0]}. cond selects one of the six
 *     TX6_CMP_* comparisons (EQ/NE/LT/GE/LTU/GEU); the result is a per-lane
 *     mask in preds[pdst]. p0 is hardwired all-ones. Predicated ops write
 *     only enabled lanes.
 *   - CVT: imm[0]=0 int->float (RNE); imm[0]=1 float->int (truncate).
 *   - DIV, SIN, COS, atomics: not implemented in hardware (DIV/SIN/COS
 *     are compiler-expanded on real GPUs too); they retire with rd=0.
 *
 * This comment block described the pre-conformance semantics for a while
 * after the RTL had moved on -- BRANCH as a register test, SETP as a bare
 * signed less-than, and an RSQRT on opcode 29 that is not in this ISA at
 * all. Four divergences from driver/titan_x6_isa.h have now been found in
 * this module; see docs/X7_ISA_CONFORMANCE.md before trusting any statement
 * about what an opcode here does.
 */
module titan_x7_sm #(
    parameter NUM_WARPS = 8,
    parameter WARP_W    = 3,
    parameter LANES     = 8
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // warp control
    input  wire [NUM_WARPS-1:0]     warp_active,
    input  wire [NUM_WARPS*32-1:0]  warp_pc_in,

    // instruction memory: pair fetch, warp-tagged, one outstanding/warp
    output reg                      imem_req_valid,
    input  wire                     imem_req_ready,
    output reg  [WARP_W-1:0]        imem_req_warp,
    output reg  [31:0]              imem_req_pc,
    input  wire                     imem_resp_valid,
    input  wire [WARP_W-1:0]        imem_resp_warp,
    input  wire [63:0]              imem_resp_data,

    // data memory (coalescing LSU downstream), warp-wide
    output wire                     dmem_req_valid,
    input  wire                     dmem_req_ready,
    output wire                     dmem_req_write,
    output wire [WARP_W-1:0]        dmem_req_warp,
    output wire [LANES-1:0]         dmem_req_mask,
    output wire [LANES*32-1:0]      dmem_req_addr,
    output wire [LANES*32-1:0]      dmem_req_wdata,
    input  wire                     dmem_resp_valid,
    input  wire [WARP_W-1:0]        dmem_resp_warp,
    input  wire [LANES*32-1:0]      dmem_resp_rdata,

    // tensor export (WMMA operands stream to the tensor array)
    output reg                      wmma_valid,
    output reg  [WARP_W-1:0]        wmma_warp,
    output reg  [LANES*32-1:0]      wmma_a,
    output reg  [LANES*32-1:0]      wmma_b,

    // warp retirement: EXIT is BARRIER with use_imm && imm == 0xFFF (the
    // same TX6_EXIT_IMM convention as titan_x5_pipeline). A plain BARRIER
    // (without that immediate) is thread sync, not termination.
    output reg                      warp_exit_valid,
    output reg  [WARP_W-1:0]        warp_exit_warp,
    output wire                     all_retired,

    // shader export: the INT writeback port, mirrored out so an enclosing
    // SM can forward R63 writes to the ROP the way titan_x5_sm does
    // (shader_wb_valid/reg/data are just its writeback port).
    output reg                      wb_export_valid,
    output reg  [5:0]               wb_export_reg,
    output reg  [LANES*32-1:0]      wb_export_data,

    // observability
    output reg  [31:0]              dbg_retired,
    input  wire [WARP_W-1:0]        dbg_warp,
    input  wire [5:0]               dbg_reg,
    output wire [LANES*32-1:0]      dbg_rdata
);

    localparam CL_INT = 2'd0, CL_FP = 2'd1, CL_MEM = 2'd2, CL_OTH = 2'd3;
    localparam IB_DEPTH = 8;
    localparam FP_LAT = 8;

    // NOTE: every always block gets PRIVATE loop variables. Sharing one
    // integer across processes is a real concurrency hazard: the scheduler
    // may interleave processes, so another block's finished loop can leave
    // the shared index out of range and silently skip this block's loops.
    integer i, j;        // main sequential block only
    integer fsi;         // fetch-scan combinational block
    integer fmi;         // FP operand-mux combinational block
    integer fqi;         // FP sideband queue block
    genvar g, gl;

    // ==================================================================
    // per-warp front-end state
    // ==================================================================
    reg [31:0] fetch_pc [0:NUM_WARPS-1];
    reg        epoch    [0:NUM_WARPS-1];
    reg        pend     [0:NUM_WARPS-1];
    reg        pend_epoch [0:NUM_WARPS-1];
    reg        pend_drop1 [0:NUM_WARPS-1];
    reg        pend_pt0 [0:NUM_WARPS-1];
    reg [31:0] pend_tg0 [0:NUM_WARPS-1];
    reg        pend_pt1 [0:NUM_WARPS-1];
    reg [31:0] pend_tg1 [0:NUM_WARPS-1];
    reg [31:0] pend_pc  [0:NUM_WARPS-1];
    reg [NUM_WARPS-1:0] prev_active;

    // instruction buffers: {epoch, pred_taken, pred_target, pc, inst}
    localparam IBW = 1 + 1 + 32 + 32 + 32;
    reg [IBW-1:0] ibuf [0:NUM_WARPS-1][0:IB_DEPTH-1];
    reg [2:0]     ib_rd [0:NUM_WARPS-1];
    reg [2:0]     ib_wr [0:NUM_WARPS-1];
    reg [3:0]     ib_cnt [0:NUM_WARPS-1];

    // per-warp interlocks
    reg [NUM_WARPS-1:0] branch_shadow;
    reg [1:0]           pred_pending [0:NUM_WARPS-1];
    reg [NUM_WARPS-1:0] barrier_wait;
    reg [NUM_WARPS-1:0] warp_retired;
    reg                 lsu_busy;

    assign all_retired = (warp_active != {NUM_WARPS{1'b0}}) &&
                          ((warp_retired & warp_active) == warp_active);

    // ==================================================================
    // register file & predicate file (flop model; physical: banked SRAM
    // with an operand collector, see docs/X7_UPGRADE.md)
    // ==================================================================
    reg [LANES*32-1:0] rf [0:NUM_WARPS*64-1];
    reg [LANES-1:0]    preds [0:NUM_WARPS-1][0:3];

    assign dbg_rdata = rf[{dbg_warp, dbg_reg}];

    // ==================================================================
    // branch predictor + fetch arbitration (F0/F1)
    // ==================================================================
    reg  [WARP_W-1:0] f_warp;
    reg               f_valid;
    reg  [WARP_W-1:0] fetch_rr;

    wire        bp_t0, bp_t1;
    wire [31:0] bp_tg0, bp_tg1;

    // resolve-side update wires (driven by INT pipe EX1, declared early)
    reg               bru_valid;
    reg  [WARP_W-1:0] bru_warp;
    reg  [31:0]       bru_pc;
    reg               bru_taken;
    reg  [31:0]       bru_target;

    titan_x7_branch_predictor #(
        .NUM_WARPS(NUM_WARPS), .WARP_W(WARP_W)
    ) u_bp (
        .clk(clk), .rst_n(rst_n),
        .p_warp(f_warp),
        .p_pc0(f_valid ? fetch_pc[f_warp] : 32'd0),
        .p_pc1(f_valid ? (fetch_pc[f_warp] + 32'd4) : 32'd4),
        .p_taken0(bp_t0), .p_target0(bp_tg0),
        .p_taken1(bp_t1), .p_target1(bp_tg1),
        .u_valid(bru_valid), .u_warp(bru_warp), .u_pc(bru_pc),
        .u_taken(bru_taken), .u_target(bru_target)
    );

    // pick a warp to fetch for: live (for at least one full cycle, so the
    // activation-edge epoch flip has settled), no outstanding fetch,
    // ibuf room
    always @(*) begin
        f_valid = 1'b0;
        f_warp  = {WARP_W{1'b0}};
        for (fsi = 0; fsi < NUM_WARPS; fsi = fsi + 1) begin : f_scan
            reg [WARP_W-1:0] w;
            w = fetch_rr + fsi[WARP_W-1:0];
            if (!f_valid && warp_active[w] && prev_active[w] && !pend[w] &&
                !warp_retired[w] && ib_cnt[w] <= (IB_DEPTH-2)) begin
                f_valid = 1'b1;
                f_warp  = w;
            end
        end
    end

    always @(*) begin
        imem_req_valid = f_valid;
        imem_req_warp  = f_warp;
        imem_req_pc    = fetch_pc[f_warp];
    end

    // ==================================================================
    // issue stage: per-warp head decode + readiness + GTO selection
    // ==================================================================
    wire [NUM_WARPS*64-1:0] sb_busy_flat;

    // writeback clear wires (declared early, driven by the pipes)
    reg               wb_int_v;
    reg  [WARP_W-1:0] wb_int_w;
    reg  [5:0]        wb_int_rd;
    reg               wb_fp_v;
    reg  [WARP_W-1:0] wb_fp_w;
    reg  [5:0]        wb_fp_rd;
    reg               wb_mem_v;
    reg  [WARP_W-1:0] wb_mem_w;
    reg  [5:0]        wb_mem_rd;

    // issue-side sets (driven below)
    reg               is0_sets, is1_sets;
    reg  [WARP_W-1:0] is0_warp_r, is1_warp_r;
    reg  [5:0]        is0_rd_r, is1_rd_r;

    titan_x7_scoreboard #(
        .NUM_WARPS(NUM_WARPS), .WARP_W(WARP_W)
    ) u_sb (
        .clk(clk), .rst_n(rst_n),
        .set0_en(is0_sets), .set0_warp(is0_warp_r), .set0_reg(is0_rd_r),
        .set1_en(is1_sets), .set1_warp(is1_warp_r), .set1_reg(is1_rd_r),
        .clr0_en(wb_int_v), .clr0_warp(wb_int_w), .clr0_reg(wb_int_rd),
        .clr1_en(wb_fp_v),  .clr1_warp(wb_fp_w),  .clr1_reg(wb_fp_rd),
        .clr2_en(wb_mem_v), .clr2_warp(wb_mem_w), .clr2_reg(wb_mem_rd),
        .busy_flat(sb_busy_flat)
    );

    // head decode per warp
    wire [31:0] head_inst [0:NUM_WARPS-1];
    wire [31:0] head_pc   [0:NUM_WARPS-1];
    wire        head_pt   [0:NUM_WARPS-1];
    wire [31:0] head_tg   [0:NUM_WARPS-1];
    wire        head_ep   [0:NUM_WARPS-1];
    wire        head_vld  [0:NUM_WARPS-1];

    wire [4:0]  d_op   [0:NUM_WARPS-1];
    wire [5:0]  d_rd   [0:NUM_WARPS-1];
    wire [5:0]  d_rs1  [0:NUM_WARPS-1];
    wire [5:0]  d_rs2  [0:NUM_WARPS-1];
    wire [5:0]  d_rs3  [0:NUM_WARPS-1];
    wire [15:0] d_imm  [0:NUM_WARPS-1];
    wire        d_uimm [0:NUM_WARPS-1];
    wire        d_br   [0:NUM_WARPS-1];
    wire        d_ld   [0:NUM_WARPS-1];
    wire        d_st   [0:NUM_WARPS-1];
    wire        d_alu  [0:NUM_WARPS-1];
    wire        d_wmma [0:NUM_WARPS-1];
    wire        d_sfu  [0:NUM_WARPS-1];
    wire        d_atom [0:NUM_WARPS-1];
    wire        d_barr [0:NUM_WARPS-1];
    wire        d_predicated [0:NUM_WARPS-1];
    wire [1:0]  d_preg [0:NUM_WARPS-1];

    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : g_dec
            assign {head_ep[g], head_pt[g], head_tg[g], head_pc[g], head_inst[g]}
                       = ibuf[g][ib_rd[g]];
            assign head_vld[g] = (ib_cnt[g] != 0) && (head_ep[g] == epoch[g]);

            titan_x5_decoder u_dec (
                .inst(head_inst[g]),
                .opcode(d_op[g]), .rd(d_rd[g]),
                .rs1(d_rs1[g]), .rs2(d_rs2[g]), .rs3(d_rs3[g]),
                .imm(d_imm[g]), .use_imm(d_uimm[g]),
                .is_branch(d_br[g]), .is_mem_load(d_ld[g]),
                .is_mem_store(d_st[g]), .is_alu(d_alu[g]),
                .is_valid(), .is_wmma(d_wmma[g]), .is_sfu(d_sfu[g]),
                .is_atomic(d_atom[g]), .is_barrier(d_barr[g]),
                .is_predicated(d_predicated[g]), .pred_reg(d_preg[g])
            );
        end
    endgenerate

    // classification + readiness
    wire is_fp_op [0:NUM_WARPS-1];
    wire [1:0] head_class [0:NUM_WARPS-1];
    wire writes_rd [0:NUM_WARPS-1];
    wire d_exit [0:NUM_WARPS-1];
    wire [NUM_WARPS-1:0] issueable;
    wire [2*NUM_WARPS-1:0] head_pipe_flat;

    generate
        for (g = 0; g < NUM_WARPS; g = g + 1) begin : g_cls
            // FP pipe ops: FADD(16) FMUL(17) FFMA(29). FMIN/FMAX/CVT run in
            // the INT pipe's comparators/shifters.
            //
            // ISA SEMANTICS: opcode 15 is TX6_OP_FMA, the *INTEGER* fma
            // (`rd = rs1*rs2 + rs3`), and fp32 fused multiply-add is
            // TX6_OP_FFMA = 29 (driver/titan_x6_isa.h; titan_x5_alu's
            // OP_IFMA=15 / OP_FPFMA=29). This module had 15 routed to the FP
            // pipe and executed 29 as an RSQRT seed -- a transcendental that
            // the ISA deleted when FP FMA took slot 29 (see the opcode-21
            // decision in docs/HANDOFF_NEXT_SESSION.md). Both were wrong.
            assign is_fp_op[g] = (d_op[g] == 5'd16) || (d_op[g] == 5'd17) ||
                                 (d_op[g] == 5'd29);

            // EXIT is BARRIER with use_imm && imm == 0xFFF (TX6_EXIT_IMM,
            // same convention as titan_x5_pipeline). A plain BARRIER is
            // thread sync, not termination.
            assign d_exit[g] = d_barr[g] && d_uimm[g] && (d_imm[g] == 16'h0FFF);
            assign head_class[g] = (d_ld[g] || d_st[g] || d_atom[g]) ? CL_MEM :
                                   is_fp_op[g]                       ? CL_FP  :
                                   (d_wmma[g] || d_barr[g])          ? CL_OTH :
                                                                       CL_INT;
            assign head_pipe_flat[g*2 +: 2] = head_class[g];

            assign writes_rd[g] = (d_alu[g] && d_op[g] != 5'd21) // not SETP
                                  || d_ld[g] || d_sfu[g];

            // busy view with same-cycle writeback forwarding
            wire [63:0] bz_raw = sb_busy_flat[g*64 +: 64];
            wire [63:0] bz =
                bz_raw & ~((wb_int_v && wb_int_w == g) ? (64'd1 << wb_int_rd) : 64'd0)
                       & ~((wb_fp_v  && wb_fp_w  == g) ? (64'd1 << wb_fp_rd)  : 64'd0)
                       & ~((wb_mem_v && wb_mem_w == g) ? (64'd1 << wb_mem_rd) : 64'd0);

            // stores read their data from the rd field (the imm mode
            // consumes the rs2/rs3 fields), so rd is a source for them
            wire deps_ok = !bz[d_rs1[g]] &&
                           (d_uimm[g] || !bz[d_rs2[g]]) &&
                           (d_uimm[g] || !bz[d_rs3[g]]) &&
                           ((!writes_rd[g] && !d_st[g]) || !bz[d_rd[g]]);

            assign issueable[g] =
                warp_active[g] && !warp_retired[g] && head_vld[g] && deps_ok &&
                !branch_shadow[g] && (pred_pending[g] == 2'd0) &&
                !barrier_wait[g] &&
                !(head_class[g] == CL_MEM && lsu_busy);
        end
    endgenerate

    wire        sel0_v, sel1_v;
    wire [WARP_W-1:0] sel0_w, sel1_w;

    titan_x7_warp_scheduler #(
        .NUM_WARPS(NUM_WARPS), .WARP_W(WARP_W)
    ) u_sched (
        .clk(clk), .rst_n(rst_n),
        .issueable(issueable),
        .head_pipe(head_pipe_flat),
        .sel0_valid(sel0_v), .sel0_warp(sel0_w),
        .sel1_valid(sel1_v), .sel1_warp(sel1_w)
    );

    // ==================================================================
    // IS -> RF pipeline registers (two slots)
    // ==================================================================
    reg        s_valid [0:1];
    reg [WARP_W-1:0] s_warp [0:1];
    reg [4:0]  s_op   [0:1];
    reg [5:0]  s_rd   [0:1];
    reg [5:0]  s_rs1  [0:1];
    reg [5:0]  s_rs2  [0:1];
    reg [5:0]  s_rs3  [0:1];
    reg [15:0] s_imm  [0:1];
    reg        s_uimm [0:1];
    reg [1:0]  s_class[0:1];
    reg [31:0] s_pc   [0:1];
    reg        s_pt   [0:1];
    reg [31:0] s_ptg  [0:1];
    reg        s_br   [0:1];
    reg        s_ld   [0:1];
    reg        s_st   [0:1];
    reg        s_wrd  [0:1];
    reg [1:0]  s_preg [0:1];

    // slot metadata for the sequential block
    reg [WARP_W-1:0] iw;
    reg [1:0] slot_sel;

    // issue-side scoreboard sets
    always @(*) begin
        is0_sets   = sel0_v && writes_rd[sel0_w];
        is0_warp_r = sel0_w;
        is0_rd_r   = d_rd[sel0_w];
        is1_sets   = sel1_v && writes_rd[sel1_w];
        is1_warp_r = sel1_w;
        is1_rd_r   = d_rd[sel1_w];
    end

    // ==================================================================
    // RF -> EX registers, per pipe
    // ==================================================================
    // INT pipe input
    reg               xi_v;
    reg [WARP_W-1:0]  xi_w;
    reg [4:0]         xi_op;
    reg [5:0]         xi_rd;
    reg [LANES*32-1:0] xi_a, xi_b, xi_c;
    reg [LANES-1:0]   xi_mask;
    reg [31:0]        xi_pc;
    reg               xi_br, xi_pt;
    reg [31:0]        xi_ptg;
    reg [15:0]        xi_imm;
    reg               xi_uimm;

    // FP pipe input
    reg               xf_v;
    reg [WARP_W-1:0]  xf_w;
    reg [4:0]         xf_op;
    reg [5:0]         xf_rd;
    reg [LANES*32-1:0] xf_a, xf_b, xf_c;
    reg [LANES-1:0]   xf_mask;

    // MEM pipe input
    reg               xm_v;
    reg [WARP_W-1:0]  xm_w;
    reg [5:0]         xm_rd;
    reg               xm_st;
    reg [LANES*32-1:0] xm_base, xm_off, xm_data;
    reg [LANES-1:0]   xm_mask;
    reg [15:0]        xm_imm;
    reg               xm_uimm;

    // ==================================================================
    // INT pipe: X1 (light ALU / branch / cmp / cvt-prep) -> X2 (mul,
    // cvt-finish, select) -> WB
    // ==================================================================
    // FP32 total-order key for FMIN/FMAX
    function [31:0] fp_key;
        input [31:0] x;
        begin
            fp_key = x[31] ? ~x : (x ^ 32'h80000000);
        end
    endfunction

    function [31:0] int_alu1;      // 1-cycle lane ops
        input [4:0]  op;
        input [31:0] a;
        input [31:0] b;
        begin
            case (op)
                5'd0:  int_alu1 = a + b;
                5'd1:  int_alu1 = a - b;
                5'd5:  int_alu1 = a & b;
                5'd6:  int_alu1 = a | b;
                5'd7:  int_alu1 = a ^ b;
                5'd8:  int_alu1 = a << b[4:0];
                5'd9:  int_alu1 = a >> b[4:0];
                5'd10: int_alu1 = $signed(a) >>> b[4:0];
                5'd11: int_alu1 = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
                5'd12: int_alu1 = (a < b) ? 32'd1 : 32'd0;
                5'd13: int_alu1 = ($signed(a) < $signed(b)) ? a : b;
                5'd14: int_alu1 = ($signed(a) < $signed(b)) ? b : a;
                // FMIN/FMAX: IEEE minNum/maxNum-ish (NaN -> other operand)
                5'd18: int_alu1 = ((a[30:23]==8'hFF) && (a[22:0]!=0)) ? b :
                                  ((b[30:23]==8'hFF) && (b[22:0]!=0)) ? a :
                                  (fp_key(a) < fp_key(b)) ? a : b;
                5'd19: int_alu1 = ((a[30:23]==8'hFF) && (a[22:0]!=0)) ? b :
                                  ((b[30:23]==8'hFF) && (b[22:0]!=0)) ? a :
                                  (fp_key(a) < fp_key(b)) ? b : a;
                5'd27: int_alu1 = 32'h7FC00000;               // SIN: SW
                5'd28: int_alu1 = 32'h7FC00000;               // COS: SW
                // 29 is FFMA (fp32) and runs in the FP pipe, not here. The
                // RSQRT seed that used to sit on 29 is not in the ISA: RSQRT
                // was displaced when FP FMA took slot 29.
                default: int_alu1 = 32'd0;
            endcase
        end
    endfunction

    // SETP comparison, per TX6_CMP_* in driver/titan_x6_isa.h. The condition
    // travels in rd[4:2] and the predicate destination in rd[1:0].
    //
    // This module used to hardwire signed less-than and ignore the condition
    // field entirely, so five of the ISA's six comparisons silently executed
    // as LT. titan_x5_pipeline.v implements all six (its setp_lane_gen block
    // is the reference this mirrors), the C oracle implements all six, and
    // tb/test_compute_kernels.py::test_setp_conditions sweeps all six -- so
    // the divergence would have shown up as five failing conditions the
    // moment X7 ran that suite. 6 and 7 are unassigned and read false, which
    // is x5's behaviour too.
    function setp_cmp;
        input [2:0]  cond;
        input [31:0] a;
        input [31:0] b;
        begin
            case (cond)
                3'd0: setp_cmp = (a == b);                      // EQ
                3'd1: setp_cmp = (a != b);                      // NE
                3'd2: setp_cmp = ($signed(a) <  $signed(b));    // LT  (signed)
                3'd3: setp_cmp = ($signed(a) >= $signed(b));    // GE  (signed)
                3'd4: setp_cmp = (a <  b);                      // LTU
                3'd5: setp_cmp = (a >= b);                      // GEU
                default: setp_cmp = 1'b0;
            endcase
        end
    endfunction

    // int -> float, round-to-nearest-even
    function [31:0] i2f;
        input [31:0] x;
        reg [31:0] mag;
        reg [4:0]  msb;
        reg [31:0] norm;    // MSB normalized to bit 31
        reg [23:0] mant;
        reg        gbit, sbit;
        reg [24:0] mr;
        reg [7:0]  e;
        integer    ii;
        begin
            if (x == 32'd0) i2f = 32'd0;
            else begin
                mag = x[31] ? (~x + 32'd1) : x;
                msb = 5'd0;
                for (ii = 0; ii < 32; ii = ii + 1)
                    if (mag[ii]) msb = ii[4:0];
                norm = mag << (5'd31 - msb);   // MSB at bit 31
                mant = norm[31:8];
                gbit = norm[7];
                sbit = |norm[6:0];
                mr   = {1'b0, mant} + {24'd0, (gbit && (sbit || mant[0]))};
                e    = 8'd127 + {3'd0, msb};
                if (mr[24]) begin
                    mr = mr >> 1;
                    e  = e + 8'd1;
                end
                i2f = {x[31], e, mr[22:0]};
            end
        end
    endfunction

    // float -> int, truncate toward zero, saturating
    function [31:0] f2i;
        input [31:0] x;
        reg [7:0]  e;
        reg [23:0] m;
        reg [31:0] v;
        reg signed [9:0] sh;
        begin
            e = x[30:23];
            m = {1'b1, x[22:0]};
            if (e == 8'hFF) f2i = x[31] ? 32'h80000000 : 32'h7FFFFFFF;
            else if (e < 8'd127) f2i = 32'd0;
            else if (e > 8'd157) f2i = x[31] ? 32'h80000000 : 32'h7FFFFFFF;
            else begin
                sh = {2'd0, e} - 10'sd150;   // m * 2^sh
                if (sh >= 0) v = {8'd0, m} << sh[5:0];
                else         v = {8'd0, m} >> (-sh);
                f2i = x[31] ? (~v + 32'd1) : v;
            end
        end
    endfunction

    // X1 stage registers
    reg               x1_v;
    reg [WARP_W-1:0]  x1_w;
    reg [4:0]         x1_op;
    reg [5:0]         x1_rd;
    reg [LANES*32-1:0] x1_res;
    reg [LANES*32-1:0] x1_a, x1_b, x1_c;   // x1_c: rs3, for integer FMA
    reg [LANES-1:0]   x1_mask;
    reg               x1_setp;
    reg [1:0]         x1_ppos;
    reg [LANES-1:0]   x1_pval;
    reg               x1_writes;

    // ==================================================================
    // FP pipe: LANES x 8-stage FMA + sideband queue
    // ==================================================================
    wire [LANES*32-1:0] fp_res;
    wire [LANES-1:0]    fp_vout;

    reg [31:0] fp_a_in [0:LANES-1];
    reg [31:0] fp_b_in [0:LANES-1];
    reg [31:0] fp_c_in [0:LANES-1];

    always @(*) begin
        for (fmi = 0; fmi < LANES; fmi = fmi + 1) begin
            case (xf_op)
                5'd29: begin  // FFMA (fp32): a*b + c
                    fp_a_in[fmi] = xf_a[fmi*32 +: 32];
                    fp_b_in[fmi] = xf_b[fmi*32 +: 32];
                    fp_c_in[fmi] = xf_c[fmi*32 +: 32];
                end
                5'd16: begin  // FADD: a*1.0 + b
                    fp_a_in[fmi] = xf_a[fmi*32 +: 32];
                    fp_b_in[fmi] = 32'h3F800000;
                    fp_c_in[fmi] = xf_b[fmi*32 +: 32];
                end
                default: begin // FMUL: a*b + (sign-matched 0)
                    fp_a_in[fmi] = xf_a[fmi*32 +: 32];
                    fp_b_in[fmi] = xf_b[fmi*32 +: 32];
                    fp_c_in[fmi] = {xf_a[fmi*32+31] ^ xf_b[fmi*32+31], 31'd0};
                end
            endcase
        end
    end

    generate
        for (gl = 0; gl < LANES; gl = gl + 1) begin : g_fma
            titan_x7_fp32_fma_pipe u_fma (
                .clk(clk), .rst_n(rst_n), .en(1'b1),
                .valid_in(xf_v),
                .rm(2'b00),
                .a(fp_a_in[gl]), .b(fp_b_in[gl]), .c(fp_c_in[gl]),
                .valid_out(fp_vout[gl]),
                .result(fp_res[gl*32 +: 32]),
                .flag_invalid(), .flag_overflow(),
                .flag_underflow(), .flag_inexact()
            );
        end
    endgenerate

    // sideband: warp/rd/mask travel alongside the FMA pipe
    reg [WARP_W-1:0] fq_w [0:FP_LAT-1];
    reg [5:0]        fq_rd [0:FP_LAT-1];
    reg [LANES-1:0]  fq_mask [0:FP_LAT-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (fqi = 0; fqi < FP_LAT; fqi = fqi + 1) begin
                fq_w[fqi] <= 0; fq_rd[fqi] <= 0; fq_mask[fqi] <= 0;
            end
        end else begin
            fq_w[0]    <= xf_w;
            fq_rd[0]   <= xf_rd;
            fq_mask[0] <= xf_mask;
            for (fqi = 1; fqi < FP_LAT; fqi = fqi + 1) begin
                fq_w[fqi]    <= fq_w[fqi-1];
                fq_rd[fqi]   <= fq_rd[fqi-1];
                fq_mask[fqi] <= fq_mask[fqi-1];
            end
        end
    end

    // ==================================================================
    // MEM pipe: AGU -> request hold -> response
    // ==================================================================
    reg               mq_pend;      // request awaiting dmem acceptance
    reg               mq_write;
    reg [WARP_W-1:0]  mq_w;
    reg [5:0]         mq_rd;
    reg [LANES-1:0]   mq_mask;
    reg [LANES*32-1:0] mq_addr, mq_wdata;
    reg               mo_load;      // outstanding load
    reg [WARP_W-1:0]  mo_w;
    reg [5:0]         mo_rd;
    reg [LANES-1:0]   mo_mask;

    assign dmem_req_valid = mq_pend;
    assign dmem_req_write = mq_write;
    assign dmem_req_warp  = mq_w;
    assign dmem_req_mask  = mq_mask;
    assign dmem_req_addr  = mq_addr;
    assign dmem_req_wdata = mq_wdata;

    // ==================================================================
    // main sequential machinery
    // ==================================================================
    reg [63:0] pair;
    reg [31:0] rpc;
    // blocking temps for unified per-warp ibuf count accounting
    reg [1:0]        f2_push_n;
    reg [WARP_W-1:0] f2_push_w;
    // blocking temps for branch resolution
    reg               mp_flush;
    reg [WARP_W-1:0]  mp_warp;
    reg               mp_tk;
    reg [31:0]        mp_tgt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // blocking assigns: reset-only array init (see L2 note on
            // Verilator BLKLOOPINIT)
            for (i = 0; i < NUM_WARPS*64; i = i + 1)
                rf[i] = {LANES*32{1'b0}};
            for (i = 0; i < NUM_WARPS; i = i + 1) begin
                fetch_pc[i] <= 32'd0;
                epoch[i] <= 1'b0;
                pend[i] <= 1'b0;
                pend_epoch[i] <= 1'b0;
                pend_drop1[i] <= 1'b0;
                pend_pt0[i] <= 1'b0; pend_tg0[i] <= 32'd0;
                pend_pt1[i] <= 1'b0; pend_tg1[i] <= 32'd0;
                pend_pc[i] <= 32'd0;
                ib_rd[i] <= 3'd0;
                ib_wr[i] <= 3'd0;
                ib_cnt[i] <= 4'd0;
                pred_pending[i] <= 2'd0;
                preds[i][0] <= {LANES{1'b1}};
                preds[i][1] <= {LANES{1'b0}};
                preds[i][2] <= {LANES{1'b0}};
                preds[i][3] <= {LANES{1'b0}};
            end
            prev_active <= {NUM_WARPS{1'b0}};
            branch_shadow <= {NUM_WARPS{1'b0}};
            barrier_wait <= {NUM_WARPS{1'b0}};
            warp_retired <= {NUM_WARPS{1'b0}};
            lsu_busy <= 1'b0;
            fetch_rr <= {WARP_W{1'b0}};
            s_valid[0] <= 1'b0; s_valid[1] <= 1'b0;
            xi_v <= 1'b0; xf_v <= 1'b0; xm_v <= 1'b0;
            x1_v <= 1'b0;
            mq_pend <= 1'b0; mo_load <= 1'b0;
            bru_valid <= 1'b0;
            wb_int_v <= 1'b0; wb_fp_v <= 1'b0; wb_mem_v <= 1'b0;
            wmma_valid <= 1'b0;
            dbg_retired <= 32'd0;
            wb_export_valid <= 1'b0;
            warp_exit_valid <= 1'b0;
            warp_exit_warp <= {WARP_W{1'b0}};
        end else begin
            // defaults
            bru_valid <= 1'b0;
            wmma_valid <= 1'b0;
            f2_push_n = 2'd0;
            f2_push_w = {WARP_W{1'b0}};

            // ----------------------------------------------------------
            // branch resolution, evaluated early so the outcome is
            // available to the stages below in the same cycle
            mp_flush = 1'b0;
            mp_warp  = {WARP_W{1'b0}};
            mp_tk    = 1'b0;
            mp_tgt   = 32'd0;
            if (xi_v && xi_br) begin
                // ISA SEMANTICS: BRANCH is UNCONDITIONAL, gated only by its
                // PREDICATE. It does not read rs1. This module used to compute
                //     mp_tk = (xi_a[31:0] != 32'd0);
                // a "branch if rs1 != 0" rule that exists nowhere in the ISA
                // -- the fourth divergence found in this core, and the first
                // one caught by a test rather than by reading (see
                // docs/X7_ISA_CONFORMANCE.md). The other three definitions
                // agree with each other and not with that:
                //   driver/titan_x6_isa.h      pc = imm; honors pred
                //   driver/titan_x6_gpu_model.c  next_pc = imm  (no reg read)
                //   rtl/core/titan_x5_pipeline.v pc_redirect_valid =
                //                                  id_exec && dec_is_branch,
                //                                where id_exec folds in the
                //                                predicate and nothing else
                //
                // The condition mechanism in this ISA is SETP writing P1..P3,
                // not a register compare. BRANCH's rs1 field is unused, so a
                // compiled `BRANCH #target` encodes rs1 = R0 -- which reads
                // zero, so the old rule made every compiled unconditional
                // branch fall through. In the full-chip render test that ran
                // the poison instruction the branch exists to skip: 117 of
                // 181 pixels came back wrong-path.
                //
                // x5 takes the branch iff the predicate is uniformly true
                // (titan_x5_pipeline.v: id_pred_ok = id_pred_all_true); a
                // divergent or all-false mask falls through. xi_mask is this
                // instruction's per-lane predicate (P0 is all-ones), so the
                // reduction AND reproduces that rule exactly.
                mp_tk   = &xi_mask;
                mp_tgt  = {18'd0, xi_imm[11:0], 2'b00};
                mp_warp = xi_w;
                if (mp_tk != xi_pt || (mp_tk && mp_tgt != xi_ptg))
                    mp_flush = 1'b1;
            end

            // ----------------------------------------------------------
            // warp activation edges
            // ----------------------------------------------------------
            prev_active <= warp_active;
            for (i = 0; i < NUM_WARPS; i = i + 1) begin
                if (warp_active[i] && !prev_active[i]) begin
                    fetch_pc[i] <= warp_pc_in[i*32 +: 32];
                    epoch[i]    <= ~epoch[i];
                    pend[i]     <= 1'b0;   // cancel any in-flight fetch
                    ib_rd[i]    <= 3'd0;
                    ib_wr[i]    <= 3'd0;
                    ib_cnt[i]   <= 4'd0;
                    warp_retired[i] <= 1'b0;
                end
            end

            // ----------------------------------------------------------
            // F1: fetch request accepted -> record prediction, advance pc
            // ----------------------------------------------------------
            if (f_valid && imem_req_ready) begin
                pend[f_warp]       <= 1'b1;
                pend_epoch[f_warp] <= epoch[f_warp];
                pend_pc[f_warp]    <= fetch_pc[f_warp];
                pend_pt0[f_warp]   <= bp_t0;
                pend_tg0[f_warp]   <= bp_tg0;
                pend_pt1[f_warp]   <= bp_t1 && !bp_t0;
                pend_tg1[f_warp]   <= bp_tg1;
                pend_drop1[f_warp] <= bp_t0;
                fetch_pc[f_warp]   <= bp_t0 ? bp_tg0 :
                                      (bp_t1 ? bp_tg1 : fetch_pc[f_warp] + 32'd8);
                fetch_rr           <= f_warp + {{(WARP_W-1){1'b0}}, 1'b1};
            end

            // ----------------------------------------------------------
            // F2: fetch response -> push into ibuf (drop stale epochs)
            // ----------------------------------------------------------
            if (imem_resp_valid) begin : f2
                reg [WARP_W-1:0] rw;
                rw = imem_resp_warp;
                if (!(warp_active[rw] && !prev_active[rw]))
                    pend[rw] <= 1'b0;
                if (pend[rw] && pend_epoch[rw] == epoch[rw] &&
                    !(warp_active[rw] && !prev_active[rw])) begin
                    pair = imem_resp_data;
                    rpc  = pend_pc[rw];
                    ibuf[rw][ib_wr[rw]] <= {epoch[rw], pend_pt0[rw],
                                            pend_tg0[rw], rpc, pair[31:0]};
                    f2_push_w = rw;
                    if (!pend_drop1[rw]) begin
                        ibuf[rw][ib_wr[rw]+3'd1] <= {epoch[rw], pend_pt1[rw],
                                                     pend_tg1[rw], rpc+32'd4,
                                                     pair[63:32]};
                        ib_wr[rw] <= ib_wr[rw] + 3'd2;
                        f2_push_n = 2'd2;
                    end else begin
                        ib_wr[rw] <= ib_wr[rw] + 3'd1;
                        f2_push_n = 2'd1;
                    end
                end
            end

            // ----------------------------------------------------------
            // IS: pop issued heads / drop stale heads; unified per-warp
            // count update (push and pop may coincide in one cycle)
            // ----------------------------------------------------------
            for (i = 0; i < NUM_WARPS; i = i + 1) begin : ib_upd
                reg pop1;
                pop1 = 1'b0;
                if ((sel0_v && {29'd0, sel0_w} == i) ||
                    (sel1_v && {29'd0, sel1_w} == i)) begin
                    pop1 = 1'b1;
                end else if (ib_cnt[i] != 0 && head_ep[i] != epoch[i]) begin
                    pop1 = 1'b1;   // stale (flushed) entry: discard
                end
                if (pop1)
                    ib_rd[i] <= ib_rd[i] + 3'd1;
                // activation reset (above) must win over this update
                if (!(warp_active[i] && !prev_active[i]))
                    ib_cnt[i] <= ib_cnt[i]
                                 + ((f2_push_n != 0 && {29'd0, f2_push_w} == i)
                                    ? {2'd0, f2_push_n} : 4'd0)
                                 - (pop1 ? 4'd1 : 4'd0);
            end

            warp_exit_valid <= 1'b0;
            for (j = 0; j < 2; j = j + 1) begin : is_latch
                reg v;
                v  = (j == 0) ? sel0_v : sel1_v;
                iw = (j == 0) ? sel0_w : sel1_w;
                s_valid[j] <= v;
                if (v) begin
`ifdef X7_TRACE
                    $display("[%0t] ISSUE w%0d pc=%h op=%0d rd=%0d cls=%0d cnt=%0d",
                             $time, iw, head_pc[iw], d_op[iw], d_rd[iw],
                             head_class[iw], ib_cnt[iw]);
`endif
                    s_warp[j] <= iw;
                    s_op[j]   <= d_op[iw];
                    s_rd[j]   <= d_rd[iw];
                    s_rs1[j]  <= d_rs1[iw];
                    s_rs2[j]  <= d_rs2[iw];
                    s_rs3[j]  <= d_rs3[iw];
                    s_imm[j]  <= d_imm[iw];
                    s_uimm[j] <= d_uimm[iw];
                    s_class[j]<= head_class[iw];
                    s_pc[j]   <= head_pc[iw];
                    s_pt[j]   <= head_pt[iw];
                    s_ptg[j]  <= head_tg[iw];
                    s_br[j]   <= d_br[iw];
                    s_ld[j]   <= d_ld[iw];
                    s_st[j]   <= d_st[iw];
                    s_wrd[j]  <= writes_rd[iw];
                    s_preg[j] <= d_preg[iw];

                    // interlocks
                    if (d_br[iw])            branch_shadow[iw] <= 1'b1;
                    if (d_op[iw] == 5'd21)   pred_pending[iw]  <= 2'd3;
                    if (head_class[iw] == CL_MEM) lsu_busy     <= 1'b1;
                    if (d_exit[iw]) begin
                        warp_retired[iw] <= 1'b1;
                        warp_exit_valid  <= 1'b1;
                        warp_exit_warp   <= iw;
                    end else if (d_barr[iw]) begin
                        barrier_wait[iw] <= 1'b1;
                    end
                end
            end

            dbg_retired <= dbg_retired + (sel0_v ? 32'd1 : 32'd0)
                                       + (sel1_v ? 32'd1 : 32'd0);

            // barrier release: every active warp waiting -> clear all
            if (warp_active != 0 && ((barrier_wait & warp_active) == warp_active))
                barrier_wait <= {NUM_WARPS{1'b0}};

            // SETP interlock countdown
            for (i = 0; i < NUM_WARPS; i = i + 1)
                if (pred_pending[i] != 2'd0)
                    pred_pending[i] <= pred_pending[i] - 2'd1;

            // ----------------------------------------------------------
            // RF: read operands, steer each slot to its pipe
            // ----------------------------------------------------------
            xi_v <= 1'b0;
            xf_v <= 1'b0;
            xm_v <= 1'b0;
            for (j = 0; j < 2; j = j + 1) begin : rf_stage
                reg [LANES*32-1:0] o1, o2, o3;
                reg [LANES-1:0] lm;
                if (s_valid[j]) begin
                    o1 = rf[{s_warp[j], s_rs1[j]}];
                    o2 = s_uimm[j] ? {LANES{ {16'd0, s_imm[j]} }}
                                   : rf[{s_warp[j], s_rs2[j]}];
                    o3 = rf[{s_warp[j], s_rs3[j]}];
                    lm = preds[s_warp[j]][s_preg[j]];
                    case (s_class[j])
                        CL_INT: begin
                            xi_v    <= 1'b1;
                            xi_w    <= s_warp[j];
                            xi_op   <= s_op[j];
                            xi_rd   <= s_rd[j];
                            xi_a    <= o1;
                            xi_b    <= o2;
                            xi_c    <= o3;
                            xi_mask <= lm;
                            xi_pc   <= s_pc[j];
                            xi_br   <= s_br[j];
                            xi_pt   <= s_pt[j];
                            xi_ptg  <= s_ptg[j];
                            xi_imm  <= s_imm[j];
                            xi_uimm <= s_uimm[j];
                        end
                        CL_FP: begin
                            xf_v    <= 1'b1;
                            xf_w    <= s_warp[j];
                            xf_op   <= s_op[j];
                            xf_rd   <= s_rd[j];
                            xf_a    <= o1;
                            xf_b    <= o2;
                            xf_c    <= o3;
                            xf_mask <= lm;
                        end
                        CL_MEM: begin
                            xm_v    <= 1'b1;
                            xm_w    <= s_warp[j];
                            xm_rd   <= s_rd[j];
                            xm_st   <= s_st[j];
                            xm_base <= o1;
                            xm_off  <= o2;
                            xm_data <= s_st[j] ? rf[{s_warp[j], s_rd[j]}] : o3;
                            xm_mask <= lm;
                            xm_imm  <= s_imm[j];
                            xm_uimm <= s_uimm[j];
                        end
                        default: begin // WMMA export / barrier
                            if (s_op[j] == 5'd26) begin
                                wmma_valid <= 1'b1;
                                wmma_warp  <= s_warp[j];
                                wmma_a     <= o1;
                                wmma_b     <= o2;
                            end
                        end
                    endcase
                end
            end

            // ----------------------------------------------------------
            // INT pipe X1
            // ----------------------------------------------------------
            x1_v <= xi_v;
            if (xi_v) begin
                x1_w    <= xi_w;
                x1_op   <= xi_op;
                x1_rd   <= xi_rd;
                x1_mask <= xi_mask;
                x1_a    <= xi_a;
                x1_b    <= xi_b;
                x1_c    <= xi_c;
                x1_setp <= (xi_op == 5'd21);
                x1_ppos <= xi_rd[1:0];
                x1_writes <= !(xi_op == 5'd21) && !xi_br;
                for (i = 0; i < LANES; i = i + 1) begin
                    x1_res[i*32 +: 32] <= int_alu1(xi_op, xi_a[i*32 +: 32],
                                                   xi_b[i*32 +: 32]);
                    // SETP condition code lives in rd[4:2]; rd[1:0] is the
                    // predicate destination and is latched into x1_ppos.
                    x1_pval[i] <= setp_cmp(xi_rd[4:2], xi_a[i*32 +: 32],
                                                       xi_b[i*32 +: 32]);
                end

                // branch resolution (lane 0 of rs1)
                //
                // ISA SEMANTICS: the target is an ABSOLUTE INSTRUCTION INDEX,
                // not a PC-relative offset. This module originally computed
                // `xi_pc + sext(imm12)<<2`, which disagreed with every other
                // component that defines the ISA:
                //   compiler/titan_compiler.py  words[idx] |= (lbl.pc & 0xFFF) << 3
                //   driver/titan_x6_gpu_model.c next_pc = imm
                //   rtl/core/titan_x5_pipeline.v pc_redirect_pc = {16'd0, dec_imm}
                // X7 was developed standalone against tests that used its own
                // relative encoding, so nothing caught the divergence. Every
                // compiled kernel would have branched to the wrong address.
                // PCs are bytes inside this module, so index -> byte is <<2.
                if (xi_br) begin : bres
                    branch_shadow[xi_w] <= 1'b0;
                    bru_valid  <= 1'b1;
                    bru_warp   <= xi_w;
                    bru_pc     <= xi_pc;
                    bru_taken  <= mp_tk;
                    bru_target <= mp_tgt;
                    if (mp_flush) begin
                        // epoch flip still drops the in-flight fetch response
                        // (F2 checks pend_epoch); the ibuf itself was cleared
                        // above, which is what makes recovery unambiguous.
                        epoch[xi_w]    <= ~epoch[xi_w];
                        fetch_pc[xi_w] <= mp_tk ? mp_tgt : (xi_pc + 32'd4);
                    end
                end
            end

            // ----------------------------------------------------------
            // INT pipe X2 -> WB port 0
            // ----------------------------------------------------------
            wb_int_v <= 1'b0;
            wb_export_valid <= 1'b0;
            if (x1_v) begin
                if (x1_setp) begin
                    if (x1_ppos != 2'd0)
                        preds[x1_w][x1_ppos] <= x1_pval;
                end else if (x1_writes) begin : x2
                    reg [LANES*32-1:0] r2;
                    reg [LANES*32-1:0] wword;
                    for (i = 0; i < LANES; i = i + 1) begin
                        case (x1_op)
                            5'd2: r2[i*32 +: 32] =
                                x1_a[i*32 +: 32] * x1_b[i*32 +: 32];
                            5'd3: begin : mh
                                reg [63:0] p64;
                                p64 = {32'd0, x1_a[i*32 +: 32]} *
                                      {32'd0, x1_b[i*32 +: 32]};
                                r2[i*32 +: 32] = p64[63:32];
                            end
                            5'd20: r2[i*32 +: 32] =
                                x1_b[0] ? f2i(x1_a[i*32 +: 32])
                                        : i2f(x1_a[i*32 +: 32]);
                            // TX6_OP_FMA: INTEGER fma, rd = rs1*rs2 + rs3
                            5'd15: r2[i*32 +: 32] =
                                x1_a[i*32 +: 32] * x1_b[i*32 +: 32] +
                                x1_c[i*32 +: 32];
                            5'd4:  r2[i*32 +: 32] = 32'd0;  // DIV: SW
                            default: r2[i*32 +: 32] = x1_res[i*32 +: 32];
                        endcase
                    end
                    wb_int_v  <= 1'b1;
                    wb_int_w  <= x1_w;
                    wb_int_rd <= x1_rd;
                    // whole-word RMW: lane-masked merge, single array NBA
                    wword = rf[{x1_w, x1_rd}];
                    for (i = 0; i < LANES; i = i + 1)
                        if (x1_mask[i])
                            wword[i*32 +: 32] = r2[i*32 +: 32];
                    rf[{x1_w, x1_rd}] <= wword;
                    wb_export_valid <= 1'b1;
                    wb_export_reg   <= x1_rd;
                    wb_export_data  <= wword;
                end
            end

            // ----------------------------------------------------------
            // FP pipe WB port 1
            // ----------------------------------------------------------
            wb_fp_v <= 1'b0;
            if (fp_vout[0]) begin : fpwb
                reg [LANES*32-1:0] wword;
                wb_fp_v  <= 1'b1;
                wb_fp_w  <= fq_w[FP_LAT-1];
                wb_fp_rd <= fq_rd[FP_LAT-1];
                wword = rf[{fq_w[FP_LAT-1], fq_rd[FP_LAT-1]}];
                for (i = 0; i < LANES; i = i + 1)
                    if (fq_mask[FP_LAT-1][i])
                        wword[i*32 +: 32] = fp_res[i*32 +: 32];
                rf[{fq_w[FP_LAT-1], fq_rd[FP_LAT-1]}] <= wword;
            end

            // ----------------------------------------------------------
            // MEM pipe: AGU -> request -> response, WB port 2
            // ----------------------------------------------------------
            if (xm_v) begin
                mq_pend  <= 1'b1;
                mq_write <= xm_st;
                mq_w     <= xm_w;
                mq_rd    <= xm_rd;
                mq_mask  <= xm_mask;
                mq_wdata <= xm_data;
                for (i = 0; i < LANES; i = i + 1)
                    mq_addr[i*32 +: 32] <= xm_base[i*32 +: 32] +
                        (xm_uimm ? {16'd0, xm_imm} : xm_off[i*32 +: 32]);
            end
            if (mq_pend && dmem_req_ready) begin
                mq_pend <= 1'b0;
                if (mq_write) begin
                    lsu_busy <= 1'b0;         // stores retire at acceptance
                end else begin
                    mo_load <= 1'b1;
                    mo_w    <= mq_w;
                    mo_rd   <= mq_rd;
                    mo_mask <= mq_mask;
                end
            end
            wb_mem_v <= 1'b0;
            if (dmem_resp_valid && mo_load) begin : memwb
                reg [LANES*32-1:0] wword;
                mo_load  <= 1'b0;
                lsu_busy <= 1'b0;
                wb_mem_v  <= 1'b1;
                wb_mem_w  <= mo_w;
                wb_mem_rd <= mo_rd;
                wword = rf[{mo_w, mo_rd}];
                for (i = 0; i < LANES; i = i + 1)
                    if (mo_mask[i])
                        wword[i*32 +: 32] = dmem_resp_rdata[i*32 +: 32];
                rf[{mo_w, mo_rd}] <= wword;
            end
        end
    end

endmodule
