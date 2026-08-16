# Prompt for the next session — moving off the 2005-era node

Paste everything below the line into a new chat.

---

Work on the repo `asfddb/Titan-X5B-GPU`, branch `claude/titan-x5-gpu-conversion-lf6udk`.
It is checked out locally at **`C:\Titan-X5B-GPU`** (Windows).

Read `docs/HANDOFF_NEXT_SESSION.md` first — environment, how to run the tests,
current state, and the known-open list. Then read `docs/ASIC_PHASE2_REPORT.md`
and `docs/ROADMAP_REAL_HARDWARE.md`.

## Where things stand

The v2.0 RTL work is **done and committed**: per-warp register file, SETP +
per-warp predicate registers driving conditional branches, and
`compiler/kernels/matmul.py` running end to end on the RTL bit-exact against
NumPy. Regression is 17/17 and the full-chip render test is 181 pixels / 0 out
of bounds with all 8 warps launched.

**Two commits are unpushed** (`0a853e6`, `ed69aae`). `git push` fails with
"Password authentication is not supported for Git operations" — Git Credential
Manager blocks on a GUI prompt and `gh` is not installed. Ask me to
authenticate before you try; do not attempt to enter credentials yourself.

## The task

**The physical-design flow targets SkyWater sky130 — a 130 nm node with
roughly 2005-era density and speed. Move it toward a modern one, and be
honest about how far that can actually go.**

### Read this before planning — it constrains everything

1. **There is no open PDK anywhere near a modern GPU node.** Real GPUs are on
   ~4–5 nm. What OpenROAD-flow-scripts (ORFS) can redistribute is:
   `nangate45` (45 nm), `sky130hd`/`sky130hs` (130 nm), `gf180` (180 nm),
   `ihp-sg13g2` (130 nm BiCMOS), and **`asap7` — a 7 nm *predictive* PDK**.
   ORFS also supports GF12/GF55/Intel16/Intel22/TSMC65, but those are NDA and
   the files cannot be obtained.
   **ASAP7 is the only modern-node option, and it is predictive, not a foundry
   PDK — you cannot fab it and its numbers are not silicon-accurate.** Every
   number produced from it must be labelled that way. Do not let the report
   imply a 7 nm tapeout is possible.

2. **The node is probably not this design's real bottleneck, and I want that
   tested rather than assumed.** Measured on the current design:
   - `titan_x6_tensor_core_array` hardened at a **65 ns** clock (~15.4 MHz) and
     `titan_x5_fp32_fma` at **25 ns** (40 MHz) — see `docs/ASIC_PHASE2_REPORT.md`.
     A 65 ns critical path at 130 nm is an enormous logic depth; a smaller node
     scales that down but does not fix it. **Suspect missing pipelining, and
     check it before crediting the node.**
   - The SM retires roughly **one instruction per 58 clock cycles**.
   - 8 warps take **24,069 cycles where 1 warp takes 3,257** — 7.4× for 8× the
     work, i.e. almost no concurrency. Cause is identified in the handoff:
     one outstanding fetch per SM, plus `titan_x5_warp_scheduler.v:88` testing
     the *current ID instruction's* source registers against *every* warp's
     scoreboard, so warps stall on each other's register numbers.

   A 7 nm port would give a fast clock to a machine that still stalls
   constantly. Both tracks matter; I want them sequenced so the cheap
   measurement comes first and tells us where the real limit is.

3. **`titan_x6_gpu_top` is a non-working scaffold** — its GPCs are not
   connected to its L2 (`assign l2_req_addr = 0;`). It has an aspirational
   `CLOCK_PERIOD: 0.66` (1.5 GHz) in `openlane/titan_x6_gpu_top/config.json`.
   Do not harden it or quote its clock as if it runs. The working design is
   `titan_x5_gpu_top`.

### Environment reality — check before planning

`docs/ASIC_PHASE2_REPORT.md` describes OpenLane 2.3.10 + sky130A run inside
**WSL Ubuntu-24.04 with Docker**. **WSL is no longer installed on this
machine** (`wsl -l -v` reports "not installed"). So the ASIC flow as
documented is **not currently reproducible here**. Present is: Icarus Verilog
12.0 at `C:\iverilog\bin`, Python 3.12 with cocotb 2.0.1, pytest and numpy 2.5.1.
**No Verilator, no Yosys.**

Getting any physical-design result therefore needs WSL + Docker + ORFS + PDKs
installed — several GB. **Tell me the actual download/disk cost and get my
explicit yes before installing any of it.** If I say no, say so plainly and do
the parts that need no PDK rather than quietly substituting estimates.

### What I want from you

Produce a **plan first, not code**, covering at least:

- **Track A — node port as a controlled experiment.** Take the two macros that
  are already known-good through the full flow (`titan_x5_fp32_fma`,
  `titan_x6_tensor_core_array`), run the *same RTL* through ORFS on
  `nangate45` and `asap7`, and build one comparison table: cells, area,
  achievable clock, power, per node. That isolates how much of 15–40 MHz is
  the PDK and how much is the design. Include sky130 as the control.
- **Track B — is it the node or the pipelining?** Get the critical path
  *composition* (logic depth, what the dominant stages are), not just the
  period. State a hypothesis and the measurement that would falsify it. If the
  tensor array's 65 ns is combinational depth rather than node speed, say so
  and cost the pipelining work.
- **Track C — the architectural gap to a modern GPU.** From the known-open
  list and the measurements above: instruction cache and multiple outstanding
  fetches, the warp scheduler's hazard check, a reconvergence stack for
  divergent predication, per-SM shared memory/scratchpad, a cache
  flush/writeback path (there is none — kernel results never reach memory
  today), MSHRs / hit-under-miss in the LSU, 64-bit addressing (registers are
  32-bit, so threads cannot address above 4 GiB), and making the tensor/RT
  units reachable from compiled code. Rank these by impact on real
  instructions-per-cycle, and say which are prerequisites for others.
- **Sequencing and a recommendation.** Say which track to do first and why.
  If you think the node port is the less valuable use of effort, say that
  plainly — I would rather hear it than get an agreeable plan.
- **What each step proves**, and the gate that decides it worked.

Then stop and let me pick. Do not start implementing until I choose.

### Working rules — these have produced the good results so far

- **No invented numbers.** Every figure must come from a command you actually
  ran. Say "unknown and unmeasured" rather than estimating. This especially
  applies to PDK/node comparisons, where it is very easy to quote vendor
  marketing numbers instead of measurements.
- **Mutation-test every new test.** Inject a defect, show the test fails,
  restore, show it passes. Last session this caught a test that proved nothing:
  `test_predicates_are_per_warp` passed even with predicate registers
  deliberately shared across all warps, because warps in this design barely
  overlap. Read that finding in the handoff before writing multi-warp tests.
- **Control-experiment every fix.** Revert it with the new test in place and
  show the failure, so the bug is demonstrated rather than asserted.
- **Keep 17/17 suites green and the full-chip render test at 181 pixels, 0 out
  of bounds.** Any RTL change must be re-verified against both.
- **Keep the honest-scope discipline in `README.md`.** Extend the limitations
  section as capability grows; never quietly drop a caveat. If a 7 nm number
  goes in, the "predictive, not fabbable" caveat goes in beside it.
- Commit with detailed messages explaining the *why*, ending with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  ```
- Push to `claude/titan-x5-gpu-conversion-lf6udk`. No PR unless I ask.

### Decisions that are mine, not yours

Ask me, do not choose unilaterally:

1. **Whether to install WSL + Docker + ORFS + PDKs at all**, once you have told
   me the real disk cost.
2. **Which node to target** if the cost forces a single choice — `asap7`
   (modern, predictive, unfabbable) or `nangate45` (older, but the standard
   academic baseline and much lighter).
3. **Whether to spend effort on the node port at all** versus going straight at
   the architectural bottlenecks. Give me your recommendation with reasoning.
