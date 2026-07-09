// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// Titan X6 kernel driver UAPI — shared between titan_x6_drv.c (the driver)
// and titan_runtime.cpp (the user-space runtime).
//
// On a real Linux system this header would live in include/uapi and the
// runtime would reach the driver through open("/dev/titan0") + ioctl().
// In the simulated build (TITAN_SIM_BUILD) the same entry points are plain
// functions exported by the driver object, so the whole stack runs as one
// process while exercising exactly the same code paths.

#ifndef TITAN_X6_DRV_H
#define TITAN_X6_DRV_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---------------------------------------------------------------------------
// PCIe identity
// ---------------------------------------------------------------------------
#define TITAN_PCI_VENDOR_ID   0x1B4D          // "Adhiraj Silicon"
#define TITAN_PCI_DEVICE_ID   0x0660          // Titan X6

// BAR0: MMIO register file (see titan_x6_gpu_model.h for the map)
// BAR1: VRAM aperture (GDDR7), write-combined

// ---------------------------------------------------------------------------
// Command ring packet format
//
// Matches rtl/control/titan_x5_command_processor.v: every ring entry is a
// 64-bit word whose low 8 bits are the opcode and upper 56 bits are payload.
// Multi-word packets carry additional 64-bit operand words immediately after
// the header.
// ---------------------------------------------------------------------------
#define TITAN_CMD_NOP       0x00  // 1 qword
#define TITAN_CMD_DRAW      0x01  // graphics path (unused by compute stack)
#define TITAN_CMD_DISPATCH  0x02  // 3 qwords: hdr, code_addr, {nthreads:32|param_addr:32}
#define TITAN_CMD_DMA       0x03  // 4 qwords: hdr, src, dst, nbytes (VRAM->VRAM)
#define TITAN_CMD_FENCE     0x04  // 1 qword:  hdr, payload[31:0] = seqno

#define TITAN_CMD_HDR(op, payload56) \
    (((uint64_t)(payload56) << 8) | ((uint64_t)(op) & 0xFF))

#define TITAN_RING_QWORDS   512   // 4 KiB ring

// ---------------------------------------------------------------------------
// ioctl interface
// ---------------------------------------------------------------------------
typedef struct titan_ioc_info {
    uint32_t vendor_id;
    uint32_t device_id;
    uint32_t vram_bytes;
    uint32_t num_gpcs;
    uint32_t num_sms;
    uint32_t clock_mhz;
} titan_ioc_info_t;

// Allocate a buffer object in GDDR7 VRAM.
typedef struct titan_ioc_gem_alloc {
    uint64_t size;        // in:  requested bytes (rounded up to 4 KiB)
    uint32_t handle;      // out: buffer object handle
    uint32_t gpu_addr;    // out: VRAM address (device virtual == physical)
} titan_ioc_gem_alloc_t;

typedef struct titan_ioc_gem_free {
    uint32_t handle;
} titan_ioc_gem_free_t;

// pwrite/pread-style transfer between user memory and a buffer object
// (models DMA over the PCIe BAR1 aperture).
typedef struct titan_ioc_gem_rw {
    uint32_t handle;
    uint32_t offset;      // byte offset inside the buffer object
    uint64_t user_ptr;    // user-space buffer
    uint64_t size;        // bytes
} titan_ioc_gem_rw_t;

// Submit a command buffer: `num_qwords` 64-bit packets copied into the
// ring; the driver appends a FENCE and rings the doorbell. Returns the
// fence seqno to wait on.
typedef struct titan_ioc_submit {
    uint64_t cmds_ptr;    // in: user pointer to uint64_t packets
    uint32_t num_qwords;  // in
    uint32_t fence;       // out: seqno signaled when this batch retires
} titan_ioc_submit_t;

typedef struct titan_ioc_wait {
    uint32_t fence;       // in
    uint32_t timeout_ms;  // in (0 = poll once)
} titan_ioc_wait_t;

#ifdef __KERNEL__
#include <linux/ioctl.h>
#define TITAN_IOC_MAGIC 'T'
#define TITAN_IOCTL_GET_INFO   _IOR (TITAN_IOC_MAGIC, 0x00, titan_ioc_info_t)
#define TITAN_IOCTL_GEM_ALLOC  _IOWR(TITAN_IOC_MAGIC, 0x01, titan_ioc_gem_alloc_t)
#define TITAN_IOCTL_GEM_FREE   _IOW (TITAN_IOC_MAGIC, 0x02, titan_ioc_gem_free_t)
#define TITAN_IOCTL_GEM_WRITE  _IOW (TITAN_IOC_MAGIC, 0x03, titan_ioc_gem_rw_t)
#define TITAN_IOCTL_GEM_READ   _IOWR(TITAN_IOC_MAGIC, 0x04, titan_ioc_gem_rw_t)
#define TITAN_IOCTL_SUBMIT     _IOWR(TITAN_IOC_MAGIC, 0x05, titan_ioc_submit_t)
#define TITAN_IOCTL_WAIT       _IOW (TITAN_IOC_MAGIC, 0x06, titan_ioc_wait_t)
#else
// Simulated build: ioctl numbers are plain command indices.
#define TITAN_IOCTL_GET_INFO   0x00
#define TITAN_IOCTL_GEM_ALLOC  0x01
#define TITAN_IOCTL_GEM_FREE   0x02
#define TITAN_IOCTL_GEM_WRITE  0x03
#define TITAN_IOCTL_GEM_READ   0x04
#define TITAN_IOCTL_SUBMIT     0x05
#define TITAN_IOCTL_WAIT       0x06

// Simulated syscall surface exported by titan_x6_drv.c
int  titan_sim_insmod(void);                       // load module + probe device
void titan_sim_rmmod(void);
int  titan_sim_open(void);                         // open /dev/titan0
int  titan_sim_close(int fd);
long titan_sim_ioctl(int fd, unsigned int cmd, void *arg);
#endif

#ifdef __cplusplus
}
#endif

#endif // TITAN_X6_DRV_H
