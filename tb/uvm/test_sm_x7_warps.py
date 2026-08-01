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
          BRANCH=24, BARRIER=25, WMMA=26, SIN=27, COS=28, FFMA=29)


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
            enc("BARRIER", imm=0xFFF),               # EXIT: stop, don't run on
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
    # BRANCH targets are ABSOLUTE INSTRUCTION INDICES in a 12-bit field, so
    # every warp's program must live within instruction index 0..4095 (byte
    # 0..16380). 0x100-byte spacing keeps all 8 programs inside that window.
    for w in range(NUM_WARPS):
        base = 0x100 * (w + 1)
        bases.append(base)
        loop_idx = base // 4 + 2                     # index of "acc += 3"
        body = [
            enc("ADD", rd=10, rs1=0, imm=w + 1),     # trip count = w+1
            enc("ADD", rd=11, rs1=0, imm=0),         # accumulator
            # loop:
            enc("ADD", rd=11, rs1=11, imm=3),        # acc += 3
            enc("SUB", rd=10, rs1=10, imm=1),
            enc("BRANCH", rs1=10, imm=loop_idx),     # back to acc += 3
            enc("ADD", rd=12, rs1=0, imm=0x777),     # post-loop marker
            # EXIT. Without it a warp runs off the end of its program, walks
            # through the NOP padding and falls into the NEXT warp's code,
            # overwriting its own results with that warp's. That is exactly
            # what happened when these programs were packed 0x100 apart --
            # warp 3 finished correctly (r11=12) and was then corrupted by
            # warp 4's `ADD r10, r0, 5`. The old 0x1000 spacing only hid it
            # behind 1024 NOPs of padding, which 600 cycles never crossed.
            enc("BARRIER", imm=0xFFF),
        ]
        for i, word in enumerate(body):
            prog[base + i * 4] = word

    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_pc_in.value = pack_pcs(bases)
    dut.warp_active.value = (1 << NUM_WARPS) - 1
    await ClockCycles(dut.clk, 600)

    obs = {}
    for w in range(NUM_WARPS):
        obs[w] = {reg: (await read_reg(dut, w, reg))[0] for reg in (10, 11, 12)}
    for w in range(NUM_WARPS):
        dut._log.info(
            "warp %d trips=%d: r10=%#x r11=%#x (want %#x) r12=%#x",
            w, w + 1, obs[w][10], obs[w][11], 3 * (w + 1), obs[w][12])

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


@cocotb.test()
async def sm_x7_branch_target_is_absolute_index(dut):
    """One warp, one counted loop: BRANCH imm is an ABSOLUTE instruction
    index, not a PC-relative offset.

    This is the ISA contract shared by compiler/titan_compiler.py (the label
    fixup ORs `lbl.pc` straight into the immediate), the C oracle
    (`next_pc = imm`) and titan_x5_pipeline (`pc_redirect_pc = {16'd0,
    dec_imm}`). Single warp so nothing cross-warp can mask the result.
    """
    await boot(dut)

    base = 0x40                       # instruction index 16
    loop_idx = base // 4 + 2          # index of "acc += 3"
    body = [
        enc("ADD", rd=10, rs1=0, imm=3),      # 3 trips
        enc("ADD", rd=11, rs1=0, imm=0),
        # loop:
        enc("ADD", rd=11, rs1=11, imm=3),
        enc("SUB", rd=10, rs1=10, imm=1),
        enc("BRANCH", rs1=10, imm=loop_idx),
        enc("ADD", rd=12, rs1=0, imm=0x777),
        enc("BARRIER", imm=0xFFF),                # EXIT
    ]
    prog = {base + i * 4: word for i, word in enumerate(body)}
    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_pc_in.value = pack_pcs([base] + [0] * (NUM_WARPS - 1))
    dut.warp_active.value = 0b1
    await ClockCycles(dut.clk, 400)

    for reg, want in ((10, 0), (11, 9), (12, 0x777)):
        lanes = await read_reg(dut, 0, reg)
        for ln, got in enumerate(lanes):
            assert got == want, (
                f"r{reg} lane {ln} = {got:#x}, expected {want:#x} -- a "
                f"3-trip loop with an absolute-index BRANCH target did not "
                f"execute the right number of iterations")

    dut._log.info("absolute-index BRANCH: 3-trip loop reached acc=9")


@cocotb.test()
async def sm_x7_exit_retires_only_the_exiting_warp(dut):
    """EXIT (BARRIER, use_imm, imm==0xFFF) retires one warp at a time;
    `all_retired` only rises once every ACTIVE warp has retired.

    Three warps run programs of different lengths, each ending in EXIT.
    If `warp_retired`/`all_retired` were shared across warps -- or if EXIT
    were confused with a plain BARRIER (which waits for every warp) -- the
    short warps would either retire every warp at once or never retire at
    all while a longer warp is still running.
    """
    await boot(dut)

    prog = {}
    lengths = {0: 2, 1: 4, 2: 6}   # instructions before EXIT, per warp
    bases = {}
    for w, n in lengths.items():
        base = 0x1000 * (w + 1)
        bases[w] = base
        body = [enc("ADD", rd=1, rs1=0, imm=w) for _ in range(n)]
        body.append(enc("BARRIER", imm=0xFFF))   # EXIT
        for i, word in enumerate(body):
            prog[base + i * 4] = word

    cocotb.start_soon(imem_model(dut, prog))

    pcs = [bases.get(w, 0) for w in range(NUM_WARPS)]
    dut.warp_pc_in.value = pack_pcs(pcs)
    dut.warp_active.value = 0b0111   # warps 0, 1, 2

    exits_seen = []
    all_retired_at_exit_count = []
    for cyc in range(300):
        await RisingEdge(dut.clk)
        if int(dut.warp_exit_valid.value):
            exits_seen.append(int(dut.warp_exit_warp.value))
            all_retired_at_exit_count.append(int(dut.all_retired.value))

    assert sorted(exits_seen) == [0, 1, 2], (
        f"expected exactly one EXIT pulse per active warp, got {exits_seen}")
    # all_retired must not assert until every active warp has exited, i.e.
    # only on the LAST of the three pulses -- regardless of which warp
    # (scheduling fairness, not program length, decides the exact order)
    assert all_retired_at_exit_count == [0, 0, 1], (
        f"all_retired asserted before every active warp had retired: "
        f"{all_retired_at_exit_count}")
    assert int(dut.all_retired.value) == 1, (
        "all_retired should stay asserted once every active warp has retired")

    dut._log.info(
        "3 warps of different lengths each retired independently via EXIT; "
        "all_retired only rose after the last (longest) warp finished")


@cocotb.test()
async def sm_x7_relaunch_clears_retired(dut):
    """A warp that EXITs and is relaunched at a new PC is not stuck retired.

    Guards the activation-edge clear of `warp_retired`: without it, a warp
    reused after EXIT would never become issueable again and `all_retired`
    would latch true forever regardless of what runs next.
    """
    await boot(dut)

    prog = {
        0x0000: enc("BARRIER", imm=0xFFF),                 # EXIT immediately
        0x2000: enc("ADD", rd=5, rs1=0, imm=0x55),
        0x2004: enc("ADD", rd=6, rs1=0, imm=0x66),
    }
    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_pc_in.value = 0x0000
    dut.warp_active.value = 0b1
    await ClockCycles(dut.clk, 40)
    assert int(dut.all_retired.value) == 1, "warp 0 should have retired"

    # deactivate, then relaunch at a fresh PC -- a real falling->rising edge
    dut.warp_active.value = 0b0
    await ClockCycles(dut.clk, 2)
    dut.warp_pc_in.value = 0x2000
    dut.warp_active.value = 0b1
    await ClockCycles(dut.clk, 2)
    assert int(dut.all_retired.value) == 0, (
        "all_retired must drop on relaunch, not stay latched from the "
        "previous EXIT")

    await ClockCycles(dut.clk, 60)
    lanes = await read_reg(dut, 0, 6)
    for ln, got in enumerate(lanes):
        assert got == 0x66, (
            f"relaunched warp 0 lane {ln} r6 = {got:#x}, expected 0x66 -- "
            f"the warp did not resume normal execution after EXIT")
    assert int(dut.all_retired.value) == 0, (
        "relaunched program has no EXIT, so all_retired must stay low")

    dut._log.info(
        "warp 0 retired, was relaunched at a new PC, and resumed normal "
        "execution instead of staying latched retired")


@cocotb.test()
async def sm_x7_plain_barrier_is_not_exit(dut):
    """A plain BARRIER (use_imm=0, thread sync) must NOT retire a warp.

    Only BARRIER with use_imm && imm==0xFFF is EXIT. If that distinction
    were lost -- e.g. by treating every BARRIER as EXIT -- ordinary
    synchronisation would silently deactivate warps instead of just
    rendezvousing them, and this test is what would catch it: both warps
    must run their post-barrier instruction, and neither `warp_exit_valid`
    nor `all_retired` may fire anywhere in the run.
    """
    await boot(dut)

    prog = {
        0x1000: enc("ADD", rd=1, rs1=0, imm=1),
        0x1004: enc("BARRIER"),                     # plain sync, not EXIT
        0x1008: enc("ADD", rd=2, rs1=0, imm=0xAA),
        0x2000: enc("ADD", rd=1, rs1=0, imm=2),
        0x2004: enc("ADD", rd=63, rs1=63, imm=0),    # extra NOP: staggers arrival
        0x2008: enc("BARRIER"),
        0x200C: enc("ADD", rd=2, rs1=0, imm=0xBB),
    }
    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_pc_in.value = pack_pcs([0x1000, 0x2000] + [0] * (NUM_WARPS - 2))
    dut.warp_active.value = 0b11

    saw_exit = False
    saw_all_retired = False
    for cyc in range(200):
        await RisingEdge(dut.clk)
        if int(dut.warp_exit_valid.value):
            saw_exit = True
        if int(dut.all_retired.value):
            saw_all_retired = True

    assert not saw_exit, "plain BARRIER must never pulse warp_exit_valid"
    assert not saw_all_retired, "plain BARRIER must never assert all_retired"

    for w, want in ((0, 0xAA), (1, 0xBB)):
        lanes = await read_reg(dut, w, 2)
        for ln, got in enumerate(lanes):
            assert got == want, (
                f"warp {w} lane {ln} r2 = {got:#x}, expected {want:#x} -- "
                f"it did not resume after the plain barrier released")

    dut._log.info(
        "plain BARRIER synchronised both warps and released them without "
        "retiring either one")
