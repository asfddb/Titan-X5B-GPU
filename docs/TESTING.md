# Testing & Verification Guide

## Prerequisites

Download and install the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) which includes:
- **Icarus Verilog** — RTL simulation
- **GTKWave** — Waveform viewing
- **Yosys** — Logic synthesis

## Quick Test

```bash
cd Titan-X5B-GPU

# Compile all Verilog files
iverilog -g2012 -I rtl -o tb/ultimate_blackwell.vvp \
  tb/ultimate_blackwell_tb.v rtl/titan_x5_gpu_top.v \
  rtl/tensor/*.v rtl/raytracing/*.v rtl/memory/*.v \
  rtl/graphics/*.v rtl/interconnect/*.v rtl/core/*.v \
  rtl/control/*.v rtl/sr/*.v rtl/power/*.v \
  rtl/display/*.v rtl/common/*.v

# Run simulation
vvp tb/ultimate_blackwell.vvp
```

## Expected Output

```
===============================================================
  TITAN X5-B (BLACKWELL) SILICON VALIDATION SUITE v2.0
  Testing Code: rtl/titan_x5_gpu_top.v
  Software: Icarus Verilog (OSS CAD Suite)
===============================================================
VCD info: dumpfile tb/blackwell_wave.vcd opened for output.
Time=0      | CLK=0 | RST=0 | Host PTR=10000000 | VRAM_WVALID=0 | VRAM_RVALID=0
Time=5000   | CLK=1 | RST=0 | Host PTR=10000000 | VRAM_WVALID=0 | VRAM_RVALID=0
Time=20000  | CLK=0 | RST=1 | Host PTR=10000000 | VRAM_WVALID=0 | VRAM_RVALID=0
Time=60000  | CLK=0 | RST=1 | Host PTR=10000010 | VRAM_WVALID=0 | VRAM_RVALID=0
...
===============================================================
  TEST PASSED: RTL Simulation Completed Without Assertion Failures
===============================================================
```

## Viewing Waveforms

After simulation, a VCD (Value Change Dump) file is generated at `tb/blackwell_wave.vcd`.

```bash
gtkwave tb/blackwell_wave.vcd
```

In GTKWave:
1. Expand the signal tree on the left: `ultimate_blackwell_tb` → `uut`
2. Drag signals like `clk`, `rst_n`, `vram_wdata` into the waveform pane
3. Click "Zoom Fit" to see all transitions
4. You will see the clock ticking, reset releasing, and the pipeline operating

## Running Synthesis

```bash
yosys -p "read_verilog -sv rtl/tensor/titan_x6_tensor_core_array.v rtl/tensor/titan_x5_fp16_mul.v; synth -top titan_x6_tensor_core_array; stat"
```

Expected result: **603,664 logic cells** for the Tensor Core alone.

## What the Test Validates

| Check | Status |
|:---|:---|
| All 57 Verilog files compile without errors | ✅ |
| Reset sequence operates correctly | ✅ |
| Clock propagation through all modules | ✅ |
| Host ring buffer pointer updates | ✅ |
| AXI4 handshaking signals stable | ✅ |
| No assertion failures during simulation | ✅ |
| VCD waveform generated successfully | ✅ |
| Yosys synthesis completes with 0 errors | ✅ |

## FPGA bring-up, without an FPGA board

The tests above drive the RTL. This one drives the *board connectors* — the
100 MHz pin, the buttons, the switches, the LEDs and the five wires of a VGA
cable — and contains no hierarchical reference into the design, because none of
those exist on a bench.

```bash
python tools/run_fpga_bringup.py            # RTL, synthesis, netlist, frame diff
python tools/run_fpga_bringup.py --quick    # power-on frame only
python tools/run_fpga_bringup.py --stage rtl
```

It captures what a monitor plugged into the Basys 3 would display, as a PPM,
and checks it against the pattern the design was asked to store. It also runs
the identical testbench against the post-synthesis netlist, which is where
assumptions the synthesiser does not share show up.

Full write-up, measured results and the defects it found:
**`docs/FPGA_BRINGUP_NO_BOARD.md`**.
