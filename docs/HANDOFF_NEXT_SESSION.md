# Handoff — next session

Read this first. It is the full context for continuing work on Titan X5.

**Repo:** `asfddb/Titan-X5B-GPU`
**Branch:** `claude/titan-x5-gpu-conversion-lf6udk` (all work goes here)

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
