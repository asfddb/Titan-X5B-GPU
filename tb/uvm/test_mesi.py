# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""MESI coherency protocol verification (4 x L1 + coherent crossbar).

DUT: tb_mesi_top - four deliberately tiny titan_x5_l1_cache instances
(16B lines, 4 sets, 2 ways => constant evictions/writebacks) behind the
titan_x5_coherent_xbar. The L2 is a Python memory model on the exposed L2
port, giving the scoreboard exact visibility of every line that reaches
the next level.

Checks:
  1. Directed producer/consumer: SM0 writes A, SM1 reads A -> must observe
     the new data (the exact stale-data bug this phase fixes), including
     M->S dirty interventions, S->M upgrades, and write-after-invalidate.
  2. Sequential-consistency phase: masters take turns issuing random
     reads/writes to a small shared pool; every read is checked against a
     byte-accurate global reference model.
  3. Eviction storm: many lines mapping to the same set force dirty
     writebacks; everything is read back and checked.
  4. Concurrent storm: all four masters hammer a shared pool at once
     (exercises the BusUpgr-invalidation race and pending-writeback-snoop
     race); afterwards all masters must agree on every line and the value
     must be one of the legally-written ones.
  5. A continuous MESI invariant monitor samples the debug state ports:
     at most one M/E owner per line, M/E implies all others Invalid.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly, NextTimeStep

from tb_common import start_clock_and_reset, deterministic_line
from coverage_util import sample_mesi_state, export_on_exit

export_on_exit("mesi")

LINE_BYTES = 16
LINE_BITS = LINE_BYTES * 8
LINE_MASK = ~(LINE_BYTES - 1) & 0xFFFFFFFF
MESI_NAMES = {0: "I", 1: "S", 2: "E", 3: "M"}


class L2Model:
    """Python L2/memory model driving the exposed L2 port."""

    def __init__(self, dut, rng):
        self.dut = dut
        self.rng = rng
        self.mem = {}
        self.stop = False
        self.writes = []  # (addr, data) log of everything reaching L2

    def line(self, addr):
        base = addr & LINE_MASK
        if base not in self.mem:
            self.mem[base] = deterministic_line(base, LINE_BYTES)
        return self.mem[base]

    async def run(self):
        dut = self.dut
        dut.l2_req_ready.value = 0
        dut.l2_resp_valid.value = 0
        dut.l2_resp_rdata.value = 0
        while not self.stop:
            ready = self.rng.random() < 0.75
            dut.l2_req_ready.value = 1 if ready else 0
            await ReadOnly()
            valid = int(dut.l2_req_valid.value) == 1
            if valid and ready:
                addr = int(dut.l2_req_addr.value) & LINE_MASK
                write = int(dut.l2_req_write.value)
                wdata = int(dut.l2_req_wdata.value)
            await RisingEdge(dut.clk)  # acceptance edge (if valid & ready)
            if valid and ready:
                dut.l2_req_ready.value = 0
                if write:
                    self.mem[addr] = wdata
                    self.writes.append((addr, wdata))
                else:
                    data = self.line(addr)
                    for _ in range(self.rng.randint(0, 3)):
                        await RisingEdge(dut.clk)
                    dut.l2_resp_valid.value = 1
                    dut.l2_resp_rdata.value = data
                    await RisingEdge(dut.clk)
                    dut.l2_resp_valid.value = 0


class Master:
    """Core-port driver for one L1."""

    def __init__(self, dut, idx):
        self.dut = dut
        self.i = idx
        self.req_valid = getattr(dut, f"m{idx}_req_valid")
        self.req_ready = getattr(dut, f"m{idx}_req_ready")
        self.req_write = getattr(dut, f"m{idx}_req_write")
        self.req_addr = getattr(dut, f"m{idx}_req_addr")
        self.req_wdata = getattr(dut, f"m{idx}_req_wdata")
        self.req_be = getattr(dut, f"m{idx}_req_be")
        self.resp_valid = getattr(dut, f"m{idx}_resp_valid")
        self.resp_rdata = getattr(dut, f"m{idx}_resp_rdata")
        self.dbg = getattr(dut, f"m{idx}_dbg_mesi")
        self.req_valid.value = 0

    async def _accept(self):
        # sample ready in the ReadOnly phase of the same edge the DUT
        # samples valid: acceptance is the edge where both were high
        for _ in range(30000):
            await ReadOnly()
            accepted = int(self.req_ready.value) == 1
            await RisingEdge(self.dut.clk)
            if accepted:
                self.req_valid.value = 0
                return
        raise AssertionError(f"master {self.i}: request never accepted")

    async def _idle(self):
        # wait until the L1 can take another request => previous completed
        for _ in range(30000):
            await ReadOnly()
            ready = int(self.req_ready.value) == 1
            await RisingEdge(self.dut.clk)
            if ready:
                return
        raise AssertionError(f"master {self.i}: L1 never returned to ready")

    async def read(self, addr):
        self.req_write.value = 0
        self.req_addr.value = addr
        self.req_be.value = 0
        self.req_wdata.value = 0
        self.req_valid.value = 1
        await self._accept()
        data = None
        for _ in range(30000):
            await ReadOnly()
            if int(self.resp_valid.value) == 1:
                data = int(self.resp_rdata.value)
            await RisingEdge(self.dut.clk)
            if data is not None:
                return data
        raise AssertionError(f"master {self.i}: read response timeout")

    async def write(self, addr, data, be):
        self.req_write.value = 1
        self.req_addr.value = addr
        self.req_wdata.value = data
        self.req_be.value = be
        self.req_valid.value = 1
        await self._accept()
        await self._idle()


class RefMemory:
    """Byte-accurate global reference (valid while accesses serialize)."""

    def __init__(self):
        self.mem = {}

    def line(self, addr):
        base = addr & LINE_MASK
        if base not in self.mem:
            self.mem[base] = deterministic_line(base, LINE_BYTES)
        return self.mem[base]

    def write(self, addr, data, be):
        base = addr & LINE_MASK
        cur = self.line(base)
        for b in range(LINE_BYTES):
            if (be >> b) & 1:
                byte = (data >> (b * 8)) & 0xFF
                cur = (cur & ~(0xFF << (b * 8))) | (byte << (b * 8))
        self.mem[base] = cur


async def check_invariants(dut, lines):
    """MESI invariants via the debug ports (combinational lookup)."""
    for addr in lines:
        dut.dbg_addr.value = addr
        await ReadOnly()
        states = [int(getattr(dut, f"m{i}_dbg_mesi").value) for i in range(4)]
        await NextTimeStep()
        for i, s in enumerate(states):
            sample_mesi_state(i, addr, s)   # FSM occupancy + transitions
        n_m = states.count(3)
        n_e = states.count(2)
        n_s = states.count(1)
        assert n_m <= 1, f"@{addr:#x}: two Modified owners! {states}"
        assert n_e <= 1, f"@{addr:#x}: two Exclusive owners! {states}"
        if n_m == 1:
            assert n_e == 0 and n_s == 0, \
                f"@{addr:#x}: M coexists with S/E: " \
                f"{[MESI_NAMES[s] for s in states]}"
        if n_e == 1:
            assert n_m == 0 and n_s == 0, \
                f"@{addr:#x}: E coexists with S/M: " \
                f"{[MESI_NAMES[s] for s in states]}"


def rand_be(rng):
    style = rng.randrange(3)
    if style == 0:
        return (1 << LINE_BYTES) - 1          # full line
    if style == 1:
        w = rng.randrange(LINE_BYTES // 4)     # one word
        return 0xF << (4 * w)
    return rng.getrandbits(LINE_BYTES) or 1    # random sparse


@cocotb.test()
async def test_mesi_directed_producer_consumer(dut):
    rng = random.Random(0x3E51)
    await start_clock_and_reset(dut)
    l2 = L2Model(dut, rng)
    cocotb.start_soon(l2.run())
    m = [Master(dut, i) for i in range(4)]
    dut.dbg_addr.value = 0
    await ClockCycles(dut.clk, 2)

    A = 0x0000_1000
    full_be = (1 << LINE_BYTES) - 1

    # 1. THE bug scenario: SM0 writes, SM1 must see it (not stale L2 data)
    v1 = 0xDEAD_BEEF_0123_4567_89AB_CDEF_0F1E_2D3C
    await m[0].write(A, v1, full_be)
    got = await m[1].read(A)
    assert got == v1, \
        f"STALE DATA: m1 read {got:#x}, m0 wrote {v1:#x} (coherency broken)"
    await check_invariants(dut, [A])

    # after M->S intervention both hold S; write from m1 forces BusUpgr
    v2 = v1 ^ ((1 << LINE_BITS) - 1)
    await m[1].write(A, v2, full_be)
    got = await m[0].read(A)
    assert got == v2, f"upgrade path stale: m0 read {got:#x} != {v2:#x}"
    await check_invariants(dut, [A])

    # all four read (line becomes widely shared), then one writes,
    # then everyone must see the new value
    for i in range(4):
        got = await m[i].read(A)
        assert got == v2, f"m{i} shared read stale: {got:#x} != {v2:#x}"
    await check_invariants(dut, [A])
    v3 = 0x1111_2222_3333_4444_5555_6666_7777_8888
    await m[3].write(A, v3, full_be)
    for i in range(4):
        got = await m[i].read(A)
        assert got == v3, f"m{i} post-invalidate read stale: {got:#x}"
    await check_invariants(dut, [A])

    # partial-line write (byte enables) on a shared line
    await m[2].write(A + 4, 0xA5A5A5A5 << 32, 0xF0)  # word 1 only
    exp = (v3 & ~(0xFFFFFFFF << 32)) | ((0xA5A5A5A5 << 32) & (0xFFFFFFFF << 32))
    for i in (0, 1, 3):
        got = await m[i].read(A)
        assert got == exp, f"m{i} partial-write merge wrong: {got:#x} != {exp:#x}"
    # directed E-state coverage: exclusive fill then silent E->M upgrade,
    # and exclusive fill then foreign-BusRdX invalidation (E->I). The
    # invariant sampler between steps records the FSM transitions.
    X, Y = 0x0000_3100, 0x0000_3200
    await m[0].read(X)                    # nobody else has X -> E
    await check_invariants(dut, [X])
    await m[0].write(X, v1, full_be)      # silent E->M (no bus traffic)
    await check_invariants(dut, [X])
    await m[1].read(Y)                    # -> E in m1
    await check_invariants(dut, [Y])
    await m[0].write(Y, v2, full_be)      # BusRdX: m1 E->I
    await check_invariants(dut, [Y])
    got = await m[1].read(Y)
    assert got == v2, f"E->I path stale: {got:#x} != {v2:#x}"
    await check_invariants(dut, [Y])

    dut._log.info("MESI directed producer/consumer passed")
    l2.stop = True


@cocotb.test()
async def test_mesi_sequential_consistency(dut):
    rng = random.Random(0x5EC0)
    await start_clock_and_reset(dut)
    l2 = L2Model(dut, rng)
    cocotb.start_soon(l2.run())
    m = [Master(dut, i) for i in range(4)]
    ref = RefMemory()
    dut.dbg_addr.value = 0
    await ClockCycles(dut.clk, 2)

    # small pool: 8 lines spanning 2 sets -> shared lines + evictions
    pool = [0x2000 + LINE_BYTES * k for k in range(8)]

    for step in range(300):
        i = rng.randrange(4)
        addr = rng.choice(pool)
        if rng.random() < 0.5:
            data = rng.getrandbits(LINE_BITS)
            be = rand_be(rng)
            await m[i].write(addr, data, be)
            ref.write(addr, data, be)
        else:
            got = await m[i].read(addr)
            exp = ref.line(addr)
            assert got == exp, (
                f"step {step}: m{i} read @{addr:#x} got {got:#x} "
                f"expected {exp:#x}")
        if step % 25 == 0:
            await check_invariants(dut, pool)
    await check_invariants(dut, pool)
    dut._log.info("MESI sequential-consistency (300 serialized ops) passed")
    l2.stop = True


@cocotb.test()
async def test_mesi_eviction_storm(dut):
    rng = random.Random(0xE71C)
    await start_clock_and_reset(dut)
    l2 = L2Model(dut, rng)
    cocotb.start_soon(l2.run())
    m = [Master(dut, i) for i in range(4)]
    ref = RefMemory()
    dut.dbg_addr.value = 0
    await ClockCycles(dut.clk, 2)

    # 12 lines that all map to set 0 (index bits [5:4] == 0): with 2 ways
    # per set this forces continuous dirty evictions + refills
    lines = [0x4000 + (k << 6) for k in range(12)]
    full_be = (1 << LINE_BYTES) - 1

    for rnd in range(4):
        for a in lines:
            i = rng.randrange(4)
            data = rng.getrandbits(LINE_BITS)
            await m[i].write(a, data, full_be)
            ref.write(a, data, full_be)
        for a in rng.sample(lines, 6):
            i = rng.randrange(4)
            got = await m[i].read(a)
            assert got == ref.line(a), (
                f"eviction storm: m{i} @{a:#x} got {got:#x} "
                f"expected {ref.line(a):#x}")
    # final full readback through a single master
    for a in lines:
        got = await m[0].read(a)
        assert got == ref.line(a), \
            f"final readback @{a:#x}: {got:#x} != {ref.line(a):#x}"
    await check_invariants(dut, lines)
    dut._log.info("MESI eviction storm passed (dirty writebacks verified)")
    l2.stop = True


@cocotb.test()
async def test_mesi_concurrent_storm(dut):
    rng = random.Random(0xC0C0)
    await start_clock_and_reset(dut)
    l2 = L2Model(dut, rng)
    cocotb.start_soon(l2.run())
    m = [Master(dut, i) for i in range(4)]
    dut.dbg_addr.value = 0
    await ClockCycles(dut.clk, 2)

    pool = [0x8000 + LINE_BYTES * k for k in range(6)]
    written = {a: {deterministic_line(a, LINE_BYTES)} for a in pool}
    full_be = (1 << LINE_BYTES) - 1

    async def agent(idx, seed):
        arng = random.Random(seed)
        for _ in range(60):
            addr = arng.choice(pool)
            if arng.random() < 0.6:
                # unique tagged data: master id + counter in the top byte
                data = arng.getrandbits(LINE_BITS - 8) | (idx << (LINE_BITS - 8))
                written[addr].add(data)
                await m[idx].write(addr, data, full_be)
            else:
                await m[idx].read(addr)
            for _ in range(arng.randrange(4)):
                await RisingEdge(dut.clk)

    tasks = [cocotb.start_soon(agent(i, 0x1234 + i)) for i in range(4)]
    # continuous invariant monitoring while the storm runs
    for _ in range(200):
        await ClockCycles(dut.clk, 10)
        await check_invariants(dut, pool)
        if all(t.done() for t in tasks):
            break
    for t in tasks:
        await t

    # quiesce, then: all masters must agree, and the value must be a
    # legally-written one
    await ClockCycles(dut.clk, 20)
    for addr in pool:
        vals = [await m[i].read(addr) for i in range(4)]
        assert len(set(vals)) == 1, (
            f"@{addr:#x}: masters disagree after quiesce: "
            f"{[hex(v) for v in vals]}")
        assert vals[0] in written[addr], (
            f"@{addr:#x}: settled value {vals[0]:#x} was never written")
    await check_invariants(dut, pool)
    dut._log.info("MESI concurrent storm passed (races + invariants)")
    l2.stop = True
