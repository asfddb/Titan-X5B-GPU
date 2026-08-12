# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Lint the whole design against the checks that actually matter for silicon.

WHY THIS EXISTS AND WHY IT IS NOT THE COMMAND IN THE HANDOFF

`docs/HANDOFF_NEXT_SESSION.md` gives a verilator command that suppresses
`-Wno-LATCH`, `-Wno-UNDRIVEN` and `-Wno-SYNCASYNCNET`. Those three are not
style preferences. An inferred latch, a net with no driver and a reset flopped
in two domains are three of the most common reasons a chip comes back dead.
Suppressing them makes the gate green and the silicon wrong.

Worse, the gate was not running at all. `rtl/core/titan_x7_sm.v` contained a
prose comment whose second line began with the linter's own name:

    // blocking assigns: reset-only array init (see L2 note on
    // Verilator BLKLOOPINIT)

Verilator parses *any* comment beginning with its name as a metacomment
pragma, so that sentence became `/*verilator BLKLOOPINIT)*/`, an unknown
pragma, and v5 aborted the entire lint before checking a single line. v4 --
which the CI job pinned -- did not, so lint stayed green while checking
nothing. The identical trap had already been hit once in
`rtl/memory/titan_x5_l1_cache.v`, where a warning comment about it survives;
the same mistake was still live in the X7 SM.

SEVERITY, HONESTLY

Findings are triaged rather than counted, because a raw count invites both
panic and complacency. In particular `MULTIDRIVENPROC` reads alarming and, in
this design, is currently 19 shared `integer` loop indices -- `r`, `c`, `i`,
`w` declared once and reused across always blocks. Synthesis unrolls those, so
they are a portability and code-hygiene problem, not multiple drivers on a
wire. Calling them tapeout blockers would be wrong, and this script says so.

USAGE

  python tools/asic_lint.py                 # summary
  python tools/asic_lint.py --detail        # every finding
  python tools/asic_lint.py --top titan_x5_gpu_top
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
OSS_CAD = Path(os.environ.get("TITAN_OSS_CAD_DIR", r"C:\eda\oss-cad-suite"))

# Severity. The question each class answers is "would this make the chip wrong
# or dead", not "is it untidy".
BLOCKER = {
    "LATCH":        "inferred latch -- no clock, unbounded hold, kills timing closure",
    "UNDRIVEN":     "net has no driver; it is X on real silicon, not 0",
    "MULTIDRIVEN":  "two drivers on one net",
    "IMPLICIT":     "undeclared net auto-created as 1 bit wide",
    "SYNCASYNCNET": "reset flopped both synchronously and asynchronously "
                    "-- a reset-domain crossing, metastable on release",
    "COMBDLY":      "non-blocking assignment in combinational logic",
    "ALWCOMBORDER": "combinational block reads a value it writes later",
}
SERIOUS = {
    "WIDTHTRUNC":       "bits silently dropped by an assignment",
    "PINMISSING":       "instance port left unconnected -- floats on ASIC",
    "BLKSEQ":           "blocking assignment inside a clocked block",
    "CASEINCOMPLETE":   "case without full coverage or a default",
    "CASEX":            "casex/casez treats X as a wildcard",
    "MULTIDRIVENPROC":  "variable written from two always blocks "
                        "(shared loop indices are benign; real signals are not)",
}
COSMETIC = {
    "WIDTHEXPAND":  "operand zero-extended",
    "UNUSEDSIGNAL": "signal never read",
    "UNUSEDPARAM":  "parameter never used",
    "VARHIDDEN":    "inner declaration shadows an outer one",
    "GENUNNAMED":   "unlabelled generate block",
    "DECLFILENAME": "module name does not match its filename",
    "EOFNEWLINE":   "no newline at end of file",
    "PINCONNECTEMPTY": "port deliberately left empty",
}

# Suppressed outright: noise that says nothing about the silicon.
SUPPRESS = ["DECLFILENAME", "EOFNEWLINE", "PINCONNECTEMPTY"]


def tool(name):
    exe = OSS_CAD / "bin" / (name + (".exe" if os.name == "nt" else ""))
    if exe.exists():
        return str(exe)
    found = shutil.which(name)
    if found:
        return found
    sys.exit(f"cannot find {name}")


def sources(top):
    """Every RTL file except the FPGA wrapper, which has its own top."""
    out = []
    for p in sorted((REPO / "rtl").rglob("*.v")):
        if p.name == "titan_x5_fpga_top.v":
            continue
        out.append(str(p))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--top", default="titan_x5_gpu_top")
    ap.add_argument("--detail", action="store_true")
    ap.add_argument("--fail-on", choices=["blocker", "serious", "any", "never"],
                    default="blocker",
                    help="exit non-zero at this severity (default: blocker)")
    args = ap.parse_args()

    env = dict(os.environ)
    env["PATH"] = os.pathsep.join(
        [str(OSS_CAD / "bin"), str(OSS_CAD / "lib"), env.get("PATH", "")])
    # verilator_bin is invoked directly: the `verilator` wrapper is a Perl
    # script and this install has no Pod::Usage. VERILATOR_ROOT must be set
    # because the binary was built with a path that does not exist here.
    env["VERILATOR_ROOT"] = str(OSS_CAD / "share" / "verilator")

    cmd = [tool("verilator_bin"), "--lint-only", "-Wall",
           "-Wno-UNUSEDSIGNAL", "-Wno-UNUSEDPARAM", "-Wno-VARHIDDEN",
           "-Wno-GENUNNAMED", "-Wno-MULTITOP"]
    cmd += [f"-Wno-{w}" for w in SUPPRESS]
    cmd += ["--top-module", args.top] + sources(args.top)

    p = subprocess.run(cmd, cwd=REPO, env=env, capture_output=True,
                       text=True, errors="replace")
    text = p.stdout + p.stderr

    # A hard %Error means the lint did not run -- which is the failure mode
    # that hid everything until now, so it is reported loudly rather than
    # folded into the counts.
    fatal = [l for l in text.splitlines()
             if l.startswith("%Error") and "Exiting due to" not in l]
    if fatal:
        print("  LINT DID NOT RUN -- verilator refused the sources:")
        for l in fatal[:10]:
            print(f"    {l}")
        print()
        print("  Nothing below was checked. Fix these first.")
        return 2

    findings = defaultdict(list)
    for line in text.splitlines():
        m = re.match(r"%Warning-([A-Z0-9_]+):\s*(.*)", line)
        if m:
            findings[m.group(1)].append(m.group(2))

    def band(name):
        if name in BLOCKER:
            return "BLOCKER"
        if name in SERIOUS:
            return "SERIOUS"
        return "COSMETIC"

    counts = Counter({k: len(v) for k, v in findings.items()})
    print()
    print(f"  Titan ASIC lint -- top {args.top}, {len(sources(args.top))} files")
    print("  " + "=" * 68)
    totals = Counter()
    for sev in ("BLOCKER", "SERIOUS", "COSMETIC"):
        rows = [(n, c) for n, c in counts.most_common() if band(n) == sev]
        if not rows:
            continue
        print(f"\n  {sev}")
        for name, c in rows:
            why = BLOCKER.get(name) or SERIOUS.get(name) or COSMETIC.get(name, "")
            print(f"    {c:4d}  {name:<18} {why}")
            totals[sev] += c
            if args.detail:
                for f in findings[name][:40]:
                    print(f"          {f}")
    print()
    print("  " + "=" * 68)
    print(f"  {totals['BLOCKER']} blocker, {totals['SERIOUS']} serious, "
          f"{totals['COSMETIC']} cosmetic")
    print()

    if args.fail_on == "never":
        return 0
    if args.fail_on == "blocker":
        return 1 if totals["BLOCKER"] else 0
    if args.fail_on == "serious":
        return 1 if totals["BLOCKER"] or totals["SERIOUS"] else 0
    return 1 if sum(totals.values()) else 0


if __name__ == "__main__":
    sys.exit(main())
