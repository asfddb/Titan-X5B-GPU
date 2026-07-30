# Titan X7 on GT2N — real 2 nm synthesis results

*Measured 2026-07-29. Yosys 0.67+111 (oss-cad-suite 2026-07-29) mapping onto
the **GT2N** open-source 2 nm nanosheet GAAFET PDK with backside power
delivery (BSD-3, Georgia Tech; Jang et al., IEEE ISCAS 2026). Every number
below comes from a command that was run; the logs are under
`syn/gt2n/results/`. Reproduce with `syn/gt2n/run_gt2n.sh`.*

---

## 1. What these numbers are, and what they are not

**They are real.** The RTL is mapped onto actual GT2N standard cells with
their characterised Liberty timing — ABC reports the library loading as
"65 cells (7 skipped: 3 seq)". This is not a scaling estimate.

**They are not silicon, and not a chip.** Specifically:

- **GT2N is a PREDICTIVE PDK.** It is realistic and foundry-agnostic, and it
  is **not fabbable**. No foundry will take it. A fabbable 2 nm part needs an
  NDA agreement with TSMC / Intel / Samsung and a mask set costing tens of
  millions; nothing here changes that.
- **Only one corner exists.** GT2N ships `tt` at 0.7 V, 25 °C. There is no
  `ss` or `ff`, so there is **no slow-corner signoff and no margin analysis**.
  The upstream README lists three corners as "under development".
- **Zero wire delay.** ABC reports `WireLoad = "none"`. These are gate delays
  only. At 2 nm wire delay dominates gate delay, so **place-and-route can
  only make these numbers worse, never better.**
- **Synthesis only.** No floorplan, no placement, no CTS, no routing, no
  parasitic extraction, no DRC/LVS. GT2N's DRC/LVS decks are for Synopsys IC
  Validator, a commercial tool.
- No clock uncertainty, skew or setup margin is included.

Treat every delay below as an **optimistic lower bound**.

---

## 2. Headline: the 333 ps/stage design target is missed by ~2x

`titan_x7_fp32_fma_pipe`'s header states a target of "~333 ps/stage on
ASAP7", i.e. 3 GHz. Measured on GT2N across all five threshold-voltage
flavours and both nanosheet widths:

| VT | width | area (um2) | delay (ps) | GHz |
|:--|:--|--:|--:|--:|
| elvt | w31 | 448.71 | **658.71** | **1.52** |
| ulvt | w31 | 448.76 | 691.72 | 1.45 |
| lvt  | w31 | 448.71 | 723.15 | 1.38 |
| svt  | w31 | 448.72 | 885.73 | 1.13 |
| hvt  | w31 | 448.70 | 1216.68 | 0.82 |
| elvt | w13 | 448.71 | 858.48 | 1.16 |
| ulvt | w13 | 448.71 | 908.27 | 1.10 |
| lvt  | w13 | 448.72 | 955.46 | 1.05 |
| svt  | w13 | 448.72 | 1193.81 | 0.84 |
| hvt  | w13 | 448.71 | 1684.32 | 0.59 |

**Even the fastest configuration — ELVT, wide nanosheet, typical corner,
zero wire delay — reaches 658.71 ps, missing the 333 ps target by 1.98x.**
The realistic figure after routing, a slow corner and clock uncertainty is
materially worse than 1.52 GHz.

Two secondary readings, both real design knobs GT2N exists to expose:

- **Vt spread is 1.85x** (elvt 658.71 ps vs hvt 1216.68 ps at w31). Multi-Vt
  is therefore a genuine lever here — but ELVT costs leakage, and GT2N ships
  no leakage-corner data to quantify that trade.
- **Nanosheet width is worth 1.35x** (svt w31 885.73 ps vs w13 1193.81 ps).
- **Area is flat at ~448.7 um2 across all ten.** Vt and width change delay
  and leakage, not footprint — cell count is what sets area.

---

## 3. Why it misses: 58 levels of logic per stage

`stime -p` on the svt/w31 mapping prints a **58-gate critical path**. The
shape of it is the diagnosis:

```
Path  1..14 : or3 / nor3 / nand3 alternating      <- carry propagate chain
Path 15..29+: oai21 / aoi21 / ao31 alternating    <- second carry chain
```

That is **ripple carry**. Two compounding causes:

1. **GT2N has no adder cells.** The library is 69 logic cells: and/or/nand/
   nor/aoi/oai/xor/mux/buf/inv, plus 3 flops. There is no full adder, no half
   adder, no carry cell. Every wide addition in the FMA — the 104-bit
   alignment frame, the 105-bit signed-magnitude add, the exponent path —
   synthesises to a ripple chain out of NAND/XOR.
2. **The stage split was structural, not timed.** The 8 stages were chosen so
   that "no stage carries more than one heavy structure (multiplier half,
   wide shifter, wide adder, CLZ tree, rounder)". That is a sound *principle*,
   but one wide adder is by itself ~58 levels deep here. The partition was
   never validated against real cell delays because until now there was no
   library to validate against.

For scale: Hrishikesh et al. (ISCA 2002) put the optimal logic depth at
**6-8 FO4 per pipeline stage** plus ~2 FO4 of overhead. 58 levels is roughly
an order of magnitude past that.

**This is the actionable result.** Reaching 333 ps needs the adders
restructured — carry-select or carry-lookahead written explicitly in RTL,
since the library gives the synthesiser nothing to work with — not more
pipeline stages around the same ripple chains.

---

## 4. All three blocks

svt / w31 / tt, 333 ps target:

| module | area (um2) | delay (ps) | note |
|:--|--:|--:|:--|
| `titan_x7_fp32_fma_pipe` | 448.99 | 885.73 | 11,431 cells; 1,067 flops = 193.6 um2 (43.1%) |
| `titan_x7_tensor_pe` | 262.92 | 1239.29 | misses target by 3.7x |
| `titan_x7_regfile_banked` | **37,288.91** | **22,022.40** | see below — this one is not real |

### The register file result is a genuine negative, and it matters

37,288 um2 and 22 ns: **83x the area of the FMA and 25x its delay.**

The cause is not a bug in the module. It is that **GT2N contains no SRAM and
no memory compiler.** `titan_x7_sram_1r1w.v` is a behavioural macro model,
and with no macro to bind to, Yosys synthesised all eight banks into flip
flops with the associated address decode and output muxing — which is
precisely the flop-array structure the banked register file exists to
eliminate.

So the honest position is:

- The banked register file is **functionally correct** (suite `rfbank`,
  6 tests, two mutations caught) and is **the right structure** for an
  advanced node.
- It is **not implementable on GT2N as it stands**, and the 37,288 um2 figure
  should be read as "what happens with no memory compiler", not as the cost
  of the design.
- Making it real needs an SRAM macro from somewhere else — OpenRAM targeting
  a compatible node, or FakeRAM2.0-style generated LIB/LEF as ASAP7 does
  (ASAP7 has no memory generator either and ORFS uses FakeRAM2.0 for exactly
  this reason).

---

## 5. Other gaps this exposed in the library

Things a 2 nm GPU needs that GT2N does not have:

| Need | Status in GT2N |
|:--|:--|
| SRAM / register-file macros | **absent** — see above |
| Scan flops | **absent** (only `dffasync_x1/x2/x4`) — DFT/scan cannot be inserted |
| Integrated clock gating cell | **absent** — no ICG for the power intent |
| Full/half adder cells | **absent** — forces ripple carry |
| Flop without async reset | **absent** — every flop carries a reset pin |
| Multi-corner libs | **absent** — `tt` only |
| Open DRC/LVS decks | **absent** — IC Validator (commercial) only |

Note the irony on reset: `titan_x7_sram_1r1w.v` is deliberately written with
no reset on the array, matching a real macro. GT2N's only flop is
async-reset, so every synthesised sequential element gets a reset pin whether
the RTL wants one or not.

---

## 6. Cross-node comparison, stated carefully

| | Titan X5 FMA, sky130 (130 nm) | Titan X7 FMA, GT2N (2 nm) |
|:--|--:|--:|
| cells | 12,575 | 11,431 |
| area | 234,000 um2 (0.234 mm2) | 448.99 um2 |
| clock | 25 ns (40 MHz) | 0.886 ns (1.13 GHz), svt/w31 |
| flow stage | full GDSII, DRC/LVS clean | **synthesis only** |

Area is **~521x smaller** at comparable cell count, and the clock ~28x
faster. Both figures are real, but they are not like-for-like: the sky130
number is a routed, signed-off macro with parasitics; the GT2N number is
pre-layout gate delay with no wires. The sky130 result is the more complete
piece of engineering; the GT2N result is the more advanced node.

---

## 7. Closing the gap: 1.52 GHz -> 2.49 GHz

Section 3 said the fix was to restructure the adders rather than add pipeline
stages. That was done, and then the next bottleneck was found and done too.

### 7.1 What changed

**`rtl/common/titan_x7_prefix_add.v`** — Kogge-Stone parallel-prefix adder,
replacing the bare `+`/`-` on E5's three 106-bit operations and E4's 48-bit
partial-product CPA. Carry depth O(W) -> O(log2 W).

**The 106-bit comparator deleted.** `p_ge_c = (mag_p >= mag_c)` was a *fourth*
106-bit carry chain in E5. Both operands are 105 bits zero-extended to 106, so
the subtract already answers it: `p_ge_c = ~sub_pc[105]`.

**`rtl/common/titan_x7_lzc.v`** — the real find. E6 was described in the
module header as a "106-bit CLZ tree" and was not a tree:

```verilog
for (m = 0; m <= 105; m = m + 1)
    if (e5_sum[m]) msb_idx_c = m[6:0];
```

That is a 106-deep linear priority scan — ~106 chained 7-bit muxes, with the
normalized-exponent add serialised behind it. Once E5's adders were made
prefix, this became the dominant path. Replaced with a log-depth reduction
tree, along with E1's three 24-bit instances of the same pattern.

### 7.2 Measured, elvt/w31/tt

| RTL | synthesis effort | delay | GHz | levels |
|:--|:--|--:|--:|--:|
| original | default (`-D 333`) | 658.71 ps | 1.52 | 58 |
| original | aggressive (`-D 200`, buffer) | 561.15 ps | 1.78 | — |
| prefix + LZC | default (`-D 333`) | 572.18 ps | 1.75 | 31 |
| **prefix + LZC** | **aggressive** | **401.81 ps** | **2.49** | — |

**The control experiment matters here.** Part of the gain is simply driving
ABC harder, which is a tool setting and not an achievement of the design. Run
at *matched* effort:

- tool settings alone, on the original RTL: 658.71 -> 561.15 ps (**-14.8%**)
- RTL alone, at default effort: 658.71 -> 572.18 ps (**-13.1%**)
- **RTL alone, at matched aggressive effort: 561.15 -> 401.81 ps (-28.4%)**
- both together: 658.71 -> 401.81 ps (**-39.0%**, 1.52 -> 2.49 GHz)

Neither gets close to 2.49 GHz on its own; they compose. Area cost of the
whole exercise is **+6.2%** (448.99 -> 476.85 um2).

Logic levels fell 58 -> 31 (**-47%**) while delay fell only 13% at matched
effort, which says the remaining path is **load- and fanout-dominated, not
depth-dominated** — one net on the critical path drives fanout 22 at 10.4 ff
and costs 61.7 ps in a single gate. That is what the buffering pass then
attacks, and it is why the two changes compound.

Against the 333 ps target the miss is now **1.21x**, down from 1.98x.

### 7.3 Correctness: formally proven, not sampled

Every substitution was proven equivalent with Yosys' SAT engine before being
trusted, and then the whole pipeline was proven end to end:

| Property | Result |
|:--|:--|
| `titan_x7_prefix_add` == `a + b + cin`, W=106 | **SAT: proven** |
| `titan_x7_lzc` == the 106-deep linear scan it replaces | **SAT: proven** |
| `~sub_pc[105]` == `(mag_p >= mag_c)` | **SAT: proven** |
| optimised FMA == original FMA, **sequential**, all cycles | **`equiv_induct`: 2172 cells proven, 0 unproven — "Equivalence successfully proven!"** |

The sequential proof needed `async2sync` first; without it `equiv_simple`
aborts on the async-reset flops with "No SAT model available for async FF
cell".

This is stronger than the differential test: it covers all inputs rather
than 6,880 vectors.

### 7.4 The cost, which is real

**Simulation got ~250x slower.** `fma8` ran in 2.3 s before and now exceeds
10 minutes under Icarus, because a Kogge-Stone and a reduction tree are
hundreds of explicit gates each and event-driven simulation pays per gate.
Simulation speed was already the binding constraint on this project (~90
clock cycles per wall second for the whole GPU), so this is a genuine
trade, not a free win. Mitigations, in order of leverage: use Verilator
(now installed) instead of Icarus, or keep a behavioural `+` version behind
a `` `ifdef `` for simulation while synthesising the structural one — at the
cost of simulating something other than what is built, which is exactly the
kind of divergence the formal proofs above would then be guarding.

## 8. The tensor PE: 1239 ps -> 433 ps, and one idea that did not work

The tensor PE was the slowest block in the design at 1239.29 ps, and it is
the one that does matmul, so it is what local-AI throughput rests on.

### 8.1 What worked

Same treatment as the FMA — it had the identical defects:

| site | was | now |
|:--|:--|:--|
| M1, two 11-bit CLZs | linear priority scan | `titan_x7_lzc` tree |
| M3, product negate | 113-bit ripple increment | prefix adder |
| D1, carry-save resolve | 113-bit ripple CPA | prefix adder |
| D2, magnitude negate | 113-bit ripple increment | prefix adder |
| D2, 112-bit CLZ | linear priority scan | `titan_x7_lzc` tree |
| **D3, sticky mask** | **`(1 << down) - 1`** | **`~(~0 << down)`** |

That last one was the real critical path and is worth stating plainly:

```verilog
st_d = |(mag_ext & (({...,1'b1} << down) - 1));
```

is a 137-bit variable shift, then a **137-bit ripple decrement**, then a
137-bit OR reduction, all in series. `stime -p` showed 41 of 47 gate levels
were or3/nand3/nor3 — an OR/borrow chain, not a carry chain, which is what
pointed here. The mask of `down` ones needs no arithmetic at all:
`(1 << down) - 1 == ~(~0 << down)`, **SAT-proven** in
`syn/gt2n/prove_mask.ys`.

### 8.2 Measured, elvt/w31/tt

| RTL | synthesis | delay | GHz | area |
|:--|:--|--:|--:|--:|
| original | default (`-D 333`) | 1239.29 ps | 0.81 | 262.92 um2 |
| original | aggressive | 921.91 ps | 1.08 | 275.79 um2 |
| prefix + LZC | aggressive | 460.90 ps | 2.17 | 284.35 um2 |
| **+ sticky mask** | **aggressive** | **433.06 ps** | **2.31** | **283.29 um2** |

At matched effort the RTL changes are worth **53.0%** (921.91 -> 433.06,
a 2.13x speedup) for **+2.7% area**.

### 8.3 What did NOT work: adding a pipeline stage

The obvious move — the PE's D2 stage chained two log-depth trees (prefix
negate, then LZC), so splitting it across a register should have halved that
path. The drain runs once per tile rather than once per MAC, so the extra
cycle of latency costs no throughput at all: II stays 1. It looked free.

**It made things worse.** Measured, both with the sticky fix in place:

| | delay | area |
|:--|--:|--:|
| with the D2 split | 434.52 ps | 305.42 um2 |
| **without it** | **433.06 ps** | **283.29 um2** |

Identical timing, **+7.8% area**. Reverted.

The reason is the one the FMA already taught: after the prefix/LZC rework
these blocks are **load- and fanout-dominated, not depth-dominated**. Cutting
a path that is not critical buys nothing, and the added flops cost area and
put more load on the nets that *are* critical. The stage split was aimed at
D2 on the assumption D2 was the bottleneck; a diagnostic (stubbing the
zero-compare, then reading the gate histogram) showed the real path ran
through D3's sticky computation instead.

**The lesson is procedural, not architectural: measure which stage is
critical before slicing one.** Pipelining is the right instinct for a
depth-dominated path, and this one was not.

The accumulate loop is separately off-limits: `acc_s`/`acc_c` are
loop-carried, which is the whole reason the accumulator is redundant
carry-save. A register inside that loop breaks single-cycle accumulation.
Only the feed-forward multiply front-end and drain path can be cut at all.

## 9. The 3 GHz question, and the 20,000-lane die budget

### 9.1 2.49 GHz is a structural floor, not a tool setting

Sweeping ABC's delay target on the FMA:

| target | delay | area |
|:--|--:|--:|
| `-D 200` | 401.81 ps | 476.85 um2 |
| `-D 150` | **401.81 ps** | 496.81 um2 |
| `-D 120` | **401.81 ps** | 496.81 um2 |

Identical delay, more area. The tool has nothing left to give: **401.81 ps
(2.49 GHz) is what this RTL structure costs.** 3 GHz means 333.33 ps, so the
gap is 17% and it has to come from the design.

The critical path is now **40 gate levels with 6 buffers on it** and no
single dominant structure — the ripple chains and linear scans are gone. A
distributed 40-level path in one pipeline stage is simply too deep for
3 GHz; closing it means re-partitioning the 8 stages into roughly 10-11,
which is a substantial rewrite of the stage boundaries rather than a local
fix. That is the honest next step, and it is not attempted here.

### 9.2 A negative result worth keeping: the mask trick is width-dependent

Section 8 replaced the tensor PE's sticky mask `(1 << d) - 1` with
`~(~0 << d)` for a 2x win. The FMA's E4 has a *textually similar* sticky:

```verilog
for (k = 0; k < 24; k = k + 1)
    if (k < rsh) c_sticky_c = c_sticky_c | e3_mc[k];
```

Applying the same rewrite there **made it worse: 401.81 -> 460.39 ps.**
Reverted, with a comment in the RTL so nobody "fixes" it again.

The reason is width. At 137 bits the mask form removes a ripple decrement
that dominates everything. At 24 bits there is no decrement worth removing,
the per-bit `k < rsh` comparisons synthesise **in parallel** feeding a
balanced OR, and the mask form instead puts a barrel shift **in series**
ahead of that same OR. Same transformation, opposite sign, decided by
operand width.

### 9.3 Will 20,000 lanes fit on a 2 nm die?

Yes, comfortably. `syn/gt2n/die_budget.py` sums the measured per-block
areas (it is a cell-area budget, not a floorplan — no routing, clock tree,
power grid, PHYs or pads):

| block | mm2 | share |
|:--|--:|--:|
| FP32 FMA lanes (20,000) | 9.54 | 8.8% |
| tensor PEs (20,000) | 5.67 | 5.2% |
| register files, **as built (flops)** | **93.22** | **86.0%** |
| **total cell area** | **108.43** | |
| at 70% utilisation -> die | **154.89** | |

| reference | die | this design |
|:--|--:|--:|
| reticle limit | 858 mm2 | 18.1% |
| H100 | 814 mm2 | 19.0% |
| RTX 4090 (AD102) | 609 mm2 | 25.4% |

**Fitting is not the problem.** The problem is that the register file is
**86% of the area**, holding 39.1 MiB in flip-flops because GT2N has no SRAM
and no memory compiler (section 4). On the stated -- and *not measured* --
assumption that a compiled SRAM bitcell is ~10x denser than a flop, the same
design is 24.53 mm2 of cells, about 35 mm2 of die, 5.8% of a 4090.

So the single highest-value change available is still an SRAM macro source,
not more frequency: it is worth ~4.4x the whole die area, where the entire
FMA rework was worth 39% of one block's delay.

### 9.4 "Every core works"

Per-lane correctness is structural rather than exhaustively simulated:
every lane is an instance of one module, and that module is proven — the
FMA and tensor PE are each SAT-proven sequentially equivalent to their
pre-optimisation versions (sections 7.3 and 8).

Instance-level independence is verified at **N=16** by the `tensor7` suite,
which checks all 4x4 PE outputs individually against an exact reference for
K=1/4/16/64 and back-to-back tiles. That is the largest array that
simulates in reasonable time: 16 PEs already exceeds 9 minutes under Icarus
(section 7.4). Simulating 20,000 lanes is not feasible here and is not
claimed.

## 10. Reproducing

```bash
export GT2N_ROOT=/path/to/GT2N
export OSS_CAD=/path/to/oss-cad-suite
./syn/gt2n/run_gt2n.sh titan_x7_fp32_fma_pipe rtl/fpu/titan_x7_fp32_fma_pipe.v
```

Downloads: oss-cad-suite Windows x64 363 MB (YosysHQ release 2026-07-29),
GT2N 116 MB cloned / 252 MB on disk. Each synthesis run takes well under a
minute; the ten-point sweep above is a few minutes total.
