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
}


def check_results(xml_path):
    """Hard gate: the results file must exist, contain at least one test,
    and report zero failures/errors (a crashed sim must not pass)."""
    import xml.etree.ElementTree as ET
    if not os.path.exists(xml_path):
        raise RuntimeError(f"no results file produced ({xml_path})")
    root = ET.parse(xml_path).getroot()
    cases = root.iter("testcase")
    n, bad = 0, 0
    for tc in cases:
        n += 1
        if tc.find("failure") is not None or tc.find("error") is not None:
            bad += 1
    if n == 0:
        raise RuntimeError("results file contains no testcases")
    if bad:
        raise RuntimeError(f"{bad}/{n} testcases failed")
    print(f"    results: {n} testcase(s), all passed")


def run_suite(name, cfg):
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
        build_args=["-g2012"],
        build_dir=build_dir,
        always=True,
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
    for name in wanted:
        try:
            run_suite(name, SUITES[name])
        except Exception as exc:  # runner raises on any test failure
            print(f"[{name}] FAILED: {exc}")
            failures.append(name)
    print("\n=== regression summary ===")
    for name in wanted:
        print(f"  {name:6s} : {'FAIL' if name in failures else 'PASS'}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
