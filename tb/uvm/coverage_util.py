# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Functional-coverage layer for the Titan X5 regression suites.

Built on cocotb-coverage (Icarus has no native line/toggle coverage, so
coverage is collected functionally at the transaction level):

    fpu  - operation x rounding-mode cross, operand-class cross
           (zero/subnormal/normal/inf/nan per operand), exception flags
    mesi - L1 MESI FSM coverage: state occupancy and every legal observable
           state transition (I->S/E/M, S->M/I, E->M/S/I, M->S/I)
    lsu  - lane-mask shape x load/store cross, coalesced transaction-count
           buckets, acceptance backpressure (skid/stall) buckets
    tmu  - format x wrap/clamp cross, fractional-weight corners

Each test module registers `export_on_exit("<suite>")` once; the cumulative
coverage database is written to tb/uvm/<suite>_coverage.yml when the
simulation process exits, and a summary is printed to the log. The
regression runner surfaces the per-suite percentages.
"""

import atexit
import os

from cocotb_coverage.coverage import CoverPoint, CoverCross, coverage_db

HERE = os.path.dirname(os.path.abspath(__file__))

FP_CLASSES = ["zero", "sub", "norm", "inf", "nan"]
MESI_NAMES = ["I", "S", "E", "M"]
# transitions observable at transaction boundaries in a MESI L1
MESI_LEGAL_TRANS = ["I->S", "I->E", "I->M",
                    "S->M", "S->I",
                    "E->M", "E->S", "E->I",
                    "M->S", "M->I"]


def fp_class(bits, width=32):
    """Classify an IEEE-754 operand for coverage binning."""
    if width == 32:
        e, f, emax = (bits >> 23) & 0xFF, bits & 0x7FFFFF, 0xFF
    else:
        e, f, emax = (bits >> 10) & 0x1F, bits & 0x3FF, 0x1F
    if e == emax:
        return "nan" if f else "inf"
    if e == 0:
        return "sub" if f else "zero"
    return "norm"


# ---------------------------------------------------------------------------
# FPU
# ---------------------------------------------------------------------------
@CoverPoint("fpu.op", xf=lambda op, rm, ca, cb: op,
            bins=["add", "mul", "fma", "mul16"])
@CoverPoint("fpu.rm", xf=lambda op, rm, ca, cb: rm, bins=[0, 1, 2, 3])
@CoverPoint("fpu.cls_a", xf=lambda op, rm, ca, cb: ca, bins=FP_CLASSES)
@CoverPoint("fpu.cls_b", xf=lambda op, rm, ca, cb: cb, bins=FP_CLASSES)
@CoverCross("fpu.op_x_rm", items=["fpu.op", "fpu.rm"],
            ign_bins=[("mul16", 1), ("mul16", 2), ("mul16", 3)])
@CoverCross("fpu.cls_a_x_b", items=["fpu.cls_a", "fpu.cls_b"])
def sample_fpu(op, rm, ca, cb):
    pass


@CoverPoint("fpu.flag", xf=lambda fl: fl,
            bins=["invalid", "overflow", "underflow", "inexact", "none"])
def sample_fpu_flag(fl):
    pass


def sample_fpu_op(op, rm, a_bits, b_bits, flags=None, width=32):
    sample_fpu(op, rm, fp_class(a_bits, width), fp_class(b_bits, width))
    if flags is not None:
        any_flag = False
        for name in ("invalid", "overflow", "underflow", "inexact"):
            if flags.get(name):
                sample_fpu_flag(name)
                any_flag = True
        if not any_flag:
            sample_fpu_flag("none")


# ---------------------------------------------------------------------------
# MESI (FSM coverage via the dbg_mesi ports)
# ---------------------------------------------------------------------------
@CoverPoint("mesi.state", xf=lambda p, n: n, bins=MESI_NAMES)
def _sample_mesi_state(p, n):
    pass


@CoverPoint("mesi.transition", xf=lambda p, n: f"{p}->{n}",
            bins=MESI_LEGAL_TRANS)
def _sample_mesi_trans(p, n):
    pass


_mesi_last = {}


def sample_mesi_state(master, addr, state_num):
    """Track per-(master,line) state; sample occupancy and transitions."""
    new = MESI_NAMES[state_num & 3]
    key = (master, addr)
    prev = _mesi_last.get(key)
    _sample_mesi_state(prev, new)
    if prev is not None and prev != new:
        _sample_mesi_trans(prev, new)
    _mesi_last[key] = new


# ---------------------------------------------------------------------------
# LSU
# ---------------------------------------------------------------------------
def _mask_kind(mask):
    n = bin(mask & 0xFFFFFFFF).count("1")
    if n == 0:
        return "empty"
    if n == 1:
        return "single"
    if n == 32:
        return "full"
    return "sparse"


def _xact_bin(n):
    if n <= 2:
        return str(n)
    if n <= 8:
        return "3-8"
    if n <= 31:
        return "9-31"
    return "32"


def _stall_bin(n):
    if n == 0:
        return "0"
    if n <= 3:
        return "1-3"
    return "4+"


@CoverPoint("lsu.mask", xf=lambda m, x, w, s: m,
            bins=["empty", "single", "sparse", "full"])
@CoverPoint("lsu.xactions", xf=lambda m, x, w, s: x,
            bins=["0", "1", "2", "3-8", "9-31", "32"])
@CoverPoint("lsu.write", xf=lambda m, x, w, s: w, bins=[0, 1])
@CoverPoint("lsu.backpressure", xf=lambda m, x, w, s: s,
            bins=["0", "1-3", "4+"])
@CoverCross("lsu.mask_x_write", items=["lsu.mask", "lsu.write"])
def _sample_lsu(mask_kind, xact_bin, write, stall_bin):
    pass


def sample_lsu_warp(mask, xactions, write, stall_cycles):
    _sample_lsu(_mask_kind(mask), _xact_bin(xactions),
                1 if write else 0, _stall_bin(stall_cycles))


# ---------------------------------------------------------------------------
# TMU
# ---------------------------------------------------------------------------
def _frac_bin(f):
    if f == 0:
        return "min"
    if f == 255:
        return "max"
    return "mid"


@CoverPoint("tmu.fmt", xf=lambda f, m, u, v: f, bins=[0, 1, 2])
@CoverPoint("tmu.mode", xf=lambda f, m, u, v: m, bins=["wrap", "clamp"])
@CoverPoint("tmu.ufrac", xf=lambda f, m, u, v: u, bins=["min", "mid", "max"])
@CoverPoint("tmu.vfrac", xf=lambda f, m, u, v: v, bins=["min", "mid", "max"])
@CoverCross("tmu.fmt_x_mode", items=["tmu.fmt", "tmu.mode"])
def _sample_tmu(fmt, mode, ub, vb):
    pass


def sample_tmu(fmt, clamp, uf, vf):
    _sample_tmu(fmt, "clamp" if clamp else "wrap",
                _frac_bin(uf & 0xFF), _frac_bin(vf & 0xFF))


# ---------------------------------------------------------------------------
# export
# ---------------------------------------------------------------------------
_registered = []


def export_on_exit(suite):
    """Write <suite>_coverage.yml and log a summary at process exit."""
    if suite in _registered:
        return
    _registered.append(suite)

    def _export():
        path = os.path.join(HERE, f"{suite}_coverage.yml")
        try:
            coverage_db.export_to_yaml(filename=path)
        except Exception as exc:  # never fail the sim on report writing
            print(f"[coverage] export failed: {exc}")
            return
        print(f"[coverage] functional coverage written to {path}")
        for name in sorted(coverage_db):
            item = coverage_db[name]
            size = getattr(item, "size", 0)
            # only this suite's groups (the db is global per process)
            if size and name.startswith(f"{suite}."):
                print(f"[coverage]   {name:20s} "
                      f"{item.coverage}/{size} "
                      f"({item.cover_percentage:.0f}%)")

    atexit.register(_export)
