# Commercial License — Titan X5-B GPU IP

## Overview

The Titan X5-B GPU is available under a **commercial license** for
companies that need to use the IP in closed-source products without
the open-source obligations of CERN-OHL-S-2.0.

This document describes the available license models, what's included,
and how to engage.

---

## License Models

### 1. Evaluation License (90 days, free)

**Purpose:** Let your engineering team evaluate the IP before
committing to a commercial license.

**What you get:**
- Encrypted RTL (or full source under strict NDA)
- Architecture specification
- Verification testbench suite
- 90 days of email support
- Up to 10 hours of technical Q&A

**Cost:** Free (under mutual NDA)

**Limitations:**
- No commercial use during evaluation
- No right to manufacture
- Must destroy all materials after eval period

---

### 2. Perpetual License + Royalty

**Purpose:** Use the IP in a commercial product forever.

**What you get:**
- Full source code (SystemVerilog RTL)
- Right to modify (modifications remain your property)
- Right to use in unlimited products
- Warranty + indemnification
- 12 months of updates + bug fixes
- Email support

**Cost structure:**
- One-time upfront fee: $150,000 – $400,000 USD
- Per-unit royalty: 0.5% – 2% of chip sale price
- Annual support (optional): $20,000 – $50,000/year

**Best for:** Established companies with shipping products.

---

### 3. Annual Subscription License

**Purpose:** Lower upfront cost, ongoing access.

**What you get:**
- Full source code
- Right to use in commercial products during subscription
- All updates + new versions during subscription
- Email + phone support

**Cost structure:**
- Annual fee: $50,000 – $150,000/year per product line
- No per-unit royalty
- Minimum 2-year commitment

**Best for:** Startups, smaller companies, projects with shorter lifecycle.

---

### 4. Source Code Buyout

**Purpose:** Own a snapshot of the IP forever.

**What you get:**
- Full source code + rights to create derivative works
- No ongoing royalties
- No ongoing support (optional add-on)
- Right to sub-license within your organization

**Cost:** $300,000 – $1,000,000 USD one-time

**Best for:** Companies that want to own the IP forever and have
internal teams to maintain it.

---

### 5. Custom License

**Purpose:** Something doesn't fit the above models.

We're flexible. Common custom arrangements:
- Royalty-only (no upfront fee, higher royalty %)
- Equity + reduced fee (for early-stage startups)
- Territory-exclusive license (e.g., exclusive to India market)
- Field-of-use exclusive (e.g., exclusive to automotive)
- Multi-year R&D partnership

Just ask.

---

## What's Included in Every Commercial License

Regardless of license model, every commercial licensee receives:

### RTL Source
- All 57+ SystemVerilog modules
- Synthesis scripts (Yosys + Vivado)
- FPGA target constraints (Artix-7, Lattice ECP5, Gowin)
- RAM style attributes for BRAM inference

### Verification Suite
- Cocotb testbenches (200+ tests)
- UVM environment (where available)
- Functional coverage model
- Regression suite
- Continuous integration setup

### Documentation
- Architecture specification
- Microarchitecture specification
- Verification plan
- Datasheet
- Integration guide
- ISA reference

### Software Stack
- Bare-metal driver library
- Linux DRM driver stub
- Shader assembler
- Example applications

### Reference Designs
- Reference SoC (RISC-V + Titan X5-B + DDR)
- FPGA demonstration design
- PCB reference (when available)

---

## Support Tiers

| Tier | Cost | Response Time | Includes |
|------|------|---------------|----------|
| **Standard** | Included | 5 business days | Email support, bug fixes |
| **Priority** | $30K/year | 2 business days | Email + Slack channel, bug fixes, monthly call |
| **Enterprise** | $75K/year | 4 hours | Dedicated engineer, custom fixes, weekly call |
| **On-site** | Custom | N/A | Engineer visits your site for 1-4 weeks |

---

## Warranty & Indemnification

Commercial license includes:
- **Warranty:** IP is original work of the author, free of third-party IP claims
- **Indemnification:** Author will defend against any IP infringement claims
- **Limitation of liability:** Capped at 2x annual license fee paid

Full warranty terms in the executed license agreement.

---

## How to Engage

### Step 1: Reach out

Email: `adhiraj@[your-domain]`

Include:
- Your name + company
- Your use case (1-2 paragraphs)
- Approximate volume / timeline
- Any specific questions

### Step 2: Mutual NDA

We'll sign a mutual NDA (we provide template, or use yours).

### Step 3: Technical deep-dive call

30-60 minute call with your engineering team. We share:
- Full architecture spec
- Verification reports
- FPGA demo video
- Source code snippets

### Step 4: Evaluation license

If both sides want to proceed, we sign a 90-day eval license. You get
encrypted RTL or full source (under NDA) to integrate into your flow.

### Step 5: Commercial license

After successful eval, we negotiate commercial terms and sign the
license agreement. Invoice. You get full source + rights.

### Step 6: Ongoing support

Bug fixes, updates, technical support per your support tier.

---

## Pricing Rationale

Why $150K-$400K and not $5K or $5M?

- **Below $50K:** IP is perceived as low-quality. Buyers won't take it seriously.
- **Above $500K:** Buyers compare to Arm Mali / Imagination PowerVR
  and expect silicon-proven IP.
- **$150K-$400K:** Sweet spot for a clean, FPGA-proven, well-documented
  GPU IP targeting display/compute SoCs where Arm/Imagination is
  overkill or politically unavailable.

Reference points:
- Arm Mali-400 GPU IP: ~$500K + 1-3% royalty
- Imagination PowerVR Series8XE: ~$400K + 1-2% royalty
- VeriSilicon GPU IP: ~$300K + 1-2% royalty
- Open-source GPUs (Vortex, Nyuzi): $0 but no commercial license

Titan X5-B sits below the commercial leaders (smaller, less proven)
but above the open-source alternatives (commercially licenseable,
warranted, supported).

---

## Contact

```
Adhiraj
[Your LLP Name]
[Your Address]
India

Email:   adhiraj@[your-domain]
Web:     https://[your-domain]
GitHub:  https://github.com/asfddb
LinkedIn: https://linkedin.com/in/[your-handle]
```

For commercial license inquiries, please use the subject line:
`"Commercial License Inquiry — Titan X5-B GPU"`.

---

*This document is for informational purposes only and does not
constitute a legal offer. The actual commercial license is a separate
executed agreement.*
