# 2D Mesh NoC Router Analysis & Advanced Routing Proposal

## 1. Review of Current Architecture
The current router implementation (`rtl/interconnect/titan_x5_mesh_router.v`) uses a standard **XY Dimension-Order Routing (DOR)** algorithm. 
- **Implementation Detail:** The function `xy_route` explicitly compares the destination coordinates with the current coordinates, prioritizing X-axis traversal before Y-axis traversal.
- **Deadlock Properties:** XY routing is inherently deadlock-free in a fully connected 2D mesh because it prohibits all turns from the Y dimension to the X dimension (e.g., North-to-East, South-to-West), preventing any cyclic resource dependencies.

## 2. Limitations of XY Dimension-Order Routing
While simple and deadlock-free, XY DOR has several significant drawbacks for an advanced, high-performance NoC like the Titan X5:
1. **Zero Adaptivity:** It always chooses the exact same path between a source and destination. If a router or link on that path is congested, packets will stall, increasing latency and reducing overall throughput.
2. **Poor Fault Tolerance:** Because there is only one valid path, a single link or node failure completely breaks communication between specific nodes.
3. **Uneven Network Utilization:** Traffic is often concentrated in the center of the mesh, causing hotspots, while edge links remain underutilized.

## 3. Proposed Advanced Routing Algorithms (Turn-Model)
To improve performance and fault tolerance without introducing deadlocks, we propose adopting **Turn-Model Routing**. A 2D mesh has 8 possible turns. Cyclic dependencies require at least one complete cycle of turns (e.g., North-to-East, East-to-South, South-to-West, West-to-North). By strategically prohibiting a subset of these turns, we can mathematically guarantee the absence of deadlocks while allowing packets to take alternative paths.

### A. West-First Routing
- **Mechanism:** If a packet needs to travel West, it must do so first. Once it travels in any other direction (North, South, East), it is prohibited from turning West again.
- **Turns Prohibited:** North-to-West, South-to-West.
- **Pros:** High adaptivity for traffic moving East.
- **Cons:** Zero adaptivity for traffic moving West.

### B. North-Last Routing
- **Mechanism:** If a packet needs to travel North, it must do so last. It can adaptively travel South, East, and West, but once it turns North, it cannot turn into any other direction.
- **Turns Prohibited:** North-to-East, North-to-West.
- **Pros:** High adaptivity for Southbound traffic.

### C. Negative-First Routing
- **Mechanism:** Packets must first complete all movement in the negative directions (West and South) before making any movement in the positive directions (East and North).
- **Turns Prohibited:** East-to-South, East-to-West, North-to-South, North-to-West (simplified: positive to negative turns).

### D. Odd-Even Turn Model (Recommended)
- **Mechanism:** Instead of universally prohibiting turns across the whole mesh, the Odd-Even model prohibits East-to-North and East-to-South turns at **even columns**, and North-to-West and South-to-West turns at **odd columns**.
- **Pros:** It provides a much more balanced adaptiveness compared to West-First or North-Last, avoiding asymmetric traffic bottlenecks. It remains mathematically deadlock-free.

## 4. Alternative: Virtual Channel (VC) Based Fully Adaptive Routing
Since `titan_x5_mesh_router.v` already defines `NUM_VCS` (Virtual Channels), we can also implement **Duato's Protocol (Escape VCs)**:
- Dedicate one VC (the "escape VC") strictly to deterministic XY routing.
- Use the remaining VCs for **fully adaptive routing** (allowing all turns, enabling dynamic pathfinding based on local buffer congestion).
- If adaptive VCs become congested or encounter a potential cycle, packets transition to the escape VC, which mathematically guarantees deadlock resolution.

## 5. Conclusion & Recommendation
For the Titan X5 NoC, we recommend implementing the **Odd-Even Turn Model** if we wish to keep VC allocation simple and preserve VCs strictly for QoS classes. If we want maximum performance and are willing to dedicate one VC to deadlock avoidance, **Fully Adaptive Routing with Escape VCs** is the optimal choice for a modern GPU architecture.
