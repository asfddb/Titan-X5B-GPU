# Synthesis Results

## Tool Information

| Tool | Version | Purpose |
|:---|:---|:---|
| **Yosys** | 0.66+4 (git sha1 8125af88d) | Logic synthesis |
| **Icarus Verilog** | 14.0 (devel) | RTL simulation |
| **GTKWave** | (bundled with OSS CAD Suite) | Waveform viewer |
| **OSS CAD Suite** | 2026-06-03 release | Toolchain bundle |

## Full-Chip Synthesis: titan_x5_gpu_top

### Summary

| Metric | Value |
|:---|---:|
| **Total Logic Cells** | **3,030,603** |
| **Total Wires** | 2,427,904 |
| **Total Wire Bits** | 3,230,370 |
| **Total Ports** | 1,065 |
| **Total Port Bits** | 135,170 |
| **Errors** | 0 |

### Gate Breakdown

| Gate Type | Count | Description |
|:---|---:|:---|
| `$_AND_` | 1,045,966 | 2-input AND gate |
| `$_NAND_` | 1,227,710 | 2-input NAND gate |
| `$_DFFE_PN0P_` | 483,230 | D flip-flop with enable (pos clk, neg enable, async reset) |
| `$_XOR_` | 98,753 | 2-input XOR gate |
| `$_MUX_` | 88,263 | 2-to-1 multiplexer |
| `$_DFFE_PP_` | 43,806 | D flip-flop with enable (pos clk, pos enable) |
| `$_NOR_` | 2,700 | 2-input NOR gate |
| `$_OR_` | 8,545 | 2-input OR gate |
| `$_XNOR_` | 14,501 | 2-input XNOR gate |
| `$_ANDNOT_` | 5,053 | AND-NOT gate |
| `$_ORNOT_` | 5,843 | OR-NOT gate |
| `$_NOT_` | 522 | Inverter |
| `$_SDFFCE_PP0P_` | 2,048 | Sync D flip-flop with clear and enable |
| `$_DFF_PN0_` | 2,373 | D flip-flop (pos clk, neg async reset) |
| `$_DFFE_PN0N_` | 1,248 | D flip-flop variant |
| `$_DFFE_PN1P_` | 31 | D flip-flop variant |
| `$_DFF_PN1_` | 8 | D flip-flop variant |
| `$_DFF_P_` | 3 | Simple D flip-flop |

### Module Hierarchy

| Module | Gate Count | Description |
|:---|---:|:---|
| `titan_x6_tensor_core_array` | 603,664 | 16×16 FP16 systolic tensor core |
| `titan_x5_tmu` (×4) | 183,030 each | Texture mapping units |
| `titan_x5_rt_core` | 179,450 | Ray tracing intersection engine |
| `titan_x5_sm` (×4) | ~150,000 each | Streaming multiprocessors |
| `titan_x5_crossbar` | ~50,000 | AXI4 interconnect |
| `titan_x5_rasterizer` | ~30,000 | Triangle rasterization |
| `titan_x5_rop` (×4) | 4,853 each | Render output units |
| `titan_x5_display_engine` | 2,061 | Video output |
| `titan_x5_command_processor` | ~5,000 | Host command decode |

---

## Tensor Core Standalone Synthesis

### Summary

| Metric | Value |
|:---|---:|
| **Total Logic Cells** | **603,664** |
| **Flip-Flops (DFFE)** | 16,400 |
| **AND gates** | 154,368 |
| **NAND gates** | 179,456 |
| **MUX** | 72,192 |
| **XOR gates** | 59,648 |
| **Processing Elements** | 256 (16×16) |
| **Problems Found** | **0** |

---

## How to Reproduce

```powershell
# Set up environment
$env:PATH = "C:\tools\oss-cad-suite\oss-cad-suite\bin;$env:PATH"

# Synthesize full chip
yosys -q -p "read_verilog -sv [all .v files]; hierarchy -top titan_x5_gpu_top; synth; stat"

# Synthesize tensor core only
yosys -p "read_verilog -sv rtl/tensor/*.v; synth -top titan_x6_tensor_core_array; stat"
```

All results are independently reproducible using the free, open-source Yosys toolchain.
