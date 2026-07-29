// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Compute-only full-chip testbench.
//
// tb_titan_x5_gpu_top drives the graphics path: it queues a DRAW into the ring
// buffer and judges the result by the rendered image. That is the right test
// for the raster pipeline but the wrong shape for a compute kernel, where the
// answer is a block of words in VRAM rather than pixels.
//
// This testbench boots the same titan_x5_gpu_top, but:
//   * loads an arbitrary program (produced by compiler/titan_compiler.py)
//     into VRAM at CODE_BASE,
//   * loads an arbitrary input image into VRAM at DATA_BASE,
//   * lets the SMs launch out of reset (titan_x5_gpu_top does this itself),
//   * waits for every warp of every SM to retire,
//   * dumps a window of VRAM so a Python reference can check it word for word.
//
// Everything is driven by plusargs so one compiled image serves many kernels:
//
//   +PROG=<file>     hex, one instruction word per line, loaded at CODE_BASE
//   +DATA=<file>     hex, one 32-bit word per line, loaded at DATA_BASE
//   +OUT=<file>      where to write the result words
//   +RESBASE=<hex>   VRAM byte address of the first result word
//   +NRES=<n>        how many result words to dump
//   +MAXCYC=<n>      watchdog, in clk cycles (default 2,000,000)
//
// Threads are redundant, not partitioned: every launched warp on every SM runs
// the same program with the same register state, so a kernel must be
// idempotent (each thread computes and stores the same value). That is true of
// the scalar kernels the compiler emits today, which are written as
// single-threaded code. It is the reason LAUNCH_WARP_MASK defaults to one warp
// here -- more warps only add redundant work and coherence traffic.
module tb_compute_top();

    // Which warps each SM launches. Overridden at elaboration with
    // `iverilog -P tb_compute_top.LAUNCH_MASK=255` for the multi-warp tests;
    // it is a parameter of titan_x5_gpu_top, so it cannot be a plusarg.
    parameter [7:0] LAUNCH_MASK = 8'h01;

    // Framebuffer stride. The graphics path is idle here (no DRAW is ever
    // queued), but the display engine free-runs scanning out video and its
    // fetches contend for the same crossbar the SMs use. 1920 makes it scan
    // 30x more per line than it needs to for a test that renders nothing, so
    // this is set small purely to keep simulation cost down.
    localparam FB_STRIDE = 64;
    localparam [31:0] CODE_BASE = 32'h0020_0000;   // 2 MiB in, clear of the FB
    localparam [31:0] DATA_BASE = 32'h0040_0000;   // 4 MiB in
    localparam [31:0] PARAM_BASE = 32'h0060_0000;  // 6 MiB in

    reg clk, mem_clk, pclk, rst_n;

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

    titan_x5_gpu_top #(.VGA_H_VISIBLE(FB_STRIDE),
                       .KERNEL_CODE_BASE(CODE_BASE),
                       .KERNEL_ENTRY_PC(32'd0),
                       // One warp per SM by default: the kernels are scalar
                       // and every extra warp repeats identical work.
                       .LAUNCH_WARP_MASK(LAUNCH_MASK),
                       // The kernels driven from here are integer/scalar and
                       // issue no WMMA. ENABLE_TENSOR=1 instantiates a 4x4
                       // tensor core array inside EVERY ALU -- 32 ALUs x 4 SMs
                       // = 128 arrays -- all of which would clock every cycle
                       // doing nothing. Stripping them is a simulation-speed
                       // decision only; nothing here can reach a WMMA opcode.
                       // Tensor behaviour is covered by the `tensor` suite.
                       .ENABLE_TENSOR(0)) dut (
        .clk(clk), .mem_clk(mem_clk), .pclk(pclk), .rst_n(rst_n),
        .host_ring_base(host_ring_base), .host_ring_wptr(host_ring_wptr),
        .host_ring_rptr(host_ring_rptr), .host_intr(host_intr),
        .vram_arid(vram_arid), .vram_araddr(vram_araddr),
        .vram_arlen(vram_arlen), .vram_arsize(vram_arsize),
        .vram_arburst(vram_arburst), .vram_arvalid(vram_arvalid),
        .vram_arready(vram_arready), .vram_rid(vram_rid),
        .vram_rdata(vram_rdata), .vram_rresp(vram_rresp),
        .vram_rlast(vram_rlast), .vram_rvalid(vram_rvalid),
        .vram_rready(vram_rready), .vram_awid(vram_awid),
        .vram_awaddr(vram_awaddr), .vram_awlen(vram_awlen),
        .vram_awsize(vram_awsize), .vram_awburst(vram_awburst),
        .vram_awvalid(vram_awvalid), .vram_awready(vram_awready),
        .vram_wdata(vram_wdata), .vram_wstrb(vram_wstrb),
        .vram_wlast(vram_wlast), .vram_wvalid(vram_wvalid),
        .vram_wready(vram_wready), .vram_bid(vram_bid),
        .vram_bresp(vram_bresp), .vram_bvalid(vram_bvalid),
        .vram_bready(vram_bready),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .vga_de(vga_de)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end
    initial begin mem_clk = 0; forever #3 mem_clk = ~mem_clk; end
    initial begin pclk = 0; forever #7 pclk = ~pclk; end

    integer cycle_count;
    initial begin
        cycle_count = 0;
        forever @(posedge clk) cycle_count = cycle_count + 1;
    end

    // ---- AXI VRAM model (same behaviour as tb_titan_x5_gpu_top) -----------
    reg [255:0] vram_mem [0:262143];   // 8 MiB

    integer i;
    initial begin
        for (i = 0; i < 262144; i = i + 1) vram_mem[i] = 256'h0;
    end

    reg aw_received, w_received;
    reg [31:0] latched_awaddr;
    reg [511:0] latched_wdata;
    reg [63:0]  latched_wstrb;
    integer     vram_wr_commits;
    integer     commit_byte;
    reg [3:0]   latency_counter;

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
            latched_wdata  <= 512'h0;
            latched_wstrb  <= 64'h0;
            vram_wr_commits <= 0;
            latency_counter <= 4'h0;
        end else begin
            latency_counter <= latency_counter + 1;

            vram_arready <= (latency_counter == 4'hF);
            vram_awready <= (!aw_received && latency_counter == 4'hA);
            vram_wready  <= (!w_received && latency_counter[0] == 1'b1);

            if (vram_arvalid && vram_arready) begin
                vram_rvalid <= 1'b1;
                vram_rdata  <= {vram_mem[{vram_araddr[22:6], 1'b1}],
                                vram_mem[{vram_araddr[22:6], 1'b0}]};
                vram_rresp  <= 2'b00;
                vram_rlast  <= 1'b1;
                vram_rid    <= vram_arid;
            end else if (vram_rready) begin
                vram_rvalid <= 1'b0;
            end

            if (vram_awvalid && vram_awready) begin
                latched_awaddr <= vram_awaddr;
                aw_received <= 1'b1;
            end

            if (vram_wvalid && vram_wready) begin
                latched_wdata <= vram_wdata;
                latched_wstrb <= vram_wstrb;
                w_received <= 1'b1;
            end

            if (aw_received && w_received && !vram_bvalid) begin
                for (commit_byte = 0; commit_byte < 32;
                     commit_byte = commit_byte + 1) begin
                    if (latched_wstrb[commit_byte])
                        vram_mem[{latched_awaddr[22:6], 1'b0}][commit_byte*8 +: 8]
                            <= latched_wdata[commit_byte*8 +: 8];
                    if (latched_wstrb[32 + commit_byte])
                        vram_mem[{latched_awaddr[22:6], 1'b1}][commit_byte*8 +: 8]
                            <= latched_wdata[256 + commit_byte*8 +: 8];
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

    // ---- VRAM backdoor ----------------------------------------------------
    // VRAM occupies the low 8 MiB and aliases above that (the AXI model
    // indexes with addr[22:6]); mirror that here.
    task write_vram_word;
        input [31:0] addr;
        input [31:0] data;
        reg [31:0] offset, word_idx;
        reg [2:0] sub_word;
        begin
            offset = addr & 32'h007F_FFFF;
            word_idx = offset / 32;
            sub_word = (offset % 32) / 4;
            case (sub_word)
                0: vram_mem[word_idx][31:0]    = data;
                1: vram_mem[word_idx][63:32]   = data;
                2: vram_mem[word_idx][95:64]   = data;
                3: vram_mem[word_idx][127:96]  = data;
                4: vram_mem[word_idx][159:128] = data;
                5: vram_mem[word_idx][191:160] = data;
                6: vram_mem[word_idx][223:192] = data;
                7: vram_mem[word_idx][255:224] = data;
            endcase
        end
    endtask

    function [31:0] read_vram_word;
        input [31:0] addr;
        reg [31:0] offset, word_idx;
        reg [2:0] sub_word;
        begin
            offset = addr & 32'h007F_FFFF;
            word_idx = offset / 32;
            sub_word = (offset % 32) / 4;
            read_vram_word = vram_mem[word_idx][sub_word*32 +: 32];
        end
    endfunction

    // ---- architectural readback -------------------------------------------
    //
    // The design has NO cache-flush path. L1 (4-way, 64 sets, 128 B lines) and
    // L2 (8-way, 256 sets, 4 banks) are both write-back with no flush or
    // writeback-all port, so a kernel's stores sit in a Modified L1 line and
    // never reach the AXI memory model on their own. Measured directly: a
    // kernel that stores 0xABC to DATA_BASE and exits leaves VRAM reading 0.
    //
    // Waiting does not help -- write-back caches have no reason to drain -- so
    // this reads the architectural value where it actually lives, newest copy
    // first: any SM's L1 that holds the line in a valid MESI state, then L2,
    // then VRAM. MESI guarantees at most one Modified copy, so at most one L1
    // can disagree with L2, and checking L1s first is what makes this the
    // architectural value rather than a stale one.
    //
    // This is a testbench-side workaround for a real missing feature; a host
    // reading results back from a real part would need an actual flush. It is
    // recorded as a known-open item in docs/HANDOFF_NEXT_SESSION.md.

    // L1: LINE_BYTES=128 -> offset [6:0]; SETS=64 -> index [12:7]; tag [31:13]
    // L2: LINE_SIZE=128  -> offset [6:0]; BANKS=4 -> bank [8:7];
    //     SETS_PER_BANK=64 -> index [14:9]; tag [31:15]
    function [31:0] read_l1_word;
        input integer sm;
        input [31:0] addr;
        input [31:0] miss_value;
        reg [5:0] idx;
        reg [18:0] tg;
        reg [1023:0] line;
        reg [1:0] st;
        reg found;
        reg tg_match;
        integer way;
        begin
            idx = addr[12:7];
            tg  = addr[31:13];
            found = 1'b0;
            read_l1_word = miss_value;
            for (way = 0; way < 4; way = way + 1) begin
                case (sm)
                0: begin st = dut.sm_gen[0].u_sm.u_l1_dcache.mesi_array[idx][way];
                         tg_match = (dut.sm_gen[0].u_sm.u_l1_dcache.tag_array[idx][way] == tg);
                         line = dut.sm_gen[0].u_sm.u_l1_dcache.data_array[idx][way]; end
                1: begin st = dut.sm_gen[1].u_sm.u_l1_dcache.mesi_array[idx][way];
                         tg_match = (dut.sm_gen[1].u_sm.u_l1_dcache.tag_array[idx][way] == tg);
                         line = dut.sm_gen[1].u_sm.u_l1_dcache.data_array[idx][way]; end
                2: begin st = dut.sm_gen[2].u_sm.u_l1_dcache.mesi_array[idx][way];
                         tg_match = (dut.sm_gen[2].u_sm.u_l1_dcache.tag_array[idx][way] == tg);
                         line = dut.sm_gen[2].u_sm.u_l1_dcache.data_array[idx][way]; end
                3: begin st = dut.sm_gen[3].u_sm.u_l1_dcache.mesi_array[idx][way];
                         tg_match = (dut.sm_gen[3].u_sm.u_l1_dcache.tag_array[idx][way] == tg);
                         line = dut.sm_gen[3].u_sm.u_l1_dcache.data_array[idx][way]; end
                endcase
                // MESI_I == 0; anything else is a live copy.
                if (!found && (st != 2'd0) && tg_match) begin
                    found = 1'b1;
                    read_l1_word = line[addr[6:0]*8 +: 32];
                end
            end
        end
    endfunction

    function [31:0] read_l2_word;
        input [31:0] addr;
        input [31:0] miss_value;
        reg [1:0] bnk;
        reg [5:0] idx;
        reg [16:0] tg;
        integer way;
        reg found;
        begin
            bnk = addr[8:7];
            idx = addr[14:9];
            tg  = addr[31:15];
            found = 1'b0;
            read_l2_word = miss_value;
            for (way = 0; way < 8; way = way + 1) begin
                if (!found &&
                    dut.u_l2_cache.valid_array[bnk][idx][way] &&
                    (dut.u_l2_cache.tag_array[bnk][idx][way] == tg)) begin
                    found = 1'b1;
                    read_l2_word =
                        dut.u_l2_cache.data_array[bnk][idx][way][addr[6:0]*8 +: 32];
                end
            end
        end
    endfunction

    // Newest copy wins: L1s, then L2, then VRAM.
    function [31:0] read_arch_word;
        input [31:0] addr;
        reg [31:0] v;
        integer s;
        begin
            v = read_vram_word(addr);
            v = read_l2_word(addr, v);
            for (s = 3; s >= 0; s = s - 1)
                v = read_l1_word(s, addr, v);
            read_arch_word = v;
        end
    endfunction

    // ---- stimulus ---------------------------------------------------------
    // Program and data arrive as hex files so the Python side owns both the
    // compilation and the expected result; this testbench never encodes an
    // instruction itself.
    localparam MAX_PROG = 65536;
    localparam MAX_DATA = 262144;
    localparam MAX_PARAM = 64;
    localparam MAX_WREG = 768;   // 256 (warp, reg, value) triples
    reg [31:0] prog_mem [0:MAX_PROG-1];
    reg [31:0] data_mem [0:MAX_DATA-1];
    reg [31:0] param_mem [0:MAX_PARAM-1];
    reg [31:0] wreg_mem [0:MAX_WREG-1];

    reg [1023:0] prog_file, data_file, param_file, wreg_file, out_file;
    integer n_prog, n_data, n_param, n_wreg, n_res, max_cyc;
    reg [31:0] res_base;
    integer fd, w, t;
    integer timed_out;

    initial begin
        rst_n = 0;
        host_ring_base = 32'h1010_0000;
        host_ring_wptr = 32'h0;   // no DRAW: the graphics path stays idle
        timed_out = 0;

        if (!$value$plusargs("PROG=%s", prog_file)) begin
            $display("FATAL: +PROG=<hexfile> is required");
            $fatal(1);
        end
        if (!$value$plusargs("OUT=%s", out_file)) begin
            $display("FATAL: +OUT=<file> is required");
            $fatal(1);
        end
        if (!$value$plusargs("NRES=%d", n_res))     n_res = 16;
        if (!$value$plusargs("NPROG=%d", n_prog))   n_prog = 0;
        if (!$value$plusargs("NDATA=%d", n_data))   n_data = 0;
        if (!$value$plusargs("NPARAM=%d", n_param)) n_param = 0;
        if (!$value$plusargs("NWREG=%d", n_wreg))   n_wreg = 0;
        if (!$value$plusargs("MAXCYC=%d", max_cyc)) max_cyc = 2000000;
        if (!$value$plusargs("RESBASE=%h", res_base)) res_base = DATA_BASE;

        // Program image.
        for (i = 0; i < MAX_PROG; i = i + 1) prog_mem[i] = 32'h0;
        $readmemh(prog_file, prog_mem);
        for (i = 0; i < n_prog; i = i + 1)
            write_vram_word(CODE_BASE + i*4, prog_mem[i]);

        // Input data image.
        if ($value$plusargs("DATA=%s", data_file)) begin
            for (i = 0; i < MAX_DATA; i = i + 1) data_mem[i] = 32'h0;
            $readmemh(data_file, data_mem);
            for (i = 0; i < n_data; i = i + 1)
                write_vram_word(DATA_BASE + i*4, data_mem[i]);
        end

        // Kernel parameter block at R1 (TX6_REG_PARAM). The compiler's
        // prologue loads one word per kernel argument from here.
        if ($value$plusargs("PARAM=%s", param_file)) begin
            for (i = 0; i < MAX_PARAM; i = i + 1) param_mem[i] = 32'h0;
            $readmemh(param_file, param_mem);
            for (i = 0; i < n_param; i = i + 1)
                write_vram_word(PARAM_BASE + i*4, param_mem[i]);
        end

        $display("=== tb_compute_top ===");
        $display("  program : %0s (%0d words at %08x)", prog_file, n_prog, CODE_BASE);
        $display("  data    : %0d words at %08x", n_data, DATA_BASE);
        $display("  result  : %0d words at %08x", n_res, res_base);

        #20; rst_n = 1; #20;

        // Kernel entry state, per the ABI in driver/titan_x6_isa.h. All
        // registers are zero out of reset, which already satisfies
        // TX6_REG_ZERO; these are the ones a kernel may rely on being set.
        // Deposited into every warp of every SM (the register file is
        // per-warp: bank_mem[warp*16 + entry], bank = reg%4, entry = reg/4).
        // Per-warp register overrides, as flat (warp, reg, value) triples.
        //
        // These exist so a test can give each warp DIFFERENT state. Without
        // them every warp runs identical work with identical inputs, which
        // makes a whole class of cross-warp bug invisible: a mutation that
        // shared the predicate registers across warps was not caught by an
        // 8-warp test, because all eight warps computed the same predicate
        // anyway and the shared value happened to be right.
        if ($value$plusargs("WREGS=%s", wreg_file)) begin
            for (i = 0; i < MAX_WREG; i = i + 1) wreg_mem[i] = 32'h0;
            $readmemh(wreg_file, wreg_mem);
        end

        for (t = 0; t < 4; t = t + 1) begin
            for (w = 0; w < 8; w = w + 1) begin
                // R1 = TX6_REG_PARAM (bank 1, entry 0)
                deposit_reg(t, w, 1, PARAM_BASE);
                // R61 = TX6_REG_NTHREADS (bank 1, entry 15) - one thread per
                // lane; the scalar kernels do not read it, but leaving it at a
                // lie would be worse than setting it.
                deposit_reg(t, w, 61, 32'd32);
                // R62 = TX6_REG_TID (bank 2, entry 15): the lane index.
                deposit_tid(t, w);
            end
        end

        // Applied after the ABI defaults so a test can override any of them.
        for (i = 0; i + 2 < n_wreg; i = i + 3) begin
            for (t = 0; t < 4; t = t + 1)
                if (wreg_mem[i] < 8)
                    deposit_reg(t, wreg_mem[i], wreg_mem[i+1], wreg_mem[i+2]);
        end

        $display("[%0t] Reset released, warps launched. Waiting for retire...", $time);

        fork
            begin : watchdog
                while (cycle_count < max_cyc && !dut.kernel_complete)
                    @(posedge clk);
                if (!dut.kernel_complete) timed_out = 1;
            end
        join

        if (timed_out) begin
            $display("[%0t] TIMEOUT after %0d cycles: kernel never retired.",
                     $time, cycle_count);
        end else begin
            $display("[%0t] Kernel complete after %0d cycles.",
                     $time, cycle_count);
        end

        // Let anything still in flight land. This is a settle delay, not a
        // flush: the caches are write-back with no flush port, so results are
        // read out of the hierarchy by read_arch_word rather than waiting for
        // a drain that never comes.
        settle();

        fd = $fopen(out_file, "w");
        if (fd == 0) begin
            $display("FATAL: cannot open %0s for writing", out_file);
            $fatal(1);
        end
        // Line 1 is the verdict/metadata, so the Python side can tell a
        // timeout from a real answer instead of silently diffing garbage.
        $fdisplay(fd, "%0d %0d %0d", timed_out, cycle_count,
                  dut.any_pred_divergent);
        for (i = 0; i < n_res; i = i + 1)
            $fdisplay(fd, "%08x", read_arch_word(res_base + i*4));
        $fclose(fd);
        $display("[%0t] Wrote %0d result words to %0s", $time, n_res, out_file);

        if (timed_out) $fatal(1, "kernel did not retire");
        $finish;
    end

    // Deposit a 32-bit scalar into every lane of one architectural register
    // of one warp of one SM, through the register file's backdoor.
    task deposit_reg;
        input integer sm;
        input integer warp;
        input integer regno;
        input [31:0] value;
        reg [1023:0] broadcast;
        integer lane;
        begin
            for (lane = 0; lane < 32; lane = lane + 1)
                broadcast[lane*32 +: 32] = value;
            poke_rf(sm, warp, regno, broadcast);
        end
    endtask

    // R62 = TX6_REG_TID is per-lane, not a broadcast.
    task deposit_tid;
        input integer sm;
        input integer warp;
        reg [1023:0] tids;
        integer lane;
        begin
            for (lane = 0; lane < 32; lane = lane + 1)
                tids[lane*32 +: 32] = lane;
            poke_rf(sm, warp, 62, tids);
        end
    endtask

    // The register file is banked: bank = reg % 4, entry = reg / 4, and the
    // warp selects a 16-entry window (warp-major). Verilog has no way to index
    // a generate block with a runtime variable, so the bank and SM selects are
    // spelled out.
    task poke_rf;
        input integer sm;
        input integer warp;
        input integer regno;
        input [1023:0] value;
        integer slot;
        begin
            slot = warp*16 + (regno/4);
            case (sm)
            0: case (regno % 4)
               0: dut.sm_gen[0].u_sm.rf_inst.bank_gen[0].bank_mem[slot] = value;
               1: dut.sm_gen[0].u_sm.rf_inst.bank_gen[1].bank_mem[slot] = value;
               2: dut.sm_gen[0].u_sm.rf_inst.bank_gen[2].bank_mem[slot] = value;
               3: dut.sm_gen[0].u_sm.rf_inst.bank_gen[3].bank_mem[slot] = value;
               endcase
            1: case (regno % 4)
               0: dut.sm_gen[1].u_sm.rf_inst.bank_gen[0].bank_mem[slot] = value;
               1: dut.sm_gen[1].u_sm.rf_inst.bank_gen[1].bank_mem[slot] = value;
               2: dut.sm_gen[1].u_sm.rf_inst.bank_gen[2].bank_mem[slot] = value;
               3: dut.sm_gen[1].u_sm.rf_inst.bank_gen[3].bank_mem[slot] = value;
               endcase
            2: case (regno % 4)
               0: dut.sm_gen[2].u_sm.rf_inst.bank_gen[0].bank_mem[slot] = value;
               1: dut.sm_gen[2].u_sm.rf_inst.bank_gen[1].bank_mem[slot] = value;
               2: dut.sm_gen[2].u_sm.rf_inst.bank_gen[2].bank_mem[slot] = value;
               3: dut.sm_gen[2].u_sm.rf_inst.bank_gen[3].bank_mem[slot] = value;
               endcase
            3: case (regno % 4)
               0: dut.sm_gen[3].u_sm.rf_inst.bank_gen[0].bank_mem[slot] = value;
               1: dut.sm_gen[3].u_sm.rf_inst.bank_gen[1].bank_mem[slot] = value;
               2: dut.sm_gen[3].u_sm.rf_inst.bank_gen[2].bank_mem[slot] = value;
               3: dut.sm_gen[3].u_sm.rf_inst.bank_gen[3].bank_mem[slot] = value;
               endcase
            endcase
        end
    endtask

    // Allow in-flight transactions (a store accepted by the LSU but not yet
    // committed into L1, an L2 refill in progress) to complete before the
    // backdoor samples cache state. All warps have already retired, so nothing
    // new is issued and this converges quickly.
    // 300 cycles is well beyond the longest in-flight path (an LSU request
    // accepted but not yet committed into L1). It was 2000, which at the
    // measured ~30 simulated cycles/second cost ~60 s of wall time on every
    // run -- more than the kernel itself for the small tests.
    task settle;
        integer q;
        begin
            for (q = 0; q < 300; q = q + 1) @(posedge clk);
        end
    endtask

endmodule
