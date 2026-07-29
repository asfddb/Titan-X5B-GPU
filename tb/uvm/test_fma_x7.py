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
