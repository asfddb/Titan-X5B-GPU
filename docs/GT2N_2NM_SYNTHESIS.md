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

## 7. Reproducing

```bash
export GT2N_ROOT=/path/to/GT2N
export OSS_CAD=/path/to/oss-cad-suite
./syn/gt2n/run_gt2n.sh titan_x7_fp32_fma_pipe rtl/fpu/titan_x7_fp32_fma_pipe.v
```

Downloads: oss-cad-suite Windows x64 363 MB (YosysHQ release 2026-07-29),
GT2N 116 MB cloned / 252 MB on disk. Each synthesis run takes well under a
minute; the ten-point sweep above is a few minutes total.
