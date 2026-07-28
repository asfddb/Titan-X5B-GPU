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
