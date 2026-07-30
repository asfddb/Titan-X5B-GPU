# TITAN APEX (30,000 cores @ 5 GHz) — what is buildable on GT2N, measured

*2026-07-29. Every number here comes from a synthesis run or from GT2N's own
Liberty data. Reproduce with `syn/gt2n/run_gt2n.sh` and `syn/gt2n/leakage.py`.*

The APEX spec has four pillars. Two are implementable and measured below.
One is **inverted** and would make the design slower. One is **not
implementable on this PDK at all**. Details, with evidence.

---

## 1. Correction: the FMA is already 8 stages; 31 is ONE stage's depth

> *"Take the existing 31-level, 106-bit FMA and super-pipeline it into 5 to 6
> balanced stages."*

This reads the 31 as a whole-pipeline figure. It is not. `titan_x7_fp32_fma_pipe`
is **already an 8-stage pipeline**, and 31 is the logic depth of its *worst
single stage* — ABC's timing network is register-to-register by construction
("Extracted ... 1167 inputs and 1067 outputs", i.e. flop Q's to flop D's).

So **re-pipelining to 5–6 stages would remove stages and make it slower.**
Going the other way is what the 5–7-level target requires:

| | measured |
|:--|--:|
| current stages | 8 |
| worst stage depth | 31 levels |
| worst stage delay (elvt/w31) | 401.81 ps |
| implied per-level delay | ~12.96 ps |
| logic budget for 5–7 levels | ~65–91 ps |

Reaching 5–7 levels per stage means splitting the critical region roughly
**5×**, i.e. heading for **~24–40 stages total, not 5–6.**

### The 401.81 ps floor is structural, not effort

Asking ABC for a tighter target changes nothing at all:

| target | achieved |
|:--|--:|
| 333 ps | 401.81 ps |
| 200 ps | 401.81 ps |
| 100 ps | 401.81 ps |

The tool is already extracting everything the current stage boundaries allow.
**5 GHz (200 ps) is 2.0× away, and that is with zero wire delay.** Only
re-pipelining moves it.

---

## 2. Correction: Vdd scaling cannot be evaluated here, and fights the goal

> *"drop the theoretical supply voltage by 30–40% to exponentially cut dynamic
> power"*

**GT2N ships exactly one characterised operating point: `tt`, 0.7 V, 25 °C.**
There is no 0.5 V or 0.45 V library. So:

- The delay penalty of a 30–40% Vdd drop **cannot be measured** here — and
  near-threshold operation (0.7 V × 0.6 ≈ 0.42 V) typically costs *several
  times* the delay, which would consume the entire pipelining gain and more.
- The dynamic-power saving **cannot be measured either.** Yosys has no power
  analysis and OpenSTA is not installed, so α·C·Vdd²·f is not computable with
  the current toolchain at any voltage.

The pillar-1 claim — deeper pipelining buys slack, slack can be spent on
voltage — is directionally sound. But slack can be spent on frequency **or**
on voltage, not both from the same budget, and neither the exchange rate nor
the resulting power is measurable on this PDK.

**Static leakage, however, is measurable.** See §4.

---

## 3. Not implementable: ICG cells and cell-level multi-Vt

### GT2N's complete cell list

Verified across all five Vt libraries — this is everything:

```
and2 and3 ao21 ao211 ao22 ao31 ao32 ao33 aoi21 aoi211 aoi22 aoi31 aoi32
aoi33 buf decapcc dffasync inv mux2 nand2 nand3 nor2 nor3 oa21 oa211 oa22
oa31 oa32 oa33 oai21 oai211 oai22 oai31 oai32 oai33 or2 or3 tiehigh tielow
xnor2 xor2
```

**No ICG cell. No latch cell. No scan flop.** The only sequential element is
`dffasync`. Consequences for pillar 2:

- *"Implement fine-grained Clock Gating (ICG cells) at every pipeline
  register"* — **cannot be done.** Building a clock gate from a bare AND is a
  glitch hazard on the clock net; the latch inside a real ICG exists precisely
  to prevent that, and GT2N has no latch either.
- *"Use transparent latches ... to freeze the inputs"* — **no latch cell**;
  isolation must be AND-based clamping, which is what §5 implements.
- Enable-based gating still saves the *register and downstream cloud*
  switching. It does **not** save clock-tree power. On a 30,208-lane design
  the clock tree is a large fraction of dynamic power, so this is a real loss,
  not a technicality.

### Cell-level multi-Vt: the flow cannot do it

> *"force the tool to use HVT for 90% of the logic, restricting LVT strictly
> to critical paths"*

Tested directly. Passing two `-liberty` files to Yosys' `abc`:

```
Library "gt2_6t_w31_hvt_tt_0p7v25c"  ... has 65 cells
Library "gt2_6t_w31_elvt_tt_0p7v25c" ... has 65 cells
```

Both load — and the mapped netlist then contains **18 elvt cell types and
zero hvt**. The second `read_lib` *replaces* the first. Yosys/ABC maps against
one library at a time, so cell-level Vt mixing with critical-path-only LVT
**is not achievable in this flow**.

What *is* achievable is **module-granular** Vt assignment: synthesise each
module against whichever library suits it and integrate hierarchically. That
is coarser than the spec asks for, but it is real, and §4 shows it is worth
doing.

---

## 4. Measured: the Vt trade, and why "ELVT everywhere" melts

All five flavours, identical synthesis effort (`-D 200`, `buffer -N 4`,
`upsize`/`dnsize`), w31/tt. Leakage computed by `syn/gt2n/leakage.py` from
each library's own `cell_leakage_power` and exact `stat -liberty` counts.

| Vt | delay | GHz | area (µm²) | leakage / FMA | **× 30,208 lanes** |
|:--|--:|--:|--:|--:|--:|
| elvt | 401.81 ps | **2.49** | 476.9 | 900.3 µW | **27.20 W** |
| ulvt | 423.20 ps | 2.36 | 476.5 | 341.1 µW | 10.30 W |
| lvt  | 448.05 ps | 2.23 | 476.4 | 173.7 µW | 5.25 W |
| svt  | 554.75 ps | 1.80 | 476.4 | 14.6 µW | 0.44 W |
| hvt  | 761.82 ps | 1.31 | 476.7 | 0.8 µW | **0.02 W** |

**ELVT is 1.90× faster than HVT and leaks 1,125× more.** Area is flat — Vt
buys speed and costs leakage, it does not change footprint.

At APEX scale that is **27.2 W of pure static leakage** for an all-ELVT
design, burned while computing nothing, before a single transistor switches.
All-HVT is 0.02 W but caps at 1.31 GHz.

This is the quantitative case for the spec's multi-Vt pillar — the strategy
is right even though **this flow cannot implement it at cell level** (§3).
Module-granular assignment is the available approximation.

*Leakage only.* Dynamic power remains unmeasurable here.

---

## 5. Implemented: operand isolation (`rtl/fpu/titan_apex_fma_lane.v`)

AND-based clamping of a/b/c/rm whenever the lane is not launching, so the
~10k-cell E2–E5 cloud sees a constant and does not toggle on idle cycles.
Latch-based holding is not possible (§3), and clamping needs no sequential
element anyway.

Measured cost, hvt/w31:

| | area (µm²) | delay (ps) |
|:--|--:|--:|
| `ISOLATE=0` | 486.91 | 807.08 |
| `ISOLATE=1` | 487.84 | 795.48 |

**+0.19% area, no delay penalty.** Essentially free.

An ICG is instantiated behind `` `ifdef TITAN_HAS_ICG `` for a PDK that has
one; on GT2N it must stay undefined.

**Correctness status: the transparency test is written
(`tb/uvm/test_apex_lane.py`, suite `apexlane`) but does NOT yet complete
under Icarus.** A bounded sequential SAT proof was attempted first and is
intractable — two full FMAs unrolled 12 cycles is 2.17 M variables and the
solver did not finish in 9 minutes. The simulation is slow for the reason
documented in `GT2N_2NM_SYNTHESIS.md` §7.4: after the Kogge-Stone/LZC rework
each FMA is hundreds of explicit gates and the miter holds two of them.
**This block is therefore synthesised and measured but not yet functionally
verified. Do not treat it as proven.** Running it under Verilator (now
installed) is the fix.

---

## 6. Scale: the 30,208-lane arithmetic

128 lanes/SM × 236 SMs = **30,208**. Using the measured post-isolation lane:

| | value |
|:--|--:|
| FP32 FMA lane, hvt/w31, isolated | 487.84 µm² |
| × 30,208 | **14.74 mm²** |
| static leakage, all-HVT | 0.02 W |
| static leakage, all-ELVT | 27.20 W |

**14.74 mm² is FMA datapath only.** It excludes register files, schedulers,
LSUs, caches, the NoC and every wire. For scale, an H100 die is ~814 mm², so
the FMA array is a plausible fraction — this is not where the design falls
over.

**Where it does fall over is the register file.** `titan_x7_regfile_banked`
measures **37,288 µm²** because GT2N has no SRAM and no memory compiler, so
the banked structure collapses into 535,419 gates of flip-flops
(`GT2N_2NM_SYNTHESIS.md` §4). One such instance serves 8 lanes. Scaling that
naively to 30,208 lanes gives ~141 mm² of register file — an order of
magnitude more than the entire FMA array, and it is an artefact of the missing
memory compiler rather than of the architecture.

**The register file, not the FMA, is the blocking problem for APEX at 2 nm.**
No amount of pipelining or Vt selection touches it; it needs an SRAM
generator.

---

## 7. Verdict

| Pillar | Status |
|:--|:--|
| 1. Deep-pipelined low-Vdd FMA | **Spec inverted** — needs ~24–40 stages, not 5–6. 401.81 ps is a structural floor; 5 GHz is 2.0× away. Vdd scaling unmeasurable (one corner only). |
| 2. Operand isolation | **Done**, +0.19% area. *Test does not yet complete — unverified.* |
| 2. ICG clock gating | **Not implementable** — no ICG and no latch cell in GT2N. |
| 3. 30,208-lane hierarchy | Area math measured: 14.74 mm² of FMA. **Register file is the real blocker** at ~141 mm² without an SRAM compiler. |
| 4. Cell-level multi-Vt | **Not implementable in this flow** — second `-liberty` replaces the first. Module-granular is the available approximation; the trade is quantified in §4. |

The single highest-value next step is **not** more frequency work. It is an
SRAM macro source (OpenRAM, or FakeRAM2.0-style generated LIB/LEF as ASAP7
does), because the register file currently costs ~10× the entire compute
array.
