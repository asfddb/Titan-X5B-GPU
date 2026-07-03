# ============================================================================
# Copyright (c) 2026 Adhiraj
# 
# This file is part of the Titan X5-B GPU project.
# 
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
import sys
import matplotlib.pyplot as plt
from vcdvcd import VCDVCD
import os

def plot_vcd(vcd_path, out_png, signals_to_plot):
    if not os.path.exists(vcd_path):
        print(f"Error: VCD file {vcd_path} not found.")
        sys.exit(1)
        
    vcd = VCDVCD(vcd_path)
    
    fig, axes = plt.subplots(len(signals_to_plot), 1, figsize=(14, 2.5 * len(signals_to_plot)), sharex=True)
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
        for t, v in tv:
            times.append(t)
            try:
                numeric_val = int(v, 2)
            except ValueError:
                numeric_val = 0 # Fallback for x/z
                
            vals.append(numeric_val)
            max_time = max(max_time, t)
            
        times.append(max_time)
        vals.append(vals[-1] if vals else 0)
        
        ax.step(times, vals, where='post', color='#00ffcc', linewidth=2)
        ax.set_ylabel(sig_name.split('.')[-1], rotation=0, labelpad=50, color='white', fontweight='bold', fontsize=12)
        ax.tick_params(axis='x', colors='white')
        ax.tick_params(axis='y', colors='white')
        
        # Set y-axis limits to clearly show binary transitions
        ax.set_ylim(-0.2, 1.2)
        ax.set_yticks([0, 1])
        
        # Style the plot to look like a logic analyzer
        ax.set_facecolor('#1e1e1e')
        fig.patch.set_facecolor('#1e1e1e')
        ax.grid(True, color='#333333', linestyle='--')
        ax.spines['bottom'].set_color('#555555')
        ax.spines['top'].set_color('#555555')
        ax.spines['left'].set_color('#555555')
        ax.spines['right'].set_color('#555555')

    plt.xlabel('Simulation Time (ps)', color='white', fontsize=12)
    plt.suptitle('Titan X5-B - Real Icarus Verilog Simulation Waveforms (AXI4 & Host Bus)', color='white', fontsize=16, fontweight='bold', y=0.98)
    plt.tight_layout(rect=[0, 0, 1, 0.95])
    plt.savefig(out_png, facecolor='#1e1e1e', bbox_inches='tight', dpi=150)
    print(f"Authentic waveform plot saved to {out_png}")

if __name__ == "__main__":
    import pathlib
    base_dir = pathlib.Path(__file__).parent.parent
    vcd_file = str(base_dir / "tb" / "blackwell_wave.vcd")
    out_file = str(base_dir / "docs" / "assets" / "simulation_waveforms.png")    
    sigs = [
        "ultimate_blackwell_tb.clk",
        "ultimate_blackwell_tb.rst_n",
        "ultimate_blackwell_tb.host_ring_wptr",
        "ultimate_blackwell_tb.vram_wvalid",
        "ultimate_blackwell_tb.vram_arvalid"
    ]
    
    plot_vcd(vcd_file, out_file, sigs)
