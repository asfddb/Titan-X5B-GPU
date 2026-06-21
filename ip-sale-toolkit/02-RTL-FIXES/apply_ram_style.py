#!/usr/bin/env python3
"""
apply_ram_style.py — Add `(* ram_style="block" *)` attributes to all
                     inferred memories in RTL source files.

WHY:
  Yosys (and Vivado) by default infer `reg [W-1:0] mem [0:N-1];` as
  flip-flop banks. This causes your gate count to balloon (530K+
  registers in your case) and prevents the design from fitting on
  FPGA targets.

  Adding the synthesis attribute:
      (* ram_style="block" *) reg [W-1:0] mem [0:N-1];
  tells Vivado/Quartus to map the memory to a Block RAM (BRAM)
  primitive instead. Yosys itself ignores this attribute but does
  not warn about it.

USAGE:
  python3 apply_ram_style.py /path/to/your/repo/rtl

  This will walk every .v and .sv file under the given directory,
  find memory declarations of the form:
      reg [width-1:0] name [0:depth-1];
  and insert the attribute on the line above.

  A backup of every modified file is written to <file>.bak.

  Run `git diff` afterwards to review changes before committing.

OPTIONS:
  --dry-run   Show what would change, but don't modify files.
  --no-backup Don't write .bak files.
  --verbose   Print every match.

NOTE:
  This script is conservative. It only matches memory declarations
  that are clearly 2D (reg [W:0] name [..]) and skips any line that
  already has an `(* ram_style *)` attribute.

  Some memories (small register files, FIFOs) may be better left as
  distributed RAM or LUTRAM. Review the diff and remove the attribute
  from any memory you'd prefer to keep as registers.
"""

import os
import re
import sys
import argparse


# Regex: matches `reg [W-1:0] name [0:N-1];` and similar forms.
# Groups:
#   1: leading whitespace
#   2: signed keyword (optional)
#   3: width part `[...]` (optional)
#   4: identifier
#   5: depth `[...]`
MEMORY_DECL_RE = re.compile(
    r'^(\s*)'                                    # 1: leading whitespace
    r'(?:reg\s+)?'                               # `reg ` keyword (optional, see below)
    r'(reg\b)'                                   # 2: `reg` keyword
    r'(\s+(?:signed\s+)?(?:\[[^\]]+\]))?'        # 3: optional `signed [W:0]`
    r'\s+([A-Za-z_]\w*)'                         # 4: identifier
    r'\s*(\[[^\]]+\])'                           # 5: depth dimension
    r'\s*(?:=\s*[^;]+)?'                         # optional initializer
    r'\s*;',
    re.MULTILINE,
)


def has_ram_style_attr(text: str, start: int) -> bool:
    """Return True if the line above the match already has ram_style."""
    line_start = text.rfind('\n', 0, start) + 1
    # Look back up to 3 lines
    for _ in range(3):
        prev_line_end = line_start - 1
        if prev_line_end <= 0:
            break
        prev_line_start = text.rfind('\n', 0, prev_line_end) + 1
        prev = text[prev_line_start:prev_line_end]
        if 'ram_style' in prev or '(* ' in prev:
            return True
        line_start = prev_line_start
    return False


def process_file(path: str, dry_run: bool, no_backup: bool, verbose: bool) -> int:
    """Process a single file. Returns number of attributes added."""
    try:
        with open(path, 'r', encoding='utf-8', errors='replace') as f:
            text = f.read()
    except Exception as e:
        print(f"  ERROR reading {path}: {e}", file=sys.stderr)
        return 0

    additions = 0
    matches = list(MEMORY_DECL_RE.finditer(text))

    if not matches:
        return 0

    # Walk matches in reverse so insertions don't shift offsets of
    # later matches.
    new_text = text
    for m in reversed(matches):
        if has_ram_style_attr(new_text, m.start()):
            if verbose:
                print(f"  SKIP (already has attr): {m.group(0).strip()}")
            continue

        indent = m.group(1)
        insertion = f'{indent}(* ram_style="block" *) '

        # Insert at the start of the matched whitespace, replacing
        # the existing leading whitespace.
        # The matched whitespace starts at m.start(). We replace the
        # whitespace + `reg` start with: indent + attr + indent + `reg`.
        # Simpler: just inject the attribute right before the `reg`
        # keyword (which is group 2).
        reg_pos = m.start(2)
        new_text = new_text[:reg_pos] + f'(* ram_style="block" *) ' + new_text[reg_pos:]
        additions += 1
        if verbose:
            print(f"  ADD: {m.group(0).strip()}")

    if additions == 0 or dry_run:
        if dry_run and additions:
            print(f"  DRY-RUN: {path}: {additions} attribute(s) would be added")
        return additions

    if not no_backup:
        backup = path + '.bak'
        try:
            with open(backup, 'w', encoding='utf-8') as f:
                f.write(text)
        except Exception as e:
            print(f"  WARN: could not write backup {backup}: {e}", file=sys.stderr)

    try:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_text)
    except Exception as e:
        print(f"  ERROR writing {path}: {e}", file=sys.stderr)
        return 0

    print(f"  {path}: {additions} attribute(s) added")
    return additions


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('directory', help='Directory to scan for .v / .sv files')
    ap.add_argument('--dry-run', action='store_true',
                    help='Show what would change, but do not modify files')
    ap.add_argument('--no-backup', action='store_true',
                    help='Do not write .bak files')
    ap.add_argument('--verbose', action='store_true',
                    help='Print every match')
    args = ap.parse_args()

    if not os.path.isdir(args.directory):
        print(f"ERROR: {args.directory} is not a directory", file=sys.stderr)
        sys.exit(1)

    print(f"Scanning {args.directory} for memory declarations...")
    if args.dry_run:
        print("(DRY RUN — no files will be modified)")

    total = 0
    files_modified = 0
    for root, dirs, files in os.walk(args.directory):
        # Skip hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for fname in sorted(files):
            if not (fname.endswith('.v') or fname.endswith('.sv')):
                continue
            path = os.path.join(root, fname)
            n = process_file(path, args.dry_run, args.no_backup, args.verbose)
            if n:
                files_modified += 1
                total += n

    print()
    print(f"Done. {total} attribute(s) added across {files_modified} file(s).")
    if total and not args.dry_run:
        print()
        print("Next steps:")
        print("  1. Review changes:  git diff")
        print("  2. Re-run synth:    yosys -p 'read_verilog -sv rtl/**/*.v; synth; stat'")
        print("  3. Commit:          git commit -am 'perf(rtl): add ram_style for BRAM inference'")


if __name__ == '__main__':
    main()
