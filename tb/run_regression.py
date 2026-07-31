# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Titan X5-B verification regression (cocotb + Icarus, no make required).

Usage:
    python run_regression.py            # everything
    python run_regression.py lsu mesi   # selected suites

Suites:
    lsu      - memory-coalescing LSU (optimality, byte enables, lane data)
    fpu      - IEEE-754 FP32 add/mul + FP16 mul + ALU FP pipeline integration
    mesi     - MESI coherency across the coherent crossbar (4 x L1)
    tmu      - bilinear texture filtering (3 formats, wrap/clamp)
    rt_isect - pipelined Möller-Trumbore ray-triangle unit (II=1, bit-exact)
    rt_box   - pipelined ray-AABB slab test unit (II=1, bit-exact)
    rt_core  - multi-ray BVH traversal engine over random scenes
    tensor   - 16x16 output-stationary tensor array via the warp-sync
               WMMA dispatcher (INT8 SIMD, FP8 E4M3/E5M2, FP16)
    pc_unit  - per-warp program counter file: sequencing, absolute-index
               branches, backward loops, EXIT retire, same-cycle priority
    regfile  - per-warp vector register file: two warps holding different
               values in the same register number, cross-warp isolation
    compute  - compiled kernels executed on the whole GPU (pytest, quick
               subset only; see tb/test_compute_kernels.py for the rest)
"""

import os
import sys

from cocotb_tools.runner import get_runner

TB = os.path.abspath(os.path.dirname(__file__))
RTL = os.path.abspath(os.path.join(TB, "..", "rtl"))


def rtl_files(*rel):
    return [os.path.join(RTL, r) for r in rel]


SUITES = {
    "lsu": dict(
        sources=rtl_files("memory/titan_x5_lsu.v"),
        toplevel="titan_x5_lsu",
        module="test_lsu",
    ),
    "fpu": dict(
        sources=[os.path.join(TB, "tb_fpu_top.v")] + rtl_files(
            "fpu/titan_x5_fp32_add.v",
            "fpu/titan_x5_fp32_mul.v",
            "fpu/titan_x5_fp32_fma.v",
            "tensor/titan_x5_fp16_mul.v",
            "tensor/titan_x6_tensor_core_array.v",
            "core/titan_x5_alu.v",
        ),
        toplevel="tb_fpu_top",
        module="test_fpu",
    ),
    "mesi": dict(
        sources=[os.path.join(TB, "tb_mesi_top.v")] + rtl_files(
            "memory/titan_x5_l1_cache.v",
            "interconnect/titan_x5_crossbar.v",
        ),
        toplevel="tb_mesi_top",
        module="test_mesi",
    ),
    "tmu": dict(
        sources=rtl_files(
            "graphics/titan_x5_tmu.v",
            "memory/titan_x5_l1_cache.v",
        ),
        toplevel="titan_x5_tmu",
        module="test_tmu",
    ),
    "rt_isect": dict(
        sources=rtl_files("raytracing/titan_x5_ray_triangle_isect.v"),
        toplevel="titan_x5_ray_triangle_isect",
        module="test_rt_isect",
    ),
    "rt_box": dict(
        sources=rtl_files("raytracing/titan_x5_ray_box_isect.v"),
        toplevel="titan_x5_ray_box_isect",
        module="test_rt_box",
    ),
    "rt_core": dict(
        sources=rtl_files(
            "raytracing/titan_x5_ray_triangle_isect.v",
            "raytracing/titan_x5_ray_box_isect.v",
            "raytracing/titan_x5_rt_core.v",
        ),
        toplevel="titan_x5_rt_core",
        module="test_rt_core",
    ),
    "tensor": dict(
        sources=rtl_files(
            "tensor/titan_x5_fp16_mul.v",
            "tensor/titan_x6_tensor_core_array.v",
            "tensor/titan_x6_wmma_dispatch.v",
        ),
        toplevel="titan_x6_wmma_dispatch",
        module="test_tensor",
    ),
    "noc": dict(
        sources=rtl_files(
            "interconnect/titan_x6_noc_router.v",
            "interconnect/titan_x6_noc_mesh.v",
        ),
        toplevel="titan_x6_noc_mesh",
        module="test_noc",
    ),
    "vram": dict(
        sources=[os.path.join(TB, "tb_vram_top.v")] + rtl_files(
            "titan_x6_vram_ctrl.v",
        ),
        toplevel="tb_vram_top",
        module="test_vram",
    ),
    "l2": dict(
        sources=[os.path.join(TB, "tb_l2_top.v")] + rtl_files(
            "titan_x6_banked_l2.v",
            "memory/titan_x5_l2_cache.v",
            "common/titan_x5_skid_buffer.v",
        ),
        toplevel="tb_l2_top",
        module="test_l2",
    ),
    "alu_isa": dict(
        sources=[os.path.join(TB, "tb_fpu_top.v")] + rtl_files(
            "core/titan_x5_alu.v",
            "fpu/titan_x5_fp32_add.v",
            "fpu/titan_x5_fp32_mul.v",
            "fpu/titan_x5_fp32_fma.v",
            "tensor/titan_x5_fp16_mul.v",
            "tensor/titan_x6_tensor_core_array.v",
        ),
        toplevel="tb_fpu_top",
        module="test_alu_isa",
    ),
    "pc_unit": dict(
        sources=[os.path.join(TB, "tb_pc_unit_top.v")] + rtl_files(
            "core/titan_x5_pc_unit.v",
        ),
        toplevel="tb_pc_unit_top",
        module="test_pc_unit",
    ),
    # Built with the exact geometry titan_x5_sm instantiates, so the suite
    # exercises the configuration that actually ships rather than a
    # convenient small one.
    "regfile": dict(
        sources=rtl_files("core/titan_x5_register_file.v"),
        toplevel="titan_x5_register_file",
        module="test_regfile_warps",
        parameters={
            "DATA_WIDTH": 1024,
            "NUM_REGS": 64,
            "NUM_BANKS": 4,
            "NUM_WARPS": 8,
        },
    ),
    # Same DUT and same test at both memory-path beat widths. 32 bits is the
    # current design (32 beats per 128-byte line); 512 bits is the wide path
    # (2 beats). Running both proves the module is genuinely width-generic.
    "l2adapt32": dict(
        sources=[os.path.join(TB, "tb_l2_adapter_top.v")] + rtl_files(
            "memory/titan_x5_l2_mem_adapter.v",
        ),
        toplevel="tb_l2_adapter_top",
        module="test_l2_adapter",
        parameters={"DW": 32},
    ),
    "l2adapt512": dict(
        sources=[os.path.join(TB, "tb_l2_adapter_top.v")] + rtl_files(
            "memory/titan_x5_l2_mem_adapter.v",
        ),
        toplevel="tb_l2_adapter_top",
        module="test_l2_adapter",
        parameters={"DW": 512},
    ),
    "l2adapt1024": dict(
        sources=[os.path.join(TB, "tb_l2_adapter_top.v")] + rtl_files(
            "memory/titan_x5_l2_mem_adapter.v",
        ),
        toplevel="tb_l2_adapter_top",
        module="test_l2_adapter",
        parameters={"DW": 1024},
    ),
    # Beyond 1024 bits a 128-byte line has nothing left to widen: WORDS would
    # be 0. Going wider requires a wider LINE too, so this pairs a 2048-bit
    # beat with a 256-byte line -- still one beat per line, twice the payload.
    "l2adapt2048": dict(
        sources=[os.path.join(TB, "tb_l2_adapter_top.v")] + rtl_files(
            "memory/titan_x5_l2_mem_adapter.v",
        ),
        toplevel="tb_l2_adapter_top",
        module="test_l2_adapter",
        parameters={"DW": 2048, "LINE_BYTES": 256},
    ),
    # Flush must run in its own simulation: see the module docstring.
    "flush": dict(
        sources=[os.path.join(TB, "tb_mesi_top.v")] + rtl_files(
            "memory/titan_x5_l1_cache.v",
            "interconnect/titan_x5_crossbar.v",
        ),
        toplevel="tb_mesi_top",
        module="test_mesi_flush",
    ),
    # ---- Titan X7: the high-frequency generation ------------------------
    # These target a short-stage, advanced-node budget rather than the x5
    # blocks' single-cycle-everything structure. See
    # docs/PLAN_ADVANCED_NODE_CLEAN_SHEET.md for why each exists.
    "fma8": dict(
        sources=[os.path.join(TB, "tb_fma_x7.v")] + rtl_files(
            "fpu/titan_x5_fp32_fma.v",
            "common/titan_x7_prefix_add.v",
            "common/titan_x7_lzc.v",
            "fpu/titan_x7_fp32_fma_pipe.v",
        ),
        toplevel="tb_fma_x7",
        module="test_fma_x7",
    ),
    "tensor7": dict(
        sources=rtl_files(
            "common/titan_x7_prefix_add.v",
            "common/titan_x7_lzc.v",
            "tensor/titan_x7_tensor_pe.v",
            "tensor/titan_x7_tensor_array.v",
        ),
        toplevel="titan_x7_tensor_array",
        module="test_tensor_x7",
    ),
    "rfbank": dict(
        sources=rtl_files(
            "memory/titan_x7_sram_1r1w.v",
            "core/titan_x7_regfile_banked.v",
        ),
        toplevel="titan_x7_regfile_banked",
        module="test_regfile_banked",
    ),
    "sm7": dict(
        sources=rtl_files(
            "core/titan_x5_decoder.v",
            "core/titan_x7_scoreboard.v",
            "core/titan_x7_branch_predictor.v",
            "core/titan_x7_warp_scheduler.v",
            "common/titan_x7_prefix_add.v",
            "common/titan_x7_lzc.v",
            "fpu/titan_x7_fp32_fma_pipe.v",
            "core/titan_x7_sm.v",
        ),
        toplevel="titan_x7_sm",
        module="test_sm_x7",
        parameters={"LANES": 4},
    ),
    # Cross-warp independence. Separate module from sm7 because that suite's
    # imem/dmem models run for the whole simulation; see the docstring.
    "sm7warp": dict(
        sources=rtl_files(
            "core/titan_x5_decoder.v",
            "core/titan_x7_scoreboard.v",
            "core/titan_x7_branch_predictor.v",
            "core/titan_x7_warp_scheduler.v",
            "common/titan_x7_prefix_add.v",
            "common/titan_x7_lzc.v",
            "fpu/titan_x7_fp32_fma_pipe.v",
            "core/titan_x7_sm.v",
        ),
        toplevel="titan_x7_sm",
        module="test_sm_x7_warps",
        parameters={"LANES": 4},
    ),
    "apexlane": dict(
        sources=[os.path.join(TB, "..", "syn", "gt2n", "iso_miter.v")] + rtl_files(
            "common/titan_x7_prefix_add.v",
            "common/titan_x7_lzc.v",
            "fpu/titan_x7_fp32_fma_pipe.v",
            "fpu/titan_apex_fma_lane.v",
        ),
        toplevel="iso_miter",
        module="test_apex_lane",
    ),
    # TITAN APEX-X: precision-scalable multiplier core (1x24x24 / 4x12x12 /
    # 16x6x6). Purely combinational, so it simulates fast despite the size.
    "multseg": dict(
        sources=rtl_files("tensor/titan_apex_mult_seg.v"),
        toplevel="titan_apex_mult_seg",
        module="test_mult_seg",
    ),
    "dpmac": dict(
        sources=rtl_files(
            "tensor/titan_apex_mult_seg.v",
            "tensor/titan_apex_dp_mac.v",
        ),
        toplevel="titan_apex_dp_mac",
        module="test_dp_mac",
    ),
    # Not a cocotb suite: pytest driving whole-GPU kernel runs. Handled by
    # run_compute_suite(); the dict entry exists so it appears in the suite
    # list and runs by default.
    "compute": dict(pytest=True),
}


class SuiteInfraError(RuntimeError):
    """The suite never produced a verdict.

    Distinct from a test failure: this means the simulation did not run to
    completion (missing tool, failed import, crashed elaboration). Reporting
    it as FAIL makes a broken environment look identical to a design
    regression, which previously hid the lsu/fpu/mesi/tmu suites entirely
    when cocotb-coverage was not installed.
    """


def check_results(xml_path):
    """Hard gate: the results file must exist, contain at least one test,
    and report zero failures/errors (a crashed sim must not pass)."""
    import xml.etree.ElementTree as ET
    if not os.path.exists(xml_path):
        raise SuiteInfraError(f"no results file produced ({xml_path})")
    root = ET.parse(xml_path).getroot()
    cases = root.iter("testcase")
    n, bad = 0, 0
    for tc in cases:
        n += 1
        if tc.find("failure") is not None or tc.find("error") is not None:
            bad += 1
    if n == 0:
        raise SuiteInfraError("results file contains no testcases")
    if bad:
        raise RuntimeError(f"{bad}/{n} testcases failed")
    print(f"    results: {n} testcase(s), all passed")


def run_compute_suite():
    """Compiled kernels on the whole GPU (pytest, not cocotb).

    Only the `not slow` subset runs here: these are full-chip Icarus
    simulations and the design does roughly 90 clock cycles per wall second,
    so the counted loops, the SETP condition sweep and matmul are left to an
    explicit `pytest tb/test_compute_kernels.py`. Running the quick ones by
    default is what stops the compiler -> ISA -> RTL path from rotting
    unnoticed.
    """
    import subprocess
    print("\n=== [compute] building & running ===", flush=True)
    proc = subprocess.run(
        [sys.executable, "-m", "pytest", os.path.join(TB, "test_compute_kernels.py"),
         "-q", "-m", "not slow", "-p", "no:cacheprovider"],
        cwd=TB)
    if proc.returncode != 0:
        raise RuntimeError(f"pytest exited {proc.returncode}")
    print("    results: quick compute kernels passed")


def run_suite(name, cfg):
    if name == "compute":
        return run_compute_suite()
    print(f"\n=== [{name}] building & running ===", flush=True)
    runner = get_runner("icarus")
    build_dir = os.path.join(TB, "sim_build", name)
    test_dir = os.path.join(TB, "uvm")
    results = f"{name}_results.xml"
    results_path = os.path.join(test_dir, results)
    if os.path.exists(results_path):
        os.remove(results_path)
    runner.build(
        verilog_sources=cfg["sources"],
        hdl_toplevel=cfg["toplevel"],
        # TITAN_FAST_SIM selects the behavioural form of titan_x7_prefix_add
        # and titan_x7_lzc. Both are SAT-proven identical to the structural
        # versions, and the structural ones cost ~250x simulation time (fma8
        # 2.3 s -> >10 min, tensor7 -> 3.56 h). Synthesis never defines it:
        # syn/gt2n/run_gt2n.sh builds the structural RTL, which is what the
        # 2 nm timing numbers are measured on.
        build_args=["-g2012", "-DTITAN_FAST_SIM"],
        build_dir=build_dir,
        always=True,
        parameters=cfg.get("parameters", {}),
    )
    runner.test(
        hdl_toplevel=cfg["toplevel"],
        test_module=cfg["module"],
        build_dir=build_dir,
        test_dir=test_dir,
        results_xml=results,
    )
    check_results(results_path)


def main():
    wanted = [a.lower() for a in sys.argv[1:]] or list(SUITES)
    unknown = [w for w in wanted if w not in SUITES]
    if unknown:
        print(f"unknown suite(s): {unknown}; available: {list(SUITES)}")
        return 2
    failures = []
    infra_errors = []
    for name in wanted:
        try:
            run_suite(name, SUITES[name])
        except SuiteInfraError as exc:
            # the suite produced no verdict at all - environment problem
            print(f"[{name}] ERROR (suite did not run): {exc}")
            infra_errors.append(name)
        except Exception as exc:  # runner raises on any test failure
            print(f"[{name}] FAILED: {exc}")
            failures.append(name)
    print("\n=== regression summary ===")
    for name in wanted:
        if name in infra_errors:
            verdict = "ERROR"
        elif name in failures:
            verdict = "FAIL"
        else:
            verdict = "PASS"
        print(f"  {name:6s} : {verdict}")
    if infra_errors:
        print(f"\n{len(infra_errors)} suite(s) never ran: {infra_errors}")
        print("This is an ENVIRONMENT problem, not a design regression.")
        print("Check the toolchain: pip install -r tb/requirements.txt")
    return 1 if (failures or infra_errors) else 0


if __name__ == "__main__":
    sys.exit(main())
