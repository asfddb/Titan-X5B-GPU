# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Run tb/test_compute_kernels.py across every core instead of one.

WHY

Every document in this project says the same thing: the whole-GPU Icarus
simulation runs at roughly 90 clock cycles per wall second, and that is the
binding constraint on the work. The deep compute suite takes 27 minutes on the
X7 build and 54 on x5. Meanwhile the machine sits at one busy core out of
sixteen, because pytest runs the cases one after another and each `vvp` process
is single-threaded.

The cases are independent -- each one elaborates nothing, writes to its own
temporary directory, and only reads the shared .vvp image -- so there is no
reason to run them in sequence.

HOW

1. Elaborate the images ONCE, serially, up front. This is the one piece of
   shared mutable state: several workers building the same .vvp path at the
   same time would interleave writes and produce a corrupt image, and the
   mtime-based reuse check in compute_runner.build() cannot see that happening.
   Both launch masks the suite uses (0x01 and 0xFF) are built before any
   worker starts, so every worker finds a complete image and reuses it.

2. Collect the test node ids with pytest itself, so the set of cases can never
   drift from what the suite actually contains.

3. Run them N at a time, each in its own pytest process, and report per-case
   PASS/FAIL with the exact cycle count the case printed.

This changes no RTL and no test. A case that fails here fails under plain
pytest too -- if it does not, that difference is itself a finding worth
chasing, because it would mean a case depends on the ones before it.

    python tools/run_compute_parallel.py                  # all cases, N-1 jobs
    python tools/run_compute_parallel.py -j 8
    python tools/run_compute_parallel.py -k matmul        # pytest -k filter
    TITAN_ICACHE=1 python tools/run_compute_parallel.py   # with the I-cache
"""

import argparse
import os
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
TEST = os.path.join(ROOT, "tb", "test_compute_kernels.py")

sys.path.insert(0, os.path.join(ROOT, "tb"))
sys.path.insert(0, os.path.join(ROOT, "compiler"))

import compute_runner as cr        # noqa: E402

CYCLES_RE = re.compile(r"TITAN_CYCLES .*cycles=(\d+)")


def collect(kfilter):
    """Test node ids, from pytest itself so the list cannot go stale."""
    cmd = [sys.executable, "-m", "pytest", TEST, "--collect-only", "-q",
           "-p", "no:cacheprovider"]
    if kfilter:
        cmd += ["-k", kfilter]
    out = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT).stdout
    ids = [l.strip() for l in out.splitlines()
           if "::" in l and not l.startswith(" ")]
    return ids


def prebuild(masks):
    """Elaborate every image serially before any worker runs. See HOW above."""
    for mask in masks:
        t0 = time.time()
        path = cr.build(warp_mask=mask)
        print(f"  built {os.path.basename(path)}  ({time.time()-t0:.0f}s)",
              flush=True)


def run_one(node):
    t0 = time.time()
    proc = subprocess.run(
        [sys.executable, "-m", "pytest", node, "-q", "-s",
         "-p", "no:cacheprovider"],
        capture_output=True, text=True, cwd=ROOT)
    wall = time.time() - t0
    out = (proc.stdout or "") + (proc.stderr or "")
    m = CYCLES_RE.search(out)
    return node, proc.returncode == 0, (int(m.group(1)) if m else None), wall, out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("-j", "--jobs", type=int, default=0,
                    help="parallel jobs (default: cores - 1)")
    ap.add_argument("-k", dest="kfilter", default=None, help="pytest -k filter")
    args = ap.parse_args()

    jobs = args.jobs or max(1, (os.cpu_count() or 2) - 1)
    nodes = collect(args.kfilter)
    if not nodes:
        print("no tests collected", file=sys.stderr)
        return 2

    print(f"sm={cr.sm_flavour()} icache={'on' if cr.icache_on() else 'off'}  "
          f"{len(nodes)} cases, {jobs} jobs")
    print("elaborating images serially first:")
    prebuild([0x01, 0xFF])

    t0 = time.time()
    fails = []
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        for node, ok, cycles, wall, out in pool.map(run_one, nodes):
            name = node.split("::", 1)[-1]
            cyc = f"{cycles:>9,}" if cycles is not None else "        -"
            print(f"  {'PASS' if ok else 'FAIL'}  {cyc} cyc  {wall:6.0f}s  "
                  f"{name}", flush=True)
            if not ok:
                fails.append((name, out))

    print(f"\n{len(nodes)-len(fails)}/{len(nodes)} passed in "
          f"{time.time()-t0:.0f}s wall")
    for name, out in fails:
        print(f"\n===== {name}\n{out[-2500:]}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
