import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotbext.axi import AxiRam, AxiBus
from PIL import Image
import os

@cocotb.test()
async def test_system_vga_reconstruction(dut):
    """
    System-Level Functional Test:
    1. Initializes an AXI RAM model attached to the GPU's VRAM pins.
    2. Injects a command stream into VRAM (draw a triangle).
    3. Runs the Command Processor to dispatch it to the graphics pipeline.
    4. ROP renders the triangle to VRAM.
    5. Display Engine fetches the framebuffer via AXI and outputs to VGA pins.
    6. Reconstructs the actual VGA stream into an image.
    """
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.host_ring_base.value = 0x1000_0000
    dut.host_ring_wptr.value = 0
    
    await Timer(50, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Initialize AxiRam after reset so DUT outputs aren't 'X'
    axi_bus = AxiBus.from_prefix(dut, "vram")
    ram = AxiRam(axi_bus, dut.clk, dut.rst_n, size=2**29) # 512MB RAM
    await RisingEdge(dut.clk)
    
    # Fill texture memory at address 0x0 so TMU reads white pixels
    # The TMU reads from base 0x0, we fill 64KB with white
    ram.write(0x0, b'\xFF' * 65536)
    
    # CMD_DRAW = 0x01. Total command size = 17 words (68 bytes)
    # Word 0: Opcode (0x01)
    # Words 1-8: 4x4 Weight Matrix (16 * 16-bit = 256 bits = 32 bytes)
    # Words 9-16: 4x4 Vertices Matrix (16 * 16-bit = 256 bits = 32 bytes)
    cmd_data_fixed = bytearray(68)
    cmd_data_fixed[0] = 0x01 # Opcode
    
    # Fill Weights with Identity Matrix scaled by 1 to pass through
    # Matrix is packed as [r][c], row-major.
    # We want W = I.
    for i in range(4):
        offset = 4 + (i*4 + i)*2 # Word 0 is 4 bytes. Then offset into 32 byte block.
        cmd_data_fixed[offset:offset+2] = (1).to_bytes(2, 'little', signed=True) # Identity
    
    # Vertices (4x4 Matrix). v0, v1, v2, v3
    # v0 = (0, 0, 0, 1)
    # v1 = (20, 0, 0, 1)
    # v2 = (5, 5, 0, 1)
    # v3 = (0, 0, 0, 1)
    v_base = 4 + 32
    
    # v0
    cmd_data_fixed[v_base+0:v_base+2] = (0).to_bytes(2, 'little', signed=True)
    cmd_data_fixed[v_base+2:v_base+4] = (0).to_bytes(2, 'little', signed=True)
    cmd_data_fixed[v_base+6:v_base+8] = (1).to_bytes(2, 'little', signed=True) # W
    # v1
    cmd_data_fixed[v_base+8:v_base+10] = (20).to_bytes(2, 'little', signed=True)
    cmd_data_fixed[v_base+10:v_base+12] = (0).to_bytes(2, 'little', signed=True)
    cmd_data_fixed[v_base+14:v_base+16] = (1).to_bytes(2, 'little', signed=True) # W
    # v2
    cmd_data_fixed[v_base+16:v_base+18] = (5).to_bytes(2, 'little', signed=True)
    cmd_data_fixed[v_base+18:v_base+20] = (5).to_bytes(2, 'little', signed=True)
    cmd_data_fixed[v_base+22:v_base+24] = (1).to_bytes(2, 'little', signed=True) # W
    # v3
    cmd_data_fixed[v_base+30:v_base+32] = (1).to_bytes(2, 'little', signed=True) # W
    
    ram.write(0x1000_0000, cmd_data_fixed)
    dut.host_ring_wptr.value = 17
    
    dut._log.info("Injected Command: DRAW Triangle through Vertex Transformer")
    
    vga_pixels = []
    
    # The VGA resolution is configured to 32x32 in parameter
    H_VISIBLE = 32
    V_VISIBLE = 32
    
    dut._log.info(f"Simulating {H_VISIBLE}x{V_VISIBLE} VGA Output. Reconstructing image...")
    
    # Wait for vga_vsync to go high, then capture one full frame
    frames_captured = 0
    in_vsync = False
    in_frame = False
    
    # We will run for a max of 20000 cycles to capture the frame
    # since 32x32 = 1024 pixels + porches = ~1500 cycles per frame
    
    timeout_cycles = 25000
    cycles = 0
    
    while cycles < timeout_cycles:
        await RisingEdge(dut.clk)
        cycles += 1
        
        # Poll graphics pipeline for debugging
        try:
            cmd_valid = int(dut.u_cmd_processor.cmd_valid.value) if dut.u_cmd_processor.cmd_valid.value.is_resolvable else 0
            rast_valid = int(dut.u_rasterizer.valid_out.value) if dut.u_rasterizer.valid_out.value.is_resolvable else 0
            rop_req = int(dut.rop_gen[0].u_rop.mem_req.value) if dut.rop_gen[0].u_rop.mem_req.value.is_resolvable else 0
            if cmd_valid:
                dut._log.info(f"Cmd Processor Valid!")
            if rast_valid:
                dut._log.info(f"Rasterizer Valid! X: {dut.u_rasterizer.x_out.value}, Y: {dut.u_rasterizer.y_out.value}")
            if rop_req:
                dut._log.info(f"ROP Mem Req! Addr: {dut.rop_gen[0].u_rop.mem_addr.value}")
        except Exception as e:
            # dut._log.info(f"Debug Error: {e}")
            pass
            
        vsync = int(dut.vga_vsync.value)
        de = int(dut.vga_de.value)
        
        if frames_captured == 2 and de == 1:
            r = int(dut.vga_r.value)
            g = int(dut.vga_g.value)
            b = int(dut.vga_b.value)
            vga_pixels.append((r, g, b))
        
        if vsync == 1:
            if not in_vsync:
                in_vsync = True
                frames_captured += 1
                if frames_captured > 2:
                    break # Wait for 2 frames so GPU has time to draw
                in_frame = True
        else:
            in_vsync = False
            
            
    assert len(vga_pixels) == H_VISIBLE * V_VISIBLE, f"Expected {H_VISIBLE*V_VISIBLE} pixels in frame, got {len(vga_pixels)}"
    
    # Reconstruct Image
    img = Image.new("RGB", (H_VISIBLE, V_VISIBLE), "black")
    img_pixels = img.load()
    
    rendered_pixels = 0
    for i, (r, g, b) in enumerate(vga_pixels):
        px = i % H_VISIBLE
        py = i // H_VISIBLE
        img_pixels[px, py] = (r, g, b)
        # Check if the pixel has changed from the initial default white background
        if r != 255 or g != 255 or b != 255:
            rendered_pixels += 1
            
    assert rendered_pixels > 0, "Image is completely blank background! GPU failed to render the triangle (no pixels changed from default background)."
    
    img_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "system_vga_reconstruction.png"))
    img.save(img_path)
    
    dut._log.info("VGA Output:")
    white_pixels = 0
    black_pixels = 0
    
    with open('triangle.txt', 'w') as f:
        for y in range(H_VISIBLE):
            row_str = ""
            for x in range(V_VISIBLE):
                idx = y * H_VISIBLE + x
                if idx < len(vga_pixels):
                    p = vga_pixels[idx]
                    if p[0] < 128:
                        row_str += "X"
                        black_pixels += 1
                    else:
                        row_str += "."
                        white_pixels += 1
                else:
                    row_str += "?"
            dut._log.info(f"Row {y:2}: {row_str}")
            f.write(row_str + '\n')
            
    dut._log.info(f"Total Black Pixels: {black_pixels}")
    dut._log.info(f"Total White Pixels: {white_pixels}")

    dut._log.info(f"Saved Reconstructed VGA Stream Image to {img_path}")
    dut._log.info(f"Test Passed: Rendered {rendered_pixels} pixels to actual VGA hardware pins!")
    
    # Dump RAM contents
    ram_data = ram.read(0x0, 4096)
    dump_path = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs", "assets", "ram_dump.bin"))
    with open(dump_path, "wb") as f:
        f.write(ram_data)
    dut._log.info(f"Dumped RAM to {dump_path}")
