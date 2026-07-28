# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_alu ISA-conformance verification.

The ALU used to implement a *different opcode map* than the ISA header, the
decoder, the compiler and the functional model -- all four of which agree with
each other. Opcode 8 is SHL everywhere except the ALU, where it was OP_CMP;
3, 9, 10, 11 were likewise wrong; and 4, 12-15, 18-20 were unimplemented and
fell through to `default`, returning 0.

Every one of those failed *silently*: a SHL returned a comparison result, a
DIV returned zero. `compiler/test_compiler_isa.py` checked the compiler
against the DECODER and never against the ALU, which is why it survived.

This suite closes that hole. The reference model below is a direct
transcription of the integer/FP semantics in driver/titan_x6_gpu_model.c,
which is the authoritative definition of the ISA.

DUT: tb_fpu_top (it already instantiates titan_x5_alu).
"""

import random
import struct

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, ClockCycles

from tb_common import start_clock_and_reset

M32 = 0xFFFFFFFF

# ISA opcodes -- driver/titan_x6_isa.h
ADD, SUB, MUL, MULHI, DIV = 0, 1, 2, 3, 4
AND, OR, XOR = 5, 6, 7
SHL, SHR, SRA = 8, 9, 10
SLT, SLTU, MIN, MAX = 11, 12, 13, 14
IFMA = 15
FADD, FMUL, FMIN, FMAX, CVT = 16, 17, 18, 19, 20

# Opcodes this suite covers. FADD/FMUL are covered in depth by test_fpu.py;
# 21 is deliberately still the FP fused unit (the ISA has no FP-FMA opcode --
# see the note in titan_x5_alu.v), so SETP is not exercised here.
INT_OPS = [ADD, SUB, MUL, MULHI, DIV, AND, OR, XOR, SHL, SHR, SRA,
           SLT, SLTU, MIN, MAX, IFMA]

NAMES = {ADD: "ADD", SUB: "SUB", MUL: "MUL", MULHI: "MULHI", DIV: "DIV",
         AND: "AND", OR: "OR", XOR: "XOR", SHL: "SHL", SHR: "SHR",
         SRA: "SRA", SLT: "SLT", SLTU: "SLTU", MIN: "MIN", MAX: "MAX",
         IFMA: "IFMA", FMIN: "FMIN", FMAX: "FMAX", CVT: "CVT"}


def s32(v):
    v &= M32
    return v - (1 << 32) if v & 0x80000000 else v


def f2b(f):
    return struct.unpack("<I", struct.pack("<f", f))[0]


def b2f(b):
    return struct.unpack("<f", struct.pack("<I", b & M32))[0]


def ref(op, a, b, c=0, rs3=0):
    """Reference model -- transcribed from driver/titan_x6_gpu_model.c."""
    a &= M32
    b &= M32
    c &= M32
    sa, sb = s32(a), s32(b)
    if op == ADD:   return (a + b) & M32
    if op == SUB:   return (a - b) & M32
    if op == MUL:   return (sa * sb) & M32
    if op == MULHI: return ((sa * sb) >> 32) & M32
    if op == DIV:
        if sb == 0:                            return M32
        if sa == -(1 << 31) and sb == -1:      return a
        q = abs(sa) // abs(sb)                 # C truncates toward zero
        if (sa < 0) != (sb < 0):
            q = -q
        return q & M32
    if op == AND:   return a & b
    if op == OR:    return a | b
    if op == XOR:   return a ^ b
    if op == SHL:   return (a << (b & 31)) & M32
    if op == SHR:   return (a >> (b & 31)) & M32
    if op == SRA:   return (sa >> (b & 31)) & M32
    if op == SLT:   return 1 if sa < sb else 0
    if op == SLTU:  return 1 if a < b else 0
    if op == MIN:   return a if sa < sb else b
    if op == MAX:   return a if sa > sb else b
    if op == IFMA:  return ((sa * sb) + c) & M32
    if op in (FMIN, FMAX):
        fa, fb = b2f(a), b2f(b)
        # fminf/fmaxf: a NaN operand loses
        if fa != fa:   return b
        if fb != fb:   return a
        lt = fa < fb
        if op == FMIN: return a if lt else b
        return b if lt else a
    if op == CVT:
        if rs3 & 1:                            # fp32 -> int32 (truncate)
            fa = b2f(a)
            if fa != fa:                       return 0
            t = int(fa)                        # Python truncates toward zero
            if t > 0x7FFFFFFF or t < -(1 << 31):
                return 0x80000000
            return t & M32
        return f2b(float(s32(a)))              # int32 -> fp32
    raise AssertionError(f"no reference for opcode {op}")


async def alu(dut, op, a, b=0, c=0, timeout=200):
    """Issue one operation and wait for its result."""
    dut.alu_opcode.value = op
    dut.alu_src1.value = a & M32
    dut.alu_src2.value = b & M32
    dut.alu_src3.value = c & M32
    dut.alu_fp_rm.value = 0
    dut.alu_valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.alu_valid_in.value = 0
    for _ in range(timeout):
        await ReadOnly()
        if int(dut.alu_valid_out.value):
            res = int(dut.alu_result.value) & M32
            await RisingEdge(dut.clk)
            return res
        await RisingEdge(dut.clk)
    raise AssertionError(f"{NAMES.get(op, op)}: no result within {timeout} cycles")


async def check(dut, op, a, b, c=0, rs3=0, ctx=""):
    got = await alu(dut, op, a, b, c)
    exp = ref(op, a, b, c, rs3)
    assert got == exp, (
        f"{NAMES.get(op, op)}{ctx}: a={a:#010x} b={b:#010x} c={c:#010x} "
        f"-> got {got:#010x}, model says {exp:#010x}")
    return got


async def setup(dut):
    dut.alu_valid_in.value = 0
    dut.alu_opcode.value = 0
    dut.alu_src1.value = 0
    dut.alu_src2.value = 0
    dut.alu_src3.value = 0
    dut.alu_fp_rm.value = 0
    await start_clock_and_reset(dut)
    await ClockCycles(dut.clk, 2)


@cocotb.test()
async def test_directed_corners(dut):
    """Every integer opcode against directed corner operands."""
    await setup(dut)
    corners = [0, 1, 2, 3, 31, 32, 0x7FFFFFFF, 0x80000000, 0xFFFFFFFF,
               0xDEADBEEF, 0x5A5A5A5A, 0xFFFF0000, 0x0000FFFF]
    n = 0
    for op in INT_OPS:
        for a in corners:
            for b in corners:
                await check(dut, op, a, b, c=0x1234_5678, ctx=" directed")
                n += 1
    dut._log.info("directed: %d integer ops match the functional model", n)


@cocotb.test()
async def test_shifts_are_shifts(dut):
    """SHL/SHR/SRA compute shifts, not comparisons.

    This is the regression guard for the specific defect: opcode 8 used to be
    OP_CMP in the ALU, so `SHL 1, 2` returned 0 (a != b) instead of 4.
    """
    await setup(dut)
    assert await alu(dut, SHL, 1, 2) == 4, "SHL 1,2 must be 4"
    assert await alu(dut, SHL, 1, 31) == 0x80000000
    assert await alu(dut, SHR, 0x80000000, 31) == 1
    assert await alu(dut, SRA, 0x80000000, 31) == M32, "SRA must sign-extend"
    assert await alu(dut, SRA, 0x40000000, 30) == 1
    # shift amounts are masked to 5 bits (model: a << (b & 31))
    assert await alu(dut, SHL, 1, 33) == 2, "shift amount must mask to 5 bits"
    dut._log.info("SHL/SHR/SRA verified as real shifts")


@cocotb.test()
async def test_div_edge_cases(dut):
    """Signed division, including the two defined special cases."""
    await setup(dut)
    assert await alu(dut, DIV, 100, 7) == 14
    assert await alu(dut, DIV, (-100) & M32, 7) == (-14) & M32
    assert await alu(dut, DIV, 100, (-7) & M32) == (-14) & M32
    assert await alu(dut, DIV, (-100) & M32, (-7) & M32) == 14
    assert await alu(dut, DIV, 5, 0) == M32, "divide by zero must yield 0xFFFFFFFF"
    assert await alu(dut, DIV, 0x80000000, M32) == 0x80000000, "INT_MIN/-1 overflow"
    dut._log.info("signed DIV verified incl. div-by-zero and INT_MIN/-1")


@cocotb.test()
async def test_mulhi(dut):
    """MULHI returns the high word of the SIGNED product."""
    await setup(dut)
    assert await alu(dut, MULHI, 0x10000, 0x10000) == 1
    assert await alu(dut, MULHI, (-1) & M32, (-1) & M32) == 0, "(-1*-1)>>32 == 0"
    assert await alu(dut, MULHI, (-1) & M32, 1) == M32, "sign must extend"
    assert await alu(dut, MULHI, 0x7FFFFFFF, 0x7FFFFFFF) == 0x3FFFFFFF
    dut._log.info("MULHI verified as signed high-word multiply")


@cocotb.test()
async def test_fmin_fmax_and_cvt(dut):
    """FP min/max and int<->fp conversion."""
    await setup(dut)
    vals = [0.0, -0.0, 1.0, -1.0, 3.5, -3.5, 1e10, -1e10, 1e-10]
    for x in vals:
        for y in vals:
            a, b = f2b(x), f2b(y)
            for op in (FMIN, FMAX):
                got = await alu(dut, op, a, b)
                exp = ref(op, a, b)
                assert b2f(got) == b2f(exp), (
                    f"{NAMES[op]}({x},{y}) -> {b2f(got)} exp {b2f(exp)}")
    # NaN loses
    nan = 0x7FC00000
    assert b2f(await alu(dut, FMIN, nan, f2b(2.0))) == 2.0
    assert b2f(await alu(dut, FMAX, f2b(2.0), nan)) == 2.0

    for v in [0, 1, -1, 2, -2, 1000, -1000, 0x7FFFFFFF, 0x80000000, 123456789]:
        got = await alu(dut, CVT, v & M32, 0, 0)          # rs3=0 -> int->fp
        exp = ref(CVT, v & M32, 0, 0, rs3=0)
        assert got == exp, (
            f"CVT int->fp({s32(v)}): got {b2f(got)} ({got:#010x}) "
            f"exp {b2f(exp)} ({exp:#010x})")
    dut._log.info("FMIN/FMAX and CVT int->fp verified")


@cocotb.test()
async def test_random_soak(dut):
    """Randomised operands across every integer opcode."""
    await setup(dut)
    rng = random.Random(0x15A)
    N = 40
    for op in INT_OPS:
        for _ in range(N):
            a = rng.getrandbits(32)
            b = rng.getrandbits(32)
            c = rng.getrandbits(32)
            await check(dut, op, a, b, c, ctx=" random")
    dut._log.info("soak: %d random ops across %d opcodes match the model",
                  N * len(INT_OPS), len(INT_OPS))
