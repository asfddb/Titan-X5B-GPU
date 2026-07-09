#!/usr/bin/env python3
# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Mission 2 TDD checkpoint: assert the Titan Compute Compiler emits ISA bytes
that mathematically match the driver/titan_x6_isa.h spec (which itself mirrors
rtl/core/titan_x5_decoder.v).

Three layers:
  1. Encoding: recompute the 32-bit field layout independently from the spec
     comment (op[31:27] rd[26:21] rs1[20:15] rs2[14:9] rs3[8:3] pred[2:1]
     use_imm[0]) and assert the compiler's enc_r/enc_i produce exactly that.
  2. Spec sync: parse titan_x6_isa.h and assert every opcode value, ABI
     register, EXIT/WMMA/TBIN constant equals the compiler's copy -- this is
     the software<->hardware contract the whole stack depends on.
  3. Real kernels: compile the canonical matmul and assert structural + exact
     byte properties (valid opcodes, EXIT terminator, WMMA mode flag, TBIN
     container header).

Run:  python3 test_compiler_isa.py   (exit 0 iff all checks pass)
"""

import os
import re
import struct
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import titan_compiler as tc  # noqa: E402

HERE = os.path.dirname(os.path.abspath(__file__))
ISA_H = os.path.join(HERE, "..", "driver", "titan_x6_isa.h")
KERNEL = os.path.join(HERE, "kernels", "matmul.py")

_checks = 0
_failures = 0


def check(cond, msg):
    global _checks, _failures
    _checks += 1
    if cond:
        print(f"  [PASS] {msg}")
    else:
        print(f"  [FAIL] {msg}")
        _failures += 1


# ---------------------------------------------------------------------------
# Independent reference encoder straight from the titan_x6_isa.h bit spec.
# Deliberately NOT calling tc.enc_* so a matching result cross-validates them.
# ---------------------------------------------------------------------------
def spec_enc_r(op, rd, rs1, rs2, rs3, pred):
    return (((op & 0x1F) << 27) | ((rd & 0x3F) << 21) | ((rs1 & 0x3F) << 15) |
            ((rs2 & 0x3F) << 9) | ((rs3 & 0x3F) << 3) | ((pred & 0x3) << 1))


def spec_enc_i(op, rd, rs1, imm, pred):
    return (((op & 0x1F) << 27) | ((rd & 0x3F) << 21) | ((rs1 & 0x3F) << 15) |
            ((imm & 0xFFF) << 3) | ((pred & 0x3) << 1) | 1)


def test_encoding():
    print("[1] instruction encoding matches the bit-field spec")
    # A spread of operands incl. boundary (63/62) and overflow (>63 must mask).
    vectors = [
        (tc.OPS["ADD"], 5, 2, 3, 0, 0),
        (tc.OPS["FMA"], 63, 62, 61, 60, 3),
        (tc.OPS["WMMA"], 40, 41, 42, 1, 0),
        (tc.OPS["STORE"], 0, 33, 34, 0, 2),
        (tc.OPS["ATOM_CAS"], 64, 65, 66, 67, 4),   # overflow -> masked
    ]
    ok = True
    for op, rd, rs1, rs2, rs3, pred in vectors:
        got = tc.enc_r(op, rd, rs1, rs2, rs3, pred)
        exp = spec_enc_r(op, rd, rs1, rs2, rs3, pred)
        if got != exp:
            ok = False
            print(f"      enc_r{(op, rd, rs1, rs2, rs3, pred)} = {got:#010x} "
                  f"!= spec {exp:#010x}")
        if got & 1:
            ok = False
            print(f"      enc_r has use_imm bit set: {got:#010x}")
    check(ok, "enc_r reg-form encoding == spec (fields, masking, use_imm=0)")

    ok = True
    for op, rd, rs1, imm, pred in [
        (tc.OPS["ADD"], 7, 1, 0, 0),
        (tc.OPS["LOAD"], 2, 1, 4, 0),
        (tc.OPS["BRANCH"], 0, 0, 0xFFF, 1),
        (tc.OPS["BARRIER"], 0, 0, tc.EXIT_IMM, 0),
    ]:
        got = tc.enc_i(op, rd, rs1, imm, pred)
        exp = spec_enc_i(op, rd, rs1, imm, pred)
        if got != exp:
            ok = False
            print(f"      enc_i{(op, rd, rs1, imm, pred)} = {got:#010x} "
                  f"!= spec {exp:#010x}")
        if not (got & 1):
            ok = False
            print(f"      enc_i missing use_imm bit: {got:#010x}")
    check(ok, "enc_i imm-form encoding == spec (imm12 field, use_imm=1)")

    # Human-checkable golden values.
    check(tc.enc_r(tc.OPS["ADD"], 5, 2, 3) == 0x00A10600,
          "golden: ADD r5, r2, r3 == 0x00A10600")
    check(tc.enc_i(tc.OPS["BARRIER"], 0, 0, tc.EXIT_IMM) == 0xC8007FF9,
          "golden: EXIT (BARRIER #0xFFF) == 0xC8007FF9")

    # Field boundaries must not overlap: encode distinct max fields, decode back.
    w = spec_enc_r(tc.OPS["FMA"], 63, 62, 61, 60, 3)
    fields = ((w >> 27) & 0x1F, (w >> 21) & 0x3F, (w >> 15) & 0x3F,
              (w >> 9) & 0x3F, (w >> 3) & 0x3F, (w >> 1) & 0x3)
    check(fields == (tc.OPS["FMA"], 63, 62, 61, 60, 3),
          "field boundaries are disjoint (encode/decode round-trip)")


def _parse_isa_header():
    with open(ISA_H, "r", encoding="utf-8") as f:
        text = f.read()
    ops = {m.group(1): int(m.group(2))
           for m in re.finditer(r"TX6_OP_(\w+)\s*=\s*(\d+)", text)}
    defs = {}
    for m in re.finditer(r"#define\s+TX6_(\w+)\s+(0x[0-9A-Fa-f]+u?|\d+u?)", text):
        defs[m.group(1)] = int(m.group(2).rstrip("uU"), 0)
    return ops, defs


def test_spec_sync():
    print("[2] compiler constants stay in sync with titan_x6_isa.h")
    ops, defs = _parse_isa_header()

    check(len(ops) == 32, f"header defines all 32 opcodes (found {len(ops)})")
    check(set(ops) == set(tc.OPS),
          "opcode name sets match between header and compiler")
    check(all(tc.OPS.get(n) == v for n, v in ops.items()),
          "every opcode numeric value matches the header")

    reg_map = {
        "REG_ZERO": tc.R_ZERO, "REG_PARAM": tc.R_PARAM,
        "REG_LDA": tc.R_LDA, "REG_LDB": tc.R_LDB, "REG_LDC": tc.R_LDC,
        "REG_NTHREADS": tc.R_NTHREADS, "REG_TID": tc.R_TID,
    }
    check(all(defs.get(k) == v for k, v in reg_map.items()),
          "ABI register numbers match the header")

    check(defs.get("EXIT_IMM") == tc.EXIT_IMM, "EXIT_IMM matches (0xFFF)")
    check(defs.get("WMMA_FLAG_FP8") == tc.WMMA_FLAG_FP8, "WMMA FP8 flag matches")
    check(defs.get("WMMA_M") == tc.WMMA_TILE and defs.get("WMMA_K") == tc.WMMA_TILE,
          "WMMA tile size matches (16)")
    check(defs.get("TBIN_MAGIC") == tc.TBIN_MAGIC, "TBIN magic matches")
    check(defs.get("TBIN_VERSION") == tc.TBIN_VERSION, "TBIN version matches")


def _compile(backend, dtype=None):
    with open(KERNEL, "r", encoding="utf-8") as f:
        src = f.read()
    fn = tc.parse_kernel(src)
    if backend == "scalar":
        return tc.ScalarCodegen(fn).compile()
    return tc.compile_tensor(fn, dtype)


def test_kernels():
    print("[3] compiled matmul kernels match the ISA")
    scalar = _compile("scalar")
    i8 = _compile("tensor", "int8")
    fp8 = _compile("tensor", "fp8")

    for name, words in (("scalar", scalar), ("int8", i8), ("fp8", fp8)):
        check(all(((w >> 27) & 0x1F) in tc.OP_NAMES for w in words),
              f"{name}: every word decodes to a defined opcode")
        check(words[-1] == 0xC8007FF9,
              f"{name}: kernel terminates with EXIT (BARRIER #0xFFF)")

    def wmma_words(words):
        return [w for w in words if ((w >> 27) & 0x1F) == tc.OPS["WMMA"]]

    check(len(wmma_words(scalar)) == 0,
          "scalar backend emits no WMMA (pure SM pipeline)")
    check(len(wmma_words(i8)) == 1 and len(wmma_words(fp8)) == 1,
          "tensor backend emits exactly one WMMA tile op")

    # WMMA rs3 mode flag: bit0 == 1 for FP8, == 0 for INT8.
    check((wmma_words(i8)[0] >> 3) & 1 == 0, "INT8 WMMA clears the FP8 flag")
    check((wmma_words(fp8)[0] >> 3) & 1 == 1, "FP8 WMMA sets the FP8 flag")

    # TBIN container header must match the tx6_tbin_header_t C struct.
    for name, words, tensor in (("scalar", scalar, False), ("fp8", fp8, True)):
        with tempfile.NamedTemporaryFile(suffix=".tbin", delete=False) as tf:
            path = tf.name
        try:
            tc.write_tbin(path, words, tensor=tensor)
            with open(path, "rb") as f:
                magic, version, flags, nwords = struct.unpack("<IIII", f.read(16))
            check(magic == tc.TBIN_MAGIC and version == tc.TBIN_VERSION,
                  f"{name}: TBIN magic/version correct")
            check(nwords == len(words), f"{name}: TBIN num_words == instruction count")
            check((flags & 1) == (1 if tensor else 0),
                  f"{name}: TBIN tensor flag reflects the backend")
        finally:
            os.unlink(path)


def main():
    print("== Titan Compute Compiler: ISA encoding unit tests ==")
    test_encoding()
    test_spec_sync()
    test_kernels()
    print(f"\n{'COMPILER TEST FAILED' if _failures else 'COMPILER TEST PASSED'} "
          f"({_checks - _failures}/{_checks} checks passed)")
    return 1 if _failures else 0


if __name__ == "__main__":
    sys.exit(main())
