import sys
from vcdvcd import VCDVCD

vcd = VCDVCD('waves_gpu_top.vcd')
signals = vcd.signals

print("Matching signals:")
for s in signals:
    if 'dut' in s and 'state' in s and 'rop' in s:
        print(s)
    if 'cfg_dcc' in s:
        print(s)
    if 'dcc_gnt' in s:
        print(s)
