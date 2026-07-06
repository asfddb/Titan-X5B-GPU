#!/usr/bin/env bash
# Synthesize one block: run_one_block.sh <name> <top_module> [chparam args...]
# e.g. run_one_block.sh sm_min titan_x5_sm -set NUM_ALUS 2 -set ENABLE_TENSOR 0
# Writes syn/reports/blocks/<name>.stat ; skips if it already exists.
set -u
cd "$(dirname "$0")/../.."

name="$1"; top="$2"; shift 2
OUT=syn/reports/blocks
mkdir -p "$OUT"
[ -s "$OUT/${name}.stat" ] && { echo "SKIP $name (exists)"; exit 0; }

script="/tmp/synth_${name}.ys"
{
    # only the files this top actually needs: yosys's coarse passes run on
    # every module read (reachable or not), so reading all 41 files makes
    # every block pay for flattening the 2 Mbit L2 data array
    python3 syn/scripts/rtl_deps.py "$top" | sed 's/^/read_verilog /'
    [ $# -gt 0 ] && echo "chparam $* $top"
    echo "synth_xilinx -family xc7 -top $top"
    echo "tee -o $OUT/${name}.stat stat -tech xilinx"
} > "$script"

if timeout 5400 yosys -q "$script" > "$OUT/${name}.log" 2>&1; then
    echo "OK   $name"
else
    echo "FAIL $name (see $OUT/${name}.log)"
    exit 1
fi
