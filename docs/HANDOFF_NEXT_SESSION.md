# Handoff — next session

Read this first. It is the full context for continuing work on Titan X5.

**Repo:** `asfddb/Titan-X5B-GPU`
**Working branch:** `fix/idreg-forwarding-hole`, cut from local `master`.
Note that local `master` is ahead of `origin/master`; `git push` still does not
work here (see section 5).

---

## 0. STATE AS OF 2026-08-06 — the I-cache bug is fixed, and it was never an I-cache bug

The previous session left the instruction cache **disabled** with an open bug:
26.9% faster on the render test, but every multi-line compute kernel returned
0. The note at the instantiation site said "root cause not yet found; it is an
integration/timing interaction."

It is neither an integration issue nor an I-cache bug. It is a **one-cycle
forwarding hole in `titan_x5_pipeline.v` that has been there the whole time**,
and the cache is simply the first thing fast enough to expose it.

### The bug

An instruction spends one cycle in the ID *register* (`id_valid_reg`, `id_rd`)
between being popped from the instruction FIFO and launching into EX. During
that cycle it is in **none** of the three forwarding sources — `ex_*`, `mem_*`
and `wb_*` all describe stages it has not reached — and no interlock covered
it. A consumer popped in that same cycle read its operand from the register
file and got the pre-write value.

Caught with a new `TITAN_ID_TRACE` build on the trip=1 counted loop:

```
IDTRACE  op=21 rs1=2(00000000) rs2=4(00000000) cond=3 res=ffffffff
IDTRACE+ idreg(v=1 rd=4) ex(v=0 rd=3) mem(v=1 rd=3) wb(v=0 rd=2)
```

`SETP.GE p1, i, bound` read `bound` as 0 while `li bound, 1` sat in the ID
register with `rd=4`. `GE(0,0)` is true, so the loop-exit branch fired on
iteration zero and the kernel stored 0 — exactly the reported symptom.

**Why it hid for the entire project:** without a cache, every fetch is a full
crossbar round trip, so consecutive instructions reached ID roughly 48 cycles
apart and every producer had long since written back. The hole needs a
producer-consumer distance of one cycle, and nothing in this design could
produce that until the cache removed the latency. It is not SETP-specific
either — the same trace shows the `end:` block's address computation reading a
stale R5.

**This is the fourth time in this project that slow fetch or a shared
misunderstanding hid a real defect.** The pattern is worth naming: a test that
passes only because the machine is slow is not passing.

### The fix

An interlock, not a new forwarding path — the producer's result does not exist
yet, so there is nothing to forward. `id_ready` splits in two:

```
id_issue_ok = !ex_busy && !hazard            -- EX may take the ID register
id_ready    = id_issue_ok && !idreg_hazard   -- the FIFO head may pop
```

`ex_launch` uses `id_issue_ok`. **Using `id_ready` there deadlocks** — it would
hold back the very instruction whose departure clears the hazard. The ID
register is cleared when it drains without a replacement, so the hazard
self-clears in exactly one cycle.

### Measured

**Control experiment**, trip=1, I-cache on:

| | result | cycles |
|:--|:--|--:|
| with the interlock | `0x7` correct | 5,220 |
| interlock mutated out | `0x0` | 4,827 |

4,827/`0x0` is the original failure reproduced exactly. The fix is
load-bearing.

**Matched baseline, I-cache OFF.** All 15 deep-suite kernels are
byte-identical to the pre-fix numbers — 4,664 / 4,952 / 5,240 / 9,560 /
23,096 / 6,728×6 / 4,760 / 5,164 / 69,022 / 35,864 — and the render test is
byte-identical too (181 pixels, 0 poison, last write 6,989, span 5,818). The
interlock never fires when fetch is slow, so it costs **nothing** on the old
default path. That makes every comparison below clean.

**Deep compute suite, x5, I-cache ON: 15/15 — the first time it has passed.**

| kernel | I-cache off | I-cache on | Δ |
|:--|--:|--:|--:|
| counted loop, 0 trips | 4,664 | 5,201 | +11.51% |
| counted loop, 1 trip | 4,952 | 5,220 | +5.41% |
| counted loop, 2 trips | 5,240 | 5,230 | −0.19% |
| counted loop, 17 trips | 9,560 | 5,441 | **−43.09%** |
| counted loop, 64 trips | 23,096 | 6,104 | **−73.57%** |
| SETP EQ | 6,728 | 7,208 | +7.13% |
| SETP NE | 6,728 | 7,217 | +7.27% |
| SETP LT | 6,728 | 7,217 | +7.27% |
| SETP GE | 6,728 | 7,188 | +6.84% |
| SETP LTU | 6,728 | 7,208 | +7.13% |
| SETP GEU | 6,728 | 7,208 | +7.13% |
| predicated instruction skipped | 4,760 | 5,211 | +9.47% |
| host reads results from memory | 5,164 | 5,653 | +9.47% |
| matmul 4×4×4, bit-exact | 69,022 | 13,476 | **−80.48%** |
| predicates are per-warp (8 warps) | 35,864 | 6,324 | **−82.37%** |

**Full-chip render test**, self-checking, both with the interlock:

| | off | on | Δ |
|:--|--:|--:|--:|
| first framebuffer write | 1,171 | 1,085 | −7.34% |
| last framebuffer write | 6,989 | 5,126 | **−26.66%** |
| write span | 5,818 | 4,041 | **−30.54%** |
| wrong-path poison pixels | 0 | 0 | — |

Regression: **34/34**.

### The regressions are real — read them

Six kernels got 5–11% **slower** with the cache on. That is not noise and it
is not a measurement artefact. The fill is **sequential and blocking**: a cold
miss costs `LINE_BYTES/4` = 16 crossbar round trips before the SM sees any
instruction at all. A kernel that runs straight through one line once pays for
16 words it never reuses. Anything with a loop or reuse wins enormously; a
15-instruction straight-line kernel loses.

This is a known, understood cost with a known fix — see task 2 below.

### THE X7 HYPOTHESIS IN THE PREVIOUS HANDOFF IS WRONG

That handoff concluded X7 lost 14 of 15 kernels because dual-issue is
cross-warp only (`titan_x7_warp_scheduler.v:91` requires `sel0_warp != i1`),
and predicted the sign would flip with eight warps. **It does not.**

X7 also passes **15/15 with the I-cache on** — `titan_x7_sm` does not share the
x5 pipeline's hole. Matched, both SMs, cache on:

| kernel | x5 | X7 | Δ |
|:--|--:|--:|--:|
| counted loop, 64 trips | 6,104 | 6,756 | +10.68% |
| SETP (six cases) | ~7,208 | ~7,240 | +0.26…+0.81% |
| predicated skip | 5,211 | 5,211 | 0.00% |
| host reads results | 5,653 | 5,653 | 0.00% |
| **predicates per-warp (8 warps)** | 6,324 | 6,449 | **+1.98%** |
| **matmul 4×4×4** | 13,476 | **10,971** | **−18.59%** |

The 8-warp kernel went from **−1.71% (X7 ahead)** to **+1.98% (X7 behind)**
once fetch was fixed. So X7's one previous win was not dual-issue at all — X7
was merely *less starved* by the fetch port than x5, and fixing fetch removed
that advantage.

What X7 actually wins is **matmul, by 18.59%**: the one kernel with real
instruction-level parallelism in its instruction stream. The mechanism is ILP,
not warp count. **The thing to benchmark next is kernels with independent work
in the instruction stream, not simply more warps.**

For reference, X7 against its own pre-cache numbers: matmul 69,646 → 10,971
(−84.25%), 8 warps 35,249 → 6,449 (−81.71%), 64-trip loop 23,624 → 6,756
(−71.40%).

### Simulation is no longer one core out of sixteen

`tools/run_compute_parallel.py` runs the deep suite across every core. The
cases are independent — each is its own `vvp` process with its own temp
directory — so only elaboration is shared, and that is done serially up front
(concurrent builds of the same `.vvp` path would interleave writes, and the
mtime reuse check cannot see that happening).

The x5 I-cache-on suite took **21:43 serial**. The x5 I-cache-off suite ran in
**1,000 s wall at `-j 10`** while sharing the machine with another full run.
The X7 suite finished in **138 s**.

Every document in this project called simulation speed the binding constraint
while using 1/16th of the machine. Use this runner.

```bash
python tools/run_compute_parallel.py            # cores-1 jobs
python tools/run_compute_parallel.py -j 8 -k matmul
TITAN_ICACHE=1 TITAN_SM=x7 python tools/run_compute_parallel.py
```

### New diagnostics

- `TITAN_ID_TRACE` — every ID commit with the operand values SETP and BRANCH
  actually saw, plus which stage holds which `rd`. Tagged with `%m`, so the
  four SMs can be told apart. This is what found the bug; reach for it before
  reading RTL.
- `TITAN_ICACHE_TRACE` — the cache's core-side handshake.
- `TITAN_DEFINES=A,B` in `compute_runner` adds arbitrary defines **and folds
  them into the image identity**, without which the mtime reuse check hands
  back an image built without them.
- I-cache geometry is overridable:
  `TITAN_DEFINES=TITAN_ICACHE_LINE_BYTES=32,TITAN_ICACHE_SETS=128`.

---

## 0a. NEW 2026-08-12 — FPGA bring-up rig, and the reset bug it found

There is now a way to bring the display path up on a Basys 3 without owning a
Basys 3. Full write-up in **`docs/FPGA_BRINGUP_NO_BOARD.md`**; one command:

```bash
python tools/run_fpga_bringup.py
```

It runs `tb/tb_board_bringup.v` against the RTL, synthesises the display path
to Artix-7 cells, runs the *same* testbench against the netlist with yosys's
Xilinx primitive models, and diffs the two captured frames.

**The rule that makes it work: that testbench has no hierarchical reference
into the design.** Only the 100 MHz pin, the buttons, the switches, the 16 LEDs
and the five VGA wires. A `vga_monitor` model measures sync from the pins,
recovers the pixel grid the way a monitor's PLL does, and captures frames to
PPM. `tb/tb_display_top.v` stays as the RTL unit test.

**Measured, synthesis:** 1,605 LUT / 2,883 FF / 32 RAMB36 / 1 DSP48 against the
xc7a35t's 20,800 / 41,600 / 50 / 90. It fits, BRAM tightest at 64%. First
whole-design fit number for any Titan configuration.

**Measured, at the connector:** 449 lines, 32.000 us line period, 96-pixel
hsync, 2-line vsync, 14.368 ms frame, 25.0000 MHz recovered pixel clock — all
matching the 640x400@70 mode. All five captured frames are **100.0000% correct
against the expected pattern**, 0 X pixels.

### It found a real bug, and it is the fifth of the same kind

**Cold power-on with nothing pressed produces no video at all** — 0 hsync edges
in 5 ms. The core domain is fine (VRAM fills, `led[0]` lights at 101 us); the
VGA connector is dead.

`rst_n` is built by a synchroniser on `clk_core` (100 MHz) and handed to the
display engine, whose counters run on the 25 MHz `pclk`. Out of configuration
`rst_n` releases on the same edge that `pclk_div` first produces a pixel clock
edge. Measured with a counter on pclk edges taken while `rst_n` is low:

| | pclk edges while `rst_n` low | `h_counter` after |
|:--|--:|:--|
| cold boot, nothing pressed | **0** | **x** |
| after a btnC press | 70,400 | 0 |

The display engine's reset branch never executes, so `h_counter` stays X.

**`tb/tb_display_top.v` starts with `reg btnC = 1;` — it holds reset for you.**
That one line is why this was never seen. Same pattern as the four already
named in section 0: a test that passes because the harness helped.

On the Basys 3 this is masked — configuration loads INIT into every flop, so
`h_counter` starts at 0 regardless. **On the GT2N ASIC target there is no
configuration and no INIT**, so this design would come up with garbage counters
and no video, permanently. It is also a genuine reset-domain crossing: `rst_n`
is released in `clk_core` and used as an async reset in `pclk` with no
re-synchronisation — the `SYNCASYNCNET` hazard section 5 already lists.

**Not fixed here.** The fix is a pixel-domain reset synchroniser (assert async
from `rst_n`, release synchronous to `pclk`), which needs a second reset port
on `titan_x5_display_engine` and therefore touches `titan_x5_gpu_top` too.
Changing the reset architecture of a shared module is a deliberate design call,
and this session built the instrument rather than making it. **Do this next —
see task 6.**

Also found: **hsync polarity is active-high, and IBM VGA assigns 640x400@70
negative hsync** (the polarity pair is how a monitor tells this mode from
640x350 and 720x400 at the same line rate). And the picture sits **+1 pixel**
right of the sync pulses, measured from the connector — the same skew
`tb_display_top.v` compensates for internally, now quantified externally.

## 0a2. NEW 2026-08-12 — a DOOM-style renderer, end to end

`docs/DOOM_ON_TITAN.md`. Not DOOM — DOOM needs a CPU and Titan is a GPU — but
the rendering half, which is what a GPU is for.

`compiler/kernels/doom_raycast.py` is a raycaster in the Titan kernel language,
compiled by this project's compiler to **201 Titan ISA instructions**, executed
by `titan_compiler.simulate()` (**18,286,662 retired per frame**), checked
against an independent Python reference (**32,000/32,000 framebuffer words
identical**), then scanned out by the real display path and captured off the
VGA connector: **255,600/255,600 pixels, 100.0000%**, at the same +1 px skew
the bring-up rig measures.

```bash
python tools/doom_titan.py --x 28.5 --y 24.0 --angle -1.5708 --check
```

Two things worth carrying forward:

- **The kernel language has no `if`.** `ScalarCodegen.gen_stmt` takes
  assignment, augmented assignment and `for ... in range(...)`, nothing else.
  Every conditional is `(a - b) >> 31` used as a full-width mask. This is a
  genuinely usable technique for this compiler and it is written up in the doc.
- **Rendering is constant-time** — four camera positions retired an identical
  instruction count, because nothing is data-dependent. That also means no
  branch divergence, which matters given the pipeline skips instructions whose
  predicate lanes disagree.

**The ray cast now runs on the actual SM cores, bit-exact.**
`compiler/kernels/doom_raycast_tile.py` is the same cast with the loop bounds
parameterised; `tools/doom_rtl_tile.py` runs it both ways and compares.
**142 instructions, 13,450 retired, 76,731 RTL clock cycles, 12/12 words
identical to the functional model** — four distinct answers across three wall
types at four depths, so a constant-returning or mis-masked kernel could not
match by accident.

That is **5.7 cycles per instruction**, I-cache on, one warp, for a tight
integer loop with a dependent load. First measured CPI figure for a real kernel
on this design; it is the number to beat, and the fetch work in task 2 is what
should move it.

The *full frame* is still model-only: 18.3M instructions at ~90 cycles per wall
second does not finish. But the arithmetic in it is now verified on the RTL,
not merely against a model of the machine.

## 0b. TASKS, IN ORDER

**1. Resolve the replay bug below, THEN turn the I-cache on by default.**

The cache itself is ready and the evidence is strong: 15/15 on x5, 15/15 on
X7, render test clean with **0 poison pixels**, regression 34/34, and an
I-cache-off control that is byte-identical on all 15 kernels and the render
test. The win is 26.7% on the render test and 43–82% on every kernel with
reuse.

**It was nevertheless left OFF by default on 2026-08-06**, and the reason is
deliberate rather than cautious-by-default: the line-size sweep uncovered a
**spurious instruction replay in the x5 pipeline** (next section). Enabling
the cache changes fetch timing globally, and that timing is exactly what
governs whether that replay is reachable. Every test the project has passes
at 64 B — but the ID-register hole also passed every test for months, so
"our tests pass" is weaker evidence here than it looks.

Once the replay is understood: flip the ``ifndef TITAN_USE_ICACHE`` sense in
`rtl/titan_x5_gpu_top.v`, keep an opt-*out* define for bisection, rerun the
full regression plus both suites and the render test. **If this is already
done when you read this, check `git log`.**

**2. Critical-word-first, then per-word valid bits.** This is the fix for the
5–11% short-kernel regression, and it is the single biggest remaining
front-end win.
   - *Critical-word-first:* fill starting at the requested word and wrap, and
     answer the core the moment that word arrives instead of at `S_DONE`.
     Cold-miss latency to the first instruction drops from 16 round trips to 1.
   - *Per-word valid bits:* the real prize. Today `core_gnt` requires
     `st == S_IDLE`, so the SM cannot fetch **anything** during a fill even if
     the word it wants has already landed. With per-word valid, sequential
     code streams at fill speed instead of fill-then-run.
   - The existing `icache` suite (6 tests) asserts on **read counts, not
     order**, so it still guards the change. Add a test that asserts the
     critical word is returned before the fill completes — otherwise a
     correct-but-slow implementation passes silently.
   - Do the line-size sweep first (below); it is nearly free and tells you how
     much of the regression is fill width versus fill latency.

**3. Line-size sweep.** 32-byte lines with 128 sets keep the same 4 KiB and
halve the cold-miss fill. Sweepable now without editing RTL. Measure before
assuming 64 is right — it was never justified by measurement.

**4. Re-benchmark X7 on ILP, not warp count.** matmul is the only kernel in
the suite with dual-issuable ILP and X7 wins it by 18.59%. Write two or three
more kernels with independent instruction chains and measure. That is the
evidence that decides whether X7 earns its place in the chip — the warp-count
theory is now falsified, so do not lean on it.

**5. Widen the fetch epoch, carefully.** `titan_x5_pipeline.v`'s wrong-path
epoch is 1 bit and is sound *only* because there is a single outstanding fetch
per SM. Task 2's per-word valid bits do **not** change that (the SM still has
one request in flight; the cache answers it faster). Anything that lets the SM
have two fetches in flight requires widening the epoch first, or wrong-path
instructions will retire. Do not do these together.

### OPEN BUG, FOUND 2026-08-06: 16-byte I-cache lines break multi-warp predicates

**Do not adopt a 16-byte line until this is understood.** The line-size sweep
found it, and it is a correctness failure, not a performance one.

```bash
TITAN_ICACHE=1 TITAN_SM=x5 \
TITAN_DEFINES=TITAN_ICACHE_LINE_BYTES=16,TITAN_ICACHE_SETS=256 \
python -m pytest tb/test_compute_kernels.py::test_predicates_are_per_warp -q
```

```
RTL      ['0xe','0x23','0x38','0x4d','0x62','0xcb','0x8c','0xa1']
expected ['0xe','0x23','0x38','0x4d','0x62','0x77','0x8c','0xa1']
```

Warp 5 ran **29 loop trips instead of 17** (0xcb = 7×29, 0x77 = 7×17). Every
other warp is correct. Deterministic — reproduced three times, same value.

What is already known, and what it rules out:

| configuration | result |
|:--|:--|
| 64 B / 64 sets, x5 | PASS, 6,324 cycles |
| 32 B / 128 sets, x5 | PASS, 6,209 cycles |
| **16 B / 256 sets, x5** | **FAIL** |
| 16 B / 256 sets, **X7** | **PASS** |

X7 passing at the same geometry **exonerates the cache, the crossbar and the
memory path** — `titan_x7_sm` does not use `titan_x5_pipeline.v`. The bug is in
the x5 pipeline, exposed by fill timing.

It is not known whether this is pre-existing or was introduced by the
`idreg_hazard` interlock in `cb79dab`. That interlock is verified at 64 B and
32 B (15/15 each, plus a byte-identical I-cache-off control on all 15 kernels
and the render test), so if it is the cause, the trigger is specific to 16 B
fill timing. **Determine this first** — it decides whether this is a new
regression or the fifth timing-hidden defect in this project.

**The mechanism is known — it is a spurious instruction replay, not bad
arithmetic.** `TITAN_ID_TRACE` on the failing run, warp 5's SETP sequence per
SM:

| SM | acc adds | i adds | trips |
|:--|--:|--:|--:|
| 0 | 18 | 18 | 17 |
| 1 | 18 | 18 | 17 |
| **2** | **30** | **30** | **29** |
| 3 | 18 | 18 | 17 |

Only SM2 diverges, on the same program. Its warp-5 trace:

```
12: rs1=2(0000000b) res=00000000     i = 11
13: rs1=2(00000000) res=00000000     i = 0   <-- reset mid-loop
```

`i` resets to 0 after 12 iterations and then runs the full 17: 12 + 17 = 29,
and 7×29 = 203 = 0xcb, the exact observed value. **`acc` does not reset.** So
`li i, 0` re-executed on its own while `li acc, 0` did not — a single stale
instruction retiring in the middle of the loop, long after the pre-loop
prologue.

That points squarely at the **1-bit wrong-path epoch**, which
`titan_x5_pipeline.v` documents as sound *"only because there is a single
outstanding fetch per SM"*. Start there. Widening `warp_epoch`, `if_epoch` and
`fifo_epoch` to 2 bits (counters rather than a toggle) is a contained
experiment: if 16 B then passes, the mechanism is confirmed. Note the
in-order-FIFO argument in that comment claims ABA is impossible; either the
argument or the implementation is wrong, and finding out which is the task.

**Not yet ruled out:** whether the `idreg_hazard` interlock from `cb79dab`
enables this. It does not touch epoch tagging or FIFO push order, but it does
delay pops by a cycle. Control-experiment it before assuming either way.

Reproduction notes: `compute_runner` captures simulator stdout into `res.log`,
which pytest never prints — call the test function directly and dump the log
(see the harness used for this, which wraps `cr.run`). Filter the trace by
`%m` to separate the four SMs; the failure was invisible until SM2 was looked
at on its own.

### Two verification gaps still open from the previous session

- `dbg_pred_divergent` is tied to `1'b0` in the X7 shim, so the deep suite's
  five `assert not res.pred_divergent` checks are **vacuous on X7**.
- X7 still has **no static ISA conformance check** of the kind
  `compiler/test_compiler_isa.py` gives x5. Five divergences have been found
  in that module so far — three by reading, two by running. There is no reason
  to believe five is the total.

### Standing working rules (from the user, still in force)

No invented numbers — say "unknown and unmeasured". Mutation-test every new
test. Control-experiment every fix. Commits end with
`Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`. No PRs unless asked.
Keep this file updated; it is the living handoff.

---

## 1. Environment setup (do this first — nothing is preinstalled)

```bash
apt-get update -qq
apt-get install -y -qq iverilog verilator yosys
pip install cocotb==2.0.1 pytest
```

`cocotb-coverage` is **optional** and often fails to build on distro images
(its `python-constraint` dependency breaks against Debian-patched setuptools).
The suites detect its absence and run without functional coverage. If you want
coverage, use a clean venv:

```bash
python3 -m venv /tmp/venv && /tmp/venv/bin/pip install -U pip setuptools wheel
/tmp/venv/bin/pip install cocotb==2.0.1 cocotb-coverage pytest
```

Versions used previously: Icarus 12.0, cocotb 2.0.1, Verilator 5.020, Yosys 0.33.

## 2. How to verify anything

```bash
# unit/transaction regression - 17 suites, must be 17/17 PASS, exit 0
python3 tb/run_regression.py
python3 tb/run_regression.py fpu lsu          # subset

# compiled kernels on the whole GPU (pytest, not cocotb). run_regression.py
# runs the "not slow" subset as the `compute` suite; this is the full set,
# including the bit-exact matmul. Slow: the design simulates at roughly 90
# clock cycles per wall second, so budget ~25 min plus ~15 min for matmul.
python3 -m pytest tb/test_compute_kernels.py -v

# the compiler's ISA conformance checks (78 checks, and they now actually
# fail pytest -- see the note in that file)
python3 compiler/test_compiler_isa.py

# full-chip render test (the integration test that matters)
cd tb && iverilog -g2012 -s tb_titan_x5_gpu_top -I../rtl -o /tmp/sim.vvp \
    tb_titan_x5_gpu_top.v ../rtl/*/*.v ../rtl/*.v && vvp /tmp/sim.vvp

# lint (v5 needs GENUNNAMED/SYNCASYNCNET suppressed - both pre-existing)
verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-WIDTH -Wno-PINCONNECTEMPTY \
  -Wno-PINMISSING -Wno-UNUSED -Wno-UNDRIVEN -Wno-CMPCONST -Wno-BLKSEQ \
  -Wno-VARHIDDEN -Wno-EOFNEWLINE -Wno-IMPLICIT -Wno-MULTITOP -Wno-LATCH \
  -Wno-GENUNNAMED -Wno-SYNCASYNCNET --top-module titan_x5_gpu_top \
  $(find rtl -name '*.v' ! -name 'titan_x5_fpga_top.v' | sort)

# area, per module, with parameter override
yosys -p "read_verilog -sv rtl/core/titan_x5_alu.v; \
          chparam -set DATA_WIDTH 32 titan_x5_alu; \
          hierarchy -top titan_x5_alu; synth -top titan_x5_alu; stat;"
```

Full-chip Yosys synthesis of `titan_x5_gpu_top` takes **>30 min** (~604k cells).
Budget for it or skip it.

**Environment note (v2.0 session):** that session ran on Windows with Icarus
12.0, cocotb 2.0.1 and numpy 2.5.1, but **no Verilator and no Yosys** — on
Windows those mean the multi-hundred-MB oss-cad-suite, which the no-large-
downloads constraint rules out. So the lint and area commands above were **not
run**, and the area cost of the per-warp register file (8x the flops) and of
the predicate registers is **unknown and unmeasured**. Everything else below
was measured on a command that was actually run.

## 3. Where the project is now

The full-chip render test passes and is genuinely self-checking:
**181 pixels, 0 out of bounds, 0 wrong-path pixels, per-lane gradient intact,
all 8 warps retired, 10,009 cycles.** (It was 8,009 cycles with a single warp;
the extra 2,000 is instruction-supply contention between 8 warps sharing the
SM's one outstanding fetch.)

**The v2.0 headline: `compiler/kernels/matmul.py` runs end to end on the RTL
and is bit-exact against NumPy.** Python source -> Titan ISA -> whole-GPU
Icarus simulation -> a result matrix matching an independent reference word for
word, at 2x2x2 (11,436 cycles) and 4x4x4 (65,311 cycles), signed negatives
included. Test: `tb/test_compute_kernels.py::test_matmul_bit_exact_vs_numpy`.

All three v2.0 steps in section 4b are done. Regression is **17/17**.

Recently completed on this branch:

- **Per-warp register file** (step 1). 64 regs x NUM_WARPS x 32 lanes,
  warp-major. `LAUNCH_WARP_MASK` is back to `8'hFF`. Suite: `regfile`.
- **SETP + per-warp predicate registers -> conditional branches** (step 2).
  Loops can have exit conditions. FP FMA moved from opcode 21 to 29 (see
  section 4b). Tests: `tb/test_compute_kernels.py`.
- **matmul end to end** (step 3), bit-exact vs NumPy.

- **Per-warp PCs and real control flow.** `rtl/core/titan_x5_pc_unit.v` gives
  the SM program counters. Previously `titan_x5_gpu_top` hardwired every PC to
  zero (`.warp_pc_in(256'h0)`), `is_branch` was decoded and discarded, and
  kernels could not terminate. Branches, wrong-path squash (per-warp epoch) and
  `EXIT` all work. Suite: `pc_unit`.
- **L2 addresses 128 GiB** (37-bit). Suite: `l2` (`test_l2_128gib_addressing`).
- **512-bit memory path.** `titan_x5_l2_mem_adapter` fixed (it hardcoded a
  4-byte beat stride, so every width except 32 corrupted the line) and
  `titan_x5_mem_controller` gained a dedicated wide port. Measured 2 beats per
  128-byte line where the 32-bit path needed 64. Suites: `l2adapt32`,
  `l2adapt512`.
- **ALU now matches the ISA** (section 4). Suite: `alu_isa`, plus a static
  opcode-map check in `compiler/test_compiler_isa.py` (run it directly:
  `python3 compiler/test_compiler_isa.py`, 75/75 checks).
- **STORE fixed** — it sourced its data from the address offset instead of
  `rd`, so `STORE [r6+0], r2` stored 0. Now reads `rd` via the spare rs3 port.

The testbench kernel at `tb/tb_titan_x5_gpu_top.v` is now a real program:

```
0: SHL     R6, R62, #2     R6 = tid*4
1: ADD     R6, R6, R3      R6 = DATA_BASE + tid*4
2: STORE   [R6+0], R2      per-lane colour -> VRAM
3: LOAD    R5, [R6+0]      read back via L2 and the 512-bit port
4: ADD     R63, R5, #0     export what memory returned
5: BRANCH  #7              skip the poison
6: ADD     R63, R4, #0     POISON - must never execute
7: BARRIER #0xFFF          EXIT
```

Instruction 6 is a trap: R4 is `0x0000FF00` in every lane, so a failed branch
or a failed squash turns the triangle a uniform colour, which the checker
detects. Control flow is verified by the rendered image.

Background: `docs/ROADMAP_REAL_HARDWARE.md` (phases 0-7 to FPGA and silicon),
`docs/ROADMAP_128GB_VRAM.md` (memory work + every finding below).

---

## 4. ALU/ISA reconciliation — DONE

`titan_x5_alu.v` used to implement a private opcode map while the decoder
handed it ISA opcodes (opcode 8 = SHL executed as a compare; 3, 9, 10, 11 wrong;
4, 12-15, 18-20 unimplemented and silently returning 0). It now matches the ISA,
with the missing opcodes implemented: MULHI, signed DIV with both defined
special cases, SHL/SHR/SRA, SLT/SLTU, MIN/MAX, integer FMA, FMIN/FMAX, CVT.

Guards added so it cannot regress:
- `tb/uvm/test_alu_isa.py` (suite `alu_isa`) — every integer opcode against a
  reference model transcribed from `driver/titan_x6_gpu_model.c`.
- `compiler/test_compiler_isa.py` now parses the ALU's opcode localparams and
  asserts they match the header, and that every ISA opcode <= 21 is implemented.

**Known, documented exception:** opcode 21 is SETP in the ISA but still drives
the verified FP fused multiply-add unit, because the ISA has *no FP FMA
opcode* (15 is integer FMA) and slots 0-31 are all assigned. SETP is inert
anyway — predicate registers do not exist in the pipeline. Assigning FP FMA a
real opcode is an ISA decision that needs a human call.

Measured cost: ALU grew 24,226 -> 31,650 cells (+30.6%, `ENABLE_TENSOR=0`).

## 4b. THE PLAN: v2.0 release work (do these in order)

Target: a release whose claim is **"runs real compiled kernels with real
control flow, verified against a reference model."** Three steps, ordered so
each unblocks the next.

### CONSTRAINT: no large downloads

Do **not** install OpenLane, Docker images, or any PDK (sky130 etc.). Those are
multi-GB and are out of scope for this work. The entire plan below runs on:

```bash
apt-get install -y -qq iverilog verilator yosys   # tens of MB
pip install cocotb==2.0.1 pytest                  # small
```

Yosys is used only for `stat` cell counts, never for a full physical flow.
If a step seems to need a PDK, it is the wrong step — skip it and say so.

### Step 1 — per-warp register file *(smallest, unblocks the rest)*

`rtl/core/titan_x5_register_file.v` has **no warp dimension**: 64 registers
shared by all `NUM_WARPS` warps. Warps cannot hold independent state, so
`LAUNCH_WARP_MASK` in `titan_x5_gpu_top.v` is pinned to `8'h01` (one warp).
Eight warps running `ADD r6, r6, r3` accumulate 8x.

- Give the register file a warp index (64 regs x NUM_WARPS x 32 lanes).
- Thread the warp id from the pipeline stages into the read and write ports
  (ID reads with `id_warp_raw`, WB writes with `wb_warp_reg`).
- Restore `LAUNCH_WARP_MASK` to `8'hFF`.
- The testbench backdoor deposits in `tb/tb_titan_x5_gpu_top.v` write
  `bank_gen[b].bank_mem[e]` and will need the warp index too.

**Gate:** the full-chip render test passes with all 8 warps launched, still
181 pixels / 0 out of bounds / per-lane gradient intact. Add a cocotb test
proving two warps can hold different values in the same register number.

### Step 2 — SETP + predicate registers -> conditional branches

Today every branch is unconditional, so a loop cannot have an exit condition.
`titan_x5_decoder.v` already exposes `is_predicated` and `pred_reg`; nothing
consumes them.

- Add per-warp predicate registers (P0 hardwired true, P1-P3 writable).
- Implement `SETP` (opcode 21) per the ISA: the `rd` field carries
  `{cond[2:0], pdst[1:0]}`, comparison per `TX6_CMP_*`. Semantics are in
  `driver/titan_x6_gpu_model.c`.
- Gate instruction execution on the predicate in the pipeline.
- Make `BRANCH` honour its predicate, so it becomes conditional.
- **The opcode-21 question, RESOLVED.** SETP needs 21, which the FP fused
  multiply-add unit was squatting on because the ISA had no FP-FMA opcode at
  all (opcode 15 is documented and modelled as INTEGER fma) and slots 0-31
  were all assigned. The encoding is exactly full -- `[31:27]` opcode,
  `[26:21]` rd, `[20:15]` rs1, `[14:9]` rs2, `[8:3]` rs3, `[2:1]` pred,
  `[0]` use_imm -- so widening the opcode field would cost register-index
  bits.

  **Decision (the user's, asked explicitly): move FP FMA to slot 29,
  displacing RSQRT.** RSQRT was assigned in the header and implemented in the
  C functional model but *never built in hardware* -- `titan_x5_alu.v` has no
  SFU. So this trades a transcendental that never existed for a datapath that
  does (`rtl/fpu/titan_x5_fp32_fma.v`, IEEE-754 verified), and leaves SETP at
  its documented number so the header, compiler and model do not move.

  Updated together: `driver/titan_x6_isa.h` (`TX6_OP_FFMA = 29`),
  `driver/titan_x6_gpu_model.c` (RSQRT case removed, `fmaf()` added --
  single rounding, not `a*b+c`), `compiler/titan_compiler.py`,
  `rtl/core/titan_x5_decoder.v` (`is_alu` is now `<= 20 || == 29`) and
  `rtl/core/titan_x5_alu.v`. Adding RSQRT back needs a new ISA decision.

**Gate:** a kernel with a real counted loop (`SETP` + conditional `BRANCH`)
runs to completion with the right trip count, checked against the functional
model. **MET** — `test_counted_loop_trip_count` at trips 0, 1, 2, 17 and 64,
each checked against `titan_compiler.simulate()`.

**How it was built (worth knowing before changing it):**

- **SETP is resolved in the ID stage, not EX.** Two reasons: the ALU has no
  `rd` port, so the condition code in `rd[4:2]` could not reach it; and its
  `rd` field is `{cond, pdst}` rather than a register index, so letting it
  reach writeback would scribble on GPR #{cond,pdst}. It is now its own
  decoder class (`is_setp`) alongside BRANCH and BARRIER, and `is_alu` no
  longer covers 21. Resolving in ID also means the predicate is written the
  same cycle SETP commits, so the very next instruction sees it — there is no
  SETP -> BRANCH hazard, which matters because that back-to-back pair is
  exactly what the compiler emits for a loop exit.
- **Predicates are 32-bit per-lane masks**, per warp, `P1..P3` (`P0` reads as
  all-ones). Storing one bit per warp would throw away 31 lanes' answers.
- **Divergent predication is NOT implemented.** An instruction executes only
  when every lane of its predicate agrees; a mixed mask is skipped and the
  sticky `dbg_pred_divergent` flag is raised (plumbed out through
  `titan_x5_sm` to `titan_x5_gpu_top.any_pred_divergent`). Handling divergence
  properly needs a reconvergence stack. Every compute test asserts the flag
  never fires, so if a future kernel diverges it will be noticed.

### Step 3 — matmul end to end, bit-exact

`compiler/kernels/matmul.py` compiles to Titan ISA today but has never been
executed by the RTL.

- Compile it, load the resulting program into the full-chip testbench,
  run it, and compare the output matrix against a NumPy reference.

**Gate:** compiler -> ISA -> RTL produces a bit-exact matmul result. This is
the headline claim for v2.0. **MET** — 2x2x2 (11,436 cycles) and 4x4x4
(65,311 cycles), every word matching NumPy including signed negatives.
Test: `tb/test_compute_kernels.py::test_matmul_bit_exact_vs_numpy`.

The harness built for this is `tb/tb_compute_top.v` + `tb/compute_runner.py`:
it boots the same `titan_x5_gpu_top`, loads a compiled program, an input
image and a kernel parameter block into VRAM, lets the SMs launch out of
reset, waits for every warp to retire, and reads the result back. Notes:

- **Threads are redundant, not partitioned.** Every launched warp on every SM
  runs the same program with the same register state, so kernels must be
  idempotent. The compiler's scalar kernels are (each thread computes and
  stores the same value). `LAUNCH_WARP_MASK` therefore defaults to one warp
  here — more warps only add duplicate work and coherence traffic.
- **Results are read out of the cache hierarchy, not VRAM.** There is no cache
  flush anywhere in the design (see section 5), so a kernel's stores sit in a
  Modified L1 line and never reach memory.
- **Simulation speed is the binding constraint**, measured at ~92 clock cycles
  per wall second, so 4x4x4 matmul takes ~15 minutes. Two things bought a 3x
  speedup and are worth keeping: `ENABLE_TENSOR(0)` (a 4x4 tensor array is
  instantiated inside *every* ALU — 128 of them — and a scalar integer kernel
  never touches one) and a small `FB_STRIDE` (the display engine free-runs
  scanning video and contends for the same crossbar). Going much beyond
  4x4x4 needs Verilator, not more patience.

### Working rules that keep producing good results

- **No invented numbers.** Every figure must come from a command actually run.
  Say "unknown and unmeasured" rather than estimating.
- **Mutation-test every new test.** Inject a defect, confirm the test fails,
  restore, confirm it passes.

  This is not a formality — in the v2.0 work it killed three defects
  (BRANCH ignoring its predicate, predication not gating EX, SETP comparing
  unsigned) **and exposed a verification gap that would otherwise have been
  reported as a passing test.** See the next item.

- **Known verification gap: nothing proves the predicate registers are
  per-warp.** `test_predicates_are_per_warp` does not, despite the name, and
  its docstring says so. With `pred_mask` reindexed so all warps share warp
  0's slots, 8 warps still produced exactly the right per-warp results. Giving
  each warp a different trip count did not help.

  Measured reason: **warps barely overlap.** The 8-warp loop takes 24,069
  cycles where 1 warp takes 3,257 — 7.4x for 8x the work. Two causes: one
  outstanding fetch per SM, and `titan_x5_warp_scheduler.v:88`, where the
  hazard check tests the *current ID instruction's* source registers against
  *every* warp's scoreboard, so warps running the same program stall on each
  other's register numbers. A warp's SETP and its BRANCH end up adjacent, and
  a shared predicate is never read stale.

  The per-warp indexing is implemented because the ISA requires per-thread
  predicate state, not because a test caught it missing. **The defect is
  latent, not benign** — widening fetch (Phase 2) or fixing that hazard check
  will expose it. Anyone doing either should re-run this mutation first.

  Generalise the lesson: **if every warp (or lane, or bank) in a test does the
  same thing — or the machine never lets them overlap — that test cannot see a
  cross-warp bug.** The scheduler's coarse hazard check is itself worth fixing
  on its own merits: it is conservative, so never unsafe, but it destroys
  multi-warp concurrency, which is the entire point of having warps.
- **Control-experiment every fix.** Revert the fix with the new test in place
  and show the failure, so the bug is demonstrated rather than asserted.

### After the three steps

Merge to `master`, tag **`v2.0`**, write release notes. Do **not** create a new
repository -- the commit history documenting bugs found and fixed is the
project's credibility, and a fresh repo throws it away. A rename plus a tagged
release gives the same "new version" identity with none of the loss.

Keep the honest-scope discipline in `README.md`. Do not drop caveats at release
time; real verified results next to honest limitations read far better than a
version number with the limitations quietly removed.

---

## 5. Other known-open items (do not lose these)

- ~~**Register file has no warp dimension.**~~ **DONE** (step 1). The file is
  now 64 regs x NUM_WARPS x 32 lanes, warp-major
  (`bank_mem[warp*REGS_PER_BANK + entry]`), with the ID-stage warp driving the
  three read ports and the WB-stage warp driving the write port.
  `LAUNCH_WARP_MASK` is back to `8'hFF` and the render test passes with all 8
  warps at 181 pixels / 0 out of bounds. Suite: `regfile`.
- **No instruction cache; one outstanding fetch per SM.** Roadmap Phase 2.
  Now measurably the dominant cost: 8 warps sharing the single outstanding
  fetch pushed the render from 8,009 to 10,009 cycles, and delayed the
  shader's first export past the start of rasterization (see the ROP note
  below).
  Note: the wrong-path epoch in `titan_x5_pipeline.v` is 1 bit and is only
  sound because a single fetch is outstanding — widening fetch requires
  widening the epoch.
- ~~**Branches are unconditional only.**~~ **DONE** (step 2). Per-warp predicate
  registers (P0 hardwired true, P1-P3 writable, each a 32-bit per-lane mask)
  live in `titan_x5_pipeline.v`; SETP is resolved in ID and BRANCH honours its
  predicate. **Divergent predication is still not implemented**: an instruction
  executes only when every lane of its predicate agrees, and a mixed mask is
  skipped with the sticky `dbg_pred_divergent` flag raised so it is observable
  rather than silent. That needs a reconvergence stack.
- **Warps barely run concurrently.** Measured: the same counted loop takes
  24,069 cycles with 8 warps and 3,257 with 1 — 7.4x for 8x the work.
  `titan_x5_warp_scheduler.v:88` compares the *current ID instruction's*
  source registers against *every* warp's scoreboard, so warps executing the
  same program stall on each other's register numbers even with no real
  dependency. Conservative, so never unsafe, but it removes the concurrency
  warps exist to provide — and it is what hides the shared-predicate defect
  described in the working rules above.
- ~~**No cache flush path.**~~ **DONE.** `CMD_FENCE` now runs a device-level
  flush: all 8 L1s, then a wait for the coherent crossbar to drain, then L2.
  The drain matters — an L1's `flush_done` means the crossbar *accepted* its
  last writeback, not that it reached L2. `rtl/control/titan_x5_flush_ctrl.v`;
  suites `l2flush`, `flushctl`, and
  `test_compute_kernels.py::test_host_reads_kernel_results_from_memory`.
  Measured: **3,411 cycles per fence**. `tb/tb_compute_top.v` now reads
  results out of the AXI memory model, not the hierarchy; the old
  `read_arch_word` survives only as a diagnostic that distinguishes "the flush
  lost it" from "the kernel computed it wrong".
  **Two traps worth knowing about**, both found by mutation testing:
  a held `flush_req` used to restart the walk (fixed with a `flush_seen`
  one-shot latch in each cache — one assertion, one walk), and
  `compute_runner.build()` reused its elaborated `.vvp` whenever the file
  merely existed, so the compute suite silently tested a two-day-old binary.
  It now rebuilds when any source is newer. **If a compute result ever looks
  impossible, check that first.**
  Still open: the fence flushes everything rather than a range, and there is
  no acquire-side invalidate ordering beyond it.
- **Threads cannot address above 4 GiB** — registers are 32-bit. Needs an
  aperture base register or 64-bit addressing.
- **`SYNCASYNCNET`**: `rst_n` is flopped both synchronously and asynchronously
  (`titan_x5_crossbar.v:70` vs `titan_x5_gddr7_pam3_phy.v:67`). CI declares this
  lint fatal but pins Verilator 4, which does not flag it. Real reset-domain
  hazard for FPGA bring-up.
- **18 `GENUNNAMED`** unlabelled generate blocks — cosmetic, Verilator 5 only.
- **`titan_x6_gpu_top` is a scaffold, not a working design** — its GPCs are not
  connected to its L2 (`assign l2_req_addr = 0;` with the comment "Tie off L1
  interface for this structural top-level"). The working GPU is
  `titan_x5_gpu_top`. Do not benchmark or harden the x6 top believing it runs.
- **`titan_x5_hbm3_controller.v` is not instantiated anywhere.**
- **The ROP has no per-fragment shader dispatch.** `titan_x5_rop` latches the
  shader's last R63 export into `latched_shader_color` and paints whatever the
  rasterizer hands it; the two engines are otherwise independent. Fragments are
  no longer painted with a colour that does not exist yet (the ROP now holds
  `i_ready` low until the first export — found when 8 warps delayed that export
  past the start of rasterization and 64 of 181 pixels came out black), but the
  colour a given fragment receives is still "the most recent export", not "the
  shader result for that fragment". A real fragment pipeline would dispatch per
  quad and carry the result back with the fragment.
