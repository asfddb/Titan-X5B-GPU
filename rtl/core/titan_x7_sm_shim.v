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
 * titan_x7_sm_shim - titan_x7_sm behind titan_x5_sm's port list.
 *
 * WHY A SHIM. docs/HANDOFF_NEXT_SESSION.md priority 1 is "wire the X7 SM
 * into the chip". The two SMs do not present the same interface, and the
 * mismatch is not cosmetic:
 *
 *   titan_x5_sm                          titan_x7_sm
 *   -----------                          -----------
 *   32-bit single-word granted fetch     64-bit warp-tagged PAIR fetch
 *   owns its PC unit (launch/retire)     warp_active/warp_pc_in are INPUTS
 *   contains LSU + L1 D-cache            raw warp-wide dmem interface
 *   32 lanes                             LANES parameter (was 8)
 *   exports its WB port to the ROP       no export path
 *
 * Making titan_x5_gpu_top instantiate X7 directly would mean rewriting the
 * top level. A shim with x5's exact port list is a drop-in instead, so the
 * top can select between the two and both stay buildable and testable.
 *
 * WHAT IS REUSED, NOT REWRITTEN: titan_x5_lsu and titan_x5_l1_cache are
 * instantiated verbatim, exactly as titan_x5_sm does. X7's dmem interface
 * is a direct match for the LSU's warp port, so the coherence, snoop and
 * flush behaviour the regression already covers is unchanged.
 *
 * ADDRESSING. x5's pc_unit works in instruction INDICES and the pipeline
 * fetches at code_base + pc*4. X7 works in byte PCs. So warps launch at
 * launch_pc<<2 and the fetch adapter adds code_base. BRANCH targets are
 * absolute instruction indices scaled by 4 inside X7 (see
 * docs/X7_ISA_CONFORMANCE.md), so both agree on where a target lands.
 */
module titan_x7_sm_shim #(
    parameter NUM_WARPS     = 8,
    parameter NUM_ALUS      = 32,   // accepted for drop-in compatibility
    parameter LINE_BYTES    = 128,
    parameter ENABLE_TENSOR = 1     // accepted; X7 has no per-ALU tensor array
)(
    input  wire clk,
    input  wire rst_n,

    // L1 Cache Interface (Instruction)
    output wire [31:0] l1_icache_addr,
    output wire        l1_icache_req,
    input  wire        l1_icache_gnt,
    input  wire [31:0] l1_icache_rdata,
    input  wire        l1_icache_rvalid,

    // L1 D-cache coherent bus interface (to titan_x5_coherent_xbar)
    output wire                     dbus_req_valid,
    input  wire                     dbus_req_ready,
    output wire [1:0]               dbus_req_type,
    output wire [31:0]              dbus_req_addr,
    output wire [LINE_BYTES*8-1:0]  dbus_req_wdata,
    input  wire                     dbus_resp_valid,
    input  wire [LINE_BYTES*8-1:0]  dbus_resp_rdata,
    input  wire                     dbus_resp_shared,

    // L1 D-cache snoop interface (from titan_x5_coherent_xbar)
    input  wire                     snp_req_valid,
    input  wire [1:0]               snp_req_type,
    input  wire [31:0]              snp_req_addr,
    output wire                     snp_resp_valid,
    output wire                     snp_resp_hit,
    output wire                     snp_resp_dirty,
    output wire [LINE_BYTES*8-1:0]  snp_resp_data,

    // debug/verification
    input  wire [31:0]              dbg_mesi_addr,
    output wire [1:0]               dbg_mesi_state,
    output wire                     dbg_lsu_resp_valid,
    output wire [5:0]               dbg_lsu_xactions,
    output wire                     dbg_pred_divergent,

    input  wire [1:0]               fp_rm,

    // cache flush (straight through to this SM's L1 D-cache)
    input  wire                     flush_req,
    output wire                     flush_done,

    // Shader Export Interface
    output wire        shader_wb_valid,
    output wire [5:0]  shader_wb_reg,
    output wire [1023:0] shader_wb_data,

    // kernel launch
    input  wire                   launch_valid,
    input  wire [NUM_WARPS-1:0]   launch_mask,
    input  wire [31:0]            launch_pc,     // instruction index
    input  wire [31:0]            code_base,     // byte address of code segment
    output wire [NUM_WARPS-1:0]   warp_active,
    output wire                   all_retired
);

    localparam LANES  = 32;
    localparam WARP_W = 3;

    // ==================================================================
    // launch / retire bookkeeping
    //
    // X7 takes warp_active and warp_pc_in as inputs and has no PC unit, so
    // this reproduces titan_x5_pc_unit's contract: a launch activates the
    // masked warps at launch_pc, each warp's EXIT clears its own bit, and
    // all_retired is qualified by `launched` so it cannot read true before
    // the first kernel starts.
    //
    // The active mask is what X7 sees, so clearing a bit on EXIT also stops
    // that warp being fetched or issued. X7 clears its internal retired
    // flag on the next activation edge, so a relaunch is clean.
    // ==================================================================
    reg [NUM_WARPS-1:0] active;
    reg                 launched;

    wire                  x7_exit_valid;
    wire [WARP_W-1:0]     x7_exit_warp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active   <= {NUM_WARPS{1'b0}};
            launched <= 1'b0;
        end else if (launch_valid) begin
            active   <= launch_mask;
            launched <= 1'b1;
        end else if (x7_exit_valid) begin
            active[x7_exit_warp] <= 1'b0;
        end
    end

    assign warp_active = active;
    assign all_retired = launched && (active == {NUM_WARPS{1'b0}});

    // every launched warp starts at the same PC; index -> byte
    wire [31:0] launch_pc_bytes = {launch_pc[29:0], 2'b00};
    wire [NUM_WARPS*32-1:0] x7_warp_pc_in;
    genvar gw;
    generate
        for (gw = 0; gw < NUM_WARPS; gw = gw + 1) begin : g_pcin
            assign x7_warp_pc_in[gw*32 +: 32] = launch_pc_bytes;
        end
    endgenerate

    // ==================================================================
    // instruction fetch adapter: 64-bit warp-tagged pair  ->  the chip's
    // 32-bit granted single-word port
    //
    // X7 asks for an instruction PAIR (pc, pc+4) tagged with a warp id and
    // allows one outstanding fetch per warp. The top level provides one
    // 32-bit port with a grant and a later rvalid, and only one fetch may
    // be outstanding on it. So each pair becomes two sequential word
    // fetches, and imem_req_ready holds X7 off until the pair completes.
    //
    // This does NOT widen fetch bandwidth -- the chip still supplies one
    // word at a time, which HANDOFF_NEXT_SESSION.md already identifies as
    // the dominant cost in the render test. It makes X7 correct on this
    // port; making it fast needs a real I-cache, which is a separate job.
    // ==================================================================
    localparam IF_IDLE  = 3'd0,
               IF_REQ0  = 3'd1,
               IF_WAIT0 = 3'd2,
               IF_REQ1  = 3'd3,
               IF_WAIT1 = 3'd4;

    reg  [2:0]        ifs;
    reg  [WARP_W-1:0] if_warp;
    reg  [31:0]       if_pc;
    reg  [31:0]       if_word0;

    wire              x7_imem_req_valid;
    wire [WARP_W-1:0] x7_imem_req_warp;
    wire [31:0]       x7_imem_req_pc;

    reg               x7_imem_resp_valid;
    reg  [WARP_W-1:0] x7_imem_resp_warp;
    reg  [63:0]       x7_imem_resp_data;

    assign l1_icache_req  = (ifs == IF_REQ0) || (ifs == IF_REQ1);
    assign l1_icache_addr = code_base + if_pc + ((ifs == IF_REQ1) ? 32'd4 : 32'd0);

    // X7 may present a new pair request only while the adapter is idle
    wire if_ready = (ifs == IF_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifs                <= IF_IDLE;
            if_warp            <= {WARP_W{1'b0}};
            if_pc              <= 32'd0;
            if_word0           <= 32'd0;
            x7_imem_resp_valid <= 1'b0;
            x7_imem_resp_warp  <= {WARP_W{1'b0}};
            x7_imem_resp_data  <= 64'd0;
        end else begin
            x7_imem_resp_valid <= 1'b0;
            case (ifs)
                IF_IDLE: begin
                    if (x7_imem_req_valid) begin
                        if_warp <= x7_imem_req_warp;
                        if_pc   <= x7_imem_req_pc;
                        ifs     <= IF_REQ0;
                    end
                end
                IF_REQ0:  if (l1_icache_gnt)    ifs <= IF_WAIT0;
                IF_WAIT0: if (l1_icache_rvalid) begin
                              if_word0 <= l1_icache_rdata;
                              ifs      <= IF_REQ1;
                          end
                IF_REQ1:  if (l1_icache_gnt)    ifs <= IF_WAIT1;
                IF_WAIT1: if (l1_icache_rvalid) begin
                              x7_imem_resp_valid <= 1'b1;
                              x7_imem_resp_warp  <= if_warp;
                              x7_imem_resp_data  <= {l1_icache_rdata, if_word0};
                              ifs                <= IF_IDLE;
                          end
                default: ifs <= IF_IDLE;
            endcase
        end
    end

    // ==================================================================
    // the core
    // ==================================================================
    wire                 x7_dmem_req_valid, x7_dmem_req_ready, x7_dmem_req_write;
    wire [WARP_W-1:0]    x7_dmem_req_warp;
    wire [LANES-1:0]     x7_dmem_req_mask;
    wire [LANES*32-1:0]  x7_dmem_req_addr, x7_dmem_req_wdata;
    wire                 x7_dmem_resp_valid;
    wire [LANES*32-1:0]  x7_dmem_resp_rdata;

    wire                 x7_wb_valid;
    wire [5:0]           x7_wb_reg;
    wire [LANES*32-1:0]  x7_wb_data;

    titan_x7_sm #(
        .NUM_WARPS(NUM_WARPS),
        .WARP_W(WARP_W),
        .LANES(LANES)
    ) u_x7 (
        .clk(clk),
        .rst_n(rst_n),

        .warp_active(active),
        .warp_pc_in(x7_warp_pc_in),

        .imem_req_valid(x7_imem_req_valid),
        .imem_req_ready(if_ready),
        .imem_req_warp(x7_imem_req_warp),
        .imem_req_pc(x7_imem_req_pc),
        .imem_resp_valid(x7_imem_resp_valid),
        .imem_resp_warp(x7_imem_resp_warp),
        .imem_resp_data(x7_imem_resp_data),

        .dmem_req_valid(x7_dmem_req_valid),
        .dmem_req_ready(x7_dmem_req_ready),
        .dmem_req_write(x7_dmem_req_write),
        .dmem_req_warp(x7_dmem_req_warp),
        .dmem_req_mask(x7_dmem_req_mask),
        .dmem_req_addr(x7_dmem_req_addr),
        .dmem_req_wdata(x7_dmem_req_wdata),
        .dmem_resp_valid(x7_dmem_resp_valid),
        .dmem_resp_warp(),
        .dmem_resp_rdata(x7_dmem_resp_rdata),

        .wmma_valid(), .wmma_warp(), .wmma_a(), .wmma_b(),

        .warp_exit_valid(x7_exit_valid),
        .warp_exit_warp(x7_exit_warp),
        .all_retired(),                 // the shim owns this, see above

        .wb_export_valid(x7_wb_valid),
        .wb_export_reg(x7_wb_reg),
        .wb_export_data(x7_wb_data),

        .dbg_retired(),
        .dbg_warp(3'd0),
        .dbg_reg(6'd0),
        .dbg_rdata()
    );

    assign shader_wb_valid = x7_wb_valid;
    assign shader_wb_reg   = x7_wb_reg;
    assign shader_wb_data  = x7_wb_data;

    // X7 applies the predicate as a per-lane write mask, so a divergent
    // mask is handled rather than skipped. The x5 sticky flag reports an
    // unimplemented case that does not exist here.
    assign dbg_pred_divergent = 1'b0;

    // ==================================================================
    // LSU + L1 D-cache: instantiated exactly as titan_x5_sm does
    // ==================================================================
    wire                    lsu_l1_req_valid, lsu_l1_req_ready, lsu_l1_req_write;
    wire [31:0]             lsu_l1_req_addr;
    wire [LINE_BYTES*8-1:0] lsu_l1_req_wdata;
    wire [LINE_BYTES-1:0]   lsu_l1_req_be;
    wire                    lsu_l1_resp_valid;
    wire [LINE_BYTES*8-1:0] lsu_l1_resp_rdata;

    titan_x5_lsu #(
        .NUM_LANES(LANES),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .LINE_BYTES(LINE_BYTES)
    ) u_lsu (
        .clk(clk),
        .rst_n(rst_n),

        .warp_req_valid(x7_dmem_req_valid),
        .warp_req_ready(x7_dmem_req_ready),
        .warp_req_wid(x7_dmem_req_warp),
        .warp_req_write(x7_dmem_req_write),
        .warp_req_mask(x7_dmem_req_mask),
        .warp_req_addr(x7_dmem_req_addr),
        .warp_req_wdata(x7_dmem_req_wdata),

        .warp_resp_valid(x7_dmem_resp_valid),
        .warp_resp_wid(),
        .warp_resp_rdata(x7_dmem_resp_rdata),
        .warp_resp_xactions(dbg_lsu_xactions),

        .mem_req_valid(lsu_l1_req_valid),
        .mem_req_ready(lsu_l1_req_ready),
        .mem_req_write(lsu_l1_req_write),
        .mem_req_addr(lsu_l1_req_addr),
        .mem_req_wdata(lsu_l1_req_wdata),
        .mem_req_be(lsu_l1_req_be),
        .mem_resp_valid(lsu_l1_resp_valid),
        .mem_resp_rdata(lsu_l1_resp_rdata)
    );

    assign dbg_lsu_resp_valid = x7_dmem_resp_valid;

    titan_x5_l1_cache #(
        .ADDR_WIDTH(32),
        .LINE_BYTES(LINE_BYTES),
        .WAYS(4),
        .SETS(64)
    ) u_l1_dcache (
        .clk(clk),
        .rst_n(rst_n),

        .core_req_valid(lsu_l1_req_valid),
        .core_req_ready(lsu_l1_req_ready),
        .core_req_write(lsu_l1_req_write),
        .core_req_addr(lsu_l1_req_addr),
        .core_req_wdata(lsu_l1_req_wdata),
        .core_req_be(lsu_l1_req_be),
        .core_resp_valid(lsu_l1_resp_valid),
        .core_resp_rdata(lsu_l1_resp_rdata),

        .bus_req_valid(dbus_req_valid),
        .bus_req_ready(dbus_req_ready),
        .bus_req_type(dbus_req_type),
        .bus_req_addr(dbus_req_addr),
        .bus_req_wdata(dbus_req_wdata),
        .bus_resp_valid(dbus_resp_valid),
        .bus_resp_rdata(dbus_resp_rdata),
        .bus_resp_shared(dbus_resp_shared),

        .snp_req_valid(snp_req_valid),
        .snp_req_type(snp_req_type),
        .snp_req_addr(snp_req_addr),
        .snp_resp_valid(snp_resp_valid),
        .snp_resp_hit(snp_resp_hit),
        .snp_resp_dirty(snp_resp_dirty),
        .snp_resp_data(snp_resp_data),

        .flush_req(flush_req),
        .flush_done(flush_done),
        .dbg_addr(dbg_mesi_addr),
        .dbg_mesi(dbg_mesi_state)
    );

endmodule
