# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""The 2x2x2 measurement the handoff asked for: SM x I-cache x warp count.

docs/HANDOFF_NEXT_SESSION.md ends on an open question. X7 lost fourteen of
fifteen deep-suite kernels and won the one that ran eight warps, and the
explanation offered was that `titan_x7_warp_scheduler.v` requires
`sel0_warp != i1`, so a single warp can never dual-issue. That explanation
predicts a sign flip when the warp count goes up. It had not been tested,
because every kernel in the deep suite except one runs `warp_mask=0x01`.

This runs ONE kernel -- the 64-trip counted loop, which is branch- and
fetch-dominated and therefore the workload both the I-cache and dual-issue
are supposed to help -- across all eight combinations of:

    SM       x5 | x7          (TITAN_USE_X7_SM)
    I-cache  off | on         (TITAN_USE_ICACHE)
    warps    0x01 | 0xFF      (LAUNCH_WARP_MASK)

Every run is checked against titan_compiler.simulate() before its cycle count
is recorded, so a configuration cannot contribute a fast number by being
wrong. A config that fails is reported as FAIL and excluded from the table.

    python tools/bench_sm_matrix.py                 # all eight
    python tools/bench_sm_matrix.py --warps 0xFF    # one column
    python tools/bench_sm_matrix.py --trip 17       # shorter, ~4x faster

Nothing here writes to the RTL. It only elaborates images into the build
directory compute_runner already uses.
"""

import argparse
import os
import sys
import time

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "tb"))
sys.path.insert(0, os.path.join(ROOT, "compiler"))

import compute_runner as cr                       # noqa: E402
from test_compute_kernels import counted_loop_program, ref_run   # noqa: E402


def one(sm, icache, warp_mask, trip, max_cycles):
    """Elaborate and run one configuration. Returns (cycles, error-or-None)."""
    # compute_runner reads both of these at call time, so setting them here
    # is enough -- no subprocess needed, and the image cache in _sim_path()
    # keys on both, so the configurations cannot collide.
    os.environ["TITAN_SM"] = sm
    os.environ["TITAN_ICACHE"] = "1" if icache else "0"

    prog = counted_loop_program(trip)
    expect = ref_run(prog, 1)[0]

    t0 = time.time()
    try:
        res = cr.run(prog, n_res=1, max_cycles=max_cycles,
                     warp_mask=warp_mask, timeout_s=7200)
    except Exception as exc:                       # elaboration or vvp failure
        return None, f"{type(exc).__name__}: {exc}", time.time() - t0
    wall = time.time() - t0

    if res.timed_out:
        return None, "kernel never retired (watchdog)", wall
    if res.pred_divergent:
        return None, "divergent predicate flagged", wall
    if res.words[0] != expect:
        return None, (f"wrong result {res.words[0]:#x}, "
                      f"model says {expect:#x}"), wall
    return res.cycles, None, wall


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--trip", type=int, default=64,
                    help="counted-loop trip count (default 64)")
    ap.add_argument("--sm", action="append", choices=["x5", "x7"])
    ap.add_argument("--warps", action="append",
                    help="launch mask, e.g. 0x01 or 0xFF")
    ap.add_argument("--max-cycles", type=int, default=2_000_000)
    args = ap.parse_args()

    sms = args.sm or ["x5", "x7"]
    masks = ([int(w, 0) for w in args.warps] if args.warps else [0x01, 0xFF])

    rows = []
    for mask in masks:
        for icache in (False, True):
            for sm in sms:
                tag = f"sm={sm} icache={'on' if icache else 'off'} warps={mask:#04x}"
                print(f"--- {tag}", flush=True)
                cycles, err, wall = one(sm, icache, mask, args.trip,
                                        args.max_cycles)
                if err:
                    print(f"    FAIL  {err}  ({wall:.0f}s)", flush=True)
                else:
                    print(f"    {cycles} cycles  ({wall:.0f}s)", flush=True)
                rows.append((mask, icache, sm, cycles, err, wall))

    print()
    print(f"# counted loop, trip={args.trip}")
    print()
    print("| warps | I-cache | SM | cycles | wall (s) |")
    print("|:--|:--|:--|--:|--:|")
    for mask, icache, sm, cycles, err, wall in rows:
        got = f"{cycles:,}" if cycles is not None else f"FAIL ({err})"
        print(f"| {mask:#04x} | {'on' if icache else 'off'} | {sm} "
              f"| {got} | {wall:.0f} |")

    # The deltas the handoff actually asked about, printed only where both
    # halves of the pair were measured.
    by = {(m, i, s): c for m, i, s, c, e, _ in rows if c is not None}
    print()
    for mask in masks:
        for icache in (False, True):
            a, b = by.get((mask, icache, "x5")), by.get((mask, icache, "x7"))
            if a and b:
                print(f"X7 vs x5, warps={mask:#04x}, "
                      f"icache={'on' if icache else 'off'}: "
                      f"{(b - a) / a * 100:+.2f}%")
    for mask in masks:
        for sm in sms:
            a, b = by.get((mask, False, sm)), by.get((mask, True, sm))
            if a and b:
                print(f"I-cache on vs off, {sm}, warps={mask:#04x}: "
                      f"{(b - a) / a * 100:+.2f}%")

    return 0 if all(e is None for *_, e, _ in rows) else 1


if __name__ == "__main__":
    sys.exit(main())
