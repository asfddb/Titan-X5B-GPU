# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""The raycaster's ray-casting pass, sized so the RTL can actually finish it.

`doom_raycast.py` renders a whole 640x400 frame and retires 18.3 million
instructions. The whole-GPU Icarus simulation runs at roughly 90 clock cycles
per wall second, so that frame is not something the RTL is going to produce
this decade. This is the same algorithm with the loop bounds lifted into
parameters, so a handful of columns can be run on the actual SM cores and
checked against the functional simulator word for word.

WHAT IS THE SAME, AND WHY THAT MATTERS: the ray march, the liveness masking,
the branchless clamps, the distance-is-step-count trick and the palette
shading are identical to the full kernel. Only `NCOL` and `NSTEP` shrink. So a
bit-exact result here is evidence about the real kernel's arithmetic on real
hardware, not about a toy written to be easy.

Pass 2 -- packing pixels into the framebuffer -- is deliberately not here. It
is address arithmetic and shifts, it dominates the instruction count, and it
exercises nothing the ray cast does not. The interesting work is the cast.

Output is three words per column: wall top, wall bottom, palette index. Every
warp computes the same thing from the same inputs, which is what this harness
requires -- threads are redundant here, not partitioned.
"""


def kernel(MAP, OUT, RDX0, RDY0, INCX, INCY, POSX, POSY,
           X0, NCOL, NSTEP, STRIDE):
    for i in range(NCOL):
        # STRIDE spreads the sampled columns across the screen instead of
        # taking neighbours. Adjacent columns hit the same wall at nearly the
        # same distance and return nearly identical words, which a kernel that
        # simply returned a constant would also do. Spread columns hit
        # different walls at different distances, so agreement means something.
        x = X0 + i * STRIDE
        rdx = RDX0 + INCX * x
        rdy = RDY0 + INCY * x
        stepx = rdx >> 4
        stepy = rdy >> 4
        px = POSX
        py = POSY
        hit = 0
        n = 0

        for s in range(NSTEP):
            live = hit ^ -1
            px = px + (stepx & live)
            py = py + (stepy & live)
            n = n + (1 & live)
            mx = (px >> 16) & 31
            my = (py >> 16) & 31
            cell = MAP[my * 32 + mx]
            hit = hit | ((0 - cell) >> 31)

        mx = (px >> 16) & 31
        my = (py >> 16) & 31
        cell = MAP[my * 32 + mx]

        hitm = (0 - cell) >> 31
        lh = (6400 // n) & hitm
        top = 200 - (lh >> 1)
        bot = 200 + (lh >> 1)

        tm = top >> 31
        top = top & (tm ^ -1)
        bm = (bot - 400) >> 31
        bot = (bot & bm) | (400 & (bm ^ -1))

        near = (n - 80) >> 31

        OUT[i * 3] = top
        OUT[i * 3 + 1] = bot
        OUT[i * 3 + 2] = cell + (8 & near)
