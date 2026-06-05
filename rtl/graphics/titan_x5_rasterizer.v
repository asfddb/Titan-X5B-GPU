`timescale 1ns/1ps

/*
 * Module: titan_x5_rasterizer
 * Description: Hardware triangle rasterizer. Edge equation setup, scanline traversal, 
 * bounding box optimization, pixel coverage test, barycentric interpolation.
 * Now using a fully pipelined decoupled approach.
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
    
    // pixel output
    output wire o_valid,
    input  wire o_ready,
    output wire signed [COORD_W-1:0] o_x, o_y,
    output wire signed [WEIGHT_W-1:0] o_w0, o_w1, o_w2
);

    // stage 1: bounding box & deltas
    reg s1_valid;
    wire s1_ready;
    reg signed [COORD_W-1:0] s1_min_x, s1_max_x, s1_min_y, s1_max_y;
    reg signed [COORD_W:0] s1_dy0, s1_dx0, s1_dy1, s1_dx1, s1_dy2, s1_dx2;
    reg signed [WEIGHT_W-1:0] s1_c0, s1_c1, s1_c2;

    assign i_ready = !s1_valid || s1_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 0;
        end else begin
            if (i_ready) begin
                s1_valid <= i_valid;
            end else if (s1_ready) begin
                s1_valid <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (i_ready && i_valid) begin
            s1_min_x <= ($signed(v0_x) < $signed(v1_x)) ? (($signed(v0_x) < $signed(v2_x)) ? $signed(v0_x) : $signed(v2_x)) : (($signed(v1_x) < $signed(v2_x)) ? $signed(v1_x) : $signed(v2_x));
            s1_max_x <= ($signed(v0_x) > $signed(v1_x)) ? (($signed(v0_x) > $signed(v2_x)) ? $signed(v0_x) : $signed(v2_x)) : (($signed(v1_x) > $signed(v2_x)) ? $signed(v1_x) : $signed(v2_x));
            s1_min_y <= ($signed(v0_y) < $signed(v1_y)) ? (($signed(v0_y) < $signed(v2_y)) ? $signed(v0_y) : $signed(v2_y)) : (($signed(v1_y) < $signed(v2_y)) ? $signed(v1_y) : $signed(v2_y));
            s1_max_y <= ($signed(v0_y) > $signed(v1_y)) ? (($signed(v0_y) > $signed(v2_y)) ? $signed(v0_y) : $signed(v2_y)) : (($signed(v1_y) > $signed(v2_y)) ? $signed(v1_y) : $signed(v2_y));
            
            s1_dy0 <= $signed(v1_y) - $signed(v2_y); s1_dx0 <= $signed(v2_x) - $signed(v1_x);
            s1_dy1 <= $signed(v2_y) - $signed(v0_y); s1_dx1 <= $signed(v0_x) - $signed(v2_x);
            s1_dy2 <= $signed(v0_y) - $signed(v1_y); s1_dx2 <= $signed(v1_x) - $signed(v0_x);
            
            s1_c0 <= $signed(v1_x) * $signed(v2_y) - $signed(v2_x) * $signed(v1_y);
            s1_c1 <= $signed(v2_x) * $signed(v0_y) - $signed(v0_x) * $signed(v2_y);
            s1_c2 <= $signed(v0_x) * $signed(v1_y) - $signed(v1_x) * $signed(v0_y);
        end
    end

    // stage 2: initial edge equations
    reg s2_valid;
    wire s2_ready;
    reg signed [COORD_W-1:0] s2_min_x, s2_max_x, s2_min_y, s2_max_y;
    reg signed [COORD_W:0] s2_dy0, s2_dx0, s2_dy1, s2_dx1, s2_dy2, s2_dx2;
    reg signed [WEIGHT_W-1:0] s2_e0_row, s2_e1_row, s2_e2_row;

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
        end
    end

    // stage 3: traversal logic
    reg traverse_active;
    reg signed [COORD_W-1:0] x_curr, y_curr;
    reg signed [WEIGHT_W-1:0] e0_val, e1_val, e2_val;
    reg signed [WEIGHT_W-1:0] e0_row, e1_row, e2_row;
    
    assign s2_ready = !traverse_active;

    reg o_valid_reg;
    reg signed [COORD_W-1:0] o_x_reg, o_y_reg;
    reg signed [WEIGHT_W-1:0] o_w0_reg, o_w1_reg, o_w2_reg;

    assign o_valid = o_valid_reg;
    assign o_x = o_x_reg;
    assign o_y = o_y_reg;
    assign o_w0 = o_w0_reg;
    assign o_w1 = o_w1_reg;
    assign o_w2 = o_w2_reg;

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
            end else if (traverse_active) begin
                if (!o_valid_reg || o_ready) begin
                    if (e0_val >= 0 && e1_val >= 0 && e2_val >= 0) begin
                        o_valid_reg <= 1'b1;
                        o_x_reg <= x_curr;
                        o_y_reg <= y_curr;
                        o_w0_reg <= e0_val;
                        o_w1_reg <= e1_val;
                        o_w2_reg <= e2_val;
                    end else begin
                        o_valid_reg <= 1'b0;
                    end
                    
                    if (x_curr == s2_max_x) begin
                        if (y_curr == s2_max_y) begin
                            traverse_active <= 0; // finished
                        end else begin
                            x_curr <= s2_min_x;
                            y_curr <= y_curr + 1;
                            e0_row <= e0_row + s2_dx0;
                            e1_row <= e1_row + s2_dx1;
                            e2_row <= e2_row + s2_dx2;
                            e0_val <= e0_row + s2_dx0;
                            e1_val <= e1_row + s2_dx1;
                            e2_val <= e2_row + s2_dx2;
                        end
                    end else begin
                        x_curr <= x_curr + 1;
                        e0_val <= e0_val + s2_dy0;
                        e1_val <= e1_val + s2_dy1;
                        e2_val <= e2_val + s2_dy2;
                    end
                end
            end
        end
    end
endmodule
