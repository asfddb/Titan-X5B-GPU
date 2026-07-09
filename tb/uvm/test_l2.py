# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x6_banked_l2 verification.

DUT: tb_l2_top - a 2-slice banked L2 (128-bit lines, 2 ways, 4 banks x 4 sets)
wrapping titan_x5_l2_cache slices. A Python memory model sits on each slice's
VRAM-facing port (accepts writebacks, serves allocate refills).

The requester uses a standard single-cycle ready/valid handshake: it asserts
req then drops it the cycle req_ready is seen high. This is the contract a
correctly pipelined wrapper must honour. The pre-fix wrapper registered the
request but exposed a stale combinational req_ready, so it overwrote the
in-flight request and the slice processed the wrong address.

Checks:
  1. Write-then-readback: distinct lines survive allocate/writeback/refill.
  2. Back-to-back same-slice requests (no idle gap) return correct data.
  3. Eviction: 3 lines mapped to one 2-way set force a dirty writeback; the
     evicted line is read back from the mem model byte-exact.
  4. Both slices driven in parallel stay independent.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly

from tb_common import start_clock_and_reset, deterministic_line

NUM_SLICES = 2
LINE_BYTES = 16
LINE_BITS = LINE_BYTES * 8
LINE_MASK = (1 << LINE_BITS) - 1
ADDR_W = 32
ALL_READY = (1 << NUM_SLICES) - 1


def slice_int(sig, s, width):
    """Extract slice s's `width`-bit field from a packed bus, tolerating X/Z on
    other (inactive) slices. Returns None if this slice's bits are unresolved."""
    b = sig.value.binstr           # MSB-first, length == full bus width
    total = len(b)
    sub = b[total - (s + 1) * width: total - s * width]
    if any(c not in "01" for c in sub):
        return None
    return int(sub, 2)


class MemModel:
    """VRAM model on the per-slice mem interface (single-transfer full line)."""

    def __init__(self, dut, rng):
        self.dut = dut
        self.l2 = dut.u_l2
        self.rng = rng
        self.mem = {}
        self.stop = False

    def line(self, addr):
        if addr not in self.mem:
            self.mem[addr] = deterministic_line(addr, LINE_BYTES)
        return self.mem[addr]

    async def run(self):
        l2 = self.l2
        clk = self.dut.clk
        pending = [None] * NUM_SLICES  # allocate reads awaiting a response
        l2.mem_req_ready.value = ALL_READY
        l2.mem_resp_valid.value = 0
        l2.mem_resp_rdata.value = 0
        while not self.stop:
            # Drive responses for reads accepted on the previous cycle.
            rv = 0
            rd = 0
            for s in range(NUM_SLICES):
                if pending[s] is not None:
                    rv |= 1 << s
                    rd |= (self.line(pending[s]) & LINE_MASK) << (s * LINE_BITS)
            l2.mem_req_ready.value = ALL_READY
            l2.mem_resp_valid.value = rv
            l2.mem_resp_rdata.value = rd

            await ReadOnly()
            mrv = int(l2.mem_req_valid.value)
            reqs = []
            for s in range(NUM_SLICES):
                if (mrv >> s) & 1:
                    addr = slice_int(l2.mem_req_addr, s, ADDR_W)
                    wr = slice_int(l2.mem_req_write, s, 1)
                    assert addr is not None and wr is not None, \
                        f"slice {s}: mem_req addr/write X while mem_req_valid asserted"
                    if wr:
                        wd = slice_int(l2.mem_req_wdata, s, LINE_BITS)
                        assert wd is not None, f"slice {s}: writeback wdata is X"
                    else:
                        wd = 0  # write data is don't-care for an allocate read
                    reqs.append((s, addr, wr, wd))
            await RisingEdge(clk)

            # Clear pending that were just responded.
            for s in range(NUM_SLICES):
                if pending[s] is not None and (rv >> s) & 1:
                    pending[s] = None
            # Process accepted mem requests (mem_req_ready is always high).
            for (s, addr, wr, wd) in reqs:
                if wr:
                    self.mem[addr] = wd
                else:
                    pending[s] = addr


class ReqDriver:
    """Drives the banked_l2 req interface, holding the shared-bus Python state."""

    def __init__(self, dut):
        self.dut = dut
        self.l2 = dut.u_l2
        self.rv = 0
        self.raddr = 0
        self.rwrite = 0
        self.rwdata = 0
        self._push()

    def _push(self):
        self.l2.req_valid.value = self.rv
        self.l2.req_addr.value = self.raddr
        self.l2.req_write.value = self.rwrite
        self.l2.req_wdata.value = self.rwdata

    def _set_slice(self, s, valid, addr, write, wdata):
        m32 = 0xFFFFFFFF
        self.rv = (self.rv & ~(1 << s)) | ((valid & 1) << s)
        self.rwrite = (self.rwrite & ~(1 << s)) | ((write & 1) << s)
        self.raddr = (self.raddr & ~(m32 << (s * ADDR_W))) | ((addr & m32) << (s * ADDR_W))
        self.rwdata = (self.rwdata & ~(LINE_MASK << (s * LINE_BITS))) | \
                      ((wdata & LINE_MASK) << (s * LINE_BITS))
        self._push()

    async def request(self, s, write, addr, wdata=0):
        """Single-cycle handshake issue; returns rdata for reads, None for writes."""
        clk = self.dut.clk
        self._set_slice(s, 1, addr, 1 if write else 0, wdata)
        for _ in range(1000):
            await ReadOnly()
            accepted = (int(self.l2.req_ready.value) >> s) & 1
            await RisingEdge(clk)
            if accepted:
                self._set_slice(s, 0, addr, 0, 0)
                break
        else:
            raise AssertionError(f"slice {s}: request not accepted")

        if not write:
            for _ in range(1000):
                await ReadOnly()
                if (int(self.l2.resp_valid.value) >> s) & 1:
                    data = slice_int(self.l2.resp_rdata, s, LINE_BITS)
                    assert data is not None, f"slice {s}: resp_rdata X while resp_valid"
                    await RisingEdge(clk)
                    return data
                await RisingEdge(clk)
            raise AssertionError(f"slice {s}: read response timeout")
        else:
            # Write completes when the slice becomes ready again.
            for _ in range(1000):
                await ReadOnly()
                if (int(self.l2.req_ready.value) >> s) & 1:
                    await RisingEdge(clk)
                    return None
                await RisingEdge(clk)
            raise AssertionError(f"slice {s}: write completion timeout")


def addr_for(bank, index, tag):
    # layout: [tag | index(2) | bank(2) | offset(4)]
    return (tag << 8) | (index << 6) | (bank << 4)


async def _setup(dut, seed):
    rng = random.Random(seed)
    l2 = dut.u_l2
    # init req bus before reset
    l2.req_valid.value = 0
    l2.req_addr.value = 0
    l2.req_write.value = 0
    l2.req_wdata.value = 0
    await start_clock_and_reset(dut)
    mem = MemModel(dut, rng)
    cocotb.start_soon(mem.run())
    await RisingEdge(dut.clk)
    return rng, mem, ReqDriver(dut)


@cocotb.test()
async def test_l2_write_readback(dut):
    """Distinct lines written then read back must return the written data."""
    rng, mem, drv = await _setup(dut, seed=1)
    ref = {}
    lines = [addr_for(b, i, 0x100 + n) for n, (b, i) in enumerate(
        [(0, 0), (1, 0), (2, 1), (3, 1), (0, 2), (1, 3)])]
    for a in lines:
        d = rng.getrandbits(LINE_BITS)
        await drv.request(0, True, a, d)
        ref[a] = d
    for a in lines:
        got = await drv.request(0, False, a)
        assert got == ref[a], f"line {a:#x}: got {got:#x} exp {ref[a]:#x}"
    mem.stop = True


@cocotb.test()
async def test_l2_back_to_back(dut):
    """Back-to-back requests with no idle cycle must not corrupt each other."""
    rng, mem, drv = await _setup(dut, seed=2)
    a0 = addr_for(0, 0, 0x200)
    a1 = addr_for(1, 1, 0x201)
    d0 = rng.getrandbits(LINE_BITS)
    d1 = rng.getrandbits(LINE_BITS)
    await drv.request(0, True, a0, d0)
    await drv.request(0, True, a1, d1)   # immediately follows, no gap
    g1 = await drv.request(0, False, a1)
    g0 = await drv.request(0, False, a0)
    assert g0 == d0, f"a0 got {g0:#x} exp {d0:#x}"
    assert g1 == d1, f"a1 got {g1:#x} exp {d1:#x}"
    mem.stop = True


@cocotb.test()
async def test_l2_eviction(dut):
    """WAYS+1 lines into one set force a dirty writeback + later refill."""
    rng, mem, drv = await _setup(dut, seed=3)
    # same bank(0) + index(1) -> same set; 9 tags exceed the 8 ways.
    a = [addr_for(0, 1, 0x300 + t) for t in range(9)]
    d = [rng.getrandbits(LINE_BITS) for _ in a]
    for ai, di in zip(a, d):
        await drv.request(0, True, ai, di)
    # Read all back; at least one was evicted and must refill byte-exact.
    for ai, di in zip(a, d):
        got = await drv.request(0, False, ai)
        assert got == di, f"line {ai:#x}: got {got:#x} exp {di:#x}"
    mem.stop = True


@cocotb.test()
async def test_l2_parallel_slices(dut):
    """Both slices driven concurrently stay independent."""
    rng, mem, drv = await _setup(dut, seed=4)
    a0 = addr_for(0, 0, 0x400)
    a1 = addr_for(0, 0, 0x401)
    d0 = rng.getrandbits(LINE_BITS)
    d1 = rng.getrandbits(LINE_BITS)
    t0 = cocotb.start_soon(drv.request(0, True, a0, d0))
    t1 = cocotb.start_soon(drv.request(1, True, a1, d1))
    await t0
    await t1
    g0 = await drv.request(0, False, a0)
    g1 = await drv.request(1, False, a1)
    assert g0 == d0, f"slice0 got {g0:#x} exp {d0:#x}"
    assert g1 == d1, f"slice1 got {g1:#x} exp {d1:#x}"
    mem.stop = True
