# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_apex_dp_mac -- dynamic-precision multiply-accumulate.

The MAC that turns the segmented multiplier into throughput: 1 / 4 / 16 MACs
per cycle at 24 / 12 / 6-bit operand slices. Accumulation is exact integer,
so the reference model is plain Python arithmetic with no tolerance.

Properties under test:
  1. Single-shot product in every mode, signed and unsigned.
  2. Accumulation over a long chain is exact (no truncation or saturation).
  3. acc_clear starts a fresh tile on the same cycle it accepts a product.
  4. The three extremes -- all zeros, all ones, and max positive / max
     negative -- in each mode and both signednesses.

Signed operands are the interesting case: the multiplier array is unsigned
and the RTL corrects afterwards so ONE array serves both. A sign-correction
bug shows up only on negative operands, so those are driven deliberately
rather than left to chance.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly

from tb_common import start_clock_and_reset

TILE = 6
NT = 4
W = TILE * NT                 # 24
ACC_W = 2 * W + 16            # 64
ACC_MASK = (1 << ACC_W) - 1

MODE_FULL, MODE_HALF, MODE_TILE = 0, 1, 2


def to_signed(v, bits):
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def slices(v, width, n):
    return [(v >> (i * width)) & ((1 << width) - 1) for i in range(n)]


def expected_products(a, b, mode, signed):
    """Reference: the list of products the DUT should sum this cycle."""
    if mode == MODE_FULL:
        av = to_signed(a, W) if signed else a
        bv = to_signed(b, W) if signed else b
        return [av * bv]
    if mode == MODE_HALF:
        p = 2 * TILE
        A = slices(a, p, 2)
        B = slices(b, p, 2)
        if signed:
            A = [to_signed(x, p) for x in A]
            B = [to_signed(x, p) for x in B]
        # quadrant (i,j) pairs a-half i with b-half j -- outer product
        return [A[i] * B[j] for i in range(2) for j in range(2)]
    A = slices(a, TILE, NT)
    B = slices(b, TILE, NT)
    if signed:
        A = [to_signed(x, TILE) for x in A]
        B = [to_signed(x, TILE) for x in B]
    return [A[i] * B[j] for i in range(NT) for j in range(NT)]


async def mac(dut, a, b, mode, signed, clear=0):
    dut.a.value = a
    dut.b.value = b
    dut.mode.value = mode
    dut.is_signed.value = 1 if signed else 0
    dut.acc_clear.value = clear
    dut.mac_valid.value = 1
    await RisingEdge(dut.clk)
    dut.mac_valid.value = 0
    dut.acc_clear.value = 0


async def read_acc(dut):
    await ReadOnly()
    v = int(dut.acc.value) & ACC_MASK
    await RisingEdge(dut.clk)
    return to_signed(v, ACC_W)


async def idle(dut):
    dut.mac_valid.value = 0
    dut.acc_clear.value = 0
    dut.a.value = 0
    dut.b.value = 0
    dut.mode.value = 0
    dut.is_signed.value = 0
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def dp_mac_single_products(dut):
    """1+4. One product per mode, on the extremes and directed values."""
    await start_clock_and_reset(dut)
    await idle(dut)

    ALL1 = (1 << W) - 1
    cases = [0, 1, ALL1, ALL1 - 1, 1 << (W - 1), (1 << (W - 1)) - 1,
             0x555555, 0xAAAAAA, 0x7FFFFF, 0x800000]
    n = 0
    for mode in (MODE_FULL, MODE_HALF, MODE_TILE):
        for signed in (False, True):
            for a in cases:
                for b in cases:
                    await mac(dut, a, b, mode, signed, clear=1)
                    got = await read_acc(dut)
                    exp = sum(expected_products(a, b, mode, signed))
                    assert got == exp, (
                        f"mode={mode} signed={signed} a={a:#08x} b={b:#08x}: "
                        f"got {got}, expected {exp}")
                    n += 1
    dut._log.info(f"single products: {n} cases across 3 modes x signed/unsigned, "
                  f"all exact")


@cocotb.test()
async def dp_mac_accumulates_exactly(dut):
    """2. A long chain accumulates with no truncation or saturation."""
    rng = random.Random(0xACC)
    await start_clock_and_reset(dut)
    await idle(dut)

    for mode, signed, depth in ((MODE_FULL, True, 64),
                                (MODE_HALF, True, 128),
                                (MODE_TILE, True, 256),
                                (MODE_TILE, False, 256)):
        ref = 0
        first = True
        for _ in range(depth):
            a = rng.getrandbits(W)
            b = rng.getrandbits(W)
            ref += sum(expected_products(a, b, mode, signed))
            await mac(dut, a, b, mode, signed, clear=1 if first else 0)
            first = False
        got = await read_acc(dut)
        assert got == ref, (
            f"mode={mode} signed={signed} depth={depth}: accumulator holds "
            f"{got}, expected {ref} (difference {got-ref})")
        dut._log.info(f"mode={mode} signed={signed}: {depth} MACs exact "
                      f"(total {ref})")


@cocotb.test()
async def dp_mac_clear_starts_fresh_tile(dut):
    """3. acc_clear must drop the old tile and keep the incoming product.

    A clear that also discarded the incoming product would lose the first
    term of every tile -- an error of exactly one MAC, which a
    sum-at-the-end check would otherwise absorb into the noise.
    """
    await start_clock_and_reset(dut)
    await idle(dut)

    # build a tile
    for _ in range(8):
        await mac(dut, 0x111111, 0x222222, MODE_TILE, False, clear=0)
    stale = await read_acc(dut)
    assert stale != 0, "setup produced nothing to clear"

    a, b = 0x0F0F0F, 0x00FF00
    await mac(dut, a, b, MODE_TILE, False, clear=1)
    got = await read_acc(dut)
    exp = sum(expected_products(a, b, MODE_TILE, False))
    assert got == exp, (
        f"after acc_clear the accumulator holds {got}, expected {exp} "
        f"(the single cleared-cycle product); stale tile was {stale}")
    dut._log.info("acc_clear drops the old tile and keeps the incoming product")


@cocotb.test()
async def dp_mac_random_soak(dut):
    """Randomised sweep, all modes, both signednesses, random tile lengths."""
    rng = random.Random(0x50AC)
    await start_clock_and_reset(dut)
    await idle(dut)

    for it in range(200):
        mode = rng.choice((MODE_FULL, MODE_HALF, MODE_TILE))
        signed = rng.random() < 0.5
        depth = rng.randint(1, 12)
        ref = 0
        for k in range(depth):
            a = rng.getrandbits(W)
            b = rng.getrandbits(W)
            ref += sum(expected_products(a, b, mode, signed))
            await mac(dut, a, b, mode, signed, clear=1 if k == 0 else 0)
        got = await read_acc(dut)
        assert got == ref, (
            f"iter {it} mode={mode} signed={signed} depth={depth}: "
            f"got {got}, expected {ref}")
    dut._log.info("random soak: 200 tiles, all modes, exact")
