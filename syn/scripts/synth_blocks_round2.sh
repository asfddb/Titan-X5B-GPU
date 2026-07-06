#!/usr/bin/env bash
# Round 2: blocks missing after the parallel run OOM-killed (big memory
# blocks need the whole RAM budget - run everything SERIALLY), plus the
# FPGA-minimal sizing probes.
# Run from the repository root (Linux/WSL): bash syn/scripts/synth_blocks_round2.sh
set -u
cd "$(dirname "$0")/../.."

OUT=syn/reports/blocks
mkdir -p "$OUT"

READ_CMDS=$(sed -n 's/^read_verilog /read_verilog /p' fpga/synth_fpga_top.ys)

run_block() {
    local name="$1" top="$2" chp="$3"
    [ -s "$OUT/${name}.stat" ] && { echo "SKIP $name (exists)"; return; }
    local script="/tmp/synth_${name}.ys"
    {
        echo "$READ_CMDS"
        [ -n "$chp" ] && echo "$chp"
        echo "synth_xilinx -family xc7 -top $top"
        echo "tee -o $OUT/${name}.stat stat -tech xilinx"
    } > "$script"
    if timeout 5400 yosys -q "$script" > "$OUT/${name}.log" 2>&1; then
        echo "OK   $name"
    else
        echo "FAIL $name (see $OUT/${name}.log)"
    fi
}

# small/medium first for fast feedback, big memory blocks last
run_block pipeline          titan_x5_pipeline ""
run_block tmu               titan_x5_tmu ""
run_block rop               titan_x5_rop ""
run_block rt_core           titan_x5_rt_core ""
run_block display_engine    titan_x5_display_engine ""
run_block vram_ctrl         titan_x5_vram_ctrl ""
run_block mem_controller    titan_x5_mem_controller ""
run_block command_processor titan_x5_command_processor ""
run_block dma_engine        titan_x5_dma_engine ""
run_block sr_engine         titan_x5_sr_engine ""
run_block gddr7_phy         titan_x5_gddr7_pam3_phy ""
run_block neural_shader     titan_x5_neural_shader_dispatch ""
run_block alu_notensor      titan_x5_alu "chparam -set ENABLE_TENSOR 0 titan_x5_alu"
run_block shared_memory     titan_x5_shared_memory ""
run_block lsu               titan_x5_lsu ""
run_block l1_cache          titan_x5_l1_cache ""
run_block sm_min            titan_x5_sm "chparam -set NUM_ALUS 2 -set ENABLE_TENSOR 0 titan_x5_sm"
run_block l2_cache          titan_x5_l2_cache ""
echo "Round 2 done."
