# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_ray_triangle_isect unit tests.

The DUT is a 14-stage, II=1 pipeline. Checks:
  1. Directed hits/misses with analytically known t/u/v.
  2. A back-to-back random stream (one new test per clock) verified
     bit-exactly against the rt_ref golden model - this also proves the
     initiation-interval-1 claim because outputs must come back gap-free.
  3. Float cross-check on well-conditioned hits (fixed-point t within
     tolerance of the real-arithmetic answer).
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

from tb_common import start_clock_and_reset
from rt_ref import fx, fx_to_f, tri_isect

TAG_MASK = 0xFF


def float_mt(o, d, v0, v1, v2, min_det=0.0):
    """Plain float Möller-Trumbore (double-sided), Q16.16 inputs."""
    of = [c / 65536.0 for c in o]
    df = [c / 65536.0 for c in d]
    a = [c / 65536.0 for c in v0]
    b = [c / 65536.0 for c in v1]
    c3 = [c / 65536.0 for c in v2]
    e1 = [b[i] - a[i] for i in range(3)]
    e2 = [c3[i] - a[i] for i in range(3)]
    h = [df[1] * e2[2] - df[2] * e2[1],
         df[2] * e2[0] - df[0] * e2[2],
         df[0] * e2[1] - df[1] * e2[0]]
    det = sum(e1[i] * h[i] for i in range(3))
    if abs(det) < max(1e-9, min_det):
        return None
    s = [of[i] - a[i] for i in range(3)]
    u = sum(s[i] * h[i] for i in range(3)) / det
    q = [s[1] * e1[2] - s[2] * e1[1],
         s[2] * e1[0] - s[0] * e1[2],
         s[0] * e1[1] - s[1] * e1[0]]
    v = sum(df[i] * q[i] for i in range(3)) / det
    t = sum(e2[i] * q[i] for i in range(3)) / det
    if u < 0 or v < 0 or u + v > 1 or t <= 0:
        return None
    return t, u, v


async def drive_stream(dut, cases):
    """Feed one case per clock (II=1), collect outputs, return results."""
    results = []

    async def monitor():
        while len(results) < len(cases):
            await FallingEdge(dut.clk)
            if int(dut.valid_out.value):
                results.append((int(dut.tag_out.value),
                                int(dut.is_hit.value),
                                int(dut.t_out.value),
                                int(dut.u_out.value),
                                int(dut.v_out.value)))

    mon = cocotb.start_soon(monitor())

    for i, (o, d, v0, v1, v2) in enumerate(cases):
        await RisingEdge(dut.clk)
        dut.valid_in.value = 1
        dut.tag_in.value = i & TAG_MASK
        for name, vec in (("ray_o", o), ("ray_d", d),
                          ("v0", v0), ("v1", v1), ("v2", v2)):
            for ax, val in zip("xyz", vec):
                getattr(dut, f"{name}_{ax}").value = val & 0xFFFFFFFF
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0

    await ClockCycles(dut.clk, 25)
    mon.kill()
    assert len(results) == len(cases), \
        f"expected {len(cases)} outputs, got {len(results)} (II=1 violated?)"
    return results


def check_case(idx, case, got):
    o, d, v0, v1, v2 = case
    exp = tri_isect(o, d, v0, v1, v2)
    tag, hit, t, u, v = got
    assert tag == idx & TAG_MASK, f"case {idx}: tag {tag} != {idx & TAG_MASK}"
    assert hit == int(exp[0]), \
        f"case {idx}: hit={hit} expected={int(exp[0])} case={case}"
    if exp[0]:
        assert (t, u, v) == exp[1:], \
            f"case {idx}: t/u/v {(t, u, v)} != {exp[1:]} case={case}"


@cocotb.test()
async def test_directed(dut):
    """Known-answer hits and misses."""
    dut.valid_in.value = 0
    await start_clock_and_reset(dut)

    tri = ((fx(0), fx(0), fx(5)), (fx(4), fx(0), fx(5)), (fx(0), fx(4), fx(5)))
    cases = [
        # straight-on hit at (1,1,5): t=5, u=0.25, v=0.25
        ((fx(1), fx(1), fx(0)), (fx(0), fx(0), fx(1))) + tri,
        # backface (approach from +z going -z) still hits (double-sided)
        ((fx(1), fx(1), fx(10)), (fx(0), fx(0), fx(-1))) + tri,
        # miss: aimed past the hypotenuse
        ((fx(3), fx(3), fx(0)), (fx(0), fx(0), fx(1))) + tri,
        # miss: triangle behind the ray
        ((fx(1), fx(1), fx(10)), (fx(0), fx(0), fx(1))) + tri,
        # degenerate triangle (collinear vertices) must never hit
        ((fx(1), fx(1), fx(0)), (fx(0), fx(0), fx(1)),
         (fx(0), fx(0), fx(5)), (fx(2), fx(0), fx(5)), (fx(4), fx(0), fx(5))),
    ]
    results = await drive_stream(dut, cases)
    for i, (case, got) in enumerate(zip(cases, results)):
        check_case(i, case, got)

    # analytic values for case 0
    _, hit, t, u, v = results[0]
    assert hit == 1
    assert abs(fx_to_f(t) - 5.0) < 0.01, f"t={fx_to_f(t)}"
    assert abs(fx_to_f(u) - 0.25) < 0.01, f"u={fx_to_f(u)}"
    assert abs(fx_to_f(v) - 0.25) < 0.01, f"v={fx_to_f(v)}"
    # backface hit: t=5 as well
    _, hit, t, _, _ = results[1]
    assert hit == 1 and abs(fx_to_f(t) - 5.0) < 0.01
    assert results[2][1] == 0 and results[3][1] == 0 and results[4][1] == 0


@cocotb.test()
async def test_random_stream_bitexact(dut):
    """1500 back-to-back random rays, bit-exact vs the golden model."""
    dut.valid_in.value = 0
    await start_clock_and_reset(dut)
    rng = random.Random(0xB4B1)

    def rnd_pt(lo=-20, hi=20):
        return tuple(fx(rng.uniform(lo, hi)) for _ in range(3))

    # cases 0..1349: bounded coordinates (all Q16.16 intermediates stay in
    # range -> float cross-check is meaningful); cases 1350+: large
    # coordinates that overflow-wrap, checked bit-exactly only.
    cases = []
    for ci in range(1500):
        big = ci >= 1350
        if big:
            v0, v1, v2 = rnd_pt(-200, 200), rnd_pt(-200, 200), rnd_pt(-200, 200)
            o = rnd_pt(-400, 400)
        else:
            v0, v1, v2 = rnd_pt(-5, 5), rnd_pt(-5, 5), rnd_pt(-5, 5)
            o = rnd_pt(-10, 10)
        if rng.random() < 0.7:
            # aim at a random point inside/near the triangle
            w0, w1 = rng.random(), rng.random()
            if w0 + w1 > 1 and rng.random() < 0.8:
                w0, w1 = 1 - w0, 1 - w1
            tgt = tuple(fx(fx_to_f(v0[i]) +
                           w0 * (fx_to_f(v1[i]) - fx_to_f(v0[i])) +
                           w1 * (fx_to_f(v2[i]) - fx_to_f(v0[i])))
                        for i in range(3))
            d = tuple(fx((fx_to_f(tgt[i]) - fx_to_f(o[i])) / (8.0 if not big else 400.0))
                      for i in range(3))
        else:
            d = rnd_pt(-2, 2)
        if all(abs(c) < 64 for c in d):   # avoid near-zero directions
            d = (d[0] + fx(0.5), d[1], d[2])
        cases.append((o, d, v0, v1, v2))

    results = await drive_stream(dut, cases)
    hits = 0
    float_checked = 0
    for i, (case, got) in enumerate(zip(cases, results)):
        check_case(i, case, got)
        if got[1]:
            hits += 1
            if i >= 1350:
                continue  # overflow-wrap slice: bit-exact check only
            # float cross-check only on well-conditioned cases: comfortable
            # barycentrics AND a determinant large enough that Q16.16
            # truncation noise stays small relative to the answer
            ref = float_mt(*case, min_det=0.25)
            if ref is not None and 0.5 < ref[0] < 100 and \
               0.05 < ref[1] < 0.95 and 0.05 < ref[2] < 0.95 and \
               ref[1] + ref[2] < 0.95:
                assert abs(fx_to_f(got[2]) - ref[0]) < max(0.08 * ref[0], 0.08), \
                    f"case {i}: t={fx_to_f(got[2])} float={ref[0]}"
                assert abs(fx_to_f(got[3]) - ref[1]) < 0.08
                assert abs(fx_to_f(got[4]) - ref[2]) < 0.08
                float_checked += 1
    dut._log.info(f"random stream: {hits}/{len(cases)} hits, "
                  f"{float_checked} float cross-checked")
    assert hits > 100, "test generator produced implausibly few hits"
    assert float_checked > 30, "too few well-conditioned float checks"
