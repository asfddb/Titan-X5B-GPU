# Titan X5-B GPU — Verification Plan

**Version:** 1.0  
**Date:** [TODAY'S DATE]  
**Author:** Adhiraj (@asfddb)

---

## 1. Overview

This document describes the verification methodology, test plan, and
coverage model for the Titan X5-B GPU IP.

### 1.1 Verification Philosophy

The Titan X5-B is verified using **cocotb** — the industry-standard
Python verification framework. Cocotb interfaces natively with the
Icarus Verilog simulator using VPI (Verilog Procedural Interface),
directly manipulating and observing RTL signals without software
wrappers.

**Why cocotb over SystemVerilog UVM?**
- Faster test development (Python vs SystemVerilog)
- Rich ecosystem (cocotbext-axi for AXI VIPs)
- Lower barrier to contribution (more engineers know Python than SV)
- Native VPI interface — no simulation performance penalty
- Open-source, no vendor lock-in

**UVM is planned** for v1.1, targeting enterprise customers who
require it in their verification flow.

---

## 2. Verification Environment

### 2.1 Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Icarus Verilog | 14.0 | RTL simulation |
| Cocotb | 1.8.1 | Test framework |
| cocotbext-axi | latest | AXI4 Verification IP |
| cocotb-coverage | latest | Functional coverage |
| Yosys | 0.66+ | Synthesis + formal equivalence |
| Verilator | 5.x | Lint + alternative sim |
| PIL (Pillow) | latest | VGA image reconstruction |

### 2.2 Testbench Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Cocotb Testbench                   │
│                                                     │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐ │
│  │  AXI Master │  │  AXI Slave  │  │   Monitor   │ │
│  │   Driver    │  │  (VRAM Ram) │  │  (VGA Pins) │ │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘ │
│         │                │                │        │
└─────────┼────────────────┼────────────────┼────────┘
          │                │                │
   ┌──────┴────────────────┴────────────────┴──────┐
   │          DUT: titan_x5_gpu_top                │
   │                                                │
   │   ┌─────────┐  ┌─────────┐  ┌─────────┐      │
   │   │   SM 0  │  │   SM 1  │  │   SM 2  │ ...  │
   │   └─────────┘  └─────────┘  └─────────┘      │
   │   ┌─────────────────────────────────────┐    │
   │   │      AXI4 Crossbar (8x4)            │    │
   │   └─────────────────────────────────────┘    │
   │   ┌─────────┐  ┌─────────┐  ┌─────────┐      │
   │   │   TMU   │  │   ROP   │  │Display  │      │
   │   └─────────┘  └─────────┘  └─────────┘      │
   └────────────────────────────────────────────────┘
```

### 2.3 Test File Structure

```
tb/
├── Makefile                          # cocotb makefile
├── test_runner.py                    # pytest runner
├── test_system.py                    # System-level VGA test
├── test_graphics_pipeline.py         # Graphics-only test
├── test_alu.py                       # ALU unit test
├── test_crossbar_routing.py          # Crossbar test
├── test_cache_coherence.py           # L1/L2 cache test
├── test_texture_sampling.py          # TMU test
├── test_display_timing.py            # Display timing test
├── test_command_processor.py         # Command FIFO test
├── test_tensor_core.py               # Tensor MAC test
├── cocotb_graphics_top.v             # Graphics testbench wrapper
├── ultimate_blackwell_tb.v           # Full-chip SV testbench
└── uvm/                              # UVM environment (planned v1.1)
    ├── titan_x5_env.sv
    ├── axi_agent/
    ├── scoreboard.sv
    └── sequences/
```

---

## 3. Test Plan

### 3.1 Test Categories

| Category | Description | Tool |
|----------|-------------|------|
| **Unit tests** | Single module, directed | cocotb |
| **Integration tests** | Multi-module, directed | cocotb |
| **System tests** | Full chip, directed | cocotb |
| **Random tests** | Constrained random | cocotb + random seeds |
| **Formal verification** | Property-based | SymbiYosys |
| **Regression tests** | All of the above + bug fixes | pytest |

### 3.2 Test Matrix

| Test | Module(s) | Type | Status | Coverage Target |
|------|-----------|------|--------|-----------------|
| `test_alu_ops` | titan_x5_alu | Unit | ✅ | 95% |
| `test_alu_latency` | titan_x5_alu | Unit | ✅ | 100% (multicycle) |
| `test_register_file` | titan_x5_register_file | Unit | 🚧 | 90% |
| `test_warp_scheduler` | titan_x5_warp_scheduler | Unit | 🚧 | 85% |
| `test_pipeline_hazards` | titan_x5_pipeline | Unit | 🚧 | 90% |
| `test_decoder` | titan_x5_decoder | Unit | 🚧 | 95% |
| `test_crossbar_routing` | titan_x5_crossbar | Integration | ✅ | 85% |
| `test_crossbar_fifo` | titan_x5_crossbar | Integration | 🚧 | 90% |
| `test_l1_cache` | titan_x5_l1_cache | Unit | 🚧 | 85% |
| `test_l2_cache` | titan_x5_l2_cache | Unit | 🚧 | 80% |
| `test_command_processor` | titan_x5_command_processor | Unit | ✅ | 85% |
| `test_rasterizer` | titan_x5_rasterizer | Unit | ✅ | 75% |
| `test_texture_sampling` | titan_x5_tmu | Unit | ✅ | 70% |
| `test_rop_blend` | titan_x5_rop | Unit | 🚧 | 80% |
| `test_rt_intersection` | titan_x5_rt_core | Unit | 🚧 | 75% |
| `test_tensor_mac` | titan_x6_tensor_core_array | Unit | 🚧 | 85% |
| `test_display_timing` | titan_x5_display_engine | Unit | ✅ | 80% |
| `test_graphics_pipeline` | graphics modules | Integration | ✅ | 70% |
| `test_system_vga` | Full chip | System | ✅ | 65% |
| `test_compute_dispatch` | SM + memory | Integration | 🚧 | 75% |
| `test_dma` | titan_x5_dma_engine | Unit | 🚧 | 80% |
| `test_power_mgmt` | titan_x5_power_mgmt | Unit | 🚧 | 70% |

### 3.3 Random Test Configuration

- **Seeds:** 1000 random seeds per test
- **Constrained random:** AXI transaction types, addresses, burst lengths
- **Coverage-driven:** Stop when coverage target hit OR 1000 seeds run

---

## 4. Coverage Model

### 4.1 Functional Coverage

#### 4.1.1 ALU Coverage

```python
# Coverage items for ALU
functional_coverage = {
    'ALU_OPCODE': {
        'ADD':  False, 'SUB':  False, 'MUL':  False, 'DIV':  False,
        'AND':  False, 'OR':   False, 'XOR':  False,
        'SHL':  False, 'SHR':  False,
        'FADD': False, 'FMUL': False, 'FDIV': False,
    },
    'ALU_OPERAND_BOUNDARY': {
        'MIN_INT':  False, 'MAX_INT':  False,
        'ZERO':     False, 'NEG_ONE':  False,
        'MIN_FP16': False, 'MAX_FP16': False,
        'NAN':      False, 'INF':      False,
    },
    'ALU_LATENCY': {
        'SINGLE_CYCLE':    False,  # ADD, AND, etc.
        'MULTI_CYCLE_3':   False,  # MUL
        'MULTI_CYCLE_14':  False,  # FDIV
        'MULTI_CYCLE_16':  False,  # DIV
    },
}
```

#### 4.1.2 Crossbar Coverage

```python
crossbar_coverage = {
    'MASTER_SLAVE_PAIR': {
        # 8 masters × 4 slaves = 32 combinations
        'M0_S0': False, 'M0_S1': False, ..., 'M7_S3': False,
    },
    'TRANSACTION_TYPE': {
        'READ_SINGLE':  False,
        'WRITE_SINGLE': False,
        'READ_BURST_4': False,
        'READ_BURST_8': False,
        'WRITE_BURST_4': False,
        'WRITE_BURST_8': False,
    },
    'CONTENTION': {
        'NO_CONTENTION':     False,
        'TWO_MASTERS_SAME_SLAVE': False,
        'ALL_MASTERS_SAME_SLAVE': False,
        'ALL_DIFFERENT_SLAVES':   False,
    },
}
```

#### 4.1.3 Graphics Coverage

```python
graphics_coverage = {
    'TRIANGLE_TYPE': {
        'SMALL':     False,  # < 100 pixels
        'MEDIUM':    False,  # 100-1000 pixels
        'LARGE':     False,  # > 1000 pixels
        'DEGENERATE': False, # zero area
    },
    'VERTEX_POSITION': {
        'ON_SCREEN':    False,
        'PARTIAL_CLIP': False,
        'OFF_SCREEN':   False,
    },
    'BLEND_MODE': {
        'OPAQUE':     False,
        'ALPHA_BLEND': False,
        'ADDITIVE':   False,
    },
}
```

### 4.2 Code Coverage

| Coverage Type | Current | Target |
|---------------|---------|--------|
| Line | 70% | 90% |
| Branch | 60% | 85% |
| Toggle | 55% | 80% |
| FSM state | 80% | 100% |
| FSM transition | 75% | 95% |

---

## 5. Regression Suite

### 5.1 Regression Categories

| Regression | Frequency | Tests Included | Runtime |
|------------|-----------|----------------|---------|
| **Smoke** | Every push | 5 basic tests | < 5 min |
| **Nightly** | Every night | All directed tests | ~30 min |
| **Weekly** | Every weekend | Directed + 100 random seeds | ~2 hr |
| **Pre-release** | Before tag | Directed + 1000 random seeds | ~24 hr |

### 5.2 Regression Tracking

- All regressions run in GitHub Actions CI
- Results stored as artifacts (30-day retention)
- Failures filed as GitHub Issues
- Coverage trends tracked in `docs/COVERAGE_TRENDS.md`

---

## 6. Bug Tracking

### 6.1 Bug Lifecycle

```
New → Triaged → Assigned → In Progress → Fixed → Regression Test → Verified → Closed
```

### 6.2 Bug Severity

| Severity | Definition | Example |
|----------|------------|---------|
| **S0 — Critical** | Blocks release, no workaround | Synth fails, sim hangs |
| **S1 — Major** | Wrong output, has workaround | ROP blends wrong color |
| **S2 — Minor** | Cosmetic, edge case | Display flicker at 1024x768 |
| **S3 — Enhancement** | Not a bug, nice-to-have | Add INT8 tensor support |

### 6.3 Bug Reporting Template

```markdown
## Bug: [Title]

**Severity:** S0/S1/S2/S3
**Module:** [e.g., titan_x5_crossbar]
**Test:** [e.g., test_crossbar_routing.py]
**Seed:** [random seed, if applicable]

### Steps to Reproduce
1. ...
2. ...

### Expected Behavior
...

### Actual Behavior
...

### Waveform
[Attach VCD screenshot]

### Logs
[Attach sim log excerpt]
```

---

## 7. Formal Verification

### 7.1 Properties (planned)

```verilog
// Crossbar: every request eventually gets a response
assert property (@(posedge clk) disable iff (!rst_n)
    m_req_valid |-> ##[1:100] m_resp_valid);

// ALU: writeback happens exactly N cycles after issue
assert property (@(posedge clk) disable iff (!rst_n)
    alu_valid |-> ##N alu_ready);

// Command processor: never drops a command
assert property (@(posedge clk) disable iff (!rst_n)
    cmd_fifo_push |-> ##[1:1000] cmd_fifo_pop);
```

### 7.2 Formal Tool

- **SymbiYosys** (open source, Yosys-based)
- Run on every PR via CI
- 5-minute time limit per property

---

## 8. Verification Roadmap

### v1.0 (current)
- ✅ cocotb testbench
- ✅ 3 system tests passing
- ✅ 60% functional coverage
- ✅ GitHub Actions CI

### v1.1 (Q1 2026)
- ⏳ UVM environment
- ⏳ 85% functional coverage
- ⏳ Formal verification
- ⏳ 1000-seed random regression

### v1.2 (Q2 2026)
- ⏳ Coverage-driven verification
- ⏳ Mutation testing
- ⏳ Gate-level simulation
- ⏳ Power-aware simulation

### v2.0 (Q3 2026)
- ⏳ Silicon correlation
- ⏳ Production sign-off
- ⏳ Tape-out ready

---

## 9. CI/CD Integration

### 9.1 GitHub Actions Workflow

See `.github/workflows/ci.yml`. The workflow runs:

1. **Lint** — Verilator lint on every file
2. **Compile** — Icarus compile of full RTL
3. **Test** — cocotb test suite
4. **Synth** — Yosys synthesis + gate count check
5. **Coverage** — Coverage report (on push only)

### 9.2 PR Requirements

- ✅ All CI checks pass
- ✅ No new lint warnings
- ✅ No new coverage regression
- ✅ CLA signed
- ✅ At least 1 reviewer approval

---

## 10. Verification Deliverables for IP Customers

Commercial licensees receive:

1. **Full testbench source** — every test file
2. **Coverage model** — functional coverage definitions
3. **Regression scripts** — run regressions locally
4. **Bug database export** — historical bugs + fixes
5. **Methodology documentation** — this document
6. **CI configuration** — same `.github/workflows/ci.yml`
7. **2 hours of verification consulting** — initial onboarding call

---

*For commercial license inquiries, contact adhiraj@[your-domain].*
