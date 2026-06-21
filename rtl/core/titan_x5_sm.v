// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x5_sm #(
    parameter NUM_WARPS = 8,
    parameter NUM_ALUS = 32
)(
    input  wire clk,
    input  wire rst_n,
    
    // L1 Cache Interface (Instruction)
    output wire [31:0] l1_icache_addr,
    output wire        l1_icache_req,
    input wire [31:0] l1_icache_rdata,
    input  wire        l1_icache_rvalid,
    
    // L1 Cache Interface (Data)
    output wire [31:0] l1_dcache_addr,
    output wire [31:0] l1_dcache_wdata,
    output wire        l1_dcache_req,
    output wire        l1_dcache_we,
    input wire [31:0] l1_dcache_rdata,
    input  wire        l1_dcache_rvalid,
    
    // thread/warp control
    input wire [NUM_WARPS-1:0] warp_active,
    input wire [NUM_WARPS*32-1:0] warp_pc_in
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
    
    wire        alu_valid_in;
    wire [4:0]  alu_opcode;
    wire [1023:0] alu_src1, alu_src2, alu_src3;
    wire        alu_valid_out [0:NUM_ALUS-1];
    wire [31:0] alu_result    [0:NUM_ALUS-1];
    wire        fifo_full;
    
    titan_x5_warp_scheduler #(
        .NUM_WARPS(NUM_WARPS)
    ) warp_sched (
        .clk(clk),
        .rst_n(rst_n),
        .warp_active(warp_active),
        .warp_pc(warp_pc_in),
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
                .DATA_WIDTH(32)
            ) alu_inst (
                .clk(clk),
                .rst_n(rst_n),
                .valid_in(alu_valid_in),
                .opcode(alu_opcode),
                .src1(alu_src1[i*32 +: 32]),
                .src2(alu_src2[i*32 +: 32]),
                .src3(alu_src3[i*32 +: 32]),
                .stall_in(1'b0),
                .valid_out(alu_valid_out[i]),
                .result_out(alu_result[i]),
                .ready_out()
            );
        end
    endgenerate

    wire [1023:0] alu_result_flat;
    generate
        for (i=0; i<NUM_ALUS; i=i+1) begin : res_flat
            assign alu_result_flat[i*32 +: 32] = alu_result[i];
        end
    endgenerate

    // pipeline logic
    wire [1023:0] pipeline_mem_addr, pipeline_mem_wdata, pipeline_mem_rdata;
    
    // since l1 d-cache is 32-bit (scalar interface in titan_x5_gpu_top), we map thread 0's request
    assign l1_dcache_addr  = pipeline_mem_addr[31:0];
    assign l1_dcache_wdata = pipeline_mem_wdata[31:0];
    
    // broadcast loaded 32-bit data to all 32 lanes
    assign pipeline_mem_rdata = {32{l1_dcache_rdata}};

    titan_x5_pipeline pipeline_inst (
        .clk(clk),
        .rst_n(rst_n),
        .sched_warp_id(sched_warp_id),
        .sched_valid(sched_valid),
        .sched_pc(sched_pc),
        .if_pc(l1_icache_addr),
        .if_req(l1_icache_req),
        .if_inst(l1_icache_rdata),
        .if_inst_valid(l1_icache_rvalid),
        .rf_rd_addr1(rf_rd_addr1),
        .rf_rd_addr2(rf_rd_addr2),
        .rf_rd_addr3(rf_rd_addr3),
        .rf_rd_data1(rf_rd_data1),
        .rf_rd_data2(rf_rd_data2),
        .rf_rd_data3(rf_rd_data3),
        .rf_wr_addr(rf_wr_addr),
        .rf_wr_data(rf_wr_data),
        .rf_wr_en(rf_wr_en),
        .alu_valid_in(alu_valid_in),
        .alu_opcode(alu_opcode),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_src3(alu_src3),
        .alu_valid_out(alu_valid_out[0]), // assume uniform execution latency across warp
        .alu_result(alu_result_flat),
        .mem_req(l1_dcache_req),
        .mem_we(l1_dcache_we),
        .mem_addr(pipeline_mem_addr),
        .mem_wdata(pipeline_mem_wdata),
        .mem_rdata(pipeline_mem_rdata),
        .mem_rvalid(l1_dcache_rvalid),
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
    
    // register file bank mapping and connectivity
    wire [3:0] bank_wr_en = (rf_wr_en) ? (4'b0001 << rf_wr_addr[1:0]) : 4'd0;
    
    wire [4095:0] rf_rd_data_0_flat;
    wire [4095:0] rf_rd_data_1_flat;
    wire [4095:0] rf_rd_data_2_flat;
    
    titan_x5_register_file #(
        .DATA_WIDTH(1024), // 32 threads * 32 bits
        .NUM_REGS(64),
        .NUM_BANKS(4)
    ) rf_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rd_en_0(4'b1111),
        .rd_en_1(4'b1111),
        .rd_en_2(4'b1111),
        .rd_addr_0({4{rf_rd_addr1[5:2]}}),
        .rd_addr_1({4{rf_rd_addr2[5:2]}}),
        .rd_addr_2({4{rf_rd_addr3[5:2]}}),
        .rd_data_0(rf_rd_data_0_flat),
        .rd_data_1(rf_rd_data_1_flat),
        .rd_data_2(rf_rd_data_2_flat),
        .wr_en(bank_wr_en),
        .wr_addr({4{rf_wr_addr[5:2]}}),
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
