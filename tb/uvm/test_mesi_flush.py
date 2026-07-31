# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""L1 cache flush / writeback-all.

The hole this closes was documented in README.md for a long time: L1 and L2
are both write-back with no flush or writeback-all port, so a kernel's stores
can sit in a Modified line indefinitely and nothing makes them reach memory.
Measured previously -- a kernel that stored 0xABC and exited left VRAM
reading 0, and tb/tb_compute_top.v had to work around it by reading the
architectural value back out of the cache hierarchy rather than out of
memory. A real host readback has no such workaround.

The property under test is exactly what a host needs:

    after flush_done, MEMORY holds the data, and the CACHE holds nothing.

It is checked against this module's own memory model, never against the
cache, so a pass means the data genuinely left the L1.

WHY THIS IS ITS OWN MODULE
--------------------------
cocotb runs every test in a module inside ONE simulation, and test_mesi.py's
L2Model.run() loops until self.stop, which nothing ever sets. Appending this
test to that module left several L2 models driving the same bus signals with
separate memory dictionaries, and a line appeared in "memory" before any
flush had run. The suite is deliberately self-contained -- it does not import
from test_mesi, because importing a module that defines @cocotb.test()
functions would pull those tests into this run too. Same trap, and the same
fix, as tb/uvm/test_sm_x7_warps.py.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly, NextTimeStep

from tb_common import start_clock_and_reset

LINE_BYTES = 16      # tb_mesi_top's parameter, NOT the 128 the SM uses
LINE_MASK = ~(LINE_BYTES - 1) & 0xFFFFFFFF
MESI_NAMES = {0: "I", 1: "S", 2: "E", 3: "M"}
FULL_BE = (1 << LINE_BYTES) - 1


class Memory:
    """Backing store on the wrapper's L2 port. Records every write."""

    def __init__(self, dut):
        self.dut = dut
        self.mem = {}
        self.stop = False

    async def run(self):
        d = self.dut
        d.l2_req_ready.value = 0
        d.l2_resp_valid.value = 0
        d.l2_resp_rdata.value = 0
        while not self.stop:
            d.l2_req_ready.value = 1
            await ReadOnly()
            fire = int(d.l2_req_valid.value) == 1
            if fire:
                addr = int(d.l2_req_addr.value) & LINE_MASK
                write = int(d.l2_req_write.value)
                wdata = int(d.l2_req_wdata.value)
            await RisingEdge(d.clk)
            if fire:
                d.l2_req_ready.value = 0
                if write:
                    self.mem[addr] = wdata
                else:
                    d.l2_resp_valid.value = 1
                    d.l2_resp_rdata.value = self.mem.get(addr, 0)
                    await RisingEdge(d.clk)
                    d.l2_resp_valid.value = 0


async def write_line(dut, addr, data):
    """One line-wide write through master 0, held until accepted."""
    dut.m0_req_valid.value = 1
    dut.m0_req_write.value = 1
    dut.m0_req_addr.value = addr
    dut.m0_req_wdata.value = data
    dut.m0_req_be.value = FULL_BE
    while True:
        await ReadOnly()
        ready = int(dut.m0_req_ready.value)
        await RisingEdge(dut.clk)
        if ready:
            break
    dut.m0_req_valid.value = 0
    dut.m0_req_write.value = 0
    # let the miss/fill complete before issuing the next one
    await ClockCycles(dut.clk, 60)


async def mesi_of(dut, addr):
    dut.dbg_addr.value = addr
    await ReadOnly()
    st = int(dut.m0_dbg_mesi.value)
    await NextTimeStep()
    return st


async def settle(dut, mem):
    """Stop this test's memory model before the next test starts.

    cocotb runs every test in one simulation, so a model left looping keeps
    driving l2_req_ready into the following test. That is precisely the bug
    this suite was split out of test_mesi.py to avoid, and it bit here too:
    the clean-cache test saw a write that the previous test's leftover model
    had recorded.
    """
    mem.stop = True
    await ClockCycles(dut.clk, 2)


async def quiesce(dut):
    for i in range(4):
        getattr(dut, f"m{i}_req_valid").value = 0
        getattr(dut, f"m{i}_req_write").value = 0
        getattr(dut, f"m{i}_req_addr").value = 0
        getattr(dut, f"m{i}_req_wdata").value = 0
        getattr(dut, f"m{i}_req_be").value = 0
    dut.dbg_addr.value = 0
    dut.flush_req.value = 0
    await ClockCycles(dut.clk, 4)


async def do_flush(dut, mask=0b0001, limit=40000):
    """Raise flush_req, wait for the done pulse, return cycles taken."""
    dut.flush_req.value = mask
    cycles = 0
    for _ in range(limit):
        await ReadOnly()
        done = (int(dut.flush_done.value) & mask) != 0
        await RisingEdge(dut.clk)
        cycles += 1
        if done:
            dut.flush_req.value = 0
            await ClockCycles(dut.clk, 20)
            return cycles
    dut.flush_req.value = 0
    return None


@cocotb.test()
async def flush_writes_dirty_lines_to_memory(dut):
    """Dirty lines reach memory, and the cache is left empty.

    The three extremes are covered deliberately: all-zeros, all-ones, and a
    directed pattern -- plus a line in a different set, so the walk has to
    advance its set counter and not only its way counter.
    """
    await start_clock_and_reset(dut)
    mem = Memory(dut)
    cocotb.start_soon(mem.run())
    await quiesce(dut)

    # tb_mesi_top builds the L1 with SETS=4, WAYS=2 and LINE_BYTES=16, so
    # set = addr[5:4]. One line per set: that keeps every line resident (2
    # ways would evict a third line sharing a set) AND forces the flush walk
    # to advance its set counter rather than only its way counter.
    lines = {
        0x0000_2000: 0,                                            # set 0, all zeros
        0x0000_2010: (1 << (LINE_BYTES * 8)) - 1,                  # set 1, all ones
        0x0000_2020: 0xDEAD_BEEF_0123_4567_89AB_CDEF_0F1E_2D3C,    # set 2, directed
    }
    for addr, val in lines.items():
        await write_line(dut, addr, val)

    # Every line should be Modified in L1 and not yet in memory. If memory
    # already had them, the flush would pass for the wrong reason -- so this
    # is asserted, not assumed.
    for addr in lines:
        st = await mesi_of(dut, addr)
        assert st == 3, (
            f"@{addr:#x}: expected Modified before flush, got "
            f"{MESI_NAMES[st]} -- the write did not land dirty in L1")
    early = [a for a, v in lines.items() if mem.mem.get(a) == v]
    assert not early, (
        f"lines {[hex(a) for a in early]} were already in memory before any "
        f"flush; this test would prove nothing")

    cycles = await do_flush(dut)
    assert cycles is not None, "flush_done never pulsed"

    # 1. memory holds every dirty line
    for addr, val in lines.items():
        got = mem.mem.get(addr)
        assert got == val, (
            f"@{addr:#x}: memory holds "
            f"{'nothing' if got is None else hex(got)}, expected {val:#x} "
            f"-- flush did not write this line back")

    # 2. the cache holds nothing
    for addr in lines:
        st = await mesi_of(dut, addr)
        assert st == 0, (
            f"@{addr:#x}: L1 still {MESI_NAMES[st]} after flush, expected I "
            f"-- flush must invalidate, not only write back")

    dut._log.info(
        f"flush in {cycles} cycles: {len(lines)} Modified lines (all-zeros, "
        f"all-ones, directed) written back to memory and invalidated")
    await settle(dut, mem)


@cocotb.test()
async def flush_of_clean_cache_is_harmless(dut):
    """Flushing with nothing dirty must still terminate, and write nothing.

    The walk has to run over every set and way even when it finds no
    Modified line. A termination bug here would hang the GPU on any kernel
    that happened not to write, and a spurious writeback would corrupt
    memory with whatever an invalid way happened to contain.
    """
    await start_clock_and_reset(dut)
    mem = Memory(dut)
    cocotb.start_soon(mem.run())
    await quiesce(dut)

    before = dict(mem.mem)
    cycles = await do_flush(dut)
    assert cycles is not None, \
        "flush_done never pulsed on a clean cache -- the walk does not terminate"
    assert mem.mem == before, (
        f"flush of a clean cache wrote {len(mem.mem) - len(before)} lines to "
        f"memory; clean and invalid lines must be dropped silently")
    dut._log.info(
        f"clean-cache flush terminated in {cycles} cycles with no bus writes")
    await settle(dut, mem)


@cocotb.test()
async def flush_is_repeatable(dut):
    """A second flush after a second write must work exactly like the first.

    Catches a walk whose counters are not re-initialised on entry -- that
    would pass once and then either hang or skip lines forever after, which
    is the shape of bug a single-shot test cannot see.
    """
    await start_clock_and_reset(dut)
    mem = Memory(dut)
    cocotb.start_soon(mem.run())
    await quiesce(dut)

    A, B = 0x0000_4000, 0x0000_4010   # different sets
    v1 = 0x1111_2222_3333_4444_5555_6666_7777_8888
    v2 = 0xAAAA_BBBB_CCCC_DDDD_EEEE_FFFF_0000_9999

    await write_line(dut, A, v1)
    c1 = await do_flush(dut)
    assert c1 is not None, "first flush never completed"
    assert mem.mem.get(A) == v1, f"first flush: @{A:#x} not in memory"

    await write_line(dut, B, v2)
    c2 = await do_flush(dut)
    assert c2 is not None, "SECOND flush never completed -- walk counters " \
                           "are not re-initialised on entry"
    assert mem.mem.get(B) == v2, (
        f"second flush: @{B:#x} holds "
        f"{mem.mem.get(B) and hex(mem.mem[B])}, expected {v2:#x}")
    assert mem.mem.get(A) == v1, "first flush's data was lost"

    dut._log.info(f"two successive flushes both completed ({c1} then {c2} "
                  f"cycles), both lines in memory")
    await settle(dut, mem)
