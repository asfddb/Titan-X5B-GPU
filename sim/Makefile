compile:
	iverilog -g2012 -I ../rtl -o test.vvp ../tb/ultimate_blackwell_tb.v ../rtl/titan_x5_gpu_top.v ../rtl/common/*.v ../rtl/control/*.v ../rtl/core/*.v ../rtl/display/*.v ../rtl/graphics/*.v ../rtl/interconnect/*.v ../rtl/memory/*.v ../rtl/power/*.v ../rtl/raytracing/*.v ../rtl/sr/*.v ../rtl/tensor/*.v

test:
	pytest ../tb/test_*.py -v

test-system:
	pytest ../tb/test_system.py -v

test-graphics:
	pytest ../tb/test_graphics_pipeline.py -v

regression:
	python3 regression.py --seeds 10

wave:
	gtkwave waves.vcd

clean:
	rm -f *.vvp *.vcd *.log
	rm -rf sim_build/ __pycache__/
