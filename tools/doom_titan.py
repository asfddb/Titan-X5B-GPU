# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Render a DOOM-style frame with the Titan toolchain.

WHAT THIS IS, AND WHAT IT IS NOT

It is not DOOM. DOOM is about forty thousand lines of C that need a CPU, and
Titan is a GPU -- a custom ISA, no C compiler, no operating system. Nothing
here runs id's game logic.

What it is: the *rendering* half, which is the part a GPU is actually for.
`compiler/kernels/doom_raycast.py` is a raycaster written in the Titan kernel
language, compiled by this project's own compiler into Titan ISA v2 machine
code -- the same encoding `rtl/core/titan_x5_decoder.v` decodes -- and executed
instruction by instruction. The frame it produces is then handed to the real
display path and scanned out through the real VGA timing generator.

THREE LEVELS, AND WHICH ONE EACH RESULT COMES FROM

  1. Python raycaster (`--reference`)  -- an independent model, used only to
     check the kernel. No Titan involvement.
  2. Titan ISA execution (default)     -- the compiled kernel run by
     `titan_compiler.simulate()`, the project's functional twin of
     `driver/titan_x6_gpu_model.c`. Real instructions, modelled machine.
  3. Titan RTL display path            -- the framebuffer written into VRAM and
     scanned out by `titan_x5_display_top`, captured off the VGA connector by
     `tb/board/vga_monitor.v`. Real hardware description, gate-accurate timing.

Levels 2 and 3 are both real; they are different parts of the chip. The
whole-GPU RTL runs at roughly 90 clock cycles per wall second, so executing
twelve million raycaster instructions on the SMs is not a thing that finishes.
Rendering happens at level 2, scanning out happens at level 3, and this file
never claims otherwise.

USAGE

  python tools/doom_titan.py                      # render, write PNG + VRAM
  python tools/doom_titan.py --angle 0.9          # look somewhere else
  python tools/doom_titan.py --check              # vs the Python reference
"""
import argparse
import math
import struct
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "compiler"))
sys.path.insert(0, str(REPO / "tb" / "board"))

import titan_compiler as tc                                  # noqa: E402
from check_frame import PALETTE                              # noqa: E402

W, H = 640, 400
MAPW = MAPH = 32
FB_WORDS = W * H // 8                     # 8 pixels per 32-bit word
FP = 16                                   # 16.16 fixed point

# Memory map for the simulated address space. The framebuffer sits at 0
# because that is where the display engine starts reading.
A_FB = 0x00000
A_MAP = 0x20000
A_TOP = 0x21000
A_BOT = 0x21A00
A_COL = 0x22400
A_PARAM = 0x23000
MEM_SIZE = 0x24000

# A room-and-corridor level on a 32x32 grid. Digits are palette indices for
# the dark half of the 16-colour set; the kernel adds 8 for near walls, which
# lands on the bright counterpart. '.' is open floor.
LEVEL = [
    "44444444444444444444444444444444",
    "4..............4...............4",
    "4..7777........4......2222.....4",
    "4..7...........4......2........4",
    "4..7...........4......2........4",
    "4..7....555....4......2222222..4",
    "4..7....5......4...............4",
    "4.......5......4...............4",
    "4.......5......4......33333....4",
    "4.......555....4......3...3....4",
    "4..............4......3...3....4",
    "4..............4......3...3....4",
    "4..............4......33333....4",
    "4..............4...............4",
    "44444.4444444444...............4",
    "4.....4........................4",
    "4.....4........................4",
    "4.....4......6666666666........4",
    "4.....4......6........6........4",
    "4............6........6........4",
    "4............6........6........4",
    "4.....4......6...55...6........4",
    "4.....4......6...55...6........4",
    "4.....4......6........6........4",
    "4.....4......66666.6666........4",
    "4.....4........................4",
    "44444444444.4444444444444444...4",
    "4..............................4",
    "4...2222...........7777777.....4",
    "4...2..............7.....7.....4",
    "4..................7.....7.....4",
    "44444444444444444444444444444444",
]


def build_map():
    assert len(LEVEL) == MAPH and all(len(r) == MAPW for r in LEVEL)
    return [[0 if c == "." else int(c) for c in row] for row in LEVEL]


def camera(angle, fov=0.66):
    """Camera uniforms in 16.16: ray direction at column 0 and its per-column
    increment. rayDir = dir + plane*cameraX with cameraX from -1 to +1, so the
    increment is plane * 2/W."""
    dx, dy = math.cos(angle), math.sin(angle)
    px, py = -math.sin(angle) * fov, math.cos(angle) * fov
    one = 1 << FP
    return (int((dx - px) * one), int((dy - py) * one),       # RDX0, RDY0
            int(px * 2 / W * one), int(py * 2 / W * one))     # INCX, INCY


def u32(v):
    return v & 0xFFFFFFFF


def render_on_titan(level, cam, pos, verbose=True):
    """Compile the kernel and execute it as Titan ISA. Returns the framebuffer
    words and the instruction count actually retired."""
    src = (REPO / "compiler" / "kernels" / "doom_raycast.py").read_text()
    fn = tc.parse_kernel(src, "kernel")
    words = tc.ScalarCodegen(fn).compile()
    if verbose:
        print(f"  compiled to {len(words)} Titan ISA instructions")

    mem = bytearray(MEM_SIZE)
    for y in range(MAPH):
        for x in range(MAPW):
            struct.pack_into("<I", mem, A_MAP + 4 * (y * MAPW + x),
                             level[y][x])

    rdx0, rdy0, incx, incy = cam
    posx, posy = pos
    params = [A_MAP, A_TOP, A_BOT, A_COL, A_FB,
              u32(rdx0), u32(rdy0), u32(incx), u32(incy),
              u32(posx), u32(posy)]
    for i, v in enumerate(params):
        struct.pack_into("<I", mem, A_PARAM + 4 * i, v)

    if verbose:
        print("  executing on the Titan ISA simulator...")
    steps = tc.simulate(words, mem, A_PARAM, max_steps=1 << 27)
    fb = list(struct.unpack_from("<%dI" % FB_WORDS, mem, A_FB))
    return fb, words, steps


def render_reference(level, cam, pos):
    """An independent Python raycaster. Deliberately written straight, with
    real `if`s, so agreement with the branchless kernel means something."""
    rdx0, rdy0, incx, incy = cam
    posx, posy = pos
    fb = [0] * FB_WORDS
    cols = []
    for x in range(W):
        rdx = rdx0 + incx * x
        rdy = rdy0 + incy * x
        stepx, stepy = rdx >> 4, rdy >> 4
        px, py, n = posx, posy, 0
        for _ in range(320):
            px += stepx
            py += stepy
            n += 1
            if level[(py >> 16) & 31][(px >> 16) & 31] > 0:
                break
        cell = level[(py >> 16) & 31][(px >> 16) & 31]
        lh = (6400 // n) if cell > 0 else 0
        top = max(0, 200 - (lh >> 1))
        bot = min(400, 200 + (lh >> 1))
        cols.append((top, bot, cell + (8 if n < 80 else 0)))
    for y in range(H):
        for g in range(W // 8):
            word = 0
            for k in range(8):
                top, bot, c = cols[(g << 3) + k]
                v = 1 if y < top else (c if y < bot else 8)
                word |= v << (k * 4)
            fb[y * (W // 8) + g] = word
    return fb


def fb_to_rgb(fb):
    """Framebuffer words to 8-bit RGB bytes, through the display top's palette."""
    out = bytearray(W * H * 3)
    for i, word in enumerate(fb):
        for k in range(8):
            r, g, b = PALETTE[(word >> (k * 4)) & 0xF]
            o = (i * 8 + k) * 3
            out[o], out[o + 1], out[o + 2] = r * 17, g * 17, b * 17
    return out


def write_png(path, rgb):
    from PIL import Image
    Image.frombytes("RGB", (W, H), bytes(rgb)).save(path)
    print(f"  wrote {path}")


def write_vram_hex(path, fb):
    """$readmemh image for titan_x5_vram_ctrl: 2048 lines of 512 bits.

    A line is 64 bytes = 16 framebuffer words. bram is `reg [511:0]`, and
    line_buf[pix_off*4 +: 4] is pixel pix_off, so word 0 occupies the LOW bits
    -- which means the hex text runs from the highest word down to word 0.
    """
    lines = []
    for line in range(2048):
        ws = fb[line * 16:(line + 1) * 16]
        if len(ws) < 16:
            ws = ws + [0] * (16 - len(ws))
        lines.append("".join(f"{w:08x}" for w in reversed(ws)))
    Path(path).write_text("\n".join(lines) + "\n")
    print(f"  wrote {path} (2048 x 512-bit lines)")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--angle", type=float, default=0.35,
                    help="camera heading in radians")
    ap.add_argument("--x", type=float, default=8.5, help="camera x, in cells")
    ap.add_argument("--y", type=float, default=20.5, help="camera y, in cells")
    ap.add_argument("--outdir", default="doom_out")
    ap.add_argument("--check", action="store_true",
                    help="also run the Python reference and compare")
    args = ap.parse_args()

    outdir = REPO / args.outdir
    outdir.mkdir(parents=True, exist_ok=True)

    level = build_map()
    cam = camera(args.angle)
    pos = (int(args.x * (1 << FP)), int(args.y * (1 << FP)))

    print(f"  camera at ({args.x}, {args.y}) heading {args.angle} rad")
    fb, words, steps = render_on_titan(level, cam, pos)
    print(f"  retired {steps:,} Titan instructions")

    rgb = fb_to_rgb(fb)
    write_png(outdir / "doom_titan.png", rgb)
    write_vram_hex(outdir / "doom_vram.hex", fb)

    if args.check:
        print("  running the independent Python reference...")
        ref = render_reference(level, cam, pos)
        bad = sum(1 for a, b in zip(fb, ref) if a != b)
        if bad == 0:
            print(f"  MATCH: all {len(fb):,} framebuffer words identical "
                  f"to the reference")
        else:
            print(f"  MISMATCH: {bad:,} of {len(fb):,} words differ")
            for i, (a, b) in enumerate(zip(fb, ref)):
                if a != b:
                    print(f"    first at word {i} (x={i%80*8} y={i//80}): "
                          f"titan={a:08x} ref={b:08x}")
                    break
            write_png(outdir / "doom_reference.png", fb_to_rgb(ref))
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
