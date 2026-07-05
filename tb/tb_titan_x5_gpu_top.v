// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

// ----------------------------------------------------------------------------
// Module: tb_titan_x5_gpu_top
// ----------------------------------------------------------------------------
module tb_titan_x5_gpu_top();

    // Framebuffer row stride in pixels. The ROP and display engine both use
    // the DUT's VGA_H_VISIBLE as the stride of the packed framebuffer, so the
    // TB passes this same value down via the parameter override on `dut`.
    localparam FB_STRIDE = 1920;
    // Ring buffer base. VRAM addresses alias modulo 8 MiB (addr[22:0]); the
    // ring lives 1 MiB in so command words don't collide with the shader
    // code at address 0 or the framebuffer region scanned by fb_check.
    localparam [31:0] RING_BASE = 32'h1010_0000;

    reg clk;
    reg mem_clk;
    reg pclk;
    reg rst_n;

    // Host Ring Buffer Interface
    reg  [31:0] host_ring_base;
    reg  [31:0] host_ring_wptr;
    wire [31:0] host_ring_rptr;
    wire        host_intr;

    // AXI4 VRAM Interface
    wire [3:0]   vram_arid;
    wire [31:0]  vram_araddr;
    wire [7:0]   vram_arlen;
    wire [2:0]   vram_arsize;
    wire [1:0]   vram_arburst;
    wire         vram_arvalid;
    reg          vram_arready;
    reg  [3:0]   vram_rid;
    reg  [511:0] vram_rdata;
    reg  [1:0]   vram_rresp;
    reg          vram_rlast;
    reg          vram_rvalid;
    wire         vram_rready;
    wire [3:0]   vram_awid;
    wire [31:0]  vram_awaddr;
    wire [7:0]   vram_awlen;
    wire [2:0]   vram_awsize;
    wire [1:0]   vram_awburst;
    wire         vram_awvalid;
    reg          vram_awready;
    wire [511:0] vram_wdata;
    wire [63:0]  vram_wstrb;
    wire         vram_wlast;
    wire         vram_wvalid;
    reg          vram_wready;
    reg  [3:0]   vram_bid;
    reg  [1:0]   vram_bresp;
    reg          vram_bvalid;
    wire         vram_bready;

    // VGA Output
    wire        vga_hsync;
    wire        vga_vsync;
    wire [7:0]  vga_r;
    wire [7:0]  vga_g;
    wire [7:0]  vga_b;
    wire        vga_de;

    // DUT
    titan_x5_gpu_top #(.VGA_H_VISIBLE(FB_STRIDE)) dut (
        .clk           (clk),
        .mem_clk       (mem_clk),
        .pclk          (pclk),
        .rst_n         (rst_n),
        .host_ring_base(host_ring_base),
        .host_ring_wptr(host_ring_wptr),
        .host_ring_rptr(host_ring_rptr),
        .host_intr     (host_intr),
        .vram_arid     (vram_arid),
        .vram_araddr   (vram_araddr),
        .vram_arlen    (vram_arlen),
        .vram_arsize   (vram_arsize),
        .vram_arburst  (vram_arburst),
        .vram_arvalid  (vram_arvalid),
        .vram_arready  (vram_arready),
        .vram_rid      (vram_rid),
        .vram_rdata    (vram_rdata),
        .vram_rresp    (vram_rresp),
        .vram_rlast    (vram_rlast),
        .vram_rvalid   (vram_rvalid),
        .vram_rready   (vram_rready),
        .vram_awid     (vram_awid),
        .vram_awaddr   (vram_awaddr),
        .vram_awlen    (vram_awlen),
        .vram_awsize   (vram_awsize),
        .vram_awburst  (vram_awburst),
        .vram_awvalid  (vram_awvalid),
        .vram_awready  (vram_awready),
        .vram_wdata    (vram_wdata),
        .vram_wstrb    (vram_wstrb),
        .vram_wlast    (vram_wlast),
        .vram_wvalid   (vram_wvalid),
        .vram_wready   (vram_wready),
        .vram_bid      (vram_bid),
        .vram_bresp    (vram_bresp),
        .vram_bvalid   (vram_bvalid),
        .vram_bready   (vram_bready),
        .vga_hsync     (vga_hsync),
        .vga_vsync     (vga_vsync),
        .vga_r         (vga_r),
        .vga_g         (vga_g),
        .vga_b         (vga_b),
        .vga_de        (vga_de)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end
    initial begin
        mem_clk = 0;
        forever #3 mem_clk = ~mem_clk; // 166 MHz
    end
    initial begin
        pclk = 0;
        forever #7 pclk = ~pclk; // ~71 MHz
    end
    
    integer cycle_count;
    initial begin
        cycle_count = 0;
        forever @(posedge clk) cycle_count = cycle_count + 1;
    end

    // Simulated VRAM Array (8MB = 262144 256-bit words)
    reg [255:0] vram_mem [0:262143];

    integer i;
    initial begin
        for (i=0; i<262144; i=i+1) vram_mem[i] = 256'h0; // clear to black
    end

    reg aw_received;
    reg w_received;
    reg [31:0] latched_awaddr;
    reg [511:0] latched_wdata;
    reg [63:0]  latched_wstrb;
    integer     vram_wr_commits; // total committed AXI writes (used by the render-quiesce wait)
    integer     commit_byte;

    // Simulate memory latency
    reg [3:0] latency_counter;

    always @(posedge mem_clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_arready <= 1'b0;
            vram_awready <= 1'b0;
            vram_wready  <= 1'b0;
            vram_rvalid  <= 1'b0;
            vram_bvalid  <= 1'b0;
            aw_received  <= 1'b0;
            w_received   <= 1'b0;
            latched_awaddr <= 32'h0;
            latched_wdata <= 512'h0;
            latched_wstrb <= 64'h0;
            vram_wr_commits <= 0;
            latency_counter <= 4'h0;
        end else begin
            // Introduce arbitrary random latency
            latency_counter <= latency_counter + 1;
            
            // Ready to accept commands periodically (do not assert ready if we already latched that channel for the current transaction)
            vram_arready <= (latency_counter == 4'hF);
            vram_awready <= (!aw_received && latency_counter == 4'hA);
            vram_wready  <= (!w_received && latency_counter[0] == 1'b1); // Accept data 50% of the time

            // Handle Read
            if (vram_arvalid && vram_arready) begin
                vram_rvalid <= 1'b1;
                vram_rdata  <= {vram_mem[{vram_araddr[22:6], 1'b1}], vram_mem[{vram_araddr[22:6], 1'b0}]};
                vram_rresp  <= 2'b00;
                vram_rlast  <= 1'b1;
                vram_rid    <= vram_arid;
            end else if (vram_rready) begin
                vram_rvalid <= 1'b0;
            end

            // Handle Write Address phase
            if (vram_awvalid && vram_awready) begin
                latched_awaddr <= vram_awaddr;
                aw_received <= 1'b1;
            end

            // Handle Write Data phase
            if (vram_wvalid && vram_wready) begin
                latched_wdata <= vram_wdata;
                latched_wstrb <= vram_wstrb;
                w_received <= 1'b1;
            end

            // Commit Write when both AW and W phases are complete.
            // Honor the byte strobes: the memory controller replicates the
            // 32-bit payload across the 512-bit bus and marks only the
            // addressed word's lanes valid.
            if (aw_received && w_received && !vram_bvalid) begin
                for (commit_byte = 0; commit_byte < 32; commit_byte = commit_byte + 1) begin
                    if (latched_wstrb[commit_byte])
                        vram_mem[{latched_awaddr[22:6], 1'b0}][commit_byte*8 +: 8] <= latched_wdata[commit_byte*8 +: 8];
                    if (latched_wstrb[32 + commit_byte])
                        vram_mem[{latched_awaddr[22:6], 1'b1}][commit_byte*8 +: 8] <= latched_wdata[256 + commit_byte*8 +: 8];
                end
                vram_wr_commits <= vram_wr_commits + 1;
                vram_bvalid <= 1'b1;
                vram_bresp  <= 2'b00;
                vram_bid    <= vram_awid;
                aw_received <= 1'b0;
                w_received  <= 1'b0;
            end else if (vram_bready) begin
                vram_bvalid <= 1'b0;
            end
        end
    end

    // Decode pixel (px,py) from the packed FB_STRIDE-wide framebuffer at
    // VRAM offset 0 (base_color in the DUT is 0).
    function [31:0] get_pixel;
        input integer px;
        input integer py;
        reg [255:0] word;
        integer addr;
        begin
            addr = (py * FB_STRIDE + px) * 4;
            word = vram_mem[addr / 32];
            get_pixel = word[(addr % 32) * 8 +: 32];
        end
    endfunction

    // Framebuffer Dumper (only dumps top-left 64x64 chunk for speed)
    task dump_vram;
        integer fd;
        integer y, x;
        begin
            fd = $fopen("fb_dump.txt", "w");
            for (y = 0; y < 64; y = y + 1) begin
                for (x = 0; x < 64; x = x + 1) begin
                    $fwrite(fd, "%08x\n", get_pixel(x, y));
                end
            end
            $fclose(fd);
            $display("[%0t] Dumped 64x64 framebuffer to fb_dump.txt", $time);
        end
    endtask

    // VRAM writing task for testbench initialization
    task write_vram_word;
        input [31:0] addr;
        input [31:0] data;
        reg [31:0] offset;
        reg [31:0] word_idx;
        reg [2:0] sub_word;
        begin
            // VRAM occupies the low 8 MiB of the address space and aliases
            // above that (the AXI model indexes with addr[22:6]); mirror that
            // here instead of assuming a fixed base.
            offset = addr & 32'h007F_FFFF;
            word_idx = offset / 32;
            sub_word = (offset % 32) / 4;
            case (sub_word)
                0: vram_mem[word_idx][31:0]   = data;
                1: vram_mem[word_idx][63:32]  = data;
                2: vram_mem[word_idx][95:64]  = data;
                3: vram_mem[word_idx][127:96] = data;
                4: vram_mem[word_idx][159:128] = data;
                5: vram_mem[word_idx][191:160] = data;
                6: vram_mem[word_idx][223:192] = data;
                7: vram_mem[word_idx][255:224] = data;
            endcase
        end
    endtask

    integer tid;
    reg [31:0] r_val, g_val, b_val, a_val;
    reg [1023:0] temp_r2, temp_r3, temp_r4;
    // Test sequence
    initial begin
        rst_n          = 0;
        host_ring_base = RING_BASE;
        host_ring_wptr = 32'h0;

        // Initialize Shader instruction at PC=0x0
        // ADD R63, R2, 0 (32'h07E10001)
        write_vram_word(32'h0000_0000, 32'h07E10001);
        
        // Prepare per-thread gradient colors for R2 (deposited into the RF
        // after reset below — the register file zeroes itself while rst_n
        // is low, so a time-0 deposit would be wiped at the first clk edge)
        for (tid = 0; tid < 32; tid = tid + 1) begin
            r_val = tid * 8;
            g_val = 255 - (tid * 8);
            b_val = 128;
            a_val = 255;
            temp_r2[tid*32 +: 32] = {a_val[7:0], b_val[7:0], g_val[7:0], r_val[7:0]};
            temp_r3[tid*32 +: 32] = 32'h1000_0000;
            temp_r4[tid*32 +: 32] = 32'h0000_FF00;
        end

        // Pre-initialize VRAM with DRAW command (17 words)
        // Word 0: Opcode DRAW = 0x01
        write_vram_word(RING_BASE + 0*4,  32'h0000_0001);
        // Word 1-8: Weights (Identity Matrix)
        write_vram_word(RING_BASE + 1*4,  32'h0000_0001); // W00=1, W01=0
        write_vram_word(RING_BASE + 2*4,  32'h0000_0000); // W02=0, W03=0
        write_vram_word(RING_BASE + 3*4,  32'h0001_0000); // W10=0, W11=1
        write_vram_word(RING_BASE + 4*4,  32'h0000_0000); // W12=0, W13=0
        write_vram_word(RING_BASE + 5*4,  32'h0000_0000); // W20=0, W21=0
        write_vram_word(RING_BASE + 6*4,  32'h0000_0001); // W22=1, W23=0
        write_vram_word(RING_BASE + 7*4,  32'h0000_0000); // W30=0, W31=0
        write_vram_word(RING_BASE + 8*4,  32'h0064_0000); // W32=0, W33=100
        // Word 9-16: Vertices
        write_vram_word(RING_BASE + 9*4,  32'h0000_0000); // v0_x=0, v0_y=0
        write_vram_word(RING_BASE + 10*4, 32'h0001_0000); // v0_z=0, v0_w=1
        write_vram_word(RING_BASE + 11*4, 32'h0000_0014); // v1_x=20, v1_y=0
        write_vram_word(RING_BASE + 12*4, 32'h0001_0000); // v1_z=0, v1_w=1
        write_vram_word(RING_BASE + 13*4, 32'h0010_0000); // v2_x=0, v2_y=16
        write_vram_word(RING_BASE + 14*4, 32'h0001_0000); // v2_z=0, v2_w=1
        write_vram_word(RING_BASE + 15*4, 32'h0000_0000); // v3_x=0, v3_y=0
        write_vram_word(RING_BASE + 16*4, 32'h0001_0000); // v3_z=0, v3_w=1

        // Pre-initialize VRAM with FENCE command (17 words)
        // Word 17: Opcode FENCE = 0x04
        write_vram_word(RING_BASE + 17*4, 32'h0000_0004);
        // Words 18-33: Payload (all 0)
        for (i = 18; i < 34; i = i + 1) begin
            write_vram_word(RING_BASE + i*4, 32'h0000_0000);
        end

        $dumpfile("blackwell_wave.vcd");
        $dumpvars(0, tb_titan_x5_gpu_top);

        $display("==================================================");
        $display("  TITAN X5 GPU TOP-LEVEL GRAPHICS PIPELINE TEST  ");
        $display("==================================================");

        #20; rst_n = 1; #20;

        // Backdoor-initialize SM0's register file now that reset is done:
        // R2 = per-thread gradient colors (bank = reg%4, entry = reg/4)
        dut.sm_gen[0].u_sm.rf_inst.bank_gen[2].bank_mem[0] = temp_r2;
        dut.sm_gen[0].u_sm.rf_inst.bank_gen[3].bank_mem[0] = temp_r3;
        dut.sm_gen[0].u_sm.rf_inst.bank_gen[0].bank_mem[1] = temp_r4;

        $display("[%0t] Reset done. Queuing CMD_DRAW into ring buffer...", $time);

        @(posedge clk); host_ring_wptr = 32'd34; // Trigger DRAW & FENCE
        #50;

        $display("[%0t] Waiting for Rasterizer to complete rendering...", $time);

        // Wait adaptively: the render is done when no new VRAM write has
        // committed for 3 consecutive 10us windows (the ROP's idle-timeout
        // flush guarantees trailing pixels drain). Hard cap of 50 windows
        // (500us) so a hung pipeline still terminates and fails the checks.
        begin : wait_render
            integer prev_commits, idle_windows, waited_windows;
            prev_commits = -1;
            idle_windows = 0;
            waited_windows = 0;
            while (idle_windows < 3 && waited_windows < 50) begin
                #10000;
                waited_windows = waited_windows + 1;
                if (vram_wr_commits == prev_commits && vram_wr_commits > 0)
                    idle_windows = idle_windows + 1;
                else
                    idle_windows = 0;
                prev_commits = vram_wr_commits;
            end
            $display("[%0t] Render quiesced after %0d windows (%0d VRAM write commits).",
                     $time, waited_windows, vram_wr_commits);
        end

        $display("[%0t] Rendering cycle complete. Dumping VRAM...", $time);
        dump_vram();

        // Check if framebuffer contains non-zero pixels
        // Check actual output (Self-Checking)
        begin: fb_check
            integer px_x, px_y;
            reg [31:0] pixel;
            integer pixels_drawn;
            integer oob_pixels;

            pixels_drawn = 0;
            oob_pixels = 0;

            for (px_y = 0; px_y < 64; px_y = px_y + 1) begin
                for (px_x = 0; px_x < 64; px_x = px_x + 1) begin
                    // Pixel (0,0) shares VRAM bytes 0-3 with the shader
                    // instruction at PC=0 (the SMs boot from address 0);
                    // it is code, not rasterizer output, so skip it.
                    if (px_x != 0 || px_y != 0) begin
                        pixel = get_pixel(px_x, px_y);
                        if (pixel != 0) begin
                            pixels_drawn = pixels_drawn + 1;
                            // Bounding box of triangle is X: 16-36, Y: 16-32
                            if (px_x < 16 || px_x > 36 || px_y < 16 || px_y > 32) begin
                                oob_pixels = oob_pixels + 1;
                                $display("  OOB pixel at (%0d,%0d) = %08x", px_x, px_y, pixel);
                            end
                        end
                    end
                end
            end

            // Probe a pixel that must be covered: (16,30) lies on the left
            // edge of the transformed triangle (16,16)-(36,16)-(16,32).
            if (get_pixel(16, 30) != 32'd0) begin
                $display("Rendering test passed!");
            end else begin
                $display("Rendering test failed! No pixel at (16,30).");
            end

            $display("Coverage Metrics:");
            $display("  Pixels Drawn inside Bounding Box: %0d", pixels_drawn - oob_pixels);
            $display("  Pixels Drawn OUTSIDE Bounding Box: %0d", oob_pixels);
            
            if (pixels_drawn == 0) begin
                $display("==================================================");
                $fatal(1, "  FATAL ERROR: Framebuffer is completely empty!   ");
                $display("  VRAM writes failed, or pipeline is stalled.    ");
                $display("==================================================");
            end else if (oob_pixels > 0) begin
                $display("==================================================");
                $fatal(1, "  FATAL ERROR: Rasterizer drew out of bounds!    ");
                $display("==================================================");
            end else begin
                $display("==================================================");
                $display("  TITAN X5 GPU: RENDERING TEST PASSED (SELF-CHECKING)!");
                $display("  PERFORMANCE METRICS:");
                $display("  Total Clock Cycles: %0d", cycle_count);
                $display("  Estimated Time (at 1 GHz): %0d ns", cycle_count);
                $display("==================================================");
            end
        end

        $finish;
    end

    // Snooping debug monitors
    always @(posedge clk) begin
        if (dut.cmd_valid) $display("[%0t] CMD_PROC: Valid command issued! Opcode: %0h", $time, dut.cmd_opcode);
        // if (dut.u_rasterizer.o_valid) $display("[%0t] RASTERIZER: Pixel generated at (%0d, %0d) ready=%b", $time, dut.u_rasterizer.o_x, dut.u_rasterizer.o_y, dut.u_rasterizer.o_ready);
        if (vram_awvalid && vram_awready) $display("[%0t] VRAM: Write requested at Addr %0x", $time, vram_awaddr);
        
        // ADDED DEBUG LOGIC
        if ($time > 300000 && $time < 350000) begin
            $display("[%0t] TMU State: %0d, ROP State: %0d, rop_o_ready: %b, tmu_o_valid: %b", 
                     $time, dut.dbg_tmu_state, dut.dbg_rop_state, dut.rop_o_ready, dut.tmu_o_valid);
        end
    end

endmodule
