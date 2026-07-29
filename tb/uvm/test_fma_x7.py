# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Differential regression: 8-stage titan_x7_fp32_fma_pipe vs the proven
6-stage titan_x5_fp32_fma.

Both units see the same operand stream (specials, subnormals, randoms, all
four rounding modes) with random `en` stalling. Each unit's ordered output
stream (result + 4 flags) must match element-for-element: the x7 pipe is a
bit-exact re-partition, only latency differs (8 vs 6 cycles)."""

import random
import struct

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles

from tb_common import start_clock_and_reset

SPECIALS = [
    0x00000000, 0x80000000,              # +/- 0
    0x3F800000, 0xBF800000,              # +/- 1.0
    0x7F800000, 0xFF800000,              # +/- inf
    0x7FC00000, 0xFFC00000,              # qNaN
    0x7F800001, 0xFF800001,              # sNaN
    0x00000001, 0x80000001,              # smallest subnormals
    0x007FFFFF, 0x807FFFFF,              # largest subnormals
    0x00800000, 0x80800000,              # smallest normals
    0x7F7FFFFF, 0xFF7FFFFF,              # largest finite
    0x3F000000, 0x40000000,              # 0.5, 2.0
]


def rand_operand(rng):
    r = rng.random()
    if r < 0.35:
        return rng.choice(SPECIALS)
    if r < 0.55:
        # random exponent near the subnormal/normal boundary
        return (rng.getrandbits(1) << 31) | (rng.randrange(0, 8) << 23) | rng.getrandbits(23)
    if r < 0.70:
        # random exponent near overflow
        return (rng.getrandbits(1) << 31) | (rng.randrange(250, 256) << 23) | rng.getrandbits(23)
    return rng.getrandbits(32)


@cocotb.test()
async def fma_x7_differential(dut):
    rng = random.Random(20260718)
    await start_clock_and_reset(dut)

    ref_stream = []
    dut_stream = []
    sent = []

    n_vectors = 4000
    vectors = []
    # directed: all special x special x 1.0 combos, cycling rounding modes
    for i, x in enumerate(SPECIALS):
        for j, y in enumerate(SPECIALS):
            vectors.append((x, y, SPECIALS[(i + j) % len(SPECIALS)], (i + j) & 3))
    while len(vectors) < n_vectors:
        vectors.append((rand_operand(rng), rand_operand(rng),
                        rand_operand(rng), rng.randrange(4)))

    idx = 0
    drain = 0
    while idx < len(vectors) or drain < 20:
        # random stall: en low ~20% of cycles
        en = 0 if rng.random() < 0.2 else 1
        dut.en.value = en

        if en and idx < len(vectors):
            a, b, c, rm = vectors[idx]
            dut.valid_in.value = 1
            dut.a.value = a
            dut.b.value = b
            dut.c.value = c
            dut.rm.value = rm
            sent.append((a, b, c, rm))
            idx += 1
        elif en:
            dut.valid_in.value = 0
            drain += 1

        await RisingEdge(dut.clk)

        # valid_out is a level: during en=0 the pipe is frozen and the
        # previous result is still on the port, so only sample on en edges
        if not en:
            continue
        if int(dut.ref_valid.value):
            ref_stream.append((int(dut.ref_result.value),
                               int(dut.ref_invalid.value),
                               int(dut.ref_overflow.value),
                               int(dut.ref_underflow.value),
                               int(dut.ref_inexact.value)))
        if int(dut.dut_valid.value):
            dut_stream.append((int(dut.dut_result.value),
                               int(dut.dut_invalid.value),
                               int(dut.dut_overflow.value),
                               int(dut.dut_underflow.value),
                               int(dut.dut_inexact.value)))

    assert len(ref_stream) == len(sent), \
        f"x5 reference produced {len(ref_stream)} results for {len(sent)} inputs"
    assert len(dut_stream) == len(sent), \
        f"x7 pipe produced {len(dut_stream)} results for {len(sent)} inputs"

    mismatches = 0
    for n, (r, d) in enumerate(zip(ref_stream, dut_stream)):
        if r != d:
            a, b, c, rm = sent[n]
            dut._log.error(
                "vec %d: a=%08x b=%08x c=%08x rm=%d  x5=%08x/%s  x7=%08x/%s",
                n, a, b, c, rm, r[0], r[1:], d[0], d[1:])
            mismatches += 1
            if mismatches > 10:
                break
    assert mismatches == 0, f"{mismatches}+ mismatches between x5 and x7 FMA"
    dut._log.info("x7 FMA differential: %d vectors, all bit-exact", len(sent))


def rounding_boundary_vectors():
    """Operands landing exactly on, just above and just below a half-ULP.

    `fma_x7_differential` above has ~zero coverage of this. Demonstrated,
    not assumed: deleting the tie-to-even term from the x7 rounder
    (`RM_RNE: rnd_inc = rb && (st || mant_d[0])` -> `rb && st`) left that
    test passing on all 4000 vectors. An exact tie needs every bit below the
    round bit to be zero, which random 32-bit operands essentially never
    produce, and the SPECIALS are all exactly representable so they never
    round at all.

    Construction, using a * 1.0 + c so the tie comes from the addend:

        a = 1.m x 2^(e-127)          ULP(a) = 2^(e-127-23)
        c = 2^(e-127-24)             exactly half an ULP of a

    so a*1.0 + c sits exactly between 1.m and 1.m + 2^-23. Round-to-nearest
    -EVEN therefore rounds UP only when the mantissa LSB is 1, which is what
    the deleted term decides. Both LSB parities are swept.

    Two neighbours of each tie are included as boundary checks, catching a
    sticky bit that is computed one position off rather than dropped:

        just above the midpoint -> must round up regardless of LSB
        just below the midpoint -> must never round up
    """
    ONE = 0x3F800000
    v = []
    for exp in range(30, 250, 7):
        for lsb in (0, 1):
            for frac in (0x000000, 0x123456, 0x7FFFFE):
                mant = (frac & 0x7FFFFE) | lsb
                a = (exp << 23) | mant
                exact = (exp - 24) << 23                 # 2^(e-24)
                above = ((exp - 24) << 23) | 1           # + 2^(e-47)
                below = ((exp - 25) << 23) | 0x7FFFFF    # just under half
                for c in (exact, above, below):
                    v.append((a, ONE, c, 0))                       # RNE
                    v.append((a | 0x80000000, ONE, c | 0x80000000, 0))
                    # the directed modes must be unaffected by ties
                    for rm in (1, 2, 3):
                        v.append((a, ONE, c, rm))
    return v


@cocotb.test()
async def fma_x7_rounding_boundaries(dut):
    """Half-ULP ties and their neighbours, x7 against the proven x5 unit.

    Same differential method as above -- the x5 FMA is the oracle, and it is
    verified bit-exact against an integer reference by the `fpu` suite -- but
    with stimulus that actually reaches the tie-break logic.
    """
    rng = random.Random(0x71E)
    await start_clock_and_reset(dut)

    vectors = rounding_boundary_vectors()
    ref_stream, dut_stream, sent = [], [], []

    idx, drain = 0, 0
    while idx < len(vectors) or drain < 20:
        en = 0 if rng.random() < 0.15 else 1
        dut.en.value = en
        if en and idx < len(vectors):
            a, b, c, rm = vectors[idx]
            dut.valid_in.value = 1
            dut.a.value = a
            dut.b.value = b
            dut.c.value = c
            dut.rm.value = rm
            sent.append((a, b, c, rm))
            idx += 1
        elif en:
            dut.valid_in.value = 0
            drain += 1

        await RisingEdge(dut.clk)
        if not en:
            continue
        if int(dut.ref_valid.value):
            ref_stream.append((int(dut.ref_result.value),
                               int(dut.ref_invalid.value),
                               int(dut.ref_overflow.value),
                               int(dut.ref_underflow.value),
                               int(dut.ref_inexact.value)))
        if int(dut.dut_valid.value):
            dut_stream.append((int(dut.dut_result.value),
                               int(dut.dut_invalid.value),
                               int(dut.dut_overflow.value),
                               int(dut.dut_underflow.value),
                               int(dut.dut_inexact.value)))

    assert len(dut_stream) == len(sent), \
        f"x7 pipe produced {len(dut_stream)} results for {len(sent)} inputs"

    # A tie that rounds UP must actually occur, or the stimulus is not
    # reaching the tie-break at all and this test proves nothing.
    ties_rounding_up = 0
    mismatches = 0
    for n, (r, d) in enumerate(zip(ref_stream, dut_stream)):
        a, b, c, rm = sent[n]
        if rm == 0 and (a & 1) and ((r[0] & 0xFF) != (a & 0xFF)):
            ties_rounding_up += 1
        if r != d:
            dut._log.error(
                "vec %d: a=%08x b=%08x c=%08x rm=%d  x5=%08x/%s  x7=%08x/%s",
                n, a, b, c, rm, r[0], r[1:], d[0], d[1:])
            mismatches += 1
            if mismatches > 10:
                break
    assert mismatches == 0, \
        f"{mismatches}+ x5/x7 mismatches on rounding boundaries"
    assert ties_rounding_up > 0, (
        "no odd-mantissa case rounded up: the stimulus never reached the "
        "round-to-nearest-even tie-break, so this test proves nothing")
    dut._log.info(
        "x7 FMA rounding boundaries: %d vectors (tie / just-above / "
        "just-below, both signs, all 4 modes), %d odd-mantissa ties rounded "
        "up, all bit-exact", len(sent), ties_rounding_up)
