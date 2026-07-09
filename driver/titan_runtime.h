// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// Titan Runtime API — user-space library mirroring the CUDA runtime.
// Implemented in titan_runtime.cpp on top of the titan_x6_drv.c ioctl
// interface.

#ifndef TITAN_RUNTIME_H
#define TITAN_RUNTIME_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    titanSuccess = 0,
    titanErrorInvalidValue,
    titanErrorMemoryAllocation,
    titanErrorNoDevice,
    titanErrorInvalidModule,
    titanErrorLaunchFailure,
    titanErrorTimeout,
    titanErrorIoctl,
} titanError_t;

typedef enum {
    titanMemcpyHostToDevice,
    titanMemcpyDeviceToHost,
    titanMemcpyDeviceToDevice,
} titanMemcpyKind;

typedef uint32_t titanDevicePtr;      // VRAM address
typedef struct titanModule_st *titanModule;

typedef struct {
    char     name[32];
    uint32_t vram_bytes;
    uint32_t num_gpcs;
    uint32_t num_sms;
    uint32_t clock_mhz;
} titanDeviceProp;

// --- device / context ---
titanError_t titanInit(void);
titanError_t titanShutdown(void);
titanError_t titanGetDeviceProperties(titanDeviceProp *prop);

// --- memory ---
titanError_t titanMalloc(titanDevicePtr *dptr, size_t size);
titanError_t titanFree(titanDevicePtr dptr);
titanError_t titanMemcpy(void *dst, const void *src, size_t size,
                         titanMemcpyKind kind);
titanError_t titanMemset(titanDevicePtr dptr, int value, size_t size);

// --- modules & launch ---
titanError_t titanModuleLoad(titanModule *module, const char *tbin_path);
titanError_t titanModuleUnload(titanModule module);

// Launch: `params` is an array of 32-bit kernel arguments (device pointers
// and int scalars), copied into a device-side parameter block whose address
// lands in R1 of every thread.
titanError_t titanLaunchKernel(titanModule module, const uint32_t *params,
                               uint32_t num_params, uint32_t num_threads);

titanError_t titanDeviceSynchronize(void);

const char *titanGetErrorString(titanError_t err);

// FP8 (E4M3) host-side conversion, bit-compatible with the tensor cores.
uint8_t titanFloatToFp8(float f);
float   titanFp8ToFloat(uint8_t b);

#ifdef __cplusplus
}
#endif

#endif // TITAN_RUNTIME_H
