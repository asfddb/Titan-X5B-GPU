#!/usr/bin/env bash
# ============================================================================
# Synthesize EVERY module in rtl/ onto the GT2N open 2 nm GAAFET PDK and
# report real cell area and real critical-path delay for each.
#
#   sh syn/gt2n/run_gt2n_all.sh                 # all modules
#   sh syn/gt2n/run_gt2n_all.sh titan_x5_alu    # named modules only
#
# run_gt2n.sh sweeps one module across 10 corner/width combinations. This is
# the other axis: one corner, every module, so the whole design has a measured
# 2 nm area figure rather than four blocks having one.
#
# Corner is fixed at svt/w31 - standard-Vt, wide device. It is the middle of
# the range run_gt2n.sh sweeps, and the ABC recipe below is copied from that
# script verbatim so the numbers stay comparable with results/ .
#
# PERFORMANCE NOTE, learned the hard way: the obvious implementation runs one
# yosys per module, and each of those re-parses all ~90 RTL files before it
# synthesises anything. That is ~90 x 90 file parses and takes hours. Instead
# this parses once, saves the elaborated design with `design -save`, and
# reloads that snapshot per module. If a module aborts the run, the script
# records it and resumes from the next one, so a single bad module costs one
# extra parse rather than the whole sweep.
#
# READ THIS BEFORE QUOTING ANY NUMBER FROM HERE
#   - GT2N is a PREDICTIVE PDK. Realistic, foundry-agnostic, and NOT fabbable.
#   - Its only characterised corner is tt 0.7 V 25 C. No slow corner exists,
#     so there is no signoff margin in any of this.
#   - WireLoad="none": these are gate delays with ZERO wire delay. At 2 nm
#     wire delay dominates, so place-and-route can only make them worse.
#   - Synthesis only. No floorplan, placement, CTS, routing or extraction.
#   - GT2N ships NO SRAM of any kind. Every memory in this design maps to
#     flip-flops, which is why cache and register-file areas come out
#     enormous. Those figures are real for a flop-based implementation and
#     say nothing about what the block would cost with a real memory macro.
# ============================================================================
set -u

GT2N_ROOT="${GT2N_ROOT:-C:/eda/GT2N}"
OSS_CAD="${OSS_CAD:-C:/eda/oss-cad-suite}"
REPO="${REPO:-C:/Titan-X5B-GPU}"

# PATH needs msys-style paths or the shell cannot resolve them; yosys.exe's
# own arguments need Windows-style. Both forms are required, and mixing them
# up is silent - yosys never starts and writes no log at all, which looks
# exactly like every module failing to synthesize.
#
# lib/ is on PATH because yosys.exe loads its DLLs from there, not just bin/.
OSS_CAD_UNIX="${OSS_CAD_UNIX:-$(echo "$OSS_CAD" | sed 's|^\([A-Za-z]\):|/\L\1|')}"
export PATH="$OSS_CAD_UNIX/bin:$OSS_CAD_UNIX/lib:$PATH"
YOSYS="$OSS_CAD_UNIX/bin/yosys.exe"

W="${W:-w31}"
VT="${VT:-svt}"
LIB="$GT2N_ROOT/lib/tt/gt2_6t_${W}_${VT}_tt_0p7v25c.lib"
TARGET_PS="${TARGET_PS:-333}"

OUT="${OUT:-syn/gt2n/results/all}"
mkdir -p "$OUT"

[ -f "$(echo "$LIB" | sed 's|^\([A-Za-z]\):|/\L\1|')" ] || {
    echo "Liberty not found: $LIB" >&2; exit 1; }

# Every .v under rtl/, as forward-slash Windows paths.
SRC_LIST=$(find "$REPO/rtl" -name '*.v' 2>/dev/null | sed "s|^/c/|C:/|" | tr '\n' ' ')
[ -n "$SRC_LIST" ] || SRC_LIST=$(find /c/Titan-X5B-GPU/rtl -name '*.v' | sed "s|^/c/|C:/|" | tr '\n' ' ')

# Module names come from the files, not the filenames - several modules live
# in a file named after something else (titan_x7_csa_mul24 is in
# titan_x7_csa_mul.v), and using filenames would silently miss them.
if [ $# -gt 0 ]; then
    MODULES="$*"
else
    MODULES=$(grep -rhoE '^[[:space:]]*module[[:space:]]+[A-Za-z_][A-Za-z0-9_]*' \
                   /c/Titan-X5B-GPU/rtl/*.v /c/Titan-X5B-GPU/rtl/*/*.v 2>/dev/null \
              | awk '{print $2}' | sort -u)
fi

RESULTS="$OUT/summary_${W}_${VT}.txt"
rm -f "$OUT"/*.stat.txt "$OUT"/*.abc.txt

emit_ys() {   # $1 = file to write, rest = modules to attempt
    local ys="$1"; shift
    {
        echo "read_verilog -sv $SRC_LIST"
        echo "design -save parsed"
        for M in "$@"; do
            echo "design -load parsed"
            echo "hierarchy -check -top $M"
            echo "synth -top $M -flatten"
            echo "dfflibmap -liberty $LIB"
            echo "tee -o $OUT/$M.abc.txt abc -liberty $LIB -script +strash;dc2;strash;&get,-n;&dch,-f;&nf,-D,$TARGET_PS;&put;topo;buffer,-N,4;upsize,-D,$TARGET_PS;dnsize,-D,$TARGET_PS;stime"
            echo "opt_clean -purge"
            echo "tee -o $OUT/$M.stat.txt stat -liberty $LIB"
        done
    } > "$ys"
}

# --- run, resuming past any module that aborts the script -------------------
remaining="$MODULES"
failed=""
pass=0

while [ -n "$(echo "$remaining" | tr -d '[:space:]')" ]; do
    emit_ys "$OUT/.sweep.ys" $remaining
    # Bounded: a module that never converges would otherwise hang the whole
    # sweep with no output at all. On timeout the resume logic below treats
    # the first module with no stat file as the culprit and carries on past
    # it, so one pathological block costs one re-parse, not the run.
    timeout "${ATTEMPT_TIMEOUT:-3600}" \
        "$YOSYS" -l "$OUT/sweep.log" -s "$OUT/.sweep.ys" >/dev/null 2>&1

    # Whatever produced a stat file finished; the first module without one is
    # where it died.
    next=""
    died=""
    for M in $remaining; do
        if [ -f "$OUT/$M.stat.txt" ]; then
            continue
        fi
        died="$M"
        break
    done

    [ -z "$died" ] && break              # everything completed

    failed="$failed $died"
    # Resume after the module that killed the run.
    next=$(echo "$remaining" | tr ' ' '\n' | sed -n "/^$died\$/,\$p" | tail -n +2 | tr '\n' ' ')
    remaining="$next"
done

# --- report -----------------------------------------------------------------
{
    printf '%-42s %14s %12s %9s\n' MODULE "AREA(um2)" "DELAY(ps)" "GHz"
    printf '%-42s %14s %12s %9s\n' "------------------------------------------" \
           "--------------" "------------" "---------"
    for M in $MODULES; do
        S="$OUT/$M.stat.txt"
        A=""
        [ -f "$S" ] && A=$(grep "Chip area for module" "$S" | tail -1 | sed 's/.*: //')
        if [ -z "${A:-}" ]; then
            printf '%-42s %14s %12s %9s\n' "$M" "FAIL" "-" "-"
        else
            D=$(grep -o "Delay = *[0-9.]* ps" "$OUT/$M.abc.txt" 2>/dev/null \
                | tail -1 | grep -o "[0-9.]*")
            if [ -n "${D:-}" ]; then
                G=$(awk "BEGIN{printf \"%.2f\", 1000.0/$D}")
            else
                D="-"; G="-"
            fi
            printf '%-42s %14.2f %12s %9s\n' "$M" "$A" "$D" "$G"
        fi
    done
    echo
    echo "corner: $VT / $W, tt 0.7V 25C, target ${TARGET_PS}ps, ZERO wire delay"
    echo "GT2N is predictive and not fabbable; it has no SRAM, so all memories"
    echo "here are flip-flops. See docs/GT2N_2NM_SYNTHESIS.md before quoting."
    [ -n "$failed" ] && echo "aborted the run (see sweep.log):$failed"
} | tee "$RESULTS"

echo
echo "summary: $RESULTS"
