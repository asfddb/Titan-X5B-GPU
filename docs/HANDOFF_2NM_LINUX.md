# Handoff: running the GT2N 2 nm place-and-route flow on Linux

*Written 2026-08-16, on Windows, for a fresh session on Aadhi's new Linux
install. Everything stated as fact here was produced by a command that ran;
where something is unverified it says so.*

This is **not** `docs/PROMPT_FROM_SCRATCH_2NM.md` — that one is about designing
a new GPU for an advanced node. This one is narrower and concrete: take the
existing RTL and push it through a real 2 nm place-and-route flow, which the
Windows machine could not do because it has no Docker and no WSL.

---

## 1. Where to get the code

```sh
git clone https://github.com/asfddb/Titan-X5B-GPU.git
cd Titan-X5B-GPU
git checkout claude/2nm-flow-and-tt-wrapper
```

That branch carries everything described below. `master` is the default branch
but does **not** have the recent work.

**The PDK is not in the repo and is not downloadable from it.** GT2N lives at
`C:\eda\GT2N` on the Windows machine (~several GB: `lib/`, `lef/`, `gds/`,
`techlib/`, `qrc/`, `icv_runset/`, `Openroad_example/`). Copy that directory
across — USB stick, network share, whatever is easiest. It is the Georgia Tech
open 2 nm nanosheet GAAFET PDK (BSD-3, Jang et al., IEEE ISCAS 2026); there is
an upstream release, but **I have not verified a working download URL**, so
copying the known-good directory is the reliable route.

---

## 2. What this project is, in one paragraph

An open-source GPU: Verilog RTL, a C functional model, a driver, a runtime and
a compiler. It is real and it works. As of 2026-08-16 `tb/run_regression.py`
passes **33/33 cocotb suites** against the actual RTL, and DOOM runs with its
per-pixel palette expansion executing on the GPU's own instruction set. Aadhi
is a hobbyist solo builder learning Verilog — **use plain language, and do not
correct his spelling.**

---

## 3. Verified state you can rely on

| Thing | State |
|:--|:--|
| `tb/run_regression.py` | 33/33 suites PASS (Icarus + cocotb) |
| DOOM on the ISA model | Runs; palette expansion is 18 Titan instructions per pixel |
| `tt/tt_um_titan_fma.v` | Tiny Tapeout wrapper, self-checking testbench passes 5/5 |
| `syn/gt2n/run_gt2n_all.sh` | Synthesises every `rtl/` module onto GT2N |
| Synthesis, svt/w31 | `titan_x7_lzc` 6.18 µm² @ 114.08 ps; `titan_x5_fp32_mul` 160.89 µm²; `titan_x5_alu` 1284.39 µm² @ 907.41 ps |

Those areas are **synthesis only, with `WireLoad="none"` — zero wire delay.**
Closing that gap is the entire point of the job below.

---

## 4. The job

Place-and-route a Titan module on GT2N and report **real** area and timing —
with routing, parasitics and a DRC/LVS-clean layout.

### 4.1 What is already sitting there

`/c/eda/GT2N/Openroad_example/gt2n_openroad_runscripts_no_work_20260601.tar.gz`
(already extracted on Windows) is a complete ORFS **overlay** — not a full
checkout. It contains:

- `flow/platforms/gt2n/` — LEF, Liberty, `make_tracks.tcl`, `tapcell.tcl`,
  `fastroute.tcl`, `setRC.tcl`, `rcx_patterns.rules`, and KLayout DRC/LVS
  decks (`gt2n.lydrc`, `gt2n.lylvs`).
- `flow/platforms/gt2n_compat_bspdn_proxy/` — a backside-power-delivery view.
- Two worked AES-128 examples, frontside and backside PDN.

Its README says to set:

```sh
export ORFS=/path/to/OpenROAD-flow-scripts
export PROJ=/path/to/project/root
export OR_IMAGE=docker.io/openroad/orfs:26Q2
```

### 4.2 Suggested order

1. **Install Docker** (or Podman) and get a full OpenROAD-flow-scripts
   checkout. Confirm ORFS works on its own bundled example *before* touching
   GT2N — if the stock flow is broken, nothing downstream is interpretable.
2. **Merge the GT2N platform** into the ORFS checkout and reproduce **one of
   the shipped AES runs**. This is the control experiment: it proves the
   platform collateral is intact on this machine. Do not skip it and do not
   start with Titan RTL.
3. **Then, and only then, a Titan module.** Start with **`titan_x7_lzc`** —
   6.18 µm², so it completes quickly and proves the flow end to end. Aadhi was
   asked which block to start with and said "idk", so this is my
   recommendation, not his instruction; check with him if it matters.
4. Then step up: `titan_x5_alu` (1284 µm²), then `titan_x5_fp32_fma`, which is
   the flagship and is already hardened on sky130 at 0.234 mm² — so it gives a
   direct 130 nm vs 2 nm comparison.
5. Write results into `docs/` as a report, not just into chat.

### 4.3 What "done" looks like

Real post-route numbers: area including routing, timing **with** parasitics,
and a clean DRC/LVS. Then update `docs/GT2N_2NM_SYNTHESIS.md`, which currently
carries the zero-wire-delay caveat, with numbers that no longer need it.

---

## 5. Facts about GT2N that will save you hours

- **It is a PREDICTIVE PDK and is NOT fabbable.** No foundry will take it. A
  real 2 nm tapeout needs an NDA with TSMC/Intel/Samsung and a mask set costing
  tens of millions. If Aadhi asks about fabricating this, that is the honest
  answer, and the realistic route to silicon he can hold is **sky130 via Tiny
  Tapeout** — `tt/` in this repo is already built and passing for that.
- **One corner only:** `tt` 0.7 V 25 °C. No `ss`, no `ff`. There is no
  slow-corner signoff and no margin analysis, and saying otherwise would be
  fiction.
- **No SRAM whatsoever.** The `gt2_6t` in every filename is a *6-track
  standard-cell site*, not a 6T SRAM bitcell. Every memory in this design maps
  to flip-flops, which is why cache and register-file areas look enormous.
  Those figures are real for a flop-based build and say nothing about the block
  with a real memory macro.
- **No Verilog cell models ship with the PDK.** I checked: `find /c/eda/GT2N
  -iname '*.v'` returns nothing. You therefore **cannot gate-level simulate a
  GT2N-mapped netlist.** Use the formal equivalence proofs in
  `syn/gt2n/prove_*.ys` instead — that is what they are for.
- **The whole GPU will not place-and-route.** One module at a time.

---

## 6. Traps that already cost real time on this project

- **Modules whose filename differs from the module name.** `titan_x7_csa_mul24`
  lives in `titan_x7_csa_mul.v`; `titan_x5_coherent_xbar` lives in
  `titan_x5_crossbar.v`; `BUFG` lives in `xilinx_stubs.v`. iverilog's `-y`
  resolves a module by looking for `<modulename>.v`, so it cannot find these,
  and the failure surfaces as a **failing test rather than a build error** —
  it looks like broken hardware. This produced 5 bogus regression failures
  (`fma8`, `sm7`, `sm7warp`, `apexlane`, `x7shim`), all fixed by the
  `IMPLIED_SOURCES` table in `tb/run_regression.py`. Expect the same class of
  bug in any new file list you write.
- **The plain `tb/tb_*.v` testbenches are mostly waveform dumps, not tests.**
  `tb_fpu_top` prints nothing at all; `tb_titan_x5_alu` just says "Complete".
  Do not count them as coverage. The cocotb suite is the real verification.
  `tb/run_iverilog_tbs.sh` runs them under Icarus if you need to.
- **`tb_doom_display.v` reads `doom_out/doom_vram.hex` by relative path** — run
  it from the repo root or it silently renders an empty frame.
- **Killing a worker does not kill the loop that spawned it.** On Windows,
  killing `yosys.exe` left the driving shell alive; it just started another
  one, and two sweeps ran concurrently into the same output directory. Kill
  the shell, then the workers, then verify nothing respawned.

---

## 7. How Aadhi wants to be worked with

- **Never give estimated or modelled numbers.** If it was not measured by a
  command that actually ran, say "unmeasured". He rejects estimates outright,
  even clearly labelled ones. This is the single most important rule here.
- Warm, plain language. Do not correct his spelling.
- Commit as you go on the working branch. **No PRs unless he asks.**
- Commits end with:
  `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`
- Control-experiment every fix; mutation-test new tests.
- Work in this repo, in place. Do not start a new repository.
