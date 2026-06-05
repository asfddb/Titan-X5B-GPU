TOPLEVEL_LANG = verilog

VERILOG_SOURCES = $(PWD)/cocotb_graphics_top.v \
                  $(PWD)/../rtl/graphics/titan_x5_rasterizer.v \
                  $(PWD)/../rtl/sr/titan_x5_sr_engine.v \
                  $(PWD)/../rtl/sr/titan_x5_hash_fnv64.v \
                  $(PWD)/../rtl/titan_x5_apex_sr_engine.v \
                  $(PWD)/../rtl/common/titan_x5_skid_buffer.v

TOPLEVEL = cocotb_graphics_top
MODULE = test_graphics_pipeline

include $(shell cocotb-config --makefiles)/Makefile.sim
