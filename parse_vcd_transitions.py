import sys
from vcdvcd import VCDVCD

vcd = VCDVCD('waves_gpu_top.vcd')

# Get signal names
rop_state = 'tb_titan_x5_gpu_top.dut.rop_gen[0].genblk1.u_rop.state[3:0]'
cfg_dcc = 'tb_titan_x5_gpu_top.dut.rop_gen[0].genblk1.u_rop.cfg_dcc_en'
dcc_gnt = 'tb_titan_x5_gpu_top.dut.rop_gen[0].genblk1.u_rop.dcc_gnt'
mem_req = 'tb_titan_x5_gpu_top.dut.rop_mem_req'
mem_gnt = 'tb_titan_x5_gpu_top.dut.mc_req_ready'
clk = 'tb_titan_x5_gpu_top.clk'

def get_val_at_time(sig, t):
    tv = vcd[sig].tv
    val = None
    for time, v in tv:
        if time <= t:
            val = v
        else:
            break
    return val

t = 310000
print(f"Time {t}:")
print(f"ROP state: {get_val_at_time(rop_state, t)}")
print(f"cfg_dcc: {get_val_at_time(cfg_dcc, t)}")
print(f"dcc_gnt: {get_val_at_time(dcc_gnt, t)}")
print(f"mem_req: {get_val_at_time(mem_req, t)}")
print(f"mem_gnt: {get_val_at_time(mem_gnt, t)}")

