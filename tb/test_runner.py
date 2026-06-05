import os
from cocotb_test.simulator import run

def test_graphics():
    run(
        verilog_sources=[
            "cocotb_graphics_top.v",
            "../rtl/graphics/titan_x5_rasterizer.v",
            "../rtl/sr/titan_x5_sr_engine.v",
            "../rtl/sr/titan_x5_hash_fnv64.v",
            "../rtl/titan_x5_apex_sr_engine.v",
            "../rtl/common/titan_x5_skid_buffer.v"
        ],
        toplevel="cocotb_graphics_top",
        module="test_graphics_pipeline",
        simulator="icarus"
    )

def test_alu():
    run(
        verilog_sources=[
            "../rtl/core/titan_x5_alu.v"
        ],
        toplevel="titan_x5_alu",
        module="test_alu",
        simulator="icarus"
    )

import glob

def test_system():
    # Gather all rtl sources for the system test
    rtl_files = glob.glob("../rtl/**/*.v", recursive=True) + glob.glob("../rtl/*.v")
    # exclude duplicate files if any
    rtl_files = list(set(rtl_files))
    
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
