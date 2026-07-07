# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Bit-exact golden models for the Titan X6 tensor core array.

Mirrors rtl/tensor/titan_x6_tensor_core_array.v exactly:
  - IEEE RNE FP16 multiply (titan_x5_fp16_mul) + the PE's widening rules
  - native FP8 E4M3/E5M2 multiply -> FP32 (exact, NaN/Inf flushed to 0)
  - the compact truncating flush-to-zero FP32 accumulator adder
  - dual-INT8 SIMD MAC with wrapping INT32 accumulate
Output-stationary array semantics: C[i][j] folds products in k order.
"""

M32 = 0xFFFFFFFF


def _rshift_rne(v, s):
    """Round-to-nearest-even right shift of a positive integer."""
    if s <= 0:
        return v << (-s)
    q = v >> s
    rem = v & ((1 << s) - 1)
    half = 1 << (s - 1)
    if rem > half or (rem == half and (q & 1)):
        q += 1
    return q


def fp16_mul(a, b):
    """IEEE-754 RNE half-precision multiply, bit-exact vs titan_x5_fp16_mul."""
    sa, ea, fa = (a >> 15) & 1, (a >> 10) & 0x1F, a & 0x3FF
    sb, eb, fb = (b >> 15) & 1, (b >> 10) & 0x1F, b & 0x3FF
    sr = sa ^ sb
    a_nan = ea == 31 and fa != 0
    b_nan = eb == 31 and fb != 0
    a_inf = ea == 31 and fa == 0
    b_inf = eb == 31 and fb == 0
    a_zero = ea == 0 and fa == 0
    b_zero = eb == 0 and fb == 0
    if a_nan or b_nan or (a_inf and b_zero) or (a_zero and b_inf):
        return 0x7E00
    if a_inf or b_inf:
        return (sr << 15) | 0x7C00
    if a_zero or b_zero:
        return sr << 15
    ma = fa | (0x400 if ea else 0)
    mb = fb | (0x400 if eb else 0)
    ea_eff = ea if ea else 1
    eb_eff = eb if eb else 1
    # value = (ma * mb) * 2^(ea_eff + eb_eff - 30 - 20)
    mp = ma * mb
    ep = (ea_eff - 15 - 10) + (eb_eff - 15 - 10)
    pos = mp.bit_length() - 1 + ep          # floor(log2(value))
    if pos >= -14:
        # normal (round first, renormalize on carry)
        shift = mp.bit_length() - 11
        mant = _rshift_rne(mp, shift)
        e_unb = pos
        if mant >> 11:                       # rounding carried out
            mant >>= 1
            e_unb += 1
        e_field = e_unb + 15
        if e_field >= 31:
            return (sr << 15) | 0x7C00       # overflow -> Inf
        if e_field >= 1:
            return (sr << 15) | (e_field << 10) | (mant & 0x3FF)
        # rounded back below the normal range: fall through as subnormal
    # subnormal: quantum 2^-24
    n = _rshift_rne(mp, -(ep + 24))
    if n == 0:
        return sr << 15
    if n >= 0x400:                           # rounds up into the normal range
        return (sr << 15) | (1 << 10) | (n & 0x3FF)
    return (sr << 15) | n


def fp16_to_fp32(h):
    """The PE's widening: signed zero kept, f16 denormals flushed."""
    s = (h >> 15) & 1
    if h & 0x7FFF == 0:
        return s << 31
    e = (h >> 10) & 0x1F
    if e == 0:
        return 0
    return (s << 31) | ((e + 112) << 23) | ((h & 0x3FF) << 13)


def fp8_mul_to_fp32(a, b, fmt):
    """Native FP8 multiply -> FP32, bit-exact vs fp8_mul_to_fp32."""
    sign = ((a >> 7) ^ (b >> 7)) & 1
    if fmt:
        ea, fa = (a >> 2) & 0x1F, ((a & 3) << 1)
        eb, fb = (b >> 2) & 0x1F, ((b & 3) << 1)
        a_nonfin = ea == 31
        b_nonfin = eb == 31
        bias = 15
    else:
        ea, fa = (a >> 3) & 0xF, a & 7
        eb, fb = (b >> 3) & 0xF, b & 7
        a_nonfin = ea == 15 and fa == 7
        b_nonfin = eb == 15 and fb == 7
        bias = 7
    a_den = ea == 0
    b_den = eb == 0
    a_zero = a_den and fa == 0
    b_zero = b_den and fb == 0
    ma = ((0 if a_den else 1) << 3) | fa
    mb = ((0 if b_den else 1) << 3) | fb
    prod = ma * mb
    if a_zero or b_zero or a_nonfin or b_nonfin or prod == 0:
        return sign << 31
    ea_eff = (1 if a_den else ea) - bias
    eb_eff = (1 if b_den else eb) - bias
    p = prod.bit_length() - 1
    exp32 = ea_eff + eb_eff - 6 + p + 127
    mant = (prod << (23 - p)) & 0x7FFFFF
    return (sign << 31) | ((exp32 & 0xFF) << 23) | mant


def fp32_add(a, b):
    """The compact truncating FTZ adder, bit-exact vs the RTL fp32_add."""
    if a == 0:
        return b
    if b == 0:
        return a
    sa, ea, fa = (a >> 31) & 1, (a >> 23) & 0xFF, a & 0x7FFFFF
    sb, eb, fb = (b >> 31) & 1, (b >> 23) & 0xFF, b & 0x7FFFFF
    ma = 0 if ea == 0 else ((1 << 23) | fa)
    mb = 0 if eb == 0 else ((1 << 23) | fb)
    if ea > eb:
        ma_al, mb_al = ma, mb >> min(ea - eb, 63)
        er, sr = ea, sa
    else:
        ma_al, mb_al = ma >> min(eb - ea, 63), mb
        er, sr = eb, sb
    if sa == sb:
        s = ma_al + mb_al
        if s >> 24:
            s >>= 1
            er = (er + 1) & 0xFF
        return (sr << 31) | (er << 23) | (s & 0x7FFFFF)
    if ma_al > mb_al:
        s, sr = ma_al - mb_al, sa
    elif mb_al > ma_al:
        s, sr = mb_al - ma_al, sb
    else:
        return 0
    if s == 0:
        return 0
    msb = s.bit_length() - 1
    shift = 23 - msb if msb <= 23 else 0
    # RTL priority chain caps at shift=23 (checks bits 23 down to 1)
    if shift > 23:
        shift = 23
    s = (s << shift) & ((1 << 25) - 1)
    er = (er - shift) & 0xFF
    return (sr << 31) | (er << 23) | (s & 0x7FFFFF)


def se(v, bits):
    v &= (1 << bits) - 1
    return v - (1 << bits) if v & (1 << (bits - 1)) else v


def pe_product(act, wgt, mode, fmt):
    """One PE product (32-bit raw), matching prod_mux."""
    if mode == 0:
        return fp16_to_fp32(fp16_mul(act, wgt))
    if mode == 1:
        return fp8_mul_to_fp32(act & 0xFF, wgt & 0xFF, fmt)
    if mode == 3:
        a0, a1 = se(act & 0xFF, 8), se((act >> 8) & 0xFF, 8)
        w0, w1 = se(wgt & 0xFF, 8), se((wgt >> 8) & 0xFF, 8)
        return (a0 * w0 + a1 * w1) & M32
    raise ValueError("mode 2 (FP4) not modelled here")


def wmma_golden(A, B, M, N, K, mode, fmt=0):
    """C[i][j] = fold_k acc(prod(A[i][k], B[k][j])), exactly as the
    output-stationary array computes it. A: M x K, B: K x N of raw
    16-bit lane values. Returns M x N of raw 32-bit accumulators."""
    C = [[0] * N for _ in range(M)]
    for i in range(M):
        for j in range(N):
            acc = 0
            for k in range(K):
                p = pe_product(A[i][k], B[k][j], mode, fmt)
                if mode == 3:
                    acc = (acc + p) & M32
                else:
                    acc = fp32_add(acc, p)
            C[i][j] = acc
    return C
