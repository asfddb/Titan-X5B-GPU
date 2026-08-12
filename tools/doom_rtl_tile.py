# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Run the raycaster's ray-cast pass on the actual SM cores, and check it.

WHY

`docs/DOOM_ON_TITAN.md` renders its frame with `titan_compiler.simulate()` --
the functional twin of `driver/titan_x6_gpu_model.c`. That is a real execution
of real Titan ISA, but it is a *model of* the machine, not the machine. The
whole-GPU RTL runs at roughly 90 clock cycles per wall second, and 18.3 million
instructions do not fit in that budget, so the full frame stays modelled.

A tile does fit. This compiles `compiler/kernels/doom_raycast_tile.py` once and
runs the identical program, with identical inputs, two ways:

  - `titan_compiler.simulate()`  -- the functional model
  - `tb/compute_runner.py`       -- `titan_x5_gpu_top` in Icarus, the SMs
                                    fetching and retiring those instructions,
                                    results read back out of the AXI memory
                                    model after a device fence

If the two agree word for word, the gap between "modelled machine" and "the
RTL itself" is closed for this arithmetic. If they disagree, that is a defect
in one of them and worth far more than the picture.

The I-cache is enabled by default here. It is still off by default in the
design (see the handoff), but a tight march loop is exactly the shape it helps,
and without it every fetch is a full crossbar round trip and the run does not
finish in reasonable time.

USAGE

  python tools/doom_rtl_tile.py                  # 4 columns, 48 steps
  python tools/doom_rtl_tile.py --cols 8 --steps 64
  python tools/doom_rtl_tile.py --model-only     # no RTL, just the model
"""
import argparse
import os
import struct
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "compiler"))
sys.path.insert(0, str(REPO / "tb"))
sys.path.insert(0, str(REPO / "tools"))

import titan_compiler as tc                                  # noqa: E402
from doom_titan import build_map, camera, u32, MAPW, FP      # noqa: E402

MAP_WORDS = MAPW * MAPW


def compile_tile():
    src = (REPO / "compiler" / "kernels" / "doom_raycast_tile.py").read_text()
    fn = tc.parse_kernel(src, "kernel")
    return tc.ScalarCodegen(fn).compile()


def run_model(program, level, cam, pos, x0, ncol, nstep, stride):
    """The functional model. Same layout as the RTL run so the two are
    comparing the same thing."""
    A_MAP, A_OUT, A_PARAM = 0x1000, 0x3000, 0x5000
    mem = bytearray(0x6000)
    for y in range(MAPW):
        for x in range(MAPW):
            struct.pack_into("<I", mem, A_MAP + 4 * (y * MAPW + x), level[y][x])
    rdx0, rdy0, incx, incy = cam
    params = [A_MAP, A_OUT, u32(rdx0), u32(rdy0), u32(incx), u32(incy),
              u32(pos[0]), u32(pos[1]), x0, ncol, nstep, stride]
    for i, v in enumerate(params):
        struct.pack_into("<I", mem, A_PARAM + 4 * i, v)
    steps = tc.simulate(program, mem, A_PARAM, max_steps=1 << 26)
    out = list(struct.unpack_from("<%dI" % (3 * ncol), mem, A_OUT))
    return out, steps


def run_rtl(program, level, cam, pos, x0, ncol, nstep, stride, max_cycles):
    """The RTL. titan_x5_gpu_top in Icarus, results read out of memory."""
    os.environ.setdefault("TITAN_ICACHE", "1")
    import compute_runner as cr

    base_map = cr.DATA_BASE
    base_out = base_map + 4 * MAP_WORDS
    data = [level[y][x] for y in range(MAPW) for x in range(MAPW)]
    data += [0] * (3 * ncol)

    rdx0, rdy0, incx, incy = cam
    params = [base_map, base_out, u32(rdx0), u32(rdy0), u32(incx), u32(incy),
              u32(pos[0]), u32(pos[1]), x0, ncol, nstep, stride]

    print("  building the whole-GPU simulation (first run elaborates)...")
    res = cr.run(program, n_res=3 * ncol, data=data, params=params,
                 res_base=base_out, max_cycles=max_cycles)
    return res


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--cols", type=int, default=4)
    ap.add_argument("--steps", type=int, default=48)
    ap.add_argument("--x0", type=int, default=80, help="first screen column")
    ap.add_argument("--stride", type=int, default=160,
                    help="gap between sampled columns")
    ap.add_argument("--angle", type=float, default=3.14159)
    ap.add_argument("--x", type=float, default=3.5)
    ap.add_argument("--y", type=float, default=19.5)
    ap.add_argument("--max-cycles", type=int, default=4_000_000)
    ap.add_argument("--model-only", action="store_true")
    args = ap.parse_args()

    level = build_map()
    cam = camera(args.angle)
    pos = (int(args.x * (1 << FP)), int(args.y * (1 << FP)))

    program = compile_tile()
    print(f"  kernel compiled to {len(program)} Titan ISA instructions")
    print(f"  tile: {args.cols} columns from x={args.x0} step {args.stride}, {args.steps} march steps")
    print(f"  camera ({args.x}, {args.y}) heading {args.angle} rad")
    print()

    model, steps = run_model(program, level, cam, pos,
                             args.x0, args.cols, args.steps, args.stride)
    print(f"  MODEL  retired {steps:,} instructions")
    for i in range(args.cols):
        t, b, c = model[3*i:3*i+3]
        print(f"    col {args.x0+i*args.stride}: top={t:3d} bot={b:3d} colour={c:2d}")

    if all(v == 0 for v in model):
        print()
        print("  every column is empty -- no ray reached a wall inside the")
        print("  step budget, so this tile would prove nothing. Move the")
        print("  camera closer or raise --steps.")
        return 1

    if args.model_only:
        return 0

    print()
    res = run_rtl(program, level, cam, pos, args.x0, args.cols, args.steps,
                  args.stride, args.max_cycles)
    if res.timed_out:
        print(f"  RTL TIMED OUT after {res.cycles:,} cycles")
        print(res.log[-2000:])
        return 1
    print(f"  RTL    retired the tile in {res.cycles:,} clock cycles")
    if res.pred_divergent:
        print("  WARNING: a divergent predicate was flagged")
    for i in range(args.cols):
        t, b, c = res.words[3*i:3*i+3]
        print(f"    col {args.x0+i*args.stride}: top={t:3d} bot={b:3d} colour={c:2d}")

    print()
    if res.words == model:
        print(f"  BIT-EXACT: all {3*args.cols} words from the RTL match the "
              f"functional model")
        return 0
    print("  MISMATCH between the RTL and the functional model:")
    for i, (a, b) in enumerate(zip(res.words, model)):
        if a != b:
            print(f"    word {i} (col {args.x0 + (i//3)*args.stride}, "
                  f"{['top','bot','colour'][i%3]}): RTL={a} model={b}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
