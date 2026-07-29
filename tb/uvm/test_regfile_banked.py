# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x7_regfile_banked verification -- banked SRAM + operand collector.

DUT: titan_x7_regfile_banked, the replacement for the flop-array register
files (titan_x5_register_file.v, and the `rf` array inside titan_x7_sm.v).

Why this suite exists
---------------------
The flop arrays give 8 combinational reads and 3 writes per cycle, which is
buildable at 130 nm and pointless at an advanced node. This module gives one
read and one write per BANK per cycle from compiled SRAM, with the read data
a cycle late, and gathers each instruction's operands over however many
cycles that takes. The properties that matter are therefore:

  1. It stores and returns data correctly at all (round trip per bank).
  2. Operands landing in DIFFERENT banks collect in one pass.
  3. Operands landing in the SAME bank still collect -- serialised, slower,
     but correct. This is the case that costs performance, so it must be
     measured rather than assumed.
  4. The write-first bypass works: a read whose bank access lands in the
     same cycle as a write to that register returns the NEW value. The SRAM
     macro is read-before-write, so without the `wprev_*` merge in the DUT
     this read silently returns stale data.
  5. Per-lane write masks are honoured (a partial write leaves other lanes).
  6. Writeback ports back-pressure rather than dropping writes when two of
     them hit the same bank in one cycle, and no port starves.
  7. Randomised soak against a Python reference model.

Ordering discipline in the random test
--------------------------------------
The DUT's contract is that a read observes writes up to the cycle its BANK
ACCESS is issued -- and the collector issues that access whenever bank
arbitration gets to it, which is not a fixed number of cycles after
allocation. A real machine makes that non-determinism unobservable with a
scoreboard: nothing writes a register an in-flight instruction is reading
(a WAR hazard). The soak below enforces the same discipline by keeping
write targets disjoint from the registers live collector units are reading.
Property 4 tests the bypass directly instead, with exact cycle control.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly

from tb_common import start_clock_and_reset

LANES = 8
NUM_WARPS = 8
NUM_REGS = 64
NUM_BANKS = 8
NUM_CU = 4
NUM_WP = 3
DW = LANES * 32
LANE_MASK_ALL = (1 << LANES) - 1


def bank_of(reg):
    return reg & (NUM_BANKS - 1)


def lane_pattern(seed):
    """A distinct DW-bit value: one derived 32-bit word per lane.

    Per-lane rather than a constant so a bug that corrupts only some lanes
    (a bad +: slice, a mis-sized bus, a dropped mask bit) still shows up.
    """
    val = 0
    for lane in range(LANES):
        word = (0x9E3779B9 * (seed * LANES + lane + 1)) & 0xFFFFFFFF
        val |= word << (32 * lane)
    return val


def lane_of(value, lane):
    return (value >> (32 * lane)) & 0xFFFFFFFF


class WritePorts:
    """Drives the NUM_WP writeback ports and respects wr_ready."""

    def __init__(self, dut):
        self.dut = dut
        self.clear()

    def clear(self):
        self.valid = [0] * NUM_WP
        self.warp = [0] * NUM_WP
        self.reg = [0] * NUM_WP
        self.mask = [0] * NUM_WP
        self.data = [0] * NUM_WP

    def set(self, port, warp, reg, data, mask=LANE_MASK_ALL):
        self.valid[port] = 1
        self.warp[port] = warp
        self.reg[port] = reg
        self.mask[port] = mask
        self.data[port] = data

    def apply(self):
        d = self.dut
        v = w = r = m = dat = 0
        for p in range(NUM_WP):
            v |= self.valid[p] << p
            w |= self.warp[p] << (p * 3)
            r |= self.reg[p] << (p * 6)
            m |= self.mask[p] << (p * LANES)
            dat |= self.data[p] << (p * DW)
        d.wr_valid.value = v
        d.wr_warp.value = w
        d.wr_reg.value = r
        d.wr_mask.value = m
        d.wr_data.value = dat


def idle_alloc(dut):
    dut.alloc_valid.value = 0
    dut.alloc_warp.value = 0
    dut.alloc_rs1.value = 0
    dut.alloc_rs2.value = 0
    dut.alloc_rs3.value = 0
    dut.alloc_need.value = 0
    dut.alloc_id.value = 0


async def write_one(dut, wp, warp, reg, data, mask=LANE_MASK_ALL):
    """Drive a single write and hold it until the DUT accepts it."""
    while True:
        wp.clear()
        wp.set(0, warp, reg, data, mask)
        wp.apply()
        await ReadOnly()
        granted = (int(dut.wr_ready.value) >> 0) & 1
        await RisingEdge(dut.clk)
        if granted:
            break
    wp.clear()
    wp.apply()


async def collect(dut, warp, regs, need=0b111, tag=1, timeout=200):
    """Allocate one collector unit and wait for its operands.

    Returns (o1, o2, o3, cycles) where `cycles` counts from the cycle the
    allocation was accepted to the cycle the operands were handed back --
    the bank-conflict cost this module exists to make visible.
    """
    idle_alloc(dut)
    dut.alloc_valid.value = 1
    dut.alloc_warp.value = warp
    dut.alloc_rs1.value = regs[0]
    dut.alloc_rs2.value = regs[1]
    dut.alloc_rs3.value = regs[2]
    dut.alloc_need.value = need
    dut.alloc_id.value = tag
    dut.issue_ready.value = 1

    # wait for the allocation to be accepted
    while True:
        await ReadOnly()
        ready = int(dut.alloc_ready.value)
        await RisingEdge(dut.clk)
        if ready:
            break
    idle_alloc(dut)

    cycles = 0
    for _ in range(timeout):
        await ReadOnly()
        if int(dut.issue_valid.value) and int(dut.issue_id.value) == tag:
            o1 = int(dut.issue_o1.value)
            o2 = int(dut.issue_o2.value)
            o3 = int(dut.issue_o3.value)
            await RisingEdge(dut.clk)
            return o1, o2, o3, cycles
        await RisingEdge(dut.clk)
        cycles += 1
    raise AssertionError(f"operands for tag {tag} never issued ({timeout} cycles)")


@cocotb.test()
async def regfile_banked_roundtrip(dut):
    """1. Data written to every bank comes back correctly."""
    await start_clock_and_reset(dut)
    wp = WritePorts(dut)
    dut.issue_ready.value = 1
    idle_alloc(dut)

    # one register per bank, so every bank's SRAM is exercised
    for b in range(NUM_BANKS):
        reg = b            # bank == reg low bits
        await write_one(dut, wp, warp=2, reg=reg, data=lane_pattern(100 + b))

    for b in range(NUM_BANKS):
        reg = b
        o1, _, _, _ = await collect(dut, 2, (reg, 0, 0), need=0b001, tag=b + 1)
        exp = lane_pattern(100 + b)
        assert o1 == exp, (
            f"bank {b} round trip: got {o1:#x} expected {exp:#x}")

    dut._log.info(f"round trip through all {NUM_BANKS} banks ok")


@cocotb.test()
async def regfile_banked_conflict_cost(dut):
    """2+3. Distinct banks collect in one pass; same bank serialises.

    This is the property that decides whether the banked structure is
    usable. If a 3-operand instruction whose registers share a bank cost the
    same as one whose registers do not, the arbitration is not actually
    serialising and the test is not measuring what it claims.
    """
    await start_clock_and_reset(dut)
    wp = WritePorts(dut)
    dut.issue_ready.value = 1
    idle_alloc(dut)

    # spread: r1,r2,r3 -> banks 1,2,3
    spread = (1, 2, 3)
    # conflict: r0,r8,r16 -> all bank 0
    conflict = (0, 8, 16)

    for r in set(spread) | set(conflict):
        await write_one(dut, wp, warp=1, reg=r, data=lane_pattern(200 + r))

    o1, o2, o3, c_spread = await collect(dut, 1, spread, tag=10)
    for i, r in enumerate(spread):
        exp = lane_pattern(200 + r)
        got = (o1, o2, o3)[i]
        assert got == exp, f"spread operand {i} (r{r}): {got:#x} != {exp:#x}"

    o1, o2, o3, c_conflict = await collect(dut, 1, conflict, tag=11)
    for i, r in enumerate(conflict):
        exp = lane_pattern(200 + r)
        got = (o1, o2, o3)[i]
        assert got == exp, f"conflict operand {i} (r{r}): {got:#x} != {exp:#x}"

    dut._log.info(
        f"3 operands in distinct banks: {c_spread} cycles; "
        f"all 3 in one bank: {c_conflict} cycles")

    # Three requests to one bank must serialise behind each other, so the
    # conflicting case has to cost strictly more. Equal timings would mean
    # the per-bank arbiter is handing out more than one read per cycle.
    assert c_conflict > c_spread, (
        f"same-bank operands cost {c_conflict} cycles and distinct-bank cost "
        f"{c_spread}: the per-bank read arbiter is not serialising")


@cocotb.test()
async def regfile_banked_write_first_bypass(dut):
    """4. A write landing in the same cycle as the bank read is observed.

    Cycle-exact, because the bypass is invisible to random traffic that
    never happens to collide:

      cycle T   : alloc accepted -> collector state updates at edge T
      cycle T+1 : bank read issued (arbiter sees the new request);
                  drive the write HERE so both hit the same bank+row
      cycle T+2 : SRAM returns the OLD value; wprev_* must merge the new one

    Without the merge in titan_x7_regfile_banked the read returns the stale
    value, which is exactly the failure a write-first SRAM assumption hides.
    """
    await start_clock_and_reset(dut)
    wp = WritePorts(dut)
    dut.issue_ready.value = 1
    idle_alloc(dut)

    REG = 0                     # bank 0
    WARP = 5
    old = lane_pattern(300)
    new = lane_pattern(301)
    assert old != new

    await write_one(dut, wp, warp=WARP, reg=REG, data=old)

    # cycle T: allocate, requesting only rs1
    dut.alloc_valid.value = 1
    dut.alloc_warp.value = WARP
    dut.alloc_rs1.value = REG
    dut.alloc_rs2.value = 0
    dut.alloc_rs3.value = 0
    dut.alloc_need.value = 0b001
    dut.alloc_id.value = 42
    await ReadOnly()
    assert int(dut.alloc_ready.value) == 1, "collector should be free"
    await RisingEdge(dut.clk)
    idle_alloc(dut)

    # cycle T+1: the bank read is issued now -- collide the write with it
    wp.clear()
    wp.set(0, WARP, REG, new)
    wp.apply()
    await ReadOnly()
    assert int(dut.bank_re[0].value) == 1, (
        "expected the bank-0 read to be issued the cycle after allocation; "
        "the test's cycle alignment is wrong, not the DUT")
    assert (int(dut.wr_ready.value) & 1) == 1, "write port 0 should win bank 0"
    await RisingEdge(dut.clk)
    wp.clear()
    wp.apply()

    # cycle T+2 onwards: the operand must be the NEW value
    for _ in range(20):
        await ReadOnly()
        if int(dut.issue_valid.value) and int(dut.issue_id.value) == 42:
            got = int(dut.issue_o1.value)
            assert got == new, (
                f"write-first bypass failed: got {got:#x}, expected the "
                f"newly written {new:#x} (stale value is {old:#x})")
            dut._log.info("same-cycle write observed by the in-flight read")
            return
        await RisingEdge(dut.clk)
    raise AssertionError("operand never issued")


@cocotb.test()
async def regfile_banked_lane_mask(dut):
    """5. A partial write updates only the enabled lanes."""
    await start_clock_and_reset(dut)
    wp = WritePorts(dut)
    dut.issue_ready.value = 1
    idle_alloc(dut)

    REG, WARP = 3, 4
    base = lane_pattern(400)
    over = lane_pattern(401)
    mask = 0b01010101 & LANE_MASK_ALL

    await write_one(dut, wp, WARP, REG, base)
    await write_one(dut, wp, WARP, REG, over, mask=mask)

    o1, _, _, _ = await collect(dut, WARP, (REG, 0, 0), need=0b001, tag=7)
    for lane in range(LANES):
        want = lane_of(over if (mask >> lane) & 1 else base, lane)
        got = lane_of(o1, lane)
        assert got == want, (
            f"lane {lane}: got {got:#010x} expected {want:#010x} "
            f"(mask bit {(mask >> lane) & 1})")
    dut._log.info(f"per-lane write mask {mask:#04x} honoured on all {LANES} lanes")


@cocotb.test()
async def regfile_banked_write_port_arbitration(dut):
    """6. Same-bank writes back-pressure instead of being dropped.

    Three ports aim at the same bank. Only one may be granted per cycle, and
    every one of them must eventually land -- a dropped write would show up
    as a stale operand.
    """
    await start_clock_and_reset(dut)
    wp = WritePorts(dut)
    dut.issue_ready.value = 1
    idle_alloc(dut)

    # r0, r8, r16 all live in bank 0
    targets = [(1, 0), (2, 8), (3, 16)]
    values = {reg: lane_pattern(500 + reg) for _, reg in targets}

    pending = list(range(NUM_WP))
    grants_seen = []
    for _ in range(40):
        wp.clear()
        for p in pending:
            warp, reg = targets[p]
            wp.set(p, warp, reg, values[reg])
        wp.apply()
        await ReadOnly()
        ready = int(dut.wr_ready.value)
        granted = [p for p in pending if (ready >> p) & 1]
        assert len(granted) <= 1, (
            f"{len(granted)} ports granted the same bank in one cycle")
        await RisingEdge(dut.clk)
        for p in granted:
            grants_seen.append(p)
            pending.remove(p)
        if not pending:
            break
    wp.clear()
    wp.apply()
    assert not pending, f"ports {pending} never got their write accepted"
    assert sorted(grants_seen) == list(range(NUM_WP))
    dut._log.info(f"3 same-bank writes serialised, grant order {grants_seen}")

    for i, (warp, reg) in enumerate(targets):
        o1, _, _, _ = await collect(dut, warp, (reg, 0, 0), need=0b001, tag=20 + i)
        assert o1 == values[reg], (
            f"warp {warp} r{reg}: {o1:#x} != {values[reg]:#x} (write dropped)")


@cocotb.test()
async def regfile_banked_random_soak(dut):
    """7. Randomised traffic against a Python reference model.

    Write targets are kept disjoint from registers being read, per the WAR
    discipline described in the module docstring.
    """
    await start_clock_and_reset(dut)
    random.seed(0xB0FFED)
    wp = WritePorts(dut)
    dut.issue_ready.value = 1
    idle_alloc(dut)

    ref = {}
    seed = 0
    conflict_cases = 0

    for it in range(60):
        warp = random.randrange(NUM_WARPS)

        # 1-3 fresh writes, then read them back
        regs = random.sample(range(1, NUM_REGS), 3)
        for r in regs:
            seed += 1
            val = lane_pattern(seed)
            await write_one(dut, wp, warp, r, val)
            ref[(warp, r)] = val

        # deliberately bias towards same-bank operand sets
        if it % 3 == 0:
            b = random.randrange(NUM_BANKS)
            same = [r for r in range(1, NUM_REGS) if bank_of(r) == b][:3]
            if len(same) == 3:
                for r in same:
                    if (warp, r) not in ref:
                        seed += 1
                        await write_one(dut, wp, warp, r, lane_pattern(seed))
                        ref[(warp, r)] = lane_pattern(seed)
                regs = same
                conflict_cases += 1

        o1, o2, o3, _ = await collect(dut, warp, tuple(regs), tag=(it % 250) + 1)
        for i, r in enumerate(regs):
            exp = ref[(warp, r)]
            got = (o1, o2, o3)[i]
            assert got == exp, (
                f"iter {it} warp {warp} r{r} (bank {bank_of(r)}): "
                f"{got:#x} != {exp:#x}")

    dut._log.info(
        f"soak: 60 instructions, {len(ref)} live registers, "
        f"{conflict_cases} forced same-bank operand sets, all correct")
