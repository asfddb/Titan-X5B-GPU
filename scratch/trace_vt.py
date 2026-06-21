import sys
from vcdvcd import VCDVCD

def main():
    vcd = VCDVCD('waves_gpu_top.vcd')
    state_sig = 'tb_titan_x5_gpu_top.dut.u_vertex_transformer.state[2:0]'
    
    # Resolve signal
    match = None
    for key in vcd.signals:
        if key.endswith(state_sig) or state_sig in key:
            match = key
            break
            
    if not match:
        print("Could not find state signal.")
        return
        
    print(f"Traced state signal: {match}")
    tv = vcd[match].tv
    for t, val in tv:
        print(f"Time {t:12d} ps : state -> {val}")

if __name__ == '__main__':
    main()
