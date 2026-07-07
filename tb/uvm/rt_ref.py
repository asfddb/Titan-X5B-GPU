# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Bit-exact golden models for the Titan X5 ray tracing hardware.

Mirrors, integer for integer, the Q16.16 fixed-point arithmetic of
  rtl/raytracing/titan_x5_ray_triangle_isect.v   (Möller-Trumbore, NR recip)
  rtl/raytracing/titan_x5_ray_box_isect.v        (slab test)
  rtl/raytracing/titan_x5_rt_core.v              (stack traversal order)
so testbenches can predict every DUT output exactly, including truncation,
wrap-around and saturation behaviour.
"""

MASK32 = 0xFFFFFFFF
FX_ONE = 1 << 16          # 1.0 in Q16.16
NR_C1 = 1515870810        # round(24/17 * 2^30)
NR_C2 = 505290270         # round( 8/17 * 2^30)
STACK_DEPTH = 32


def se32(x):
    """Two's-complement wrap to signed 32-bit."""
    x &= MASK32
    return x - (1 << 32) if x & 0x80000000 else x


def fx(v):
    """Float -> Q16.16 (round to nearest)."""
    return se32(int(round(v * 65536.0)))


def fx_to_f(v):
    return v / 65536.0


def fx_mul(a, b):
    """RTL fx_mul: (a*b)[47:16] reinterpreted as signed 32."""
    return se32((a * b) >> 16)


def fx_inv_dir(d):
    """Reciprocal direction as the testbench feeds it: 2^32/d truncated,
    saturated for zero/overflow."""
    if d == 0:
        return 0x7FFFFFFF
    if d > 0:
        r = (1 << 32) // d
        return min(r, 0x7FFFFFFF)
    r = (1 << 32) // (-d)
    return -min(r, 0x7FFFFFFF)


def clz32(x):
    x &= MASK32
    if x == 0:
        return 32
    n = 0
    for i in range(31, -1, -1):
        if x & (1 << i):
            return 31 - i
    return 32


def tri_isect(o, d, v0, v1, v2):
    """Exact model of titan_x5_ray_triangle_isect.

    o, d, v0..v2: 3-tuples of signed Q16.16 ints.
    Returns (hit, t, u, v) with t/u/v exactly as the DUT emits them
    (zero when miss).
    """
    e1 = [se32(v1[i] - v0[i]) for i in range(3)]
    e2 = [se32(v2[i] - v0[i]) for i in range(3)]
    s = [se32(o[i] - v0[i]) for i in range(3)]

    h = [se32(fx_mul(d[1], e2[2]) - fx_mul(d[2], e2[1])),
         se32(fx_mul(d[2], e2[0]) - fx_mul(d[0], e2[2])),
         se32(fx_mul(d[0], e2[1]) - fx_mul(d[1], e2[0]))]

    det = se32(fx_mul(e1[0], h[0]) + fx_mul(e1[1], h[1]) + fx_mul(e1[2], h[2]))
    unum = se32(fx_mul(s[0], h[0]) + fx_mul(s[1], h[1]) + fx_mul(s[2], h[2]))

    q = [se32(fx_mul(s[1], e1[2]) - fx_mul(s[2], e1[1])),
         se32(fx_mul(s[2], e1[0]) - fx_mul(s[0], e1[2])),
         se32(fx_mul(s[0], e1[1]) - fx_mul(s[1], e1[0]))]

    vnum = se32(fx_mul(d[0], q[0]) + fx_mul(d[1], q[1]) + fx_mul(d[2], q[2]))
    tnum = se32(fx_mul(e2[0], q[0]) + fx_mul(e2[1], q[1]) + fx_mul(e2[2], q[2]))

    # stage 5: sign-normalize (32-bit wrapping negate) + hit test
    if det < 0:
        n_det, n_unum, n_vnum, n_tnum = (se32(-det), se32(-unum),
                                         se32(-vnum), se32(-tnum))
    else:
        n_det, n_unum, n_vnum, n_tnum = det, unum, vnum, tnum

    # RTL compares uv_sum (exact 33-bit) against {1'b0, n_det} (unsigned)
    n_det_u = n_det & MASK32
    hit = (det != 0 and n_unum >= 0 and n_vnum >= 0
           and (n_unum + n_vnum) <= n_det_u and n_tnum > 0)

    if not hit:
        return False, 0, 0, 0

    # stages 5..13: Newton-Raphson reciprocal of n_det (as unsigned)
    k = clz32(n_det_u)
    m = (n_det_u << k) & MASK32 if n_det_u else 0x80000000
    if n_det_u == 0:
        k = 0

    r = (NR_C1 - ((NR_C2 * m) >> 31)) & MASK32
    for _ in range(3):
        p = ((m * r) >> 31) & MASK32
        r = ((r * ((0x80000000 - p) & MASK32)) >> 30) & MASK32

    recip_wide = (r << k) >> 29
    recip = MASK32 if recip_wide > MASK32 else recip_wide

    def out(num_u):
        w = (num_u * recip) >> 16
        return 0x7FFFFFFF if w >= (1 << 31) else w

    return (True, out(n_tnum & MASK32), out(n_unum & MASK32),
            out(n_vnum & MASK32))


def box_isect(o, inv, t_max, bmin, bmax):
    """Exact model of titan_x5_ray_box_isect. Returns (hit, t_entry)."""
    tmin = []
    tmax_ax = []
    for i in range(3):
        t1 = fx_mul(se32(bmin[i] - o[i]), inv[i])
        t2 = fx_mul(se32(bmax[i] - o[i]), inv[i])
        tmin.append(min(t1, t2))
        tmax_ax.append(max(t1, t2))
    lo = max(tmin)
    hi = min(tmax_ax)
    hit = lo <= hi and hi >= 0 and lo <= t_max
    return hit, lo


# ---------------------------------------------------------------------------
# BVH: builder + traversal-order-exact reference
# ---------------------------------------------------------------------------

class BVHNode:
    __slots__ = ("leaf", "left", "right", "bmin", "bmax", "tri_id", "verts")

    def __init__(self):
        self.leaf = False
        self.left = self.right = 0
        self.bmin = self.bmax = (0, 0, 0)
        self.tri_id = 0
        self.verts = None


def build_bvh(tris):
    """tris: list of (tri_id, v0, v1, v2) with Q16.16 vertex tuples.
    Returns (nodes dict addr->BVHNode, root_addr). Simple median split."""
    nodes = {}
    next_addr = [1]  # 0 is never used so a root ptr of 0 stays distinguishable

    def alloc():
        a = next_addr[0]
        next_addr[0] += 1
        return a

    def tri_bounds(t):
        _, v0, v1, v2 = t
        bmin = tuple(min(v0[i], v1[i], v2[i]) for i in range(3))
        bmax = tuple(max(v0[i], v1[i], v2[i]) for i in range(3))
        return bmin, bmax

    def rec(items):
        addr = alloc()
        n = BVHNode()
        nodes[addr] = n
        if len(items) == 1:
            tid, v0, v1, v2 = items[0]
            n.leaf = True
            n.tri_id = tid
            n.verts = (v0, v1, v2)
            return addr
        bounds = [tri_bounds(t) for t in items]
        bmin = tuple(min(b[0][i] for b in bounds) for i in range(3))
        bmax = tuple(max(b[1][i] for b in bounds) for i in range(3))
        n.bmin, n.bmax = bmin, bmax
        # split on the widest axis at the centroid median
        ext = [bmax[i] - bmin[i] for i in range(3)]
        axis = ext.index(max(ext))
        items = sorted(items, key=lambda t: t[1][axis] + t[2][axis] + t[3][axis])
        mid = len(items) // 2
        n.left = rec(items[:mid])
        n.right = rec(items[mid:])
        return addr

    root = rec(list(tris))
    return nodes, root


def node_to_bits(n):
    """Encode a BVHNode into the 384-bit node_rsp_data word."""
    def u32(x):
        return x & MASK32

    if n.leaf:
        v0, v1, v2 = n.verts
        w = 1  # header [383:352], bit 352 = leaf
        w = (w << 32) | u32(n.tri_id)   # [351:320]
        w <<= 32                        # [319:288] unused in a leaf
        for c in (v0[0], v0[1], v0[2], v1[0], v1[1], v1[2],
                  v2[0], v2[1], v2[2]):
            w = (w << 32) | u32(c)      # [287:0]
        return w
    w = 0
    w = (w << 32) | u32(n.left)
    w = (w << 32) | u32(n.right)
    for c in (n.bmin[0], n.bmin[1], n.bmin[2],
              n.bmax[0], n.bmax[1], n.bmax[2]):
        w = (w << 32) | u32(c)
    w <<= 96  # unused low bits of an internal node
    return w


def traverse(nodes, root, o, d, inv):
    """Exact model of the rt_core per-ray traversal (same order, same
    pruning, same stack-overflow drop policy).

    Returns (hit, tri_id, t, u, v) exactly as res_* emits them."""
    stack = []
    node = root
    ct = 0x7FFFFFFF
    best = (False, 0, 0, 0)
    while True:
        n = nodes[node]
        if n.leaf:
            h, t, u, v = tri_isect(o, d, *n.verts)
            if h and t < ct:
                ct = t
                best = (True, n.tri_id, u, v)
            if stack:
                node = stack.pop()
            else:
                break
        else:
            near, far = ((n.left, n.right) if d[0] >= 0
                         else (n.right, n.left))
            h, _ = box_isect(o, inv, ct, n.bmin, n.bmax)
            if h:
                if len(stack) < STACK_DEPTH:
                    stack.append(far)
                node = near
            elif stack:
                node = stack.pop()
            else:
                break
    bhit, tid, u, v = best
    return bhit, (tid if bhit else 0), ct, u, v
