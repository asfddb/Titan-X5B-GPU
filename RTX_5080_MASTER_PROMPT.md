# RTX 5080 SCALING PROTOCOL

**TARGET:** Scale the Titan X5-B GPU architecture to RTX 5080 equivalence.

## 1. HARDWARE RAY TRACING (BVH)
* **Target:** `rtl/raytracing/`
* Replace `titan_x5_ray_triangle_isect.v` placeholders with a fully pipelined, unrolled Möller–Trumbore intersection pipeline.
* Implement a Hardware Bounding Volume Hierarchy (BVH) traversal state machine.
* **Requirement:** Must issue one new ray-box test per clock cycle.

## 2. FP8/INT8 TENSOR CORE ARRAY
* **Target:** `rtl/tensor/titan_x6_tensor_core_array.v`
* Upgrade the systolic array to natively support FP8 (E4M3/E5M2) and INT8 matrix multiplication.
* Scale physical dimensions to compute 16x16 or 32x32 MACs per cycle.
* Implement warp-synchronous instruction dispatch to prevent `titan_x5_sm` stalling.

## 3. NETWORK-ON-CHIP (NoC) MESH
* **Target:** `rtl/interconnect/titan_x5_crossbar.v`
* Tear out the flat crossbar. Build a 2D Mesh/Torus NoC.
* Implement packetized XY-routing with Virtual Channels (VCs) to prevent MESI invalidation deadlocks.
* Flit-level pipelining to sustain >1.5 GHz target frequency.

## 4. MASSIVE SCALING & GDDR7 INTERFACE
* **Target:** `rtl/titan_x5_gpu_top.v`
* Instantiate thousands of `titan_x5_sm` cores grouped into GPCs/TPCs.
* Expand unified L2 cache to 64MB+ with banked slice architecture.
* Widen external AXI VRAM controllers to 512-bit/384-bit to saturate GDDR7 bandwidth.

## EXECUTION RULES
1. **Pipeline Aggressively:** The RTL must hit <2.5ns (400+ MHz) synthesis timing on SkyWater 130nm to prove 2+ GHz viability on 5nm.
2. **Step-by-Step Validation:** Do not commit blindly. Build Phase 1, write `cocotb` tests, run `iverilog`, run OpenLane synthesis, prove timing closure, then move to Phase 2.
3. **Background Processing:** Send OpenLane ASIC runs to the background and write testbenches while waiting.
