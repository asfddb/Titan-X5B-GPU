# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x6_vram_ctrl verification: AXI4 master FSM against a Python AXI-slave
memory model.

DUT: tb_vram_top - two controllers, u_dut2 (2 beats/line) and u_dut4 (4
beats/line), so every test runs at both burst lengths and proves the
BEATS_PER_LINE generalization.

Checks:
  1. Read/write correctness: written lines read back byte-exact; response id
     preserved; reads return the AXI-slave backing data reassembled from all
     beats in the right order.
  2. Burst framing: ARLEN/AWLEN == beats-1, ARSIZE/AWSIZE == log2(bus bytes),
     INCR burst, and WLAST asserted on exactly the final W beat.
  3. Backpressure: randomized AR/AW/W ready deassertion and R/B stalls; no
     beat is ever dropped and all data stays correct under heavy stalling.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly

from tb_common import start_clock_and_reset, deterministic_line

AXI_DATA_WIDTH = 512
AXI_BYTES = AXI_DATA_WIDTH // 8
EXPECTED_SIZE = (AXI_BYTES).bit_length() - 1  # log2(64) = 6


class AxiMemSlave:
    """AXI4 slave + backing memory for one titan_x6_vram_ctrl instance."""

    def __init__(self, dut, inst, line_bytes, rng, bp=0.0):
        self.dut = dut
        self.inst = inst
        self.line_bytes = line_bytes
        self.line_bits = line_bytes * 8
        self.beats = self.line_bits // AXI_DATA_WIDTH
        self.rng = rng
        self.bp = bp          # ready-deassert / stall probability
        self.mem = {}
        self.stop = False
        self.errors = []

    def line(self, addr):
        base = addr
        if base not in self.mem:
            self.mem[base] = deterministic_line(base, self.line_bytes)
        return self.mem[base]

    def _init(self):
        i = self.inst
        i.m_axi_arready.value = 0
        i.m_axi_rvalid.value = 0
        i.m_axi_rdata.value = 0
        i.m_axi_rid.value = 0
        i.m_axi_rresp.value = 0
        i.m_axi_rlast.value = 0
        i.m_axi_awready.value = 0
        i.m_axi_wready.value = 0
        i.m_axi_bvalid.value = 0
        i.m_axi_bid.value = 0
        i.m_axi_bresp.value = 0

    async def run(self):
        i = self.inst
        clk = self.dut.clk
        self._init()
        while not self.stop:
            ar_rdy = self.rng.random() >= self.bp
            aw_rdy = self.rng.random() >= self.bp
            i.m_axi_arready.value = 1 if ar_rdy else 0
            i.m_axi_awready.value = 1 if aw_rdy else 0
            await ReadOnly()
            arv = int(i.m_axi_arvalid.value) == 1
            awv = int(i.m_axi_awvalid.value) == 1
            if arv and ar_rdy:
                a_addr = int(i.m_axi_araddr.value)
                a_len = int(i.m_axi_arlen.value)
                a_id = int(i.m_axi_arid.value)
                a_size = int(i.m_axi_arsize.value)
                a_burst = int(i.m_axi_arburst.value)
            if awv and aw_rdy:
                w_addr = int(i.m_axi_awaddr.value)
                w_len = int(i.m_axi_awlen.value)
                w_id = int(i.m_axi_awid.value)
                w_size = int(i.m_axi_awsize.value)
                w_burst = int(i.m_axi_awburst.value)
            await RisingEdge(clk)
            i.m_axi_arready.value = 0
            i.m_axi_awready.value = 0

            if arv and ar_rdy:
                self._check(a_len == self.beats - 1, f"ARLEN {a_len} != {self.beats-1}")
                self._check(a_size == EXPECTED_SIZE, f"ARSIZE {a_size} != {EXPECTED_SIZE}")
                self._check(a_burst == 1, f"ARBURST {a_burst} != INCR")
                await self._send_r(a_addr, a_id)
            elif awv and aw_rdy:
                self._check(w_len == self.beats - 1, f"AWLEN {w_len} != {self.beats-1}")
                self._check(w_size == EXPECTED_SIZE, f"AWSIZE {w_size} != {EXPECTED_SIZE}")
                self._check(w_burst == 1, f"AWBURST {w_burst} != INCR")
                await self._collect_w(w_addr, w_id)

    def _check(self, cond, msg):
        if not cond:
            self.errors.append(msg)

    async def _send_r(self, addr, rid):
        i = self.inst
        clk = self.dut.clk
        line = self.line(addr)
        mask = (1 << AXI_DATA_WIDTH) - 1
        for b in range(self.beats):
            # optional stall: hold rvalid low for a random gap
            while self.rng.random() < self.bp:
                i.m_axi_rvalid.value = 0
                await RisingEdge(clk)
            i.m_axi_rvalid.value = 1
            i.m_axi_rdata.value = (line >> (b * AXI_DATA_WIDTH)) & mask
            i.m_axi_rid.value = rid
            i.m_axi_rresp.value = 0
            i.m_axi_rlast.value = 1 if b == self.beats - 1 else 0
            while True:
                await ReadOnly()
                ready = int(i.m_axi_rready.value) == 1
                await RisingEdge(clk)
                if ready:
                    break
        i.m_axi_rvalid.value = 0
        i.m_axi_rlast.value = 0

    async def _collect_w(self, addr, wid):
        i = self.inst
        clk = self.dut.clk
        mask = (1 << AXI_DATA_WIDTH) - 1
        line = 0
        got = 0
        last_on_final = None
        while got < self.beats:
            rdy = self.rng.random() >= self.bp
            i.m_axi_wready.value = 1 if rdy else 0
            await ReadOnly()
            wv = int(i.m_axi_wvalid.value) == 1
            if wv and rdy:
                wd = int(i.m_axi_wdata.value) & mask
                wl = int(i.m_axi_wlast.value)
            await RisingEdge(clk)
            if wv and rdy:
                line |= wd << (got * AXI_DATA_WIDTH)
                # WLAST must be high iff this is the final beat.
                self._check((wl == 1) == (got == self.beats - 1),
                            f"WLAST={wl} on beat {got}/{self.beats}")
                got += 1
        i.m_axi_wready.value = 0
        self.mem[addr] = line
        # B response with optional backpressure already on bready side.
        i.m_axi_bvalid.value = 1
        i.m_axi_bid.value = wid
        i.m_axi_bresp.value = 0
        while True:
            await ReadOnly()
            ready = int(i.m_axi_bready.value) == 1
            await RisingEdge(clk)
            if ready:
                break
        i.m_axi_bvalid.value = 0


async def do_req(dut, inst, write, addr, wdata, rid):
    """Issue one request on the internal req interface; return (rdata, resp_id)."""
    clk = dut.clk
    inst.req_valid.value = 1
    inst.req_write.value = 1 if write else 0
    inst.req_addr.value = addr
    inst.req_wdata.value = wdata
    inst.req_id.value = rid
    # Acceptance handshake (req_valid & req_ready).
    for _ in range(2000):
        await ReadOnly()
        accepted = int(inst.req_ready.value) == 1
        await RisingEdge(clk)
        if accepted:
            inst.req_valid.value = 0
            break
    else:
        raise AssertionError("request never accepted")
    inst.req_valid.value = 0
    # Wait for the single-cycle response pulse.
    for _ in range(4000):
        await ReadOnly()
        if int(inst.resp_valid.value) == 1:
            resp_id = int(inst.resp_id.value)
            rdata = 0 if write else int(inst.resp_rdata.value)
            await RisingEdge(clk)
            return rdata, resp_id
        await RisingEdge(clk)
    raise AssertionError("response never arrived")


def _inst(dut, name):
    return getattr(dut, name)


async def _init_reqs(dut):
    for name in ("u_dut2", "u_dut4"):
        inst = _inst(dut, name)
        inst.req_valid.value = 0
        inst.req_write.value = 0
        inst.req_addr.value = 0
        inst.req_wdata.value = 0
        inst.req_id.value = 0


CONFIGS = [("u_dut2", 128), ("u_dut4", 256)]


async def _run_scenario(dut, bp, seed):
    rng = random.Random(seed)
    await _init_reqs(dut)
    await start_clock_and_reset(dut)

    slaves = {}
    for name, lb in CONFIGS:
        inst = _inst(dut, name)
        sl = AxiMemSlave(dut, inst, lb, random.Random(seed ^ hash(name) & 0xFFFF), bp=bp)
        slaves[name] = sl
        cocotb.start_soon(sl.run())
    await RisingEdge(dut.clk)

    for name, lb in CONFIGS:
        inst = _inst(dut, name)
        sl = slaves[name]
        line_bits = lb * 8
        line_mask = (1 << line_bits) - 1
        base = 0x2000_0000

        # --- writes then read-backs to distinct lines ---
        written = {}
        for k in range(6):
            addr = base + k * lb
            data = rng.getrandbits(line_bits)
            rid = (k + 1) & 0x1F
            _, resp_id = await do_req(dut, inst, True, addr, data, rid)
            assert resp_id == rid, f"{name}: write resp_id {resp_id} != {rid}"
            assert sl.mem[addr] == data, (
                f"{name}: mem[{addr:#x}] wrong: {sl.mem[addr]:#x} != {data:#x}")
            written[addr] = data

        for addr, data in written.items():
            rid = (addr & 0x1F)
            rdata, resp_id = await do_req(dut, inst, False, addr, 0, rid)
            assert rdata == (data & line_mask), (
                f"{name}: read {addr:#x} got {rdata:#x} exp {data:#x}")
            assert resp_id == rid, f"{name}: read resp_id {resp_id} != {rid}"

        # --- read of a never-written line returns slave's backing data ---
        raddr = base + 0x100 * lb
        exp = sl.line(raddr) & line_mask
        rdata, _ = await do_req(dut, inst, False, raddr, 0, 7)
        assert rdata == exp, f"{name}: cold read {raddr:#x} got {rdata:#x} exp {exp:#x}"

    for name, _ in CONFIGS:
        slaves[name].stop = True
    await RisingEdge(dut.clk)

    for name, sl in slaves.items():
        assert not sl.errors, f"{name} AXI protocol errors: {sl.errors}"


@cocotb.test()
async def test_vram_read_write_clean(dut):
    """Read/write correctness + burst framing with no backpressure."""
    await _run_scenario(dut, bp=0.0, seed=1)


@cocotb.test()
async def test_vram_backpressure(dut):
    """Same, but with heavy randomized AR/AW/W/R/B backpressure and stalls."""
    await _run_scenario(dut, bp=0.5, seed=2)
