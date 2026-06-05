#ifndef TITAN_X5_ISA_H
#define TITAN_X5_ISA_H

#include <stdint.h>

/*
 * Titan X5 GPU Instruction Set Architecture
 * Firmware & Driver Definitions
 */

// --- 32-bit ALU Opcodes ---
#define TX5_OP_ADD      0x01
#define TX5_OP_SUB      0x02
#define TX5_OP_MUL      0x03
#define TX5_OP_DIV      0x04
#define TX5_OP_AND      0x05
#define TX5_OP_OR       0x06
#define TX5_OP_XOR      0x07
#define TX5_OP_SHL      0x08
#define TX5_OP_SHR      0x09
#define TX5_OP_FADD     0x0A
#define TX5_OP_FMUL     0x0B
#define TX5_OP_FMADD    0x0C

// --- Memory Operations ---
#define TX5_OP_LD       0x10
#define TX5_OP_ST       0x11
#define TX5_OP_MOV      0x12
#define TX5_OP_LDC      0x13 // Load Constant

// --- Control Operations ---
#define TX5_OP_JMP      0x20
#define TX5_OP_BEQ      0x21
#define TX5_OP_BNE      0x22
#define TX5_OP_SYNC     0x2D
#define TX5_OP_YIELD    0x2E
#define TX5_OP_HALT     0x2F

// --- SR Engine Control Operations ---
#define TX5_OP_SR_CFG   0x30
#define TX5_OP_SR_TRIG  0x31
#define TX5_OP_SR_WAIT  0x32

// --- Register Map (MMIO Base Addresses) ---
#define TX5_BASE_ADDR           0x40000000
#define TX5_CMD_PROC_REG        (TX5_BASE_ADDR + 0x0000)
#define TX5_CMD_STATUS_REG      (TX5_BASE_ADDR + 0x0004)
#define TX5_PERF_CNT_REG        (TX5_BASE_ADDR + 0x0008)
#define TX5_PWR_MGMT_REG        (TX5_BASE_ADDR + 0x000C)

// --- Apex SR Engine Register Map ---
#define TX5_SR_ENGINE_BASE      (TX5_BASE_ADDR + 0x1000)
#define TX5_SR_IN_WARP_ID       (TX5_SR_ENGINE_BASE + 0x0000)
#define TX5_SR_IN_PIXEL_X       (TX5_SR_ENGINE_BASE + 0x0004)
#define TX5_SR_IN_PIXEL_Y       (TX5_SR_ENGINE_BASE + 0x0008)
#define TX5_SR_IN_MOTION_X      (TX5_SR_ENGINE_BASE + 0x000C)
#define TX5_SR_IN_MOTION_Y      (TX5_SR_ENGINE_BASE + 0x0010)
#define TX5_SR_IN_HASH_SEED     (TX5_SR_ENGINE_BASE + 0x0014)
#define TX5_SR_CONTROL          (TX5_SR_ENGINE_BASE + 0x0018)
#define TX5_SR_STATUS           (TX5_SR_ENGINE_BASE + 0x001C)
#define TX5_SR_OUT_TAG          (TX5_SR_ENGINE_BASE + 0x0020)
#define TX5_SR_OUT_CONFIDENCE   (TX5_SR_ENGINE_BASE + 0x0024)

// SR Control Bits
#define TX5_SR_CTRL_IN_VALID    (1 << 0)
#define TX5_SR_CTRL_OUT_READY   (1 << 1)

// SR Status Bits
#define TX5_SR_STAT_IN_READY    (1 << 0)
#define TX5_SR_STAT_OUT_VALID   (1 << 1)
#define TX5_SR_STAT_CACHE_HIT   (1 << 2)
#define TX5_SR_STAT_CACHE_MISS  (1 << 3)

// CMD Status Bits
#define TX5_CMD_STAT_READY      (1 << 0)

// --- Command Construction Macros ---
// Instruction Format: [31:24] Opcode | [23:16] Rd | [15:8] Rs1 | [7:0] Rs2/Imm
#define TX5_INSTR(opcode, rd, rs1, rs2_imm) \
    (((uint32_t)(opcode) << 24) | ((uint32_t)(rd) << 16) | ((uint32_t)(rs1) << 8) | ((uint32_t)(rs2_imm)))

#endif // TITAN_X5_ISA_H
