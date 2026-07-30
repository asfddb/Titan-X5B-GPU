#!/usr/bin/env python3
"""Static leakage of a mapped netlist, from GT2N's own Liberty data.

Yosys has no power analysis and OpenSTA is not installed, so DYNAMIC power
(alpha*C*Vdd^2*f) cannot be computed here at all. Leakage can: every GT2N
cell carries `cell_leakage_power` in uW, and `stat -liberty` gives exact
cell counts. Multiplying the two is a real measurement, not an estimate.

    python syn/gt2n/leakage.py <yosys.log> <liberty.lib>
"""
import re
import sys


def cell_leakage(lib_path):
    """cell name -> leakage in uW (leakage_power_unit is 1uW in GT2N)."""
    out, cur = {}, None
    with open(lib_path, errors="ignore") as fh:
        for line in fh:
            m = re.match(r"\s*cell\(([^)]+)\)", line)
            if m:
                cur = m.group(1)
                continue
            if cur:
                m = re.match(r"\s*cell_leakage_power\s*:\s*([0-9.eE+-]+)", line)
                if m:
                    out[cur] = float(m.group(1))
                    cur = None
    return out


def counts(log_path):
    """cell name -> instance count, from the final `stat -liberty` block."""
    out = {}
    for line in open(log_path, errors="ignore"):
        m = re.match(r"\s*(\d+)\s+[0-9.]+\s+(gt2_6t_\S+)", line)
        if m:
            out[m.group(2)] = int(m.group(1))
    return out


def main():
    log, lib = sys.argv[1], sys.argv[2]
    leak, cnt = cell_leakage(lib), counts(log)
    total = 0.0
    seq = 0.0
    missing = []
    for cell, n in sorted(cnt.items()):
        if cell not in leak:
            missing.append(cell)
            continue
        p = n * leak[cell]
        total += p
        if "dff" in cell:
            seq += p
    print(f"cells      : {sum(cnt.values()):>12,}")
    print(f"leakage    : {total:>12,.1f} uW  ({total/1000:.3f} mW)")
    if total:
        print(f"  sequential: {seq:>10,.1f} uW  ({100*seq/total:.1f}%)")
        print(f"  combinat. : {total-seq:>10,.1f} uW  ({100*(total-seq)/total:.1f}%)")
    if missing:
        print(f"NOTE: no leakage data for {len(missing)} cell type(s): "
              f"{', '.join(missing[:4])}")


if __name__ == "__main__":
    main()
