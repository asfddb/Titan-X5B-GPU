# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Transaction-based verification of the coalescing LSU (titan_x5_lsu).

Environment:
  - WarpDriver     : drives warp-wide requests on the core port.
  - LineMemoryModel: services the line port with randomized backpressure
                     and latency; monitors every accepted transaction.
  - Scoreboard     : a byte-accurate reference memory. Checks
      * per-lane load data (inactive lanes must return 0),
      * store byte enables / merged write data (higher lane wins),
      * coalescing OPTIMALITY: the set of issued line addresses must equal
        the set of distinct lines referenced by active lanes - no more,
        no fewer, no duplicates - and warp_resp_xactions must match.

Stimulus: directed corner patterns, constrained-random warps, and an
optional external corpus (tb/vectors/lsu_patterns.json).
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly

from tb_common import start_clock_and_reset, load_vectors, deterministic_line
from coverage_util import sample_lsu_warp, export_on_exit

export_on_exit("lsu")

NUM_LANES = 32
LINE_BYTES = 128
ADDR_MASK = ~(LINE_BYTES - 1) & 0xFFFFFFFF


class LineMemoryModel:
    """Backing memory + line-port driver + transaction monitor."""

    def __init__(self, dut, rng):
        self.dut = dut
        self.rng = rng
        self.mem = {}          # line_addr -> int (LINE_BYTES*8 bits)
        self.transactions = [] # (addr, write, wdata, be) per accepted req
        self.stall_count = 0   # cycles a line request waited on backpressure
        self.stop = False

    def line(self, addr):
        base = addr & ADDR_MASK
        if base not in self.mem:
            self.mem[base] = deterministic_line(base, LINE_BYTES)
        return self.mem[base]

    def read_word(self, addr):
        base = addr & ADDR_MASK
        off = (addr & (LINE_BYTES - 1)) >> 2
        return (self.line(base) >> (off * 32)) & 0xFFFFFFFF

    def apply_write(self, addr, wdata, be):
        base = addr & ADDR_MASK
        cur = self.line(base)
        for b in range(LINE_BYTES):
            if (be >> b) & 1:
                byte = (wdata >> (b * 8)) & 0xFF
                cur = (cur & ~(0xFF << (b * 8))) | (byte << (b * 8))
        self.mem[base] = cur

    async def run(self):
        """valid/ready protocol driver.

        Each iteration: decide ready for the upcoming edge, sample the
        request fields in the ReadOnly phase (NBA-stable), and treat the
        edge where both ready and valid were high as the acceptance.
        """
        dut = self.dut
        dut.mem_req_ready.value = 0
        dut.mem_resp_valid.value = 0
        dut.mem_resp_rdata.value = 0
        while not self.stop:
            ready = self.rng.random() < 0.7
            dut.mem_req_ready.value = 1 if ready else 0
            await ReadOnly()
            valid = int(dut.mem_req_valid.value) == 1
            if valid and not ready:
                self.stall_count += 1  # backpressure (skid) coverage
            if valid and ready:
                addr = int(dut.mem_req_addr.value)
                write = int(dut.mem_req_write.value)
                wdata = int(dut.mem_req_wdata.value)
                be = int(dut.mem_req_be.value)
            await RisingEdge(dut.clk)  # acceptance edge (if valid & ready)
            if valid and ready:
                assert addr % LINE_BYTES == 0, \
                    f"line request not {LINE_BYTES}B aligned: {addr:#x}"
                self.transactions.append((addr, write, wdata, be))
                if write:
                    assert be != 0, "store transaction with empty byte enables"
                    self.apply_write(addr, wdata, be)
                else:
                    data = self.line(addr)
                    dut.mem_req_ready.value = 0
                    for _ in range(self.rng.randint(1, 4)):
                        await RisingEdge(dut.clk)
                    dut.mem_resp_valid.value = 1
                    dut.mem_resp_rdata.value = data
                    await RisingEdge(dut.clk)
                    dut.mem_resp_valid.value = 0


def expected_lines(mask, addrs):
    return {addrs[i] & ADDR_MASK for i in range(NUM_LANES) if (mask >> i) & 1}


def pack(vals, width):
    out = 0
    for i, v in enumerate(vals):
        out |= (v & ((1 << width) - 1)) << (i * width)
    return out


async def drive_warp(dut, mem, sb_mem_read, wid, write, mask, addrs, wdata):
    """Issue one warp request and fully check the response."""
    n_before = len(mem.transactions)

    dut.warp_req_valid.value = 1
    dut.warp_req_wid.value = wid
    dut.warp_req_write.value = 1 if write else 0
    dut.warp_req_mask.value = mask
    dut.warp_req_addr.value = pack(addrs, 32)
    dut.warp_req_wdata.value = pack(wdata, 32)

    # wait for acceptance: sample ready in the ReadOnly phase of the same
    # edge at which the DUT samples valid
    stall_base = mem.stall_count
    for _ in range(1000):
        await ReadOnly()
        accepted = int(dut.warp_req_ready.value) == 1
        await RisingEdge(dut.clk)
        if accepted:
            break
    else:
        raise AssertionError("LSU never accepted the warp request")
    dut.warp_req_valid.value = 0

    # expected data snapshot for loads (memory can't change concurrently:
    # one warp in flight at a time)
    exp_words = None
    if not write:
        exp_words = [mem.read_word(addrs[i]) if (mask >> i) & 1 else 0
                     for i in range(NUM_LANES)]

    # wait for the response pulse (sampled in the ReadOnly phase so the
    # single-cycle pulse cannot be lost to the read-after-edge race)
    got_wid = got_x = got_rdata = None
    for _ in range(20000):
        await ReadOnly()
        if int(dut.warp_resp_valid.value) == 1:
            got_wid = int(dut.warp_resp_wid.value)
            got_x = int(dut.warp_resp_xactions.value)
            got_rdata = int(dut.warp_resp_rdata.value)
        await RisingEdge(dut.clk)
        if got_wid is not None:
            break
    else:
        raise AssertionError("LSU response timeout")

    assert got_wid == wid, f"warp id mismatch: {got_wid} != {wid}"

    exp_line_set = expected_lines(mask, addrs)
    new_tx = mem.transactions[n_before:]
    tx_lines = [t[0] for t in new_tx]

    # --- coalescing optimality assertions ---
    assert len(tx_lines) == len(set(tx_lines)), \
        f"duplicate line transactions issued: {[hex(a) for a in tx_lines]}"
    assert set(tx_lines) == exp_line_set, \
        (f"coalescing mismatch: issued {sorted(hex(a) for a in tx_lines)} "
         f"expected {sorted(hex(a) for a in exp_line_set)}")
    assert got_x == len(exp_line_set), \
        f"xaction count {got_x} != optimal {len(exp_line_set)}"

    sample_lsu_warp(mask, got_x, write, mem.stall_count - stall_base)

    if write:
        # per-transaction byte enables / data already applied to the model
        # by the monitor; verify the union of enables matches the lanes
        exp_be = {}
        exp_bytes = {}
        for i in range(NUM_LANES):  # ascending: higher lane wins conflicts
            if (mask >> i) & 1:
                a = addrs[i]
                base = a & ADDR_MASK
                off = (a & (LINE_BYTES - 1)) & ~3
                for b in range(4):
                    exp_be.setdefault(base, set()).add(off + b)
                    exp_bytes[(base, off + b)] = (wdata[i] >> (b * 8)) & 0xFF
        for (addr, w, wd, be) in new_tx:
            assert w == 1, "read transaction during a store warp"
            got_be = {b for b in range(LINE_BYTES) if (be >> b) & 1}
            assert got_be == exp_be[addr], \
                f"byte-enable mismatch @{addr:#x}"
            for b in got_be:
                got_byte = (wd >> (b * 8)) & 0xFF
                assert got_byte == exp_bytes[(addr, b)], \
                    (f"store data mismatch @{addr:#x} byte {b}: "
                     f"{got_byte:#x} != {exp_bytes[(addr, b)]:#x}")
        # cross-check the reference memory too
        for i in range(NUM_LANES):
            if (mask >> i) & 1:
                pass  # covered by byte-level checks above
    else:
        for i in range(NUM_LANES):
            got = (got_rdata >> (i * 32)) & 0xFFFFFFFF
            assert got == exp_words[i], \
                (f"lane {i} load data mismatch @{addrs[i]:#x}: "
                 f"{got:#x} != {exp_words[i]:#x}")
        for (_, w, _, _) in new_tx:
            assert w == 0, "write transaction during a load warp"


def directed_patterns(rng):
    """Corner-case warp patterns: (name, mask, addrs, expected_optimal)."""
    pats = []
    base = 0x0001_0000

    # fully converged: 32 sequential words in one line -> 1 transaction
    pats.append(("converged", 0xFFFFFFFF,
                 [base + 4 * i for i in range(32)]))
    # broadcast: all lanes hit the same address -> 1 transaction
    pats.append(("broadcast", 0xFFFFFFFF, [base + 64] * 32))
    # stride-2: spans exactly 2 lines
    pats.append(("stride2", 0xFFFFFFFF,
                 [base + 8 * i for i in range(32)]))
    # line straddle: half in line N, half in line N+1
    pats.append(("straddle", 0xFFFFFFFF,
                 [base + 64 + 4 * i for i in range(32)]))
    # fully scattered: 32 distinct lines -> 32 transactions
    pats.append(("scatter", 0xFFFFFFFF,
                 [base + LINE_BYTES * i for i in range(32)]))
    # reverse order lanes
    pats.append(("reverse", 0xFFFFFFFF,
                 [base + 4 * (31 - i) for i in range(32)]))
    # single lane
    pats.append(("single_lane", 1 << 17,
                 [base + 4 * i for i in range(32)]))
    # alternating mask
    pats.append(("alternating", 0x55555555,
                 [base + 4 * i for i in range(32)]))
    # empty mask (fully predicated off)
    pats.append(("empty_mask", 0x00000000,
                 [base + 4 * i for i in range(32)]))
    # broadcast with one outlier
    addrs = [base] * 32
    addrs[31] = base + 0x4000
    pats.append(("outlier", 0xFFFFFFFF, addrs))
    # same-word store conflicts (higher lane must win)
    pats.append(("conflict", 0xFFFFFFFF, [base + 4 * (i % 4) for i in range(32)]))
    return pats


@cocotb.test()
async def test_lsu_coalescing(dut):
    rng = random.Random(0xC0A1E5CE)
    await start_clock_and_reset(dut)

    mem = LineMemoryModel(dut, rng)
    cocotb.start_soon(mem.run())

    dut.warp_req_valid.value = 0

    # --- directed phase (each pattern as load and store) ---
    for name, mask, addrs in directed_patterns(rng):
        for write in (False, True):
            wdata = [rng.getrandbits(32) for _ in range(32)]
            await drive_warp(dut, mem, None, rng.randrange(8), write,
                             mask, addrs, wdata)
    dut._log.info("LSU directed patterns passed")

    # --- external corpus (Antigravity), if present ---
    corpus = load_vectors("lsu_patterns.json")
    n_corpus = 0
    if corpus:
        for entry in corpus:
            try:
                mask = int(entry["mask"], 0) & 0xFFFFFFFF
                addrs = [int(a, 0) & 0xFFFFFFFC for a in entry["addrs"]][:32]
                write = bool(entry.get("write", 0))
            except (KeyError, ValueError, TypeError):
                continue
            if len(addrs) < 32:
                addrs += [addrs[-1] if addrs else 0x1000] * (32 - len(addrs))
            wdata = [rng.getrandbits(32) for _ in range(32)]
            await drive_warp(dut, mem, None, rng.randrange(8), write,
                             mask, addrs, wdata)
            n_corpus += 1
        dut._log.info("LSU external corpus: %d patterns passed", n_corpus)

    # --- constrained-random phase ---
    for trial in range(150):
        style = rng.randrange(4)
        if style == 0:      # tight pool: heavy coalescing + conflicts
            pool = 0x0002_0000
            addrs = [pool + 4 * rng.randrange(64) for _ in range(32)]
        elif style == 1:    # medium pool: mixed
            pool = 0x0003_0000
            addrs = [pool + 4 * rng.randrange(1024) for _ in range(32)]
        elif style == 2:    # scattered
            addrs = [0x0010_0000 + LINE_BYTES * rng.randrange(4096)
                     for _ in range(32)]
        else:               # sequential with random base (line straddling)
            b = 0x0004_0000 + 4 * rng.randrange(256)
            addrs = [b + 4 * i for i in range(32)]
        mask = rng.getrandbits(32) if rng.random() < 0.7 else 0xFFFFFFFF
        write = rng.random() < 0.5
        wdata = [rng.getrandbits(32) for _ in range(32)]
        await drive_warp(dut, mem, None, rng.randrange(8), write,
                         mask, addrs, wdata)

    mem.stop = True
    dut._log.info("LSU: %d line transactions issued across all phases",
                  len(mem.transactions))
