// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// Titan X6 ISA definitions (software stack).
//
// Bit-level encoding matches rtl/core/titan_x5_decoder.v (ISA v2, carried
// forward unchanged into the X6 SMs):
//
//   [31:27] opcode (5 bits, 32 instructions)
//   [26:21] rd     (6 bits, 64 registers per thread)
//   [20:15] rs1
//   [14:9]  rs2
//   [8:3]   rs3
//   [2:1]   pred   (predicate register select; 0 = always execute)
//   [0]     use_imm
//
// When use_imm = 1 the rs2/rs3 fields ([14:3]) are reinterpreted as a
// 12-bit zero-extended immediate.
//
// Everything below the encoding (operand roles for LOAD/STORE/SETP/BRANCH/
// WMMA, the ABI registers, the exit convention) is the software
// architecture contract shared by the compiler, the driver and the
// functional GPU model in titan_x6_gpu_model.c.

#ifndef TITAN_X6_ISA_H
#define TITAN_X6_ISA_H

#include <stdint.h>

// ---------------------------------------------------------------------------
// Opcodes (titan_x5_decoder.v opcode map, verbatim)
// ---------------------------------------------------------------------------
enum {
    TX6_OP_ADD      = 0,   // rd = rs1 + (imm | rs2)
    TX6_OP_SUB      = 1,   // rd = rs1 - (imm | rs2)
    TX6_OP_MUL      = 2,   // rd = (rs1 * rs2)[31:0]
    TX6_OP_MULHI    = 3,   // rd = (rs1 * rs2)[63:32] (signed)
    TX6_OP_DIV      = 4,   // rd = rs1 / rs2 (signed)
    TX6_OP_AND      = 5,
    TX6_OP_OR       = 6,
    TX6_OP_XOR      = 7,
    TX6_OP_SHL      = 8,
    TX6_OP_SHR      = 9,   // logical
    TX6_OP_SRA      = 10,  // arithmetic
    TX6_OP_SLT      = 11,  // rd = (rs1 < rs2) ? 1 : 0 (signed)
    TX6_OP_SLTU     = 12,
    TX6_OP_MIN      = 13,
    TX6_OP_MAX      = 14,
    TX6_OP_FMA      = 15,  // rd = rs1 * rs2 + rs3 (integer)
    TX6_OP_FADD     = 16,  // fp32
    TX6_OP_FMUL     = 17,  // fp32
    TX6_OP_FMIN     = 18,
    TX6_OP_FMAX     = 19,
    TX6_OP_CVT      = 20,  // rs3[0]=0: int->fp32, 1: fp32->int
    TX6_OP_SETP     = 21,  // set predicate, see below
    TX6_OP_LOAD     = 22,  // rd = mem32[rs1 + (imm | rs2)]
    TX6_OP_STORE    = 23,  // mem32[rs1 + (imm | rs2)] = rd
    TX6_OP_BRANCH   = 24,  // pc = imm (absolute instr index); honors pred
    TX6_OP_BARRIER  = 25,  // imm == 0xFFF => EXIT (end of kernel thread)
    TX6_OP_WMMA     = 26,  // tensor tile op, see below
    TX6_OP_SIN      = 27,
    TX6_OP_COS      = 28,
    TX6_OP_RSQRT    = 29,
    TX6_OP_ATOM_ADD = 30,  // rd = old mem32[rs1]; mem32[rs1] += rs2
    TX6_OP_ATOM_CAS = 31   // rd = old; if (old == rs2) mem32[rs1] = rs3
};

// ---------------------------------------------------------------------------
// SETP (opcode 21): rd field carries {cond[2:0], pdst[1:0]}
//   P[pdst] = compare(rs1, rs2_or_imm)
// Predicated execution: any instruction with pred != 0 executes only when
// P[pred] is true. P0 is hardwired "always".
// ---------------------------------------------------------------------------
enum {
    TX6_CMP_EQ  = 0,
    TX6_CMP_NE  = 1,
    TX6_CMP_LT  = 2,   // signed
    TX6_CMP_GE  = 3,   // signed
    TX6_CMP_LTU = 4,
    TX6_CMP_GEU = 5
};
#define TX6_SETP_RD(cond, pdst)  ((((cond) & 0x7) << 2) | ((pdst) & 0x3))

// ---------------------------------------------------------------------------
// WMMA (opcode 26): one instruction = one (16,16,16) tile MAC through the
// titan_x6_wmma_dispatch / titan_x6_tensor_core_array pair.
//
//   rd  = register holding C tile base address (32-bit accumulators)
//   rs1 = register holding A tile base address (1 byte per element)
//   rs2 = register holding B tile base address (1 byte per element)
//   rs3 = literal flag field: bit0: 0 = INT8, 1 = FP8 (E4M3)
//
// Row strides in *elements* come from the ABI registers below.
// Semantics: C[r][c] += sum_k A[r][k] * B[k][c]   (accumulating)
//   A element  = byte  [R[rs1] +     r*R[58] + k]
//   B element  = byte  [R[rs2] +     k*R[59] + c]
//   C element  = word32[R[rd]  + 4*(r*R[60] + c)]  (int32 or fp32 by mode)
// ---------------------------------------------------------------------------
#define TX6_WMMA_M        16
#define TX6_WMMA_N        16
#define TX6_WMMA_K        16
#define TX6_WMMA_FLAG_FP8 0x1

// ---------------------------------------------------------------------------
// ABI registers (kernel entry state set by the command processor model)
// ---------------------------------------------------------------------------
#define TX6_REG_ZERO       0   // reads as 0 (all regs cleared at entry)
#define TX6_REG_PARAM      1   // R1 = kernel parameter block VRAM address
#define TX6_REG_LDA        58  // WMMA: A row stride (elements)
#define TX6_REG_LDB        59  // WMMA: B row stride (elements)
#define TX6_REG_LDC        60  // WMMA: C row stride (elements)
#define TX6_REG_NTHREADS   61  // launch width
#define TX6_REG_TID        62  // thread id

#define TX6_EXIT_IMM       0xFFF  // BARRIER #0xFFF == thread exit

// ---------------------------------------------------------------------------
// Encoding helpers
// ---------------------------------------------------------------------------
static inline uint32_t tx6_enc_r(uint32_t op, uint32_t rd, uint32_t rs1,
                                 uint32_t rs2, uint32_t rs3, uint32_t pred)
{
    return (op << 27) | ((rd & 63u) << 21) | ((rs1 & 63u) << 15) |
           ((rs2 & 63u) << 9) | ((rs3 & 63u) << 3) | ((pred & 3u) << 1);
}

static inline uint32_t tx6_enc_i(uint32_t op, uint32_t rd, uint32_t rs1,
                                 uint32_t imm12, uint32_t pred)
{
    return (op << 27) | ((rd & 63u) << 21) | ((rs1 & 63u) << 15) |
           ((imm12 & 0xFFFu) << 3) | ((pred & 3u) << 1) | 1u;
}

// Field extractors (mirror the decoder's continuous assigns)
#define TX6_F_OP(i)   (((i) >> 27) & 0x1F)
#define TX6_F_RD(i)   (((i) >> 21) & 0x3F)
#define TX6_F_RS1(i)  (((i) >> 15) & 0x3F)
#define TX6_F_RS2(i)  (((i) >> 9)  & 0x3F)
#define TX6_F_RS3(i)  (((i) >> 3)  & 0x3F)
#define TX6_F_PRED(i) (((i) >> 1)  & 0x3)
#define TX6_F_IMM(i)  (((i) >> 3)  & 0xFFF)
#define TX6_F_UIMM(i) ((i) & 1u)

// ---------------------------------------------------------------------------
// TBIN kernel image format (produced by compiler/titan_compiler.py)
// ---------------------------------------------------------------------------
#define TX6_TBIN_MAGIC   0x4E494254u  // "TBIN" little-endian
#define TX6_TBIN_VERSION 1u

typedef struct {
    uint32_t magic;
    uint32_t version;
    uint32_t flags;      // bit0: uses tensor cores
    uint32_t num_words;  // instruction count
} tx6_tbin_header_t;

#endif // TITAN_X6_ISA_H
