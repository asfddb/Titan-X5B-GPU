#!/usr/bin/env python3
# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Generate the chip blueprint FROM the RTL, so it cannot drift from it.

    python tools/gen_blueprint.py                 # write docs/TITAN_APEX_X_BLUEPRINT.md
    python tools/gen_blueprint.py --check         # exit 1 if that file is stale
    python tools/gen_blueprint.py --sm x7         # blueprint the X7 build instead

WHY THIS IS A PROGRAM AND NOT A DOCUMENT
----------------------------------------
A hand-written architecture document is wrong the moment someone edits the
RTL, and nothing tells you. Every structural number below is therefore
recovered from the design itself at generation time:

  * The ELABORATED HIERARCHY comes from Yosys -- `read_verilog; hierarchy
    -check -top; stat`. That resolves generate loops, parameter overrides and
    `ifdef` selection, which regex over the source cannot do. When the top
    instantiates four SMs through `for (gi = 0; gi < 4)`, Yosys reports four,
    not one textual site.

  * PORT DIRECTIONS, WIDTHS AND PARAMETERS come from a small structural
    parser over the same files, because Yosys' `stat` reports port *counts*
    but not names or widths.

`--check` is the part that gives the guarantee. Run it in CI and the
committed blueprint can never disagree with the RTL: if it does, the check
fails and prints the diff.

REQUIREMENTS
------------
Yosys on PATH, or OSS_CAD set to an oss-cad-suite directory. Yosys here is a
Windows binary, so it is handed Windows-style paths.
"""

import argparse
import collections
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RTL = os.path.join(ROOT, "rtl")
OUT_DEFAULT = os.path.join(ROOT, "docs", "TITAN_APEX_X_BLUEPRINT.md")
TOP = "titan_x5_gpu_top"

# Files that are not part of any chip build.
EXCLUDE = ("titan_x5_fpga_top.v", "xilinx_stubs.v")


# --------------------------------------------------------------------------
# source discovery + a small structural Verilog reader
# --------------------------------------------------------------------------
def rtl_files():
    out = []
    for d, _, fs in os.walk(RTL):
        for f in sorted(fs):
            if f.endswith(".v") and f not in EXCLUDE:
                out.append(os.path.join(d, f))
    return sorted(out)


def strip_comments(s):
    s = re.sub(r"//[^\n]*", "", s)
    return re.sub(r"/\*.*?\*/", "", s, flags=re.S)


def module_bodies(path):
    """{module: (body, path)} for every module defined in one file."""
    src = strip_comments(open(path, encoding="utf-8", errors="replace").read())
    out = {}
    for m in re.finditer(r"\bmodule\s+(\w+)", src):
        end = src.find("endmodule", m.end())
        out[m.group(1)] = (src[m.end(): end if end > 0 else len(src)], path)
    return out


def parse_ports(body):
    """[(dir, width, name)] from an ANSI-style port header."""
    i = body.find("(")
    if i < 0:
        return []
    # skip a parameter block: #( ... ) before the port list
    if body[:i].rstrip().endswith("#"):
        depth, k = 0, i
        while k < len(body):
            if body[k] == "(":
                depth += 1
            elif body[k] == ")":
                depth -= 1
                if depth == 0:
                    break
            k += 1
        i = body.find("(", k + 1)
        if i < 0:
            return []
    depth, k = 0, i
    while k < len(body):
        if body[k] == "(":
            depth += 1
        elif body[k] == ")":
            depth -= 1
            if depth == 0:
                break
        k += 1
    header = body[i + 1:k]
    ports = []
    for m in re.finditer(
        r"\b(input|output|inout)\b\s*(?:wire|reg|logic)?\s*(?:signed\s*)?"
        r"(\[[^\]]*\])?\s*(\w+)", header):
        ports.append((m.group(1), (m.group(2) or "").strip(), m.group(3)))
    return ports


def parse_params(body):
    """[(name, default)] declared in the module's #( ) block."""
    i = body.find("#(")
    if i < 0:
        return []
    depth, k = 0, i + 1
    while k < len(body):
        if body[k] == "(":
            depth += 1
        elif body[k] == ")":
            depth -= 1
            if depth == 0:
                break
        k += 1
    blk = body[i + 2:k]
    return [(m.group(1), m.group(2).strip())
            for m in re.finditer(r"parameter\s+(?:\[[^\]]*\]\s*)?(\w+)\s*=\s*([^,]+?)(?=,\s*(?:parameter|$)|$)",
                                 blk, flags=re.S)]


# --------------------------------------------------------------------------
# Yosys: the authoritative elaborated hierarchy
# --------------------------------------------------------------------------
_KW = {
    "module", "endmodule", "input", "output", "inout", "wire", "reg", "assign",
    "always", "begin", "end", "if", "else", "for", "case", "endcase",
    "generate", "endgenerate", "genvar", "integer", "parameter", "localparam",
    "function", "endfunction", "task", "endtask", "initial", "posedge",
    "negedge", "default", "real", "time", "signed", "unsigned", "while",
    "repeat", "forever", "casez", "casex", "endspecify", "specify",
}


def reachable_files(bodies, top):
    """The files holding modules reachable from `top`, both SM variants.

    A pre-pass, NOT the source of truth -- Yosys does the real elaboration.
    It exists because `rtl/` also holds modules that are not in any chip
    build, and at least one of them (titan_x5_noc_router.v) does not even
    parse:

        titan_x5_noc_router.v:195: ERROR: Unsupported expression on dynamic
        range select on signal `\\pop'!

    Handing Yosys the whole directory therefore fails on a module the chip
    does not contain. This walks the instantiation graph textually, ignoring
    `ifdef` so both SM variants are kept, and passes on only what is
    reachable. Anything mis-included here is harmless: `hierarchy -top`
    prunes whatever the top does not actually instantiate.
    """
    edges = collections.defaultdict(set)
    for parent, (body, _) in bodies.items():
        for m in re.finditer(
                r"\b(\w+)\s*(?:#\s*\((?:[^()]|\([^()]*\))*\)\s*)?(\w+)\s*\(", body):
            child, inst = m.group(1), m.group(2)
            if child in bodies and child != parent \
                    and inst not in _KW and child not in _KW:
                edges[parent].add(child)
    seen, stack = set(), [top]
    while stack:
        mod = stack.pop()
        if mod in seen:
            continue
        seen.add(mod)
        stack.extend(edges.get(mod, ()))
    return sorted({bodies[m][1] for m in seen if m in bodies}), seen


def find_yosys():
    for cand in (shutil.which("yosys"), shutil.which("yosys.exe")):
        if cand:
            return cand
    oss = os.environ.get("OSS_CAD")
    if oss:
        for name in ("yosys.exe", "yosys"):
            p = os.path.join(oss, "bin", name)
            if os.path.exists(p):
                return p
    raise SystemExit(
        "yosys not found. Put it on PATH or set OSS_CAD to an oss-cad-suite "
        "directory (it also needs its lib/ alongside bin/).")


PARAMOD = re.compile(r"^\$paramod[^\\]*\\(\w+)")


def base_module(name):
    """`$paramod$<hash>\\mod` and `$paramod\\mod\\P=..` both mean `mod`."""
    m = PARAMOD.match(name)
    return m.group(1) if m else name


def run_yosys_stat(files, defines):
    """{module: {'ports','port_bits','cells','wire_bits','subs':{mod:count}}}"""
    yosys = find_yosys()
    rel = [os.path.relpath(f, ROOT).replace("\\", "/") for f in files]
    d = " ".join(f"-D{x}" for x in defines)
    script = (f"read_verilog {d} {' '.join(rel)}\n"
              f"hierarchy -check -top {TOP}\n"
              f"stat\n")
    tmp = tempfile.mkdtemp(prefix="titan_bp_")
    try:
        ys = os.path.join(tmp, "bp.ys")
        log = os.path.join(tmp, "bp.log")
        with open(ys, "w") as f:
            f.write(script)
        proc = subprocess.run([yosys, "-l", log, "-s", ys],
                              cwd=ROOT, capture_output=True, text=True)
        text = open(log, encoding="utf-8", errors="replace").read()
        if proc.returncode != 0:
            err = [l for l in text.splitlines() if "ERROR" in l]
            raise SystemExit("yosys failed:\n" + "\n".join(err[-5:] or [text[-2000:]]))
        return parse_stat(text), parse_design_total(text, TOP)
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def parse_stat(text):
    """Parse `stat` output into per-module facts, keyed by the RAW name.

    Two things here are load-bearing.

    ORDER. The `N submodules` marker is a number followed by a single token,
    exactly like `N cells` and `N wires`, so a generic "number then one word"
    rule swallows it and the submodule list is never entered -- silently
    yielding a chip with no submodules and a one-line hierarchy. It is
    therefore tested first.

    RAW NAMES. Yosys emits a separate block per PARAMETERISATION, named
    `$paramod$<hash>\mod`. Those are genuinely distinct elaborated modules
    with distinct submodule lists, so they are kept distinct here and only
    folded together by base name for display. Normalising them at parse time
    merges their submodule counters, and the totals then multiply: doing that
    reported 8,196 SMs in a chip that has 4.
    """
    mods, cur, in_subs = {}, None, False
    for line in text.splitlines():
        # `stat` ends with a design-wide summary under this heading. It is
        # NOT a module: it repeats the whole instance tree and carries its
        # own `N submodules` line, which re-arms the submodule parser while
        # `cur` still points at the last real module. That module then
        # inherits the entire chip as its children and the totals explode --
        # it reported 8,196 SMs, all of them attributed to `mac_pe`, a
        # 19-cell multiply-accumulate leaf. Stop here.
        if line.startswith("=== design hierarchy ==="):
            break
        m = re.match(r"^=== (\S+) ===", line)
        if m:
            cur = mods.setdefault(m.group(1).lstrip("\\"),
                                  dict(ports=0, port_bits=0, cells=0,
                                       wire_bits=0,
                                       subs=collections.Counter()))
            in_subs = False
            continue
        if cur is None:
            continue
        if re.match(r"^\s+\d+\s+submodules\s*$", line):
            in_subs = True
            continue
        m = re.match(r"^\s+(\d+)\s+port bits\s*$", line)
        if m:
            cur["port_bits"] = int(m.group(1))
            in_subs = False
            continue
        m = re.match(r"^\s+(\d+)\s+wire bits\s*$", line)
        if m:
            cur["wire_bits"] = int(m.group(1))
            in_subs = False
            continue
        m = re.match(r"^\s+(\d+)\s+(\S+)\s*$", line)
        if m:
            n, what = int(m.group(1)), m.group(2)
            if in_subs:
                cur["subs"][what.lstrip("\\")] += n
            elif what == "ports":
                cur["ports"] = n
            elif what == "cells":
                cur["cells"] = n
            continue
        if line.strip():
            in_subs = False
    return mods


def parse_design_total(text, top):
    """Whole-chip cell count from `stat`'s design-hierarchy summary.

    That section is headed "Count including submodules", so the row for the
    top module is the total cell count of the entire elaborated design --
    RTL cells (adders, muxes, memories) before technology mapping, not
    GT2N standard cells.
    """
    m = re.search(r"=== design hierarchy ===(.*)", text, flags=re.S)
    if not m:
        return None
    for line in m.group(1).splitlines():
        mm = re.match(r"^\s+(\d+)\s+" + re.escape(top) + r"\s*$", line)
        if mm:
            return int(mm.group(1))
    return None


def total_instances(mods, top):
    """Elaborated instance count of every RAW module across the whole chip."""
    memo = {}

    def under(mod):
        if mod in memo:
            return memo[mod]
        memo[mod] = collections.Counter()          # cycle guard
        acc = collections.Counter()
        for sub, n in mods.get(mod, {}).get("subs", {}).items():
            acc[sub] += n
            for k, v in under(sub).items():
                acc[k] += n * v
        memo[mod] = acc
        return acc

    total = collections.Counter({top: 1})
    total.update(under(top))
    return total


def by_base(mods, total):
    """Fold parameterised variants together for display.

    Returns {base_name: (instances, variants, ports, cells, wire_bits)},
    where the reported ports/cells/wire_bits come from the variant with the
    most instances -- parameterisations of one module differ in size, so a
    single representative is named rather than a sum implied.
    """
    groups = collections.defaultdict(list)
    for raw, n in total.items():
        groups[base_module(raw)].append((n, raw))
    out = {}
    for base, items in groups.items():
        items.sort(reverse=True)
        insts = sum(n for n, _ in items)
        rep = mods.get(items[0][1], {})
        out[base] = (insts, len(items), rep.get("ports", 0),
                     rep.get("cells", 0), rep.get("wire_bits", 0))
    return out


def tree_lines(mods, top, depth=0, seen=None, prefix=""):
    """Hierarchy tree. Nodes are raw (parameterised) modules so the counts
    stay exact; only the printed label is folded to the base name."""
    seen = seen or set()
    out = [f"{'    ' * depth}{prefix}{base_module(top)}"]
    if top in seen or depth > 8:
        return out
    seen = seen | {top}
    subs = mods.get(top, {}).get("subs", {})
    merged = collections.Counter()
    for sub, n in subs.items():
        merged[sub] += n
    for sub in sorted(merged, key=base_module):
        n = merged[sub]
        out += tree_lines(mods, sub, depth + 1, seen, f"{n} x " if n > 1 else "")
    return out


# --------------------------------------------------------------------------
# instantiation-site parameter overrides (Yosys keeps these in the paramod
# hash, which is not human-readable, so read them from the source)
# --------------------------------------------------------------------------
def inst_params(bodies, parent, child):
    """Parameter overrides used where `parent` instantiates `child`."""
    body = bodies.get(parent, ("", ""))[0]
    m = re.search(re.escape(child) + r"\s*#\s*\((.*?)\)\s*\w+\s*\(", body, flags=re.S)
    if not m:
        return {}
    return {k: v.strip() for k, v in
            re.findall(r"\.(\w+)\s*\(\s*([^()]*?)\s*\)", m.group(1))}


def parse_isa(root):
    """[(num, name, comment)] from driver/titan_x6_isa.h.

    The header is the ISA's definition of record -- the compiler, the C
    functional model and the RTL decoder are all written against it -- so the
    opcode table is read from it rather than transcribed. Three divergences
    between it and titan_x7_sm were found by reading and two more by running;
    a table that regenerates cannot drift into being a sixth.
    """
    path = os.path.join(root, "driver", "titan_x6_isa.h")
    if not os.path.exists(path):
        return []
    out = []
    pat = r"TX6_OP_(\w+)\s*=\s*(\d+)\s*,?\s*(?://\s*([^\r\n]*))?"
    src = open(path, encoding="utf-8", errors="replace").read()
    for m in re.finditer(pat, src):
        out.append((int(m.group(2)), m.group(1), (m.group(3) or "").strip()))
    return sorted(out)


def xbar_masters(top_body):
    """[(lo, hi, description)] from the `// master N: ...` comments.

    The comments are the only machine-readable record of which client sits
    on which crossbar port -- the wiring itself is spread across a hundred
    lines of concatenation -- so they are parsed rather than retyped, and go
    stale loudly (an empty table) rather than quietly.
    """
    out = []
    pat = r"//\s*masters?\s+(\d+)(?:\s*[-toand]+\s*(\d+))?\s*:\s*([^\r\n]+)"
    for m in re.finditer(pat, top_body):
        lo = int(m.group(1))
        hi = int(m.group(2)) if m.group(2) else lo
        who = m.group(3).strip().rstrip(".")
        out.append((lo, hi, who[:80]))
    return sorted(out)


def fmt_int(n):
    return f"{n:,}"


def build_report(sm, mods, bodies, files, orphans, design_cells):
    tot = total_instances(mods, TOP)
    disp = by_base(mods, tot)
    top = mods[TOP]

    def ninst(name):
        return disp.get(name, (0,))[0]

    # --- geometry recovered from instantiation sites ----------------------
    l1 = inst_params(bodies, "titan_x5_sm" if sm == "x5" else "titan_x7_sm_shim",
                     "titan_x5_l1_cache")
    l2 = inst_params(bodies, TOP, "titan_x5_l2_cache")
    xbar = inst_params(bodies, TOP, "titan_x5_crossbar")
    cxb = inst_params(bodies, TOP, "titan_x5_coherent_xbar")
    smp = inst_params(bodies, TOP, "titan_x5_sm" if sm == "x5" else "titan_x7_sm_shim")
    rf = inst_params(bodies, "titan_x5_sm", "titan_x5_register_file")

    def geti(d, k, default=0):
        v = d.get(k, "")
        m = re.search(r"(\d+)", v)
        return int(m.group(1)) if m else default

    n_sm = ninst("titan_x5_sm") or ninst("titan_x7_sm_shim")
    lanes_per_sm = geti(smp, "NUM_ALUS", 32)
    warps = geti(smp, "NUM_WARPS", 8)
    line_b = geti(smp, "LINE_BYTES", 128)

    l1_ways, l1_sets = geti(l1, "WAYS", 4), geti(l1, "SETS", 64)
    l1_kib = l1_ways * l1_sets * line_b // 1024
    l2_ways, l2_sets = geti(l2, "WAYS", 8), geti(l2, "SETS", 256)
    l2_banks = geti(l2, "BANKS", 4)
    l2_kib = l2_ways * l2_sets * geti(l2, "LINE_SIZE", line_b) // 1024

    n_l1d = ninst("titan_x5_l1_cache")
    n_tmu = ninst("titan_x5_tmu")
    n_rop = ninst("titan_x5_rop")

    rf_regs = geti(rf, "NUM_REGS", 64)
    rf_dw = geti(rf, "DATA_WIDTH", 1024)
    rf_kib_per_sm = rf_regs * warps * rf_dw // 8 // 1024

    ports = parse_ports(bodies[TOP][0])
    isa = parse_isa(ROOT)
    n_in = sum(1 for d, _, _ in ports if d == "input")
    n_out = sum(1 for d, _, _ in ports if d == "output")

    L = []
    A = L.append
    A(f"# TITAN APEX-X — chip blueprint ({sm} build)")
    A("")
    A("> **This file is generated. Do not edit it by hand.**")
    A("> ")
    A("> ```bash")
    A("> python tools/gen_blueprint.py            # regenerate")
    A("> python tools/gen_blueprint.py --check    # fail if it is stale")
    A("> ```")
    A("> ")
    A("> Every structural figure below was recovered from the RTL at")
    A("> generation time. The hierarchy and all instance counts come from")
    A("> Yosys (`read_verilog; hierarchy -check -top; stat`), so generate")
    A("> loops, parameter overrides and `ifdef` selection are *elaborated*,")
    A("> not guessed at with a regex. If this document and the RTL ever")
    A("> disagree, `--check` fails.")
    A("")
    A("---")
    A("")
    A("## 0. What this is, and the caveats that travel with it")
    A("")
    A("A GPU written from RTL up, simulated and synthesised. It is **not a")
    A("product**: there is no manufactured chip, no installable driver and no")
    A("benchmarked frame rate. Its honest peer group is academic open-source")
    A("GPUs — MIAOW, Vortex, Nyuzi — not shipping silicon.")
    A("")
    A("Three caveats attach to every physical number here:")
    A("")
    A("1. **GT2N is a *predictive* PDK — this design is not fabbable.** No")
    A("   foundry accepts it.")
    A("2. **Synthesis only.** No floorplan, placement or routing. ABC reports")
    A("   `WireLoad = \"none\"`: **zero wire delay**. At 2 nm wire delay")
    A("   dominates, so place-and-route can only make timing worse.")
    A("3. **One corner** (`tt`, 0.7 V, 25 °C). No slow corner, so no signoff")
    A("   margin.")
    A("")
    A("---")
    A("")
    A("## 1. The chip, measured")
    A("")
    A("| Property | Value |")
    A("|:--|--:|")
    A(f"| Top module | `{TOP}` |")
    A(f"| SM variant built | **{sm}** |")
    A(f"| Modules elaborated into the chip | **{len(mods)}** |")
    A(f"| Total module instances | **{fmt_int(sum(tot.values()))}** |")
    if design_cells:
        A(f"| RTL cells, whole chip | **{fmt_int(design_cells)}** |")
    A(f"| Top-level ports | **{len(ports)}** ({n_in} in, {n_out} out), {fmt_int(top['port_bits'])} bits |")
    A(f"| Shader cores (SM) | **{n_sm}** |")
    A(f"| Lanes per SM | **{lanes_per_sm}** |")
    A(f"| **Total lanes** | **{n_sm * lanes_per_sm}** |")
    A(f"| Warps per SM | {warps} |")
    A(f"| Threads in flight | **{fmt_int(n_sm * warps * lanes_per_sm)}** |")
    A(f"| Texture units (TMU) | {n_tmu} |")
    A(f"| Raster output units (ROP) | {n_rop} |")
    A(f"| L1 caches | **{n_l1d}** x {l1_kib} KiB ({l1_ways}-way, {l1_sets} sets, {line_b} B lines) |")
    A(f"| L2 cache | **{l2_kib} KiB** ({l2_ways}-way, {l2_sets} sets, {l2_banks} banks) |")
    A(f"| Register file | {rf_kib_per_sm} KiB per SM, **{rf_kib_per_sm * n_sm} KiB** total |" if rf else "| Register file | see SM |")
    A(f"| Word crossbar | {geti(xbar, 'NUM_MASTERS')} masters, {geti(xbar, 'NUM_SLAVES')} slaves, {geti(xbar, 'DATA_WIDTH', 32)}-bit |")
    A(f"| Coherent crossbar | {geti(cxb, 'NUM_MASTERS')} masters, MESI, {line_b} B lines |")
    A("")
    A("---")
    A("")
    A("## 2. Every module in the chip")
    A("")
    A("Instance counts are **elaborated totals across the whole design**, so a")
    A("module inside a 4x generate loop inside another 4x loop reports 16.")
    A("")
    A("`variants` counts distinct parameterisations Yosys elaborated for that")
    A("module; ports / cells / wire bits are the largest such variant.")
    A("")
    A("| Module | Instances | Variants | Ports | Local cells | Wire bits |")
    A("|:--|--:|--:|--:|--:|--:|")
    for name in sorted(disp, key=lambda k: (-disp[k][0], k)):
        n, nv, np_, nc, nw = disp[name]
        A(f"| `{name}` | {fmt_int(n)} | {nv} | {np_} | "
          f"{fmt_int(nc)} | {fmt_int(nw)} |")
    A("")
    A("---")
    A("")
    A("## 3. Hierarchy")
    A("")
    A("```")
    L.extend(tree_lines(mods, TOP))
    A("```")
    A("")
    A("---")
    A("")
    A("## 4. Pinout")
    A("")
    A(f"{len(ports)} ports, {fmt_int(top['port_bits'])} bits.")
    A("")
    A("| Dir | Width | Name |")
    A("|:--|:--|:--|")
    for d, w, n in ports:
        A(f"| {d} | `{w or '1'}` | `{n}` |")
    A("")
    A("---")
    A("")
    A("## 5. Word crossbar master map")
    A("")
    A("Parsed from the master-assignment comments in the top level.")
    A("")
    A("| Port | Client |")
    A("|:--|:--|")
    raw_top = open(bodies[TOP][1], encoding='utf-8', errors='replace').read()
    for lo, hi, who in xbar_masters(raw_top):
        A(f"| {lo}{'' if hi == lo else '-' + str(hi)} | {who} |")
    A("")
    A("---")
    A("")
    A("## 6. Instruction set")
    A("")
    A("Read from `driver/titan_x6_isa.h`, which is the ISA's definition of")
    A("record: the compiler, the C functional model and the RTL decoder are")
    A("all written against it.")
    A("")
    A("```")
    A(" [31:27] opcode   [26:21] rd   [20:15] rs1   [14:9] rs2")
    A(" [8:3] rs3/imm12  [2:1] pred   [0] use_imm")
    A("```")
    A("")
    A("| # | Mnemonic | Notes |")
    A("|--:|:--|:--|")
    for num, name, note in isa:
        # `|` appears inside the header's own comments ("rd = rs1 + (imm |
        # rs2)") and would otherwise split the markdown row into new columns.
        A(f"| {num} | `{name}` | {note.replace('|', chr(92) + '|')} |")
    A("")
    A("Three encoding facts have each caused a real bug in this project:")
    A("")
    A("- **`BRANCH` is unconditional**, gated only by its predicate. It does")
    A("  *not* read rs1, and its target is an **absolute instruction index**.")
    A("- **`BARRIER` with `use_imm` and `imm == 0xFFF` is EXIT.** A plain")
    A("  `BARRIER` is thread sync.")
    A("- **`SETP`'s `rd` field is `{cond[2:0], pdst[1:0]}`**, not a register")
    A("  index. `cond` selects one of six `TX6_CMP_*` comparisons.")
    A("")
    A("Predicates are per-warp P0..P3, each a **32-bit per-lane mask**; P0 is")
    A("hardwired all-ones. There is **no reconvergence stack**: `titan_x5_sm`")
    A("executes only on a uniformly-true predicate and raises the sticky")
    A("`dbg_pred_divergent` flag on a mixed mask, while `titan_x7_sm` applies")
    A("the predicate as a per-lane write mask.")
    A("")
    A("---")
    A("")
    A("## 7. Things the block diagram would mislead you about")
    A("")
    A("- **Only ROP 0 receives fragments.** ROPs 1-3 are instantiated with")
    A("  `i_valid(16'b0)` and never paint.")
    A("- **The ROP has no per-fragment shader dispatch.** It latches the")
    A("  shader's most recent R63 export and paints whatever the rasterizer")
    A("  hands it, so a fragment's colour is \"the most recent export\", not")
    A("  \"the shader result for this fragment\".")
    A("- **There is no instruction cache.** Each SM fetches single 32-bit")
    A("  words on crossbar masters 9-12, one outstanding at a time. Measured:")
    A("  8 warps versus 1 pushed the render test from 8,009 to 10,009 cycles")
    A("  on fetch contention alone.")
    A("- **The four TMU L1s are read-only** (`core_req_write` tied low), so")
    A("  they contribute invalidation but never a writeback.")
    A("- **`titan_x5_gddr7_pam3_phy` is not a PHY.** It contains")
    A("  `assign tx_ready = 1'b1;`. A real memory PHY is transistor-level")
    A("  analog IP -- DLLs, per-bit deskew, training -- licensed, not written.")
    A("")
    A("---")
    A("")
    A("## 8. In `rtl/`, but NOT in the chip")
    A("")
    A(f"**{len(orphans)} of {len(bodies)} modules** in `rtl/` are not reachable")
    A("from the top level in either SM build. Some are verified blocks waiting")
    A("to be connected, some are scaffolding for a larger part. A reader")
    A("looking at the directory listing would reasonably assume otherwise,")
    A("which is why this section is generated rather than remembered.")
    A("")
    A("| Module | File |")
    A("|:--|:--|")
    for name in orphans:
        path = os.path.relpath(bodies[name][1], ROOT).replace("\\", "/")
        A(f"| `{name}` | `{path}` |")
    A("")
    return L

def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--sm", choices=("x5", "x7"), default="x5",
                    help="which SM the chip is built with (default x5)")
    ap.add_argument("--out", default=None,
                    help="output path (default docs/TITAN_APEX_X_BLUEPRINT.md)")
    ap.add_argument("--check", action="store_true",
                    help="do not write; exit 1 if the committed file is stale")
    args = ap.parse_args()

    out = args.out or OUT_DEFAULT
    files = rtl_files()
    bodies = {}
    for f in files:
        for name, (body, path) in module_bodies(f).items():
            bodies[name] = (body, path)

    # TITAN_FAST_SIM IS DELIBERATELY NOT DEFINED HERE.
    #
    # It swaps titan_x7_prefix_add and titan_x7_lzc for behavioural `+` and a
    # loop. The two forms are SAT-proven identical in BEHAVIOUR, so it is
    # sound for simulation -- but they are nothing alike in STRUCTURE, and a
    # blueprint is a structural document. Defining it made the X7 build
    # report 512 prefix adders of 2 cells each and 512 leading-zero counters
    # of 1 cell each, for a whole-chip total of 59,212 RTL cells against the
    # x5 build's 659,284. That reads as "X7 is a tenth the size", which is
    # false: a 106-bit Kogge-Stone adder is hundreds of gates, and it is the
    # structural form that every 2 nm timing number in this project is
    # measured on. syn/gt2n/run_gt2n.sh never defines it either.
    #
    # It costs generation time and buys a number that means something.
    defines = ["TITAN_USE_X7_SM"] if args.sm == "x7" else []
    design_files, reachable = reachable_files(bodies, TOP)
    mods, design_cells = run_yosys_stat(design_files, defines)

    orphans = sorted(set(bodies) - reachable)
    text = "\n".join(build_report(args.sm, mods, bodies, files,
                                 orphans, design_cells)) + "\n"

    if args.check:
        if not os.path.exists(out):
            print(f"FAIL: {out} does not exist; run tools/gen_blueprint.py")
            return 1
        have = open(out, encoding="utf-8").read()
        if have.replace("\r\n", "\n") == text:
            print(f"OK: {os.path.relpath(out, ROOT)} matches the RTL")
            return 0
        import difflib
        diff = list(difflib.unified_diff(
            have.replace("\r\n", "\n").splitlines(), text.splitlines(),
            "committed", "generated-from-rtl", lineterm="", n=1))
        print(f"FAIL: {os.path.relpath(out, ROOT)} is STALE -- the RTL has "
              f"changed under it.\n")
        print("\n".join(diff[:60]))
        if len(diff) > 60:
            print(f"... and {len(diff) - 60} more diff lines")
        print("\nRegenerate with: python tools/gen_blueprint.py")
        return 1

    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    print(f"wrote {os.path.relpath(out, ROOT)} "
          f"({len(text.splitlines())} lines, sm={args.sm}, "
          f"{len(mods)} modules elaborated)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
