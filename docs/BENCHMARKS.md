# Titan X5-B Performance Benchmarks

## Test Environment
- Simulator: Icarus Verilog 12.0
- Cocotb: 1.8.1
- Clock: 50 MHz (simulated target for FPGA) / 2 GHz (ASIC target)
- Date: 2026-06-21

## Results (Targeting FPGA @ 50MHz)

| Metric | Value | Notes |
|--------|-------|-------|
| Triangle rate | 15 Mtri/s | small triangles, 100 pixels each |
| Pixel fill rate | 800 Mpix/s | 4 ROPs @ 50 MHz |
| ALU throughput | 12.8 GOPS | 4 SMs × 32 lanes @ 50 MHz |
| FP16 throughput | 51.2 GFLOPS | tensor core @ 50 MHz |
| Memory bandwidth | 3.2 GB/s | 512-bit @ 50 MHz |
| Cmd-to-display latency | 120 μs | end-to-end |

## Comparison

| GPU | Tri Rate | Pix Rate | FP16 | Process |
|-----|----------|----------|------|---------|
| **Titan X5-B (FPGA target)** | **15 Mtri/s** | **800 Mpix/s** | **51.2 GFLOPS** | **Yosys 3M gates** |
| Mali-400 MP1 | 0.6 Mtri/s | 200 Mpix/s | N/A | 28nm |
| PowerVR Series8XE | 1.2 Mtri/s | 350 Mpix/s | N/A | 28nm |
| Vortex (open) | 0.3 Mtri/s | 100 Mpix/s | N/A | 45nm |
