// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x_wse_sm #(
    parameter DATA_WIDTH = 64,
    parameter CORE_X = 16'd0,
    parameter CORE_Y = 16'd0
) (
    input  wire clk,
    input  wire rst_n,
    
    // defect bypass fuse
    input  wire is_defective,
    
    // noc interfaces
    input wire [DATA_WIDTH-1:0] noc_in_n,
    input wire [DATA_WIDTH-1:0] noc_in_s,
    input wire [DATA_WIDTH-1:0] noc_in_e,
    input wire [DATA_WIDTH-1:0] noc_in_w,
    
    output wire [DATA_WIDTH-1:0] noc_out_n,
    output wire [DATA_WIDTH-1:0] noc_out_s,
    output wire [DATA_WIDTH-1:0] noc_out_e,
    output wire [DATA_WIDTH-1:0] noc_out_w
);

    // packet structure: [63:48] dest x, [47:32] dest y, [31:0] payload
    wire [15:0] dest_x_n = noc_in_n[63:48];
    wire [15:0] dest_y_n = noc_in_n[47:32];
    wire [15:0] dest_x_s = noc_in_s[63:48];
    wire [15:0] dest_y_s = noc_in_s[47:32];
    wire [15:0] dest_x_e = noc_in_e[63:48];
    wire [15:0] dest_y_e = noc_in_e[47:32];
    wire [15:0] dest_x_w = noc_in_w[63:48];
    wire [15:0] dest_y_w = noc_in_w[47:32];

    reg [DATA_WIDTH-1:0] out_n, out_s, out_e, out_w;

    always @(*) begin
        out_n = 64'd0;
        out_s = 64'd0;
        out_e = 64'd0;
        out_w = 64'd0;

        if (is_defective) begin
            // hardware defect bypass: hardwire pass-through
            out_n = noc_in_s;
            out_s = noc_in_n;
            out_e = noc_in_w;
            out_w = noc_in_e;
        end else begin
            // X-Y Dimensional Routing logic (X first, then Y)
            
            // process packet from north
            if (noc_in_n != 0) begin
                if (dest_x_n == CORE_X && dest_y_n == CORE_Y)
                    out_s = {16'hFFFF, 16'hFFFF, ~noc_in_n[31:0]}; // respond with inverted payload
                else if (dest_x_n == 16'hFFFF) out_s = noc_in_n; // escape route (goes straight down)
                else if (dest_x_n < CORE_X) out_w = noc_in_n;
                else if (dest_x_n > CORE_X) out_e = noc_in_n;
                else if (dest_y_n > CORE_Y) out_s = noc_in_n;
            end
            
            // process packet from west
            if (noc_in_w != 0) begin
                if (dest_x_w == CORE_X && dest_y_w == CORE_Y)
                    out_s = {16'hFFFF, 16'hFFFF, ~noc_in_w[31:0]}; // respond with inverted payload (goes down)
                else if (dest_x_w == 16'hFFFF) out_s = noc_in_w; // escape route (goes straight down)
                else if (dest_x_w < CORE_X) out_w = noc_in_w; 
                else if (dest_x_w > CORE_X) out_e = noc_in_w;
                else if (dest_y_w > CORE_Y) out_s = noc_in_w;
                else if (dest_y_w < CORE_Y) out_n = noc_in_w;
            end
            
            // simple pass-through for other directions for this basic demo
            if (noc_in_s != 0) out_n = noc_in_s;
            if (noc_in_e != 0) out_w = noc_in_e;
        end
    end

    // add 1 cycle latency register for clean synthesis
    reg [DATA_WIDTH-1:0] out_n_reg, out_s_reg, out_e_reg, out_w_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_n_reg <= 0; out_s_reg <= 0; out_e_reg <= 0; out_w_reg <= 0;
        end else begin
            out_n_reg <= out_n;
            out_s_reg <= out_s;
            out_e_reg <= out_e;
            out_w_reg <= out_w;
        end
    end

    assign noc_out_n = out_n_reg;
    assign noc_out_s = out_s_reg;
    assign noc_out_e = out_e_reg;
    assign noc_out_w = out_w_reg;

endmodule
