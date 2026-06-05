# TITAN X5 APEX GPU — ISA Reference Manual

**Version:** 2.0
**Architecture Width:** 32-bit
**Instruction Length:** 32-bit fixed

## Overview
The Titan X5 features a completely overhauled Instruction Set Architecture (ISA). Expanding from a meager 4 instructions, the v2.0 ISA provides 32 diverse instructions supporting complex arithmetic, logical, memory manipulation, and branching capabilities necessary for modern shader and compute workloads.

## Instruction Formats
All instructions are 32 bits long and generally follow a three-operand structure.

- **R-Type (Register-Register):** `[Opcode: 6] [Rd: 6] [Rs1: 6] [Rs2: 6] [Funct: 8]`
- **I-Type (Register-Immediate):** `[Opcode: 6] [Rd: 6] [Rs1: 6] [Immediate: 14]`
- **J-Type (Jump/Branch):** `[Opcode: 6] [Rs1: 6] [Rs2: 6] [Target Offset: 14]`

*(Note: The register file contains 64 registers per thread, thus requiring 6 bits for addressing.)*

## Instruction Categories

### 1. Arithmetic Instructions
| Mnemonic | Opcode | Description | Cycles |
|----------|--------|-------------|--------|
| `ADD`    | 0x01   | Add Rs1 and Rs2, store in Rd. | 1 |
| `ADDI`   | 0x02   | Add Rs1 and sign-extended Imm14, store in Rd. | 1 |
| `SUB`    | 0x03   | Subtract Rs2 from Rs1, store in Rd. | 1 |
| `MUL`    | 0x04   | Multiply Rs1 and Rs2 (lower 32-bits), store in Rd. | 3 |
| `MULH`   | 0x05   | Multiply Rs1 and Rs2 (upper 32-bits), store in Rd. | 3 |
| `DIV`    | 0x06   | Signed divide Rs1 by Rs2, store quotient in Rd. | 6 |
| `MOD`    | 0x07   | Signed divide Rs1 by Rs2, store remainder in Rd. | 6 |
| `FMA`    | 0x08   | Fused Multiply-Add: (Rs1 * Rs2) + Rs3 -> Rd. | 1 |

### 2. Logical Instructions
| Mnemonic | Opcode | Description | Cycles |
|----------|--------|-------------|--------|
| `AND`    | 0x10   | Bitwise AND of Rs1 and Rs2, store in Rd. | 1 |
| `ANDI`   | 0x11   | Bitwise AND of Rs1 and zero-extended Imm14, store in Rd. | 1 |
| `OR`     | 0x12   | Bitwise OR of Rs1 and Rs2, store in Rd. | 1 |
| `ORI`    | 0x13   | Bitwise OR of Rs1 and zero-extended Imm14, store in Rd. | 1 |
| `XOR`    | 0x14   | Bitwise XOR of Rs1 and Rs2, store in Rd. | 1 |
| `NOT`    | 0x15   | Bitwise NOT of Rs1, store in Rd. | 1 |
| `SHL`    | 0x16   | Shift Rs1 left by Rs2 (mod 32), store in Rd. | 1 |
| `SHR`    | 0x17   | Logical shift Rs1 right by Rs2 (mod 32), store in Rd. | 1 |
| `SRA`    | 0x18   | Arithmetic shift Rs1 right by Rs2 (mod 32), store in Rd. | 1 |

### 3. Memory Instructions
| Mnemonic | Opcode | Description | Cycles |
|----------|--------|-------------|--------|
| `LDR`    | 0x20   | Load 32-bit Word from Address (Rs1 + Imm). | ~1 (Cache hit) |
| `LDR.B`  | 0x21   | Load 8-bit Byte from Address (Rs1 + Imm), zero extend. | ~1 (Cache hit) |
| `STR`    | 0x22   | Store 32-bit Word in Rs2 to Address (Rs1 + Imm). | 1 |
| `STR.B`  | 0x23   | Store 8-bit Byte in Rs2 to Address (Rs1 + Imm). | 1 |

### 4. Branch & Flow Control
| Mnemonic | Opcode | Description | Cycles |
|----------|--------|-------------|--------|
| `BEQ`    | 0x30   | Branch to PC + Offset if Rs1 == Rs2. | 1 (Predict hit) |
| `BNE`    | 0x31   | Branch to PC + Offset if Rs1 != Rs2. | 1 (Predict hit) |
| `BLT`    | 0x32   | Branch to PC + Offset if Rs1 < Rs2 (signed). | 1 (Predict hit) |
| `BGE`    | 0x33   | Branch to PC + Offset if Rs1 >= Rs2 (signed). | 1 (Predict hit) |
| `JAL`    | 0x34   | Jump to PC + Offset, store return address (PC+4) in Rd. | 1 |
| `JALR`   | 0x35   | Jump to Rs1 + Offset, store return address (PC+4) in Rd. | 1 |

### 5. Compare & Special Instructions
| Mnemonic | Opcode | Description | Cycles |
|----------|--------|-------------|--------|
| `SLT`    | 0x40   | Set Rd to 1 if Rs1 < Rs2 (signed), else 0. | 1 |
| `SLTU`   | 0x41   | Set Rd to 1 if Rs1 < Rs2 (unsigned), else 0. | 1 |
| `CLZ`    | 0x42   | Count Leading Zeros of Rs1, store in Rd. | 1 |
| `POPC`   | 0x43   | Population Count (set bits) of Rs1, store in Rd. | 1 |
| `LUI`    | 0x44   | Load Upper Immediate: shift Imm14 left by 16, store in Rd. | 1 |
| `HALT`   | 0x45   | Halt execution of current thread/warp. | - |
| `NOP`    | 0x00   | No Operation. | 1 |

## Hazard Handling
The SM pipeline is 5 stages (IF, ID, EX, MEM, WB) and employs full data forwarding. If an instruction depends on the result of a multi-cycle instruction (e.g., `MUL`, `DIV`, or an `LDR` cache miss), the pipeline scoreboard automatically inserts stalls and prompts the Warp Scheduler to context-switch to another resident warp to hide the latency.
