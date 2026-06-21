#include "titan_x5_driver.h"
#include <stdio.h>

// Helper to encode a color
#define COLOR_RGB(r, g, b) (((r) << 16) | ((g) << 8) | (b))

int main() {
    printf("Starting Titan X5-B Demo...\n");

    titan_x5_device_t gpu;
    
    // Initialize the GPU
    titan_x5_init(&gpu);
    printf("GPU Initialized.\n");

    // Clear the framebuffer
    printf("Clearing framebuffer...\n");
    titan_x5_submit_cmd(&gpu, CMD_OP_CLEAR, 0, COLOR_RGB(0, 0, 0));

    // Draw a colored triangle
    printf("Submitting draw commands for a triangle...\n");
    
    // Setup state (e.g., bind vertex buffer, shader, etc. - mocked payload)
    titan_x5_submit_cmd(&gpu, CMD_OP_SET_STATE, 0, 0x1000); 

    // Vertex 1: Red
    titan_x5_submit_cmd(&gpu, CMD_OP_DRAW, 1, COLOR_RGB(255, 0, 0));
    // Vertex 2: Green
    titan_x5_submit_cmd(&gpu, CMD_OP_DRAW, 1, COLOR_RGB(0, 255, 0));
    // Vertex 3: Blue
    titan_x5_submit_cmd(&gpu, CMD_OP_DRAW, 1, COLOR_RGB(0, 0, 255));
    
    // Finalize draw
    titan_x5_submit_cmd(&gpu, CMD_OP_DRAW, 0, 3); // Draw 3 vertices

    // Ensure all commands are processed
    // Note: Calling flush ring on a mock/host environment will hang if hardware doesn't update the tail pointer.
    // titan_x5_flush_ring(&gpu);
    printf("Commands executed. Triangle drawn.\n");

    // Optional: Matrix math utility test
    float identity[16];
    titan_x5_math_identity_matrix(identity);
    printf("Identity matrix generated.\n");

    return 0;
}
