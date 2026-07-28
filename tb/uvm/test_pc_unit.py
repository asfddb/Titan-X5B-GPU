# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_pc_unit verification.

DUT: tb_pc_unit_top - the per-warp program counter file that gives the SM
control flow. Before this block existed, titan_x5_gpu_top tied every warp's
PC to zero (`.warp_pc_in(256'h0)`), so no warp could advance past
instruction 0 and no kernel could terminate.

The reference model below encodes the same PC semantics as the C functional
model in driver/titan_x6_gpu_model.c:

    pc is an instruction *index*      (model: code_addr + pc * 4)
    straight-line advance is pc + 1   (model: next_pc = pc + 1)
    BRANCH writes an absolute index   (model: next_pc = imm)
    EXIT retires the thread           (model: returns on imm == 0xFFF)

Checks:
  1. Reset/launch state: warps inactive out of reset, launch sets PC + active.
  2. Straight-line sequencing across interleaved warps (each warp's PC
     advances only on its own accepted fetch).
  3. Taken branch redirects to an absolute index; a later fetch continues
     from the target, not from the branch site.
  4. Backward branch executes a loop with a real trip count.
  5. EXIT retires one warp while its siblings keep running; all_retired
     asserts only when every launched warp has retired.
  6. Priority: redirect beats a same-cycle sequential advance for the same
     warp; retire beats both.
  7. Inactive warps never advance.
  8. Randomised soak: 4000 interleaved launch/fetch/redirect/retire events
     against the reference model, checking every warp's PC and active bit on
     every cycle.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ReadOnly, NextTimeStep

from tb_common import start_clock_and_reset

NUM_WARPS = 8
PC_MASK = 0xFFFFFFFF


class PcModel:
    """Reference model for titan_x5_pc_unit.

    Mirrors the RTL's documented same-cycle priority: launch > retire >
    redirect > sequential advance.
    """

    def __init__(self, num_warps=NUM_WARPS):
        self.n = num_warps
        self.pc = [0] * num_warps
        self.active = [0] * num_warps
        self.launched = False

    def step(self, launch=None, fetch=None, redirect=None, retire=None):
        """Apply one clock edge's worth of stimulus.

        launch   = (mask, pc) or None
        fetch    = warp id or None
        redirect = (warp id, pc) or None
        retire   = warp id or None
        """
        launched_now = set()
        if launch is not None:
            mask, lpc = launch
            for w in range(self.n):
                if mask & (1 << w):
                    self.pc[w] = lpc & PC_MASK
                    self.active[w] = 1
                    launched_now.add(w)
            if mask:
                self.launched = True

        for w in range(self.n):
            if w in launched_now:
                continue  # launch wins outright for this warp
            if redirect is not None and redirect[0] == w and self.active[w]:
                self.pc[w] = redirect[1] & PC_MASK
            elif fetch is not None and fetch == w and self.active[w]:
                self.pc[w] = (self.pc[w] + 1) & PC_MASK

        if retire is not None and retire not in launched_now:
            self.active[retire] = 0

    @property
    def all_retired(self):
        return self.launched and not any(self.active)


def idle(dut):
    """Deassert every control input."""
    dut.launch_valid.value = 0
    dut.launch_mask.value = 0
    dut.launch_pc.value = 0
    dut.fetch_accept.value = 0
    dut.fetch_warp.value = 0
    dut.redirect_valid.value = 0
    dut.redirect_warp.value = 0
    dut.redirect_pc.value = 0
    dut.retire_valid.value = 0
    dut.retire_warp.value = 0


def drive(dut, launch=None, fetch=None, redirect=None, retire=None):
    """Drive one cycle of stimulus (combinational inputs only)."""
    idle(dut)
    if launch is not None:
        mask, lpc = launch
        dut.launch_valid.value = 1
        dut.launch_mask.value = mask
        dut.launch_pc.value = lpc
    if fetch is not None:
        dut.fetch_accept.value = 1
        dut.fetch_warp.value = fetch
    if redirect is not None:
        dut.redirect_valid.value = 1
        dut.redirect_warp.value = redirect[0]
        dut.redirect_pc.value = redirect[1]
    if retire is not None:
        dut.retire_valid.value = 1
        dut.retire_warp.value = retire


def warp_pc(dut, w):
    """Extract warp w's 32-bit PC from the flattened bus."""
    b = str(dut.warp_pc.value)
    total = len(b)
    sub = b[total - (w + 1) * 32: total - w * 32]
    assert all(c in "01" for c in sub), f"warp {w} PC unresolved: {sub}"
    return int(sub, 2)


async def check(dut, model, ctx):
    """Compare every warp's PC/active and all_retired against the model."""
    await ReadOnly()
    act = int(dut.warp_active.value)
    for w in range(NUM_WARPS):
        got_pc = warp_pc(dut, w)
        exp_pc = model.pc[w]
        assert got_pc == exp_pc, (
            f"{ctx}: warp {w} PC mismatch: RTL {got_pc} != model {exp_pc}")
        got_act = (act >> w) & 1
        assert got_act == model.active[w], (
            f"{ctx}: warp {w} active mismatch: RTL {got_act} "
            f"!= model {model.active[w]}")
    got_all = int(dut.all_retired.value)
    assert got_all == int(model.all_retired), (
        f"{ctx}: all_retired mismatch: RTL {got_all} "
        f"!= model {int(model.all_retired)}")
    # leave the ReadOnly phase so the caller may drive again this timestep
    await NextTimeStep()


async def cycle(dut, model, ctx, **stim):
    """Drive one cycle, advance the model, then check state."""
    drive(dut, **stim)
    await RisingEdge(dut.clk)
    model.step(**stim)
    idle(dut)
    await check(dut, model, ctx)


@cocotb.test()
async def test_reset_and_launch(dut):
    """Out of reset no warp is active; launch sets PC and active bits."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()

    await check(dut, model, "post-reset")
    assert int(dut.warp_active.value) == 0, "warps active out of reset"
    assert int(dut.all_retired.value) == 0, (
        "all_retired asserted before any launch")

    await cycle(dut, model, "launch-all", launch=(0xFF, 0x100))
    assert int(dut.warp_active.value) == 0xFF
    for w in range(NUM_WARPS):
        assert warp_pc(dut, w) == 0x100

    dut._log.info("reset/launch state correct")


@cocotb.test()
async def test_straight_line_sequencing(dut):
    """Each warp's PC advances only on its own accepted fetch."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()
    await cycle(dut, model, "launch", launch=(0xFF, 0))

    # interleave fetches across warps in a non-uniform pattern
    order = [0, 1, 0, 2, 0, 1, 3, 3, 3, 7, 0, 2]
    for i, w in enumerate(order):
        await cycle(dut, model, f"seq[{i}] warp{w}", fetch=w)

    expect = {0: 4, 1: 2, 2: 2, 3: 3, 7: 1}
    for w, n in expect.items():
        assert warp_pc(dut, w) == n, (
            f"warp {w}: expected PC {n}, got {warp_pc(dut, w)}")
    for w in (4, 5, 6):
        assert warp_pc(dut, w) == 0, f"warp {w} advanced without a fetch"

    dut._log.info("straight-line sequencing correct (pc+1 per accepted fetch)")


@cocotb.test()
async def test_taken_branch(dut):
    """A redirect writes an absolute instruction index; fetch resumes there."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()
    await cycle(dut, model, "launch", launch=(0xFF, 0))

    for i in range(5):
        await cycle(dut, model, f"pre-branch[{i}]", fetch=1)
    assert warp_pc(dut, 1) == 5

    # BRANCH to absolute index 100 (TX6_OP_BRANCH: next_pc = imm)
    await cycle(dut, model, "branch", redirect=(1, 100))
    assert warp_pc(dut, 1) == 100, "redirect did not take"

    await cycle(dut, model, "post-branch", fetch=1)
    assert warp_pc(dut, 1) == 101, "fetch after branch resumed at wrong PC"

    # sibling warps untouched by warp 1's control flow
    for w in (0, 2, 3):
        assert warp_pc(dut, w) == 0, f"warp {w} disturbed by warp 1 branch"

    dut._log.info("taken branch redirects to absolute index correctly")


@cocotb.test()
async def test_backward_loop(dut):
    """A backward branch runs a loop with a real trip count."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()
    await cycle(dut, model, "launch", launch=(0x01, 10))

    # loop body occupies indices 10..13, branch at 13 returns to 10
    TRIPS = 6
    fetched = 0
    for trip in range(TRIPS):
        for _ in range(4):                       # fetch body 10,11,12,13
            await cycle(dut, model, f"loop{trip}", fetch=0)
            fetched += 1
        if trip != TRIPS - 1:
            await cycle(dut, model, f"loop{trip}-back", redirect=(0, 10))
            assert warp_pc(dut, 0) == 10, "backward branch did not take"

    assert fetched == TRIPS * 4, "wrong number of body fetches"
    assert warp_pc(dut, 0) == 14, (
        f"loop fell through to {warp_pc(dut, 0)}, expected 14")

    dut._log.info("backward loop executed %d trips, %d fetches", TRIPS, fetched)


@cocotb.test()
async def test_exit_retires_warp(dut):
    """EXIT retires one warp; siblings continue; all_retired gates correctly."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()
    await cycle(dut, model, "launch", launch=(0x0F, 0))   # warps 0..3

    await cycle(dut, model, "retire-w1", retire=1)
    assert (int(dut.warp_active.value) >> 1) & 1 == 0, "warp 1 did not retire"
    assert int(dut.all_retired.value) == 0, "all_retired asserted too early"

    # a retired warp must not advance even if a stale fetch arrives
    pc_before = warp_pc(dut, 1)
    await cycle(dut, model, "stale-fetch-retired", fetch=1)
    assert warp_pc(dut, 1) == pc_before, "retired warp advanced on stale fetch"

    # siblings still run
    await cycle(dut, model, "sibling-runs", fetch=2)
    assert warp_pc(dut, 2) == 1, "sibling warp stalled by another's retire"

    for w in (0, 2, 3):
        await cycle(dut, model, f"retire-w{w}", retire=w)

    assert int(dut.warp_active.value) == 0
    assert int(dut.all_retired.value) == 1, (
        "all_retired not asserted after every launched warp retired")

    dut._log.info("EXIT retire semantics correct")


@cocotb.test()
async def test_same_cycle_priority(dut):
    """redirect beats sequential advance; retire beats both."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()
    await cycle(dut, model, "launch", launch=(0xFF, 0))

    # redirect + fetch on the SAME warp in the SAME cycle -> redirect wins.
    # If the increment won, a branch resolved in the shadow of its own fetch
    # would be silently lost.
    await cycle(dut, model, "redirect-vs-fetch", fetch=3, redirect=(3, 64))
    assert warp_pc(dut, 3) == 64, (
        f"redirect lost to same-cycle advance (PC={warp_pc(dut, 3)})")

    # redirect + fetch on DIFFERENT warps -> both apply
    await cycle(dut, model, "independent", fetch=4, redirect=(5, 200))
    assert warp_pc(dut, 4) == 1 and warp_pc(dut, 5) == 200

    # retire + redirect on the same warp -> warp goes inactive
    await cycle(dut, model, "retire-vs-redirect", retire=6, redirect=(6, 900))
    assert (int(dut.warp_active.value) >> 6) & 1 == 0, "retire lost"

    # launch overrides a stale redirect for the same warp
    await cycle(dut, model, "launch-vs-redirect",
                launch=(1 << 7, 0x500), redirect=(7, 0x999))
    assert warp_pc(dut, 7) == 0x500, "launch did not override stale redirect"

    dut._log.info("same-cycle priority (launch > retire > redirect > advance) ok")


@cocotb.test()
async def test_random_soak(dut):
    """Randomised interleaving checked against the reference model."""
    idle(dut)
    await start_clock_and_reset(dut)
    model = PcModel()
    rnd = random.Random(0xC0FFEE)

    await cycle(dut, model, "launch", launch=(0xFF, 0))

    N = 4000
    counts = {"fetch": 0, "redirect": 0, "retire": 0, "launch": 0}
    for i in range(N):
        stim = {}
        r = rnd.random()
        if r < 0.55:
            stim["fetch"] = rnd.randrange(NUM_WARPS)
            counts["fetch"] += 1
        elif r < 0.75:
            stim["redirect"] = (rnd.randrange(NUM_WARPS),
                                rnd.randrange(0, 1 << 20))
            counts["redirect"] += 1
        elif r < 0.80:
            stim["retire"] = rnd.randrange(NUM_WARPS)
            counts["retire"] += 1
        elif r < 0.86:
            # occasionally do two things at once to stress priority
            stim["fetch"] = rnd.randrange(NUM_WARPS)
            stim["redirect"] = (rnd.randrange(NUM_WARPS),
                                rnd.randrange(0, 1 << 20))
            counts["fetch"] += 1
            counts["redirect"] += 1

        # relaunch retired warps periodically so the soak keeps making progress
        if not any(model.active) or (i % 500 == 499):
            stim = {"launch": (rnd.randrange(1, 256), rnd.randrange(0, 1 << 16))}
            counts["launch"] += 1

        await cycle(dut, model, f"soak[{i}]", **stim)

    dut._log.info("soak: %d cycles matched the reference model %s", N, counts)
