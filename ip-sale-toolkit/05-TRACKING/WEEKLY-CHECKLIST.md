# Phase 1 Weekly Checklist — Titan X5-B IP Sale

Print this. Tape it to your wall. Check off every box. Don't skip days.

---

## WEEK 1 — LEGAL FOUNDATION (Days 1-7)

### Day 1 — License Audit + Lawyer Search
- [ ] Read current LICENSE file end-to-end
- [ ] Confirm CERN-OHL-S-2.0 (strongly reciprocal)
- [ ] Research dual licensing (read Wikipedia + Qt/MongoDB examples)
- [ ] Email 3 IP lawyers for quotes (or decide to use template)
- [ ] Book lawyer OR commit to template approach

### Day 2 — Apply Dual License
- [ ] Copy `LICENSE.md` to repo as new `LICENSE`
- [ ] Copy `COMMERCIAL.md` to repo root
- [ ] Update `README.md` with Licensing section
- [ ] Buy domain name (~$10/year)
- [ ] Set up professional email forward
- [ ] Create `CONTACT.md` with commercial inquiry instructions
- [ ] Commit: `license: dual-license for commercial use`

### Day 3 — CLA Setup
- [ ] Copy `CLA-INDIVIDUAL.md` and `CLA-CORPORATE.md` to `.github/CLA/`
- [ ] Sign up for CLA Assistant (https://cla-assistant.io)
- [ ] Connect GitHub account, add repo
- [ ] Create `.github/FUNDING.yml` with sponsor tiers
- [ ] Enable GitHub Sponsors
- [ ] Update `CONTRIBUTING.md` to require CLA
- [ ] Commit: `legal: add CLA + funding channels`

### Day 4 — LLP Registration (Start)
- [ ] Pick 3 company name options, check MCA availability
- [ ] Get Digital Signature Certificate (DSC) (~₹1K-2K)
- [ ] File name reservation (RUN-LLP, ₹200)
- [ ] Draft LLP agreement (or hire CA, ~₹3K)

### Day 5 — LLP Registration (Finish)
- [ ] File FiLLiP form (LLP incorporation, ~₹5K-8K)
- [ ] Get Certificate of Incorporation
- [ ] Apply for GST registration (free)
- [ ] Open current account in LLP name
- [ ] Apply for Startup India recognition (free)
- [ ] Update LinkedIn + GitHub with company name
- [ ] Commit: `legal: LLP incorporated`

### Day 6 — Banking + Tools Setup
- [ ] Set up Stripe or Razorpay (accept license payments)
- [ ] Set up accounting (Zoho Books free)
- [ ] Set up CRM (HubSpot Free or Notion)
- [ ] Create LinkedIn company page
- [ ] Create Twitter/X handle
- [ ] Write 1-paragraph company About
- [ ] Design logo (Canva free, 30 min)
- [ ] Build simple landing page (GitHub Pages or Cloudflare Pages)

### Day 7 — REST + Review
- [ ] Sleep in
- [ ] 30 min: weekly review
- [ ] 30 min: plan Week 2
- [ ] 1 hr: read /r/FPGA, HN, semi Twitter

---

## WEEK 2 — TECHNICAL DEBT CLEANUP (Days 8-14)

### Day 8 — Fix GAAFET Bug
- [ ] Read `02-RTL-FIXES/titan_x_3nm_gaafet_optimizer_FIXED.v`
- [ ] Copy patched file to `rtl/titan_x_3nm_gaafet_optimizer.v`
- [ ] Update any parent module that instantiates GAAFET (port connections)
- [ ] Run Yosys on GAAFET module alone — confirm zero errors
- [ ] Run full expanded synth — confirm no errors
- [ ] Commit: `fix(rtl): GAAFET unpacked array ports → packed bus`

### Day 9 — Fix translate_off + Other Warnings
- [ ] `grep -rn "translate_off" rtl/` — find every instance
- [ ] Replace each with `` `ifdef SIMULATION `` ... `` `endif ``
- [ ] Add `-DSIMULATION` to Icarus/cocotb compile flags
- [ ] Do NOT add `-DSIMULATION` to Yosys/Vivado synth commands
- [ ] Run expanded synth, save log as `synthesis_report_expanded_clean.txt`
- [ ] Screenshot final `stat` output (gate count breakdown)
- [ ] Commit: `fix(rtl): replace translate_off with SYNTHESIS ifdef`

### Day 10 — Add RAM Style Attributes
- [ ] Run `python3 02-RTL-FIXES/apply_ram_style.py /path/to/your/repo/rtl`
- [ ] Review changes with `git diff`
- [ ] Remove `(* ram_style="block" *)` from any memory you want as registers
- [ ] Run synth again, check if gate count dropped
- [ ] Commit: `perf(rtl): add ram_style attributes for BRAM inference`

### Day 11 — Code Cleanup + Linting
- [ ] Install Verilator (free)
- [ ] Run `verilator --lint-only -Wall rtl/**/*.v`
- [ ] Fix every UNOPTFLAT, WIDTH, CASEINCOMPLETE warning
- [ ] Standardize naming (per CONTRIBUTING.md)
- [ ] Add file headers to every .v file
- [ ] Commit: `chore: lint cleanup + standardized headers`

### Day 12 — `.gitignore` + Repo Hygiene
- [ ] Update `.gitignore` (build artifacts, editors, OS, EDA)
- [ ] `git rm -r --cached sim_build/`
- [ ] Reorganize repo per industry convention (rtl, tb, sim, syn, fpga, docs)
- [ ] Commit: `chore: reorganize repo, fix .gitignore`

### Day 13 — Synthesis Report Polish
- [ ] Run final clean synthesis with `stat > syn/synthesis_stats.txt`
- [ ] Generate JSON summary of gate counts
- [ ] Create `syn/REPORT.md` with breakdown + comparison
- [ ] Generate pie chart + bar chart (matplotlib)
- [ ] Save visualizations to `docs/assets/synth_breakdown.png`
- [ ] Commit: `syn: clean report + visualizations`

### Day 14 — REST + Review
- [ ] Rest
- [ ] 30 min: weekly review
- [ ] Plan Week 3

---

## WEEK 3 — CI + AUTOMATION (Days 15-21)

### Day 15 — GitHub Actions CI Setup
- [ ] Copy `03-CI/ci.yml` to `.github/workflows/ci.yml`
- [ ] Push to GitHub, watch first CI run
- [ ] Fix any CI failures
- [ ] Add CI badges to README
- [ ] Commit: `ci: GitHub Actions workflow + badges`

### Day 16 — Expand Cocotb Tests
- [ ] Inventory current tests
- [ ] Identify gaps (ALU, crossbar, cache, TMU, display)
- [ ] Write 5 new directed tests:
  - [ ] `test_alu_ops.py`
  - [ ] `test_crossbar_routing.py`
  - [ ] `test_cache_coherence.py`
  - [ ] `test_texture_sampling.py`
  - [ ] `test_display_timing.py`
- [ ] Commit: `test: 5 new directed cocotb tests`

### Day 17 — Coverage Reporting
- [ ] Enable `cocotb_coverage` in tests
- [ ] Generate HTML coverage report
- [ ] Add coverage upload to CI (upload-artifact)
- [ ] Set coverage target: 60%
- [ ] Commit: `test: coverage reporting`

### Day 18 — Regression Suite
- [ ] Create `sim/regression.py` — runs all tests, reports pass/fail
- [ ] Add `make regression` target to Makefile
- [ ] Add random seed support to cocotb tests
- [ ] Run 100 random seeds, log results
- [ ] File failures as GitHub Issues
- [ ] Commit: `test: regression suite + random seeds`

### Day 19 — Bug Triage Day
- [ ] Run regression with 500 random seeds
- [ ] File all failures as GitHub Issues (with repro steps + seed)
- [ ] Fix top 5 most critical bugs
- [ ] Write regression test for each fix
- [ ] Commit: `fix: 5 bugs from regression + regression tests`

### Day 20 — Performance Benchmarks
- [ ] Write `sim/benchmark.py` — measures:
  - [ ] Triangles/sec
  - [ ] Pixels/sec
  - [ ] ALU ops/sec
  - [ ] Memory bandwidth
  - [ ] Command-to-display latency
- [ ] Run benchmarks, save to `docs/BENCHMARKS.md`
- [ ] Compare to Vortex, Nyuzi, Mali-400, PowerVR Series8XE
- [ ] Commit: `perf: benchmark suite + comparison table`

### Day 21 — REST + Month 1 Review
- [ ] Rest
- [ ] 1 hour: Month 1 review (what got done, what slipped)

---

## WEEK 4 — DOCUMENTATION ARSENAL (Days 22-28)

### Day 22 — Architecture Spec
- [ ] Copy `04-DOCS/ARCHITECTURE.md` to `docs/ARCHITECTURE.md`
- [ ] Fill in every section (overview, block diagram, hierarchy, data flow, etc.)
- [ ] Add diagrams (draw.io, export SVG)
- [ ] Commit: `docs: architecture spec`

### Day 23 — Microarchitecture Spec (Part 1)
- [ ] Start `docs/MICROARCHITECTURE.md`
- [ ] Document: SM, ALU, register file, pipeline, decoder, warp scheduler
- [ ] Each module: 5-10 pages with diagrams

### Day 24 — Microarchitecture Spec (Part 2)
- [ ] Document remaining modules: crossbar, command processor, rasterizer,
      TMU, ROP, RT core, tensor core, memory, display, power
- [ ] Total: 100+ pages

### Day 25 — Verification Plan
- [ ] Copy `04-DOCS/VERIFICATION.md` to `docs/VERIFICATION.md`
- [ ] Fill in: methodology, test plan, coverage model, regression
- [ ] Commit: `docs: verification plan`

### Day 26 — Datasheet + Integration Guide
- [ ] Copy `04-DOCS/DATASHEET.md` to `docs/DATASHEET.md`
- [ ] Fill in: pinout, electrical specs, performance, package
- [ ] Write `docs/INTEGRATION_GUIDE.md`

### Day 27 — Product Brief + Pitch Deck
- [ ] Copy `04-DOCS/PRODUCT-BRIEF.md` to `docs/PRODUCT-BRIEF.md`
- [ ] Polish to 2 pages max
- [ ] Build 10-slide pitch deck (Google Slides or Pitch.com):
  - [ ] Cover slide
  - [ ] Problem
  - [ ] Solution
  - [ ] Architecture diagram
  - [ ] Specs table
  - [ ] Verification status
  - [ ] Roadmap
  - [ ] Market
  - [ ] Business model
  - [ ] Contact + CTA

### Day 28 — Month 1 Final Review
- [ ] 2 hours: Month 1 final review
- [ ] Score yourself on 8 dimensions (legal, tech, CI, tests, docs, etc.)
- [ ] Identify what slipped to Month 2

---

## WEEK 5 — FPGA HARDWARE SETUP (Days 29-35)

### Day 29 — Order FPGA Hardware
- [ ] Order from Digi-Key / Mouser / Robu.in:
  - [ ] Digilent Arty A7-100T ($130) OR Tang Mega 138K Pro (₹7,000)
  - [ ] Pmod VGA ($15)
  - [ ] Pmod OLED (optional, $20)
- [ ] Install FPGA vendor tools (Vivado / Gowin EDA / Lattice Diamond)

### Day 30 — FPGA Target Architecture
- [ ] Plan FPGA target (full GPU won't fit; reduce to 1 SM, 4×4 tensor, 8KB L1)
- [ ] Add parameter overrides in `titan_x5_gpu_top.v`
- [ ] Create `fpga/titan_x5_gpu_top_fpga.v` wrapper with FPGA configs
- [ ] Create `fpga/constraints/arty_a7.xdc` constraints file

### Day 31 — Hello World LED
- [ ] Synthesize minimal design: command processor + 1 SM + LED output
- [ ] Generate bitstream, program FPGA
- [ ] **TAKE A PHOTO OF THE LED LIT UP** (marketing gold!)

### Day 32 — VGA Output
- [ ] Connect Pmod VGA to FPGA
- [ ] Synthesize display engine + framebuffer
- [ ] Pre-load framebuffer with static pattern (color bars)
- [ ] Program FPGA, connect to monitor
- [ ] **TAKE A PHOTO OF THE MONITOR SHOWING GPU OUTPUT**

### Day 33 — Render the Triangle
- [ ] Connect full pipeline: command → SM → rasterizer → ROP → display
- [ ] Load triangle command from `test_system.py`
- [ ] Program FPGA, connect to monitor
- [ ] **RECORD A VIDEO OF THE TRIANGLE RENDERING** (THE killer demo)

### Day 34 — Timing Closure
- [ ] Run Vivado timing analysis
- [ ] Target: 50 MHz minimum (100 MHz ideal)
- [ ] Identify critical paths
- [ ] Add pipeline registers on critical paths
- [ ] Re-synthesize, re-check timing
- [ ] Generate timing report: `fpga/timing_report.txt`

### Day 35 — Resource Utilization Report
- [ ] Generate Vivado utilization report
- [ ] Capture: LUTs, FFs, BRAMs, DSPs, IOBs
- [ ] Create `fpga/UTILIZATION.md` with utilization table

---

## WEEK 6 — VERIFICATION UPGRADE (Days 36-42)

### Day 36 — Verification Contractor (Optional)
- [ ] If budget allows (~₹60K), post job on LinkedIn/Naukri
- [ ] Interview 3-5 candidates
- [ ] Hire (start tomorrow)
- [ ] If solo: commit to learning UVM basics this week

### Day 37 — UVM Foundation
- [ ] Self-doing: watch Doulos UVM Basics series, read Accellera UVM PDF
- [ ] Hired: have them set up UVM environment skeleton
- [ ] Create `tb/uvm/` directory structure

### Day 38 — UVM Agent for AXI
- [ ] Build AXI4 agent: driver, monitor, sequencer, sequences, coverage
- [ ] Test agent in isolation

### Day 39 — UVM Scoreboard + Coverage
- [ ] Build scoreboard: predict expected, compare to actual
- [ ] Define functional coverage items
- [ ] Add coverage collector

### Day 40 — Constrained Random Tests
- [ ] Write 10 constrained-random test sequences
- [ ] Run with 1000 random seeds
- [ ] File failures as bugs
- [ ] Track coverage progression (target: 85%)

### Day 41 — Formal Verification (Stretch)
- [ ] Install SymbiYosys (`sudo apt install sby`)
- [ ] Write formal properties for crossbar, ALU, command processor
- [ ] Run formal, fix counterexamples

### Day 42 — Verification Documentation Update
- [ ] Update `docs/VERIFICATION.md` with UVM details
- [ ] Update coverage numbers
- [ ] Update README badges with coverage %
- [ ] Rest

---

## WEEK 7 — SOFTWARE STACK STUB (Days 43-49)

### Day 43 — Driver Skeleton
- [ ] Create `driver/` directory structure
- [ ] Define register map in `titan_x5_regs.h`
- [ ] Stub out public API in `titan_x5.h`

### Day 44 — Bare-metal Library
- [ ] Implement `titan_x5_bare.c`: init, draw_triangle, clear, flush, wait_idle
- [ ] Write `examples/hello_triangle.c`
- [ ] Test on FPGA (or simulation)

### Day 45 — Linux Driver Stub
- [ ] Implement minimal Linux DRM driver: probe, MMIO, IRQ stub, FB alloc
- [ ] Verify compiles + loads
- [ ] Don't need production — just needs to exist as proof

### Day 46 — Shader Compiler Stub
- [ ] Define ISA in `docs/ISA.md`
- [ ] Write tiny assembler in Python (10 instructions is enough)
- [ ] Test: `./tasm hello.asm -o hello.bin`

### Day 47 — OpenGL ES Subset (Stretch)
- [ ] Write minimal OpenGL ES wrapper
- [ ] Implement: glClear, glBegin, glEnd, glVertex, glColor
- [ ] Even this much makes GPU usable from "real" graphics code

### Day 48 — Reference SoC
- [ ] Create `soc/` directory
- [ ] Build reference SoC: PicoRV32 RISC-V + Titan X5-B + LiteDRAM + UART
- [ ] Synthesize, run on FPGA

### Day 49 — Software Stack Documentation
- [ ] Write `docs/SOFTWARE_STACK.md`
- [ ] Update `docs/INTEGRATION_GUIDE.md`
- [ ] Rest

---

## WEEK 8 — POLISH + LAUNCH PREP (Days 50-56)

### Day 50 — Demo Video
- [ ] Record 60-second demo video:
  - [ ] 0-10s: Your face + intro
  - [ ] 10-25s: Code on screen
  - [ ] 25-40s: FPGA running, monitor showing VGA
  - [ ] 40-50s: Waveform / GTKWave
  - [ ] 50-60s: Final rendered image + tagline
- [ ] Edit in DaVinci Resolve (free)
- [ ] Upload to YouTube unlisted

### Day 51 — Website
- [ ] Build one-page landing site
- [ ] Deploy to Vercel or Cloudflare Pages (free)
- [ ] Sections: Hero, Architecture, Specs, Demo video, CTAs

### Day 52 — Technical Blog Posts
- [ ] Write 2 blog posts:
  - [ ] "How I built a 3M-gate GPU in 90 days"
  - [ ] "5 critical bugs in my own GPU RTL (and how cocotb caught them)"
- [ ] Each 2000-3000 words, with code + diagrams + photos

### Day 53 — Case Studies
- [ ] Write 3 case studies:
  - [ ] "Display SoC for IoT: How Titan X5-B fits"
  - [ ] "Educational use case: Teaching GPU architecture at IIT"
  - [ ] "RISC-V SoC integration: A reference design"

### Day 54 — NLnet Grant Application
- [ ] Draft NLnet grant proposal (use template in `04-DOCS/`)
- [ ] Sections: Abstract, Problem, Solution, Approach, Budget, Impact
- [ ] Submit at https://nlnet.nl/propose/

### Day 55 — DLI Grant Application (India)
- [ ] Talk to CA (~₹2K consulting fee)
- [ ] Prepare LLP registration, project report, budget, timeline
- [ ] Apply at https://www.meity.gov.in/dli
- [ ] Target: ₹50 lakh - ₹15 crore reimbursement

### Day 56 — Rest + Month 2 Review
- [ ] Rest
- [ ] 2 hours: Month 2 review (FPGA working? UVM verified? Software stack?)

---

## WEEK 9 — BUYER LIST + OUTREACH (Days 57-63)

### Day 57 — Build the Buyer List
- [ ] Open spreadsheet (Google Sheets or Notion)
- [ ] Columns: Company, Type, Contact Name, Title, Email, LinkedIn, Last Contact, Status, Notes
- [ ] Add 50 target companies:
  - [ ] 10 RISC-V SoC startups (SiFive, Tenstorrent, Ventana, Esperanto, InCore)
  - [ ] 10 Chinese fabless (Allwinner, Rockchip, Actions)
  - [ ] 10 display/automotive (TI, NXP, Renesas)
  - [ ] 10 Indian fabless (Signalchip, InCore)
  - [ ] 10 universities / research labs
- [ ] Find right person for each (Director of Eng, VP HW, IP Procurement, CTO)

### Day 58 — Cold Email Round 1
- [ ] Personalize email template for top 10 targets (use `COLD_EMAIL_TEMPLATES.md`)
- [ ] Send 10 emails today
- [ ] Track in CRM
- [ ] Connect on LinkedIn with everyone you emailed

### Day 59 — Cold Email Round 2
- [ ] Send 10 more personalized emails (20 total)
- [ ] Respond to any replies from yesterday
- [ ] Book calls

### Day 60 — Cold Email Round 3
- [ ] Send 10 more emails (30 total)
- [ ] Handle replies, book calls

### Day 61 — Cold Email Round 4
- [ ] Send 10 more emails (40 total)
- [ ] Handle replies

### Day 62 — Cold Email Round 5
- [ ] Send 10 more emails (50 total — your first milestone!)
- [ ] Handle replies
- [ ] Book calls for Week 10

### Day 63 — Conference Talk Submissions
- [ ] Submit talks to: FOSDEM, Embedded World India, OSDC, Hackaday Supercon, RISC-V Summit EU
- [ ] 3-5 talk proposals total

---

## WEEK 10 — SALES CALLS + NDA (Days 64-70)

### Days 64-70 — Sales Calls
For each call booked:
- [ ] Send NDA 24 hours before (use `01-LEGAL/NDA-TEMPLATE.md`)
- [ ] 30-min call structure:
  - [ ] 5 min: intros
  - [ ] 10 min: your pitch (slide deck)
  - [ ] 10 min: their use case + technical Q&A
  - [ ] 5 min: next steps (eval license?)
- [ ] Follow-up email same day with architecture spec + demo video link
- [ ] Add call notes to CRM

**Week 10 Goal:** Sign 1-2 mutual NDAs. Get 1 company to request eval license terms.

---

## WEEK 11 — FIRST EVAL LICENSE (Days 71-77)

### Days 71-77 — Negotiate First Eval License
- [ ] Draft eval license (use `01-LEGAL/EVAL-LICENSE-TEMPLATE.md`)
- [ ] Eval terms: 90-day, $0 fee, encrypted RTL or NDA source
- [ ] Send to interested company
- [ ] Iterate on terms
- [ ] Get signed

**Week 11 Goal:** First eval license signed.

---

## WEEK 12 — CONTENT MARKETING BLITZ (Days 78-84)

### Day 78 — Hacker News Launch
- [ ] Post to Hacker News (Tue or Wed 8am PT)
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

### Days 81-83 — Engage + Capture
- [ ] Respond to every comment, DM, email
- [ ] Add interested people to CRM
- [ ] Add newsletter signups to Substack

### Day 84 — Week Review
- [ ] GitHub stars gained?
- [ ] Newsletter subscribers?
- [ ] New sales leads?

---

## WEEK 13 — CLOSE OUT (Days 85-90)

### Days 85-87 — NLnet Follow-up
- [ ] Email NLnet to confirm receipt
- [ ] Be ready to answer questions

### Day 88 — DLI Follow-up
- [ ] Follow up on DLI application
- [ ] Talk to CA about any missing docs

### Day 89 — Phase 1 Final Review (3 hours)
- [ ] Legal: dual-license live? LLP registered? CLA enforced?
- [ ] Technical: synth clean? FPGA working? UVM at 85%?
- [ ] Documentation: all 6 docs complete?
- [ ] CI: green on every push?
- [ ] Sales: 50 emails sent? Calls? NDAs? Eval licenses?
- [ ] Grants: NLnet + DLI submitted?
- [ ] Brand: demo video? website? blog posts?
- [ ] Press: HN launch? press coverage?

Score yourself:
- 8/8 = A+, ready for Phase 2
- 6-7/8 = B, ahead of 95% of indie devs
- 4-5/8 = C, foundation in place
- <4/8 = reassess and recommit

### Day 90 — Plan Phase 2
- [ ] Write `PHASE2_PLAN.md` based on Day 89 review
- [ ] Set 90-day goals for Months 4-6
- [ ] Commit to next 90 days

---

## Phase 1 Completion Checklist

At Day 90, ALL of these should be checked:

### Legal
- [ ] Dual-license live in repo
- [ ] COMMERCIAL.md in repo root
- [ ] CLA enforced via CLA Assistant
- [ ] LLP registered in India
- [ ] Bank account in LLP name
- [ ] GST registration done
- [ ] Startup India recognition
- [ ] Domain + professional email

### Technical
- [ ] GAAFET bug fixed
- [ ] All translate_off replaced
- [ ] RAM style attributes added
- [ ] Verilator lint clean
- [ ] Yosys synth clean (0 errors)
- [ ] FPGA proven on Artix-7 (or equivalent)
- [ ] VGA output demonstrated
- [ ] Timing closes at ≥50 MHz
- [ ] Utilization report generated

### Verification
- [ ] 200+ cocotb tests
- [ ] 60%+ functional coverage
- [ ] Regression suite running
- [ ] UVM environment (if hired contractor)
- [ ] Formal verification attempted
- [ ] Performance benchmarks run

### CI/CD
- [ ] GitHub Actions workflow live
- [ ] Lint job passes
- [ ] Compile job passes
- [ ] Test job passes
- [ ] Synth job passes
- [ ] Coverage job runs (on push)
- [ ] CI badges in README

### Documentation
- [ ] Architecture spec (30-50 pages)
- [ ] Microarchitecture spec (100+ pages)
- [ ] Verification plan (20 pages)
- [ ] Datasheet (10 pages)
- [ ] Integration guide (15 pages)
- [ ] Product brief (2 pages)
- [ ] Pitch deck (10 slides)

### Software
- [ ] Bare-metal driver library
- [ ] Linux DRM driver stub
- [ ] Shader assembler
- [ ] Reference SoC design
- [ ] Example applications

### Sales & Marketing
- [ ] 50-company buyer list
- [ ] 50 cold emails sent
- [ ] 5-10 sales calls booked
- [ ] 1-2 NDAs signed
- [ ] 0-1 eval licenses signed
- [ ] Demo video recorded
- [ ] Website live
- [ ] 2 blog posts published
- [ ] Hacker News launch done

### Grants
- [ ] NLnet grant submitted
- [ ] DLI grant submitted
- [ ] Startup India recognition active

---

**Print this. Tape to wall. Execute daily. Win.**
