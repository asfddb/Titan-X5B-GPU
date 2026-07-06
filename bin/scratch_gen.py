import json
import struct
import random

def f32_to_hex(f_int):
    return f"0x{f_int:08X}"

def f16_to_hex(f_int):
    return f"0x{f_int:04X}"

fp32_add = []
fp32_mul = []
fp16_mul = []

def add_f32_pair(a, b):
    fp32_add.append([f32_to_hex(a), f32_to_hex(b)])
    fp32_add.append([f32_to_hex(b), f32_to_hex(a)])

def mul_f32_pair(a, b):
    fp32_mul.append([f32_to_hex(a), f32_to_hex(b)])
    fp32_mul.append([f32_to_hex(b), f32_to_hex(a)])

def mul_f16_pair(a, b):
    fp16_mul.append([f16_to_hex(a), f16_to_hex(b)])
    fp16_mul.append([f16_to_hex(b), f16_to_hex(a)])

# NaNs
add_f32_pair(0x7FC00000, 0x3F800000) # qNaN + normal
add_f32_pair(0x7F800001, 0x3F800000) # sNaN + normal
add_f32_pair(0x7FC00000, 0x7F800001) # qNaN + sNaN
add_f32_pair(0x7FC01234, 0x3F800000) # qNaN with payload
mul_f32_pair(0x7FC00000, 0x3F800000)
mul_f32_pair(0x7F800001, 0x3F800000)
mul_f32_pair(0x7FC01234, 0x7F800001)

# Infs
add_f32_pair(0x7F800000, 0xFF800000) # +Inf + -Inf
add_f32_pair(0x7F800000, 0x7F800000) # +Inf + +Inf
add_f32_pair(0xFF800000, 0xFF800000) # -Inf + -Inf
add_f32_pair(0x7F800000, 0x3F800000) # +Inf + normal
add_f32_pair(0xFF800000, 0x3F800000) # -Inf + normal
mul_f32_pair(0x7F800000, 0x00000000) # Inf * 0
mul_f32_pair(0xFF800000, 0x80000000) # -Inf * -0
mul_f32_pair(0x7F800000, 0x7F800000) # Inf * Inf
mul_f32_pair(0x7F800000, 0x3F800000) # Inf * normal

# Zeros
for a in [0x00000000, 0x80000000]:
    for b in [0x00000000, 0x80000000]:
        add_f32_pair(a, b)
        mul_f32_pair(a, b)

# Subnormals
add_f32_pair(0x00000001, 0x00000001) # smallest subnormal
add_f32_pair(0x003FFFFF, 0x003FFFFF) # large subnormal
mul_f32_pair(0x00000001, 0x00000001) # subnormal * subnormal -> 0
mul_f32_pair(0x007FFFFF, 0x007FFFFF) # subnormal * subnormal 
mul_f32_pair(0x4F000000, 0x00000001) # normal * subnormal -> normal

# Cancellation
add_f32_pair(0x3F800000, 0xBF800001) # 1.0 + -1.0000001
add_f32_pair(0x40000000, 0xC0000001)

# Round-to-nearest-even tie cases
# Guard=1, round=sticky=0.
# A tie happens exactly halfway between two representable numbers.
# We can trigger this by adding a number with a 1 bit at the 25th position (shifted out).
# e.g., 1.0 (2^0) + 2^-24. The 2^-24 bit becomes the guard bit.
add_f32_pair(0x3F800000, 0x33000000) # LSB=0 tie
add_f32_pair(0x3F800001, 0x33000000) # LSB=1 tie

# Overflow
add_f32_pair(0x7F7FFFFF, 0x72000000) # exactly rounds up to Inf
mul_f32_pair(0x7F7FFFFF, 0x3F800000) # max finite * 1
mul_f32_pair(0x7F7FFFFF, 0x3F800001) # just above max finite
mul_f32_pair(0x7F7FFFFF, 0x3F7FFFFF) # just below max finite

# Gradual underflow
mul_f32_pair(0x3F800000, 0x00000001) # 1.0 * subnormal
mul_f32_pair(0x3E800000, 0x00800000) # 0.25 * smallest normal -> subnormal

# Alignment shifts
for shift in [0, 1, 23, 24, 25, 60]:
    add_f32_pair(0x3F800000, (127 - shift) << 23)

# Add random padding to reach 300+ pairs
for i in range(100):
    a = random.randint(0, 0xFFFFFFFF)
    b = random.randint(0, 0xFFFFFFFF)
    add_f32_pair(a, b)
    mul_f32_pair(a, b)

# FP16 equivalent
# NaNs
mul_f16_pair(0x7E00, 0x3C00)
mul_f16_pair(0x7E01, 0x3C00)
# Infs
mul_f16_pair(0x7C00, 0x0000)
mul_f16_pair(0xFC00, 0x8000)
mul_f16_pair(0x7C00, 0x7C00)
# Zeros
for a in [0x0000, 0x8000]:
    for b in [0x0000, 0x8000]:
        mul_f16_pair(a, b)
# Subnormals
mul_f16_pair(0x0001, 0x0001)
mul_f16_pair(0x03FF, 0x03FF)
mul_f16_pair(0x5C00, 0x0001)
# Tie
mul_f16_pair(0x3C00, 0x3800)
# Overflow
mul_f16_pair(0x7BFF, 0x3C01)
mul_f16_pair(0x7BFF, 0x3BFF)

for i in range(300):
    a = random.randint(0, 0xFFFF)
    b = random.randint(0, 0xFFFF)
    mul_f16_pair(a, b)

with open("tb/vectors/fp32_vectors.json", "w") as f:
    json.dump({"add": fp32_add, "mul": fp32_mul}, f)

with open("tb/vectors/fp16_vectors.json", "w") as f:
    json.dump({"mul": fp16_mul}, f)

# LSU Patterns
lsu_patterns = []
def add_lsu(addrs):
    lsu_patterns.append({"mask": "0xFFFFFFFF", "addrs": [f"0x{a:08X}" for a in addrs], "write": 0})

# Fully converged
add_lsu([0x1000] * 32)
# Perfectly sequential
add_lsu([0x1000 + i*4 for i in range(32)])
# Stride 2, 4, 8
add_lsu([0x1000 + i*8 for i in range(32)])
add_lsu([0x1000 + i*16 for i in range(32)])
add_lsu([0x1000 + i*32 for i in range(32)])
# Line boundary straddling (16 in N, 16 in N+1)
add_lsu([0x1040 + i*4 for i in range(32)])
# Fully scattered (32 distinct lines)
add_lsu([0x1000 + i*128 for i in range(32)])
# Broadcast with outlier
addrs = [0x1000] * 32
addrs[15] = 0x2000
add_lsu(addrs)
# Reverse order
add_lsu([0x1000 + (31-i)*4 for i in range(32)])

# Add partial masks
for i in range(20):
    addrs = [0x1000 + j*4 for j in range(32)]
    lsu_patterns.append({"mask": "0x00000001", "addrs": [f"0x{a:08X}" for a in addrs], "write": 0})
    lsu_patterns.append({"mask": "0x55555555", "addrs": [f"0x{a:08X}" for a in addrs], "write": 0})
    lsu_patterns.append({"mask": f"0x{random.randint(0, 0xFFFFFFFF):08X}", "addrs": [f"0x{a:08X}" for a in addrs], "write": 0})

# Add random to reach 50+
while len(lsu_patterns) < 60:
    addrs = [random.randint(0, 0x3FFF) * 4 for _ in range(32)]
    lsu_patterns.append({"mask": "0xFFFFFFFF", "addrs": [f"0x{a:08X}" for a in addrs], "write": 0})

with open("tb/vectors/lsu_patterns.json", "w") as f:
    json.dump(lsu_patterns, f)

