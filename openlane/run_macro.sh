#!/bin/bash
# Titan X5-B OpenLane macro-hardening runner (WSL, run as root).
# usage: run_macro.sh <design_dir_name>   (a directory under openlane/)
#
# OpenROAD crashes (SIGABRT in writeDb) when the run directory lives on
# /mnt/c (drvfs), so mirror the workspace to native ext4, run there, and
# copy the finished run back into the repo for archiving.
d="$1"
[ -z "$d" ] && { echo "usage: run_macro.sh <design>"; exit 2; }
exec > "/var/log/ol_${d}.log" 2>&1
set -x
pgrep dockerd || { nohup dockerd > /var/log/dockerd.log 2>&1 & sleep 6; }
REPO=/mnt/c/Users/singb/Downloads/gpuuhj
WORK=/root/tx5
mkdir -p "$WORK"
rsync -a --delete "$REPO/rtl" "$WORK/"
rsync -a --exclude runs "$REPO/openlane" "$WORK/"
cd "$WORK"
/root/olenv/bin/openlane --dockerized "openlane/${d}/config.json"
rc=$?
if [ $rc -eq 0 ]; then
    last=$(ls -1dt "$WORK/openlane/${d}/runs/"* 2>/dev/null | head -1)
    if [ -n "$last" ]; then
        mkdir -p "$REPO/openlane/${d}/runs"
        rsync -a "$last" "$REPO/openlane/${d}/runs/"
    fi
fi
echo "EXIT=$rc"
