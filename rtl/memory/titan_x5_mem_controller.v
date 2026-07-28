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
 * Titan X5 GPU - Memory Controller
 * - AXI4 master interface to external memory
 * - Supports up to 16 beat bursts
 */
module titan_x5_mem_controller #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 256,
    parameter AXI_ID_WIDTH   = 4,
    parameter ID_WIDTH       = 5,
    // Width of the dedicated wide port. Set equal to AXI_DATA_WIDTH so a
    // wide request is a single full-bus AXI beat.
    parameter WIDE_DATA_WIDTH = AXI_DATA_WIDTH
)(
    input wire clk,
    input wire rst_n,

    // ---- narrow request interface (32-bit words) -------------------------
    // Serves the legacy word crossbar: instruction fetch, ROP pixel writes,
    // the command processor and DMA. Each request moves 4 useful bytes: the
    // write path replicates the word across the AXI bus and enables 4 bytes
    // with wstrb, and the read path muxes one word out of the response.
    input  wire                       req_valid,
    input wire [AXI_ADDR_WIDTH-1:0] req_addr,
    input  wire                       req_write,
    input wire [31:0] req_wdata,
    input wire [3:0] req_len, // burst length (0-15)
    input wire [ID_WIDTH-1:0] req_id,
    output reg                        req_ready,

    output reg                        resp_valid,
    output reg [ID_WIDTH-1:0] resp_id,
    output reg [31:0] resp_rdata,

    // ---- wide request interface (WIDE_DATA_WIDTH) ------------------------
    // Dedicated bulk port for L2 line fills and writebacks. One request is
    // one full-width AXI beat, so a 128-byte line costs 2 transactions here
    // instead of the 32 it costs through the narrow port.
    input  wire                        wreq_valid,
    input  wire [AXI_ADDR_WIDTH-1:0]   wreq_addr,
    input  wire                        wreq_write,
    input  wire [WIDE_DATA_WIDTH-1:0]  wreq_wdata,
    input  wire [ID_WIDTH-1:0]         wreq_id,
    output reg                         wreq_ready,

    output reg                         wresp_valid,
    output reg  [ID_WIDTH-1:0]         wresp_id,
    output reg  [WIDE_DATA_WIDTH-1:0]  wresp_rdata,

    // axi4 master interface
    // ar channel
    output reg [AXI_ID_WIDTH-1:0] m_axi_arid,
    output reg [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output reg [7:0] m_axi_arlen,
    output wire [2:0] m_axi_arsize,
    output wire [1:0] m_axi_arburst,
    output reg                        m_axi_arvalid,
    input  wire                       m_axi_arready,
    
    // r channel
    input wire [AXI_ID_WIDTH-1:0] m_axi_rid,
    input wire [AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input wire [1:0] m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output reg                        m_axi_rready,

    // aw channel
    output reg [AXI_ID_WIDTH-1:0] m_axi_awid,
    output reg [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output reg [7:0] m_axi_awlen,
    output wire [2:0] m_axi_awsize,
    output wire [1:0] m_axi_awburst,
    output reg                        m_axi_awvalid,
    input  wire                       m_axi_awready,
    
    // w channel
    output reg [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output reg [(AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output reg                        m_axi_wlast,
    output reg                        m_axi_wvalid,
    input  wire                       m_axi_wready,
    
    // b channel
    input wire [AXI_ID_WIDTH-1:0] m_axi_bid,
    input wire [1:0] m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output reg                        m_axi_bready
);

    assign m_axi_arsize = 3'b101; // 32 bytes
    assign m_axi_arburst = 2'b01; // incr
    assign m_axi_awsize = 3'b101; 
    assign m_axi_awburst = 2'b01;

    localparam IDLE   = 3'd0;
    localparam AR_WAIT = 3'd1;
    localparam R_WAIT  = 3'd2;
    localparam AW_WAIT = 3'd3;
    localparam W_WAIT  = 3'd4;
    localparam B_WAIT  = 3'd5;

    reg [2:0] state, next_state;
    reg [AXI_ADDR_WIDTH-1:0] saved_req_addr;
    reg [ID_WIDTH-1:0] saved_req_id;

    // ---- port arbitration --------------------------------------------------
    // One AXI master is shared by the narrow and wide ports, so exactly one
    // transaction is in flight at a time. `cur_wide` remembers which port owns
    // it so the response is routed back correctly; `last_was_wide` alternates
    // priority so neither port can starve the other -- without it a busy L2
    // would lock out instruction fetch entirely.
    reg cur_wide;
    reg last_was_wide;

    // Acceptance is qualified by the *registered* ready, matching the existing
    // narrow handshake (ready is raised on entry to IDLE and the request is
    // taken the following cycle).
    //
    // CRITICAL: at most one ready may be asserted per cycle. A requester
    // treats `valid && ready` as acceptance -- the narrow side is a CDC FIFO
    // that pops on exactly that condition. Asserting both readies and then
    // picking a winner in the same cycle silently destroys the loser's
    // request: the FIFO pops an entry the controller never serves. That
    // dropped instruction fetches and hung the SM with if_pending stuck high.
    //
    // Arbitration therefore happens when granting `ready` (below), not when
    // sampling `valid`, which makes these two mutually exclusive by
    // construction.
    wire take_wide   = wreq_valid && wreq_ready;
    wire take_narrow = req_valid  && req_ready && !take_wide;

    localparam [(AXI_DATA_WIDTH/8)-1:0] STRB_ALL = {(AXI_DATA_WIDTH/8){1'b1}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            m_axi_arvalid <= 0;
            m_axi_rready <= 0;
            m_axi_awvalid <= 0;
            m_axi_wvalid <= 0;
            m_axi_bready <= 0;
            req_ready <= 0;
            resp_valid <= 0;
            saved_req_addr <= 0;
            saved_req_id <= 0;
            wreq_ready <= 0;
            wresp_valid <= 0;
            wresp_id <= 0;
            wresp_rdata <= 0;
            cur_wide <= 0;
            last_was_wide <= 0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    resp_valid <= 1'b0;
                    wresp_valid <= 1'b0;
                    // Grant `ready` to exactly one port for the next cycle.
                    // Round-robin via last_was_wide so neither can starve the
                    // other: a busy L2 must not lock out instruction fetch.
                    if (wreq_valid && (!req_valid || !last_was_wide)) begin
                        wreq_ready <= 1'b1;
                        req_ready  <= 1'b0;
                    end else begin
                        req_ready  <= 1'b1;
                        wreq_ready <= 1'b0;
                    end
                    if (take_wide) begin
                        // ---- wide port: one full-bus beat ----
                        req_ready  <= 1'b0;
                        wreq_ready <= 1'b0;
                        cur_wide      <= 1'b1;
                        last_was_wide <= 1'b1;
                        saved_req_addr <= wreq_addr;
                        saved_req_id <= wreq_id;
                        if (wreq_write) begin
                            m_axi_awvalid <= 1'b1;
                            m_axi_awaddr <= wreq_addr;
                            m_axi_awlen <= 0;
                            m_axi_awid <= wreq_id[AXI_ID_WIDTH-1:0];

                            m_axi_wvalid <= 1'b1;
                            m_axi_wdata <= wreq_wdata;
                            m_axi_wstrb <= STRB_ALL; // full-width beat
                            m_axi_wlast <= 1'b1;
                        end else begin
                            m_axi_arvalid <= 1'b1;
                            m_axi_araddr <= wreq_addr;
                            m_axi_arlen <= 8'd0;
                            m_axi_arid <= wreq_id[AXI_ID_WIDTH-1:0];
                            m_axi_rready <= 1'b1;
                        end
                    end else if (take_narrow) begin
                        req_ready <= 1'b0;
                        wreq_ready <= 1'b0;
                        cur_wide      <= 1'b0;
                        last_was_wide <= 1'b0;
                        saved_req_addr <= req_addr;
                        saved_req_id <= req_id;
                        if (req_write) begin
                            m_axi_awvalid <= 1'b1;
                            m_axi_awaddr <= req_addr;
                            m_axi_awlen <= 0; // optimized: strictly single beat write supported by request interface
                            m_axi_awid <= req_id;

                            m_axi_wvalid <= 1'b1;
                            m_axi_wdata <= {(AXI_DATA_WIDTH/32){req_wdata}};
                            m_axi_wstrb <= ( {((AXI_DATA_WIDTH/8)+1){1'b0}} + 4'hF ) << ((req_addr % (AXI_DATA_WIDTH/8)) / 4 * 4);
                            m_axi_wlast <= 1'b1;
                        end else begin
                            m_axi_arvalid <= 1'b1;
                            m_axi_araddr <= req_addr;
                            m_axi_arlen <= req_len;
                            m_axi_arid <= req_id;
                            m_axi_rready <= 1'b1; // assert rready early
                        end
                    end
                end
                AR_WAIT: begin
                    if (m_axi_arready && m_axi_arvalid) begin
                        m_axi_arvalid <= 1'b0;
                    end
                end
                R_WAIT: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        if (cur_wide) begin
                            // wide port takes the whole bus, no muxing
                            wresp_valid <= 1'b1;
                            wresp_id    <= saved_req_id;
                            wresp_rdata <= m_axi_rdata[WIDE_DATA_WIDTH-1:0];
                        end else begin
                            resp_valid <= 1'b1;
                            resp_id <= saved_req_id;
                            // multiplex the 32-bit word from the AXI_DATA_WIDTH bus using the byte offset
                            // index is (saved_req_addr % (AXI_DATA_WIDTH/8)) / 4
                            resp_rdata <= m_axi_rdata[((saved_req_addr % (AXI_DATA_WIDTH/8)) / 4) * 32 +: 32];
                        end
                        if (m_axi_rlast) begin
                            m_axi_rready <= 1'b0;
                        end
                    end else begin
                        resp_valid <= 1'b0;
                        wresp_valid <= 1'b0;
                    end
                end
                AW_WAIT: begin // optimized to handle AW and W in parallel
                    if (m_axi_awready && m_axi_awvalid) m_axi_awvalid <= 1'b0;
                    if (m_axi_wready && m_axi_wvalid) m_axi_wvalid <= 1'b0;
                    if ((!m_axi_awvalid || (m_axi_awready && m_axi_awvalid)) && 
                        (!m_axi_wvalid || (m_axi_wready && m_axi_wvalid))) begin
                        m_axi_bready <= 1'b1;
                    end
                end
                W_WAIT: begin
                    // unused, kept for parameter compatibility
                end
                B_WAIT: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        if (cur_wide) begin
                            wresp_valid <= 1'b1;
                            wresp_id    <= saved_req_id;
                        end else begin
                            resp_valid <= 1'b1;
                            resp_id <= saved_req_id;
                        end
                    end else begin
                        resp_valid <= 1'b0;
                        wresp_valid <= 1'b0;
                    end
                end
                default: ; // recovery handled by the next_state case below
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                // must mirror the arbitration in the sequential block exactly
                if (take_wide) begin
                    next_state = wreq_write ? AW_WAIT : AR_WAIT;
                end else if (take_narrow) begin
                    next_state = req_write ? AW_WAIT : AR_WAIT;
                end
            end
            AR_WAIT: begin
                if (m_axi_arready && m_axi_arvalid) next_state = R_WAIT;
            end
            R_WAIT: begin
                if (m_axi_rvalid && m_axi_rready && m_axi_rlast) next_state = IDLE;
            end
            AW_WAIT: begin
                if ((!m_axi_awvalid || m_axi_awready) && (!m_axi_wvalid || m_axi_wready)) next_state = B_WAIT;
            end
            W_WAIT: begin
                // unused state now
            end
            B_WAIT: begin
                if (m_axi_bvalid && m_axi_bready) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
