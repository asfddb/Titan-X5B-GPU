# Antigravity Delegation Brief — Titan X5-B Remediation Support

You are Antigravity, collaborating with Claude Code on the Titan X5-B GPU
remediation (memory coalescing LSU, IEEE-754 FPU compliance, MESI coherency,
bilinear TMU). Claude Code owns all RTL files under `rtl/` and the testbench
infrastructure under `tb/uvm/` — **do not edit those**. Your deliverables are
stimulus corpora and review documents that Claude's testbenches and reports
consume.

## Task 1 — IEEE-754 stress-vector corpus (highest priority)
Create `tb/vectors/fp32_vectors.json`: a JSON list of operand pairs (hex
strings) targeting FP32 add/mul edge cases. Format:

```json
{
  "add": [["0x7F800000", "0xFF800000"], ["0x00000001", "0x80000001"], ...],
  "mul": [["0x00000001", "0x7F000000"], ...]
}
```

Only supply **operands** — the cocotb scoreboard computes expected results
itself. Cover at least (both operand orders where asymmetric):
- qNaN / sNaN propagation, NaN with payloads
- (+Inf) + (-Inf), Inf * 0, Inf +/- finite, Inf * Inf
- +0/-0 in all sign combinations (add and mul)
- subnormal + subnormal, subnormal * subnormal (results above and below
  the subnormal threshold), smallest subnormal 0x00000001
- normal * subnormal crossing into normal range
- massive cancellation (a + b where a ≈ -b, differing only in last ulp)
- round-to-nearest-even tie cases (guard=1, round=sticky=0, lsb=0 and lsb=1)
- overflow boundary: 0x7F7FFFFF + ulp contributions, mul results just
  above/below max finite
- gradual underflow: mul results that round up to the smallest normal
- alignment-shift extremes for add (exponent difference 0, 1, 23, 24, 25, 60)

Aim for 300–1000 pairs per op. Similarly create `tb/vectors/fp16_vectors.json`
with a `"mul"` list of 16-bit hex operand pairs covering the same categories.

## Task 2 — LSU address-pattern corpus
Create `tb/vectors/lsu_patterns.json`: a JSON list of warp memory access
patterns. Each entry:

```json
{"mask": "0xFFFFFFFF", "addrs": ["0x1000", "0x1004", ... 32 entries ...], "write": 0}
```

Addresses are 4-byte aligned, below 0x40000. Cover: fully converged (all
lanes one 128-byte line), perfectly sequential, stride-2/4/8, all lanes same
address, line-boundary straddling (16 lanes in line N, 16 in N+1), fully
scattered (32 distinct lines), partial masks (single lane, alternating,
random sparse), broadcast-with-outlier, and reverse-order lanes. 50+ entries.
The testbench computes expected data and the optimal transaction count itself.

## Task 3 — MESI protocol review (document only)
Read `rtl/memory/titan_x5_l1_cache.v` (module header documents the protocol)
and the `titan_x5_coherent_xbar` module at the bottom of
`rtl/interconnect/titan_x5_crossbar.v`. Write `docs/MESI_REVIEW.md` analyzing:
state-transition completeness against the canonical MESI table, the two
documented races (pending BusUpgr invalidated; pending BusWB snooped), and
any additional race/deadlock scenarios you can construct. List concrete
counterexample traces if you find holes.

## Ground rules
- Do NOT modify anything under `rtl/`, `tb/uvm/`, `tb/Makefile`, or
  `tb/run_regression.py`.
- JSON files must be valid JSON (no comments, no trailing commas).
- Commit nothing; leave files in the working tree.
