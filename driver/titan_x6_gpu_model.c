// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// Titan X6 functional GPU model. See titan_x6_gpu_model.h for the interface
// and titan_x6_isa.h for the ISA contract.

#include "titan_x6_gpu_model.h"
#include "titan_x6_isa.h"
#include "titan_x6_drv.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define TITAN_MAX_STEPS_PER_THREAD (1u << 26)  // watchdog: 67M instructions

struct titan_gpu_model {
    uint8_t  *vram;
    uint32_t  vram_bytes;

    uint64_t *ring;
    uint32_t  ring_qwords;
    uint32_t  rptr;
    uint32_t  wptr;

    uint32_t  ctrl;
    uint32_t  status;
    uint32_t  ring_base;
    uint32_t  fence_seq;
    uint32_t  intr_status;

    uint64_t  perf_instr;
    uint64_t  perf_wmma;
};

// ---------------------------------------------------------------------------
// FP8 E4M3 (1s / 4e / 3m, bias 7, no infinities, S.1111.111 = NaN)
// ---------------------------------------------------------------------------
float titan_fp8_to_float(uint8_t b)
{
    int      s = (b >> 7) & 1;
    int      e = (b >> 3) & 0xF;
    int      m = b & 0x7;
    float    v;

    if (e == 0xF && m == 0x7)
        return s ? -NAN : NAN;
    if (e == 0)
        v = (float)m / 8.0f * (1.0f / 64.0f);          // subnormal, 2^-6
    else
        v = (1.0f + (float)m / 8.0f) * ldexpf(1.0f, e - 7);
    return s ? -v : v;
}

uint8_t titan_fp8_from_float(float f)
{
    uint8_t s = (f < 0.0f || (f == 0.0f && signbit(f))) ? 0x80 : 0x00;
    float   a = fabsf(f);

    if (isnan(f))
        return s | 0x7F;
    if (a > 448.0f)                                    // E4M3 max magnitude
        a = 448.0f;
    if (a < ldexpf(1.0f, -9))                          // below half of min sub
        return s;

    int ef;
    frexpf(a, &ef);                                    // a = frac * 2^ef, frac in [0.5,1)
    int e = ef - 1;                                    // a = 1.xxx * 2^e
    if (e < -6) {
        // subnormal: quantize to multiples of 2^-9
        int m = (int)lrintf(a * 512.0f);
        if (m > 7) { m = 0; e = -6; return s | (uint8_t)((1 << 3) | 0); }
        return s | (uint8_t)m;
    }
    // normal: mantissa in units of 1/8
    int m = (int)lrintf((a / ldexpf(1.0f, e) - 1.0f) * 8.0f);
    if (m == 8) { m = 0; e++; }
    if (e > 8 || (e == 8 && m == 7))                   // clamp to 448 (e=8,m=6)
        { e = 8; m = 6; }
    return s | (uint8_t)(((e + 7) << 3) | m);
}

// ---------------------------------------------------------------------------
// Model lifecycle
// ---------------------------------------------------------------------------
titan_gpu_model_t *titan_gpu_create(uint32_t vram_bytes)
{
    titan_gpu_model_t *gpu = (titan_gpu_model_t *)calloc(1, sizeof(*gpu));
    if (!gpu)
        return NULL;
    gpu->vram = (uint8_t *)calloc(1, vram_bytes);
    if (!gpu->vram) {
        free(gpu);
        return NULL;
    }
    gpu->vram_bytes = vram_bytes;
    gpu->status     = TITAN_STAT_READY;
    return gpu;
}

void titan_gpu_destroy(titan_gpu_model_t *gpu)
{
    if (!gpu)
        return;
    free(gpu->vram);
    free(gpu);
}

void titan_gpu_bind_ring(titan_gpu_model_t *gpu, uint64_t *ring,
                         uint32_t num_qwords)
{
    gpu->ring        = ring;
    gpu->ring_qwords = num_qwords;
    gpu->rptr        = 0;
    gpu->wptr        = 0;
}

uint8_t *titan_gpu_vram(titan_gpu_model_t *gpu)       { return gpu->vram; }
uint32_t titan_gpu_vram_size(titan_gpu_model_t *gpu)  { return gpu->vram_bytes; }

// ---------------------------------------------------------------------------
// VRAM access helpers (bounds-checked; errors latch TITAN_STAT_ERROR)
// ---------------------------------------------------------------------------
static int vram_ok(titan_gpu_model_t *gpu, uint32_t addr, uint32_t len)
{
    if ((uint64_t)addr + len > gpu->vram_bytes) {
        fprintf(stderr, "[titan-gpu] VRAM fault: addr=0x%08X len=%u\n",
                addr, len);
        gpu->status |= TITAN_STAT_ERROR;
        return 0;
    }
    return 1;
}

static uint32_t vram_rd32(titan_gpu_model_t *gpu, uint32_t addr)
{
    uint32_t v = 0;
    if (vram_ok(gpu, addr, 4))
        memcpy(&v, gpu->vram + addr, 4);
    return v;
}

static void vram_wr32(titan_gpu_model_t *gpu, uint32_t addr, uint32_t v)
{
    if (vram_ok(gpu, addr, 4))
        memcpy(gpu->vram + addr, &v, 4);
}

// ---------------------------------------------------------------------------
// Tensor core array: one WMMA tile op (titan_x6_wmma_dispatch semantics)
// ---------------------------------------------------------------------------
static void exec_wmma(titan_gpu_model_t *gpu, uint32_t c_addr, uint32_t a_addr,
                      uint32_t b_addr, uint32_t flags,
                      uint32_t lda, uint32_t ldb, uint32_t ldc)
{
    int fp8 = (flags & TX6_WMMA_FLAG_FP8) != 0;
    int r, c, k;

    for (r = 0; r < TX6_WMMA_M; r++) {
        for (c = 0; c < TX6_WMMA_N; c++) {
            uint32_t c_ea = c_addr + 4u * ((uint32_t)r * ldc + (uint32_t)c);
            if (fp8) {
                float acc;
                uint32_t bits = vram_rd32(gpu, c_ea);
                memcpy(&acc, &bits, 4);
                for (k = 0; k < TX6_WMMA_K; k++) {
                    uint32_t a_ea = a_addr + (uint32_t)r * lda + (uint32_t)k;
                    uint32_t b_ea = b_addr + (uint32_t)k * ldb + (uint32_t)c;
                    if (!vram_ok(gpu, a_ea, 1) || !vram_ok(gpu, b_ea, 1))
                        return;
                    acc += titan_fp8_to_float(gpu->vram[a_ea]) *
                           titan_fp8_to_float(gpu->vram[b_ea]);
                }
                memcpy(&bits, &acc, 4);
                vram_wr32(gpu, c_ea, bits);
            } else {
                int32_t acc = (int32_t)vram_rd32(gpu, c_ea);
                for (k = 0; k < TX6_WMMA_K; k++) {
                    uint32_t a_ea = a_addr + (uint32_t)r * lda + (uint32_t)k;
                    uint32_t b_ea = b_addr + (uint32_t)k * ldb + (uint32_t)c;
                    if (!vram_ok(gpu, a_ea, 1) || !vram_ok(gpu, b_ea, 1))
                        return;
                    acc += (int32_t)(int8_t)gpu->vram[a_ea] *
                           (int32_t)(int8_t)gpu->vram[b_ea];
                }
                vram_wr32(gpu, c_ea, (uint32_t)acc);
            }
        }
    }
    gpu->perf_wmma++;
}

// ---------------------------------------------------------------------------
// SM: single-thread ISA interpreter (titan_x5_decoder.v field semantics)
// ---------------------------------------------------------------------------
static int exec_thread(titan_gpu_model_t *gpu, uint32_t code_addr,
                       uint32_t param_addr, uint32_t tid, uint32_t nthreads)
{
    uint32_t r[64];
    int      p[4] = { 1, 0, 0, 0 };  // P0 hardwired true
    uint32_t pc   = 0;
    uint32_t steps = 0;

    memset(r, 0, sizeof(r));
    r[TX6_REG_PARAM]    = param_addr;
    r[TX6_REG_TID]      = tid;
    r[TX6_REG_NTHREADS] = nthreads;

    for (;;) {
        if (++steps > TITAN_MAX_STEPS_PER_THREAD) {
            fprintf(stderr, "[titan-gpu] watchdog: thread %u exceeded %u "
                    "instructions (runaway kernel?)\n", tid,
                    TITAN_MAX_STEPS_PER_THREAD);
            gpu->status |= TITAN_STAT_ERROR;
            return -1;
        }

        uint32_t inst = vram_rd32(gpu, code_addr + pc * 4);
        if (gpu->status & TITAN_STAT_ERROR)
            return -1;

        uint32_t op   = TX6_F_OP(inst);
        uint32_t rd   = TX6_F_RD(inst);
        uint32_t rs1  = TX6_F_RS1(inst);
        uint32_t pred = TX6_F_PRED(inst);
        int      uimm = TX6_F_UIMM(inst);
        uint32_t imm  = TX6_F_IMM(inst);
        // operand B: immediate or rs2 (decoder: id_data2 = use_imm ? imm : rs2)
        uint32_t b    = uimm ? imm : r[TX6_F_RS2(inst)];
        uint32_t a    = r[rs1];
        uint32_t next_pc = pc + 1;

        gpu->perf_instr++;

        if (!p[pred]) {          // predicated off: fall through
            pc = next_pc;
            continue;
        }

        switch (op) {
        case TX6_OP_ADD:   r[rd] = a + b; break;
        case TX6_OP_SUB:   r[rd] = a - b; break;
        case TX6_OP_MUL:   r[rd] = (uint32_t)((int64_t)(int32_t)a *
                                              (int64_t)(int32_t)b); break;
        case TX6_OP_MULHI: r[rd] = (uint32_t)(((int64_t)(int32_t)a *
                                               (int64_t)(int32_t)b) >> 32); break;
        case TX6_OP_DIV:
            if ((int32_t)b == 0)              r[rd] = 0xFFFFFFFFu;
            else if ((int32_t)a == INT32_MIN && (int32_t)b == -1)
                                              r[rd] = a;
            else                              r[rd] = (uint32_t)((int32_t)a /
                                                                 (int32_t)b);
            break;
        case TX6_OP_AND:   r[rd] = a & b; break;
        case TX6_OP_OR:    r[rd] = a | b; break;
        case TX6_OP_XOR:   r[rd] = a ^ b; break;
        case TX6_OP_SHL:   r[rd] = a << (b & 31); break;
        case TX6_OP_SHR:   r[rd] = a >> (b & 31); break;
        case TX6_OP_SRA:   r[rd] = (uint32_t)((int32_t)a >> (b & 31)); break;
        case TX6_OP_SLT:   r[rd] = ((int32_t)a < (int32_t)b) ? 1u : 0u; break;
        case TX6_OP_SLTU:  r[rd] = (a < b) ? 1u : 0u; break;
        case TX6_OP_MIN:   r[rd] = ((int32_t)a < (int32_t)b) ? a : b; break;
        case TX6_OP_MAX:   r[rd] = ((int32_t)a > (int32_t)b) ? a : b; break;
        case TX6_OP_FMA:   r[rd] = (uint32_t)((int64_t)(int32_t)a *
                                              (int64_t)(int32_t)b) +
                                   r[TX6_F_RS3(inst)]; break;
        case TX6_OP_FADD: case TX6_OP_FMUL:
        case TX6_OP_FMIN: case TX6_OP_FMAX: {
            float fa, fb, fr;
            uint32_t bb = b;
            memcpy(&fa, &a, 4);
            memcpy(&fb, &bb, 4);
            switch (op) {
            case TX6_OP_FADD: fr = fa + fb; break;
            case TX6_OP_FMUL: fr = fa * fb; break;
            case TX6_OP_FMIN: fr = fminf(fa, fb); break;
            default:          fr = fmaxf(fa, fb); break;
            }
            memcpy(&r[rd], &fr, 4);
            break;
        }
        case TX6_OP_CVT:
            if (TX6_F_RS3(inst) & 1) {        // fp32 -> int32
                float fa;
                memcpy(&fa, &a, 4);
                r[rd] = (uint32_t)(int32_t)fa;
            } else {                          // int32 -> fp32
                float fr = (float)(int32_t)a;
                memcpy(&r[rd], &fr, 4);
            }
            break;
        case TX6_OP_SETP: {
            uint32_t cond = (rd >> 2) & 7;
            uint32_t pdst = rd & 3;
            int      res  = 0;
            switch (cond) {
            case TX6_CMP_EQ:  res = (a == b); break;
            case TX6_CMP_NE:  res = (a != b); break;
            case TX6_CMP_LT:  res = ((int32_t)a <  (int32_t)b); break;
            case TX6_CMP_GE:  res = ((int32_t)a >= (int32_t)b); break;
            case TX6_CMP_LTU: res = (a <  b); break;
            case TX6_CMP_GEU: res = (a >= b); break;
            }
            if (pdst != 0)
                p[pdst] = res;
            break;
        }
        case TX6_OP_LOAD:  r[rd] = vram_rd32(gpu, a + b); break;
        case TX6_OP_STORE: vram_wr32(gpu, a + b, r[rd]); break;
        case TX6_OP_BRANCH:
            next_pc = imm;
            break;
        case TX6_OP_BARRIER:
            if (uimm && imm == TX6_EXIT_IMM)
                return 0;                     // EXIT: thread retires
            break;                            // bar.sync: nop in 1-thread model
        case TX6_OP_WMMA:
            exec_wmma(gpu, r[rd], a, r[TX6_F_RS2(inst)], TX6_F_RS3(inst),
                      r[TX6_REG_LDA], r[TX6_REG_LDB], r[TX6_REG_LDC]);
            break;
        case TX6_OP_SIN: case TX6_OP_COS: case TX6_OP_RSQRT: {
            float fa, fr;
            memcpy(&fa, &a, 4);
            fr = (op == TX6_OP_SIN) ? sinf(fa)
               : (op == TX6_OP_COS) ? cosf(fa)
               : 1.0f / sqrtf(fa);
            memcpy(&r[rd], &fr, 4);
            break;
        }
        case TX6_OP_ATOM_ADD: {
            uint32_t old = vram_rd32(gpu, a);
            vram_wr32(gpu, a, old + b);
            r[rd] = old;
            break;
        }
        case TX6_OP_ATOM_CAS: {
            uint32_t old = vram_rd32(gpu, a);
            if (old == r[TX6_F_RS2(inst)])
                vram_wr32(gpu, a, r[TX6_F_RS3(inst)]);
            r[rd] = old;
            break;
        }
        default:
            fprintf(stderr, "[titan-gpu] illegal opcode %u at pc=%u\n", op, pc);
            gpu->status |= TITAN_STAT_ERROR;
            return -1;
        }

        if (gpu->status & TITAN_STAT_ERROR)
            return -1;
        pc = next_pc;
    }
}

// ---------------------------------------------------------------------------
// Host Command Processor: drain the ring (titan_x5_command_processor
// opcodes: DISPATCH / DMA / FENCE)
// ---------------------------------------------------------------------------
static uint64_t ring_pop(titan_gpu_model_t *gpu)
{
    uint64_t q = gpu->ring[gpu->rptr];
    gpu->rptr = (gpu->rptr + 1) % gpu->ring_qwords;
    return q;
}

static void process_ring(titan_gpu_model_t *gpu)
{
    if (!gpu->ring || !(gpu->ctrl & 1))
        return;

    gpu->status |= TITAN_STAT_BUSY;

    while (gpu->rptr != gpu->wptr) {
        uint64_t hdr     = ring_pop(gpu);
        uint8_t  op      = (uint8_t)(hdr & 0xFF);
        uint64_t payload = hdr >> 8;

        switch (op) {
        case TITAN_CMD_NOP:
            break;

        case TITAN_CMD_DISPATCH: {
            uint64_t q1        = ring_pop(gpu);
            uint64_t q2        = ring_pop(gpu);
            uint32_t code_addr = (uint32_t)q1;
            uint32_t param     = (uint32_t)q2;
            uint32_t nthreads  = (uint32_t)(q2 >> 32);
            uint32_t t;
            if (nthreads == 0)
                nthreads = 1;
            for (t = 0; t < nthreads; t++)
                if (exec_thread(gpu, code_addr, param, t, nthreads) != 0)
                    break;
            break;
        }

        case TITAN_CMD_DMA: {
            uint64_t src = ring_pop(gpu);
            uint64_t dst = ring_pop(gpu);
            uint64_t len = ring_pop(gpu);
            if (vram_ok(gpu, (uint32_t)src, (uint32_t)len) &&
                vram_ok(gpu, (uint32_t)dst, (uint32_t)len))
                memmove(gpu->vram + dst, gpu->vram + src, (size_t)len);
            break;
        }

        case TITAN_CMD_FENCE:
            gpu->fence_seq    = (uint32_t)payload;
            gpu->intr_status |= 1;            // fence interrupt
            break;

        case TITAN_CMD_DRAW:
        default:
            // graphics path not modeled; skip
            break;
        }
    }

    gpu->status &= ~TITAN_STAT_BUSY;
}

// ---------------------------------------------------------------------------
// MMIO
// ---------------------------------------------------------------------------
uint32_t titan_gpu_mmio_read(titan_gpu_model_t *gpu, uint32_t offset)
{
    switch (offset) {
    case TITAN_REG_ID:          return TITAN_ID_VALUE;
    case TITAN_REG_CTRL:        return gpu->ctrl;
    case TITAN_REG_STATUS:      return gpu->status;
    case TITAN_REG_RING_BASE:   return gpu->ring_base;
    case TITAN_REG_RING_WPTR:   return gpu->wptr;
    case TITAN_REG_RING_RPTR:   return gpu->rptr;
    case TITAN_REG_FENCE_SEQ:   return gpu->fence_seq;
    case TITAN_REG_INTR_STATUS: return gpu->intr_status;
    case TITAN_REG_VRAM_SIZE:   return gpu->vram_bytes;
    case TITAN_REG_PERF_INSTR:  return (uint32_t)gpu->perf_instr;
    case TITAN_REG_PERF_WMMA:   return (uint32_t)gpu->perf_wmma;
    default:                    return 0xDEADBEEFu;
    }
}

void titan_gpu_mmio_write(titan_gpu_model_t *gpu, uint32_t offset,
                          uint32_t value)
{
    switch (offset) {
    case TITAN_REG_CTRL:
        gpu->ctrl = value;
        break;
    case TITAN_REG_RING_BASE:
        gpu->ring_base = value;
        break;
    case TITAN_REG_RING_WPTR:
        // Doorbell. The synchronous model retires the whole batch here;
        // real silicon would return immediately and raise the fence
        // interrupt later.
        gpu->wptr = value % gpu->ring_qwords;
        process_ring(gpu);
        break;
    case TITAN_REG_INTR_STATUS:
        gpu->intr_status &= ~value;           // write-1-to-clear
        break;
    default:
        break;
    }
}
