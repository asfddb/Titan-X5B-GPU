# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Bring the Titan X5 display path up on a Basys 3, without a Basys 3.

WHY

`docs/FPGA_PHASE1_REPORT.md` section 6 names the display-path bitstream as the
one subset of this GPU that actually fits an xc7a35t, and calls it the route to
"Hardware Hello World". That has been blocked on owning the board and on Vivado
for a bitstream. Most of what the board would have told us does not need the
board:

  - does it come up on its own when power is applied, with nothing pressed
  - is there a signal on the VGA connector, and does it meet the mode standard
  - what does the picture actually look like
  - do the buttons and switches do what the silkscreen says
  - does the *synthesised netlist* behave like the RTL did

The last one is the part a normal testbench cannot reach, and it is the reason
this flow exists rather than another `iverilog tb/*.v`. Between RTL and gates
sits every assumption the synthesiser does not share: registers that were only
ever initialised by a testbench, resets that never actually reach a flop, logic
that simulated cleanly because X propagated somewhere convenient. On a real
board you find those the hard way, with a monitor that stays black. Here they
show up as a diff between two frame captures.

HOW

  1. Build and run tb/tb_board_bringup.v against the RTL. That testbench is
     wired to the *board connectors* -- 100 MHz clock, buttons, switches, LEDs
     and the five VGA wires -- and contains no hierarchical reference into the
     design. tb/tb_display_top.v remains the RTL-level unit test; this is the
     bench test.
  2. Synthesise the same design to Artix-7 cells with yosys.
  3. Run the identical testbench against the netlist, with yosys's Xilinx
     primitive models. Those models carry the INIT values configuration loads
     into every flop, so this run -- not the RTL one -- is what the board does
     at power-on.
  4. Compare the two frame captures pixel for pixel, and both against the
     pattern the boot writer was asked to store.

Nothing here needs Vivado. A .bit still does, and place-and-route timing is
still unmeasured -- there is no open-source 7-series PnR on this machine, so
whether the design closes at 100 MHz is unknown.

USAGE

  python tools/run_fpga_bringup.py                # everything
  python tools/run_fpga_bringup.py --quick        # power-on frame only
  python tools/run_fpga_bringup.py --stage rtl    # skip synthesis and gates
  python tools/run_fpga_bringup.py --skip-synth   # reuse an existing netlist
"""
import argparse
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent

# Neither toolchain is on PATH on this machine. Yosys additionally needs its
# lib/ directory there, because it loads DLLs from it at startup.
IVERILOG_DIR = Path(os.environ.get("TITAN_IVERILOG_DIR", r"C:\iverilog\bin"))
OSS_CAD_DIR = Path(os.environ.get("TITAN_OSS_CAD_DIR", r"C:\eda\oss-cad-suite"))

NETLIST = REPO / "syn" / "netlists" / "titan_x5_display_top_xc7.v"
CELLS_SIM = OSS_CAD_DIR / "share" / "yosys" / "xilinx" / "cells_sim.v"

RTL_SOURCES = [
    "rtl/xilinx_stubs.v",
    "rtl/memory/titan_x5_vram_ctrl.v",
    "rtl/display/titan_x5_async_fifo.v",
    "rtl/display/titan_x5_display_engine.v",
    "fpga/titan_x5_display_top.v",
]
BENCH_SOURCES = [
    "tb/board/basys3_board.v",
    "tb/board/vga_monitor.v",
    "tb/tb_board_bringup.v",
]

# Frames the testbench captures, and the pattern each one should hold. A reset
# press clears pattern_sel, so the post-reset frame is pattern 0 again.
FRAMES = [
    ("frame_boot.ppm", 0),
    ("frame_after_reset.ppm", 0),
    ("frame_pattern1.ppm", 1),
    ("frame_pattern2.ppm", 2),
    ("frame_pattern3.ppm", 3),
]


def tool(name, directory):
    """Resolve a tool from its known directory, falling back to PATH."""
    exe = directory / (name + (".exe" if os.name == "nt" else ""))
    if exe.exists():
        return str(exe)
    found = shutil.which(name)
    if found:
        return found
    sys.exit(f"cannot find {name}: not in {directory} and not on PATH")


def run(cmd, cwd=None, env=None, log=None):
    """Run a command, streaming nothing, returning (rc, output)."""
    t0 = time.time()
    p = subprocess.run(cmd, cwd=cwd or REPO, env=env, capture_output=True,
                       text=True, errors="replace")
    out = p.stdout + p.stderr
    if log:
        Path(log).write_text(out, encoding="utf-8")
    return p.returncode, out, time.time() - t0


def banner(text):
    print()
    print("=" * 70)
    print(f" {text}")
    print("=" * 70)


def build_and_run(label, sources, outdir, quick, top_src_note):
    """Compile tb_board_bringup against `sources` and run it."""
    iverilog = tool("iverilog", IVERILOG_DIR)
    vvp = tool("vvp", IVERILOG_DIR)

    outdir.mkdir(parents=True, exist_ok=True)
    vvp_path = outdir / f"bringup_{label}.vvp"

    print(f"  compiling ({top_src_note})...")
    rc, out, dt = run([iverilog, "-g2012", "-s", "tb_board_bringup",
                       "-o", str(vvp_path)] + sources)
    if rc != 0:
        print(out)
        return False, "compile failed"
    print(f"  compiled in {dt:.1f}s")

    args = [vvp, str(vvp_path), f"+outdir={outdir.name}"]
    if quick:
        args.append("+quick")
    print(f"  simulating...")
    rc, out, dt = run(args, cwd=outdir.parent, log=outdir / "bringup.log")
    print(out.rstrip())
    print(f"  simulated in {dt/60:.1f} min")

    if "BRING-UP PASSED" in out:
        return True, "all checks passed"
    if "BRING-UP FAILED" in out:
        line = [l for l in out.splitlines() if "BRING-UP FAILED" in l]
        return False, line[0].strip() if line else "failed"
    return False, "simulation did not reach a verdict"


def synthesize():
    yosys = tool("yosys", OSS_CAD_DIR / "bin")
    env = dict(os.environ)
    env["PATH"] = os.pathsep.join(
        [str(OSS_CAD_DIR / "bin"), str(OSS_CAD_DIR / "lib"), env.get("PATH", "")])
    NETLIST.parent.mkdir(parents=True, exist_ok=True)
    log = NETLIST.parent / "synth_display.log"
    print("  running yosys synth_xilinx -family xc7 ...")
    rc, out, dt = run([yosys, "-l", str(log), "fpga/synth_display_basys3.ys"],
                      env=env)
    if rc != 0 or not NETLIST.exists():
        print(out[-4000:])
        return False, "synthesis failed"
    print(f"  synthesised in {dt:.1f}s -> {NETLIST.relative_to(REPO)}")

    # Report the totals the log already measured, against the xc7a35t budget.
    text = log.read_text(encoding="utf-8", errors="replace")
    tail = text.split("=== design hierarchy ===")[-1]
    counts = {}
    for line in tail.splitlines():
        parts = line.split()
        if len(parts) == 2 and parts[0].isdigit() and parts[1].isupper():
            counts[parts[1]] = int(parts[0])
    luts = sum(v for k, v in counts.items() if k.startswith("LUT"))
    ffs = sum(v for k, v in counts.items() if k.startswith("FD"))
    print(f"  measured: {luts} LUT / {ffs} FF / "
          f"{counts.get('RAMB36E1', 0)} RAMB36 / {counts.get('DSP48E1', 0)} DSP48")
    print(f"  xc7a35t : 20800 LUT / 41600 FF / 50 BRAM36 / 90 DSP48")
    return True, f"{luts} LUT, {ffs} FF, {counts.get('RAMB36E1', 0)} BRAM36"


def check_frames(outdir, quick):
    """Every captured frame against the pattern it should be holding."""
    checker = REPO / "tb" / "board" / "check_frame.py"
    results = []
    for name, pat in (FRAMES[:1] if quick else FRAMES):
        ppm = outdir / name
        if not ppm.exists():
            continue
        png = ppm.with_suffix(".png")
        rc, out, _ = run([sys.executable, str(checker), "check", str(ppm),
                          "--pattern", str(pat), "--png", str(png)])
        print(out.rstrip())
        results.append((name, rc == 0))
    return results


def diff_frames(rtl_dir, gate_dir, quick):
    """RTL capture against gate-level capture, pixel for pixel."""
    checker = REPO / "tb" / "board" / "check_frame.py"
    results = []
    for name, _ in (FRAMES[:1] if quick else FRAMES):
        a, b = rtl_dir / name, gate_dir / name
        if not (a.exists() and b.exists()):
            print(f"  {name}: missing on one side, cannot diff")
            results.append((name, False))
            continue
        png = gate_dir / (Path(name).stem + "_diff.png")
        rc, out, _ = run([sys.executable, str(checker), "diff", str(a), str(b),
                          "--png", str(png)])
        print(out.rstrip())
        results.append((name, rc == 0))
    return results


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--outdir", default="bringup_out",
                    help="directory for frames, logs and the netlist run")
    ap.add_argument("--quick", action="store_true",
                    help="power-on frame only; skip the button and pattern tests")
    ap.add_argument("--stage", choices=["rtl", "synth", "gate", "all"],
                    default="all")
    ap.add_argument("--skip-synth", action="store_true",
                    help="reuse the existing netlist instead of re-running yosys")
    args = ap.parse_args()

    root = (REPO / args.outdir) if not Path(args.outdir).is_absolute() \
        else Path(args.outdir)
    rtl_dir, gate_dir = root / "rtl", root / "gate"
    summary = []

    if args.stage in ("rtl", "all"):
        banner("1. RTL, driven at the board connectors")
        ok, msg = build_and_run("rtl", RTL_SOURCES + BENCH_SOURCES,
                                rtl_dir, args.quick, "RTL sources")
        summary.append(("RTL bring-up", ok, msg))
        if (rtl_dir / FRAMES[0][0]).exists():
            banner("2. RTL frames against the expected pattern")
            for name, good in check_frames(rtl_dir, args.quick):
                summary.append((f"RTL frame {name}", good, ""))

    if args.stage in ("synth", "gate", "all"):
        banner("3. Synthesis to Artix-7 cells")
        if args.skip_synth and NETLIST.exists():
            print(f"  reusing {NETLIST.relative_to(REPO)}")
            summary.append(("Synthesis", True, "reused existing netlist"))
        else:
            ok, msg = synthesize()
            summary.append(("Synthesis", ok, msg))
            if not ok:
                report(summary)
                return 1

    if args.stage in ("gate", "all"):
        if not CELLS_SIM.exists():
            sys.exit(f"cannot find Xilinx primitive models at {CELLS_SIM}")
        banner("4. The netlist, driven at the same connectors")
        ok, msg = build_and_run("gate", [str(CELLS_SIM), str(NETLIST)] +
                                BENCH_SOURCES, gate_dir, args.quick,
                                "post-synthesis netlist + Xilinx primitives")
        summary.append(("Gate-level bring-up", ok, msg))
        if (gate_dir / FRAMES[0][0]).exists():
            banner("5. Gate-level frames against the expected pattern")
            for name, good in check_frames(gate_dir, args.quick):
                summary.append((f"gate frame {name}", good, ""))

    if args.stage == "all" and (rtl_dir / FRAMES[0][0]).exists() \
            and (gate_dir / FRAMES[0][0]).exists():
        banner("6. RTL capture vs netlist capture")
        for name, same in diff_frames(rtl_dir, gate_dir, args.quick):
            summary.append((f"RTL==gate {name}", same, ""))

    return report(summary)


def report(summary):
    banner("Summary")
    width = max((len(n) for n, _, _ in summary), default=10)
    bad = 0
    for name, ok, msg in summary:
        mark = "PASS" if ok else "FAIL"
        if not ok:
            bad += 1
        print(f"  {mark}  {name.ljust(width)}  {msg}")
    print()
    print(f"  {len(summary) - bad}/{len(summary)} stages passed")
    print()
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
