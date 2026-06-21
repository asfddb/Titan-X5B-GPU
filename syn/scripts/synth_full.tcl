# Yosys synthesis script for Titan X5-B GPU
read_verilog -sv [glob rtl/*.v] [glob rtl/**/*.v]
hierarchy -top titan_x5_gpu_top
synth -top titan_x5_gpu_top
stat > syn/reports/synthesis_stats.txt
write_verilog syn/titan_x5b_synth.v
