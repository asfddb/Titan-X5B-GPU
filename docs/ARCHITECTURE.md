# Titan X5-B GPU — Architecture Specification

**Version:** 1.0  
**Date:** [TODAY'S DATE]  
**Author:** Adhiraj (@asfddb)  
**License:** CERN-OHL-S-2.0 (OSS) / Commercial (see LICENSE)  
**Status:** Living document — updated with each release

---

## 1. Overview

Titan X5-B is a SIMT-class educational graphics processing unit architecture
implemented in 9,983 lines of SystemVerilog across 57 synthesizable
modules. The design targets educational, research, and commercial
display-compute SoC applications where a full Arm Mali or Imagination
PowerVR license is cost-prohibitive or politically unavailable.

### 1.1 Key Specifications

| Feature | Value |
|---------|-------|
| Target Environment | Simulation / FPGA |
| Total Logic Cells (Yosys) | 3,030,603 |
| Flip-Flops | 530,000+ |
| Wire Bits | 3,230,370 |
| Streaming Multiprocessors | 4 × (32-thread SIMT) |
| Tensor Core Array | 16 × 16 (256 PEs), FP16 |
| Memory Bus Width | 512-bit (GDDR7 PAM3 simulation) |
| AXI4 Crossbar | 20 Masters × 2 Slaves, round-robin |
| Ray Tracing | BVH traversal + ray-triangle intersection |
| Display | VGA timing generator, RGB output |
| Clock Domains | 1 (single-clock for simplicity) |
| Synthesis Tool | Yosys 0.66+ (OSS CAD Suite) |
| Simulation Tool | Icarus Verilog 14.0 + cocotb 1.8 |

---

## 2. Top-Level Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TITAN X5-B GPU TOP                          │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │   SM 0   │  │   SM 1   │  │   SM 2   │  │   SM 3   │           │
│  │ 32-Thread│  │ 32-Thread│  │ 32-Thread│  │ 32-Thread│           │
│  │ SIMT ALU │  │ SIMT ALU │  │ SIMT ALU │  │ SIMT ALU │           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       │              │              │              │                │
│  ┌────┴──────────────┴──────────────┴──────────────┴────┐          │
│  │              AXI4 CROSSBAR (20×2)                     │          │
│  │         Round-Robin · Transaction Tracking            │          │
│  └──┬─────────┬─────────────────────────────────────────┘          │
│     │         │          │          │                               │
│  ┌──┴──┐  ┌──┴──┐  ┌───┴───┐  ┌──┴──────────┐                   │
│  │ RT  │  │Tensor│  │Neural │  │   Memory     │                   │
│  │Core │  │Core  │  │Shader │  │ Controller   │                   │
│  │Mega │  │16×16 │  │Dispatch│  │  512-bit    │                   │
│  │Geom │  │FP16  │  │       │  │  GDDR7 PHY  │                   │
│  └─────┘  └──────┘  └───────┘  └─────────────┘                   │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │Rasterizer│  │  4× ROP  │  │  4× TMU  │  │ Display  │           │
│  │          │  │          │  │          │  │ Engine   │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Module Hierarchy

```
titan_x5_gpu_top
├── control/
│   ├── titan_x5_command_processor       # 64-bit command FIFO + FSM
│   └── titan_x5_perf_counters           # 32 performance counters
├── core/
│   ├── titan_x5_sm (×4)                 # Streaming Multiprocessor
│   │   ├── titan_x5_warp_scheduler      # 32-thread warp scheduling
│   │   ├── titan_x5_register_file       # Banked RF, 32 lanes
│   │   ├── titan_x5_pipeline            # 5-stage, hazard-forwarding
│   │   ├── titan_x5_decoder             # Instruction decode
│   │   └── titan_x5_alu                 # INT16/FP16 ALU, multi-cycle
├── graphics/
│   ├── titan_x5_vertex_transformer      # INT16 systolic, 4×4 matrix
│   ├── titan_x5_rasterizer              # Edge function + barycentric
│   ├── titan_x5_tmu (×4)                # Bilinear texture sampling
│   ├── titan_x5_rop (×4)                # Blend + depth test
│   └── titan_x5_neural_shader_dispatch  # AI shader dispatch
├── raytracing/
│   ├── titan_x5_rt_core                 # Mega geometry + BVH
│   └── titan_x5_ray_triangle_isect      # Möller-Trumbore
├── tensor/
│   ├── titan_x6_tensor_core_array       # 16×16 FP16 systolic
│   └── titan_x5_fp16_mul                # IEEE 754 FP16 multiplier
├── memory/
│   ├── titan_x5_mem_controller          # 512-bit GDDR7 controller
│   ├── titan_x5_gddr7_pam3_phy          # PAM3 signaling PHY
│   ├── titan_x5_l1_cache                # 4-way, 32KB
│   ├── titan_x5_l2_cache                # 8-way, 256KB
│   ├── titan_x5_shared_memory           # SM-local shared memory
│   └── titan_x5_hbm3_controller         # HBM3 (alternative path)
├── interconnect/
│   ├── titan_x5_crossbar                # 8×4 AXI4, round-robin + FIFO
│   ├── titan_x5_axi4_lite               # AXI4-Lite for control
│   ├── titan_x5_dma_engine              # Scatter-gather DMA
│   ├── titan_x5_mesh_router             # 2D mesh for NoC
│   └── titan_x6_ucie_phy                # UCIe die-to-die
├── display/
│   ├── titan_x5_display_engine          # VGA + HDMI timing
│   └── titan_x5_async_fifo              # Cross-clock FIFO
├── power/
│   └── titan_x5_power_mgmt              # DVFS + island gating
├── sr/
│   ├── titan_x5_sr_engine               # Super resolution (FIR + ESRGAN)
│   ├── titan_x5_apex_sr_engine          # Apex SR variant
│   └── titan_x5_hash_fnv64              # FNV-64 hash for cache
├── common/
│   └── titan_x5_skid_buffer             # Skid buffer for AXI
└── crypto/
    ├── titan_x5_2048_alu                # 2048-bit ALU
    ├── titan_x5_2048_mul                # 2048-bit multiplier
    └── titan_x5_2048_regfile            # 2048-bit register file
```

---

## 4. Data Flow

### 4.1 Command Submission Flow

```
Host CPU → AXI write → VRAM ring buffer
                              ↓
                  titan_x5_command_processor
                              ↓ (CMD_DRAW)
                  titan_x5_vertex_transformer
                              ↓ (transformed vertices)
                  titan_x5_rasterizer
                              ↓ (per-tile fragments)
        ┌─────────────────────┼─────────────────────┐
        ↓                     ↓                     ↓
   titan_x5_tmu        titan_x5_rop          titan_x5_rt_core
   (texture)           (blend+depth)         (ray hit/miss)
        ↓                     ↓                     ↓
        └─────────────────────┼─────────────────────┘
                              ↓ (merged pixel)
                   titan_x5_display_engine
                              ↓ (VGA/HDMI)
                          Monitor
```

### 4.2 Compute Flow (SM path)

```
Host CPU → CMD_DISPATCH → command_processor
                              ↓
                  titan_x5_warp_scheduler (×4 SMs)
                              ↓ (32-thread warps)
                  titan_x5_register_file
                              ↓ (operand fetch)
                  titan_x5_pipeline (5 stages)
                              ↓
                  titan_x5_alu (multi-cycle for DIV/MUL)
                              ↓ (writeback)
                  titan_x5_register_file
                              ↓ (memory ops)
                  titan_x5_l1_cache → crossbar → L2 → VRAM
```

### 4.3 Tensor Flow

```
Host CPU → CMD_TENSOR → command_processor
                              ↓
                  titan_x6_tensor_core_array (16×16)
                              ↓ (A, B matrices)
                  256 MAC PEs (FP16 multiply, FP32 accumulate)
                              ↓ (systolic)
                  accumulator → DMA → VRAM
```

---

## 5. Clock and Reset

### 5.1 Clock Domains

The current implementation uses a **single clock domain** (`clk`) for
simplicity. All modules share the same clock.

**Future plans:**
- Split into 3 domains: `clk_core` (SM/ALU), `clk_mem` (memory controller),
  `clk_display` (VGA pixel clock)
- Add asynchronous FIFOs at domain boundaries

### 5.2 Reset Strategy

- Active-low async reset (`rst_n`)
- All flip-flops reset to a defined state
- Reset deassertion is synchronous (deglitch)

---

## 6. Memory Map

| Address Range | Size | Target | Description |
|---------------|------|--------|-------------|
| `0x0000_0000` – `0x0FFF_FFFF` | 256 MB | VRAM | Framebuffer + textures |
| `0x1000_0000` – `0x1000_FFFF` | 64 KB | CMD FIFO | Command ring buffer |
| `0x1001_0000` – `0x1001_03FF` | 1 KB | Perf counters | Performance monitor regs |
| `0x1001_0400` – `0x1001_07FF` | 1 KB | Power mgmt | DVFS + island control |
| `0x1002_0000` – `0x1002_3FFF` | 16 KB | SM 0 regs | Per-SM config |
| `0x1003_0000` – `0x1003_3FFF` | 16 KB | SM 1 regs | Per-SM config |
| `0x1004_0000` – `0x1004_3FFF` | 16 KB | SM 2 regs | Per-SM config |
| `0x1005_0000` – `0x1005_3FFF` | 16 KB | SM 3 regs | Per-SM config |
| `0x2000_0000` – `0x2FFF_FFFF` | 256 MB | L2 cache | Direct L2 access |

---

## 7. AXI Port Definitions

### 7.1 Master Ports (GPU → Memory)

| Master | Source | Purpose |
|--------|--------|---------|
| M0 | Command Processor | Command fetches |
| M1-M4 | TMU 0-3 | Texture fetches |
| M5-M8 | ROP 0-3 | Framebuffer writes |
| M9-M12 | SM 0-3 I-Cache | Instruction fetches |
| M13-M16 | SM 0-3 D-Cache | Data fetches/writes |
| M17 | DMA Engine | Scatter-gather transfers |
| M18 | RT Core | BVH + geometry fetches |
| M19 | Display Engine | Framebuffer reads (VGA output) |

### 7.2 Slave Ports (Memory → GPU)

| Slave | Target | Address Range |
|-------|--------|---------------|
| S0 | VRAM (Memory Controller) | `0x0000_0000 – 0xFFFF_FFFF` |
| S1 | DMA Config Registers | `0x1000_0000 – 0x1000_FFFF` |

---

## 8. ISA Summary

### 8.1 ALU Instructions

| Opcode | Mnemonic | Description | Latency |
|--------|----------|-------------|---------|
| `0x00` | `NOP` | No operation | 1 cycle |
| `0x01` | `ADD` | Integer add | 3 cycles |
| `0x02` | `SUB` | Integer subtract | 3 cycles |
| `0x03` | `MUL` | Integer multiply | 4 cycles |
| `0x04` | `DIV` | Integer divide | 33 cycles |
| `0x05` | `AND` | Bitwise AND | 3 cycles |
| `0x06` | `OR` | Bitwise OR | 3 cycles |
| `0x07` | `XOR` | Bitwise XOR | 3 cycles |
| `0x08` | `SHL` | Shift left | 3 cycles |
| `0x09` | `SHR` | Shift right | 3 cycles |
| `0x0A` | `FADD` | FP32 add | 6 cycles |
| `0x0B` | `FMUL` | FP32 multiply | 6 cycles |
| `0x0C` | `FMA` | FP32 fused multiply-add | 6 cycles |

### 8.2 Memory Instructions

| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| `0x10` | `LOAD` | Load from memory |
| `0x11` | `STORE` | Store to memory |
| `0x12` | `TEX` | Texture sample (via TMU) |
| `0x13` | `ATOM` | Atomic op |

### 8.3 Control Flow

| Opcode | Mnemonic | Description |
|--------|----------|-------------|
| `0x20` | `BRANCH` | Conditional branch |
| `0x21` | `CALL` | Function call |
| `0x22` | `RET` | Return |
| `0x23` | `SYNC` | Warp synchronization |

### 8.4 Command Packet Format (64-bit)

```
┌─────────┬─────────┬───────────────────────────────────────────────┐
│ Opcode  | Sub-op  | Payload (48 bits)                              │
│ [7:0]   │ [11:8]  │ [63:12]                                        │
└─────────┴─────────┴───────────────────────────────────────────────┘
```

| Opcode | Command | Payload |
|--------|---------|---------|
| `0x01` | CMD_DRAW | 4×4 weight matrix + 4×4 vertices (17 words) |
| `0x02` | CMD_CLEAR | Color (32-bit) + framebuffer offset |
| `0x03` | CMD_FENCE | Sync barrier ID |
| `0x04` | CMD_DISPATCH | SM ID + warp count + kernel addr |
| `0x05` | CMD_TENSOR | A addr + B addr + C addr + M, N, K |
| `0x06` | CMD_RT | BVH addr + ray buffer addr |
| `0x07` | CMD_PRESENT | Display flip |

---

## 9. Verification Status

| Component | Testbench | Status |
|-----------|-----------|--------|
| ALU | test_alu.py | ✅ Passing |
| System (Graphics) | test_system.py | ✅ Passing |
| Crossbar | (stub removed) | ⚠️ TODO |
| Rasterizer | (integrated) | ✅ Passing |
| TMU | (stub removed) | ⚠️ TODO |
| Display Engine | (integrated) | ✅ Passing |
| RT Core | (planned) | ⚠️ TODO |

**Overall functional coverage:** Measured by cocotb simulation passes.

---

## 10. FPGA Validation

| Target | Status | Frequency | Notes |
|--------|--------|-----------|-------|
| Artix-7 100T | ✅ Proven | 50 MHz | VGA output verified |
| Lattice ECP5 | 🚧 Planned | TBD | |
| Gowin Arora | 🚧 Planned | TBD | |

**Resource Utilization (Artix-7 100T, FPGA edition):**

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | 41,234 | 63,400 | 65% |
| FFs | 38,122 | 126,800 | 30% |
| BRAM | 84 | 135 | 62% |
| DSP | 124 | 240 | 52% |
| IOB | 23 | 210 | 11% |

---

## 11. Known Limitations

1. **Single clock domain** — limits max frequency on real silicon
2. **No MMU** — virtual memory not supported
3. **Limited driver stack** — bare-metal only, Linux DRM stub
4. **No Vulkan/OpenGL** — custom ISA only (planned for future)
5. **Tensor core is FP16 only** — no FP8 or INT8
6. **RT core is single-ray** — no parallel ray traversal
7. **Memory controller is simplified** — no DRAM refresh, no training

---

## 12. Roadmap

### v1.1 (Q1 2026)
- UVM verification environment
- 85% functional coverage
- Linux DRM driver
- Lattice ECP5 FPGA target

### v1.2 (Q2 2026)
- Multi-clock domain
- TinyTapeout silicon validation
- OpenGL ES 2.0 subset
- INT8 tensor support

### v2.0 (Q3 2026)
- Vulkan 1.0 subset
- Hardware ray tracing (parallel)
- HBM3 production PHY
- TSMC 28nm tape-out

---

## 13. References

- [1] NVIDIA Blackwell architecture whitepaper
- [2] AXI4 Protocol Specification (ARM IHI 0022)
- [3] IEEE 754-2008 floating-point standard
- [4] Möller-Trumbore ray-triangle intersection algorithm
- [5] Cocotb documentation: https://docs.cocotb.org
- [6] Yosys documentation: https://yosyshq.net/yosys

---

*This document is part of the Titan X5-B GPU IP package. For
commercial license inquiries, contact adhiraj@[your-domain].*
