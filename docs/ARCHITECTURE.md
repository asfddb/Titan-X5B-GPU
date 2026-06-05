# Titan X5-B Architecture Guide

## Overview

The Titan X5-B is a Blackwell-class GPU architecture implemented in SystemVerilog. This document describes the micro-architecture of each major subsystem.

---

## 1. Streaming Multiprocessor (SM)

**File**: `rtl/core/titan_x5_sm.v`

The SM is the fundamental compute unit. Each SM contains:

- **32-thread SIMT Vector Datapath**: All 32 threads execute the same instruction simultaneously (Single Instruction, Multiple Threads)
- **Register File**: 32 × 32-bit registers per thread (1024 registers total per SM)
- **ALU Bank**: 32 parallel ALUs supporting ADD, SUB, MUL, AND, OR, XOR, SHL, SHR
- **Pipeline**: 5-stage pipeline (Fetch → Decode → Execute → Memory → Writeback) with full hazard forwarding

The GPU contains **4 SMs**, giving a total of **128 concurrent threads**.

### Pipeline Hazard Handling

The pipeline implements:
- **Data forwarding** from EX→EX and MEM→EX to eliminate most stalls
- **Load-use hazard detection** with automatic 1-cycle stall insertion
- **Branch resolution** at the decode stage

---

## 2. Tensor Core Array

**File**: `rtl/tensor/titan_x6_tensor_core_array.v`

The tensor core implements a **16×16 systolic array** of MAC (Multiply-Accumulate) Processing Elements.

### Dataflow

```
Input A (16×16 FP16 matrix)
    ↓
┌──────────────────────────────┐
│  PE[0,0]  PE[0,1] ... PE[0,15] │
│  PE[1,0]  PE[1,1] ... PE[1,15] │
│    ...      ...    ...   ...    │
│  PE[15,0] PE[15,1]... PE[15,15]│
└──────────────────────────────┘
    ↓
Output C (16×16 FP32 accumulator)
```

Each PE performs: `C[i][j] += A[i][k] × B[k][j]`

- **FP16 Multiplier** (`titan_x5_fp16_mul.v`): Full IEEE 754 half-precision multiply
- **FP32 Accumulator** (`fp32_add`): Full IEEE 754 single-precision add with proper rounding
- **NVFP4 Support**: Native E2M1 (2-bit exponent, 1-bit mantissa) with micro-scaling factors

### Gate Count: 603,664 cells (Tensor Core alone)

---

## 3. Ray Tracing Core

**File**: `rtl/raytracing/titan_x5_rt_core.v`

The RT Core implements the **Mega Geometry** intersection engine using a multi-cycle pipelined state machine.

### Pipeline Stages

| Stage | Operation | Cycles |
|:---|:---|:---|
| IDLE | Wait for ray input | 1 |
| EDGE_COMPUTE | Calculate edge vectors (V1-V0, V2-V0, Ray-V0) | 1 |
| CROSS_PRODUCT | Compute cross products for Möller-Trumbore | 3 |
| DOT_DETERMINANT | Calculate determinant and validate | 1 |
| PARAM_COMPUTE | Compute barycentric coordinates (u, v, t) | 2 |
| HIT_CHECK | Validate intersection parameters | 1 |

Key design decision: **No single-cycle division**. All divisions are replaced with multi-cycle reciprocal approximation to ensure the design can be synthesized at reasonable clock frequencies.

---

## 4. Memory Subsystem

### GDDR7 PAM3 PHY

**File**: `rtl/memory/titan_x5_gddr7_pam3_phy.v`

- **Bus Width**: 512-bit (64 bytes per transfer)
- **Encoding**: PAM3 (Pulse Amplitude Modulation, 3 levels: -1, 0, +1)
- **Channels**: 128 PAM3 encoders operating in parallel
- **Interface**: AXI4 compliant

### Memory Controller

**File**: `rtl/memory/titan_x5_mem_controller.v`

- AXI4 master interface
- Request queuing with FIFO
- Read/Write arbitration

---

## 5. Interconnect

### AXI4 Crossbar

**File**: `rtl/interconnect/titan_x5_crossbar.v`

The crossbar connects 8 master ports to 4 slave ports with:

- **Round-robin arbitration**: Fair scheduling across all masters
- **Transaction tracking**: Request FIFOs with source ID tracking
- **Back-pressure handling**: AXI4 valid/ready handshaking

---

## 6. Graphics Pipeline

### Rasterizer

**File**: `rtl/graphics/titan_x5_rasterizer.v`

- Edge-function based triangle rasterization
- Bounding-box scan with early rejection
- Barycentric coordinate interpolation

### Render Output Units (ROP)

**File**: `rtl/graphics/titan_x5_rop.v`

- 4× ROP instances for parallel pixel output
- Alpha blending support
- Framebuffer write-back

### Texture Mapping Units (TMU)

**File**: `rtl/graphics/titan_x5_tmu.v`

- 4× TMU instances
- Bilinear texture filtering
- Texture coordinate generation

### Neural Shader Dispatch

**File**: `rtl/graphics/titan_x5_neural_shader_dispatch.v`

- Routes shader workloads to tensor cores for neural rendering
- Supports tensor-accelerated lighting calculations

---

## 7. Display Engine

**File**: `rtl/display/titan_x5_display_engine.v`

- VGA timing generator (configurable resolution)
- Async FIFO for clock-domain crossing
- RGB output with horizontal/vertical sync

---

## 8. Command Processor

**File**: `rtl/control/titan_x5_command_processor.v`

- Host ring-buffer interface
- Command decode and dispatch
- Opcode support: DRAW, COMPUTE, DMA, CLEAR, FENCE
