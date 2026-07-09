// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// titan_runtime.cpp — user-space Titan Runtime API (Phase 5.3).
//
// Sits on the driver's ioctl surface exactly like the CUDA runtime sits on
// the kernel-mode driver:
//
//   titanMalloc        -> TITAN_IOCTL_GEM_ALLOC        (GDDR7 buffer object)
//   titanMemcpy        -> TITAN_IOCTL_GEM_WRITE/READ   (BAR1 aperture DMA)
//   titanLaunchKernel  -> param-block upload + DISPATCH packet
//   titanDeviceSynchronize -> TITAN_IOCTL_WAIT on the last fence
//
// In the simulated build the "syscalls" are the titan_sim_* entry points
// exported by titan_x6_drv.c; on real hardware they would be
// open("/dev/titan0") / ioctl().

#include "titan_runtime.h"
#include "titan_x6_drv.h"
#include "titan_x6_isa.h"
#include "titan_x6_gpu_model.h"   // fp8 helpers shared with the model

#include <cstdio>
#include <cstring>
#include <cstdlib>
#include <map>
#include <vector>

// ---------------------------------------------------------------------------
// Driver access shim
// ---------------------------------------------------------------------------
namespace {

struct Allocation {
    uint32_t handle;
    uint32_t size;
};

struct RuntimeState {
    bool initialized = false;
    int  fd          = -1;
    std::map<uint32_t, Allocation> allocs;   // gpu_addr -> allocation
    uint32_t last_fence = 0;
};

RuntimeState g_rt;

long drv_ioctl(unsigned int cmd, void *arg)
{
    return titan_sim_ioctl(g_rt.fd, cmd, arg);
}

titanError_t require_init()
{
    return g_rt.initialized ? titanSuccess : titanErrorNoDevice;
}

// Find the allocation containing [dptr, dptr+size); returns handle/offset.
titanError_t resolve(titanDevicePtr dptr, size_t size,
                     uint32_t *handle, uint32_t *offset)
{
    auto it = g_rt.allocs.upper_bound(dptr);
    if (it == g_rt.allocs.begin())
        return titanErrorInvalidValue;
    --it;
    uint32_t base = it->first;
    const Allocation &a = it->second;
    if (dptr < base || dptr + size > (uint64_t)base + a.size)
        return titanErrorInvalidValue;
    *handle = a.handle;
    *offset = dptr - base;
    return titanSuccess;
}

} // namespace

// ---------------------------------------------------------------------------
// Device / context
// ---------------------------------------------------------------------------
titanError_t titanInit(void)
{
    if (g_rt.initialized)
        return titanSuccess;
    if (titan_sim_insmod() != 0)
        return titanErrorNoDevice;
    g_rt.fd = titan_sim_open();
    if (g_rt.fd < 0) {
        titan_sim_rmmod();
        return titanErrorNoDevice;
    }
    g_rt.initialized = true;
    return titanSuccess;
}

titanError_t titanShutdown(void)
{
    if (!g_rt.initialized)
        return titanSuccess;
    titan_sim_close(g_rt.fd);
    titan_sim_rmmod();
    g_rt = RuntimeState{};
    return titanSuccess;
}

titanError_t titanGetDeviceProperties(titanDeviceProp *prop)
{
    if (titanError_t e = require_init())
        return e;
    if (!prop)
        return titanErrorInvalidValue;
    titan_ioc_info_t info{};
    if (drv_ioctl(TITAN_IOCTL_GET_INFO, &info) != 0)
        return titanErrorIoctl;
    std::snprintf(prop->name, sizeof(prop->name), "Titan X6 [%04X:%04X]",
                  info.vendor_id, info.device_id);
    prop->vram_bytes = info.vram_bytes;
    prop->num_gpcs   = info.num_gpcs;
    prop->num_sms    = info.num_sms;
    prop->clock_mhz  = info.clock_mhz;
    return titanSuccess;
}

// ---------------------------------------------------------------------------
// Memory
// ---------------------------------------------------------------------------
titanError_t titanMalloc(titanDevicePtr *dptr, size_t size)
{
    if (titanError_t e = require_init())
        return e;
    if (!dptr || size == 0)
        return titanErrorInvalidValue;
    titan_ioc_gem_alloc_t req{};
    req.size = size;
    if (drv_ioctl(TITAN_IOCTL_GEM_ALLOC, &req) != 0)
        return titanErrorMemoryAllocation;
    g_rt.allocs[req.gpu_addr] = Allocation{req.handle,
                                           (uint32_t)((size + 4095) & ~4095u)};
    *dptr = req.gpu_addr;
    return titanSuccess;
}

titanError_t titanFree(titanDevicePtr dptr)
{
    if (titanError_t e = require_init())
        return e;
    auto it = g_rt.allocs.find(dptr);
    if (it == g_rt.allocs.end())
        return titanErrorInvalidValue;
    titan_ioc_gem_free_t req{it->second.handle};
    drv_ioctl(TITAN_IOCTL_GEM_FREE, &req);
    g_rt.allocs.erase(it);
    return titanSuccess;
}

titanError_t titanMemcpy(void *dst, const void *src, size_t size,
                         titanMemcpyKind kind)
{
    if (titanError_t e = require_init())
        return e;
    if (size == 0)
        return titanSuccess;

    titan_ioc_gem_rw_t rw{};
    titanError_t e;

    switch (kind) {
    case titanMemcpyHostToDevice: {
        titanDevicePtr d = (titanDevicePtr)(uintptr_t)dst;
        if ((e = resolve(d, size, &rw.handle, &rw.offset)))
            return e;
        rw.user_ptr = (uint64_t)(uintptr_t)src;
        rw.size     = size;
        return drv_ioctl(TITAN_IOCTL_GEM_WRITE, &rw) ? titanErrorIoctl
                                                     : titanSuccess;
    }
    case titanMemcpyDeviceToHost: {
        titanDevicePtr d = (titanDevicePtr)(uintptr_t)src;
        if ((e = resolve(d, size, &rw.handle, &rw.offset)))
            return e;
        rw.user_ptr = (uint64_t)(uintptr_t)dst;
        rw.size     = size;
        return drv_ioctl(TITAN_IOCTL_GEM_READ, &rw) ? titanErrorIoctl
                                                    : titanSuccess;
    }
    case titanMemcpyDeviceToDevice: {
        // DMA engine copy via the command ring
        uint64_t pkt[4];
        pkt[0] = TITAN_CMD_HDR(TITAN_CMD_DMA, 0);
        pkt[1] = (uint32_t)(uintptr_t)src;
        pkt[2] = (uint32_t)(uintptr_t)dst;
        pkt[3] = size;
        titan_ioc_submit_t sub{};
        sub.cmds_ptr   = (uint64_t)(uintptr_t)pkt;
        sub.num_qwords = 4;
        if (drv_ioctl(TITAN_IOCTL_SUBMIT, &sub) != 0)
            return titanErrorIoctl;
        g_rt.last_fence = sub.fence;
        return titanDeviceSynchronize();
    }
    }
    return titanErrorInvalidValue;
}

titanError_t titanMemset(titanDevicePtr dptr, int value, size_t size)
{
    if (titanError_t e = require_init())
        return e;
    std::vector<uint8_t> buf(size, (uint8_t)value);
    return titanMemcpy((void *)(uintptr_t)dptr, buf.data(), size,
                       titanMemcpyHostToDevice);
}

// ---------------------------------------------------------------------------
// Modules & kernel launch
// ---------------------------------------------------------------------------
struct titanModule_st {
    titanDevicePtr code_addr = 0;
    uint32_t       num_words = 0;
    uint32_t       flags     = 0;
};

titanError_t titanModuleLoad(titanModule *module, const char *tbin_path)
{
    if (titanError_t e = require_init())
        return e;
    if (!module || !tbin_path)
        return titanErrorInvalidValue;

    FILE *f = std::fopen(tbin_path, "rb");
    if (!f) {
        std::fprintf(stderr, "[titan-rt] cannot open module '%s'\n",
                     tbin_path);
        return titanErrorInvalidModule;
    }
    tx6_tbin_header_t hdr{};
    if (std::fread(&hdr, sizeof(hdr), 1, f) != 1 ||
        hdr.magic != TX6_TBIN_MAGIC || hdr.version != TX6_TBIN_VERSION ||
        hdr.num_words == 0) {
        std::fclose(f);
        return titanErrorInvalidModule;
    }
    std::vector<uint32_t> words(hdr.num_words);
    if (std::fread(words.data(), 4, hdr.num_words, f) != hdr.num_words) {
        std::fclose(f);
        return titanErrorInvalidModule;
    }
    std::fclose(f);

    titanDevicePtr code = 0;
    titanError_t e = titanMalloc(&code, hdr.num_words * 4u);
    if (e)
        return e;
    e = titanMemcpy((void *)(uintptr_t)code, words.data(), hdr.num_words * 4u,
                    titanMemcpyHostToDevice);
    if (e) {
        titanFree(code);
        return e;
    }

    titanModule m = new titanModule_st;
    m->code_addr = code;
    m->num_words = hdr.num_words;
    m->flags     = hdr.flags;
    *module = m;
    std::printf("[titan-rt] module '%s': %u instructions at 0x%08X%s\n",
                tbin_path, hdr.num_words, code,
                (hdr.flags & 1) ? " (tensor)" : "");
    return titanSuccess;
}

titanError_t titanModuleUnload(titanModule module)
{
    if (!module)
        return titanErrorInvalidValue;
    titanFree(module->code_addr);
    delete module;
    return titanSuccess;
}

titanError_t titanLaunchKernel(titanModule module, const uint32_t *params,
                               uint32_t num_params, uint32_t num_threads)
{
    if (titanError_t e = require_init())
        return e;
    if (!module || (num_params && !params) || num_threads == 0)
        return titanErrorInvalidValue;

    // upload the parameter block
    titanDevicePtr pblock = 0;
    uint32_t psize = num_params ? num_params * 4u : 4u;
    titanError_t e = titanMalloc(&pblock, psize);
    if (e)
        return e;
    if (num_params) {
        e = titanMemcpy((void *)(uintptr_t)pblock, params, num_params * 4u,
                        titanMemcpyHostToDevice);
        if (e) {
            titanFree(pblock);
            return e;
        }
    }

    // build & submit the DISPATCH packet
    uint64_t pkt[3];
    pkt[0] = TITAN_CMD_HDR(TITAN_CMD_DISPATCH, 0);
    pkt[1] = module->code_addr;
    pkt[2] = (uint64_t)num_threads << 32 | pblock;

    titan_ioc_submit_t sub{};
    sub.cmds_ptr   = (uint64_t)(uintptr_t)pkt;
    sub.num_qwords = 3;
    if (drv_ioctl(TITAN_IOCTL_SUBMIT, &sub) != 0) {
        titanFree(pblock);
        return titanErrorLaunchFailure;
    }
    g_rt.last_fence = sub.fence;

    // synchronous model: safe to release the param block after the fence
    e = titanDeviceSynchronize();
    titanFree(pblock);
    return e ? titanErrorLaunchFailure : titanSuccess;
}

titanError_t titanDeviceSynchronize(void)
{
    if (titanError_t e = require_init())
        return e;
    if (g_rt.last_fence == 0)
        return titanSuccess;
    titan_ioc_wait_t w{g_rt.last_fence, 1000};
    if (drv_ioctl(TITAN_IOCTL_WAIT, &w) != 0)
        return titanErrorTimeout;
    return titanSuccess;
}

// ---------------------------------------------------------------------------
// Misc
// ---------------------------------------------------------------------------
const char *titanGetErrorString(titanError_t err)
{
    switch (err) {
    case titanSuccess:               return "success";
    case titanErrorInvalidValue:     return "invalid value";
    case titanErrorMemoryAllocation: return "VRAM allocation failed";
    case titanErrorNoDevice:         return "no Titan device";
    case titanErrorInvalidModule:    return "invalid TBIN module";
    case titanErrorLaunchFailure:    return "kernel launch failed";
    case titanErrorTimeout:          return "fence wait timeout";
    case titanErrorIoctl:            return "driver ioctl failed";
    }
    return "unknown error";
}

uint8_t titanFloatToFp8(float f) { return titan_fp8_from_float(f); }
float   titanFp8ToFloat(uint8_t b) { return titan_fp8_to_float(b); }
