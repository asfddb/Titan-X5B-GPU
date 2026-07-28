# Titan X5 → Real Working GPU: Architecture Roadmap

**Goal:** take Titan X5 from *"a set of correct GPU blocks that simulate"* to
*"a GPU that runs a real program, on real hardware, that you can hold."*

The organising rule of this roadmap is that **every phase must end in evidence
someone else can re-run.** Not a document claiming something works — a command
that exits 0 on a clean clone. A phase is not done when the RTL is written; it
is done when the gate passes.

---

## 0. Verified baseline (2026-07-28)

Before planning anything, the existing repo was independently re-verified from a
clean container. This is what is *actually* true today, not what is claimed:

| Check | Command | Result |
|:--|:--|:--|
| Transaction regression | `python tb/run_regression.py` | **11/11 suites PASS**, runner exits 0 |
| Full-chip render | `iverilog -s tb_titan_x5_gpu_top … && vvp` | **PASS** — 181 pixels, **0** out of bounds, 14,009 cycles |
| Full-chip synthesis | `yosys … synth -top titan_x5_gpu_top` | elaborates; **603,664 cells** |
| Physical implementation | `openlane/*/final/` | FP32 FMA + tensor core array — real sky130 GDSII |

Toolchain used: Icarus Verilog 12.0, cocotb 2.0.1, Verilator 5.020, Yosys 0.33.

**The baseline is real.** The `REMEDIATION_REPORT.md` claims hold up under
independent re-run — the LSU coalescer, the IEEE-754 FPU, the MESI hierarchy and
the bilinear TMU all pass their scoreboards. That is a genuinely strong starting
position and the rest of this roadmap builds on it rather than around it.

### One reproducibility defect found immediately

On a clean environment, **4 of 11 suites (`lsu`, `fpu`, `mesi`, `tmu`) fail** —
not from a design bug, but because they `import cocotb_coverage` via
`tb/uvm/coverage_util.py`, and that package is not declared in any requirements
file. `pip install cocotb-coverage` also fails outright on Debian/Ubuntu images
whose `setuptools` is distro-patched (`python-constraint` cannot build).

The failure mode is the dangerous kind: *the four most important suites are the
ones that vanish*, and the developer sees "7 passed". Fixed in Phase 0.

---

## 1. Why this is not yet a "real working GPU"

The blocks are good. The problem is that the machine cannot **run a program**.

### The headline blocker

`rtl/titan_x5_gpu_top.v:337`

```verilog
.warp_active(8'hFF), .warp_pc_in(256'h0)
```

Every warp's program counter is **hardwired to zero, from outside the SM**. The
warp scheduler takes `warp_pc` as an *input* it never modifies. Consequently:

- No warp ever advances past instruction 0.
- Every warp refetches the same word from memory forever.
- `dec_is_branch` is decoded in `titan_x5_pipeline.v:149`, wired to the decoder
  at line 161, and **then never read by anything**. Branches are decoded and
  silently discarded.
- `TX6_OP_BARRIER`/EXIT cannot retire a warp, so kernels cannot terminate.

The full-chip render test passes *because* it only needs one instruction to be
executed repeatedly by 32 lanes. It is a real result — the SM→ROP→crossbar→
memory→VRAM path genuinely works — but it is the ceiling of what a
single-instruction machine can demonstrate.

**Everything else in this roadmap is downstream of fixing this.** A GPU that
cannot take a branch cannot run a loop, cannot run a kernel with control flow,
and cannot execute anything the compiler in `compiler/` actually emits.

### The rest of the gap, honestly

| Gap | Where | Consequence |
|:--|:--|:--|
| No instruction cache | `titan_x5_sm.v` | every fetch is a full memory round-trip |
| One outstanding fetch per SM | `titan_x5_pipeline.v:83` | fetch bandwidth ≈ 1 instr / memory latency |
| Coherent xbar serialises | `titan_x5_crossbar.v` | one memory transaction chip-wide at a time |
| LSU handles one warp at a time | `titan_x5_lsu.v` | no hit-under-miss, no MSHR |
| Divergence stack unused | `titan_x5_warp_scheduler.v` | `div_push`/`div_pop` ports exist, nothing drives them |
| Tensor/RT not in the datapath | `rtl/tensor/`, `rtl/raytracing/` | verified standalone, not reachable from an instruction |
| Full chip never placed & routed | `openlane/` | only FMA + tensor array are physical |

Note the shape of this list: the *hard* parts (IEEE-754 FMA, MESI, coalescing,
BVH traversal, a systolic array — all verified, two of them in GDSII) are done.
What is missing is mostly **integration and control flow**, which is more
tractable than what has already been built.

---

## 2. Phases

Each phase states its exit gate as a runnable command. Effort estimates assume
one person working part-time and are deliberately conservative.

### Phase 0 — Make the baseline reproducible *(small)*

The verification story is only worth as much as its reproducibility.

- Add `tb/requirements.txt` pinning `cocotb==2.0.1`, `cocotb-coverage`, `pytest`.
- Make `tb/uvm/coverage_util.py` degrade gracefully: if `cocotb_coverage` is
  absent, fall back to a no-op shim so suites **run without coverage** rather
  than disappearing.
- Have `run_regression.py` fail loudly on a suite that produced no results file
  (it already detects this — surface it as a distinct `ERROR` state, not `FAIL`,
  so an environment problem is never mistaken for a design regression).
- Document the venv path for distro-patched setuptools.

**Gate:** clean container → `pip install -r tb/requirements.txt && python tb/run_regression.py` → all suites PASS, exit 0.

#### Lint portability (open follow-up)

The CI lint job pins `ubuntu-22.04`, which ships **Verilator 4**. On
**Verilator 5** the same command does not merely warn — it *errors out before
linting anything*:

```
%Error: rtl/memory/titan_x5_l1_cache.v:247: Unknown verilator comment:
        '/*verilator 's unroll limit handling (BLKLOOPINIT-safe pattern)*/'
```

A two-line explanatory comment happened to **begin** with the linter's own
name, so v5 parsed it as a metacomment pragma. Fixed (comment reworded only —
no functional change), which unblocks v5 and reveals what was hiding behind it:

| Category | Count | Assessment |
|:--|--:|:--|
| `GENUNNAMED` | 18 | Cosmetic, new in v5 (unlabelled `generate` blocks, IEEE 1800-2017 27.6). Consistent with the categories CI already suppresses — but `-Wno-GENUNNAMED` is not a valid flag on v4, so suppressing it would break the pinned job. Label the blocks instead. |
| `SYNCASYNCNET` | 1 | **A real finding, not cosmetic.** `rst_n` is flopped both synchronously and asynchronously (`titan_x5_crossbar.v:70` async vs `titan_x5_gddr7_pam3_phy.v:67` sync). The CI comment explicitly lists `SYNCASYNCNET` among the lints that "remain fatal", so this is a latent reset-domain inconsistency that the v4 pin has been masking. It matters directly for Phase 6, where reset recovery on real silicon/FPGA is a genuine bring-up hazard. |

Neither is suppressed here. Labelling the generate blocks and resolving the
reset-domain inconsistency should land before the CI lint job is moved to a
Verilator 5 image.

### Phase 1 — Program execution: per-warp PC, branches, EXIT *(the unlock)*

Move the PC **into** the SM and make control flow real.

- New `rtl/core/titan_x5_pc_unit.v`: one PC register per warp (instruction
  index, matching the functional model's `next_pc = pc + 1` semantics), plus a
  per-warp active/retired bit.
- Sequencing: on fetch accept for warp *w*, `PC[w] <= PC[w] + 1`.
- Branch: consume `dec_is_branch` in the pipeline, honour the predicate, and
  redirect `PC[w] <= imm` (absolute instruction index, per `TX6_OP_BRANCH`).
- EXIT: `TX6_OP_BARRIER` with `use_imm && imm == 0xFFF` retires the warp and
  clears its active bit; kernel completes when all warps retire.
- Flush: on redirect, squash the in-flight fetch and any FIFO entries belonging
  to that warp, so a mispredicted-path instruction cannot execute.
- Add a `kernel_entry` input so the command processor can launch at an address.

Correctness is anchored to `driver/titan_x6_gpu_model.c`, which is an existing,
independent functional model of exactly these semantics — the RTL can be
differentially tested against it rather than against a hand-written expectation.

**Gate:** a cocotb suite runs a multi-instruction program with straight-line
sequencing, a taken branch, a not-taken branch, a backward loop with a real trip
count, and EXIT — RTL register state bit-matches the C functional model.

#### Phase 1 status

**Step 1 of 2 — done.** `rtl/core/titan_x5_pc_unit.v` exists and is verified by
the `pc_unit` suite (7 tests: reset/launch, interleaved straight-line
sequencing, absolute-index taken branch, a 6-trip backward loop, EXIT retire
with sibling warps still running, same-cycle priority, and a 4,000-cycle
randomised soak against a reference model that mirrors
`driver/titan_x6_gpu_model.c`). Clean under `verilator -Wall`.

The suite was **mutation-tested** to confirm it is not vacuous — three
independently injected RTL defects were each caught:

| Injected defect | Result |
|:--|:--|
| advance `pc + 2` instead of `pc + 1` | 6/7 tests fail |
| sequential advance given priority over redirect | 2/7 tests fail |
| retired warps allowed to keep advancing | 2/7 tests fail |

Also fixed en route: `sched_pc`/`sched_active_mask` in
`titan_x5_warp_scheduler.v` were **registered** while `sched_warp_id` and
`sched_valid` are combinational, so an accepted fetch was tagged with warp A
while being addressed with warp B's PC. Unobservable while every PC was the
same constant; fatal the moment per-warp PCs differ. Now combinational.

**Step 2 of 2 — remaining: integration.** Wiring the PC unit into
`titan_x5_sm.v` / `titan_x5_gpu_top.v` requires the full-chip testbench to
change at the same time, and that is why it is deliberately a separate step:

`tb/tb_titan_x5_gpu_top.v:299` installs exactly **one** instruction
(`write_vram_word(32'h0000_0000, 32'h07E10001)`) and the render test depends on
all 32 lanes re-executing it forever. Once PCs advance, warps walk off into
zero-filled VRAM. So integration means:

1. consume `dec_is_branch` in `titan_x5_pipeline.v` and drive `redirect_*`;
2. detect `TX6_OP_BARRIER` + `use_imm` + `imm == 0xFFF` and drive `retire_*`;
3. flush the in-flight fetch and any FIFO entries of a redirected warp, so a
   wrong-path instruction cannot reach EX;
4. form the fetch byte address as `code_base + pc*4` (index → address);
5. **rewrite the TB shader as a real program that ends in EXIT**, reproducing
   the same 181-pixel gradient triangle — which then becomes a far stronger
   result than the current one, because it proves real control flow.

Predicated branches (`pred != 0`) additionally need `SETP` and predicate
registers, which the pipeline does not implement yet — the decoder exposes
`is_predicated`/`pred_reg` but `titan_x5_pipeline.v` does not connect them.
That is Phase 4 work; Phase 1 covers unconditional branch and EXIT.

### Phase 2 — Instruction supply *(medium)*

Phase 1 makes fetch *correct*; this makes it *fast enough to matter*.

- Real per-SM I-cache (start direct-mapped, line-sized refill over the existing
  crossbar port) replacing the single-word fetch path.
- Multiple outstanding fetches (retire the `if_pending` single-shot limit).
- Per-warp instruction buffers so one warp's miss cannot starve the others.

**Gate:** measured IPC on a loop kernel improves ≥5× vs Phase 1; I-cache hit
rate reported by a counter in `titan_x5_perf_counters.v`; all prior suites green.

### Phase 3 — Memory system throughput *(medium–large)*

- MSHRs in the L1/LSU for hit-under-miss and multiple outstanding warp requests.
- Split-transaction coherent crossbar (address and data phases decoupled) to
  replace the correctness-first serialising bus, keeping the MESI invariants the
  existing `mesi` suite already checks.
- Keep the existing invariant monitor running throughout — it is the safety net
  that makes this refactor safe to attempt.

**Gate:** `mesi` suite still green *and* a new throughput assertion shows ≥N
concurrent in-flight transactions; no protocol invariant violations under the
4-way race storm.

### Phase 4 — Make the accelerators reachable *(medium)*

The tensor array and RT core are verified and one is in GDSII, but no
instruction can currently reach them from a running program.

- Wire `TX6_OP_WMMA` through `titan_x6_wmma_dispatch` into the SM datapath, with
  operand staging per the ABI registers (R58/R59/R60 strides).
- Drive the warp scheduler's existing `div_push`/`div_pop` divergence stack from
  real predicate divergence, giving true SIMT reconvergence.
- Expose the RT core through the command processor.

**Gate:** `compiler/kernels/matmul.py` compiles to Titan ISA, runs on the RTL,
and its result matches a NumPy reference bit-exactly — end to end, compiler →
ISA → hardware.

### Phase 5 — Scale up to the X6 top *(medium)*

- Bring `titan_x6_gpu_top` (GPC × NoC × banked L2) up on the Phase 1–4 SM.
- Multi-SM, multi-GPC coherence and NoC congestion testing at `MESH_X/Y = 2`,
  then wider.

**Gate:** the full-chip render test passes on `titan_x6_gpu_top` with ≥4 GPCs,
plus a multi-SM kernel with cross-SM coherent sharing.

### Phase 6 — Real hardware: FPGA bring-up *(the "real world working" milestone)*

This is the phase that converts the project from *simulated* to *real*. The
scaffolding already exists (`fpga/fpga_top.v`, `titan_x5_basys3.xdc`, VGA out,
boot ROM).

- Right-size a synthesis config that fits: the full chip is ~604k Yosys cells,
  far beyond a Basys3 (Artix-7 35T). Start with **1 SM, 2–4 warps, small caches,
  BRAM-backed VRAM**, tensor/RT excluded, and grow from there.
- Close timing at a real clock (target 50–100 MHz), fix the CDC between core,
  memory and pixel clocks properly.
- Replace `xilinx_stubs.v` with real primitives; resolve the known
  `titan_x5_fpga_top.v` issues (missing `titan_x5_vram_ctrl`, BUFG).
- Bring-up ladder, in order: blink → boot ROM executes → VGA raster → one
  instruction → **a real kernel with a loop** → triangle on a monitor.
- Consider a larger board (Arty A7-100T / Nexys Video) once 1 SM fits, since
  headroom is the whole constraint here.

**Gate:** a photo/video of a monitor showing a Titan-rendered triangle, plus the
bitstream, timing report, and resource utilisation committed to the repo.

### Phase 7 — Full-chip silicon *(large)*

- Harden the RT core (already in progress per the README).
- Take a *right-sized* full GPU — realistically 1 SM plus caches, not 64 SMs —
  through the complete OpenLane flow as one routed die: floorplan, macro
  placement, CTS, timing closure, DRC/LVS signoff.
- Explore a shuttle (TinyTapeout / Efabless-style) for an actually manufactured
  block.

**Gate:** one GDSII of an integrated GPU (not a single block), DRC/LVS clean,
with a signoff timing report.

---

## 3. Sequencing and dependencies

```
Phase 0 ──▶ Phase 1 ──┬──▶ Phase 2 ──┬──▶ Phase 5 ──▶ Phase 6 ──▶ Phase 7
 (repro)   (control    │   (I-cache)  │   (X6 top)    (FPGA)     (silicon)
            flow)      │              │
                       ├──▶ Phase 3 ──┤
                       │   (memory)   │
                       └──▶ Phase 4 ──┘
                          (tensor/RT)
```

Phases 2, 3 and 4 are independent of one another and can be worked in any order
once Phase 1 lands. **Phase 1 gates everything** — it is the difference between
a collection of blocks and a processor.

If the goal is the shortest path to something undeniably real, the route is
**0 → 1 → 6**: fix reproducibility, make it execute programs, then put a
cut-down version on an FPGA. Performance work (2, 3, 4) can follow on hardware,
where the numbers mean more.

---

## 4. Principles

1. **No claim without a re-runnable command.** The existing remediation report
   is a good model: it names the bug, the file, and the test that catches it.
2. **Differential-test against the functional model.** `titan_x6_gpu_model.c`
   already encodes the ISA semantics; new RTL should be checked against it, not
   against expectations written by the same person who wrote the RTL.
3. **Never let a suite disappear silently.** An environment failure and a design
   regression must not look the same (see Phase 0).
4. **Right-size before hardening.** 64 SMs is a parameter, not a plan. One
   excellent SM on real silicon beats 64 simulated ones.
5. **Keep the honest-scope discipline.** The README's limitations section is the
   most credible thing in the repo. Extend it as capability grows; do not quietly
   drop caveats.
