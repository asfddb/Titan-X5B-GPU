# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Render a high-quality path trace by splitting the frame across every core.

WHY

`titan_compiler.simulate()` is a Python interpreter for the Titan ISA. It
retires roughly two million instructions a second, single-threaded, and a
path traced frame at a sample count high enough not to look grainy costs
tens of billions. One core turns that into most of a day.

The frame splits perfectly, though: every pixel is independent, and the kernel
seeds its RNG from the pixel index, so a band rendered on its own is
bit-identical to the same rows rendered as part of the whole. Fourteen workers
on a sixteen-core machine turn a day into an hour, and the image is the same
image.

This is the same reasoning as `tools/run_compute_parallel.py`, which the
handoff notes for the compute suite: the project kept calling simulation speed
the binding constraint while using one core out of sixteen.

USAGE

  python tools/titan_trace_parallel.py --width 480 --height 300 --samples 64
  python tools/titan_trace_parallel.py --jobs 8 --samples 16      # quicker
"""
import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TRACE = REPO / "tools" / "titan_trace.py"


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--width", type=int, default=480)
    ap.add_argument("--height", type=int, default=300)
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--bounces", type=int, default=4)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--jobs", type=int, default=max(1, (os.cpu_count() or 4) - 2))
    ap.add_argument("--outdir", default="trace_out")
    ap.add_argument("--name", default="pathtrace_hq")
    args = ap.parse_args()

    outdir = REPO / args.outdir
    bands_dir = outdir / "bands"
    bands_dir.mkdir(parents=True, exist_ok=True)

    # Split rows as evenly as possible; the last band absorbs the remainder.
    n = min(args.jobs, args.height)
    edges = [round(i * args.height / n) for i in range(n + 1)]
    bands = [(edges[i], edges[i + 1]) for i in range(n) if edges[i + 1] > edges[i]]

    print(f"  {args.width}x{args.height}, {args.samples} samples/pixel, "
          f"{args.bounces} bounces")
    print(f"  {len(bands)} workers over {os.cpu_count()} logical cores")
    print()

    procs = []
    t0 = time.time()
    for i, (r0, r1) in enumerate(bands):
        raw = bands_dir / f"{args.name}_{i:03d}.raw"
        cmd = [sys.executable, "-u", str(TRACE), "pathtrace",
               "--width", str(args.width), "--height", str(args.height),
               "--samples", str(args.samples), "--bounces", str(args.bounces),
               "--seed", str(args.seed),
               "--row0", str(r0), "--row1", str(r1),
               "--raw-out", str(raw), "--outdir", args.outdir]
        log = open(bands_dir / f"{args.name}_{i:03d}.log", "w")
        procs.append((i, r0, r1, raw,
                      subprocess.Popen(cmd, cwd=REPO, stdout=log, stderr=log),
                      log))
        print(f"    worker {i:2d}: rows {r0:4d}..{r1:4d}")

    print()
    done = 0
    for i, r0, r1, raw, p, log in procs:
        p.wait()
        log.close()
        done += 1
        ok = p.returncode == 0 and raw.exists()
        print(f"  [{done}/{len(procs)}] worker {i:2d} rows {r0}..{r1} "
              f"{'ok' if ok else 'FAILED'}  ({time.time()-t0:.0f}s elapsed)")
        if not ok:
            print((bands_dir / f'{args.name}_{i:03d}.log').read_text()[-1500:])
            return 1

    # Stitch. Bands are raw RGB, top to bottom, in worker order.
    data = bytearray()
    for i, r0, r1, raw, p, log in procs:
        b = raw.read_bytes()
        want = (r1 - r0) * args.width * 3
        if len(b) != want:
            print(f"  band {i} is {len(b)} bytes, expected {want}")
            return 1
        data += b

    from PIL import Image
    out = outdir / f"{args.name}.png"
    Image.frombytes("RGB", (args.width, args.height), bytes(data)).save(out)
    dt = time.time() - t0
    print()
    print(f"  wrote {out}  ({dt/60:.1f} min wall)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
