// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// Self-test for DOOM's palette-expansion kernel.
//
// Runs a full 320x200 frame through the Titan ISA and checks every pixel
// against a CPU reference. This exists so that a broken blit kernel is caught
// here, where the failure is one wrong integer, rather than inside DOOM where
// it is a garbled picture.
//
//   ./test_blit titan_blit.tbin

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "titan_video.h"

#define W     320
#define H     200
#define NPIX  (W * H)

static uint8_t  frame[NPIX];
static uint32_t gpu_out[NPIX];
static uint32_t cpu_out[NPIX];
static uint32_t palette[256];

// A frame with structure rather than noise: horizontal bands crossed with a
// diagonal, so a kernel that mixes up its x and y arithmetic, or drops the
// low bits of the index, produces a visibly different answer rather than one
// that happens to still compare equal.
static void make_frame(void)
{
    int x, y;
    for (y = 0; y < H; y++)
        for (x = 0; x < W; x++)
            frame[y * W + x] = (uint8_t)((x + y * 3) & 0xFF);
}

static void make_palette(unsigned seed)
{
    int i;
    for (i = 0; i < 256; i++) {
        unsigned r = (i * 7  + seed * 11) & 0xFF;
        unsigned g = (i * 13 + seed * 29) & 0xFF;
        unsigned b = (i * 31 + seed * 3)  & 0xFF;
        palette[i] = 0xFF000000u | (r << 16) | (g << 8) | b;
    }
}

static void cpu_reference(void)
{
    int i;
    for (i = 0; i < NPIX; i++)
        cpu_out[i] = palette[frame[i]];
}

// Returns the number of mismatching pixels, and prints the first few.
static int compare(const char *label)
{
    int i, wrong = 0;
    for (i = 0; i < NPIX; i++) {
        if (gpu_out[i] != cpu_out[i]) {
            if (wrong < 5)
                printf("    px %6d: gpu %08X != cpu %08X (index %3u)\n",
                       i, gpu_out[i], cpu_out[i], frame[i]);
            wrong++;
        }
    }
    if (wrong == 0)
        printf("  [PASS] %s\n", label);
    else
        printf("  [FAIL] %s: %d of %d pixels wrong\n", label, wrong, NPIX);
    return wrong;
}

int main(int argc, char **argv)
{
    const char *tbin = (argc > 1) ? argv[1] : "titan_blit.tbin";
    int failures = 0;

    printf("=== Titan X6: DOOM palette-expansion kernel test ===\n");

    if (titan_video_init(W, H, tbin) != 0) {
        fprintf(stderr, "init failed\n");
        return 1;
    }

    make_frame();

    // --- 1. a full frame, every pixel checked --------------------------
    make_palette(0);
    titan_video_set_palette_argb(palette);
    cpu_reference();

    memset(gpu_out, 0, sizeof(gpu_out));
    titan_video_expand(frame, gpu_out);
    failures += compare("64000 pixels expanded on the GPU, bit-exact vs CPU");

    // --- 2. a palette change must actually reach VRAM ------------------
    // The upload is skipped when the palette has not changed, so this is
    // guarding a real optimisation: if the shadow-compare were wrong, DOOM
    // would keep rendering with a stale palette during fades and damage
    // flashes, which looks like a colour bug and is miserable to trace.
    make_palette(1);
    titan_video_set_palette_argb(palette);
    cpu_reference();

    memset(gpu_out, 0, sizeof(gpu_out));
    titan_video_expand(frame, gpu_out);
    failures += compare("palette change takes effect");

    // --- 3. re-sending the same palette must not corrupt anything ------
    titan_video_set_palette_argb(palette);   // identical: upload skipped
    memset(gpu_out, 0, sizeof(gpu_out));
    titan_video_expand(frame, gpu_out);
    failures += compare("unchanged palette still renders correctly");

    titan_video_shutdown();

    printf("\n%s\n", failures ? "TESTS FAILED" : "ALL TESTS PASSED");
    return failures ? 1 : 0;
}
