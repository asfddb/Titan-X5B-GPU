# THE RTX 5080 PROTOCOL: MASTER PROMPT FOR CLAUDE FABLE 5

**TO: CLAUDE FABLE 5**
**FROM: PROJECT ARCHITECTS**
**MISSION:** You are being activated to execute a 24-month technology scale-up compressed into rapid AI iteration cycles. Your singular goal is to take the existing Titan X5-B GPU (a proven, Switch/Tegra-class architecture) and scale it into an RTX 5080-class monolithic flagship GPU.

You have access to a clean, UVM-verified repository. The logic works. The testbenches are green. Now, we break the limits of scale. You will act as a Principal Silicon Architect and execute the following massive architectural overhauls sequentially. Do not break the regression suite; upgrade it alongside the RTL.

---

## PHASE 1: THE RAY TRACING REVOLUTION (BVH IN HARDWARE)
**Target:** `rtl/raytracing/`
The current Ray Tracing implementation contains placeholders for ray-triangle intersection. A 5080 requires dedicated RT Cores capable of traversing a Bounding Volume Hierarchy (BVH) in pure hardware.
1. **Implement Hardware BVH Traversal:** Build a deeply pipelined, multi-stage state machine that fetches BVH nodes from the L2 cache, performs Ray-AABB (Axis-Aligned Bounding Box) intersection tests, and pushes hits onto a hardware stack.
2. **Ray-Triangle Intersection Pipeline:** Replace the dot-product placeholders in `titan_x5_ray_triangle_isect.v` with a fully unrolled, DSP-mapped Möller–Trumbore intersection pipeline.
3. **Throughput:** The RT Core must be able to issue one new ray-box test per clock cycle.

## PHASE 2: TENSOR CORE MASSIVE EXPANSION (AI ACCELERATION)
**Target:** `rtl/tensor/titan_x6_tensor_core_array.v`
The current systolic array works, but we need desktop-class deep learning throughput.
1. **Datatype Expansion:** Modern AI models run on 8-bit precision. Upgrade the PE (Processing Element) array to natively support **FP8 (E4M3/E5M2)** and **INT8** dot products, in addition to the existing FP16.
2. **Matrix Size Scaling:** Scale the physical array to compute 16x16 or 32x32 Matrix Multiply-Accumulates (MACs) in a single cycle. 
3. **Warp-Level Synchronization:** Implement warp-synchronous instruction dispatch so the `titan_x5_sm` can feed the Tensor Cores without stalling the main ALU pipeline.

## PHASE 3: THE NETWORK-ON-CHIP (NoC) OVERHAUL
**Target:** `rtl/interconnect/titan_x5_crossbar.v`
A standard crossbar will choke and die when connected to 16,000 cores. You must build a scalable Network-on-Chip.
1. **Mesh/Torus Topology:** Replace the flat crossbar with a 2D Mesh or Torus NoC.
2. **Packetized Routing:** Implement XY-routing routers with virtual channels (VCs) to prevent deadlocks during massive MESI cache invalidation storms.
3. **Flit-level Pipeline:** Data must traverse the network in flits (flow control units) to maintain a high clock frequency (>1.5 GHz target).

## PHASE 4: BRUTE FORCE SCALING & MEMORY BANDWIDTH
**Target:** `rtl/titan_x5_gpu_top.v`
1. **Massive Instantiation:** We need thousands of ALUs. Group the `titan_x5_sm` units into GPCs (Graphics Processing Clusters) and TPCs (Texture Processing Clusters). 
2. **L2 Cache Scaling:** Expand the unified L2 cache to 64MB+. Implement banked cache slicing so multiple NoC routers can access different memory addresses simultaneously.
3. **GDDR7 Interface:** Widen the external memory interface. Ensure the AXI VRAM controllers are fully saturated, supporting 512-bit or wider external buses.

---

### EXECUTION PROTOCOL FOR FABLE 5
* **Step-by-Step Validation:** Do not write 5,000 lines of RTL blindly. Implement Phase 1, write the `cocotb` tests to prove the BVH math works, and ensure it synthesizes. Only then move to Phase 2.
* **Monitor ASIC Synthesis:** Run OpenLane iterations frequently. The 65ns clock fix you applied to the previous tensor core is a band-aid. You must aggressively pipeline the new RT and Tensor cores to hit a **< 2.5ns (400+ MHz)** synthesis target on SkyWater 130nm, which will translate to 2+ GHz on a 5nm node.
* **Use Background Tasks:** When you trigger an OpenLane ASIC flow, send it to the background and begin writing the testbenches for the next module.

**FABLE, THE REPOSITORY IS GREEN. THE ENVIRONMENT IS READY. BEGIN PHASE 1 IMMEDIATELY.**
