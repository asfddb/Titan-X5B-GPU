`timescale 1ns / 1ps

// Focused debug testbench to trace ROP tile flush through the crossbar
module debug_rop_flush();
    reg clk;
    reg rst_n;

    reg  [31:0] host_ring_base;
    reg  [31:0] host_ring_wptr;
    wire [31:0] host_ring_rptr;
    wire        host_intr;

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

    wire vga_hsync, vga_vsync, vga_de;
    wire [7:0] vga_r, vga_g, vga_b;

    titan_x5_gpu_top #(
        .VGA_H_VISIBLE(32),
        .VGA_V_VISIBLE(32)
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .host_ring_base(host_ring_base),
        .host_ring_wptr(host_ring_wptr),
        .host_ring_rptr(host_ring_rptr),
        .host_intr(host_intr),
        .vram_arid(vram_arid), .vram_araddr(vram_araddr), .vram_arlen(vram_arlen),
        .vram_arsize(vram_arsize), .vram_arburst(vram_arburst), .vram_arvalid(vram_arvalid),
        .vram_arready(vram_arready), .vram_rid(vram_rid), .vram_rdata(vram_rdata),
        .vram_rresp(vram_rresp), .vram_rlast(vram_rlast), .vram_rvalid(vram_rvalid),
        .vram_rready(vram_rready), .vram_awid(vram_awid), .vram_awaddr(vram_awaddr),
        .vram_awlen(vram_awlen), .vram_awsize(vram_awsize), .vram_awburst(vram_awburst),
        .vram_awvalid(vram_awvalid), .vram_awready(vram_awready), .vram_wdata(vram_wdata),
        .vram_wstrb(vram_wstrb), .vram_wlast(vram_wlast), .vram_wvalid(vram_wvalid),
        .vram_wready(vram_wready), .vram_bid(vram_bid), .vram_bresp(vram_bresp),
        .vram_bvalid(vram_bvalid), .vram_bready(vram_bready),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .vga_de(vga_de)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // VRAM model
    reg [255:0] vram_mem [0:262143];
    reg [31:0] active_awaddr;
    integer i;

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

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vram_arready <= 1'b0;
            vram_awready <= 1'b0;
            vram_wready  <= 1'b0;
            vram_rvalid  <= 1'b0;
            vram_bvalid  <= 1'b0;
        end else begin
            vram_arready <= 1'b1;
            vram_awready <= 1'b1;
            vram_wready  <= 1'b1;

            if (vram_arvalid && vram_arready) begin
                vram_rvalid <= 1'b1;
                vram_rdata  <= {vram_mem[{vram_araddr[22:6], 1'b1}], vram_mem[{vram_araddr[22:6], 1'b0}]};
                vram_rresp  <= 2'b00;
                vram_rlast  <= 1'b1;
                vram_rid    <= vram_arid;
            end else if (vram_rready) begin
                vram_rvalid <= 1'b0;
            end

            if (vram_awvalid && vram_awready) begin
                active_awaddr <= vram_awaddr;
            end

            if (vram_wvalid && vram_wready) begin
                vram_mem[{active_awaddr[22:6], 1'b0}] <= vram_wdata[255:0];
                vram_mem[{active_awaddr[22:6], 1'b1}] <= vram_wdata[511:256];
                vram_bvalid <= 1'b1;
                vram_bresp  <= 2'b00;
                vram_bid    <= vram_awid;
            end else if (vram_bready) begin
                vram_bvalid <= 1'b0;
            end
        end
    end

    initial begin
        for (i=0; i<262144; i=i+1) vram_mem[i] = 256'h0;

        // DRAW command
        write_vram_word(32'h1000_0000 + 0*4,  32'h0000_0001);
        write_vram_word(32'h1000_0000 + 1*4,  32'h0000_0001);
        write_vram_word(32'h1000_0000 + 2*4,  32'h0000_0000);
        write_vram_word(32'h1000_0000 + 3*4,  32'h0001_0000);
        write_vram_word(32'h1000_0000 + 4*4,  32'h0000_0000);
        write_vram_word(32'h1000_0000 + 5*4,  32'h0000_0000);
        write_vram_word(32'h1000_0000 + 6*4,  32'h0000_0001);
        write_vram_word(32'h1000_0000 + 7*4,  32'h0000_0000);
        write_vram_word(32'h1000_0000 + 8*4,  32'h0001_0000);
        write_vram_word(32'h1000_0000 + 9*4,  32'h0000_0000);
        write_vram_word(32'h1000_0000 + 10*4, 32'h0001_0000);
        write_vram_word(32'h1000_0000 + 11*4, 32'h0000_0014);
        write_vram_word(32'h1000_0000 + 12*4, 32'h0001_0000);
        write_vram_word(32'h1000_0000 + 13*4, 32'h0005_0005);
        write_vram_word(32'h1000_0000 + 14*4, 32'h0001_0000);
        write_vram_word(32'h1000_0000 + 15*4, 32'h0000_0000);
        write_vram_word(32'h1000_0000 + 16*4, 32'h0001_0000);
        // FENCE
        write_vram_word(32'h1000_0000 + 17*4, 32'h0000_0004);
        for (i = 18; i < 34; i = i + 1)
            write_vram_word(32'h1000_0000 + i*4, 32'h0000_0000);

        $dumpfile("scratch/debug_flush.vcd");
        $dumpvars(0, debug_rop_flush);

        rst_n = 0;
        host_ring_base = 32'h1000_0000;
        host_ring_wptr = 32'h0;

        #20; rst_n = 1; #20;
        @(posedge clk); host_ring_wptr = 32'd34;

        #300000;

        $display("=== DEBUG ROP FLUSH TEST COMPLETE ===");
        $display("ROP flush_state = %0d", dut.rop_gen[0].u_rop.flush_state);
        $display("ROP flush_idx = %0d", dut.rop_gen[0].u_rop.flush_idx);
        $display("ROP tile_dirty = %0h", dut.rop_gen[0].u_rop.tile_dirty);
        $display("ROP mem_req = %0b", dut.rop_gen[0].u_rop.mem_req);
        $display("ROP mem_gnt = %0b", dut.rop_gen[0].u_rop.mem_gnt);
        $display("ROP mem_valid = %0b", dut.rop_gen[0].u_rop.mem_valid);
        $display("MC state = %0d", dut.u_mem_ctrl.state);
        $display("MC resp_valid = %0b", dut.u_mem_ctrl.resp_valid);
        $display("XBAR s_resp_valid = %0b", dut.u_sys_crossbar.s_resp_valid);
        $display("XBAR m_resp_valid[5] = %0b", dut.u_sys_crossbar.m_resp_valid[5]);
        $display("XBAR fifo_count[0] = %0d", dut.u_sys_crossbar.fifo_count[0]);

        $finish;
    end

    // Debug trace during flush
    always @(posedge clk) begin
        if (dut.rop_gen[0].u_rop.flush_state != 0) begin
            $display("[%0t] FLUSH: state=%0d idx=%0d mem_req=%b mem_gnt=%b mem_valid=%b mem_we=%b addr=%0h | MC_state=%0d MC_resp=%b | XBAR_fifo=%0d s_resp=%b m_resp5=%b",
                $time,
                dut.rop_gen[0].u_rop.flush_state,
                dut.rop_gen[0].u_rop.flush_idx,
                dut.rop_gen[0].u_rop.mem_req,
                dut.rop_gen[0].u_rop.mem_gnt,
                dut.rop_gen[0].u_rop.mem_valid,
                dut.rop_gen[0].u_rop.mem_we,
                dut.rop_gen[0].u_rop.mem_addr,
                dut.u_mem_ctrl.state,
                dut.u_mem_ctrl.resp_valid,
                dut.u_sys_crossbar.fifo_count[0],
                dut.u_sys_crossbar.s_resp_valid,
                dut.u_sys_crossbar.m_resp_valid[5]
            );
        end
    end

endmodule
