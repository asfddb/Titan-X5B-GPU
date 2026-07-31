# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Compiled kernels executed end to end on the RTL.

These are full-chip tests: compiler/titan_compiler.py emits Titan ISA words,
tb_compute_top loads them into VRAM, titan_x5_gpu_top runs them, and the result
is read back out of the memory hierarchy and compared against an independent
reference.

The reference is never this file's own arithmetic:

  * control-flow and integer kernels are checked against
    `titan_compiler.simulate()`, the Python twin of `exec_thread()` in
    driver/titan_x6_gpu_model.c (the authoritative functional model), and
  * matmul is additionally checked against NumPy.

Run with:

    python -m pytest tb/test_compute_kernels.py -v              # everything
    python -m pytest tb/test_compute_kernels.py -m "not slow"   # quick subset

These are whole-GPU Icarus simulations and the design simulates at roughly 90
clock cycles per wall second here, so the long ones are marked `slow`.
tb/run_regression.py runs the quick subset as the `compute` suite -- enough
that the path cannot rot silently -- and leaves the rest, including matmul, to
an explicit run.
"""

import os
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "compiler"))

import compute_runner as cr
from titan_compiler import (Assembler, OPS, simulate, CMP_EQ, CMP_NE, CMP_LT,
                            CMP_GE, CMP_LTU, CMP_GEU, R_TID, R_ZERO)

M32 = 0xFFFFFFFF


def ref_run(words, n_words, data=None):
    """Expected result window, from the functional model's Python twin.

    The model is scalar (one thread); the RTL runs 32 lanes. Every kernel here
    is written so lane-independent state is identical across lanes, so lane N's
    architectural result equals the model's -- except where the kernel uses
    R62 (TID), which the model does not set and which those kernels avoid.
    """
    mem = bytearray(8 << 20)
    if data:
        for i, w in enumerate(data):
            mem[cr.DATA_BASE + 4*i: cr.DATA_BASE + 4*i + 4] = \
                (w & M32).to_bytes(4, "little")
    simulate(words, mem, cr.PARAM_BASE)
    base = cr.DATA_BASE
    return [int.from_bytes(mem[base + 4*i: base + 4*i + 4], "little")
            for i in range(n_words)]


def counted_loop_program(trip, step_val=7):
    """acc = 0; for i in range(trip): acc += step_val;  store acc.

    Deliberately shaped like the compiler's own loop lowering:

        top:  SETP.GE p1, i, bound
              BRANCH end, pred=1        <- conditional: the loop exit
              acc += step_val
              i   += 1
              BRANCH top                <- unconditional: the back edge
        end:  STORE

    If the conditional branch is treated as unconditional the loop exits on
    the first iteration and acc is 0. If the predicate is ignored the other
    way the loop never exits and the watchdog fires. Only the correct trip
    count produces trip*step_val.
    """
    a = Assembler()
    R_I, R_ACC, R_BOUND, R_ADDR = 2, 3, 4, 5
    a.li(R_I, 0)
    a.li(R_ACC, 0)
    a.li(R_BOUND, trip)
    top = a.here()
    end = a.new_label()
    a.setp(CMP_GE, 1, R_I, R_BOUND)
    a.branch(end, pred=1)
    a.i("ADD", R_ACC, R_ACC, step_val)
    a.i("ADD", R_I, R_I, 1)
    a.branch(top)
    a.bind(end)
    a.li(R_ADDR, cr.DATA_BASE)
    a.i("STORE", R_ACC, R_ADDR, 0)
    a.exit()
    a.finalize()
    return a.words


# 0 exits before the body runs at all; 1 and 2 catch off-by-one at the
# boundary; 17 and 64 are long enough that a wrong trip count cannot coincide
# with the right answer. Larger counts add simulation time without adding
# coverage -- the whole GPU simulates at ~90 cycles/second here.
@pytest.mark.parametrize("trip", [
    0, 1, 2,
    pytest.param(17, marks=pytest.mark.slow),
    pytest.param(64, marks=pytest.mark.slow),
])
def test_counted_loop_trip_count(trip):
    """A real counted loop runs the right number of times on the RTL.

    This is the property SETP + predicated BRANCH exist to provide: before
    them every branch was unconditional and a loop could not have an exit
    condition.
    """
    prog = counted_loop_program(trip)
    expect = ref_run(prog, 1)
    assert expect[0] == (trip * 7) & M32, (
        "the reference model itself disagrees with the intended trip count")

    res = cr.run(prog, n_res=1, max_cycles=1_500_000)
    assert not res.timed_out, f"kernel never retired:\n{res.log[-3000:]}"
    assert not res.pred_divergent, "unexpected divergent predicate"
    assert res.words[0] == expect[0], (
        f"trip={trip}: RTL produced {res.words[0]:#x}, "
        f"functional model says {expect[0]:#x}")


@pytest.mark.slow
@pytest.mark.parametrize(
    "cond,name", [(CMP_EQ, "EQ"), (CMP_NE, "NE"), (CMP_LT, "LT"),
                  (CMP_GE, "GE"), (CMP_LTU, "LTU"), (CMP_GEU, "GEU")])
def test_setp_conditions(cond, name):
    """Every TX6_CMP_* condition drives a branch the way the model says.

    For each of a set of operand pairs the kernel evaluates SETP and lets a
    predicated branch pick between storing 1 and storing 0, so the stored word
    is the predicate itself as seen by control flow.

    LT/GE are signed and LTU/GEU unsigned, so the pairs include a case where
    the two disagree (-1 vs 1: signed less-than, unsigned greater-than). A
    sign-blind implementation passes the other pairs and fails that one.
    """
    pairs = [(5, 5), (5, 6), (6, 5), (0xFFFFFFFF, 1), (1, 0xFFFFFFFF), (0, 0)]

    a = Assembler()
    R_A, R_B, R_OUT, R_ADDR = 2, 3, 4, 5
    a.li(R_ADDR, cr.DATA_BASE)
    for idx, (x, y) in enumerate(pairs):
        a.li(R_A, x)
        a.li(R_B, y)
        a.li(R_OUT, 0)
        a.setp(cond, 1, R_A, R_B)
        skip = a.new_label()
        # BRANCH is taken only when P1 is true, so R_OUT ends up 1 exactly
        # when the comparison held.
        taken = a.new_label()
        a.branch(taken, pred=1)
        a.branch(skip)
        a.bind(taken)
        a.li(R_OUT, 1)
        a.bind(skip)
        a.i("STORE", R_OUT, R_ADDR, 4*idx)
    a.exit()
    a.finalize()
    prog = a.words

    expect = ref_run(prog, len(pairs))
    res = cr.run(prog, n_res=len(pairs), max_cycles=1_500_000)
    assert not res.timed_out, f"kernel never retired:\n{res.log[-3000:]}"
    assert not res.pred_divergent, "unexpected divergent predicate"
    assert res.words == expect, (
        f"SETP.{name}: RTL {[hex(w) for w in res.words]} != "
        f"model {[hex(w) for w in expect]} for pairs {pairs}")


def test_predicated_instruction_is_skipped():
    """A predicated-off non-branch instruction must not take effect.

    The model's rule is `if (!p[pred]) { pc = next_pc; continue; }` -- the
    whole instruction is suppressed, not just branches. Here P1 is set false
    and a predicated ADD is skipped, so the accumulator keeps its old value.
    """
    a = Assembler()
    R_A, R_OUT, R_ADDR = 2, 3, 5
    a.li(R_ADDR, cr.DATA_BASE)

    # P1 = (1 >= 2) = false
    a.li(R_A, 1)
    a.li(R_OUT, 0x11)
    a.setp(CMP_GE, 1, R_A, R_ZERO)      # P1 = (1 >= 0) = true
    a.i("ADD", R_OUT, R_OUT, 1, pred=1)  # executes -> 0x12
    a.i("STORE", R_OUT, R_ADDR, 0)

    a.li(R_OUT, 0x21)
    a.setp(CMP_LT, 1, R_A, R_ZERO)      # P1 = (1 < 0) = false
    a.i("ADD", R_OUT, R_OUT, 1, pred=1)  # skipped -> stays 0x21
    a.i("STORE", R_OUT, R_ADDR, 4)
    a.exit()
    a.finalize()
    prog = a.words

    expect = ref_run(prog, 2)
    assert expect == [0x12, 0x21], f"model disagrees: {expect}"

    res = cr.run(prog, n_res=2, max_cycles=1_500_000)
    assert not res.timed_out, f"kernel never retired:\n{res.log[-3000:]}"
    assert not res.pred_divergent, "unexpected divergent predicate"
    assert res.words == expect, (
        f"predication: RTL {[hex(w) for w in res.words]} != model "
        f"{[hex(w) for w in expect]}")


def test_host_reads_kernel_results_from_memory():
    """A kernel's stores reach VRAM, and a host can read them back.

    This is the property the whole cache-flush path exists for, and until
    CMD_FENCE was wired to titan_x5_flush_ctrl it was FALSE: both cache
    levels are write-back, so a kernel that stored a value and exited left
    it sitting in a Modified L1 line and VRAM read zero. tb_compute_top.v
    worked around it by reading results out of the cache hierarchy, which
    meant no test in this repo ever exercised the path between an L1
    write-back and memory at all.

    Every other test in this file now depends on that path too -- the
    testbench reads results straight from the AXI memory model. This one
    states the dependency outright, with values chosen so a partial flush
    cannot pass by luck:

      * 0x00000000 and 0xFFFFFFFF, the extremes a byte-enable or
        write-strobe bug mangles;
      * words in two different cache lines, so more than one line has to
        be walked and written back;
      * 0xDEADBEEF, which cannot be confused with the zero VRAM is
        initialised to -- without a distinctive value, "the flush wrote
        nothing" and "the flush wrote zeros" look identical.
    """
    a = Assembler()
    R_VAL, R_ADDR = 2, 5
    a.li(R_ADDR, cr.DATA_BASE)

    # Two words in the first cache line, two 128 B away in the next one.
    for offset, value in ((0, 0xDEADBEEF), (4, 0x00000000),
                          (128, 0xFFFFFFFF), (132, 0x5A5A5A5A)):
        a.li(R_VAL, value)
        a.i("STORE", R_VAL, R_ADDR, offset)
    a.exit()
    a.finalize()
    prog = a.words

    # 132/4 + 1 = 34 words spans both lines; the gap reads back as zero.
    res = cr.run(prog, n_res=34, max_cycles=1_500_000)
    assert not res.timed_out, f"kernel never retired:\n{res.log[-3000:]}"

    # The testbench prints this line only when VRAM disagrees with the
    # architectural value held in the caches -- i.e. the flush lost a word.
    assert "STALE" not in res.log, (
        f"a result word never reached VRAM:\n{res.log[-3000:]}")
    assert "FENCE TIMEOUT" not in res.log, (
        f"CMD_FENCE never completed:\n{res.log[-3000:]}")

    got = {0: res.words[0], 4: res.words[1],
           128: res.words[32], 132: res.words[33]}
    expect = {0: 0xDEADBEEF, 4: 0x00000000,
              128: 0xFFFFFFFF, 132: 0x5A5A5A5A}
    assert got == expect, (
        f"host readback from VRAM: {  {k: hex(v) for k, v in got.items()} } "
        f"!= {  {k: hex(v) for k, v in expect.items()} }")


def _matmul_setup(M, N, K, seed=0x71760006):
    """Compile compiler/kernels/matmul.py and lay out its operands in VRAM.

    Returns (program, data, params, base_c, A, B). The kernel source is read
    from the kernels directory rather than duplicated here, so this test
    exercises the file the project ships.
    """
    import random
    from titan_compiler import parse_kernel, ScalarCodegen

    kernel_path = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                               "..", "compiler", "kernels", "matmul.py")
    with open(kernel_path) as f:
        src = f.read()
    fn = parse_kernel(src, "matmul")
    program = ScalarCodegen(fn).compile()

    rng = random.Random(seed)
    A = [rng.randrange(-50, 50) for _ in range(M * K)]
    B = [rng.randrange(-50, 50) for _ in range(K * N)]

    # A, B and C laid out back to back inside the data region.
    base_a = cr.DATA_BASE
    base_b = base_a + 4 * M * K
    base_c = base_b + 4 * K * N
    data = [v & M32 for v in A] + [v & M32 for v in B] + [0] * (M * N)
    params = [base_a, base_b, base_c, M, N, K]
    return program, data, params, base_c, A, B


@pytest.mark.slow
@pytest.mark.parametrize("M,N,K", [(4, 4, 4)])
def test_matmul_bit_exact_vs_numpy(M, N, K):
    """compiler/kernels/matmul.py, compiled and executed by the RTL, is
    bit-exact against NumPy.

    This is the end-to-end claim: Python source -> Titan ISA -> RTL -> a
    result matrix that matches an independent reference word for word. It is
    also the first time this kernel has been executed by the hardware rather
    than only by the reference simulator.
    """
    numpy = pytest.importorskip("numpy")

    program, data, params, base_c, A, B = _matmul_setup(M, N, K)

    ref = (numpy.array(A, dtype=numpy.int64).reshape(M, K) @
           numpy.array(B, dtype=numpy.int64).reshape(K, N))
    expect = [int(v) & M32 for v in ref.reshape(-1)]

    res = cr.run(program, n_res=M * N, data=data, params=params,
                 res_base=base_c, max_cycles=4_000_000)
    assert not res.timed_out, f"matmul never retired:\n{res.log[-3000:]}"
    assert not res.pred_divergent, "unexpected divergent predicate"
    assert res.words == expect, (
        f"matmul {M}x{N}x{K} mismatch\n"
        f"  RTL   : {[hex(w) for w in res.words]}\n"
        f"  NumPy : {[hex(w) for w in expect]}")


@pytest.mark.slow
def test_predicates_are_per_warp():
    """P1 is per-warp state, not shared across warps.

    Each warp gets its OWN loop bound and its OWN result slot, deposited
    through the register-file backdoor, so warp w must run exactly
    `2 + 3*w` iterations and store `7 * (2 + 3*w)` at DATA_BASE + 4*w.

    Registers used: R10 = this warp's bound, R11 = this warp's result address.
    Both are deposited per warp; the program itself is warp-agnostic, so the
    divergence comes purely from per-warp register state.

    HONEST LIMITATION -- read before trusting this test's name.
    ----------------------------------------------------------
    This test does NOT prove the predicate registers are per-warp. It was
    written to, and mutation testing showed it does not: with
    `pred_mask`/`id_pred_idx` deliberately reindexed so every warp shares warp
    0's predicate slots, all 8 warps still produced exactly the right results
    (0xe, 0x23, ... 0xa1). An earlier, weaker version of this test -- the same
    counted loop in all 8 warps -- also survived that mutation, and giving the
    warps different trip counts did not fix it.

    The measured reason is that warps barely overlap. The same 8-warp loop
    takes 24,069 cycles where one warp takes 3,257 -- 7.4x for 8x the work, so
    there is almost no concurrency to interleave. Two things cause that: one
    outstanding instruction fetch per SM, and a warp scheduler whose hazard
    check compares the *current ID instruction's* source registers against
    *every* warp's scoreboard (titan_x5_warp_scheduler.v:88), so warps running
    the same program stall on each other's register numbers. A warp's SETP and
    its dependent BRANCH therefore end up adjacent in practice, and a shared
    predicate is never observed stale.

    So the per-warp indexing is implemented because the ISA requires per-thread
    predicate state, not because a test caught it missing. The defect is
    latent, not benign: widening fetch (roadmap Phase 2) or fixing the
    scheduler's hazard check would expose it immediately. What this test does
    verify is that per-warp *register* state feeds SETP correctly and that 8
    warps each run their own trip count.
    """
    n_warps = 8
    bounds = [2 + 3*w for w in range(n_warps)]

    a = Assembler()
    R_I, R_ACC, R_BOUND, R_ADDR = 2, 3, 10, 11
    a.li(R_I, 0)
    a.li(R_ACC, 0)
    top = a.here()
    end = a.new_label()
    a.setp(CMP_GE, 1, R_I, R_BOUND)
    a.branch(end, pred=1)
    a.i("ADD", R_ACC, R_ACC, 7)
    a.i("ADD", R_I, R_I, 1)
    a.branch(top)
    a.bind(end)
    a.i("STORE", R_ACC, R_ADDR, 0)
    a.exit()
    a.finalize()

    warp_regs = []
    for w in range(n_warps):
        warp_regs.append((w, R_BOUND, bounds[w]))
        warp_regs.append((w, R_ADDR, cr.DATA_BASE + 4*w))

    expect = [(7 * b) & M32 for b in bounds]

    res = cr.run(a.words, n_res=n_warps, warp_regs=warp_regs,
                 max_cycles=2_000_000, warp_mask=0xFF)
    assert not res.timed_out, f"kernel never retired:\n{res.log[-3000:]}"
    assert not res.pred_divergent, "unexpected divergent predicate"
    assert res.words == expect, (
        f"per-warp predicates: RTL {[hex(w) for w in res.words]} != "
        f"expected {[hex(w) for w in expect]} (bounds {bounds})")
