# Phase 2: Open-Source ASIC Physical Design — Status Report

*2026-07-07 — produced with Claude Fable 5. Flow: OpenLane 2.3.10 (Classic,
78 stages) on the SkyWater sky130A PDK (`sky130_fd_sc_hd`), run inside WSL
Ubuntu-24.04 via Docker. All numbers are measured from `metrics.json` of
completed runs; artifacts under `openlane/<design>/final/`.*

## 1. What was achieved

Two Titan X5-B macros carried through the **complete RTL → GDSII flow**
(synthesis, floorplan, placement, CTS, routing, and signoff: magic DRC,
KLayout DRC, XOR, SPICE extraction, netgen LVS, multi-corner STA):

| | `titan_x5_fp32_fma` | `titan_x6_tensor_core_array` (4×4 FP16 PEs) |
|---|---|---|
| Std cells | 12,575 | 149,909 |
| Die area | 0.234 mm² | 2.70 mm² |
| Clock | 25 ns (40 MHz) | 65 ns (~15.4 MHz) |
| Setup WS (tt) | **+10.22 ns** | **+23.92 ns** |
| Setup WS (ss/1.60 V) | met | **−4.29 ns** (see §3) |
| Hold WS (worst corner) | +0.32 ns | +0.11 ns |
| Magic DRC | **0** | **0** |
| LVS | **0 errors** | **0 errors** |
| Antenna nets | 5 | 124 |
| Est. power | ~20 mW | ~0.8 W |
| GDS | `final/` (committed) | `final/` (280 MB, not in git — regenerate via `run_macro.sh`) |

A third macro, `titan_x5_rasterizer` (~21k LUT-eq on FPGA, pure logic), uses
the same config pattern; run it with
`wsl -d Ubuntu-24.04 -u root -- /root/go_raster.sh`.

## 2. How to reproduce

```bash
# from Windows
powershell Start-Process wsl.exe -ArgumentList '-d','Ubuntu-24.04','-u','root','--','/root/go_tensor.sh'
# progress
wsl -d Ubuntu-24.04 -u root -- bash -c "tail /var/log/ol_titan_x6_tensor_core_array.log"
# signoff summary
wsl -d Ubuntu-24.04 -u root -- bash -c "/root/report_metrics.sh titan_x6_tensor_core_array"
```

`openlane/run_macro.sh` (master copy; installed at `/root/run_macro.sh`)
mirrors `rtl/` + `openlane/` to native ext4, runs the dockerized flow, and
rsyncs the run back. See `openlane/README.md` for the one-time toolchain
setup and the host quirks (drvfs crashes, WSL memory, argv mangling).

## 3. Honest caveats on the tensor macro

- **Slow-corner setup misses by 4.29 ns** (ss/100 °C/1.60 V) at the 65 ns
  clock; typical corner has +23.9 ns of margin. Full multi-corner closure
  needs either a ~70 ns clock or — properly — **pipelining the PE**: each
  processing element evaluates an FP16 multiply plus FP32 adds
  combinationally in a single cycle, which is the entire critical path.
- **124 antenna-violating nets** remain after repair (vs 5 on the FMA);
  another repair iteration or `DIODE_ON_PORTS` tuning would clean these.
- **KLayout DRC reports 18 `npc.2`** violations; these are known false
  positives of the KLayout sky130 deck around tap rows — magic, the PDK's
  reference checker, reports 0 and is the hard gate
  (`ERROR_ON_KLAYOUT_DRC=false`, justified in the config).
- Slow-corner slew warnings (1,299 at ss) accompany the setup shortfall
  and would resolve with the same fixes.

## 4. Flow engineering findings (cost real debugging time)

1. **OpenROAD SIGABRTs on drvfs**: its database writer cannot run on the
   Windows-mounted filesystem; all runs execute on native ext4.
2. **yosys's SAT-based `share` pass explodes** on the flattened 16-PE
   array: OOM-killed at 11.5 GB and again at 32.7 GB total-vm.
   `SYNTH_SHARE_RESOURCES` is declared but **not honored** by OpenLane
   2.3.10's pyosys script; `SYNTH_HIERARCHY_MODE=deferred_flatten` is the
   effective fix (per-module optimization, flattening deferred to ABC).
3. WSL memory raised to 16 GB + 16 GB swap via `C:\Users\singb\.wslconfig`
   (host: 23.7 GB; delete the file to revert).

## 5. Path to a full-chip GDSII

Blocked, in order of severity:

1. **L1/L2 caches must be rewritten around SRAM macros** (OpenRAM or
   DFFRAM): as written, their multi-dimensional arrays with way-parallel
   combinational lookups flatten to registers — synthesis alone exhausts
   host memory (see `docs/FPGA_PHASE1_REPORT.md` §5). This is the same
   rewrite Phase 1 needs for BRAM, one effort serving both targets.
2. **Hierarchical assembly**: with macros hardened (LEF/GDS per subsystem),
   the top level integrates them as black boxes. OpenLane 2 supports
   `MACROS` for this; the l2/sm macros gate the useful version of it.
3. **Host capacity**: LSU/TMU-class blocks (~100k+ LUT-eq each) synthesize
   fine hierarchically, but a flat full-GPU run is far beyond a 16 GB
   WSL instance; macro-by-macro hardening is the only viable route here —
   which is also the methodology the roadmap prescribes.
