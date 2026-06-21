// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

/*
 * Module: titan_x5_decoder
 * Description: Full GPU ISA Instruction Decoder.
 * Supports 32 opcodes across ALU, Memory, Control, Tensor, and SFU categories.
 * Custom 32-bit instruction format with 3-source operand support and predication.
 */
module titan_x5_decoder (
    input wire [31:0] inst,
    output wire [4:0] opcode,
    output wire [5:0] rd,
    output wire [5:0] rs1,
    output wire [5:0] rs2,
    output wire [5:0] rs3,
    output wire [15:0] imm,
    output wire        use_imm,
    output wire        is_branch,
    output wire        is_mem_load,
    output wire        is_mem_store,
    output wire        is_alu,
    output wire        is_valid,
    // new decode outputs
    output wire        is_wmma,        // tensor core wmma instruction
    output wire        is_sfu,         // special function unit (sin/cos/rsqrt)
    output wire        is_atomic,      // atomic memory operation
    output wire        is_barrier,     // thread barrier synchronization
    output wire        is_predicated,  // instruction is predicated
    output wire [1:0] pred_reg // predicate register selector
);

    // instruction format (custom 32-bit titan x5 isa v2):
    // [31:27] Opcode (5 bits)         = 32 instructions
    // [26:21] rd  (6 bits)            = 64 registers
    // [20:15] rs1 (6 bits)
    // [14:9]  rs2 (6 bits)
    // [8:3]   rs3 (6 bits)            = 3-source ops (FMA, etc.)
    // [2]     pred_sel[1]             = Predicate register bit 1
    // [1]     pred_sel[0]             = Predicate register bit 0
    // [0]     use_imm                 = Immediate mode flag
    //
    // when use_imm=1: rs2 and rs3 fields are reinterpreted as a 12-bit immediate
    // immediate: inst[14:3] zero-extended to 16 bits

    assign opcode  = inst[31:27];
    assign rd      = inst[26:21];
    assign rs1     = inst[20:15];
    assign rs2     = inst[14:9];
    assign rs3     = inst[8:3];
    assign use_imm = inst[0];
    assign imm     = {4'b0, inst[14:3]}; // 12-bit immediate zero-extended to 16

    assign pred_reg     = inst[2:1];
    assign is_predicated = (pred_reg != 2'b00); // p0 = always true (no predication)

    // opcode map (titan x5 isa v2)
    // 0:  ADD       - Integer Addition
    // 1:  SUB       - Integer Subtraction
    // 2:  MUL       - Integer Multiplication (lower 32 bits)
    // 3:  MULHI     - Integer Multiplication (upper 32 bits)
    // 4:  DIV       - Integer Division
    // 5:  AND       - Bitwise AND
    // 6:  OR        - Bitwise OR
    // 7:  XOR       - Bitwise XOR
    // 8:  SHL       - Shift Left Logical
    // 9:  SHR       - Shift Right Logical
    // 10: SRA       - Shift Right Arithmetic
    // 11: SLT       - Set Less Than (signed)
    // 12: SLTU      - Set Less Than (unsigned)
    // 13: MIN       - Minimum
    // 14: MAX       - Maximum
    // 15: FMA       - Fused Multiply-Add (rd = rs1 * rs2 + rs3)
    // 16: FADD      - FP32 Add
    // 17: FMUL      - FP32 Multiply
    // 18: FMIN      - FP32 Min
    // 19: FMAX      - FP32 Max
    // 20: CVT       - Int/Float Conversion
    // 21: SETP      - Set Predicate Register
    // --- Memory ---
    // 22: LOAD      - Memory Load
    // 23: STORE     - Memory Store
    // --- Control ---
    // 24: BRANCH    - Conditional Branch
    // 25: BARRIER   - Warp Barrier / __syncthreads()
    // --- AI / Tensor ---
    // 26: WMMA      - Warp Matrix Multiply Accumulate (Tensor Core dispatch)
    // --- SFU ---
    // 27: SIN       - Sine (Special Function Unit)
    // 28: COS       - Cosine (Special Function Unit)
    // 29: RSQRT     - Reciprocal Square Root
    // --- Atomic ---
    // 30: ATOM_ADD  - Atomic Add to global memory
    // 31: ATOM_CAS  - Atomic Compare-And-Swap

    assign is_alu       = (opcode <= 5'd21);
    assign is_mem_load  = (opcode == 5'd22);
    assign is_mem_store = (opcode == 5'd23);
    assign is_branch    = (opcode == 5'd24);
    assign is_barrier   = (opcode == 5'd25);
    assign is_wmma      = (opcode == 5'd26);
    assign is_sfu       = (opcode >= 5'd27) && (opcode <= 5'd29);
    assign is_atomic    = (opcode >= 5'd30);

    assign is_valid     = 1'b1; // all 32 opcodes are valid in v2 isa

endmodule
