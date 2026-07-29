# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Titan X7 SM: program-driven verification of the dual-issue SIMT core.

Assembles real Titan ISA v2 programs, models a pair-fetch I-cache and a
warp-wide D-memory, runs them on the RTL and checks architectural register
state through the debug port. Covers: scoreboard RAW/WAW chains, the
branch loop with gshare/BTB mispredict recovery (epoch flush), the 8-stage
FP pipe (FMUL/FADD/FMA), scatter/gather loads/stores, SETP+predication,
and cross-warp dual-issue IPC."""

import struct

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

LANES = 4
NUM_WARPS = 8

# ---------------------------------------------------------------- assembler
OP = dict(ADD=0, SUB=1, MUL=2, MULHI=3, DIV=4, AND=5, OR=6, XOR=7, SHL=8,
          SHR=9, SRA=10, SLT=11, SLTU=12, MIN=13, MAX=14, FMA=15, FADD=16,
          FMUL=17, FMIN=18, FMAX=19, CVT=20, SETP=21, LOAD=22, STORE=23,
          BRANCH=24, BARRIER=25, WMMA=26, SIN=27, COS=28, RSQRT=29)


def enc(op, rd=0, rs1=0, rs2=0, rs3=0, imm=None, pred=0):
    w = (OP[op] << 27) | (rd << 21) | (rs1 << 15) | (pred & 3) << 1
    if imm is not None:
        w |= ((imm & 0xFFF) << 3) | 1
    else:
        w |= (rs2 << 9) | (rs3 << 3)
    return w


NOP = enc("ADD", rd=63, rs1=63, imm=0)


def f32(x):
    return struct.unpack("<I", struct.pack("<f", x))[0]


def default_mem(addr, lane):
    return (addr * 3 + lane * 0x1000) & 0xFFFFFFFF


# ------------------------------------------------------------- memory models
async def imem_model(dut, prog):
    """Pair-fetch I-mem: 3-cycle latency, always ready, in-order.
    Samples requests at the FALLING edge (stable mid-cycle values)."""
    dut.imem_req_ready.value = 1
    inflight = []
    while True:
        await FallingEdge(dut.clk)
        dut.imem_resp_valid.value = 0
        for e in inflight:
            e[0] -= 1
        if inflight and inflight[0][0] <= 0:
            _, w, pc = inflight.pop(0)
            pair = prog.get(pc, NOP) | (prog.get(pc + 4, NOP) << 32)
            dut.imem_resp_valid.value = 1
            dut.imem_resp_warp.value = w
            dut.imem_resp_data.value = pair
        if int(dut.imem_req_valid.value):
            inflight.append([3, int(dut.imem_req_warp.value),
                             int(dut.imem_req_pc.value)])


async def dmem_model(dut, mem):
    """Warp-wide D-mem: per-lane scatter/gather, 4-cycle load latency."""
    dut.dmem_req_ready.value = 1
    load = None
    while True:
        await FallingEdge(dut.clk)
        dut.dmem_resp_valid.value = 0
        if load is not None:
            load[0] -= 1
            if load[0] <= 0:
                _, w, rdata = load
                dut.dmem_resp_valid.value = 1
                dut.dmem_resp_warp.value = w
                dut.dmem_resp_rdata.value = rdata
                load = None
        if int(dut.dmem_req_valid.value) and int(dut.dmem_req_ready.value):
            w = int(dut.dmem_req_warp.value)
            mask = int(dut.dmem_req_mask.value)
            addr = int(dut.dmem_req_addr.value)
            if int(dut.dmem_req_write.value):
                wdata = int(dut.dmem_req_wdata.value)
                for ln in range(LANES):
                    if (mask >> ln) & 1:
                        a = (addr >> (32 * ln)) & 0xFFFFFFFF
                        mem[(a, ln)] = (wdata >> (32 * ln)) & 0xFFFFFFFF
            else:
                rdata = 0
                for ln in range(LANES):
                    a = (addr >> (32 * ln)) & 0xFFFFFFFF
                    v = mem.get((a, ln), default_mem(a, ln))
                    rdata |= v << (32 * ln)
                load = [4, w, rdata]


# ----------------------------------------------------------------- helpers
async def read_reg(dut, warp, reg):
    dut.dbg_warp.value = warp
    dut.dbg_reg.value = reg
    await RisingEdge(dut.clk)
    v = int(dut.dbg_rdata.value)
    return [(v >> (32 * ln)) & 0xFFFFFFFF for ln in range(LANES)]


async def expect_uniform(dut, warp, reg, val, what):
    lanes = await read_reg(dut, warp, reg)
    for ln, lv in enumerate(lanes):
        assert lv == val & 0xFFFFFFFF, \
            f"{what}: w{warp} r{reg} lane{ln} = {lv:#010x}, expected {val:#010x}"


async def quiesce(dut, cycles=120):
    await ClockCycles(dut.clk, cycles)


# ------------------------------------------------------------------- tests
@cocotb.test()
async def sm_x7_programs(dut):
    Clock(dut.clk, 10, "ns").start()
    dut.rst_n.value = 0
    dut.warp_active.value = 0
    dut.warp_pc_in.value = 0
    dut.imem_resp_valid.value = 0
    dut.dmem_resp_valid.value = 0
    dut.dbg_warp.value = 0
    dut.dbg_reg.value = 0
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    prog = {}
    mem = {}

    # ---- program for warp 0 at 0x0000 ------------------------------------
    a = []
    a.append(enc("ADD", rd=1, rs1=0, imm=5))          # r1 = 5
    a.append(enc("ADD", rd=2, rs1=1, imm=7))          # r2 = 12 (RAW)
    a.append(enc("MUL", rd=3, rs1=2, rs2=2))          # r3 = 144
    a.append(enc("SUB", rd=4, rs1=3, imm=44))         # r4 = 100
    a.append(enc("SHL", rd=5, rs1=4, imm=2))          # r5 = 400
    a.append(enc("XOR", rd=6, rs1=5, rs2=4))          # r6 = 400^100
    a.append(enc("MIN", rd=7, rs1=5, rs2=4))          # r7 = 100
    a.append(enc("MAX", rd=8, rs1=5, rs2=4))          # r8 = 400
    # countdown loop: r10 = 4; do { r10-- } while (r10 != 0)
    a.append(enc("ADD", rd=10, rs1=0, imm=4))
    loop_pc = len(a) * 4
    a.append(enc("SUB", rd=10, rs1=10, imm=1))
    a.append(enc("BRANCH", rs1=10, imm=(-1) & 0xFFF))  # -> loop_pc
    a.append(enc("ADD", rd=11, rs1=0, imm=0x123))     # post-loop marker
    # FP phase
    a.append(enc("ADD", rd=20, rs1=0, imm=3))
    a.append(enc("CVT", rd=21, rs1=20, imm=0))        # r21 = 3.0f
    a.append(enc("ADD", rd=22, rs1=0, imm=2))
    a.append(enc("CVT", rd=23, rs1=22, imm=0))        # r23 = 2.0f
    a.append(enc("FMUL", rd=24, rs1=21, rs2=23))      # 6.0
    a.append(enc("FADD", rd=25, rs1=24, rs2=21))      # 9.0
    a.append(enc("FMA", rd=26, rs1=21, rs2=23, rs3=25))  # 3*2+9 = 15.0
    a.append(enc("CVT", rd=27, rs1=26, imm=1))        # f2i -> 15
    # memory phase: gather distinct lanes, modify, scatter, gather back
    a.append(enc("ADD", rd=30, rs1=0, imm=0x200))
    a.append(enc("LOAD", rd=40, rs1=30, imm=0x40))    # distinct default fill
    a.append(enc("ADD", rd=41, rs1=40, imm=1))
    a.append(enc("STORE", rd=41, rs1=40, imm=0x10))   # mem[r40+0x10] = r41
    a.append(enc("LOAD", rd=42, rs1=40, imm=0x10))    # r42 = r41
    # predication: p1 = (r40 < thresh); [p1] r46 = 9 else stays 7
    a.append(enc("ADD", rd=46, rs1=0, imm=7))
    a.append(enc("SETP", rd=1, rs1=40, imm=0x800))    # p1 = r40 < 0x800
    a.append(enc("ADD", rd=46, rs1=0, imm=9, pred=1))
    for pc, w in enumerate(a):
        prog[pc * 4] = w

    cocotb.start_soon(imem_model(dut, prog))
    cocotb.start_soon(dmem_model(dut, mem))

    dut.warp_pc_in.value = 0
    dut.warp_active.value = 1
    await quiesce(dut, 400)

    # INT phase
    await expect_uniform(dut, 0, 1, 5, "add-imm")
    await expect_uniform(dut, 0, 2, 12, "raw-chain")
    await expect_uniform(dut, 0, 3, 144, "mul")
    await expect_uniform(dut, 0, 4, 100, "sub")
    await expect_uniform(dut, 0, 5, 400, "shl")
    await expect_uniform(dut, 0, 6, 400 ^ 100, "xor")
    await expect_uniform(dut, 0, 7, 100, "min")
    await expect_uniform(dut, 0, 8, 400, "max")
    # loop
    await expect_uniform(dut, 0, 10, 0, "loop-counter")
    await expect_uniform(dut, 0, 11, 0x123, "post-loop")
    # FP phase
    await expect_uniform(dut, 0, 21, f32(3.0), "cvt-i2f")
    await expect_uniform(dut, 0, 24, f32(6.0), "fmul")
    await expect_uniform(dut, 0, 25, f32(9.0), "fadd")
    await expect_uniform(dut, 0, 26, f32(15.0), "fma")
    await expect_uniform(dut, 0, 27, 15, "cvt-f2i")
    # memory phase (per-lane)
    r40 = await read_reg(dut, 0, 40)
    r42 = await read_reg(dut, 0, 42)
    for ln in range(LANES):
        exp = default_mem(0x240, ln)
        assert r40[ln] == exp, f"gather lane{ln}: {r40[ln]:#x} != {exp:#x}"
        assert r42[ln] == (exp + 1) & 0xFFFFFFFF, \
            f"scatter/gather-back lane{ln}: {r42[ln]:#x}"
    # predication (r40 lanes: lane0 < 0x800, others larger)
    r46 = await read_reg(dut, 0, 46)
    for ln in range(LANES):
        exp = 9 if (default_mem(0x240, ln) & 0xFFFFFFFF) < 0x800 else 7
        # signed compare: defaults are positive here
        assert r46[ln] == exp, f"predication lane{ln}: {r46[ln]} != {exp}"
    dut._log.info("warp-0 program: INT/loop/FP/MEM/predication all correct")

    # ---- dual-issue IPC: 4 warps, alternating INT/FP streams -------------
    base = 0x4000
    b = []
    for n in range(64):
        if n % 2 == 0:
            b.append(enc("ADD", rd=8 + (n % 8), rs1=0, imm=n))
        else:
            b.append(enc("FMUL", rd=16 + (n % 8), rs1=1, rs2=2))
    for pc, w in enumerate(b):
        prog[base + pc * 4] = w

    pcs = 0
    for wnum in range(4):
        pcs |= base << (32 * wnum)
    dut.warp_pc_in.value = pcs
    r0 = int(dut.dbg_retired.value)
    dut.warp_active.value = 0b1111    # warps 0-3 (re-activates warp 0 too)
    t0 = 0
    # measure over a window once warm
    await ClockCycles(dut.clk, 40)
    r1 = int(dut.dbg_retired.value)
    await ClockCycles(dut.clk, 100)
    r2 = int(dut.dbg_retired.value)
    ipc = (r2 - r1) / 100.0
    dut._log.info("dual-issue window: %d instructions / 100 cycles (IPC=%.2f)",
                  r2 - r1, ipc)
    assert ipc > 1.2, f"expected dual-issue IPC > 1.2, measured {ipc:.2f}"
