# MESI Protocol Review: Titan X5-B L1 Cache & Coherent Crossbar

## 1. State-Transition Completeness
The implementation adheres to the canonical MESI protocol with standard transitions:

* **Local Read Hit:**
  * **M, E, S** -> remain in same state; line served locally.
* **Local Write Hit:**
  * **M** -> remains **M**; data updated locally.
  * **E** -> silent upgrade to **M**; data updated locally.
  * **S** -> transitions to **S_REQ** for **BusUpgr**, then to **M**.
* **Local Read Miss (Clean Victim):**
  * Issues **BusRd**. Transitions to **S** (if `bus_resp_shared=1`) or **E** (if `bus_resp_shared=0`).
* **Local Write Miss (Clean Victim):**
  * Issues **BusRdX**. Transitions directly to **M** after merging write data.
* **Local Read/Write Miss (Dirty Victim):**
  * Issues **BusWB** for the victim. State temporarily remains **M** in the array (detailed below) and evicts, then issues **BusRd** / **BusRdX**.
* **Snoop Responses:**
  * **BusRd Snoop:** Hits on M/E/S downgrade to **S**. A hit on **M** additionally responds with `dirty=1` and supplies the modified data to the crossbar (which writes it through to L2 and forwards to the requesting master).
  * **BusRdX/BusUpgr Snoop:** Hits on M/E/S invalidate the line (**I**). A hit on **M** (for BusRdX) responds with `dirty=1` and supplies data to the crossbar.

All standard state transitions map correctly, and write-allocations correctly acquire exclusive ownership before committing core writes.

## 2. Documented Races

### Race 1: Pending BusUpgr Invalidated
**Scenario:** A cache (Cache A) holding a line in **S** receives a write request from the core. It enters `S_REQ` to broadcast a **BusUpgr**. Before the crossbar grants A the bus, Cache B is granted the bus for a **BusRdX** or **BusUpgr** targeting the same line.
**Resolution:** 
Cache A snoops Cache B's request. Since Cache A holds the line in **S**, it registers a hit, invalidates the line (S $\rightarrow$ I), and correctly identifies that its pending **BusUpgr** is no longer valid. The protocol logic:
```verilog
if (state == S_REQ && bus_req_type == BUS_UPGR &&
    snp_req_type != BUS_RD &&
    snp_req_addr[ADDR_WIDTH-1:OFFSET_BITS] == bus_req_addr[ADDR_WIDTH-1:OFFSET_BITS]) begin
    bus_req_type <= BUS_RDX;
end
```
By converting its pending transaction to a **BusRdX**, Cache A will safely re-fetch the entire line from L2 (or via a cache-to-cache transfer from Cache B) instead of erroneously promoting a now-stale line to **M**.

### Race 2: Pending BusWB Snooped
**Scenario:** A cache (Cache A) replaces a dirty line (**M**) and enters `S_EVICT` waiting for a grant to issue a **BusWB**. Before it gets the grant, Cache B requests the exact same line via **BusRd** or **BusRdX**.
**Resolution:**
The snoop hits Cache A. Cache A provides the dirty data directly to the snoop response, satisfying Cache B. It then immediately aborts its own **BusWB** and transitions to fetching its *new* line:
```verilog
if (state == S_EVICT &&
    snp_req_addr[ADDR_WIDTH-1:OFFSET_BITS] == bus_req_addr[ADDR_WIDTH-1:OFFSET_BITS]) begin
    bus_req_type <= req_write_q ? BUS_RDX : BUS_RD;
    ...
    state        <= S_REQ;
end
```
If the snoop was a **BusRd**, the crossbar writes the supplied dirty data through to the L2 (`X_L2WR_SNP`), preserving coherency. If it was a **BusRdX**, Cache B takes over ownership as **M**. In both cases, the L2 state is kept coherent without requiring Cache A to finish its now-redundant writeback.

## 3. Additional Race & Deadlock Scenarios Analyzed

### A. Delayed Snoop During 1-Cycle Transient States (S_LOOKUP / S_FILL)
**Scenario:** A cache is performing a silent E $\rightarrow$ M upgrade inside `S_LOOKUP` (or writing fetched data in `S_FILL`). A snoop arrives on the exact same cycle.
**Analysis:** The cache blocks snoops (`snoop_allowed` is false) during these transient states. This is critically important: if the cache serviced a **BusRd** snoop during `S_LOOKUP`, it would respond `dirty=0` (clean), the crossbar would fetch stale data from L2, and the cache would proceed to overwrite the line with its new write—causing lost updates. 
**Resolution:** Because `S_LOOKUP` strictly advances in one cycle, the snoop is safely delayed by 1 cycle. In the following cycle (`S_IDLE`), the cache processes the snoop, identifies the line is now **M**, and responds with `dirty=1` to supply the newly updated data. There is no deadlock because the crossbar waits for the snoop response, and the cache always enters a snoop-allowed state within one cycle.

### B. "Ghost" Dirty Victim Race
**Scenario:** Cache A misses and selects an **M** line as a victim, moving to `S_EVICT` and executing a **BusWB**. When the writeback completes, the cache enters `S_REQ` to fetch the new line. The `mesi_array` state for the evicted line is deliberately *not* cleared yet; it remains **M** until `S_FILL` overwrites it. While in `S_REQ`, Cache B requests the old victim line.
**Analysis:** Cache A receives the snoop and, because the array still says **M**, it responds with `hit=1, dirty=1` and supplies the (now clean) data from its array. 
**Resolution:** This response is technically redundant but perfectly safe. Cache A hasn't modified the data since the **BusWB**, so it supplies the exact same data to Cache B that the L2 already possesses. The crossbar writes it to the L2 again (if **BusRd**) or simply passes it to Cache B (if **BusRdX**). This clever optimization avoids needing a complex secondary state machine to clear victim states before `S_FILL`.

### C. Writeback / Snoop Collision Deadlock 
**Scenario:** Cache A is granted the bus for a **BusWB**.
**Analysis:** The `titan_x5_coherent_xbar` handles **BusWB** by transitioning directly to `X_L2WR` *without broadcasting snoops*. 
**Resolution:** Since a line can only be written back if it is in the **M** state, it is guaranteed that no other cache holds a valid copy of the line. Skipping the snoop phase is a safe MESI optimization and avoids any protocol deadlocks where a master might wait on snoops during an eviction.

## Conclusion
The protocol implementation is highly robust. The combination of a strict serializing crossbar, deterministic 1-cycle snoop deferrals, and intelligent overrides for pending-transaction races successfully handles all corner cases. There are no missing canonical MESI transitions, and no deadlock traces or coherency holes were found during the analysis.
