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
 * Titan X7 GPU - output-stationary systolic tensor array (FP16 in, FP32 out).
 *
 * N x N grid of titan_x7_tensor_pe. A-operands stream west->east, B-operands
 * north->south, one register per hop (the PE's M1 input registers double as
 * the systolic pipeline registers). The caller injects row i of A delayed by
 * i cycles and column j of B delayed by j cycles (standard skew); this
 * module maintains matching valid-delay meshes so each PE multiplies only
 * aligned pairs.
 *
 * Protocol:
 *   1. stream K aligned (a_col, b_row) vectors on in_valid/a_in/b_in with
 *      the skew described above (in_valid[i] qualifies a_in row i;
 *      in_valid_b[j] qualifies b_in column j);
 *   2. wait >= 2*(N-1) + 4 cycles after the last injection (array flush +
 *      PE multiply pipeline depth);
 *   3. pulse drain; result_valid pulses 3 cycles later with all N*N FP32
 *      accumulators on result (row-major), and the array is clear for the
 *      next tile.
 *
 * Every accumulate is exact (Kulisch carry-save inside the PE); each output
 * element is the correctly-rounded (RNE) FP32 value of its exact dot
 * product.
 */
module titan_x7_tensor_array #(
    parameter N = 4
)(
    input  wire              clk,
    input  wire              rst_n,

    input  wire [N-1:0]      in_valid,      // per-row valid for a_in
    input  wire [N*16-1:0]   a_in,          // west edge: element per row
    input  wire [N-1:0]      in_valid_b,    // per-column valid for b_in
    input  wire [N*16-1:0]   b_in,          // north edge: element per column

    input  wire              drain,
    output wire              result_valid,
    output wire [N*N*32-1:0] result
);

    // inter-PE data meshes
    wire [15:0] a_mesh [0:N-1][0:N];       // a_mesh[i][j] feeds PE(i,j) west port
    wire [15:0] b_mesh [0:N][0:N-1];       // b_mesh[i][j] feeds PE(i,j) north port

    // valid delay meshes (aligned with the PE input registers): data reaches
    // PE(i,j) through j (resp. i) PE input registers, so the edge valid is
    // combinational and each inner hop adds one register
    wire [N-1:0] va [0:N-1];               // va[i][j]: a-valid at PE(i,j)
    wire [N-1:0] vb [0:N-1];               // vb[i][j]: b-valid at PE(i,j)
    reg  [N-1:0] va_r [0:N-1];             // registered inner columns (j>=1)
    reg  [N-1:0] vb_r [0:N-1];             // registered inner rows (i>=1)

    wire [31:0] pe_result [0:N-1][0:N-1];
    wire        pe_rvalid [0:N-1][0:N-1];

    genvar gi, gj;
    integer i, j;

    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_row
            assign a_mesh[gi][0] = a_in[gi*16 +: 16];
        end
        for (gj = 0; gj < N; gj = gj + 1) begin : g_col
            assign b_mesh[0][gj] = b_in[gj*16 +: 16];
        end

        for (gi = 0; gi < N; gi = gi + 1) begin : g_pe_row
            for (gj = 0; gj < N; gj = gj + 1) begin : g_pe_col
                wire mac_v = va[gi][gj] & vb[gi][gj];

                titan_x7_tensor_pe u_pe (
                    .clk(clk), .rst_n(rst_n),
                    .mac_valid(mac_v),
                    .a(a_mesh[gi][gj]),
                    .b(b_mesh[gi][gj]),
                    .acc_drain(drain),
                    .result_valid(pe_rvalid[gi][gj]),
                    .result(pe_result[gi][gj]),
                    .a_pass(a_mesh[gi][gj+1]),
                    .b_pass(b_mesh[gi+1][gj]),
                    .v_pass()
                );

                assign result[(gi*N+gj)*32 +: 32] = pe_result[gi][gj];
            end
        end
    endgenerate

    // valid meshes: va shifts east, vb shifts south, matching the 1-cycle
    // a_pass/b_pass registers inside each PE
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : g_va_edge
            assign va[gi][0] = in_valid[gi];
            for (gj = 1; gj < N; gj = gj + 1) begin : g_va_in
                assign va[gi][gj] = va_r[gi][gj];
            end
        end
        for (gj = 0; gj < N; gj = gj + 1) begin : g_vb_edge
            assign vb[0][gj] = in_valid_b[gj];
            for (gi = 1; gi < N; gi = gi + 1) begin : g_vb_in
                assign vb[gi][gj] = vb_r[gi][gj];
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < N; i = i + 1) begin
                va_r[i] <= {N{1'b0}};
                vb_r[i] <= {N{1'b0}};
            end
        end else begin
            for (i = 0; i < N; i = i + 1) begin
                for (j = N-1; j > 0; j = j - 1) begin
                    va_r[i][j] <= va[i][j-1];
                end
            end
            for (j = 0; j < N; j = j + 1) begin
                for (i = N-1; i > 0; i = i - 1) begin
                    vb_r[i][j] <= vb[i-1][j];
                end
            end
        end
    end

    assign result_valid = pe_rvalid[0][0];

endmodule
