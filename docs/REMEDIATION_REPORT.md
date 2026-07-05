# Titan X5-B Architectural Remediation Report

**Date:** 2026-07-05
**Scope:** Memory coalescing (LSU), IEEE-754 FPU compliance, MESI cache
coherency, bilinear texture filtering — plus the transaction-based
verification environment mandated for all four.

Regression entry point: `python tb/run_regression.py` (all suites green;
no `make` required). Full-chip build: `iverilog -g2012 -s tb_titan_x5_gpu_top ...`
(see `tb/Makefile: sim_top`).

---

## Phase 1 — Memory-Coalescing LSU

**Problem fixed.** The SM previously mapped *only thread 0's* address onto a
32-bit D-cache port and broadcast one word to all 32 lanes
(`titan_x5_sm.v`, old lines 119-126): warp memory traffic was not merely
serialized — 31 lanes of every warp were silently wrong.

**New module [`rtl/memory/titan_x5_lsu.v`](../rtl/memory/titan_x5_lsu.v):**
- Accepts a warp-wide request: 32 lane addresses + write data + SIMT active
  mask (fetched per-warp from the scheduler's new `mask_query` port).
- Iterative coalescer: picks the lowest pending lane as leader, merges every
  pending lane that falls in the same 128-byte-aligned line into ONE line
  transaction (byte enables mark touched words), repeats until no lanes are
  pending. A fully converged warp costs exactly 1 transaction instead of 32.
- Same-word store conflicts: highest lane wins (documented, verified).
- `warp_resp_xactions` reports the transaction count so testbenches can
  assert coalescing *optimality*, not just correctness.

**Integration:** pipeline MEM stage → LSU → per-SM L1 D-cache → coherent
crossbar → L2 (see Phase 3). The pipeline's memory handshake was hardened
(`titan_x5_pipeline.v`): requests are held until accepted instead of pulsed
(they were previously *dropped* if the memory wasn't ready that cycle), and
the EX stage stays busy until store-acceptance / load-response so in-flight
writeback bookkeeping can no longer be clobbered.

## Phase 2 — IEEE-754 Compliance

**Problem fixed.** The ALU's "FP pipeline" computed `(src1*src2)+src3` as
*integer* arithmetic on float bit patterns (`titan_x5_alu.v`, old line 254).
`titan_x5_fp16_mul` flushed subnormals to zero and truncated instead of
rounding.

**New units (3-stage pipelines, `en`-stallable):**
- [`rtl/fpu/titan_x5_fp32_add.v`](../rtl/fpu/titan_x5_fp32_add.v) — magnitude
  swap, alignment with guard/round/sticky (borrow-corrected sticky for
  subtraction), subnormal inputs/outputs, signed-zero semantics
  (incl. exact-cancellation sign under RDN), NaN/Inf handling with canonical
  qNaN, four rounding modes (RNE/RTZ/RDN/RUP), full exception flags.
- [`rtl/fpu/titan_x5_fp32_mul.v`](../rtl/fpu/titan_x5_fp32_mul.v) — subnormal
  **pre-normalization stage** (CLZ + shift), signed-domain exponent, 24x24
  multiply, gradual-underflow denormalization, same rounding/flag support.
- [`rtl/tensor/titan_x5_fp16_mul.v`](../rtl/tensor/titan_x5_fp16_mul.v) —
  rewritten with the same algorithm at half precision (RNE), port-compatible
  with the tensor cores.

**ALU integration:** multiplier occupies stages 1-3, adder stages 4-6;
FADD/FMUL/FMA all have a uniform 6-cycle latency. New ALU ports: `fp_rm`
(rounding mode) and `fp_flags_out`. ~~Documented deviation: FMA executes
as `round(round(a*b) + c)` — a cascade with double rounding.~~
**Resolved 2026-07-06:** FMA is now a true fused single-rounding unit
([`rtl/fpu/titan_x5_fp32_fma.v`](../rtl/fpu/titan_x5_fp32_fma.v), 6-stage):
the 48-bit product is kept exact, the addend is aligned against it in a
104-bit frame (alignment shift saturating at [-24, +80] with exact
sticky preservation and addend-anchored exponent re-basing when the
addend dominates), one magnitude add/subtract, one CLZ normalize, one
rounding. Specials follow the RISC-V convention (0·∞ raises invalid even
with a quiet-NaN addend). Verified against a new integer-exact fused
oracle (`fp_fma` in `tb/uvm/fp_ref.py`, itself cross-checked by 100k
identity comparisons `fma(a,b,±0)≡mul` and `fma(a,1,c)≡add`): 250
general randoms, 10 directed fused-vs-cascade cases x 4 rounding modes,
and 1,000 exponent-overlap-biased randoms stressing catastrophic
cancellation — all bit-exact.

## Phase 3 — MESI Cache Coherency

**Problem fixed.** There was no coherency because there was no coherent
hierarchy at all: no per-SM L1 D-cache instance existed, and the L2 module
was never instantiated anywhere.

**New/rewritten blocks:**
- [`rtl/memory/titan_x5_l1_cache.v`](../rtl/memory/titan_x5_l1_cache.v) —
  full rewrite: line-wide write-back/write-allocate cache with a 2-bit MESI
  state per line, a bus-master port (BusRd / BusRdX / BusUpgr / BusWB), a
  snoop port (M-hit supplies dirty data cache-to-cache), and a `dbg_mesi`
  lookup port for protocol verification. Two protocol races are handled
  explicitly: (1) a pending BusUpgr whose line is invalidated before grant
  converts to BusRdX; (2) a pending BusWB whose victim is snooped is
  cancelled (the crossbar has already forwarded the dirty data), preventing
  a stale writeback from landing in L2 after the new owner's writeback.
  The old "L1" always allocated way 0, dropped writes on miss, and had a
  non-functional MSHR.
- `titan_x5_coherent_xbar` (in
  [`rtl/interconnect/titan_x5_crossbar.v`](../rtl/interconnect/titan_x5_crossbar.v)) —
  serializing MESI snooping bus: grant → snoop broadcast (all masters except
  requester) → data sourcing (dirty snoop copy wins over L2; dirty BusRd
  data is written through to L2) → response with `shared` (drives S vs E
  fill). The legacy 20-master word crossbar is untouched.
- `titan_x5_gpu_top.v` — instantiates 4x(LSU+L1 inside the SM), the coherent
  crossbar, **the L2 (for the first time)**, and a new
  [`rtl/memory/titan_x5_l2_mem_adapter.v`](../rtl/memory/titan_x5_l2_mem_adapter.v)
  bridging L2 lines onto legacy crossbar master 13 toward the memory
  controller.
- Pre-existing L2 bugs fixed (`titan_x5_l2_cache.v`): the memory handshake
  transitioned on `ready` without checking its own `valid` (lost requests /
  hangs), and the replacement way kept incrementing *between* FSM states so
  the victim could change mid-writeback (corruption).

## Phase 4 — Bilinear Texture Filtering

The TMU already fetched a 2x2 footprint, but the blend math was wrong in two
ways, both fixed in
[`rtl/graphics/titan_x5_tmu.v`](../rtl/graphics/titan_x5_tmu.v):
- 8-bit and 16-bit texels were blended **raw** (565 channels straddle the
  8-bit lerp lanes). Texels are now expanded to RGBA8888 *before* filtering
  (L8 → replicated luminance, RGB565 → 888 with bit replication, alpha 0xFF).
- The lerp truncated; it now rounds to nearest:
  `c = a ± ((|b-a| * f + 128) >> 8)` per channel.
- The internal texture cache is now the rewritten L1 (read-only client,
  4-byte lines, coherency ports tied off). Wrap mode assumes in-range
  integer texel coordinates (documented); clamp handles arbitrary ones.

---

## Verification (cocotb 2.0 + Icarus, transaction-based)

`tb/run_regression.py` builds and runs four suites; each has driver /
monitor / scoreboard structure with reference models, randomized
backpressure and latency on every memory interface, and hard JUnit gating
(a crashed sim cannot pass).

| Suite | DUT | Checks | Result |
|---|---|---|---|
| `lsu` | titan_x5_lsu | per-lane data, byte enables, store-conflict rule, **coalescing optimality** (issued line set == distinct active-lane lines, count == optimum) over 11 directed patterns + 150 random warps | PASS (1,461 transactions) |
| `fpu` | fp32 add/mul, fp16 mul, full ALU | bit-exact results **and all 4 exception flags** vs an integer-exact IEEE-754 oracle (itself validated against hardware float32 over 200k pairs); 8,192 directed special-case ops x 4 rounding modes, biased randoms, back-to-back pipeline streaming, ALU FADD/FMUL/FMA end-to-end | PASS |
| `mesi` | 4x L1 + coherent xbar (tiny 4-set/2-way caches for stress) | producer/consumer stale-data check, 300 serialized ops vs byte-accurate model, dirty-eviction storm, 4-way concurrent race storm; continuous invariant monitor (≤1 M/E owner, M/E ⇒ others I) | PASS |
| `tmu` | titan_x5_tmu | bit-exact color vs reference bilinear model; 3 formats x wrap/clamp x corner weights, out-of-range clamp, cache-hit determinism, randoms | PASS |

External stimulus corpora in `tb/vectors/` (`fp32_vectors.json`,
`fp16_vectors.json`, `lsu_patterns.json` — produced by the Antigravity agent
per `ANTIGRAVITY_TASKS.md`) are picked up automatically; scoreboards always
compute expectations locally, so corpora can only add coverage. Current
corpus results: 52 LSU patterns, 700 FP32 ops and 350 FP16 ops — all PASS.
Antigravity's independent protocol review (`docs/MESI_REVIEW.md`) analyzed
the canonical transition table, both documented races, and three additional
scenarios; it reports no missing transitions, deadlocks, or coherency holes.

**Bugs the testbenches caught during bring-up** (fixed before sign-off):
- fp32 adder lost the sticky bit when the alignment shift exceeded the
  54-bit window (e.g. `1.0 + 2^-149` reported exact; RUP failed to round up).
- Two testbench-side protocol races (read-after-edge sampling), documented
  in the TB code as ReadOnly-phase sampling rules.

## Phase 5 (2026-07-06) — Full-chip "rasterizer out of bounds" root cause

The long-standing full-chip failure (`Rasterizer drew out of bounds`,
12 stray pixels) was root-caused and fixed. **It was never the rasterizer**
— the framebuffer had never received a single correctly-colored pixel in
this test's history, and the "12 stray pixels" were the DRAW/FENCE command
packet itself: the ring buffer lived at VRAM offset 0 and aliased into the
region the checker scanned. Eight stacked defects (2 RTL, 6 testbench) hid
behind that one symptom:

**RTL bugs (both fixed):**
1. *Warp-scheduler X-lock* (`titan_x5_pipeline.v`) — the scheduler's
   scoreboard hazard lookup indexed with source-register fields decoded
   combinationally from the **uninitialized instruction-FIFO head** (X at
   time 0). `scoreboard[warp][X]` returns X, X-stalling every warp forever,
   so no SM ever fetched an instruction. Fixed by gating the FIFO head with
   `fifo_empty`.
2. *Unthrottled instruction fetch* (`titan_x5_pipeline.v`, `titan_x5_sm.v`,
   `titan_x5_gpu_top.v`) — the fetch request was held high with **no
   grant/flow control**, so the crossbar re-accepted the same request every
   cycle, flooding the memory controller's CDC FIFO with duplicate reads
   and starving the command processor and ROP (once bug 1 was fixed and the
   SMs woke up). Fixed by wiring the crossbar accept signal
   (`xbar_m_req_ready`) into the SM as `l1_icache_gnt` and limiting each SM
   to one outstanding fetch, with the in-flight warp id captured at accept.

**Testbench bugs (`tb/tb_titan_x5_gpu_top.v`, all fixed):**
3. Framebuffer read-back used a 1024-pixel row stride; the ROP and display
   engine both use `VGA_H_VISIBLE` (1920). The TB now derives its stride
   from one localparam passed down as a parameter override on the DUT.
4. The ring buffer at `0x1000_0000` aliases to VRAM offset 0, colliding
   with the framebuffer scan region and the shader code at PC=0. Moved to
   1 MiB into VRAM.
5. `write_vram_word` subtracted a fixed `0x1000_0000` base, so installing
   the shader instruction at address 0 underflowed to an out-of-bounds
   array index and was silently dropped — the SMs never had a real program.
   The task now mirrors the AXI model's 8 MiB address aliasing.
6. The register-file backdoor init ran at time 0, but the RF zeroes itself
   while `rst_n` is low, wiping the deposit at the first clock edge. The
   init now runs after reset deassertion.
7. The per-thread gradient color was built as `{a_val, b_val, g_val,
   r_val}` from four 32-bit regs — a 128-bit concatenation truncated to
   its low word, leaving only the red channel. Now packs byte slices.
8. The AXI VRAM model ignored `wstrb` (the memory controller replicates
   the 32-bit payload across the 512-bit bus and strobes one word), so
   each committed pixel smeared across a 16-pixel block. The model now
   commits byte-by-byte per the strobes. The fixed `#50000` render wait
   was also replaced with an adaptive quiesce loop (no new VRAM write
   commits for 3 consecutive 10 µs windows, 500 µs hard cap).

**Result:** the full-chip render test now genuinely passes — 181 pixels
drawn, all inside the expected bounding box, zero out of bounds, probe
pixel (16,30) present, with real per-thread gradient colors flowing
SM shader → ROP → crossbar → memory controller → AXI VRAM. All four
regression suites (lsu/fpu/mesi/tmu) re-run green after the RTL changes.

## Known limitations / pre-existing issues (out of scope)

- `rtl/titan_x5_fpga_top.v` references Xilinx primitives (BUFG) and a
  missing `titan_x5_vram_ctrl`; simulation builds must scope elaboration
  with `-s tb_titan_x5_gpu_top` (pre-existing).
- The coherent crossbar serializes transactions (correctness-first snooping
  bus); throughput optimization (split transactions, multiple outstanding)
  is future work.
- The LSU handles one warp request at a time; MSHR-style hit-under-miss is
  future work.
- The SM has no instruction cache and no per-warp PC advance
  (`warp_pc_in` is tied to 0 in `titan_x5_gpu_top.v`), so active warps
  refetch the same instruction from memory; fetch is now flow-controlled
  to one outstanding request per SM, but a real I-cache and PC sequencing
  remain future work.
