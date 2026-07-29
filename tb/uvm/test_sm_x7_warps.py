# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Titan X7 SM: per-warp architectural state, and per-warp control flow.

Why this suite exists
---------------------
`test_sm_x7.py` runs one warp's program, checks warp 0's registers, then
activates four warps ONLY to measure dual-issue IPC. Nothing checks warps
1-3's results. That gap was demonstrated, not assumed: rewiring every
register-file access inside titan_x7_sm.v to index warp 0 -- making all
eight warps share one set of 64 registers -- left `sm7` passing with a
byte-identical IPC of 1.72.

This is the same shape of hole `docs/HANDOFF_NEXT_SESSION.md` documents for
the x5 predicate registers, and the same generalisation applies: if every
warp in a test runs the same program and only one warp's results are
checked, the test cannot see a cross-warp bug.

So these tests give each warp a DIFFERENT program at a different PC, writing
different values to the SAME register numbers, and then check every warp
independently.

A separate module (rather than more tests in test_sm_x7.py) because that
file's imem/dmem models are started with `cocotb.start_soon` and run for the
rest of the simulation; a second test in the same module would have two sets
of models driving the same ports.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

LANES = 4
NUM_WARPS = 8

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


# r63 is the scratch the NOP writes, so no test observes it.
NOP = enc("ADD", rd=63, rs1=63, imm=0)


async def imem_model(dut, prog):
    """Pair-fetch I-mem: 3-cycle latency, always ready, in-order."""
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


async def dmem_idle(dut):
    dut.dmem_req_ready.value = 1
    dut.dmem_resp_valid.value = 0


async def read_reg(dut, warp, reg):
    dut.dbg_warp.value = warp
    dut.dbg_reg.value = reg
    await RisingEdge(dut.clk)
    v = int(dut.dbg_rdata.value)
    return [(v >> (32 * ln)) & 0xFFFFFFFF for ln in range(LANES)]


async def boot(dut):
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
    await dmem_idle(dut)


def pack_pcs(pcs):
    v = 0
    for w, pc in enumerate(pcs):
        v |= (pc & 0xFFFFFFFF) << (32 * w)
    return v


@cocotb.test()
async def sm_x7_registers_are_per_warp(dut):
    """Eight warps hold different values in the SAME register numbers.

    Each warp runs its own program at its own PC writing warp-dependent
    constants to r1..r4. If the register file were shared -- or if the warp
    index were dropped anywhere on the read, write or writeback path -- the
    warps would overwrite each other and at most one could be correct.
    """
    await boot(dut)

    prog = {}
    bases = []
    for w in range(NUM_WARPS):
        base = 0x1000 * (w + 1)
        bases.append(base)
        body = [
            enc("ADD", rd=1, rs1=0, imm=0x100 + w),
            enc("ADD", rd=2, rs1=0, imm=0x200 + w),
            enc("ADD", rd=3, rs1=1, rs2=2),          # RAW within the warp
            enc("SUB", rd=4, rs1=2, rs2=1),          # = 0x100 for every warp
        ]
        for i, word in enumerate(body):
            prog[base + i * 4] = word

    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_pc_in.value = pack_pcs(bases)
    dut.warp_active.value = (1 << NUM_WARPS) - 1
    await ClockCycles(dut.clk, 400)

    for w in range(NUM_WARPS):
        for reg, want in ((1, 0x100 + w), (2, 0x200 + w),
                          (3, 0x300 + 2 * w), (4, 0x100)):
            lanes = await read_reg(dut, w, reg)
            for ln, got in enumerate(lanes):
                assert got == want, (
                    f"warp {w} r{reg} lane {ln} = {got:#x}, expected "
                    f"{want:#x} -- warps are not holding independent "
                    f"register state")

    dut._log.info(
        f"{NUM_WARPS} warps hold independent values in r1..r4 "
        f"(r1=0x100+w, r2=0x200+w, r3=r1+r2, r4=r2-r1)")


@cocotb.test()
async def sm_x7_control_flow_is_per_warp(dut):
    """Warps take different trip counts through their own loops.

    Register state alone can be per-warp while the PC / branch machinery is
    not. Here warp w counts down from (w + 1), so a shared loop counter, a
    shared predictor update or a mis-tagged epoch flush lands the warps on
    different totals than they should have.
    """
    await boot(dut)

    prog = {}
    bases = []
    for w in range(NUM_WARPS):
        base = 0x1000 * (w + 1)
        bases.append(base)
        body = [
            enc("ADD", rd=10, rs1=0, imm=w + 1),     # trip count = w+1
            enc("ADD", rd=11, rs1=0, imm=0),         # accumulator
            # loop:
            enc("ADD", rd=11, rs1=11, imm=3),        # acc += 3
            enc("SUB", rd=10, rs1=10, imm=1),
            enc("BRANCH", rs1=10, imm=(-2) & 0xFFF),  # back to acc += 3
            enc("ADD", rd=12, rs1=0, imm=0x777),     # post-loop marker
        ]
        for i, word in enumerate(body):
            prog[base + i * 4] = word

    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_pc_in.value = pack_pcs(bases)
    dut.warp_active.value = (1 << NUM_WARPS) - 1
    await ClockCycles(dut.clk, 600)

    for w in range(NUM_WARPS):
        trips = w + 1
        for reg, want in ((10, 0), (11, 3 * trips), (12, 0x777)):
            lanes = await read_reg(dut, w, reg)
            for ln, got in enumerate(lanes):
                assert got == want, (
                    f"warp {w} (trip count {trips}) r{reg} lane {ln} = "
                    f"{got:#x}, expected {want:#x} -- per-warp control flow "
                    f"is not independent")

    dut._log.info(
        f"{NUM_WARPS} warps ran loops of {1}..{NUM_WARPS} trips concurrently, "
        f"each reaching its own accumulator total")
