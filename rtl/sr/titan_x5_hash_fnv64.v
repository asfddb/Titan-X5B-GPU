// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

/*
 * Module: titan_x5_hash_fnv64
 * Description: 64-bit FNV-1a hash module, 3-stage pipeline.
 */
module titan_x5_hash_fnv64 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        i_valid,
    input wire [63:0] i_data,
    output wire        o_valid,
    output wire [63:0] o_hash
);

    localparam FNV_OFFSET_BASIS = 64'hcbf29ce484222325;
    localparam FNV_PRIME        = 64'h00000100000001B3;

    function automatic [63:0] fnv_step;
    input [63:0] hash_in;
    input [7:0] data_byte;
        begin
            fnv_step = (hash_in ^ data_byte) * FNV_PRIME;
        end
    endfunction

    // stage 1 (bytes 0, 1, 2)
    reg [63:0] s1_hash;
    reg [39:0] s1_data_rem; // bytes 7..3
    reg        s1_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_hash     <= 64'd0;
            s1_data_rem <= 40'd0;
            s1_valid    <= 1'b0;
        end else begin
            s1_valid <= i_valid;
            if (i_valid) begin
                s1_hash <= fnv_step(
                             fnv_step(
                               fnv_step(FNV_OFFSET_BASIS, i_data[7:0]),
                               i_data[15:8]
                             ),
                             i_data[23:16]
                           );
                s1_data_rem <= i_data[63:24];
            end
        end
    end

    // stage 2 (bytes 3, 4, 5)
    reg [63:0] s2_hash;
    reg [15:0] s2_data_rem; // bytes 7..6
    reg        s2_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_hash     <= 64'd0;
            s2_data_rem <= 16'd0;
            s2_valid    <= 1'b0;
        end else begin
            s2_valid <= s1_valid;
            if (s1_valid) begin
                s2_hash <= fnv_step(
                             fnv_step(
                               fnv_step(s1_hash, s1_data_rem[7:0]),
                               s1_data_rem[15:8]
                             ),
                             s1_data_rem[23:16]
                           );
                s2_data_rem <= s1_data_rem[39:24];
            end
        end
    end

    // stage 3 (bytes 6, 7)
    reg [63:0] s3_hash;
    reg        s3_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_hash  <= 64'd0;
            s3_valid <= 1'b0;
        end else begin
            s3_valid <= s2_valid;
            if (s2_valid) begin
                s3_hash <= fnv_step(
                             fnv_step(s2_hash, s2_data_rem[7:0]),
                             s2_data_rem[15:8]
                           );
            end
        end
    end

    assign o_valid = s3_valid;
    assign o_hash  = s3_hash;

endmodule
