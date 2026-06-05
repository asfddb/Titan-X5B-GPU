#include "titan_x5_isa.h"
#include <stdint.h>
#include <stdbool.h>

/*
 * Titan X5 GPU Firmware Driver
 * Description: Low-level driver functions to interface with the Titan X5 hardware.
 */

// Abstract MMIO read/write macros for firmware driver
static inline void tx5_reg_write(uint32_t addr, uint32_t data) {
    *((volatile uint32_t*)addr) = data;
}

static inline uint32_t tx5_reg_read(uint32_t addr) {
    return *((volatile uint32_t*)addr);
}

/**
 * Initialize the GPU hardware
 */
void tx5_init_gpu(void) {
    // Reset command processor and wait for ready state
    tx5_reg_write(TX5_CMD_STATUS_REG, 0x0);
    
    // Set power state to normal (e.g., full power state 1)
    tx5_reg_write(TX5_PWR_MGMT_REG, 0x1);
    
    // Initialize SR engine control registers to default
    tx5_reg_write(TX5_SR_CONTROL, TX5_SR_CTRL_OUT_READY);
}

/**
 * Dispatch a warp (batch of instructions) to the Command Processor
 * @param instructions Pointer to instruction stream
 * @param count Number of instructions to dispatch
 * @return true if successfully dispatched, false if busy
 */
bool tx5_dispatch_warp(const uint32_t* instructions, uint32_t count) {
    // Check if CMD processor is ready
    uint32_t status = tx5_reg_read(TX5_CMD_STATUS_REG);
    if ((status & TX5_CMD_STAT_READY) == 0) {
        return false;
    }
    
    // Push instructions into the Command Processor FIFO/Queue
    for (uint32_t i = 0; i < count; i++) {
        tx5_reg_write(TX5_CMD_PROC_REG, instructions[i]);
    }
    
    return true;
}

/**
 * Trigger the Apex SR (Super Resolution) Engine with frame and pixel parameters
 * @param warp_id Associated execution warp ID
 * @param pixel_x Target X coordinate
 * @param pixel_y Target Y coordinate
 * @param motion_x Computed X motion vector
 * @param motion_y Computed Y motion vector
 * @param hash_seed Temporal random seed
 * @param out_tag Output parameter for reprojection tag
 * @param out_confidence Output parameter for temporal confidence level
 * @param out_hit Output parameter indicating a cache hit
 * @return true if successful, false if engine is busy
 */
bool tx5_trigger_sr_engine(uint8_t warp_id, uint16_t pixel_x, uint16_t pixel_y, 
                           int16_t motion_x, int16_t motion_y, uint32_t hash_seed,
                           uint32_t* out_tag, uint16_t* out_confidence, bool* out_hit) {
    
    // Wait for SR Engine ingress to be ready
    if ((tx5_reg_read(TX5_SR_STATUS) & TX5_SR_STAT_IN_READY) == 0) {
        return false; // Could optionally spin-wait here depending on RTOS config
    }
    
    // Write spatial and temporal parameters
    tx5_reg_write(TX5_SR_IN_WARP_ID, (uint32_t)warp_id);
    tx5_reg_write(TX5_SR_IN_PIXEL_X, (uint32_t)pixel_x);
    tx5_reg_write(TX5_SR_IN_PIXEL_Y, (uint32_t)pixel_y);
    tx5_reg_write(TX5_SR_IN_MOTION_X, (uint32_t)motion_x); // Hardware expects 2's complement
    tx5_reg_write(TX5_SR_IN_MOTION_Y, (uint32_t)motion_y);
    tx5_reg_write(TX5_SR_IN_HASH_SEED, hash_seed);
    
    // Trigger computation by asserting IN_VALID
    uint32_t ctrl = tx5_reg_read(TX5_SR_CONTROL);
    tx5_reg_write(TX5_SR_CONTROL, ctrl | TX5_SR_CTRL_IN_VALID);
    
    // Spin wait for OUT_VALID
    // (In a real implementation with an RTOS, this would block or yield)
    while ((tx5_reg_read(TX5_SR_STATUS) & TX5_SR_STAT_OUT_VALID) == 0) {
        __asm__ volatile("nop"); // Prevent compiler from optimizing loop away
    }
    
    // Extract metadata results
    if (out_tag) {
        *out_tag = tx5_reg_read(TX5_SR_OUT_TAG);
    }
    
    if (out_confidence) {
        *out_confidence = (uint16_t)(tx5_reg_read(TX5_SR_OUT_CONFIDENCE) & 0xFFFF);
    }
    
    uint32_t status = tx5_reg_read(TX5_SR_STATUS);
    if (out_hit) {
        *out_hit = (status & TX5_SR_STAT_CACHE_HIT) != 0;
    }
    
    // De-assert IN_VALID trigger
    tx5_reg_write(TX5_SR_CONTROL, ctrl & ~TX5_SR_CTRL_IN_VALID);
    
    return true;
}
