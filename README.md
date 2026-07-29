<p align="center">
  <img src="docs/assets/titan_x5b_banner.svg" alt="Titan X5" width="720"/>
</p>

<h1 align="center">Titan X5 — a GPU built from scratch in Verilog</h1>

<p align="center">
  <em>A solo learning project: designing the building blocks of a modern GPU at the RTL level,<br/>
  and taking some of them all the way to a real chip layout with open-source tools.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/HDL-Verilog%20%2F%20SystemVerilog-blue"/>
  <img src="https://img.shields.io/badge/synthesis-Yosys%20%2B%20OpenLane-green"/>
  <img src="https://img.shields.io/badge/PDK-SkyWater%20sky130-orange"/>
  <img src="https://img.shields.io/badge/sim-Icarus%20%2B%20cocotb-purple"/>
  <img src="https://img.shields.io/badge/license-CERN--OHL--S--2.0-lightgrey"/>
</p>

---

## What this is

Titan X5 is an **educational project** where I built the core pieces of a GPU — compute cores,
tensor math, ray tracing, an on-chip network, and a cache hierarchy — as **synthesizable Verilog**,
then pushed some blocks through a **real physical chip-design flow** (Yosys → OpenLane → OpenROAD)
on the open-source **SkyWater sky130** process to produce actual **GDSII layout**.

It is a learning artifact, not a commercial product. See **[Honest scope](#honest-scope--limitations)**
below — I've tried hard to keep every claim in this README true and verifiable.

By the numbers (all countable from this repo):

| | |
|:--|:--|
| RTL | **76 Verilog files · ~17,700 lines** |
| Blocks hardened to real GDSII (sky130) | **FP32 FMA (~0.23 mm²)**, **Tensor core array (~2.7 mm²)** |
| Verification | cocotb + Icarus Verilog testbenches |
| Software stack | Python compiler · C driver · C++ runtime · shared ISA |

---

## What's actually in here

**Compute**
- SIMT streaming multiprocessor (`rtl/core/`) — ALU, decoder, pipeline with forwarding, register file, warp scheduler
- Per-warp program counters (`rtl/core/titan_x5_pc_unit.v`) — sequencing, absolute-index
  branches with wrong-path squash, and `EXIT` warp retire. The full-chip test runs a real
  multi-instruction program, not a single instruction on repeat
  (see [roadmap](docs/ROADMAP_REAL_HARDWARE.md))
- IEEE-754 floating point (`rtl/fpu/`) — FP32 add / multiply / fused-multiply-add
- Scaled top (`rtl/titan_x6_gpu_top.v`) parameterized up to 64 SMs

**Tensor / AI**
- Output-stationary systolic **tensor core array** (`rtl/tensor/`) — FP16 path, **hardened to GDSII**

**Ray tracing**
- Multi-ray **BVH traversal engine** (`rtl/raytracing/`) — pipelined Möller–Trumbore triangle test + ray-box slab test

**Interconnect & memory**
- 2D-mesh **NoC router** with XY routing and virtual-channel support (`rtl/interconnect/`)
- **MESI** coherent L1 caches → banked L2 (configurable, up to 64 MB) → 512-bit **GDDR7-width** memory interface (`rtl/memory/`)

**Software (the hardware/software contract)**
- `compiler/titan_compiler.py` — a small compute compiler that emits the Titan ISA
- `driver/` — C kernel driver + C++ runtime
- A test that checks the **compiler's ISA encoding matches the driver header, the RTL
  decoder and the ALU** (`compiler/test_compiler_isa.py`)
- **Compiled kernels actually run on the RTL.** `compiler/kernels/matmul.py` is compiled
  to Titan ISA, loaded into VRAM, executed by `titan_x5_gpu_top` in simulation, and the
  result matrix compared against NumPy — **bit-exact**, signed negatives included, at
  2×2×2 and 4×4×4 (`tb/test_compute_kernels.py`). This needs real control flow: the
  compiler lowers `for` loops to `SETP` plus a predicated `BRANCH`, so it only became
  possible once predicate registers existed.

---

## Real silicon layout (sky130)

These went through the full open-source RTL→GDSII flow (synthesis, floorplan, placement, CTS,
routing, signoff) and are DRC/LVS-clean:

| Block | Process | Die area | Status |
|:--|:--|--:|:--|
| `titan_x5_fp32_fma` | sky130 (130 nm) | ~0.23 mm² | ✅ GDSII |
| `titan_x6_tensor_core_array` | sky130 (130 nm) | ~2.7 mm² | ✅ GDSII |
| `titan_x5_rt_core` | sky130 (130 nm) | — | 🔧 hardening |

> These are real, taped-out-style layouts on a free/open PDK — the same tools a startup would
> prototype with — **not** a manufactured chip. See scope below.

---

## Architecture

```
            ┌──────────── GPC ×N ────────────┐
   SMs ───▶ │  SIMT SM  ·  L1 (MESI)         │
            └───────────────┬────────────────┘
                            │  coherent traffic
                    ┌───────▼────────┐
                    │  2D-mesh NoC   │   XY routing, virtual channels
                    └───────┬────────┘
                    ┌───────▼────────┐
                    │  Banked L2     │   configurable, up to 64 MB
                    └───────┬────────┘
                    ┌───────▼────────┐
                    │ 512-bit VRAM   │   GDDR7-width AXI
                    └────────────────┘

   Accelerators:  Tensor core array (systolic, FP16)   ·   RT core (BVH traversal)
   Software:      titan_compiler.py  →  ISA  →  C driver / C++ runtime
```

---

## Repository layout

```
rtl/          synthesizable Verilog
  core/         SIMT SM, ALU, pipeline, register file, warp scheduler
  fpu/          FP32 add / mul / fma
  tensor/       systolic tensor core array (→ GDSII)
  raytracing/   multi-ray BVH traversal engine
  interconnect/ 2D-mesh NoC router
  memory/       MESI L1, banked L2, GDDR7-width VRAM controller
  control/      command processor, perf counters
compiler/     Python compute compiler + ISA tests
driver/       C driver + C++ runtime + ISA header
openlane/     OpenLane configs + real sky130 runs (GDSII in final/)
tb/           cocotb / Icarus testbenches
docs/         architecture, microarchitecture, ISA, verification notes
```

---

## Quick start

**Simulate (Icarus + cocotb):**
```bash
pip install cocotb pytest numpy
# the block-level regression (17 suites)
python tb/run_regression.py
```

**Run a compiled kernel on the RTL, including the bit-exact matmul:**
```bash
python -m pytest tb/test_compute_kernels.py -v
```
These are whole-GPU simulations — the design runs at roughly 90 clock cycles per wall
second under Icarus, so budget tens of minutes. `run_regression.py` runs the quick
subset automatically as the `compute` suite.

**Reproduce a chip layout (OpenLane, sky130):**
```bash
# requires OpenLane 2 + Docker
openlane openlane/titan_x6_tensor_core_array/config.json
# output GDSII lands in openlane/<design>/runs/*/final/
```

See [`docs/TESTING.md`](docs/TESTING.md) and [`docs/SYNTHESIS.md`](docs/SYNTHESIS.md) for details.

---

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Microarchitecture — compute](docs/MICROARCHITECTURE_PART1.md) · [graphics & memory](docs/MICROARCHITECTURE_PART2.md)
- [ISA reference](docs/TITAN_X5_ISA_REFERENCE.md)
- [MESI coherence review](docs/MESI_REVIEW.md)
- [Verification plan](docs/VERIFICATION.md)

---

## Honest scope & limitations

I want this to be judged as real engineering, so here's the straight story:

- **It is a learning project, not a product.** There is no manufactured chip, no driver you can
  install, and no benchmarked performance.
- **sky130 is a 130 nm open PDK** (~2005-era). Real GPUs are on ~4 nm. The hardened blocks target
  ~100 MHz on sky130 — orders of magnitude behind commercial silicon in speed and density.
- **There are real 2 nm synthesis numbers, and they are synthesis only.** The Titan X7 blocks
  have been mapped onto [GT2N](https://github.com/azadnaeemi/GT2N), an open-source 2 nm nanosheet
  GAAFET PDK. **GT2N is predictive, not fabbable** — no foundry will take it, and a fabbable 2 nm
  part needs an NDA foundry agreement and a mask set costing tens of millions. The numbers are
  also *synthesis only*: no place & route, no CTS, no extraction, and ABC reports
  `WireLoad = "none"`, so they contain **zero wire delay** and can only get worse after routing.
  GT2N ships one corner (`tt` 0.7 V 25 °C), so there is no slow-corner signoff.
  Measured: the 8-stage FP32 FMA first came out at 658.71 ps (**1.52 GHz**, elvt/w31) against the
  333 ps/stage target in its own header — a ~2× miss, traced to a **58-gate ripple-carry critical
  path** (GT2N has no adder cells) and a "CLZ tree" that was actually a 106-deep linear scan.
  Replacing both with a Kogge-Stone prefix adder and a real log-depth reduction tree took it to
  **401.81 ps = 2.49 GHz** for +6.2% area — a 39% improvement, of which **28.4% is the RTL change
  measured at matched synthesis effort** (the rest is driving the tool harder; both were measured
  separately with a control run). Every substitution is **SAT-proven** equivalent, and the whole
  pipeline is proven sequentially equivalent to the original (`equiv_induct`: 2172 cells proven,
  0 unproven). Cost: Icarus simulation of that block got ~250× slower.
  Full results and caveats: [docs/GT2N_2NM_SYNTHESIS.md](docs/GT2N_2NM_SYNTHESIS.md).
- **The banked register file has no SRAM to map onto at 2 nm.** GT2N contains no memory compiler,
  so the behavioural macro model synthesises into 535,419 gates of flip-flops — 37,288 µm², 83× the
  FMA. The module is functionally correct and structurally right; it is simply not implementable
  on this PDK without an external SRAM generator.
- **Each "SM" is a simplified core** compared to a real GPU SM. The 64-SM figure is the parameterized
  top-level configuration, not silicon.
- **The full GPU has not been placed & routed as one chip** — individual blocks have (FMA, tensor array).
- **No instruction cache, and one outstanding fetch per SM.** Control flow works, but
  instruction supply is slow; this is the next bottleneck (roadmap Phase 2). Measured:
  ~58 clock cycles per instruction retired, and launching 8 warps instead of 1 took the
  render test from 8,009 to 10,009 cycles.
- **Divergent predication is not implemented.** `SETP` and per-warp predicate registers
  exist and conditional branches work, so loops can have exit conditions. Predicates are
  32-bit per-lane masks, but an instruction only executes when *every* lane agrees; a
  mask whose lanes disagree needs a reconvergence stack the pipeline does not have. That
  case is not silently mis-executed — the instruction is skipped and a sticky
  `dbg_pred_divergent` flag is raised so it is observable.
- **No cache flush path.** L1 and L2 are both write-back with no flush or writeback-all
  port, so a kernel's results can sit in a Modified L1 line indefinitely; nothing makes
  them reach memory. A host reading results back from a real part would need a flush that
  does not exist yet. The compute testbench works around this by reading the
  architectural value out of the cache hierarchy directly.
- Parts of this were built with AI assistance; the goal was to understand GPU architecture end-to-end.

Its honest peer group is open-source research GPUs like **MIAOW**, **Vortex**, and **Nyuzi** —
not NVIDIA silicon.

---

## License

Released under **CERN-OHL-S-2.0** (a copyleft open-hardware license). You're free to use, study,
modify, and share it; derivative hardware must stay open under the same license. See [LICENSE](LICENSE).

---

<p align="center"><sub>Built as a self-taught deep dive into how GPUs actually work — from a single ALU to a routed chip layout.</sub></p>
