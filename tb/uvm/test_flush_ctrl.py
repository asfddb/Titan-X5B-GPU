# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Device-level flush sequencer ordering.

The sequencer exists because flushing the two cache levels in the wrong
order, or without waiting for the coherent crossbar to drain in between,
loses data silently. Both failure modes produce a chip that passes every
other test in this repo and hands a host one stale word occasionally, which
is the worst possible way to find out.

The three properties, all checked here rather than in the full chip where a
violation is a rare stale read:

  1. L2's walk does not start until EVERY L1 has reported done.
  2. L2's walk does not start until the crossbar reports itself drained --
     an L1's flush_done only means its last writeback was accepted by the
     crossbar, not that it reached L2.
  3. l1_flush_req stays asserted for the whole sequence, because that is
     what holds every L1's core_req_ready low and stops an already-flushed
     L1 taking a store and re-dirtying itself mid-flush.
"""

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly

from tb_common import start_clock_and_reset

NUM_L1 = 8
ALL_L1 = (1 << NUM_L1) - 1


async def quiesce(dut):
    dut.flush_start.value = 0
    dut.l1_flush_done.value = 0
    dut.bus_idle.value = 1
    dut.l2_flush_done.value = 0
    await ClockCycles(dut.clk, 4)


async def pulse_l1_done(dut, which):
    """One-cycle flush_done pulse from a subset of the L1s."""
    dut.l1_flush_done.value = which
    await RisingEdge(dut.clk)
    dut.l1_flush_done.value = 0


class Watch:
    """Samples the sequencer's outputs every cycle for later assertions."""

    def __init__(self, dut):
        self.dut = dut
        self.stop = False
        self.trace = []      # (l1_req, l2_req, complete)

    async def run(self):
        while not self.stop:
            await ReadOnly()
            self.trace.append((int(self.dut.l1_flush_req.value),
                               int(self.dut.l2_flush_req.value),
                               int(self.dut.flush_complete.value)))
            await RisingEdge(self.dut.clk)

    @property
    def l2_ever_asserted(self):
        return any(t[1] for t in self.trace)

    @property
    def completes(self):
        return sum(t[2] for t in self.trace)


async def setup(dut):
    # Inputs are deasserted BEFORE reset, not after. cocotb runs every test
    # in one simulation, so a test that leaves flush_start high hands it to
    # the next test's reset -- and the sequencer starts a flush the moment
    # rst_n rises, before that test has driven anything. That is how the
    # mid-sequence rearm bug below was found, so it is worth keeping the
    # ordering deliberate rather than accidental.
    dut.flush_start.value = 0
    dut.l1_flush_done.value = 0
    dut.bus_idle.value = 1
    dut.l2_flush_done.value = 0
    await start_clock_and_reset(dut)
    await quiesce(dut)
    w = Watch(dut)
    cocotb.start_soon(w.run())
    await ClockCycles(dut.clk, 2)
    return w


@cocotb.test()
async def l2_waits_for_every_l1(dut):
    """L2's walk must not start while any L1 is still flushing.

    Seven of the eight report done and the eighth is held back deliberately.
    A sequencer that ORs the dones, or that counts pulses without tracking
    WHICH cache sent them, starts L2 early -- and the eighth L1's writebacks
    then land in an L2 the walk has already passed.
    """
    w = await setup(dut)

    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    assert int(dut.flush_busy.value) == 1, "flush_start did not start a flush"

    await pulse_l1_done(dut, 0b0111_1111)     # 7 of 8
    await ClockCycles(dut.clk, 50)

    assert not w.l2_ever_asserted, (
        "l2_flush_req asserted with one L1 still flushing -- that L1's "
        "writebacks would reach L2 after its walk had passed them")
    assert int(dut.l1_flush_req.value) == 1, (
        "l1_flush_req dropped while an L1 was still flushing")

    await pulse_l1_done(dut, 0b1000_0000)     # the last one
    await ClockCycles(dut.clk, 20)
    assert w.l2_ever_asserted, (
        "l2_flush_req never asserted after all 8 L1s reported done")

    dut._log.info("L2 held off until all 8 L1s reported done, then started")
    w.stop = True


@cocotb.test()
async def l2_waits_for_the_bus_to_drain(dut):
    """L2's walk must not start while the coherent crossbar has work in it.

    All eight L1s report done immediately, but the crossbar is held busy.
    flush_done from an L1 means "the crossbar accepted my last writeback",
    and the crossbar is split-transaction with a queue behind a one-cycle
    grant, so those writebacks are still in flight.
    """
    w = await setup(dut)

    dut.bus_idle.value = 0
    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    await pulse_l1_done(dut, ALL_L1)
    await ClockCycles(dut.clk, 100)

    assert not w.l2_ever_asserted, (
        "l2_flush_req asserted while the crossbar still had transactions in "
        "flight -- those writebacks land in L2 after its walk has passed")

    dut.bus_idle.value = 1
    await ClockCycles(dut.clk, 20)
    assert w.l2_ever_asserted, "l2_flush_req never asserted after bus_idle"

    dut._log.info("L2 held off until the crossbar drained, then started")
    w.stop = True


@cocotb.test()
async def l1_stays_held_until_the_whole_sequence_ends(dut):
    """l1_flush_req must not drop when the L1 phase ends.

    It is what holds every L1's core_req_ready low. Dropping it after the L1
    walks would let an SM store into a freshly flushed L1 while L2 is still
    walking; that line reaches L2 after its set has been passed and is never
    written back. The flush would report success and lose the store.
    """
    w = await setup(dut)

    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    await pulse_l1_done(dut, ALL_L1)

    # through the drain and the whole of L2's walk
    for _ in range(40):
        await ReadOnly()
        assert int(dut.l1_flush_req.value) == 1, (
            "l1_flush_req dropped before the sequence finished -- the L1s are "
            "no longer frozen and can re-dirty themselves during L2's walk")
        await RisingEdge(dut.clk)

    assert int(dut.l2_flush_req.value) == 1, "L2 phase never reached"
    dut.l2_flush_done.value = 1
    await RisingEdge(dut.clk)
    dut.l2_flush_done.value = 0
    await ClockCycles(dut.clk, 4)

    assert int(dut.l1_flush_req.value) == 0, (
        "l1_flush_req never dropped after the flush completed -- every L1 "
        "stays closed to core traffic and the GPU wedges")
    assert w.completes == 1, (
        f"flush_complete pulsed {w.completes} times, expected exactly 1")

    dut._log.info(
        "l1_flush_req held across the drain and L2 walk, released on "
        "completion; flush_complete pulsed once")
    w.stop = True


@cocotb.test()
async def dropping_flush_start_mid_sequence_does_not_restart_it(dut):
    """Withdrawing the request mid-flush must not buy a second flush.

    The one-shot latch is set when the sequence STARTS, so it has to survive
    the whole sequence. Rearming it on `flush_start` simply being low clears
    it mid-flight, and the sequencer then restarts the instant it reaches
    S_IDLE -- re-freezing every L1 immediately after reporting the flush
    complete, with nothing left to un-freeze them until another fence.

    This was a real defect in this module. It surfaced because a previous
    test left flush_start asserted across this one's reset, so a flush began
    before the test drove anything; that is now prevented in setup(), which
    is exactly why the case needs a test of its own.
    """
    w = await setup(dut)

    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    assert int(dut.flush_busy.value) == 1, "flush did not start"

    # A transient on the request line while the flush is in flight. The
    # sequencer must treat this as the SAME fence: a new one requires it to
    # see flush_start low while it is idle. Otherwise the glitch queues a
    # second flush that fires the moment the first completes.
    dut.flush_start.value = 0
    await ClockCycles(dut.clk, 2)
    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    await pulse_l1_done(dut, ALL_L1)
    await ClockCycles(dut.clk, 20)
    dut.l2_flush_done.value = 1
    await RisingEdge(dut.clk)
    dut.l2_flush_done.value = 0
    await ClockCycles(dut.clk, 40)

    assert w.completes == 1, (
        f"flush_complete pulsed {w.completes} times, expected 1")
    assert int(dut.flush_busy.value) == 0, (
        "sequencer restarted after completing -- the one-shot latch was "
        "cleared mid-sequence when the requester withdrew")
    assert int(dut.l1_flush_req.value) == 0, (
        "l1_flush_req re-asserted after completion -- every L1 is frozen "
        "again with no fence outstanding")

    dut._log.info(
        "request glitched low and back mid-sequence: the flush finished "
        "once and did not restart")
    w.stop = True


@cocotb.test()
async def held_flush_start_runs_exactly_one_sequence(dut):
    """One request = one flush, however long flush_start is held.

    flush_start is a level and the requester (the command processor's FENCE)
    cannot drop it until it has seen flush_complete, so the sequencer is
    guaranteed to be back in S_IDLE with flush_start still high. Restarting
    there would re-freeze every L1 immediately after telling the host the
    flush was done.
    """
    w = await setup(dut)

    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    await pulse_l1_done(dut, ALL_L1)
    await ClockCycles(dut.clk, 20)
    dut.l2_flush_done.value = 1
    await RisingEdge(dut.clk)
    dut.l2_flush_done.value = 0

    # keep flush_start asserted well past completion
    await ClockCycles(dut.clk, 60)
    assert w.completes == 1, (
        f"flush_complete pulsed {w.completes} times while flush_start was "
        f"held high; expected exactly 1 -- the sequence restarts on the level")
    assert int(dut.flush_busy.value) == 0, (
        "sequencer is busy again with no new request -- it restarted on the "
        "held level")

    # dropping and re-asserting must run a second flush, or fences after the
    # first would hang forever
    dut.flush_start.value = 0
    await ClockCycles(dut.clk, 4)
    dut.flush_start.value = 1
    await ClockCycles(dut.clk, 2)
    assert int(dut.flush_busy.value) == 1, (
        "re-asserting flush_start started nothing -- the one-shot latch never "
        "rearms and every fence after the first would hang")

    dut._log.info(
        "held flush_start produced exactly one sequence; re-asserting it "
        "started a second")
    w.stop = True
