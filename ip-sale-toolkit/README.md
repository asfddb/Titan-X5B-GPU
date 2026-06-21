# 🛠️ Titan X5-B IP Sale Toolkit

Everything you need to take the Titan X5-B GPU from a learning project
to a commercially sellable IP block, in 90 days.

Built specifically for Adhiraj's Titan X5-B GPU project.

---

## 📁 What's in here

```
ip-sale-toolkit/
├── 00-MASTER-ROADMAP.md          ← Start here. Day-by-day 90-day plan.
│
├── 01-LEGAL/                     ← Legal foundation (Week 1)
│   ├── LICENSE.md                   New dual-license for repo
│   ├── COMMERCIAL.md                Commercial license pricing + terms
│   ├── CLA-INDIVIDUAL.md            Individual contributor license
│   ├── CLA-CORPORATE.md             Corporate contributor license
│   ├── NDA-TEMPLATE.md              Mutual NDA for buyer discussions
│   └── EVAL-LICENSE-TEMPLATE.md     90-day eval license template
│
├── 02-RTL-FIXES/                 ← Technical fixes (Week 2)
│   ├── titan_x_3nm_gaafet_optimizer_FIXED.v  ← THE bug fix
│   ├── apply_ram_style.py           Script to add BRAM attributes
│   └── translate_off_fix.patch      Fix for legacy hot-comments
│
├── 03-CI/                        ← CI/CD (Week 3)
│   └── ci.yml                       GitHub Actions workflow
│
├── 04-DOCS/                      ← Documentation arsenal (Week 4)
│   ├── ARCHITECTURE.md              Architecture spec template
│   ├── VERIFICATION.md              Verification plan template
│   ├── DATASHEET.md                 IP datasheet template
│   ├── PRODUCT-BRIEF.md             2-page pitch
│   └── COLD_EMAIL_TEMPLATES.md      10 cold email templates
│
└── 05-TRACKING/                  ← Accountability (every day)
    ├── WEEKLY-CHECKLIST.md          Week-by-week checklist
    └── DAILY-LOG.md                 Daily progress log template
```

---

## 🚀 How to use this toolkit

### Step 1: Read the master roadmap
Open `00-MASTER-ROADMAP.md`. Read it end-to-end. Print it. Tape the
relevant week to your wall.

### Step 2: Start Day 1 today
Don't wait. Open `05-TRACKING/DAILY-LOG.md`, fill in Day 1's date,
and execute the Day 1 checklist from `WEEKLY-CHECKLIST.md`.

### Step 3: Copy artifacts to your repo as you progress

**Day 2 (Apply dual license):**
```bash
cd /your/repo
cp /path/to/ip-sale-toolkit/01-LEGAL/LICENSE.md ./LICENSE
cp /path/to/ip-sale-toolkit/01-LEGAL/COMMERCIAL.md .
git add LICENSE COMMERCIAL.md
git commit -m "license: dual-license for commercial use"
git push
```

**Day 8 (Fix GAAFET bug):**
```bash
cd /your/repo
cp /path/to/ip-sale-toolkit/02-RTL-FIXES/titan_x_3nm_gaafet_optimizer_FIXED.v \
   ./rtl/titan_x_3nm_gaafet_optimizer.v
# Update any parent modules that instantiate it (port connections)
yosys -p "read_verilog -sv rtl/titan_x_3nm_gaafet_optimizer.v; synth; stat"
git add rtl/titan_x_3nm_gaafet_optimizer.v
git commit -m "fix(rtl): GAAFET unpacked array ports → packed bus"
git push
```

**Day 10 (Add RAM style attributes):**
```bash
cd /your/repo
python3 /path/to/ip-sale-toolkit/02-RTL-FIXES/apply_ram_style.py ./rtl
git diff   # review changes
git add rtl/
git commit -m "perf(rtl): add ram_style attributes for BRAM inference"
git push
```

**Day 15 (Set up CI):**
```bash
cd /your/repo
mkdir -p .github/workflows
cp /path/to/ip-sale-toolkit/03-CI/ci.yml .github/workflows/
git add .github/
git commit -m "ci: GitHub Actions workflow"
git push
# Watch CI run at https://github.com/asfddb/Titan-X5B-GPU/actions
```

### Step 4: Fill in the templates

Every file has `[BRACKETS]` where you fill in your specific info:

| File | Fill in |
|------|---------|
| `LICENSE.md` | Your name, email, domain |
| `COMMERCIAL.md` | Your contact info, LLP name |
| `CLA-INDIVIDUAL.md` | Your city (for jurisdiction) |
| `NDA-TEMPLATE.md` | Counterparty info (per buyer) |
| `EVAL-LICENSE-TEMPLATE.md` | Counterparty info (per buyer) |
| `ARCHITECTURE.md` | All technical specs |
| `DATASHEET.md` | All specs + pinout |
| `PRODUCT-BRIEF.md` | Contact info |
| `COLD_EMAIL_TEMPLATES.md` | Your links, calendly, etc. |

### Step 5: Track daily
End of every day, open `05-TRACKING/DAILY-LOG.md` and fill in the
day's progress. End of every week, fill in the weekly roll-up.

---

## 🎯 Quick-start checklist (do this in the next 2 hours)

If you do nothing else today, do these 7 things:

- [ ] 1. Read `00-MASTER-ROADMAP.md` end-to-end
- [ ] 2. Copy `01-LEGAL/LICENSE.md` to your repo as `LICENSE`
- [ ] 3. Copy `01-LEGAL/COMMERCIAL.md` to your repo root
- [ ] 4. Update `README.md` to add a Licensing section (see roadmap)
- [ ] 5. Copy `02-RTL-FIXES/titan_x_3nm_gaafet_optimizer_FIXED.v` to
       `rtl/titan_x_3nm_gaafet_optimizer.v`
- [ ] 6. Run Yosys on the GAAFET module to confirm it synthesizes
- [ ] 7. Commit + push: `git commit -m "phase 1 kickoff: dual-license + GAAFET fix"`

That's Day 1 + Day 2 + Day 8 done in 2 hours. You're already 3 days
ahead of schedule.

---

## 📊 Phase 1 success metrics

At Day 90, you should have:

| Metric | Target |
|--------|--------|
| GitHub stars | 200+ |
| Synth warnings | 0 |
| Cocotb tests | 200+ |
| Functional coverage | 70%+ |
| FPGA frequency | 50 MHz+ |
| Documentation pages | 250+ |
| Buyer emails sent | 50+ |
| NDAs signed | 1-3 |
| Eval licenses | 0-1 |
| Cash invested | ~$500 |
| Cash earned | $0 (realistic — first revenue in Month 12-18) |

---

## ⚠️ Realistic expectations

**Phase 1 (Days 1-90):** $0 revenue. This is the asset-building phase.
You're creating the sellable product, not selling it yet.

**Phase 2 (Months 4-9):** $0-15K revenue. First eval licenses signed.
Grants may come in. Cold outreach continues.

**Phase 3 (Months 10-18):** $100K-500K revenue. First commercial
licenses close. This is when the IP actually starts paying for itself.

**Phase 4 (Months 19-36):** $500K-2M revenue OR acquisition exit.

**Total 3-year outcome:** $850K-2.7M realistic, $5M-15M best case.

The math works IF you execute. This toolkit gives you the playbook.
The execution is on you.

---

## 🆘 When you get stuck

**Stuck on a legal question?** Email a real IP lawyer. ₹2K-5K for a
consult is worth it. Don't wing legal stuff.

**Stuck on a technical issue?** Post on:
- r/FPGA (Reddit) — active community
- Stack Overflow (tag: verilog, fpga)
- Yosys GitHub Issues
- Cocotb Gitter / Discord

**Stuck on sales?** Read:
- "Crossing the Chasm" by Geoffrey Moore
- "The Mom Test" by Rob Fitzpatrick
- "Predictable Revenue" by Aaron Ross

**Stuck on motivation?** Re-read `00-MASTER-ROADMAP.md` Section
"What to do right now." Then open `DAILY-LOG.md` and execute.

---

## 📞 Contact

Built by your AI assistant. If you find bugs in the toolkit itself
(wrong instructions, broken scripts, outdated info), report them.

But the toolkit is just paper. The work is yours to do.

**GO.** 🚀
