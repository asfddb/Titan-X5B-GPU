// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Titan X5 GPU - HBM3 Memory Controller
 * - 1024-bit ultra-wide internal datapath
 * - Pseudo-Channel (PC) mode: Splits 1024-bit requests into two independent 512-bit AXI4 interfaces
 * - PC0 handles lower 512 bits (64 bytes), PC1 handles upper 512 bits
 * - Designed to replace the standard DDR controller
 */
module titan_x5_hbm3_controller #(
    parameter AXI_ADDR_WIDTH = 33, // 8GB per stack
    parameter AXI_DATA_WIDTH = 1024,
    parameter PC_DATA_WIDTH  = 512,
    parameter AXI_ID_WIDTH   = 4
)(
    input wire clk,
    input wire rst_n,

    // 1024-bit Internal Request Interface
    input  wire                       req_valid,
    input wire [AXI_ADDR_WIDTH-1:0] req_addr,
    input  wire                       req_write,
    input wire [AXI_DATA_WIDTH-1:0] req_wdata,
    input wire [3:0] req_len,
    output wire                       req_ready,

    output wire                       resp_valid,
    output wire [AXI_DATA_WIDTH-1:0] resp_rdata,

    // axi4 master interface - pseudo channel 0 (lower 64b)
    output wire [AXI_ID_WIDTH-1:0] pc0_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0] pc0_axi_araddr,
    output wire [7:0] pc0_axi_arlen,
    output wire [2:0] pc0_axi_arsize,
    output wire [1:0] pc0_axi_arburst,
    output wire                       pc0_axi_arvalid,
    input  wire                       pc0_axi_arready,
    
    input wire [AXI_ID_WIDTH-1:0] pc0_axi_rid,
    input wire [PC_DATA_WIDTH-1:0] pc0_axi_rdata,
    input wire [1:0] pc0_axi_rresp,
    input  wire                       pc0_axi_rlast,
    input  wire                       pc0_axi_rvalid,
    output wire                       pc0_axi_rready,

    output wire [AXI_ID_WIDTH-1:0] pc0_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0] pc0_axi_awaddr,
    output wire [7:0] pc0_axi_awlen,
    output wire [2:0] pc0_axi_awsize,
    output wire [1:0] pc0_axi_awburst,
    output wire                       pc0_axi_awvalid,
    input  wire                       pc0_axi_awready,
    
    output wire [PC_DATA_WIDTH-1:0] pc0_axi_wdata,
    output wire [(PC_DATA_WIDTH/8)-1:0] pc0_axi_wstrb,
    output wire                       pc0_axi_wlast,
    output wire                       pc0_axi_wvalid,
    input  wire                       pc0_axi_wready,
    
    input wire [AXI_ID_WIDTH-1:0] pc0_axi_bid,
    input wire [1:0] pc0_axi_bresp,
    input  wire                       pc0_axi_bvalid,
    output wire                       pc0_axi_bready,

    // axi4 master interface - pseudo channel 1 (upper 64b)
    output wire [AXI_ID_WIDTH-1:0] pc1_axi_arid,
    output wire [AXI_ADDR_WIDTH-1:0] pc1_axi_araddr,
    output wire [7:0] pc1_axi_arlen,
    output wire [2:0] pc1_axi_arsize,
    output wire [1:0] pc1_axi_arburst,
    output wire                       pc1_axi_arvalid,
    input  wire                       pc1_axi_arready,
    
    input wire [AXI_ID_WIDTH-1:0] pc1_axi_rid,
    input wire [PC_DATA_WIDTH-1:0] pc1_axi_rdata,
    input wire [1:0] pc1_axi_rresp,
    input  wire                       pc1_axi_rlast,
    input  wire                       pc1_axi_rvalid,
    output wire                       pc1_axi_rready,

    output wire [AXI_ID_WIDTH-1:0] pc1_axi_awid,
    output wire [AXI_ADDR_WIDTH-1:0] pc1_axi_awaddr,
    output wire [7:0] pc1_axi_awlen,
    output wire [2:0] pc1_axi_awsize,
    output wire [1:0] pc1_axi_awburst,
    output wire                       pc1_axi_awvalid,
    input  wire                       pc1_axi_awready,
    
    output wire [PC_DATA_WIDTH-1:0] pc1_axi_wdata,
    output wire [(PC_DATA_WIDTH/8)-1:0] pc1_axi_wstrb,
    output wire                       pc1_axi_wlast,
    output wire                       pc1_axi_wvalid,
    input  wire                       pc1_axi_wready,
    
    input wire [AXI_ID_WIDTH-1:0] pc1_axi_bid,
    input wire [1:0] pc1_axi_bresp,
    input  wire                       pc1_axi_bvalid,
    output wire                       pc1_axi_bready
);

    // axi properties for 512-bit (64-byte) pseudo-channels
    assign pc0_axi_arsize = 3'b110; // 64 bytes
    assign pc0_axi_arburst = 2'b01; // incr
    assign pc0_axi_awsize = 3'b110; 
    assign pc0_axi_awburst = 2'b01;

    assign pc1_axi_arsize = 3'b110; // 64 bytes
    assign pc1_axi_arburst = 2'b01; // incr
    assign pc1_axi_awsize = 3'b110; 
    assign pc1_axi_awburst = 2'b01;

    // fsm states
    localparam IDLE    = 3'd0;
    localparam AR_WAIT = 3'd1;
    localparam R_WAIT  = 3'd2;
    localparam AW_WAIT = 3'd3;
    localparam W_WAIT  = 3'd4;
    localparam B_WAIT  = 3'd5;

    reg [2:0] state, next_state;

    // acknowledgement tracking for both pcs
    reg pc0_done, pc1_done;

    // axi registers
    reg pc0_arvalid_reg, pc1_arvalid_reg;
    reg pc0_awvalid_reg, pc1_awvalid_reg;
    reg pc0_wvalid_reg,  pc1_wvalid_reg;
    reg pc0_bready_reg,  pc1_bready_reg;
    reg pc0_rready_reg,  pc1_rready_reg;

    reg [AXI_ADDR_WIDTH-1:0] latched_addr;
    reg [7:0]                latched_len;
    reg [AXI_DATA_WIDTH-1:0] latched_wdata;

    // assign outputs
    assign pc0_axi_arvalid = pc0_arvalid_reg;
    assign pc1_axi_arvalid = pc1_arvalid_reg;
    assign pc0_axi_awvalid = pc0_awvalid_reg;
    assign pc1_axi_awvalid = pc1_awvalid_reg;
    assign pc0_axi_wvalid  = pc0_wvalid_reg;
    assign pc1_axi_wvalid  = pc1_wvalid_reg;
    assign pc0_axi_bready  = pc0_bready_reg;
    assign pc1_axi_bready  = pc1_bready_reg;
    assign pc0_axi_rready  = pc0_rready_reg;
    assign pc1_axi_rready  = pc1_rready_reg;

    // hbm3 controller distributes the single request to both pcs
    assign pc0_axi_araddr = latched_addr;
    assign pc1_axi_araddr = latched_addr; 
    assign pc0_axi_awaddr = latched_addr;
    assign pc1_axi_awaddr = latched_addr;

    assign pc0_axi_arlen = latched_len;
    assign pc1_axi_arlen = latched_len;
    assign pc0_axi_awlen = latched_len;
    assign pc1_axi_awlen = latched_len;

    assign pc0_axi_arid = 0;
    assign pc1_axi_arid = 0;
    assign pc0_axi_awid = 0;
    assign pc1_axi_awid = 0;

    assign pc0_axi_wdata = latched_wdata[511:0];
    assign pc1_axi_wdata = latched_wdata[1023:512];
    
    assign pc0_axi_wstrb = {(PC_DATA_WIDTH/8){1'b1}};
    assign pc1_axi_wstrb = {(PC_DATA_WIDTH/8){1'b1}};
    
    assign pc0_axi_wlast = 1'b1;
    assign pc1_axi_wlast = 1'b1;

    assign req_ready  = (state == IDLE);
    
    // combine responses
    assign resp_valid = (state == R_WAIT) && pc0_axi_rvalid && pc1_axi_rvalid;
    assign resp_rdata = {pc1_axi_rdata, pc0_axi_rdata};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            pc0_arvalid_reg <= 0; pc1_arvalid_reg <= 0;
            pc0_awvalid_reg <= 0; pc1_awvalid_reg <= 0;
            pc0_wvalid_reg  <= 0; pc1_wvalid_reg  <= 0;
            pc0_bready_reg  <= 0; pc1_bready_reg  <= 0;
            pc0_rready_reg  <= 0; pc1_rready_reg  <= 0;
            pc0_done <= 0; pc1_done <= 0;
            latched_addr <= 0;
            latched_len <= 0;
            latched_wdata <= 0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    pc0_done <= 0; pc1_done <= 0;
                    if (req_valid && req_ready) begin
                        latched_addr <= req_addr;
                        latched_len  <= {4'b0, req_len};
                        latched_wdata <= req_wdata;
                        
                        if (req_write) begin
                            pc0_awvalid_reg <= 1'b1;
                            pc1_awvalid_reg <= 1'b1;
                        end else begin
                            pc0_arvalid_reg <= 1'b1;
                            pc1_arvalid_reg <= 1'b1;
                        end
                    end
                end

                AR_WAIT: begin
                    if (pc0_axi_arready && pc0_arvalid_reg) begin
                        pc0_arvalid_reg <= 1'b0;
                        pc0_rready_reg <= 1'b1;
                        pc0_done <= 1'b1;
                    end
                    if (pc1_axi_arready && pc1_arvalid_reg) begin
                        pc1_arvalid_reg <= 1'b0;
                        pc1_rready_reg <= 1'b1;
                        pc1_done <= 1'b1;
                    end
                    if ((pc0_done || (pc0_axi_arready && pc0_arvalid_reg)) && 
                        (pc1_done || (pc1_axi_arready && pc1_arvalid_reg))) begin
                        pc0_done <= 0; pc1_done <= 0;
                    end
                end

                R_WAIT: begin
                    if (resp_valid) begin
                        if (pc0_axi_rlast && pc1_axi_rlast) begin
                            pc0_rready_reg <= 1'b0;
                            pc1_rready_reg <= 1'b0;
                        end
                    end
                end

                AW_WAIT: begin
                    if (pc0_axi_awready && pc0_awvalid_reg) begin
                        pc0_awvalid_reg <= 1'b0;
                        pc0_wvalid_reg <= 1'b1;
                        pc0_done <= 1'b1;
                    end
                    if (pc1_axi_awready && pc1_awvalid_reg) begin
                        pc1_awvalid_reg <= 1'b0;
                        pc1_wvalid_reg <= 1'b1;
                        pc1_done <= 1'b1;
                    end
                    if ((pc0_done || (pc0_axi_awready && pc0_awvalid_reg)) && 
                        (pc1_done || (pc1_axi_awready && pc1_awvalid_reg))) begin
                        pc0_done <= 0; pc1_done <= 0;
                    end
                end

                W_WAIT: begin
                    if (pc0_axi_wready && pc0_wvalid_reg) begin
                        pc0_wvalid_reg <= 1'b0;
                        pc0_bready_reg <= 1'b1;
                        pc0_done <= 1'b1;
                    end
                    if (pc1_axi_wready && pc1_wvalid_reg) begin
                        pc1_wvalid_reg <= 1'b0;
                        pc1_bready_reg <= 1'b1;
                        pc1_done <= 1'b1;
                    end
                    if ((pc0_done || (pc0_axi_wready && pc0_wvalid_reg)) && 
                        (pc1_done || (pc1_axi_wready && pc1_wvalid_reg))) begin
                        pc0_done <= 0; pc1_done <= 0;
                    end
                end

                B_WAIT: begin
                    if (pc0_axi_bvalid && pc0_bready_reg) begin
                        pc0_bready_reg <= 1'b0;
                        pc0_done <= 1'b1;
                    end
                    if (pc1_axi_bvalid && pc1_bready_reg) begin
                        pc1_bready_reg <= 1'b0;
                        pc1_done <= 1'b1;
                    end
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (req_valid && req_ready) next_state = req_write ? AW_WAIT : AR_WAIT;
            AR_WAIT: if ((pc0_done || (pc0_axi_arready && pc0_arvalid_reg)) && 
                         (pc1_done || (pc1_axi_arready && pc1_arvalid_reg))) next_state = R_WAIT;
            R_WAIT: if (resp_valid && pc0_axi_rlast && pc1_axi_rlast) next_state = IDLE;
            AW_WAIT: if ((pc0_done || (pc0_axi_awready && pc0_awvalid_reg)) && 
                         (pc1_done || (pc1_axi_awready && pc1_awvalid_reg))) next_state = W_WAIT;
            W_WAIT: if ((pc0_done || (pc0_axi_wready && pc0_wvalid_reg)) && 
                        (pc1_done || (pc1_axi_wready && pc1_wvalid_reg))) next_state = B_WAIT;
            B_WAIT: if ((pc0_done || (pc0_axi_bvalid && pc0_bready_reg)) && 
                        (pc1_done || (pc1_axi_bvalid && pc1_bready_reg))) next_state = IDLE;
        endcase
    end

endmodule
