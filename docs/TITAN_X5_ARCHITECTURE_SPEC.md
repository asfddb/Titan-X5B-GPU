# TITAN X5 APEX GPU — Architecture Specification

**Revision:** 2.0 (Massive Architectural Overhaul)
**Target:** 2nm class ASIC / High-End FPGA (e.g., Xilinx Virtex UltraScale+)

## 1. Executive Summary
The Titan X5 Apex GPU represents a massive architectural leap from its predecessor. Originally a simple educational design with a 4-instruction scalar pipeline, the Titan X5 has been completely redesigned into a **next-generation, heavily parallel GPU**. It now features Streaming Multiprocessors (SMs), a multi-level cache hierarchy, hardware Ray Tracing (RT), AI-accelerating Tensor Cores, and a full fixed-function graphics pipeline.

## 2. Core Architecture (Streaming Multiprocessors)
The Titan X5 is organized around 4 Streaming Multiprocessors (SMs), each containing:
- **32-Lane ALU Array:** Capable of executing FP32, INT32, and FMA (Fused Multiply-Add) operations in a single cycle. Multi-cycle instructions like MUL and DIV are fully pipelined.
- **Warp Scheduler:** Manages 8 active warps (32 threads total per SM) using a priority-round-robin scheme and a hardware scoreboard to resolve data dependencies dynamically with zero-overhead context switching.
- **Register File:** Massive 64-entry x 32-bit register file per thread, partitioned across 4 concurrent banks to prevent read/write conflicts during FMA operations.
- **L1 Data Cache / Shared Memory:** 32KB 4-way set-associative L1 Cache and 16KB banked Shared Memory, providing rapid intra-warp data sharing and atomic operations.
- **5-Stage Pipeline:** Instruction Fetch (IF), Instruction Decode (ID), Execute (EX), Memory (MEM), and Write-Back (WB). It features full operand forwarding and dynamic branch prediction via a 64-entry BTB.

## 3. Graphics Pipeline
The graphics subsystem is a modern fixed-function pipeline designed for high throughput:
- **Hardware Rasterizer:** Performs bounding-box optimized triangle setup, scanline traversal, and barycentric coordinate generation at 1 triangle per clock.
- **Texture Mapping Unit (TMU):** 4 TMUs per SM handle bilinear filtering, mipmap LOD selection, and address clamping/wrapping, backed by a 4KB direct-mapped L0 texture cache.
- **Render Output Unit (ROP):** 4 ROPs support Depth/Stencil testing, multi-mode Alpha Blending, and lossless Delta Color Compression (DCC) before writing the 32-bit RGBA pixel stream to the L2 Cache.

## 4. Hardware Accelerators
- **Tensor Cores (AI/ML):** Each SM contains a 4x4 systolic matrix multiply-accumulate array. It supports INT8 and FP16 datatypes and 2:4 structured sparsity, drastically accelerating neural network inference for super resolution (DLSS/FSR equivalents).
- **Ray Tracing Unit (RT Core):** A dedicated hardware engine for Bounding Volume Hierarchy (BVH) traversal. It performs ray-AABB intersection testing (2 boxes/cycle) and delegates ray-triangle intersections to a fixed-point Möller-Trumbore math unit.

## 5. Memory Subsystem & Interconnect
- **L2 Cache:** A 256KB unified L2 cache, 8-way set-associative, divided into 4 banks. It serves as the primary hub between the SMs, graphics units, and the memory controller.
- **Crossbar Interconnect:** A 4x4 high-bandwidth NoC (Network-on-Chip) using AXI4-Lite semantics, ensuring non-blocking, single-cycle arbitration between all major blocks.
- **Memory Controller:** An AXI4 master interface handling burst requests up to 16 beats to external DDR/HBM memory, optimizing throughput for wide memory buses.

## 6. Power & Control
- **Power Management (DVFS):** Supports 4 dynamic performance states (P0-P3) and implements aggressive fine-grained clock gating per SM and execution unit.
- **Command Processor:** Replaces simple memory-mapped I/O. It autonomously fetches work packets (Compute, Draw, DMA, Fence) from a host ring buffer.
- **Performance Counters:** 32 hardware 48-bit counters track cache hit rates, warp occupancy, ALU utilization, and IPC, accessible via memory-mapped registers.
