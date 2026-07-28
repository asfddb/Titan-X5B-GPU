# Titan: scaling toward 128 GB VRAM

**Target as stated:** a real GPU with 128 GB of VRAM at ~1000 W.

This document separates that into the part that is buildable and verifiable
here, and the part that is not — and says which is which, with measurements
rather than estimates. Every number below was produced by running something in
this repo. Where a number is not measured, it is marked as unknown rather than
filled in.

---

## 1. What was actually blocking 128 GB

Not the memory controller. **The address path.**

Every address interface in the design is 32 bits wide:

```
rtl/memory/titan_x5_lsu.v            ADDR_WIDTH = 32
rtl/memory/titan_x5_l1_cache.v       ADDR_WIDTH = 32
rtl/interconnect/titan_x5_crossbar.v ADDR_WIDTH = 32
rtl/memory/titan_x5_l2_cache.v       ADDR_WIDTH = 32
rtl/titan_x6_banked_l2.v             ADDR_WIDTH = 32
rtl/titan_x6_vram_ctrl.v             AXI_ADDR_WIDTH = 32
rtl/titan_x5_gpu_top.v               vram_araddr / vram_awaddr  [31:0]
```

2³² = **4 GiB**. That is a hard ceiling regardless of how much physical memory
is attached, and it is 32× short of 128 GB.

`rtl/memory/titan_x5_hbm3_controller.v` is declared at 33 bits (8 GB per
stack), but it is **not instantiated in any top level** — the tops use the
32-bit `titan_x6_vram_ctrl`. So the widest thing in the repo was not in the
data path at all.

### The good news, measured

The memory modules are already properly parameterised. Counting hardcoded
32-bit address literals versus uses of the `ADDR_WIDTH` parameter:

| Module | hardcoded `[31:0]` | uses `ADDR_WIDTH` |
|:--|--:|--:|
| `titan_x5_lsu.v` | 0 | 4 |
| `titan_x5_l1_cache.v` | 0 | 5 |
| `titan_x5_l2_cache.v` | 0 | 3 |
| `titan_x5_l2_mem_adapter.v` | 0 | 3 |
| `titan_x5_crossbar.v` | 0 | 8 |
| `titan_x6_banked_l2.v` | 0 | (fully parameterised) |

The width is pinned by *instantiation*, not by the modules. Widening is
therefore a parameter and port-width change, not a rewrite.

---

## 2. What has been built and verified

**The L2 cache hierarchy now addresses 128 GiB**, verified by simulation.

- `tb/tb_l2_top.v` instantiates `titan_x6_banked_l2` with `ADDR_WIDTH(37)`
  (2³⁷ = 128 GiB).
- New test `test_l2_128gib_addressing` in `tb/uvm/test_l2.py` writes distinct
  data to lines at 4, 5, 32, 64, 96 and ~127 GiB, then reads every one back and
  requires byte-exact data.
- The addresses are chosen adversarially: several pairs share identical low 32
  bits and differ only above bit 32. On a truncating path they collapse onto the
  same line and return each other's data.

**Control experiment** (the test is not vacuous): reverting the DUT to
`ADDR_WIDTH(32)` while keeping the same test makes it fail with exactly the
aliasing it is designed to catch —

```
AssertionError: low control <4GiB @ 0x50000 (0.0 GiB):
  got 0x5f2dd97f... exp 0x5bc8fbbc... -- address truncated or aliased
```

Restoring 37 bits passes. Full regression: **12/12 suites PASS**.

### Measured cost of the widening

Yosys, `titan_x5_l2_cache` (LINE_SIZE 16, SETS 16, WAYS 8, BANKS 4):

| `ADDR_WIDTH` | Addressable | Cells | Wire bits |
|--:|--:|--:|--:|
| 32 | 4 GiB | 101,451 | 102,123 |
| 37 | 128 GiB | 104,713 | 105,400 |
| **delta** | **32×** | **+3,262 (+3.2%)** | +3,277 |

This is consistent with the structure rather than coincidental: 16 sets × 8
ways × 4 banks = 512 lines, each needing 5 more tag bits ≈ 2,560 extra flops,
plus wider tag comparators. **32× the address space for ~3% more logic** — the
tag array is a small fraction of a cache dominated by data storage.

---

## 3. The limit this exposes: 32-bit registers

Widening the *physical* path is necessary but not sufficient. Titan's
architectural registers are 32 bits (`rtl/core/titan_x5_register_file.v`, and
the ISA in `driver/titan_x6_isa.h` — `LOAD` is `rd = mem32[rs1 + imm]`).

**A thread cannot compute an address larger than 4 GiB.** Sixty-four-bit
addressing would require widening the register file, the ALU address path, the
LSU's per-lane address vector (currently 32 lanes × 32 bits), and the ISA's
operand model — a far larger change than the physical path.

Two real options, both used by shipping hardware:

1. **Aperture / base register.** Threads compute 32-bit offsets; a
   per-context 37-bit base is added at the LSU output, so L1 and L2 tag on
   physical addresses and nothing aliases. A kernel sees a 4 GiB window that
   can sit anywhere in 128 GiB. This is how pre-64-bit GPUs handled large
   frame buffers. Small, contained change.
2. **Full 64-bit addressing.** What modern GPUs do. Correct long-term, but it
   touches the register file, ALU, LSU, ISA, compiler, driver and functional
   model together.

Option 1 is the honest next step; option 2 is the honest end state.

---

## 4. What is *not* buildable here, stated plainly

**128 GB of physical VRAM and a 1000 W part cannot be built in this project.**
Not "hard" — not reachable:

- 128 GB at that bandwidth means **HBM3e**, roughly 8 stacks. HBM cannot be
  soldered to a PCB; it requires a silicon interposer (**CoWoS** or
  equivalent) with the die. Interposer capacity is allocated years ahead to
  a handful of customers.
- 1000 W at ~0.8 V core is **>1000 A**. That needs a 40+ phase VRM, an OAM/SXM
  form factor and direct-liquid cooling — a power-delivery and thermal
  engineering programme in its own right.
- The compute density implied requires a leading-edge node (4 nm class).
  A mask set alone is tens of millions of dollars; a full programme is a
  multi-year effort by a large team.
- This repo's hardened blocks are on **sky130, a 130 nm open PDK** (~2005-era).
  The gap to 4 nm is roughly four orders of magnitude in density.

**I have not estimated a TFLOPS or a wattage for this design, because nothing
in this repo measures either.** There is no power-analysis flow here, no
timing-closed frequency for the full chip, and no silicon. Any such figure
would be invented, so none is given. If those numbers are wanted, the way to
earn them is listed in §5.

---

## 5. Deep build plan — what actually gets closer

Ordered so each step ends in something re-runnable.

### Step 1 — finish the physical address path ✅ *(L2 done)*
- [x] `titan_x6_banked_l2` + `titan_x5_l2_cache` at 37 bits, verified, measured.
- [ ] Widen `titan_x5_lsu`, `titan_x5_l1_cache`, `titan_x5_crossbar`,
      `titan_x5_l2_mem_adapter`, `titan_x5_mem_controller` to a single
      `PADDR_W` parameter threaded from the top.
- [ ] Widen `titan_x5_gpu_top` VRAM ports and the testbench AXI model.
- **Gate:** the full-chip render test passes with `PADDR_W = 37` and the
  framebuffer placed above 4 GiB — which no 32-bit design can do.

### Step 2 — aperture base register
- [ ] 37-bit `vram_base` applied at the LSU output; L1/L2 tag physically.
- [ ] Command processor writes it at dispatch.
- **Gate:** two kernels with the same 32-bit offsets but different bases read
  and write disjoint physical memory, verified against a sparse memory model.

### Step 3 — real HBM path
- [ ] Instantiate `titan_x5_hbm3_controller` (currently in no top level) behind
      the L2, widened past its 33-bit declaration.
- [ ] Model N stacks with independent pseudo-channels; verify address
      interleaving across stacks preserves data.
- **Gate:** cycle-accurate sim shows correct data across all stacks, and
  measured achieved bandwidth in bytes/cycle is reported from the simulation —
  a real number, not a datasheet number.

### Step 4 — earn the performance numbers
Until this step, the design has no defensible TFLOPS or watts.
- [ ] Close timing on a real target to get a defensible frequency (FPGA first —
      `syn/` already reports per-block area on sky130).
- [ ] Run a power-analysis flow (OpenSTA/OpenROAD power, or vendor tools on
      FPGA) against real switching activity from simulation VCDs — `bin/parse_vcd.py`
      already exists for this.
- **Gate:** a stated FLOPS and watt figure, each traceable to a command in
  this repo.

### Step 5 — real silicon, right-sized
- [ ] One SM plus caches through OpenLane as a single routed die.
- [ ] A shuttle (TinyTapeout / Efabless-class) for a genuinely manufactured
      block.
- **Gate:** DRC/LVS-clean GDSII of an integrated GPU, and eventually a part
  that physically exists.

---

## 6. Honest summary

| Claim | Status |
|:--|:--|
| L2 hierarchy addresses 128 GiB | **Verified in simulation**, control-tested, cost measured |
| Widening costs ~3.2% cells in the L2 slice | **Measured** (Yosys, both configs) |
| Full GPU addresses 128 GB | **Not yet** — LSU/L1/crossbar/top still 32-bit (Step 1) |
| A thread can address >4 GiB | **No** — 32-bit registers; needs aperture or 64-bit ISA |
| 128 GB of physical VRAM exists | **No** — requires HBM3e + CoWoS interposer |
| Runs at 1000 W | **Unknown and unmeasured** — no power flow in this repo |
| Performance in FLOPS | **Unknown and unmeasured** — no timing-closed frequency |

The first two rows are real engineering results. The rest are the honest
distance still to cover, and §5 is the order to cover it in.
