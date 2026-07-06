# ============================================================================
# Vivado batch build: Titan X5-B GPU -> Digilent Basys 3 (xc7a35tcpg236-1)
#
# Usage (from the repository root):
#   vivado -mode batch -source fpga/vivado_build.tcl
#
# Outputs (in fpga/build/):
#   titan_x5_basys3.bit          - bitstream for the Basys 3
#   post_route_timing.rpt        - timing summary (check WNS >= 0)
#   post_route_util.rpt          - utilization report
# ============================================================================

set repo_root  [file normalize [file join [file dirname [info script]] ..]]
set build_dir  $repo_root/fpga/build
set part       xc7a35tcpg236-1
set top        titan_x5_fpga_top

file mkdir $build_dir

# --- Sources (keep in sync with fpga/synth_fpga_top.ys) ---------------------
set rtl_sources {
    rtl/common/titan_x5_skid_buffer.v
    rtl/control/titan_x5_command_processor.v
    rtl/control/titan_x5_perf_counters.v
    rtl/core/titan_x5_alu.v
    rtl/core/titan_x5_decoder.v
    rtl/core/titan_x5_pipeline.v
    rtl/core/titan_x5_register_file.v
    rtl/core/titan_x5_sm.v
    rtl/core/titan_x5_warp_scheduler.v
    rtl/display/titan_x5_async_fifo.v
    rtl/display/titan_x5_display_engine.v
    rtl/fpu/titan_x5_fp32_add.v
    rtl/fpu/titan_x5_fp32_add_comb.v
    rtl/fpu/titan_x5_fp32_fma.v
    rtl/fpu/titan_x5_fp32_mul.v
    rtl/graphics/titan_x5_neural_shader_dispatch.v
    rtl/graphics/titan_x5_rasterizer.v
    rtl/graphics/titan_x5_rop.v
    rtl/graphics/titan_x5_tmu.v
    rtl/graphics/titan_x5_vertex_transformer.v
    rtl/interconnect/titan_x5_axi4_lite.v
    rtl/interconnect/titan_x5_crossbar.v
    rtl/interconnect/titan_x5_dma_engine.v
    rtl/interconnect/titan_x5_mesh_router.v
    rtl/memory/titan_x5_gddr7_pam3_phy.v
    rtl/memory/titan_x5_l1_cache.v
    rtl/memory/titan_x5_l2_cache.v
    rtl/memory/titan_x5_l2_mem_adapter.v
    rtl/memory/titan_x5_lsu.v
    rtl/memory/titan_x5_mem_controller.v
    rtl/memory/titan_x5_shared_memory.v
    rtl/memory/titan_x5_vram_ctrl.v
    rtl/power/titan_x5_power_mgmt.v
    rtl/raytracing/titan_x5_ray_triangle_isect.v
    rtl/raytracing/titan_x5_rt_core.v
    rtl/sr/titan_x5_hash_fnv64.v
    rtl/sr/titan_x5_sr_engine.v
    rtl/tensor/titan_x5_fp16_mul.v
    rtl/tensor/titan_x6_tensor_core_array.v
    rtl/titan_x5_gpu_top.v
    rtl/titan_x5_fpga_top.v
}

foreach f $rtl_sources {
    read_verilog $repo_root/$f
}
read_xdc $repo_root/fpga/titan_x5_basys3.xdc

# --- Synthesis ---------------------------------------------------------------
synth_design -top $top -part $part -flatten_hierarchy rebuilt
write_checkpoint -force $build_dir/post_synth.dcp
report_utilization      -file $build_dir/post_synth_util.rpt
report_timing_summary   -file $build_dir/post_synth_timing.rpt

# --- Implementation ----------------------------------------------------------
opt_design
place_design
phys_opt_design
route_design
write_checkpoint -force $build_dir/post_route.dcp
report_utilization      -file $build_dir/post_route_util.rpt
report_timing_summary   -file $build_dir/post_route_timing.rpt
report_drc              -file $build_dir/post_route_drc.rpt

# --- Bitstream ---------------------------------------------------------------
# Fail loudly if timing is not met rather than shipping a broken bitstream.
set wns [get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup]]
puts "INFO: post-route worst negative slack (WNS) = $wns ns"
if {$wns < 0} {
    puts "ERROR: Timing NOT met (WNS = $wns ns). No bitstream written."
    puts "       Inspect $build_dir/post_route_timing.rpt for the critical path."
    exit 1
}

write_bitstream -force $build_dir/titan_x5_basys3.bit
puts "SUCCESS: bitstream written to $build_dir/titan_x5_basys3.bit"
