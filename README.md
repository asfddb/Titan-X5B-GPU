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
- A test that checks the **compiler's ISA encoding matches the driver header and the RTL decoder** (`compiler/test_compiler_isa.py`)

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
pip install cocotb pytest
# example: run the NoC / ALU testbenches under tb/
python tb/run_regression.py
```

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
- **Each "SM" is a simplified core** compared to a real GPU SM. The 64-SM figure is the parameterized
  top-level configuration, not silicon.
- **The full GPU has not been placed & routed as one chip** — individual blocks have (FMA, tensor array).
- Parts of this were built with AI assistance; the goal was to understand GPU architecture end-to-end.

Its honest peer group is open-source research GPUs like **MIAOW**, **Vortex**, and **Nyuzi** —
not NVIDIA silicon.

---

## License

Released under **CERN-OHL-S-2.0** (a copyleft open-hardware license). You're free to use, study,
modify, and share it; derivative hardware must stay open under the same license. See [LICENSE](LICENSE).

---

<p align="center"><sub>Built as a self-taught deep dive into how GPUs actually work — from a single ALU to a routed chip layout.</sub></p>
