#ifndef TITAN_X5_DRIVER_H
#define TITAN_X5_DRIVER_H

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

// Memory Map Definitions
#define AXI_BASE_ADDR      0x40000000
#define VRAM_BASE          0x80000000
#define VRAM_SIZE          (1024 * 1024 * 1024) // 1GB
#define CMD_RING_BASE      0x40100000
#define CMD_RING_SIZE      4096 // 4KB ring buffer
#define FRAMEBUFFER_BASE   0x80000000

// Registers
#define REG_GPU_CTRL       (AXI_BASE_ADDR + 0x00)
#define REG_GPU_STATUS     (AXI_BASE_ADDR + 0x04)
#define REG_RING_HEAD      (AXI_BASE_ADDR + 0x08)
#define REG_RING_TAIL      (AXI_BASE_ADDR + 0x0C)

// Command Opcodes
#define CMD_OP_NOP         0x00
#define CMD_OP_SET_STATE   0x01
#define CMD_OP_DRAW        0x02
#define CMD_OP_CLEAR       0x03

// Command packet structure (64-bit)
typedef union {
    uint64_t raw;
    struct {
        uint64_t opcode : 8;
        uint64_t sub_op : 8;
        uint64_t payload : 48;
    } fields;
} titan_x5_cmd_t;

// Context structure
typedef struct {
    volatile uint64_t* ring_buffer;
    uint32_t ring_head;
    uint32_t ring_size;
} titan_x5_device_t;

// Function prototypes
void titan_x5_init(titan_x5_device_t* dev);
void titan_x5_submit_cmd(titan_x5_device_t* dev, uint8_t opcode, uint8_t sub_op, uint64_t payload);
void titan_x5_flush_ring(titan_x5_device_t* dev);
void titan_x5_math_identity_matrix(float matrix[16]);

#endif // TITAN_X5_DRIVER_H
