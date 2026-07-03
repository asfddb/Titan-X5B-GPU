// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
/*
 * Module: titan_x5_fp16_mul
 * Description: IEEE 754 Half-Precision Floating Point Multiplier.
 * Combines sign, adds exponents, and multiplies mantissas.
 */
module titan_x5_fp16_mul (
    input wire [15:0] a,
    input wire [15:0] b,
    output reg [15:0] result
);

    wire sign_a = a[15];
    wire [4:0] exp_a = a[14:10];
    wire [9:0] frac_a = a[9:0];

    wire sign_b = b[15];
    wire [4:0] exp_b = b[14:10];
    wire [9:0] frac_b = b[9:0];

    wire sign_res = sign_a ^ sign_b;

    wire is_zero_a = (exp_a == 5'b00000 && frac_a == 10'b0);
    wire is_zero_b = (exp_b == 5'b00000 && frac_b == 10'b0);
    wire is_inf_a  = (exp_a == 5'b11111 && frac_a == 10'b0);
    wire is_inf_b  = (exp_b == 5'b11111 && frac_b == 10'b0);
    wire is_nan_a  = (exp_a == 5'b11111 && frac_a != 10'b0);
    wire is_nan_b  = (exp_b == 5'b11111 && frac_b != 10'b0);

    // add hidden bit
    wire [10:0] mant_a = (exp_a == 5'b00000) ? {1'b0, frac_a} : {1'b1, frac_a};
    wire [10:0] mant_b = (exp_b == 5'b00000) ? {1'b0, frac_b} : {1'b1, frac_b};

    // multiply mantissas
    wire [21:0] mant_res_full = mant_a * mant_b;
    
    reg [5:0] exp_res_temp;
    reg [9:0] frac_res_temp;

    always @(*) begin
        result = 16'b0;
        exp_res_temp = 6'b0;
        frac_res_temp = 10'b0;
        
        if (is_nan_a || is_nan_b) begin
            result = 16'h7E00; // nan
        end else if ((is_inf_a && is_zero_b) || (is_zero_a && is_inf_b)) begin
            result = 16'h7E00; // nan
        end else if (is_inf_a || is_inf_b) begin
            result = {sign_res, 5'b11111, 10'b0}; // inf
        end else if (is_zero_a || is_zero_b) begin
            result = {sign_res, 15'b0}; // zero
        end else begin
            // normalization
            exp_res_temp = exp_a + exp_b - 5'd15;
            
            if (mant_res_full[21]) begin
                frac_res_temp = mant_res_full[20:11]; // simplified rounding
                exp_res_temp = exp_res_temp + 1;
            end else begin
                frac_res_temp = mant_res_full[19:10];
            end
            
            // check overflow/underflow
            if (exp_res_temp >= 6'd31) begin
                result = {sign_res, 5'b11111, 10'b0}; // overflow to inf
            end else if (exp_res_temp <= 6'd0 || exp_res_temp[5]) begin
                result = {sign_res, 15'b0}; // underflow to zero (ignoring denormals for simplicity)
            end else begin
                result = {sign_res, exp_res_temp[4:0], frac_res_temp};
            end
        end
    end

endmodule
