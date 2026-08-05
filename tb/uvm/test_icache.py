# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_icache: does it actually cache, and does it return the right word?

The full-chip tests would catch an I-cache that returns garbage -- the render
test's checker and all fifteen compute kernels depend on fetching the right
instructions. What they could NOT catch is an I-cache that is CORRECT but
useless: one that misses on every access and simply forwards each fetch to the
crossbar. That would pass every existing test while delivering none of the
speedup the block exists for, and the only visible symptom would be a cycle
count nobody was comparing against anything.

So these tests assert on the memory traffic, not just the data:
`test_line_is_reused` requires that reading all 16 words of a line costs
exactly ONE line fill, and `test_counters` pins the hit/miss ratio.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

LINE_BYTES = 64
WORDS = LINE_BYTES // 4
SETS = 64


def mem_word(addr):
    """The backing store returns a function of the address, so a word that
    came from the wrong place is obvious rather than plausible."""
    return (addr * 2654435761) & 0xFFFFFFFF


class Mem:
    """Word-read memory model with a 3-cycle latency, counting fills."""

    def __init__(self, dut, latency=3):
        self.dut = dut
        self.latency = latency
        self.reads = 0
        self.addrs = []

    async def run(self):
        dut = self.dut
        dut.mem_gnt.value = 0
        dut.mem_rvalid.value = 0
        dut.mem_rdata.value = 0
        pending = []
        while True:
            await FallingEdge(dut.clk)
            dut.mem_rvalid.value = 0
            dut.mem_gnt.value = 0
            for e in pending:
                e[0] -= 1
            if pending and pending[0][0] <= 0:
                _, a = pending.pop(0)
                dut.mem_rvalid.value = 1
                dut.mem_rdata.value = mem_word(a)
            # `mem_req` is X until reset has been through the DUT's async
            # reset. int() on an X raises, and an exception in a coroutine
            # started with start_soon kills it SILENTLY -- the memory then
            # never answers again and every test fails with "never returned
            # rvalid", which reads exactly like a DUT hang. It is not; the
            # model died. Skip unresolvable cycles instead.
            if not dut.mem_req.value.is_resolvable:
                continue
            if int(dut.mem_req.value):
                a = int(dut.mem_addr.value)
                dut.mem_gnt.value = 1
                pending.append([self.latency, a])
                self.reads += 1
                self.addrs.append(a)


async def boot(dut):
    cocotb.start_soon(Clock(dut.clk, 10, "ns").start())
    dut.rst_n.value = 0
    dut.core_req.value = 0
    dut.core_addr.value = 0
    mem = Mem(dut)
    cocotb.start_soon(mem.run())
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    return mem


async def fetch(dut, addr, timeout=800):
    """Drive one fetch through the core port and return the word."""
    dut.core_addr.value = addr
    dut.core_req.value = 1
    for _ in range(timeout):
        await RisingEdge(dut.clk)
        if int(dut.core_gnt.value):
            break
    else:
        raise AssertionError(f"fetch of {addr:#x} was never granted")
    dut.core_req.value = 0
    for _ in range(timeout):
        await RisingEdge(dut.clk)
        if int(dut.core_rvalid.value):
            return int(dut.core_rdata.value)
    raise AssertionError(f"fetch of {addr:#x} never returned rvalid")


@cocotb.test()
async def test_cold_miss_returns_the_right_word(dut):
    """A miss fills the line and answers with the requested word."""
    mem = await boot(dut)
    addr = 0x0020_0000 + 3 * 4          # word 3 of a line
    got = await fetch(dut, addr)
    assert got == mem_word(addr), \
        f"{addr:#x} returned {got:#010x}, expected {mem_word(addr):#010x}"
    assert mem.reads == WORDS, \
        f"a cold miss should fetch exactly one {WORDS}-word line, saw {mem.reads}"
    dut._log.info(f"cold miss: one {WORDS}-word line fill, correct word")


@cocotb.test()
async def test_line_is_reused(dut):
    """THE POINT OF THE BLOCK: 16 words in a line cost ONE fill.

    Without this assertion an I-cache that forwards every fetch to memory
    would pass every other test in the project while providing no benefit.
    """
    mem = await boot(dut)
    base = 0x0020_1000
    for w in range(WORDS):
        a = base + w * 4
        got = await fetch(dut, a)
        assert got == mem_word(a), \
            f"word {w} of the line returned {got:#010x}, expected {mem_word(a):#010x}"
    assert mem.reads == WORDS, (
        f"reading all {WORDS} words of one line issued {mem.reads} memory "
        f"reads; it must issue exactly {WORDS} (one fill) -- the cache is "
        f"not retaining the line")
    dut._log.info(
        f"{WORDS} sequential fetches cost {mem.reads} memory reads (one fill)")


@cocotb.test()
async def test_two_lines_do_not_alias(dut):
    """Different tags in the same set must not return each other's data."""
    mem = await boot(dut)
    set_stride = SETS * LINE_BYTES          # same set, different tag
    a = 0x0020_0000
    b = a + set_stride
    va = await fetch(dut, a)
    vb = await fetch(dut, b)
    va2 = await fetch(dut, a)
    for addr, got in ((a, va), (b, vb), (a, va2)):
        assert got == mem_word(addr), (
            f"{addr:#x} returned {got:#010x}, expected {mem_word(addr):#010x} "
            f"-- a conflicting line was served from the wrong tag")
    assert mem.reads == 3 * WORDS, \
        f"three conflicting accesses should refill three times, saw {mem.reads}"
    dut._log.info("conflicting tags in one set refill correctly, no aliasing")


@cocotb.test()
async def test_counters(dut):
    """dbg_hits / dbg_misses match the traffic actually issued."""
    mem = await boot(dut)
    base = 0x0020_2000
    for w in range(WORDS):
        await fetch(dut, base + w * 4)
    await ClockCycles(dut.clk, 2)
    hits = int(dut.dbg_hits.value)
    misses = int(dut.dbg_misses.value)
    assert misses == 1, f"expected exactly 1 miss for one line, got {misses}"
    assert hits == WORDS - 1, \
        f"expected {WORDS - 1} hits after the fill, got {hits}"
    dut._log.info(f"counters: {hits} hits, {misses} miss over one line")


@cocotb.test()
async def test_sequential_across_line_boundaries(dut):
    """Walk straight through several lines, the way a real program is fetched.

    The earlier tests each stayed INSIDE one line, or jumped between lines
    that conflicted in the same set. Neither exercises the ordinary case: a
    program counter walking sequentially from one line into the next. That is
    what every kernel longer than LINE_BYTES actually does, and it is how the
    full-chip render test (an 8-instruction program, one line) can pass while
    every multi-line compute kernel returns the wrong answer.
    """
    mem = await boot(dut)
    base = 0x0020_0000
    nlines = 4
    for w in range(nlines * WORDS):
        a = base + w * 4
        got = await fetch(dut, a)
        assert got == mem_word(a), (
            f"word {w} (addr {a:#x}, line {w // WORDS}, "
            f"offset {w % WORDS}) returned {got:#010x}, "
            f"expected {mem_word(a):#010x}")
    assert mem.reads == nlines * WORDS, (
        f"{nlines} lines should cost {nlines} fills "
        f"({nlines * WORDS} reads), saw {mem.reads}")
    dut._log.info(
        f"walked {nlines * WORDS} words across {nlines} lines, "
        f"{mem.reads} memory reads")


@cocotb.test()
async def test_loop_refetch(dut):
    """A backward branch re-fetching addresses it has already fetched.

    Every earlier test walks FORWARD. A loop does not: it returns to an
    address already in the cache, so those fetches are hits answered a single
    cycle after grant, which is a far tighter timing than the multi-cycle
    crossbar round trip the SM was built against. The full-chip render test
    cannot cover this -- its only branch is forward, and it fetches every
    address exactly once.
    """
    mem = await boot(dut)
    base = 0x0020_0000
    body = [base + i * 4 for i in range(5)]     # 5-instruction loop body
    for _ in range(4):                          # four trips
        for a in body:
            got = await fetch(dut, a)
            assert got == mem_word(a), (
                f"loop re-fetch of {a:#x} returned {got:#010x}, "
                f"expected {mem_word(a):#010x}")
    assert mem.reads == WORDS, (
        f"a 5-instruction loop lives in one line: expected {WORDS} reads "
        f"(one fill) across four trips, saw {mem.reads}")
    dut._log.info(f"4 trips x 5 instructions served from one fill")
