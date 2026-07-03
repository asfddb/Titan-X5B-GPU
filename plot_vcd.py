import sys
import matplotlib.pyplot as plt
from vcdvcd import VCDVCD

def plot_vcd(vcd_path, out_png, signals_to_plot):
    vcd = VCDVCD(vcd_path)
    
    fig, axes = plt.subplots(len(signals_to_plot), 1, figsize=(12, 2 * len(signals_to_plot)), sharex=True)
    if len(signals_to_plot) == 1:
        axes = [axes]
    
    max_time = 0
    for ax, sig_name in zip(axes, signals_to_plot):
        if sig_name not in vcd.signals:
            print(f"Warning: {sig_name} not found in VCD.")
            continue
        
        tv = vcd[sig_name].tv
        times = []
        vals = []
        
        # Parse transitions into step function data
        last_val = 0
        for t, v in tv:
            times.append(t)
            # Try to convert to int if possible, otherwise treat as 0 or 1 (e.g. 'z', 'x')
            try:
                numeric_val = int(v, 2)
            except ValueError:
                numeric_val = 0 # Fallback for x/z
                
            vals.append(numeric_val)
            max_time = max(max_time, t)
            
        # Add final point for the step plot to look right
        times.append(max_time)
        vals.append(vals[-1] if vals else 0)
        
        ax.step(times, vals, where='post', color='#00ffcc', linewidth=2)
        ax.set_ylabel(sig_name.split('.')[-1], rotation=0, labelpad=40, color='white')
        ax.tick_params(axis='x', colors='white')
        ax.tick_params(axis='y', colors='white')
        
        # Style the plot to look like a modern EDA tool (dark mode)
        ax.set_facecolor('#1e1e1e')
        fig.patch.set_facecolor('#1e1e1e')
        ax.grid(True, color='#333333', linestyle='--')
        ax.spines['bottom'].set_color('#555555')
        ax.spines['top'].set_color('#555555')
        ax.spines['left'].set_color('#555555')
        ax.spines['right'].set_color('#555555')

    plt.xlabel('Time (ps)', color='white')
    plt.suptitle('Titan X5 Hardware Waveform Analysis', color='white', fontsize=16)
    plt.tight_layout()
    plt.savefig(out_png, facecolor='#1e1e1e', bbox_inches='tight')
    print(f"Saved waveform plot to {out_png}")

if __name__ == "__main__":
    import os
    artifact_dir = os.path.dirname(os.path.abspath(__file__))
    # Let's plot waves_hdc.vcd which is smaller and very clear
    sigs = [
        "tb_nexus_hdc.clk",
        "tb_nexus_hdc.rst_n",
        "tb_nexus_hdc.cam_start_train",
        "tb_nexus_hdc.cam_start_query",
        "tb_nexus_hdc.cam_done"
    ]
    plot_vcd("waves_hdc.vcd", f"{artifact_dir}\\waveform_real.png", sigs)
