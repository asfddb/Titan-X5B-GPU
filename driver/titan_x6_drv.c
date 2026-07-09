// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X6 GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
//
// titan_x6_drv.c — Linux PCIe character driver for the Titan X6 GPU.
//
// Responsibilities:
//   * PCI probe: map BAR0 (MMIO register file) and BAR1 (GDDR7 aperture)
//   * GEM-style VRAM buffer-object management (first-fit allocator over the
//     GDDR7 address space) exposed through ioctls
//   * Command submission: user command buffers are validated, copied into
//     the kernel-owned ring, terminated with a FENCE packet, and the
//     doorbell (RING_WPTR) is rung so the Host Command Processor fetches
//     them (see rtl/control/titan_x5_command_processor.v)
//   * Fence wait via the FENCE_SEQ register / fence interrupt
//
// Build modes:
//   __KERNEL__        — real kernel module (structure shown, needs Kbuild)
//   TITAN_SIM_BUILD   — the same driver logic compiled into user space and
//                       bound to the functional GPU model in
//                       titan_x6_gpu_model.c. open()/ioctl() are exported
//                       as titan_sim_open()/titan_sim_ioctl() so the
//                       runtime exercises the identical code paths.

#include "titan_x6_drv.h"
#include "titan_x6_gpu_model.h"

// ---------------------------------------------------------------------------
// Kernel-service shim
// ---------------------------------------------------------------------------
#ifdef __KERNEL__

#include <linux/module.h>
#include <linux/pci.h>
#include <linux/fs.h>
#include <linux/cdev.h>
#include <linux/uaccess.h>
#include <linux/slab.h>
#include <linux/mutex.h>

#define TITAN_LOG(fmt, ...)  pr_info("titan: " fmt "\n", ##__VA_ARGS__)
#define TITAN_ERR(fmt, ...)  pr_err ("titan: " fmt "\n", ##__VA_ARGS__)

#else // TITAN_SIM_BUILD ------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#define TITAN_LOG(fmt, ...)  printf ("[titan-drv] " fmt "\n", ##__VA_ARGS__)
#define TITAN_ERR(fmt, ...)  fprintf(stderr, "[titan-drv] ERROR: " fmt "\n", ##__VA_ARGS__)

#define EINVAL_RET   (-22)
#define ENOMEM_RET   (-12)
#define EBADF_RET    (-9)
#define ETIMEDOUT_RET (-110)

// copy_{from,to}_user collapse to memcpy in the single-process simulation
static inline int copy_from_user(void *dst, const void *src, unsigned long n)
{ memcpy(dst, src, n); return 0; }
static inline int copy_to_user(void *dst, const void *src, unsigned long n)
{ memcpy(dst, src, n); return 0; }

#endif

// ---------------------------------------------------------------------------
// Device state
// ---------------------------------------------------------------------------
#define TITAN_VRAM_BYTES   (256u * 1024u * 1024u)   // 256 MiB simulated GDDR7
#define TITAN_MAX_BOS      1024
#define TITAN_PAGE         4096u

typedef struct titan_bo {
    uint32_t gpu_addr;
    uint32_t size;       // page-rounded
    int      used;
} titan_bo_t;

typedef struct titan_device {
    // MMIO / aperture (in the sim build these are backed by the model)
    titan_gpu_model_t *hw;

    // command ring (system memory, GPU DMAs from it)
    uint64_t ring[TITAN_RING_QWORDS];
    uint32_t ring_wptr;

    // buffer objects: handle = index + 1
    titan_bo_t bos[TITAN_MAX_BOS];

    uint32_t fence_counter;
    int      opened;
} titan_device_t;

static titan_device_t titan_dev;

// --- MMIO accessors ---------------------------------------------------------
#ifdef __KERNEL__
static void __iomem *titan_bar0;
static void __iomem *titan_bar1;
#define malloc(n) kvmalloc((n), GFP_KERNEL)
#define free(p)   kvfree(p)
static inline uint32_t titan_rd(uint32_t off)            { return readl(titan_bar0 + off); }
static inline void     titan_wr(uint32_t off, uint32_t v) { writel(v, titan_bar0 + off); }
#else
static inline uint32_t titan_rd(uint32_t off)
{ return titan_gpu_mmio_read(titan_dev.hw, off); }
static inline void titan_wr(uint32_t off, uint32_t v)
{ titan_gpu_mmio_write(titan_dev.hw, off, v); }
#endif

// ---------------------------------------------------------------------------
// VRAM buffer-object allocator (first-fit over free gaps)
// ---------------------------------------------------------------------------
// Address 0 is reserved so a NULL device pointer is never valid.
#define TITAN_VRAM_HEAP_BASE  TITAN_PAGE

static uint32_t round_up_page(uint64_t size)
{
    return (uint32_t)((size + TITAN_PAGE - 1) & ~(uint64_t)(TITAN_PAGE - 1));
}

// Is [addr, addr+size) free of live BOs?
static int range_is_free(uint32_t addr, uint32_t size)
{
    int i;
    for (i = 0; i < TITAN_MAX_BOS; i++) {
        titan_bo_t *bo = &titan_dev.bos[i];
        if (!bo->used)
            continue;
        if (addr < bo->gpu_addr + bo->size && bo->gpu_addr < addr + size)
            return 0;
    }
    return 1;
}

static int titan_bo_alloc(uint64_t size, uint32_t *handle, uint32_t *gpu_addr)
{
    uint32_t need = round_up_page(size ? size : 1);
    uint32_t vram = titan_rd(TITAN_REG_VRAM_SIZE);
    uint32_t addr;
    int      slot;

    for (slot = 0; slot < TITAN_MAX_BOS; slot++)
        if (!titan_dev.bos[slot].used)
            break;
    if (slot == TITAN_MAX_BOS)
        return ENOMEM_RET;

    // first-fit scan of the heap in page steps, jumping over live BOs
    addr = TITAN_VRAM_HEAP_BASE;
    while (addr + need <= vram) {
        if (range_is_free(addr, need)) {
            titan_dev.bos[slot].gpu_addr = addr;
            titan_dev.bos[slot].size     = need;
            titan_dev.bos[slot].used     = 1;
            *handle   = (uint32_t)slot + 1;
            *gpu_addr = addr;
            return 0;
        }
        // skip past the BO that overlaps this address
        {
            int i;
            uint32_t next = addr + TITAN_PAGE;
            for (i = 0; i < TITAN_MAX_BOS; i++) {
                titan_bo_t *bo = &titan_dev.bos[i];
                if (bo->used && addr < bo->gpu_addr + bo->size &&
                    bo->gpu_addr < addr + need)
                    if (bo->gpu_addr + bo->size > next)
                        next = bo->gpu_addr + bo->size;
            }
            addr = next;
        }
    }
    return ENOMEM_RET;
}

static titan_bo_t *titan_bo_lookup(uint32_t handle)
{
    if (handle == 0 || handle > TITAN_MAX_BOS)
        return NULL;
    if (!titan_dev.bos[handle - 1].used)
        return NULL;
    return &titan_dev.bos[handle - 1];
}

// ---------------------------------------------------------------------------
// Command submission
// ---------------------------------------------------------------------------
// Copy a validated user command buffer into the ring, append a FENCE and
// ring the doorbell. Returns the fence seqno (>0) or a negative errno.
static long titan_submit(const uint64_t *cmds, uint32_t num_qwords,
                         uint32_t *fence_out)
{
    uint32_t i, seq;

    if (num_qwords == 0 || num_qwords > TITAN_RING_QWORDS - 2)
        return EINVAL_RET;

    // Basic validation: opcodes must be known and packet sizes must add up.
    for (i = 0; i < num_qwords; ) {
        uint8_t op = (uint8_t)(cmds[i] & 0xFF);
        uint32_t len;
        switch (op) {
        case TITAN_CMD_NOP:      len = 1; break;
        case TITAN_CMD_DISPATCH: len = 3; break;
        case TITAN_CMD_DMA:      len = 4; break;
        case TITAN_CMD_FENCE:    len = 1; break;
        default:
            TITAN_ERR("submit: illegal packet opcode 0x%02X at qword %u",
                      op, i);
            return EINVAL_RET;
        }
        if (i + len > num_qwords) {
            TITAN_ERR("submit: truncated packet at qword %u", i);
            return EINVAL_RET;
        }
        i += len;
    }

    // copy into the ring
    for (i = 0; i < num_qwords; i++) {
        titan_dev.ring[titan_dev.ring_wptr] = cmds[i];
        titan_dev.ring_wptr = (titan_dev.ring_wptr + 1) % TITAN_RING_QWORDS;
    }

    // append fence
    seq = ++titan_dev.fence_counter;
    titan_dev.ring[titan_dev.ring_wptr] = TITAN_CMD_HDR(TITAN_CMD_FENCE, seq);
    titan_dev.ring_wptr = (titan_dev.ring_wptr + 1) % TITAN_RING_QWORDS;

    // doorbell
    titan_wr(TITAN_REG_RING_WPTR, titan_dev.ring_wptr);

    if (titan_rd(TITAN_REG_STATUS) & TITAN_STAT_ERROR) {
        TITAN_ERR("submit: GPU raised ERROR while executing batch (fence %u)",
                  seq);
    }

    *fence_out = seq;
    return 0;
}

static int titan_fence_done(uint32_t seq)
{
    // seqno compare with wrap tolerance
    return (int32_t)(titan_rd(TITAN_REG_FENCE_SEQ) - seq) >= 0;
}

// ---------------------------------------------------------------------------
// ioctl dispatch (shared by kernel and sim builds)
// ---------------------------------------------------------------------------
static long titan_ioctl_dispatch(unsigned int cmd, void *arg)
{
    switch (cmd) {
    case TITAN_IOCTL_GET_INFO: {
        titan_ioc_info_t info;
        info.vendor_id  = TITAN_PCI_VENDOR_ID;
        info.device_id  = TITAN_PCI_DEVICE_ID;
        info.vram_bytes = titan_rd(TITAN_REG_VRAM_SIZE);
        info.num_gpcs   = 4;
        info.num_sms    = 64;   // 4 GPCs x 4 TPCs x 4 SMs
        info.clock_mhz  = 2610;
        if (copy_to_user(arg, &info, sizeof(info)))
            return EINVAL_RET;
        return 0;
    }

    case TITAN_IOCTL_GEM_ALLOC: {
        titan_ioc_gem_alloc_t req;
        long ret;
        if (copy_from_user(&req, arg, sizeof(req)))
            return EINVAL_RET;
        ret = titan_bo_alloc(req.size, &req.handle, &req.gpu_addr);
        if (ret)
            return ret;
        TITAN_LOG("gem_alloc: handle=%u gpu_addr=0x%08X size=%u KiB",
                  req.handle, req.gpu_addr,
                  titan_dev.bos[req.handle - 1].size / 1024);
        if (copy_to_user(arg, &req, sizeof(req)))
            return EINVAL_RET;
        return 0;
    }

    case TITAN_IOCTL_GEM_FREE: {
        titan_ioc_gem_free_t req;
        titan_bo_t *bo;
        if (copy_from_user(&req, arg, sizeof(req)))
            return EINVAL_RET;
        bo = titan_bo_lookup(req.handle);
        if (!bo)
            return EINVAL_RET;
        bo->used = 0;
        return 0;
    }

    case TITAN_IOCTL_GEM_WRITE:
    case TITAN_IOCTL_GEM_READ: {
        titan_ioc_gem_rw_t req;
        titan_bo_t *bo;
        uint8_t *vram;
        if (copy_from_user(&req, arg, sizeof(req)))
            return EINVAL_RET;
        bo = titan_bo_lookup(req.handle);
        if (!bo)
            return EINVAL_RET;
        if (req.offset + req.size > bo->size)
            return EINVAL_RET;
#ifdef __KERNEL__
        vram = titan_bar1;   // BAR1 aperture
#else
        vram = titan_gpu_vram(titan_dev.hw);
#endif
        if (cmd == TITAN_IOCTL_GEM_WRITE) {
            if (copy_from_user(vram + bo->gpu_addr + req.offset,
                               (void *)(uintptr_t)req.user_ptr,
                               (unsigned long)req.size))
                return EINVAL_RET;
        } else {
            if (copy_to_user((void *)(uintptr_t)req.user_ptr,
                             vram + bo->gpu_addr + req.offset,
                             (unsigned long)req.size))
                return EINVAL_RET;
        }
        return 0;
    }

    case TITAN_IOCTL_SUBMIT: {
        titan_ioc_submit_t req;
        uint64_t *cmds;
        long ret;
        if (copy_from_user(&req, arg, sizeof(req)))
            return EINVAL_RET;
        if (req.num_qwords == 0 || req.num_qwords > TITAN_RING_QWORDS - 2)
            return EINVAL_RET;
        cmds = (uint64_t *)malloc(req.num_qwords * sizeof(uint64_t));
        if (!cmds)
            return ENOMEM_RET;
        if (copy_from_user(cmds, (void *)(uintptr_t)req.cmds_ptr,
                           req.num_qwords * sizeof(uint64_t))) {
            free(cmds);
            return EINVAL_RET;
        }
        ret = titan_submit(cmds, req.num_qwords, &req.fence);
        free(cmds);
        if (ret)
            return ret;
        if (copy_to_user(arg, &req, sizeof(req)))
            return EINVAL_RET;
        return 0;
    }

    case TITAN_IOCTL_WAIT: {
        titan_ioc_wait_t req;
        if (copy_from_user(&req, arg, sizeof(req)))
            return EINVAL_RET;
        // The simulated GPU retires synchronously at doorbell time, so the
        // fence is normally already signaled; keep a bounded poll loop so
        // the code shape matches real hardware.
        {
            uint32_t spins = req.timeout_ms ? req.timeout_ms * 1000u : 1u;
            while (!titan_fence_done(req.fence) && spins--)
                ;
        }
        if (!titan_fence_done(req.fence))
            return ETIMEDOUT_RET;
        // acknowledge the fence interrupt
        titan_wr(TITAN_REG_INTR_STATUS, 1);
        return 0;
    }

    default:
        return EINVAL_RET;
    }
}

// ---------------------------------------------------------------------------
// Probe / remove
// ---------------------------------------------------------------------------
static int titan_probe_common(void)
{
    uint32_t id;

    memset(titan_dev.bos, 0, sizeof(titan_dev.bos));
    memset(titan_dev.ring, 0, sizeof(titan_dev.ring));
    titan_dev.ring_wptr     = 0;
    titan_dev.fence_counter = 0;

#ifndef __KERNEL__
    titan_dev.hw = titan_gpu_create(TITAN_VRAM_BYTES);
    if (!titan_dev.hw)
        return ENOMEM_RET;
    titan_gpu_bind_ring(titan_dev.hw, titan_dev.ring, TITAN_RING_QWORDS);
#endif

    id = titan_rd(TITAN_REG_ID);
    if (id != TITAN_ID_VALUE) {
        TITAN_ERR("probe: bad device id 0x%08X", id);
        return EINVAL_RET;
    }

    titan_wr(TITAN_REG_RING_BASE, 0);   // informational in the sim build
    titan_wr(TITAN_REG_RING_WPTR, 0);
    titan_wr(TITAN_REG_CTRL, 1);        // enable command processor

    TITAN_LOG("probe: Titan X6 [%04X:%04X], %u MiB GDDR7, ring %u qwords",
              TITAN_PCI_VENDOR_ID, TITAN_PCI_DEVICE_ID,
              titan_rd(TITAN_REG_VRAM_SIZE) >> 20, TITAN_RING_QWORDS);
    return 0;
}

#ifdef __KERNEL__
// ---------------------------------------------------------------------------
// Real kernel-module scaffolding (reference; built out-of-tree with Kbuild)
// ---------------------------------------------------------------------------
static long titan_unlocked_ioctl(struct file *f, unsigned int cmd,
                                 unsigned long arg)
{
    return titan_ioctl_dispatch(_IOC_NR(cmd), (void *)arg);
}

static const struct file_operations titan_fops = {
    .owner          = THIS_MODULE,
    .unlocked_ioctl = titan_unlocked_ioctl,
};

static const struct pci_device_id titan_pci_ids[] = {
    { PCI_DEVICE(TITAN_PCI_VENDOR_ID, TITAN_PCI_DEVICE_ID) },
    { 0 }
};
MODULE_DEVICE_TABLE(pci, titan_pci_ids);

static int titan_pci_probe(struct pci_dev *pdev,
                           const struct pci_device_id *id)
{
    int ret = pcim_enable_device(pdev);
    if (ret)
        return ret;
    titan_bar0 = pcim_iomap(pdev, 0, 0);
    titan_bar1 = pcim_iomap(pdev, 1, 0);
    if (!titan_bar0 || !titan_bar1)
        return -ENOMEM;
    pci_set_master(pdev);
    return titan_probe_common();
}

static struct pci_driver titan_pci_driver = {
    .name     = "titan_x6",
    .id_table = titan_pci_ids,
    .probe    = titan_pci_probe,
};
module_pci_driver(titan_pci_driver);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Titan X6 GPU driver");

#else
// ---------------------------------------------------------------------------
// Simulated module / syscall surface
// ---------------------------------------------------------------------------
int titan_sim_insmod(void)
{
    TITAN_LOG("insmod: titan_x6 module loaded, scanning PCI bus...");
    TITAN_LOG("pci 0000:01:00.0: [%04X:%04X] Titan X6 found (BAR0 MMIO, "
              "BAR1 VRAM aperture)", TITAN_PCI_VENDOR_ID, TITAN_PCI_DEVICE_ID);
    return (int)titan_probe_common();
}

void titan_sim_rmmod(void)
{
    if (titan_dev.hw) {
        titan_gpu_destroy(titan_dev.hw);
        titan_dev.hw = NULL;
    }
    TITAN_LOG("rmmod: titan_x6 module unloaded");
}

int titan_sim_open(void)
{
    if (!titan_dev.hw)
        return EBADF_RET;
    titan_dev.opened = 1;
    return 3;   // a well-behaved fake fd
}

int titan_sim_close(int fd)
{
    (void)fd;
    titan_dev.opened = 0;
    return 0;
}

long titan_sim_ioctl(int fd, unsigned int cmd, void *arg)
{
    if (fd != 3 || !titan_dev.opened)
        return EBADF_RET;
    return titan_ioctl_dispatch(cmd, arg);
}
#endif
