# Titan X5 Vulkan ICD Wrapper Structure

The Vulkan Installable Client Driver (ICD) wrapper for the Titan X5 is designed to intercept, route, and optimize Vulkan API calls tailored specifically for the architecture of the Titan X5 GPU. It sits between the Vulkan loader and the underlying Titan X5 hardware/kernel driver.

## 1. Directory Structure

```text
titan_x5_icd/
├── include/
│   ├── vk_icd.h                 # Standard Vulkan ICD header
│   └── titan_x5_backend.h       # Titan X5 specific structures and definitions
├── src/
│   ├── icd_dispatch.c           # Dispatch table initialization
│   ├── icd_entrypoints.c        # Implementation of vk_icdGetInstanceProcAddr, etc.
│   ├── device.c                 # VkDevice and VkPhysicalDevice management
│   ├── memory.c                 # VRAM and GART memory allocation (Titan X5 specific)
│   ├── pipeline.c               # Shader compilation and pipeline state caching
│   ├── command_buffer.c         # Command buffer recording and submission
│   └── queue.c                  # Queue submission and synchronization
├── json/
│   └── titan_x5_icd.json        # ICD manifest file for the Vulkan loader
├── CMakeLists.txt
└── README.md
```

## 2. Core Components

### 2.1 ICD Manifest (`titan_x5_icd.json`)
This file is required by the Vulkan loader to discover the ICD.
```json
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "./libtitan_x5_vulkan.so",
        "api_version": "1.3.250"
    }
}
```

### 2.2 Entry Points (`icd_entrypoints.c`)
The ICD must expose at least three core functions exported to the Vulkan loader:
- `vk_icdGetInstanceProcAddr`: The primary function to retrieve Vulkan instance-level commands.
- `vk_icdGetPhysicalDeviceProcAddr`: (Optional but recommended) Retrieve physical device commands.
- `vk_icdNegotiateLoaderICDInterfaceVersion`: Negotiates the interface version between the loader and the ICD.

### 2.3 Dispatch Tables (`icd_dispatch.c`)
Vulkan uses a dispatch mechanism. The ICD must populate a dispatch table (`VkLayerInstanceDispatchTable`, `VkLayerDispatchTable` equivalent or internal dispatch mechanism) containing function pointers to the Titan X5 specific implementations of Vulkan API calls.

- **Instance Dispatch Table**: Contains functions like `vkCreateInstance`, `vkEnumeratePhysicalDevices`, `vkDestroyInstance`.
- **Device Dispatch Table**: Contains functions like `vkCreateDevice`, `vkAllocateMemory`, `vkQueueSubmit`, `vkCmdDraw`.

### 2.4 Device Management (`device.c`)
Handles the enumeration of the Titan X5 hardware.
- `vkEnumeratePhysicalDevices`: Interacts with the OS/kernel to detect the Titan X5 and returns a `VkPhysicalDevice` handle.
- `vkGetPhysicalDeviceProperties`: Returns Titan X5 specific properties (vendor ID, device ID, API version supported, limits).
- `vkCreateDevice`: Initializes the logical device, setting up queues and enabling specific Titan X5 extensions.

### 2.5 Memory Management (`memory.c`)
Titan X5 specific memory allocators.
- Translates `vkAllocateMemory` into Titan X5 kernel driver allocation requests.
- Manages memory types (e.g., Device Local, Host Visible, Host Coherent).
- Implements custom sub-allocation or pooling if the Titan X5 architecture benefits from it.

### 2.6 Command Buffer and Queues (`command_buffer.c`, `queue.c`)
- **Command Buffers**: Translates Vulkan commands (`vkCmd*`) into Titan X5 specific hardware command packets (e.g., Ring Buffer commands, PM4 packets for AMD, or equivalent for Titan X5).
- **Queues**: Manages submission of command buffers to the hardware queues (`vkQueueSubmit`) and handles synchronization primitives (fences, semaphores).

### 2.7 Pipeline and Shaders (`pipeline.c`)
- Translates SPIR-V shaders into Titan X5 machine code.
- Manages pipeline state objects (PSOs), translating Vulkan state descriptions into hardware registers.

## 3. Workflow of a Vulkan Call

1. **Application Call**: The application calls a Vulkan function (e.g., `vkCmdDraw`).
2. **Vulkan Loader**: The loader looks up the function pointer in the device dispatch table and jumps to the ICD's implementation.
3. **ICD Wrapper**: The Titan X5 ICD intercepts the call (`titan_x5_vkCmdDraw`).
4. **Translation**: The ICD converts the Vulkan draw parameters into the specific command packet format required by the Titan X5 hardware.
5. **Command Recording**: The ICD writes the translated packet into the current command buffer's memory.
6. **Execution**: Later, upon `vkQueueSubmit`, the ICD flushes the command buffer to the Titan X5 hardware ring buffer via an ioctl/kernel call.
