#!/usr/bin/env bash
# Round 2: blocks missing after the parallel run OOM-killed, plus the
# FPGA-minimal sizing probes. Serial on purpose: the big memory blocks
# peak at ~7 GB RSS each in yosys. Uses run_one_block.sh, which scopes
# each run to the files its top actually needs (see rtl_deps.py).
# Run from the repository root (Linux/WSL): bash syn/scripts/synth_blocks_round2.sh
set -u
cd "$(dirname "$0")/../.."
R=syn/scripts/run_one_block.sh

# small/medium first for fast feedback, big memory blocks last
bash $R pipeline          titan_x5_pipeline
bash $R tmu               titan_x5_tmu
bash $R rop               titan_x5_rop
bash $R rt_core           titan_x5_rt_core
bash $R display_engine    titan_x5_display_engine
bash $R vram_ctrl         titan_x5_vram_ctrl
bash $R mem_controller    titan_x5_mem_controller
bash $R command_processor titan_x5_command_processor
bash $R dma_engine        titan_x5_dma_engine
bash $R sr_engine         titan_x5_sr_engine
bash $R gddr7_phy         titan_x5_gddr7_pam3_phy
bash $R neural_shader     titan_x5_neural_shader_dispatch
bash $R alu_notensor      titan_x5_alu -set ENABLE_TENSOR 0
bash $R shared_memory     titan_x5_shared_memory
bash $R lsu               titan_x5_lsu
bash $R l1_cache          titan_x5_l1_cache
bash $R sm_min            titan_x5_sm -set NUM_ALUS 2 -set ENABLE_TENSOR 0
bash $R l2_cache          titan_x5_l2_cache
echo "Round 2 done."
