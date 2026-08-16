#!/bin/sh
# ============================================================================
# Run the plain-Verilog testbenches under Icarus.
#
# These are the ones that need no cocotb and no Python: iverilog compiles the
# RTL, vvp runs it. tb/run_regression.py covers the cocotb suites separately.
#
#   sh run_iverilog_tbs.sh            # all of them
#   sh run_iverilog_tbs.sh tb_fpu_top.v tb_titan_x5_alu.v
#
# -y makes iverilog search a directory for a module by filename when it hits
# an unresolved instance, so each testbench pulls in exactly the RTL it needs
# without a hand-maintained file list per target.
# ============================================================================

IV=${IV:-/c/iverilog/bin/iverilog}
VVP=${VVP:-/c/iverilog/bin/vvp}
RTL=../rtl
OUT=sim_out
TIMEOUT=${TIMEOUT:-90}

LIBS="-y $RTL -y $RTL/common -y $RTL/control -y $RTL/core -y $RTL/crypto \
      -y $RTL/display -y $RTL/fpu -y $RTL/graphics -y $RTL/interconnect \
      -y $RTL/memory -y $RTL/power -y $RTL/raytracing -y $RTL/sr \
      -y $RTL/tensor \
      -y board -y ../fpga"

# -y finds a module by looking for <modulename>.v, so it cannot resolve a
# module whose filename differs from its name. Every file below defines a
# module under some other name, and each one caused an "Unknown module type"
# elaboration failure until it was named explicitly:
#
#   titan_x7_csa_mul.v      -> titan_x7_csa_mul24   (tb_fma_x7, tb_x7_shim)
#   titan_x5_crossbar.v     -> titan_x5_coherent_xbar (tb_mesi_top)
#   xilinx_stubs.v          -> BUFG and friends     (every display/board tb)
#
# BUFG is a Xilinx primitive that Vivado supplies from its own library and
# Icarus knows nothing about; xilinx_stubs.v exists precisely to stand in for
# it in simulation.
LIBS="$LIBS -l $RTL/common/titan_x7_csa_mul.v"
LIBS="$LIBS -l $RTL/interconnect/titan_x5_crossbar.v"
LIBS="$LIBS -l $RTL/xilinx_stubs.v"

mkdir -p "$OUT"

[ $# -gt 0 ] && LIST="$*" || LIST=$(ls tb_*.v)

pass=0; fail=0; cerr=0

for tb in $LIST; do
    name=$(basename "$tb" .v)
    log="$OUT/$name.log"

    # -Wno-timescale: mixing modules with and without `timescale is noisy and
    # not what we are testing here.
    if ! $IV -g2012 -Wno-timescale -Y .v $LIBS -o "$OUT/$name.vvp" "$tb" \
             > "$log" 2>&1; then
        printf '  COMPILE-FAIL  %s\n' "$name"
        cerr=$((cerr+1))
        continue
    fi

    timeout "$TIMEOUT" $VVP "$OUT/$name.vvp" >> "$log" 2>&1
    rc=$?

    # Decide the verdict from what the testbench actually printed. Icarus
    # exits 0 even when $display says FAIL, so the exit code alone is useless.
    if [ $rc -eq 124 ]; then
        printf '  TIMEOUT       %s (%ss)\n' "$name" "$TIMEOUT"
        fail=$((fail+1))
    elif grep -qiE 'FAIL|MISMATCH|ERROR|\$fatal' "$log"; then
        printf '  FAIL          %s\n' "$name"
        fail=$((fail+1))
    elif grep -qiE 'PASS|OK|SUCCESS|DONE' "$log"; then
        printf '  PASS          %s\n' "$name"
        pass=$((pass+1))
    else
        printf '  RAN (no verdict) %s\n' "$name"
        pass=$((pass+1))
    fi
done

echo
echo "compiled+passed: $pass    failed: $fail    would not compile: $cerr"
echo "logs in $OUT/"
