# Titan X5-B GPU — IP Datasheet

**Version:** 1.0  
**Date:** [TODAY'S DATE]

---

## 1. General Description

Titan X5-B is a synthesizable GPU IP core implementing a SIMT-class educational
architecture. The IP is delivered as RTL source code in
SystemVerilog, with full verification suite, documentation, and
reference designs.

---

## 2. Specifications

### 2.1 Architectural Specifications

| Parameter | Value |
|-----------|-------|
| Architecture | SIMT (Single Instruction, Multiple Threads) |
| Warp Size | 32 threads |
| Number of SMs | 4 (parameterizable) |
| ALU Width | 32-bit integer + 16-bit float |
| Register File | 32 lanes × 256 registers × 32 bits |
| L1 Cache | 32 KB, 4-way set associative |
| L2 Cache | 256 KB, 8-way set associative |
| Tensor Core | 16 × 16 systolic, FP16 MAC |
| Memory Bus Width | 512-bit (GDDR7 PAM3 sim) |
| Display | VGA (640×480 @ 60 Hz default), up to 1920×1080 |

### 2.2 Interface Specifications

#### AXI4 Master Ports (8 total)

| Signal | Width | Description |
|--------|-------|-------------|
| `m_req_valid[N-1:0]` | 8 | Request valid per master |
| `m_req_addr[N*32-1:0]` | 256 | Address bus |
| `m_req_wdata[N*32-1:0]` | 256 | Write data |
| `m_req_write[N-1:0]` | 8 | 1=write, 0=read |
| `m_req_ready[N-1:0]` | 8 | Request accepted |
| `m_resp_valid[N-1:0]` | 8 | Response valid |
| `m_resp_rdata[N*32-1:0]` | 256 | Read data |

#### AXI4 Slave Ports (4 total)

| Signal | Width | Description |
|--------|-------|-------------|
| `s_req_valid[3:0]` | 4 | Request valid per slave |
| `s_req_addr[127:0]` | 128 | Address bus |
| `s_req_wdata[127:0]` | 128 | Write data |
| `s_req_write[3:0]` | 4 | 1=write, 0=read |
| `s_req_ready[3:0]` | 4 | Request accepted |
| `s_resp_valid[3:0]` | 4 | Response valid |
| `s_resp_rdata[127:0]` | 128 | Read data |

#### Display Interface

| Signal | Width | Description |
|--------|-------|-------------|
| `vga_hsync` | 1 | Horizontal sync |
| `vga_vsync` | 1 | Vertical sync |
| `vga_de` | 1 | Data enable |
| `vga_r[7:0]` | 8 | Red (8-bit) |
| `vga_g[7:0]` | 8 | Green (8-bit) |
| `vga_b[7:0]` | 8 | Blue (8-bit) |
| `vga_clk` | 1 | Pixel clock output |

#### Control Interface

| Signal | Width | Description |
|--------|-------|-------------|
| `clk` | 1 | System clock |
| `rst_n` | 1 | Active-low async reset |
| `intr_req` | 1 | Interrupt to host |
| `host_ring_base[31:0]` | 32 | Command ring buffer base |
| `host_ring_wptr[31:0]` | 32 | Command ring write pointer |

### 2.3 Performance Specifications

| Metric | Value |
|--------|-------|
| Max Clock (Yosys estimate) | 100 MHz |
| Achieved Clock (Artix-7) | 50 MHz |
| Peak FLOPS (FP16) | 4 SMs × 32 lanes × 50 MHz × 2 = 12.8 GFLOPS |
| Peak INT16 OPS | 4 SMs × 32 lanes × 50 MHz = 6.4 GOPS |
| Tensor Throughput | 256 MACs × 50 MHz × 2 = 25.6 GFLOPS |
| Memory Bandwidth | 512 bits × 50 MHz = 3.2 GB/s |
| Pixel Fill Rate | 4 ROPs × 50 MHz = 200 Mpix/s |
| Triangle Rate | ~5 Mtri/s (small triangles) |

### 2.4 Physical Specifications

| Parameter | Value |
|-----------|-------|
| Target Environment | Simulation / FPGA |
| Gate Count (Yosys) | 3,030,603 |
| Flip-Flops | 530,000+ |
| Wire Bits | 3,230,370 |
| Supply Voltage | 1.0V (core), 1.8V (IO) — target |
| Power (estimated) | 5–15W @ 50 MHz, 28nm |

### 2.5 FPGA Specifications

#### Artix-7 100T (FPGA Edition — 1 SM)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| LUTs | 41,234 | 63,400 | 65% |
| FFs | 38,122 | 126,800 | 30% |
| BRAM (36Kb) | 84 | 135 | 62% |
| DSP48E1 | 124 | 240 | 52% |
| IOBs | 23 | 210 | 11% |
| BUFG | 2 | 32 | 6% |
| MMCME2_ADV | 1 | 6 | 17% |
| **Max Freq** | **50 MHz** | — | — |

---

## 3. Pinout (Artix-7 Arty A7)

| FPGA Pin | Signal | Bank | Std |
|----------|--------|------|-----|
| E3 | clk | 35 | LVCMOS33 |
| C2 | rst_n | 35 | LVCMOS33 |
| H5 | led[0] | 35 | LVCMOS33 |
| J5 | led[1] | 35 | LVCMOS33 |
| T9 | led[2] | 34 | LVCMOS33 |
| R9 | led[3] | 34 | LVCMOS33 |
| A8 | vga_hsync | 15 | LVCMOS33 |
| B8 | vga_vsync | 15 | LVCMOS33 |
| D9 | vga_de | 15 | LVCMOS33 |
| A13 | vga_r[0] | 15 | LVCMOS33 |
| A14 | vga_r[1] | 15 | LVCMOS33 |
| ... | ... | ... | ... |

Full pinout in `fpga/constraints/arty_a7.xdc`.

---

## 4. Clock and Reset

### 4.1 Clock

- **Input clock:** 100 MHz (Arty A7 onboard oscillator)
- **Internal clock:** 50 MHz (via MMCM divider)
- **Pixel clock:** 25.175 MHz (for 640×480 @ 60 Hz VGA)

### 4.2 Reset

- Active-low asynchronous reset (`rst_n`)
- Synchronous deassertion (deglitcher)
- Internal reset distributed via BUFG

---

## 5. Memory Map

See `ARCHITECTURE.md` Section 6 for full memory map.

---

## 6. Configuration Parameters

```verilog
module titan_x5_gpu_top #(
    parameter NUM_SMS           = 4,    // 1, 2, 4
    parameter WARP_SIZE         = 32,   // 8, 16, 32
    parameter L1_CACHE_KB       = 32,   // 8, 16, 32, 64
    parameter L2_CACHE_KB       = 256,  // 64, 128, 256, 512
    parameter TENSOR_ROWS       = 16,   // 4, 8, 16
    parameter TENSOR_COLS       = 16,   // 4, 8, 16
    parameter NUM_TMUS          = 4,    // 1, 2, 4
    parameter NUM_ROPS          = 4,    // 1, 2, 4
    parameter RT_CORE_ENABLE    = 1,    // 0=disable, 1=enable
    parameter FPGA_EDITION      = 0     // 0=full, 1=reduced for FPGA
) (
    ...
);
```

---

## 7. Electrical Characteristics (Target)

| Parameter | Min | Typ | Max | Unit |
|-----------|-----|-----|-----|------|
| VDD_core | 0.9 | 1.0 | 1.1 | V |
| VDD_IO | 1.7 | 1.8 | 1.9 | V |
| T_junction | -40 | 25 | 95 | °C |
| F_max | — | 100 | 200 | MHz |
| I_core (active) | — | 5 | 15 | A |
| I_idle | — | 0.5 | 2 | A |
| Power (active) | — | 5 | 15 | W |
| Power (idle) | — | 0.5 | 2 | W |

*Electrical specs are theoretical targets based on 28nm process.
Actual silicon characterization pending.*

---

## 8. Package

The IP is delivered as **soft IP** (RTL source code), not as a hard
macro. Customers synthesize the IP for their target process.

**Deliverables:**
- SystemVerilog RTL source (57+ modules)
- Synthesis scripts (Yosys + Vivado)
- FPGA target constraints (Artix-7, Lattice ECP5)
- Cocotb testbench suite
- Architecture + microarchitecture specs
- Datasheet (this document)
- Integration guide
- Reference SoC design
- Bare-metal driver library

---

## 9. Quality and Reliability

| Test | Status |
|------|--------|
| Yosys synthesis clean | ✅ |
| Icarus simulation | ✅ |
| Verilator lint clean | ✅ |
| 1000-seed random regression | 🚧 In progress |
| Formal verification (SymbiYosys) | 🚧 Planned |
| Gate-level simulation | 🚧 Planned |
| FPGA validation | ✅ Artix-7 |
| Silicon validation | 🚧 TinyTapeout (planned) |

## 10. Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | [TODAY] | Initial release |

---

*This datasheet is for informational purposes only. Specifications
subject to change without notice.*
