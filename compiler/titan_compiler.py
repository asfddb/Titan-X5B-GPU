#!/usr/bin/env python3
# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# ============================================================================
"""
titan_compiler.py -- the Titan Compute Compiler (TCC).

A CUDA-like compiler for the Titan X6 GPU. The frontend parses a restricted
Python kernel function into an AST; the backend lowers it to Titan ISA v2
machine code (bit-identical encoding to rtl/core/titan_x5_decoder.v, see
driver/titan_x6_isa.h for the software contract).

Two backends:

  scalar  -- general lowering of loops / integer arithmetic / array
             subscripts onto the SM scalar pipeline (int32 arrays).

  tensor  -- pattern-matches the canonical matrix-multiplication triple
             loop and re-lowers it as 16x16x16 WMMA tile operations on the
             FP8/INT8 tensor core array (titan_x6_wmma_dispatch.v).

Kernel language subset:
    def kernel(A, B, C, M, N, K):        # arrays + int scalars
        for i in range(...):             # range(stop|start,stop[,step])
            x = <int expr>               # + - * // % << >> & | ^
            A[<expr>] = <expr>           # int32 element access
            acc += <expr>

ABI (must match titan_x6_gpu_model.c):
    R0    = 0
    R1    = kernel parameter block address (one uint32 per parameter)
    R58/59/60 = WMMA strides lda/ldb/ldc (elements)
    R61/62    = nthreads / tid
    BARRIER #0xFFF = EXIT

Usage:
    python3 titan_compiler.py kernel.py -o kernel.tbin [--backend tensor]
            [--dtype fp8|int8] [--dump]
    python3 titan_compiler.py --selftest
"""

import argparse
import ast
import struct
import sys

# ---------------------------------------------------------------------------
# ISA definition (mirror of driver/titan_x6_isa.h)
# ---------------------------------------------------------------------------
OPS = {
    "ADD": 0,  "SUB": 1,  "MUL": 2,  "MULHI": 3, "DIV": 4,
    "AND": 5,  "OR": 6,   "XOR": 7,  "SHL": 8,   "SHR": 9,
    "SRA": 10, "SLT": 11, "SLTU": 12, "MIN": 13, "MAX": 14,
    "FMA": 15, "FADD": 16, "FMUL": 17, "FMIN": 18, "FMAX": 19,
    "CVT": 20, "SETP": 21, "LOAD": 22, "STORE": 23, "BRANCH": 24,
    "BARRIER": 25, "WMMA": 26, "SIN": 27, "COS": 28, "RSQRT": 29,
    "ATOM_ADD": 30, "ATOM_CAS": 31,
}
OP_NAMES = {v: k for k, v in OPS.items()}

CMP_EQ, CMP_NE, CMP_LT, CMP_GE, CMP_LTU, CMP_GEU = range(6)
CMP_NAMES = ["EQ", "NE", "LT", "GE", "LTU", "GEU"]

R_ZERO, R_PARAM = 0, 1
R_LDA, R_LDB, R_LDC = 58, 59, 60
R_NTHREADS, R_TID = 61, 62
R_POOL = list(range(2, 58))          # general-purpose allocation pool

EXIT_IMM = 0xFFF
WMMA_FLAG_FP8 = 0x1
WMMA_TILE = 16

TBIN_MAGIC = 0x4E494254             # "TBIN"
TBIN_VERSION = 1
TBIN_FLAG_TENSOR = 0x1


def enc_r(op, rd, rs1, rs2=0, rs3=0, pred=0):
    return ((op << 27) | ((rd & 63) << 21) | ((rs1 & 63) << 15) |
            ((rs2 & 63) << 9) | ((rs3 & 63) << 3) | ((pred & 3) << 1))


def enc_i(op, rd, rs1, imm, pred=0):
    assert 0 <= imm <= 0xFFF, f"imm12 out of range: {imm}"
    return ((op << 27) | ((rd & 63) << 21) | ((rs1 & 63) << 15) |
            ((imm & 0xFFF) << 3) | ((pred & 3) << 1) | 1)


def disassemble(word):
    op = (word >> 27) & 0x1F
    rd = (word >> 21) & 0x3F
    rs1 = (word >> 15) & 0x3F
    rs2 = (word >> 9) & 0x3F
    rs3 = (word >> 3) & 0x3F
    pred = (word >> 1) & 0x3
    uimm = word & 1
    imm = (word >> 3) & 0xFFF
    name = OP_NAMES[op]
    ptxt = f"@p{pred} " if pred else ""

    if name == "BRANCH":
        return f"{ptxt}BRANCH -> {imm}"
    if name == "BARRIER":
        return f"{ptxt}EXIT" if (uimm and imm == EXIT_IMM) else f"{ptxt}BARRIER"
    if name == "SETP":
        cond, pdst = (rd >> 2) & 7, rd & 3
        src2 = f"#{imm}" if uimm else f"r{rs2}"
        return f"{ptxt}SETP.{CMP_NAMES[cond]} p{pdst}, r{rs1}, {src2}"
    if name == "WMMA":
        mode = "FP8" if (rs3 & WMMA_FLAG_FP8) else "INT8"
        return f"{ptxt}WMMA.{mode}.16x16x16 [r{rd}] += [r{rs1}] x [r{rs2}]"
    if name == "LOAD":
        off = f"#{imm}" if uimm else f"r{rs2}"
        return f"{ptxt}LOAD r{rd}, [r{rs1} + {off}]"
    if name == "STORE":
        off = f"#{imm}" if uimm else f"r{rs2}"
        return f"{ptxt}STORE [r{rs1} + {off}], r{rd}"
    src2 = f"#{imm}" if uimm else f"r{rs2}"
    if name == "FMA":
        return f"{ptxt}FMA r{rd}, r{rs1}, {src2}, r{rs3}"
    return f"{ptxt}{name} r{rd}, r{rs1}, {src2}"


class CompileError(Exception):
    def __init__(self, msg, node=None):
        if node is not None and hasattr(node, "lineno"):
            msg = f"line {node.lineno}: {msg}"
        super().__init__(msg)


# ---------------------------------------------------------------------------
# Assembler: instruction stream with label fixups
# ---------------------------------------------------------------------------
class Label:
    def __init__(self):
        self.pc = None


class Assembler:
    def __init__(self):
        self.words = []
        self.fixups = []              # (index, label)

    def here(self):
        lbl = Label()
        lbl.pc = len(self.words)
        return lbl

    def new_label(self):
        return Label()

    def bind(self, lbl):
        lbl.pc = len(self.words)

    def r(self, op, rd, rs1, rs2=0, rs3=0, pred=0):
        self.words.append(enc_r(OPS[op], rd, rs1, rs2, rs3, pred))

    def i(self, op, rd, rs1, imm, pred=0):
        self.words.append(enc_i(OPS[op], rd, rs1, imm, pred))

    def branch(self, lbl, pred=0):
        self.fixups.append((len(self.words), lbl))
        self.words.append(enc_i(OPS["BRANCH"], 0, 0, 0, pred))

    def setp(self, cond, pdst, rs1, rs2):
        self.r("SETP", (cond << 2) | pdst, rs1, rs2)

    def li(self, rd, value):
        """Materialize a 32-bit constant."""
        value &= 0xFFFFFFFF
        if value <= 0xFFF:
            self.i("ADD", rd, R_ZERO, value)
        elif (1 << 32) - value <= 0xFFF:            # small negative
            self.i("ADD", rd, R_ZERO, (1 << 32) - value)
            self.r("SUB", rd, R_ZERO, rd)
        else:
            self.i("ADD", rd, R_ZERO, (value >> 24) & 0xFF)
            self.i("SHL", rd, rd, 12)
            self.i("OR", rd, rd, (value >> 12) & 0xFFF)
            self.i("SHL", rd, rd, 12)
            self.i("OR", rd, rd, value & 0xFFF)

    def mov(self, rd, rs):
        if rd != rs:
            self.i("ADD", rd, rs, 0)

    def exit(self):
        self.i("BARRIER", 0, 0, EXIT_IMM)

    def finalize(self):
        for idx, lbl in self.fixups:
            if lbl.pc is None:
                raise CompileError("unbound label")
            if lbl.pc > 0xFFF:
                raise CompileError("branch target beyond imm12 range")
            self.words[idx] |= (lbl.pc & 0xFFF) << 3
        self.fixups = []
        return self.words


# ---------------------------------------------------------------------------
# Frontend helpers
# ---------------------------------------------------------------------------
def parse_kernel(source, func_name=None):
    tree = ast.parse(source)
    fns = [n for n in tree.body if isinstance(n, ast.FunctionDef)]
    if not fns:
        raise CompileError("no function definition found in kernel source")
    if func_name:
        fns = [f for f in fns if f.name == func_name]
        if not fns:
            raise CompileError(f"function '{func_name}' not found")
    return fns[0]


def collect_array_params(fn):
    """Parameters used with subscripts are arrays; the rest are int scalars."""
    arrays = set()

    class V(ast.NodeVisitor):
        def visit_Subscript(self, node):
            if isinstance(node.value, ast.Name):
                arrays.add(node.value.id)
            self.generic_visit(node)

    V().visit(fn)
    return arrays


# ---------------------------------------------------------------------------
# Scalar backend: general lowering of the kernel subset
# ---------------------------------------------------------------------------
class ScalarCodegen:
    BINOPS = {
        ast.Add: "ADD", ast.Sub: "SUB", ast.Mult: "MUL",
        ast.LShift: "SHL", ast.RShift: "SRA",
        ast.BitAnd: "AND", ast.BitOr: "OR", ast.BitXor: "XOR",
        ast.FloorDiv: "DIV",
    }

    def __init__(self, fn):
        self.fn = fn
        self.asm = Assembler()
        self.free_regs = list(R_POOL)
        self.vars = {}                # name -> reg (params + locals)
        self.arrays = collect_array_params(fn)

    # --- register management ---
    def alloc(self):
        if not self.free_regs:
            raise CompileError("register pressure too high (out of regs)")
        return self.free_regs.pop(0)

    def release(self, reg):
        if reg in R_POOL and reg not in self.vars.values():
            self.free_regs.insert(0, reg)

    def var_reg(self, name, node=None):
        if name not in self.vars:
            self.vars[name] = self.alloc()
        return self.vars[name]

    # --- expression lowering; returns (reg, is_temp) ---
    def gen_expr(self, node):
        if isinstance(node, ast.Constant):
            if not isinstance(node.value, int):
                raise CompileError("only integer constants supported", node)
            t = self.alloc()
            self.asm.li(t, node.value)
            return t, True

        if isinstance(node, ast.Name):
            if node.id not in self.vars:
                raise CompileError(f"undefined variable '{node.id}'", node)
            return self.vars[node.id], False

        if isinstance(node, ast.UnaryOp) and isinstance(node.op, ast.USub):
            src, tmp = self.gen_expr(node.operand)
            t = self.alloc()
            self.asm.r("SUB", t, R_ZERO, src)
            if tmp:
                self.release(src)
            return t, True

        if isinstance(node, ast.BinOp):
            return self.gen_binop(node)

        if isinstance(node, ast.Subscript):
            base, off, off_tmp = self.gen_subscript(node)
            t = self.alloc()
            self.asm.r("LOAD", t, base, off)
            if off_tmp:
                self.release(off)
            return t, True

        raise CompileError(f"unsupported expression {ast.dump(node)}", node)

    def gen_binop(self, node):
        opty = type(node.op)
        if opty not in self.BINOPS and opty is not ast.Mod:
            raise CompileError(f"unsupported operator {opty.__name__}", node)

        a, a_tmp = self.gen_expr(node.left)

        # immediate form when RHS is a small constant
        if (isinstance(node.right, ast.Constant) and
                isinstance(node.right.value, int) and
                0 <= node.right.value <= 0xFFF and opty is not ast.Mod):
            t = self.alloc()
            self.asm.i(self.BINOPS[opty], t, a, node.right.value)
            if a_tmp:
                self.release(a)
            return t, True

        b, b_tmp = self.gen_expr(node.right)
        t = self.alloc()
        if opty is ast.Mod:
            # a % b  ->  a - (a // b) * b   (b > 0 in kernel code)
            self.asm.r("DIV", t, a, b)
            self.asm.r("MUL", t, t, b)
            self.asm.r("SUB", t, a, t)
        else:
            self.asm.r(self.BINOPS[opty], t, a, b)
        if a_tmp:
            self.release(a)
        if b_tmp:
            self.release(b)
        return t, True

    def gen_subscript(self, node):
        """Return (base_reg, byte_offset_reg, offset_is_temp) for A[idx]."""
        if not isinstance(node.value, ast.Name):
            raise CompileError("only direct array subscripts supported", node)
        name = node.value.id
        if name not in self.vars:
            raise CompileError(f"unknown array '{name}'", node)
        idx = node.slice
        idx_reg, idx_tmp = self.gen_expr(idx)
        off = self.alloc()
        self.asm.i("SHL", off, idx_reg, 2)      # int32 elements
        if idx_tmp:
            self.release(idx_reg)
        return self.vars[name], off, True

    # --- statement lowering ---
    def gen_stmt(self, node):
        if isinstance(node, ast.For):
            return self.gen_for(node)

        if isinstance(node, ast.Assign):
            if len(node.targets) != 1:
                raise CompileError("multiple assignment not supported", node)
            tgt = node.targets[0]
            if isinstance(tgt, ast.Name):
                src, tmp = self.gen_expr(node.value)
                dst = self.var_reg(tgt.id)
                self.asm.mov(dst, src)
                if tmp:
                    self.release(src)
                return
            if isinstance(tgt, ast.Subscript):
                val, val_tmp = self.gen_expr(node.value)
                base, off, off_tmp = self.gen_subscript(tgt)
                self.asm.r("STORE", val, base, off)
                if val_tmp:
                    self.release(val)
                if off_tmp:
                    self.release(off)
                return
            raise CompileError("unsupported assignment target", node)

        if isinstance(node, ast.AugAssign):
            expanded = ast.Assign(
                targets=[node.target],
                value=ast.BinOp(left=node.target, op=node.op,
                                right=node.value))
            ast.copy_location(expanded, node)
            ast.fix_missing_locations(expanded)
            # AugAssign targets are loads on the RHS: re-tag context
            expanded.value.left = ast.copy_location(
                ast.Subscript(value=node.target.value,
                              slice=node.target.slice, ctx=ast.Load())
                if isinstance(node.target, ast.Subscript)
                else ast.Name(id=node.target.id, ctx=ast.Load()), node)
            return self.gen_stmt(expanded)

        if isinstance(node, ast.Return):
            if node.value is not None:
                raise CompileError("kernels cannot return values; write "
                                   "results through array parameters", node)
            self.asm.exit()
            return

        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant):
            return  # docstring

        if isinstance(node, ast.Pass):
            return

        raise CompileError(f"unsupported statement {type(node).__name__}",
                           node)

    def gen_for(self, node):
        if (not isinstance(node.iter, ast.Call) or
                not isinstance(node.iter.func, ast.Name) or
                node.iter.func.id != "range"):
            raise CompileError("only 'for ... in range(...)' loops supported",
                               node)
        if not isinstance(node.target, ast.Name):
            raise CompileError("loop target must be a simple name", node)
        args = node.iter.args
        if len(args) == 1:
            start, stop, step = ast.Constant(value=0), args[0], 1
        elif len(args) == 2:
            start, stop, step = args[0], args[1], 1
        elif len(args) == 3:
            if (not isinstance(args[2], ast.Constant) or
                    not isinstance(args[2].value, int) or args[2].value <= 0):
                raise CompileError("range step must be a positive integer "
                                   "constant", node)
            start, stop, step = args[0], args[1], args[2].value
        else:
            raise CompileError("bad range()", node)

        ivar = self.var_reg(node.target.id)
        s_reg, s_tmp = self.gen_expr(start)
        self.asm.mov(ivar, s_reg)
        if s_tmp:
            self.release(s_reg)

        stop_reg, stop_tmp = self.gen_expr(stop)
        if not stop_tmp:
            # keep loop bound in a private register in case the body
            # writes the source variable
            held = self.alloc()
            self.asm.mov(held, stop_reg)
            stop_reg, stop_tmp = held, True

        top = self.asm.here()
        end = self.asm.new_label()
        self.asm.setp(CMP_GE, 1, ivar, stop_reg)
        self.asm.branch(end, pred=1)
        for stmt in node.body:
            self.gen_stmt(stmt)
        if node.orelse:
            raise CompileError("for/else not supported", node)
        self.asm.i("ADD", ivar, ivar, step)
        self.asm.branch(top)
        self.asm.bind(end)
        self.release(stop_reg)

    def compile(self):
        # prologue: load parameters from the parameter block (R1)
        for idx, arg in enumerate(self.fn.args.args):
            reg = self.var_reg(arg.arg)
            self.asm.i("LOAD", reg, R_PARAM, 4 * idx)
        for stmt in self.fn.body:
            self.gen_stmt(stmt)
        self.asm.exit()
        return self.asm.finalize()


# ---------------------------------------------------------------------------
# Tensor backend: matmul pattern match -> WMMA tiles
# ---------------------------------------------------------------------------
class MatmulPattern:
    """Recognized canonical form:

        for i in range(M):
            for j in range(N):
                acc = 0
                for k in range(K):
                    acc += A[i*K + k] * B[k*N + j]
                C[i*N + j] = acc
    """
    def __init__(self, A, B, C, M, N, K):
        self.A, self.B, self.C = A, B, C
        self.M, self.N, self.K = M, N, K


def _match_range1(node):
    """for <name> in range(<Name>) -> (ivar, bound) or None"""
    if (isinstance(node, ast.For) and isinstance(node.target, ast.Name) and
            isinstance(node.iter, ast.Call) and
            isinstance(node.iter.func, ast.Name) and
            node.iter.func.id == "range" and len(node.iter.args) == 1 and
            isinstance(node.iter.args[0], ast.Name)):
        return node.target.id, node.iter.args[0].id
    return None


def _match_affine(node, row, col):
    """Match `row_var * stride + col_var`; returns stride name or None."""
    if not (isinstance(node, ast.BinOp) and isinstance(node.op, ast.Add)):
        return None
    for mul, other in ((node.left, node.right), (node.right, node.left)):
        if (isinstance(mul, ast.BinOp) and isinstance(mul.op, ast.Mult) and
                isinstance(other, ast.Name) and other.id == col):
            f1, f2 = mul.left, mul.right
            for a, b in ((f1, f2), (f2, f1)):
                if (isinstance(a, ast.Name) and a.id == row and
                        isinstance(b, ast.Name)):
                    return b.id
    return None


def _match_prod(node, i, k, j):
    """Match A[i*?+k] * B[k*?+j]; returns (A, strideA, B, strideB) or None."""
    if not (isinstance(node, ast.BinOp) and isinstance(node.op, ast.Mult)):
        return None
    for lhs, rhs in ((node.left, node.right), (node.right, node.left)):
        if not (isinstance(lhs, ast.Subscript) and
                isinstance(rhs, ast.Subscript) and
                isinstance(lhs.value, ast.Name) and
                isinstance(rhs.value, ast.Name)):
            continue
        sA = _match_affine(lhs.slice, i, k)
        sB = _match_affine(rhs.slice, k, j)
        if sA and sB:
            return lhs.value.id, sA, rhs.value.id, sB
    return None


def match_matmul(fn):
    body = [s for s in fn.body
            if not (isinstance(s, ast.Expr) and
                    isinstance(s.value, ast.Constant))]  # strip docstring
    if len(body) != 1:
        return None
    m_i = _match_range1(body[0])
    if not m_i or len(body[0].body) != 1:
        return None
    i, M = m_i
    m_j = _match_range1(body[0].body[0])
    if not m_j:
        return None
    j, N = m_j
    jbody = body[0].body[0].body
    if len(jbody) != 3:
        return None
    init, loop, store = jbody

    # acc = 0
    if not (isinstance(init, ast.Assign) and len(init.targets) == 1 and
            isinstance(init.targets[0], ast.Name) and
            isinstance(init.value, ast.Constant) and init.value.value == 0):
        return None
    acc = init.targets[0].id

    # for k in range(K): acc += A[..]*B[..]
    m_k = _match_range1(loop)
    if not m_k or len(loop.body) != 1:
        return None
    k, K = m_k
    inner = loop.body[0]
    if isinstance(inner, ast.AugAssign) and isinstance(inner.op, ast.Add):
        if not (isinstance(inner.target, ast.Name) and
                inner.target.id == acc):
            return None
        prod = inner.value
    elif (isinstance(inner, ast.Assign) and len(inner.targets) == 1 and
          isinstance(inner.targets[0], ast.Name) and
          inner.targets[0].id == acc and
          isinstance(inner.value, ast.BinOp) and
          isinstance(inner.value.op, ast.Add)):
        l, r = inner.value.left, inner.value.right
        if isinstance(l, ast.Name) and l.id == acc:
            prod = r
        elif isinstance(r, ast.Name) and r.id == acc:
            prod = l
        else:
            return None
    else:
        return None

    m_p = _match_prod(prod, i, k, j)
    if not m_p:
        return None
    A, sA, B, sB = m_p
    if sA != K or sB != N:
        return None

    # C[i*N + j] = acc
    if not (isinstance(store, ast.Assign) and len(store.targets) == 1 and
            isinstance(store.targets[0], ast.Subscript) and
            isinstance(store.targets[0].value, ast.Name) and
            isinstance(store.value, ast.Name) and store.value.id == acc):
        return None
    C = store.targets[0].value.id
    if _match_affine(store.targets[0].slice, i, j) != N:
        return None

    return MatmulPattern(A, B, C, M, N, K)


def compile_tensor(fn, dtype):
    mm = match_matmul(fn)
    if mm is None:
        raise CompileError(
            "tensor backend: kernel does not match the canonical matmul "
            "triple loop (C[i*N+j] = sum_k A[i*K+k] * B[k*N+j])")

    params = [a.arg for a in fn.args.args]
    for name in (mm.A, mm.B, mm.C, mm.M, mm.N, mm.K):
        if name not in params:
            raise CompileError(f"matmul symbol '{name}' is not a kernel "
                               f"parameter")

    asm = Assembler()
    flags = WMMA_FLAG_FP8 if dtype == "fp8" else 0

    # parameter loads
    reg = {}
    free = list(R_POOL)
    for idx, name in enumerate(params):
        reg[name] = free.pop(0)
        asm.i("LOAD", reg[name], R_PARAM, 4 * idx)

    rA, rB, rC = reg[mm.A], reg[mm.B], reg[mm.C]
    rM, rN, rK = reg[mm.M], reg[mm.N], reg[mm.K]

    # WMMA element strides: lda = K, ldb = N, ldc = N
    asm.mov(R_LDA, rK)
    asm.mov(R_LDB, rN)
    asm.mov(R_LDC, rN)

    i0, j0, k0 = free.pop(0), free.pop(0), free.pop(0)
    t0, t1 = free.pop(0), free.pop(0)
    ap, bp, cp = free.pop(0), free.pop(0), free.pop(0)

    # for i0 in range(0, M, 16)
    asm.li(i0, 0)
    Li_top = asm.here(); Li_end = asm.new_label()
    asm.setp(CMP_GE, 1, i0, rM)
    asm.branch(Li_end, pred=1)

    #   for j0 in range(0, N, 16)
    asm.li(j0, 0)
    Lj_top = asm.here(); Lj_end = asm.new_label()
    asm.setp(CMP_GE, 1, j0, rN)
    asm.branch(Lj_end, pred=1)

    #     cp = C + 4*(i0*N + j0)   (32-bit accumulator tile)
    asm.r("MUL", t0, i0, rN)
    asm.r("ADD", t0, t0, j0)
    asm.i("SHL", t0, t0, 2)
    asm.r("ADD", cp, rC, t0)

    #     for k0 in range(0, K, 16)
    asm.li(k0, 0)
    Lk_top = asm.here(); Lk_end = asm.new_label()
    asm.setp(CMP_GE, 1, k0, rK)
    asm.branch(Lk_end, pred=1)

    #       ap = A + i0*K + k0 ; bp = B + k0*N + j0   (byte elements)
    asm.r("MUL", t0, i0, rK)
    asm.r("ADD", t0, t0, k0)
    asm.r("ADD", ap, rA, t0)
    asm.r("MUL", t1, k0, rN)
    asm.r("ADD", t1, t1, j0)
    asm.r("ADD", bp, rB, t1)

    #       C tile += A tile x B tile on the tensor core array
    asm.r("WMMA", cp, ap, bp, rs3=flags)

    asm.i("ADD", k0, k0, WMMA_TILE)
    asm.branch(Lk_top)
    asm.bind(Lk_end)

    asm.i("ADD", j0, j0, WMMA_TILE)
    asm.branch(Lj_top)
    asm.bind(Lj_end)

    asm.i("ADD", i0, i0, WMMA_TILE)
    asm.branch(Li_top)
    asm.bind(Li_end)

    asm.exit()
    return asm.finalize()


# ---------------------------------------------------------------------------
# TBIN container
# ---------------------------------------------------------------------------
def write_tbin(path, words, tensor):
    flags = TBIN_FLAG_TENSOR if tensor else 0
    with open(path, "wb") as f:
        f.write(struct.pack("<IIII", TBIN_MAGIC, TBIN_VERSION, flags,
                            len(words)))
        f.write(struct.pack(f"<{len(words)}I", *words))


def dump_listing(words, file=sys.stdout):
    for pc, w in enumerate(words):
        print(f"  {pc:4d}: {w:08X}  {disassemble(w)}", file=file)


# ---------------------------------------------------------------------------
# Reference ISA simulator (compiler self-test; the authoritative model is
# driver/titan_x6_gpu_model.c)
# ---------------------------------------------------------------------------
def fp8_to_float(b):
    s = -1.0 if b & 0x80 else 1.0
    e = (b >> 3) & 0xF
    m = b & 7
    if e == 0xF and m == 7:
        return float("nan")
    if e == 0:
        return s * (m / 8.0) * 2.0 ** -6
    return s * (1.0 + m / 8.0) * 2.0 ** (e - 7)


def float_to_fp8(f):
    import math
    s = 0x80 if (f < 0 or (f == 0 and math.copysign(1, f) < 0)) else 0
    a = abs(f)
    if math.isnan(f):
        return s | 0x7F
    a = min(a, 448.0)
    if a < 2.0 ** -9:
        return s
    e = math.floor(math.log2(a))
    if e < -6:
        m = round(a * 512.0)
        if m > 7:
            return s | (1 << 3)
        return s | m
    m = round((a / 2.0 ** e - 1.0) * 8.0)
    if m == 8:
        m = 0
        e += 1
    if e > 8 or (e == 8 and m == 7):
        e, m = 8, 6
    return s | ((e + 7) << 3) | m


def simulate(words, mem, param_addr, code_addr=None, max_steps=1 << 24):
    """Minimal Python twin of exec_thread() in titan_x6_gpu_model.c.
    `mem` is a bytearray (VRAM); code is taken from `words` directly."""
    import struct as _s
    r = [0] * 64
    p = [1, 0, 0, 0]
    r[R_PARAM] = param_addr
    pc = 0
    steps = 0

    def rd32(addr):
        return _s.unpack_from("<I", mem, addr)[0]

    def wr32(addr, v):
        _s.pack_into("<I", mem, addr, v & 0xFFFFFFFF)

    def s32(v):
        v &= 0xFFFFFFFF
        return v - (1 << 32) if v & (1 << 31) else v

    while True:
        steps += 1
        if steps > max_steps:
            raise RuntimeError("simulator watchdog expired")
        w = words[pc]
        op = (w >> 27) & 31
        rdst = (w >> 21) & 63
        rs1 = (w >> 15) & 63
        pred = (w >> 1) & 3
        uimm = w & 1
        imm = (w >> 3) & 0xFFF
        rs3 = (w >> 3) & 63
        b = imm if uimm else r[(w >> 9) & 63]
        a = r[rs1]
        nxt = pc + 1
        name = OP_NAMES[op]

        if p[pred]:
            if name == "ADD":
                r[rdst] = (a + b) & 0xFFFFFFFF
            elif name == "SUB":
                r[rdst] = (a - b) & 0xFFFFFFFF
            elif name == "MUL":
                r[rdst] = (s32(a) * s32(b)) & 0xFFFFFFFF
            elif name == "DIV":
                r[rdst] = (0xFFFFFFFF if s32(b) == 0 else
                           int(s32(a) / s32(b)) & 0xFFFFFFFF)
            elif name == "AND":
                r[rdst] = a & b
            elif name == "OR":
                r[rdst] = a | b
            elif name == "XOR":
                r[rdst] = a ^ b
            elif name == "SHL":
                r[rdst] = (a << (b & 31)) & 0xFFFFFFFF
            elif name == "SHR":
                r[rdst] = a >> (b & 31)
            elif name == "SRA":
                r[rdst] = (s32(a) >> (b & 31)) & 0xFFFFFFFF
            elif name == "SETP":
                cond, pdst = (rdst >> 2) & 7, rdst & 3
                res = [a == b, a != b, s32(a) < s32(b), s32(a) >= s32(b),
                       a < b, a >= b][cond]
                if pdst:
                    p[pdst] = 1 if res else 0
            elif name == "LOAD":
                r[rdst] = rd32(a + b)
            elif name == "STORE":
                wr32(a + b, r[rdst])
            elif name == "BRANCH":
                nxt = imm
            elif name == "BARRIER":
                if uimm and imm == EXIT_IMM:
                    return steps
            elif name == "WMMA":
                fp8 = rs3 & WMMA_FLAG_FP8
                ca, aa, ba = r[rdst], a, r[(w >> 9) & 63]
                lda, ldb, ldc = r[R_LDA], r[R_LDB], r[R_LDC]
                for rr in range(16):
                    for cc in range(16):
                        ea = ca + 4 * (rr * ldc + cc)
                        if fp8:
                            acc = _s.unpack_from("<f", mem, ea)[0]
                            for kk in range(16):
                                av = fp8_to_float(mem[aa + rr * lda + kk])
                                bv = fp8_to_float(mem[ba + kk * ldb + cc])
                                # float32-quantize each step like the HW
                                acc = _s.unpack("<f", _s.pack(
                                    "<f", acc + av * bv))[0]
                            _s.pack_into("<f", mem, ea, acc)
                        else:
                            def sb(x):
                                return x - 256 if x & 0x80 else x
                            acc = s32(rd32(ea))
                            for kk in range(16):
                                acc += (sb(mem[aa + rr * lda + kk]) *
                                        sb(mem[ba + kk * ldb + cc]))
                            wr32(ea, acc)
            else:
                raise RuntimeError(f"selftest sim: unimplemented op {name}")
        pc = nxt


# ---------------------------------------------------------------------------
# Self-test
# ---------------------------------------------------------------------------
MATMUL_SRC = '''
def matmul(A, B, C, M, N, K):
    """C[MxN] = A[MxK] @ B[KxN] (row-major, int32)"""
    for i in range(M):
        for j in range(N):
            acc = 0
            for k in range(K):
                acc = acc + A[i * K + k] * B[k * N + j]
            C[i * N + j] = acc
'''


def selftest():
    import random
    random.seed(0x71760006)
    failures = 0

    # 1. encode/decode round trip
    w = enc_i(OPS["LOAD"], 5, 1, 8)
    assert (w >> 27) == OPS["LOAD"] and ((w >> 21) & 63) == 5 and (w & 1) == 1
    print("[selftest] encoding round-trip: OK")

    # 2. scalar matmul on the reference simulator
    fn = parse_kernel(MATMUL_SRC)
    words = ScalarCodegen(fn).compile()
    M = N = K = 8
    mem = bytearray(1 << 16)
    base_a, base_b, base_c, base_p = 0x1000, 0x2000, 0x3000, 0x4000
    A = [random.randrange(-50, 50) for _ in range(M * K)]
    B = [random.randrange(-50, 50) for _ in range(K * N)]
    for i, v in enumerate(A):
        struct.pack_into("<i", mem, base_a + 4 * i, v)
    for i, v in enumerate(B):
        struct.pack_into("<i", mem, base_b + 4 * i, v)
    struct.pack_into("<6I", mem, base_p, base_a, base_b, base_c, M, N, K)
    steps = simulate(words, mem, base_p)
    ok = True
    for i in range(M):
        for j in range(N):
            ref = sum(A[i * K + k] * B[k * N + j] for k in range(K))
            got = struct.unpack_from("<i", mem, base_c + 4 * (i * N + j))[0]
            if ref != got:
                ok = False
    print(f"[selftest] scalar matmul {M}x{N}x{K} "
          f"({len(words)} instrs, {steps} steps): {'OK' if ok else 'FAIL'}")
    failures += not ok

    # 3. tensor matmul (INT8 WMMA) on the reference simulator
    words = compile_tensor(fn, "int8")
    M = N = K = 32
    mem = bytearray(1 << 16)
    A = [random.randrange(-8, 8) for _ in range(M * K)]
    B = [random.randrange(-8, 8) for _ in range(K * N)]
    for i, v in enumerate(A):
        mem[base_a + i] = v & 0xFF
    for i, v in enumerate(B):
        mem[base_b + i] = v & 0xFF
    struct.pack_into("<6I", mem, base_p, base_a, base_b, base_c, M, N, K)
    steps = simulate(words, mem, base_p)
    ok = True
    for i in range(M):
        for j in range(N):
            ref = sum(A[i * K + k] * B[k * N + j] for k in range(K))
            got = struct.unpack_from("<i", mem, base_c + 4 * (i * N + j))[0]
            if ref != got:
                ok = False
    print(f"[selftest] WMMA INT8 matmul {M}x{N}x{K} "
          f"({len(words)} instrs, {steps} steps): {'OK' if ok else 'FAIL'}")
    failures += not ok

    # 4. fp8 conversion sanity
    for v in (0.0, 1.0, -1.5, 0.0625, 448.0, 3.25):
        rt = fp8_to_float(float_to_fp8(v))
        if abs(rt - v) > max(abs(v) * 0.0626, 1e-3):
            print(f"[selftest] fp8 round-trip {v} -> {rt}: FAIL")
            failures += 1
    print("[selftest] fp8 E4M3 round-trip: OK" if not failures else "")

    return failures


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def main():
    ap = argparse.ArgumentParser(
        description="Titan Compute Compiler: Python kernel -> Titan X6 ISA")
    ap.add_argument("input", nargs="?", help="kernel source (.py)")
    ap.add_argument("-o", "--output", help="output .tbin path")
    ap.add_argument("-f", "--function", help="kernel function name")
    ap.add_argument("--backend", choices=["scalar", "tensor"],
                    default="scalar")
    ap.add_argument("--dtype", choices=["int8", "fp8"], default="int8",
                    help="tensor-core element type (tensor backend)")
    ap.add_argument("--dump", action="store_true",
                    help="print disassembly listing")
    ap.add_argument("--selftest", action="store_true")
    args = ap.parse_args()

    if args.selftest:
        sys.exit(1 if selftest() else 0)

    if not args.input or not args.output:
        ap.error("input and -o are required (or use --selftest)")

    with open(args.input, "r", encoding="utf-8") as f:
        source = f.read()

    try:
        fn = parse_kernel(source, args.function)
        if args.backend == "tensor":
            words = compile_tensor(fn, args.dtype)
        else:
            words = ScalarCodegen(fn).compile()
    except CompileError as e:
        print(f"titan_compiler: error: {e}", file=sys.stderr)
        sys.exit(1)

    write_tbin(args.output, words, tensor=(args.backend == "tensor"))
    print(f"[tcc] {args.input}:{fn.name} -> {args.output} "
          f"[{args.backend}{'/' + args.dtype if args.backend == 'tensor' else ''}] "
          f"{len(words)} instructions ({len(words) * 4} bytes)")
    if args.dump:
        dump_listing(words)


if __name__ == "__main__":
    main()
