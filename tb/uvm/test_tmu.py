# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Bilinear-filtering verification of the TMU (titan_x5_tmu).

Environment:
  - TextureMemory: byte-accurate texture backing store serving the TMU's
    miss port with randomized grant/latency (exercises the internal
    texture cache: hits, misses, evictions).
  - Reference model: exact bit-level replica of the documented TMU
    semantics - 2x2 footprint address generation (wrap/clamp), format
    expansion (L8 replicate / RGB565->8888 bit-replication / RGBA8888),
    and the round-to-nearest lerp:  c = a +/- (((|b-a|)*f + 128) >> 8).

Checks: o_color must match the reference exactly for every sample; o_x/o_y
must echo the integer texel coordinates.

Coverage: all three formats, wrap and clamp modes, fractional weights
{0, 128, 255, random}, texture-edge footprints (u = w-1: wrap to column 0
vs clamp), out-of-range clamp coordinates, cache-hit determinism (same
sample twice), and constrained-random sampling on multiple textures.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, ClockCycles, ReadOnly

from tb_common import start_clock_and_reset
from coverage_util import sample_tmu, export_on_exit

export_on_exit("tmu")


class TextureMemory:
    """Serves the TMU miss port from a byte array texture."""

    def __init__(self, dut, rng):
        self.dut = dut
        self.rng = rng
        self.data = {}  # byte addr -> byte
        self.stop = False

    def word(self, addr):
        a = addr & ~3
        return (self.data.get(a, 0)
                | self.data.get(a + 1, 0) << 8
                | self.data.get(a + 2, 0) << 16
                | self.data.get(a + 3, 0) << 24)

    async def run(self):
        dut = self.dut
        dut.mem_gnt.value = 0
        dut.mem_valid.value = 0
        dut.mem_rdata.value = 0
        while not self.stop:
            await ReadOnly()
            req = int(dut.mem_req.value) == 1
            addr = int(dut.mem_addr.value) if req else 0
            await RisingEdge(dut.clk)
            if req and self.rng.random() < 0.75:
                dut.mem_gnt.value = 1
                await RisingEdge(dut.clk)   # grant edge observed by cache
                dut.mem_gnt.value = 0
                for _ in range(self.rng.randint(0, 2)):
                    await RisingEdge(dut.clk)
                dut.mem_valid.value = 1
                dut.mem_rdata.value = self.word(addr)
                await RisingEdge(dut.clk)
                dut.mem_valid.value = 0
            else:
                dut.mem_gnt.value = 0


# ---------------------------------------------------------------------------
# reference model (bit-exact replica of the RTL semantics)
# ---------------------------------------------------------------------------
def wrap_clamp(ui, vi, w, h, clamp):
    if clamp:
        u0 = min(ui, w - 1)
        u1 = min(ui + 1, w - 1)
        v0 = min(vi, h - 1)
        v1 = min(vi + 1, h - 1)
    else:
        u0 = ui
        u1 = 0 if ui + 1 == w else ui + 1
        v0 = vi
        v1 = 0 if vi + 1 == h else vi + 1
    return u0, u1, v0, v1


def bpp_shift(fmt):
    return {0: 0, 1: 1, 2: 2}[fmt]


def expand(word, byte_off, fmt):
    if fmt == 2:
        return word & 0xFFFFFFFF
    if fmt == 1:
        t16 = (word >> 16) & 0xFFFF if (byte_off & 2) else word & 0xFFFF
        r5 = (t16 >> 11) & 0x1F
        g6 = (t16 >> 5) & 0x3F
        b5 = t16 & 0x1F
        r = (r5 << 3) | (r5 >> 2)
        g = (g6 << 2) | (g6 >> 4)
        b = (b5 << 3) | (b5 >> 2)
        return (0xFF << 24) | (b << 16) | (g << 8) | r
    t8 = (word >> (8 * (byte_off & 3))) & 0xFF
    return (0xFF << 24) | (t8 << 16) | (t8 << 8) | t8


def lerp8(a, b, f):
    if a > b:
        return a - (((a - b) * f + 128) >> 8)
    return a + (((b - a) * f + 128) >> 8)


def lerp32(ca, cb, f):
    out = 0
    for sh in (0, 8, 16, 24):
        out |= lerp8((ca >> sh) & 0xFF, (cb >> sh) & 0xFF, f) << sh
    return out


def reference_sample(tex, u_fix, v_fix, w, h, clamp, fmt, base):
    ui, vi = (u_fix >> 16) & 0xFFFF, (v_fix >> 16) & 0xFFFF
    uf, vf = (u_fix >> 8) & 0xFF, (v_fix >> 8) & 0xFF
    u0, u1, v0, v1 = wrap_clamp(ui, vi, w, h, clamp)
    sh = bpp_shift(fmt)
    texels = []
    for (vv, uu) in ((v0, u0), (v0, u1), (v1, u0), (v1, u1)):
        addr = (base + ((vv * w + uu) << sh)) & 0xFFFFFFFF
        texels.append(expand(tex.word(addr), addr & 3, fmt))
    top = lerp32(texels[0], texels[1], uf)
    bot = lerp32(texels[2], texels[3], uf)
    return lerp32(top, bot, vf)


async def sample(dut, u_fix, v_fix, w, h, clamp, fmt, base):
    dut.i_u.value = u_fix
    dut.i_v.value = v_fix
    dut.i_tex_width.value = w
    dut.i_tex_height.value = h
    dut.i_wrap_mode.value = 1 if clamp else 0
    dut.i_format.value = fmt
    dut.i_tex_base_addr.value = base
    dut.i_valid.value = 1
    for _ in range(2000):
        await ReadOnly()
        accepted = int(dut.i_ready.value) == 1
        await RisingEdge(dut.clk)
        if accepted:
            break
    else:
        raise AssertionError("TMU never accepted the sample request")
    dut.i_valid.value = 0
    out = None
    for _ in range(20000):
        await ReadOnly()
        if int(dut.o_valid.value) == 1:
            out = (int(dut.o_color.value),
                   int(dut.o_x.value), int(dut.o_y.value))
        await RisingEdge(dut.clk)
        if out is not None:
            return out
    raise AssertionError("TMU sample timeout")


def fill_texture(mem, rng, base, w, h, fmt):
    nbytes = (w * h) << bpp_shift(fmt)
    for k in range(nbytes):
        mem.data[(base + k) & 0xFFFFFFFF] = rng.getrandbits(8)


async def run_case(dut, mem, u_fix, v_fix, w, h, clamp, fmt, base, tag):
    got, gx, gy = await sample(dut, u_fix, v_fix, w, h, clamp, fmt, base)
    exp = reference_sample(mem, u_fix, v_fix, w, h, clamp, fmt, base)
    assert got == exp, (
        f"{tag}: color mismatch u={u_fix:#x} v={v_fix:#x} w={w} h={h} "
        f"clamp={clamp} fmt={fmt}: got {got:08x}, expected {exp:08x}")
    assert gx == (u_fix >> 16) & 0xFFFF and gy == (v_fix >> 16) & 0xFFFF, \
        f"{tag}: x/y echo wrong: ({gx},{gy})"
    sample_tmu(fmt, clamp, (u_fix >> 8) & 0xFF, (v_fix >> 8) & 0xFF)


@cocotb.test()
async def test_tmu_bilinear(dut):
    rng = random.Random(0x7311)
    await start_clock_and_reset(dut)
    dut.i_valid.value = 0
    dut.o_ready.value = 1
    mem = TextureMemory(dut, rng)
    cocotb.start_soon(mem.run())
    await ClockCycles(dut.clk, 2)

    W, H = 16, 16
    BASE = 0x0002_0000

    def fix(i, frac):
        return ((i & 0xFFFF) << 16) | ((frac & 0xFF) << 8)

    # --- directed: all formats x {wrap, clamp} x corner weights/coords ---
    # Each format gets its own address region: the TMU texture cache has no
    # flush port (as in real hardware), so re-filling memory at the same
    # base would legitimately alias against still-cached lines.
    for fmt in (2, 1, 0):
        fbase = BASE + fmt * 0x4000
        fill_texture(mem, rng, fbase, W, H, fmt)
        for clamp in (True, False):
            for (ui, vi) in ((0, 0), (7, 3), (W - 1, H - 1), (W - 1, 0),
                             (0, H - 1), (W - 2, H - 2)):
                for (uf, vf) in ((0, 0), (255, 255), (128, 128),
                                 (255, 0), (0, 255), (37, 201)):
                    await run_case(dut, mem, fix(ui, uf), fix(vi, vf),
                                   W, H, clamp, fmt, fbase,
                                   f"directed-fmt{fmt}")
            if clamp:
                # out-of-range integer coords (clamp must saturate)
                for (ui, vi) in ((W, H), (W + 5, 2), (3, H + 9)):
                    await run_case(dut, mem, fix(ui, 77), fix(vi, 190),
                                   W, H, clamp, fmt, fbase,
                                   f"clamp-oob-fmt{fmt}")
    dut._log.info("TMU directed cases passed (3 formats, wrap+clamp)")

    # --- cache-hit determinism: identical sample twice ---
    u, v = fix(5, 99), fix(9, 160)
    fbase2 = BASE + 2 * 0x4000
    got1, _, _ = await sample(dut, u, v, W, H, True, 2, fbase2)
    got2, _, _ = await sample(dut, u, v, W, H, True, 2, fbase2)
    assert got1 == got2, "cache-hit path returned a different color"

    # --- constrained-random on several textures/sizes ---
    for tex_i in range(3):
        w = rng.choice((8, 16, 32))
        h = rng.choice((8, 16, 32))
        base = 0x0004_0000 + tex_i * 0x10000
        fmt = rng.randrange(3)
        fill_texture(mem, rng, base, w, h, fmt)
        for _ in range(40):
            clamp = rng.random() < 0.5
            ui = rng.randrange(w if not clamp else w + 4)
            vi = rng.randrange(h if not clamp else h + 4)
            await run_case(dut, mem, fix(ui, rng.getrandbits(8)),
                           fix(vi, rng.getrandbits(8)),
                           w, h, clamp, fmt, base, f"rand-tex{tex_i}")
    dut._log.info("TMU constrained-random passed")
    mem.stop = True
