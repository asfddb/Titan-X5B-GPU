# 🗺️ TITAN X5-B IP SALE — PHASE 1 MASTER ROADMAP
## "Make It Sellable" — 90 Days, Day-by-Day

**Goal:** Transform the Titan X5-B repo from a learning project into a
commercially sellable GPU IP block.

**Success criteria at Day 90:**
1. ✅ Dual-licensed (CERN-OHL-S for OSS + commercial license available)
2. ✅ Clean Yosys synthesis with ZERO warnings (currently fails on GAAFET)
3. ✅ GitHub Actions CI runs lint + compile + sim on every push
4. ✅ FPGA-proven on Artix-7 (hello-world LED + VGA output)
5. ✅ Full documentation set (Architecture Spec, Verification Plan,
   Datasheet, Product Brief, Integration Guide)
6. ✅ 5 cold-outreach emails sent per week (40+ companies contacted)
7. ✅ NLnet grant application submitted
8. ✅ Indian LLP registered (or in progress)
9. ✅ 200+ cocotb tests, ≥60% functional coverage

**Estimated cash investment:** ₹35,000 (~$420) for FPGA hardware + lawyer
**Estimated time investment:** 4-6 hours/day, 6 days/week
**Realistic outcome at Day 90:** IP is sellable. First eval license
conversations can begin. NLnet grant decision pending.

---

# 📅 MONTH 1 — LEGAL + TECHNICAL FOUNDATION

The goal of Month 1: kill every blocker that says "this is a hobby project."

---

## WEEK 1 (Days 1-7): LEGAL FOUNDATION

The single most important week. Without this, nothing else matters.

### Day 1 (Monday) — License Audit + Lawyer Search

**Morning (2 hrs):**
- [ ] Read your current `LICENSE` file end-to-end
- [ ] Confirm it's CERN-OHL-S-2.0 (strongly reciprocal)
- [ ] Understand WHY this blocks commercial sale (reciprocity clause)
- [ ] Read about dual licensing: https://en.wikipedia.org/wiki/Multi-licensing

**Afternoon (3 hrs):**
- [ ] Search for IP lawyers in India:
  - IndiaFilings (cheap, ₹2K-5K for basic dual-license)
  - Vakilsearch (similar pricing)
  - BananaIP (Bangalore, semi-specialty, ₹10K-25K)
  - Alternative: use a dual-license template (I provide one in
    `01-LEGAL/LICENSE.md`) and only pay a lawyer to REVIEW it (₹1K-3K)
- [ ] Email 3 lawyers asking for quotes on:
  - Dual-license review
  - CLA (Contributor License Agreement) drafting
  - Indian LLP registration

**Evening (1 hr):**
- [ ] Decide: pay lawyer ₹10K-25K to draft from scratch, OR
  use my template + ₹1K-3K review
- [ ] Book the lawyer

**Deliverable:** Lawyer engaged or template chosen.

### Day 2 (Tuesday) — Apply the Dual License

**Morning (2 hrs):**
- [ ] Copy `01-LEGAL/LICENSE.md` to your repo as the new `LICENSE`
- [ ] Copy `01-LEGAL/COMMERCIAL.md` to your repo root
- [ ] Update `README.md` to add a "Licensing" section at the top:

```markdown
## 📜 Licensing

Titan X5-B is **dual-licensed**:

- **Open Source:** CERN-OHL-S-2.0 (free for research/education/personal)
- **Commercial:** Available separately — contact adhiraj@[your-email]

Commercial licensees receive: warranty, indemnification, support,
and no open-source obligation on derivative products.
```

**Afternoon (2 hrs):**
- [ ] Pick a domain name (e.g., `titanx5-gpu.com` or `adhiraj-gpu.dev`)
- [ ] Buy it on Namecheap or Cloudflare Registrar (~$10/year)
- [ ] Set up a professional email: `adhiraj@yourdomain.com`
  - Free: Cloudflare Email Routing → forwards to your Gmail
  - Paid: Google Workspace ($6/month)

**Evening (1 hr):**
- [ ] Create a `CONTACT.md` file with commercial license inquiry instructions
- [ ] Commit all changes: `git commit -m "license: dual-license for commercial use"`

**Deliverable:** Repo is now dual-licensed.

### Day 3 (Wednesday) — CLA Setup

If anyone ever contributes to your repo, you need a CLA to retain
the right to relicense. Set this up BEFORE you accept any PRs.

**Morning (2 hrs):**
- [ ] Copy `01-LEGAL/CLA-INDIVIDUAL.md` and `01-LEGAL/CLA-CORPORATE.md`
      to your repo under `.github/CLA/`
- [ ] Sign up for CLA Assistant: https://cla-assistant.io/
- [ ] Connect your GitHub account
- [ ] Add your repo to CLA Assistant
- [ ] Configure: contributors must sign CLA before PR merge

**Afternoon (2 hrs):**
- [ ] Add a `.github/FUNDING.yml`:

```yaml
github: [asfddb]
patreon: asfddb
ko_fi: asfddb
custom: ["https://your-domain.com/commercial-license"]
```

- [ ] Enable GitHub Sponsors: https://github.com/sponsors/asfddb
- [ ] Add sponsor tiers: $5, $25, $100

**Evening (1 hr):**
- [ ] Add `CONTRIBUTING.md` update requiring CLA signature
- [ ] Commit: `git commit -m "legal: add CLA + funding channels"`

**Deliverable:** CLA enforced, funding channels live.

### Day 4 (Thursday) — Indian LLP Registration (Start)

An Indian LLP (Limited Liability Partnership) costs ~₹10K-15K to
register and gives you:
- Legal entity to sign IP licenses
- Bank account in company name
- Limited liability (protects personal assets)
- Eligibility for DLI grants (must be Indian company)
- Credibility with buyers ("company" > "individual")

**Morning (3 hrs):**
- [ ] Pick a company name (check availability on MCA portal):
  - Options: "Adhiraj Silicon LLP", "Titan GPU Systems LLP",
    "Astra Semiconductor LLP"
- [ ] Get Digital Signature Certificate (DSC) for yourself —
      required for LLP filing. Use any CA, ~₹1K-2K.
- [ ] Apply for Director Identification Number (DPN) —
      automatic with LLP filing

**Afternoon (2 hrs):**
- [ ] File name reservation on MCA portal (RUN-LLP form, ₹200)
- [ ] Wait 24 hours for approval
- [ ] While waiting: draft LLP agreement (use my template or
      IndiaFilings for ~₹3K)

**Evening (1 hr):**
- [ ] Apply for PAN + TAN (automatic with LLP filing, ~₹1K)

**Deliverable:** LLP name reserved, registration in progress.

### Day 5 (Friday) — LLP Registration (Finish)

**Morning (3 hrs):**
- [ ] File FiLLiP form (LLP incorporation) on MCA portal
- [ ] Attach LLP agreement
- [ ] Pay filing fee (~₹5K-8K depending on capital)
- [ ] Get Certificate of Incorporation (usually same day or next day)

**Afternoon (2 hrs):**
- [ ] Apply for GST registration (free, 7 days to approve)
- [ ] Open a current account in LLP name (HDFC, ICICI, Axis —
      most have zero-balance startup accounts)
- [ ] Apply for Startup India recognition (free, gives DLI eligibility
      + tax benefits): https://startupindia.gov.in

**Evening (1 hr):**
- [ ] Update LinkedIn: add "Founder" role at your LLP
- [ ] Update GitHub profile: add company name
- [ ] Commit: `git commit -m "legal: LLP incorporated, commercial-ready"`

**Deliverable:** You are now a legal Indian company.

### Day 6 (Saturday) — Banking + Tools Setup

**Morning (2 hrs):**
- [ ] Set up Stripe or Razorpay account (to accept license payments)
- [ ] Set up accounting: use Zoho Books (free for small biz) or Tally
- [ ] Set up a CRM: HubSpot Free or Notion to track IP sales leads

**Afternoon (2 hrs):**
- [ ] Set up professional profiles:
  - LinkedIn company page for your LLP
  - Twitter/X handle (@TitanX5B or @adhiraj_gpu)
  - Mastodon account (semiconductor community is there)
  - Hacker News account (if you don't have one)

**Evening (2 hrs):**
- [ ] Write a 1-paragraph "About" for your company
- [ ] Design a simple logo (use Canva free, 30 minutes)
- [ ] Create a simple landing page: GitHub Pages or Cloudflare Pages
      with one page: "Titan X5-B GPU IP — Commercial License Available"

**Deliverable:** Business infrastructure operational.

### Day 7 (Sunday) — REST + Weekly Review

- [ ] Sleep in
- [ ] 30 min: review what you accomplished this week
- [ ] 30 min: plan next week
- [ ] 1 hr: read /r/FPGA, Hacker News, semi Twitter — get inspired

---

## WEEK 2 (Days 8-14): TECHNICAL DEBT CLEANUP

Now we kill every technical blocker.

### Day 8 (Monday) — Fix the GAAFET Bug

This is the single most important technical fix. Without it, your
expanded synthesis doesn't run.

**Morning (3 hrs):**
- [ ] Read `02-RTL-FIXES/titan_x_3nm_gaafet_optimizer_FIXED.v`
- [ ] Compare to your current `rtl/titan_x_3nm_gaafet_optimizer.v`
- [ ] The fix: replace unpacked array ports with packed buses

```verilog
// OLD (broken — Yosys can't parse):
input wire [7:0] thermal_sensors [0:ISLAND_COUNT-1],

// NEW (fixed — packed bus):
input wire [ISLAND_COUNT*8-1:0] thermal_sensors,
```

- [ ] Update all internal references to use `[i*8 +: 8]` slicing
- [ ] Replace the file in your repo

**Afternoon (2 hrs):**
- [ ] Run Yosys synthesis on the GAAFET module alone:
```bash
yosys -p "read_verilog -sv rtl/titan_x_3nm_gaafet_optimizer.v; synth; stat"
```
- [ ] Confirm ZERO errors
- [ ] Update any module that instantiates this one — change port
      connections to packed bus format

**Evening (1 hr):**
- [ ] Commit: `git commit -m "fix(rtl): GAAFET optimizer unpacked array ports → packed bus"`

**Deliverable:** GAAFET module synthesizes cleanly.

### Day 9 (Tuesday) — Fix translate_off + Other Warnings

**Morning (2 hrs):**
- [ ] Open `rtl/astra8/astra8_mas_wetware.v` line 50
- [ ] Replace `// translate_off` / `// translate_on` with:

```verilog
`ifdef SYNTHESIS
  // synthesis code
`else
  // simulation-only code
`endif
```

- [ ] Search all files for `translate_off`:
```bash
grep -rn "translate_off" rtl/
```
- [ ] Fix every instance

**Afternoon (3 hrs):**
- [ ] Run the EXPANDED synthesis (the one that was failing):
```bash
yosys -p "read_verilog -sv rtl/raytracing/*.v rtl/astra/*.v rtl/titan_x6_top.v ... ; hierarchy -top titan_x5_gpu_top; synth; stat"
```
- [ ] Iterate on any remaining errors (memory → register warnings are OK)
- [ ] Save the final log: `synthesis_report_expanded_clean.txt`
- [ ] Screenshot the final `stat` output (gate count breakdown)

**Evening (1 hr):**
- [ ] Commit: `git commit -m "fix(rtl): replace translate_off with SYNTHESIS ifdef, clean synth"`
- [ ] Update README with new gate count (should be much higher now)

**Deliverable:** Clean expanded synthesis.

### Day 10 (Wednesday) — Add RAM Style Attributes

Without `(* ram_style="block" *)`, Yosys infers your memories as
flip-flops (that's why you have 530K registers). On FPGA, this will
NOT fit. Add attributes to map them to BRAMs.

**Morning (2 hrs):**
- [ ] Run `02-RTL-FIXES/apply_ram_style.py` against your repo:
```bash
python3 02-RTL-FIXES/apply_ram_style.py /path/to/your/repo/rtl
```
- [ ] This auto-detects `reg [..] name [..];` declarations and
      prepends `(* ram_style="block" *)`

**Afternoon (2 hrs):**
- [ ] Manually review the changes (the script is conservative)
- [ ] For cache tag/data arrays, you may want `(* ram_style="block" *)`
      for true BRAMs
- [ ] For small register files, leave as registers
- [ ] Run synth again, check if gate count dropped

**Evening (1 hr):**
- [ ] Commit: `git commit -m "perf(rtl): add ram_style attributes for BRAM inference"`

**Deliverable:** RTL is FPGA-ready.

### Day 11 (Thursday) — Code Cleanup + Linting

**Morning (2 hrs):**
- [ ] Install Verilator (free, fast linter):
```bash
# Linux/Mac: brew install verilator OR apt install verilator
# Windows: download from https://www.veripool.org/verilator/
```
- [ ] Run Verilator lint on every file:
```bash
verilator --lint-only -Wall rtl/**/*.v
```
- [ ] Fix every `UNOPTFLAT`, `WIDTH`, `CASEINCOMPLETE` warning

**Afternoon (3 hrs):**
- [ ] Standardize naming (per your CONTRIBUTING.md):
  - Modules: `snake_case`
  - Registers: `r_` prefix or `_q` suffix
  - Wires: `w_` prefix or `_d` suffix
  - Use `<=` in sequential, `=` in combinational
- [ ] Add file headers to every .v file:
```verilog
`timescale 1ns / 1ps
// =============================================================================
// Module: titan_x5_<name>
// Project: Titan X5-B GPU
// License: CERN-OHL-S-2.0 (OSS) / Commercial (see LICENSE)
// Author:  Adhiraj (@asfddb)
// =============================================================================
```

**Evening (1 hr):**
- [ ] Commit: `git commit -m "chore: lint cleanup + standardized headers"`

**Deliverable:** Code looks professional.

### Day 12 (Friday) — `.gitignore` + Repo Hygiene

**Morning (2 hrs):**
- [ ] Update `.gitignore`:
```
# Build artifacts
*.vvp
*.vcd
*.fst
*.lxt
*.gtkw
sim_build/
work/
_angepasst/

# Editor
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# EDA
*.bak
*.log
*.json.x
*.rc~
```

- [ ] Remove `sim_build/` from git tracking (but keep on disk):
```bash
git rm -r --cached sim_build/
```

**Afternoon (2 hrs):**
- [ ] Reorganize repo per industry convention:
```
Titan-X5B-GPU/
├── rtl/            # RTL sources
├── tb/             # Testbenches
├── sim/            # Sim scripts + Makefile
├── syn/            # Synthesis scripts + reports
├── fpga/           # FPGA constraints + Vivado project
├── docs/           # Documentation
├── driver/         # Host-side driver code
├── firmware/       # On-GPU firmware
├── compiler/       # Shader compiler (if any)
├── tools/          # Helper scripts
└── third_party/    # Vendored deps
```

**Evening (1 hr):**
- [ ] Commit: `git commit -m "chore: reorganize repo, fix .gitignore"`

**Deliverable:** Repo is professional.

### Day 13 (Saturday) — Synthesis Report Polish

**Morning (3 hrs):**
- [ ] Run final clean synthesis with proper reporting:
```bash
yosys -p "
  read_verilog -sv rtl/**/*.v;
  hierarchy -top titan_x5_gpu_top;
  synth -top titan_x5_gpu_top;
  stat > syn/synthesis_stats.txt;
  write_verilog syn/titan_x5b_synth.v;
"
```
- [ ] Generate a JSON summary of gate counts
- [ ] Create a `syn/REPORT.md` with:
  - Total gate count
  - Per-module breakdown
  - Critical path (if you can extract)
  - Memory usage
  - Comparison to Mali-400 / PowerVR baseline

**Afternoon (2 hrs):**
- [ ] Generate visualizations:
  - Pie chart of gate types (use Python matplotlib)
  - Bar chart of per-module gate counts
  - Save as `docs/assets/synth_breakdown.png`

**Evening (1 hr):**
- [ ] Commit: `git commit -m "syn: clean report + visualizations"`

**Deliverable:** Buyer-grade synthesis report.

### Day 14 (Sunday) — REST + Review

- [ ] Rest
- [ ] 30 min: weekly review
- [ ] Plan Week 3

---

## WEEK 3 (Days 15-21): CI + AUTOMATION

### Day 15 (Monday) — GitHub Actions CI Setup

**Morning (3 hrs):**
- [ ] Copy `03-CI/ci.yml` to `.github/workflows/ci.yml` in your repo
- [ ] This workflow does:
  - Lints with Verilator
  - Compiles with Icarus
  - Runs cocotb tests
  - Runs Yosys synthesis
  - Caches dependencies
- [ ] Push to GitHub, watch the first CI run

**Afternoon (2 hrs):**
- [ ] Add CI badges to README.md:
```markdown
[![CI](https://github.com/asfddb/Titan-X5B-GPU/actions/workflows/ci.yml/badge.svg)](https://github.com/asfddb/Titan-X5B-GPU/actions/workflows/ci.yml)
[![License: CERN-OHL-S](https://img.shields.io/badge/License-CERN--OHL--S--2.0-red.svg)](LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/asfddb/Titan-X5B-GPU)](https://github.com/asfddb/Titan-X5B-GPU)
```

**Evening (1 hr):**
- [ ] Fix any CI failures
- [ ] Commit: `git commit -m "ci: GitHub Actions workflow + badges"`

**Deliverable:** CI runs green on every push.

### Day 16 (Tuesday) — Expand Cocotb Tests

**Morning (3 hrs):**
- [ ] Inventory current tests:
  - `test_system.py` — system-level VGA
  - `test_graphics_pipeline.py` — graphics
  - `test_runner.py` — runner
- [ ] Identify gaps:
  - ALU unit tests (do you have tb_titan_x5_alu.py?)
  - Crossbar tests (do you have AXI master/slave tests?)
  - Memory controller tests
  - ROP/TMU tests

**Afternoon (3 hrs):**
- [ ] Write 5 new directed cocotb tests:
  1. `test_alu_ops.py` — test every ALU operation (ADD, SUB, MUL, DIV)
  2. `test_crossbar_routing.py` — test master N → slave M routing
  3. `test_cache_coherence.py` — L1/L2 cache behavior
  4. `test_texture_sampling.py` — TMU bilinear filtering
  5. `test_display_timing.py` — VGA timing violations

**Evening (1 hr):**
- [ ] Commit: `git commit -m "test: 5 new directed cocotb tests"`

**Deliverable:** Test coverage expanded.

### Day 17 (Wednesday) — Coverage Reporting

**Morning (3 hrs):**
- [ ] Enable coverage in cocotb:
```python
# In test_runner.py
import cocotb_coverage
cocotb_coverage.coverage_report()
```
- [ ] Add coverage collection to every test
- [ ] Generate HTML coverage report

**Afternoon (2 hrs):**
- [ ] Add coverage upload to CI (use `actions/upload-artifact`)
- [ ] Set coverage target: 60% (you'll improve over time)

**Evening (1 hr):**
- [ ] Commit: `git commit -m "test: coverage reporting"`

**Deliverable:** Coverage metrics live.

### Day 18 (Thursday) — Regression Suite

**Morning (2 hrs):**
- [ ] Create `sim/regression.py` — runs all tests, reports pass/fail
- [ ] Add `make regression` target to Makefile

**Afternoon (2 hrs):**
- [ ] Add random seed support for cocotb tests
- [ ] Run 100 random seeds, log results
- [ ] Any failures → file as bugs in GitHub Issues

**Evening (2 hrs):**
- [ ] Create a "known issues" dashboard in GitHub Projects
- [ ] Commit: `git commit -m "test: regression suite + random seeds"`

**Deliverable:** Professional regression infrastructure.

### Day 19 (Friday) — Bug Triage Day

**Morning (3 hrs):**
- [ ] Run regression with 500 random seeds
- [ ] File all failures as GitHub Issues with:
  - Reproduction steps
  - Seed number
  - Expected vs actual
  - Waveform screenshot

**Afternoon (3 hrs):**
- [ ] Fix top 5 most critical bugs found
- [ ] For each fix: write a regression test that catches it

**Evening (1 hr):**
- [ ] Commit: `git commit -m "fix: 5 bugs from regression run + regression tests"`

**Deliverable:** Bug count down, test count up.

### Day 20 (Saturday) — Performance Benchmarks

**Morning (2 hrs):**
- [ ] Write `sim/benchmark.py` — measures:
  - Triangles rendered per second
  - Pixels per second
  - ALU operations per second
  - Memory bandwidth
  - Command-to-display latency

**Afternoon (3 hrs):**
- [ ] Run benchmarks, save results to `docs/BENCHMARKS.md`
- [ ] Compare to:
  - Vortex GPU (open source)
  - Nyuzi GPU (open source)
  - Mali-400 (datasheet numbers)
  - PowerVR Series8XE (datasheet numbers)

**Evening (1 hr):**
- [ ] Commit: `git commit -m "perf: benchmark suite + comparison table"`

**Deliverable:** Performance numbers buyers can compare.

### Day 21 (Sunday) — REST + Month 1 Review

- [ ] Rest
- [ ] 1 hour: Month 1 review
  - What got done?
  - What slipped?
  - What's the priority for Month 2?

---

## WEEK 4 (Days 22-28): DOCUMENTATION ARSENAL

This is the highest-ROI week. Documentation sells IP.

### Day 22 (Monday) — Architecture Spec

**All day (6 hrs):**
- [ ] Copy `04-DOCS/ARCHITECTURE.md` to `docs/ARCHITECTURE.md`
- [ ] Fill in every section:
  - Overview
  - Block diagram
  - Module hierarchy (with tree)
  - Per-module description (all 57 modules!)
  - Data flow (command → SM → crossbar → memory → ROP → display)
  - Clock domains
  - Reset strategy
  - Memory map
  - AXI port definitions
- [ ] Add diagrams (use draw.io, free, export as SVG)

**Deliverable:** 30-50 page architecture spec.

### Day 23 (Tuesday) — Microarchitecture Spec (Part 1)

**All day (6 hrs):**
- [ ] Start `docs/MICROARCHITECTURE.md`
- [ ] Document each module in detail:
  - `titan_x5_sm` — SM internals, warp scheduler, pipeline stages
  - `titan_x5_alu` — ALU ops, latency table, hazard handling
  - `titan_x5_register_file` — banking, conflicts, read/write ports
  - `titan_x5_pipeline` — pipeline stages, forwarding, stalls
  - `titan_x5_decoder` — instruction formats, decoding
  - `titan_x5_warp_scheduler` — warp states, scheduling policy

**Deliverable:** 50+ pages of microarchitecture doc.

### Day 24 (Wednesday) — Microarchitecture Spec (Part 2)

**All day (6 hrs):**
- [ ] Document remaining modules:
  - `titan_x5_crossbar` — arbitration, FIFO, response routing
  - `titan_x5_command_processor` — command formats, FSM
  - `titan_x5_rasterizer` — triangle setup, edge functions
  - `titan_x5_tmu` — texture sampling, filtering
  - `titan_x5_rop` — blending, depth test
  - `titan_x5_rt_core` — ray traversal, BVH
  - `titan_x6_tensor_core_array` — systolic array, FP16 MAC
  - Memory: `titan_x5_l1_cache`, `titan_x5_l2_cache`, `titan_x5_mem_controller`
  - Display: `titan_x5_display_engine`
  - Power: `titan_x5_power_mgmt`

**Deliverable:** 100+ page microarchitecture spec complete.

### Day 25 (Thursday) — Verification Plan

**All day (6 hrs):**
- [ ] Copy `04-DOCS/VERIFICATION.md` to `docs/VERIFICATION.md`
- [ ] Fill in:
  - Verification methodology (cocotb + VPI)
  - Test plan table (every feature → test(s) that cover it)
  - Coverage model (functional coverage items)
  - Regression suite description
  - Bug tracking process
  - Current coverage numbers
  - Known limitations

**Deliverable:** 20-page verification plan.

### Day 26 (Friday) — Datasheet + Integration Guide

**Morning (3 hrs):**
- [ ] Copy `04-DOCS/DATASHEET.md` to `docs/DATASHEET.md`
- [ ] Fill in:
  - Pinout
  - Electrical specs (timing, voltage — even if simulated)
  - Clock requirements
  - Reset timing
  - Memory map
  - Performance specs
  - Package (or "soft IP, target technology agnostic")

**Afternoon (3 hrs):**
- [ ] Write `docs/INTEGRATION_GUIDE.md`:
  - How to instantiate the GPU in a SoC
  - Required clock/reset connections
  - AXI port connections
  - Configuration parameters
  - Initial boot sequence
  - Driver initialization (even a stub)

**Deliverable:** Datasheet + integration guide.

### Day 27 (Saturday) — Product Brief + Pitch Deck

**Morning (3 hrs):**
- [ ] Copy `04-DOCS/PRODUCT-BRIEF.md` to `docs/PRODUCT-BRIEF.md`
- [ ] Polish to 2 pages max:
  - What it is (1 paragraph)
  - Key features (bullet list)
  - Architecture diagram
  - Specs table
  - Verification status
  - Licensing model
  - Contact

**Afternoon (3 hrs):**
- [ ] Build a 10-slide pitch deck (Google Slides or Pitch.com):
  1. Cover: "Titan X5-B GPU IP"
  2. Problem: GPU IP is closed and expensive
  3. Solution: Open + commercial-dual-licensed Blackwell-class GPU
  4. Architecture diagram
  5. Specs table
  6. Verification (cocotb, coverage, CI green)
  7. Roadmap (FPGA → TinyTapeout → production)
  8. Market (who buys GPU IP, market size)
  9. Business model (licensing tiers)
  10. Contact + call to action

**Deliverable:** Product brief + pitch deck.

### Day 28 (Sunday) — Month 1 Final Review

- [ ] 2 hrs: Month 1 final review
  - All legal done? ✅
  - All tech debt cleaned? ✅
  - CI green? ✅
  - Tests expanded? ✅
  - Documentation complete? ✅
- [ ] Identify what slipped to Month 2

---

# 📅 MONTH 2 — FPGA VALIDATION + VERIFICATION UPGRADE

The goal of Month 2: prove the GPU works on real hardware, and
upgrade verification to commercial-grade.

---

## WEEK 5 (Days 29-35): FPGA HARDWARE SETUP

### Day 29 (Monday) — Order FPGA Hardware

**Morning (2 hrs):**
- [ ] Order from Digi-Key or Mouser (ships to India):
  - Digilent Arty A7-100T — $130
  - Pmod VGA — $15
  - Pmod OLED (optional) — $20
- [ ] OR order from Robu.in (India, faster delivery):
  - Tang Mega 138K Pro (Gowin) — ₹7,000
  - Sipeed Tang Primer 25K — ₹4,500 (smaller, cheaper alternative)

**Afternoon (2 hrs):**
- [ ] Install FPGA vendor tools:
  - If Artix-7: AMD Vivado ML Edition (free WebPACK, ~80GB download)
  - If Gowin: Gowin EDA (free, ~5GB)
  - If Lattice: Diamond (free, ~10GB)

**Evening (2 hrs):**
- [ ] While waiting for hardware (3-5 days), start writing:
  - `fpga/README.md` — FPGA target overview
  - `fpga/constraints/arty_a7.xdc` — Vivado constraints template

**Deliverable:** Hardware ordered, tools installed.

### Day 30 (Tuesday) — FPGA Target Architecture

**All day (6 hrs):**
- [ ] Plan FPGA target:
  - The full 3M-gate GPU won't fit on Artix-7 (100K LUTs)
  - Create a "FPGA edition" config:
    - 1 SM instead of 4
    - 4×4 tensor core instead of 16×16
    - 8KB L1 cache instead of 32KB
    - Skip RT core (too big)
    - Skip astra7/astra8 (exotic, not synthesizable)
- [ ] Add parameter overrides in `titan_x5_gpu_top.v`:
```verilog
parameter FPGA_EDITION = 0  // 0 = full, 1 = FPGA-reduced
```

- [ ] Create `fpga/titan_x5_gpu_top_fpga.v` — wrapper with FPGA configs

**Deliverable:** FPGA target design complete.

### Day 31 (Wednesday) — Hello World LED

**All day (6 hrs):**
- [ ] If hardware arrived: do this today
- [ ] If not: do it on simulation first, then port when hardware arrives

**The "Hello World" test:**
- [ ] Synthesize a minimal design: command processor + 1 SM + LED output
- [ ] The SM executes a "toggle LED" command
- [ ] Constraints file maps `led[0]` to a physical pin

```verilog
// fpga/hello_world.v
module hello_world(
    input clk,
    input rst_n,
    output [3:0] led
);
    titan_x5_command_processor #(...) cpu(
        .clk(clk),
        .rst_n(rst_n),
        // ... minimal hookup
    );

    assign led[0] = cpu.cmd_valid;
    assign led[1] = cpu.busy;
    assign led[2] = ~cpu.busy;
    assign led[3] = 1'b1;  // always on = power good
endmodule
```

- [ ] Synthesize, generate bitstream, program FPGA
- [ ] **TAKE A PHOTO OF THE LED LIT UP** — this is marketing gold

**Deliverable:** First FPGA proof of life.

### Day 32 (Thursday) — VGA Output

**All day (6 hrs):**
- [ ] Connect Pmod VGA to FPGA
- [ ] Synthesize display engine + framebuffer
- [ ] Pre-load framebuffer with a static pattern (e.g., color bars)
- [ ] Program FPGA, connect to monitor
- [ ] **TAKE A PHOTO OF THE MONITOR SHOWING YOUR GPU'S OUTPUT**
- [ ] This image is worth $50K in IP sale credibility

**Deliverable:** GPU generates real VGA output.

### Day 33 (Friday) — Render the Triangle

**All day (6 hrs):**
- [ ] Connect command processor → SM → rasterizer → ROP → display
- [ ] Load the same triangle command from `test_system.py`
- [ ] Program FPGA, connect to monitor
- [ ] **RECORD A VIDEO OF THE TRIANGLE RENDERING**
- [ ] This is THE demo. The one you'll show buyers.

**Deliverable:** THE killer demo.

### Day 34 (Saturday) — Timing Closure

**Morning (3 hrs):**
- [ ] Run Vivado timing analysis
- [ ] Target: 50 MHz minimum (100 MHz ideal)
- [ ] Identify critical paths (probably in crossbar or memory)

**Afternoon (3 hrs):**
- [ ] Add pipeline registers on critical paths
- [ ] Re-synthesize, re-check timing
- [ ] Generate timing report: `fpga/timing_report.txt`

**Deliverable:** Timing closes at ≥50 MHz.

### Day 35 (Sunday) — Resource Utilization Report

**Morning (2 hrs):**
- [ ] Generate Vivado utilization report
- [ ] Capture: LUTs, FFs, BRAMs, DSPs, IOBs
- [ ] Calculate % utilization

**Afternoon (2 hrs):**
- [ ] Create `fpga/UTILIZATION.md`:
```markdown
# FPGA Utilization (Artix-7 100T)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs     | 41234| 63400     | 65%         |
| FFs      | 38122| 126800    | 30%         |
| BRAM     | 84   | 135       | 62%         |
| DSP      | 124  | 240       | 52%         |
| IOBs     | 23   | 210       | 11%         |

Target Frequency: 50 MHz (achieved)
Timing: Met with 5ns slack
```

**Deliverable:** Buyer-grade FPGA report.

---

## WEEK 6 (Days 36-42): VERIFICATION UPGRADE

### Day 36 (Monday) — Verification Contractor (Optional)

If you can afford ₹60K (≈$720) for a 1-month India-based verification
engineer, this is the highest-ROI spend of the entire roadmap.

**Morning (2 hrs):**
- [ ] Post job on:
  - LinkedIn (target: 2-3 yr experience VLSI engineers in Bangalore/Hyderabad)
  - Naukri.com
  - IIT Bombay / IIT Madras alumni groups
- [ ] Job description:
  - 1-month contract
  - Build UVM testbench for AXI4 crossbar
  - Achieve 85% functional coverage
  - Remote OK, ₹60K fixed

**Afternoon (2 hrs):**
- [ ] Interview 3-5 candidates
- [ ] Hire the best one (start tomorrow)

**If you can't afford this:** Do it yourself, it'll just take 3x longer.

**Deliverable:** Verification engineer hired (or self-learning plan committed).

### Day 37 (Tuesday) — UVM Foundation

**All day (6 hrs):**
- [ ] If self-doing: spend the day learning UVM basics
  - Watch: "UVM Basics" YouTube series (Doulos)
  - Read: "SystemVerilog UVM" by Accellera (free PDF)
- [ ] If hired: have them set up UVM environment:
  - `tb/uvm/titan_x5_env.sv`
  - `tb/uvm/axi_agent/`
  - `tb/uvm/scoreboard.sv`
  - `tb/uvm/sequences/`

**Deliverable:** UVM skeleton in place.

### Day 38 (Wednesday) — UVM Agent for AXI

**All day (6 hrs):**
- [ ] Build AXI4 agent:
  - Driver
  - Monitor
  - Sequencer
  - Sequence library (read, write, burst, error)
  - Coverage collector

**Deliverable:** AXI agent operational.

### Day 39 (Thursday) — UVM Scoreboard + Coverage

**All day (6 hrs):**
- [ ] Build scoreboard: predicts expected output, compares to actual
- [ ] Define functional coverage:
  - AXI transaction types
  - Address ranges
  - Burst lengths
  - Command opcodes
  - Memory access patterns

**Deliverable:** Scoreboard + coverage model live.

### Day 40 (Friday) — Constrained Random Tests

**All day (6 hrs):**
- [ ] Write 10 constrained-random test sequences
- [ ] Run with 1000 random seeds
- [ ] File all failures as bugs
- [ ] Track coverage progression

**Deliverable:** 85% functional coverage target.

### Day 41 (Saturday) — Formal Verification (Stretch)

**Morning (3 hrs):**
- [ ] Try SymbiYosys (free, open source formal verifier):
```bash
sudo apt install sby
```
- [ ] Write simple formal properties for crossbar:
```verilog
// Crossbar never drops a request
assert property (@(posedge clk) m_req_valid |-> ##[1:10] m_req_ready);
```

**Afternoon (3 hrs):**
- [ ] Run formal on ALU, crossbar, command processor
- [ ] Fix any counterexamples found

**Deliverable:** Formal verification baseline.

### Day 42 (Sunday) — Verification Documentation Update

- [ ] Update `docs/VERIFICATION.md` with new UVM details
- [ ] Update coverage numbers
- [ ] Update README badges with coverage %
- [ ] Rest

---

## WEEK 7 (Days 43-49): SOFTWARE STACK STUB

A GPU without a driver is useless. Build a minimal software stack.

### Day 43 (Monday) — Driver Skeleton

**All day (6 hrs):**
- [ ] Create `driver/` directory structure:
```
driver/
├── include/
│   ├── titan_x5.h         # Public API
│   └── titan_x5_regs.h    # Register definitions
├── linux/
│   ├── titan_x5_drv.c     # Linux kernel driver stub
│   └── Makefile
├── baremetal/
│   └── titan_x5_bare.c    # Bare-metal library
└── examples/
    ├── hello_triangle.c
    └── clear_screen.c
```

- [ ] Define register map in `titan_x5_regs.h`:
```c
#define TITAN_X5_REG_CMD_FIFO_BASE   0x00
#define TITAN_X5_REG_CMD_FIFO_WPTR   0x08
#define TITAN_X5_REG_CMD_FIFO_RPTR   0x0C
#define TITAN_X5_REG_FB_BASE         0x10
#define TITAN_X5_REG_FB_SIZE         0x14
#define TITAN_X5_REG_STATUS          0x20
#define TITAN_X5_REG_INTR            0x24
// ... etc
```

**Deliverable:** Driver skeleton.

### Day 44 (Tuesday) — Bare-metal Library

**All day (6 hrs):**
- [ ] Implement `titan_x5_bare.c`:
  - `titan_x5_init()` — reset GPU, set up VRAM
  - `titan_x5_draw_triangle()` — submit CMD_DRAW
  - `titan_x5_clear()` — submit CMD_CLEAR
  - `titan_x5_flush()` — submit CMD_FENCE
  - `titan_x5_wait_idle()` — poll status

- [ ] Write `examples/hello_triangle.c`:
```c
#include "titan_x5.h"

int main() {
    titan_x5_init();
    titan_x5_clear(0x000000);  // black
    titan_x5_draw_triangle(0, 0, 100, 0, 50, 100, 0xFFFFFF);
    titan_x5_flush();
    titan_x5_wait_idle();
    return 0;
}
```

**Deliverable:** Working bare-metal API.

### Day 45 (Wednesday) — Linux Driver Stub

**All day (6 hrs):**
- [ ] Implement minimal Linux DRM driver:
  - Probe function
  - MMIO setup
  - IRQ handler stub
  - DRM framebuffer allocation
  - Basic modesetting (placeholder)

- [ ] This doesn't need to be production. It needs to exist as proof
      that the GPU is usable from Linux.

**Deliverable:** Linux driver compiles + loads.

### Day 46 (Thursday) — Shader Compiler Stub

**All day (6 hrs):**
- [ ] Define your ISA in `docs/ISA.md`:
  - Instruction formats
  - Opcodes
  - Register file
  - Addressing modes

- [ ] Write a tiny assembler in Python:
  - Input: simple .asm files
  - Output: binary instruction stream
  - Even 10 instructions is enough

- [ ] Example:
```python
# tools/assembler.py
./tasm hello.asm -o hello.bin
```

**Deliverable:** Working assembler.

### Day 47 (Friday) — OpenGL ES Subset (Stretch)

**All day (6 hrs):**
- [ ] If you have time/energy: write a minimal OpenGL ES wrapper
- [ ] Even just `glClear`, `glBegin`, `glEnd`, `glVertex` is enough
- [ ] This makes the GPU usable from "real" graphics code

**Deliverable:** Minimal GL wrapper.

### Day 48 (Saturday) — Reference SoC

**All day (6 hrs):**
- [ ] Create `soc/` directory
- [ ] Build a reference SoC:
  - RISC-V core (use PicoRV32 or VexRiscv, free)
  - Your GPU
  - AXI interconnect
  - DDR3 controller (use LiteDRAM, free)
  - UART for debug
- [ ] Synthesize the SoC
- [ ] Run on FPGA

**Deliverable:** Reference SoC running on FPGA.

### Day 49 (Sunday) — Software Stack Documentation

- [ ] Write `docs/SOFTWARE_STACK.md`
- [ ] Write `docs/INTEGRATION_GUIDE.md` (update)
- [ ] Rest

---

## WEEK 8 (Days 50-56): POLISH + LAUNCH PREP

### Day 50 (Monday) — Demo Video

**All day (6 hrs):**
- [ ] Record a 60-second demo video:
  - 0-10s: Show your face, "I'm Adhiraj, I built a GPU"
  - 10-25s: Show code on screen (architecture diagram, key modules)
  - 25-40s: Show FPGA running, monitor showing VGA output
  - 40-50s: Show waveform / GTKWave trace
  - 50-60s: Show final rendered image, "Titan X5-B, open + commercial license"
- [ ] Edit in DaVinci Resolve (free)
- [ ] Upload to YouTube unlisted (you'll publish in Month 3)

**Deliverable:** Demo video recorded.

### Day 51 (Tuesday) — Website

**All day (6 hrs):**
- [ ] Build a one-page landing site:
  - Hero: "Titan X5-B GPU IP"
  - Sub: "Open-source Blackwell-class GPU, commercially licenseable"
  - Architecture diagram
  - Specs table
  - Demo video embed
  - "Commercial License" CTA button → email
  - "View on GitHub" button
- [ ] Use Next.js + Tailwind (you already have this project!)
  - Or use Astro / plain HTML if faster
- [ ] Deploy to Vercel or Cloudflare Pages (free)

**Deliverable:** Live website.

### Day 52 (Wednesday) — Technical Blog Posts

**All day (6 hrs):**
- [ ] Write 2 blog posts for your site:
  1. "How I built a 3M-gate GPU in 90 days"
  2. "5 critical bugs in my own GPU RTL (and how cocotb caught them)"
- [ ] Each post: 2000-3000 words, with code snippets, diagrams, photos

**Deliverable:** 2 high-quality blog posts.

### Day 53 (Thursday) — Case Studies

**All day (6 hrs):**
- [ ] Write 3 case studies (even hypothetical ones):
  1. "Display SoC for IoT: How Titan X5-B fits"
  2. "Educational use case: Teaching GPU architecture at IIT"
  3. "RISC-V SoC integration: A reference design"
- [ ] These help buyers see themselves using your IP

**Deliverable:** 3 case studies.

### Day 54 (Friday) — NLnet Grant Application

**All day (6 hrs):**
- [ ] Draft NLnet grant application:
  - Project name
  - Abstract (200 words)
  - Problem (500 words)
  - Solution (1000 words)
  - Technical approach (1500 words)
  - Budget (8 months, €25K-€50K)
  - Team (just you, but emphasize expertise)
  - Impact (500 words)
  - Open source commitment
- [ ] Submit at https://nlnet.nl/propose/

**Deliverable:** NLnet grant submitted.

### Day 55 (Saturday) — DLI Grant Application (India)

**All day (6 hrs):**
- [ ] Apply for India DLI Scheme:
  - https://www.meity.gov.in/dli
  - Talk to a CA first (~₹2K consulting fee)
  - Prepare: LLP registration, project report, budget, timeline
  - Target: ₹50 lakh - ₹15 crore reimbursement

**Deliverable:** DLI application in progress.

### Day 56 (Sunday) — Rest + Month 2 Review

- [ ] Rest
- [ ] 2 hours: Month 2 review
  - FPGA working? ✅
  - UVM verified? ✅
  - Software stack? ✅
  - Grants submitted? ✅
- [ ] Plan Month 3

---

# 📅 MONTH 3 — GO TO MARKET

The goal of Month 3: start sales conversations. Get eval licenses
signed. Begin the path to first revenue.

---

## WEEK 9 (Days 57-63): BUYER LIST + OUTREACH

### Day 57 (Monday) — Build the Buyer List

**All day (6 hrs):**
- [ ] Open a spreadsheet (Google Sheets or Notion database)
- [ ] Columns: Company, Type, Contact Name, Title, Email, LinkedIn,
      GitHub, Last Contact, Status, Notes

- [ ] Add 50 target companies:
  - 10 RISC-V SoC startups (SiFive, Tenstorrent, Ventana, Esperanto,
    InCore, etc.)
  - 10 Chinese fabless (Allwinner, Rockchip, Actions, etc.)
  - 10 display/automotive (TI, NXP, Renesas clusters)
  - 10 Indian fabless (Signalchip, InCore, etc.)
  - 10 universities / research labs

- [ ] For each: find the right person (Director of Eng, VP Hardware,
      IP Procurement, or CTO if small startup)

**Deliverable:** 50-company buyer list.

### Day 58 (Tuesday) — Cold Email Campaign Round 1

**All day (6 hrs):**
- [ ] Personalize the cold email template for each of the top 10 targets
- [ ] Send 10 emails today
- [ ] Track in your CRM (HubSpot Free or Notion)

Email template (copy `04-DOCS/COLD_EMAIL_TEMPLATES.md`):

```
Subject: Open Blackwell-class GPU IP — FPGA-proven, commercial license available

Hi [First Name],

I noticed [Company] is building [product] and likely needs GPU IP
for [display/compute/edge AI]. I've built Titan X5-B, a 3M-gate
GPU in SystemVerilog:

- Synthesizable on Yosys + Vivado
- FPGA-proven on Artix-7 (50 MHz, VGA output working)
- Verified with cocotb (X% functional coverage)
- Dual-licensed: CERN-OHL-S for OSS, commercial license available
- 4 SMs (32-thread SIMT), 16×16 FP16 tensor core, AXI4 crossbar,
  ray tracing, neural shader dispatch

It's not Mali or PowerVR — it's a clean-room educational-grade
design hardened to commercial-adjacent quality. Could fit display
SoCs, IoT, embedded compute at a fraction of Arm/Imagination pricing.

I'm attaching the product brief and a link to the demo video.
Worth a 20-minute call next week?

Best,
Adhiraj
Founder, [Your LLP Name]
[Email] | [LinkedIn] | [Demo video] | [GitHub]
```

**Deliverable:** 10 emails sent.

### Day 59 (Wednesday) — Cold Email Campaign Round 2

**All day (6 hrs):**
- [ ] Send 10 more personalized emails
- [ ] Respond to any replies from yesterday
- [ ] Follow up on LinkedIn (connect request) with everyone you emailed

**Deliverable:** 20 emails sent total.

### Day 60 (Thursday) — Cold Email Campaign Round 3

**All day (6 hrs):**
- [ ] Send 10 more emails
- [ ] Handle replies, book calls

**Deliverable:** 30 emails sent total.

### Day 61 (Friday) — Cold Email Campaign Round 4

**All day (6 hrs):**
- [ ] Send 10 more emails (last batch of 50)
- [ ] Handle replies
- [ ] Book calls for Week 10

**Deliverable:** 50 emails sent total.

### Day 62 (Saturday) — Conference Talk Submissions

**All day (6 hrs):**
- [ ] Submit talk proposals to:
  - FOSDEM 2026 (Open Hardware devroom)
  - Embedded World India 2025
  - OSDC 2025
  - Hackaday Supercon (call for proposals)
  - RISC-V Summit Europe

- [ ] Talk title options:
  - "Building a 3M-Gate GPU in 90 Days: Lessons from Titan X5-B"
  - "Open Hardware GPU IP: A Practical Path to Commercial Licensing"
  - "Cocotb + Yosys: Verifying Open Silicon Without Breaking the Bank"

**Deliverable:** 3-5 talk proposals submitted.

### Day 63 (Sunday) — Rest + Weekly Review

- [ ] Rest
- [ ] Review: how many replies? How many calls booked?
- [ ] Plan Week 10

---

## WEEK 10 (Days 64-70): SALES CALLS + NDA NEGOTIATIONS

### Day 64-70 — Sales Calls

For each call you booked:
- [ ] Prepare: send NDA 24 hours before (use `01-LEGAL/NDA-TEMPLATE.md`)
- [ ] 30-min call structure:
  - 5 min: intros
  - 10 min: your pitch (use slide deck)
  - 10 min: their use case + technical Q&A
  - 5 min: next steps (eval license?)
- [ ] Follow-up email same day with:
  - Architecture spec attached
  - Demo video link
  - Proposed eval license terms

**Goal for Week 10:** Sign 1-2 mutual NDAs. Get 1 company to request
eval license terms.

---

## WEEK 11 (Days 71-77): FIRST EVAL LICENSE

### Day 71-77 — Negotiate First Eval License

- [ ] Draft eval license (use `01-LEGAL/EVAL-LICENSE-TEMPLATE.md`)
- [ ] Eval terms:
  - 90-day evaluation period
  - Encrypted or obfuscated RTL (or full source under NDA)
  - No commercial use during eval
  - $0 fee (or nominal $5K fee to filter serious buyers)
  - Option to convert to commercial license

- [ ] Send to interested company
- [ ] Iterate on terms
- [ ] Get signed

**Goal:** First eval license signed by end of Week 11.

---

## WEEK 12 (Days 78-84): CONTENT MARKETING BLITZ

### Day 78 — Hacker News Launch

- [ ] Post to Hacker News (Tuesday or Wednesday 8am PT)
- [ ] Title: "Show HN: I built a 3M-gate Blackwell-class GPU in SystemVerilog"
- [ ] Have 3-4 friends ready to upvote in first hour
- [ ] Be ready to respond to every comment for 24 hours

### Day 79 — Reddit + LinkedIn

- [ ] Post to r/hardware, r/FPGA, r/embedded, r/RISCV
- [ ] LinkedIn carousel post
- [ ] Twitter/X thread (15 tweets)

### Day 80 — Press Outreach

- [ ] Email Tom's Hardware, ServeTheHome, Hackster.io tips
- [ ] Email Indian press: Inc42, YourStory, FactorDaily
- [ ] Email SemiAnalysis, The Next Platform

### Day 81-83 — Engage + Capture

- [ ] Respond to every comment, DM, email
- [ ] Add every interested person to CRM
- [ ] Add newsletter signups to Substack

### Day 84 — Week Review

- [ ] How many GitHub stars gained?
- [ ] How many newsletter subs?
- [ ] How many new sales leads?

---

## WEEK 13 (Days 85-90): CLOSE OUT + PLAN MONTH 4+

### Day 85-87 — NLnet Grant Follow-up

- [ ] Email NLnet to confirm receipt
- [ ] Be ready to answer questions / provide more detail

### Day 88 — DLI Grant Follow-up

- [ ] Follow up on DLI application
- [ ] Talk to your CA about any missing docs

### Day 89 — Phase 1 Final Review

Spend 3 hours answering:

1. **Legal:** Is dual-license live? LLP registered? CLA enforced?
2. **Technical:** Synth clean? FPGA working? UVM at 85% coverage?
3. **Documentation:** All 6 docs complete? Product brief polished?
4. **CI:** Green on every push? Coverage reporting live?
5. **Sales:** 50 emails sent? How many calls? Any NDAs? Eval licenses?
6. **Grants:** NLnet submitted? DLI submitted? Any other grants?
7. **Brand:** Demo video done? Website live? Blog posts published?
8. **Press:** Hacker News launch done? Any press coverage?

Score yourself:
- 8/8 = A+, ready for Phase 2 (commercial licensing)
- 6-7/8 = B, you're ahead of 95% of indie devs
- 4-5/8 = C, you have the foundation, push harder in Month 4
- <4/8 = reassess and recommit

### Day 90 — Plan Phase 2

- [ ] Write `PHASE2_PLAN.md` based on Day 89 review
- [ ] Set 90-day goals for Months 4-6
- [ ] Commit to next 90 days

---

# 📊 PROGRESS TRACKING

Use `05-TRACKING/WEEKLY-CHECKLIST.md` and `05-TRACKING/DAILY-LOG.md`
to track progress. Update them every day.

## Key Metrics to Track Weekly

| Metric | Day 0 | Day 30 | Day 60 | Day 90 |
|--------|-------|--------|--------|--------|
| GitHub stars | 1 | 10 | 50 | 200+ |
| Synth warnings | 50+ | 5 | 0 | 0 |
| Cocotb tests | 3 | 20 | 100 | 200+ |
| Functional coverage | 0% | 20% | 50% | 70%+ |
| FPGA MHz | N/A | 0 | 25 | 50+ |
| Documentation pages | 5 | 50 | 150 | 250+ |
| Buyer emails sent | 0 | 0 | 0 | 50+ |
| NDAs signed | 0 | 0 | 0 | 1-3 |
| Eval licenses | 0 | 0 | 0 | 0-1 |
| Cash invested | $0 | $50 | $400 | $500 |
| Cash earned | $0 | $0 | $0 | $0-5K |

**Note on cash earned:** Realistic expectation for Phase 1 is $0.
First revenue typically comes in Months 12-18. Phase 1 is about
building the asset and starting conversations.

---

# 🎯 WHAT TO DO RIGHT NOW

Stop reading. Open your terminal. Do this:

```bash
# 1. Copy the dual-license files to your repo
cp 01-LEGAL/LICENSE.md /path/to/your/repo/LICENSE
cp 01-LEGAL/COMMERCIAL.md /path/to/your/repo/

# 2. Fix the GAAFET bug
cp 02-RTL-FIXES/titan_x_3nm_gaafet_optimizer_FIXED.v \
   /path/to/your/repo/rtl/titan_x_3nm_gaafet_optimizer.v

# 3. Add CI
mkdir -p /path/to/your/repo/.github/workflows
cp 03-CI/ci.yml /path/to/your/repo/.github/workflows/

# 4. Commit and push
cd /path/to/your/repo
git add -A
git commit -m "phase 1: dual-license + GAAFET fix + CI"
git push

# 5. Email a lawyer about LLP registration (use the email template
#    in 01-LEGAL/LAWYER_OUTREACH.md)
```

You can be at Day 1 complete in 2 hours.

GO. 🚀
