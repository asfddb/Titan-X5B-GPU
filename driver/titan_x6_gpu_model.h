// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// Functional (transaction-level) model of the Titan X6 GPU as seen from the
// PCIe bus: an MMIO register file (BAR0), GDDR7 VRAM (BAR1), and a Host
// Command Processor that consumes the ring buffer and drives the SMs and
// the tensor core array.
//
// The instruction interpreter implements the ISA contract in titan_x6_isa.h,
// whose encoding is bit-identical to rtl/core/titan_x5_decoder.v. WMMA is
// modeled at tile granularity, matching one full pass through
// rtl/tensor/titan_x6_wmma_dispatch.v (16x16x16, INT8 or FP8-E4M3 operands,
// 32-bit accumulators).

#ifndef TITAN_X6_GPU_MODEL_H
#define TITAN_X6_GPU_MODEL_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// --- BAR0 register map -----------------------------------------------------
#define TITAN_REG_ID          0x000  // RO: 0x71760006 ("X6")
#define TITAN_REG_CTRL        0x004  // bit0: enable
#define TITAN_REG_STATUS      0x008  // bit0: ready, bit1: busy, bit2: error
#define TITAN_REG_RING_BASE   0x00C  // ring base (system-memory address)
#define TITAN_REG_RING_WPTR   0x010  // doorbell: write pointer (qwords)
#define TITAN_REG_RING_RPTR   0x014  // RO: read pointer (qwords)
#define TITAN_REG_FENCE_SEQ   0x018  // RO: last retired fence seqno
#define TITAN_REG_INTR_STATUS 0x01C  // W1C: bit0 = fence interrupt
#define TITAN_REG_VRAM_SIZE   0x020  // RO: VRAM bytes
#define TITAN_REG_PERF_INSTR  0x024  // RO: instructions retired (low 32)
#define TITAN_REG_PERF_WMMA   0x028  // RO: WMMA tile ops retired

#define TITAN_ID_VALUE        0x71760006u

#define TITAN_STAT_READY      (1u << 0)
#define TITAN_STAT_BUSY       (1u << 1)
#define TITAN_STAT_ERROR      (1u << 2)

typedef struct titan_gpu_model titan_gpu_model_t;

titan_gpu_model_t *titan_gpu_create(uint32_t vram_bytes);
void               titan_gpu_destroy(titan_gpu_model_t *gpu);

// The command ring lives in system memory (the driver owns it); the GPU
// "DMAs" packets out of it. In the model that is a direct pointer.
void titan_gpu_bind_ring(titan_gpu_model_t *gpu, uint64_t *ring,
                         uint32_t num_qwords);

uint32_t titan_gpu_mmio_read (titan_gpu_model_t *gpu, uint32_t offset);
void     titan_gpu_mmio_write(titan_gpu_model_t *gpu, uint32_t offset,
                              uint32_t value);

// BAR1 VRAM aperture (driver uses this for pwrite/pread DMA).
uint8_t *titan_gpu_vram(titan_gpu_model_t *gpu);
uint32_t titan_gpu_vram_size(titan_gpu_model_t *gpu);

// FP8 E4M3 conversion helpers (also used by the runtime/tests so host and
// device agree bit-for-bit).
uint8_t titan_fp8_from_float(float f);
float   titan_fp8_to_float(uint8_t b);

#ifdef __cplusplus
}
#endif

#endif // TITAN_X6_GPU_MODEL_H
