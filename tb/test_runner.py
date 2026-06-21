import os
from cocotb_test.simulator import run
from cocotb_coverage import coverage_report, coverage_model

# Define coverage items
cov_alu_opcode = coverage_model.CoverItem("ALU_OPCODE",
    values=list(range(13)),  # opcodes 0-12
    at_least=1)

cov_alu_operand = coverage_model.CoverItem("ALU_OPERAND_BOUNDARY",
    values=["MIN_INT", "MAX_INT", "ZERO", "NEG_ONE"],
    at_least=1)

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

def test_alu():
    base_dir = os.path.dirname(__file__)
    run(
        verilog_sources=[
            os.path.join(base_dir, "..", "rtl", "core", "titan_x5_alu.v")
        ],
        toplevel="titan_x5_alu",
        module="test_alu",
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
