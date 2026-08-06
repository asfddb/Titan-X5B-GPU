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


def sm_flavour():
    """Which SM titan_x5_gpu_top is built with: "x5" (default) or "x7".

    Set TITAN_SM=x7 to build the dual-issue X7 core in via
    titan_x7_sm_shim. Kept an environment switch rather than an argument so
    the whole deep suite can be run both ways without editing any test.
    """
    v = os.environ.get("TITAN_SM", "x5").strip().lower()
    if v not in ("x5", "x7"):
        raise RuntimeError(f"TITAN_SM must be x5 or x7, got {v!r}")
    return v


def icache_on():
    """Whether the build includes the per-SM instruction cache.

    TITAN_ICACHE=0 restores the pre-cache behaviour (every instruction fetch
    is its own crossbar round trip) so the two can be measured against each
    other on one tree.
    """
    # Default OFF: the block has an open bug in the chip (multi-line compute
    # kernels return 0). See the note in rtl/titan_x5_gpu_top.v.
    return os.environ.get("TITAN_ICACHE", "0").strip() in ("1", "on", "yes")


def _sim_path(warp_mask):
    # The SM flavour is part of the image identity, not just the warp mask.
    # Without it, flipping TITAN_SM changes no source file, so the mtime reuse
    # check below would hand back an image built for the OTHER core and the
    # suite would silently report the previous SM's results. That is exactly
    # the stale-image failure recorded in docs/BUILD_LOG_2NM.md, where a
    # control experiment passed when it should have failed.
    ic = "ic" if icache_on() else "noic"
    # Extra defines are part of the image identity for the same reason the SM
    # flavour is: they change no source file, so without them in the name the
    # mtime reuse check below would hand back an image built without them.
    xd = extra_defines()
    # `=` and other punctuation from -DNAME=value defines are stripped so the
    # image name stays a plain filename on every platform.
    safe = ["".join(c if c.isalnum() else "_" for c in d) for d in sorted(xd)]
    suffix = ("_" + "_".join(safe)) if safe else ""
    return os.path.join(_BUILD_DIR,
                        f"compute_{sm_flavour()}_{ic}_w{warp_mask:02x}"
                        f"{suffix}.vvp")


def extra_defines():
    """Extra `define names for the build, from TITAN_DEFINES (comma separated).

    For diagnostics that must not be in the default image, e.g.
    TITAN_DEFINES=TITAN_FETCH_TRACE to dump the fetch stream.
    """
    raw = os.environ.get("TITAN_DEFINES", "").strip()
    return [d.strip() for d in raw.split(",") if d.strip()]


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
    # TITAN_FAST_SIM selects the behavioural titan_x7_prefix_add and
    # titan_x7_lzc. It is unconditional because the X7 build instantiates
    # titan_x7_fp32_fma_pipe PER LANE -- 32 per SM, 128 across the chip -- and
    # the structural forms cost roughly 250x simulation time (docs/
    # GT2N_2NM_SYNTHESIS.md 7.4), which this suite cannot absorb. Both forms
    # are SAT-proven identical, and run_regression.py already builds this way.
    # Synthesis never defines it: syn/gt2n/run_gt2n.sh builds the structural
    # RTL, which is what every 2 nm timing number is measured on.
    #
    # For the x5 build this changes nothing -- the x5 chip instantiates
    # neither primitive -- so the before/after comparison stays matched.
    cmd = [_tool("iverilog"), "-g2012", "-s", "tb_compute_top",
           "-DTITAN_FAST_SIM",
           "-P", f"tb_compute_top.LAUNCH_MASK={warp_mask}",
           "-I", RTL, "-o", sim]
    if sm_flavour() == "x7":
        cmd.insert(4, "-DTITAN_USE_X7_SM")
    if icache_on():
        cmd.insert(4, "-DTITAN_USE_ICACHE")
    for d in extra_defines():
        cmd.insert(4, f"-D{d}")
    cmd += sources
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
        # Exact per-kernel cycle count, tagged with the SM it ran on. This is
        # the honest scoreboard for comparing SMs: the full-chip render test's
        # "Total Clock Cycles" is quantised to its 1000-cycle quiesce window
        # and cannot resolve a difference smaller than that (see the note in
        # tb/tb_titan_x5_gpu_top.v). Visible under `pytest -s`; grep TITAN_CYCLES.
        print(f"TITAN_CYCLES sm={sm_flavour()} "
              f"icache={'on' if icache_on() else 'off'} "
              f"warps={warp_mask:#04x} cycles={cycles} "
              f"timed_out={bool(timed_out)}", flush=True)
        return Result(words, cycles, bool(timed_out), bool(divergent), log)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
