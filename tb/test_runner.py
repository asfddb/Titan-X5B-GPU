# ============================================================================
# Copyright (c) 2026 Adhiraj
# 
# This file is part of the Titan X5-B GPU project.
# 
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
import os
from cocotb_test.simulator import run
# Coverage removed

def test_graphics():
    base_dir = os.path.dirname(__file__)
    run(
        verilog_sources=[
            os.path.join(base_dir, "cocotb_graphics_top.v"),
            os.path.join(base_dir, "..", "rtl", "graphics", "titan_x5_rasterizer.v"),
            os.path.join(base_dir, "..", "rtl", "sr", "titan_x5_sr_engine.v"),
            os.path.join(base_dir, "..", "rtl", "sr", "titan_x5_hash_fnv64.v"),
            os.path.join(base_dir, "..", "rtl", "titan_x5_apex_sr_engine.v"),
            os.path.join(base_dir, "..", "rtl", "common", "titan_x5_skid_buffer.v")
        ],
        toplevel="cocotb_graphics_top",
        module="test_graphics_pipeline",
        simulator="icarus"
    )

import glob

def test_alu():
    base_dir = os.path.dirname(__file__)
    rtl_dir = os.path.join(base_dir, "..", "rtl")
    rtl_files = glob.glob(os.path.join(rtl_dir, "**", "*.v"), recursive=True) + glob.glob(os.path.join(rtl_dir, "*.v"))
    rtl_files = list(set([os.path.abspath(f) for f in rtl_files]))
    
    run(
        verilog_sources=rtl_files,
        toplevel="titan_x5_alu",
        module="test_alu",
        simulator="icarus"
    )

def test_alu_uvm():
    base_dir = os.path.dirname(__file__)
    rtl_dir = os.path.join(base_dir, "..", "rtl")
    rtl_files = glob.glob(os.path.join(rtl_dir, "**", "*.v"), recursive=True) + glob.glob(os.path.join(rtl_dir, "*.v"))
    rtl_files = list(set([os.path.abspath(f) for f in rtl_files]))
    
    run(
        verilog_sources=rtl_files,
        toplevel="titan_x5_alu",
        module="uvm.test_alu_uvm",
        simulator="icarus"
    )

import glob

def test_system():
    # Gather all rtl sources for the system test
    base_dir = os.path.dirname(__file__)
    rtl_dir = os.path.join(base_dir, "..", "rtl")
    rtl_files = glob.glob(os.path.join(rtl_dir, "**", "*.v"), recursive=True) + glob.glob(os.path.join(rtl_dir, "*.v"))
    # exclude duplicate files if any
    rtl_files = list(set([os.path.abspath(f) for f in rtl_files]))
    
    run(
        verilog_sources=rtl_files,
        toplevel="titan_x5_gpu_top",
        module="test_system",
        simulator="icarus",
        parameters={
            "VGA_H_VISIBLE": "32",
            "VGA_V_VISIBLE": "32"
        }
    )
