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
# unit/transaction regression - 14 suites, must be 14/14 PASS, exit 0
python3 tb/run_regression.py
python3 tb/run_regression.py fpu lsu          # subset

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

## 3. Where the project is now

The full-chip render test passes and is genuinely self-checking:
**181 pixels, 0 out of bounds, 0 wrong-path pixels, per-lane gradient intact,
all warps retired, 8,009 cycles.**

Recently completed on this branch:

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

The testbench kernel at `tb/tb_titan_x5_gpu_top.v` is now a real program:

```
0: MUL     R6, R62, #4     R6 = tid*4
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

## 4. THE TASK: reconcile the ALU with the ISA

**`rtl/core/titan_x5_alu.v` implements a different opcode map than the rest of
the stack.** The ISA header (`driver/titan_x6_isa.h`), the decoder
(`rtl/core/titan_x5_decoder.v`), the compiler (`compiler/titan_compiler.py`)
and the functional model (`driver/titan_x6_gpu_model.c`) all agree with each
other. The ALU does not.

| Opcode | ISA / decoder / compiler / model | `titan_x5_alu.v` |
|--:|:--|:--|
| 0 | ADD | ADD ✅ |
| 1 | SUB | SUB ✅ |
| 2 | MUL | MUL ✅ |
| 3 | MULHI | **DIV** ❌ |
| 4 | DIV | *unimplemented* ❌ |
| 5 | AND | AND ✅ |
| 6 | OR | OR ✅ |
| 7 | XOR | XOR ✅ |
| 8 | **SHL** | **CMP** ❌ |
| 9 | SHR | **SLT** ❌ |
| 10 | SRA | **BRANCH** ❌ |
| 11 | SLT | **JUMP** ❌ |
| 12 | SLTU | *unimplemented* ❌ |
| 13 | MIN | *unimplemented* ❌ |
| 14 | MAX | *unimplemented* ❌ |
| 15 | FMA (integer) | *unimplemented* ❌ |
| 16 | FADD | FADD ✅ |
| 17 | FMUL | FMUL ✅ |
| 18 | FMIN | *unimplemented* ❌ |
| 19 | FMAX | *unimplemented* ❌ |
| 20 | CVT | *unimplemented* ❌ |
| 21 | SETP | **FMA** ❌ |
| 26 | WMMA | WMMA ✅ |

Only **0, 1, 2, 5, 6, 7, 16, 17, 26** agree.

**Why it survived:** `compiler/test_compiler_isa.py` checks that the compiler's
encoding matches the driver header and the **decoder**. It never checks the
**ALU**. So the decoder correctly identifies opcode 8 as SHL, hands it to the
ALU, and the ALU computes a comparison. It fails silently — a `SHL` returns 0
rather than erroring.

**Impact:** any compiled kernel using a shift, divide, min/max, comparison,
integer FMA, conversion or predicate computes wrong answers today. This blocks
running real kernels (including `compiler/kernels/matmul.py`) and blocks any
meaningful memory-bandwidth measurement.

### What to do

1. **Make the ALU match the ISA.** Renumber its opcodes to the ISA map and
   implement the missing ones: MULHI, DIV, SHL, SHR, SRA, SLT, SLTU, MIN, MAX,
   integer FMA, FMIN, FMAX, CVT, SETP. Keep the existing verified FP units
   (`rtl/fpu/`) wired where they already are — FADD/FMUL/FMA are correct and
   IEEE-754-verified, do not disturb them.
2. **Decide SETP properly.** Predicate registers do not exist in the pipeline
   yet (`titan_x5_decoder.v` exposes `is_predicated`/`pred_reg`; nothing
   consumes them). Either implement predicate registers, or implement SETP's
   datapath and document predication as still absent. Say which you did.
3. **Extend `compiler/test_compiler_isa.py` to cover the ALU**, not just the
   decoder. This is the part that prevents regression — without it the same
   class of bug returns.
4. **Add a cocotb ALU suite** in `tb/uvm/` checking every ISA opcode against a
   Python reference model, and register it in `tb/run_regression.py`. Model the
   integer semantics on `driver/titan_x6_gpu_model.c`, which is the
   authoritative reference (e.g. `MULHI` is signed high-word, `SRA` is
   arithmetic).
5. **Prove it end to end.** Once shifts work, switch the testbench kernel's
   instruction 0 back from `MUL R6, R62, #4` to `SHL R6, R62, #2`
   (`0x40DF0011`) and confirm the render test still passes. That is a direct
   demonstration the divergence is closed.

### Working rules that produced good results so far

- **No invented numbers.** Every figure must come from a command that was
  actually run. If something is unmeasured, say "unknown and unmeasured"
  rather than estimating. This has been an explicit instruction from the user.
- **Mutation-test new tests.** Inject a defect, confirm the test fails, restore,
  confirm it passes. A test that has not been shown to fail proves nothing.
  Every suite added on this branch was validated this way.
- **Control-experiment every fix.** Revert the fix with the new test in place
  and show the failure, so the bug is demonstrated rather than asserted.
- Keep the honest-scope discipline in `README.md` — extend the limitations
  section as capability grows; never quietly drop a caveat.
- Commit with detailed messages explaining the *why*, and end with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  ```
- Push with `git push -u origin claude/titan-x5-gpu-conversion-lf6udk`.
  Do not open a PR unless asked.

---

## 5. Other known-open items (do not lose these)

- **Register file has no warp dimension.** 64 registers shared by all 8 warps,
  not 64 per warp, so warps cannot hold independent state. `LAUNCH_WARP_MASK`
  in `titan_x5_gpu_top` defaults to `8'h01` (one warp) because of this. A
  per-warp register file is required before launching more.
- **No instruction cache; one outstanding fetch per SM.** Roadmap Phase 2.
  Note: the wrong-path epoch in `titan_x5_pipeline.v` is 1 bit and is only
  sound because a single fetch is outstanding — widening fetch requires
  widening the epoch.
- **Branches are unconditional only** (needs SETP + predicate registers).
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
