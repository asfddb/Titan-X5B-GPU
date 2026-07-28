# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_register_file verification -- the per-warp dimension.

DUT: titan_x5_register_file, built with the exact geometry the SM uses
(DATA_WIDTH=1024 i.e. 32 lanes x 32 bits, NUM_REGS=64, NUM_BANKS=4,
NUM_WARPS=8).

Why this suite exists
---------------------
The register file had no warp dimension: NUM_REGS entries shared by every
warp. Warp 3 writing r6 clobbered warp 5's r6. Nothing tested the file
directly, and the full-chip render test could not see it because
LAUNCH_WARP_MASK was pinned to a single warp precisely *because* of this
bug -- the workaround hid the defect it was working around.

So the property under test is the one that was missing: two warps holding
different values in the same architectural register number, at the same
time.

Addressing
----------
The file is addressed the way titan_x5_sm drives it. Register r maps to

    bank  = r[1:0]          (low-order interleave across 4 banks)
    entry = r[5:2]          (16 entries per bank)

and the warp index selects a contiguous REGS_PER_BANK-sized window inside
each bank, warp-major:

    bank_mem[warp * 16 + entry]

The SM broadcasts one entry index to all four banks and selects the answer
from the addressed bank, so the helpers below do the same. Driving the file
any other way would test an interface the SM does not use.

Checks:
  1. Two warps hold different values in the same register number.
  2. All 8 warps hold independent values in one register number.
  3. Writing one warp's register leaves every other warp's copy of that
     register untouched (no aliasing in either direction).
  4. Independence holds across the whole register file, not just one
     register: every (warp, reg) pair gets a distinct value.
  5. The three read ports can read three different warps in the same cycle.
  6. Reset clears every warp's registers, not just warp 0's.
  7. Randomised soak against a Python reference model.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles

from tb_common import start_clock_and_reset

DATA_WIDTH = 1024
NUM_REGS = 64
NUM_BANKS = 4
NUM_WARPS = 8
REGS_PER_BANK = NUM_REGS // NUM_BANKS  # 16
DATA_MASK = (1 << DATA_WIDTH) - 1


def bank_of(reg):
    return reg & (NUM_BANKS - 1)


def entry_of(reg):
    return reg >> 2


def lane_pattern(seed):
    """A distinct 1024-bit value: 32 lanes of 32 bits derived from `seed`.

    Using a per-lane pattern rather than a constant means a bug that
    corrupts only some lanes (a bad +: slice, a mis-sized bus) still shows
    up, instead of every lane happening to carry the same byte.
    """
    val = 0
    for lane in range(32):
        word = (0x9E3779B9 * (seed * 32 + lane + 1)) & 0xFFFFFFFF
        val |= word << (32 * lane)
    return val


def replicate(value, width):
    """Replicate a `width`-bit value across all NUM_BANKS bank slices.

    The SM broadcasts one entry index and one data word to every bank and
    lets wr_en / the output mux pick the bank, so the testbench does too.
    """
    out = 0
    for b in range(NUM_BANKS):
        out |= (value & ((1 << width) - 1)) << (b * width)
    return out


async def write_reg(dut, warp, reg, value):
    """One synchronous write, mirroring titan_x5_sm's bank decode."""
    dut.wr_en.value = 1 << bank_of(reg)
    dut.wr_addr.value = replicate(entry_of(reg), 4)
    dut.wr_warp.value = warp
    dut.wr_data.value = replicate(value, DATA_WIDTH)
    await RisingEdge(dut.clk)
    dut.wr_en.value = 0


def read_port_setup(dut, port, warp, reg):
    getattr(dut, f"rd_en_{port}").value = (1 << NUM_BANKS) - 1
    getattr(dut, f"rd_addr_{port}").value = replicate(entry_of(reg), 4)
    getattr(dut, f"rd_warp_{port}").value = warp


def read_port_result(dut, port, reg):
    flat = int(getattr(dut, f"rd_data_{port}").value)
    return (flat >> (bank_of(reg) * DATA_WIDTH)) & DATA_MASK


async def read_reg(dut, warp, reg, port=0):
    """Combinational read: drive the port, settle, sample the addressed bank."""
    read_port_setup(dut, port, warp, reg)
    await ClockCycles(dut.clk, 1)
    return read_port_result(dut, port, reg)


async def init(dut):
    for p in range(3):
        getattr(dut, f"rd_en_{p}").value = 0
        getattr(dut, f"rd_addr_{p}").value = 0
        getattr(dut, f"rd_warp_{p}").value = 0
    dut.wr_en.value = 0
    dut.wr_addr.value = 0
    dut.wr_warp.value = 0
    dut.wr_data.value = 0
    await start_clock_and_reset(dut)


@cocotb.test()
async def test_two_warps_same_register(dut):
    """Two warps must hold different values in the SAME register number.

    This is the headline property. With the pre-fix shared file the second
    write lands on the same storage as the first, so warp 3 reads back
    warp 5's value and this test fails.
    """
    await init(dut)

    reg = 6  # r6: the scratch register the render kernel accumulates into
    val_a = lane_pattern(0xA)
    val_b = lane_pattern(0xB)
    assert val_a != val_b

    await write_reg(dut, 3, reg, val_a)
    await write_reg(dut, 5, reg, val_b)

    got_a = await read_reg(dut, 3, reg)
    got_b = await read_reg(dut, 5, reg)

    assert got_a == val_a, (
        f"warp 3 r{reg}: expected {val_a:#0258x}, got {got_a:#0258x} -- "
        "warp 5's write aliased onto warp 3's register")
    assert got_b == val_b, (
        f"warp 5 r{reg}: expected {val_b:#0258x}, got {got_b:#0258x}")
    dut._log.info(
        "warp 3 and warp 5 hold different values in r%d simultaneously", reg)


@cocotb.test()
async def test_all_warps_independent(dut):
    """All 8 warps hold independent values in one register number."""
    await init(dut)

    reg = 6
    expect = {w: lane_pattern(0x100 + w) for w in range(NUM_WARPS)}
    for w in range(NUM_WARPS):
        await write_reg(dut, w, reg, expect[w])

    for w in range(NUM_WARPS):
        got = await read_reg(dut, w, reg)
        assert got == expect[w], (
            f"warp {w} r{reg}: expected {expect[w]:#0258x}, got {got:#0258x}")
    dut._log.info("all %d warps hold independent values in r%d",
                  NUM_WARPS, reg)


@cocotb.test()
async def test_write_does_not_disturb_other_warps(dut):
    """A write to one warp must leave every other warp's copy untouched."""
    await init(dut)

    reg = 9
    baseline = {w: lane_pattern(0x200 + w) for w in range(NUM_WARPS)}
    for w in range(NUM_WARPS):
        await write_reg(dut, w, reg, baseline[w])

    victim = lane_pattern(0xDEAD)
    await write_reg(dut, 4, reg, victim)

    for w in range(NUM_WARPS):
        got = await read_reg(dut, w, reg)
        want = victim if w == 4 else baseline[w]
        assert got == want, (
            f"after writing warp 4 r{reg}, warp {w} r{reg} was disturbed: "
            f"expected {want:#0258x}, got {got:#0258x}")
    dut._log.info("writing warp 4 r%d disturbed no other warp", reg)


@cocotb.test()
async def test_every_warp_register_pair_distinct(dut):
    """Independence across the whole file: every (warp, reg) is distinct.

    Catches an index that *aliases* two distinct (warp, reg) pairs onto one
    slot -- for example `warp + entry` instead of `warp * REGS_PER_BANK +
    entry`, which collides for many pairs but happens to be correct for
    warp 0 and so survives a single-warp test.

    Note this does not pin the layout: an entry-major mapping
    (`entry * NUM_WARPS + warp`) is still a bijection and passes here, as it
    should -- it is an equally valid implementation. What fixes warp-major
    is the backdoor deposit in tb/tb_titan_x5_gpu_top.v, which indexes
    bank_mem directly and is documented as depending on it.
    """
    await init(dut)

    expect = {}
    for w in range(NUM_WARPS):
        for r in range(NUM_REGS):
            v = lane_pattern(w * NUM_REGS + r + 0x1000)
            expect[(w, r)] = v
            await write_reg(dut, w, r, v)

    for w in range(NUM_WARPS):
        for r in range(NUM_REGS):
            got = await read_reg(dut, w, r)
            assert got == expect[(w, r)], (
                f"warp {w} r{r}: expected {expect[(w, r)]:#0258x}, "
                f"got {got:#0258x}")
    dut._log.info("all %d warp/register pairs hold distinct values",
                  NUM_WARPS * NUM_REGS)


@cocotb.test()
async def test_three_ports_three_warps(dut):
    """The three read ports are independently warp-indexed.

    The SM drives all three from the ID-stage warp, but the ports are
    separate signals; wiring two of them to the same warp index by mistake
    would be invisible in the SM and caught here.
    """
    await init(dut)

    reg = 12
    vals = {w: lane_pattern(0x300 + w) for w in range(NUM_WARPS)}
    for w in range(NUM_WARPS):
        await write_reg(dut, w, reg, vals[w])

    read_port_setup(dut, 0, 1, reg)
    read_port_setup(dut, 1, 2, reg)
    read_port_setup(dut, 2, 7, reg)
    await ClockCycles(dut.clk, 1)

    got0 = read_port_result(dut, 0, reg)
    got1 = read_port_result(dut, 1, reg)
    got2 = read_port_result(dut, 2, reg)

    assert got0 == vals[1], f"port 0 (warp 1) got {got0:#0258x}"
    assert got1 == vals[2], f"port 1 (warp 2) got {got1:#0258x}"
    assert got2 == vals[7], f"port 2 (warp 7) got {got2:#0258x}"
    dut._log.info("three read ports served warps 1, 2 and 7 in one cycle")


@cocotb.test()
async def test_reset_clears_every_warp(dut):
    """Reset must clear all NUM_WARPS register sets, not just warp 0's."""
    await init(dut)

    reg = 21
    for w in range(NUM_WARPS):
        await write_reg(dut, w, reg, lane_pattern(0x400 + w))

    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    for w in range(NUM_WARPS):
        got = await read_reg(dut, w, reg)
        assert got == 0, (
            f"warp {w} r{reg} survived reset: {got:#0258x} -- the reset loop "
            "does not cover every warp's entries")
    dut._log.info("reset cleared r%d in all %d warps", reg, NUM_WARPS)


@cocotb.test()
async def test_random_soak(dut):
    """Randomised writes across warps/registers against a reference model."""
    await init(dut)

    random.seed(0xB1A5)
    model = {(w, r): 0 for w in range(NUM_WARPS) for r in range(NUM_REGS)}

    for i in range(600):
        w = random.randrange(NUM_WARPS)
        r = random.randrange(NUM_REGS)
        v = lane_pattern(random.randrange(1 << 20))
        await write_reg(dut, w, r, v)
        model[(w, r)] = v

        # Spot-check a random location every iteration, so a corruption is
        # caught near the write that caused it rather than 600 writes later.
        cw = random.randrange(NUM_WARPS)
        cr = random.randrange(NUM_REGS)
        got = await read_reg(dut, cw, cr)
        assert got == model[(cw, cr)], (
            f"iteration {i}: warp {cw} r{cr} expected "
            f"{model[(cw, cr)]:#0258x}, got {got:#0258x}")

    # Final full sweep.
    for w in range(NUM_WARPS):
        for r in range(NUM_REGS):
            got = await read_reg(dut, w, r)
            assert got == model[(w, r)], (
                f"final sweep: warp {w} r{r} expected "
                f"{model[(w, r)]:#0258x}, got {got:#0258x}")
    dut._log.info("600-write random soak matched the reference model")
