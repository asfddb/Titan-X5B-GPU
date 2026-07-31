# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_apex_hbm4_ctrl -- multi-channel HBM4 front-end.

8 x 1024-bit channels rather than one 8192-bit bus, because a single bus that
wide does not work: titan_x5_l2_mem_adapter's WORDS = LINE_BYTES*8/DATA_WIDTH
truncates to 0 above 1024 bits on a 128-byte line, and 1024 is already one
full line per beat.

Properties under test:
  1. Address interleaving -- consecutive lines go to DIFFERENT channels, which
     is the whole point. If they all landed in one channel the bandwidth
     would be a single channel's.
  2. Every request eventually gets exactly one response, with the RIGHT tag
     and the right data.
  3. Responses come back out of order across channels, and the tag is what
     makes that safe. The model deliberately returns channels out of order.
  4. Back-pressure: a full tag queue must stall its channel, not drop or
     duplicate requests.
  5. Extremes -- all-zeros and all-ones data, address 0 and the top of the
     address space.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly

from tb_common import start_clock_and_reset

ADDR_WIDTH = 40
LINE_BYTES = 128
LINE_BITS = LINE_BYTES * 8
NUM_CH = 8
TAG_WIDTH = 8
OFFSET = 7
CH_BITS = 3
LINE_MASK = ((1 << LINE_BITS) - 1)


def ch_of(addr):
    return (addr >> OFFSET) & (NUM_CH - 1)


class Channels:
    """Model of NUM_CH independent memory channels.

    Latency is deliberately different per channel and randomised, so
    responses genuinely arrive out of order and the tag path is exercised
    rather than accidentally being in-order.
    """

    def __init__(self, dut, rng):
        self.dut = dut
        self.rng = rng
        self.mem = {}
        self.inflight = [[] for _ in range(NUM_CH)]   # [(countdown, data)]
        self.stop = False
        self.served = [0] * NUM_CH

    async def run(self):
        d = self.dut
        d.ch_req_ready.value = (1 << NUM_CH) - 1
        d.ch_resp_valid.value = 0
        d.ch_resp_rdata.value = 0
        while not self.stop:
            await ReadOnly()
            rv = int(d.ch_req_valid.value)
            rw = int(d.ch_req_write.value)
            ra = int(d.ch_req_addr.value)
            rd = int(d.ch_req_wdata.value)
            rr = int(d.ch_resp_ready.value)
            rdy = int(d.ch_req_ready.value)

            accepted = []
            for c in range(NUM_CH):
                if (rv >> c) & 1 and (rdy >> c) & 1:
                    a = (ra >> (c * ADDR_WIDTH)) & ((1 << ADDR_WIDTH) - 1)
                    w = (rw >> c) & 1
                    dat = (rd >> (c * LINE_BITS)) & LINE_MASK
                    accepted.append((c, a, w, dat))

            # which pending responses are being consumed this cycle
            consumed = [c for c in range(NUM_CH)
                        if (rr >> c) & 1 and self.inflight[c]
                        and self.inflight[c][0][0] <= 0]

            await RisingEdge(d.clk)

            for c, a, w, dat in accepted:
                if w:
                    self.mem[a] = dat
                    self.inflight[c].append([self.rng.randint(0, 6), 0])
                else:
                    self.inflight[c].append(
                        [self.rng.randint(0, 6), self.mem.get(a, 0)])

            for c in consumed:
                self.inflight[c].pop(0)
                self.served[c] += 1

            # advance countdowns and present whatever is ready
            valid = 0
            data = 0
            for c in range(NUM_CH):
                if self.inflight[c]:
                    if self.inflight[c][0][0] > 0:
                        self.inflight[c][0][0] -= 1
                    if self.inflight[c][0][0] <= 0:
                        valid |= 1 << c
                        data |= self.inflight[c][0][1] << (c * LINE_BITS)
            d.ch_resp_valid.value = valid
            d.ch_resp_rdata.value = data
            # occasionally throttle a channel's request port
            mask = (1 << NUM_CH) - 1
            if self.rng.random() < 0.2:
                mask &= ~(1 << self.rng.randrange(NUM_CH))
            d.ch_req_ready.value = mask


async def idle(dut):
    dut.req_valid.value = 0
    dut.req_write.value = 0
    dut.req_addr.value = 0
    dut.req_wdata.value = 0
    dut.req_tag.value = 0
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def hbm4_interleaves_consecutive_lines(dut):
    """1. Consecutive cache lines must land in different channels."""
    rng = random.Random(0x4B4)
    await start_clock_and_reset(dut)
    ch = Channels(dut, rng)
    cocotb.start_soon(ch.run())
    await idle(dut)

    seen = []
    for i in range(NUM_CH):
        addr = i * LINE_BYTES
        dut.req_valid.value = 1
        dut.req_write.value = 1
        dut.req_addr.value = addr
        dut.req_wdata.value = i + 1
        dut.req_tag.value = i
        while True:
            await ReadOnly()
            rdy = int(dut.req_ready.value)
            cv = int(dut.ch_req_valid.value)
            await RisingEdge(dut.clk)
            if rdy:
                assert cv != 0, "request accepted but no channel selected"
                seen.append(cv.bit_length() - 1)
                break
        dut.req_valid.value = 0
        await ClockCycles(dut.clk, 1)

    assert sorted(seen) == list(range(NUM_CH)), (
        f"consecutive lines hit channels {seen}; expected each of "
        f"0..{NUM_CH-1} exactly once -- interleaving is broken, so all "
        f"streaming bandwidth would come from one channel")
    dut._log.info(f"consecutive lines interleave across all {NUM_CH} channels: {seen}")


@cocotb.test()
async def hbm4_every_request_gets_its_tag_back(dut):
    """2+3+5. Tags and data survive out-of-order return, incl. extremes."""
    rng = random.Random(0x7A6)
    await start_clock_and_reset(dut)
    ch = Channels(dut, rng)
    cocotb.start_soon(ch.run())
    await idle(dut)
    dut.req_valid.value = 0

    ALL1 = LINE_MASK
    TOP = ((1 << ADDR_WIDTH) - 1) & ~(LINE_BYTES - 1)
    writes = [(0, 0), (LINE_BYTES, ALL1), (TOP, ALL1),
              (5 * LINE_BYTES, 0xDEADBEEF), (9 * LINE_BYTES, 1)]
    for k, (a, d) in enumerate(writes):
        writes[k] = (a, d)

    expect = {}
    tag = 0
    sent = []

    got = {}
    order = []

    async def send(addr, write, data, t):
        dut.req_valid.value = 1
        dut.req_write.value = 1 if write else 0
        dut.req_addr.value = addr
        dut.req_wdata.value = data
        dut.req_tag.value = t
        while True:
            await ReadOnly()
            ok = int(dut.req_ready.value)
            # Responses arrive WHILE we are still issuing, and channels are
            # independent so they do not wait for the request stream to
            # finish. Not draining here loses them -- which is exactly how
            # the first version of this test reported "7 responses for 10
            # requests" against a controller that was actually correct.
            if int(dut.resp_valid.value):
                rt = int(dut.resp_tag.value)
                got[rt] = int(dut.resp_rdata.value)
                order.append(rt)
            await RisingEdge(dut.clk)
            if ok:
                break
        dut.req_valid.value = 0

    # write then read every address back
    for a, d in writes:
        await send(a, True, d, tag)
        sent.append(tag)
        tag = (tag + 1) & 0xFF
    for a, d in writes:
        await send(a, False, 0, tag)
        expect[tag] = d
        sent.append(tag)
        tag = (tag + 1) & 0xFF

    for _ in range(4000):
        await ReadOnly()
        if int(dut.resp_valid.value):
            t = int(dut.resp_tag.value)
            got[t] = int(dut.resp_rdata.value)
            order.append(t)
        await RisingEdge(dut.clk)
        if len(order) >= len(sent):
            break

    assert len(order) == len(sent), (
        f"{len(order)} responses for {len(sent)} requests -- requests were "
        f"dropped or duplicated")
    assert sorted(order) == sorted(sent), \
        f"tag mismatch: got {sorted(order)}, sent {sorted(sent)}"
    for t, want in expect.items():
        assert got[t] == want, (
            f"tag {t}: data {got[t]:#x}, expected {want:#x}")

    in_order = (order == sent)
    dut._log.info(
        f"{len(sent)} requests, every tag returned exactly once, data exact "
        f"(incl. all-zeros, all-ones, address 0 and top-of-space); "
        f"return order was {'in order' if in_order else 'OUT OF ORDER'}")


@cocotb.test()
async def hbm4_backpressure_never_loses_a_request(dut):
    """4. Under heavy random traffic nothing is dropped or duplicated."""
    rng = random.Random(0xBEEF)
    await start_clock_and_reset(dut)
    ch = Channels(dut, rng)
    cocotb.start_soon(ch.run())
    await idle(dut)

    N = 120
    sent = []
    tag = 0
    pending = 0
    got = []

    for i in range(N):
        addr = (rng.randrange(64) * LINE_BYTES)
        dut.req_valid.value = 1
        dut.req_write.value = 1
        dut.req_addr.value = addr
        dut.req_wdata.value = rng.getrandbits(64)
        dut.req_tag.value = tag
        while True:
            await ReadOnly()
            ok = int(dut.req_ready.value)
            if int(dut.resp_valid.value):
                got.append(int(dut.resp_tag.value))
            await RisingEdge(dut.clk)
            if ok:
                break
        sent.append(tag)
        tag = (tag + 1) & 0xFF
        dut.req_valid.value = 0

    for _ in range(6000):
        await ReadOnly()
        if int(dut.resp_valid.value):
            got.append(int(dut.resp_tag.value))
        await RisingEdge(dut.clk)
        if len(got) >= N:
            break

    assert len(got) == N, f"{len(got)} responses for {N} requests"
    assert sorted(got) == sorted(sent), "tags dropped or duplicated"
    dut._log.info(
        f"{N} requests under randomised channel back-pressure: all returned "
        f"exactly once, per-channel service counts {ch.served}")
