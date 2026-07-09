// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// test_runtime.cpp — Mission 3 runtime API unit tests.
//
// test_matmul.cpp already verifies the happy end-to-end path (Malloc ->
// Memcpy H2D -> LaunchKernel -> Memcpy D2H -> compare). This complements it
// with the surfaces that test never touches:
//   * device-to-device titanMemcpy (the command-ring TITAN_CMD_DMA path),
//   * the CUDA-style error contract (bad handles, bad modules, no-device,
//     invalid arguments).
//
// Exit code 0 iff every check passes.

#include "titan_runtime.h"
#include "titan_x6_isa.h"

#include <cstdio>
#include <cstring>
#include <cstdint>
#include <vector>

static int checks = 0;
static int failures = 0;

static void expect(bool cond, const char *msg)
{
    checks++;
    if (cond) {
        std::printf("  [PASS] %s\n", msg);
    } else {
        std::printf("  [FAIL] %s\n", msg);
        failures++;
    }
}

int main(void)
{
    std::printf("== Titan runtime API unit tests ==\n");

    // --- error contract before init -----------------------------------------
    titanDevicePtr tmp = 0;
    expect(titanMalloc(&tmp, 1024) == titanErrorNoDevice,
           "titanMalloc before titanInit -> NoDevice");

    // --- init ----------------------------------------------------------------
    expect(titanInit() == titanSuccess, "titanInit succeeds");
    expect(titanInit() == titanSuccess, "titanInit is idempotent");

    titanDeviceProp prop{};
    expect(titanGetDeviceProperties(&prop) == titanSuccess &&
           prop.vram_bytes == 256u * 1024u * 1024u,
           "GetDeviceProperties reports 256 MiB");

    // --- argument validation -------------------------------------------------
    expect(titanMalloc(nullptr, 16) == titanErrorInvalidValue,
           "titanMalloc(nullptr) -> InvalidValue");
    expect(titanMalloc(&tmp, 0) == titanErrorInvalidValue,
           "titanMalloc(size=0) -> InvalidValue");
    expect(titanFree(0x12345) == titanErrorInvalidValue,
           "titanFree of an unknown pointer -> InvalidValue");
    expect(titanLaunchKernel(nullptr, nullptr, 0, 1) == titanErrorInvalidValue,
           "titanLaunchKernel(nullptr module) -> InvalidValue");

    // --- host<->device roundtrip --------------------------------------------
    const size_t N = 4096;
    titanDevicePtr buf = 0;
    expect(titanMalloc(&buf, N) == titanSuccess, "titanMalloc 4 KiB succeeds");

    std::vector<uint8_t> src(N), back(N, 0);
    for (size_t i = 0; i < N; i++) src[i] = (uint8_t)(i * 31 + 7);
    expect(titanMemcpy((void *)(uintptr_t)buf, src.data(), N,
                       titanMemcpyHostToDevice) == titanSuccess,
           "H2D memcpy succeeds");
    expect(titanMemcpy(back.data(), (void *)(uintptr_t)buf, N,
                       titanMemcpyDeviceToHost) == titanSuccess &&
           std::memcmp(src.data(), back.data(), N) == 0,
           "D2H memcpy returns the same bytes");

    // out-of-range device pointer must be rejected by resolve()
    expect(titanMemcpy(back.data(), (void *)(uintptr_t)0x0EADBEE0, N,
                       titanMemcpyDeviceToHost) == titanErrorInvalidValue,
           "D2H from an unallocated address -> InvalidValue");

    // --- device-to-device DMA (command ring TITAN_CMD_DMA) ------------------
    titanDevicePtr dst = 0;
    expect(titanMalloc(&dst, N) == titanSuccess, "titanMalloc D2D dst succeeds");
    expect(titanMemset(dst, 0, N) == titanSuccess, "titanMemset dst to 0");
    expect(titanMemcpy((void *)(uintptr_t)dst, (void *)(uintptr_t)buf, N,
                       titanMemcpyDeviceToDevice) == titanSuccess,
           "device-to-device memcpy succeeds");
    std::memset(back.data(), 0, N);
    titanMemcpy(back.data(), (void *)(uintptr_t)dst, N, titanMemcpyDeviceToHost);
    expect(std::memcmp(src.data(), back.data(), N) == 0,
           "D2D copy moved the bytes correctly through the DMA engine");

    // --- module loading errors ----------------------------------------------
    titanModule mod = nullptr;
    expect(titanModuleLoad(&mod, "does/not/exist.tbin") == titanErrorInvalidModule,
           "titanModuleLoad of a missing file -> InvalidModule");

    // a file with a bad magic must be rejected
    const char *bad = "bad_module.tbin";
    {
        FILE *f = std::fopen(bad, "wb");
        tx6_tbin_header_t h{};
        h.magic = 0xDEADBEEFu; h.version = 1; h.flags = 0; h.num_words = 1;
        std::fwrite(&h, sizeof(h), 1, f);
        uint32_t word = 0;
        std::fwrite(&word, 4, 1, f);
        std::fclose(f);
    }
    expect(titanModuleLoad(&mod, bad) == titanErrorInvalidModule,
           "titanModuleLoad of a bad-magic TBIN -> InvalidModule");
    std::remove(bad);

    // --- cleanup -------------------------------------------------------------
    expect(titanFree(buf) == titanSuccess, "titanFree succeeds");
    expect(titanFree(dst) == titanSuccess, "titanFree dst succeeds");
    expect(titanShutdown() == titanSuccess, "titanShutdown succeeds");

    std::printf("\n%s (%d/%d checks passed)\n",
                failures ? "RUNTIME TEST FAILED" : "RUNTIME TEST PASSED",
                checks - failures, checks);
    return failures ? 1 : 0;
}
