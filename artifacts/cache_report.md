# Titan X5 GPU Cache Architecture & Wafer-Scale UMA Strategies

## 1. Current Cache Architecture Review
After reviewing the RTL in `rtl/memory`, here is the state of the current cache hierarchy:

- **L1 Data Cache (`titan_x5_l1_cache.v`)**:
  - **Specs**: 32KB, 4-way set associative, 64B cache lines.
  - **Features**: LRU replacement policy, non-blocking with a basic 4-entry MSHR, uses an AXI4 Master interface.
  - **Limitations**: 4 MSHR entries are drastically insufficient for hiding latency at a wafer scale. Hit/miss logic and way allocation are currently simplified.
- **L2 Cache (`titan_x5_l2_cache.v`)**:
  - **Specs**: 256KB Unified L2 Cache, 8-way associative, 128B lines.
  - **Features**: 4-bank design for parallel access.
  - **Limitations**: Currently acts largely as a pass-through to the memory controller. It lacks robust tag/data pipelining, mesh routing logic, and coherency integration required for a unified memory architecture.

## 2. Ultra-Low Latency UMA Strategies for Wafer-Scale Integration
Wafer-scale integration (WSI) provides massive silicon area but introduces significant on-wafer propagation delays. To achieve ultra-low latency UMA on WSI, the following strategies should be implemented:

### A. Non-Uniform Cache Architecture (NUCA)
- **Distributed Shared L2/L3 Cache**: Instead of a monolithic L2, distribute the L2 cache across the wafer mesh. Each computing node (or tile) manages a local L2 slice.
- **Dynamic Data Migration**: Implement hardware mechanisms to allow cache lines to migrate closer to the cores that most frequently access them, minimizing average Network-on-Chip (NoC) hop latency.

### B. Scalable MSHR & Aggressive Prefetching
- **Expanded MSHRs**: For WSI, where memory accesses can traverse long distances, L1 MSHR entries must be significantly increased (e.g., 32-64 per core) to support massive concurrency and effectively hide latency.
- **Spatial & Temporal Prefetchers**: Implement stride and stream prefetchers at the L1/L2 boundaries to pull data into caches before explicit requests are made.

### C. Directory-Based Cache Coherence
- Broadcast-based snooping does not scale to wafer size. Implement a **distributed directory-based coherence protocol** (e.g., MESI or MOESI) co-located with the distributed L2 slices.
- **Point-to-Point Messaging**: Use targeted unicast messages for invalidates and data forwarding to reduce NoC congestion.

### D. Advanced Network-on-Chip (NoC)
- **Low-Latency Router Microarchitecture**: Use 1-cycle or 2-cycle routers for the mesh network connecting tiles across the wafer to ensure minimal per-hop latency.
- **Dedicated Coherence Network**: Separate data, request, and coherence message virtual channels (VCs) to prevent head-of-line blocking and guarantee rapid coherence resolution.

### E. Proximity-Aware Memory Controllers & 3D TSVs
- **Distributed Memory Controllers**: Scatter HBM/Memory controllers along the wafer edges or distribute them internally to avoid traffic bottlenecks at a single edge.
- **TSV (Through-Silicon Via) Integration**: If utilizing 3D stacking, place SRAM or DRAM dies directly on top of compute tiles via TSVs, effectively turning "global" memory accesses into local, ultra-low latency vertical hops.

## 3. Recommended Next Steps for RTL
1. **L1 Upgrade**: Expand MSHR capacity in `titan_x5_l1_cache.v` and implement fully associative MSHR lookups.
2. **L2 Upgrade**: Fully flesh out the banked pipelining in `titan_x5_l2_cache.v`. Implement a slice-based NoC routing interface instead of the current single memory controller pass-through.
3. **Coherency & Routing Logic**: Introduce a directory module and NoC router RTL modules to tie multiple L1s and L2 banks together in a scalable mesh.
