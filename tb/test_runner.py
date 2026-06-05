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
