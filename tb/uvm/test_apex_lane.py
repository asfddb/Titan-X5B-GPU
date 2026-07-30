# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_apex_fma_lane: operand isolation must be power-only, not functional.

DUT: syn/gt2n/iso_miter.v -- two titan_apex_fma_lane instances fed identical
stimulus, one with ISOLATE=1 and one with ISOLATE=0. Both compute `en` the
same way, so the ONLY difference between them is that the isolated lane
clamps its operands to zero on cycles it is not launching an operation.

The property under test is that this is invisible at the output:

    bad = (valid_out_A ^ valid_out_B)
        | (valid_out_A & (results or flags differ))

and `bad` must never assert.

Why a test rather than a proof
-----------------------------
A bounded sequential SAT proof of this miter was attempted
(syn/gt2n/iso_miter.v is written for it) and is not tractable here: two full
FMAs unrolled 12 cycles is 2.17 million variables, and Yosys' solver did not
finish in 9 minutes. The structural argument -- the FMA is strictly
feed-forward, so an operation launched with valid_in=1 cannot be influenced
by operands presented on any other cycle -- is sound but is an argument, so
it is checked here against randomised traffic instead.

The stimulus deliberately maximises the number of isolated cycles, because
those are the only cycles on which the two lanes' internal state diverges;
a test that kept the pipe permanently busy would never isolate anything and
would prove nothing.
"""

import random
import struct

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly

from tb_common import start_clock_and_reset

SPECIALS = [
    0x00000000, 0x80000000,              # +/- 0
    0x3F800000, 0xBF800000,              # +/- 1.0
    0x7F800000, 0xFF800000,              # +/- inf
    0x7FC00000, 0xFFC00000,              # qNaN
    0x7F800001, 0xFF800001,              # sNaN
    0x00000001, 0x807FFFFF,              # subnormals
    0x00800000, 0x7F7FFFFF,              # smallest normal, largest finite
]


def rand_operand(rng):
    r = rng.random()
    if r < 0.4:
        return rng.choice(SPECIALS)
    if r < 0.6:
        return (rng.getrandbits(1) << 31) | (rng.randrange(0, 8) << 23) \
               | rng.getrandbits(23)
    return rng.getrandbits(32)


async def run_stream(dut, rng, n_ops, launch_prob, active_prob, label):
    """Drive n_ops operations with randomised idle gaps; watch `bad`."""
    launched = 0
    isolated_cycles = 0
    valid_seen = 0
    cycles = 0

    while launched < n_ops or cycles < n_ops * 3 + 24:
        want = (rng.random() < launch_prob) and launched < n_ops
        active = rng.random() < active_prob

        dut.valid_in.value = 1 if want else 0
        dut.lane_active.value = 1 if active else 0
        dut.a.value = rand_operand(rng)
        dut.b.value = rand_operand(rng)
        dut.c.value = rand_operand(rng)
        dut.rm.value = rng.randrange(4)

        await ReadOnly()
        assert int(dut.bad.value) == 0, (
            f"{label}: operand isolation changed the result at cycle {cycles} "
            f"(bad asserted) -- isolation is not functionally transparent")
        if int(dut.uA_.dbg_isolated.value):
            isolated_cycles += 1
        if int(dut.vA.value):
            valid_seen += 1

        await RisingEdge(dut.clk)
        if want and active:
            launched += 1
        cycles += 1

    dut.valid_in.value = 0
    dut.lane_active.value = 0
    return launched, valid_seen, isolated_cycles, cycles


@cocotb.test()
async def apex_lane_isolation_is_transparent(dut):
    """Random traffic with heavy idling: results must be untouched."""
    rng = random.Random(0xA9EC)
    await start_clock_and_reset(dut)

    launched, valid_seen, iso, cycles = await run_stream(
        dut, rng, n_ops=14, launch_prob=0.35, active_prob=0.8,
        label="sparse")

    assert launched > 0, "no operations launched -- stimulus is broken"
    assert valid_seen > 0, "no results emerged -- stimulus is broken"
    # The whole point is that isolation actually engaged.
    assert iso > cycles // 4, (
        f"only {iso}/{cycles} cycles were isolated; this test cannot see an "
        f"isolation bug if isolation barely engages")
    dut._log.info(
        f"sparse: {launched} ops launched, {valid_seen} results, "
        f"{iso}/{cycles} cycles isolated, no functional difference")


@cocotb.test()
async def apex_lane_back_to_back(dut):
    """Back-to-back issue, with no idle gaps between launches.

    The complement of the sparse test: if results diverged only under
    back-to-back issue, the sparse test's heavy idling could hide it.

    Note the isolated-cycle count this reports is still high. That is not a
    contradiction -- every launch happens in the first n_ops cycles with no
    gaps, and the loop then runs on to drain the pipe, which is idle time.
    The property being exercised is the gapless launch burst at the start.
    """
    rng = random.Random(0x2244)
    await start_clock_and_reset(dut)

    launched, valid_seen, iso, cycles = await run_stream(
        dut, rng, n_ops=12, launch_prob=1.0, active_prob=1.0,
        label="dense")

    assert launched > 0 and valid_seen > 0
    dut._log.info(
        f"dense: {launched} ops launched, {valid_seen} results, "
        f"{iso}/{cycles} cycles isolated, no functional difference")


@cocotb.test()
async def apex_lane_inactive_lane_computes_nothing(dut):
    """lane_active low must suppress launches entirely.

    This is the coarse power knob; if it did not actually gate `valid_in`
    the lane would keep computing while nominally powered down.
    """
    rng = random.Random(0x5150)
    await start_clock_and_reset(dut)

    dut.lane_active.value = 0
    results = 0
    for _ in range(12):
        dut.valid_in.value = 1              # asking for work...
        dut.a.value = rand_operand(rng)
        dut.b.value = rand_operand(rng)
        dut.c.value = rand_operand(rng)
        dut.rm.value = rng.randrange(4)
        await ReadOnly()
        assert int(dut.bad.value) == 0
        results += int(dut.vA.value)
        await RisingEdge(dut.clk)

    dut.valid_in.value = 0
    assert results == 0, (
        f"{results} results emerged while lane_active was low -- the lane "
        f"kept computing with its power gate nominally off")
    dut._log.info("inactive lane produced 0 results across 12 request cycles")
