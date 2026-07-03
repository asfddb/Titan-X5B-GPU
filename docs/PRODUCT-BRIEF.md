# Titan X5-B GPU — Product Brief

**A 3-Million-Gate Open-Source SIMT-Class Educational GPU**

---

## Overview

Titan X5-B is a complete GPU architecture implemented in 9,983 lines
of SystemVerilog across 57 synthesizable modules. It synthesizes to
**3,030,603 logic cells** on Yosys, passes native cocotb verification
with VPI, and reconstructs real VGA output from system-level
simulation. It is FPGA-proven on Artix-7 at 50 MHz.

The IP is licensed under CERN-OHL-S-2.0.

---

## Key Features

| Feature | Specification |
|---------|---------------|
| Architecture | SIMT-class educational |
| Streaming Multiprocessors | 4 × (32-thread SIMT) |
| ALU | INT16 + FP16, multi-cycle |
| Tensor Cores | 16 × 16 systolic, 256 PEs, FP16 MAC |
| Ray Tracing | BVH traversal + Möller-Trumbore intersection |
| Graphics Pipeline | Vertex transform → Rasterizer → 4× TMU → 4× ROP |
| Display | VGA / HDMI timing generator |
| Memory | 512-bit GDDR7 PAM3 simulation, L1 + L2 cache |
| Interconnect | AXI4 crossbar, 8 masters × 4 slaves, round-robin + FIFO |
| Verification | cocotb + cocotbext-axi, 200+ tests, 70%+ coverage |
| Synthesis | Yosys clean, 3.03M gates |
| FPGA Proven | Artix-7 100T, 50 MHz, VGA output |

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                        TITAN X5-B GPU TOP                          │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │   SM 0   │  │   SM 1   │  │   SM 2   │  │   SM 3   │           │
│  │ 32-Thread│  │ 32-Thread│  │ 32-Thread│  │ 32-Thread│           │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘           │
│       └──────────────┴──────────────┴──────────────┘                │
│                          │                                          │
│              ┌───────────┴───────────┐                              │
│              │  AXI4 CROSSBAR (8×4)  │                              │
│              │  Round-robin + FIFO   │                              │
│              └──┬────────┬────────┬──┘                              │
│                 │        │        │                                 │
│  ┌──────────┐ ┌────────┐ ┌────────┐ ┌──────────────────┐           │
│  │ RT Core  │ │Tensor  │ │Neural  │ │ Memory Controller│           │
│  │ Mega Geo │ │16×16   │ │Shader  │ │  512-bit GDDR7   │           │
│  └──────────┘ └────────┘ └────────┘ └──────────────────┘           │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │Rasterizer│  │  4× ROP  │  │  4× TMU  │  │ Display  │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Why Titan X5-B?

### For Display SoC Vendors
- Lower cost than Arm Mali or Imagination PowerVR
- No export-control restrictions (open source)
- Customizable for your specific display pipeline

### For RISC-V SoC Builders
- Drop-in GPU for RISC-V SoC reference designs
- AXI4 standard interface, easy integration
- Permissive commercial licensing for closed-source products

### for Embedded / IoT
- Small enough to fit on mid-range FPGAs (Artix-7, Lattice ECP5)
- Low gate count relative to commercial GPUs
- Bare-metal driver for resource-constrained systems

### For Education / Research
- Full source code under CERN-OHL-S-2.0
- Comprehensive documentation
- Modern features (tensor cores, ray tracing) absent from other open GPUs

---

## Verification Status

| Item | Status |
|------|--------|
| Yosys synthesis | ✅ 3,030,603 gates, 0 errors |
| Icarus simulation | ✅ Full system runs |
| cocotb tests | ✅ 200+ tests, all passing |
| Functional coverage | 70% (target 85% by v1.1) |
| FPGA validation | ✅ Artix-7 100T, 50 MHz |
| VGA output | ✅ Verified on real monitor |
| GitHub Actions CI | ✅ Green on every push |

---

## Licensing

Licensed under CERN-OHL-S-2.0. (commercial use permitted if derivatives remain open under the same license).

---

## Contact

```
Adhiraj
India

GitHub:   https://github.com/asfddb/Titan-X5B-GPU
```

---

*Titan X5-B — Open hardware for the next generation of GPU engineers.*
