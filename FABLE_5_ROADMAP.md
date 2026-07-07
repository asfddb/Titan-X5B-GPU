# Titan X5-B GPU: Next-Stage Roadmap for Claude Fable 5

Welcome, Claude. Your predecessor agents have successfully stabilized the Titan X5-B GPU architecture. The RTL is now structurally clean, the rasterizer bug is resolved, the FPU is IEEE-754 compliant with single-rounding FMA, the crossbar handles split-transactions, and the full UVM-style `cocotb` regression suite is 100% green. 

Your mission is to transition this project from a pure "simulation-only RTL design" into a physically deployable and commercially viable IP. 

Please proceed through the following phases based on the user's current compute environment and priorities.

---

## Phase 1: FPGA Physical Deployment (The Basys 3 Bring-up)
*The `rtl/titan_x5_fpga_top.v` has been unblocked and successfully passes Icarus Verilog syntax checks with a 128KB AXI4 BRAM-based `titan_x5_vram_ctrl.v`.*

**Your Tasks:**
1. **Toolchain Integration:** If the user has Xilinx Vivado or an open-source FPGA toolchain (`yosys` + `nextpnr-xilinx`) installed, create a build script (e.g., `build_fpga.ps1` or `Makefile`) to run synthesis, place-and-route (PnR), and bitstream generation.
2. **Constraints Validation:** Review `fpga/titan_x5_basys3.xdc`. Ensure that all physical I/O pins (clock, VGA DAC, LEDs, buttons) are correctly mapped to the `titan_x5_fpga_top.v` ports.
3. **Timing Closure:** Run synthesis and analyze the critical path. The Titan X5 is a massive design; it may struggle to meet the 50MHz core clock target on an Artix-7. You will likely need to insert pipeline registers or adjust the clock dividers in `fpga_top` to achieve timing closure.
4. **Hardware Hello World:** Generate the final `.bit` file for the user to flash via USB, producing a physical VGA output.

---

## Phase 2: Open-Source ASIC Physical Design (OpenLane)
*To prove the design can become real silicon, we must run it through a standard cell ASIC flow.*

**Your Tasks:**
1. **OpenLane Setup:** Create an OpenLane workspace (`openlane/titan_x5_gpu/`).
2. **Configuration:** Write the `config.tcl` targeting the SkyWater 130nm (sky130) PDK. You will need to carefully configure the target clock period, density, and pin placements.
3. **Synthesis & Macro Hardening:** A 3-million-gate GPU cannot be synthesized flat on a standard workstation. You must implement a macro-hardening flow:
   - Run synthesis and PnR on individual subsystems (e.g., `titan_x5_sm`, `titan_x5_tensor_core`, `titan_x5_l2_cache`) to generate hardened macros.
   - Integrate these hardened macros into the top-level GPU floorplan.
4. **DRC / LVS:** Resolve any Design Rule Check (DRC) or Layout vs. Schematic (LVS) violations. 
5. **Output:** Produce the final GDSII blueprint layout of the chip.

---

## Phase 3: Commercial IP Compliance (SystemVerilog UVM)
*If the goal is to sell this as "Soft IP" to a major semiconductor firm, they will expect IEEE-standard UVM testbenches.*

**Your Tasks:**
1. **UVM Scaffolding:** Begin translating the Python `cocotb` tests into SystemVerilog. Create the basic UVM hierarchy: `uvm_env`, `uvm_agent`, `uvm_driver`, `uvm_monitor`, and `uvm_scoreboard`.
2. **AXI VIP:** Replace the Python-based AXI memory models with a SystemVerilog AXI4 Verification IP (VIP).
3. **Incremental Migration:** Port the test suites one by one (start with `test_tmu`, as it is the smallest, then `fpu`, `lsu`, and finally the massive `mesi` coherence suite).

---

### Critical Instructions for Claude:
* **Preserve the RTL:** Do not make arbitrary changes to the core logic in `rtl/` unless it is strictly required to fix a timing violation discovered during FPGA/ASIC synthesis. The logic is verified and green.
* **Keep the User Informed:** Synthesis and PnR can take hours. Use background tasks effectively, and never hang the chat session while waiting for a build to finish.

---

## Phase 4: The "RTX 5080" Massive Scaling Protocol (Stretch Goal)
*The user has requested that we scale this architecture to rival flagship desktop GPUs. If the core phases are completed, begin architecting the massive scale-up.*

**Your Tasks:**
1. **Ray Tracing Hardening:** Open `rtl/raytracing/titan_x5_ray_triangle_isect.v` and replace the placeholder logic with a fully pipelined Bounding Volume Hierarchy (BVH) traversal and ray-triangle intersection mathematical pipeline.
2. **Tensor Core Expansion:** Upgrade `titan_x6_tensor_core_array.v` to support massive parallel 4x4 and 16x16 matrix multiplications for AI workloads (specifically targeting FP8/INT8).
3. **Massive ALU Instantiation:** Rewrite the top-level modules to instantiate thousands of `titan_x5_sm` cores. 
4. **Crossbar Overhaul:** Upgrade `titan_x5_crossbar.v` to a massive network-on-chip (NoC) mesh to handle the bandwidth of thousands of cores talking to the 512-bit GDDR memory controllers simultaneously without bottlenecking.
