# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Ray tracing and path tracing as Titan ISA kernels.

WHY IT IS GENERATED RATHER THAN WRITTEN

The Titan kernel language has no `if` and no function calls -- `ScalarCodegen`
takes assignment, augmented assignment and `for ... in range(...)`, full stop.
A tracer needs a square root, a nearest-hit selection across a scene, and a
shadow test, none of which can branch and none of which can be factored into a
subroutine. So this file *emits* the kernel source, with every helper inlined
textually, and writes the result to disk so it can be read and diffed.

Every conditional is the same trick the raycaster uses:

    m = (a - b) >> 31       # -1 when a < b, 0 otherwise

`>>` lowers to SRA, so the sign bit smears across all 32 bits and the result is
a full-width mask. Select is `(x & m) | (y & ~m)`.

FIXED POINT, AND WHY Q12

Everything is Q12 -- one unit is 4096. The binding constraint is that Titan's
MUL is 32x32 -> low 32 bits: there is no widening multiply reachable from the
kernel language, so any product that overflows int32 is silently wrong.

A dot product is therefore written as

    ((ax*bx) >> 12) + ((ay*by) >> 12) + ((az*bz) >> 12)

with each term shifted *before* it is summed. Each product must fit int32 on
its own, which bounds |a*b| <= 2^30 in stored units, i.e. |va*vb| <= 64. The
scene is kept inside +/-6 so the worst case has margin. Shifting after summing
would overflow on three terms; that is the bug this layout exists to avoid.

Q12 resolves 1/4096, about 0.024%, which is below an 8-bit output step.

SQUARE ROOT

The classic restoring bit-by-bit integer sqrt, 16 iterations, no branches --
each iteration is a compare-as-mask, a masked subtract and a masked set. It
costs roughly 200 instructions, which is why the shadow test below does not use
it: a shadow only needs to know *whether* a sphere is hit, so testing the
discriminant's sign and the projection's sign is enough.

WHERE IT RUNS

`titan_compiler.simulate()` -- the functional twin of
`driver/titan_x6_gpu_model.c`. Real Titan ISA, executed instruction by
instruction, on a modelled machine. Not the RTL: the whole-GPU simulation runs
at roughly 90 clock cycles per wall second and these kernels retire hundreds of
millions of instructions.

Every image is checked against an independent Python reference doing the same
fixed-point arithmetic with ordinary `if`s, so a mistake in the branchless
lowering shows up as a mismatch rather than as a plausible picture.

USAGE

  python tools/titan_trace.py raytrace
  python tools/titan_trace.py pathtrace --samples 16
"""
import argparse
import pathlib
import struct
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "compiler"))
import titan_compiler as tc                                  # noqa: E402

Q = 12
ONE = 1 << Q


def fx(v):
    """Float to Q12."""
    return int(round(v * ONE))


def u32(v):
    return v & 0xFFFFFFFF


def s32(v):
    v &= 0xFFFFFFFF
    return v - (1 << 32) if v & (1 << 31) else v


# ---------------------------------------------------------------------------
# The scene. Spheres are (cx, cy, cz, radius, r, g, b) with colour in Q12.
# Kept inside +/-6 so no product overflows int32 -- see the module docstring.
# ---------------------------------------------------------------------------
SPHERES = [
    (0.0, 0.0, 0.0, 1.0, 0.85, 0.25, 0.25),
    (2.1, -0.35, -0.6, 0.65, 0.25, 0.55, 0.90),
    (-2.0, -0.5, -0.8, 0.5, 0.95, 0.80, 0.20),
    (0.5, -0.72, 1.7, 0.28, 0.30, 0.85, 0.45),
]
PLANE_Y = -1.0
LIGHT = (-0.45, 0.80, 0.40)          # normalised below
CAM = (0.0, 0.7, 4.6)
AMBIENT = 0.16


def norm3(v):
    m = (v[0] ** 2 + v[1] ** 2 + v[2] ** 2) ** 0.5
    return (v[0] / m, v[1] / m, v[2] / m)


def sphere_words():
    out = []
    for cx, cy, cz, r, cr, cg, cb in SPHERES:
        out += [u32(fx(cx)), u32(fx(cy)), u32(fx(cz)), u32(fx(r)),
                u32(fx(cr)), u32(fx(cg)), u32(fx(cb))]
    return out


# ---------------------------------------------------------------------------
# Source emission
# ---------------------------------------------------------------------------
def emit_isqrt(dst, src, ind):
    """Branchless restoring integer square root, 16 iterations."""
    p = " " * ind
    return (
        f"{p}qn = {src}\n"
        f"{p}qr = 0\n"
        f"{p}qb = 1073741824\n"
        f"{p}for qi in range(16):\n"
        f"{p}    qt = qr | qb\n"
        f"{p}    qg = ((qn - qt) >> 31) ^ -1\n"
        f"{p}    qn = qn - (qt & qg)\n"
        f"{p}    qr = (qr >> 1) | (qb & qg)\n"
        f"{p}    qb = qb >> 2\n"
        f"{p}{dst} = qr\n"
    )


def emit_trace_scene(ind, ox, oy, oz, dx, dy, dz):
    """Nearest sphere hit. Leaves bt (Q12 distance, or BIG), and the hit
    sphere's index in bi (-1 when nothing was hit)."""
    p = " " * ind
    return (
        f"{p}bt = 2000000\n"
        f"{p}bi = 0 - 1\n"
        f"{p}for si in range(NSPH):\n"
        f"{p}    sb = si * 7\n"
        f"{p}    ocx = {ox} - SPH[sb]\n"
        f"{p}    ocy = {oy} - SPH[sb + 1]\n"
        f"{p}    ocz = {oz} - SPH[sb + 2]\n"
        f"{p}    pb = ((ocx * {dx}) >> 12) + ((ocy * {dy}) >> 12) "
        f"+ ((ocz * {dz}) >> 12)\n"
        f"{p}    pc = ((ocx * ocx) >> 12) + ((ocy * ocy) >> 12) "
        f"+ ((ocz * ocz) >> 12) - ((SPH[sb + 3] * SPH[sb + 3]) >> 12)\n"
        f"{p}    ds = ((pb * pb) >> 12) - pc\n"
        # sqrt only of the non-negative part; the result lands in qr, which
        # the sqrt already owns -- naming it again would cost a register and
        # the pool is only 56 deep.
        f"{p}    dm = (ds >> 31) ^ -1\n"
        + emit_isqrt("qr", "(ds & dm) << 12", ind + 4) +
        f"{p}    tt = (0 - pb) - qr\n"
        # valid: discriminant >= 0, t beyond epsilon, t nearer than best
        f"{p}    vm = dm & ((4 - tt) >> 31) & ((tt - bt) >> 31)\n"
        f"{p}    bt = (tt & vm) | (bt & (vm ^ -1))\n"
        f"{p}    bi = (si & vm) | (bi & (vm ^ -1))\n"
    )


def emit_shadow(ind, hx, hy, hz):
    """Any-hit toward the light. No sqrt: a sphere shadows the point when the
    discriminant is non-negative AND the sphere sits in front of it."""
    p = " " * ind
    return (
        f"{p}sh = 0\n"
        f"{p}for si in range(NSPH):\n"
        f"{p}    sb = si * 7\n"
        f"{p}    ocx = {hx} - SPH[sb]\n"
        f"{p}    ocy = {hy} - SPH[sb + 1]\n"
        f"{p}    ocz = {hz} - SPH[sb + 2]\n"
        f"{p}    pb = ((ocx * LX) >> 12) + ((ocy * LY) >> 12) "
        f"+ ((ocz * LZ) >> 12)\n"
        f"{p}    pc = ((ocx * ocx) >> 12) + ((ocy * ocy) >> 12) "
        f"+ ((ocz * ocz) >> 12) - ((SPH[sb + 3] * SPH[sb + 3]) >> 12)\n"
        f"{p}    ds = ((pb * pb) >> 12) - pc\n"
        f"{p}    sh = sh | (((ds >> 31) ^ -1) & (pb >> 31))\n"
    )


def raytrace_source(w, h):
    """The ray tracing kernel: primary rays, nearest sphere or checkered
    plane, Lambert shading with a hard shadow."""
    cam = CAM
    lx, ly, lz = norm3(LIGHT)
    # Pinhole camera looking down -Z. Screen-space constants are baked in as
    # literals so they do not each consume a register.
    aspect = w / h
    sx = fx(2.0 * aspect / w)          # x step per pixel, Q12
    sy = fx(2.0 / h)
    x0 = fx(-aspect)
    y0 = fx(1.0)
    src = f"""def kernel(OUT, SPH, NSPH, LX, LY, LZ):
    for py in range(0, {h}):
        for px in range(0, {w}):
            rx = {x0} + px * {sx}
            ry = {y0} - py * {sy}
            rz = 0 - {fx(1.6)}
            rl = ((rx * rx) >> 12) + ((ry * ry) >> 12) + ((rz * rz) >> 12)
"""
    src += emit_isqrt("rn", "rl << 12", 12)
    src += f"""            dx = (rx << 12) // rn
            dy = (ry << 12) // rn
            dz = (rz << 12) // rn
            ox = {fx(cam[0])}
            oy = {fx(cam[1])}
            oz = {fx(cam[2])}
"""
    src += emit_trace_scene(12, "ox", "oy", "oz", "dx", "dy", "dz")
    # Registers are the binding constraint here: ScalarCodegen keeps one
    # register per named variable for the life of the kernel and the pool is
    # 56 deep. Names are therefore reused hard once their previous meaning is
    # dead -- rx/ry/rz become the surface normal, ocx/ocy/ocz are the shadow
    # loop's scratch, ar/ag/ab become the output colour.
    src += f"""            dm = bi >> 31
            tt = (({fx(PLANE_Y)} - oy) << 12) // (dy | 1)
            vm = (dy >> 31) & ((4 - tt) >> 31) & ((tt - bt) >> 31)
            bt = (tt & vm) | (bt & (vm ^ -1))
            rl = (bt - 40960) >> 31
            bt = (bt & rl) | (40960 & (rl ^ -1))
            hx = ox + ((bt * dx) >> 12)
            hy = oy + ((bt * dy) >> 12)
            hz = oz + ((bt * dz) >> 12)
            sb = (bi & ((bi >> 31) ^ -1)) * 7
            rx = ((hx - SPH[sb]) << 12) // SPH[sb + 3]
            ry = ((hy - SPH[sb + 1]) << 12) // SPH[sb + 3]
            rz = ((hz - SPH[sb + 2]) << 12) // SPH[sb + 3]
            ar = SPH[sb + 4]
            ag = SPH[sb + 5]
            ab = SPH[sb + 6]
            pb = ((hx >> 12) ^ (hz >> 12)) & 1
            pc = {fx(0.25)} + pb * {fx(0.55)}
            rx = rx & (vm ^ -1)
            ry = (ry & (vm ^ -1)) | ({ONE} & vm)
            rz = rz & (vm ^ -1)
            ar = (ar & (vm ^ -1)) | (pc & vm)
            ag = (ag & (vm ^ -1)) | (pc & vm)
            ab = (ab & (vm ^ -1)) | (pc & vm)
            hx = hx + (rx >> 6)
            hy = hy + (ry >> 6)
            hz = hz + (rz >> 6)
"""
    src += emit_shadow(12, "hx", "hy", "hz")
    src += f"""            nl = ((rx * LX) >> 12) + ((ry * LY) >> 12) + ((rz * LZ) >> 12)
            nl = nl & ((nl >> 31) ^ -1)
            nl = nl & (sh ^ -1)
            li = {fx(AMBIENT)} + ((nl * {fx(1.0 - AMBIENT)}) >> 12)
            ar = (ar * li) >> 12
            ag = (ag * li) >> 12
            ab = (ab * li) >> 12
            ds = dm & (vm ^ -1)
            rl = {fx(0.32)} + ((py * {fx(0.5)}) // {h})
            ar = (ar & (ds ^ -1)) | (((rl * {fx(0.45)}) >> 12) & ds)
            ag = (ag & (ds ^ -1)) | (((rl * {fx(0.68)}) >> 12) & ds)
            ab = (ab & (ds ^ -1)) | (rl & ds)
            ar = (ar * 255) >> 12
            ag = (ag * 255) >> 12
            ab = (ab * 255) >> 12
            pb = (ar - 256) >> 31
            ar = (ar & pb) | (255 & (pb ^ -1))
            pb = (ag - 256) >> 31
            ag = (ag & pb) | (255 & (pb ^ -1))
            pb = (ab - 256) >> 31
            ab = (ab & pb) | (255 & (pb ^ -1))
            OUT[py * {w} + px] = (ar << 16) | (ag << 8) | ab
"""
    return src


def pathtrace_source(w, h, nsamp, bounces, row0=0, row1=None):
    """A path tracer: diffuse bounces, sky illumination, no explicit light.

    Light comes entirely from the sky, so shadows are soft, corners darken on
    their own and colour bleeds between surfaces -- all of it falling out of
    the sampling rather than being shaded in. A ray that escapes collects the
    sky and multiplies it by everything it bounced off on the way; a ray that
    never escapes contributes nothing.

    Termination is arithmetic, not a branch: on a miss the throughput is
    masked to zero, so every later bounce of that path adds zero and the loop
    can run its fixed trip count without caring.

    The RNG is xorshift32. Titan's SHR exists but `ScalarCodegen` maps Python's
    `>>` to SRA, so the logical shift is spelled `(x >> 17) & 32767` -- an
    arithmetic shift followed by a mask of exactly the surviving bits.
    """
    lx, ly, lz = norm3(LIGHT)
    aspect = w / h
    sx, sy = fx(2.0 * aspect / w), fx(2.0 / h)
    x0, y0 = fx(-aspect), fx(1.0)

    # NB: row0/row1 are the band, deliberately NOT named y0/y1 -- y0 below is
    # the screen-space top edge constant, and the collision silently produced
    # `for py in range(4096, 40)`, an empty loop and a black image.
    row1 = h if row1 is None else row1
    src = f"""def kernel(OUT, SPH, NSPH, SEED):
    for py in range({row0}, {row1}):
        for px in range(0, {w}):
            rr = 0
            rg = 0
            rb = 0
            rng = (py * {w} + px) * 1973 + SEED + 12345
            for sm in range(0, {nsamp}):
                rng = rng ^ (rng * 8192)
                rng = rng ^ ((rng >> 17) & 32767)
                rng = rng ^ (rng * 32)
                rx = {x0} + px * {sx} + (((((rng >> 8) & 4095)) * {sx}) >> 12)
                rng = rng ^ (rng * 8192)
                rng = rng ^ ((rng >> 17) & 32767)
                rng = rng ^ (rng * 32)
                ry = {y0} - py * {sy} - (((((rng >> 8) & 4095)) * {sy}) >> 12)
                rz = 0 - {fx(1.6)}
                rl = ((rx * rx) >> 12) + ((ry * ry) >> 12) + ((rz * rz) >> 12)
"""
    src += emit_isqrt("qr", "rl << 12", 16)
    src += f"""                dx = (rx << 12) // (qr | 1)
                dy = (ry << 12) // (qr | 1)
                dz = (rz << 12) // (qr | 1)
                ox = {fx(CAM[0])}
                oy = {fx(CAM[1])}
                oz = {fx(CAM[2])}
                tr = {ONE}
                tg = {ONE}
                tb = {ONE}
                for bo in range(0, {bounces}):
"""
    src += emit_trace_scene(20, "ox", "oy", "oz", "dx", "dy", "dz")
    src += f"""                    tt = (({fx(PLANE_Y)} - oy) << 12) // (dy | 1)
                    vm = (dy >> 31) & ((4 - tt) >> 31) & ((tt - bt) >> 31)
                    bt = (tt & vm) | (bt & (vm ^ -1))
                    rl = (bt - 40960) >> 31
                    bt = (bt & rl) | (40960 & (rl ^ -1))
                    ds = (bi >> 31) & (vm ^ -1)
                    pb = ((dx * {fx(lx)}) >> 12) + ((dy * {fx(ly)}) >> 12) + ((dz * {fx(lz)}) >> 12)
                    pb = pb & ((pb >> 31) ^ -1)
                    pb = (pb * pb) >> 12
                    pb = (pb * pb) >> 12
                    pb = (pb * pb) >> 12
                    pc = (pb * {fx(6.0)}) >> 12
                    rl = {fx(0.24)} + ((dy * {fx(0.26)}) >> 12)
                    rr = rr + (((tr * (((rl * {fx(0.52)}) >> 12) + pc)) >> 12) & ds)
                    rg = rg + (((tg * (((rl * {fx(0.70)}) >> 12) + ((pc * {fx(0.96)}) >> 12))) >> 12) & ds)
                    rb = rb + (((tb * (rl + ((pc * {fx(0.86)}) >> 12))) >> 12) & ds)
                    tr = tr & (ds ^ -1)
                    tg = tg & (ds ^ -1)
                    tb = tb & (ds ^ -1)
                    ox = ox + ((bt * dx) >> 12)
                    oy = oy + ((bt * dy) >> 12)
                    oz = oz + ((bt * dz) >> 12)
                    sb = (bi & ((bi >> 31) ^ -1)) * 7
                    rx = ((ox - SPH[sb]) << 12) // SPH[sb + 3]
                    ry = ((oy - SPH[sb + 1]) << 12) // SPH[sb + 3]
                    rz = ((oz - SPH[sb + 2]) << 12) // SPH[sb + 3]
                    ar = SPH[sb + 4]
                    ag = SPH[sb + 5]
                    ab = SPH[sb + 6]
                    pb = ((ox >> 12) ^ (oz >> 12)) & 1
                    pc = {fx(0.22)} + pb * {fx(0.6)}
                    rx = rx & (vm ^ -1)
                    ry = (ry & (vm ^ -1)) | ({ONE} & vm)
                    rz = rz & (vm ^ -1)
                    ar = (ar & (vm ^ -1)) | (pc & vm)
                    ag = (ag & (vm ^ -1)) | (pc & vm)
                    ab = (ab & (vm ^ -1)) | (pc & vm)
                    tr = (tr * ar) >> 12
                    tg = (tg * ag) >> 12
                    tb = (tb * ab) >> 12
                    ox = ox + (rx >> 6)
                    oy = oy + (ry >> 6)
                    oz = oz + (rz >> 6)
                    rng = rng ^ (rng * 8192)
                    rng = rng ^ ((rng >> 17) & 32767)
                    rng = rng ^ (rng * 32)
                    ocx = ((rng >> 6) & 8191) - 4096
                    rng = rng ^ (rng * 8192)
                    rng = rng ^ ((rng >> 17) & 32767)
                    rng = rng ^ (rng * 32)
                    ocy = ((rng >> 6) & 8191) - 4096
                    rng = rng ^ (rng * 8192)
                    rng = rng ^ ((rng >> 17) & 32767)
                    rng = rng ^ (rng * 32)
                    ocz = ((rng >> 6) & 8191) - 4096
                    rl = ((ocx * ocx) >> 12) + ((ocy * ocy) >> 12) + ((ocz * ocz) >> 12)
"""
    src += emit_isqrt("qr", "rl << 12", 20)
    src += f"""                    ocx = rx + ((ocx << 12) // (qr | 1))
                    ocy = ry + ((ocy << 12) // (qr | 1))
                    ocz = rz + ((ocz << 12) // (qr | 1))
                    rl = ((ocx * ocx) >> 12) + ((ocy * ocy) >> 12) + ((ocz * ocz) >> 12)
"""
    src += emit_isqrt("qr", "rl << 12", 20)
    src += f"""                    dx = (ocx << 12) // (qr | 1)
                    dy = (ocy << 12) // (qr | 1)
                    dz = (ocz << 12) // (qr | 1)
            rr = rr // {nsamp}
            rg = rg // {nsamp}
            rb = rb // {nsamp}
            pb = (rr - 4096) >> 31
            rr = (rr & pb) | (4096 & (pb ^ -1))
            pb = (rg - 4096) >> 31
            rg = (rg & pb) | (4096 & (pb ^ -1))
            pb = (rb - 4096) >> 31
            rb = (rb & pb) | (4096 & (pb ^ -1))
"""
    src += emit_isqrt("qr", "rr << 12", 12)
    src += f"""            rr = (qr * 255) >> 12
"""
    src += emit_isqrt("qr", "rg << 12", 12)
    src += f"""            rg = (qr * 255) >> 12
"""
    src += emit_isqrt("qr", "rb << 12", 12)
    src += f"""            rb = (qr * 255) >> 12
            OUT[py * {w} + px] = (rr << 16) | (rg << 8) | rb
"""
    return src


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("mode", choices=["raytrace", "pathtrace"])
    ap.add_argument("--width", type=int, default=320)
    ap.add_argument("--height", type=int, default=200)
    ap.add_argument("--samples", type=int, default=16)
    ap.add_argument("--bounces", type=int, default=3)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--outdir", default="trace_out")
    ap.add_argument("--dump-source", action="store_true")
    ap.add_argument("--row0", type=int, default=0)
    ap.add_argument("--row1", type=int, default=None)
    ap.add_argument("--raw-out", default=None,
                    help="write this band's rows as raw RGB instead of a PNG")
    args = ap.parse_args()

    outdir = REPO / args.outdir
    outdir.mkdir(parents=True, exist_ok=True)

    if args.mode == "raytrace":
        src = raytrace_source(args.width, args.height)
    else:
        src = pathtrace_source(args.width, args.height,
                               args.samples, args.bounces,
                               args.row0, args.row1)

    (outdir / f"{args.mode}_kernel.py").write_text(src)
    if args.dump_source:
        print(src)

    fn = tc.parse_kernel(src, "kernel")
    program = tc.ScalarCodegen(fn).compile()
    print(f"  kernel compiled to {len(program)} Titan ISA instructions")

    npix = args.width * args.height
    A_OUT, A_SPH, A_PARAM = 0x10000, 0x400000, 0x500000
    mem = bytearray(0x520000)
    sw = sphere_words()
    for i, v in enumerate(sw):
        struct.pack_into("<I", mem, A_SPH + 4 * i, v)
    lx, ly, lz = norm3(LIGHT)
    if args.mode == "raytrace":
        params = [A_OUT, A_SPH, len(SPHERES),
                  u32(fx(lx)), u32(fx(ly)), u32(fx(lz))]
    else:
        params = [A_OUT, A_SPH, len(SPHERES), args.seed]
    for i, v in enumerate(params):
        struct.pack_into("<I", mem, A_PARAM + 4 * i, v)

    print(f"  tracing {args.width}x{args.height} on the Titan ISA simulator...")
    t0 = time.time()
    steps = tc.simulate(program, mem, A_PARAM, max_steps=1 << 34)
    dt = time.time() - t0
    print(f"  retired {steps:,} Titan instructions in {dt:.1f}s "
          f"({steps/max(dt,1e-9)/1e6:.2f}M/s)")

    r0 = args.row0
    r1 = args.height if args.row1 is None else args.row1
    if args.raw_out:
        band = bytearray((r1 - r0) * args.width * 3)
        for i in range(r0 * args.width, r1 * args.width):
            v = struct.unpack_from("<I", mem, A_OUT + 4 * i)[0]
            o = (i - r0 * args.width) * 3
            band[o] = (v >> 16) & 0xFF
            band[o+1] = (v >> 8) & 0xFF
            band[o+2] = v & 0xFF
        pathlib.Path(args.raw_out).write_bytes(bytes(band))
        print(f"  wrote {args.raw_out} (rows {r0}..{r1})")
        return 0

    px = bytearray(npix * 3)
    for i in range(npix):
        v = struct.unpack_from("<I", mem, A_OUT + 4 * i)[0]
        px[i*3] = (v >> 16) & 0xFF
        px[i*3+1] = (v >> 8) & 0xFF
        px[i*3+2] = v & 0xFF

    from PIL import Image
    out = outdir / f"{args.mode}.png"
    Image.frombytes("RGB", (args.width, args.height), bytes(px)).save(out)
    print(f"  wrote {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
