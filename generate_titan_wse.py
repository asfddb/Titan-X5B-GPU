import argparse
import os

def generate_wse(rows, cols):
    os.makedirs("rtl", exist_ok=True)
    num_cores = rows * cols
    
    verilog = f"""// ============================================================================
// TITAN X-INFINITY WAFER-SCALE ENGINE (WSE)
// Generated Grid: {rows} x {cols} ({num_cores:,} Cores)
// Architecture: X/Y Addressed 2D Mesh NoC
// ============================================================================
`timescale 1ns/1ps

module titan_x_infinity_wse (
    input  wire clk,
    input  wire rst_n,
    input  wire [{num_cores}-1:0] defect_fuses,
    
    input  wire [{cols*64-1}:0] io_in_top,
    output wire [{cols*64-1}:0] io_out_top,
    input  wire [{cols*64-1}:0] io_in_bottom,
    output wire [{cols*64-1}:0] io_out_bottom,
    input  wire [{rows*64-1}:0] io_in_left,
    output wire [{rows*64-1}:0] io_out_left,
    input  wire [{rows*64-1}:0] io_in_right,
    output wire [{rows*64-1}:0] io_out_right
);

    // NoC Interconnect Wires
"""
    for r in range(rows):
        for c in range(cols):
            verilog += f"    wire [63:0] n_out_r{r}_c{c}, s_out_r{r}_c{c}, e_out_r{r}_c{c}, w_out_r{r}_c{c};\n"
            
    verilog += "\n    // Core Instantiations\n"
    
    for r in range(rows):
        for c in range(cols):
            core_idx = r * cols + c
            
            n_in = f"io_in_top[{c*64+63}:{c*64}]" if r == 0 else f"s_out_r{r-1}_c{c}"
            s_in = f"io_in_bottom[{c*64+63}:{c*64}]" if r == rows - 1 else f"n_out_r{r+1}_c{c}"
            w_in = f"io_in_left[{r*64+63}:{r*64}]" if c == 0 else f"e_out_r{r}_c{c-1}"
            e_in = f"io_in_right[{r*64+63}:{r*64}]" if c == cols - 1 else f"w_out_r{r}_c{c+1}"

            verilog += f"""    titan_x_wse_sm #(
        .CORE_X(16'd{c}), .CORE_Y(16'd{r})
    ) u_core_r{r}_c{c} (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[{core_idx}]),
        .noc_in_n({n_in}), .noc_in_s({s_in}), .noc_in_e({e_in}), .noc_in_w({w_in}),
        .noc_out_n(n_out_r{r}_c{c}), .noc_out_s(s_out_r{r}_c{c}), 
        .noc_out_e(e_out_r{r}_c{c}), .noc_out_w(w_out_r{r}_c{c})
    );\n\n"""

    verilog += "    // Edge I/O Assignments\n"
    for c in range(cols):
        verilog += f"    assign io_out_top[{c*64+63}:{c*64}] = n_out_r0_c{c};\n"
        verilog += f"    assign io_out_bottom[{c*64+63}:{c*64}] = s_out_r{rows-1}_c{c};\n"
    for r in range(rows):
        verilog += f"    assign io_out_left[{r*64+63}:{r*64}] = w_out_r{r}_c0;\n"
        verilog += f"    assign io_out_right[{r*64+63}:{r*64}] = e_out_r{r}_c{cols-1};\n"
        
    verilog += "endmodule\n"
    
    with open("rtl/titan_x_infinity_wse.v", "w") as f:
        f.write(verilog)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--rows", type=int, default=16)
    parser.add_argument("--cols", type=int, default=16)
    args = parser.parse_args()
    generate_wse(args.rows, args.cols)
