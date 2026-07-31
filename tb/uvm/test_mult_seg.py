# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_apex_mult_seg -- the precision-scalable multiplier core.

DUT: the 4x4 grid of 6x6 tiles that lets one FP32-width mantissa multiplier
serve as 1x 24x24, 4x 12x12, or 16x 6x6 products.

Why this module exists (the arithmetic is in the RTL header): at 40,000 lanes
and 2.49 GHz the existing FP16 tensor PE reaches 398 TOPS FP8 / 797 TOPS FP4,
against an RTX 5090's 838 / 1676 dense -- a 2x loss. Segmenting an FP32-width
multiplier is where the extra MACs come from.

Verification approach
---------------------
A SAT equivalence proof was attempted first (syn/gt2n/prove_mult_seg.v) and
is NOT tractable: multiplier miters are a known hard case and Yosys' solver
did not finish in 10 minutes on the 24x24 mode. So this suite uses
simulation, with the coverage chosen per mode by what is affordable:

  MODE_TILE : EXHAUSTIVE. 6x6 is 4,096 operand pairs, and all 16 tiles are
              checked on every pair, so every tile sees every input.
  MODE_HALF : exhaustive on the corners of each 12-bit half plus heavy
              random, since 12x12 exhaustive is 16.7 M pairs per quadrant.
  MODE_FULL : directed corners (0, 1, all-ones, powers of two, and the
              carry-heavy patterns that break a mis-weighted tree) plus
              random.

The tiles are always evaluated and only the summation network is switched,
so a defect in the tile array shows up in all three modes; the mode-specific
risk is entirely in the shift/sum wiring, which is what the directed vectors
target.
"""

import random

import cocotb
from cocotb.triggers import Timer

TILE = 6
NT = 4
W = TILE * NT                 # 24
MASK_T = (1 << TILE) - 1
MASK_H = (1 << (2 * TILE)) - 1
MASK_W = (1 << W) - 1


async def apply(dut, a, b):
    dut.a.value = a
    dut.b.value = b
    dut.mode.value = 0
    await Timer(1, "ns")


def slice_of(v, i, width):
    return (v >> (i * width)) & ((1 << width) - 1)


async def check_all(dut, a, b, where):
    """Check all three modes for one operand pair."""
    await apply(dut, a, b)

    got = int(dut.full.value)
    exp = (a * b) & ((1 << (2 * W)) - 1)
    assert got == exp, (
        f"{where}: FULL a={a:#08x} b={b:#08x} -> {got:#012x}, expected "
        f"{exp:#012x}")

    half = int(dut.half.value)
    for i in range(2):
        for j in range(2):
            ah = slice_of(a, i, 2 * TILE)
            bh = slice_of(b, j, 2 * TILE)
            g = (half >> ((i * 2 + j) * 4 * TILE)) & ((1 << (4 * TILE)) - 1)
            assert g == ah * bh, (
                f"{where}: HALF quadrant ({i},{j}) a={ah:#x} b={bh:#x} -> "
                f"{g:#x}, expected {ah*bh:#x}")

    tile = int(dut.tile.value)
    for i in range(NT):
        for j in range(NT):
            at = slice_of(a, i, TILE)
            bt = slice_of(b, j, TILE)
            g = (tile >> ((i * NT + j) * 2 * TILE)) & MASK_H
            assert g == at * bt, (
                f"{where}: TILE ({i},{j}) a={at:#x} b={bt:#x} -> {g:#x}, "
                f"expected {at*bt:#x}")


@cocotb.test()
async def mult_seg_tiles_exhaustive(dut):
    """MODE_TILE exhaustively: every 6x6 operand pair, on all 16 tiles.

    Replicating the same 6-bit value into all four slices means each of the
    4,096 pairs is applied to every tile simultaneously, so this is genuinely
    exhaustive per tile rather than only exercising tile (0,0).
    """
    n = 0
    for av in range(1 << TILE):
        a = sum(av << (k * TILE) for k in range(NT))
        for bv in range(1 << TILE):
            b = sum(bv << (k * TILE) for k in range(NT))
            await apply(dut, a, b)
            tile = int(dut.tile.value)
            for i in range(NT):
                for j in range(NT):
                    g = (tile >> ((i * NT + j) * 2 * TILE)) & MASK_H
                    assert g == av * bv, (
                        f"tile ({i},{j}) {av}*{bv} -> {g}, expected {av*bv}")
            n += 1
    dut._log.info(f"MODE_TILE exhaustive: {n} operand pairs x 16 tiles, "
                  f"all exact")


@cocotb.test()
async def mult_seg_directed_corners(dut):
    """Corner patterns that break a mis-weighted or truncated adder tree."""
    corners = [0, 1, 2, MASK_W, MASK_W - 1,
               1 << (W - 1), (1 << (W - 1)) - 1,
               0x555555, 0xAAAAAA, 0xFFF000, 0x000FFF, 0xFFFFFF, 0x800001]
    # every slice-boundary power of two, where a wrong shift shows up
    corners += [1 << k for k in range(W)]
    n = 0
    for a in corners:
        for b in corners:
            await check_all(dut, a, b, "corner")
            n += 1
    dut._log.info(f"directed corners: {n} pairs, all three modes exact")


@cocotb.test()
async def mult_seg_random(dut):
    """Randomised sweep across all three modes."""
    rng = random.Random(0xA9EC)
    N = 3000
    for k in range(N):
        a = rng.getrandbits(W)
        b = rng.getrandbits(W)
        await check_all(dut, a, b, f"rand{k}")
    dut._log.info(f"random: {N} pairs, FULL/HALF/TILE all exact")


@cocotb.test()
async def mult_seg_half_is_outer_product(dut):
    """MODE_HALF must give the OUTER product of the two a- and b-halves.

    This is the property the tensor tile depends on: quadrant (I,J) pairs
    a-half I with b-half J, so two A operands against two B operands yield
    four independent products. If the quadrant wiring were transposed or a
    quadrant duplicated, the totals would still look plausible in a random
    sweep -- so the halves are made deliberately distinct here.
    """
    rng = random.Random(0x5EED)
    for _ in range(400):
        a0, a1 = rng.getrandbits(2 * TILE), rng.getrandbits(2 * TILE)
        b0, b1 = rng.getrandbits(2 * TILE), rng.getrandbits(2 * TILE)
        if len({a0, a1}) < 2 or len({b0, b1}) < 2:
            continue
        a = a0 | (a1 << (2 * TILE))
        b = b0 | (b1 << (2 * TILE))
        await apply(dut, a, b)
        half = int(dut.half.value)
        want = {(0, 0): a0 * b0, (0, 1): a0 * b1,
                (1, 0): a1 * b0, (1, 1): a1 * b1}
        for (i, j), exp in want.items():
            g = (half >> ((i * 2 + j) * 4 * TILE)) & ((1 << (4 * TILE)) - 1)
            assert g == exp, (
                f"outer product ({i},{j}): a{i}={a0 if i==0 else a1:#x} "
                f"b{j}={b0 if j==0 else b1:#x} -> {g:#x}, expected {exp:#x}")
    dut._log.info("MODE_HALF is the true 2x2 outer product of the operand "
                  "halves")
