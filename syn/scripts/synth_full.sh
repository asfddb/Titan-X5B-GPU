#!/usr/bin/env bash
# ============================================================================
# Full-chip synthesis for the Titan X5-B GPU.
#
#   bash syn/scripts/synth_full.sh [top_module]
#
# Replaces synth_full.tcl, which could not run as written: it uses Tcl's
# [glob ...], but `yosys -s` reads a *yosys* script, not Tcl. Yosys took the
# literal text "[glob" as a filename and stopped. Tcl mode needs `yosys -c`,
# and that requires a Tcl-enabled build -- expanding the file list in the shell
# works on any build, so that is what this does.
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")/../.."

TOP="${1:-titan_x5_gpu_top}"
OUT=syn/reports
mkdir -p "$OUT"

# Put the toolchain on PATH. The lib/ directory matters as much as bin/ --
# the binaries link against 240 DLLs that live there, and without it yosys
# dies with "cannot open shared object file: libreadline8.dll".
export YOSYSHQ_ROOT="${YOSYSHQ_ROOT:-C:/eda/oss-cad-suite/}"
if [ -d "/c/eda/oss-cad-suite/bin" ]; then
  export PATH="/c/eda/oss-cad-suite/bin:/c/eda/oss-cad-suite/lib:$PATH"
  export SSL_CERT_FILE="/c/eda/oss-cad-suite/etc/cacert.pem"
fi
command -v yosys >/dev/null || { echo "yosys not on PATH"; exit 1; }

# Every synthesisable source. xilinx_stubs.v is excluded on purpose: it holds
# simulation stand-ins for Xilinx primitives and must not reach synthesis.
mapfile -t SOURCES < <(find rtl -name '*.v' ! -name 'xilinx_stubs.v' | sort)
echo "sources : ${#SOURCES[@]} files"
echo "top     : $TOP"
echo "log     : $OUT/synth_full.log"
echo

LOG="$OUT/synth_full.log"
{
  printf 'read_verilog -sv %s\n' "${SOURCES[*]}"
  echo "hierarchy -top $TOP"
  echo "synth -top $TOP"
  echo "stat"
  echo "write_json $OUT/${TOP}.json"
} > "$OUT/synth_full.ys"

start=$(date +%s)
yosys -s "$OUT/synth_full.ys" > "$LOG" 2>&1
status=$?
elapsed=$(( $(date +%s) - start ))

echo "yosys exit $status after ${elapsed}s"
if [ $status -ne 0 ]; then
  echo
  echo "--- errors ---"
  grep -a "^ERROR" "$LOG" | head -10
  exit $status
fi

# Pull the final statistics block out of the log and keep it as the report.
awk '/^[0-9.]+\. Printing statistics/{keep=1; buf=""} keep{buf=buf $0 "\n"} END{printf "%s", buf}' \
  "$LOG" > "$OUT/synthesis_stats.txt"

echo
echo "--- final statistics ---"
cat "$OUT/synthesis_stats.txt"
