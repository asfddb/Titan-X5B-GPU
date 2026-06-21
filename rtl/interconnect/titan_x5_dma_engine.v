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
 * Titan X5 GPU - DMA Engine
 * - Scatter-gather support
 * - 2D block transfers
 * - Interrupt generation on completion
 */
module titan_x5_dma_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire clk,
    input  wire rst_n,

    // control interface (axi-lite slave mapped)
    input  wire                    ctrl_req_valid,
    input wire [ADDR_WIDTH-1:0] ctrl_req_addr,
    input wire [DATA_WIDTH-1:0] ctrl_req_wdata,
    input  wire                    ctrl_req_write,
    output wire                    ctrl_req_ready,

    output wire                    ctrl_resp_valid,
    output wire [DATA_WIDTH-1:0] ctrl_resp_rdata,
    
    // interrupt output
    output reg                     dma_interrupt,

    // master memory interface
    output reg                     mem_req_valid,
    output reg [ADDR_WIDTH-1:0] mem_req_addr,
    output reg                     mem_req_write,
    output reg [DATA_WIDTH-1:0] mem_req_wdata,
    input  wire                    mem_req_ready,

    input  wire                    mem_resp_valid,
    input wire [DATA_WIDTH-1:0] mem_resp_rdata
);

    // dma registers
    reg [ADDR_WIDTH-1:0] src_addr;
    reg [ADDR_WIDTH-1:0] dst_addr;
    reg [15:0]           x_count;
    reg [15:0]           y_count;
    reg [15:0]           src_stride;
    reg [15:0]           dst_stride;
    reg                  start;
    reg                  busy;

    // fsm states
    localparam IDLE       = 3'd0;
    localparam READ_DATA  = 3'd1;
    localparam WAIT_READ  = 3'd2;
    localparam WRITE_DATA = 3'd3;
    localparam WAIT_WRITE = 3'd4;
    localparam DONE       = 3'd5;

    reg [2:0] state, next_state;

    // internal counters
    reg [15:0] current_x;
    reg [15:0] current_y;
    reg [DATA_WIDTH-1:0] buffer; // simple single-word buffer

    // control logic
    assign ctrl_req_ready = !busy;
    assign ctrl_resp_valid = ctrl_req_valid && !busy;
    assign ctrl_resp_rdata = 32'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_addr <= 0;
            dst_addr <= 0;
            x_count <= 0;
            y_count <= 0;
            src_stride <= 0;
            dst_stride <= 0;
            start <= 0;
        end else begin
            if (ctrl_req_valid && ctrl_req_write && !busy) begin
                case (ctrl_req_addr[7:0])
                    8'h00: src_addr <= ctrl_req_wdata;
                    8'h04: dst_addr <= ctrl_req_wdata;
                    8'h08: x_count <= ctrl_req_wdata[15:0];
                    8'h0C: y_count <= ctrl_req_wdata[15:0];
                    8'h10: src_stride <= ctrl_req_wdata[15:0];
                    8'h14: dst_stride <= ctrl_req_wdata[15:0];
                    8'h18: start <= ctrl_req_wdata[0];
                endcase
            end else begin
                start <= 0; // auto-clear start bit
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            dma_interrupt <= 0;
            current_x <= 0;
            current_y <= 0;
            mem_req_valid <= 0;
        end else begin
            state <= next_state;

            case (state)
                IDLE: begin
                    dma_interrupt <= 1'b0;
                    if (start) begin
                        busy <= 1'b1;
                        current_x <= 0;
                        current_y <= 0;
                    end else begin
                        busy <= 1'b0;
                    end
                end
                READ_DATA: begin
                    mem_req_valid <= 1'b1;
                    mem_req_write <= 1'b0;
                    mem_req_addr <= src_addr + (current_y * src_stride) + (current_x * 4); // 4 bytes per word
                end
                WAIT_READ: begin
                    if (mem_req_ready) mem_req_valid <= 1'b0;
                    if (mem_resp_valid) buffer <= mem_resp_rdata;
                end
                WRITE_DATA: begin
                    mem_req_valid <= 1'b1;
                    mem_req_write <= 1'b1;
                    mem_req_addr <= dst_addr + (current_y * dst_stride) + (current_x * 4);
                    mem_req_wdata <= buffer;
                end
                WAIT_WRITE: begin
                    if (mem_req_ready) begin
                        mem_req_valid <= 1'b0;
                        // increment logic
                        if (current_x == x_count - 1) begin
                            current_x <= 0;
                            current_y <= current_y + 1;
                        end else begin
                            current_x <= current_x + 1;
                        end
                    end
                end
                DONE: begin
                    busy <= 1'b0;
                    dma_interrupt <= 1'b1;
                end
            endcase
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = READ_DATA;
            READ_DATA: if (mem_req_valid && mem_req_ready) next_state = WAIT_READ;
            WAIT_READ: if (mem_resp_valid) next_state = WRITE_DATA;
            WRITE_DATA: if (mem_req_valid && mem_req_ready) next_state = WAIT_WRITE;
            WAIT_WRITE: begin
                if (mem_req_ready) begin
                    if (current_x == x_count - 1 && current_y == y_count - 1)
                        next_state = DONE;
                    else
                        next_state = READ_DATA;
                end
            end
            DONE: next_state = IDLE;
        endcase
    end

endmodule
