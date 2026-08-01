# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x7_sm_shim: the X7 core behind titan_x5_sm's interface.

This is the integration step from docs/HANDOFF_NEXT_SESSION.md priority 1.
It exercises the three adapters the shim adds, against the REAL
titan_x5_lsu and titan_x5_l1_cache rather than a stub:

  - the launch/retire manager (x5's pc_unit contract, rebuilt around X7's
    warp_active input and warp_exit output)
  - the instruction fetch adapter (64-bit warp-tagged pair -> the chip's
    32-bit granted single-word port)
  - stores and loads through the coalescing LSU and the coherent L1

A store followed by a load of the same address is the sharpest check
available here: it has to traverse the LSU's coalescer, miss in L1, fill
from the coherent bus, and come back to the right lane of the right warp.
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

NUM_WARPS = 8
CODE_BASE = 0x0000_1000

OP = dict(ADD=0, SUB=1, MUL=2, MULHI=3, DIV=4, AND=5, OR=6, XOR=7, SHL=8,
          SHR=9, SRA=10, SLT=11, SLTU=12, MIN=13, MAX=14, FMA=15, FADD=16,
          FMUL=17, FMIN=18, FMAX=19, CVT=20, SETP=21, LOAD=22, STORE=23,
          BRANCH=24, BARRIER=25, WMMA=26, SIN=27, COS=28, FFMA=29)


def enc(op, rd=0, rs1=0, rs2=0, rs3=0, imm=None, pred=0):
    w = (OP[op] << 27) | (rd << 21) | (rs1 << 15) | (pred & 3) << 1
    if imm is not None:
        w |= ((imm & 0xFFF) << 3) | 1
    else:
        w |= (rs2 << 9) | (rs3 << 3)
    return w


async def boot(dut, prog, launch_mask=0b1, launch_pc=0):
    """Reset, load the program at CODE_BASE, launch, return."""
    Clock(dut.clk, 10, "ns").start()
    dut.rst_n.value = 0
    dut.launch_valid.value = 0
    dut.launch_mask.value = 0
    dut.launch_pc.value = 0
    dut.code_base.value = CODE_BASE

    # instruction memory is word-indexed by (byte addr >> 2)
    for i in range(4096):
        dut.imem[i].value = enc("ADD", rd=63, rs1=63, imm=0)   # NOP
    for idx, word in prog.items():
        dut.imem[(CODE_BASE >> 2) + idx].value = word
    for i in range(64):
        dut.linemem[i].value = 0

    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 3)

    dut.launch_mask.value = launch_mask
    dut.launch_pc.value = launch_pc
    dut.launch_valid.value = 1
    await RisingEdge(dut.clk)
    dut.launch_valid.value = 0


async def run_until_retired(dut, limit=4000):
    for cyc in range(limit):
        await RisingEdge(dut.clk)
        if int(dut.all_retired.value):
            return cyc
    return None


async def collect_exports(dut, limit=4000, drain=30):
    """Watch shader_wb_* until the kernel retires, then keep watching.

    `all_retired` rises when EXIT *issues*, but instructions ahead of it are
    still in the pipe -- an export issued one cycle before EXIT writes back
    two or three stages later. titan_x5_sm retires the same way
    (pc_retire_valid is asserted in ID), so this is the SM's contract, not a
    quirk of the shim: anything sampling the export port has to drain the
    pipeline rather than stop dead on all_retired.
    """
    seen = []
    retired_at = None
    for cyc in range(limit):
        await RisingEdge(dut.clk)
        if int(dut.shader_wb_valid.value):
            seen.append((cyc, int(dut.shader_wb_reg.value),
                         int(dut.shader_wb_data.value) & 0xFFFFFFFF))
        if int(dut.all_retired.value):
            if retired_at is None:
                retired_at = cyc
            elif cyc - retired_at >= drain:
                break
    return seen, retired_at


@cocotb.test()
async def x7shim_runs_a_kernel_to_completion(dut):
    """A single warp runs an arithmetic kernel and EXITs.

    Covers the fetch adapter (every instruction arrives as half of a pair
    assembled from two 32-bit fetches) and the launch/retire manager
    (all_retired must rise only after EXIT, and must not be true before the
    kernel is launched).
    """
    prog = {
        0: enc("ADD", rd=1, rs1=0, imm=5),
        1: enc("ADD", rd=2, rs1=1, imm=7),        # RAW -> 12
        2: enc("MUL", rd=3, rs1=2, rs2=2),        # 144
        3: enc("ADD", rd=63, rs1=3, imm=0),       # shader export of 144
        4: enc("BARRIER", imm=0xFFF),             # EXIT
    }
    await boot(dut, prog)

    assert int(dut.all_retired.value) == 0, \
        "all_retired must not be set before the kernel has run"

    cycles = await run_until_retired(dut)
    assert cycles is not None, \
        "kernel never retired -- the fetch adapter or the retire path is stuck"

    assert int(dut.warp_active.value) == 0, \
        f"warp_active = {int(dut.warp_active.value):#x} after all_retired"

    dut._log.info("kernel retired in %d cycles via the 32-bit fetch adapter",
                  cycles)


@cocotb.test()
async def x7shim_exports_r63_to_the_rop(dut):
    """R63 writes appear on shader_wb_*, which is what the ROP paints.

    titan_x5_sm exports its writeback port directly; the shim mirrors X7's
    INT writeback the same way. Without this the ROP has no colour.
    """
    prog = {
        0: enc("ADD", rd=5, rs1=0, imm=0x2A),
        1: enc("ADD", rd=63, rs1=5, imm=0),       # export 0x2A
        2: enc("BARRIER", imm=0xFFF),
    }
    await boot(dut, prog)

    events, _ = await collect_exports(dut, limit=600)
    seen = [v for _, r, v in events if r == 63]

    assert 0x2A in seen, \
        f"no R63 export of 0x2A reached the ROP port; saw {[hex(v) for v in seen]}"
    dut._log.info("shader export: R63 = 0x2a reached the ROP port")


@cocotb.test()
async def x7shim_store_then_load_through_l1(dut):
    """A store and a load of the same address, through the real LSU and L1.

    This is the path that does not exist in titan_x7_sm on its own: X7 has
    a raw dmem interface and no cache. The value has to be coalesced by
    titan_x5_lsu, miss in titan_x5_l1_cache, fill over the coherent bus,
    merge, and come back to the right lane.
    """
    prog = {
        0: enc("ADD", rd=6, rs1=0, imm=0x400),    # address
        1: enc("ADD", rd=7, rs1=0, imm=0x5A),     # value
        2: enc("STORE", rd=7, rs1=6, imm=0),      # mem[r6] = r7
        3: enc("LOAD", rd=8, rs1=6, imm=0),       # r8 = mem[r6]
        4: enc("ADD", rd=63, rs1=8, imm=0),       # export what memory returned
        5: enc("BARRIER", imm=0xFFF),
    }
    await boot(dut, prog)

    events, retired_at = await collect_exports(dut, limit=3000)
    dut._log.info("retired at %s; writebacks: %s", retired_at,
                  [(c, f"r{r}", hex(v)) for c, r, v in events])
    seen = [v for _, r, v in events if r == 63]

    assert 0x5A in seen, (
        f"store->load through the LSU and L1 did not return 0x5a; "
        f"exports seen: {[hex(v) for v in seen]}")
    dut._log.info("store -> load through the real LSU and L1 returned 0x5a")


@cocotb.test()
async def x7shim_multiple_warps_all_retire(dut):
    """Four warps launched together each reach EXIT.

    all_retired is the top level's kernel_complete, so it must wait for
    every launched warp, not the first one.
    """
    prog = {
        0: enc("ADD", rd=1, rs1=0, imm=1),
        1: enc("ADD", rd=2, rs1=1, imm=1),
        2: enc("BARRIER", imm=0xFFF),
    }
    await boot(dut, prog, launch_mask=0b1111)

    cycles = await run_until_retired(dut)
    assert cycles is not None, "4 warps never all retired"
    assert int(dut.warp_active.value) == 0, \
        f"warp_active = {int(dut.warp_active.value):#x} after all_retired"
    dut._log.info("4 warps all retired in %d cycles", cycles)
