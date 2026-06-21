# Titan X5-B Microarchitecture Specification (Part 2)

## 1. Graphics Pipeline
The graphics pipeline is structured for standard rasterization:
- **Vertex Shader:** Transforms vertices and calculates lighting.
- **Rasterizer:** Converts primitives to fragments.
- **Fragment Shader:** Colors the fragments.
- **ROP:** Handles depth-testing, blending, and writing to the Framebuffer.

## 2. Memory Hierarchy
- **L1 Cache:** 32KB per SM, 4-way set associative.
- **L2 Cache:** 256KB shared, unifying access before hitting VRAM.
- **VRAM:** Connects to external GDDR/HBM via 512-bit PHY.

## 3. Display Engine
The display engine fetches the rendered framebuffer and outputs it over VGA or HDMI timing standards.
