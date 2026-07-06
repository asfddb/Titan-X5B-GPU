import os
import subprocess

def generate_scanner(rows, cols):
    num_cores = rows * cols
    print(f"Generating Diagnostic Scan Testbench for {rows}x{cols} ({num_cores} Cores)...")
    
    tb = f"""`timescale 1ns/1ps

module tb_wafer_scan();
    reg clk;
    reg rst_n;
    reg [{num_cores}-1:0] defect_fuses;
    
    reg  [{cols*64-1}:0] io_in_top;
    wire [{cols*64-1}:0] io_out_top;
    reg  [{cols*64-1}:0] io_in_bottom;
    wire [{cols*64-1}:0] io_out_bottom;
    reg  [{rows*64-1}:0] io_in_left;
    wire [{rows*64-1}:0] io_out_left;
    reg  [{rows*64-1}:0] io_in_right;
    wire [{rows*64-1}:0] io_out_right;

    titan_x_infinity_wse u_wse (
        .clk(clk), .rst_n(rst_n), .defect_fuses(defect_fuses),
        .io_in_top(io_in_top), .io_out_top(io_out_top),
        .io_in_bottom(io_in_bottom), .io_out_bottom(io_out_bottom),
        .io_in_left(io_in_left), .io_out_left(io_out_left),
        .io_in_right(io_in_right), .io_out_right(io_out_right)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        defect_fuses = 0;
        io_in_top = 0; io_in_bottom = 0; io_in_left = 0; io_in_right = 0;
        #20 rst_n = 1;
        
        $display("Starting Single-Core Diagnostic Scan...");
"""
    
    for r in range(rows):
        for c in range(cols):
            # Send packet to Target X=c, Y=r with Payload=0xCAFE
            # Packet: [63:48]=DestX, [47:32]=DestY, [31:0]=Payload
            tb += f"        // Scanning Core ({c}, {r})\n"
            tb += f"        io_in_top[{c*64+63}:{c*64}] = {{16'd{c}, 16'd{r}, 32'h0000CAFE}};\n"
            tb += f"        #500; // Hold inputs steady\n"
            tb += f"        io_in_top[{c*64+63}:{c*64}] = 0;\n"
            # Output is expected to come out the nearest edge, let's just log io_out_bottom for now 
            # Actually, our NoC core responds by sending out_e or out_s. 
            # If we just watch the bottom edge of column `c` and right edge of row `r` we can catch it.
            tb += f"        $display(\"SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.\", {c}, {r}, io_out_bottom[{c*64+31}:{c*64}]);\n"

    tb += """
        $display("SCAN_COMPLETE");
        $finish;
    end
endmodule
"""
    os.makedirs("tb", exist_ok=True)
    with open("tb/tb_wafer_scan.v", "w") as f:
        f.write(tb)

def run_scan():
    rows, cols = 16, 16
    print(f"1. Generating {rows}x{cols} Wafer Scale Engine...")
    subprocess.run(f"python generate_titan_wse.py --rows {rows} --cols {cols}", shell=True, check=True)
    
    generate_scanner(rows, cols)
    
    print("2. Compiling Wafer Scanner Testbench...")
    compile_cmd = "iverilog -g2012 -o scan_sim.vvp tb/tb_wafer_scan.v rtl/titan_x_infinity_wse.v rtl/titan_x_wse_sm.v"
    subprocess.run(compile_cmd, shell=True, check=True)
    
    print("3. Executing Deterministic Single-Core Scan...")
    run_cmd = "vvp scan_sim.vvp"
    result = subprocess.run(run_cmd, shell=True, capture_output=True, text=True)
    
    verified = 0
    total = rows * cols
    
    for line in result.stdout.split("\n"):
        if "SCAN_RESULT:" in line:
            # We inverted CAFE = 3501 (inverted 32-bit = FFFF3501)
            if "ffff3501" in line.lower():
                verified += 1
                
    print("\n=======================================================")
    print("TITAN WAFER DIAGNOSTIC: SINGLE-CORE SCAN REPORT")
    print("=======================================================")
    print(f"Total Cores Scanned : {total}")
    print(f"Cores Responsive    : {verified}")
    print(f"Cores Unresponsive  : {total - verified}")
    print("=======================================================")
    
    if verified == total:
        print("RESULT: SUCCESS - 100% Core Yield Verified.")
    else:
        print("RESULT: FAILURE - Dead zones or routing errors detected.")

if __name__ == "__main__":
    run_scan()
