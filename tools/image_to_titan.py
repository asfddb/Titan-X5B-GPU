# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Put any image on the Titan display path.

WHY THIS EXISTS

Titan cannot run DOOM. Its ISA has no call, no return and no indirect branch
(the opcode table in `compiler/titan_compiler.py` is the whole set), branch
targets are 12 bits so nothing beyond 4096 instructions is even addressable,
LOAD/STORE are word-only, and the ABI has no stack pointer. It is a shader
ISA. DOOM needs a CPU.

What Titan *can* do is display. So: run DOOM wherever it does run, take a
frame, and hand it to this. It becomes a VRAM image that
`tb/tb_doom_display.v` scans out through the real display engine -- real VGA
timing, real line-buffer shim, real palette, real 4-bit DAC pins -- and
`tb/board/vga_monitor.v` captures off the connector. The pixels are DOOM's.
The hardware putting them on a monitor is yours.

Nothing about this is DOOM-specific; any image works.

WHAT THE HARDWARE COSTS YOU

The framebuffer is 640x400 at 4 bits per pixel: 128,000 bytes, which is
exactly the 128 KB BRAM budget. That means **16 colours**, fixed, chosen by
the palette hardwired in `fpga/titan_x5_display_top.v`. A 256-colour DOOM
frame gets quantised to those 16 by nearest RGB distance, and it will look
posterised. That is the display path being honest about what it is, not a
defect.

DOOM's native 320x200 doubles to 640x400 exactly, so that path costs nothing --
no interpolation, no resampling, every source pixel becomes a clean 2x2 block.
Other sizes are letterboxed to preserve aspect.

USAGE

  python tools/image_to_titan.py shot.png
  python tools/image_to_titan.py shot.png --outdir doom_out --preview
"""
import argparse
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tb" / "board"))

from check_frame import PALETTE                              # noqa: E402

W, H = 640, 400


def nearest_index(r, g, b, cache={}):
    """Closest of the display path's 16 colours, by squared RGB distance."""
    key = (r >> 2, g >> 2, b >> 2)          # cache on a coarse grid
    hit = cache.get(key)
    if hit is not None:
        return hit
    best, bi = None, 0
    for i, (pr, pg, pb) in enumerate(PALETTE):
        pr, pg, pb = pr * 17, pg * 17, pb * 17
        d = (pr - r) ** 2 + (pg - g) ** 2 + (pb - b) ** 2
        if best is None or d < best:
            best, bi = d, i
    cache[key] = bi
    return bi


def load_and_fit(path):
    """Load, scale to fit 640x400 preserving aspect, letterbox the rest."""
    from PIL import Image
    im = Image.open(path).convert("RGB")
    sw, sh = im.size

    # Integer upscale when it divides exactly -- DOOM's 320x200 hits this and
    # doubles with no resampling at all.
    if W % sw == 0 and H % sh == 0 and (W // sw) == (H // sh):
        im = im.resize((W, H), Image.NEAREST)
        print(f"  {sw}x{sh} -> {W}x{H} by exact {W//sw}x nearest-neighbour")
        return im

    scale = min(W / sw, H / sh)
    nw, nh = max(1, int(sw * scale)), max(1, int(sh * scale))
    resample = Image.NEAREST if scale >= 1 else Image.LANCZOS
    im = im.resize((nw, nh), resample)
    canvas = Image.new("RGB", (W, H), (0, 0, 0))
    canvas.paste(im, ((W - nw) // 2, (H - nh) // 2))
    print(f"  {sw}x{sh} -> {nw}x{nh}, letterboxed into {W}x{H}")
    return canvas


def quantise(im):
    """RGB image to one 4-bit palette index per pixel."""
    px = im.tobytes()
    idx = bytearray(W * H)
    for i in range(W * H):
        o = i * 3
        idx[i] = nearest_index(px[o], px[o + 1], px[o + 2])
    return idx


def pack_framebuffer(idx):
    """8 pixels per 32-bit word, pixel k in nibble k."""
    fb = [0] * (W * H // 8)
    for i in range(len(fb)):
        w = 0
        for k in range(8):
            w |= idx[i * 8 + k] << (k * 4)
        fb[i] = w
    return fb


def write_vram_hex(path, fb):
    """$readmemh image for titan_x5_vram_ctrl: 2048 lines of 512 bits.

    bram is `reg [511:0]` and line_buf[pix_off*4 +: 4] is pixel pix_off, so
    word 0 sits in the LOW bits and the hex text runs highest word first.
    """
    lines = []
    for line in range(2048):
        ws = fb[line * 16:(line + 1) * 16]
        ws = ws + [0] * (16 - len(ws))
        lines.append("".join(f"{w:08x}" for w in reversed(ws)))
    Path(path).write_text("\n".join(lines) + "\n")
    print(f"  wrote {path} (2048 x 512-bit lines)")


def write_preview(path, idx):
    from PIL import Image
    out = bytearray(W * H * 3)
    for i, v in enumerate(idx):
        r, g, b = PALETTE[v]
        out[i * 3:i * 3 + 3] = bytes((r * 17, g * 17, b * 17))
    Image.frombytes("RGB", (W, H), bytes(out)).save(path)
    print(f"  wrote {path}")


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image", help="any image; a DOOM screenshot is the point")
    ap.add_argument("--outdir", default="doom_out")
    ap.add_argument("--name", default="frame_vram.hex")
    ap.add_argument("--preview", action="store_true",
                    help="also write what the 16-colour framebuffer will hold")
    args = ap.parse_args()

    outdir = (REPO / args.outdir) if not Path(args.outdir).is_absolute() \
        else Path(args.outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    im = load_and_fit(args.image)
    idx = quantise(im)
    used = len(set(idx))
    print(f"  quantised to {used} of the display path's 16 colours")
    write_vram_hex(outdir / args.name, pack_framebuffer(idx))
    if args.preview:
        write_preview(outdir / "frame_preview.png", idx)

    print()
    print("  scan it out through the real display path with:")
    print(f"    iverilog -g2012 -s tb_doom_display -o {args.outdir}/disp.vvp \\")
    print("        rtl/xilinx_stubs.v rtl/memory/titan_x5_vram_ctrl.v \\")
    print("        rtl/display/titan_x5_async_fifo.v \\")
    print("        rtl/display/titan_x5_display_engine.v \\")
    print("        fpga/titan_x5_display_top.v tb/board/basys3_board.v \\")
    print("        tb/board/vga_monitor.v tb/tb_doom_display.v")
    print(f"    vvp {args.outdir}/disp.vvp +vram={args.outdir}/{args.name} "
          f"+outdir={args.outdir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
