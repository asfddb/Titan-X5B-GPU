# Titan X5-B Microarchitecture Specification (Part 1)

## 1. Shader Core (SM)
The Titan X5-B features 4 Shader Multiprocessors (SMs). Each SM manages the execution of threads in warps of 32 threads.
- **Warp Schedulers:** Round-robin or greedy scheduling.
- **Register File:** 32 registers per thread, shared across the warp.

## 2. ALU Pipeline
The ALU pipeline is optimized for maximum throughput of INT and FP16 operations.
- **Stages:** Fetch, Decode, Read, Execute, Writeback.
- **Latencies:** 
  - Add/Sub: 1 cycle
  - Mul: 4 cycles
  - Div: 32 cycles

## 3. Tensor Core Array
Attached to each SM is a 4x4 or 8x8 Tensor Core array for matrix multiplication, accelerating AI and ML workloads.
