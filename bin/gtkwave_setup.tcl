set facs [list]

# Find top-level signals
set all_facs [gtkwave::getNumFacs]

# Let's add some important signals explicitly
catch {lappend facs "tb_titan_x5_gpu_top.clk"}
catch {lappend facs "tb_titan_x5_gpu_top.rst_n"}
catch {lappend facs "tb_titan_x5_gpu_top.cmd_valid"}
catch {lappend facs "tb_titan_x5_gpu_top.cmd_ready"}
catch {lappend facs "tb_titan_x5_gpu_top.cmd_data\[63:0\]"}

# Rasterizer signals
catch {lappend facs "tb_titan_x5_gpu_top.dut.u_rasterizer.pixel_x\[15:0\]"}
catch {lappend facs "tb_titan_x5_gpu_top.dut.u_rasterizer.pixel_y\[15:0\]"}
catch {lappend facs "tb_titan_x5_gpu_top.dut.u_rasterizer.valid_out"}

# Add them to the viewer
set num_added [gtkwave::addSignalsFromList $facs]

# Zoom to fit the entire simulation
gtkwave::/Time/Zoom/Zoom_Full
