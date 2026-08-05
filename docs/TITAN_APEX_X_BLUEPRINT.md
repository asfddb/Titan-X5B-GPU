# TITAN APEX-X — chip blueprint (x5 build)

> **This file is generated. Do not edit it by hand.**
> 
> ```bash
> python tools/gen_blueprint.py            # regenerate
> python tools/gen_blueprint.py --check    # fail if it is stale
> ```
> 
> Every structural figure below was recovered from the RTL at
> generation time. The hierarchy and all instance counts come from
> Yosys (`read_verilog; hierarchy -check -top; stat`), so generate
> loops, parameter overrides and `ifdef` selection are *elaborated*,
> not guessed at with a regex. If this document and the RTL ever
> disagree, `--check` fails.

---

## 0. What this is, and the caveats that travel with it

A GPU written from RTL up, simulated and synthesised. It is **not a
product**: there is no manufactured chip, no installable driver and no
benchmarked frame rate. Its honest peer group is academic open-source
GPUs — MIAOW, Vortex, Nyuzi — not shipping silicon.

Three caveats attach to every physical number here:

1. **GT2N is a *predictive* PDK — this design is not fabbable.** No
   foundry accepts it.
2. **Synthesis only.** No floorplan, placement or routing. ABC reports
   `WireLoad = "none"`: **zero wire delay**. At 2 nm wire delay
   dominates, so place-and-route can only make timing worse.
3. **One corner** (`tt`, 0.7 V, 25 °C). No slow corner, so no signoff
   margin.

---

## 1. The chip, measured

| Property | Value |
|:--|--:|
| Top module | `titan_x5_gpu_top` |
| SM variant built | **x5** |
| Modules elaborated into the chip | **48** |
| Total module instances | **23,239** |
| RTL cells, whole chip | **659,284** |
| Top-level ports | **43** (17 in, 26 out), 1,338 bits |
| Shader cores (SM) | **4** |
| Lanes per SM | **32** |
| **Total lanes** | **128** |
| Warps per SM | 8 |
| Threads in flight | **1,024** |
| Texture units (TMU) | 4 |
| Raster output units (ROP) | 4 |
| L1 caches | **8** x 32 KiB (4-way, 64 sets, 128 B lines) |
| L2 cache | **256 KiB** (8-way, 256 sets, 4 banks) |
| Register file | 64 KiB per SM, **256 KiB** total |
| Word crossbar | 20 masters, 2 slaves, 32-bit |
| Coherent crossbar | 4 masters, MESI, 128 B lines |

**"RTL cells" is not a gate count.** It is what Yosys counts after
elaboration and before technology mapping: `$add`, `$mux`, `$dff`,
whole memories as single cells. Mapping onto GT2N turns each of
those into some number of standard cells, and a memory into a very
large number of flip-flops, because **GT2N has no SRAM**. The
mapped gate count for the whole chip is **unmeasured**: a full-chip
`synth` run was attempted for this document and was still running
at a 50-minute timeout, so no figure is quoted for it. The per-block
GT2N areas that ARE measured are in
[GT2N_2NM_SYNTHESIS.md](GT2N_2NM_SYNTHESIS.md).

---

## 2. Every module in the chip

Instance counts are **elaborated totals across the whole design**, so a
module inside a 4x generate loop inside another 4x loop reports 16.

`variants` counts distinct parameterisations Yosys elaborated for that
module; ports / cells / wire bits are the largest such variant.

| Module | Instances | Variants | Ports | Local cells | Wire bits |
|:--|--:|--:|--:|--:|--:|
| `fp32_add` | 8,192 | 1 | 3 | 22 | 1,330 |
| `fp4_mul_to_fp32` | 8,192 | 1 | 3 | 11 | 243 |
| `fp8_mul_to_fp32` | 2,048 | 1 | 4 | 41 | 440 |
| `mac_pe` | 2,048 | 1 | 13 | 19 | 1,077 |
| `titan_x5_fp16_mul` | 2,048 | 1 | 3 | 80 | 1,538 |
| `titan_x5_alu` | 128 | 1 | 16 | 231 | 9,853 |
| `titan_x5_fp32_add` | 128 | 1 | 13 | 89 | 2,778 |
| `titan_x5_fp32_fma` | 128 | 1 | 14 | 232 | 7,249 |
| `titan_x5_fp32_mul` | 128 | 1 | 13 | 125 | 2,764 |
| `titan_x6_tensor_core_array` | 128 | 1 | 11 | 7 | 6,033 |
| `titan_x5_l1_cache` | 8 | 2 | 29 | 213 | 133,763 |
| `titan_x5_async_fifo` | 5 | 5 | 10 | 21 | 4,700 |
| `titan_x5_decoder` | 4 | 1 | 20 | 14 | 105 |
| `titan_x5_lsu` | 4 | 1 | 21 | 750 | 258,203 |
| `titan_x5_pc_unit` | 4 | 1 | 15 | 88 | 1,447 |
| `titan_x5_pipeline` | 4 | 1 | 55 | 761 | 59,404 |
| `titan_x5_register_file` | 4 | 1 | 18 | 48 | 1,132,710 |
| `titan_x5_rop` | 4 | 1 | 34 | 451 | 119,265 |
| `titan_x5_sm` | 4 | 1 | 39 | 20 | 46,086 |
| `titan_x5_tmu` | 4 | 1 | 24 | 189 | 8,444 |
| `titan_x5_warp_scheduler` | 4 | 1 | 32 | 308 | 23,331 |
| `titan_x5_skid_buffer` | 2 | 2 | 8 | 6 | 598 |
| `titan_x5_coherent_xbar` | 1 | 1 | 25 | 191 | 72,656 |
| `titan_x5_command_processor` | 1 | 1 | 16 | 26 | 8,711 |
| `titan_x5_crossbar` | 1 | 1 | 18 | 607 | 14,955 |
| `titan_x5_display_engine` | 1 | 1 | 23 | 51 | 865 |
| `titan_x5_dma_engine` | 1 | 1 | 19 | 28 | 1,185 |
| `titan_x5_flush_ctrl` | 1 | 1 | 10 | 9 | 73 |
| `titan_x5_gddr7_pam3_phy` | 1 | 1 | 9 | 1 | 4,793 |
| `titan_x5_gpu_top` | 1 | 1 | 43 | 31 | 55,848 |
| `titan_x5_l2_cache` | 1 | 1 | 18 | 184 | 4,322,482 |
| `titan_x5_l2_mem_adapter` | 1 | 1 | 16 | 29 | 30,109 |
| `titan_x5_mem_controller` | 1 | 1 | 50 | 41 | 4,094 |
| `titan_x5_neural_shader_dispatch` | 1 | 1 | 14 | 10 | 1,476 |
| `titan_x5_perf_counters` | 1 | 1 | 6 | 33 | 5,101 |
| `titan_x5_power_mgmt` | 1 | 1 | 9 | 2 | 60 |
| `titan_x5_rasterizer` | 1 | 1 | 21 | 553 | 27,033 |
| `titan_x5_ray_box_isect` | 1 | 1 | 21 | 38 | 8,765 |
| `titan_x5_ray_triangle_isect` | 1 | 1 | 25 | 162 | 23,521 |
| `titan_x5_rt_core` | 1 | 1 | 30 | 68 | 38,062 |
| `titan_x5_sr_engine` | 1 | 1 | 11 | 65 | 4,099 |
| `titan_x5_vertex_transformer` | 1 | 1 | 14 | 210 | 15,048 |

---

## 3. Hierarchy

```
titan_x5_gpu_top
    titan_x5_async_fifo
    titan_x5_async_fifo
    titan_x5_async_fifo
    titan_x5_async_fifo
    titan_x5_coherent_xbar
    titan_x5_command_processor
    titan_x5_crossbar
    titan_x5_display_engine
        titan_x5_async_fifo
    titan_x5_dma_engine
    titan_x5_flush_ctrl
    titan_x5_gddr7_pam3_phy
    titan_x5_l2_cache
    titan_x5_l2_mem_adapter
    titan_x5_mem_controller
    titan_x5_neural_shader_dispatch
    titan_x5_perf_counters
    titan_x5_power_mgmt
    titan_x5_rasterizer
    4 x titan_x5_rop
    titan_x5_rt_core
        titan_x5_ray_box_isect
        titan_x5_ray_triangle_isect
    4 x titan_x5_sm
        32 x titan_x5_alu
            titan_x5_fp32_add
            titan_x5_fp32_fma
            titan_x5_fp32_mul
            titan_x6_tensor_core_array
                16 x mac_pe
                    4 x fp32_add
                    4 x fp4_mul_to_fp32
                    fp8_mul_to_fp32
                    titan_x5_fp16_mul
        titan_x5_l1_cache
        titan_x5_lsu
        titan_x5_pc_unit
        titan_x5_pipeline
            titan_x5_decoder
        titan_x5_register_file
        titan_x5_warp_scheduler
    titan_x5_sr_engine
        titan_x5_skid_buffer
        titan_x5_skid_buffer
    4 x titan_x5_tmu
        titan_x5_l1_cache
    titan_x5_vertex_transformer
```

---

## 4. Pinout

43 ports, 1,338 bits.

| Dir | Width | Name |
|:--|:--|:--|
| input | `1` | `clk` |
| input | `1` | `mem_clk` |
| input | `1` | `pclk` |
| input | `1` | `rst_n` |
| input | `[31:0]` | `host_ring_base` |
| input | `[31:0]` | `host_ring_wptr` |
| output | `[31:0]` | `host_ring_rptr` |
| output | `1` | `host_intr` |
| output | `[3:0]` | `vram_arid` |
| output | `[31:0]` | `vram_araddr` |
| output | `[7:0]` | `vram_arlen` |
| output | `[2:0]` | `vram_arsize` |
| output | `[1:0]` | `vram_arburst` |
| output | `1` | `vram_arvalid` |
| input | `1` | `vram_arready` |
| input | `[3:0]` | `vram_rid` |
| input | `[511:0]` | `vram_rdata` |
| input | `[1:0]` | `vram_rresp` |
| input | `1` | `vram_rlast` |
| input | `1` | `vram_rvalid` |
| output | `1` | `vram_rready` |
| output | `[3:0]` | `vram_awid` |
| output | `[31:0]` | `vram_awaddr` |
| output | `[7:0]` | `vram_awlen` |
| output | `[2:0]` | `vram_awsize` |
| output | `[1:0]` | `vram_awburst` |
| output | `1` | `vram_awvalid` |
| input | `1` | `vram_awready` |
| output | `[511:0]` | `vram_wdata` |
| output | `[63:0]` | `vram_wstrb` |
| output | `1` | `vram_wlast` |
| output | `1` | `vram_wvalid` |
| input | `1` | `vram_wready` |
| input | `[3:0]` | `vram_bid` |
| input | `[1:0]` | `vram_bresp` |
| input | `1` | `vram_bvalid` |
| output | `1` | `vram_bready` |
| output | `1` | `vga_hsync` |
| output | `1` | `vga_vsync` |
| output | `[7:0]` | `vga_r` |
| output | `[7:0]` | `vga_g` |
| output | `[7:0]` | `vga_b` |
| output | `1` | `vga_de` |

---

## 5. Word crossbar master map

Parsed from the master-assignment comments in the top level.

| Port | Client |
|:--|:--|
| 0 | command processor |
| 1-4 | tmus |
| 5-8 | rops |
| 9-12 | sm i-caches |
| 13 | now free. L2 backing-store traffic used to be serialised into |
| 14-16 | reserved (previously per-SM scalar D-cache ports) |
| 17 | dma engine |
| 18 | rt core |

---

## 6. Instruction set

Read from `driver/titan_x6_isa.h`, which is the ISA's definition of
record: the compiler, the C functional model and the RTL decoder are
all written against it.

```
 [31:27] opcode   [26:21] rd   [20:15] rs1   [14:9] rs2
 [8:3] rs3/imm12  [2:1] pred   [0] use_imm
```

| # | Mnemonic | Notes |
|--:|:--|:--|
| 0 | `ADD` | rd = rs1 + (imm \| rs2) |
| 1 | `SUB` | rd = rs1 - (imm \| rs2) |
| 2 | `MUL` | rd = (rs1 * rs2)[31:0] |
| 3 | `MULHI` | rd = (rs1 * rs2)[63:32] (signed) |
| 4 | `DIV` | rd = rs1 / rs2 (signed) |
| 5 | `AND` |  |
| 6 | `OR` |  |
| 7 | `XOR` |  |
| 8 | `SHL` |  |
| 9 | `SHR` | logical |
| 10 | `SRA` | arithmetic |
| 11 | `SLT` | rd = (rs1 < rs2) ? 1 : 0 (signed) |
| 12 | `SLTU` |  |
| 13 | `MIN` |  |
| 14 | `MAX` |  |
| 15 | `FMA` | rd = rs1 * rs2 + rs3 (integer) |
| 16 | `FADD` | fp32 |
| 17 | `FMUL` | fp32 |
| 18 | `FMIN` |  |
| 19 | `FMAX` |  |
| 20 | `CVT` | rs3[0]=0: int->fp32, 1: fp32->int |
| 21 | `SETP` | set predicate, see below |
| 22 | `LOAD` | rd = mem32[rs1 + (imm \| rs2)] |
| 23 | `STORE` | mem32[rs1 + (imm \| rs2)] = rd |
| 24 | `BRANCH` | pc = imm (absolute instr index); honors pred |
| 25 | `BARRIER` | imm == 0xFFF => EXIT (end of kernel thread) |
| 26 | `WMMA` | tensor tile op, see below |
| 27 | `SIN` |  |
| 28 | `COS` | Slot 29 was RSQRT. RSQRT was assigned here and implemented in the C |
| 29 | `FFMA` | fp32 fused multiply-add: rd = rs1*rs2 + rs3 |
| 30 | `ATOM_ADD` | rd = old mem32[rs1]; mem32[rs1] += rs2 |
| 31 | `ATOM_CAS` | rd = old; if (old == rs2) mem32[rs1] = rs3 |

Three encoding facts have each caused a real bug in this project:

- **`BRANCH` is unconditional**, gated only by its predicate. It does
  *not* read rs1, and its target is an **absolute instruction index**.
- **`BARRIER` with `use_imm` and `imm == 0xFFF` is EXIT.** A plain
  `BARRIER` is thread sync.
- **`SETP`'s `rd` field is `{cond[2:0], pdst[1:0]}`**, not a register
  index. `cond` selects one of six `TX6_CMP_*` comparisons.

Predicates are per-warp P0..P3, each a **32-bit per-lane mask**; P0 is
hardwired all-ones. There is **no reconvergence stack**: `titan_x5_sm`
executes only on a uniformly-true predicate and raises the sticky
`dbg_pred_divergent` flag on a mixed mask, while `titan_x7_sm` applies
the predicate as a per-lane write mask.

---

## 7. Things the block diagram would mislead you about

- **Only ROP 0 receives fragments.** ROPs 1-3 are instantiated with
  `i_valid(16'b0)` and never paint.
- **The ROP has no per-fragment shader dispatch.** It latches the
  shader's most recent R63 export and paints whatever the rasterizer
  hands it, so a fragment's colour is "the most recent export", not
  "the shader result for this fragment".
- **There is no instruction cache.** Each SM fetches single 32-bit
  words on crossbar masters 9-12, one outstanding at a time. Measured:
  8 warps versus 1 pushed the render test from 8,009 to 10,009 cycles
  on fetch contention alone.
- **The four TMU L1s are read-only** (`core_req_write` tied low), so
  they contribute invalidation but never a writeback.
- **`titan_x5_gddr7_pam3_phy` is not a PHY.** It contains
  `assign tx_ready = 1'b1;`. A real memory PHY is transistor-level
  analog IP -- DLLs, per-bit deskew, training -- licensed, not written.

---

## 8. In `rtl/`, but NOT in the chip

**31 of 81 modules** in `rtl/` are not reachable
from the top level in either SM build. Some are verified blocks waiting
to be connected, some are scaffolding for a larger part. A reader
looking at the directory listing would reasonably assume otherwise,
which is why this section is generated rather than remembered.

| Module | File |
|:--|:--|
| `titan_apex_dp_mac` | `rtl/tensor/titan_apex_dp_mac.v` |
| `titan_apex_fma_lane` | `rtl/fpu/titan_apex_fma_lane.v` |
| `titan_apex_hbm4_ctrl` | `rtl/memory/titan_apex_hbm4_ctrl.v` |
| `titan_apex_mult_seg` | `rtl/tensor/titan_apex_mult_seg.v` |
| `titan_x5_2048_alu` | `rtl/crypto/titan_x5_2048_alu.v` |
| `titan_x5_2048_mul` | `rtl/crypto/titan_x5_2048_mul.v` |
| `titan_x5_2048_regfile` | `rtl/crypto/titan_x5_2048_regfile.v` |
| `titan_x5_apex_sr_engine` | `rtl/titan_x5_apex_sr_engine.v` |
| `titan_x5_axi4_lite` | `rtl/interconnect/titan_x5_axi4_lite.v` |
| `titan_x5_fp32_add_comb` | `rtl/fpu/titan_x5_fp32_add_comb.v` |
| `titan_x5_hash_fnv64` | `rtl/sr/titan_x5_hash_fnv64.v` |
| `titan_x5_hbm3_controller` | `rtl/memory/titan_x5_hbm3_controller.v` |
| `titan_x5_mesh_router` | `rtl/interconnect/titan_x5_mesh_router.v` |
| `titan_x5_noc_mesh` | `rtl/interconnect/titan_x5_noc_mesh.v` |
| `titan_x5_noc_router` | `rtl/interconnect/titan_x5_noc_router.v` |
| `titan_x5_shared_memory` | `rtl/memory/titan_x5_shared_memory.v` |
| `titan_x5_tensor_core` | `rtl/tensor/titan_x5_tensor_core.v` |
| `titan_x5_vram_ctrl` | `rtl/memory/titan_x5_vram_ctrl.v` |
| `titan_x6_banked_l2` | `rtl/titan_x6_banked_l2.v` |
| `titan_x6_gpc` | `rtl/titan_x6_gpc.v` |
| `titan_x6_gpu_top` | `rtl/titan_x6_gpu_top.v` |
| `titan_x6_noc_mesh` | `rtl/interconnect/titan_x6_noc_mesh.v` |
| `titan_x6_noc_router` | `rtl/interconnect/titan_x6_noc_router.v` |
| `titan_x6_tpc` | `rtl/titan_x6_gpc.v` |
| `titan_x6_ucie_phy` | `rtl/interconnect/titan_x6_ucie_phy.v` |
| `titan_x6_vram_ctrl` | `rtl/titan_x6_vram_ctrl.v` |
| `titan_x6_wmma_dispatch` | `rtl/tensor/titan_x6_wmma_dispatch.v` |
| `titan_x7_regfile_banked` | `rtl/core/titan_x7_regfile_banked.v` |
| `titan_x7_sram_1r1w` | `rtl/memory/titan_x7_sram_1r1w.v` |
| `titan_x7_tensor_array` | `rtl/tensor/titan_x7_tensor_array.v` |
| `titan_x7_tensor_pe` | `rtl/tensor/titan_x7_tensor_pe.v` |

