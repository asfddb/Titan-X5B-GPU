// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// test_matmul.cpp — end-to-end software-stack test (Phase 5.3).
//
// Exercises the full path for three kernel variants:
//
//   host matrices -> titanMalloc (GDDR7 BOs via ioctl) -> titanMemcpy (BAR1
//   DMA) -> titanLaunchKernel (DISPATCH packet through the command ring ->
//   Host Command Processor -> SM interpreter / tensor core array) ->
//   titanMemcpy back -> compare against a CPU reference.
//
//   1. matmul_scalar.tbin   int32 elements on the SM scalar pipeline
//   2. matmul_wmma_i8.tbin  INT8 WMMA tiles, int32 accumulators
//   3. matmul_wmma_fp8.tbin FP8 (E4M3) WMMA tiles, fp32 accumulators
//
// The .tbin images are produced by compiler/titan_compiler.py from
// compiler/kernels/matmul.py (see the Makefile).

#include "titan_runtime.h"

#include <cstdio>
#include <cstring>
#include <cmath>
#include <cstdlib>
#include <vector>

static int g_failures = 0;

#define CHECK(call)                                                        \
    do {                                                                   \
        titanError_t _e = (call);                                          \
        if (_e != titanSuccess) {                                          \
            std::fprintf(stderr, "%s:%d: %s -> %s\n", __FILE__, __LINE__,  \
                         #call, titanGetErrorString(_e));                  \
            std::exit(1);                                                  \
        }                                                                  \
    } while (0)

static void report(const char *name, bool ok)
{
    std::printf("  [%s] %s\n", ok ? "PASS" : "FAIL", name);
    if (!ok)
        g_failures++;
}

// ---------------------------------------------------------------------------
// 1. Scalar int32 matmul on the SM pipeline
// ---------------------------------------------------------------------------
static void test_scalar(const char *tbin, int M, int N, int K)
{
    std::vector<int32_t> A(M * K), B(K * N), C(M * N, -1), ref(M * N);
    std::srand(0x5CA1A);
    for (auto &v : A) v = std::rand() % 100 - 50;
    for (auto &v : B) v = std::rand() % 100 - 50;
    for (int i = 0; i < M; i++)
        for (int j = 0; j < N; j++) {
            int64_t acc = 0;
            for (int k = 0; k < K; k++)
                acc += (int64_t)A[i * K + k] * B[k * N + j];
            ref[i * N + j] = (int32_t)acc;
        }

    titanDevicePtr dA, dB, dC;
    CHECK(titanMalloc(&dA, A.size() * 4));
    CHECK(titanMalloc(&dB, B.size() * 4));
    CHECK(titanMalloc(&dC, C.size() * 4));
    CHECK(titanMemcpy((void *)(uintptr_t)dA, A.data(), A.size() * 4,
                      titanMemcpyHostToDevice));
    CHECK(titanMemcpy((void *)(uintptr_t)dB, B.data(), B.size() * 4,
                      titanMemcpyHostToDevice));

    titanModule mod;
    CHECK(titanModuleLoad(&mod, tbin));
    uint32_t params[6] = { dA, dB, dC, (uint32_t)M, (uint32_t)N, (uint32_t)K };
    CHECK(titanLaunchKernel(mod, params, 6, 1));
    CHECK(titanDeviceSynchronize());

    CHECK(titanMemcpy(C.data(), (void *)(uintptr_t)dC, C.size() * 4,
                      titanMemcpyDeviceToHost));

    bool ok = std::memcmp(C.data(), ref.data(), C.size() * 4) == 0;
    char label[96];
    std::snprintf(label, sizeof(label),
                  "scalar int32 matmul %dx%dx%d (SM pipeline)", M, N, K);
    report(label, ok);

    CHECK(titanModuleUnload(mod));
    CHECK(titanFree(dA));
    CHECK(titanFree(dB));
    CHECK(titanFree(dC));
}

// ---------------------------------------------------------------------------
// 2. INT8 WMMA matmul on the tensor core array
// ---------------------------------------------------------------------------
static void test_wmma_int8(const char *tbin, int M, int N, int K)
{
    std::vector<int8_t> A(M * K), B(K * N);
    std::vector<int32_t> C(M * N, -1), ref(M * N);
    std::srand(0x1E4501);
    for (auto &v : A) v = (int8_t)(std::rand() % 16 - 8);
    for (auto &v : B) v = (int8_t)(std::rand() % 16 - 8);
    for (int i = 0; i < M; i++)
        for (int j = 0; j < N; j++) {
            int32_t acc = 0;
            for (int k = 0; k < K; k++)
                acc += (int32_t)A[i * K + k] * (int32_t)B[k * N + j];
            ref[i * N + j] = acc;
        }

    titanDevicePtr dA, dB, dC;
    CHECK(titanMalloc(&dA, A.size()));
    CHECK(titanMalloc(&dB, B.size()));
    CHECK(titanMalloc(&dC, C.size() * 4));
    CHECK(titanMemcpy((void *)(uintptr_t)dA, A.data(), A.size(),
                      titanMemcpyHostToDevice));
    CHECK(titanMemcpy((void *)(uintptr_t)dB, B.data(), B.size(),
                      titanMemcpyHostToDevice));
    CHECK(titanMemset(dC, 0, C.size() * 4));   // WMMA accumulates into C

    titanModule mod;
    CHECK(titanModuleLoad(&mod, tbin));
    uint32_t params[6] = { dA, dB, dC, (uint32_t)M, (uint32_t)N, (uint32_t)K };
    CHECK(titanLaunchKernel(mod, params, 6, 1));
    CHECK(titanDeviceSynchronize());

    CHECK(titanMemcpy(C.data(), (void *)(uintptr_t)dC, C.size() * 4,
                      titanMemcpyDeviceToHost));

    bool ok = std::memcmp(C.data(), ref.data(), C.size() * 4) == 0;
    char label[96];
    std::snprintf(label, sizeof(label),
                  "INT8 WMMA matmul %dx%dx%d (tensor cores)", M, N, K);
    report(label, ok);

    CHECK(titanModuleUnload(mod));
    CHECK(titanFree(dA));
    CHECK(titanFree(dB));
    CHECK(titanFree(dC));
}

// ---------------------------------------------------------------------------
// 3. FP8 (E4M3) WMMA matmul, fp32 accumulation
// ---------------------------------------------------------------------------
static void test_wmma_fp8(const char *tbin, int M, int N, int K)
{
    std::vector<uint8_t> A(M * K), B(K * N);
    std::vector<float> C(M * N, -1.0f), ref(M * N);
    std::srand(0xF8F8);
    for (auto &v : A)
        v = titanFloatToFp8((std::rand() % 64 - 32) / 16.0f);
    for (auto &v : B)
        v = titanFloatToFp8((std::rand() % 64 - 32) / 16.0f);

    // CPU reference decodes FP8 exactly like the tensor cores and
    // accumulates in fp32 in the same k order -> bit-exact expectation.
    for (int i = 0; i < M; i++)
        for (int j = 0; j < N; j++) {
            float acc = 0.0f;
            for (int k = 0; k < K; k++)
                acc += titanFp8ToFloat(A[i * K + k]) *
                       titanFp8ToFloat(B[k * N + j]);
            ref[i * N + j] = acc;
        }

    titanDevicePtr dA, dB, dC;
    CHECK(titanMalloc(&dA, A.size()));
    CHECK(titanMalloc(&dB, B.size()));
    CHECK(titanMalloc(&dC, C.size() * 4));
    CHECK(titanMemcpy((void *)(uintptr_t)dA, A.data(), A.size(),
                      titanMemcpyHostToDevice));
    CHECK(titanMemcpy((void *)(uintptr_t)dB, B.data(), B.size(),
                      titanMemcpyHostToDevice));
    CHECK(titanMemset(dC, 0, C.size() * 4));

    titanModule mod;
    CHECK(titanModuleLoad(&mod, tbin));
    uint32_t params[6] = { dA, dB, dC, (uint32_t)M, (uint32_t)N, (uint32_t)K };
    CHECK(titanLaunchKernel(mod, params, 6, 1));
    CHECK(titanDeviceSynchronize());

    CHECK(titanMemcpy(C.data(), (void *)(uintptr_t)dC, C.size() * 4,
                      titanMemcpyDeviceToHost));

    bool ok = true;
    float max_err = 0.0f;
    for (int i = 0; i < M * N; i++) {
        float err = std::fabs(C[i] - ref[i]);
        max_err = std::fmax(max_err, err);
        if (err > 1e-4f)
            ok = false;
    }
    char label[96];
    std::snprintf(label, sizeof(label),
                  "FP8-E4M3 WMMA matmul %dx%dx%d (max |err| = %g)",
                  M, N, K, (double)max_err);
    report(label, ok);

    CHECK(titanModuleUnload(mod));
    CHECK(titanFree(dA));
    CHECK(titanFree(dB));
    CHECK(titanFree(dC));
}

// ---------------------------------------------------------------------------
int main(int argc, char **argv)
{
    const char *dir = (argc > 1) ? argv[1] : ".";
    char scalar[256], wi8[256], wfp8[256];
    std::snprintf(scalar, sizeof(scalar), "%s/matmul_scalar.tbin", dir);
    std::snprintf(wi8, sizeof(wi8), "%s/matmul_wmma_i8.tbin", dir);
    std::snprintf(wfp8, sizeof(wfp8), "%s/matmul_wmma_fp8.tbin", dir);

    std::printf("=== Titan X6 software stack: end-to-end matmul test ===\n");
    CHECK(titanInit());

    titanDeviceProp prop;
    CHECK(titanGetDeviceProperties(&prop));
    std::printf("[titan-rt] device: %s | %u MiB GDDR7 | %u GPCs / %u SMs @ "
                "%u MHz\n\n", prop.name, prop.vram_bytes >> 20,
                prop.num_gpcs, prop.num_sms, prop.clock_mhz);

    test_scalar(scalar, 32, 32, 32);
    test_wmma_int8(wi8, 32, 32, 32);
    test_wmma_fp8(wfp8, 64, 64, 64);
    // non-square shapes through the same kernels
    test_scalar(scalar, 16, 8, 24);
    test_wmma_int8(wi8, 48, 16, 32);

    CHECK(titanShutdown());

    std::printf("\n%s (%d failure%s)\n",
                g_failures ? "*** TEST FAILED ***" : "ALL TESTS PASSED",
                g_failures, g_failures == 1 ? "" : "s");
    return g_failures ? 1 : 0;
}
