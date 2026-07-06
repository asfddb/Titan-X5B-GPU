from PIL import Image
import os

print("Rendering Framebuffer to PNG...")

try:
    with open('fb_dump.txt', 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
except Exception as e:
    print("Error reading fb_dump.txt:", e)
    exit(1)

W, H = 64, 64
img = Image.new('RGB', (W, H), color='black')
pixels = img.load()

rendered_pixels = 0

for y in range(H):
    for x in range(W):
        idx = y * W + x
        if idx < len(lines):
            hex_str = lines[idx]
            try:
                val = int(hex_str, 16)
                if val != 0:
                    pixels[x, y] = (255, 136, 0) # Titan Orange
                    rendered_pixels += 1
            except:
                pass

print(f"Found {rendered_pixels} rendered pixels in VRAM.")

# Upscale x8 for better visibility
img = img.resize((512, 512), Image.NEAREST)
img.save('rendered_triangle.png')

print("Saved output to rendered_triangle.png")
