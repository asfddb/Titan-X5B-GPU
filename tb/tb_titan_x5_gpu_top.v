`timescale 1ns / 1ps

// ----------------------------------------------------------------------------
// Module: tb_titan_x5_gpu_top
// ----------------------------------------------------------------------------
module tb_titan_x5_gpu_top();

    reg clk;
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
    titan_x5_gpu_top dut (
        .clk           (clk),
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

    // Clock generation (100 MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Simulated VRAM Array (8MB = 262144 256-bit words)
    reg [255:0] vram_mem [0:262143];
    // (active_awaddr removed - replaced by latched_awaddr in AXI write FSM)

    integer i;
    initial begin
        for (i=0; i<262144; i=i+1) vram_mem[i] = 256'h0; // clear to black
    end

    // AXI write state machine - handles AW and W phases correctly
    // The memory controller may send AW and W simultaneously, so we
    // need to capture the address before using it for the data write.
    reg aw_received;
    reg [31:0] latched_awaddr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_arready <= 1'b0;
            vram_awready <= 1'b0;
            vram_wready  <= 1'b0;
            vram_rvalid  <= 1'b0;
            vram_bvalid  <= 1'b0;
            aw_received  <= 1'b0;
            latched_awaddr <= 32'h0;
        end else begin
            // Ready to accept commands
            vram_arready <= 1'b1;
            vram_awready <= !aw_received; // Don't accept new AW while waiting for W
            vram_wready  <= 1'b1;

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

            // Handle Write Data phase (only after address is captured)
            if (vram_wvalid && vram_wready && aw_received) begin
                vram_mem[{latched_awaddr[22:6], 1'b0}] <= vram_wdata[255:0];
                vram_mem[{latched_awaddr[22:6], 1'b1}] <= vram_wdata[511:256];
                vram_bvalid <= 1'b1;
                vram_bresp  <= 2'b00;
                vram_bid    <= vram_awid;
                aw_received <= 1'b0;
            end else if (vram_bready) begin
                vram_bvalid <= 1'b0;
            end
        end
    end

    // Framebuffer Dumper (only dumps top-left 64x64 chunk for speed)
    task dump_vram;
        integer fd;
        integer y, x;
        reg [31:0] pixel;
        reg [255:0] word;
        integer addr;
        begin
            fd = $fopen("fb_dump.txt", "w");
            for (y = 0; y < 64; y = y + 1) begin
                for (x = 0; x < 64; x = x + 1) begin
                    // True address in bytes for 1024x768 stride
                    addr = (y * 1024 + x) * 4;
                    word = vram_mem[addr / 32];
                    
                    case ((addr % 32) / 4)
                        0: pixel = word[31:0];
                        1: pixel = word[63:32];
                        2: pixel = word[95:64];
                        3: pixel = word[127:96];
                        4: pixel = word[159:128];
                        5: pixel = word[191:160];
                        6: pixel = word[223:192];
                        7: pixel = word[255:224];
                    endcase
                    $fwrite(fd, "%08x\n", pixel);
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
            offset = addr - 32'h1000_0000;
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

    // Test sequence
    initial begin
        rst_n          = 0;
        host_ring_base = 32'h1000_0000;
        host_ring_wptr = 32'h0;

        // Pre-initialize VRAM with DRAW command (17 words)
        // Word 0: Opcode DRAW = 0x01
        write_vram_word(32'h1000_0000 + 0*4,  32'h0000_0001);
        // Word 1-8: Weights (Identity Matrix)
        write_vram_word(32'h1000_0000 + 1*4,  32'h0000_0001); // W00=1, W01=0
        write_vram_word(32'h1000_0000 + 2*4,  32'h0000_0000); // W02=0, W03=0
        write_vram_word(32'h1000_0000 + 3*4,  32'h0001_0000); // W10=0, W11=1
        write_vram_word(32'h1000_0000 + 4*4,  32'h0000_0000); // W12=0, W13=0
        write_vram_word(32'h1000_0000 + 5*4,  32'h0000_0000); // W20=0, W21=0
        write_vram_word(32'h1000_0000 + 6*4,  32'h0000_0001); // W22=1, W23=0
        write_vram_word(32'h1000_0000 + 7*4,  32'h0000_0000); // W30=0, W31=0
        write_vram_word(32'h1000_0000 + 8*4,  32'h0001_0000); // W32=0, W33=1
        // Word 9-16: Vertices
        write_vram_word(32'h1000_0000 + 9*4,  32'h0000_0000); // v0_x=0, v0_y=0
        write_vram_word(32'h1000_0000 + 10*4, 32'h0001_0000); // v0_z=0, v0_w=1
        write_vram_word(32'h1000_0000 + 11*4, 32'h0000_0014); // v1_x=20, v1_y=0
        write_vram_word(32'h1000_0000 + 12*4, 32'h0001_0000); // v1_z=0, v1_w=1
        write_vram_word(32'h1000_0000 + 13*4, 32'h0005_0005); // v2_x=5, v2_y=5
        write_vram_word(32'h1000_0000 + 14*4, 32'h0001_0000); // v2_z=0, v2_w=1
        write_vram_word(32'h1000_0000 + 15*4, 32'h0000_0000); // v3_x=0, v3_y=0
        write_vram_word(32'h1000_0000 + 16*4, 32'h0001_0000); // v3_z=0, v3_w=1

        // Pre-initialize VRAM with FENCE command (17 words)
        // Word 17: Opcode FENCE = 0x04
        write_vram_word(32'h1000_0000 + 17*4, 32'h0000_0004);
        // Words 18-33: Payload (all 0)
        for (i = 18; i < 34; i = i + 1) begin
            write_vram_word(32'h1000_0000 + i*4, 32'h0000_0000);
        end

        $dumpfile("waves_gpu_top.vcd");
        $dumpvars(0, tb_titan_x5_gpu_top);

        $display("==================================================");
        $display("  TITAN X5 GPU TOP-LEVEL GRAPHICS PIPELINE TEST  ");
        $display("==================================================");

        #20; rst_n = 1; #20;

        $display("[%0t] Reset done. Queuing CMD_DRAW into ring buffer...", $time);

        @(posedge clk); host_ring_wptr = 32'd34; // Trigger DRAW & FENCE
        #50;

        $display("[%0t] Waiting for Rasterizer to complete rendering...", $time);
        
        // Wait long enough for full command fetch + rasterize + flush
        // At 1920x1080, the display engine contends heavily on the crossbar,
        // so the command processor takes ~14ms to fetch all 17 words.
        #20000000; 

        $display("[%0t] Rendering cycle complete. Dumping VRAM...", $time);
        dump_vram();

        // Check if framebuffer contains non-zero pixels
        begin: fb_check
            integer fb_word_idx;
            reg fb_non_zero;
            fb_non_zero = 0;
            for (fb_word_idx = 8; fb_word_idx < 262144; fb_word_idx = fb_word_idx + 1) begin
                if (vram_mem[fb_word_idx] != 256'h0) begin
                    fb_non_zero = 1;
                end
            end
            if (!fb_non_zero) begin
                $display("==================================================");
                $display("  FATAL ERROR: Framebuffer is completely empty!   ");
                $display("==================================================");
                $fatal;
            end else begin
                $display("==================================================");
                $display("  TITAN X5 GPU: RENDERING TEST PASSED!           ");
                $display("==================================================");
            end
        end

        $finish;
    end

    // Snooping debug monitors
    always @(posedge clk) begin
        if (dut.cmd_valid) $display("[%0t] CMD_PROC: Valid command issued! Opcode: %0h", $time, dut.cmd_opcode);
        if (dut.u_rasterizer.o_valid) $display("[%0t] RASTERIZER: Pixel generated at (%0d, %0d) ready=%b", $time, dut.u_rasterizer.o_x, dut.u_rasterizer.o_y, dut.u_rasterizer.o_ready);
        if (vram_awvalid && vram_awready) $display("[%0t] VRAM: Write requested at Addr %0x", $time, vram_awaddr);
        
        // ADDED DEBUG LOGIC
        if ($time > 300000 && $time < 350000) begin
            $display("[%0t] TMU State: %0d, ROP State: %0d, rop_o_ready: %b, tmu_o_valid: %b", 
                     $time, dut.dbg_tmu_state, dut.dbg_rop_state, dut.rop_o_ready, dut.tmu_o_valid);
        end
    end

endmodule
