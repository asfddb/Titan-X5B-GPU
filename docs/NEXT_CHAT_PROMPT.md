# Prompt for the next chat

Copy everything below the line into a new chat.

---

I am building **TITAN APEX-X**, a high-performance GPU targeting the 2 nm
node, aiming to beat an RTX 5090 on compute throughput. Continue that work.

## WHERE TO WORK — read this before touching anything

**All work happens in `C:\Titan-X5B-GPU`, on branch
`claude/titan-x5-gpu-conversion-lf6udk`.**

- **Do not create a new repository and do not start a folder somewhere else.**
  A new directory tree *inside* this repo is fine; a new repo is not. The
  commit history documenting bugs found and fixed is this project's
  credibility.
- **Work on the real files, in place.** Read the actual RTL, testbenches and
  reports before proposing anything. Design against the code, not against a
  description of it.
- Commit as you go, on that branch. No PR unless I ask.

**Read these first, in this order:**

1. `docs/TITAN_GPU_SPEC.md` — what the design currently is, every figure
   measured
2. `docs/BUILD_LOG_2NM.md` — how it got there, **including what failed**
3. `docs/GT2N_2NM_SYNTHESIS.md` — the 2 nm results and their caveats
4. `docs/HANDOFF_NEXT_SESSION.md` — older context, still useful

## ENVIRONMENT — verify it, do not trust this list blindly

| Tool | Location | Notes |
|:--|:--|:--|
| Yosys 0.67 + ABC | `C:\eda\oss-cad-suite\bin` | **not on PATH** |
| GT2N 2 nm PDK | `C:\eda\GT2N` | BSD-3, predictive |
| Icarus Verilog 12.0 | `C:\iverilog\bin` | **not on PATH** |
| Python 3.12 | `%LOCALAPPDATA%\Programs\Python\Python312` | cocotb 2.0.1, numpy, pytest |

Yosys needs **both** `bin` and `lib` on PATH (it loads DLLs from `lib`):

```bash
export PATH="/c/eda/oss-cad-suite/bin:/c/eda/oss-cad-suite/lib:$PATH"
```

Yosys is a **Windows** binary — give it Windows-style paths
(`C:/eda/GT2N/...`), not `/c/...` or `/tmp/...`. Python on Windows also does
not understand `/tmp`.

**No C++ compiler exists on this machine** — no g++, gcc, clang, MSVC, or
`make`. Verilator therefore **cannot run** (it emits C++ that must be
compiled). oss-cad-suite ships the Verilator binary but no toolchain, so it
can lint but not simulate. Do not waste time on it without installing MinGW
first, and ask me before installing anything large.

**`git push` is broken** — "Password authentication is not supported".
Credential Manager blocks on a GUI prompt and `gh` is not installed. There
are ~25 unpushed commits. Ask me to authenticate; never try to supply
credentials yourself.

## HOW TO RUN THINGS

```bash
# full regression -- 29 suites, must be 29/29, exit 0
python tb/run_regression.py
python tb/run_regression.py fma8 tensor7    # subset

# deep compute suite -- 14 tests, ~32 min, the compiler -> ISA -> RTL path
python -m pytest tb/test_compute_kernels.py -v

# 2 nm synthesis of any module
export GT2N_ROOT=C:/eda/GT2N
export OSS_CAD=/c/eda/oss-cad-suite
./syn/gt2n/run_gt2n.sh titan_x7_fp32_fma_pipe rtl/fpu/titan_x7_fp32_fma_pipe.v

# die area budget
python syn/gt2n/die_budget.py 40000 32 8
```

**`TITAN_FAST_SIM`**: `tb/run_regression.py` defines it, which selects
behavioural forms of `titan_x7_prefix_add` and `titan_x7_lzc`. They are
SAT-proven identical to the structural versions, and the structural ones cost
~250x simulation time. **Synthesis must never define it** —
`syn/gt2n/run_gt2n.sh` does not. If a timing number suddenly improves
dramatically, check this first.

## CURRENT STATE — all measured

| Block | Area | Delay | Clock |
|:--|--:|--:|--:|
| FP32 FMA | 476.85 µm² | 401.81 ps | 2.49 GHz |
| Tensor PE | 283.29 µm² | 433.06 ps | 2.31 GHz |
| HBM4 controller | 724.96 µm² | — | — |

- 40,000 lanes → **199.2 TFLOPS FP32 (1.90x a 5090)**, 186.86 mm² of compute
- Memory: 8 x 1024-bit HBM4 channels, one beat per 128-byte line
- Verification: **29/29 regression suites, 14/14 deep compute tests**
- 4 formal equivalence proofs (SAT), including whole-pipeline sequential
  equivalence for the FMA and tensor PE

**2.49 GHz is a hard floor.** Tightening the synthesis target does nothing but
add area, and three structural attempts to beat it — an extra pipeline stage,
a sticky-mask rewrite, a 9-stage FMA — all made it **worse**. These blocks are
load- and fanout-limited, not depth-limited. Do not assume "add a pipeline
stage" will help; measure first.

Also be warned: **ABC's mapping is structurally sensitive enough that removing
logic can make timing worse** (measured twice). Stub-based localisation of a
critical path is unreliable on this flow.

## WHAT TO BUILD NEXT — in priority order

1. **Place and route.** Everything so far is synthesis with
   `WireLoad = "none"` — zero wire delay. This is the only way to learn how
   much of the 401.81 ps is wire, and it is the most valuable unknown left.
   Needs OpenROAD, which needs WSL2 or Docker (neither installed — ask me
   first, it is several GB).
2. **An SRAM macro source.** The register file is ~77% of die area because
   GT2N has no memory compiler, so it synthesises to flip-flops. Worth
   roughly 4.4x the whole die area — more than every frequency optimisation
   combined. Look at OpenRAM or FakeRAM2.0.
3. **Wire the flush to the command processor.** The L1 flush works and is
   verified, but nothing raises `flush_req` yet; the SM and TMU instances tie
   it low. Until then a host still cannot read kernel results back.
4. **Wire the X7 SM into the chip.** `titan_x5_gpu_top` still instantiates
   the old blocking-pipeline x5 SM (~58 cycles per instruction). The X7 SM is
   dual-issue and measures IPC 1.72 — roughly 100x — but is not connected.
5. **Integrate the banked register file into the SM.** Verified standalone;
   the swap turns operand read from combinational to variable-latency.
6. **FP8/FP4 block scaling** on top of `titan_apex_dp_mac`, plus 64-bit
   addressing and a branch reconvergence stack.

## WHAT IS IMPOSSIBLE — do not promise these

- **A fabbable chip.** GT2N is *predictive*. No foundry accepts it. A real
  2 nm tapeout needs an NDA foundry agreement and a mask set costing tens of
  millions.
- **Memory / PCIe PHYs.** Transistor-level analog IP — DLLs, per-bit deskew,
  training state machines. Licensed, not written.
- **A conformant graphics driver.** Tens of millions of lines plus Khronos
  CTS.
- **DFT/scan and clock-tree gating on GT2N** — it has no scan flop and no
  integrated clock-gating cell. Verified.
- **Cloning NVIDIA's RTL.** Their designs are trade secret. Beating them on
  measured throughput with original RTL is the goal; copying is not on the
  table.

## WORKING RULES — these produced every good result so far

- **No invented numbers.** Every figure must come from a command actually
  run. Say "unknown and unmeasured" rather than estimating.
- **Mutation-test every new test.** Inject a defect, show the test fails,
  restore, show it passes. This found two suites that were passing while
  proving nothing — a register file that could be made completely
  warp-shared with the suite still green, and an FMA differential with
  near-zero coverage of round-to-nearest-even.
- **Control-experiment every fix.** Re-measure the original at matched tool
  effort, so an RTL gain is not confused with a synthesis setting. The FMA's
  39% improvement was really 28.4% RTL and 14.8% tool.
- **Record negative results.** Three failed optimisation attempts are
  documented in `BUILD_LOG_2NM.md` and are more useful than another 2%.
- **Tell me when I am wrong.** If what I ask for is the wrong plan, say so
  directly. I would rather be corrected than agreed with.
- **Honest scope in README.md.** Never drop a caveat quietly. If a 2 nm
  number appears, "predictive, not fabbable" and "synthesis only, zero wire
  delay" appear beside it.
- **Do not edit RTL while a regression is running** — the runner elaborates
  each suite as it reaches it, so an edit silently corrupts every suite that
  has not started.
- Commit messages explain the *why*, and end with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  ```

Start by reading the four documents listed above and running
`python tb/run_regression.py` to confirm you have a clean 29/29 baseline.
Then tell me what you propose to build, and why that one first.
