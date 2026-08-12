#!/usr/bin/env python3
"""
Check a frame captured off the virtual VGA connector by tb/board/vga_monitor.v.

The monitor samples pixels off the sync edges and the mode table, the way a
real monitor does -- it never asks the DUT where the pixels are. So a frame
that comes back shifted means the picture really is shifted on the wire
relative to the sync pulses, which is what a monitor would show.

That is why this script solves for the shift instead of assuming zero: the
useful output is the measured offset, not a pass/fail against an offset that
was quietly compensated for somewhere.

Usage:
  check_frame.py check  <frame.ppm> --pattern N [--png out.png]
  check_frame.py diff   <a.ppm> <b.ppm> [--png out.png]
"""
import argparse
import sys

# 16-colour palette from fpga/titan_x5_display_top.v, as (r,g,b) 4-bit nibbles
PALETTE = [
    (0x0, 0x0, 0x0), (0x0, 0x0, 0xA), (0x0, 0xA, 0x0), (0x0, 0xA, 0xA),
    (0xA, 0x0, 0x0), (0xA, 0x0, 0xA), (0xA, 0x5, 0x0), (0xA, 0xA, 0xA),
    (0x5, 0x5, 0x5), (0x5, 0x5, 0xF), (0x5, 0xF, 0x5), (0x5, 0xF, 0xF),
    (0xF, 0x5, 0x5), (0xF, 0x5, 0xF), (0xF, 0xF, 0x5), (0xF, 0xF, 0xF),
]


def pattern_index(x, y, sel):
    """The colour index the boot writer stores for pixel (x, y).

    Mirrors the grp_idx case statement in titan_x5_display_top.v. grp_x is a
    4-bit wire, so the x group index wraps at 16 -- that wrap is real and
    visible in the picture, not an artefact of this model.
    """
    gx = (x >> 5) & 0xF
    gy = (y >> 5) & 0xF
    if sel == 0:
        return gx ^ gy
    if sel == 1:
        return gx
    if sel == 2:
        return gy
    return (gx + gy) & 0xF


def read_ppm(path):
    with open(path, "rb") as f:
        data = f.read()
    if not data.startswith(b"P6"):
        raise SystemExit(f"{path}: not a P6 PPM")
    # header: P6 <ws> W <ws> H <ws> MAXVAL <single ws> then binary
    fields, i = [], 2
    while len(fields) < 3:
        while i < len(data) and data[i:i + 1].isspace():
            i += 1
        if data[i:i + 1] == b"#":
            while i < len(data) and data[i:i + 1] != b"\n":
                i += 1
            continue
        j = i
        while j < len(data) and not data[j:j + 1].isspace():
            j += 1
        fields.append(int(data[i:j]))
        i = j
    i += 1
    w, h, maxval = fields
    px = data[i:i + w * h * 3]
    if len(px) != w * h * 3:
        raise SystemExit(f"{path}: truncated, got {len(px)} of {w*h*3} bytes")
    return w, h, px


def write_png(path, w, h, px):
    try:
        from PIL import Image
    except ImportError:
        print("  (PIL not available, skipping PNG)")
        return
    Image.frombytes("RGB", (w, h), bytes(px)).save(path)
    print(f"  wrote {path}")


def to_nibbles(px, i):
    """8-bit sample back to the 4-bit DAC value the board actually drove."""
    return (px[i] // 17, px[i + 1] // 17, px[i + 2] // 17)


def cmd_check(args):
    w, h, px = read_ppm(args.frame)
    print(f"  {args.frame}: {w}x{h}, pattern {args.pattern}")

    # Solve for the horizontal offset between the picture and the sync pulses.
    best_shift, best_hits = None, -1
    for shift in range(-8, 9):
        hits = 0
        # sample a grid rather than every pixel -- enough to rank the shifts
        for y in range(0, h, 7):
            for x in range(0, w, 3):
                sx = x + shift
                if not (0 <= sx < w):
                    continue
                if to_nibbles(px, (y * w + sx) * 3) == \
                        PALETTE[pattern_index(x, y, args.pattern)]:
                    hits += 1
        if hits > best_hits:
            best_hits, best_shift = hits, shift

    # Full count at the winning shift.
    total = bad = 0
    first_bad = None
    for y in range(h):
        for x in range(w):
            sx = x + best_shift
            if not (0 <= sx < w):
                continue
            total += 1
            got = to_nibbles(px, (y * w + sx) * 3)
            want = PALETTE[pattern_index(x, y, args.pattern)]
            if got != want:
                bad += 1
                if first_bad is None:
                    first_bad = (x, y, got, want)

    pct = 100.0 * (total - bad) / total if total else 0.0
    print(f"  best horizontal offset : {best_shift:+d} pixel(s)")
    print(f"  matching pixels        : {total - bad}/{total} ({pct:.4f}%)")
    if first_bad:
        x, y, got, want = first_bad
        print(f"  first mismatch         : x={x} y={y} got={got} want={want}")

    if args.png:
        write_png(args.png, w, h, px)

    ok = (bad == 0)
    if ok and best_shift == 0:
        print("  RESULT: frame matches the expected pattern exactly")
    elif ok:
        print(f"  RESULT: pattern is correct but displaced {best_shift:+d} px "
              f"horizontally relative to the sync pulses")
    else:
        print(f"  RESULT: {bad} pixel(s) wrong at the best offset")
    return 0 if ok else 1


def cmd_diff(args):
    wa, ha, pa = read_ppm(args.a)
    wb, hb, pb = read_ppm(args.b)
    if (wa, ha) != (wb, hb):
        print(f"  size mismatch: {wa}x{ha} vs {wb}x{hb}")
        return 1
    diffs = sum(1 for i in range(0, len(pa), 3) if pa[i:i + 3] != pb[i:i + 3])
    print(f"  {args.a}")
    print(f"  {args.b}")
    print(f"  differing pixels: {diffs}/{wa*ha}")
    if diffs == 0:
        print("  RESULT: frames are identical")
    else:
        for i in range(0, len(pa), 3):
            if pa[i:i + 3] != pb[i:i + 3]:
                p = i // 3
                print(f"  first difference at x={p % wa} y={p // wa}: "
                      f"{tuple(pa[i:i+3])} vs {tuple(pb[i:i+3])}")
                break
    if args.png:
        out = bytearray(len(pa))
        for i in range(0, len(pa), 3):
            out[i:i + 3] = b"\xff\x00\x00" if pa[i:i + 3] != pb[i:i + 3] \
                else bytes(pa[i:i + 3])
        write_png(args.png, wa, ha, out)
    return 0 if diffs == 0 else 1


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    c = sub.add_parser("check")
    c.add_argument("frame")
    c.add_argument("--pattern", type=int, default=0, choices=[0, 1, 2, 3])
    c.add_argument("--png")
    c.set_defaults(func=cmd_check)

    d = sub.add_parser("diff")
    d.add_argument("a")
    d.add_argument("b")
    d.add_argument("--png")
    d.set_defaults(func=cmd_diff)

    args = ap.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
