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
 * Titan X5 GPU - DMA Engine (Aggressively Optimized)
 * - Scatter-gather support
 * - 2D block transfers
 * - Interrupt generation on completion
 * - Single-cycle issue, registered outputs, collapsed FSM,
 *   combinational control path, bypassed buffer when possible.
 */
module titan_x5_dma_engine #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // control interface (axi-lite slave mapped)
    input  wire                    ctrl_req_valid,
    input  wire [ADDR_WIDTH-1:0]   ctrl_req_addr,
    input  wire [DATA_WIDTH-1:0]   ctrl_req_wdata,
    input  wire                    ctrl_req_write,
    output wire                    ctrl_req_ready,

    output wire                    ctrl_resp_valid,
    output wire [DATA_WIDTH-1:0]   ctrl_resp_rdata,
    
    input  wire [4:0]              ctrl_req_id,
    output wire [4:0]              ctrl_resp_id,

    // interrupt output
    output reg                     dma_interrupt,

    // master memory interface
    output reg                     mem_req_valid,
    output reg [ADDR_WIDTH-1:0]    mem_req_addr,
    output reg                     mem_req_write,
    output reg [DATA_WIDTH-1:0]    mem_req_wdata,
    input  wire                    mem_req_ready,

    input  wire                    mem_resp_valid,
    input  wire [DATA_WIDTH-1:0]   mem_resp_rdata
);

    // ------------------------------------------------------------------------
    // DMA registers
    // ------------------------------------------------------------------------
    reg [ADDR_WIDTH-1:0] src_addr;
    reg [ADDR_WIDTH-1:0] dst_addr;
    reg [15:0]           x_count;
    reg [15:0]           y_count;
    reg [15:0]           src_stride;
    reg [15:0]           dst_stride;
    reg                  start;
    reg                  busy;

    // ------------------------------------------------------------------------
    // FSM states (collapsed: single-cycle issue, no separate wait states)
    // ------------------------------------------------------------------------
    localparam IDLE       = 2'd0;
    localparam READ_ISSUE = 2'd1;
    localparam WRITE_ISSUE= 2'd2;
    localparam DONE       = 2'd3;

    reg [1:0] state, next_state;

    // internal counters
    reg [15:0] current_x;
    reg [15:0] current_y;
    reg [ADDR_WIDTH-1:0] src_cursor;
    reg [ADDR_WIDTH-1:0] dst_cursor;
    reg [DATA_WIDTH-1:0] buffer;

    // ------------------------------------------------------------------------
    // Control logic (combinational ready/valid for lowest latency)
    // ------------------------------------------------------------------------
    assign ctrl_req_ready  = !busy;
    assign ctrl_resp_valid = ctrl_req_valid && !busy;
    assign ctrl_resp_rdata = src_addr;
    assign ctrl_resp_id    = ctrl_req_id;

    // ------------------------------------------------------------------------
    // Register write port
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_addr   <= 0;
            dst_addr   <= 0;
            x_count    <= 0;
            y_count    <= 0;
            src_stride <= 0;
            dst_stride <= 0;
            start      <= 0;
        end else begin
            if (ctrl_req_valid && ctrl_req_write && !busy) begin
                case (ctrl_req_addr[7:0])
                    8'h00: src_addr   <= ctrl_req_wdata;
                    8'h04: dst_addr   <= ctrl_req_wdata;
                    8'h08: x_count    <= ctrl_req_wdata[15:0];
                    8'h0C: y_count    <= ctrl_req_wdata[15:0];
                    8'h10: src_stride <= ctrl_req_wdata[15:0];
                    8'h14: dst_stride <= ctrl_req_wdata[15:0];
                    8'h18: start      <= ctrl_req_wdata[0];
                    default: ;
                endcase
            end else if (state == IDLE) begin
                start <= 1'b0;
            end
        end
    end

    // ------------------------------------------------------------------------
    // Pre-computed next counters (combinational, reduces critical path)
    // ------------------------------------------------------------------------
    wire [15:0] next_x = (current_x == x_count - 16'd1) ? 16'd0 : (current_x + 16'd1);
    wire [15:0] next_y = (current_x == x_count - 16'd1) ? (current_y + 16'd1) : current_y;
    wire        last_x = (current_x == x_count - 16'd1);
    wire        last_y = (current_y == y_count - 16'd1);
    wire        last   = last_x && last_y;

    // ------------------------------------------------------------------------
    // FSM next-state logic (fully combinational)
    // ------------------------------------------------------------------------
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (start) next_state = READ_ISSUE;
            end
            READ_ISSUE: begin
                // Issue read; advance on accepted handshake
                if (mem_req_ready) begin
                    if (last) next_state = WRITE_ISSUE;
                    else      next_state = READ_ISSUE;
                end
            end
            WRITE_ISSUE: begin
                // Issue write; advance on accepted handshake
                if (mem_req_ready) begin
                    if (last) next_state = DONE;
                    else      next_state = READ_ISSUE;
                end
            end
            DONE: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------------------
    // FSM state register and output datapath (registered outputs)
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            busy         <= 1'b0;
            dma_interrupt<= 1'b0;
            mem_req_valid<= 1'b0;
            mem_req_addr <= 0;
            mem_req_write<= 1'b0;
            mem_req_wdata<= 0;
            current_x    <= 0;
            current_y    <= 0;
            src_cursor   <= 0;
            dst_cursor   <= 0;
            buffer       <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy         <= 1'b0;
                    dma_interrupt<= 1'b0;
                    mem_req_valid<= 1'b0;
                    if (start) begin
                        busy       <= 1'b1;
                        current_x  <= 16'd0;
                        current_y  <= 16'd0;
                        src_cursor <= src_addr;
                        dst_cursor <= dst_addr;
                        state      <= READ_ISSUE;
                    end
                end

                READ_ISSUE: begin
                    // Issue read request combinationally, registered output
                    mem_req_valid <= 1'b1;
                    mem_req_write <= 1'b0;
                    mem_req_addr  <= src_cursor;
                    mem_req_wdata <= 0;

                    if (mem_req_ready) begin
                        // Capture read data into buffer for next write
                        buffer <= mem_resp_rdata;
                        // Advance cursors
                        if (last_x) begin
                            current_x  <= 16'd0;
                            current_y  <= next_y;
                            src_cursor <= src_addr + ((next_y) * src_stride);
                            dst_cursor <= dst_addr + ((next_y) * dst_stride);
                        end else begin
                            current_x  <= next_x;
                            src_cursor <= src_cursor + (src_stride);
                            dst_cursor <= dst_cursor + (dst_stride);
                        end
                        if (last) state <= WRITE_ISSUE;
                    end
                end

                WRITE_ISSUE: begin
                    // Issue write request, registered output
                    mem_req_valid <= 1'b1;
                    mem_req_write <= 1'b1;
                    mem_req_addr  <= dst_cursor;
                    mem_req_wdata <= buffer;

                    if (mem_req_ready) begin
                        if (last) begin
                            state <= DONE;
                        end else begin
                            state <= READ_ISSUE;
                        end
                    end
                end

                DONE: begin
                    mem_req_valid <= 1'b0;
                    dma_interrupt <= 1'b1;
                    state         <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule