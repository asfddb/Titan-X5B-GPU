#include "titan_x5_driver.h"

// Memory mapped register access macros
#define READ_REG(addr) (*(volatile uint32_t*)(size_t)(addr))
#define WRITE_REG(addr, val) (*(volatile uint32_t*)(size_t)(addr) = (val))

void titan_x5_init(titan_x5_device_t* dev) {
    // Reset GPU
    WRITE_REG(REG_GPU_CTRL, 0x0);
    
    // Initialize ring buffer context
    dev->ring_buffer = (volatile uint64_t*)(size_t)CMD_RING_BASE;
    dev->ring_size = CMD_RING_SIZE / sizeof(uint64_t);
    dev->ring_head = 0;
    
    // Set ring buffer registers
    WRITE_REG(REG_RING_HEAD, 0);
    WRITE_REG(REG_RING_TAIL, 0);
    
    // Enable GPU
    WRITE_REG(REG_GPU_CTRL, 0x1);
}

void titan_x5_submit_cmd(titan_x5_device_t* dev, uint8_t opcode, uint8_t sub_op, uint64_t payload) {
    titan_x5_cmd_t cmd;
    cmd.fields.opcode = opcode;
    cmd.fields.sub_op = sub_op;
    cmd.fields.payload = payload;
    
    // Write command to ring buffer
    dev->ring_buffer[dev->ring_head] = cmd.raw;
    
    // Advance head with wrap-around
    dev->ring_head = (dev->ring_head + 1) % dev->ring_size;
    
    // Update hardware register
    WRITE_REG(REG_RING_HEAD, dev->ring_head);
}

void titan_x5_flush_ring(titan_x5_device_t* dev) {
    // Wait for GPU to process all commands (head == tail)
    while (READ_REG(REG_RING_TAIL) != dev->ring_head) {
        // Busy wait
    }
}

void titan_x5_math_identity_matrix(float matrix[16]) {
    for (int i = 0; i < 16; i++) {
        matrix[i] = (i % 5 == 0) ? 1.0f : 0.0f;
    }
}
