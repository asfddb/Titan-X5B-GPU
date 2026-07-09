// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// test_driver.c — Mission 1 TDD checkpoint for the Titan X6 kernel driver.
//
// Isolates the driver from the runtime/compiler and exercises exactly the
// checkpoint the mission asks for — initialize the driver and allocate 1 MiB
// of simulated VRAM — plus a full 1 MiB DMA roundtrip and the error paths the
// matmul integration test never touches (over-capacity alloc, double free,
// out-of-bounds transfer, ioctl on a bad fd).
//
// Exit code 0 iff every check passes, so `make test` gates on it.

#include "titan_x6_drv.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

static int checks = 0;
static int failures = 0;

#define CHECK(cond, msg)                                   \
    do {                                                   \
        checks++;                                          \
        if (cond) {                                        \
            printf("  [PASS] %s\n", (msg));                \
        } else {                                           \
            printf("  [FAIL] %s\n", (msg));                \
            failures++;                                    \
        }                                                  \
    } while (0)

int main(void)
{
    const uint64_t MIB = 1024u * 1024u;

    printf("== Titan X6 driver test: init + 1 MiB VRAM allocation ==\n");

    // --- Mission 1 checkpoint: bring the driver up ---------------------------
    CHECK(titan_sim_insmod() == 0, "insmod/probe brings the device up");

    int fd = titan_sim_open();
    CHECK(fd >= 0, "open() returns a valid fd");

    titan_ioc_info_t info;
    memset(&info, 0, sizeof(info));
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GET_INFO, &info) == 0,
          "GET_INFO ioctl succeeds");
    CHECK(info.vendor_id == TITAN_PCI_VENDOR_ID, "GET_INFO vendor id matches");
    CHECK(info.device_id == TITAN_PCI_DEVICE_ID, "GET_INFO device id matches");
    CHECK(info.vram_bytes == 256u * 1024u * 1024u, "GET_INFO reports 256 MiB VRAM");

    // --- Mission 1 checkpoint: allocate 1 MiB of VRAM ------------------------
    titan_ioc_gem_alloc_t alloc;
    memset(&alloc, 0, sizeof(alloc));
    alloc.size = MIB;
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_ALLOC, &alloc) == 0,
          "GEM_ALLOC of 1 MiB succeeds");
    CHECK(alloc.handle != 0, "allocation returns a nonzero handle");
    CHECK(alloc.gpu_addr != 0, "allocation returns a nonzero VRAM address (NULL reserved)");
    CHECK((alloc.gpu_addr & (4096u - 1)) == 0, "VRAM address is page-aligned");

    // --- Full 1 MiB DMA roundtrip through BAR1 -------------------------------
    uint8_t *src = (uint8_t *)malloc(MIB);
    uint8_t *dst = (uint8_t *)malloc(MIB);
    CHECK(src && dst, "host staging buffers allocated");
    for (uint64_t i = 0; i < MIB; i++)
        src[i] = (uint8_t)((i * 2654435761u) >> 13);
    memset(dst, 0, MIB);

    titan_ioc_gem_rw_t rw;
    memset(&rw, 0, sizeof(rw));
    rw.handle   = alloc.handle;
    rw.offset   = 0;
    rw.user_ptr = (uint64_t)(uintptr_t)src;
    rw.size     = MIB;
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_WRITE, &rw) == 0,
          "GEM_WRITE of 1 MiB to VRAM succeeds");

    rw.user_ptr = (uint64_t)(uintptr_t)dst;
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_READ, &rw) == 0,
          "GEM_READ of 1 MiB from VRAM succeeds");
    CHECK(memcmp(src, dst, MIB) == 0, "1 MiB write/read roundtrip is byte-exact");

    // --- Error paths ---------------------------------------------------------
    rw.offset = (uint32_t)(MIB - 16);
    rw.size   = 32;   // runs 16 bytes past the end of the buffer object
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_READ, &rw) != 0,
          "out-of-bounds GEM_READ is rejected");

    titan_ioc_gem_free_t freq;
    freq.handle = alloc.handle;
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_FREE, &freq) == 0,
          "GEM_FREE succeeds");
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_FREE, &freq) != 0,
          "double free of the same handle is rejected");

    titan_ioc_gem_alloc_t big;
    memset(&big, 0, sizeof(big));
    big.size = (uint64_t)info.vram_bytes + MIB;   // larger than all of VRAM
    CHECK(titan_sim_ioctl(fd, TITAN_IOCTL_GEM_ALLOC, &big) != 0,
          "over-capacity allocation fails cleanly (ENOMEM)");

    CHECK(titan_sim_ioctl(999, TITAN_IOCTL_GET_INFO, &info) != 0,
          "ioctl on an invalid fd is rejected (EBADF)");

    free(src);
    free(dst);
    titan_sim_close(fd);
    titan_sim_rmmod();

    printf("\n%s (%d/%d checks passed)\n",
           failures ? "DRIVER TEST FAILED" : "DRIVER TEST PASSED",
           checks - failures, checks);
    return failures ? 1 : 0;
}
