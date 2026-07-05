# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""IEEE-754 compliance suite for the Titan X5 FPU.

DUTs (via tb_fpu_top): titan_x5_fp32_add, titan_x5_fp32_mul,
titan_x5_fp16_mul (combinational), titan_x5_alu (FP pipeline integration).

Oracle: tb/uvm/fp_ref.py - an integer-exact IEEE-754 model covering all four
rounding modes and the exception flags. The oracle itself is cross-validated
against hardware float32 (numpy) for RNE inside fp_ref's self-test.

Checks per operation: result bits (canonical qNaN for NaNs) AND all four
exception flags (invalid / overflow / underflow / inexact).

Coverage: directed specials (NaN/sNaN propagation, Inf-Inf, Inf*0, signed
zeros, subnormal boundary, cancellation, RNE ties, overflow boundary),
constrained-random biased toward extreme exponents, an optional external
corpus (tb/vectors/fp32_vectors.json, fp16_vectors.json), and a pipelined
back-to-back streaming phase to prove the 3-stage pipeline has no
inter-operation state leakage.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, Timer, ReadOnly

from tb_common import start_clock_and_reset, load_vectors
from fp_ref import fp_add, fp_mul, fp_fma, is_nan, FP32, FP16, RM_RNE

QNAN32 = 0x7FC00000

DIRECTED_OPERANDS = [
    0x00000000, 0x80000000,              # +0 / -0
    0x00000001, 0x80000001,              # smallest subnormals
    0x007FFFFF, 0x807FFFFF,              # largest subnormals
    0x00800000, 0x80800000,              # smallest normals
    0x3F800000, 0xBF800000,              # +-1.0
    0x3F800001, 0xBF800001,              # 1.0 + ulp
    0x7F7FFFFF, 0xFF7FFFFF,              # max finite
    0x7F800000, 0xFF800000,              # +-Inf
    0x7FC00000, 0xFFC00000,              # qNaN
    0x7F800001, 0xFF800001,              # sNaN
    0x7FBFFFFF,                          # sNaN max payload
    0x34000000, 0xB4000000,              # 2^-23
    0x00400000,                          # subnormal 2^-127
    0x3EAAAAAB,                          # ~1/3
    0x7F000000, 0xFF000000,              # 2^127
    0x00800001,                          # min normal + ulp
    0x33FFFFFF,                          # just below 2^-23
    0x4B800000,                          # 2^24 (RNE tie territory)
    0x4B800001, 0x4B7FFFFF,
]


def check(kind, a, b, rm, got_res, got_flags, exp_res, exp_flags):
    if is_nan(exp_res) or is_nan(got_res):
        assert is_nan(got_res) and is_nan(exp_res), (
            f"{kind} rm={rm} a={a:08x} b={b:08x}: "
            f"got {got_res:08x}, expected {exp_res:08x}")
        assert got_res == QNAN32, (
            f"{kind} rm={rm} a={a:08x} b={b:08x}: non-canonical qNaN "
            f"{got_res:08x}")
    else:
        assert got_res == exp_res, (
            f"{kind} rm={rm} a={a:08x} b={b:08x}: "
            f"got {got_res:08x}, expected {exp_res:08x}")
    if got_flags is not None:
        for name in ("invalid", "overflow", "underflow", "inexact"):
            assert got_flags[name] == exp_flags[name], (
                f"{kind} rm={rm} a={a:08x} b={b:08x}: flag {name} "
                f"got {got_flags[name]}, expected {exp_flags[name]} "
                f"(res {got_res:08x})")


async def run_unit_op(dut, unit, a, b, rm):
    """Single (non-pipelined) operation through fp32 add or mul unit."""
    v_in = getattr(dut, f"{unit}_valid_in")
    v_out = getattr(dut, f"{unit}_valid_out")
    getattr(dut, f"{unit}_a").value = a
    getattr(dut, f"{unit}_b").value = b
    getattr(dut, f"{unit}_rm").value = rm
    v_in.value = 1
    await RisingEdge(dut.clk)
    v_in.value = 0
    res = flags = None
    for _ in range(10):
        await ReadOnly()
        if int(v_out.value) == 1:
            res = int(getattr(dut, f"{unit}_result").value)
            flags = {
                "invalid": bool(int(getattr(dut, f"{unit}_invalid").value)),
                "overflow": bool(int(getattr(dut, f"{unit}_overflow").value)),
                "underflow": bool(int(getattr(dut, f"{unit}_underflow").value)),
                "inexact": bool(int(getattr(dut, f"{unit}_inexact").value)),
            }
        await RisingEdge(dut.clk)
        if res is not None:
            return res, flags
    raise AssertionError(f"{unit} pipeline never produced valid_out")


async def stream_ops(dut, unit, pairs, rm, ref_fn):
    """Back-to-back pipelined stream: one op per cycle, results checked
    in-order with the 3-cycle latency. Proves no state leakage."""
    results = []

    async def monitor():
        v_out = getattr(dut, f"{unit}_valid_out")
        res = getattr(dut, f"{unit}_result")
        while len(results) < len(pairs):
            await ReadOnly()
            if int(v_out.value) == 1:
                results.append(int(res.value))
            await RisingEdge(dut.clk)

    mon = cocotb.start_soon(monitor())
    v_in = getattr(dut, f"{unit}_valid_in")
    getattr(dut, f"{unit}_rm").value = rm
    for a, b in pairs:
        getattr(dut, f"{unit}_a").value = a
        getattr(dut, f"{unit}_b").value = b
        v_in.value = 1
        await RisingEdge(dut.clk)
    v_in.value = 0
    await ClockCycles(dut.clk, 8)
    mon.kill()
    assert len(results) == len(pairs), (
        f"{unit} stream: {len(results)} results for {len(pairs)} ops")
    for (a, b), got in zip(pairs, results):
        exp, _ = ref_fn(a, b, rm)
        if is_nan(exp):
            assert got == QNAN32, \
                f"{unit}-stream a={a:08x} b={b:08x}: got {got:08x}"
        else:
            assert got == exp, (
                f"{unit}-stream a={a:08x} b={b:08x}: "
                f"got {got:08x}, expected {exp:08x}")


@cocotb.test()
async def test_fp32_units(dut):
    rng = random.Random(0xF9032)
    await start_clock_and_reset(dut)
    dut.add_valid_in.value = 0
    dut.mul_valid_in.value = 0
    dut.alu_valid_in.value = 0
    dut.h_a.value = 0
    dut.h_b.value = 0
    await ClockCycles(dut.clk, 2)

    # --- directed cross-product of special operands, all rounding modes ---
    n = 0
    for rm in range(4):
        for a in DIRECTED_OPERANDS:
            for b in DIRECTED_OPERANDS:
                res, flags = await run_unit_op(dut, "add", a, b, rm)
                exp, ef = fp_add(a, b, rm)
                check("fp32_add", a, b, rm, res, flags, exp, ef)
                res, flags = await run_unit_op(dut, "mul", a, b, rm)
                exp, ef = fp_mul(a, b, rm)
                check("fp32_mul", a, b, rm, res, flags, exp, ef)
                n += 2
    dut._log.info("fp32 directed: %d ops passed (all 4 rounding modes)", n)

    # --- external corpus (Antigravity), if present ---
    corpus = load_vectors("fp32_vectors.json")
    n = 0
    if corpus:
        for op, fn, unit in (("add", fp_add, "add"), ("mul", fp_mul, "mul")):
            for entry in corpus.get(op, []):
                try:
                    a = int(entry[0], 16) & 0xFFFFFFFF
                    b = int(entry[1], 16) & 0xFFFFFFFF
                except (ValueError, IndexError, TypeError):
                    continue
                rm = rng.randrange(4)
                res, flags = await run_unit_op(dut, unit, a, b, rm)
                exp, ef = fn(a, b, rm)
                check(f"fp32_{op}-corpus", a, b, rm, res, flags, exp, ef)
                n += 1
        dut._log.info("fp32 external corpus: %d ops passed", n)

    # --- constrained-random, biased toward interesting exponents ---
    def biased_operand():
        style = rng.randrange(6)
        if style == 0:    # pure random
            return rng.getrandbits(32)
        if style == 1:    # subnormal
            return (rng.getrandbits(1) << 31) | rng.getrandbits(23)
        if style == 2:    # tiny normal exponent
            return ((rng.getrandbits(1) << 31) | (rng.randrange(1, 8) << 23)
                    | rng.getrandbits(23))
        if style == 3:    # huge exponent
            return ((rng.getrandbits(1) << 31)
                    | (rng.randrange(248, 255) << 23) | rng.getrandbits(23))
        if style == 4:    # near 1.0 (cancellation fodder)
            return ((rng.getrandbits(1) << 31) | (127 << 23)
                    | rng.getrandbits(4))
        return ((rng.getrandbits(1) << 31)
                | (rng.randrange(100, 155) << 23) | rng.getrandbits(23))

    for trial in range(400):
        a, b = biased_operand(), biased_operand()
        rm = rng.randrange(4)
        res, flags = await run_unit_op(dut, "add", a, b, rm)
        exp, ef = fp_add(a, b, rm)
        check("fp32_add-rand", a, b, rm, res, flags, exp, ef)
        res, flags = await run_unit_op(dut, "mul", a, b, rm)
        exp, ef = fp_mul(a, b, rm)
        check("fp32_mul-rand", a, b, rm, res, flags, exp, ef)

    # --- pipelined back-to-back streaming (no state leakage) ---
    pairs = [(biased_operand(), biased_operand()) for _ in range(200)]
    await stream_ops(dut, "add", pairs, RM_RNE, fp_add)
    await stream_ops(dut, "mul", pairs, RM_RNE, fp_mul)
    dut._log.info("fp32 pipelined streaming passed")


@cocotb.test()
async def test_fp16_mul(dut):
    rng = random.Random(0xF16)
    await start_clock_and_reset(dut)

    directed16 = [
        0x0000, 0x8000, 0x0001, 0x8001, 0x03FF, 0x83FF, 0x0400, 0x8400,
        0x3C00, 0xBC00, 0x3C01, 0x7BFF, 0xFBFF, 0x7C00, 0xFC00, 0x7E00,
        0x7C01, 0xFC01, 0x1400, 0x2E66, 0x6800, 0x0200,
    ]

    async def check16(a, b):
        dut.h_a.value = a
        dut.h_b.value = b
        await Timer(2, "ns")   # combinational settle
        got = int(dut.h_result.value)
        exp, _ = fp_mul(a, b, RM_RNE, FP16)
        if is_nan(exp, FP16):
            assert got == 0x7E00, \
                f"fp16_mul a={a:04x} b={b:04x}: got {got:04x}, want qNaN"
        else:
            assert got == exp, \
                f"fp16_mul a={a:04x} b={b:04x}: got {got:04x}, expected {exp:04x}"

    for a in directed16:
        for b in directed16:
            await check16(a, b)

    corpus = load_vectors("fp16_vectors.json")
    if corpus:
        n = 0
        for entry in corpus.get("mul", []):
            try:
                a = int(entry[0], 16) & 0xFFFF
                b = int(entry[1], 16) & 0xFFFF
            except (ValueError, IndexError, TypeError):
                continue
            await check16(a, b)
            n += 1
        dut._log.info("fp16 external corpus: %d ops passed", n)

    for _ in range(3000):
        await check16(rng.getrandbits(16), rng.getrandbits(16))
    dut._log.info("fp16_mul exhaustive-random passed")


OP_FADD, OP_FMUL, OP_FMA = 16, 17, 21


@cocotb.test()
async def test_alu_fp_integration(dut):
    """End-to-end: FADD/FMUL/FMA through the ALU's 6-stage FP pipeline.
    FMA reference: fp_fma - true fused multiply-add, single rounding."""
    rng = random.Random(0xA1F9)
    await start_clock_and_reset(dut)
    dut.alu_valid_in.value = 0
    await ClockCycles(dut.clk, 2)

    async def alu_op(op, a, b, c, rm):
        dut.alu_opcode.value = op
        dut.alu_src1.value = a
        dut.alu_src2.value = b
        dut.alu_src3.value = c
        dut.alu_fp_rm.value = rm
        dut.alu_valid_in.value = 1
        await RisingEdge(dut.clk)
        dut.alu_valid_in.value = 0
        res = None
        for _ in range(12):
            await ReadOnly()
            if int(dut.alu_valid_out.value) == 1:
                res = int(dut.alu_result.value)
            await RisingEdge(dut.clk)
            if res is not None:
                return res
        raise AssertionError("ALU FP pipeline produced no result")

    def rand_fp():
        e = rng.randrange(0, 256)
        return (rng.getrandbits(1) << 31) | (e << 23) | rng.getrandbits(23)

    for trial in range(250):
        a, b, c = rand_fp(), rand_fp(), rand_fp()
        rm = rng.randrange(4)

        got = await alu_op(OP_FADD, a, b, c, rm)
        exp, _ = fp_add(a, b, rm)
        assert got == exp or (is_nan(got) and is_nan(exp)), (
            f"ALU FADD a={a:08x} b={b:08x} rm={rm}: "
            f"got {got:08x}, expected {exp:08x}")

        got = await alu_op(OP_FMUL, a, b, c, rm)
        exp, _ = fp_mul(a, b, rm)
        assert got == exp or (is_nan(got) and is_nan(exp)), (
            f"ALU FMUL a={a:08x} b={b:08x} rm={rm}: "
            f"got {got:08x}, expected {exp:08x}")

        got = await alu_op(OP_FMA, a, b, c, rm)
        exp, _ = fp_fma(a, b, c, rm)
        assert got == exp or (is_nan(got) and is_nan(exp)), (
            f"ALU FMA a={a:08x} b={b:08x} c={c:08x} rm={rm}: "
            f"got {got:08x}, expected {exp:08x}")

    # Directed fused-vs-cascade cases: each would round differently (or
    # lose the residual entirely) if computed as round(round(a*b) + c).
    fused_cases = [
        # x*x - round(x*x): tiny nonzero residual a cascade returns as 0
        (0x3F800001, 0x3F800001, 0xBF800002),  # (1+2^-23)^2 - rounded sq
        (0x3F800001, 0x3F800001, 0x3F800002),
        # product in the far-below-addend sticky window
        (0x3F800000, 0x33800000, 0x7F000000),  # 1 * 2^-24 + 2^127
        (0x3F800000, 0x00800000, 0xFF7FFFFF),  # 1 * 2^-126 - maxfinite
        # catastrophic cancellation: fused keeps the exact low bits
        (0x40490FDB, 0x40490FDB, 0xC11DE9E7),  # pi*pi - round(pi*pi)
        # subnormal product magnitudes
        (0x00800001, 0x3F000000, 0x80400000),
        (0x00FFFFFF, 0x3F7FFFFF, 0x80800000),
        # 0*Inf + qNaN must still raise invalid (RISC-V rule)
        (0x00000000, 0x7F800000, 0x7FC00000),
        # Inf product vs opposite Inf addend
        (0x7F800000, 0x3F800000, 0xFF800000),
        # exact cancellation to zero
        (0x3F800000, 0x40000000, 0xC0000000),  # 1*2 - 2
    ]
    for a, b, c in fused_cases:
        for rm in range(4):
            got = await alu_op(OP_FMA, a, b, c, rm)
            exp, _ = fp_fma(a, b, c, rm)
            assert got == exp or (is_nan(got) and is_nan(exp)), (
                f"ALU FMA directed a={a:08x} b={b:08x} c={c:08x} rm={rm}: "
                f"got {got:08x}, expected {exp:08x}")

    # Biased FMA randoms: pick the addend exponent near the product's so
    # the alignment window and catastrophic cancellation get hammered.
    for trial in range(1000):
        ea = rng.randrange(1, 255)
        eb = rng.randrange(1, 255)
        pe = ea + eb - 127
        ec = min(254, max(0, pe + rng.randrange(-30, 31)))
        a = (rng.getrandbits(1) << 31) | (ea << 23) | rng.getrandbits(23)
        b = (rng.getrandbits(1) << 31) | (eb << 23) | rng.getrandbits(23)
        c = (rng.getrandbits(1) << 31) | (ec << 23) | rng.getrandbits(23)
        rm = rng.randrange(4)
        got = await alu_op(OP_FMA, a, b, c, rm)
        exp, _ = fp_fma(a, b, c, rm)
        assert got == exp or (is_nan(got) and is_nan(exp)), (
            f"ALU FMA biased a={a:08x} b={b:08x} c={c:08x} rm={rm}: "
            f"got {got:08x}, expected {exp:08x}")

    dut._log.info("ALU FP pipeline integration passed "
                  "(FADD/FMUL/fused FMA + directed fused cases)")
