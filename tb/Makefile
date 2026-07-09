

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

ifeq ($(TEST_TARGET), rt)
VERILOG_SOURCES = $(PWD)/../rtl/raytracing/titan_x5_ray_triangle_isect.v
TOPLEVEL = titan_x5_ray_triangle_isect
MODULE = test_ray_isect
endif

# (the old "cache" target was removed: it referenced a test_cache module
# that never existed, and the L1 now has a MESI interface covered by the
# cocotb 2.x regression: python run_regression.py mesi)

include $(shell cocotb-config --makefiles)/Makefile.sim

# -s scopes elaboration to the simulation root (rtl/titan_x5_fpga_top.v
# references Xilinx primitives that only exist in synthesis)
sim_top:
	iverilog -g2012 -s tb_titan_x5_gpu_top -I../rtl -o sim_top.vvp tb_titan_x5_gpu_top.v ../rtl/*/*.v ../rtl/*.v
	vvp sim_top.vvp
	python generate_waveform_proof.py

# Transaction-based verification regression (works without make as well):
#   python run_regression.py [lsu] [fpu] [mesi] [tmu]
regression:
	python run_regression.py

regression_%:
	python run_regression.py $*
