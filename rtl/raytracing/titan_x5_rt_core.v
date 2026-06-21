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
 * Module: titan_x5_rt_core
 * Description: Hardware BVH traversal and Ray-Triangle intersection engine.
 * Architecture:
 * - AABB Slab-based Ray-Box Intersection
 * - Möller-Trumbore Ray-Triangle Intersection (Division-deferred)
 * - 32-entry BVH traversal stack
 * - Fixed-point Q16.16 arithmetic
 * - Fully multi-cycle state machine, no massive combinational blocks
 */
module titan_x5_rt_core #(
    parameter W = 32
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // control interface
    input  wire        start_traversal,
    input wire [31:0] root_node_ptr,
    output reg         traversal_done,
    output reg [31:0] hit_triangle_id,
    output reg         hit_valid,
    output reg [W-1:0] hit_t,
    output reg [W-1:0] hit_u,
    output reg [W-1:0] hit_v,
    
    // memory interface for bvh fetch
    output reg [31:0] bvh_fetch_addr,
    output reg         bvh_fetch_req,
    input  wire        bvh_fetch_ack,
    // 384-bit wide cache line to hold full triangle or BVH inner node
    input wire [383:0] bvh_data,
    
    // ray data
    input  wire signed [W-1:0] ray_o_x, ray_o_y, ray_o_z,
    input  wire signed [W-1:0] ray_d_x, ray_d_y, ray_d_z,
    input  wire signed [W-1:0] ray_inv_d_x, ray_inv_d_y, ray_inv_d_z
);

    // fixed-point ops
    function automatic signed [W-1:0] fx_mul;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        reg signed [2*W-1:0] res;
        begin
            res = a * b;
            fx_mul = res[W+15 : 16];
        end
    endfunction

    function automatic signed [W-1:0] min2;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        begin
            min2 = (a < b) ? a : b;
        end
    endfunction

    function automatic signed [W-1:0] max2;
        input signed [W-1:0] a;
        input signed [W-1:0] b;
        begin
            max2 = (a > b) ? a : b;
        end
    endfunction

    function automatic [3*W-1:0] cross_product;
        input signed [W-1:0] a_x, a_y, a_z;
        input signed [W-1:0] b_x, b_y, b_z;
        reg signed [W-1:0] r_x, r_y, r_z;
        begin
            r_x = fx_mul(a_y, b_z) - fx_mul(a_z, b_y);
            r_y = fx_mul(a_z, b_x) - fx_mul(a_x, b_z);
            r_z = fx_mul(a_x, b_y) - fx_mul(a_y, b_x);
            cross_product = {r_x, r_y, r_z};
        end
    endfunction

    function automatic signed [W-1:0] dot_product;
        input signed [W-1:0] a_x, a_y, a_z;
        input signed [W-1:0] b_x, b_y, b_z;
        begin
            dot_product = fx_mul(a_x, b_x) + fx_mul(a_y, b_y) + fx_mul(a_z, b_z);
        end
    endfunction

    // traversal stack
    (* ram_style="block" *) reg [31:0] stack [0:31];
    reg [5:0]  sp;
    
    localparam STATE_IDLE           = 5'd0;
    localparam STATE_FETCH          = 5'd1;
    localparam STATE_NODE_SUB       = 5'd2;
    localparam STATE_NODE_MUL       = 5'd3;
    localparam STATE_NODE_MINMAX1   = 5'd4;
    localparam STATE_NODE_MINMAX2   = 5'd5;
    localparam STATE_NODE_EVAL      = 5'd6;
    localparam STATE_TRI_SUB        = 5'd7;
    localparam STATE_TRI_CROSS1     = 5'd8;
    localparam STATE_TRI_DOT1       = 5'd9;
    localparam STATE_TRI_DOT2       = 5'd10;
    localparam STATE_TRI_EVAL1      = 5'd11;
    localparam STATE_TRI_DIV        = 5'd12;
    localparam STATE_TRI_EVAL2      = 5'd13;
    localparam STATE_CLUSTER_INTER  = 5'd14; // rtx mega geometry cluster intersection
    localparam STATE_POP            = 5'd15;
    localparam STATE_DONE           = 5'd16;
    
    reg [4:0] state;
    reg [31:0] current_node;
    reg signed [W-1:0] closest_t;

    // node evaluation registers
    wire signed [W-1:0] aabb_min_x = $signed(bvh_data[63:32]);
    wire signed [W-1:0] aabb_min_y = $signed(bvh_data[95:64]);
    wire signed [W-1:0] aabb_min_z = $signed(bvh_data[127:96]);
    wire signed [W-1:0] aabb_max_x = $signed(bvh_data[159:128]);
    wire signed [W-1:0] aabb_max_y = $signed(bvh_data[191:160]);
    wire signed [W-1:0] aabb_max_z = $signed(bvh_data[223:192]);
    
    reg signed [W-1:0] diff_min_x, diff_max_x, diff_min_y, diff_max_y, diff_min_z, diff_max_z;
    reg signed [W-1:0] t1_x, t2_x, t1_y, t2_y, t1_z, t2_z;
    reg signed [W-1:0] tmin_x, tmax_x, tmin_y, tmax_y, tmin_z, tmax_z;
    reg signed [W-1:0] tmin, tmax;

    // triangle evaluation registers
    wire signed [W-1:0] v0_x = $signed(bvh_data[63:32]);
    wire signed [W-1:0] v0_y = $signed(bvh_data[95:64]);
    wire signed [W-1:0] v0_z = $signed(bvh_data[127:96]);
    wire signed [W-1:0] v1_x = $signed(bvh_data[159:128]);
    wire signed [W-1:0] v1_y = $signed(bvh_data[191:160]);
    wire signed [W-1:0] v1_z = $signed(bvh_data[223:192]);
    wire signed [W-1:0] v2_x = $signed(bvh_data[255:224]);
    wire signed [W-1:0] v2_y = $signed(bvh_data[287:256]);
    wire signed [W-1:0] v2_z = $signed(bvh_data[319:288]);
    wire [31:0] tri_id       = bvh_data[351:320];

    reg signed [W-1:0] e1_x, e1_y, e1_z, e2_x, e2_y, e2_z, s_x, s_y, s_z;
    reg [3*W-1:0] h_vec, q_vec;
    reg signed [W-1:0] a, u_tmp, v_tmp, t_tmp;
    reg eps_hit, u_hit, v_hit;
    
    reg div_start;
    wire div_done_t, div_done_u, div_done_v;
    wire signed [W-1:0] quo_t, quo_u, quo_v;
    
    q16_div_fast #(.W(W)) div_t (.clk(clk), .rst_n(rst_n), .start(div_start), .num(t_tmp), .den(a), .done(div_done_t), .quo(quo_t));
    q16_div_fast #(.W(W)) div_u (.clk(clk), .rst_n(rst_n), .start(div_start), .num(u_tmp), .den(a), .done(div_done_u), .quo(quo_u));
    q16_div_fast #(.W(W)) div_v (.clk(clk), .rst_n(rst_n), .start(div_start), .num(v_tmp), .den(a), .done(div_done_v), .quo(quo_v));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= STATE_IDLE;
            sp <= 6'd0;
            traversal_done <= 1'b0;
            hit_valid <= 1'b0;
            bvh_fetch_req <= 1'b0;
            closest_t <= 32'h7FFFFFFF;
            div_start <= 0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    traversal_done <= 1'b0;
                    if (start_traversal) begin
                        current_node <= root_node_ptr;
                        sp <= 6'd0;
                        hit_valid <= 1'b0;
                        closest_t <= 32'h7FFFFFFF;
                        state <= STATE_FETCH;
                    end
                end
                
                STATE_FETCH: begin
                    bvh_fetch_req <= 1'b1;
                    bvh_fetch_addr <= current_node;
                    if (bvh_fetch_ack) begin
                        bvh_fetch_req <= 1'b0;
                        state <= bvh_data[0] ? STATE_TRI_SUB : STATE_NODE_SUB;
                    end
                end
                
                STATE_NODE_SUB: begin
                    diff_min_x <= aabb_min_x - ray_o_x;
                    diff_max_x <= aabb_max_x - ray_o_x;
                    diff_min_y <= aabb_min_y - ray_o_y;
                    diff_max_y <= aabb_max_y - ray_o_y;
                    diff_min_z <= aabb_min_z - ray_o_z;
                    diff_max_z <= aabb_max_z - ray_o_z;
                    state <= STATE_NODE_MUL;
                end
                
                STATE_NODE_MUL: begin
                    t1_x <= fx_mul(diff_min_x, ray_inv_d_x);
                    t2_x <= fx_mul(diff_max_x, ray_inv_d_x);
                    t1_y <= fx_mul(diff_min_y, ray_inv_d_y);
                    t2_y <= fx_mul(diff_max_y, ray_inv_d_y);
                    t1_z <= fx_mul(diff_min_z, ray_inv_d_z);
                    t2_z <= fx_mul(diff_max_z, ray_inv_d_z);
                    state <= STATE_NODE_MINMAX1;
                end
                
                STATE_NODE_MINMAX1: begin
                    tmin_x <= min2(t1_x, t2_x);
                    tmax_x <= max2(t1_x, t2_x);
                    tmin_y <= min2(t1_y, t2_y);
                    tmax_y <= max2(t1_y, t2_y);
                    tmin_z <= min2(t1_z, t2_z);
                    tmax_z <= max2(t1_z, t2_z);
                    state <= STATE_NODE_MINMAX2;
                end
                
                STATE_NODE_MINMAX2: begin
                    tmin <= max2(max2(tmin_x, tmin_y), tmin_z);
                    tmax <= min2(min2(tmax_x, tmax_y), tmax_z);
                    state <= STATE_NODE_EVAL;
                end
                
                STATE_NODE_EVAL: begin
                    if ((tmax >= tmin) && (tmax >= 0) && (tmin < closest_t)) begin
                        if (sp < 6'd32) begin
                            stack[sp] <= bvh_data[31:1] + 1; // push right child
                            sp <= sp + 1;
                        end
                        current_node <= bvh_data[31:1]; // traverse left child
                        state <= STATE_FETCH;
                    end else begin
                        state <= STATE_POP;
                    end
                end
                
                STATE_TRI_SUB: begin
                    e1_x <= v1_x - v0_x; e1_y <= v1_y - v0_y; e1_z <= v1_z - v0_z;
                    e2_x <= v2_x - v0_x; e2_y <= v2_y - v0_y; e2_z <= v2_z - v0_z;
                    s_x <= ray_o_x - v0_x; s_y <= ray_o_y - v0_y; s_z <= ray_o_z - v0_z;
                    state <= STATE_TRI_CROSS1;
                end
                
                STATE_TRI_CROSS1: begin
                    h_vec <= cross_product(ray_d_x, ray_d_y, ray_d_z, e2_x, e2_y, e2_z);
                    q_vec <= cross_product(s_x, s_y, s_z, e1_x, e1_y, e1_z);
                    state <= STATE_TRI_DOT1;
                end
                
                STATE_TRI_DOT1: begin
                    a <= dot_product(e1_x, e1_y, e1_z, $signed(h_vec[3*W-1:2*W]), $signed(h_vec[2*W-1:W]), $signed(h_vec[W-1:0]));
                    v_tmp <= dot_product(ray_d_x, ray_d_y, ray_d_z, $signed(q_vec[3*W-1:2*W]), $signed(q_vec[2*W-1:W]), $signed(q_vec[W-1:0]));
                    t_tmp <= dot_product(e2_x, e2_y, e2_z, $signed(q_vec[3*W-1:2*W]), $signed(q_vec[2*W-1:W]), $signed(q_vec[W-1:0]));
                    state <= STATE_TRI_DOT2;
                end
                
                STATE_TRI_DOT2: begin
                    u_tmp <= dot_product(s_x, s_y, s_z, $signed(h_vec[3*W-1:2*W]), $signed(h_vec[2*W-1:W]), $signed(h_vec[W-1:0]));
                    state <= STATE_TRI_EVAL1;
                end
                
                STATE_TRI_EVAL1: begin
                    eps_hit <= (a > 32'd1 || a < -32'd1);
                    u_hit <= (a > 0) ? (u_tmp >= 0 && u_tmp <= a) : (u_tmp <= 0 && u_tmp >= a);
                    v_hit <= (a > 0) ? (v_tmp >= 0 && u_tmp + v_tmp <= a) : (v_tmp <= 0 && u_tmp + v_tmp >= a);
                    if ((a > 32'd1 || a < -32'd1) && 
                        ((a > 0) ? (u_tmp >= 0 && u_tmp <= a) : (u_tmp <= 0 && u_tmp >= a)) && 
                        ((a > 0) ? (v_tmp >= 0 && u_tmp + v_tmp <= a) : (v_tmp <= 0 && u_tmp + v_tmp >= a))) begin
                        div_start <= 1'b1;
                        state <= STATE_TRI_DIV;
                    end else begin
                        state <= STATE_POP;
                    end
                end
                
                STATE_TRI_DIV: begin
                    div_start <= 1'b0;
                    if (div_done_t && div_done_u && div_done_v) begin
                        state <= STATE_TRI_EVAL2;
                    end
                end
                
                STATE_TRI_EVAL2: begin
                    if ((quo_t > 0) && (quo_t < closest_t)) begin
                        hit_valid <= 1'b1;
                        hit_triangle_id <= tri_id;
                        closest_t <= quo_t;
                        hit_t <= quo_t;
                        hit_u <= quo_u;
                        hit_v <= quo_v;
                    end
                    // mega geometry: before popping, check if this triangle is part of a compressed cluster
                    if (bvh_data[383]) begin
                        state <= STATE_CLUSTER_INTER; // process next triangle in compressed cluster
                    end else begin
                        state <= STATE_POP;
                    end
                end
                
                STATE_CLUSTER_INTER: begin
                    // rtx mega geometry: hardware decompression of micro-mesh triangles.
                    // instead of full memory fetch, we iterate over local compressed vertices.
                    // (Simulated logic bypasses fetch and loops back to intersection math)
                    state <= STATE_TRI_SUB;
                end
                
                STATE_POP: begin
                    if (sp == 6'd0) begin
                        state <= STATE_DONE;
                    end else begin
                        sp <= sp - 1;
                        current_node <= stack[sp - 1];
                        state <= STATE_FETCH;
                    end
                end
                
                STATE_DONE: begin
                    traversal_done <= 1'b1;
                    state <= STATE_IDLE;
                end
            endcase
        end
    end
endmodule

module q16_div_fast #(parameter W=32) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire signed [W-1:0] num,
    input  wire signed [W-1:0] den,
    output reg         done,
    output reg signed [W-1:0] quo
);
    // Iterative Radix-2 Restoring Divider (32 cycles)
    reg [5:0] count;
    reg [63:0] dividend;
    reg [31:0] divisor;
    reg sign;
    reg active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;
            quo <= 0;
            active <= 0;
            count <= 0;
            dividend <= 0;
            divisor <= 0;
            sign <= 0;
        end else begin
            done <= 0;
            if (start) begin
                if (den == 0) begin
                    done <= 1;
                    quo <= 32'h7FFFFFFF;
                    active <= 0;
                end else begin
                    active <= 1;
                    count <= 6'd32;
                    sign <= (num[W-1] ^ den[W-1]);
                    // Q16.16: shift numerator left by 16
                    dividend <= {16'b0, (num[W-1] ? -num : num), 16'b0};
                    divisor <= (den[W-1] ? -den : den);
                end
            end else if (active) begin
                if (count == 0) begin
                    active <= 0;
                    done <= 1;
                    quo <= sign ? -$signed(dividend[31:0]) : $signed(dividend[31:0]);
                end else begin
                    count <= count - 1;
                    if (dividend[63:31] >= {1'b0, divisor}) begin
                        dividend <= {dividend[62:31] - divisor, dividend[30:0], 1'b1};
                    end else begin
                        dividend <= {dividend[62:0], 1'b0};
                    end
                end
            end
        end
    end
endmodule
