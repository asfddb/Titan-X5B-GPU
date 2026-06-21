# Titan X5-B Microarchitecture Specification (Part 1)

## 1. Top-Level Integration & Interconnect

The Titan X5-B is integrated around a high-bandwidth `titan_x5_crossbar`.
- **Topology:** 20 Masters × 2 Slaves.
- **Data Width:** 512-bit (64 bytes per transaction) for massive memory bandwidth.
- **Transaction Tracking:** To handle long memory latencies, the crossbar tracks up to 16 outstanding transactions per slave using a Master ID FIFO.
- **Routing:** Address bit 31 selects between the main VRAM slave (Memory Controller) and the Configuration slave.

## 2. Streaming Multiprocessor (SM)

The Titan X5-B features 4 Shader Multiprocessors (SMs), designed for high-throughput graphics and compute workloads. Each SM manages the execution of threads in warps.

### 2.1 Thread & Warp Organization
- **Warp Size:** 32 threads.
- **SIMT Width:** 32 physical execution lanes.
- **Warp Scheduler (`titan_x5_warp_scheduler`):** 
  - Tracks up to 8 active warps per SM.
  - Implements a Greedy-Then-Oldest (GTO) scheduling policy to prevent starvation.
  - Features a coarse-grained Register Scoreboard that stalls fetch/decode if the scheduled warp has any pending writebacks, ensuring strict Read-After-Write (RAW) hazard prevention.

### 2.2 Instruction Pipeline (`titan_x5_pipeline`)
The SM utilizes a 6-stage instruction pipeline:
1. **Instruction Fetch (IF):** Fetches from the L1 instruction cache.
2. **Instruction FIFO:** 8-entry deep buffer to decouple fetch from decode.
3. **Instruction Decode (ID):** Translates the 32-bit instruction into opcodes and register indices.
4. **Execute (EX):** Dispatches to the ALU.
5. **Memory (MEM):** Handles load/store memory operations.
6. **Writeback (WB):** Commits results back to the register file and clears the scoreboard.

## 3. Arithmetic Logic Unit (`titan_x5_alu`)

The execution unit handles parallel 32-lane SIMT operations. It resolves structural writeback hazards dynamically by stalling the pipeline if multiple functional units attempt to complete in the same cycle.

### 3.1 Functional Units & Latency
- **Integer Simple (ADD, SUB, bitwise):** 3 cycles (1 combinational + 2 register stages).
- **Integer Multiply (MUL):** 4 cycles.
- **Integer Divide (DIV):** 33 cycles (iterative radix-2 non-restoring algorithm).
- **Floating Point (FADD, FMUL, FMA):** 6 cycles. (Note: Currently uses integer FMA fallback logic for simulation/synthesis profiling purposes, ensuring structural hazards are properly modeled).

## 4. Tensor Core Array

Attached to the GPU is the `titan_x6_tensor_core_array`, featuring a massive 16×16 systolic array structure.
- **Processing Elements:** 256 PEs.
- **Precision:** FP16 multiply with FP32 accumulation.
- **Data Path:** Systolic flow prevents global wire routing congestion, maintaining high frequency on FPGA and ASIC targets.
