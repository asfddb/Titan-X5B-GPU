# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Exact IEEE-754 reference model (integer arithmetic, no FP rounding leaks).

Supports arbitrary binary formats (fp32/fp16), all four rounding modes and
the exception flags produced by the Titan X5 FPU RTL:

    invalid   - sNaN operand, Inf-Inf (add), Inf*0 (mul)
    overflow  - rounded magnitude exceeds max finite (result per-mode)
    underflow - result is subnormal-or-zero AND inexact (after-rounding
                tininess, matching the RTL definition)
    inexact   - rounding discarded information (or overflow)

NaN results are canonical quiet NaNs, matching the RTL.
"""

RM_RNE = 0
RM_RTZ = 1
RM_RDN = 2
RM_RUP = 3


class FpFormat:
    def __init__(self, exp_bits, mant_bits):
        self.EXP = exp_bits
        self.MANT = mant_bits
        self.BIAS = (1 << (exp_bits - 1)) - 1
        self.EMAX_FIELD = (1 << exp_bits) - 1
        self.WIDTH = 1 + exp_bits + mant_bits
        self.QNAN = ((self.EMAX_FIELD << mant_bits) | (1 << (mant_bits - 1)))
        self.MIN_SCALE = 1 - self.BIAS - mant_bits  # scale of subnormal LSB

    def inf(self, sign):
        return (sign << (self.WIDTH - 1)) | (self.EMAX_FIELD << self.MANT)

    def max_finite(self, sign):
        return ((sign << (self.WIDTH - 1))
                | ((self.EMAX_FIELD - 1) << self.MANT)
                | ((1 << self.MANT) - 1))

    def zero(self, sign):
        return sign << (self.WIDTH - 1)


FP32 = FpFormat(8, 23)
FP16 = FpFormat(5, 10)


def _decode(bits, fmt):
    """Return (kind, sign, mant, scale). kind in {nan, snan, inf, zero, fin}.
    For 'fin': value == (-1)^sign * mant * 2^scale, mant > 0."""
    sign = (bits >> (fmt.WIDTH - 1)) & 1
    e = (bits >> fmt.MANT) & fmt.EMAX_FIELD
    f = bits & ((1 << fmt.MANT) - 1)
    if e == fmt.EMAX_FIELD:
        if f == 0:
            return ("inf", sign, None, None)
        return ("snan" if not (f >> (fmt.MANT - 1)) & 1 else "nan",
                sign, None, None)
    if e == 0:
        if f == 0:
            return ("zero", sign, 0, fmt.MIN_SCALE)
        return ("fin", sign, f, fmt.MIN_SCALE)
    return ("fin", sign, f | (1 << fmt.MANT), e - fmt.BIAS - fmt.MANT)


def _flags(invalid=False, overflow=False, underflow=False, inexact=False):
    return {"invalid": invalid, "overflow": overflow,
            "underflow": underflow, "inexact": inexact}


def _round_pack(sign, mant, scale, rm, fmt):
    """Round exact magnitude mant*2^scale (mant>0) into the format."""
    # choose the LSB weight of the kept mantissa
    msb_exp = scale + mant.bit_length() - 1
    lsb_exp = max(msb_exp - fmt.MANT, fmt.MIN_SCALE)
    shift = lsb_exp - scale
    if shift > 0:
        kept = mant >> shift
        rem = mant & ((1 << shift) - 1)
        round_bit = (rem >> (shift - 1)) & 1
        sticky = (rem & ((1 << (shift - 1)) - 1)) != 0
    else:
        kept = mant << (-shift)
        round_bit = 0
        sticky = False

    inexact = bool(round_bit) or sticky
    if rm == RM_RNE:
        inc = round_bit and (sticky or (kept & 1))
    elif rm == RM_RTZ:
        inc = False
    elif rm == RM_RDN:
        inc = bool(sign) and inexact
    else:  # RM_RUP
        inc = (not sign) and inexact

    if inc:
        kept += 1
        if kept.bit_length() > fmt.MANT + 1:
            kept >>= 1
            lsb_exp += 1

    if kept == 0:
        # rounded all the way to zero
        return fmt.zero(sign), _flags(underflow=inexact, inexact=inexact)

    if kept >> fmt.MANT:  # normal candidate
        biased = lsb_exp + fmt.MANT + fmt.BIAS
        if biased >= fmt.EMAX_FIELD:
            # overflow: result depends on rounding mode
            if rm == RM_RNE:
                res = fmt.inf(sign)
            elif rm == RM_RTZ:
                res = fmt.max_finite(sign)
            elif rm == RM_RDN:
                res = fmt.inf(sign) if sign else fmt.max_finite(sign)
            else:
                res = fmt.max_finite(sign) if sign else fmt.inf(sign)
            return res, _flags(overflow=True, inexact=True)
        res = ((sign << (fmt.WIDTH - 1)) | (biased << fmt.MANT)
               | (kept & ((1 << fmt.MANT) - 1)))
        return res, _flags(inexact=inexact)

    # subnormal (lsb_exp == MIN_SCALE by construction)
    res = (sign << (fmt.WIDTH - 1)) | kept
    return res, _flags(underflow=inexact, inexact=inexact)


def fp_add(a_bits, b_bits, rm, fmt=FP32):
    ka, sa, ma, ca = _decode(a_bits, fmt)
    kb, sb, mb, cb = _decode(b_bits, fmt)

    if ka in ("nan", "snan") or kb in ("nan", "snan"):
        return fmt.QNAN, _flags(invalid=(ka == "snan" or kb == "snan"))
    if ka == "inf" and kb == "inf":
        if sa != sb:
            return fmt.QNAN, _flags(invalid=True)
        return fmt.inf(sa), _flags()
    if ka == "inf":
        return fmt.inf(sa), _flags()
    if kb == "inf":
        return fmt.inf(sb), _flags()
    if ka == "zero" and kb == "zero":
        if sa == sb:
            return fmt.zero(sa), _flags()
        return fmt.zero(1 if rm == RM_RDN else 0), _flags()

    scale = min(ca, cb)
    va = (ma << (ca - scale)) * (-1 if sa else 1)
    vb = (mb << (cb - scale)) * (-1 if sb else 1)
    s = va + vb
    if s == 0:
        return fmt.zero(1 if rm == RM_RDN else 0), _flags()
    sign = 1 if s < 0 else 0
    return _round_pack(sign, abs(s), scale, rm, fmt)


def fp_mul(a_bits, b_bits, rm, fmt=FP32):
    ka, sa, ma, ca = _decode(a_bits, fmt)
    kb, sb, mb, cb = _decode(b_bits, fmt)
    sign = sa ^ sb

    if ka in ("nan", "snan") or kb in ("nan", "snan"):
        return fmt.QNAN, _flags(invalid=(ka == "snan" or kb == "snan"))
    if (ka == "inf" and kb == "zero") or (ka == "zero" and kb == "inf"):
        return fmt.QNAN, _flags(invalid=True)
    if ka == "inf" or kb == "inf":
        return fmt.inf(sign), _flags()
    if ka == "zero" or kb == "zero":
        return fmt.zero(sign), _flags()

    return _round_pack(sign, ma * mb, ca + cb, rm, fmt)


def fp_fma(a_bits, b_bits, c_bits, rm, fmt=FP32):
    """Fused multiply-add: a*b + c with a SINGLE rounding.

    Special-value rules match the RTL (titan_x5_fp32_fma):
    - any NaN -> canonical qNaN; invalid if any sNaN.
    - 0*Inf raises invalid even when the addend is a quiet NaN
      (RISC-V convention).
    - Inf product + opposite-signed Inf addend -> qNaN + invalid.
    - exact zero sum -> +0 (or -0 under RDN); same-signed zero
      operands keep their sign.
    """
    ka, sa, ma, ca = _decode(a_bits, fmt)
    kb, sb, mb, cb = _decode(b_bits, fmt)
    kc, sc, mc, cc = _decode(c_bits, fmt)
    ps = sa ^ sb

    mul_inv = ((ka == "inf" and kb == "zero")
               or (ka == "zero" and kb == "inf"))
    if ka in ("nan", "snan") or kb in ("nan", "snan") or kc in ("nan", "snan"):
        any_snan = "snan" in (ka, kb, kc)
        return fmt.QNAN, _flags(invalid=any_snan or mul_inv)
    if mul_inv:
        return fmt.QNAN, _flags(invalid=True)
    if ka == "inf" or kb == "inf":
        if kc == "inf" and sc != ps:
            return fmt.QNAN, _flags(invalid=True)
        return fmt.inf(ps), _flags()
    if kc == "inf":
        return fmt.inf(sc), _flags()
    if (ka == "zero" or kb == "zero") and kc == "zero":
        if ps == sc:
            return fmt.zero(ps), _flags()
        return fmt.zero(1 if rm == RM_RDN else 0), _flags()

    scale_p = ca + cb
    scale = min(scale_p, cc)
    s = (((ma * mb) << (scale_p - scale)) * (-1 if ps else 1)
         + ((mc << (cc - scale)) * (-1 if sc else 1)))
    if s == 0:
        return fmt.zero(1 if rm == RM_RDN else 0), _flags()
    sign = 1 if s < 0 else 0
    return _round_pack(sign, abs(s), scale, rm, fmt)


def is_nan(bits, fmt=FP32):
    e = (bits >> fmt.MANT) & fmt.EMAX_FIELD
    f = bits & ((1 << fmt.MANT) - 1)
    return e == fmt.EMAX_FIELD and f != 0


if __name__ == "__main__":
    # self-check against numpy (RNE only)
    import struct
    import random
    import numpy as np

    def np32(bits):
        return np.frombuffer(struct.pack("<I", bits), dtype=np.float32)[0]

    def bits32(v):
        return struct.unpack("<I", np.float32(v).tobytes())[0]

    random.seed(1234)
    err = 0
    old = np.seterr(all="ignore")
    for trial in range(200000):
        a = random.getrandbits(32)
        b = random.getrandbits(32)
        r_add, _ = fp_add(a, b, RM_RNE)
        r_mul, _ = fp_mul(a, b, RM_RNE)
        n_add = bits32(np32(a) + np32(b))
        n_mul = bits32(np32(a) * np32(b))
        for mine, ref in ((r_add, n_add), (r_mul, n_mul)):
            if is_nan(mine) and is_nan(ref):
                continue
            if mine != ref:
                err += 1
                print(f"MISMATCH a={a:08x} b={b:08x} mine={mine:08x} np={ref:08x}")
                if err > 5:
                    raise SystemExit(1)
    np.seterr(**old)
    print("fp_ref self-check vs numpy: OK" if err == 0 else f"{err} errors")
