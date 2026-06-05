# Titan X5 GPU Software Development Kit (SDK) Programming Guide

## 1. Architecture Overview
The Titan X5 GPU is a high-performance graphics processor designed for next-generation rendering workloads. The architecture consists of several key components:
- **Command Processor**: Interfaces with the host over an abstracted PCIe bus to receive rendering commands.
- **4x Streaming Multiprocessors (SMs)**: Handle programmable shader execution.
- **Rasterizer, TMUs (Texture Mapping Units), and ROPs (Render Output Units)**: The core graphics pipeline.
- **Ray Tracing Core**: Accelerates ray-bounding box and ray-triangle intersections.
- **Apex Super Resolution (SR) Engine**: A hardware-accelerated temporal reprojection cache designed to vastly improve frame rates.
- **Memory Hierarchy**: Includes a centralized Crossbar, L2 Cache, and a high-bandwidth Memory Controller interfacing with VRAM.

## 2. The Apex Super Resolution (SR) Engine
The standout feature of the Titan X5 is the **Apex SR Engine** (`titan_x5_apex_sr_engine.v`). It implements a direct-mapped Temporal Reprojection Cache (TRC) in hardware. 

Instead of conventionally shading every pixel every frame, the SR Engine relies on temporal coherence. By feeding the engine with pixel coordinates and their corresponding **Motion Vectors (MVs)**, the hardware computes an FNV-1a hash to look up previously shaded pixels. 

### How it works:
1. **Ingress**: The engine takes in the `pixel_x`, `pixel_y`, `motion_x`, `motion_y`, `warp_id`, and a unique `frame_hash_seed`.
2. **Hash & Confidence Computation**: The hardware quickly hashes these inputs and calculates a **confidence score**. High motion yields lower confidence (`confidence = 16'hFFFF - abs(motion_x) - abs(motion_y)`).
3. **Cache Match**: If the cache hits and confidence is high, the pipeline skips expensive fragment shading for that pixel, fetching the result from the reprojection cache instead.

## 3. Leveraging the Temporal SR Cache to Maximize Framerate
To maximize framerate, your software renderer must be built to feed high-quality data to the SR Engine. 

### Best Practices:
- **Provide Accurate Motion Vectors**: Every vertex and fragment shader should output accurate screen-space motion vectors. The hardware relies entirely on `motion_x` and `motion_y` to reproject pixels from the previous frame. 
- **Manage the Frame Hash Seed**: Supply a sequentially changing or randomly generated `frame_hash_seed` per frame to ensure cache eviction works correctly and to avoid temporal ghosting.
- **Optimize for High Confidence**: Since the hardware calculates confidence inversely to motion magnitude, minimize camera jitter to keep global motion vectors small. Smaller motion vectors mean higher confidence, leading to more cache hits and a dramatic increase in FPS.

## 4. C/C++ Programming Examples

Below is a conceptual C++ SDK example demonstrating how to interface with the Titan X5 Command Processor to leverage the SR Engine.

### Setting up the Host Interface
Communication with the Titan X5 is done via memory-mapped I/O (MMIO) to the Command Processor.

```cpp
#include <stdint.h>
#include <stdio.h>

// MMIO Base Address for Titan X5 Command Processor (Platform specific)
#define TITAN_X5_MMIO_BASE 0x40000000

// Command Opcodes
#define CMD_SET_FRAME_SEED 0x01
#define CMD_DRAW_PRIMITIVE 0x02
#define CMD_BIND_SHADER    0x03

// Register Map structure mapped to MMIO base
typedef volatile struct {
    uint32_t host_addr;
    uint32_t host_wdata;
    uint32_t host_we;
    uint32_t host_re;
    uint32_t host_rdata;
    uint32_t host_ready;
} TitanX5_Regs;

TitanX5_Regs* const gpu = (TitanX5_Regs*)TITAN_X5_MMIO_BASE;

void write_gpu_cmd(uint32_t addr, uint32_t data) {
    while (!gpu->host_ready) {
        // Busy-wait for GPU to be ready to accept a command
    }
    gpu->host_addr = addr;
    gpu->host_wdata = data;
    gpu->host_we = 1;
    gpu->host_we = 0; // Strobe write enable
}
```

### Feeding the SR Engine
To take advantage of the Temporal SR Cache, you must update the frame seed at the start of every frame and ensure your geometry passes down motion vectors.

```cpp
#include <stdlib.h>

void begin_frame(uint32_t frame_number) {
    // Generate a unique seed for the temporal hash
    uint32_t frame_hash_seed = frame_number ^ 0xDEADBEEF; 
    
    // Send seed to GPU command processor
    // (Assuming address 0x10 maps to the SR Engine Seed Register internally)
    write_gpu_cmd(0x10, frame_hash_seed);
}

// Conceptual vertex structure that MUST include motion vectors
struct Vertex {
    float x, y, z;
    float u, v;
    int16_t motion_x; // Screen-space motion X
    int16_t motion_y; // Screen-space motion Y
};

void draw_geometry(Vertex* vertices, size_t count) {
    // In a real scenario, you would DMA this buffer to VRAM.
    // Here we represent binding the buffer and issuing a draw call.
    
    // Issue Draw Command
    // The vertex shader running on the SMs will pass motion_x and motion_y
    // down to the Rasterizer, which forwards them to the SR Engine.
    write_gpu_cmd(CMD_DRAW_PRIMITIVE, count);
}

int main() {
    uint32_t frame_count = 0;
    
    while (true) {
        begin_frame(frame_count);
        
        // Render scene...
        // draw_geometry(scene_vertices, num_vertices);
        
        frame_count++;
    }
    return 0;
}
```

### Shader Level (Conceptual)
In your programmable shader (running on the SMs), you must output the motion vector to the pipeline:

```glsl
// Conceptual Shader Code
out vec2 out_motion_vector;

void main() {
    vec4 current_pos = MVP * vec4(position, 1.0);
    vec4 previous_pos = prev_MVP * vec4(position, 1.0);
    
    // Compute screen space motion
    vec2 motion = (current_pos.xy / current_pos.w) - (previous_pos.xy / previous_pos.w);
    
    // Scale to pixel space motion (e.g., 1920x1080)
    out_motion_vector = motion * vec2(1920.0, 1080.0);
    
    gl_Position = current_pos;
}
```

By ensuring your engine calculates and provides accurate `out_motion_vector` data, the Titan X5 Apex SR Engine will transparently cache and reproject pixels, vastly accelerating your framerate without additional compute overhead.
