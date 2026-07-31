# TITAN APEX-X — GPU Specification

**Process:** GT2N 2 nm nanosheet GAAFET, backside power delivery
**Date:** 2026-07-31
**Repo:** `C:\Titan-X5B-GPU`, branch `claude/titan-x5-gpu-conversion-lf6udk`

---

## Read this first

Every number in this document was produced by a command that ran. Nothing is
scaled from another process, estimated from a formula, or taken from a
datasheet. Where a figure is an assumption rather than a measurement, it says
so in the line above it.

Three caveats travel with every performance number here, and they are not
fine print:

1. **GT2N is a *predictive* PDK. It is not fabbable.** It is an open,
   realistic, foundry-agnostic 2 nm model published by Georgia Tech. No
   foundry will accept a design in it. A fabbable 2 nm part needs an NDA
   agreement with TSMC / Intel / Samsung and a mask set costing tens of
   millions of dollars.
2. **These are synthesis results, not layout.** No floorplan, no placement,
   no routing, no parasitic extraction. The timing tool reports
   `WireLoad = "none"`, meaning **zero wire delay is included**. At 2 nm wire
   delay dominates gate delay, so place-and-route can only make these numbers
   worse, never better.
3. **GT2N ships one process corner** (`tt`, 0.7 V, 25 °C). There is no slow
   corner, so there is no signoff margin analysis.

Treat every frequency below as an **optimistic upper bound**.

---

## 1. What this is

A GPU written from RTL up: shader cores, floating-point units, tensor units,
a cache hierarchy with real coherence, a memory controller, and a compiler
that produces machine code the RTL actually executes.

It is **not** a product. There is no manufactured chip, no driver you can
install, and no benchmarked frame rate. Its honest peer group is academic
open-source GPUs — MIAOW, Vortex, Nyuzi — not NVIDIA silicon.

What it genuinely does, verified:

- Runs compiled kernels end to end: **Python → Titan ISA → RTL simulation →
  a result matrix matching NumPy bit for bit**
- IEEE-754 FP32 arithmetic verified against an independent integer oracle
- MESI cache coherence across 4 L1 caches with an invariant monitor
- A self-checking full-chip render test producing a correct triangle

---

## 2. Compute — measured at 2 nm

All figures: GT2N, ELVT threshold voltage, wide nanosheet (w31), `tt` corner.

| Block | Area | Critical path | Frequency |
|:--|--:|--:|--:|
| FP32 fused multiply-add | 476.85 µm² | 401.81 ps | **2.49 GHz** |
| Tensor processing element | 283.29 µm² | 433.06 ps | **2.31 GHz** |
| Segmented multiplier | 105.16 µm² | 586.47 ps | 1.71 GHz |
| FMA lane (with power gating) | 488.37 µm² | 415.10 ps | 2.41 GHz |
| HBM4 controller | 724.96 µm² | — | — |

**2.49 GHz is a hard floor for this design.** Tightening the synthesis target
from 200 → 150 → 120 ps produced identical timing and only more area. Three
separate attempts to beat it — adding a pipeline stage, rewriting the sticky
logic, splitting the FMA into 9 stages — all made it **worse**. The blocks
are limited by electrical load and fanout, not by logic depth, which is
exactly why adding registers does not help.

### How it got there

The FMA started at 658.71 ps against a 333 ps target in its own header. Two
structural defects were found by reading the critical path rather than
guessing:

- **Ripple-carry adders.** GT2N has no adder cells at all — no full adder, no
  carry cell — so a plain `+` on a 106-bit value became a long carry chain.
  Replaced with a Kogge-Stone parallel-prefix adder (carry depth O(W) →
  O(log W)).
- **A "CLZ tree" that was not a tree.** The count-leading-zeros stage was
  written as a 106-deep linear scan. Replaced with a real logarithmic
  reduction tree.

Result: **658.71 → 401.81 ps**, a 39% improvement. A control experiment
separates the causes: **28.4% is the RTL change** measured at matched tool
effort; the rest was driving the synthesizer harder.

The tensor PE had the same disease plus one of its own — its sticky-bit mask
was built as `(1 << n) - 1`, a 137-bit ripple *decrement* in series with a
137-bit OR reduction. A mask of n ones needs no arithmetic:
`~(~0 << n)`. **1239.29 → 433.06 ps, a 2.13× speedup.**

---

## 3. Tensor / AI throughput

The tensor datapath is **precision-scalable**: one FP32-width multiplier
array subdivides, with only the summation network switching by mode — no
duplicated multiplier silicon.

| Mode | MACs per lane per cycle |
|:--|--:|
| Full width (24×24) | 1 |
| Half (4 × 12×12, outer product) | 4 |
| Tile (16 × 6×6) | **16** |

Accumulation is **exact integer** — nothing rounded, saturated or truncated
anywhere in the loop. Verified exact to a chain depth of 256.

### Why the width matters

This was nearly built the wrong way. The existing FP16 tensor PE has an 11×11
multiplier; segmenting *that* gives only 2× and 4× at lower precision. At
40,000 lanes that is 398 TOPS FP8 and 797 TOPS FP4 — **a 2× loss to an RTX
5090**. The FP32-width datapath is not a preference, it is the requirement.

The ratios are physical: a 24×24 multiply is 576 bit-products; 4 × FP16 needs
484, 8 × FP8 needs 128, 16 × FP4 needs 64. All fit.

---

## 4. Memory subsystem

| Property | Value |
|:--|:--|
| External interface | **8 × 1024-bit HBM4 channels** (8192 bits total) |
| Cache line | 128 bytes |
| Beats per line | **1** (one full line per channel beat) |
| Interleaving | Consecutive lines → different channels |
| Ordering | Out-of-order across channels, tag-matched |
| Address space | 40-bit, 1 TiB |
| L1 | 4-way, MESI coherent, **with flush/writeback-all** |

**Why 8 channels and not one 8192-bit bus.** A single bus that wide does not
work — this was measured, not assumed. The line-fill logic computes
`beats = line_bits / bus_width`, so above 1024 bits on a 128-byte line that
integer division truncates to **zero** and the transfer never terminates.
1024 bits is already one whole line per beat; there is nothing left to widen.
Real HBM has never been one wide bus either — bandwidth comes from many
independent channels, each with its own row buffers.

Measured beats to move one cache line:

| Bus width | Beats |
|:--|--:|
| 32-bit | 32 |
| 512-bit | 2 |
| **1024-bit** | **1** |

### Cache flush — a host can read kernel results back

Until this work, a kernel's results could sit in a Modified cache line
forever — a kernel that stored a value and exited left memory reading zero,
which made the GPU unusable from a host regardless of compute speed.

Both cache levels are write-back, so flushing L1 alone was never enough: L1
writes back to the coherent bus, and the coherent bus terminates at L2, which
had no flush port. `CMD_FENCE` now runs a device-level flush and raises its
completion interrupt only when every dirty line has reached memory:

| Stage | What it does |
|:--|:--|
| 1. All 8 L1s | writeback + invalidate, in parallel |
| 2. Crossbar drain | wait for the split-transaction queue to empty |
| 3. L2 | writeback + invalidate every (bank, set, way) |

The drain is not a safety margin. An L1's `flush_done` means the crossbar
*accepted* its last writeback, not that it reached L2 — so flushing L2 first
would let those writebacks land in sets the walk had already passed.

| Measurement | Value |
|:--|--:|
| Full device fence, whole chip | **3,411 cycles** |
| L1 walk, 3 dirty lines | 17 cycles |
| L1 walk, clean cache | 11 cycles, no bus traffic |
| L2 walk, 4×4×8 entries, clean | 131 cycles |

**Verified against memory, not against the cache.** The compute testbench used
to read results out of the cache hierarchy; it now queues a real `CMD_FENCE`
in the ring buffer, waits for the interrupt, and reads the AXI memory model.
Control experiment: with the flush disabled, the same test fails with VRAM
reading `00000000` while the values sit in the caches.

Of the eight L1s, the four TMU texture caches are read-only, so they
contribute invalidation rather than writeback.

---

## 5. Register file

Storage is a **pool**, not fixed per-warp windows. The scheduler hands each
warp a base row, so a kernel declaring 32 registers per thread runs twice the
warps of one declaring 64 — out of the same silicon.

The measurement that justified it: at 8 lanes, 64 registers × 4 warps and 32
registers × 8 warps cost **exactly the same** (20,079.08 µm²). Area tracks
total capacity, not how it is divided. So the division does not have to be
fixed at build time.

| Configuration | Bits | Area |
|:--|--:|--:|
| 64 regs × 8 warps | 131,072 | 37,398.80 µm² |
| 64 × 4 *or* 32 × 8 | 65,536 | 20,079.08 µm² |
| 32 regs × 4 warps | 32,768 | 11,532.96 µm² |

---

## 6. Die area

Cell area only — no routing, clock tree, power grid, PHYs or pads. A 70%
utilisation factor is applied for a realistic die.

**20,000 lanes:**

| Block | mm² | Share |
|:--|--:|--:|
| FP32 FMA lanes | 9.54 | 8.8% |
| Tensor PEs | 5.67 | 5.2% |
| Register files | 50.20 | 76.8% |
| **Die at 70% utilisation** | **93.43** | |

**40,000 lanes: 186.86 mm²** — 25% of a 4090's die, 22% of the reticle limit.

**The register file dominates.** It is flip-flops because **GT2N has no SRAM
and no memory compiler**. This is the single largest inefficiency in the
design, and closing it is worth more than every frequency optimisation
combined: on the stated (and *not measured*) assumption that an SRAM bitcell
is ~10× denser than a flop, the whole design would drop to roughly 35 mm².

---

## 7. Versus RTX 5090

5090 figures are published specifications: 21,760 CUDA cores at 2.41 GHz,
750 mm² on TSMC N4P, 575 W, 32 GB GDDR7 on a 512-bit bus, 1.79 TB/s. Tensor
figures are **dense** — NVIDIA quotes 2:4 sparse, which is double.

| | RTX 5090 | TITAN APEX-X (40,000 lanes) |
|:--|--:|--:|
| FP32 | 104.8 TFLOPS | **199.2 TFLOPS — 1.90×** |
| Low precision | 1,676 TOPS (FP4 dense) | **3,187 TOPS — 1.90×** |
| Clock | 2.41 GHz | 2.49 GHz |
| Compute die area | 750 mm² (whole chip) | 186.86 mm² (compute only) |
| Memory | 512-bit GDDR7 | 8 × 1024-bit HBM4 |

**This comparison is arithmetic, not a benchmark.** It multiplies lanes ×
clock × operations-per-lane. It says nothing about achieved performance on a
real workload, which depends on the memory system, the scheduler, the
compiler and the driver — three of which are immature here and one of which
does not exist.

The method is at least calibrated: applying the same formula to the 5090's
own specifications reproduces its published 104.8 TFLOPS.

---

## 8. Verification

| Suite | Result |
|:--|:--|
| Full regression | **29 / 29 PASS** |
| Deep compute kernels | **14 / 14 PASS** (32 min 20 s) |

The deep suite runs the whole compiler → ISA → RTL path: loop trip counts
0/1/2/17/64, all six comparison conditions, predication, and
**`matmul_bit_exact_vs_numpy` — a matrix multiply matching NumPy word for
word.**

### Formal proofs

Where equivalence could be proven rather than sampled, it was:

| Property | Result |
|:--|:--|
| Prefix adder == `a + b + cin` (106-bit) | proven |
| LZC tree == the linear scan it replaced | proven |
| Optimised FMA == original, **all cycles** | 2172 cells proven, 0 unproven |
| Optimised tensor PE == original, **all cycles** | 1250 cells proven, 0 unproven |

These cover *all* inputs, not sampled vectors.

### Mutation testing

Every new test was checked by injecting a defect and confirming the test
fails. This found two suites that were **passing while proving nothing**:

- The register file could be made **completely warp-shared** — all 8 warps
  sharing one set of registers — and the SM suite still passed with identical
  performance.
- The FMA differential had **near-zero coverage of round-to-nearest-even**;
  deleting the tie-breaking logic left all 4,000 vectors passing.

Both are now covered by tests that provably fail when the defect returns.

---

## 9. What is not built

Stated plainly, because a specification that hides its gaps is marketing.

**Cannot be solved with Verilog:**

- **Memory and PCIe PHYs.** These are transistor-level *analog* IP — DLLs,
  per-bit deskew, training state machines. They are licensed, not written.
  The file in this repo named like a PHY contains `assign tx_ready = 1'b1;`
  and a comment saying "simplified for simulation". It is not a PHY.
- **A graphics driver.** A conformant Vulkan/DirectX driver is tens of
  millions of lines plus a conformance test suite. There is none.
- **Power delivery network.** Metal grids, bump maps, decoupling capacitors
  and IR-drop analysis are physical layout, not RTL.

**Buildable, not yet built:**

- Place-and-route. Everything here is synthesis; this is the only way to find
  out how much of the 401.81 ps is wire.
- FP8/FP4 formats need a block-scaling exponent layer above the integer MAC.
- The chiplet interconnect and the 256 MB distributed L2.
- 64-bit addressing (registers are 32-bit, capping threads at 4 GiB).
- A branch reconvergence stack for divergent control flow.
- DFT/scan — **GT2N has no scan flop**, so this cannot be inserted on this PDK.
- Clock-tree gating — **GT2N has no integrated clock-gating cell**.

---

## 10. Summary

| | |
|:--|:--|
| Process | GT2N 2 nm GAAFET, predictive, **not fabbable** |
| FP32 clock | 2.49 GHz (measured, synthesis only) |
| Tensor clock | 2.31 GHz |
| Peak FP32 | 199.2 TFLOPS at 40,000 lanes |
| Peak low precision | 3,187 TOPS |
| Memory | 8 × 1024-bit HBM4, 1 beat per cache line |
| Die (compute) | 186.86 mm² at 40,000 lanes |
| Verification | 29/29 suites, 14/14 deep, 4 formal equivalence proofs |
| Codebase | ~20,800 lines Verilog, ~9,100 lines tests |
