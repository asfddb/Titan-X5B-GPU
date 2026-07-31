# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Drive tb_compute_top: compile a program, run it on the RTL, read results.

This is the plumbing shared by the compute kernel tests. It owns nothing about
what a kernel means -- it compiles, runs, and hands back words.

The RTL is the only thing under test here; expected values always come from
compiler/titan_compiler.py's reference simulator (itself a Python twin of
driver/titan_x6_gpu_model.c) or from NumPy, never from this file.
"""

import os
import shutil
import subprocess
import sys
import tempfile

TB = os.path.abspath(os.path.dirname(__file__))
ROOT = os.path.abspath(os.path.join(TB, ".."))
RTL = os.path.join(ROOT, "rtl")
sys.path.insert(0, os.path.join(ROOT, "compiler"))

# Must match the localparams in tb_compute_top.v.
CODE_BASE = 0x0020_0000
DATA_BASE = 0x0040_0000
PARAM_BASE = 0x0060_0000

_BUILD_DIR = os.path.join(TB, "sim_build", "compute")


def _sim_path(warp_mask):
    return os.path.join(_BUILD_DIR, f"compute_w{warp_mask:02x}.vvp")


def _tool(name):
    """Locate a toolchain binary, allowing for a non-PATH Icarus install."""
    found = shutil.which(name)
    if found:
        return found
    for cand in (rf"C:\iverilog\bin\{name}.exe", f"/usr/bin/{name}"):
        if os.path.exists(cand):
            return cand
    raise RuntimeError(f"{name} not found on PATH")


def _sources():
    """Every Verilog file that goes into the compute image."""
    out = [os.path.join(TB, "tb_compute_top.v")]
    for sub in sorted(os.listdir(RTL)):
        d = os.path.join(RTL, sub)
        if os.path.isdir(d):
            out += [os.path.join(d, f) for f in sorted(os.listdir(d))
                    if f.endswith(".v")]
    out += [os.path.join(RTL, f) for f in sorted(os.listdir(RTL))
            if f.endswith(".v")]
    return out


def build(warp_mask=0x01, force=False):
    """Elaborate tb_compute_top for a launch mask; reused across kernels.

    LAUNCH_WARP_MASK is a parameter of titan_x5_gpu_top, not a runtime input,
    so each mask needs its own elaborated image.

    The image is reused only while it is NEWER than every source that went
    into it. It used to be reused whenever it merely existed, which meant an
    RTL change was silently not tested: a stale image from a previous session
    kept passing, and a control experiment that disabled a feature entirely
    still came back green. Elaboration is ~30 s against a suite that runs for
    minutes, so the staleness check is cheap insurance.
    """
    sim = _sim_path(warp_mask)
    sources = _sources()
    if os.path.exists(sim) and not force:
        newest = max(os.path.getmtime(s) for s in sources)
        if os.path.getmtime(sim) >= newest:
            return sim
    os.makedirs(_BUILD_DIR, exist_ok=True)
    cmd = [_tool("iverilog"), "-g2012", "-s", "tb_compute_top",
           "-P", f"tb_compute_top.LAUNCH_MASK={warp_mask}",
           "-I", RTL, "-o", sim] + sources
    proc = subprocess.run(cmd, capture_output=True, text=True)
    errs = [l for l in (proc.stderr or "").splitlines() if "error" in l.lower()]
    if proc.returncode != 0 or errs:
        raise RuntimeError("elaboration failed:\n" + "\n".join(errs[:20]))
    return sim


class Result:
    def __init__(self, words, cycles, timed_out, pred_divergent, log):
        self.words = words
        self.cycles = cycles
        self.timed_out = timed_out
        self.pred_divergent = pred_divergent
        self.log = log


def run(program, n_res, data=None, params=None, warp_regs=None,
        res_base=DATA_BASE, max_cycles=2_000_000, timeout_s=1800,
        warp_mask=0x01):
    """Run `program` (list of 32-bit words) on the RTL, return `n_res` words.

    `data`      optional list of 32-bit words loaded at DATA_BASE.
    `params`    optional kernel parameter block loaded at PARAM_BASE, which the
                compiler's prologue reads through R1 (TX6_REG_PARAM).
    `warp_regs` optional [(warp, reg, value), ...] deposited into that warp's
                register set (broadcast across lanes, applied to every SM).
                Use it to give warps DIFFERENT state -- without that, every
                warp runs identical work and cross-warp bugs stay invisible.
    """
    sim = build(warp_mask)
    tmp = tempfile.mkdtemp(prefix="titan_compute_")
    try:
        prog_path = os.path.join(tmp, "prog.hex")
        out_path = os.path.join(tmp, "out.txt")
        with open(prog_path, "w") as f:
            f.write("".join(f"{w & 0xFFFFFFFF:08x}\n" for w in program))

        args = [_tool("vvp"), sim,
                f"+PROG={prog_path}",
                f"+OUT={out_path}",
                f"+NPROG={len(program)}",
                f"+NRES={n_res}",
                f"+RESBASE={res_base:08x}",
                f"+MAXCYC={max_cycles}"]

        if data:
            data_path = os.path.join(tmp, "data.hex")
            with open(data_path, "w") as f:
                f.write("".join(f"{w & 0xFFFFFFFF:08x}\n" for w in data))
            args += [f"+DATA={data_path}", f"+NDATA={len(data)}"]

        if params:
            param_path = os.path.join(tmp, "param.hex")
            with open(param_path, "w") as f:
                f.write("".join(f"{w & 0xFFFFFFFF:08x}\n" for w in params))
            args += [f"+PARAM={param_path}", f"+NPARAM={len(params)}"]

        if warp_regs:
            flat = []
            for warp, reg, value in warp_regs:
                flat += [warp, reg, value]
            wreg_path = os.path.join(tmp, "wregs.hex")
            with open(wreg_path, "w") as f:
                f.write("".join(f"{w & 0xFFFFFFFF:08x}\n" for w in flat))
            args += [f"+WREGS={wreg_path}", f"+NWREG={len(flat)}"]

        proc = subprocess.run(args, capture_output=True, text=True,
                              timeout=timeout_s)
        log = (proc.stdout or "") + (proc.stderr or "")
        if not os.path.exists(out_path):
            raise RuntimeError("simulation produced no result file:\n" + log)
        with open(out_path) as f:
            lines = [l.strip() for l in f if l.strip()]
        timed_out, cycles, divergent = (int(x) for x in lines[0].split())
        words = [int(l, 16) for l in lines[1:]]
        return Result(words, cycles, bool(timed_out), bool(divergent), log)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
