// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X6 GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
`timescale 1ns / 1ps

module titan_x6_tpc #(
    parameter NUM_SMS = 4,
    parameter LINE_BYTES = 128
)(
    input wire clk,
    input wire rst_n,
    
    // I-Cache interface (Aggregated)
    output wire [NUM_SMS-1:0]          icache_req,
    output wire [NUM_SMS*32-1:0]       icache_addr,
    input  wire [NUM_SMS-1:0]          icache_gnt,
    input  wire [NUM_SMS*32-1:0]       icache_rdata,
    input  wire [NUM_SMS-1:0]          icache_rvalid,

    // D-Cache MESI Bus interface (Aggregated)
    output wire [NUM_SMS-1:0]          dbus_req_valid,
    input  wire [NUM_SMS-1:0]          dbus_req_ready,
    output wire [NUM_SMS*2-1:0]        dbus_req_type,
    output wire [NUM_SMS*32-1:0]       dbus_req_addr,
    output wire [NUM_SMS*LINE_BYTES*8-1:0] dbus_req_wdata,
    input  wire [NUM_SMS-1:0]          dbus_resp_valid,
    input  wire [LINE_BYTES*8-1:0]     dbus_resp_rdata,
    input  wire [NUM_SMS-1:0]          dbus_resp_shared,

    // Snoop interface
    input  wire [NUM_SMS-1:0]          snp_req_valid,
    input  wire [1:0]                  snp_req_type,
    input  wire [31:0]                 snp_req_addr,
    output wire [NUM_SMS-1:0]          snp_resp_valid,
    output wire [NUM_SMS-1:0]          snp_resp_hit,
    output wire [NUM_SMS-1:0]          snp_resp_dirty,
    output wire [NUM_SMS*LINE_BYTES*8-1:0] snp_resp_data
);

    genvar i;
    generate
        for (i = 0; i < NUM_SMS; i = i + 1) begin : sm_inst
            titan_x5_sm #(
                .NUM_WARPS(8),
                .NUM_ALUS(32),
                .LINE_BYTES(LINE_BYTES),
                .ENABLE_TENSOR(1)
            ) sm (
                .clk(clk),
                .rst_n(rst_n),
                
                .l1_icache_addr(icache_addr[i*32 +: 32]),
                .l1_icache_req(icache_req[i]),
                .l1_icache_gnt(icache_gnt[i]),
                .l1_icache_rdata(icache_rdata[i*32 +: 32]),
                .l1_icache_rvalid(icache_rvalid[i]),
                
                .dbus_req_valid(dbus_req_valid[i]),
                .dbus_req_ready(dbus_req_ready[i]),
                .dbus_req_type(dbus_req_type[i*2 +: 2]),
                .dbus_req_addr(dbus_req_addr[i*32 +: 32]),
                .dbus_req_wdata(dbus_req_wdata[i*LINE_BYTES*8 +: LINE_BYTES*8]),
                .dbus_resp_valid(dbus_resp_valid[i]),
                .dbus_resp_rdata(dbus_resp_rdata),
                .dbus_resp_shared(dbus_resp_shared[i]),
                
                .snp_req_valid(snp_req_valid[i]),
                .snp_req_type(snp_req_type),
                .snp_req_addr(snp_req_addr),
                .snp_resp_valid(snp_resp_valid[i]),
                .snp_resp_hit(snp_resp_hit[i]),
                .snp_resp_dirty(snp_resp_dirty[i]),
                .snp_resp_data(snp_resp_data[i*LINE_BYTES*8 +: LINE_BYTES*8]),
                
                .dbg_mesi_addr(32'd0),
                .dbg_mesi_state(),
                .dbg_lsu_resp_valid(),
                .dbg_lsu_xactions(),
                .fp_rm(2'b00),
                
                .shader_wb_valid(),
                .shader_wb_reg(),
                .shader_wb_data(),
                
                .warp_active(8'hFF),
                .warp_pc_in(256'h0)
            );
        end
    endgenerate

endmodule


module titan_x6_gpc #(
    parameter NUM_TPCS = 4,
    parameter SMS_PER_TPC = 4,
    parameter LINE_BYTES = 128
)(
    input wire clk,
    input wire rst_n,
    
    // GPC Level Memory Interface connecting to Coherent Crossbar or NoC
    // For simplicity in this scale-up, we bring all SM interfaces out to be connected
    // to a scalable coherent NoC adapter at the top level.
    
    output wire [NUM_TPCS*SMS_PER_TPC-1:0]          icache_req,
    output wire [NUM_TPCS*SMS_PER_TPC*32-1:0]       icache_addr,
    input  wire [NUM_TPCS*SMS_PER_TPC-1:0]          icache_gnt,
    input  wire [NUM_TPCS*SMS_PER_TPC*32-1:0]       icache_rdata,
    input  wire [NUM_TPCS*SMS_PER_TPC-1:0]          icache_rvalid,

    output wire [NUM_TPCS*SMS_PER_TPC-1:0]          dbus_req_valid,
    input  wire [NUM_TPCS*SMS_PER_TPC-1:0]          dbus_req_ready,
    output wire [NUM_TPCS*SMS_PER_TPC*2-1:0]        dbus_req_type,
    output wire [NUM_TPCS*SMS_PER_TPC*32-1:0]       dbus_req_addr,
    output wire [NUM_TPCS*SMS_PER_TPC*LINE_BYTES*8-1:0] dbus_req_wdata,
    input  wire [NUM_TPCS*SMS_PER_TPC-1:0]          dbus_resp_valid,
    input  wire [LINE_BYTES*8-1:0]                  dbus_resp_rdata,
    input  wire [NUM_TPCS*SMS_PER_TPC-1:0]          dbus_resp_shared,

    input  wire [NUM_TPCS*SMS_PER_TPC-1:0]          snp_req_valid,
    input  wire [1:0]                               snp_req_type,
    input  wire [31:0]                              snp_req_addr,
    output wire [NUM_TPCS*SMS_PER_TPC-1:0]          snp_resp_valid,
    output wire [NUM_TPCS*SMS_PER_TPC-1:0]          snp_resp_hit,
    output wire [NUM_TPCS*SMS_PER_TPC-1:0]          snp_resp_dirty,
    output wire [NUM_TPCS*SMS_PER_TPC*LINE_BYTES*8-1:0] snp_resp_data
);

    genvar t;
    generate
        for (t = 0; t < NUM_TPCS; t = t + 1) begin : tpc_inst
            titan_x6_tpc #(
                .NUM_SMS(SMS_PER_TPC),
                .LINE_BYTES(LINE_BYTES)
            ) tpc (
                .clk(clk),
                .rst_n(rst_n),
                
                .icache_req(icache_req[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .icache_addr(icache_addr[t*SMS_PER_TPC*32 +: SMS_PER_TPC*32]),
                .icache_gnt(icache_gnt[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .icache_rdata(icache_rdata[t*SMS_PER_TPC*32 +: SMS_PER_TPC*32]),
                .icache_rvalid(icache_rvalid[t*SMS_PER_TPC +: SMS_PER_TPC]),
                
                .dbus_req_valid(dbus_req_valid[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .dbus_req_ready(dbus_req_ready[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .dbus_req_type(dbus_req_type[t*SMS_PER_TPC*2 +: SMS_PER_TPC*2]),
                .dbus_req_addr(dbus_req_addr[t*SMS_PER_TPC*32 +: SMS_PER_TPC*32]),
                .dbus_req_wdata(dbus_req_wdata[t*SMS_PER_TPC*LINE_BYTES*8 +: SMS_PER_TPC*LINE_BYTES*8]),
                .dbus_resp_valid(dbus_resp_valid[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .dbus_resp_rdata(dbus_resp_rdata),
                .dbus_resp_shared(dbus_resp_shared[t*SMS_PER_TPC +: SMS_PER_TPC]),
                
                .snp_req_valid(snp_req_valid[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .snp_req_type(snp_req_type),
                .snp_req_addr(snp_req_addr),
                .snp_resp_valid(snp_resp_valid[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .snp_resp_hit(snp_resp_hit[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .snp_resp_dirty(snp_resp_dirty[t*SMS_PER_TPC +: SMS_PER_TPC]),
                .snp_resp_data(snp_resp_data[t*SMS_PER_TPC*LINE_BYTES*8 +: SMS_PER_TPC*LINE_BYTES*8])
            );
        end
    endgenerate

endmodule
