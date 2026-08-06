// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x5_pipeline #(
    parameter NUM_WARPS = 8
)(
    input  wire clk,
    input  wire rst_n,
    
    // interface with warp scheduler
    input wire [2:0] sched_warp_id,
    input  wire        sched_valid,
    input wire [31:0] sched_pc,   // instruction INDEX of the selected warp

    // instruction cache / memory interface
    // Base byte address of the kernel's code segment. sched_pc is an
    // instruction index (see titan_x5_pc_unit), so the fetch address is
    // code_base + pc*4 -- the same mapping the functional model uses
    // (`vram_rd32(gpu, code_addr + pc * 4)`).
    input wire [31:0] code_base,
    output wire [31:0] if_pc,
    output wire        if_req,
    input  wire        if_gnt,   // fetch accepted by the interconnect
    input wire [31:0] if_inst,
    input  wire        if_inst_valid,

    // ---- control flow, back to titan_x5_pc_unit -------------------------
    // A fetch was accepted: the PC unit advances that warp (pc + 1).
    output wire        pc_fetch_accept,
    output wire [2:0]  pc_fetch_warp,
    // Taken branch: redirect the warp to an absolute instruction index.
    output wire        pc_redirect_valid,
    output wire [2:0]  pc_redirect_warp,
    output wire [31:0] pc_redirect_pc,
    // EXIT (BARRIER with use_imm && imm == 0xFFF): retire the warp.
    output wire        pc_retire_valid,
    output wire [2:0]  pc_retire_warp,
    
    // register file interface
    // The register file is per-warp, so every access carries a warp index.
    // Reads are combinational and happen in ID, so they use the ID-stage warp;
    // writes are synchronous from WB, so they use the WB-stage warp. Getting
    // these two crossed would let one warp read another's registers.
    output wire [5:0] rf_rd_addr1,
    output wire [5:0] rf_rd_addr2,
    output wire [5:0] rf_rd_addr3,
    output wire [2:0] rf_rd_warp,
    input wire [1023:0] rf_rd_data1,
    input wire [1023:0] rf_rd_data2,
    input wire [1023:0] rf_rd_data3,

    output wire [5:0] rf_wr_addr,
    output wire [2:0] rf_wr_warp,
    output wire [1023:0] rf_wr_data,
    output wire        rf_wr_en,
    
    // alu interface
    output wire        alu_valid_in,
    output wire [4:0] alu_opcode,
    output wire [1023:0] alu_src1,
    output wire [1023:0] alu_src2,
    output wire [1023:0] alu_src3,
    input  wire        alu_valid_out,
    input wire [1023:0] alu_result,
    
    // data cache / memory interface (mem stage, via the coalescing LSU)
    output wire        mem_req,
    input  wire        mem_req_ready,
    output wire        mem_we,
    output wire [2:0]  mem_warp_id,
    output wire [1023:0] mem_addr,
    output wire [1023:0] mem_wdata,
    input wire [1023:0] mem_rdata,
    input  wire        mem_rvalid,
    
    // pipeline outputs to scheduler (scoreboard updates)
    output wire        id_valid_out,
    output wire [2:0] id_warp_out,
    output wire [5:0] id_dest_reg_out,
    
    output wire        wb_valid_out,
    output wire [2:0] wb_warp_out,
    output wire [5:0] wb_dest_reg_out,
    output wire        fifo_full,

    // Sticky: an instruction was predicated on a mask whose lanes disagreed.
    // Divergent predication is not implemented (see the predicate block
    // below); this makes the condition observable rather than silent.
    output wire        dbg_pred_divergent,

    // tensor core datapath
    output wire        wmma_valid,
    output wire [1023:0] wmma_a,
    output wire [1023:0] wmma_b
);

    // if stage
    reg [2:0]  if_warp;
    reg        if_epoch;   // control-flow epoch of the in-flight fetch
    reg        if_pending; // fetch accepted, response not yet returned

    // sched_pc is an instruction index; the memory sees a byte address.
    assign if_pc = code_base + {sched_pc[29:0], 2'b00};
    // Allow only one outstanding fetch. Without this the request line is
    // held high and the crossbar re-accepts it every cycle, flooding the
    // memory controller with duplicate reads and starving every other
    // master (command processor, ROP) of the shared memory port.
    assign if_req = sched_valid && !if_pending;

    // Every accepted fetch advances that warp's PC by one instruction.
    assign pc_fetch_accept = if_req && if_gnt;
    assign pc_fetch_warp   = sched_warp_id;

    // ---- control-flow epochs (wrong-path squash) --------------------------
    // A taken branch is resolved in ID, by which time instructions fetched
    // sequentially *after* the branch are already in flight or sitting in the
    // instruction FIFO. Those are wrong-path and must not execute.
    //
    // Rather than surgically removing entries from the middle of a circular
    // FIFO, each warp carries a 1-bit epoch that toggles on redirect. A fetch
    // is tagged with its warp's epoch at accept; on pop, an entry whose epoch
    // no longer matches its warp's current epoch is discarded.
    //
    // One bit suffices *only because there is a single outstanding fetch per
    // SM*, which keeps FIFO push order equal to fetch-accept order. All stale
    // entries of a warp therefore precede its first fresh entry and are
    // discarded before a second redirect can occur, so the epoch cannot
    // alias (ABA). Widening to multiple outstanding fetches (roadmap Phase 2)
    // requires widening this counter too.
    reg [NUM_WARPS-1:0] warp_epoch;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            warp_epoch <= {NUM_WARPS{1'b0}};
        end else if (pc_redirect_valid) begin
            warp_epoch[pc_redirect_warp] <= ~warp_epoch[pc_redirect_warp];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_warp <= 0;
            if_epoch <= 1'b0;
            if_pending <= 0;
        end else begin
            if (if_req && if_gnt) begin
                if_warp <= sched_warp_id; // tag the in-flight fetch's warp
                if_epoch <= warp_epoch[sched_warp_id];
                if_pending <= 1'b1;
            end else if (if_inst_valid) begin
                if_pending <= 1'b0;
            end
        end
    end

`ifdef TITAN_FETCH_TRACE
    // Diagnostic only, never built by default. The fetch stream as the core
    // sees it, so an I-cache build can be diffed against a bypassed one.
    always @(posedge clk) if (rst_n) begin
        if (if_req && if_gnt)
            $display("FTRACE %0t ACC pc=%08x warp=%0d ep=%0d", $time, if_pc,
                     sched_warp_id, warp_epoch[sched_warp_id]);
        if (if_inst_valid)
            $display("FTRACE %0t RET inst=%08x warp=%0d ep=%0d", $time,
                     if_inst, if_warp, if_epoch);
        if (pc_redirect_valid)
            $display("FTRACE %0t RDR warp=%0d", $time, pc_redirect_warp);
    end
`endif

    // instruction fifo (8 entries)
    reg [2:0]  fifo_warp [0:7];
    reg [31:0] fifo_inst [0:7];
    reg        fifo_epoch [0:7];
    reg [3:0]  fifo_wp;
    reg [3:0]  fifo_rp;
    reg [3:0]  fifo_count;

    wire id_ready;
    assign fifo_full = (fifo_count == 8);
    wire fifo_empty = (fifo_count == 0);
    wire fifo_pop = !fifo_empty && id_ready;
    wire fifo_push = if_inst_valid && !fifo_full;

    always @(posedge clk) begin
        if (fifo_push) begin
            fifo_warp[fifo_wp[2:0]] <= if_warp;
            fifo_inst[fifo_wp[2:0]] <= if_inst;
            fifo_epoch[fifo_wp[2:0]] <= if_epoch;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wp <= 0;
            fifo_rp <= 0;
            fifo_count <= 0;
        end else begin
            if (fifo_push) begin
                fifo_wp <= fifo_wp + 1;
            end
            if (fifo_pop) begin
                fifo_rp <= fifo_rp + 1;
            end
            
            if (fifo_push && !fifo_pop) fifo_count <= fifo_count + 1;
            else if (!fifo_push && fifo_pop) fifo_count <= fifo_count - 1;
        end
    end

    // Gate the FIFO head with emptiness: before the first fetch the FIFO RAM
    // holds X, and an X source-register index would poison the scheduler's
    // scoreboard lookup (X-stalling every warp forever, so no fetch ever
    // happens to clear it).
    wire [31:0] id_inst_raw = fifo_empty ? 32'd0 : fifo_inst[fifo_rp[2:0]];
    wire [2:0]  id_warp_raw = fifo_warp[fifo_rp[2:0]];

    // Wrong-path: the entry was fetched under a control-flow epoch its warp
    // has since left. It is popped (to free the slot) but never executed and
    // never allowed to redirect or retire.
    wire        id_stale = !fifo_empty &&
                           (fifo_epoch[fifo_rp[2:0]] != warp_epoch[id_warp_raw]);
    wire        id_inst_valid_raw = !fifo_empty && !id_stale;

    // id stage
    wire [4:0]  dec_opcode;
    wire [5:0]  dec_rd, dec_rs1, dec_rs2, dec_rs3;
    wire [15:0] dec_imm;
    wire        dec_use_imm, dec_is_branch, dec_is_load, dec_is_store, dec_is_alu, dec_is_valid;
    
    wire        dec_is_wmma, dec_is_barrier, dec_is_setp, dec_is_predicated;
    wire [1:0]  dec_pred_reg;
    titan_x5_decoder decoder_inst (
        .inst(id_inst_raw),
        .opcode(dec_opcode),
        .rd(dec_rd),
        .rs1(dec_rs1),
        .rs2(dec_rs2),
        .rs3(dec_rs3),
        .imm(dec_imm),
        .use_imm(dec_use_imm),
        .is_branch(dec_is_branch),
        .is_mem_load(dec_is_load),
        .is_mem_store(dec_is_store),
        .is_alu(dec_is_alu),
        .is_valid(dec_is_valid),
        .is_wmma(dec_is_wmma),
        .is_barrier(dec_is_barrier),
        .is_setp(dec_is_setp),
        .is_predicated(dec_is_predicated),
        .pred_reg(dec_pred_reg)
    );

    // ---- predicate registers ----------------------------------------------
    //
    // Per warp: P0 is hardwired true, P1-P3 are writable by SETP. Each is a
    // 32-bit per-lane mask, because the machine is 32-wide SIMT and SETP
    // compares per-lane operands -- storing one bit per warp would silently
    // throw away 31 lanes' answers.
    //
    // Semantics follow driver/titan_x6_gpu_model.c, which gates the whole
    // instruction:  if (!p[pred]) { pc = next_pc; continue; }
    // so a predicated-off BRANCH falls through rather than branching.
    //
    // SCOPE -- divergent predication is NOT implemented. An instruction
    // predicated on P executes iff every lane of P is true, and is skipped iff
    // every lane is false. A mask whose lanes disagree is lane divergence,
    // which needs a reconvergence stack this pipeline does not have. Rather
    // than pick a silently-wrong answer, such an instruction is skipped and
    // pred_divergent is raised (sticky) so the condition is detectable instead
    // of invisible. Uniform predicates -- which is what the compiler's counted
    // loops generate, since the loop counter is warp-uniform -- are exact.
    localparam PRED_PER_WARP = 3;  // P1..P3; P0 is not stored
    reg [31:0] pred_mask [0:NUM_WARPS*PRED_PER_WARP-1];
    reg        pred_divergent;     // sticky: a divergent predicate was used

    // P0 always reads as all lanes true. The index is clamped rather than
    // written as `pred_reg - 1` inside the ternary: the array index is
    // evaluated regardless of which arm is selected, and pred_reg == 0 would
    // make it wrap to a huge value and read out of bounds (harmless here
    // because the result is discarded, but it reads back as X and would trip
    // an X-propagation check).
    wire [1:0]  id_pred_sel = dec_pred_reg;
    wire [4:0]  id_pred_idx = id_warp_raw*PRED_PER_WARP +
                              ((id_pred_sel == 2'd0) ? 2'd0 : (id_pred_sel - 2'd1));
    wire [31:0] id_pred_val = (id_pred_sel == 2'd0) ? 32'hFFFF_FFFF
                                                   : pred_mask[id_pred_idx];

    wire id_pred_all_true  = (id_pred_val == 32'hFFFF_FFFF);
    wire id_pred_all_false = (id_pred_val == 32'h0000_0000);
    wire id_pred_diverged  = !id_pred_all_true && !id_pred_all_false;

    // The instruction is allowed to take effect only on a uniform-true
    // predicate. P0 (the unpredicated case) is all-true by construction, so
    // unpredicated instructions are unaffected.
    wire id_pred_ok = id_pred_all_true;

    // ---- control-flow resolution (ID stage) -------------------------------
    // BRANCH, BARRIER and SETP are neither ALU nor memory ops (is_alu covers
    // opcodes <= 20 plus 29), so they never launch into EX; they resolve here,
    // at the point the instruction is popped from the FIFO.
    //
    // Only a non-stale pop may steer control flow -- a wrong-path branch must
    // not redirect the warp that already branched away from it.
    //
    // id_commit is the pop; id_exec additionally requires the predicate to
    // permit the instruction. A predicated-off instruction is still popped
    // (it must not block the FIFO) but has no architectural effect.
    wire id_commit = fifo_pop && id_inst_valid_raw;
    wire id_exec   = id_commit && id_pred_ok;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pred_divergent <= 1'b0;
        else if (id_commit && dec_is_predicated && id_pred_diverged)
            pred_divergent <= 1'b1;
    end
    assign dbg_pred_divergent = pred_divergent;

`ifdef TITAN_ID_TRACE
    // Diagnostic only, never built by default. Every ID-stage commit with the
    // operand values SETP and BRANCH actually saw, tagged with %m so the four
    // SMs can be told apart.
    always @(posedge clk) if (rst_n && id_commit) begin
        $display("IDTRACE %0t %m op=%0d warp=%0d rs1=%0d(%08x) rs2=%0d(%08x) imm=%04x setp=%0d cond=%0d pdst=%0d res=%08x predsel=%0d predval=%08x exec=%0d br=%0d",
                 $time, dec_opcode, id_warp_raw,
                 dec_rs1, fwd_data1[31:0], dec_rs2, fwd_data2[31:0], dec_imm,
                 dec_is_setp, setp_cond, setp_pdst, setp_result,
                 id_pred_sel, id_pred_val, id_exec, dec_is_branch);
        $display("IDTRACE+ %0t %m idreg(v=%0d rd=%0d) ex(v=%0d rd=%0d) mem(v=%0d rd=%0d) wb(v=%0d rd=%0d)",
                 $time, id_valid_reg, id_rd, ex_valid, ex_rd,
                 mem_valid, mem_rd, wb_valid, wb_rd);
    end
`endif

    // TX6_OP_BRANCH: pc = imm (absolute instruction index).
    // Now genuinely conditional: id_exec folds in the predicate, so a branch
    // whose predicate is false falls through instead of redirecting. That is
    // what makes a loop able to have an exit condition.
    assign pc_redirect_valid = id_exec && dec_is_branch;
    assign pc_redirect_warp  = id_warp_raw;
    assign pc_redirect_pc    = {16'd0, dec_imm};

    // TX6_OP_BARRIER with use_imm && imm == 0xFFF is EXIT (TX6_EXIT_IMM):
    // the warp retires and stops being scheduled. A plain BARRIER (without
    // that immediate) is thread synchronisation, not termination.
    assign pc_retire_valid = id_exec && dec_is_barrier && dec_use_imm &&
                             (dec_imm == 16'h0FFF);
    assign pc_retire_warp  = id_warp_raw;

    // STORE sources its data from the *rd* field:
    //   ISA / functional model: mem32[rs1 + (imm|rs2)] = rd
    //   (driver/titan_x6_gpu_model.c: `vram_wr32(gpu, a + b, r[rd])`)
    // but the register file's three read ports are wired to rs1/rs2/rs3 and
    // rd is never read, so the store data was taken from id_data2 -- the same
    // operand as the address offset. A store could therefore only ever write
    // the value that happened to equal its own offset; with an immediate
    // offset it wrote the immediate. STORE [r6+0], r2 stored 0.
    //
    // STORE does not use rs3, so its read port is repurposed to fetch rd.
    wire [5:0] dec_src3 = dec_is_store ? dec_rd : dec_rs3;

    assign rf_rd_addr1 = dec_rs1;
    assign rf_rd_addr2 = dec_rs2;
    assign rf_rd_addr3 = dec_src3;
    // All three operands belong to the instruction currently at the FIFO head,
    // so they share that entry's warp.
    assign rf_rd_warp  = id_warp_raw;

    wire [1023:0] id_imm_ext = {32{{16'd0, dec_imm}}};

    // forwarding & hazards
    wire ex_valid, mem_valid, wb_valid;
    wire [2:0] ex_warp, mem_warp, wb_warp;
    wire [5:0] ex_rd, mem_rd, wb_rd;
    wire [1023:0] ex_res, mem_res, wb_res;
    wire ex_is_load;

    wire fwd_rs1_ex  = ex_valid && (ex_warp == id_warp_raw) && (ex_rd == dec_rs1) && (dec_rs1 != 0);
    wire fwd_rs1_mem = mem_valid && (mem_warp == id_warp_raw) && (mem_rd == dec_rs1) && (dec_rs1 != 0);
    wire fwd_rs1_wb  = wb_valid && (wb_warp == id_warp_raw) && (wb_rd == dec_rs1) && (dec_rs1 != 0);

    wire fwd_rs2_ex  = ex_valid && (ex_warp == id_warp_raw) && (ex_rd == dec_rs2) && (dec_rs2 != 0);
    wire fwd_rs2_mem = mem_valid && (mem_warp == id_warp_raw) && (mem_rd == dec_rs2) && (dec_rs2 != 0);
    wire fwd_rs2_wb  = wb_valid && (wb_warp == id_warp_raw) && (wb_rd == dec_rs2) && (dec_rs2 != 0);

    // compares dec_src3, which is dec_rd for stores (see rf_rd_addr3 above)
    wire fwd_rs3_ex  = ex_valid && (ex_warp == id_warp_raw) && (ex_rd == dec_src3) && (dec_src3 != 0);
    wire fwd_rs3_mem = mem_valid && (mem_warp == id_warp_raw) && (mem_rd == dec_src3) && (dec_src3 != 0);
    wire fwd_rs3_wb  = wb_valid && (wb_warp == id_warp_raw) && (wb_rd == dec_src3) && (dec_src3 != 0);

    wire ex_busy;
    wire hazard_rs1 = fwd_rs1_ex && (ex_is_load || ex_busy);
    wire hazard_rs2 = fwd_rs2_ex && (ex_is_load || ex_busy);
    wire hazard_rs3 = fwd_rs3_ex && (ex_is_load || ex_busy);
    
    wire hazard = hazard_rs1 || hazard_rs2 || hazard_rs3;

    // ---- the ID-register forwarding hole ----------------------------------
    // An instruction spends one cycle in the ID *register* (id_valid_reg,
    // id_rd) between being popped from the FIFO and launching into EX. During
    // that cycle it appears in NONE of the three forwarding sources -- ex_*,
    // mem_* and wb_* all describe stages it has not reached -- and its result
    // does not exist yet, so it cannot be forwarded at all. A consumer popped
    // in that same cycle therefore read its operand from the register file and
    // got the pre-write value.
    //
    // This was invisible for the whole life of the project because fetch was
    // slow enough to hide it. With no instruction cache every fetch was a full
    // crossbar round trip, so consecutive instructions reached ID roughly 48
    // cycles apart and the producer had long since written back. Turning the
    // I-cache on closes that gap to one cycle and the hole opens. That is the
    // whole of the "I-cache breaks every multi-line compute kernel" bug
    // recorded at the instantiation site in titan_x5_gpu_top.v: measured on
    // the trip=1 counted loop, `SETP.GE p1, i, bound` read bound as 0 instead
    // of 1 while `li bound, 1` sat in the ID register, so the loop-exit branch
    // was taken on iteration zero and the kernel stored 0.
    //
    // It is not an I-cache bug, and it is not specific to SETP: any consumer
    // one cycle behind its producer reads stale. The cache only removed the
    // latency that was hiding it.
    //
    // The fix is a one-cycle interlock, not a forwarding path: the value does
    // not exist to forward. `id_rd` is only a real write for the instruction
    // classes that reach EX and produce a writeback, which is exactly the
    // condition id_valid_out uses to set the scheduler's scoreboard.
    wire idreg_writes = id_valid_reg && (id_rd != 6'd0) &&
                        (id_is_alu || id_is_load || id_is_store || id_is_wmma);
    wire idreg_hazard = idreg_writes && (id_warp_reg == id_warp_raw) &&
                        (((dec_rs1  != 6'd0) && (id_rd == dec_rs1)) ||
                         ((dec_rs2  != 6'd0) && (id_rd == dec_rs2)) ||
                         ((dec_src3 != 6'd0) && (id_rd == dec_src3)));

    // Split what used to be one signal. `id_issue_ok` is "EX can accept the
    // instruction in the ID register" and must NOT include idreg_hazard: the
    // ID register is the producer, and holding it back would stall the very
    // instruction whose departure clears the hazard -- a deadlock. `id_ready`
    // is "the FIFO head may be popped into the ID register", and does include
    // it. The hazard is therefore self-clearing in exactly one cycle: the
    // producer leaves for EX, id_valid_reg drops, and the consumer pops next
    // cycle with fwd_*_ex covering it (or hazard_rs* stalling it if it is a
    // load, as before).
    wire id_issue_ok = !ex_busy && !hazard;
    assign id_ready = id_issue_ok && !idreg_hazard;

    wire [1023:0] fwd_data1 = fwd_rs1_ex ? ex_res : (fwd_rs1_mem ? mem_res : (fwd_rs1_wb ? wb_res : rf_rd_data1));
    wire [1023:0] fwd_data2 = fwd_rs2_ex ? ex_res : (fwd_rs2_mem ? mem_res : (fwd_rs2_wb ? wb_res : rf_rd_data2));
    wire [1023:0] fwd_data3 = fwd_rs3_ex ? ex_res : (fwd_rs3_mem ? mem_res : (fwd_rs3_wb ? wb_res : rf_rd_data3));

    // ---- SETP (opcode 21) --------------------------------------------------
    // rd carries {cond[2:0], pdst[1:0]}; P[pdst] = compare(rs1, rs2|imm) per
    // lane. pdst == 0 is a no-op because P0 is read-only true, matching the
    // model's `if (pdst != 0) p[pdst] = res;`.
    //
    // Resolved in ID rather than EX because the ALU has no rd port (so the
    // condition code could not reach it) and because the operands are already
    // available here through the same forwarding network every other
    // instruction uses -- setp_a/setp_b below are literally the operands the
    // EX stage would have latched. Resolving here also means the predicate is
    // written the cycle SETP commits, so the very next instruction sees it: no
    // SETP -> BRANCH hazard, which is exactly the back-to-back sequence the
    // compiler emits for a loop exit.
    wire [2:0] setp_cond = dec_rd[4:2];
    wire [1:0] setp_pdst = dec_rd[1:0];

    wire [1023:0] setp_a = fwd_data1;
    wire [1023:0] setp_b = dec_use_imm ? id_imm_ext : fwd_data2;

    wire [31:0] setp_result;
    genvar lane;
    generate
        for (lane = 0; lane < 32; lane = lane + 1) begin : setp_lane_gen
            wire [31:0] la = setp_a[lane*32 +: 32];
            wire [31:0] lb = setp_b[lane*32 +: 32];
            // TX6_CMP_*: 0 EQ, 1 NE, 2 LT (signed), 3 GE (signed),
            //            4 LTU, 5 GEU. 6/7 are unassigned and read false.
            assign setp_result[lane] =
                (setp_cond == 3'd0) ? (la == lb) :
                (setp_cond == 3'd1) ? (la != lb) :
                (setp_cond == 3'd2) ? ($signed(la) <  $signed(lb)) :
                (setp_cond == 3'd3) ? ($signed(la) >= $signed(lb)) :
                (setp_cond == 3'd4) ? (la <  lb) :
                (setp_cond == 3'd5) ? (la >= lb) : 1'b0;
        end
    endgenerate

    integer pi;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (pi = 0; pi < NUM_WARPS*PRED_PER_WARP; pi = pi + 1)
                pred_mask[pi] <= 32'd0;
        end else if (id_exec && dec_is_setp && (setp_pdst != 2'd0)) begin
            pred_mask[id_warp_raw*PRED_PER_WARP +
                      {30'd0, setp_pdst} - 1] <= setp_result;
        end
    end

    reg [2:0]  id_warp_reg;
    reg [4:0]  id_opcode;
    reg [5:0]  id_rd;
    reg [1023:0] id_data1, id_data2, id_data3;
    reg        id_is_load, id_is_store, id_is_alu, id_valid_reg;
    reg        id_is_wmma;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_valid_reg <= 0;
        end else if (id_ready) begin
            // id_pred_ok stops a predicated-off instruction from launching
            // into EX, matching the model's "predicated off: fall through".
            // SETP never gets here anyway: it is not is_alu, so ex_launch
            // excludes it, and it resolves entirely in ID.
            id_valid_reg <= id_inst_valid_raw && dec_is_valid && id_pred_ok;
            id_warp_reg  <= id_warp_raw;
            id_opcode    <= dec_opcode;
            id_rd        <= dec_rd;
            id_data1     <= fwd_data1;
            id_data2     <= dec_use_imm ? id_imm_ext : fwd_data2;
            id_data3     <= fwd_data3;
            id_is_load   <= dec_is_load;
            id_is_store  <= dec_is_store;
            id_is_alu    <= dec_is_alu;
            id_is_wmma   <= dec_is_wmma;
        end else if (id_issue_ok) begin
            // Held back by idreg_hazard, so nothing was popped -- but EX did
            // take what was here. Mark the ID register empty, which is what
            // clears the hazard. Without this it would latch its own producer
            // forever. When id_issue_ok is also low (ex_busy) the register
            // holds, exactly as it did before.
            id_valid_reg <= 1'b0;
        end
    end

    // Scoreboard *set* must match scoreboard *clear*, or a warp deadlocks.
    //
    // The scheduler sets scoreboard[warp][id_dest_reg_out] whenever
    // id_valid_out is high, and clears it on writeback. Only instructions
    // that reach EX ever produce a writeback (see ex_launch below), so
    // asserting this for a non-executing instruction sets a scoreboard bit
    // that is never cleared.
    //
    // BRANCH and BARRIER are exactly such instructions, and both carry
    // rd == 0. Once control flow became real, every warp executed a BRANCH,
    // permanently setting scoreboard[warp][0]. The hazard check reads
    // scoreboard[warp][id_src_reg1], and an *empty* instruction FIFO decodes
    // as all-zeros -> src1 = 0 -> a permanent hazard on every warp. The SM
    // stalled forever with warp_stalled = 8'hFF and stopped fetching.
    //
    // rd == 0 is additionally excluded: the forwarding network already
    // treats register 0 as carrying no dependency (every fwd_* term has a
    // `!= 0` guard), so tracking a hazard on it would be inconsistent.
    assign id_valid_out = id_valid_reg && (id_rd != 6'd0) &&
                          (id_is_alu || id_is_load || id_is_store || id_is_wmma);
    assign id_warp_out = id_warp_reg;
    assign id_dest_reg_out = id_rd;

    // ex stage
    // id_issue_ok, not id_ready: see the idreg_hazard note above. Using
    // id_ready here would stall the producer that the hazard is waiting on.
    wire ex_launch = id_valid_reg && id_issue_ok && (id_is_alu || id_is_load || id_is_store || id_is_wmma);
    
    reg ex_valid_reg;
    reg [2:0] ex_warp_reg;
    reg [5:0] ex_rd_reg;
    reg ex_is_load_reg, ex_is_store_reg, ex_is_wmma_reg;
    reg [1023:0] ex_mem_wdata_reg;
    reg [1023:0] ex_wmma_a_reg, ex_wmma_b_reg;
    
    assign alu_valid_in = ex_launch && !id_is_wmma;
    assign alu_opcode   = (id_is_load || id_is_store) ? 5'd0 : id_opcode; // add for address calc
    assign alu_src1     = id_data1;
    assign alu_src2     = id_data2;
    assign alu_src3     = id_data3;

    // Memory requests are held (not pulsed) until the LSU accepts them:
    // the EX stage stays busy for a store until acceptance and for a load
    // until the response returns, which also guarantees the MEM-stage
    // writeback bookkeeping (warp/rd) stays stable for in-flight loads.
    reg ex_busy_reg;
    reg mem_pending_reg;
    reg [1023:0] mem_addr_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_busy_reg <= 0;
            ex_valid_reg <= 0;
            mem_pending_reg <= 0;
            mem_addr_reg <= 1024'd0;
        end else begin
            if (ex_launch) begin
                ex_busy_reg <= 1;
                ex_valid_reg <= 1;
                ex_warp_reg <= id_warp_reg;
                ex_rd_reg <= id_rd;
                ex_is_load_reg <= id_is_load;
                ex_is_store_reg <= id_is_store;
                ex_is_wmma_reg <= id_is_wmma;
                // stores take their data from rd (read via port 3)
                ex_mem_wdata_reg <= id_is_store ? id_data3 : id_data2;
                ex_wmma_a_reg <= id_data1;
                ex_wmma_b_reg <= id_data2;
            end else if (ex_busy_reg) begin
                if (ex_is_load_reg || ex_is_store_reg) begin
                    // per-lane addresses arrive from the vector ALU
                    if (alu_valid_out) begin
                        mem_pending_reg <= 1'b1;
                        mem_addr_reg    <= alu_result;
                    end
                    // request accepted by the LSU
                    if (mem_pending_reg && mem_req_ready) begin
                        mem_pending_reg <= 1'b0;
                        if (ex_is_store_reg) begin
                            ex_busy_reg  <= 0;   // stores retire at acceptance
                            ex_valid_reg <= 0;
                        end
                    end
                    // loads retire when the coalesced response returns
                    if (ex_is_load_reg && mem_rvalid) begin
                        ex_busy_reg  <= 0;
                        ex_valid_reg <= 0;
                    end
                end else if (alu_valid_out || ex_is_wmma_reg) begin
                    ex_busy_reg <= 0;
                    ex_valid_reg <= 0;
                end
            end
        end
    end

    assign ex_busy = ex_busy_reg;
    assign ex_valid = ex_valid_reg;
    assign ex_warp = ex_warp_reg;
    assign ex_rd = ex_rd_reg;
    assign ex_is_load = ex_is_load_reg;
    assign ex_res = alu_result;

    assign wmma_valid = ex_valid_reg && ex_is_wmma_reg;
    assign wmma_a     = ex_wmma_a_reg;
    assign wmma_b     = ex_wmma_b_reg;

    // mem stage
    reg mem_valid_reg;
    reg [2:0] mem_warp_reg;
    reg [5:0] mem_rd_reg;
    reg mem_is_load_reg;
    reg [1023:0] mem_alu_res_reg;
    
    assign mem_req   = mem_pending_reg;
    assign mem_we    = ex_is_store_reg;
    assign mem_warp_id = ex_warp_reg;
    assign mem_addr  = mem_addr_reg;
    assign mem_wdata = ex_mem_wdata_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_valid_reg <= 0;
        end else begin
            if (alu_valid_out || (ex_valid_reg && ex_is_wmma_reg)) begin
                mem_valid_reg <= ex_valid_reg && !ex_is_wmma_reg && !ex_is_store_reg;
                mem_warp_reg  <= ex_warp_reg;
                mem_rd_reg    <= ex_rd_reg;
                mem_is_load_reg <= ex_is_load_reg;
                mem_alu_res_reg <= alu_result;
            end else begin
                mem_valid_reg <= 0;
            end
        end
    end

    assign mem_valid = mem_valid_reg;
    assign mem_warp = mem_warp_reg;
    assign mem_rd = mem_rd_reg;
    assign mem_res = mem_alu_res_reg;

    // wb stage
    reg wb_valid_reg;
    reg [2:0] wb_warp_reg;
    reg [5:0] wb_rd_reg;
    reg [1023:0] wb_data_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_valid_reg <= 0;
        end else begin
            if (mem_valid_reg && !mem_is_load_reg) begin
                wb_valid_reg <= 1'b1;
                wb_warp_reg  <= mem_warp_reg;
                wb_rd_reg    <= mem_rd_reg;
                wb_data_reg  <= mem_alu_res_reg;
            end else if (mem_rvalid) begin
                wb_valid_reg <= 1'b1;
                wb_warp_reg  <= mem_warp_reg;
                wb_rd_reg    <= mem_rd_reg;
                wb_data_reg  <= mem_rdata;
            end else begin
                wb_valid_reg <= 0;
            end
        end
    end
    
    assign rf_wr_en   = wb_valid_reg;
    assign rf_wr_addr = wb_rd_reg;
    assign rf_wr_warp = wb_warp_reg;
    assign rf_wr_data = wb_data_reg;
    
    assign wb_valid_out = wb_valid_reg;
    assign wb_warp_out = wb_warp_reg;
    assign wb_dest_reg_out = wb_rd_reg;
    
    assign wb_valid = wb_valid_reg;
    assign wb_warp = wb_warp_reg;
    assign wb_rd = wb_rd_reg;
    assign wb_res = wb_data_reg;

endmodule
