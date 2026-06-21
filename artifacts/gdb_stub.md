# Conceptual GDB Stub Design for Titan X5 Warp Schedulers

## Overview
This document outlines the conceptual design for a GDB stub intended to debug the Titan X5 warp schedulers over a JTAG interface. The Titan X5 features a highly parallel architecture where debugging individual warps requires specialized handling of the JTAG scan chains and hardware breakpoints.

## Architecture

1. **JTAG Interface Layer**
   - Communicates with the hardware TAP (Test Access Port) controller on the Titan X5.
   - Manages shift-DR and shift-IR states to read/write hardware debug registers.

2. **Warp Control Module**
   - Handles the multiplexing required to select a specific Streaming Multiprocessor (SM) and a specific warp scheduler within that SM.
   - Translates GDB thread IDs to specific SM/Warp coordinates.

3. **GDB Remote Serial Protocol (RSP) Server**
   - Listens for GDB commands (TCP/IP).
   - Translates RSP packets (e.g., `g`, `G`, `m`, `M`, `c`, `s`) into Titan-specific JTAG sequences.
   - Encodes JTAG responses back into RSP packets.

## Key Debug Features

- **Halt/Resume**: Broadcasts halt signals to all warp schedulers or targets specific ones using JTAG IR/DR commands.
- **Register Access**: Accesses the General Purpose Registers (GPRs) and special function registers (e.g., PC, mask registers) by scanning out the state of a halted warp.
- **Memory Access**: Translates virtual/physical memory reads into memory mapped I/O (MMIO) transactions over the JTAG-to-AXI bridge.
- **Breakpoints**: Implements hardware breakpoints using the Titan X5's built-in address match registers.

## Thread Mapping Strategy
GDB represents execution contexts as threads. In this stub:
- `Thread ID` = `(SM_ID << 8) | Warp_ID`
- This allows GDB to switch between contexts (warps) transparently using the `H` command.

## JTAG Scan Chain Concept
- **IR Length**: 8 bits
- **Instructions**:
  - `IDCODE` (0x01)
  - `HALT_WARP` (0x10)
  - `RESUME_WARP` (0x11)
  - `READ_REG` (0x20)
  - `WRITE_REG` (0x21)
  - `READ_MEM` (0x30)
  - `WRITE_MEM` (0x31)

## Implementation Considerations
- **Latency**: JTAG is inherently slow. The stub must batch read/write operations and cache register states where safe.
- **Synchronization**: Halting one warp might require halting dependent warps to prevent hardware timeouts.
