# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_ray_box_isect unit tests.

4-stage II=1 slab-test pipeline: directed known answers plus a 2000-case
back-to-back random stream compared bit-exactly against rt_ref.box_isect
(hit flag and t_entry).
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

from tb_common import start_clock_and_reset
from rt_ref import fx, fx_inv_dir, box_isect

TAG_MASK = 0xFF
T_INF = 0x7FFFFFFF


async def drive_stream(dut, cases):
    results = []

    async def monitor():
        while len(results) < len(cases):
            await FallingEdge(dut.clk)
            if int(dut.valid_out.value):
                results.append((int(dut.tag_out.value),
                                int(dut.box_hit.value),
                                int(dut.t_entry_out.value)))

    mon = cocotb.start_soon(monitor())

    for i, (o, inv, tmax, bmin, bmax) in enumerate(cases):
        await RisingEdge(dut.clk)
        dut.valid_in.value = 1
        dut.tag_in.value = i & TAG_MASK
        dut.t_max_in.value = tmax & 0xFFFFFFFF
        for ax, val in zip("xyz", o):
            getattr(dut, f"ray_o_{ax}").value = val & 0xFFFFFFFF
        for ax, val in zip("xyz", inv):
            getattr(dut, f"ray_inv_d_{ax}").value = val & 0xFFFFFFFF
        for ax, val in zip("xyz", bmin):
            getattr(dut, f"box_min_{ax}").value = val & 0xFFFFFFFF
        for ax, val in zip("xyz", bmax):
            getattr(dut, f"box_max_{ax}").value = val & 0xFFFFFFFF
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0

    await ClockCycles(dut.clk, 10)
    mon.kill()
    assert len(results) == len(cases), \
        f"expected {len(cases)} outputs, got {len(results)} (II=1 violated?)"
    return results


def check(idx, case, got):
    o, inv, tmax, bmin, bmax = case
    exp_hit, exp_lo = box_isect(o, inv, tmax, bmin, bmax)
    tag, hit, lo = got
    lo_s = lo - (1 << 32) if lo & 0x80000000 else lo
    assert tag == idx & TAG_MASK
    assert hit == int(exp_hit), \
        f"case {idx}: hit={hit} expected={int(exp_hit)} case={case}"
    assert lo_s == exp_lo, \
        f"case {idx}: t_entry={lo_s} expected={exp_lo} case={case}"


@cocotb.test()
async def test_directed(dut):
    dut.valid_in.value = 0
    await start_clock_and_reset(dut)

    unit_inv = (fx_inv_dir(fx(1)), fx_inv_dir(fx(1)), fx_inv_dir(fx(1)))
    zdir_inv = (fx_inv_dir(fx(0.0001) + 1), fx_inv_dir(fx(0.0001) + 1),
                fx_inv_dir(fx(1)))
    box = ((fx(2), fx(2), fx(2)), (fx(6), fx(6), fx(6)))
    cases = [
        # diagonal ray through the box
        ((fx(0), fx(0), fx(0)), unit_inv, T_INF) + box,
        # ray starting inside the box
        ((fx(3), fx(3), fx(3)), unit_inv, T_INF) + box,
        # box behind the ray
        ((fx(10), fx(10), fx(10)), unit_inv, T_INF) + box,
        # pruned by t_max (box farther than the closest hit)
        ((fx(0), fx(0), fx(0)), unit_inv, fx(1)) + box,
        # near-axis-parallel ray offset outside the slab -> miss
        ((fx(0), fx(0), fx(0)), zdir_inv, T_INF,
         (fx(2), fx(2), fx(2)), (fx(6), fx(6), fx(6))),
    ]
    results = await drive_stream(dut, cases)
    for i, (case, got) in enumerate(zip(cases, results)):
        check(i, case, got)
    assert results[0][1] == 1
    assert results[1][1] == 1
    assert results[2][1] == 0
    assert results[3][1] == 0


@cocotb.test()
async def test_random_stream_bitexact(dut):
    dut.valid_in.value = 0
    await start_clock_and_reset(dut)
    rng = random.Random(0xB0B0)

    cases = []
    for _ in range(2000):
        o = tuple(fx(rng.uniform(-30, 30)) for _ in range(3))
        lo = tuple(fx(rng.uniform(-25, 20)) for _ in range(3))
        ext = tuple(fx(rng.uniform(0.5, 15)) for _ in range(3))
        bmin = lo
        bmax = tuple(lo[i] + ext[i] for i in range(3))
        if rng.random() < 0.5:
            # aim at a point inside the box so ~half the stream can hit
            tgt = tuple(bmin[i] + int(rng.random() * ext[i]) for i in range(3))
            d = tuple(fx((tgt[i] - o[i]) / 65536.0 / rng.uniform(4, 30))
                      for i in range(3))
            d = tuple(c if abs(c) >= 64 else c + 96 for c in d)
        else:
            d = tuple(fx(rng.uniform(0.1, 4.0) *
                         (1 if rng.random() < 0.5 else -1))
                      for _ in range(3))
        inv = tuple(fx_inv_dir(c) for c in d)
        tmax = T_INF if rng.random() < 0.5 else fx(rng.uniform(0.5, 60))
        cases.append((o, inv, tmax, bmin, bmax))

    results = await drive_stream(dut, cases)
    hits = sum(r[1] for r in results)
    for i, (case, got) in enumerate(zip(cases, results)):
        check(i, case, got)
    dut._log.info(f"random stream: {hits}/{len(cases)} hits")
    assert 100 < hits < 1900, "degenerate hit distribution"
