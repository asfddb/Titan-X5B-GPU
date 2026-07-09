// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X6 GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Titan X6 GPU - Massive VRAM Controller
 * - 512-bit AXI4 interface for GDDR7
 * - Supports wide L2 cache burst writes/reads directly
 */
module titan_x6_vram_ctrl #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 512,
    parameter AXI_ID_WIDTH   = 4,
    parameter ID_WIDTH       = 5,
    parameter LINE_BYTES     = 128 // 1024-bit L2 line size
)(
    input wire clk,
    input wire rst_n,

    // Internal request interface (Direct from L2 Bank)
    input  wire                       req_valid,
    input  wire [AXI_ADDR_WIDTH-1:0]  req_addr,
    input  wire                       req_write,
    input  wire [LINE_BYTES*8-1:0]    req_wdata,
    input  wire [ID_WIDTH-1:0]        req_id,
    output reg                        req_ready,

    output reg                        resp_valid,
    output reg  [ID_WIDTH-1:0]        resp_id,
    output reg  [LINE_BYTES*8-1:0]    resp_rdata,

    // AXI4 master interface
    output reg  [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output reg  [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output reg  [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output reg                        m_axi_arvalid,
    input  wire                       m_axi_arready,
    
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output reg                        m_axi_rready,

    output reg  [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output reg  [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output reg  [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output reg                        m_axi_awvalid,
    input  wire                       m_axi_awready,
    
    output reg  [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output reg  [(AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output reg                        m_axi_wlast,
    output reg                        m_axi_wvalid,
    input  wire                       m_axi_wready,
    
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output reg                        m_axi_bready
);

    // AXI size = log2(bytes per beat); derived from the data-bus width so this
    // controller is correct for any AXI_DATA_WIDTH, not just 512.
    assign m_axi_arsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_arburst = 2'b01; // incr
    assign m_axi_awsize = $clog2(AXI_DATA_WIDTH/8);
    assign m_axi_awburst = 2'b01;

    localparam BEATS_PER_LINE = (LINE_BYTES * 8) / AXI_DATA_WIDTH; // 1024 / 512 = 2 beats
    
    localparam IDLE    = 3'd0;
    localparam AR_WAIT = 3'd1;
    localparam R_WAIT  = 3'd2;
    localparam AW_WAIT = 3'd3;
    localparam W_WAIT  = 3'd4;
    localparam B_WAIT  = 3'd5;

    reg [2:0] state, next_state;
    reg [AXI_ADDR_WIDTH-1:0] saved_req_addr;
    reg [ID_WIDTH-1:0] saved_req_id;
    reg [LINE_BYTES*8-1:0] saved_req_wdata;
    
    reg [3:0] beat_count;
    reg [LINE_BYTES*8-1:0] collected_rdata;

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
            resp_id <= 0;
            resp_rdata <= 0;
            saved_req_addr <= 0;
            saved_req_id <= 0;
            saved_req_wdata <= 0;
            beat_count <= 0;
            collected_rdata <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    req_ready <= 1'b1;
                    resp_valid <= 1'b0;
                    beat_count <= 0;
                    
                    if (req_valid && req_ready) begin
                        req_ready <= 1'b0;
                        saved_req_addr <= req_addr;
                        saved_req_id <= req_id;
                        saved_req_wdata <= req_wdata;
                        
                        if (req_write) begin
                            m_axi_awvalid <= 1'b1;
                            m_axi_awaddr <= req_addr;
                            m_axi_awlen <= BEATS_PER_LINE - 1;
                            m_axi_awid <= req_id;
                        end else begin
                            m_axi_arvalid <= 1'b1;
                            m_axi_araddr <= req_addr;
                            m_axi_arlen <= BEATS_PER_LINE - 1;
                            m_axi_arid <= req_id;
                            m_axi_rready <= 1'b1;
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
                        // Place each beat at its indexed position in the line.
                        collected_rdata[beat_count*AXI_DATA_WIDTH +: AXI_DATA_WIDTH] <= m_axi_rdata;
                        beat_count <= beat_count + 1;

                        if (m_axi_rlast) begin
                            m_axi_rready <= 1'b0;
                            resp_valid <= 1'b1;
                            resp_id <= saved_req_id;
                            // Assemble the response: previously-collected beats
                            // plus this final beat (the later part-select NBA wins
                            // for its bits, so no stale high bits leak through).
                            resp_rdata <= collected_rdata;
                            resp_rdata[beat_count*AXI_DATA_WIDTH +: AXI_DATA_WIDTH] <= m_axi_rdata;
                        end
                    end
                end
                
                AW_WAIT: begin
                    if (m_axi_awready && m_axi_awvalid) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b1;
                        // Present the first beat; wlast only if the line is 1 beat.
                        m_axi_wdata <= saved_req_wdata[0 +: AXI_DATA_WIDTH];
                        m_axi_wstrb <= {(AXI_DATA_WIDTH/8){1'b1}};
                        m_axi_wlast <= (BEATS_PER_LINE == 1);
                        beat_count <= 0;
                    end
                end

                W_WAIT: begin
                    if (m_axi_wready && m_axi_wvalid) begin
                        if (beat_count == BEATS_PER_LINE - 1) begin
                            // Last beat accepted: finish and wait for B response.
                            m_axi_wvalid <= 1'b0;
                            m_axi_wlast <= 1'b0;
                            m_axi_bready <= 1'b1;
                        end else begin
                            // Present the next beat; assert wlast when it is last.
                            beat_count <= beat_count + 1;
                            m_axi_wdata <= saved_req_wdata[(beat_count+1)*AXI_DATA_WIDTH +: AXI_DATA_WIDTH];
                            m_axi_wlast <= ((beat_count + 1) == BEATS_PER_LINE - 1);
                        end
                    end
                end
                
                B_WAIT: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                        resp_valid <= 1'b1;
                        resp_id <= saved_req_id;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (req_valid && req_ready) begin
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
                if (m_axi_awready && m_axi_awvalid) next_state = W_WAIT;
            end
            W_WAIT: begin
                if (m_axi_wready && m_axi_wvalid && m_axi_wlast) next_state = B_WAIT;
            end
            B_WAIT: begin
                if (m_axi_bvalid && m_axi_bready) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

endmodule
