#!/usr/bin/env python3
"""Summarize per-block yosys synth_xilinx stat reports into one table.

Reads syn/reports/blocks/*.stat (written by synth_blocks.sh) and emits a
markdown table of LUT-equivalents (yosys "Estimated number of LCs"),
flip-flops, BRAM and DSP counts, sorted by size, with the Basys 3
xc7a35t budget for comparison.

Usage (from repo root):  python syn/scripts/summarize_blocks.py
"""
import glob
import os
import re
import sys

BLOCKS_DIR = os.path.join("syn", "reports", "blocks")

# xc7a35t (Basys 3) budget
BUDGET = {"LC": 20800, "FF": 41600, "BRAM36": 50, "DSP": 90}

FF_CELLS = ("FDRE", "FDCE", "FDSE", "FDPE")
LUTRAM_RE = re.compile(r"RAM(\d+)[SMX]\d*")


def parse_stat(path):
    """Parse the FINAL stats section (whole-design rollup) of a .stat file."""
    text = open(path).read()
    # stat prints one section per module; the last "Number of cells:" block
    # is the top module including all submodules.
    sections = text.split("Number of cells:")
    if len(sections) < 2:
        return None
    tail = sections[-1]
    cells = {}
    for line in tail.splitlines():
        m = re.match(r"\s{4,}(\S+)\s+(\d+)$", line)
        if m:
            cells[m.group(1)] = int(m.group(2))
    lc = 0
    m = re.search(r"Estimated number of LCs:\s+(\d+)", tail)
    if m:
        lc = int(m.group(1))
    ff = sum(v for k, v in cells.items() if k in FF_CELLS)
    bram36 = cells.get("RAMB36E1", 0) + cells.get("RAMB18E1", 0) / 2.0
    dsp = cells.get("DSP48E1", 0)
    lutram = sum(v for k, v in cells.items() if LUTRAM_RE.fullmatch(k))
    return {"LC": lc, "FF": ff, "BRAM36": bram36, "DSP": dsp, "LUTRAM": lutram}


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(BLOCKS_DIR, "*.stat"))):
        name = os.path.splitext(os.path.basename(path))[0]
        r = parse_stat(path)
        if r is None:
            print(f"warning: no stats found in {path}", file=sys.stderr)
            continue
        rows.append((name, r))

    rows.sort(key=lambda x: -x[1]["LC"])

    print("| block | LUT-eq (LC) | FF | BRAM36 | DSP48 | LUTRAM cells |")
    print("|---|---:|---:|---:|---:|---:|")
    for name, r in rows:
        print(
            f"| {name} | {r['LC']:,} | {r['FF']:,} | {r['BRAM36']:g} "
            f"| {r['DSP']} | {r['LUTRAM']} |"
        )
    print(
        f"| **xc7a35t budget** | **{BUDGET['LC']:,}** | **{BUDGET['FF']:,}** "
        f"| **{BUDGET['BRAM36']}** | **{BUDGET['DSP']}** | - |"
    )


if __name__ == "__main__":
    main()
