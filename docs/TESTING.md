# Testing & Verification Guide

## Prerequisites

Download and install the [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build/releases) which includes:
- **Icarus Verilog** — RTL simulation
- **GTKWave** — Waveform viewing
- **Yosys** — Logic synthesis

## Quick Test (Windows PowerShell)

```powershell
cd c:\Users\singb\Downloads\gpuuhj

# Set PATH
$env:PATH = "C:\tools\oss-cad-suite\oss-cad-suite\bin;$env:PATH"

# Compile all 57 Verilog files
iverilog -g2012 -I rtl -o tb/ultimate_blackwell.vvp `
  tb/ultimate_blackwell_tb.v rtl/titan_x5_gpu_top.v `
  rtl/tensor/*.v rtl/raytracing/*.v rtl/memory/*.v `
  rtl/graphics/*.v rtl/interconnect/*.v rtl/core/*.v `
  rtl/control/*.v rtl/sr/*.v rtl/power/*.v `
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

```powershell
gtkwave tb/blackwell_wave.vcd
```

In GTKWave:
1. Expand the signal tree on the left: `ultimate_blackwell_tb` → `uut`
2. Drag signals like `clk`, `rst_n`, `vram_wdata` into the waveform pane
3. Click "Zoom Fit" to see all transitions
4. You will see the clock ticking, reset releasing, and the pipeline operating

## Running Synthesis

```powershell
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
