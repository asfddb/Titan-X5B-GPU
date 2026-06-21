import sys
from vcdvcd import VCDVCD

vcd = VCDVCD('waves_gpu_top.vcd')

# Get signal names
mc_state = None

for s in vcd.signals:
    if 'dut.u_mem_ctrl.state' in s:
        mc_state = s

print("u_mem_ctrl state:")
for t, v in vcd[mc_state].tv:
    if 250000 <= t <= 320000:
        print(f"Time {t}: {v}")
