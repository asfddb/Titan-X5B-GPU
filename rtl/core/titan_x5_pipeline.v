// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x5_pipeline (
    input  wire clk,
    input  wire rst_n,
    
    // interface with warp scheduler
    input wire [2:0] sched_warp_id,
    input  wire        sched_valid,
    input wire [31:0] sched_pc,
    
    // instruction cache / memory interface
    output wire [31:0] if_pc,
    output wire        if_req,
    input wire [31:0] if_inst,
    input  wire        if_inst_valid,
    
    // register file interface
    output wire [5:0] rf_rd_addr1,
    output wire [5:0] rf_rd_addr2,
    output wire [5:0] rf_rd_addr3,
    input wire [1023:0] rf_rd_data1,
    input wire [1023:0] rf_rd_data2,
    input wire [1023:0] rf_rd_data3,
    
    output wire [5:0] rf_wr_addr,
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
    
    // data cache / memory interface (mem stage)
    output wire        mem_req,
    output wire        mem_we,
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

    // tensor core datapath
    output wire        wmma_valid,
    output wire [1023:0] wmma_a,
    output wire [1023:0] wmma_b
);

    // if stage
    reg [2:0]  if_warp;
    reg        if_valid;
    
    assign if_pc = sched_pc;
    assign if_req = sched_valid;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_warp <= 0;
            if_valid <= 0;
        end else begin
            if_warp <= sched_warp_id;
            if_valid <= sched_valid;
        end
    end

    // instruction fifo (8 entries)
    (* ram_style="block" *) reg [2:0]  fifo_warp [0:7];
    (* ram_style="block" *) reg [31:0] fifo_inst [0:7];
    reg [3:0]  fifo_wp;
    reg [3:0]  fifo_rp;
    reg [3:0]  fifo_count;
    
    wire id_ready;
    assign fifo_full = (fifo_count == 8);
    wire fifo_empty = (fifo_count == 0);
    wire fifo_pop = !fifo_empty && id_ready;
    wire fifo_push = if_inst_valid && !fifo_full;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_wp <= 0;
            fifo_rp <= 0;
            fifo_count <= 0;
        end else begin
            if (fifo_push) begin
                fifo_warp[fifo_wp[2:0]] <= if_warp;
                fifo_inst[fifo_wp[2:0]] <= if_inst;
                fifo_wp <= fifo_wp + 1;
            end
            if (fifo_pop) begin
                fifo_rp <= fifo_rp + 1;
            end
            
            if (fifo_push && !fifo_pop) fifo_count <= fifo_count + 1;
            else if (!fifo_push && fifo_pop) fifo_count <= fifo_count - 1;
        end
    end

    wire [31:0] id_inst_raw = fifo_inst[fifo_rp[2:0]];
    wire [2:0]  id_warp_raw = fifo_warp[fifo_rp[2:0]];
    wire        id_inst_valid_raw = !fifo_empty;

    // id stage
    wire [4:0]  dec_opcode;
    wire [5:0]  dec_rd, dec_rs1, dec_rs2, dec_rs3;
    wire [15:0] dec_imm;
    wire        dec_use_imm, dec_is_branch, dec_is_load, dec_is_store, dec_is_alu, dec_is_valid;
    
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
        .is_valid(dec_is_valid)
    );

    assign rf_rd_addr1 = dec_rs1;
    assign rf_rd_addr2 = dec_rs2;
    assign rf_rd_addr3 = dec_rs3;

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

    wire fwd_rs3_ex  = ex_valid && (ex_warp == id_warp_raw) && (ex_rd == dec_rs3) && (dec_rs3 != 0);
    wire fwd_rs3_mem = mem_valid && (mem_warp == id_warp_raw) && (mem_rd == dec_rs3) && (dec_rs3 != 0);
    wire fwd_rs3_wb  = wb_valid && (wb_warp == id_warp_raw) && (wb_rd == dec_rs3) && (dec_rs3 != 0);

    wire ex_busy;
    wire hazard_rs1 = fwd_rs1_ex && (ex_is_load || ex_busy);
    wire hazard_rs2 = fwd_rs2_ex && (ex_is_load || ex_busy);
    wire hazard_rs3 = fwd_rs3_ex && (ex_is_load || ex_busy);
    
    wire hazard = hazard_rs1 || hazard_rs2 || hazard_rs3;
    
    assign id_ready = !ex_busy && !hazard;

    wire [1023:0] fwd_data1 = fwd_rs1_ex ? ex_res : (fwd_rs1_mem ? mem_res : (fwd_rs1_wb ? wb_res : rf_rd_data1));
    wire [1023:0] fwd_data2 = fwd_rs2_ex ? ex_res : (fwd_rs2_mem ? mem_res : (fwd_rs2_wb ? wb_res : rf_rd_data2));
    wire [1023:0] fwd_data3 = fwd_rs3_ex ? ex_res : (fwd_rs3_mem ? mem_res : (fwd_rs3_wb ? wb_res : rf_rd_data3));

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
            id_valid_reg <= id_inst_valid_raw && dec_is_valid;
            id_warp_reg  <= id_warp_raw;
            id_opcode    <= dec_opcode;
            id_rd        <= dec_rd;
            id_data1     <= fwd_data1;
            id_data2     <= dec_use_imm ? id_imm_ext : fwd_data2;
            id_data3     <= fwd_data3;
            id_is_load   <= dec_is_load;
            id_is_store  <= dec_is_store;
            id_is_alu    <= dec_is_alu;
            id_is_wmma   <= (id_inst_raw[5:0] == 6'h3F);
        end
    end

    assign id_valid_out = id_valid_reg;
    assign id_warp_out = id_warp_reg;
    assign id_dest_reg_out = id_rd;

    // ex stage
    wire ex_launch = id_valid_reg && id_ready && (id_is_alu || id_is_load || id_is_store || id_is_wmma);
    
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

    reg ex_busy_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_busy_reg <= 0;
            ex_valid_reg <= 0;
        end else begin
            if (ex_launch) begin
                ex_busy_reg <= 1;
                ex_valid_reg <= 1;
                ex_warp_reg <= id_warp_reg;
                ex_rd_reg <= id_rd;
                ex_is_load_reg <= id_is_load;
                ex_is_store_reg <= id_is_store;
                ex_is_wmma_reg <= id_is_wmma;
                ex_mem_wdata_reg <= id_data2;
                ex_wmma_a_reg <= id_data1;
                ex_wmma_b_reg <= id_data2;
            end else if (ex_busy_reg && (alu_valid_out || ex_is_wmma_reg)) begin
                ex_busy_reg <= 0;
                ex_valid_reg <= 0;
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
    
    assign mem_req   = ex_valid_reg && (ex_is_load_reg || ex_is_store_reg) && alu_valid_out;
    assign mem_we    = ex_is_store_reg;
    assign mem_addr  = alu_result;
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
    assign rf_wr_data = wb_data_reg;
    
    assign wb_valid_out = wb_valid_reg;
    assign wb_warp_out = wb_warp_reg;
    assign wb_dest_reg_out = wb_rd_reg;
    
    assign wb_valid = wb_valid_reg;
    assign wb_warp = wb_warp_reg;
    assign wb_rd = wb_rd_reg;
    assign wb_res = wb_data_reg;

endmodule
