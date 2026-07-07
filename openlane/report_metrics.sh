#!/bin/bash
# Print key signoff metrics for the latest run of a design.
# usage: report_metrics.sh <design_dir_name>
d="$1"
R=$(ls -1dt /root/tx5/openlane/${d}/runs/RUN_* 2>/dev/null | head -1)
[ -z "$R" ] && { echo "no runs for $d"; exit 1; }
echo "RUN: $R"
python3 - "$R/final/metrics.json" <<'PYEOF'
import json, sys
m = json.load(open(sys.argv[1]))
watch = ["design__instance__count", "design__die__area",
         "timing__setup__ws", "timing__hold__ws",
         "timing__setup__vio", "timing__hold__vio",
         "magic__drc_error", "klayout__drc_error",
         "design__lvs_error", "design__lvs_device_difference",
         "antenna__violating", "max_slew_violation", "max_cap_violation",
         "max_fanout_violation", "power__total", "clock__skew"]
for k in sorted(m):
    if any(w in k for w in watch):
        print(f"{k} = {m[k]}")
PYEOF
