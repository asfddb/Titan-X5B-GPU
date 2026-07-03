// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

module titan_x5_async_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH_LOG2 = 4
) (
    // write domain
    input  wire                  wclk,
    input  wire                  wrst_n,
    input  wire                  winc,
    input wire [DATA_WIDTH-1:0] wdata,
    output wire                  wfull,
    
    // read domain
    input  wire                  rclk,
    input  wire                  rrst_n,
    input  wire                  rinc,
    output wire [DATA_WIDTH-1:0] rdata,
    output wire                  rempty
);

    localparam DEPTH = 1 << DEPTH_LOG2;
    
    (* ram_style="block" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    reg [DEPTH_LOG2:0] wptr_bin, rptr_bin;
    reg [DEPTH_LOG2:0] wptr_gray, rptr_gray;
    
    reg [DEPTH_LOG2:0] wq1_rptr, wq2_rptr;
    reg [DEPTH_LOG2:0] rq1_wptr, rq2_wptr;
    
    // binary to gray
    wire [DEPTH_LOG2:0] wptr_gray_next = (wptr_bin + 1'b1) ^ ((wptr_bin + 1'b1) >> 1);
    wire [DEPTH_LOG2:0] rptr_gray_next = (rptr_bin + 1'b1) ^ ((rptr_bin + 1'b1) >> 1);
    
    // write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_bin <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            mem[wptr_bin[DEPTH_LOG2-1:0]] <= wdata;
            wptr_bin <= wptr_bin + 1'b1;
            wptr_gray <= wptr_gray_next;
        end
    end
    
    // read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_bin <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr_bin <= rptr_bin + 1'b1;
            rptr_gray <= rptr_gray_next;
        end
    end
    
    reg [DATA_WIDTH-1:0] rdata_reg;
    always @(posedge rclk) begin
        rdata_reg <= mem[rptr_bin[DEPTH_LOG2-1:0]];
    end
    assign rdata = rdata_reg;
    // synchronizers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) {wq2_rptr, wq1_rptr} <= 0;
        else         {wq2_rptr, wq1_rptr} <= {wq1_rptr, rptr_gray};
    end
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) {rq2_wptr, rq1_wptr} <= 0;
        else         {rq2_wptr, rq1_wptr} <= {rq1_wptr, wptr_gray};
    end
    
    // flags
    assign wfull = (wptr_gray == {~wq2_rptr[DEPTH_LOG2:DEPTH_LOG2-1], wq2_rptr[DEPTH_LOG2-2:0]});
    assign rempty = (rptr_gray == rq2_wptr);

endmodule
