# ASIC readiness: where this design actually stands

*2026-08-12. Every number here comes from a command that ran on this machine.*

```bash
python tools/asic_lint.py            # the gate
python tools/asic_lint.py --detail   # every finding
```

This document exists because "is it ready for fabrication" deserves a measured
answer rather than an optimistic one. The short version: the design is a
working, verified *architecture* and is not close to a tapeout, and the gap is
mostly things nobody has started rather than things that are nearly done.

---

## 1. The finding that matters most: the lint gate was not running

`rtl/core/titan_x7_sm.v` contained a prose comment whose second line began
with the linter's own name:

```verilog
// blocking assigns: reset-only array init (see L2 note on
// Verilator BLKLOOPINIT)
```

Verilator parses **any** comment beginning with its name as a metacomment
pragma. That sentence became `/*verilator BLKLOOPINIT)*/`, an unknown pragma,
and **v5 aborted the entire lint before checking a single line**. The CI job
pins v4, which does not, so lint stayed green while checking nothing.

The identical trap had already been hit once, in
`rtl/memory/titan_x5_l1_cache.v`, where a comment warning about it survives.
The same mistake was still live in the X7 SM.

Fixed. Everything below is the first real lint this design has had.

There is a second reason nothing was being checked: the command in
`HANDOFF_NEXT_SESSION.md` passes `-Wno-LATCH`, `-Wno-UNDRIVEN` and
`-Wno-SYNCASYNCNET`. Those are not style preferences — an inferred latch, a net
with no driver and a reset flopped in two domains are three of the most common
reasons a chip comes back dead. `tools/asic_lint.py` enables them and treats
them as blockers.

## 2. Measured: 77 files, top `titan_x5_gpu_top`

| severity | first run | after the fixes below | |
|---|---:|---:|---|
| **BLOCKER** | **8** | **0** | UNDRIVEN x7, SYNCASYNCNET x1 |
| SERIOUS | 76 | 75 | PINMISSING, WIDTHTRUNC, MULTIDRIVENPROC, BLKSEQ |
| COSMETIC | 88 | 88 | WIDTHEXPAND |

All eight blockers are fixed and the full regression still passes. What follows
is what each one was, because the *kind* of defect matters more than the count.

### The blockers

**Seven undriven nets.** On silicon these are X, not zero:

| signal | file |
|---|---|
| `cmd_payload[31:0]` | `titan_x5_gpu_top.v:91` |
| `cmd_mem_data[31:0]` | `titan_x5_gpu_top.v:194` |
| `gddr7_rx_pins` | `titan_x5_gpu_top.v:1025` |
| `dcc_req`, `dcc_we`, `dcc_addr`, `dcc_wdata` | `titan_x5_rop.v:56-59` |

The ROP four are the clearest defect: a delta-colour-compression metadata
interface is declared `output reg` and **never assigned anywhere in the
module**. Those pins drive X forever. The interface is dead silicon.

**One reset-domain crossing.** `rst_n` in `titan_x5_gpu_top` is flopped both
synchronously and asynchronously. This is the same class as the display-path
defect in `FPGA_BRINGUP_NO_BOARD.md` finding 1, and it is the one that would
bite hardest without configuration to mask it.

### What is *not* as bad as it looks

`MULTIDRIVENPROC` reads alarming at 19. All nineteen are shared `integer` loop
indices — `r`, `c`, `i`, `w`, `k`, `s` declared once and reused across always
blocks. Synthesis unrolls those; they are a portability and hygiene problem,
not two drivers on a wire. Calling them tapeout blockers would be wrong.

Likewise `BLKSEQ` x5: four are the documented reset-only array-init pattern in
the L1/L2 caches, which is safe because it only ever runs under reset. The
`titan_x5_lsu.v:210` one has not been triaged.

`WIDTHTRUNC` x26 is the category most likely to hide a real bug — silent bit
loss, concentrated in `titan_x5_vertex_transformer.v` (10) and
`titan_x5_rop.v` (5). None of these has been individually reviewed yet.

---

### What each fix was

**`cmd_payload` — a real wiring bug, not a tie-off.** `titan_x5_command_processor`
*has* a `cmd_payload[55:0]` output. `titan_x5_gpu_top` never connected it, while
a top-level wire of the same name fed the RT core's `ray_root_ptr`. So the RT
core was reading a net with no driver at all. Connecting the port fixes both the
UNDRIVEN and one of the PINMISSING findings.

**`cmd_mem_data` — dead wire on a live bus.** It drove
`xbar_m_req_wdata[31:0]` while nothing drove it. The command processor has no
write-data output — it only fetches command packets, and `xbar_m_req_write[0]`
is tied low — so the wire was deleted and the write data tied to a defined
constant. X on a write bus is not harmless just because the write strobe is low.

**ROP DCC — an interface that was never built.** `dcc_req`, `dcc_we`,
`dcc_addr` and `dcc_wdata` are `output reg` and were assigned nowhere in the
module. The top level leaves them unconnected and ties `cfg_dcc_en` low, which
hid it in simulation. Now driven to their inactive state in the reset branch,
with a comment saying plainly that delta-colour compression is not implemented.

**`gddr7_rx_pins`** is the PHY's receive path with no DRAM model behind it.
Tied to a defined value; on silicon these are input pads fed from the package.

**The reset-domain crossing — fixed properly, not silenced.** Every clocked
block in this design resets asynchronously (132 of them) except two in
`titan_x5_gddr7_pam3_phy.v`, which used `rst_n` synchronously in the `clk_28g`
domain. Adding `or negedge rst_n` would have traded one defect for another: the
release edge would then land at an arbitrary point relative to `clk_28g`, which
is metastable. So that domain got a **reset synchroniser** — asserted
asynchronously, released synchronously to `clk_28g` — which is the standard
construction and the same fix the display path needs.

One of those two PHY blocks also had **no reset at all**: `pam3_chunk` powered
up undefined and drove X onto the DQ encoder until the first `tx_valid`. Reset
added.

The synchroniser then trips SYNCASYNCNET on itself, because a synchroniser is
async-reset with a synchronous feedback chain by definition and every correct
one looks like that. It carries a **five-line scoped waiver with a written
justification**, not a global suppression — the check stays armed everywhere
else, where a hit means a real hazard.

## 3. The honest gap to a tapeout

Lint is the first gate of perhaps fifteen. Status of the rest:

| signoff gate | status |
|---|---|
| RTL lint | **first run just happened; 8 blockers open** |
| Functional verification | regression 34/34, compute suite 15/15, ISA conformance 78 checks — real, but coverage is **unmeasured** |
| Code/functional coverage | **not started** — no coverage database exists |
| Assertion-based verification | **not started** — no SVA anywhere |
| Formal property checking | **not started** |
| CDC analysis | **not started**; one RDC found by lint, none analysed systematically |
| Reset architecture review | **one defect found and open** (display path), one flagged by lint |
| X-propagation analysis | **not started** |
| Synthesis at target frequency | full-chip synth runs (~604k cells) but **no timing constraints exist** |
| Static timing analysis | **impossible here** — no OpenSTA in this install |
| DFT: scan insertion, ATPG | **not started** — no scan chains, no test ports |
| Memory BIST | **not started** |
| Power intent (UPF/CPF) | **not started** |
| Place and route | blocked (see below) |
| DRC / LVS / antenna | **not started** |
| SRAM | **blocked: the GT2N PDK contains no SRAM at all** |

### Two hard blockers that are not about effort

**The GT2N 2 nm PDK has no SRAM.** No bitcell, no macro, no memory compiler.
The register file, the L1s and the L2 therefore synthesise to flip-flops, which
is not a chip anyone fabricates. Until a memory compiler or a vendor macro
exists for this node, the memory hierarchy cannot be implemented as designed,
and **no SRAM area or timing figure can be measured** — only modelled, which
this project does not accept.

**No place-and-route on this machine.** OpenLane and sky130 are multi-GB and
out of scope; `nextpnr` ships no Xilinx target here; there is no OpenSTA. So
whether anything closes timing at any frequency is **unknown and unmeasured**.

### And one that is about scope

`titan_x6_gpu_top` is a scaffold — its GPCs are not connected to its L2
(`assign l2_req_addr = 0;`). `titan_x5_hbm3_controller.v` is instantiated
nowhere. `titan_x5_shared_memory`, `titan_x5_ray_triangle_isect` and
`titan_x5_hash_fnv64` are not in the GPU hierarchy at all. The RT core is
instantiated but unreachable: **the ISA has no ray-tracing opcode**, which is
why `docs/RAYTRACING_ON_TITAN.md` traces in software.

Any claim about those blocks is a claim about files, not about a chip.

---

## 4. What to do next, in order

1. **Fix the 8 blockers.** The ROP's dead DCC interface and the two undriven
   `cmd_*` buses are contained and mechanical. The reset-domain crossings are
   an architecture decision: one reset synchroniser per clock domain, asserted
   asynchronously and released synchronously to that domain.
2. **Triage the 26 WIDTHTRUNC.** This is where a silent functional bug is most
   likely to be hiding.
3. **Write timing constraints.** An SDC with clock definitions and I/O delays
   is the prerequisite for every timing statement this project might want to
   make. Without it, "604k cells" is a size, not a result.
4. **Measure verification coverage.** The suites pass; nobody knows what
   fraction of the design they touch. That number decides whether "verified"
   means anything.
5. **Then** consider physical implementation, and only on a node whose PDK has
   memory.

## 5. What this design honestly is

A working GPU architecture with a real ISA, a real compiler, a real driver
model, and — unusually for a hobby project — a genuine verification culture:
mutation-tested tests, control-experimented fixes, and a documented history of
defects found and fixed rather than quietly patched. Compiled kernels run on
the RTL bit-exactly against an independent model. That is a substantial and
uncommon achievement.

It is not a fabricable chip, and the distance is measured in the gates listed
in section 3 rather than in polish.
