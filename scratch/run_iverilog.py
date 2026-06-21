import subprocess
import glob
import os

def main():
    env_bat = r"C:\tools\oss-cad-suite\oss-cad-suite\environment.bat"
    
    # Files
    tb_file = "tb/tb_titan_x5_gpu_top.v"
    top_file = "rtl/titan_x5_gpu_top.v"
    
    # Wildcards to expand
    wildcards = [
        "rtl/tensor/*.v",
        "rtl/raytracing/*.v",
        "rtl/memory/*.v",
        "rtl/graphics/*.v",
        "rtl/interconnect/*.v",
        "rtl/core/*.v",
        "rtl/control/*.v",
        "rtl/sr/*.v",
        "rtl/power/*.v",
        "rtl/display/*.v",
        "rtl/common/*.v"
    ]
    
    expanded_files = []
    for wc in wildcards:
        expanded_files.extend(glob.glob(wc))
        
    expanded_files = [os.path.abspath(f) for f in expanded_files]
    
    all_files = [os.path.abspath(tb_file), os.path.abspath(top_file)] + expanded_files
    # Exclude duplicates
    all_files = list(set(all_files))
    
    # Convert paths to relative for clean command line
    rel_files = [os.path.relpath(f, os.getcwd()).replace("\\", "/") for f in all_files]
    
    files_str = " ".join(rel_files)
    
    compile_cmd = f'iverilog -g2012 -I rtl -o tb/ultimate_blackwell.vvp {files_str}'
    run_cmd = 'vvp tb/ultimate_blackwell.vvp'
    
    full_cmd = f'"{env_bat}" && {compile_cmd} && {run_cmd}'
    print("Running command:", full_cmd)
    
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
    
    print("STDOUT:")
    print(result.stdout)
    print("STDERR:")
    print(result.stderr)
    print("Exit code:", result.returncode)

if __name__ == "__main__":
    main()
