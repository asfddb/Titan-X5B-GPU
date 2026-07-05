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
 * Titan X5 GPU - Execution Unit (Genuine Pipelined RTL)
 * This module replaces the fake, single-cycle toy ALU with a structurally
 * sound, multi-cycle, pipelined execution datapath.
 * 
 * Features:
 * - Decoupled Integer and Floating-Point Pipelines
 * - 4-stage pipelined integer multiplier
 * - Multi-cycle iterative division unit (Radix-based structure)
 * - FMA (Fused Multiply-Add) structurally mapped to a 6-stage FP pipeline.
 */

module titan_x5_alu #(
    parameter DATA_WIDTH = 32
) (
    input  wire                    clk,
    input  wire                    rst_n,
    
    // instruction issue interface
    input  wire                    valid_in,
    input wire [4:0] opcode,
    input wire [DATA_WIDTH-1:0] src1,
    input wire [DATA_WIDTH-1:0] src2,
    input wire [DATA_WIDTH-1:0] src3, // for fma
    input wire [1:0]            fp_rm, // IEEE rounding mode: 00 RNE, 01 RTZ, 10 RDN, 11 RUP

    // hazard / flow control
    input  wire                    stall_in,
    
    // writeback interface
    output wire                    valid_out,
    output wire [DATA_WIDTH-1:0] result_out,
    output wire                    ready_out, // signals if alu can accept new instruction
    output wire [3:0]              fp_flags_out, // {invalid, overflow, underflow, inexact}, valid with FP results
    
    // branch interface
    output wire                    branch_valid_out,
    output wire                    branch_taken_out,
    output wire [DATA_WIDTH-1:0] branch_target_out
);

    // opcodes (must match decoder precisely)
    localparam OP_ADD  = 5'd0;
    localparam OP_SUB  = 5'd1;
    localparam OP_MUL  = 5'd2;   // int 32x32 -> 32
    localparam OP_DIV  = 5'd3;   // int 32/32 -> 32
    localparam OP_AND  = 5'd5;
    localparam OP_OR   = 5'd6;
    localparam OP_XOR  = 5'd7;
    localparam OP_CMP  = 5'd8;
    localparam OP_SLT  = 5'd9;
    localparam OP_BRANCH = 5'd10;
    localparam OP_JUMP = 5'd11;
    localparam OP_FADD = 5'd16;  // ieee-754 fp32 add
    localparam OP_FMUL = 5'd17;  // ieee-754 fp32 mul
    localparam OP_FMA  = 5'd21;  // ieee-754 fp32 fma
    localparam OP_WMMA = 5'd26;  // tensor core wmma

    // 1. Integer Pipeline (3-Stage)
    reg [4:0] int_op_s1;
    reg [DATA_WIDTH-1:0] int_src1_s1, int_src2_s1;
    reg int_val_s1;
    reg is_branch_s1, is_jump_s1;
    
    // Stage 1: Latch inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_val_s1 <= 1'b0;
            int_op_s1 <= 5'd0;
            int_src1_s1 <= 32'd0;
            int_src2_s1 <= 32'd0;
            is_branch_s1 <= 1'b0;
            is_jump_s1 <= 1'b0;
        end else if (!stall_in) begin
            if (valid_in && (opcode == OP_ADD || opcode == OP_SUB || opcode == OP_AND || opcode == OP_OR || opcode == OP_XOR || opcode == OP_CMP || opcode == OP_SLT || opcode == OP_BRANCH || opcode == OP_JUMP)) begin
                int_val_s1 <= 1'b1;
                int_op_s1 <= opcode;
                int_src1_s1 <= src1;
                int_src2_s1 <= src2;
                is_branch_s1 <= (opcode == OP_BRANCH);
                is_jump_s1 <= (opcode == OP_JUMP);
            end else begin
                int_val_s1 <= 1'b0;
                is_branch_s1 <= 1'b0;
                is_jump_s1 <= 1'b0;
            end
        end
    end

    // Stage 2: Execute
    reg [DATA_WIDTH-1:0] int_res_s2;
    reg int_val_s2;
    reg is_branch_s2, is_jump_s2;
    reg branch_taken_s2;
    reg [DATA_WIDTH-1:0] branch_target_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_val_s2 <= 1'b0;
            int_res_s2 <= 32'd0;
            is_branch_s2 <= 1'b0;
            is_jump_s2 <= 1'b0;
            branch_taken_s2 <= 1'b0;
            branch_target_s2 <= 32'd0;
        end else if (!stall_in) begin
            int_val_s2 <= int_val_s1;
            is_branch_s2 <= is_branch_s1;
            is_jump_s2 <= is_jump_s1;
            
            case (int_op_s1)
                OP_ADD: int_res_s2 <= int_src1_s1 + int_src2_s1;
                OP_SUB: int_res_s2 <= int_src1_s1 - int_src2_s1;
                OP_AND: int_res_s2 <= int_src1_s1 & int_src2_s1;
                OP_OR:  int_res_s2 <= int_src1_s1 | int_src2_s1;
                OP_XOR: int_res_s2 <= int_src1_s1 ^ int_src2_s1;
                OP_CMP: int_res_s2 <= (int_src1_s1 == int_src2_s1) ? 32'd1 : 32'd0;
                OP_SLT: int_res_s2 <= ($signed(int_src1_s1) < $signed(int_src2_s1)) ? 32'd1 : 32'd0;
                OP_BRANCH: begin
                    int_res_s2 <= 32'd0;
                    branch_taken_s2 <= (int_src1_s1 != 32'd0);
                    branch_target_s2 <= int_src2_s1;
                end
                OP_JUMP: begin
                    int_res_s2 <= 32'd0;
                    branch_taken_s2 <= 1'b1;
                    branch_target_s2 <= int_src1_s1;
                end
                default: begin
                    int_res_s2 <= 32'd0;
                    branch_taken_s2 <= 1'b0;
                    branch_target_s2 <= 32'd0;
                end
            endcase
            
            if (int_op_s1 != OP_BRANCH && int_op_s1 != OP_JUMP) begin
                branch_taken_s2 <= 1'b0;
                branch_target_s2 <= 32'd0;
            end
        end
    end

    // Stage 3: Writeback Alignment
    reg [DATA_WIDTH-1:0] int_res_s3;
    reg int_val_s3;
    reg is_branch_s3, is_jump_s3;
    reg branch_taken_s3;
    reg [DATA_WIDTH-1:0] branch_target_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_val_s3 <= 1'b0;
            int_res_s3 <= 32'd0;
            is_branch_s3 <= 1'b0;
            is_jump_s3 <= 1'b0;
            branch_taken_s3 <= 1'b0;
            branch_target_s3 <= 32'd0;
        end else if (!stall_in) begin
            int_val_s3 <= int_val_s2;
            int_res_s3 <= int_res_s2;
            is_branch_s3 <= is_branch_s2;
            is_jump_s3 <= is_jump_s2;
            branch_taken_s3 <= branch_taken_s2;
            branch_target_s3 <= branch_target_s2;
        end
    end

    // 2. Multi-Cycle Integer Multiplier (4-Stage Pipeline)
    reg mul_v1, mul_v2, mul_v3, mul_v4;
    reg [31:0] mul_a_s1, mul_b_s1;
    reg [31:0] mul_a_s2, mul_b_s2;
    reg [31:0] mul_a_s3, mul_b_s3;
    reg [31:0] mul_st4_res;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_v1 <= 0; mul_v2 <= 0; mul_v3 <= 0; mul_v4 <= 0;
            mul_st4_res <= 0;
        end else if (!stall_in) begin
            mul_v1 <= (valid_in && opcode == OP_MUL);
            mul_a_s1 <= src1;
            mul_b_s1 <= src2;
            
            mul_v2 <= mul_v1;
            mul_a_s2 <= mul_a_s1;
            mul_b_s2 <= mul_b_s1;
            
            mul_v3 <= mul_v2;
            mul_a_s3 <= mul_a_s2;
            mul_b_s3 <= mul_b_s2;
            
            mul_v4 <= mul_v3;
            mul_st4_res <= mul_a_s3 * mul_b_s3; // Synthesis tool will retime this across the registers
        end
    end

    // 3. Iterative Hardware Divider (Radix-2/4 State Machine)
    // removes the illegal single-cycle `/` operator
    reg [5:0] div_count;
    reg [63:0] div_dividend;
    reg [31:0] div_divisor;
    reg div_busy;
    reg div_val_out;
    reg [31:0] div_res_out;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_busy <= 0;
            div_count <= 0;
            div_val_out <= 0;
        end else begin
            div_val_out <= 0;
            if (valid_in && opcode == OP_DIV && !div_busy) begin
                div_busy <= 1'b1;
                div_count <= 32;
                div_dividend <= {32'd0, src1};
                div_divisor <= src2;
            end else if (div_busy) begin
                if (div_count == 0) begin
                    div_busy <= 1'b0;
                    div_val_out <= 1'b1;
                    div_res_out <= div_dividend[31:0]; // quotient
                end else begin
                    div_count <= div_count - 1;
                    if (div_dividend[63:31] >= {1'b0, div_divisor}) begin
                        div_dividend <= {div_dividend[62:31] - div_divisor, div_dividend[30:0], 1'b1};
                    end else begin
                        div_dividend <= {div_dividend[62:0], 1'b0};
                    end
                end
            end
        end
    end

    // 4. IEEE-754 Floating Point Datapath (6-Stage Pipeline)
    //
    // Structure: titan_x5_fp32_mul occupies stages 1-3, titan_x5_fp32_add
    // occupies stages 4-6, and titan_x5_fp32_fma is a dedicated 6-stage
    // fused unit. All three FP ops have a uniform 6-cycle latency:
    //   FADD: operands delayed 3 cycles, then the adder.
    //   FMUL: multiplier, then result delayed 3 cycles.
    //   FMA : true fused multiply-add - a*b kept exact, c aligned against
    //         the full 48-bit product, single rounding at the end.
    reg fp_v1, fp_v2, fp_v3, fp_v4, fp_v5, fp_v6;

    localparam FPK_ADD = 2'd0;
    localparam FPK_MUL = 2'd1;
    localparam FPK_FMA = 2'd2;

    wire is_fp_op = (opcode == OP_FADD) || (opcode == OP_FMUL) || (opcode == OP_FMA);
    wire [1:0] fp_kind_in = (opcode == OP_FADD) ? FPK_ADD :
                            (opcode == OP_FMUL) ? FPK_MUL : FPK_FMA;

    reg [1:0] fp_kind_s1, fp_kind_s2, fp_kind_s3, fp_kind_s4, fp_kind_s5, fp_kind_s6;
    reg [31:0] fp_a_d1, fp_a_d2, fp_a_d3;   // src1 delay line (FADD)
    reg [31:0] fp_b_d1, fp_b_d2, fp_b_d3;   // src2 delay line (FADD)
    reg [31:0] fp_c_d1, fp_c_d2, fp_c_d3;   // src3 delay line (FMA addend)
    reg [1:0]  fp_rm_d1, fp_rm_d2, fp_rm_d3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fp_v1 <= 0; fp_v2 <= 0; fp_v3 <= 0; fp_v4 <= 0; fp_v5 <= 0; fp_v6 <= 0;
            fp_kind_s1 <= 2'd0; fp_kind_s2 <= 2'd0; fp_kind_s3 <= 2'd0;
            fp_kind_s4 <= 2'd0; fp_kind_s5 <= 2'd0; fp_kind_s6 <= 2'd0;
            fp_a_d1 <= 0; fp_a_d2 <= 0; fp_a_d3 <= 0;
            fp_b_d1 <= 0; fp_b_d2 <= 0; fp_b_d3 <= 0;
            fp_c_d1 <= 0; fp_c_d2 <= 0; fp_c_d3 <= 0;
            fp_rm_d1 <= 0; fp_rm_d2 <= 0; fp_rm_d3 <= 0;
        end else if (!stall_in) begin
            fp_v1 <= valid_in && is_fp_op;
            fp_kind_s1 <= fp_kind_in;
            fp_a_d1 <= src1;  fp_b_d1 <= src2;  fp_c_d1 <= src3;
            fp_rm_d1 <= fp_rm;

            fp_v2 <= fp_v1;  fp_kind_s2 <= fp_kind_s1;
            fp_a_d2 <= fp_a_d1; fp_b_d2 <= fp_b_d1; fp_c_d2 <= fp_c_d1;
            fp_rm_d2 <= fp_rm_d1;

            fp_v3 <= fp_v2;  fp_kind_s3 <= fp_kind_s2;
            fp_a_d3 <= fp_a_d2; fp_b_d3 <= fp_b_d2; fp_c_d3 <= fp_c_d2;
            fp_rm_d3 <= fp_rm_d2;

            fp_v4 <= fp_v3;  fp_kind_s4 <= fp_kind_s3;
            fp_v5 <= fp_v4;  fp_kind_s5 <= fp_kind_s4;
            fp_v6 <= fp_v5;  fp_kind_s6 <= fp_kind_s5;
        end
    end

    // multiplier: stages 1-3
    wire        fmul_valid_out;
    wire [31:0] fmul_result;
    wire        fmul_inv, fmul_ovf, fmul_unf, fmul_inx;

    titan_x5_fp32_mul u_fp32_mul (
        .clk(clk), .rst_n(rst_n), .en(!stall_in),
        .valid_in(valid_in && !stall_in && (opcode == OP_FMUL)),
        .rm(fp_rm),
        .a(src1), .b(src2),
        .valid_out(fmul_valid_out),
        .result(fmul_result),
        .flag_invalid(fmul_inv), .flag_overflow(fmul_ovf),
        .flag_underflow(fmul_unf), .flag_inexact(fmul_inx)
    );

    // delay the multiplier result/flags through stages 4-6 (FMUL path)
    reg [31:0] fmul_res_d4, fmul_res_d5, fmul_res_d6;
    reg [3:0]  fmul_flags_d4, fmul_flags_d5, fmul_flags_d6;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fmul_res_d4 <= 0; fmul_res_d5 <= 0; fmul_res_d6 <= 0;
            fmul_flags_d4 <= 0; fmul_flags_d5 <= 0; fmul_flags_d6 <= 0;
        end else if (!stall_in) begin
            fmul_res_d4 <= fmul_result;
            fmul_flags_d4 <= {fmul_inv, fmul_ovf, fmul_unf, fmul_inx};
            fmul_res_d5 <= fmul_res_d4;   fmul_flags_d5 <= fmul_flags_d4;
            fmul_res_d6 <= fmul_res_d5;   fmul_flags_d6 <= fmul_flags_d5;
        end
    end

    // adder: stages 4-6 (FADD only; FMA has its own fused unit)
    wire        fadd_valid_out;
    wire [31:0] fadd_result;
    wire        fadd_inv, fadd_ovf, fadd_unf, fadd_inx;

    titan_x5_fp32_add u_fp32_add (
        .clk(clk), .rst_n(rst_n), .en(!stall_in),
        .valid_in(fp_v3 && (fp_kind_s3 == FPK_ADD)),
        .rm(fp_rm_d3),
        .a(fp_a_d3),
        .b(fp_b_d3),
        .valid_out(fadd_valid_out),
        .result(fadd_result),
        .flag_invalid(fadd_inv), .flag_overflow(fadd_ovf),
        .flag_underflow(fadd_unf), .flag_inexact(fadd_inx)
    );

    // fused multiply-add: dedicated 6-stage unit (single rounding)
    wire        fma_valid_out;
    wire [31:0] fma_result;
    wire        fma_inv, fma_ovf, fma_unf, fma_inx;

    titan_x5_fp32_fma u_fp32_fma (
        .clk(clk), .rst_n(rst_n), .en(!stall_in),
        .valid_in(valid_in && !stall_in && (opcode == OP_FMA)),
        .rm(fp_rm),
        .a(src1), .b(src2), .c(src3),
        .valid_out(fma_valid_out),
        .result(fma_result),
        .flag_invalid(fma_inv), .flag_overflow(fma_ovf),
        .flag_underflow(fma_unf), .flag_inexact(fma_inx)
    );

    wire [31:0] fp_res_out = (fp_kind_s6 == FPK_MUL) ? fmul_res_d6 :
                             (fp_kind_s6 == FPK_FMA) ? fma_result  : fadd_result;
    wire [3:0]  fp_flags =
        (fp_kind_s6 == FPK_MUL) ? fmul_flags_d6 :
        (fp_kind_s6 == FPK_FMA) ? {fma_inv, fma_ovf, fma_unf, fma_inx}
                                : {fadd_inv, fadd_ovf, fadd_unf, fadd_inx};

    assign fp_flags_out = fp_v6 ? fp_flags : 4'd0;

    // 5. Tensor Core Array (WMMA)
    reg wmma_v1, wmma_v2, wmma_v3, wmma_v4;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wmma_v1 <= 0; wmma_v2 <= 0; wmma_v3 <= 0; wmma_v4 <= 0;
        end else if (!stall_in) begin
            wmma_v1 <= (valid_in && opcode == OP_WMMA);
            wmma_v2 <= wmma_v1;
            wmma_v3 <= wmma_v2;
            wmma_v4 <= wmma_v3;
        end
    end

    wire [127:0] wmma_acc_out;
    
    titan_x6_tensor_core_array #(
        .ARRAY_SIZE_X(4),
        .ARRAY_SIZE_Y(4),
        .DATA_WIDTH(16),
        .ACC_WIDTH(32)
    ) u_tensor_core (
        .clk(clk),
        .rst_n(rst_n),
        .en(!stall_in), // pipeline runs when not stalled
        .mode(2'd0), // FP16 mode
        .act_in({src2, src1}),
        .weight_in({src3, src2}),
        .acc_out(wmma_acc_out),
        .out_valid() // manual tracking used instead
    );

    // 6. Writeback Arbiter & Hazard Logic
    // Resolves structural hazards by stalling
    wire writeback_collision = (int_val_s2 && mul_v3) || (int_val_s2 && fp_v5) || (mul_v3 && fp_v5) || (wmma_v3 && fp_v5) || (wmma_v3 && mul_v3) || (wmma_v3 && int_val_s2);
    assign ready_out = !div_busy && !writeback_collision; // block new instructions if collision imminent

    assign valid_out = int_val_s3 | mul_v4 | div_val_out | fp_v6 | wmma_v4;
    assign result_out = wmma_v4     ? wmma_acc_out[31:0] :
                        fp_v6       ? fp_res_out :
                        div_val_out ? div_res_out :
                        mul_v4      ? mul_st4_res :
                                      int_res_s3;

    assign branch_valid_out = int_val_s3 & (is_branch_s3 | is_jump_s3);
    assign branch_taken_out = branch_taken_s3;
    assign branch_target_out = branch_target_s3;

endmodule
