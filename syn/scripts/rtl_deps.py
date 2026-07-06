#!/usr/bin/env python3
"""Print the RTL files needed to elaborate a given top module.

Scans the synthesizable file list in fpga/synth_fpga_top.ys, builds a
module -> file map and an instantiation graph, then emits the transitive
closure of files for the requested top (one path per line).

Usage (from repo root):  python syn/scripts/rtl_deps.py <top_module>
"""
import re
import sys


def main():
    top = sys.argv[1]

    files = []
    for line in open("fpga/synth_fpga_top.ys"):
        m = re.match(r"read_verilog\s+(\S+)", line)
        if m:
            files.append(m.group(1))

    defines = {}   # module name -> file
    text = {}      # file -> source text (comments stripped)
    for f in files:
        src = open(f, encoding="utf-8", errors="replace").read()
        src = re.sub(r"//[^\n]*", "", src)
        src = re.sub(r"/\*.*?\*/", "", src, flags=re.S)
        text[f] = src
        for mod in re.findall(r"^\s*module\s+([A-Za-z_]\w*)", src, flags=re.M):
            defines[mod] = f

    if top not in defines:
        sys.exit(f"error: module {top} not defined in the file list")

    # instantiation graph: module -> set of instantiated known modules
    names = sorted(defines, key=len, reverse=True)
    # matches "mod #(...)" (parameterized) or "mod inst_name (" (plain);
    # requiring an identifier before "(" avoids matching module headers
    pat = re.compile(
        r"\b(" + "|".join(names) + r")\b\s*(?:#|[A-Za-z_$]\w*\s*\()"
    )
    insts = {}
    for mod, f in defines.items():
        # crude but adequate: search the whole defining file
        insts.setdefault(mod, set()).update(
            m for m in pat.findall(text[f]) if m != mod
        )

    seen, stack = set(), [top]
    while stack:
        mod = stack.pop()
        if mod in seen:
            continue
        seen.add(mod)
        stack.extend(insts.get(mod, ()))

    needed = {defines[m] for m in seen}
    for f in files:  # keep original ordering
        if f in needed:
            print(f)


if __name__ == "__main__":
    main()
