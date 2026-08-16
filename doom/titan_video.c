// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// DOOM's frame path on the Titan X6. See titan_video.h.
//
// One dispatch per frame:
//
//     I_VideoBuffer (8bpp indexed)
//       -> titanMemcpy H2D          -> VRAM
//       -> titanLaunchKernel(blit)  <- the Titan ISA runs here
//       -> titanMemcpy D2H          -> the screen buffer
//
// The palette is uploaded only when it actually changes, so DOOM calling
// titan_video_set_palette() every frame costs nothing on the frames where it
// has not moved - which is nearly all of them.

#include "titan_video.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../driver/titan_runtime.h"

#define TITAN_BLIT_THREADS 256
#define PALETTE_ENTRIES    256
#define PALETTE_BYTES      (PALETTE_ENTRIES * 4)

static titanModule     s_module;
static titanDevicePtr  s_src, s_dst, s_pal;
static int             s_npix;
static int             s_ready;

// Shadow copy of what is currently in VRAM, so an unchanged palette does not
// generate a transfer.
static uint32_t        s_pal_shadow[PALETTE_ENTRIES];
static int             s_pal_valid;

static int fail(const char *what, titanError_t e)
{
    fprintf(stderr, "[titan-doom] %s: %s\n", what, titanGetErrorString(e));
    titan_video_shutdown();
    return -1;
}

int titan_video_init(int width, int height, const char *tbin_path)
{
    titanDeviceProp prop;
    titanError_t    e;
    size_t          src_bytes;

    if (s_ready)
        return 0;

    if (width <= 0 || height <= 0) {
        fprintf(stderr, "[titan-doom] bad frame size %dx%d\n", width, height);
        return -1;
    }
    s_npix = width * height;

    if (!tbin_path || !*tbin_path)
        tbin_path = "titan_blit.tbin";

    if ((e = titanInit()) != titanSuccess)
        return fail("titanInit", e);

    if ((e = titanGetDeviceProperties(&prop)) != titanSuccess)
        return fail("titanGetDeviceProperties", e);

    printf("[titan-doom] %s | %u MiB VRAM | %u GPCs / %u SMs\n",
           prop.name, prop.vram_bytes >> 20, prop.num_gpcs, prop.num_sms);
    printf("[titan-doom] frame %dx%d (%d px) through %d threads\n",
           width, height, s_npix, TITAN_BLIT_THREADS);

    // The kernel reads src[i] by loading the aligned 32-bit word containing
    // it, so the last pixel can touch up to three bytes beyond i. Round the
    // allocation up to a word and the read always lands inside our own buffer.
    src_bytes = (size_t)((s_npix + 3) & ~3);

    if ((e = titanMalloc(&s_src, src_bytes)) != titanSuccess)
        return fail("titanMalloc(src)", e);
    if ((e = titanMalloc(&s_dst, (size_t)s_npix * 4u)) != titanSuccess)
        return fail("titanMalloc(dst)", e);
    if ((e = titanMalloc(&s_pal, PALETTE_BYTES)) != titanSuccess)
        return fail("titanMalloc(pal)", e);

    if ((e = titanModuleLoad(&s_module, tbin_path)) != titanSuccess) {
        fprintf(stderr, "[titan-doom] cannot load blit kernel '%s': %s\n",
                tbin_path, titanGetErrorString(e));
        fprintf(stderr, "[titan-doom] generate it with: "
                        "python3 gen_blit_kernel.py titan_blit.tbin\n");
        titan_video_shutdown();
        return -1;
    }

    s_pal_valid = 0;
    s_ready     = 1;
    return 0;
}

void titan_video_shutdown(void)
{
    if (s_module) { titanModuleUnload(s_module); s_module = NULL; }
    if (s_src)    { titanFree(s_src); s_src = 0; }
    if (s_dst)    { titanFree(s_dst); s_dst = 0; }
    if (s_pal)    { titanFree(s_pal); s_pal = 0; }
    titanShutdown();
    s_ready     = 0;
    s_pal_valid = 0;
}

void titan_video_set_palette_argb(const uint32_t *pal256)
{
    titanError_t e;

    if (!s_ready || !pal256)
        return;

    if (s_pal_valid && memcmp(s_pal_shadow, pal256, PALETTE_BYTES) == 0)
        return;                       // unchanged - nothing to upload

    memcpy(s_pal_shadow, pal256, PALETTE_BYTES);
    s_pal_valid = 1;

    e = titanMemcpy((void *)(uintptr_t)s_pal, pal256, PALETTE_BYTES,
                    titanMemcpyHostToDevice);
    if (e != titanSuccess)
        fprintf(stderr, "[titan-doom] palette upload: %s\n",
                titanGetErrorString(e));
}

void titan_video_set_palette(const uint8_t *playpal768)
{
    uint32_t argb[PALETTE_ENTRIES];
    int      i;

    if (!playpal768)
        return;

    // PLAYPAL is 256 RGB triples. The framebuffer wants XRGB8888, and the
    // high byte is left at 0xFF so the result is opaque wherever the consumer
    // happens to respect alpha.
    for (i = 0; i < PALETTE_ENTRIES; i++) {
        uint32_t r = playpal768[i * 3 + 0];
        uint32_t g = playpal768[i * 3 + 1];
        uint32_t b = playpal768[i * 3 + 2];
        argb[i] = 0xFF000000u | (r << 16) | (g << 8) | b;
    }
    titan_video_set_palette_argb(argb);
}

void titan_video_expand(const uint8_t *indexed, uint32_t *out_argb)
{
    uint32_t     params[4];
    titanError_t e;

    if (!s_ready || !indexed || !out_argb)
        return;

    e = titanMemcpy((void *)(uintptr_t)s_src, indexed, (size_t)s_npix,
                    titanMemcpyHostToDevice);
    if (e != titanSuccess) { fail("memcpy H2D", e); return; }

    params[0] = s_src;
    params[1] = s_dst;
    params[2] = s_pal;
    params[3] = (uint32_t)s_npix;

    e = titanLaunchKernel(s_module, params, 4, TITAN_BLIT_THREADS);
    if (e != titanSuccess) { fail("launch", e); return; }

    e = titanDeviceSynchronize();
    if (e != titanSuccess) { fail("synchronize", e); return; }

    e = titanMemcpy(out_argb, (const void *)(uintptr_t)s_dst,
                    (size_t)s_npix * 4u, titanMemcpyDeviceToHost);
    if (e != titanSuccess) { fail("memcpy D2H", e); return; }
}
