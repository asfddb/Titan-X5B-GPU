#!/usr/bin/env bash
# ============================================================================
# Per-subsystem Xilinx 7-series synthesis for the Titan X5-B GPU.
# Produces one honest yosys utilization report per block in
# syn/reports/blocks/<block>.stat - the input data for both the Basys 3
# fit analysis (Phase 1) and OpenLane macro hardening (Phase 2).
#
# Run from the repository root (Linux/WSL):  bash syn/scripts/synth_blocks.sh
# ============================================================================
set -u
cd "$(dirname "$0")/../.."

OUT=syn/reports/blocks
mkdir -p "$OUT"

# All synthesizable sources (xilinx_stubs.v excluded on purpose: it holds
# simulation stand-ins for Xilinx primitives).
SOURCES=$(cat <<'EOF'
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
EOF
)
READ_CMDS=$(echo "$SOURCES" | sed 's/^/read_verilog /')

# "block_name|top_module|chparam commands (may be empty)"
# chparams mirror the parameters used at the block's instantiation site
# inside titan_x5_gpu_top / titan_x5_sm.
BLOCKS=$(cat <<'EOF'
alu|titan_x5_alu|
tensor_array_4x4|titan_x6_tensor_core_array|chparam -set ARRAY_SIZE_X 4 -set ARRAY_SIZE_Y 4 titan_x6_tensor_core_array
fp32_fma|titan_x5_fp32_fma|
register_file|titan_x5_register_file|
warp_scheduler|titan_x5_warp_scheduler|
decoder|titan_x5_decoder|
pipeline|titan_x5_pipeline|
l1_cache|titan_x5_l1_cache|
lsu|titan_x5_lsu|
shared_memory|titan_x5_shared_memory|
l2_cache|titan_x5_l2_cache|
l2_mem_adapter|titan_x5_l2_mem_adapter|
coherent_xbar|titan_x5_coherent_xbar|
crossbar|titan_x5_crossbar|
rasterizer|titan_x5_rasterizer|
vertex_transformer|titan_x5_vertex_transformer|
tmu|titan_x5_tmu|
rop|titan_x5_rop|
rt_core|titan_x5_rt_core|
display_engine|titan_x5_display_engine|
vram_ctrl|titan_x5_vram_ctrl|
mem_controller|titan_x5_mem_controller|
command_processor|titan_x5_command_processor|
dma_engine|titan_x5_dma_engine|
sr_engine|titan_x5_sr_engine|
gddr7_phy|titan_x5_gddr7_pam3_phy|
neural_shader|titan_x5_neural_shader_dispatch|
EOF
)

synth_one() {
    local name="$1" top="$2" chp="$3"
    local script="/tmp/synth_${name}.ys"
    {
        echo "$READ_CMDS"
        [ -n "$chp" ] && echo "$chp"
        echo "synth_xilinx -family xc7 -top $top"
        echo "tee -o $OUT/${name}.stat stat -tech xilinx"
    } > "$script"
    if timeout 3600 yosys -q "$script" > "$OUT/${name}.log" 2>&1; then
        echo "OK   $name"
    else
        echo "FAIL $name (see $OUT/${name}.log)"
    fi
}
export -f synth_one
export READ_CMDS OUT

# -P 2: the big memory blocks (l1/l2/lsu/shared_memory) peak at ~7 GB RSS
# each in yosys; four in parallel OOM-kill on an 11 GB WSL instance.
echo "$BLOCKS" | awk -F'|' '{printf "%s\t%s\t%s\n", $1, $2, $3}' |
    xargs -P 2 -d '\n' -I{} bash -c '
        IFS=$'"'"'\t'"'"' read -r name top chp <<< "{}"
        synth_one "$name" "$top" "$chp"
    '

echo "Done. Reports in $OUT/"
