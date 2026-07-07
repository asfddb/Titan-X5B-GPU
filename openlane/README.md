# Titan X5-B — OpenLane / SkyWater sky130 ASIC Flow (Phase 2)

Macro-hardening workspace for proving the Titan X5-B RTL through a real
standard-cell ASIC flow (synthesis → floorplan → place → CTS → route →
GDSII) on the open SkyWater 130 nm PDK.

## Prerequisites (inside WSL Ubuntu, this repo mounted at /mnt/c/...)

```bash
# one-time setup (a root script performs exactly this; see /var/log/openlane_setup.log)
python3 -m venv ~/olenv
~/olenv/bin/pip install openlane          # OpenLane 2
dockerd &                                  # WSL has no systemd; start manually
~/olenv/bin/openlane --dockerized --smoke-test
```

The first `--dockerized` run downloads the OpenLane tool image (~3 GB) and
the sky130 PDK via volare (~2 GB) to `~/.volare`.

## Running a macro

```bash
cd /mnt/c/Users/singb/Downloads/gpuuhj
~/olenv/bin/openlane --dockerized openlane/titan_x5_fp32_fma/config.json
```

Results land in `openlane/<design>/runs/<timestamp>/final/` — `gds/` holds
the GDSII, `metrics.json` the PPA numbers.

## Hardening order

| # | Macro | Why | Status |
|---|---|---|---|
| 1 | `titan_x5_fp32_fma` | small (1.4k LUT-eq / 2.3k cells FPGA-measured), single clock, proves the flow end to end | **GDS, DRC/LVS clean** — 12,575 cells, 0.23 mm², setup WS +10.2 ns @ 40 MHz, `final/` |
| 2 | `titan_x6_tensor_core_array` | the roadmap's headline macro (4×4 FP16 MAC systolic array, ~600k gates generic) | config ready |
| 3 | `titan_x5_rasterizer` | largest pure-logic graphics block | config ready |
| 4 | `titan_x5_sm` / `titan_x5_l2_cache` | **blocked**: their cache arrays must first be rewritten around SRAM macros (OpenRAM/DFFRAM); as written they flatten to registers and yosys exhausts host RAM (see docs/FPGA_PHASE1_REPORT.md §5) | blocked |

## Host quirks (hard-won)

- **Run on native ext4.** OpenROAD SIGABRTs in `writeDb` when the run
  directory is on `/mnt/c` (drvfs). `run_macro.sh` mirrors the workspace to
  `/root/tx5`, runs there, and rsyncs the finished run back.
- WSL has no systemd: start `dockerd` manually (the runner does).
- Launch long runs detached from Windows via
  `Start-Process wsl.exe ... /root/go_<design>.sh` — plain background shells
  are reaped, and passing `$`-containing scripts through `wsl.exe` argv
  corrupts them (write script files instead).

## Notes

- Clocks are constrained conservatively (40 MHz) for first silicon-viability
  runs; tighten per-macro after the first clean GDS.
- `titan_x5_display_engine` is deliberately not a macro candidate: it is
  dual-clock (core + pixel), and multi-clock macros complicate hierarchical
  integration; it belongs in the top-level assembly step instead.
