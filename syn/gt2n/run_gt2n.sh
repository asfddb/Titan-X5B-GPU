#!/usr/bin/env bash
# Synthesize a Titan module onto the GT2N open 2 nm GAAFET PDK and report
# real cell area and real critical-path delay.
#
#   ./syn/gt2n/run_gt2n.sh <top> <verilog...>
#
# GT2N is a PREDICTIVE PDK: realistic, foundry-agnostic, NOT fabbable, and
# its only characterised corner is tt 0.7 V 25 C. Delay below is ABC's
# post-mapping static timing with WireLoad="none" -- real gate delays from
# the Liberty tables, but ZERO wire delay, so place-and-route can only make
# it worse, never better.
set -u
: "${GT2N_ROOT:?set GT2N_ROOT to the GT2N checkout}"
: "${OSS_CAD:?set OSS_CAD to the oss-cad-suite directory}"
export PATH="$OSS_CAD/bin:$OSS_CAD/lib:$PATH"

TOP="$1"; shift
SRCS="$*"
TARGET_PS="${TARGET_PS:-333}"
OUT="${OUT:-syn/gt2n/results}"
mkdir -p "$OUT"

printf '%-6s %-5s %12s %12s %10s\n' VT WIDTH "AREA(um2)" "DELAY(ps)" "GHz"
for W in w31 w13; do
  for VT in elvt ulvt lvt svt hvt; do
    LIB="$GT2N_ROOT/lib/tt/gt2_6t_${W}_${VT}_tt_0p7v25c.lib"
    [ -f "$LIB" ] || continue
    LOG="$OUT/${TOP}_${W}_${VT}.log"
    cat > "$OUT/.ys" <<EOF
read_verilog $SRCS
hierarchy -check -top $TOP
synth -top $TOP -flatten
dfflibmap -liberty $LIB
abc -liberty $LIB -script +strash;dc2;strash;&get,-n;&dch,-f;&nf,-D,$TARGET_PS;&put;topo;buffer,-N,4;upsize,-D,$TARGET_PS;dnsize,-D,$TARGET_PS;stime
opt_clean -purge
stat -liberty $LIB
EOF
    yosys.exe -l "$LOG" -s "$OUT/.ys" >/dev/null 2>&1
    A=$(grep "Chip area for module" "$LOG" | tail -1 | sed 's/.*: //')
    D=$(grep -o "Delay = *[0-9.]* ps" "$LOG" | tail -1 | grep -o "[0-9.]*")
    if [ -n "${D:-}" ]; then
      G=$(python -c "print(f'{1e12/($D*1e-12*1e12)/1e9:.2f}')" 2>/dev/null || echo "-")
      G=$(python -c "print(f'{1000.0/$D:.2f}')")
    else D="FAIL"; G="-"; fi
    printf '%-6s %-5s %12.2f %12s %10s\n' "$VT" "$W" "${A:-0}" "$D" "$G"
  done
done
