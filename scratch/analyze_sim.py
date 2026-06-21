import sys
from vcdvcd import VCDVCD

def main():
    print("Loading VCD file...")
    vcd = VCDVCD('waves_gpu_top.vcd')
    print("VCD loaded successfully.")

    signals = {
        'vt_valid': 'tb_titan_x5_gpu_top.dut.vt_valid',
        'vt_payload': 'tb_titan_x5_gpu_top.dut.vt_payload',
    }

    all_keys = vcd.signals
    resolved_sigs = {}
    for name, path in signals.items():
        match = None
        for key in all_keys:
            if key.endswith(path) or path in key:
                match = key
                break
        if match:
            resolved_sigs[name] = match

    # Print vt_payload when vt_valid goes to 1
    vt_valid_key = resolved_sigs['vt_valid']
    vt_payload_key = resolved_sigs['vt_payload']
    
    for t, val in vcd[vt_valid_key].tv:
        if val == '1':
            # find payload value at this time
            pay_val = None
            for time, value in vcd[vt_payload_key].tv:
                if time <= t:
                    pay_val = value
                else:
                    break
            print(f"Time {t} ps: vt_valid -> 1")
            print(f"  vt_payload: {pay_val}")

if __name__ == '__main__':
    main()
