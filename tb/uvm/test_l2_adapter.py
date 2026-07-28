# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_l2_mem_adapter verification, at 32-bit and 512-bit beat widths.

The adapter serialises a LINE_BYTES cache line onto a narrower memory path.
With a 32-bit beat and a 128-byte line that is 32 transactions per line, and
reads are issued one beat in flight at a time -- 32 sequential round trips to
fill a single cache line. Widening the beat to 512 bits makes it 2.

The module was already parameterised on DATA_WIDTH, but the beat address was
formed as `{..., word_cnt, 2'b00}` -- a hardcoded 4-byte stride. Any width
other than 32 therefore issued overlapping beats: at 512 bits the entire
128-byte line collapsed into the first 8 bytes. The stride is now
DATA_WIDTH/8, and this suite checks it at both widths.

Checks (run at whatever DW the wrapper was built with):
  1. Beat count is exactly LINE_BYTES*8/DW, for reads and writes.
  2. Write beats carry the correct slice of the line, in order.
  3. Beat addresses are base + i*(DW/8): contiguous, ascending, and
     non-overlapping -- the property the old hardcoded stride violated.
  4. The beats exactly tile the line: they span [base, base+LINE_BYTES)
     with no gap and no overlap.
  5. Reads reassemble the line byte-exact from the returned beats.
  6. Backpressure on xbar_req_ready does not corrupt or drop beats.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep

from tb_common import start_clock_and_reset


def cfg(dut):
    """Read the build configuration out of the wrapper."""
    dw = int(dut.cfg_data_width.value)
    line_bytes = int(dut.cfg_line_bytes.value)
    beats = int(dut.cfg_beats.value)
    assert beats == (line_bytes * 8) // dw
    return dw, line_bytes, beats


def idle(dut):
    dut.l2m_req_valid.value = 0
    dut.l2m_req_addr.value = 0
    dut.l2m_req_write.value = 0
    dut.l2m_req_wdata.value = 0
    dut.xbar_req_ready.value = 0
    dut.xbar_resp_valid.value = 0
    dut.xbar_resp_rdata.value = 0


async def collect_write(dut, addr, line, rng=None, stall_p=0.0):
    """Issue a line write; capture every beat the adapter emits."""
    dw, line_bytes, beats = cfg(dut)
    mask = (1 << dw) - 1

    dut.l2m_req_valid.value = 1
    dut.l2m_req_addr.value = addr
    dut.l2m_req_write.value = 1
    dut.l2m_req_wdata.value = line
    await RisingEdge(dut.clk)
    dut.l2m_req_valid.value = 0

    seen = []
    for _ in range(beats * 60 + 200):
        ready = 1 if (rng is None or rng.random() >= stall_p) else 0
        dut.xbar_req_ready.value = ready
        await ReadOnly()
        if int(dut.xbar_req_valid.value) and ready:
            assert int(dut.xbar_req_write.value) == 1, "write beat not marked write"
            seen.append((int(dut.xbar_req_addr.value),
                         int(dut.xbar_req_wdata.value) & mask))
        await RisingEdge(dut.clk)
        await NextTimeStep()
        if len(seen) == beats:
            break
    dut.xbar_req_ready.value = 0
    assert len(seen) == beats, (
        f"expected {beats} write beats, saw {len(seen)}")
    return seen


async def do_read(dut, addr, line, rng=None, stall_p=0.0):
    """Issue a line read, serving each beat from `line`; return assembled line."""
    dw, line_bytes, beats = cfg(dut)
    mask = (1 << dw) - 1

    dut.l2m_req_valid.value = 1
    dut.l2m_req_addr.value = addr
    dut.l2m_req_write.value = 0
    dut.l2m_req_wdata.value = 0
    await RisingEdge(dut.clk)
    dut.l2m_req_valid.value = 0

    seen_addrs = []
    got = None
    for _ in range(beats * 80 + 400):
        ready = 1 if (rng is None or rng.random() >= stall_p) else 0
        dut.xbar_req_ready.value = ready
        await ReadOnly()
        accepted = int(dut.xbar_req_valid.value) and ready
        a = int(dut.xbar_req_addr.value) if accepted else None
        if int(dut.l2m_resp_valid.value):
            got = int(dut.l2m_resp_rdata.value)
        await RisingEdge(dut.clk)
        await NextTimeStep()

        if accepted:
            seen_addrs.append(a)
            # serve this beat next cycle from the golden line
            i = len(seen_addrs) - 1
            dut.xbar_resp_valid.value = 1
            dut.xbar_resp_rdata.value = (line >> (i * dw)) & mask
        else:
            dut.xbar_resp_valid.value = 0
        if got is not None:
            break
    dut.xbar_req_ready.value = 0
    dut.xbar_resp_valid.value = 0
    assert got is not None, "no l2m_resp_valid for read"
    assert len(seen_addrs) == beats, (
        f"expected {beats} read beats, saw {len(seen_addrs)}")
    return seen_addrs, got


def check_tiling(addrs, base, dw, line_bytes, ctx):
    """Beats must tile [base, base+line_bytes) exactly: no gap, no overlap."""
    stride = dw // 8
    expected = [base + i * stride for i in range(len(addrs))]
    assert addrs == expected, (
        f"{ctx}: beat addresses wrong.\n  got {[hex(a) for a in addrs[:6]]}"
        f"\n  exp {[hex(a) for a in expected[:6]]}\n"
        f"  (stride should be {stride} bytes for a {dw}-bit beat)")
    assert len(set(addrs)) == len(addrs), f"{ctx}: duplicate beat addresses"
    span = max(addrs) + stride - base
    assert span == line_bytes, (
        f"{ctx}: beats span {span} bytes, line is {line_bytes} "
        f"-- beats do not tile the line")


@cocotb.test()
async def test_beat_count_matches_width(dut):
    """Beat count is exactly line_bits / DW, for both writes and reads."""
    idle(dut)
    await start_clock_and_reset(dut)
    dw, line_bytes, beats = cfg(dut)
    rng = random.Random(0x5EED)
    line = rng.getrandbits(line_bytes * 8)
    base = 0x4_0000_0000  # 16 GiB - exercises the wide physical address too

    w = await collect_write(dut, base, line)
    assert len(w) == beats
    ra, _ = await do_read(dut, base, line)
    assert len(ra) == beats

    dut._log.info(
        "DW=%d: %d-byte line -> %d beats per line (%d bytes/beat)",
        dw, line_bytes, beats, dw // 8)


@cocotb.test()
async def test_write_beats_address_and_data(dut):
    """Write beats carry the right slice at the right, non-overlapping address."""
    idle(dut)
    await start_clock_and_reset(dut)
    dw, line_bytes, beats = cfg(dut)
    rng = random.Random(1)
    mask = (1 << dw) - 1
    line = rng.getrandbits(line_bytes * 8)
    base = 0x1_2345_6700

    seen = await collect_write(dut, base, line)
    addrs = [a for a, _ in seen]
    check_tiling(addrs, base, dw, line_bytes, "write")

    for i, (_, data) in enumerate(seen):
        exp = (line >> (i * dw)) & mask
        assert data == exp, (
            f"write beat {i}: got {data:#x} exp {exp:#x}")

    dut._log.info("DW=%d: %d write beats tile the line correctly", dw, beats)


@cocotb.test()
async def test_read_reassembles_line(dut):
    """Read beats are addressed correctly and reassemble the line byte-exact."""
    idle(dut)
    await start_clock_and_reset(dut)
    dw, line_bytes, beats = cfg(dut)
    rng = random.Random(2)
    line = rng.getrandbits(line_bytes * 8)
    base = 0x10_0000_0000  # 64 GiB

    addrs, got = await do_read(dut, base, line)
    check_tiling(addrs, base, dw, line_bytes, "read")
    assert got == line, (
        f"read line mismatch:\n  got {got:#x}\n  exp {line:#x}")

    dut._log.info("DW=%d: line reassembled byte-exact from %d beats", dw, beats)


@cocotb.test()
async def test_backpressure(dut):
    """Random stalls on xbar_req_ready must not drop or corrupt beats."""
    idle(dut)
    await start_clock_and_reset(dut)
    dw, line_bytes, beats = cfg(dut)
    rng = random.Random(3)
    mask = (1 << dw) - 1

    for trial in range(3):
        line = rng.getrandbits(line_bytes * 8)
        base = 0x8_0000_0000 + trial * line_bytes
        seen = await collect_write(dut, base, line, rng=rng, stall_p=0.5)
        check_tiling([a for a, _ in seen], base, dw, line_bytes,
                     f"write under backpressure[{trial}]")
        for i, (_, data) in enumerate(seen):
            assert data == (line >> (i * dw)) & mask, \
                f"trial {trial} beat {i} corrupted under backpressure"

        addrs, got = await do_read(dut, base, line, rng=rng, stall_p=0.5)
        check_tiling(addrs, base, dw, line_bytes,
                     f"read under backpressure[{trial}]")
        assert got == line, f"trial {trial}: read corrupted under backpressure"

    dut._log.info("DW=%d: %d beats/line survive 50%% random backpressure",
                  dw, beats)
