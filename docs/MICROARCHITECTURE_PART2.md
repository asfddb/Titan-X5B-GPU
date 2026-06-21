# Titan X5-B Microarchitecture Specification (Part 2)

## 1. Graphics & Rasterization Pipeline

The graphics pipeline diverges from a purely traditional shader structure, utilizing fixed-function acceleration for key components.

### 1.1 Vertex Transformer
- Computes matrix-vector multiplications on incoming vertex data using 16-bit signed integer arithmetic.
- Processes 4 vertices simultaneously via a deeply pipelined matrix multiplier.
- Outputs transformed coordinates (X, Y) and Z-depth.

### 1.2 Rasterizer (`titan_x5_rasterizer`)
- Employs an Edge-Function based triangle traversal algorithm.
- Iterates over bounding boxes rather than relying on sequential state machines.
- Outputs fragment coordinates and barycentric weights per pixel.

### 1.3 Render Output Unit (`titan_x5_rop`)
- Features 4 parallel ROP units.
- **Z-Buffer / Depth Test:** Reads the existing Z value from an internal tile SRAM. If the incoming fragment Z is closer, it writes the new pixel and updates the Z-buffer.
- **Alpha Blending:** Multiplies source color and destination color by the fragment's alpha channel to perform translucent rendering in real-time.
- **Tile SRAM:** Caches depth and color data to minimize memory bandwidth over the AXI crossbar.

## 2. Ray Tracing Core (`titan_x5_rt_core`)

Hardware-accelerated ray tracing calculates ray-triangle intersections natively in silicon.
- **Möller-Trumbore Algorithm:** Implemented iteratively.
- **Iterative Divider:** Avoids combinational single-cycle division explosions. It uses a 32-stage non-restoring division state machine to calculate the inverse determinant ($1/det$) and intersection parameters ($U$, $V$, $T$).
- Features internal state handling for Ray Generation, Traversal, Intersection, and Shading.

## 3. Display Engine (`titan_x5_display_engine`)

The display unit acts as a dedicated AXI Master to stream the rendered framebuffer to the physical pins.
- **Timing Generator:** Standard VGA timing (HSYNC, VSYNC, blanking intervals) configurable via parameters.
- **Asynchronous Output FIFO:** Buffers incoming AXI read bursts. It implements stalling mechanisms via `vga_de` (Data Enable) to ensure underflow does not deadlock the state machine if memory latency spikes.

## 4. Command Processor (`titan_x5_command_processor`)

The heart of the GPU control flow.
- Fetches 64-bit command packets from a host-written ring buffer.
- Evaluates the Ring Buffer Read/Write Pointers to detect new commands, handling circular wrap-around seamlessly.
- Decodes commands (e.g. `CMD_DRAW`, `CMD_CLEAR`, `CMD_DISPATCH`) and routes the payload to the specific fixed-function engines (Rasterizer, TMU, SM, RT Core).
