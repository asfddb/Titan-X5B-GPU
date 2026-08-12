# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""A DOOM-style raycaster, written in the Titan kernel language.

This is not decoration on top of the GPU -- it is compiled by
`compiler/titan_compiler.py` into Titan ISA v2 machine code, the same encoding
`rtl/core/titan_x5_decoder.v` decodes, and the frame it renders is scanned out
by the real display engine.

THE CONSTRAINT THAT SHAPES ALL OF THIS: the kernel language has no `if`.
`ScalarCodegen.gen_stmt` accepts assignment, augmented assignment, `for ... in
range(...)`, and nothing else. A raycaster is normally a pile of conditionals --
did the ray hit, is this pixel ceiling or wall or floor, clamp this to the
screen -- so every one of them here is arithmetic instead.

The whole trick is one line:

    m = (a - b) >> 31          # -1 when a < b, 0 otherwise

`>>` lowers to SRA, so the sign bit smears across all 32 bits and the result is
a full-width mask. From there `x & m` is "x if a < b else 0", `m ^ -1` is the
negation, and `(x & m) | (y & (m ^ -1))` is a select. Nothing branches.

RAY MARCHING RATHER THAN DDA. The textbook algorithm needs a reciprocal per
ray to build its deltaDist, and a 16.16 reciprocal needs a 64-bit numerator the
32-bit ISA does not have. So this marches in fixed steps instead, and gets
something better than it gives up:

The ray direction is *not* normalised. It is dir + plane*cameraX, which is the
standard unnormalised camera ray, and it is stepped by rayDir >> 3 -- an eighth
of it per step. After n steps the ray has travelled n/8 of rayDir, and because
plane is perpendicular to dir and |dir| = 1, the projection of that onto the
camera axis is exactly n/8. **The step count is the perpendicular distance.**
No division per ray, and no fisheye correction, because the distance was never
Euclidean to begin with.

Once a wall is hit the position stops advancing -- `px += stepx & live` -- so
after the loop `px, py` is the hit point and `n` is the distance to it.

Parameters are the camera, as uniforms: the ray direction at column 0 and its
per-column increment. Those are two adds per column instead of a rotation.
"""


def kernel(MAP, COL_TOP, COL_BOT, COL_COL, FB,
           RDX0, RDY0, INCX, INCY, POSX, POSY):
    # ---- pass 1: cast one ray per screen column -------------------------
    for x in range(640):
        rdx = RDX0 + INCX * x
        rdy = RDY0 + INCY * x
        stepx = rdx >> 4                  # a sixteenth of the camera ray
        stepy = rdy >> 4
        px = POSX
        py = POSY
        hit = 0
        n = 0

        for s in range(320):
            live = hit ^ -1               # all ones until something is hit
            px = px + (stepx & live)      # frozen once live is 0
            py = py + (stepy & live)
            n = n + (1 & live)
            mx = (px >> 16) & 31
            my = (py >> 16) & 31
            cell = MAP[my * 32 + mx]
            hit = hit | ((0 - cell) >> 31)   # -1 as soon as cell > 0

        # the frozen position is the hit point; read the wall it belongs to
        mx = (px >> 16) & 31
        my = (py >> 16) & 31
        cell = MAP[my * 32 + mx]

        # perpendicular distance is n/16 cells, so a wall one cell away fills
        # the screen: height = 400 * 16 / n. A ray that ran out of steps
        # without finding anything reports cell 0; zeroing its height there
        # leaves the column as bare ceiling over floor -- an open horizon
        # rather than a black hole punched in the scene.
        hitm = (0 - cell) >> 31
        lh = (6400 // n) & hitm
        top = 200 - (lh >> 1)
        bot = 200 + (lh >> 1)

        tm = top >> 31                    # -1 when top < 0
        top = top & (tm ^ -1)             # clamp up at 0
        bm = (bot - 400) >> 31            # -1 when bot < 400
        bot = (bot & bm) | (400 & (bm ^ -1))

        near = (n - 80) >> 31             # -1 when closer than 5 cells
        COL_TOP[x] = top
        COL_BOT[x] = bot
        COL_COL[x] = cell + (8 & near)    # bright half of the palette up close

    # ---- pass 2: pack the framebuffer, 8 pixels per 32-bit word ---------
    for y in range(400):
        rowb = y * 80
        for g in range(80):
            word = 0
            x0 = g << 3
            for k in range(8):
                xx = x0 + k
                t = COL_TOP[xx]
                b = COL_BOT[xx]
                c = COL_COL[xx]
                am = (y - t) >> 31        # -1 above the wall  -> ceiling
                bm2 = (y - b) >> 31       # -1 above the floor line
                wm = (am ^ -1) & bm2      # inside the wall span
                fm = bm2 ^ -1             # at or below it     -> floor
                # ceiling 1 (blue), floor 8 (grey). The level uses wall types
                # 2..7 only, so with the near-wall +8 the walls occupy 2..7
                # and 10..15 and never collide with either.
                pxv = (1 & am) | (c & wm) | (8 & fm)
                word = word | (pxv << (k << 2))
            FB[rowb + g] = word
