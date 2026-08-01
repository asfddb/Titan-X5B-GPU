# titan_x7_sm vs the Titan ISA — three divergences found before integration

*Written 2026-08-01, while starting priority 1 of
`docs/HANDOFF_NEXT_SESSION.md`: wiring `titan_x7_sm` into `titan_x5_gpu_top`.*

---

## The short version

`titan_x7_sm` did not implement the ISA the rest of the project runs on. It
was developed standalone against its own test suite, and its tests encoded
its own interpretation, so every suite passed while the core disagreed with
the compiler, the functional model and the working chip on three points.

None of this was visible from the port list, which is what the handoff's
gap list was built from. It only appears when you compare the *semantics*
against `driver/titan_x6_isa.h`.

**All three are fixed and mutation-tested. None of the fixes changed any
other suite: the regression is unchanged at 31/31.**

---

## 1. BRANCH computed a PC-relative target

The ISA header states it outright:

```c
TX6_OP_BRANCH   = 24,  // pc = imm (absolute instr index); honors pred
```

Every component agrees with that header:

| Component | Target |
|:--|:--|
| `compiler/titan_compiler.py` | `words[idx] \|= (lbl.pc & 0xFFF) << 3` — absolute index |
| `driver/titan_x6_gpu_model.c` | `next_pc = imm` — absolute index |
| `rtl/core/titan_x5_pipeline.v` | `pc_redirect_pc = {16'd0, dec_imm}` — absolute index |
| **`rtl/core/titan_x7_sm.v`** | **`xi_pc + sext(imm12) << 2` — PC-relative bytes** |

PCs are bytes inside X7, so the fix is `tgt = {18'd0, xi_imm[11:0], 2'b00}`.

Consequence had it shipped: every compiled kernel branches to the wrong
address the moment it is run on X7. The bit-exact matmul, the counted-loop
tests and the render test all depend on this.

A note on range: an absolute 12-bit index caps a program at instruction
4095 (byte 16380). X7's own warp tests placed programs 0x1000 bytes apart,
which does not fit; they are now packed 0x100 apart.

## 2. Opcode 15 was treated as fp32 FMA

```c
TX6_OP_FMA  = 15,  // rd = rs1 * rs2 + rs3 (integer)
TX6_OP_FFMA = 29,  // fp32 fused multiply-add
```

`titan_x5_alu.v` matches the header — `OP_IFMA = 5'd15`, `OP_FPFMA = 5'd29`.

X7 routed opcode 15 into its 8-stage FP32 FMA pipe and never implemented
integer FMA at all. Fixed: opcode 15 is now `rs1*rs2 + rs3` on 32-bit
integers in the INT pipe's X2 stage (which required carrying `rs3` down the
INT pipe — the `x1_c` register is new).

## 3. Opcode 29 executed an RSQRT seed

X7's INT ALU had:

```verilog
5'd29: int_alu1 = 32'h5F3759DF - (a >> 1);    // RSQRT seed
```

RSQRT is **not in this ISA**. It was displaced when FP FMA was given slot 29
— the decision is recorded in `docs/HANDOFF_NEXT_SESSION.md` §4b, and the
reason it was safe is that RSQRT "was assigned in the header and implemented
in the C functional model but *never built in hardware*". X7 then built the
thing that does not exist, on the slot that now belongs to FP FMA.

Fixed: 29 is FFMA and runs in the FP pipe. The RSQRT case is gone.

---

## Why the existing suites did not catch any of it

The same shape of hole this project keeps finding, and the same lesson:

- `test_sm_x7.py` defined its own opcode map with `RSQRT=29`, and encoded
  the fp32 FMA test as `FMA` (15). The test asserted a float result from
  opcode 15 — so it was **verifying the divergence**, not the ISA.
- Branch tests used relative offsets (`imm=(-1) & 0xFFF`), which are
  self-consistent with X7's implementation and meaningless against the ISA.

A test written from the same misunderstanding as the RTL cannot detect the
misunderstanding. The guard that would have caught all three is the one x5
already has: `compiler/test_compiler_isa.py` parses the ALU's opcode
localparams and asserts they match the header. **X7 has no equivalent, and
should get one** — that is the highest-value verification work left on this
module.

## Mutations run

Each fix was reverted in place and the suites re-run to confirm they fail:

| Mutation | Result |
|:--|:--|
| BRANCH back to `xi_pc + sext(imm)<<2` | **caught** — 3 tests fail across `sm7` and `sm7warp` |
| `is_fp_op` back to {15,16,17} | **caught** — `ffma-fp32` reads `0x00000000`, expected `0x41700000` |
| EXIT decoded as any BARRIER | **caught** — `plain BARRIER must never pulse warp_exit_valid` |
| `all_retired` = `\|warp_retired` | **caught** — asserts on the first retiree, not the last |
| drop the relaunch clear of `warp_retired` | **caught** — `all_retired` stays latched |

---

## One test defect found on the way, worth keeping

`sm_x7_control_flow_is_per_warp` failed after the programs were packed
closer together, and the cause was not the RTL. The test's programs had **no
`EXIT`**, so each warp ran off the end, walked through the NOP padding and
fell into the *next warp's* program. Warp 3 finished its own loop correctly
(`r11=12`) and was then overwritten by warp 4's `ADD r10, r0, 5` — which is
why `r10` read 5, a value warp 3's own program never writes.

The old 0x1000 spacing only hid this behind 1024 NOPs of padding that 600
cycles never crossed. Every program in these suites now ends in `EXIT`.

Generalisation, consistent with the rest of this project's findings: **a
test whose threads never terminate is timing-dependent, and it will start
failing for reasons that have nothing to do with what it claims to test.**

## A theory that was wrong, recorded because it cost time

The first diagnosis of that failure was epoch aliasing: `epoch` is 1 bit,
stale ibuf entries drain one per cycle, so two mispredicts close together
could flip the epoch back and resurrect entries the first flush should have
killed. A fix was written (clear the warp's instruction buffer outright on a
mispredict).

**It changed nothing — the failing run was byte-identical, same sim time,
same wrong value.** The fix was reverted rather than kept, because it could
not be control-experimented: there is no test that demonstrates it fixing
anything.

Whether the 1-bit epoch is *actually* exploitable in X7 is **unknown and
unmeasured**. `docs/HANDOFF_NEXT_SESSION.md` flags the same hazard for
`titan_x5_pipeline` ("the wrong-path epoch is 1 bit and is only sound
because a single fetch is outstanding — widening fetch requires widening the
epoch"). X7 *does* have multiple outstanding fetches, so the concern is
plausible; it is simply not demonstrated, and an undemonstrated fix is not
worth carrying.

---

## What this means for the integration

Priority 1 in the handoff lists the gaps as ports: retire, I-cache adapter,
LSU/L1, lane count, shader export. That list is accurate but incomplete —
it describes the *plumbing*, and X7 also disagreed with the ISA on the
*semantics*. Wiring it in first and debugging at full-chip level would have
been painful: the design simulates at roughly 90 clock cycles per wall
second, so a branch going to the wrong address shows up as a render test
that produces the wrong picture after minutes of simulation.

Recommended order, revised:

1. ~~Warp exit / `all_retired`~~ — done.
2. ~~ISA conformance of BRANCH / FMA / FFMA~~ — done, this document.
3. **An X7 equivalent of `compiler/test_compiler_isa.py`** — a static check
   that X7's opcode handling matches `driver/titan_x6_isa.h`, plus a
   differential suite against `driver/titan_x6_gpu_model.c` in the style of
   `tb/uvm/test_alu_isa.py`. Three divergences were found by reading; there
   is no reason to believe reading found all of them.
4. Then the plumbing: I-cache pair-fetch adapter, LSU + L1, `LANES` 8 -> 32,
   shader export, and the top-level swap.
