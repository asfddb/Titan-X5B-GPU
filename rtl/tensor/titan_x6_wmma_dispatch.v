// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

/*
 * Module: titan_x6_wmma_dispatch
 * Description: Warp-synchronous WMMA front end for the tensor core array.
 *
 * The SM's 32 lanes deposit matrix fragments (elements of A: MxK and
 * B: KxN) into operand collectors at their own pace; each write marks the
 * lane in a 32-bit arrival mask. A WMMA instruction issues only when all
 * 32 lanes have arrived (warp-synchronous semantics) - until then
 * wmma_issue_ready stays low but the SM is free to run other warps: the
 * dispatcher, not the SM pipeline, owns the wait, which is what prevents
 * titan_x5_sm from stalling on tensor ops.
 *
 * On issue the sequencer runs the full systolic schedule autonomously:
 *   1  acc_clear pulse
 *   2  stream k = 0..K-1 diagonals (plus M+N zero-flush cycles so the
 *      internal skew drains)
 *   3  shift the output-stationary accumulators down (M capture cycles)
 *   4  pulse wmma_done; C is then readable via c_rd_row/c_rd_col
 *
 * One WMMA (M,N,K) = (16,16,16) INT8 op through this unit performs
 * 16x16x2 = 512 MACs per streaming cycle at the array face.
 */
module titan_x6_wmma_dispatch #(
    parameter M          = 16,   // rows of A / C
    parameter N          = 16,   // cols of B / C
    parameter K          = 16,   // reduction depth
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32
)(
    input  wire        clk,
    input  wire        rst_n,

    // operand-collector writes from the warp's lanes
    input  wire        frag_wr_valid,
    input  wire        frag_wr_matrix,           // 0 = A, 1 = B
    input  wire [7:0]  frag_wr_row,
    input  wire [7:0]  frag_wr_col,
    input  wire [DATA_WIDTH-1:0] frag_wr_data,
    input  wire [4:0]  frag_wr_lane,

    // warp-synchronous issue
    input  wire        wmma_issue_valid,
    output wire        wmma_issue_ready,         // all 32 lanes arrived + idle
    input  wire [1:0]  wmma_mode,                // array mode (see array hdr)
    input  wire        wmma_fp8_fmt,

    // completion / result readout
    output reg         wmma_done,                // 1-cycle pulse
    output wire        busy,
    output wire [31:0] lane_arrival_mask,
    input  wire [7:0]  c_rd_row,
    input  wire [7:0]  c_rd_col,
    output wire [ACC_WIDTH-1:0] c_rd_data
);

    localparam S_IDLE   = 2'd0;
    localparam S_STREAM = 2'd1;
    localparam S_DRAIN  = 2'd2;
    localparam S_DONE   = 2'd3;

    // stream long enough for the last diagonal to reach PE(M-1,N-1) and
    // retire through the product register
    localparam STREAM_LEN = K + M + N;

    reg [1:0]  state;
    reg [15:0] cnt;
    reg [1:0]  mode_r;
    reg        fmt_r;

    // operand collectors
    reg [DATA_WIDTH-1:0] a_buf [0:M*K-1];
    reg [DATA_WIDTH-1:0] b_buf [0:K*N-1];
    reg [ACC_WIDTH-1:0]  c_buf [0:M*N-1];
    reg [31:0]           lane_mask;

    assign lane_arrival_mask = lane_mask;
    assign wmma_issue_ready  = (state == S_IDLE) && (&lane_mask);
    assign busy              = (state != S_IDLE);
    assign c_rd_data         = c_buf[c_rd_row * N + c_rd_col];

    // ------------------------------------------------------------------
    // array feed (diagonal k = cnt while streaming, zero flush after K)
    // ------------------------------------------------------------------
    reg [(M*DATA_WIDTH)-1:0] act_bus;
    reg [(N*DATA_WIDTH)-1:0] weight_bus;
    integer fi;
    always @(*) begin
        act_bus    = {(M*DATA_WIDTH){1'b0}};
        weight_bus = {(N*DATA_WIDTH){1'b0}};
        if (state == S_STREAM && cnt < K) begin
            for (fi = 0; fi < M; fi = fi + 1)
                act_bus[fi*DATA_WIDTH +: DATA_WIDTH] = a_buf[fi*K + cnt[7:0]];
            for (fi = 0; fi < N; fi = fi + 1)
                weight_bus[fi*DATA_WIDTH +: DATA_WIDTH] = b_buf[cnt[7:0]*N + fi];
        end
    end

    wire arr_en        = (state == S_STREAM);
    wire arr_acc_clear = (state == S_STREAM) && (cnt == 16'd0);
    wire arr_drain     = (state == S_DRAIN) && (cnt < M-1);
    wire [(N*ACC_WIDTH)-1:0] arr_acc_out;

    titan_x6_tensor_core_array #(
        .ARRAY_SIZE_X(N),
        .ARRAY_SIZE_Y(M),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_array (
        .clk(clk), .rst_n(rst_n),
        .en(arr_en),
        .mode(mode_r),
        .fp8_fmt(fmt_r),
        .acc_clear(arr_acc_clear),
        .drain(arr_drain),
        .act_in(act_bus),
        .weight_in(weight_bus),
        .acc_out(arr_acc_out),
        .out_valid()
    );

    // ------------------------------------------------------------------
    // control
    // ------------------------------------------------------------------
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= S_IDLE;
            cnt       <= 16'd0;
            mode_r    <= 2'd0;
            fmt_r     <= 1'b0;
            lane_mask <= 32'd0;
            wmma_done <= 1'b0;
        end else begin
            wmma_done <= 1'b0;

            // operand collection runs in every state; arrivals for the
            // next op may overlap the drain of the current one
            if (frag_wr_valid) begin
                if (frag_wr_matrix)
                    b_buf[frag_wr_row * N + frag_wr_col] <= frag_wr_data;
                else
                    a_buf[frag_wr_row * K + frag_wr_col] <= frag_wr_data;
                lane_mask[frag_wr_lane] <= 1'b1;
            end

            case (state)
                S_IDLE: begin
                    if (wmma_issue_valid && (&lane_mask)) begin
                        mode_r    <= wmma_mode;
                        fmt_r     <= wmma_fp8_fmt;
                        // re-arm the warp barrier; a fragment landing this
                        // same cycle counts toward the next op
                        lane_mask <= frag_wr_valid ? (32'd1 << frag_wr_lane)
                                                   : 32'd0;
                        cnt       <= 16'd0;
                        state     <= S_STREAM;
                    end
                end
                S_STREAM: begin
                    if (cnt == STREAM_LEN-1) begin
                        cnt   <= 16'd0;
                        state <= S_DRAIN;
                    end else
                        cnt <= cnt + 16'd1;
                end
                S_DRAIN: begin
                    // acc_out currently shows row M-1-cnt
                    for (j = 0; j < N; j = j + 1)
                        c_buf[(M-1 - cnt[7:0]) * N + j] <= arr_acc_out[j*ACC_WIDTH +: ACC_WIDTH];
                    if (cnt == M-1) begin
                        cnt   <= 16'd0;
                        state <= S_DONE;
                    end else
                        cnt <= cnt + 16'd1;
                end
                S_DONE: begin
                    wmma_done <= 1'b1;
                    state     <= S_IDLE;
                end
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
