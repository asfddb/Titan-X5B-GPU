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
    parameter DATA_WIDTH = 32,
    // 1 = full WMMA tensor array per lane (ASIC config, verified default).
    // 0 = WMMA returns zero; required to fit FPGA targets, where 128 tensor
    //     arrays exceed the entire device several times over.
    parameter ENABLE_TENSOR = 1
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

    // ---- opcodes: the ISA map -------------------------------------------
    //
    // These now match driver/titan_x6_isa.h, titan_x5_decoder.v,
    // compiler/titan_compiler.py and driver/titan_x6_gpu_model.c.
    //
    // They previously did NOT. This block used to declare an older, private
    // opcode set (OP_CMP=8, OP_SLT=9, OP_BRANCH=10, OP_JUMP=11, OP_DIV=3,
    // OP_FMA=21) while the decoder handed it ISA opcodes. Opcode 8 is SHL in
    // the ISA and was executed as an equality compare; 3, 9, 10, 11 were
    // similarly wrong; and 4, 12-15, 18-20 were not implemented at all and
    // fell through to `default`, returning 0. Every one of those failed
    // silently, so any kernel using a shift, divide, min/max, comparison or
    // conversion computed wrong answers.
    //
    // compiler/test_compiler_isa.py checked the compiler against the DECODER
    // and never against the ALU, which is why this survived. That test now
    // covers the ALU too.
    localparam OP_ADD   = 5'd0;
    localparam OP_SUB   = 5'd1;
    localparam OP_MUL   = 5'd2;   // signed 32x32 -> low 32
    localparam OP_MULHI = 5'd3;   // signed 32x32 -> high 32
    localparam OP_DIV   = 5'd4;   // signed 32/32
    localparam OP_AND   = 5'd5;
    localparam OP_OR    = 5'd6;
    localparam OP_XOR   = 5'd7;
    localparam OP_SHL   = 5'd8;
    localparam OP_SHR   = 5'd9;   // logical
    localparam OP_SRA   = 5'd10;  // arithmetic
    localparam OP_SLT   = 5'd11;  // signed
    localparam OP_SLTU  = 5'd12;
    localparam OP_MIN   = 5'd13;  // signed
    localparam OP_MAX   = 5'd14;  // signed
    localparam OP_IFMA  = 5'd15;  // INTEGER fma: rs1*rs2 + rs3
    localparam OP_FADD  = 5'd16;  // ieee-754 fp32 add
    localparam OP_FMUL  = 5'd17;  // ieee-754 fp32 mul
    localparam OP_FMIN  = 5'd18;
    localparam OP_FMAX  = 5'd19;
    localparam OP_CVT   = 5'd20;  // rs3[0]=0 int->fp32, 1 fp32->int
    // FP32 fused multiply-add. This used to squat on opcode 21 -- the slot the
    // ISA assigns to SETP -- because the ISA had no FP-FMA opcode at all
    // (opcode 15 is documented and modelled as INTEGER fma) while
    // rtl/fpu/titan_x5_fp32_fma.v is a real single-rounding fused unit,
    // bit-exact against an integer oracle (docs/REMEDIATION_REPORT.md).
    //
    // Slot 29 was RSQRT: assigned in the ISA header and implemented in the C
    // functional model, but never built in hardware -- there is no SFU in this
    // ALU. Reassigning it trades a transcendental that never existed for a
    // datapath that does, and returns 21 to SETP. See driver/titan_x6_isa.h.
    //
    // SETP is not handled here at all: its rd field carries {cond, pdst}
    // rather than a register index, so it is resolved in the ID stage of
    // titan_x5_pipeline.v and never reaches this ALU.
    localparam OP_FPFMA = 5'd29;
    localparam OP_WMMA  = 5'd26;  // tensor core wmma

    // ---- helpers ---------------------------------------------------------
    // IEEE-754 total-order compare for FMIN/FMAX, matching fminf/fmaxf as
    // used by the functional model: a NaN operand loses, so the non-NaN
    // operand is returned; -0 and +0 compare equal (either may be returned).
    function is_nan;
        input [31:0] f;
        is_nan = (f[30:23] == 8'hFF) && (f[22:0] != 23'd0);
    endfunction

    function flt_lt;   // a < b for non-NaN IEEE-754 floats
        input [31:0] a;
        input [31:0] b;
        reg sa, sb;
        begin
            sa = a[31]; sb = b[31];
            if (sa != sb)
                // -0 < +0 is false; treat both zeros as equal
                flt_lt = sa && (((a | b) & 32'h7FFF_FFFF) != 32'd0);
            else if (!sa)
                flt_lt = (a[30:0] < b[30:0]);   // both positive
            else
                flt_lt = (a[30:0] > b[30:0]);   // both negative: order reverses
        end
    endfunction

    // int32 -> fp32, round-to-nearest-even (C's (float) cast).
    function [31:0] i2f;
        input [31:0] v;
        reg        sign;
        reg [31:0] mag;
        integer    msb, i;
        reg [7:0]  ex;
        reg [31:0] shifted;
        reg [23:0] mant;
        reg        guard, sticky, roundup;
        begin
            if (v == 32'd0) i2f = 32'd0;
            else begin
                sign = v[31];
                mag  = sign ? (~v + 32'd1) : v;   // INT32_MIN maps to itself
                msb = 0;
                for (i = 0; i < 32; i = i + 1)
                    if (mag[i]) msb = i;
                ex = 8'd127 + msb[7:0];
                if (msb >= 24) begin
                    shifted = mag >> (msb - 23);
                    mant    = shifted[23:0];
                    guard   = mag[msb - 24];
                    sticky  = ((mag & ((32'd1 << (msb - 24)) - 32'd1)) != 32'd0);
                end else begin
                    mant   = mag[23:0] << (23 - msb);
                    guard  = 1'b0;
                    sticky = 1'b0;
                end
                roundup = guard && (sticky || mant[0]);
                mant = mant + {23'd0, roundup};
                if (mant[23:0] == 24'h000000 || mant[23] == 1'b0) begin
                    // mantissa overflowed past 1.111...  -> renormalise
                    if (mant[23] == 1'b0 && roundup) begin
                        mant = 24'h800000;
                        ex   = ex + 8'd1;
                    end
                end
                i2f = {sign, ex, mant[22:0]};
            end
        end
    endfunction

    // fp32 -> int32, truncating toward zero (C's (int32_t) cast).
    function [31:0] f2i;
        input [31:0] f;
        reg        sign;
        reg [7:0]  ex;
        reg [23:0] mant;
        reg [31:0] mag;
        integer    sh;
        begin
            sign = f[31];
            ex   = f[30:23];
            mant = {1'b1, f[22:0]};
            if (ex < 8'd127) mag = 32'd0;                 // |f| < 1
            else if (ex > 8'd157) mag = 32'h8000_0000;    // out of range
            else begin
                sh = ex - 8'd150;                         // 150 = 127 + 23
                mag = (sh >= 0) ? ({8'd0, mant} << sh) : ({8'd0, mant} >> (-sh));
            end
            f2i = sign ? (~mag + 32'd1) : mag;
        end
    endfunction

    // 1. Integer Pipeline (3-Stage)
    reg [4:0] int_op_s1;
    reg [DATA_WIDTH-1:0] int_src1_s1, int_src2_s1;
    reg int_val_s1;
    reg [2:0] cvt_mode_s1;   // src3[0] selects the conversion direction
    
    // Stage 1: Latch inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_val_s1 <= 1'b0;
            int_op_s1 <= 5'd0;
            int_src1_s1 <= 32'd0;
            int_src2_s1 <= 32'd0;
            cvt_mode_s1 <= 3'd0;
        end else if (!stall_in) begin
            if (valid_in && (opcode == OP_ADD  || opcode == OP_SUB  ||
                             opcode == OP_AND  || opcode == OP_OR   ||
                             opcode == OP_XOR  || opcode == OP_SHL  ||
                             opcode == OP_SHR  || opcode == OP_SRA  ||
                             opcode == OP_SLT  || opcode == OP_SLTU ||
                             opcode == OP_MIN  || opcode == OP_MAX  ||
                             opcode == OP_FMIN || opcode == OP_FMAX ||
                             opcode == OP_CVT)) begin
                int_val_s1 <= 1'b1;
                int_op_s1 <= opcode;
                int_src1_s1 <= src1;
                int_src2_s1 <= src2;
                cvt_mode_s1 <= src3[2:0];
            end else begin
                int_val_s1 <= 1'b0;
            end
        end
    end

    // Stage 2: Execute
    reg [DATA_WIDTH-1:0] int_res_s2;
    reg int_val_s2;

    // shift amount is masked to 5 bits (model: `a << (b & 31)`)
    wire [4:0] sh_amt = int_src2_s1[4:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_val_s2 <= 1'b0;
            int_res_s2 <= 32'd0;
        end else if (!stall_in) begin
            int_val_s2 <= int_val_s1;

            case (int_op_s1)
                OP_ADD:  int_res_s2 <= int_src1_s1 + int_src2_s1;
                OP_SUB:  int_res_s2 <= int_src1_s1 - int_src2_s1;
                OP_AND:  int_res_s2 <= int_src1_s1 & int_src2_s1;
                OP_OR:   int_res_s2 <= int_src1_s1 | int_src2_s1;
                OP_XOR:  int_res_s2 <= int_src1_s1 ^ int_src2_s1;
                OP_SHL:  int_res_s2 <= int_src1_s1 << sh_amt;
                OP_SHR:  int_res_s2 <= int_src1_s1 >> sh_amt;
                OP_SRA:  int_res_s2 <= $signed(int_src1_s1) >>> sh_amt;
                OP_SLT:  int_res_s2 <= ($signed(int_src1_s1) < $signed(int_src2_s1)) ? 32'd1 : 32'd0;
                OP_SLTU: int_res_s2 <= (int_src1_s1 < int_src2_s1) ? 32'd1 : 32'd0;
                OP_MIN:  int_res_s2 <= ($signed(int_src1_s1) < $signed(int_src2_s1)) ? int_src1_s1 : int_src2_s1;
                OP_MAX:  int_res_s2 <= ($signed(int_src1_s1) > $signed(int_src2_s1)) ? int_src1_s1 : int_src2_s1;
                OP_FMIN: int_res_s2 <= is_nan(int_src1_s1) ? int_src2_s1 :
                                       is_nan(int_src2_s1) ? int_src1_s1 :
                                       flt_lt(int_src1_s1, int_src2_s1) ? int_src1_s1 : int_src2_s1;
                OP_FMAX: int_res_s2 <= is_nan(int_src1_s1) ? int_src2_s1 :
                                       is_nan(int_src2_s1) ? int_src1_s1 :
                                       flt_lt(int_src1_s1, int_src2_s1) ? int_src2_s1 : int_src1_s1;
                OP_CVT:  int_res_s2 <= cvt_mode_s1[0] ? f2i(int_src1_s1)
                                                      : i2f(int_src1_s1);
                default: int_res_s2 <= 32'd0;
            endcase
        end
    end

    // Stage 3: Writeback Alignment
    reg [DATA_WIDTH-1:0] int_res_s3;
    reg int_val_s3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_val_s3 <= 1'b0;
            int_res_s3 <= 32'd0;
        end else if (!stall_in) begin
            int_val_s3 <= int_val_s2;
            int_res_s3 <= int_res_s2;
        end
    end

    // 2. Multi-Cycle Integer Multiplier (4-Stage Pipeline)
    //
    // Serves MUL (low 32), MULHI (high 32 of the *signed* product) and the
    // ISA's integer FMA (rs1*rs2 + rs3). The product is taken as a full
    // signed 64-bit value so MULHI matches the model exactly:
    //   (uint32_t)(((int64_t)(int32_t)a * (int64_t)(int32_t)b) >> 32)
    reg mul_v1, mul_v2, mul_v3, mul_v4;
    reg [31:0] mul_a_s1, mul_b_s1, mul_c_s1;
    reg [31:0] mul_a_s2, mul_b_s2, mul_c_s2;
    reg [31:0] mul_a_s3, mul_b_s3, mul_c_s3;
    reg [1:0]  mul_k_s1, mul_k_s2, mul_k_s3;   // 0 = MUL, 1 = MULHI, 2 = IFMA
    reg [31:0] mul_st4_res;

    wire is_mul_op = (opcode == OP_MUL) || (opcode == OP_MULHI) ||
                     (opcode == OP_IFMA);
    wire [1:0] mul_kind_in = (opcode == OP_MULHI) ? 2'd1 :
                             (opcode == OP_IFMA)  ? 2'd2 : 2'd0;

    wire signed [63:0] mul_prod_s3 =
        $signed(mul_a_s3) * $signed(mul_b_s3);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mul_v1 <= 0; mul_v2 <= 0; mul_v3 <= 0; mul_v4 <= 0;
            mul_st4_res <= 0;
            mul_k_s1 <= 0; mul_k_s2 <= 0; mul_k_s3 <= 0;
        end else if (!stall_in) begin
            mul_v1 <= (valid_in && is_mul_op);
            mul_a_s1 <= src1;
            mul_b_s1 <= src2;
            mul_c_s1 <= src3;
            mul_k_s1 <= mul_kind_in;

            mul_v2 <= mul_v1;
            mul_a_s2 <= mul_a_s1;
            mul_b_s2 <= mul_b_s1;
            mul_c_s2 <= mul_c_s1;
            mul_k_s2 <= mul_k_s1;

            mul_v3 <= mul_v2;
            mul_a_s3 <= mul_a_s2;
            mul_b_s3 <= mul_b_s2;
            mul_c_s3 <= mul_c_s2;
            mul_k_s3 <= mul_k_s2;

            mul_v4 <= mul_v3;
            // Synthesis will retime the multiply across these registers.
            mul_st4_res <= (mul_k_s3 == 2'd1) ? mul_prod_s3[63:32] :
                           (mul_k_s3 == 2'd2) ? (mul_prod_s3[31:0] + mul_c_s3)
                                              :  mul_prod_s3[31:0];
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

    // Signed division, per the ISA and the functional model:
    //   b == 0            -> 0xFFFFFFFF
    //   INT32_MIN / -1    -> INT32_MIN (would overflow)
    //   otherwise         -> truncating signed quotient
    // The core loop is unsigned restoring division on the magnitudes; the
    // sign is applied on completion. Previously this unit was purely
    // unsigned and was also wired to opcode 3, which is MULHI in the ISA.
    reg        div_neg;        // quotient must be negated
    reg        div_special;    // result is forced (div-by-0 / overflow)
    reg [31:0] div_special_val;

    wire signed [31:0] div_a_s = src1;
    wire signed [31:0] div_b_s = src2;
    wire [31:0] div_a_mag = div_a_s[31] ? (~src1 + 32'd1) : src1;
    wire [31:0] div_b_mag = div_b_s[31] ? (~src2 + 32'd1) : src2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_busy <= 0;
            div_count <= 0;
            div_val_out <= 0;
            div_neg <= 0;
            div_special <= 0;
            div_special_val <= 0;
        end else begin
            div_val_out <= 0;
            if (valid_in && opcode == OP_DIV && !div_busy) begin
                div_busy <= 1'b1;
                div_count <= 32;
                div_dividend <= {32'd0, div_a_mag};
                div_divisor <= div_b_mag;
                div_neg <= (src1[31] ^ src2[31]);
                if (src2 == 32'd0) begin
                    div_special <= 1'b1;
                    div_special_val <= 32'hFFFF_FFFF;
                end else if (src1 == 32'h8000_0000 && src2 == 32'hFFFF_FFFF) begin
                    div_special <= 1'b1;
                    div_special_val <= 32'h8000_0000;
                end else begin
                    div_special <= 1'b0;
                end
            end else if (div_busy) begin
                if (div_count == 0) begin
                    div_busy <= 1'b0;
                    div_val_out <= 1'b1;
                    div_res_out <= div_special ? div_special_val :
                                   div_neg     ? (~div_dividend[31:0] + 32'd1)
                                               :   div_dividend[31:0];
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

    wire is_fp_op = (opcode == OP_FADD) || (opcode == OP_FMUL) || (opcode == OP_FPFMA);
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
        .valid_in(valid_in && !stall_in && (opcode == OP_FPFMA)),
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

    generate
        if (ENABLE_TENSOR) begin : tensor_gen
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
                .fp8_fmt(1'b0),
                .acc_clear(valid_in && opcode == OP_WMMA), // clear at issue
                .drain(wmma_v2), // shift a row toward acc_out before readout
                .act_in({src2, src1}),
                .weight_in({src3, src2}),
                .acc_out(wmma_acc_out),
                .out_valid() // manual tracking used instead
            );
        end else begin : no_tensor_gen
            assign wmma_acc_out = 128'd0;
        end
    endgenerate

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

    // Branch resolution moved out of the ALU. It used to own opcodes 10 and
    // 11 (OP_BRANCH / OP_JUMP), which are SRA and SLT in the ISA. Control
    // flow is now handled in titan_x5_pipeline.v against titan_x5_pc_unit,
    // so these outputs are retained for port compatibility and tied off.
    assign branch_valid_out  = 1'b0;
    assign branch_taken_out  = 1'b0;
    assign branch_target_out = {DATA_WIDTH{1'b0}};

endmodule
