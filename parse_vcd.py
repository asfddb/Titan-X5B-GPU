import sys
from vcdvcd import VCDVCD

vcd = VCDVCD('waves_gpu_top.vcd')

# Get signal names
signals = vcd.signals

tmu0_state = None
rop0_state = None
mem_req = None
mem_gnt = None

for s in signals:
    if 'dut.dbg_tmu_state' in s:
        tmu0_state = s
    if 'dut.dbg_rop_state' in s:
        rop0_state = s
    if 'dut.rop_mem_req' in s:
        mem_req = s
    if 'dut.mc_req_ready' in s:
        mem_gnt = s

print(f"TMU state sig: {tmu0_state}")
print(f"ROP state sig: {rop0_state}")

def get_val_at_time(sig, t):
    if not sig: return None
    tv = vcd[sig].tv
    val = None
    for time, v in tv:
        if time <= t:
            val = v
        else:
            break
    return val

for t in range(300000, 380000, 10000):
    t_val = get_val_at_time(tmu0_state, t)
    r_val = get_val_at_time(rop0_state, t)
    mr_val = get_val_at_time(mem_req, t)
    mg_val = get_val_at_time(mem_gnt, t)
    print(f"Time {t:06d}: TMU={t_val} ROP={r_val} req={mr_val} gnt={mg_val}")

