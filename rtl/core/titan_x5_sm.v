// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x5_sm #(
    parameter NUM_WARPS = 8,
    parameter NUM_ALUS = 32,
    parameter LINE_BYTES = 128,
    parameter ENABLE_TENSOR = 1 // 0 strips per-lane WMMA arrays (FPGA fit)
)(
    input  wire clk,
    input  wire rst_n,

    // L1 Cache Interface (Instruction)
    output wire [31:0] l1_icache_addr,
    output wire        l1_icache_req,
    input  wire        l1_icache_gnt,
    input wire [31:0] l1_icache_rdata,
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

    // debug/verification: MESI state lookup + coalescing perf pulse
    input  wire [31:0]              dbg_mesi_addr,
    output wire [1:0]               dbg_mesi_state,
    output wire                     dbg_lsu_resp_valid,
    output wire [5:0]               dbg_lsu_xactions,

    // FP rounding mode for the vector FPUs (00 RNE, 01 RTZ, 10 RDN, 11 RUP)
    input  wire [1:0]               fp_rm,

    // Shader Export Interface
    output wire        shader_wb_valid,
    output wire [5:0]  shader_wb_reg,
    output wire [1023:0] shader_wb_data,


    // ---- kernel launch --------------------------------------------------
    // The SM owns its program counters (titan_x5_pc_unit). Launch activates
    // the selected warps at launch_pc; from then on control flow is driven
    // by the pipeline's branch/EXIT resolution, not from outside.
    input  wire                   launch_valid,
    input  wire [NUM_WARPS-1:0]   launch_mask,
    input  wire [31:0]            launch_pc,     // instruction index
    input  wire [31:0]            code_base,     // byte address of code segment
    output wire [NUM_WARPS-1:0]   warp_active,
    output wire                   all_retired
);

    wire [2:0]  sched_warp_id;
    wire        sched_valid;
    wire [31:0] sched_pc;
    wire        id_valid;
    wire [2:0]  id_warp_id;
    wire [5:0]  id_dest_reg;
    wire        wb_valid;
    wire [2:0]  wb_warp_id;
    wire [5:0]  wb_dest_reg;
    
    wire [5:0]  rf_rd_addr1, rf_rd_addr2, rf_rd_addr3, rf_wr_addr;
    wire [1023:0] rf_rd_data1, rf_rd_data2, rf_rd_data3, rf_wr_data;
    wire        rf_wr_en;
    // Which warp's register set each side of the file is touching: ID for the
    // combinational reads, WB for the synchronous write.
    wire [2:0]  rf_rd_warp, rf_wr_warp;
    
    wire        alu_valid_in;
    wire [4:0]  alu_opcode;
    wire [1023:0] alu_src1, alu_src2, alu_src3;
    wire        alu_valid_out [0:NUM_ALUS-1];
    wire [31:0] alu_result    [0:NUM_ALUS-1];
    wire        fifo_full;
    
    wire [2:0]  lsu_mask_query_id;
    wire [31:0] lsu_mask_query_mask;

    // ---- program counters -------------------------------------------------
    wire [NUM_WARPS*32-1:0] warp_pc_bus;
    wire                    pc_fetch_accept;
    wire [2:0]              pc_fetch_warp;
    wire                    pc_redirect_valid;
    wire [2:0]              pc_redirect_warp;
    wire [31:0]             pc_redirect_pc;
    wire                    pc_retire_valid;
    wire [2:0]              pc_retire_warp;

    titan_x5_pc_unit #(
        .NUM_WARPS(NUM_WARPS),
        .WARP_ID_W(3)
    ) pc_unit (
        .clk(clk),
        .rst_n(rst_n),
        .launch_valid(launch_valid),
        .launch_mask(launch_mask),
        .launch_pc(launch_pc),
        .fetch_accept(pc_fetch_accept),
        .fetch_warp(pc_fetch_warp),
        .redirect_valid(pc_redirect_valid),
        .redirect_warp(pc_redirect_warp),
        .redirect_pc(pc_redirect_pc),
        .retire_valid(pc_retire_valid),
        .retire_warp(pc_retire_warp),
        .warp_pc(warp_pc_bus),
        .warp_active(warp_active),
        .all_retired(all_retired)
    );

    titan_x5_warp_scheduler #(
        .NUM_WARPS(NUM_WARPS)
    ) warp_sched (
        .clk(clk),
        .rst_n(rst_n),
        .warp_active(warp_active),
        .warp_pc(warp_pc_bus),
        .wb_valid(wb_valid),
        .wb_warp_id(wb_warp_id),
        .wb_reg(wb_dest_reg),
        .id_valid(id_valid),
        .id_warp_id(id_warp_id),
        .id_dest_reg(id_dest_reg),
        .id_src_reg1(rf_rd_addr1),
        .id_src_reg2(rf_rd_addr2),
        .fifo_full(fifo_full),
        .barrier_req(1'b0),
        .barrier_warp_id(3'd0),
        .mask_query_id(lsu_mask_query_id),
        .mask_query_mask(lsu_mask_query_mask),
        .sched_warp_id(sched_warp_id),
        .sched_valid(sched_valid),
        .sched_pc(sched_pc),
        .warp_stalled(),
        .warp_ready()
    );
    
    // alus for the threads
    genvar i;
    generate
        for (i=0; i<NUM_ALUS; i=i+1) begin : alu_gen
            titan_x5_alu #(
                .DATA_WIDTH(32),
                .ENABLE_TENSOR(ENABLE_TENSOR)
            ) alu_inst (
                .clk(clk),
                .rst_n(rst_n),
                .valid_in(alu_valid_in),
                .opcode(alu_opcode),
                .src1(alu_src1[i*32 +: 32]),
                .src2(alu_src2[i*32 +: 32]),
                .src3(alu_src3[i*32 +: 32]),
                .fp_rm(fp_rm),
                .stall_in(1'b0),
                .valid_out(alu_valid_out[i]),
                .result_out(alu_result[i]),
                .ready_out(),
                .fp_flags_out()
            );
        end
    endgenerate

    wire [1023:0] alu_result_flat;
    generate
        for (i=0; i<NUM_ALUS; i=i+1) begin : res_flat
            assign alu_result_flat[i*32 +: 32] = alu_result[i];
        end
    endgenerate

    // pipeline <-> LSU <-> L1 D-cache datapath (warp-wide, coalescing)
    wire [1023:0] pipeline_mem_addr, pipeline_mem_wdata, pipeline_mem_rdata;
    wire          pipeline_mem_req, pipeline_mem_we, pipeline_mem_rvalid;
    wire          lsu_req_ready;
    wire [2:0]    pipeline_mem_warp;

    // LSU <-> L1 line interface
    wire                    lsu_l1_req_valid, lsu_l1_req_ready, lsu_l1_req_write;
    wire [31:0]             lsu_l1_req_addr;
    wire [LINE_BYTES*8-1:0] lsu_l1_req_wdata;
    wire [LINE_BYTES-1:0]   lsu_l1_req_be;
    wire                    lsu_l1_resp_valid;
    wire [LINE_BYTES*8-1:0] lsu_l1_resp_rdata;

    titan_x5_lsu #(
        .NUM_LANES(32),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .LINE_BYTES(LINE_BYTES)
    ) u_lsu (
        .clk(clk),
        .rst_n(rst_n),

        .warp_req_valid(pipeline_mem_req),
        .warp_req_ready(lsu_req_ready),
        .warp_req_wid(pipeline_mem_warp),
        .warp_req_write(pipeline_mem_we),
        .warp_req_mask(lsu_mask_query_mask),
        .warp_req_addr(pipeline_mem_addr),
        .warp_req_wdata(pipeline_mem_wdata),

        .warp_resp_valid(pipeline_mem_rvalid),
        .warp_resp_wid(),
        .warp_resp_rdata(pipeline_mem_rdata),
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

    assign lsu_mask_query_id  = pipeline_mem_warp;
    assign dbg_lsu_resp_valid = pipeline_mem_rvalid;

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

        .dbg_addr(dbg_mesi_addr),
        .dbg_mesi(dbg_mesi_state)
    );

    titan_x5_pipeline #(
        .NUM_WARPS(NUM_WARPS)
    ) pipeline_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sched_warp_id(sched_warp_id),
        .sched_valid(sched_valid),
        .sched_pc(sched_pc),
        .code_base(code_base),
        .pc_fetch_accept(pc_fetch_accept),
        .pc_fetch_warp(pc_fetch_warp),
        .pc_redirect_valid(pc_redirect_valid),
        .pc_redirect_warp(pc_redirect_warp),
        .pc_redirect_pc(pc_redirect_pc),
        .pc_retire_valid(pc_retire_valid),
        .pc_retire_warp(pc_retire_warp),
        .if_pc(l1_icache_addr),
        .if_req(l1_icache_req),
        .if_gnt(l1_icache_gnt),
        .if_inst(l1_icache_rdata),
        .if_inst_valid(l1_icache_rvalid),
        .rf_rd_addr1(rf_rd_addr1),
        .rf_rd_addr2(rf_rd_addr2),
        .rf_rd_addr3(rf_rd_addr3),
        .rf_rd_warp(rf_rd_warp),
        .rf_rd_data1(rf_rd_data1),
        .rf_rd_data2(rf_rd_data2),
        .rf_rd_data3(rf_rd_data3),
        .rf_wr_addr(rf_wr_addr),
        .rf_wr_warp(rf_wr_warp),
        .rf_wr_data(rf_wr_data),
        .rf_wr_en(rf_wr_en),
        .alu_valid_in(alu_valid_in),
        .alu_opcode(alu_opcode),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_src3(alu_src3),
        .alu_valid_out(alu_valid_out[0]), // assume uniform execution latency across warp
        .alu_result(alu_result_flat),
        .mem_req(pipeline_mem_req),
        .mem_req_ready(lsu_req_ready),
        .mem_we(pipeline_mem_we),
        .mem_warp_id(pipeline_mem_warp),
        .mem_addr(pipeline_mem_addr),
        .mem_wdata(pipeline_mem_wdata),
        .mem_rdata(pipeline_mem_rdata),
        .mem_rvalid(pipeline_mem_rvalid),
        .id_valid_out(id_valid),
        .id_warp_out(id_warp_id),
        .id_dest_reg_out(id_dest_reg),
        .wb_valid_out(wb_valid),
        .wb_warp_out(wb_warp_id),
        .wb_dest_reg_out(wb_dest_reg),
        .fifo_full(fifo_full),
        .wmma_valid(),
        .wmma_a(),
        .wmma_b()
    );
    
    assign shader_wb_valid = wb_valid;
    assign shader_wb_reg   = wb_dest_reg;
    assign shader_wb_data  = rf_wr_data;

    
    // register file bank mapping and connectivity
    wire [3:0] bank_wr_en = (rf_wr_en) ? (4'b0001 << rf_wr_addr[1:0]) : 4'd0;
    
    wire [4095:0] rf_rd_data_0_flat;
    wire [4095:0] rf_rd_data_1_flat;
    wire [4095:0] rf_rd_data_2_flat;
    
    titan_x5_register_file #(
        .DATA_WIDTH(1024), // 32 threads * 32 bits
        .NUM_REGS(64),     // per warp
        .NUM_BANKS(4),
        .NUM_WARPS(NUM_WARPS)
    ) rf_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rd_en_0(4'b1111),
        .rd_en_1(4'b1111),
        .rd_en_2(4'b1111),
        .rd_addr_0({4{rf_rd_addr1[5:2]}}),
        .rd_addr_1({4{rf_rd_addr2[5:2]}}),
        .rd_addr_2({4{rf_rd_addr3[5:2]}}),
        .rd_warp_0(rf_rd_warp),
        .rd_warp_1(rf_rd_warp),
        .rd_warp_2(rf_rd_warp),
        .rd_data_0(rf_rd_data_0_flat),
        .rd_data_1(rf_rd_data_1_flat),
        .rd_data_2(rf_rd_data_2_flat),
        .wr_en(bank_wr_en),
        .wr_addr({4{rf_wr_addr[5:2]}}),
        .wr_warp(rf_wr_warp),
        .wr_data({4{rf_wr_data}})
    );
    
    assign rf_rd_data1 = (rf_rd_addr1[1:0] == 2'd0) ? rf_rd_data_0_flat[1023:0] :
                         (rf_rd_addr1[1:0] == 2'd1) ? rf_rd_data_0_flat[2047:1024] :
                         (rf_rd_addr1[1:0] == 2'd2) ? rf_rd_data_0_flat[3071:2048] :
                                                      rf_rd_data_0_flat[4095:3072];

    assign rf_rd_data2 = (rf_rd_addr2[1:0] == 2'd0) ? rf_rd_data_1_flat[1023:0] :
                         (rf_rd_addr2[1:0] == 2'd1) ? rf_rd_data_1_flat[2047:1024] :
                         (rf_rd_addr2[1:0] == 2'd2) ? rf_rd_data_1_flat[3071:2048] :
                                                      rf_rd_data_1_flat[4095:3072];

    assign rf_rd_data3 = (rf_rd_addr3[1:0] == 2'd0) ? rf_rd_data_2_flat[1023:0] :
                         (rf_rd_addr3[1:0] == 2'd1) ? rf_rd_data_2_flat[2047:1024] :
                         (rf_rd_addr3[1:0] == 2'd2) ? rf_rd_data_2_flat[3071:2048] :
                                                      rf_rd_data_2_flat[4095:3072];

endmodule
