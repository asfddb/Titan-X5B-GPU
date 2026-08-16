#!/usr/bin/env python3
# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# ============================================================================
"""Generate titan_blit.tbin - DOOM's palette expansion as a Titan X6 kernel.

DOOM renders into an 8-bit palettised buffer. Turning that into the 32-bit
image a display wants is one palette lookup per pixel, and that is what this
kernel does: 64000 independent lookups, which is exactly the shape a GPU is
for.

The encoding here is written straight from driver/titan_x6_isa.h, which is in
turn the software mirror of rtl/core/titan_x5_decoder.v. No compiler is
involved - this emits the instruction words directly, so the only thing
standing between this file and the RTL's decoder is the bit layout below.

    [31:27] opcode   [26:21] rd   [20:15] rs1   [14:9] rs2   [8:3] rs3
    [2:1] pred       [0] use_imm
    use_imm = 1  ->  [14:3] is a 12-bit zero-extended immediate

Usage:  python3 gen_blit_kernel.py <output.tbin>
"""

import struct
import sys

# --- opcodes (titan_x6_isa.h) ----------------------------------------------
OP_ADD, OP_AND, OP_SHL, OP_SHR = 0, 5, 8, 9
OP_SETP, OP_LOAD, OP_STORE, OP_BRANCH, OP_BARRIER = 21, 22, 23, 24, 25

CMP_GEU = 5
EXIT_IMM = 0xFFF

# --- ABI registers ---------------------------------------------------------
R_PARAM = 1     # kernel parameter block address
R_NTHREADS = 61
R_TID = 62

# --- tbin container --------------------------------------------------------
TBIN_MAGIC = 0x4E494254  # "TBIN"
TBIN_VERSION = 1


def enc_r(op, rd, rs1, rs2=0, rs3=0, pred=0):
    """Register-operand form. Mirrors tx6_enc_r()."""
    return ((op << 27) | ((rd & 63) << 21) | ((rs1 & 63) << 15) |
            ((rs2 & 63) << 9) | ((rs3 & 63) << 3) | ((pred & 3) << 1))


def enc_i(op, rd, rs1, imm12, pred=0):
    """Immediate form. Mirrors tx6_enc_i(). Note bit 0 set."""
    if not 0 <= imm12 <= 0xFFF:
        raise ValueError("immediate %d does not fit in 12 bits" % imm12)
    return ((op << 27) | ((rd & 63) << 21) | ((rs1 & 63) << 15) |
            ((imm12 & 0xFFF) << 3) | ((pred & 3) << 1) | 1)


def setp_rd(cond, pdst):
    """SETP packs {cond[2:0], pdst[1:0]} into the rd field."""
    return ((cond & 7) << 2) | (pdst & 3)


def build():
    """The kernel.

    Parameter block (4 words, address arrives in R1):
        [0] src   8bpp indexed pixels
        [1] dst   32bpp ARGB output
        [2] pal   256 x uint32 palette
        [3] npix  pixel count

    Each thread strides through the image by the launch width, so any thread
    count divides the work evenly with no remainder handling:

        for (i = tid; i < npix; i += nthreads)
            dst[i] = pal[src[i]]

    Reading src[i] is the only awkward part. LOAD and STORE are 32-bit only -
    there is no byte load in the ISA - so a byte is recovered by loading the
    aligned word that contains it and shifting it down. That is the
    LOAD/SHR/AND sequence, and it is deliberately the aligned word rather than
    an unaligned load at src+i: the model's vram_rd32() would happily read four
    bytes past the end of the frame on the last pixel, and staying aligned
    means the kernel never touches memory the frame does not own.

    Registers:
        R2 src   R3 dst   R4 pal   R5 npix   R6 i   R7-R9 scratch   R10 colour
    """
    LOOP = 5  # BRANCH takes an absolute instruction index, so this is a
              # literal PC. It must equal the index of the SETP below.

    code = [
        # --- prologue: unpack the parameter block, seed i = tid -------------
        enc_i(OP_LOAD, 2, R_PARAM, 0),      # 0  R2 = src
        enc_i(OP_LOAD, 3, R_PARAM, 4),      # 1  R3 = dst
        enc_i(OP_LOAD, 4, R_PARAM, 8),      # 2  R4 = pal
        enc_i(OP_LOAD, 5, R_PARAM, 12),     # 3  R5 = npix
        enc_i(OP_ADD, 6, R_TID, 0),         # 4  R6 = tid

        # --- loop head: retire the thread once it runs off the end ---------
        enc_r(OP_SETP, setp_rd(CMP_GEU, 1), 6, 5),          # 5  P1 = i >= npix
        enc_i(OP_BARRIER, 0, 0, EXIT_IMM, pred=1),          # 6  exit if P1

        # --- fetch the palette index: byte i out of the aligned word -------
        enc_i(OP_SHR, 7, 6, 2),             # 7  R7 = i >> 2      (word index)
        enc_i(OP_SHL, 7, 7, 2),             # 8  R7 = R7 << 2     (byte offset)
        enc_r(OP_ADD, 7, 2, 7),             # 9  R7 = src + R7
        enc_i(OP_LOAD, 8, 7, 0),            # 10 R8 = word holding src[i]
        enc_i(OP_AND, 9, 6, 3),             # 11 R9 = i & 3       (byte in word)
        enc_i(OP_SHL, 9, 9, 3),             # 12 R9 = R9 * 8      (bit shift)
        enc_r(OP_SHR, 8, 8, 9),             # 13 R8 >>= R9
        enc_i(OP_AND, 8, 8, 0xFF),          # 14 R8 = palette index

        # --- look the colour up and write it out ---------------------------
        enc_i(OP_SHL, 8, 8, 2),             # 15 R8 = index * 4
        enc_r(OP_ADD, 8, 4, 8),             # 16 R8 = pal + R8
        enc_i(OP_LOAD, 10, 8, 0),           # 17 R10 = ARGB colour
        enc_i(OP_SHL, 9, 6, 2),             # 18 R9 = i * 4
        enc_r(OP_ADD, 9, 3, 9),             # 19 R9 = dst + R9
        enc_i(OP_STORE, 10, 9, 0),          # 20 dst[i] = R10

        # --- next pixel for this thread ------------------------------------
        enc_r(OP_ADD, 6, 6, R_NTHREADS),    # 21 i += nthreads
        enc_i(OP_BRANCH, 0, 0, LOOP),       # 22 back to the loop head
    ]

    # A wrong LOOP constant is silent - the kernel just computes nonsense - so
    # assert the branch target really is the SETP.
    if (code[LOOP] >> 27) != OP_SETP:
        raise AssertionError("LOOP=%d does not point at the SETP" % LOOP)

    return code


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: gen_blit_kernel.py <output.tbin>\n")
        return 2

    code = build()
    with open(sys.argv[1], "wb") as f:
        f.write(struct.pack("<IIII", TBIN_MAGIC, TBIN_VERSION, 0, len(code)))
        f.write(struct.pack("<%dI" % len(code), *code))

    sys.stderr.write("[gen_blit] %s: %d instructions, %d per pixel\n"
                     % (sys.argv[1], len(code), len(code) - 5))
    return 0


if __name__ == "__main__":
    sys.exit(main())
