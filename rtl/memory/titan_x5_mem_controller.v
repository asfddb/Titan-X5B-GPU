`timescale 1ns / 1ps

/*
 * Titan X5 GPU - Memory Controller
 * - AXI4 master interface to external memory
 * - Supports up to 16 beat bursts
 */
module titan_x5_mem_controller #(
    parameter AXI_ADDR_WIDTH = 32,
    parameter AXI_DATA_WIDTH = 256,
    parameter AXI_ID_WIDTH   = 4
)(
    input wire clk,
    input wire rst_n,

    // Internal Request Interface
    input  wire                       req_valid,
    input  wire [AXI_ADDR_WIDTH-1:0]  req_addr,
    input  wire                       req_write,
    input  wire [AXI_DATA_WIDTH-1:0]  req_wdata,
    input  wire [3:0]                 req_len, // Burst length (0-15)
    output reg                        req_ready,

    output reg                        resp_valid,
    output reg  [AXI_DATA_WIDTH-1:0]  resp_rdata,

    // AXI4 Master Interface
    // AR Channel
    output reg  [AXI_ID_WIDTH-1:0]    m_axi_arid,
    output reg  [AXI_ADDR_WIDTH-1:0]  m_axi_araddr,
    output reg  [7:0]                 m_axi_arlen,
    output wire [2:0]                 m_axi_arsize,
    output wire [1:0]                 m_axi_arburst,
    output reg                        m_axi_arvalid,
    input  wire                       m_axi_arready,
    
    // R Channel
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_rid,
    input  wire [AXI_DATA_WIDTH-1:0]  m_axi_rdata,
    input  wire [1:0]                 m_axi_rresp,
    input  wire                       m_axi_rlast,
    input  wire                       m_axi_rvalid,
    output reg                        m_axi_rready,

    // AW Channel
    output reg  [AXI_ID_WIDTH-1:0]    m_axi_awid,
    output reg  [AXI_ADDR_WIDTH-1:0]  m_axi_awaddr,
    output reg  [7:0]                 m_axi_awlen,
    output wire [2:0]                 m_axi_awsize,
    output wire [1:0]                 m_axi_awburst,
    output reg                        m_axi_awvalid,
    input  wire                       m_axi_awready,
    
    // W Channel
    output reg  [AXI_DATA_WIDTH-1:0]  m_axi_wdata,
    output reg  [(AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb,
    output reg                        m_axi_wlast,
    output reg                        m_axi_wvalid,
    input  wire                       m_axi_wready,
    
    // B Channel
    input  wire [AXI_ID_WIDTH-1:0]    m_axi_bid,
    input  wire [1:0]                 m_axi_bresp,
    input  wire                       m_axi_bvalid,
    output reg                        m_axi_bready
);

    assign m_axi_arsize = 3'b101; // 32 bytes
    assign m_axi_arburst = 2'b01; // INCR
    assign m_axi_awsize = 3'b101; 
    assign m_axi_awburst = 2'b01;

    localparam IDLE   = 3'd0;
    localparam AR_WAIT = 3'd1;
    localparam R_WAIT  = 3'd2;
    localparam AW_WAIT = 3'd3;
    localparam W_WAIT  = 3'd4;
    localparam B_WAIT  = 3'd5;

    reg [2:0] state, next_state;

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
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    req_ready <= 1'b1;
                    resp_valid <= 1'b0;
                    if (req_valid && req_ready) begin
                        req_ready <= 1'b0;
                        if (req_write) begin
                            m_axi_awvalid <= 1'b1;
                            m_axi_awaddr <= req_addr;
                            m_axi_awlen <= req_len;
                            m_axi_awid <= 0;
                        end else begin
                            m_axi_arvalid <= 1'b1;
                            m_axi_araddr <= req_addr;
                            m_axi_arlen <= req_len;
                            m_axi_arid <= 0;
                        end
                    end
                end
                AR_WAIT: begin
                    if (m_axi_arready && m_axi_arvalid) begin
                        m_axi_arvalid <= 1'b0;
                        m_axi_rready <= 1'b1;
                    end
                end
                R_WAIT: begin
                    if (m_axi_rvalid && m_axi_rready) begin
                        resp_valid <= 1'b1;
                        resp_rdata <= m_axi_rdata;
                        if (m_axi_rlast) begin
                            m_axi_rready <= 1'b0;
                        end
                    end else begin
                        resp_valid <= 1'b0;
                    end
                end
                AW_WAIT: begin
                    if (m_axi_awready && m_axi_awvalid) begin
                        m_axi_awvalid <= 1'b0;
                        m_axi_wvalid <= 1'b1;
                        m_axi_wdata <= req_wdata; // Single beat simplify
                        m_axi_wstrb <= {(AXI_DATA_WIDTH/8){1'b1}};
                        m_axi_wlast <= 1'b1;
                    end
                end
                W_WAIT: begin
                    if (m_axi_wready && m_axi_wvalid) begin
                        m_axi_wvalid <= 1'b0;
                        m_axi_wlast <= 1'b0;
                        m_axi_bready <= 1'b1;
                    end
                end
                B_WAIT: begin
                    if (m_axi_bvalid && m_axi_bready) begin
                        m_axi_bready <= 1'b0;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (req_valid && req_ready) next_state = req_write ? AW_WAIT : AR_WAIT;
            AR_WAIT: if (m_axi_arready && m_axi_arvalid) next_state = R_WAIT;
            R_WAIT: if (m_axi_rvalid && m_axi_rready && m_axi_rlast) next_state = IDLE;
            AW_WAIT: if (m_axi_awready && m_axi_awvalid) next_state = W_WAIT;
            W_WAIT: if (m_axi_wready && m_axi_wvalid) next_state = B_WAIT;
            B_WAIT: if (m_axi_bvalid && m_axi_bready) next_state = IDLE;
        endcase
    end

endmodule
