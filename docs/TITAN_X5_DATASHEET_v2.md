# TITAN X5 APEX GPU — Production Datasheet

**Document ID:** TX5-GPU-DS-200
**Revision:** 2.0-Production
**Target Nodes:** 2nm class ASIC / Xilinx Virtex UltraScale+
**Category:** Parallel Compute & Graphics IP

---

## 1. Description
The Titan X5 Apex GPU is a high-performance, synthesizable RTL GPU IP block designed for next-generation system-on-chip (SoC) integration. Moving far beyond fixed-function accelerators, the Titan X5 features 4 fully programmable Streaming Multiprocessors (SMs), integrated hardware ray tracing, AI-accelerating Tensor Cores, and a comprehensive raster graphics pipeline.

It serves as a drop-in 3D and Compute engine for advanced microcontrollers, autonomous vehicle compute platforms, and edge-AI devices, communicating seamlessly over AXI4 and AXI4-Lite standard buses.

## 2. Key Specifications

### 2.1 Compute & Architecture
| Parameter | Specification |
|-----------|---------------|
| Architecture | 32-bit RISC Compute (Custom ISA) |
| Streaming Multiprocessors (SM) | 4 |
| ALUs per SM | 32 (128 total across GPU) |
| Pipeline Depth | 5 Stages (IF, ID, EX, MEM, WB) |
| Warps per SM | 8 (32 active threads per SM) |
| Register File | 64 x 32-bit (per thread) |
| Clock Frequency (Target ASIC) | 2.5 GHz (2nm process) |
| Clock Frequency (Target FPGA) | 150 MHz (Xilinx UltraScale+) |

### 2.2 Memory Hierarchy
| Cache Level | Capacity | Organization | Latency |
|-------------|----------|--------------|---------|
| L0 Texture Cache | 4 KB / SM | Direct-Mapped | 1 Cycle |
| L1 Data Cache | 32 KB / SM | 4-Way Set-Associative, 64B Line | 1 Cycle (Hit) |
| Shared Memory | 16 KB / SM | 8 Banks (32-bit wide) | 1 Cycle |
| L2 Unified Cache | 256 KB | 8-Way Set-Associative, 128B Line | 4 Cycles |
| External Bus | - | AXI4 (up to 16-beat bursts) | Memory Dependent |

### 2.3 Hardware Accelerators
- **Tensor Cores:** 4x4 Systolic array per SM. Supports INT8 and FP16 datatypes. 16 MAC operations per clock per SM.
- **Ray Tracing Unit:** BVH hardware traversal engine (2 AABB checks/cycle) + fixed-point Möller-Trumbore intersection.
- **SR Engine (Temporal Reprojection):** 64-entry, 4-way associative reprojection cache using 64-bit FNV-1a hashing to predict temporal coherence and bypass redundant pixel shading.

### 2.4 Graphics Pipeline
- **Rasterizer:** Bounding-box optimized, 1 triangle setup per cycle.
- **TMU:** 4 Texture Mapping Units per SM, bilinear filtering, mipmap support.
- **ROP:** 4 Render Output Units, 32-bit RGBA out, Delta Color Compression (DCC) enabled.
- **Display Engine:** VGA/HDMI output timing generator, supports up to 1920x1080 @ 60Hz.

## 3. Power, Performance, and Area (PPA) Estimates

*Note: ASIC estimates based on nominal 2nm physical synthesis libraries.*

| Metric | 2nm ASIC (Estimated) | Xilinx Virtex UltraScale+ (Estimated) |
|--------|----------------------|---------------------------------------|
| LUTs / Logic Cells | N/A | ~450,000 LUTs |
| Flip-Flops | ~850,000 | ~850,000 FFs |
| SRAM / Block RAM | ~350 KB | 120 BRAM36 |
| DSP Slices | N/A | ~512 DSP48E2 |
| Max Frequency (Fmax) | 2.5 GHz | 150 MHz |
| Dynamic Power | 1.8 W | 4.5 W |
| Leakage Power | 150 mW | 1.2 W |

## 4. SoC Interfaces
- **AXI4 Master:** Primary external memory interface for L2 cache misses, DMA transfers, and display fetch. Data width: 64-bit to 256-bit configurable.
- **AXI4-Lite Master/Slave:** Control plane interface mapped to the internal Crossbar. Used by the host CPU to access GPU Performance Counters, configure the Display Engine, and write to the Command Processor Ring Buffer.

## 5. Software & Toolchain Support
- **Assembler:** Provided Python-based `titan-as` assembler for compiling `.tasm` files into memory initialization vectors (`.mem` or `.hex`).
- **Command Streamer:** API driver library mapping high-level draw calls (DrawTriangles, DispatchCompute, TextureBind) to hardware ring buffer packets.
- **Debug:** Internal UART-over-AXI module allows real-time streaming of all 32 hardware performance counters (cache hit rates, IPC, warp stalls).
