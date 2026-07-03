// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Titan X5 GPU - AXI4-Lite Interconnect
 * - 1 Master to up to 16 Slaves
 * - Address Decoder
 */
module titan_x5_axi4_lite #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_SLAVES = 16
)(
    input wire clk,
    input wire rst_n,

    // 1 Master Interface
    input  wire                    m_req_valid,
    input wire [ADDR_WIDTH-1:0] m_req_addr,
    input wire [DATA_WIDTH-1:0] m_req_wdata,
    input  wire                    m_req_write,
    output wire                    m_req_ready,

    output wire                    m_resp_valid,
    output wire [DATA_WIDTH-1:0] m_resp_rdata,

    // up to 16 slave interfaces
    output wire [NUM_SLAVES-1:0] s_req_valid,
    output wire [NUM_SLAVES*ADDR_WIDTH-1:0] s_req_addr,
    output wire [NUM_SLAVES*DATA_WIDTH-1:0] s_req_wdata,
    output wire [NUM_SLAVES-1:0] s_req_write,
    input wire [NUM_SLAVES-1:0] s_req_ready,

    input wire [NUM_SLAVES-1:0] s_resp_valid,
    input wire [NUM_SLAVES*DATA_WIDTH-1:0] s_resp_rdata
);

    // address decoding (top 4 bits define the slave)
    wire [3:0] target_slave = m_req_addr[ADDR_WIDTH-1:ADDR_WIDTH-4];
    
    reg [NUM_SLAVES-1:0] dec_req_valid;
    always @(*) begin
        dec_req_valid = {NUM_SLAVES{1'b0}};
        if (m_req_valid && target_slave < NUM_SLAVES) begin
            dec_req_valid[target_slave] = 1'b1;
        end
    end

    assign s_req_valid = dec_req_valid;

    genvar i;
    generate
        for (i = 0; i < NUM_SLAVES; i = i + 1) begin : s_interfaces
            assign s_req_addr[i*ADDR_WIDTH +: ADDR_WIDTH] = m_req_addr;
            assign s_req_wdata[i*DATA_WIDTH +: DATA_WIDTH] = m_req_wdata;
            assign s_req_write[i] = m_req_write;
        end
    endgenerate

    // mux responses back to master
    assign m_req_ready  = target_slave < NUM_SLAVES ? s_req_ready[target_slave] : 1'b0;
    assign m_resp_valid = target_slave < NUM_SLAVES ? s_resp_valid[target_slave] : 1'b0;
    assign m_resp_rdata = target_slave < NUM_SLAVES ? s_resp_rdata[target_slave*DATA_WIDTH +: DATA_WIDTH] : {DATA_WIDTH{1'b0}};

endmodule
