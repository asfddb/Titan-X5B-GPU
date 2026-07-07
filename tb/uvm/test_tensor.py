# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x6_wmma_dispatch (+ 16x16 output-stationary tensor array) tests.

Full WMMA ops through the warp-synchronous dispatcher at the default
(M,N,K) = (16,16,16): INT8 SIMD (512 MACs/cycle), native FP8 E4M3 and
E5M2, and FP16 - every C element compared bit-exactly against
tensor_ref.wmma_golden. Also checks the warp barrier: issue must not fire
until all 32 lanes have deposited fragments.
"""

import random

import cocotb
from cocotb.triggers import FallingEdge, ClockCycles, Timer

from tb_common import start_clock_and_reset
from tensor_ref import wmma_golden

M = N = K = 16


async def write_frags(dut, A, B, hold_lane=None):
    """Deposit all fragments, one per cycle. If hold_lane is set, skip that
    lane's writes (to test the warp barrier) and return them for later."""
    held = []
    idx = 0
    for mat, mat_sel, rows, cols in ((A, 0, M, K), (B, 1, K, N)):
        for r in range(rows):
            for c in range(cols):
                lane = idx % 32
                idx += 1
                if hold_lane is not None and lane == hold_lane:
                    held.append((mat_sel, r, c, mat[r][c], lane))
                    continue
                await FallingEdge(dut.clk)
                dut.frag_wr_valid.value = 1
                dut.frag_wr_matrix.value = mat_sel
                dut.frag_wr_row.value = r
                dut.frag_wr_col.value = c
                dut.frag_wr_data.value = mat[r][c]
                dut.frag_wr_lane.value = lane
    await FallingEdge(dut.clk)
    dut.frag_wr_valid.value = 0
    return held


async def run_wmma(dut, A, B, mode, fmt):
    """Write fragments, issue, wait for done, read back C."""
    await write_frags(dut, A, B)

    await FallingEdge(dut.clk)
    assert int(dut.wmma_issue_ready.value) == 1, "all lanes arrived -> ready"
    dut.wmma_issue_valid.value = 1
    dut.wmma_mode.value = mode
    dut.wmma_fp8_fmt.value = fmt
    await FallingEdge(dut.clk)
    dut.wmma_issue_valid.value = 0
    assert int(dut.busy.value) == 1

    for _ in range(K + M + N + M + 10):
        await FallingEdge(dut.clk)
        if int(dut.wmma_done.value):
            break
    else:
        raise AssertionError("wmma_done never pulsed")

    C = [[0] * N for _ in range(M)]
    for i in range(M):
        for j in range(N):
            dut.c_rd_row.value = i
            dut.c_rd_col.value = j
            await Timer(1, "ns")
            C[i][j] = int(dut.c_rd_data.value)
    return C


def compare(C, ref, label):
    bad = 0
    for i in range(M):
        for j in range(N):
            if C[i][j] != ref[i][j]:
                if bad < 8:
                    print(f"{label} C[{i}][{j}] = {C[i][j]:#010x} "
                          f"expected {ref[i][j]:#010x}")
                bad += 1
    assert bad == 0, f"{label}: {bad}/{M*N} elements mismatched"


def init(dut):
    dut.frag_wr_valid.value = 0
    dut.wmma_issue_valid.value = 0
    dut.frag_wr_matrix.value = 0
    dut.frag_wr_row.value = 0
    dut.frag_wr_col.value = 0
    dut.frag_wr_data.value = 0
    dut.frag_wr_lane.value = 0
    dut.wmma_mode.value = 0
    dut.wmma_fp8_fmt.value = 0
    dut.c_rd_row.value = 0
    dut.c_rd_col.value = 0


@cocotb.test()
async def test_int8_matmul(dut):
    """16x16x16 dual-INT8 WMMA (512 MACs/streaming cycle), bit-exact."""
    init(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(0x1817)
    for trial in range(2):
        A = [[rng.randrange(0, 1 << 16) for _ in range(K)] for _ in range(M)]
        B = [[rng.randrange(0, 1 << 16) for _ in range(N)] for _ in range(K)]
        C = await run_wmma(dut, A, B, mode=3, fmt=0)
        compare(C, wmma_golden(A, B, M, N, K, 3), f"int8 trial {trial}")
    dut._log.info("int8: 2 full 16x16x16 WMMA ops bit-exact "
                  "(effective K=32 with SIMD pairs)")


@cocotb.test()
async def test_fp8_e4m3_matmul(dut):
    """Native FP8 E4M3 WMMA, bit-exact vs the exact-product golden."""
    init(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(0xE4E3)
    A = [[rng.randrange(0, 256) for _ in range(K)] for _ in range(M)]
    B = [[rng.randrange(0, 256) for _ in range(N)] for _ in range(K)]
    C = await run_wmma(dut, A, B, mode=1, fmt=0)
    compare(C, wmma_golden(A, B, M, N, K, 1, 0), "fp8 e4m3")


@cocotb.test()
async def test_fp8_e5m2_matmul(dut):
    """Native FP8 E5M2 WMMA (Inf/NaN encodings flushed), bit-exact."""
    init(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(0xE5E2)
    A = [[rng.randrange(0, 256) for _ in range(K)] for _ in range(M)]
    B = [[rng.randrange(0, 256) for _ in range(N)] for _ in range(K)]
    C = await run_wmma(dut, A, B, mode=1, fmt=1)
    compare(C, wmma_golden(A, B, M, N, K, 1, 1), "fp8 e5m2")


@cocotb.test()
async def test_fp16_matmul(dut):
    """FP16 WMMA with mid-range exponents (no overflow/denormal products)."""
    init(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(0x1616)

    def rnd16():
        # exponent field 10..20 -> values ~2^-5..2^5, products stay normal
        return (rng.randrange(0, 2) << 15) | (rng.randrange(10, 21) << 10) \
            | rng.randrange(0, 1 << 10)

    A = [[rnd16() for _ in range(K)] for _ in range(M)]
    B = [[rnd16() for _ in range(N)] for _ in range(K)]
    C = await run_wmma(dut, A, B, mode=0, fmt=0)
    compare(C, wmma_golden(A, B, M, N, K, 0), "fp16")


@cocotb.test()
async def test_warp_barrier(dut):
    """Issue must be blocked until every lane has arrived."""
    init(dut)
    await start_clock_and_reset(dut)
    rng = random.Random(0xBA44)
    A = [[rng.randrange(0, 1 << 16) for _ in range(K)] for _ in range(M)]
    B = [[rng.randrange(0, 1 << 16) for _ in range(N)] for _ in range(K)]

    held = await write_frags(dut, A, B, hold_lane=17)
    await FallingEdge(dut.clk)
    assert int(dut.wmma_issue_ready.value) == 0, \
        "issue_ready must stay low with lane 17 missing"
    assert int(dut.lane_arrival_mask.value) == 0xFFFFFFFF ^ (1 << 17)

    # request queued but barred
    dut.wmma_issue_valid.value = 1
    dut.wmma_mode.value = 3
    await ClockCycles(dut.clk, 5)
    assert int(dut.busy.value) == 0, "op must not launch before the barrier"

    # lane 17 deposits its fragments; the arrival mark (frag_wr_lane=17)
    # rides only the LAST write - a lane arrives when its final fragment
    # lands, so the barrier must hold until then
    for fi, (mat_sel, r, c, data, lane) in enumerate(held):
        await FallingEdge(dut.clk)
        dut.frag_wr_valid.value = 1
        dut.frag_wr_matrix.value = mat_sel
        dut.frag_wr_row.value = r
        dut.frag_wr_col.value = c
        dut.frag_wr_data.value = data
        dut.frag_wr_lane.value = lane if fi == len(held) - 1 else 16
        if fi == len(held) - 2:
            # every fragment but one is in: barrier must still hold
            assert int(dut.busy.value) == 0
    await FallingEdge(dut.clk)
    dut.frag_wr_valid.value = 0

    for _ in range(K + M + N + M + 10):
        await FallingEdge(dut.clk)
        if int(dut.busy.value):
            break
    else:
        raise AssertionError("op never launched after barrier release")
    dut.wmma_issue_valid.value = 0

    for _ in range(K + M + N + M + 10):
        await FallingEdge(dut.clk)
        if int(dut.wmma_done.value):
            break
    else:
        raise AssertionError("wmma_done never pulsed")

    C = [[0] * N for _ in range(M)]
    for i in range(M):
        for j in range(N):
            dut.c_rd_row.value = i
            dut.c_rd_col.value = j
            await Timer(1, "ns")
            C[i][j] = int(dut.c_rd_data.value)
    compare(C, wmma_golden(A, B, M, N, K, 3), "barrier-released int8")
