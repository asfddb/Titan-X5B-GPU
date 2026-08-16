# Prompt for the next session — clean-sheet GPU built to advanced-node discipline

Supersedes `docs/PROMPT_MODERN_NODE.md`. Paste everything below the rule into a
new chat.

---

I want to build a GPU **from scratch**, designed for a **2–3 nm class process**,
not the 130 nm sky130 flow my current project uses.

Context: I have an existing open-source GPU project at **`C:\Titan-X5B-GPU`**
(repo `asfddb/Titan-X5B-GPU`, branch `claude/titan-x5-gpu-conversion-lf6udk`).
Read `docs/HANDOFF_NEXT_SESSION.md`, `docs/ASIC_PHASE2_REPORT.md` and
`docs/ROADMAP_REAL_HARDWARE.md` before answering. It works — 17/17 test suites,
a self-checking full-chip render test, and `compiler/kernels/matmul.py` running
on the RTL bit-exact against NumPy — but it hardened at **15–40 MHz on 130 nm**,
which is roughly 2005-era silicon. I want to start again and do it properly for
a modern node.

## Where the work happens — read this before you touch anything

**All work happens inside the existing project folder `C:\Titan-X5B-GPU`, on the
branch `claude/titan-x5-gpu-conversion-lf6udk`.**

- **Do not create a new repository, and do not start a new folder somewhere
  else.** Even a clean-sheet design goes in this repo — a new directory tree
  inside it is fine, a new repo is not. The commit history documenting bugs
  found and fixed is this project's credibility and is not to be thrown away.
  `docs/HANDOFF_NEXT_SESSION.md` says the same thing; if you think it is wrong,
  argue the case with me first rather than acting on it.
- **Work on the actual project files**, in place. Read the real RTL, the real
  testbenches and the real reports in this repo before proposing anything —
  do not design against a description of the project, design against the code.
- **Write the plan into the repo as a document** (e.g. `docs/`), not only into
  chat, so it survives the session and I can review it later.
- Commit as you go, on that branch. No PR unless I ask.

## Step 0 — before you plan anything, establish what is actually reachable

**Do not assume, and do not take my framing on trust. Verify and report.**

My understanding, which I want you to confirm or correct with sources:

- There is **no open or free PDK at 2–3 nm**. Those nodes (TSMC N2, Intel 18A,
  Samsung SF2) are gate-all-around / nanosheet with EUV multi-patterning and
  backside power delivery. The PDKs are NDA-only, gated behind corporate
  foundry agreements, and a mask set runs into tens of millions of dollars.
- The most advanced **openly available** PDK is **ASAP7**, a 7 nm *predictive*
  FinFET PDK, supported in OpenROAD-flow-scripts. Predictive means realistic
  but not silicon-accurate, and **not fabbable**.
- OpenROAD does not implement what advanced nodes need anyway (EUV
  multi-patterning decomposition, GAA device models, advanced fill/DFM).
- Anything below 7 nm openly — check whether ASAP5 or any newer predictive PDK
  is actually distributable and ORFS-supported, or whether it is paper-only.

Tell me plainly where the real line is. **If 2–3 nm is not reachable, say so in
one or two sentences and tell me the nearest thing that is** — do not soften it,
and do not quietly substitute a 7 nm plan while letting me believe it is 2 nm.

Also state clearly: **RTL is node-agnostic.** The Verilog for a GPU is the same
at 130 nm and 2 nm. What is node-specific is the standard-cell library, the
memory compilers, the constraints you can close, and the physical flow. So
"build it for 2 nm" is mostly a question of *design discipline and targets*,
not of writing different Verilog. If I am confused about that, correct me.

## Step 1 — what "designed for an advanced node" actually has to mean

Given the above, I want the clean-sheet design to be built to the discipline a
2–3 nm GPU would demand, even if it is implemented on ASAP7. Concretely, plan
for at least:

- **Pipelining to a real FO4 budget.** The current project's tensor array
  closed at a **65 ns** clock and the FP32 FMA at **25 ns**. That is enormous
  logic depth — a smaller node scales it but does not fix it. Set a target
  stage depth and design to it from the start, and say what GHz that implies.
- **Wire delay, not gate delay, dominates at advanced nodes.** Physical
  hierarchy and floorplan-aware partitioning have to be decided up front, not
  retrofitted.
- **SRAM from memory compilers, not flop arrays.** The existing register file
  is a flop array and grew 8× when it gained a warp dimension. At GPU register
  file sizes that is fatal for area and power. Plan the memory hierarchy around
  what compilers actually give you.
- **Power intent from day one** — clock gating, multi-Vt, and a story for
  dynamic vs leakage. At 2–3 nm power is the binding constraint, not area.
- **DFT/scan planned in**, not bolted on.
- **Clean reset and CDC discipline.** The existing repo has a real
  `SYNCASYNCNET` violation (`rst_n` flopped both synchronously and
  asynchronously) — that class of bug must be designed out.

## Step 2 — what to carry over, and what to genuinely rewrite

I said "from scratch", but I want you to challenge me on it rather than just
comply. The existing project contains verified work that cost real effort:

- IEEE-754 FP32 add/mul/FMA, bit-exact against an integer oracle
- an output-stationary tensor core array, hardened to GDSII
- a MESI-coherent cache hierarchy with a cocotb suite
- a working compiler → ISA → RTL path with a bit-exact matmul
- 17 test suites and a self-checking full-chip render test

`docs/HANDOFF_NEXT_SESSION.md` explicitly warns against starting a fresh
repository, on the grounds that the commit history documenting bugs found and
fixed is the project's credibility.

**Give me a reasoned keep/rewrite/redesign split**, unit by unit, with the
reason for each. Where you recommend rewriting, say what specifically is wrong
with the existing block for an advanced-node target — do not recommend a
rewrite just because "from scratch" is what I asked for.

## Step 3 — the architecture, since that is what actually makes it a GPU

The old design's measured problems, which a clean sheet should not repeat:

- ~**58 clock cycles per instruction retired**
- 8 warps take **24,069 cycles where 1 warp takes 3,257** — 7.4× for 8× the
  work, i.e. almost no concurrency. Causes: one outstanding instruction fetch
  per SM, and a warp scheduler whose hazard check compares the current
  instruction's source registers against *every* warp's scoreboard, so warps
  stall on each other's register numbers.
- No instruction cache, no reconvergence stack for divergent branches, no
  per-SM shared memory/scratchpad, no cache flush path at all (kernel results
  never reach memory on their own), no MSHRs/hit-under-miss, 32-bit addressing
  so threads cannot address above 4 GiB, and the tensor/RT units are not
  reachable from compiled code.

Design the clean sheet around fixing these, and rank them by impact on real
instructions-per-cycle.

## What I want from you in this session

**A plan and a reality check. No code yet.** Specifically:

1. The verified answer to Step 0 — where the node line really is, with sources.
2. A recommended target (node + toolchain) and why.
3. The keep/rewrite/redesign split from Step 2.
4. An architecture outline with the pipeline/memory/scheduler decisions that
   follow from the node target, plus the FO4/GHz budget.
5. A phased plan where each phase has a **gate** — a measurement that decides
   whether it worked — and an honest note on what each phase cannot prove.
6. What this will cost me: disk, install size, and simulation/build time.
   **Ask before installing anything large** (WSL, Docker, ORFS, PDKs are
   several GB). Tell me the number first.
7. The plan committed into `C:\Titan-X5B-GPU` as a document under `docs/`, on
   the working branch — not just written in chat.

Then stop and let me choose. Do not start implementing until I pick a direction.

## Environment reality — check it, do not trust this list blindly

On this machine: Icarus Verilog 12.0 at `C:\iverilog\bin` (**not on PATH**),
Python 3.12 at `AppData\Local\Programs\Python\Python312` with cocotb 2.0.1,
pytest and numpy. **No Verilator, no Yosys, and WSL is not installed** —
`docs/ASIC_PHASE2_REPORT.md` describes an OpenLane flow run in WSL Ubuntu-24.04
+ Docker that is therefore **not reproducible here today**. The whole-GPU Icarus
simulation runs at roughly 90 clock cycles per wall second.

Also: **two commits on the current branch are unpushed.** `git push` fails with
"Password authentication is not supported for Git operations" — Credential
Manager blocks on a GUI prompt and `gh` is not installed. Ask me to
authenticate; never try to supply credentials yourself.

## Working rules — these produced the good results so far, keep them

- **No invented numbers.** Every figure must come from a command you actually
  ran or a source you actually read. Say "unknown and unmeasured" rather than
  estimating. This matters most for node/PDK claims, where vendor marketing
  numbers are easy to quote and wrong to cite as measurements.
- **Tell me when I am wrong.** If "from scratch at 2 nm" is the wrong plan, say
  so directly and explain why. I would rather be corrected than agreed with.
- **Mutation-test every new test.** Inject a defect, show the test fails,
  restore, show it passes. On the last session this caught a test that proved
  nothing — a multi-warp test that passed even with the state it was checking
  deliberately shared across all warps.
- **Control-experiment every fix.** Revert it with the new test in place and
  show the failure.
- **Honest scope in `README.md`.** Never drop a caveat quietly. If a 7 nm
  number appears, the "predictive, not fabbable" caveat appears beside it.
- Commit messages explain the *why*, and end with:
  ```
  Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
  ```
- No PR unless I ask.
