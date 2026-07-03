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
 * Module: titan_x5_rasterizer
 * Description: Vectorized hardware triangle rasterizer. Evaluates 4x4 pixel stamps
 * concurrently in a single clock cycle. Includes proper coverage testing.
 */
module titan_x5_rasterizer #(
    parameter COORD_W = 16,
    parameter WEIGHT_W = 32
) (
    input  wire clk,
    input  wire rst_n,
    
    // triangle input
    input  wire i_valid,
    output wire i_ready,
    input wire [15:0] v0_x, v0_y,
    input wire [15:0] v1_x, v1_y,
    input wire [15:0] v2_x, v2_y,
    input wire [31:0] v0_z, v1_z, v2_z,
    
    // pixel output (4x4 vectorized stamp)
    output wire [15:0] o_valid, // bitmask of covered pixels in the 4x4 stamp
    input  wire o_ready,
    output wire signed [COORD_W-1:0] o_x, o_y, // base coordinate of 4x4 stamp
    output wire [16*WEIGHT_W-1:0] o_w0, o_w1, o_w2, // flattened barycentric weights
    output wire [16*32-1:0] o_z
);

    // stage 1: bounding box & deltas
    reg s1_valid;
    wire s1_ready;
    reg signed [COORD_W-1:0] s1_min_x, s1_max_x, s1_min_y, s1_max_y;
    reg signed [COORD_W:0] s1_dy0, s1_dx0, s1_dy1, s1_dx1, s1_dy2, s1_dx2;
    reg signed [WEIGHT_W-1:0] s1_c0, s1_c1, s1_c2;
    
    reg signed [31:0] s1_z0, s1_z1, s1_z2;
    reg signed [COORD_W-1:0] s1_v0_x, s1_v0_y;

    assign i_ready = !s1_valid || s1_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) s1_valid <= 0;
        else begin
            if (i_ready) s1_valid <= i_valid;
            else if (s1_ready) s1_valid <= 0;
        end
    end

    always @(posedge clk) begin
        if (i_ready && i_valid) begin
            // Align min coords to 4x4 boundaries for the stamp rasterization
            s1_min_x <= (($signed(v0_x) < $signed(v1_x)) ? (($signed(v0_x) < $signed(v2_x)) ? $signed(v0_x) : $signed(v2_x)) : (($signed(v1_x) < $signed(v2_x)) ? $signed(v1_x) : $signed(v2_x))) & ~16'h0003;
            s1_max_x <= ($signed(v0_x) > $signed(v1_x)) ? (($signed(v0_x) > $signed(v2_x)) ? $signed(v0_x) : $signed(v2_x)) : (($signed(v1_x) > $signed(v2_x)) ? $signed(v1_x) : $signed(v2_x));
            s1_min_y <= (($signed(v0_y) < $signed(v1_y)) ? (($signed(v0_y) < $signed(v2_y)) ? $signed(v0_y) : $signed(v2_y)) : (($signed(v1_y) < $signed(v2_y)) ? $signed(v1_y) : $signed(v2_y))) & ~16'h0003;
            s1_max_y <= ($signed(v0_y) > $signed(v1_y)) ? (($signed(v0_y) > $signed(v2_y)) ? $signed(v0_y) : $signed(v2_y)) : (($signed(v1_y) > $signed(v2_y)) ? $signed(v1_y) : $signed(v2_y));
            
            s1_dy0 <= $signed(v1_y) - $signed(v2_y); s1_dx0 <= $signed(v2_x) - $signed(v1_x);
            s1_dy1 <= $signed(v2_y) - $signed(v0_y); s1_dx1 <= $signed(v0_x) - $signed(v2_x);
            s1_dy2 <= $signed(v0_y) - $signed(v1_y); s1_dx2 <= $signed(v1_x) - $signed(v0_x);
            
            s1_c0 <= $signed(v1_x) * $signed(v2_y) - $signed(v2_x) * $signed(v1_y);
            s1_c1 <= $signed(v2_x) * $signed(v0_y) - $signed(v0_x) * $signed(v2_y);
            s1_c2 <= $signed(v0_x) * $signed(v1_y) - $signed(v1_x) * $signed(v0_y);
            
            s1_z0 <= v0_z; s1_z1 <= v1_z; s1_z2 <= v2_z;
            s1_v0_x <= v0_x; s1_v0_y <= v0_y;
        end
    end

    // stage 2: initial edge equations
    reg s2_valid;
    wire s2_ready;
    reg signed [COORD_W-1:0] s2_min_x, s2_max_x, s2_min_y, s2_max_y;
    reg signed [COORD_W:0] s2_dy0, s2_dx0, s2_dy1, s2_dx1, s2_dy2, s2_dx2;
    reg signed [WEIGHT_W-1:0] s2_e0_row, s2_e1_row, s2_e2_row;

    reg signed [31:0] s2_dzdx, s2_dzdy;
    reg signed [31:0] s2_z_row;
    
    wire signed [63:0] area = s1_c0 + s1_c1 + s1_c2;
    wire signed [63:0] dzdx_num = ($signed(s1_z1) - $signed(s1_z0)) * s1_dy1 + ($signed(s1_z2) - $signed(s1_z0)) * s1_dy2;
    wire signed [63:0] dzdy_num = ($signed(s1_z2) - $signed(s1_z0)) * s1_dx2 + ($signed(s1_z1) - $signed(s1_z0)) * s1_dx1;
    wire signed [31:0] cur_dzdx = (area != 0) ? (dzdx_num / area) : 32'd0;
    wire signed [31:0] cur_dzdy = (area != 0) ? (dzdy_num / area) : 32'd0;

    assign s1_ready = !s2_valid || s2_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) s2_valid <= 0;
        else if (s1_ready) s2_valid <= s1_valid;
        else if (s2_ready) s2_valid <= 0;
    end

    always @(posedge clk) begin
        if (s1_ready && s1_valid) begin
            s2_min_x <= s1_min_x; s2_max_x <= s1_max_x;
            s2_min_y <= s1_min_y; s2_max_y <= s1_max_y;
            s2_dy0 <= s1_dy0; s2_dx0 <= s1_dx0;
            s2_dy1 <= s1_dy1; s2_dx1 <= s1_dx1;
            s2_dy2 <= s1_dy2; s2_dx2 <= s1_dx2;
            s2_e0_row <= s1_dy0 * s1_min_x + s1_dx0 * s1_min_y + s1_c0;
            s2_e1_row <= s1_dy1 * s1_min_x + s1_dx1 * s1_min_y + s1_c1;
            s2_e2_row <= s1_dy2 * s1_min_x + s1_dx2 * s1_min_y + s1_c2;
            s2_dzdx <= cur_dzdx;
            s2_dzdy <= cur_dzdy;
            s2_z_row <= s1_z0 + cur_dzdx * (s1_min_x - s1_v0_x) + cur_dzdy * (s1_min_y - s1_v0_y);
        end
    end

    // stage 3: 4x4 Vectorized traversal logic
    reg traverse_active;
    reg signed [COORD_W-1:0] x_curr, y_curr;
    reg signed [WEIGHT_W-1:0] e0_val, e1_val, e2_val;
    reg signed [WEIGHT_W-1:0] e0_row, e1_row, e2_row;
    
    assign s2_ready = !traverse_active;

    reg [15:0] o_valid_reg;
    reg signed [COORD_W-1:0] o_x_reg, o_y_reg;
    reg [16*WEIGHT_W-1:0] o_w0_reg, o_w1_reg, o_w2_reg;
    reg [16*32-1:0] o_z_reg;

    reg signed [31:0] z_val;
    reg signed [31:0] z_row;

    assign o_valid = o_valid_reg;
    assign o_x = o_x_reg;
    assign o_y = o_y_reg;
    assign o_w0 = o_w0_reg;
    assign o_w1 = o_w1_reg;
    assign o_w2 = o_w2_reg;
    assign o_z = o_z_reg;

    wire signed [WEIGHT_W-1:0] e0_stamp [0:15];
    wire signed [WEIGHT_W-1:0] e1_stamp [0:15];
    wire signed [WEIGHT_W-1:0] e2_stamp [0:15];
    wire signed [31:0] z_stamp [0:15];
    wire [15:0] stamp_covered;

    genvar r, c;
    generate
        for (r = 0; r < 4; r = r + 1) begin : gen_r
            for (c = 0; c < 4; c = c + 1) begin : gen_c
                wire signed [WEIGHT_W-1:0] e0_val_loc = e0_val + c * s2_dy0 + r * s2_dx0;
                wire signed [WEIGHT_W-1:0] e1_val_loc = e1_val + c * s2_dy1 + r * s2_dx1;
                wire signed [WEIGHT_W-1:0] e2_val_loc = e2_val + c * s2_dy2 + r * s2_dx2;
                
                assign e0_stamp[r*4+c] = e0_val_loc;
                assign e1_stamp[r*4+c] = e1_val_loc;
                assign e2_stamp[r*4+c] = e2_val_loc;
                assign z_stamp[r*4+c] = z_val + c * s2_dzdx + r * s2_dzdy;
                
                // Pixel is covered if all edges >= 0 and it's strictly inside the max bounding box limits
                assign stamp_covered[r*4+c] = (e0_val_loc >= 0) && (e1_val_loc >= 0) && (e2_val_loc >= 0) &&
                                              (x_curr + c <= s2_max_x) && (y_curr + r <= s2_max_y);
            end
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            traverse_active <= 0;
            o_valid_reg <= 0;
        end else begin
            if (o_ready) o_valid_reg <= 0;

            if (!traverse_active && s2_valid) begin
                traverse_active <= 1;
                x_curr <= s2_min_x;
                y_curr <= s2_min_y;
                e0_val <= s2_e0_row;
                e1_val <= s2_e1_row;
                e2_val <= s2_e2_row;
                e0_row <= s2_e0_row;
                e1_row <= s2_e1_row;
                e2_row <= s2_e2_row;
                z_val <= s2_z_row;
                z_row <= s2_z_row;
            end else if (traverse_active) begin
                if (!o_valid_reg || o_ready) begin
                    o_valid_reg <= stamp_covered;
                    o_x_reg <= x_curr;
                    o_y_reg <= y_curr;
                    o_w0_reg <= {e0_stamp[15], e0_stamp[14], e0_stamp[13], e0_stamp[12], e0_stamp[11], e0_stamp[10], e0_stamp[9], e0_stamp[8], e0_stamp[7], e0_stamp[6], e0_stamp[5], e0_stamp[4], e0_stamp[3], e0_stamp[2], e0_stamp[1], e0_stamp[0]};
                    o_w1_reg <= {e1_stamp[15], e1_stamp[14], e1_stamp[13], e1_stamp[12], e1_stamp[11], e1_stamp[10], e1_stamp[9], e1_stamp[8], e1_stamp[7], e1_stamp[6], e1_stamp[5], e1_stamp[4], e1_stamp[3], e1_stamp[2], e1_stamp[1], e1_stamp[0]};
                    o_w2_reg <= {e2_stamp[15], e2_stamp[14], e2_stamp[13], e2_stamp[12], e2_stamp[11], e2_stamp[10], e2_stamp[9], e2_stamp[8], e2_stamp[7], e2_stamp[6], e2_stamp[5], e2_stamp[4], e2_stamp[3], e2_stamp[2], e2_stamp[1], e2_stamp[0]};
                    o_z_reg <= {z_stamp[15], z_stamp[14], z_stamp[13], z_stamp[12], z_stamp[11], z_stamp[10], z_stamp[9], z_stamp[8], z_stamp[7], z_stamp[6], z_stamp[5], z_stamp[4], z_stamp[3], z_stamp[2], z_stamp[1], z_stamp[0]};
                    
                    if (x_curr >= s2_max_x) begin
                        if (y_curr >= s2_max_y) begin
                            traverse_active <= 0; // finished
                        end else begin
                            x_curr <= s2_min_x;
                            y_curr <= y_curr + 4;
                            e0_row <= e0_row + (s2_dx0 <<< 2);
                            e1_row <= e1_row + (s2_dx1 <<< 2);
                            e2_row <= e2_row + (s2_dx2 <<< 2);
                            e0_val <= e0_row + (s2_dx0 <<< 2);
                            e1_val <= e1_row + (s2_dx1 <<< 2);
                            e2_val <= e2_row + (s2_dx2 <<< 2);
                            z_row <= z_row + (s2_dzdy <<< 2);
                            z_val <= z_row + (s2_dzdy <<< 2);
                        end
                    end else begin
                        x_curr <= x_curr + 4;
                        e0_val <= e0_val + (s2_dy0 <<< 2);
                        e1_val <= e1_val + (s2_dy1 <<< 2);
                        e2_val <= e2_val + (s2_dy2 <<< 2);
                        z_val <= z_val + (s2_dzdx <<< 2);
                    end
                end
            end
        end
    end
endmodule
