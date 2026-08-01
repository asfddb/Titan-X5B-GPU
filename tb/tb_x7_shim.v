// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// Wrapper for the cocotb suite `x7shim`. Gives titan_x7_sm_shim an
// instruction memory on its icache port and a simple line-granular memory
// behind its coherent bus, so a real compiled-style program can run through
// the real LSU and L1 D-cache.
module tb_x7_shim;

    localparam NUM_WARPS  = 8;
    localparam LINE_BYTES = 128;

    reg clk = 1'b0;
    reg rst_n = 1'b0;

    // ---- instruction memory (word addressed, 1-cycle grant, 1-cycle data)
    wire [31:0] ic_addr;
    wire        ic_req;
    reg         ic_gnt;
    reg  [31:0] ic_rdata;
    reg         ic_rvalid;

    reg [31:0] imem [0:4095];      // 4096 instructions, byte addr >> 2

    // ---- coherent bus: a flat line memory, no other caches
    wire                    dbus_req_valid;
    reg                     dbus_req_ready;
    wire [1:0]              dbus_req_type;
    wire [31:0]             dbus_req_addr;
    wire [LINE_BYTES*8-1:0] dbus_req_wdata;
    reg                     dbus_resp_valid;
    reg  [LINE_BYTES*8-1:0] dbus_resp_rdata;

    // 64 lines of 128 B, indexed by addr[12:7]
    reg [LINE_BYTES*8-1:0] linemem [0:63];

    wire [NUM_WARPS-1:0] warp_active;
    wire                 all_retired;
    wire                 shader_wb_valid;
    wire [5:0]           shader_wb_reg;
    wire [1023:0]        shader_wb_data;

    reg          launch_valid;
    reg  [NUM_WARPS-1:0] launch_mask;
    reg  [31:0]  launch_pc;
    reg  [31:0]  code_base;

    titan_x7_sm_shim #(
        .NUM_WARPS(NUM_WARPS),
        .LINE_BYTES(LINE_BYTES)
    ) dut (
        .clk(clk), .rst_n(rst_n),

        .l1_icache_addr(ic_addr),
        .l1_icache_req(ic_req),
        .l1_icache_gnt(ic_gnt),
        .l1_icache_rdata(ic_rdata),
        .l1_icache_rvalid(ic_rvalid),

        .dbus_req_valid(dbus_req_valid),
        .dbus_req_ready(dbus_req_ready),
        .dbus_req_type(dbus_req_type),
        .dbus_req_addr(dbus_req_addr),
        .dbus_req_wdata(dbus_req_wdata),
        .dbus_resp_valid(dbus_resp_valid),
        .dbus_resp_rdata(dbus_resp_rdata),
        .dbus_resp_shared(1'b0),

        .snp_req_valid(1'b0),
        .snp_req_type(2'd0),
        .snp_req_addr(32'd0),
        .snp_resp_valid(), .snp_resp_hit(),
        .snp_resp_dirty(), .snp_resp_data(),

        .dbg_mesi_addr(32'd0),
        .dbg_mesi_state(),
        .dbg_lsu_resp_valid(),
        .dbg_lsu_xactions(),
        .dbg_pred_divergent(),

        .fp_rm(2'b00),
        .flush_req(1'b0),
        .flush_done(),

        .shader_wb_valid(shader_wb_valid),
        .shader_wb_reg(shader_wb_reg),
        .shader_wb_data(shader_wb_data),

        .launch_valid(launch_valid),
        .launch_mask(launch_mask),
        .launch_pc(launch_pc),
        .code_base(code_base),
        .warp_active(warp_active),
        .all_retired(all_retired)
    );

    // ---- instruction memory model -------------------------------------
    // Grant in the request cycle, data the cycle after. One outstanding.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ic_gnt    <= 1'b0;
            ic_rvalid <= 1'b0;
            ic_rdata  <= 32'd0;
        end else begin
            ic_gnt    <= ic_req && !ic_gnt;
            ic_rvalid <= ic_gnt;
            if (ic_gnt)
                ic_rdata <= imem[ic_addr[13:2]];
        end
    end

    // ---- coherent bus model -------------------------------------------
    // Accept a request every cycle; return the line two cycles later.
    // BusWB (type 3) writes the line back and gets no response.
    reg [1:0]  pend_ct;
    reg [31:0] pend_addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dbus_req_ready  <= 1'b1;
            dbus_resp_valid <= 1'b0;
            pend_ct         <= 2'd0;
            pend_addr       <= 32'd0;
        end else begin
            dbus_resp_valid <= 1'b0;
            if (dbus_req_valid && dbus_req_ready) begin
                if (dbus_req_type == 2'd3) begin
                    linemem[dbus_req_addr[12:7]] <= dbus_req_wdata;
                end else begin
                    pend_ct   <= 2'd2;
                    pend_addr <= dbus_req_addr;
                end
            end
            if (pend_ct != 2'd0) begin
                pend_ct <= pend_ct - 2'd1;
                if (pend_ct == 2'd1) begin
                    dbus_resp_valid <= 1'b1;
                    dbus_resp_rdata <= linemem[pend_addr[12:7]];
                end
            end
        end
    end

    always #5 clk = ~clk;

    initial begin
        if ($test$plusargs("dumpvcd")) begin
            $dumpfile("x7shim.vcd");
            $dumpvars(0, tb_x7_shim);
        end
    end

endmodule
