# Titan X5 Warp Schedulers: Conceptual BootROM Sequence and Microcode Design

## 1. Overview
The Titan X5 architecture introduces a highly concurrent warp scheduling mechanism to maximize throughput and minimize latency in streaming multiprocessors (SMs). The Warp Schedulers are responsible for managing instruction fetch, decode, and issue across multiple warps simultaneously. This document outlines the conceptual bootROM initialization sequence and the microcode design for the Titan X5 Warp Schedulers.

## 2. BootROM Sequence

The BootROM sequence ensures that the hardware components of the Warp Scheduler are properly initialized, calibrated, and transitioned into a state ready for microcode execution and subsequent workload management.

### Phase 2.1: Power-On Reset (POR) and BIST
1. **Reset De-assertion**: System clock stabilizes, and reset signals to the SMs and Warp Schedulers are de-asserted.
2. **Built-In Self-Test (BIST)**:
   - Perform memory BIST on the Instruction Cache (L1I) and Warp State Registers (WSR).
   - Perform logic BIST on the scheduling ALUs, scoreboard logic, and dependency checking units.
   - Any failures are logged to the global error status register, potentially isolating faulty SMs or degrading performance gracefully.

### Phase 2.2: Hardware Initialization
1. **Warp State Clearing**: Clear all entries in the Warp State Registers (WSR). Set all warp states to `UNALLOCATED`.
2. **Scoreboard Initialization**: Reset the dependency scoreboards (register scoreboards, barrier scoreboards, and memory dependency scoreboards) for all available warp slots.
3. **Queue Reset**: Clear the instruction fetch queues (IFQ) and instruction issue queues (IIQ).

### Phase 2.3: Microcode Load and Authentication
1. **Microcode Fetch**: The BootROM initiates a DMA transfer to load the Warp Scheduler Microcode (WSM) from the secured on-package non-volatile memory (or main memory, if securely authenticated) into the scheduler's dedicated Microcode Control Store (MCS).
2. **Cryptographic Authentication**: The loaded microcode is verified using a hardware Root of Trust (e.g., ECDSA signature verification) to prevent unauthorized execution.
3. **Microcode Start**: Upon successful verification, the BootROM sets the Microcode Program Counter (uPC) to the entry point and transfers control to the microcode engine.

## 3. Microcode Design for Warp Schedulers

The Warp Scheduler microcode acts as the firmware that controls the complex logic of warp selection, dependency resolution, and instruction dispatch.

### 3.1. Microarchitectural State
The microcode manages several key data structures:
- **Warp Status Table (WST)**: Tracks the state of each warp (Active, Stalled, Yielded, Exited, Unallocated).
- **Instruction Buffer (IB)**: Holds pre-fetched instructions for active warps.
- **Scoreboard**: A matrix tracking register Read-After-Write (RAW), Write-After-Write (WAW), and Write-After-Read (WAR) dependencies.

### 3.2. Microcode Main Loop
The microcode executes a tight, highly optimized pipeline loop:

#### Step 1: Instruction Fetch Request (IFR)
- Scan WST for Active warps with empty or near-empty Instruction Buffers.
- Prioritize fetches based on warp age (oldest first) to prevent starvation, modified by a dynamic priority heuristic.
- Issue fetch requests to the L1 Instruction Cache.

#### Step 2: Decode and Dependency Check (Scoreboarding)
- For newly fetched instructions, decode the opcodes and register operands.
- Update the scoreboard with destination registers (marking them as pending).
- Check source registers against the scoreboard. If dependencies exist, mark the instruction as `Stalled` with a specific hazard condition (e.g., `WAIT_ON_ALU`, `WAIT_ON_MEM`).

#### Step 3: Warp Selection and Scheduling
- **Heuristic Evaluation**: Evaluate all warps not currently stalled.
- **Fairness vs. Throughput**: Implement a Round-Robin or Greedy-Then-Oldest scheduling policy to select the best warp for issue.
- **Dual-Issue Logic**: Attempt to find independent instructions within the same warp (or across paired warps) to dual-issue to disparate execution units (e.g., FP32 and INT32 pipelines).

#### Step 4: Issue and Execute
- Dispatch the selected instruction(s) to the execution units (Tensor Cores, FP32, INT32, SFU, Load/Store Units).
- Update the warp's Program Counter (PC).

#### Step 5: Writeback and Scoreboard Clear
- Monitor completion signals from execution units.
- Clear pending flags in the scoreboard for completed destination registers.
- Wake up warps that were stalled on these specific dependencies.

### 3.3. Exception Handling and Context Switching
- **Page Faults / Memory Violations**: The microcode detects memory access violations. It stalls the offending warp, records the faulting address in a control register, and signals the global Thread Block (CTA) manager.
- **Preemption**: When a higher-priority context needs the SM, the microcode coordinates a context switch: it suspends instruction fetch, drains the execution pipelines, saves the WSR and scoreboard state to memory, and signals readiness for the new context.

## 4. Conclusion
The Titan X5 Warp Scheduler relies on a robust BootROM sequence to guarantee hardware integrity and security before transferring control to the highly optimized microcode. The microcode itself is designed to handle extreme concurrency, implementing sophisticated dependency tracking and prioritization heuristics to feed the execution pipelines efficiently.
