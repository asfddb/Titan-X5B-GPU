# MESI Coherency Subsystem — Deep Protocol Audit

**Date:** 2026-07-06
**Audited artifacts (working tree):**
- `rtl/memory/titan_x5_l1_cache.v` (committed, lineage 4b2bd44)
- `titan_x5_coherent_xbar` in `rtl/interconnect/titan_x5_crossbar.v` —
  **UNCOMMITTED split-transaction rewrite**. Note: the module header still
  says "Transactions are serialized"; that comment is stale. The audited
  implementation decouples a snooping FRONT-END from an L2 ENGINE via a
  4-deep in-order transaction queue.
- Method: manual protocol analysis + lexical FSM extraction (appendix A)
  + dynamic evidence from `tb/run_regression.py mesi` (appendix B).
- No RTL or testbench was modified by this audit.

**Verdict (summary):** No coherency violation, lost-update, or deadlock was
found in the audited code. Two one-cycle timing windows (§6.2, §6.3) are
*currently safe by construction* but are load-bearing and fragile under
modification; hardening assertions are recommended (§8). Liveness is
conditional on L2/backing-memory liveness (§7.3).

---

## 1. Architecture under audit

### 1.1 L1 (per SM)
Write-back, write-allocate, line-wide core port, 2-bit MESI per line
(I=0, S=1, E=2, M=3). FSM: `S_IDLE → S_LOOKUP → {S_EVICT →} S_REQ → S_FILL
→ {S_RESP} → S_IDLE`. Bus request types: `BUS_RD / BUS_RDX / BUS_UPGR /
BUS_WB`. Snoops are serviced single-cycle in `S_IDLE, S_EVICT, S_REQ,
S_RESP` (the `snoop_allowed` gate) and **deferred** in `S_LOOKUP` and
`S_FILL`; a `snp_served` flag prevents double-service while the crossbar
holds `snp_req_valid`.

### 1.2 Coherent crossbar (split-transaction)
- **Front-end** (`F_IDLE → F_SNOOP → {F_FAST | queue-push} → F_IDLE`):
  round-robin grant over requesters that are (a) not line-conflicted with
  any in-flight transaction and (b) admissible (`!queue_full`). Broadcasts
  one snoop per transaction to all masters except the requester; the grant
  order is the global coherence order.
- **Fast path:** `BusUpgr` (no data) and `BusRdX` answered by a dirty snoop
  respond directly from the front-end (`F_FAST`), skipping the L2.
- **Queue (depth 4, in-order):** `BusWB` (write, silent retire), `BusRd`
  answered dirty (write dirty data through to L2, then respond, shared=1),
  and all misses (L2 read, respond, shared = `hit_acc` for BusRd).
- **Engine** (`E_IDLE → {E_WR | E_RD} → {E_RESP} → E_IDLE`): drains the
  queue head at the L2 port (one L2 op at a time; L2 has no request IDs)
  and owns priority on the shared response bus (`m_resp_*`).

---

## 2. Canonical MESI truth-table conformance

### 2.1 Processor-initiated (L1 local)

| State | PrRd | PrWr |
|---|---|---|
| **M** | hit, serve locally, stay M ✅ (`S_LOOKUP` read-hit path) | hit, merge via BE, stay M ✅ |
| **E** | hit, stay E ✅ | hit, **silent E→M**, no bus traffic ✅ (canonical E's raison d'être) |
| **S** | hit, stay S ✅ | **BusUpgr**, wait grant+resp, then S→M ✅ (`S_REQ/S_FILL` UPGR branch) |
| **I** (miss) | **BusRd**; fill **E** if `shared=0`, **S** if `shared=1` ✅ | **BusRdX**; fill-merge via BE; → **M** ✅ |
| miss w/ dirty victim | **BusWB** first (`S_EVICT`), victim *stays resident in M* until fill (§5) ✅ | same ✅ |
| miss w/ clean victim | silent eviction (E/S dropped without notification — permitted in snoop-based MESI) ✅ | same ✅ |

### 2.2 Snoop-initiated (L1 remote)

| State | Snoop BusRd | Snoop BusRdX | Snoop BusUpgr |
|---|---|---|---|
| **M** | supply data (`dirty=1`), M→**S**; xbar writes data through to L2 ✅ | supply data (`dirty=1`), M→**I** ✅ | M→I defensively ✅ (unreachable if protocol holds: an upgrader was in S, so no M elsewhere) |
| **E** | E→**S**, `hit=1` clean ✅ | E→**I** ✅ | E→I defensively ✅ |
| **S** | stay S, `hit=1` ✅ | S→**I** ✅ | S→**I** ✅ |
| **I** | miss (`hit=0`) ✅ | miss ✅ | miss ✅ |

**Completeness:** every cell of the canonical table is implemented; no
transition is missing and no illegal transition exists (extraction in
appendix A corroborates: the only `mesi_array` writers are the lookup-hit
paths, the fill paths, the eviction paths, and the snoop block).

**Data-sourcing rules:** dirty snoop copy wins over L2 in all cases; for
BusRd the dirty line is also written through to L2 *before* the response
retires (queue entry with `q_wr=1, q_respond=1`), so L2 is clean whenever
the line is not in M anywhere. For BusRdX the L2 write-through is skipped —
correct, because the requester installs M and any subsequent reader will be
served by *its* dirty snoop, and its eventual BusWB refreshes L2.

---

## 3. Documented race 1 — pending BusUpgr invalidated before grant

Scenario: A holds X in S and wants to write; B wins the bus first with
BusRdX(X).

```
cyc  front-end            A (L1)                          B (L1)
 0   grant B: RdX(X)      S_REQ, bus_req=UPGR(X), line S  S_REQ granted
 1   F_SNOOP: snoop A,C,D S_REQ (waiting; not granted)    S_FILL
 2   collect              snoop_fire: hit S -> S->I;      —
                          race-1 trigger: state==S_REQ &&
                          pending==UPGR && snp!=BusRd &&
                          same line -> pending := BUS_RDX
 3   ...B's txn completes (queue/L2)...                   fills M
 n   grant A: **RdX**(X)  S_FILL -> receives full line,
                          merges write bytes, -> M
```

Without the conversion A would be *granted an upgrade for a line it no
longer holds* and would merge its bytes into a stale/invalid frame — a
silent data-corruption hole. The conversion is applied while `bus_req_valid`
is still asserted and the crossbar latches `m_req_type` **at grant time**
(`F_IDLE`), so the converted type is what the bus executes. The window
where a snoop invalidates A *in the same cycle A is granted* cannot occur:
grants are issued only in `F_IDLE`, snoops only exist while the front-end
is in `F_SNOOP` for a *different* master's transaction, and per-line
conflict masking prevents X from being granted to A while B's X-transaction
is still in flight. ✅ Sound.

The BusRd variant (B issues BusRd, not RdX) correctly does **not** trigger
conversion (`snp_req_type != BUS_RD` guard): A's S-copy survives a BusRd,
so the pending upgrade remains valid. ✅

## 4. Documented race 2 — pending BusWB snooped before grant

Scenario: A must evict dirty victim V; before A's BusWB is granted, B
requests V. (Reachable under the split xbar when A loses arbitration or is
conflict-masked because B's V-transaction was granted first.)

```
cyc  front-end                A (L1)
 0   grant B: RdX(V)          S_EVICT, bus_req=WB(V), V resident M
 1   F_SNOOP: snoop A,...     —
 2                            snoop_fire: V hit M -> supply dirty data,
                              M->I; race-2 trigger: state==S_EVICT &&
                              snoop line == WB line ->
                              CANCEL WB: bus_req := {RD|RDX}(X), -> S_REQ
 3   B receives V as M (fast path, dirty RdX)
 n   grant A: fetch X normally
```

Why cancellation is *required* and not merely an optimization: if A's stale
WB(V_old) stayed pending, the legal interleaving
`B.RdX(V) -> B writes V_new -> B.WB(V_new) -> A.WB(V_old)` would leave L2
holding V_old **with no M owner anywhere** — a genuine stale-memory
end-state. Round-robin arbitration permits exactly this ordering, so the
cancel is load-bearing. ✅ Implemented correctly (the snoop supplies the
data; for BusRd-snoops the crossbar's write-through keeps L2 fresh, so
dropping the WB is safe in that variant too).

Interaction check with the fill: the cancelled-WB way is `victim_way_q`;
the subsequent fill overwrites tag/data/state of that way regardless of
what the snoop left there (S after a BusRd snoop, I after RdX) — silent
eviction of S is legal. ✅

## 5. Dirty victim stays resident until fill (design invariant)

On a dirty-victim miss the L1 deliberately does **not** invalidate the
victim at `S_LOOKUP`; V remains M-resident through `S_EVICT/S_REQ/S_FILL`
until the fill overwrites the way. Consequence: any snoop for V in that
window hits real state and real data. The alternative (invalidate-at-
lookup) reopens the §4 stale-memory hole in a form the cancel logic cannot
see (the snoop would miss). **Do not "simplify" this.** Redundant dirty
responses after the WB has retired hand over bytes identical to L2 —
harmless (the WB retires before V's line-mask lifts, §6.4).

---

## 6. Split-transaction-specific analysis (new surface)

### 6.1 Deferred snoops vs. S_FILL — liveness proof
Under the split design an L1 **can now be snooped while in `S_FILL`**
(impossible under the serialized bus): A's miss is queued; the front-end
grants B (different line — same line is masked); B's snoop broadcast
includes A. A defers (`snoop_allowed=0` in `S_FILL`), stalling the
front-end in `F_SNOOP`. Deadlock question: does A's fill depend on the
front-end? **No.** A's response comes from the ENGINE (its transaction is
already queued), and the engine's only dependencies are the queue head and
the L2 port — never the front-end and never snoop responses. Dependency
graph:

```
front-end --waits--> L1 snoop answers --wait only on--> S_FILL exit
S_FILL exit --waits--> engine E_RESP --waits--> L2 --> backing memory
engine --waits--> (nothing upstream)        => acyclic => no deadlock
```

The one case where an L1 waits on the *front-end* for its response
(`F_FAST`: BusUpgr / dirty-RdX) cannot coincide with that L1 being snooped:
the front-end is single-threaded, is occupied by that L1's own transaction
until `F_FAST` delivers, and never snoops the master it granted. ✅

`S_LOOKUP` deferral is trivially bounded (the state exits unconditionally
in one cycle). ✅

### 6.2 Retire-to-install window (one cycle, safe — fragile)
A queued response retires (`E_RESP`: `q_valid[head]<=0`, `m_resp_valid[A]
<=1`) one cycle before A installs the line (A samples `bus_resp_valid`
during cycle N+1 and writes its arrays at the end of N+1). During N+1 the
line's conflict mask is already lifted, so a same-line request from B can
be **granted at the end of N+1**:

```
cyc N    engine E_RESP: q_valid[h]:=0, resp_valid[A]:=1   (registered)
cyc N+1  A in S_FILL sees resp; installs at END of N+1.
         front-end F_IDLE: X unmasked -> may grant B(X) at END of N+1.
cyc N+2  B's snoop regs become visible; A is in S_RESP/S_IDLE
         (snoop_allowed=1) with arrays ALREADY updated at end of N+1.
cyc N+2+ A answers B's snoop from the freshly installed state. ✅
```

The snoop cannot reach A earlier than N+2 because both the grant and the
snoop broadcast are **registered** in separate front-end states. Safety
margin: exactly one cycle. Any "optimization" that broadcasts snoops
combinationally in the grant cycle, or delays the L1's array write by one
cycle, breaks this. The same analysis and margin apply to the `F_FAST`
delivery window (`fstate` returns to `F_IDLE` at the same edge the response
pulse is registered). **Recommendation §8-A1.**

### 6.3 Shared response bus arbitration (F_FAST vs E_RESP)
Both paths drive `m_resp_valid/m_resp_rdata` from the same clocked process.
`F_FAST` is gated by `!engine_responding` (`estate==E_RESP`), and `E_RESP`
lasts exactly one cycle, so a same-edge double-write is impossible: when
`estate==E_RESP` the fast path waits; when the engine merely *enters*
E_RESP on that edge, its `m_resp_*` writes occur the following cycle, by
which time the fast pulse has already been consumed (`m_resp_valid`
defaults to 0 every cycle). No response is lost or corrupted; fast-path
starvation is impossible because `E_RESP` cannot persist and the queue is
finite. ✅ (One-cycle reasoning again — assertion §8-A2.)

### 6.4 Write-back ordering vs. later same-line reads
A WB(V) queue entry masks V-line grants until it **silently retires**, and
retirement happens only after the L2 "ready-again" phase — i.e. after the
L2 has fully committed the write (the L2 consumes live address/data; the
engine holds them stable from the queue slot). Any later BusRd(V) granted
after unmasking therefore reads fresh data from L2, or fresher data from a
new M owner via snoop. A read can never be reordered ahead of an older
same-line write-back. ✅

### 6.5 Queue overflow impossibility
Pushes originate only from the single-threaded front-end: WB pushes are
gated by `!queue_full` at grant; snoop-path pushes are pre-reserved by the
same `!queue_full` check at *grant* time, and no second grant can occur
before the push (the front-end sits in `F_SNOOP` in between; the engine
only pops). Hence `q_count <= 4` always, and `q_head==q_tail` implies count
0 or 4, so push/pop never collide on a slot. ✅ (Assertion §8-A3.)

### 6.6 Response-before-grant impossibility
The earliest response for a snooped transaction is grant+4 cycles (grant ->
snoop regs -> snoop answers -> F_FAST/queue -> registered resp); the
requesting L1 enters `S_FILL` at grant+2. BusWB expects no response.
Therefore no L1 can observe `bus_resp_valid` outside `S_FILL`. ✅

### 6.7 Shared/E decision staleness
`q_shared` (the E-vs-S fill decision) is latched at snoop time and consumed
up to many cycles later at `E_RESP`. A stale decision would require another
master to acquire or drop the line in between — impossible: the line is
conflict-masked from grant until the deciding transaction retires, and
snoop order equals grant order (single front-end). ✅

### 6.8 Fairness / starvation
The round-robin pointer advances to `grant+1` on every grant; conflict
masking is transaction-scoped and every transaction retires in bounded time
(§6.1), so a persistent requester is granted within bounded turns. ✅

### 6.9 Robustness observations (not violations)
1. **Multiple dirty snoop responders**: `F_SNOOP` keeps the last-indexed
   dirty data. Reachable only if the ≤1-M-owner invariant is already
   broken; today it would silently mask corruption. Assertion §8-A4.
2. **BUS_UPGR snoop hitting M/E** is handled defensively (invalidate) —
   good; also assertion-worthy, since reaching it implies prior corruption.
3. `m_resp_shared=1` on the dirty-RdX fast path is semantically inert (the
   L1 ignores `shared` for RdX and installs M); worth a comment.
4. The module-header comment ("Transactions are serialized") predates the
   split rewrite and must be updated before commit.

---

## 7. Assumptions and conditional properties

1. **Inductive base**: all MESI arrays reset to I; the invariants above are
   inductive from that state.
2. **Bounded snoop answers**: holds because `S_LOOKUP` is 1-cycle and
   `S_FILL` exit depends only on the engine (§6.1).
3. **Liveness is conditional on the backing hierarchy**: engine -> L2 ->
   `titan_x5_l2_mem_adapter` -> legacy crossbar -> memory controller. If
   the memory controller never responds, `E_RD` waits forever. That is
   outside the coherency subsystem; the full-chip simulation exercises the
   real chain end-to-end.
4. **The TMU's private L1 instantiation** ties snoops off; it is a
   read-only client (never M, never WB) and is intentionally non-coherent
   with the SM L1s.

## 8. Recommended hardening (no functional change; NOT applied by this audit)

- **A1** SVA: a snoop request to master *i* must never be observable in the
  same cycle as `m_resp_valid[i]` for the same line (guards §6.2's margin).
- **A2** SVA: `$onehot0(m_resp_valid)`; never a fast-path response write
  while `estate==E_RESP` (guards §6.3).
- **A3** SVA: `q_count <= Q_DEPTH`; `push && queue_full` never true.
- **A4** SVA: at most one `snp_resp_dirty` per snoop round; at most one
  master with `dbg_mesi` in {M,E} per line (the testbench already checks
  the latter dynamically).
- Update the stale "serialized" header comment before committing the
  split-transaction rewrite.

## 9. Dynamic evidence

`python tb/run_regression.py mesi` against the audited working tree:
**4/4 pass** — directed producer/consumer (stale-data check, M→S
intervention, S→M upgrade, write-after-invalidate, partial-line byte-enable
merge), a 300-op serialized sequential-consistency run against a
byte-accurate model, a dirty-eviction storm (2-way × 4-set L1s), and a
4-master concurrent storm with a continuous invariant monitor (≤1 M/E owner
per line; M/E ⇒ all others I). The storm specifically exercises the §3, §4
and §6.1 interleavings.

---

## Appendix A — extracted FSM transition inventory (lexical)

Produced by a regex-based extractor (`fsm_extract.py`, session scratchpad;
context = nearest case label, so nested-case contexts appear as the inner
label — a known limitation of the lexical method, resolved by hand below):

```
L1 state:   S_IDLE->S_LOOKUP; S_LOOKUP->{S_IDLE (hit paths), S_REQ (upgr,
            clean-miss), S_EVICT (dirty-miss)}; S_EVICT->S_REQ (+ race-2
            snoop path S_EVICT->S_REQ); S_REQ->S_FILL;
            S_FILL->{S_IDLE via BUS_RD/RDX/UPGR branches (+S_RESP pulse)}
XBAR fstate: F_IDLE->F_SNOOP; F_SNOOP->{F_FAST x2, F_IDLE x2};
             F_FAST->F_IDLE
XBAR estate: E_IDLE->{E_WR, E_RD}; E_WR->{E_RESP, E_IDLE(silent WB)};
             E_RD->E_RESP; E_RESP->E_IDLE
```

No unreachable states; all three machines have `default -> *_IDLE` arms.

## Appendix B — audit trail

- MESI regression: `TESTS=4 PASS=4 FAIL=0` (2026-07-06, working tree with
  the uncommitted split-transaction crossbar).
- This document supersedes the 2026-07-05 review, which audited the
  serializing crossbar that the split-transaction rewrite replaces.
