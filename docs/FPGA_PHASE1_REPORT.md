# Phase 1: FPGA Physical Deployment — Status Report

*2026-07-07 — produced with Claude Fable 5. All numbers in this report are
**measured** yosys `synth_xilinx` results (`syn/reports/blocks/*.stat`),
reproducible via `syn/scripts/synth_blocks.sh`. This report supersedes any
earlier FPGA claims: the previous `fpga/run_artix7_synthesis.py` printed a
hardcoded "41k LUT SYNTHESIS SUCCESS" without invoking a synthesis tool and
has been deleted.*

## 1. Toolchain

| Flow | Status | Entry point |
|---|---|---|
| Vivado batch (synth → PnR → `.bit`) | **Ready, Vivado not installed** | `fpga/build_fpga.ps1` → `fpga/vivado_build.tcl` |
| Open-source check (yosys in WSL) | **Working** | `fpga/build_fpga.ps1 -SynthOnly` → `fpga/synth_fpga_top.ys` |

A bitstream for the Basys 3 requires AMD Vivado (free ML Standard covers the
xc7a35t): there is no maintained open-source place-and-route path for 7-series
on Windows, and the design size makes nextpnr-xilinx impractical anyway.
`vivado_build.tcl` gates `write_bitstream` on WNS ≥ 0, so it cannot silently
ship a bitstream that fails timing.

## 2. Constraints (`fpga/titan_x5_basys3.xdc`)

Verified against `rtl/titan_x5_fpga_top.v` ports: 100 MHz clock (W5),
16 switches, 16 LEDs, btnC/btnU, 4:4:4 VGA + hsync/vsync — all pin
assignments match the Digilent Basys 3 master XDC. No changes needed.

## 3. Defects found and fixed during bring-up

1. **`titan_x5_fpga_top` never connected `mem_clk`/`pclk`** — the memory
   controller and display engine were clockless; the generated 25 MHz pixel
   clock went nowhere; VGA would be dead on hardware. Also left the GPU at
   its 1920×1080 default while generating 640×480 timing. Fixed.
2. **Illegal `(* ram_style="block" *)` attributes** on small asynchronously
   read arrays (ifetch FIFO, crossbar grant logic, SR-engine tag mux, ROP
   tiles, vertex systolic registers, perf counters, CDC FIFO). BRAM cannot
   serve combinational reads; yosys hard-errors. Attributes removed — tools
   still infer BRAM automatically where legal.
3. **No way to exclude the per-lane tensor arrays.** Added `ENABLE_TENSOR`
   (ALU → SM → GPU top, default 1 = verified ASIC config unchanged;
   regression lsu/fpu/mesi/tmu green). The FPGA wrapper builds with 0.

Side finding: `titan_x5_shared_memory`, `titan_x5_ray_triangle_isect` and
`titan_x5_hash_fnv64` are **not instantiated anywhere in the GPU hierarchy**
(only referenced by out-of-tree tops) — the SM has no shared-memory path and
the RT core does not use the ray-triangle intersector. Left as-is; relevant
to Phase 2 floorplanning and to marketing claims about these features.

## 4. Measured utilization vs. Basys 3 (xc7a35t)

<!-- BLOCK_TABLE_START -->
(regenerate with `python syn/scripts/summarize_blocks.py`; raw data in
`syn/reports/blocks/*.stat`)

| block | LUT-eq (LC) | FF | BRAM36 | DSP48 | LUTRAM cells |
|---|---:|---:|---:|---:|---:|
| lsu | 130,288 | 4,089 | 0 | 0 | 0 |
| tmu | 90,913 | 58,472 | 0 | 26 | 0 |
| alu | 34,586 | 3,058 | 0 | 23 | 0 |
| tensor_array_4x4 | 31,600 | 1,220 | 0 | 16 | 0 |
| rasterizer | 20,891 | 3,103 | 0 | 34 | 0 |
| rop | 13,139 | 17,259 | 0 | 0 | 0 |
| coherent_xbar | 7,770 | 8,480 | 0 | 0 | 0 |
| vertex_transformer | 6,377 | 643 | 0 | 52 | 0 |
| pipeline | 5,721 | 8,263 | 0 | 0 | 7 |
| rt_core | 4,394 | 1,324 | 0 | 132 | 0 |
| l2_mem_adapter | 4,302 | 2,092 | 0 | 0 | 0 |
| warp_scheduler | 3,226 | 5,027 | 0 | 0 | 0 |
| alu_notensor | 2,632 | 1,838 | 0 | 7 | 0 |
| register_file | 1,988 | 2,048 | 0 | 0 | 0 |
| command_processor | 1,571 | 1,139 | 0 | 0 | 0 |
| fp32_fma | 1,406 | 740 | 0 | 2 | 0 |
| display_engine | 955 | 2,221 | 0 | 1 | 0 |
| crossbar | 623 | 412 | 0 | 0 | 0 |
| gddr7_phy | 513 | 685 | 0 | 0 | 0 |
| sr_engine | 408 | 654 | 0 | 0 | 88 |
| dma_engine | 203 | 329 | 0 | 2 | 0 |
| mem_controller | 128 | 171 | 0 | 0 | 0 |
| vram_ctrl | 92 | 62 | **32** | 0 | 0 |
| decoder | 8 | 0 | 0 | 0 | 0 |
| neural_shader | 5 | 228 | 0 | 0 | 0 |
| **xc7a35t budget** | **20,800** | **41,600** | **50** | **90** | - |

Not synthesizable on this host (yosys OOM-killed at ~11.6 GB RSS while
flattening their storage arrays to registers): `titan_x5_l1_cache`,
`titan_x5_l2_cache`, and the 2-lane/no-tensor `titan_x5_sm` probe (which
embeds an L1). `titan_x5_shared_memory` also failed (8-port banked array;
dead code, see §3). The full `titan_x5_fpga_top` cannot complete synthesis
for the same reason — the per-block table above is the honest substitute.
<!-- BLOCK_TABLE_END -->

## 5. Fit verdict

- **Full Titan X5-B: does not fit — by roughly two orders of magnitude.**
  One ALU lane is 34,586 LUT-eq (31,600 of which is its embedded 4×4 WMMA
  tensor array); the GPU instantiates 128 lanes. The xc7a35t has 20,800 LUTs.
  This is an area wall; no timing-closure work changes it.
- `ENABLE_TENSOR=0` shrinks a lane to 2,632 LUT-eq (13×), but 128 lanes is
  still ~337k LUT-eq of ALUs alone.
- **Individual subsystems independently exceed the chip**: the LSU measures
  130,288 LUT-eq (32-lane address-coalescing comparators and lane buffers;
  one per SM, 4 SMs). The TMU measures 90,913 LUT-eq / 58,472 FF because
  its embedded 4 KB texture cache (`titan_x5_l1_cache` with
  `LINE_BYTES=4, SETS=256, WAYS=4`) flattens entirely to flip-flops and
  way-parallel read muxes — and the GPU has two TMUs. The rasterizer alone
  is 20,891 LUT-eq. The RT core consumes 132 DSP48s against a budget of 90.
- **The caches cannot use BRAM at all as written.** L1 and L2 declare their
  storage as multi-dimensional arrays (`data_array[set][way]`,
  `data_array[bank][set][way]`) with combinational tag lookups across all
  ways; synthesis flattens them to registers — yosys was OOM-killed at
  11.6 GB RSS trying, so the caches cannot even be synthesized on this
  host, let alone fit. Even ignoring that, the full
  config's 256 KB L2 + 4×32 KB L1 + 128 KB VRAM ≈ 512 KB exceeds the
  xc7a35t's 225 KB of BRAM. A BRAM-friendly cache rewrite (1-D arrays,
  registered reads, sequential tag check) is prerequisite for any FPGA
  build that includes the caches. The VRAM controller's single-dim
  `reg [511:0] bram [0:2047]` maps to BRAM cleanly.

## 6. Recommended path to "Hardware Hello World"

1. **Basys 3 (owned today): display-path bitstream.** Display engine
   (955 LUT-eq, 1 DSP) + VRAM controller (BRAM-based after the async-reset
   fix) + boot pattern source → real VGA output. This subset fits
   comfortably and exercises genuine silicon: clocking, XDC, VGA DAC.
2. **Full (reduced) GPU: larger Artix-7 board.** An Arty/Nexys A7-100T
   (63,400 LUTs, 240 DSP, 135 BRAM36) could plausibly hold a 1-SM,
   no-tensor configuration — but only after the BRAM-friendly cache rewrite
   (§5) and shrinking the rasterizer and TMU; as measured, the TMU alone
   exceeds even the A7-100T.
3. **Install Vivado ML Standard** — required for any `.bit` in either case;
   `fpga/build_fpga.ps1` picks it up automatically once installed.
