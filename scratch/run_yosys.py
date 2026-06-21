import subprocess
import os

def main():
    env_bat = r"C:\tools\oss-cad-suite\oss-cad-suite\environment.bat"
    
    files = [
        "rtl/titan_x5_gpu_top.v",
        "rtl/control/titan_x5_command_processor.v",
        "rtl/graphics/titan_x5_vertex_transformer.v",
        "rtl/core/titan_x5_sm.v",
        "rtl/core/titan_x5_register_file.v",
        "rtl/core/titan_x5_alu.v",
        "rtl/core/titan_x5_decoder.v",
        "rtl/core/titan_x5_pipeline.v",
        "rtl/core/titan_x5_warp_scheduler.v",
        "rtl/graphics/titan_x5_rasterizer.v",
        "rtl/graphics/titan_x5_tmu.v",
        "rtl/graphics/titan_x5_rop.v",
        "rtl/raytracing/titan_x5_rt_core.v",
        "rtl/raytracing/titan_x5_ray_triangle_isect.v",
        "rtl/interconnect/titan_x5_dma_engine.v",
        "rtl/power/titan_x5_power_mgmt.v",
        "rtl/control/titan_x5_perf_counters.v",
        "rtl/memory/titan_x5_mem_controller.v",
        "rtl/display/titan_x5_display_engine.v",
        "rtl/memory/titan_x5_gddr7_pam3_phy.v",
        "rtl/graphics/titan_x5_neural_shader_dispatch.v",
        "rtl/interconnect/titan_x5_crossbar.v",
        "rtl/sr/titan_x5_sr_engine.v",
        "rtl/sr/titan_x5_hash_fnv64.v",
        "rtl/common/titan_x5_skid_buffer.v",
        "rtl/display/titan_x5_async_fifo.v",
        "rtl/memory/titan_x5_shared_memory.v",
        "rtl/memory/titan_x5_l1_cache.v",
        "rtl/memory/titan_x5_l2_cache.v"
    ]
    
    # Ensure they exist
    files = [f for f in files if os.path.exists(f)]
    
    print(f"Found {len(files)} files for synthesis.")
    
    files_str = " ".join(files)
    yosys_cmd = f"read_verilog -sv {files_str}; hierarchy -top titan_x5_gpu_top; synth; stat"
    
    full_cmd = f'"{env_bat}" && yosys -p "{yosys_cmd}"'
    
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
    
    with open("synthesis_report_top.txt", "w", encoding="utf-8") as f:
        f.write(result.stdout)
        f.write(result.stderr)
        
    print("Exit code:", result.returncode)
    if result.returncode != 0:
        print("Error during Yosys run:")
        lines = (result.stderr + result.stdout).splitlines()
        for line in lines[-50:]:
            print(line)
    else:
        print("Synthesis completed successfully! Output saved to synthesis_report_top.txt")

if __name__ == "__main__":
    main()
