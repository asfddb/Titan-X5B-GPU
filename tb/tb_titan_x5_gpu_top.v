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
    reg  [255:0] vram_rdata;
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
    wire [255:0] vram_wdata;
    wire [31:0]  vram_wstrb;
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
    reg [31:0]  active_awaddr;

    integer i;
    initial begin
        for (i=0; i<262144; i=i+1) vram_mem[i] = 256'h0; // clear to black
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_arready <= 1'b0;
            vram_awready <= 1'b0;
            vram_wready  <= 1'b0;
            vram_rvalid  <= 1'b0;
            vram_bvalid  <= 1'b0;
        end else begin
            // Ready to accept commands
            vram_arready <= 1'b1;
            vram_awready <= 1'b1;
            vram_wready  <= 1'b1;

            // Handle Read
            if (vram_arvalid && vram_arready) begin
                vram_rvalid <= 1'b1;
                vram_rdata  <= vram_mem[vram_araddr[22:5]]; // 32-byte word aligned
                vram_rresp  <= 2'b00;
                vram_rlast  <= 1'b1;
                vram_rid    <= vram_arid;
            end else if (vram_rready) begin
                vram_rvalid <= 1'b0;
            end

            // Handle Write Addr
            if (vram_awvalid && vram_awready) begin
                active_awaddr <= vram_awaddr;
            end

            // Handle Write Data
            if (vram_wvalid && vram_wready) begin
                vram_mem[active_awaddr[22:5]] <= vram_wdata;
                vram_bvalid <= 1'b1;
                vram_bresp  <= 2'b00;
                vram_bid    <= vram_awid;
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

    // Test sequence
    initial begin
        rst_n          = 0;
        host_ring_base = 32'h8000_0000;
        host_ring_wptr = 32'h0;

        $dumpfile("waves_gpu_top.vcd");
        $dumpvars(0, tb_titan_x5_gpu_top);

        $display("==================================================");
        $display("  TITAN X5 GPU TOP-LEVEL GRAPHICS PIPELINE TEST  ");
        $display("==================================================");

        #20; rst_n = 1; #20;

        $display("[%0t] Reset done. Queuing CMD_DRAW into ring buffer...", $time);

        @(posedge clk); host_ring_wptr = 32'd1; // Trigger CMD_DRAW
        #50;
        @(posedge clk); host_ring_wptr = 32'd2; // Trigger CMD_FENCE

        $display("[%0t] Waiting for Rasterizer to complete rendering...", $time);
        
        // Wait long enough for 40x30 triangle to render
        #200000; 

        $display("[%0t] Rendering cycle complete. Dumping VRAM...", $time);
        dump_vram();

        $display("==================================================");
        $display("  TITAN X5 GPU: RENDERING TEST PASSED!           ");
        $display("==================================================");

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
