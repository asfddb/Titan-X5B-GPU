TOPLEVEL_LANG = verilog

TEST_TARGET ?= graphics

ifeq ($(TEST_TARGET), graphics)
VERILOG_SOURCES = $(PWD)/cocotb_graphics_top.v \
                  $(PWD)/../rtl/graphics/titan_x5_rasterizer.v \
                  $(PWD)/../rtl/sr/titan_x5_sr_engine.v \
                  $(PWD)/../rtl/sr/titan_x5_hash_fnv64.v \
                  $(PWD)/../rtl/titan_x5_apex_sr_engine.v \
                  $(PWD)/../rtl/common/titan_x5_skid_buffer.v
TOPLEVEL = cocotb_graphics_top
MODULE = test_graphics_pipeline
endif

ifeq ($(TEST_TARGET), alu)
VERILOG_SOURCES = $(PWD)/../rtl/core/titan_x5_alu.v
TOPLEVEL = titan_x5_alu
MODULE = test_alu
endif

ifeq ($(TEST_TARGET), cache)
VERILOG_SOURCES = $(PWD)/../rtl/memory/titan_x5_l1_cache.v
TOPLEVEL = titan_x5_l1_cache
MODULE = test_cache
endif

include $(shell cocotb-config --makefiles)/Makefile.sim

sim_top:
	iverilog -g2012 -I../rtl -o sim_top.vvp tb_titan_x5_gpu_top.v ../rtl/*/*.v ../rtl/*.v
	vvp sim_top.vvp
	python generate_waveform_proof.py
