from PIL import Image
import sys

def hex_to_rgba(hex_str):
    if len(hex_str) != 8:
        return (0,0,0,255)
    
    # 0xAABBGGRR in Verilog maybe?
    # Let's check typical RGBA packing
    # Actually wait, the TMU uses fixed color for now: 32'hFFFFFFFF
    r = int(hex_str[6:8], 16)
    g = int(hex_str[4:6], 16)
    b = int(hex_str[2:4], 16)
    a = int(hex_str[0:2], 16)
    return (r, g, b, a)

def main():
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 255))
    pixels = img.load()
    
    with open('fb_dump.txt', 'r') as f:
        lines = f.readlines()
        
    for y in range(64):
        for x in range(64):
            idx = y * 64 + x
            if idx < len(lines):
                hex_str = lines[idx].strip()
                pixels[x, y] = hex_to_rgba(hex_str)
                
    img.save('triangle.png')
    print("Rendered triangle to triangle.png")

if __name__ == '__main__':
    main()
