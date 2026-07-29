# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Titan X7 tensor array: exact-accumulation systolic GEMM check.

The PE accumulates exact FP16 products in a Kulisch carry-save accumulator
and rounds once (RNE) at drain. The reference therefore computes the exact
rational dot product (Fractions) and rounds it once to FP32 - the RTL must
match bit-for-bit, which no per-step-rounded reference could guarantee."""

import random
import struct
from fractions import Fraction

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles

from tb_common import start_clock_and_reset

N = 4


def fp16_to_fraction(h):
    s = -1 if (h >> 15) & 1 else 1
    e = (h >> 10) & 0x1F
    f = h & 0x3FF
    if e == 0x1F:
        return None  # inf/nan: excluded from operand generation
    if e == 0:
        return Fraction(s * f, 1 << 24)
    return Fraction(s * (0x400 | f), 1 << 10) * Fraction(2, 1) ** (e - 15)


def round_fraction_to_fp32(x):
    """Correctly-rounded (RNE) FP32 of an exact rational value."""
    if x == 0:
        return 0x00000000
    sign = 1 if x < 0 else 0
    m = abs(x)
    # find e with 2^e <= m < 2^(e+1)
    e = 0
    while m >= 2:
        m /= 2
        e += 1
    while m < 1:
        m *= 2
        e -= 1
    # FP16 dot products stay far inside FP32 normal range (>= 2^-68)
    assert -126 <= e <= 127, f"exponent {e} out of simple-normal range"
    frac = m - 1                       # in [0,1)
    scaled = frac * (1 << 23)
    lo = int(scaled)                   # floor
    rem = scaled - lo
    if rem > Fraction(1, 2) or (rem == Fraction(1, 2) and (lo & 1)):
        lo += 1
    if lo == (1 << 23):                # mantissa overflow
        lo = 0
        e += 1
    return (sign << 31) | ((e + 127) << 23) | lo


def rand_fp16(rng):
    r = rng.random()
    if r < 0.15:
        return rng.choice([0x0000, 0x8000, 0x3C00, 0xBC00, 0x0001, 0x83FF,
                           0x0400, 0x7BFF, 0xFBFF])
    # random finite (exclude exp 31)
    return (rng.getrandbits(1) << 15) | (rng.randrange(0, 31) << 10) | rng.getrandbits(10)


async def run_tile(dut, rng, K):
    A = [[rand_fp16(rng) for _ in range(K)] for _ in range(N)]
    B = [[rand_fp16(rng) for _ in range(N)] for _ in range(K)]

    total = K + N - 1  # skewed injection length
    for t in range(total):
        iv = 0
        ivb = 0
        aval = 0
        bval = 0
        for i in range(N):
            k = t - i
            if 0 <= k < K:
                iv |= (1 << i)
                aval |= A[i][k] << (16 * i)
        for j in range(N):
            k = t - j
            if 0 <= k < K:
                ivb |= (1 << j)
                bval |= B[k][j] << (16 * j)
        dut.in_valid.value = iv
        dut.in_valid_b.value = ivb
        dut.a_in.value = aval
        dut.b_in.value = bval
        await RisingEdge(dut.clk)

    dut.in_valid.value = 0
    dut.in_valid_b.value = 0
    await ClockCycles(dut.clk, 2 * (N - 1) + 6)

    dut.drain.value = 1
    await RisingEdge(dut.clk)
    dut.drain.value = 0

    for _ in range(10):
        await RisingEdge(dut.clk)
        if int(dut.result_valid.value):
            break
    else:
        raise AssertionError("drain produced no result_valid")

    res = int(dut.result.value)
    errors = 0
    for i in range(N):
        for j in range(N):
            got = (res >> ((i * N + j) * 32)) & 0xFFFFFFFF
            exact = sum((fp16_to_fraction(A[i][k]) * fp16_to_fraction(B[k][j])
                         for k in range(K)), Fraction(0))
            exp = round_fraction_to_fp32(exact)
            if got != exp:
                dut._log.error("C[%d][%d]: got %08x expected %08x (exact %s)",
                               i, j, got, exp, float(exact))
                errors += 1
    assert errors == 0, f"{errors} wrong elements in {N}x{N} tile (K={K})"


@cocotb.test()
async def tensor_x7_gemm(dut):
    rng = random.Random(777)
    await start_clock_and_reset(dut)
    dut.in_valid.value = 0
    dut.in_valid_b.value = 0
    dut.drain.value = 0
    await ClockCycles(dut.clk, 2)

    for K in (1, 4, 16, 64):
        await run_tile(dut, rng, K)
        dut._log.info("tile K=%d ok (all %dx%d elements correctly rounded)",
                      K, N, N)

    # back-to-back tiles: accumulator must be clean after drain
    for rep in range(5):
        await run_tile(dut, rng, 8)
    dut._log.info("5 back-to-back K=8 tiles ok")
