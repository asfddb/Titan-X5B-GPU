# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Deterministic generator for the FPU/LSU stimulus corpora.

Regenerates (overwrites) in this directory:
    fp32_vectors.json   {"add": [[hex,hex],...], "mul": [[hex,hex],...]}
    fp16_vectors.json   {"mul": [[hex,hex],...]}
    lsu_patterns.json   [{"mask":hex, "addrs":[hex x32], "write":0|1}, ...]

Operands only - the cocotb scoreboards (tb/uvm) compute all expected
values, so this corpus can only add coverage, never wrong expectations.

Usage:  python tb/vectors/gen_vectors.py
"""

import json
import os
import random

HERE = os.path.dirname(os.path.abspath(__file__))
SEED = 0x715A_B00C


# ---------------------------------------------------------------------------
# FP helpers (parameterized fp32/fp16)
# ---------------------------------------------------------------------------
class F:
    def __init__(self, exp_bits, mant_bits):
        self.E, self.M = exp_bits, mant_bits
        self.W = 1 + exp_bits + mant_bits
        self.BIAS = (1 << (exp_bits - 1)) - 1
        self.EMAX = (1 << exp_bits) - 1
        self.MMASK = (1 << mant_bits) - 1

    def enc(self, s, e, f):
        return ((s & 1) << (self.W - 1)) | ((e & self.EMAX) << self.M) | (f & self.MMASK)

    def hx(self, v):
        return f"0x{v:0{self.W // 4}X}"

    # canonical values
    @property
    def inf(self): return self.enc(0, self.EMAX, 0)
    @property
    def qnan(self): return self.enc(0, self.EMAX, 1 << (self.M - 1))
    @property
    def snan(self): return self.enc(0, self.EMAX, 1)
    @property
    def min_sub(self): return self.enc(0, 0, 1)
    @property
    def max_sub(self): return self.enc(0, 0, self.MMASK)
    @property
    def min_norm(self): return self.enc(0, 1, 0)
    @property
    def max_fin(self): return self.enc(0, self.EMAX - 1, self.MMASK)
    @property
    def one(self): return self.enc(0, self.BIAS, 0)

    def neg(self, v): return v ^ (1 << (self.W - 1))

    def rand_norm(self, rng, emin=1, emax=None):
        if emax is None:
            emax = self.EMAX - 1
        return self.enc(rng.getrandbits(1), rng.randint(emin, emax),
                        rng.getrandbits(self.M))

    def rand_sub(self, rng):
        return self.enc(rng.getrandbits(1), 0,
                        rng.randint(1, self.MMASK))


FP32 = F(8, 23)
FP16 = F(5, 10)


def fp_pairs(fmt, rng, n_random):
    """Build (add_pairs, mul_pairs) covering all mandated categories."""
    add, mul = [], []

    def both(lst, a, b):
        lst.append((a, b))
        lst.append((b, a))

    # -- 1. NaN propagation (payloads, qNaN/sNaN, both operand orders) -----
    nan_payloads = [fmt.qnan, fmt.qnan | 0x123 & fmt.MMASK,
                    fmt.neg(fmt.qnan), fmt.enc(0, fmt.EMAX, fmt.MMASK),
                    fmt.snan, fmt.snan | (1 << (fmt.M - 2)),
                    fmt.neg(fmt.snan)]
    others = [fmt.one, 0, fmt.neg(0), fmt.inf, fmt.neg(fmt.inf),
              fmt.min_sub, fmt.max_fin, fmt.qnan, fmt.snan]
    for nn in nan_payloads:
        for o in others:
            both(add, nn, o)
            both(mul, nn, o)

    # -- 2. Infinity math ---------------------------------------------------
    pinf, ninf = fmt.inf, fmt.neg(fmt.inf)
    for a, b in [(pinf, pinf), (pinf, ninf), (ninf, pinf), (ninf, ninf)]:
        add.append((a, b))
        mul.append((a, b))
    for z in (0, fmt.neg(0)):
        both(mul, pinf, z)
        both(mul, ninf, z)
    for fin in (fmt.one, fmt.max_fin, fmt.min_norm, fmt.min_sub):
        for i in (pinf, ninf):
            both(add, i, fin)
            both(add, i, fmt.neg(fin))
            both(mul, i, fin)
            both(mul, i, fmt.neg(fin))

    # -- 3. Signed zeros ----------------------------------------------------
    for sa in (0, fmt.neg(0)):
        for sb in (0, fmt.neg(0)):
            add.append((sa, sb))
            mul.append((sa, sb))
    for v in (fmt.one, fmt.neg(fmt.one), fmt.min_sub, fmt.max_fin):
        for z in (0, fmt.neg(0)):
            both(add, z, v)
            both(mul, z, v)

    # -- 4. Subnormals ------------------------------------------------------
    subs = [fmt.min_sub, fmt.enc(0, 0, 3), fmt.enc(0, 0, fmt.MMASK >> 1),
            fmt.max_sub, fmt.neg(fmt.min_sub), fmt.neg(fmt.max_sub)]
    for a in subs:
        for b in subs:
            add.append((a, b))       # sub+sub (above/below normal threshold)
            mul.append((a, b))       # sub*sub (deep underflow)
    for _ in range(20):
        add.append((fmt.rand_sub(rng), fmt.rand_sub(rng)))
        mul.append((fmt.rand_sub(rng), fmt.rand_sub(rng)))
    for o in (fmt.one, fmt.max_fin, fmt.min_norm, fmt.inf):
        both(add, fmt.min_sub, o)
        both(mul, fmt.min_sub, o)

    # -- 5. normal * subnormal crossing into normal range -------------------
    for _ in range(24):
        s = fmt.rand_sub(rng)
        # large multiplier pushes the product back over the normal threshold
        n = fmt.enc(rng.getrandbits(1),
                    rng.randint(fmt.BIAS + 2, fmt.BIAS + fmt.M + 2),
                    rng.getrandbits(fmt.M))
        both(mul, s, n)

    # -- 6. massive cancellation: a + (-a +/- k ulp) -------------------------
    for _ in range(30):
        a = fmt.rand_norm(rng, emin=2)
        for k in (0, 1, 2):
            b = fmt.neg(a) + k if (a & (1 << (fmt.W - 1))) == 0 else fmt.neg(a) - k
            add.append((a, b & ((1 << fmt.W) - 1)))
    # exponent-adjacent cancellation
    for _ in range(10):
        e = rng.randint(2, fmt.EMAX - 2)
        add.append((fmt.enc(0, e, 0), fmt.enc(1, e - 1, fmt.MMASK)))

    # -- 7. RNE ties: guard=1, round=sticky=0, lsb in {0,1} ------------------
    for _ in range(20):
        e = rng.randint(fmt.M + 2, fmt.EMAX - 2)
        f_even = rng.getrandbits(fmt.M) & ~1
        for lsb in (0, 1):
            a = fmt.enc(0, e, f_even | lsb)
            b = fmt.enc(0, e - fmt.M - 1, 0)   # exactly ulp(a)/2
            both(add, a, b)
    # mul ties: mantissa products with a lone guard bit
    m_tie_a = fmt.enc(0, fmt.BIAS, 1)                       # 1 + ulp
    m_tie_b = fmt.enc(0, fmt.BIAS, 1 << (fmt.M - 1))        # 1.5
    both(mul, m_tie_a, m_tie_b)
    both(mul, fmt.enc(0, fmt.BIAS, 2), m_tie_b)
    for _ in range(10):
        both(mul, fmt.enc(0, rng.randint(2, fmt.EMAX - 2), 1), m_tie_b)

    # -- 8. overflow boundaries ----------------------------------------------
    # add: max_fin + half-ulp / full-ulp contributions
    ulp_e = (fmt.EMAX - 1) - fmt.M          # exponent of ulp(max_fin)
    add += [(fmt.max_fin, fmt.max_fin),
            (fmt.max_fin, fmt.enc(0, ulp_e, 0)),        # + ulp -> inf
            (fmt.max_fin, fmt.enc(0, ulp_e - 1, 0)),    # + ulp/2 tie -> inf
            (fmt.max_fin, fmt.enc(0, ulp_e - 2, 0)),    # stays max_fin
            (fmt.neg(fmt.max_fin), fmt.neg(fmt.max_fin))]
    # mul: results straddling max finite
    half = fmt.EMAX >> 1
    mul += [(fmt.max_fin, fmt.enc(0, fmt.BIAS, 1)),     # * (1+ulp) -> ovf
            (fmt.max_fin, fmt.one),
            (fmt.max_fin, fmt.enc(0, fmt.BIAS - 1, fmt.MMASK)),  # * <1
            (fmt.enc(0, half + fmt.BIAS // 2, 0), fmt.enc(0, half + fmt.BIAS // 2, 0)),
            (fmt.enc(0, fmt.EMAX - 2, 0), fmt.enc(0, fmt.BIAS + 1, 0))]

    # -- 9. gradual underflow rounding up to smallest normal -----------------
    # (1 - ulp) * min_norm and neighbors round back up to min_norm
    just_below_one = fmt.enc(0, fmt.BIAS - 1, fmt.MMASK)
    both(mul, just_below_one, fmt.min_norm)
    both(mul, fmt.enc(0, fmt.BIAS - 1, fmt.MMASK - 1), fmt.min_norm)
    for _ in range(16):
        # products landing within a few ulp of the subnormal/normal border
        a = fmt.enc(rng.getrandbits(1), fmt.BIAS - 1, fmt.MMASK - rng.randint(0, 3))
        b = fmt.enc(rng.getrandbits(1), 1, rng.randint(0, 3))
        both(mul, a, b)

    # -- 10. alignment-shift extremes (add) ----------------------------------
    for d in (0, 1, fmt.M, fmt.M + 1, fmt.M + 2, fmt.M + 3, 60):
        for _ in range(6):
            e1 = rng.randint(min(d + 1, fmt.EMAX - 2), fmt.EMAX - 2)
            a = fmt.enc(rng.getrandbits(1), e1, rng.getrandbits(fmt.M))
            e2 = e1 - d
            b = (fmt.enc(rng.getrandbits(1), e2, rng.getrandbits(fmt.M))
                 if e2 >= 1 else fmt.rand_sub(rng))
            both(add, a, b)

    # -- fill with biased randoms up to the target count ---------------------
    def biased(rngl):
        style = rngl.randrange(5)
        if style == 0:
            return rngl.getrandbits(fmt.W)
        if style == 1:
            return fmt.rand_sub(rngl)
        if style == 2:
            return fmt.rand_norm(rngl, emin=1, emax=4)
        if style == 3:
            return fmt.rand_norm(rngl, emin=fmt.EMAX - 4)
        return fmt.rand_norm(rngl)

    while len(add) < n_random:
        add.append((biased(rng), biased(rng)))
    while len(mul) < n_random:
        mul.append((biased(rng), biased(rng)))

    to_hex = lambda lst: [[fmt.hx(a), fmt.hx(b)] for a, b in lst]
    return to_hex(add), to_hex(mul)


# ---------------------------------------------------------------------------
# LSU patterns
# ---------------------------------------------------------------------------
def lsu_patterns(rng):
    LINE = 128
    LIMIT = 0x40000
    pats = []

    def entry(mask, addrs, write):
        assert len(addrs) == 32
        assert all(a % 4 == 0 and 0 <= a < LIMIT for a in addrs)
        pats.append({"mask": f"0x{mask & 0xFFFFFFFF:08X}",
                     "addrs": [f"0x{a:X}" for a in addrs],
                     "write": int(write)})

    full = 0xFFFFFFFF
    base = 0x1000
    seq = [base + 4 * i for i in range(32)]

    for wr in (0, 1):
        entry(full, seq, wr)                                   # 1 converged
        entry(full, [0x2000 + 4 * i for i in range(32)], wr)   # 2 sequential
        entry(full, [0x3000 + 8 * i for i in range(32)], wr)   # 3 stride-2
        entry(full, [0x4000 + 16 * i for i in range(32)], wr)  #   stride-4
        entry(full, [0x5000 + 32 * i for i in range(32)], wr)  #   stride-8
        entry(full, [0x6040] * 32, wr)                         # 4 same addr
        entry(full, [0x7000 + 64 + 4 * i for i in range(32)], wr)  # 5 straddle
        entry(full, [0x8000 + LINE * i for i in range(32)], wr)    # 6 scatter
        entry(1 << 13, seq, wr)                                # 7 single lane
        entry(0x55555555, seq, wr)                             #   alternating
        entry(rng.getrandbits(32) | 1, seq, wr)                #   random sparse
        outlier = [0x9000] * 32
        outlier[7] = 0x9000 + 0x2000                           # 8 outlier
        entry(full, outlier, wr)
        entry(full, [0xA000 + 4 * (31 - i) for i in range(32)], wr)  # 9 reverse

    # constrained randoms: pools of varying density
    for _ in range(30):
        style = rng.randrange(4)
        if style == 0:
            a0 = rng.randrange(0, LIMIT - 256, 4)
            addrs = [a0 + 4 * rng.randrange(64) for _ in range(32)]
        elif style == 1:
            addrs = [rng.randrange(0, LIMIT, 4) for _ in range(32)]
        elif style == 2:
            a0 = rng.randrange(0, LIMIT - LINE * 40, 4)
            addrs = [(a0 + LINE * rng.randrange(8)) + 4 * rng.randrange(32)
                     for _ in range(32)]
        else:
            a0 = rng.randrange(0, LIMIT - 4 * 40, 4)
            addrs = [a0 + 4 * i for i in range(32)]
        mask = rng.getrandbits(32) if rng.random() < 0.6 else full
        entry(mask, addrs, rng.getrandbits(1))
    return pats


def main():
    rng = random.Random(SEED)
    add32, mul32 = fp_pairs(FP32, rng, n_random=520)
    _, mul16 = fp_pairs(FP16, rng, n_random=420)
    lsu = lsu_patterns(rng)

    out = {
        "fp32_vectors.json": {"add": add32, "mul": mul32},
        "fp16_vectors.json": {"mul": mul16},
        "lsu_patterns.json": lsu,
    }
    for name, data in out.items():
        path = os.path.join(HERE, name)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(data, f, indent=1)
            f.write("\n")
        # round-trip validation
        with open(path, "r", encoding="utf-8") as f:
            json.load(f)
        print(f"{name}: ", end="")
        if isinstance(data, dict):
            print({k: len(v) for k, v in data.items()})
        else:
            print(f"{len(data)} entries")


if __name__ == "__main__":
    main()
