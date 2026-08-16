// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// DOOM's frame path on the Titan X6.
//
// DOOM draws into an 8-bit palettised buffer; the display wants 32-bit ARGB.
// The conversion is one independent palette lookup per pixel, which is handed
// to the GPU as a single dispatch of titan_blit.tbin.
//
// Deliberately plain C with no DOOM headers, so it builds standalone against
// test_blit.c as well as inside doomgeneric.

#ifndef TITAN_VIDEO_H
#define TITAN_VIDEO_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Bring the device up and load the blit kernel. `tbin_path` may be NULL, in
// which case "titan_blit.tbin" in the working directory is used.
// Returns 0 on success, non-zero on failure.
int titan_video_init(int width, int height, const char *tbin_path);

// Release the device. Safe to call when init failed or was never called.
void titan_video_shutdown(void);

// Set the palette from 256 packed ARGB words.
void titan_video_set_palette_argb(const uint32_t *pal256);

// Set the palette from DOOM's PLAYPAL lump: 256 RGB triples, 768 bytes.
void titan_video_set_palette(const uint8_t *playpal768);

// Expand one frame. `indexed` is width*height bytes, `out_argb` receives
// width*height 32-bit pixels. Every one of them is produced on the GPU.
void titan_video_expand(const uint8_t *indexed, uint32_t *out_argb);

// NOTE: there is deliberately no instruction-count accessor here. The model
// keeps a real counter (titan_gpu_model_t::perf_instr) but does not expose it
// through the runtime API, and a number derived from the kernel's shape would
// be arithmetic dressed up as a measurement. If this is wanted, plumb the
// real counter out through the driver rather than recomputing it here.

#ifdef __cplusplus
}
#endif

#endif // TITAN_VIDEO_H
