# Taking Titan to 2 nm — what I actually did, and what it cost

This is a working log, not a spec sheet. Every number in it came out of a
command that ran on this machine. Where something failed, it says so, because
the failures turned out to be the most useful part.

---

## The short version

I got a real 2 nm process, synthesized the GPU's hot blocks onto it, found
they were roughly half as fast as their own headers claimed, fixed that, and
then failed three times to make them faster still. The die budget for 20,000
lanes came out at 93 mm². The frequency target of 3 GHz did not happen.

| block | before | after | at 2 nm |
|:--|--:|--:|--:|
| FP32 FMA | 658.71 ps | **401.81 ps** | 2.49 GHz, 476.85 µm² |
| Tensor PE | 1239.29 ps | **433.06 ps** | 2.31 GHz, 283.29 µm² |

All four headline blocks re-measured immediately before writing this:

```
titan_x7_fp32_fma_pipe   area=  476.85 um2   delay= 401.81 ps   2.49 GHz
titan_x7_tensor_pe       area=  283.29 um2   delay= 433.06 ps   2.31 GHz
titan_apex_mult_seg      area=  105.16 um2   delay= 586.47 ps   1.71 GHz
titan_apex_fma_lane      area=  488.37 um2   delay= 415.10 ps   2.41 GHz
```

---

## Getting a 2 nm process at all

The starting assumption was that no open PDK exists below 7 nm. That is out of
date. **GT2N** is an open-source 2 nm nanosheet GAAFET PDK with backside power
delivery, BSD-3 licensed, and it is a supported OpenROAD platform. I cloned it
(252 MB on disk) and installed oss-cad-suite for Yosys.

What GT2N actually contains, because this shapes everything downstream:

- **69 logic cells** plus 3 physical (filler, two taps). That is a small
  library. No full adder. No half adder. No carry cell.
- **3 sequential cells**, all `dffasync` — async reset only. No scan flop, so
  DFT cannot be inserted. No integrated clock gate, so clock-tree gating is
  not available.
- **No SRAM and no memory compiler.** This one costs more than all the others
  combined; see the register file section.
- **One corner**: `tt`, 0.7 V, 25 °C. No slow corner, so no signoff margin.
- DRC/LVS decks target Synopsys IC Validator, a commercial tool.

And the caveat that has to travel with every number here: **GT2N is
predictive, not fabbable.** No foundry will take it. Everything below is
synthesis only — no floorplan, no placement, no routing, no extraction. ABC
reports `WireLoad = "none"`, so these delays contain **zero wire delay**.
Place-and-route can only make them worse. Treat every figure as an optimistic
lower bound.

---

## The blocks were about half as fast as advertised

The FMA header claimed a 333 ps/stage target. First measurement: **658.71 ps**,
a 1.98× miss. Rather than guess, I asked ABC for the critical path and read
the gate types:

```
Path  1..14 : or3 / nor3 / nand3 alternating      <- carry propagate chain
Path 15..29+: oai21 / aoi21 alternating           <- second carry chain
```

Ripple carry. GT2N has no adder cells, so a bare `+` on a 106-bit vector left
the synthesizer nothing to build from. Two fixes:

**A Kogge-Stone prefix adder** replacing `+`/`-` on E5's three 106-bit
operations and E4's 48-bit CPA. Carry depth O(W) → O(log W).

**Deleting a comparator.** `p_ge_c = (mag_p >= mag_c)` was a *fourth* 106-bit
carry chain. Both operands are 105 bits zero-extended to 106, so the subtract
already answers it: `~sub_pc[105]`.

That got to 572 ps. Then the next bottleneck appeared, and it was a better
find than the first: E6 is described in the module header as a "106-bit CLZ
tree". It was not a tree.

```verilog
for (m = 0; m <= 105; m = m + 1)
    if (e5_sum[m]) msb_idx_c = m[6:0];
```

A 106-deep linear priority scan — ~106 chained muxes — with the exponent add
serialized behind it. Invisible until the adders got fixed. Replaced with a
real log-depth reduction tree, plus the same pattern three more times in E1.

**Result: 401.81 ps.** But part of that was me driving ABC harder, which is a
tool setting and not an achievement of the design, so I ran the control:

| RTL | synthesis | delay |
|:--|:--|--:|
| original | default | 658.71 ps |
| original | aggressive | 561.15 ps |
| prefix + LZC | default | 572.18 ps |
| **prefix + LZC** | **aggressive** | **401.81 ps** |

At matched effort the RTL change is worth **28.4%**. Tool settings alone were
worth 14.8%. Neither reaches 401 ps alone — they compose.

---

## The tensor PE had the same disease, worse

1239.29 ps, the slowest block in the design, and the one that does matmul. Same
treatment — prefix adders and LZC trees in six places — plus one that was
specific to it and was the actual critical path:

```verilog
st_d = |(mag_ext & (({...,1'b1} << down) - 1));
```

A 137-bit variable shift, then a **137-bit ripple decrement**, then a 137-bit
OR reduction, in series. The gate histogram gave it away: 41 of 47 levels were
or3/nand3/nor3, an OR/borrow chain rather than a carry chain, which pointed
away from the adders. A mask of `down` ones needs no arithmetic at all:
`(1 << down) - 1 == ~(~0 << down)`.

**1239.29 → 433.06 ps.** At matched effort, −53.0%, a 2.13× speedup, for +2.7%
area.

---

## Three things I tried that made it worse

This is the part I'd want to read if someone else had written it.

**1. Adding a pipeline stage to the tensor PE.** D2 chained two log-depth
trees, and the drain runs once per tile rather than once per MAC, so the extra
latency costs no throughput at all — II stays 1. It looked free.

| | delay | area |
|:--|--:|--:|
| with the D2 split | 434.52 ps | 305.42 µm² |
| without it | **433.06 ps** | **283.29 µm²** |

Same timing, +7.8% area. Reverted.

**2. Applying the winning sticky-mask fix to the FMA.** E4 has a textually
similar sticky loop. Same rewrite: **401.81 → 460.39 ps**, worse. The fix is
width-dependent — at 137 bits it removes a ripple decrement that dominates; at
24 bits there is no decrement worth removing, the per-bit comparisons
synthesize in parallel into a balanced OR, and the mask form inserts a barrel
shift in series ahead of it. Same transformation, opposite sign. There is now a
comment in the RTL so nobody "fixes" it again.

**3. Splitting the FMA into 9 stages.** Registered the 106-bit normalization
shift ahead of the 81-bit sticky OR. **401.81 → 476.91 ps**, and +7.8% area.

Three attempts, three regressions. The pattern is consistent and it is the
real conclusion of this work: **these blocks are load- and fanout-limited, not
depth-limited.** Adding registers adds load without shortening a path that was
never too deep. The critical path is now 40 gate levels with 6 buffers on it
and no single dominant structure.

There is a fourth data point that seals it. I tried to localize the critical
stage by stubbing logic out — replacing two barrel shifters with constants.
Both got **slower** (453.50 and 427.49 ps). Removing a barrel shifter cannot
lengthen a critical path. It does here because ABC's structural mapping is
sensitive enough to the surrounding cone that unrelated edits swing the result
10–15%. So stub-based localization does not work on this flow, and the tensor
PE's sticky only showed through because it was a 2× effect, big enough to beat
the noise.

**3 GHz is not reached.** 401.81 ps is a robust floor. Tightening ABC's target
from 200 → 150 → 120 ps changes nothing but area. What would plausibly get
there, none of it attempted: real place-and-route where a physical tool buffers
against actual wire loads instead of `WireLoad="none"`; a richer cell library
(GT2N tops out at x4 drive); or a different FMA microarchitecture rather than
a re-partition of this one.

---

## The register file was 86% of the die

With 20,000 lanes the budget came out:

| block | mm² | share |
|:--|--:|--:|
| FP32 FMA lanes | 9.54 | 8.8% |
| tensor PEs | 5.67 | 5.2% |
| **register files** | **93.50** | **86.0%** |
| die at 70% utilization | **155.29** | |

Fitting was never the problem — that is 25% of a 4090 die. The register file
being nearly all of it was. 39.1 MiB held in flip-flops, because GT2N has no
SRAM.

Then a measurement pointed at the fix:

| regs | warps | bits | area |
|--:|--:|--:|--:|
| 64 | 8 | 131,072 | 37,398.80 µm² |
| 64 | 4 | 65,536 | 20,079.08 µm² |
| **32** | **8** | 65,536 | **20,079.08 µm²** |
| 32 | 4 | 32,768 | 11,532.96 µm² |

64×4 and 32×8 cost *exactly* the same. Area tracks total capacity, not how it
is split between warps and registers. The silicon does not care about the
split — so the split does not have to be fixed at build time.

The register file was 8 fixed windows addressed by a hardwired `{warp, reg}`
concatenation. It is now a **pool**: the scheduler hands each warp a base row
and the address is `base[warp] + reg_row`. Real GPUs have worked this way for
years — a kernel declares its register need and occupancy scales inversely.

**155.29 → 93.43 mm²**, a 40% smaller die, for a kernel declaring 32 registers
per thread instead of 64. Which is most of them.

Driving `warp_base[w] = w * (NUM_REGS/NUM_BANKS)` reproduces the old layout bit
for bit, so all six original tests still pass unchanged.

---

## The memory bus could not be built at its own best width

Widening the bus was the ask. Measuring it found the adapter could not
elaborate at the width that matters. The line is 128 bytes = 1024 bits, so
`DATA_WIDTH = 1024` is one beat per line — the fastest it can run. At that
width `WORDS = 1`, `$clog2(1) = 0`, and a zero-width counter is an elaboration
*error*:

```
titan_x5_l2_mem_adapter.v:83: error: Concatenation repeat may not be zero
```

The module was documented and tested as "genuinely width-generic" while its
best configuration would not build. Both existing suites had WORDS ≥ 2, which
is why nothing caught it.

| bus width | line | beats |
|:--|:--|--:|
| 32-bit | 128 B | 32 |
| 512-bit | 128 B | 2 |
| **1024-bit** | 128 B | **1** |
| **2048-bit** | 256 B | **1** |

A note on 1182 bits, which was requested: that is 147.75 bytes, not a whole
number, so no memory interface can be that wide. In this adapter it would have
failed *silently* — `WORDS` truncates to 0 and the terminal test compares
against an underflowed all-ones value that never arrives, so the transfer hangs
forever. It now refuses to build instead.

---

## Verification: two suites were partly proving nothing

The X7 blocks arrived with one test each. Mutation-testing them — inject a
defect, confirm the test fails — found two that did not fail.

**The X7 register file could be made completely warp-shared** — all 8 warps
sharing one set of 64 registers, 10 sites changed — and `sm7` passed with a
byte-identical IPC of 1.72. Closed with `sm7warp`, which gives each warp its
own program at its own PC. Re-injecting now fails with diagnostic values, not
a bare mismatch: warp 0's `r1` reads `0x107`, which is *warp 7's* value, and
the loop accumulator reads `0x18` = 3 × 8.

**The FMA differential had ~zero coverage of round-to-nearest-even.** Deleting
the tie-to-even term left all 4,000 vectors passing. An exact tie needs every
bit below the round bit to be zero, which random operands essentially never
produce, and every value in SPECIALS is exactly representable so none of them
round at all. Closed with 2,880 constructed half-ULP ties; the test asserts at
least one odd-mantissa tie actually rounds up (384 do), so it fails loudly if
the stimulus ever stops reaching the tie-break.

Both are the same shape of hole the project's own handoff document warned
about for the x5 predicates. That warning was correct and still live.

---

## The flush that only went halfway, and a suite that tested nothing

The L1 flush was already built and verified when this started. It was not
enough for the thing it existed for, and finding out why took reading the code
rather than the description of it.

**L1 flushes to the coherent bus, and the coherent bus terminates at L2** —
which is also write-back. `titan_x5_l2_cache` had a `dirty_array`, set it on
every write hit, and wrote back only when capacity eviction happened to pick
that way. There was no flush port at all. So flushing L1 moved a kernel's
result from a Modified L1 line into a dirty L2 line and stopped there. VRAM
still read stale, and `tb_compute_top.v` still read results out of the cache
hierarchy.

So the work was three pieces, not one: an L2 writeback-all, a sequencer to
order the two levels, and the wiring to `CMD_FENCE`.

**The ordering is load-bearing in two places.** An L1's `flush_done` means the
crossbar *accepted* its last writeback, not that it reached L2 — the crossbar
is split-transaction, with a 4-deep queue behind a one-cycle grant. Flushing
L2 first lets those writebacks land in sets the walk has already passed, where
nothing will ever write them back. And `l1_flush_req` has to stay asserted
across the *whole* sequence, because that is what holds every L1's
`core_req_ready` low: release it after the L1 phase and an SM can store into a
freshly flushed L1 while L2 is still walking.

I got that second one wrong first, and had to revert my own change. I had
relaxed `core_req_ready` so each cache resumed service after its own walk,
worrying about a lockup. That reintroduced exactly the hole above.

### Two bugs mutation testing found, both in code written that day

**Both caches restarted their flush walk.** `flush_req` is a level, and the
requester cannot drop it until it has seen `flush_done` — by which point the
FSM is back in IDLE with the level still high, so it walks again. The extra
walk is *idempotent*, which is precisely why no existing test could see it. It
was not harmless: it cost a full sweep per fence, and it ran concurrently with
whatever the requester did next. It was actively corrupting my own residency
check — a 128-entry probe loop was reading state that a second, unrequested
walk was clearing underneath it. That is how it was caught. Fixed with a
`flush_seen` one-shot latch in each cache: one assertion, one walk.

**The sequencer restarted itself** when the requester's `flush_start` glitched
low mid-flush, because the one-shot latch was rearmed on the level being low
rather than only while idle.

Nine mutations, all caught. Two initially **survived** and changed the tests
rather than the RTL:

| mutation | why it survived |
|:--|:--|
| write back but don't invalidate | the behavioural check ("read it back, require a miss") cannot see residency — replaced with a direct entry probe |
| rearm mid-sequence | the test withdrew the request but never re-raised it, so the restart could not fire |

### The compute suite had been testing a two-day-old binary

The control experiment is what caught this. With the flush deliberately
disabled, `test_host_reads_kernel_results_from_memory` still **passed**.

`compute_runner.build()` reused its elaborated `.vvp` whenever the file merely
*existed*. The image on disk was from two days earlier. Every compute run that
session — including the ones reported as a clean baseline — had executed RTL
that predated all of this work, and would have kept doing so indefinitely.

`build()` now reuses the image only while it is newer than every source that
went into it. Elaboration is ~30 s against a suite that runs for minutes.

With a build that actually reflected the RTL, the control did what it should:

```
[20765000] STALE @00400000: VRAM has 00000000, the hierarchy still holds deadbeef
[20765000] STALE @00400080: VRAM has 00000000, the hierarchy still holds ffffffff
[20765000] STALE @00400084: VRAM has 00000000, the hierarchy still holds 5a5a5a5a
```

and with the flush restored:

```
[11515000] Kernel complete after 1152 cycles.
[51635000] Fence complete in 3411 cycles: caches flushed, VRAM holds the architectural state.
```

**Measured: 3,411 cycles per fence.** The full-chip render test is unchanged at
181 pixels, 0 out of bounds, 0 poison pixels, 10,009 cycles.

One honest note on scope: eight L1s are flushed, but the four TMU texture
caches are hardwired read-only (`core_req_write` is tied to `1'b0`), so they
contribute **invalidation only, never a writeback**. They are still worth
sequencing — they are not on the snoop bus, so nothing else ever invalidates
them — but they are not eight equal contributors.

---

## Where formal beat simulation

Simulation got slow — the Kogge-Stone and reduction trees are hundreds of
explicit gates each, and `tensor7` went from seconds to **12,805 s (3.56
hours)**. So the equivalence work moved to Yosys' SAT engine, which is both
faster and stronger:

| property | result |
|:--|:--|
| `prefix_add == a+b+cin`, W=106 | proven |
| `lzc ==` the 106-deep linear scan | proven |
| `~sub_pc[105] == (mag_p >= mag_c)` | proven |
| `(1<<d)-1 == ~(~0<<d)`, W=137 | proven |
| optimized FMA == original, **sequential** | 2172 cells proven, 0 unproven |
| optimized tensor PE == original, **sequential** | 1250 cells proven, 0 unproven |

The sequential proofs need `async2sync` first or `equiv_simple` aborts on the
async-reset flops. These cover all inputs rather than 6,880 vectors.

Formal is not universal, though: a SAT miter on the 24×24 segmented multiplier
did **not** finish in 10 minutes. Multiplier equivalence is a known hard case,
so that block is verified by simulation — exhaustively on all 4,096 tile pairs,
plus 1,369 directed corners and 3,000 random.

---

## Chasing the 5090

Checking the target before building turned out to matter. Real numbers: 21,760
CUDA cores at 2.41 GHz, 104.8 TFLOPS FP32, 750 mm² on N4P, 575 W. Tensor,
dense (NVIDIA quotes 2:4 sparse, dense is half): 838 TFLOPS FP8, 1,676 TOPS
FP4.

FP32 is straightforward — 40,000 lanes at the measured 2.49 GHz gives **199.2
TFLOPS, 1.90×**, in 187 mm² of cell area against their 750 mm² die.

Inference is where it nearly went wrong. I was about to upgrade the existing
tensor PE, which is FP16-in with an 11×11 multiply:

| | 5090 dense | on the FP16 PE (1/2/4×) | on an FP32 MAC (4/8/16×) |
|:--|--:|--:|--:|
| FP8 | 838 TFLOPS | 398 TOPS — **0.48×** | 1,594 TOPS — **1.90×** |
| FP4 | 1,676 TOPS | 797 TOPS — **0.48×** | 3,187 TOPS — **1.90×** |

Segmenting the FP16 PE would have **lost by 2×**. The FP32-width datapath is
mandatory, and the ratios are physical: 24×24 = 576 bit-products, and 4× FP16
needs 484, 8× FP8 needs 128, 16× FP4 needs 64. All fit, so segmentation costs
summation logic rather than a second multiplier.

`titan_apex_mult_seg` is the core of that — a 4×4 grid of 6×6 tiles where only
the summation network switches by mode, so the multiplier array is identical in
every mode. 105.16 µm², 586.47 ps combinational, which is **over the 433 ps
budget** until the enclosing PE pipelines it.

---

## Landing the X7 SM in the chip, and finding out the render test cannot score it

The handoff's priority 1 was "swap `titan_x5_sm` for `titan_x7_sm_shim` in
`titan_x5_gpu_top` and report the render test's cycle count before and
after". Both halves of that turned out to be more interesting than expected:
the swap failed on its first run, and the metric it was supposed to be judged
by cannot resolve the difference.

### The swap itself

The shim is a genuine drop-in — 39 ports, identical names, order and
directions to `titan_x5_sm`, checked programmatically rather than by eye.
Selection is an `` `ifdef TITAN_USE_X7_SM ``, not a parameter, because a
parameter needs a generate-`if` whose block label lands in the hierarchical
path (`sm_gen[0].g_x7.u_sm`), and both testbenches reach into that instance
by name for the register backdoor and the L1 residency probe.

Three things broke that were not visible in the port list:

- **The register backdoor.** x5 stores registers in 4 banks as
  `bank_gen[r%4].bank_mem[w*16 + r/4]`; X7 uses one flat warp-major array,
  `rf[{warp, reg}]`. Both testbenches deposit R2/R3/R4/R62 that way, so
  without an X7 branch the kernel reads zeroes and computes address 0.
- **`TITAN_FAST_SIM` was missing from `compute_runner.py`.** Harmless while
  the chip was x5 — it instantiates neither `titan_x7_prefix_add` nor
  `titan_x7_lzc` — but X7 instantiates `titan_x7_fp32_fma_pipe` **per lane**,
  32 per SM and 128 across the chip. Without the define those elaborate
  structurally, at ~250x simulation cost (section 7.4 of the synthesis doc),
  which a 45-minute suite cannot absorb.
- **The compute image cache key.** `_sim_path` keyed only on the warp mask,
  so flipping the SM changed no source file and the mtime-reuse check would
  have handed back an image built for the *other* core. That is the same
  stale-image failure recorded above, and it would have produced a clean
  before/after comparison of one design against itself. The flavour is now
  part of the filename.

### It failed on the first run, and that was the point

The full-chip render test came back **117 of 181 pixels wrong-path**. The
kernel's `BRANCH #7` exists to skip a poison instruction that writes
`0x0000FF00` to R63; X7 fell through it and executed the poison.

Cause: `titan_x7_sm` computed `mp_tk = (xi_a[31:0] != 32'd0)` — "branch if
rs1 != 0". **There is no register-conditional branch in this ISA.** BRANCH is
unconditional, gated only by its predicate, and since its rs1 field is unused
a compiled `BRANCH #target` encodes rs1 = R0 — so X7 fell through *every*
unconditional branch it was ever given. A second divergence turned up in the
same area: SETP ignored the condition field in `rd[4:2]` and always did
signed less-than, so five of the ISA's six comparisons silently executed as
LT. Full detail, including why `sm7`/`sm7warp` passed throughout, is in
[X7_ISA_CONFORMANCE.md](X7_ISA_CONFORMANCE.md).

Both are fixed and both mutations are caught. With them fixed the render test
passes on X7: 181 pixels, 0 out of bounds, 0 poison, all warps retired.

### The negative result: "Total Clock Cycles" is not a speed

Before and after, the render test reported **exactly 10,009 cycles**. That
identity is not a coincidence and it is not a measurement.

The test waits for the render to quiesce by polling in `#10000` windows —
1,000 cycles each — and stopping after 3 consecutive windows with no new
committed write. So the reported figure is

```
cycle_count = waited_windows * 1000 + ~9
```

quantised to 1,000 cycles, and carrying 3,000 cycles of pure waiting after
the last write. Both builds ran 10 windows, so both printed 10,009.

The framebuffer write timestamps show what it hid:

| | x5 SM | X7 shim |
|:--|--:|--:|
| first framebuffer write | cycle 1,227 | cycle 3,051 |
| **last framebuffer write** | **cycle 6,987** | **cycle 6,843** |
| reported "Total Clock Cycles" | 10,009 | 10,009 |

A 144-cycle difference rounded to zero. X7 also starts writing **1,824
cycles later** — the ROP holds `i_ready` low until the shader's first R63
export, and the shim's fetch adapter is slower to deliver the first
instructions, which is consistent with it serialising X7's per-warp
outstanding fetch down to one pair at a time on the chip's 32-bit port.

The test now prints the first/last write cycles alongside the old number,
with the old number labelled. **The honest scoreboard for an SM comparison is
the compute harness**, which returns an exact per-kernel `cycles`.

The wider lesson matches this project's pattern: the render test is an
excellent *correctness* test — its poison trap has now caught a wrong-path
bug twice, once for x5 and once for X7 — and a poor *performance* test. It
was being asked to do the second job because it prints a number.

## What is not done

- **3 GHz.** Floor is 2.49 GHz and I could not move it.
- **`titan_apex_mult_seg` is over budget** at 586.47 ps and needs pipelining.
- **The banked register file is not wired into the SM.** It is verified
  standalone; the swap turns the operand read from combinational to
  variable-latency and is its own piece of work.
- **Pillars 2–4 of APEX-X** — the 4-chiplet coherent NoC, HBM4, and the 256 MB
  3D L2 — are untouched.
- **Verilator cannot run here.** It emits C++ that needs compiling, and this
  machine has no g++, gcc, clang, MSVC, or `make`. oss-cad-suite ships the
  Verilator binary but no toolchain, so it can lint but not simulate.
- **No place and route.** Everything is synthesis. The single most useful next
  measurement is an ORFS run, because it is the only way to find out how much
  of the 401.81 ps is wire.
- **An SRAM macro source** remains the highest-value unblock in the project:
  worth roughly 4.4× the whole die area, against the 39% of one block's delay
  that the entire FMA rework bought.

---

## Regression status at the time of writing

A full-tree run was started before writing this and is **still going** — I am
not going to claim a result I do not have. Where it had reached:

**18 suites complete, 0 failures:**

```
lsu  fpu  mesi  tmu  rt_isect  rt_box  rt_core  tensor  noc  vram
l2   alu_isa  pc_unit  regfile  l2adapt32  l2adapt512  l2adapt1024  l2adapt2048
```

Still to run when this was written: `fma8` (in progress), `tensor7`, `rfbank`,
`sm7`, `sm7warp`, `multseg`, `apexlane`, `compute`.

Every one of those has passed individually during this work — `rfbank` 7/7,
`multseg` 4/4, `apexlane` 3/3, `sm7warp` 2/2, `tensor7` in 12,805 s — but they
have not all passed *together on this exact tree* yet, and until they do I am
calling it in progress. The slow ones are slow for a real reason: `tensor7`
takes 3.56 hours because 16 PEs of explicit prefix-adder and reduction-tree
gates are expensive for an event-driven simulator.

---

## Reproducing

```bash
export GT2N_ROOT=/path/to/GT2N
export OSS_CAD=/path/to/oss-cad-suite
./syn/gt2n/run_gt2n.sh titan_x7_fp32_fma_pipe rtl/fpu/titan_x7_fp32_fma_pipe.v
python syn/gt2n/die_budget.py 20000 32 8
python tb/run_regression.py
```

Detail and full result tables: [GT2N_2NM_SYNTHESIS.md](GT2N_2NM_SYNTHESIS.md),
[TITAN_APEX_FEASIBILITY.md](TITAN_APEX_FEASIBILITY.md), and the logs under
`syn/gt2n/results/`.
