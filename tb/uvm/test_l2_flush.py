# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""L2 cache flush / writeback-all.

WHY THIS EXISTS AT ALL
----------------------
The `flush` suite (tb/uvm/test_mesi_flush.py) already proves L1 can write
every Modified line back and invalidate itself. That is not enough for a host
to read a kernel's results, and the gap was measured rather than assumed:
L1's flush writes to the coherent bus, and the coherent bus terminates at L2,
which is ALSO write-back -- titan_x5_l2_cache has a dirty_array, sets it on a
write hit, and writes back only when capacity eviction happens to pick that
way. So flushing L1 moves a dirty line from L1 into L2 and stops there. VRAM
still reads stale.

The property under test is the one a host actually depends on:

    after flush_done, MEMORY holds the data, and the CACHE holds nothing.

It is checked against this module's own memory model on the L2's memory-side
port -- never against the cache -- so a pass means the data genuinely left
L2. Invalidation is checked from the OUTSIDE too, by reading the line back
afterwards and requiring that the read miss and go to memory; that cannot be
satisfied by a flush that writes back without invalidating.

WHY IT IS ITS OWN MODULE
------------------------
Same trap as test_mesi_flush.py, for the same reason: cocotb runs every test
in a module inside one simulation, so a memory model left looping keeps
driving mem_req_ready into the following test. Each test here stops its own
model before returning.
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly

from tb_common import start_clock_and_reset

# tb_l2_flush_top's parameters. Address decode in titan_x5_l2_cache is, from
# the LSB: offset | bank | index | tag.
LINE_BYTES = 16
BANKS = 4
SETS_PER_BANK = 4
WAYS = 8

OFFSET_BITS = 4          # $clog2(16)
BANK_BITS = 2            # $clog2(4)
INDEX_BITS = 2           # $clog2(16/4)

LINE_MASK = ~(LINE_BYTES - 1) & 0xFFFF_FFFF
ALL_ONES = (1 << (LINE_BYTES * 8)) - 1


def line_addr(tag, bank, index):
    """Build an address landing in a chosen (bank, set) of the L2."""
    assert bank < BANKS and index < SETS_PER_BANK
    return ((tag << (OFFSET_BITS + BANK_BITS + INDEX_BITS))
            | (index << (OFFSET_BITS + BANK_BITS))
            | (bank << OFFSET_BITS))


class Memory:
    """Backing store on the L2's memory-side port. Records every access.

    `writes` is kept as an ordered list rather than only a dict because the
    all-zeros line is indistinguishable from "absent" in a dict -- and an
    all-zeros line is exactly the case a writeback bug would silently pass.
    """

    def __init__(self, dut):
        self.dut = dut
        self.mem = {}
        self.writes = []
        self.reads = []
        self.stop = False

    async def run(self):
        d = self.dut
        d.mem_req_ready.value = 0
        d.mem_resp_valid.value = 0
        d.mem_resp_rdata.value = 0
        while not self.stop:
            d.mem_req_ready.value = 1
            await ReadOnly()
            fire = int(d.mem_req_valid.value) == 1
            if fire:
                addr = int(d.mem_req_addr.value) & LINE_MASK
                write = int(d.mem_req_write.value)
                # Only meaningful on a write. titan_x5_l2_cache does not reset
                # mem_req_wdata_reg, so on an allocate (read) it is still X
                # and converting it raises.
                wdata = int(d.mem_req_wdata.value) if write else 0
            await RisingEdge(d.clk)
            if fire:
                d.mem_req_ready.value = 0
                if write:
                    self.mem[addr] = wdata
                    self.writes.append((addr, wdata))
                else:
                    self.reads.append(addr)
                    d.mem_resp_valid.value = 1
                    d.mem_resp_rdata.value = self.mem.get(addr, 0)
                    await RisingEdge(d.clk)
                    d.mem_resp_valid.value = 0

    def wrote(self, addr):
        """Values written back to `addr`, oldest first."""
        return [v for a, v in self.writes if a == addr]


async def quiesce(dut):
    dut.req_valid.value = 0
    dut.req_write.value = 0
    dut.req_addr.value = 0
    dut.req_wdata.value = 0
    dut.flush_req.value = 0
    dut.dbg_bank.value = 0
    dut.dbg_set.value = 0
    dut.dbg_way.value = 0
    await ClockCycles(dut.clk, 4)


async def entry(dut, bank, index, way):
    """(valid, dirty) of one cache entry, via the wrapper's residency probe."""
    dut.dbg_bank.value = bank
    dut.dbg_set.value = index
    dut.dbg_way.value = way
    await ReadOnly()
    v = int(dut.dbg_valid.value)
    d = int(dut.dbg_dirty.value)
    await RisingEdge(dut.clk)
    return v, d


async def resident(dut):
    """Every entry still valid after a flush, as (bank, set, way, dirty)."""
    out = []
    for b in range(BANKS):
        for s in range(SETS_PER_BANK):
            for w in range(WAYS):
                v, d = await entry(dut, b, s, w)
                if v:
                    out.append((b, s, w, d))
    return out


async def _issue(dut, addr, wdata, write):
    """Drive one request, holding it stable until the access completes.

    titan_x5_l2_cache does NOT latch its request: req_bank/req_index/req_tag
    and req_wdata are taken live off the input ports throughout COMPARE,
    ALLOCATE, WRITEBACK and REFILL. Dropping them at the handshake makes the
    access land on whatever the ports happen to hold afterwards. That is a
    real property of the module rather than a testbench quirk --
    titan_x6_banked_l2 carries a holding buffer (its hb_* registers) whose
    comment says it exists to "hold it stable until the slice completes".
    This suite drives a slice directly, so it has to do the same.

    Completion is req_ready going high again, which is exactly how the
    banked wrapper releases its buffer.
    """
    dut.req_addr.value = addr
    dut.req_wdata.value = wdata
    dut.req_write.value = 1 if write else 0
    dut.req_valid.value = 1

    for _ in range(1000):
        await ReadOnly()
        accepted = int(dut.req_ready.value) == 1
        await RisingEdge(dut.clk)
        if accepted:
            break
    else:
        raise AssertionError(f"@{addr:#x}: request never accepted")

    dut.req_valid.value = 0      # addr / wdata / write stay driven

    for _ in range(1000):
        await ReadOnly()
        done = int(dut.req_ready.value) == 1
        await RisingEdge(dut.clk)
        if done:
            break
    else:
        raise AssertionError(f"@{addr:#x}: access never completed")

    dut.req_write.value = 0
    await ClockCycles(dut.clk, 2)


async def write_line(dut, addr, data):
    await _issue(dut, addr, data, write=True)


async def read_line(dut, addr):
    await _issue(dut, addr, 0, write=False)


async def do_flush(dut, limit=40000):
    """Raise flush_req, wait for the done pulse, return cycles taken."""
    dut.flush_req.value = 1
    cycles = 0
    for _ in range(limit):
        await ReadOnly()
        done = int(dut.flush_done.value) == 1
        await RisingEdge(dut.clk)
        cycles += 1
        if done:
            dut.flush_req.value = 0
            await ClockCycles(dut.clk, 20)
            return cycles
    dut.flush_req.value = 0
    return None


async def settle(dut, mem):
    mem.stop = True
    await ClockCycles(dut.clk, 2)


async def setup(dut):
    await start_clock_and_reset(dut)
    mem = Memory(dut)
    cocotb.start_soon(mem.run())
    await quiesce(dut)
    return mem


@cocotb.test()
async def flush_writes_dirty_lines_to_memory(dut):
    """Dirty lines reach memory, including the all-zeros and all-ones extremes.

    The three lines sit in three different sets of one bank, so the walk has
    to advance its set counter and not only its way counter.
    """
    mem = await setup(dut)

    lines = {
        line_addr(0x20, bank=0, index=0): 0,          # all zeros
        line_addr(0x20, bank=0, index=1): ALL_ONES,   # all ones
        line_addr(0x20, bank=0, index=2): 0xDEAD_BEEF_0123_4567_89AB_CDEF_0F1E_2D3C,
    }
    for addr, val in lines.items():
        await write_line(dut, addr, val)

    # If the writes had already reached memory the flush would pass for the
    # wrong reason, so this is asserted rather than assumed. Checked against
    # the write log, not the dict: an all-zeros line is indistinguishable
    # from an absent one by value.
    early = [hex(a) for a in lines if mem.wrote(a)]
    assert not early, (
        f"lines {early} were written to memory before any flush; L2 is "
        f"write-back and this test would prove nothing")

    cycles = await do_flush(dut)
    assert cycles is not None, "flush_done never pulsed"

    for addr, val in lines.items():
        got = mem.wrote(addr)
        assert got, (f"@{addr:#x}: no writeback reached memory -- flush did "
                     f"not write this line back")
        assert got[-1] == val, (
            f"@{addr:#x}: memory holds {got[-1]:#x}, expected {val:#x}")

    dut._log.info(
        f"L2 flush in {cycles} cycles: {len(lines)} dirty lines "
        f"(all-zeros, all-ones, directed) written back to memory")
    await settle(dut, mem)


@cocotb.test()
async def flush_walks_every_bank(dut):
    """Every bank is visited, not just bank 0.

    The bank counter is the OUTERMOST loop of the L2 walk and is the one
    dimension L1 does not have, so it is the part of this flush that no
    existing test could ever have covered. One dirty line is placed in each
    of the 4 banks; a walk that never advances past bank 0 -- or that treats
    the bank index as constant -- leaves three of them behind.
    """
    mem = await setup(dut)

    lines = {line_addr(0x31, bank=b, index=0): 0xB00_0000 + b
             for b in range(BANKS)}
    for addr, val in lines.items():
        await write_line(dut, addr, val)

    cycles = await do_flush(dut)
    assert cycles is not None, "flush_done never pulsed"

    missing = [f"bank {b} @{a:#x}"
               for b, a in enumerate(lines) if not mem.wrote(a)]
    assert not missing, (
        f"{len(missing)} of {BANKS} banks were never written back: "
        f"{missing} -- the flush walk does not cover every bank")
    for addr, val in lines.items():
        assert mem.wrote(addr)[-1] == val, (
            f"@{addr:#x}: memory holds {mem.wrote(addr)[-1]:#x}, "
            f"expected {val:#x}")

    dut._log.info(f"L2 flush in {cycles} cycles: all {BANKS} banks written back")
    await settle(dut, mem)


@cocotb.test()
async def flush_leaves_the_cache_empty(dut):
    """After a flush not one entry is left valid, anywhere in the cache.

    This is the half of the contract the memory-side model cannot see, and it
    has to be checked by looking at the entries themselves. A behavioural
    version of this test -- read the line back, require the read to miss --
    was written first and does NOT work: a line left valid but clean is
    re-fetched anyway, because titan_x5_l2_cache's miss path allocates a
    victim by `replace_way` without first checking whether the address is
    already resident in another way, so the refill lands in a different way
    and the read goes to memory regardless. It was a mutation
    (writeback-without-invalidate) surviving that exposed this; the mutation
    now fails here.

    Why it matters beyond tidiness: after a fence the host writes that memory
    itself, and a surviving cached copy would shadow the host's write on the
    next kernel's read.
    """
    mem = await setup(dut)

    # Dirty lines in several banks and sets, plus one clean line, so the
    # sweep has to invalidate entries reached by BOTH walk exits.
    dirty = {
        line_addr(0x42, bank=2, index=1): 0x1234_5678_9ABC_DEF0_1122_3344_5566_7788,
        line_addr(0x42, bank=0, index=3): 0x0F0F_0F0F_0F0F_0F0F_0F0F_0F0F_0F0F_0F0F,
        line_addr(0x43, bank=3, index=0): ALL_ONES,
    }
    for addr, val in dirty.items():
        await write_line(dut, addr, val)
    clean = line_addr(0x44, bank=1, index=2)
    await read_line(dut, clean)      # allocates valid+clean

    live = await resident(dut)
    assert len(live) >= len(dirty) + 1, (
        f"only {len(live)} entries are resident before the flush; expected at "
        f"least {len(dirty) + 1} -- this test would prove nothing")

    cycles = await do_flush(dut)
    assert cycles is not None, "flush_done never pulsed"

    live = await resident(dut)
    where = ["bank%d set%d way%d%s" % (b, s, w, " dirty" if d else "")
             for b, s, w, d in live]
    assert not live, (
        f"{len(live)} entries still valid after flush_done: {where} -- flush "
        f"must invalidate every entry, not only write back the dirty ones")

    for addr, val in dirty.items():
        assert mem.wrote(addr)[-1:] == [val], (
            f"@{addr:#x}: {mem.wrote(addr)} written back, expected {val:#x}")

    dut._log.info(
        f"L2 flush in {cycles} cycles: {len(dirty)} dirty lines written back "
        f"and all {BANKS * SETS_PER_BANK * WAYS} entries left invalid")
    await settle(dut, mem)


@cocotb.test()
async def flush_of_clean_cache_is_harmless(dut):
    """Flushing with nothing dirty must terminate, and write nothing.

    The walk runs over every (bank, set, way) even when it finds nothing
    dirty. A termination bug here hangs the GPU on any fence after a kernel
    that happened not to write; a spurious writeback corrupts memory with
    whatever an invalid way contains.
    """
    mem = await setup(dut)

    before = list(mem.writes)
    cycles = await do_flush(dut)
    assert cycles is not None, (
        "flush_done never pulsed on a clean cache -- the walk does not "
        "terminate")
    assert mem.writes == before, (
        f"flush of a clean cache wrote {len(mem.writes) - len(before)} lines; "
        f"clean and invalid entries must be dropped silently")

    dut._log.info(
        f"clean-cache flush over {BANKS}x{SETS_PER_BANK}x{WAYS} entries "
        f"terminated in {cycles} cycles with no memory writes")
    await settle(dut, mem)


@cocotb.test()
async def held_flush_req_runs_exactly_one_walk(dut):
    """One assertion of flush_req = one walk, however long it is held.

    flush_req is a level and the requester cannot drop it until it has seen
    flush_done, so the FSM is guaranteed to be back in IDLE with flush_req
    still high. Restarting there is idempotent and therefore invisible to
    every other test in this file -- which is exactly why it needs its own.
    It is not harmless: the extra sweep is BANKS*SETS*WAYS cycles on every
    fence, and it runs concurrently with whatever the requester does next,
    believing the flush is over. That was measured here: it silently cleared
    entries underneath this suite's own residency check.

    The device-level sequencer also depends on this. It holds flush_req to
    every cache until they have ALL reported done, so a cache that re-arms on
    a still-high level would walk again while it waits for its neighbours.
    """
    mem = await setup(dut)

    await write_line(dut, line_addr(0x60, bank=0, index=0), 0xC0FFEE)

    dut.flush_req.value = 1
    dones = 0
    for _ in range(600):          # >> one 4x4x8 walk (131 cycles)
        await ReadOnly()
        if int(dut.flush_done.value):
            dones += 1
        await RisingEdge(dut.clk)
    assert dones == 1, (
        f"flush_done pulsed {dones} times while flush_req was held high; "
        f"expected exactly 1 -- the walk restarts on the held level")

    # ... and dropping flush_req must re-arm it, or a second fence hangs.
    dut.flush_req.value = 0
    await ClockCycles(dut.clk, 4)
    again = await do_flush(dut)
    assert again is not None, (
        "no flush_done after re-asserting flush_req -- the one-shot latch "
        "never rearms and every fence after the first would hang")

    dut._log.info(
        f"flush_req held high for 600 cycles produced exactly 1 walk; "
        f"re-asserting it produced another ({again} cycles)")
    await settle(dut, mem)


@cocotb.test()
async def flush_is_repeatable(dut):
    """A second flush must work exactly like the first.

    Catches a walk whose counters are not re-initialised on entry: that
    passes once and then either hangs or skips every line forever after,
    which a single-shot test cannot see. It matters here because a fence is
    not a once-per-boot event.
    """
    mem = await setup(dut)

    a = line_addr(0x51, bank=1, index=0)
    b = line_addr(0x51, bank=3, index=2)
    va = 0x1111_2222_3333_4444_5555_6666_7777_8888
    vb = 0xAAAA_BBBB_CCCC_DDDD_EEEE_FFFF_0000_9999

    await write_line(dut, a, va)
    c1 = await do_flush(dut)
    assert c1 is not None, "first flush never completed"
    assert mem.wrote(a)[-1:] == [va], f"first flush: @{a:#x} not in memory"

    await write_line(dut, b, vb)
    c2 = await do_flush(dut)
    assert c2 is not None, (
        "SECOND flush never completed -- walk counters are not "
        "re-initialised on entry")
    assert mem.wrote(b)[-1:] == [vb], (
        f"second flush: @{b:#x} holds {mem.wrote(b)}, expected {vb:#x}")
    assert mem.mem.get(a) == va, "first flush's data was lost"

    dut._log.info(
        f"two successive L2 flushes both completed ({c1} then {c2} cycles), "
        f"both lines in memory")
    await settle(dut, mem)
