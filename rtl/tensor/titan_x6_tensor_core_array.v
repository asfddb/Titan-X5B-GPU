// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps

// fp4 (e2m1) multiplier that outputs fp32
module fp4_mul_to_fp32 (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [31:0] result
);
    wire a_zero = (a[2:0] == 3'b000);
    wire b_zero = (b[2:0] == 3'b000);
    wire sign = a[3] ^ b[3];

    wire [1:0] ma = a_zero ? 2'b00 : {1'b1, a[0]};
    wire [1:0] mb = b_zero ? 2'b00 : {1'b1, b[0]};
    wire [3:0] m_prod = ma * mb; 

    reg [7:0] res_exp;
    reg [22:0] res_mant;

    always @(*) begin
        res_exp = 0;
        res_mant = 0;
        if (a_zero || b_zero) begin
            res_exp = 0;
            res_mant = 0;
        end else begin
            res_exp = ({6'b0, a[2:1]} + {6'b0, b[2:1]}) + 8'd127 - 8'd2;
            if (m_prod[3]) begin
                res_exp = res_exp + 1;
                res_mant = {m_prod[2:0], 20'b0};
            end else begin
                res_mant = {m_prod[1:0], 21'b0};
            end
        end
    end
    assign result = {sign, res_exp, res_mant};
endmodule

// processing element (pe) for matrix multiply-accumulate
module mac_pe #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   en,
    input wire [1:0] mode, // 0: FP16, 1: FP8, 2: NVFP4 (E2M1)
    
    input wire [DATA_WIDTH-1:0] act_in,
    input wire [DATA_WIDTH-1:0] weight_in,
    input wire [ACC_WIDTH-1:0] acc_in,
    
    output reg [DATA_WIDTH-1:0] act_out,
    output reg [DATA_WIDTH-1:0] weight_out,
    output reg [ACC_WIDTH-1:0] acc_out
);

    // fp8 to fp16 conversion (e4m3)
    wire [15:0] fp8_act_fp16 = {act_in[7], act_in[6:3] + 5'd15 - 5'd7, act_in[2:0], 7'b0};
    wire [15:0] fp8_weight_fp16 = {weight_in[7], weight_in[6:3] + 5'd15 - 5'd7, weight_in[2:0], 7'b0};

    // standard fp16/fp8 path
    wire [15:0] act_fp16 = (mode == 1) ? fp8_act_fp16 : act_in;
    wire [15:0] weight_fp16 = (mode == 1) ? fp8_weight_fp16 : weight_in;

    wire [15:0] fp16_prod;
    titan_x5_fp16_mul mul_inst (
        .a(act_fp16),
        .b(weight_fp16),
        .result(fp16_prod)
    );

    wire [31:0] fp32_prod_standard = (fp16_prod == 16'b0) ? 32'b0 : 
                            {fp16_prod[15], fp16_prod[14:10] + 8'd127 - 8'd15, fp16_prod[9:0], 13'b0};

    // dynamic simd fp4 path (4x throughput)
    wire [31:0] fp4_prod0, fp4_prod1, fp4_prod2, fp4_prod3;
    
    fp4_mul_to_fp32 fp4_m0(.a(act_in[3:0]),   .b(weight_in[3:0]),   .result(fp4_prod0));
    fp4_mul_to_fp32 fp4_m1(.a(act_in[7:4]),   .b(weight_in[7:4]),   .result(fp4_prod1));
    fp4_mul_to_fp32 fp4_m2(.a(act_in[11:8]),  .b(weight_in[11:8]),  .result(fp4_prod2));
    fp4_mul_to_fp32 fp4_m3(.a(act_in[15:12]), .b(weight_in[15:12]), .result(fp4_prod3));

    // adder tree for fp4
    wire [31:0] fp4_sum01, fp4_sum23, fp4_sum_all;
    fp32_add add_01(.a(fp4_prod0), .b(fp4_prod1), .result(fp4_sum01));
    fp32_add add_23(.a(fp4_prod2), .b(fp4_prod3), .result(fp4_sum23));
    fp32_add add_all(.a(fp4_sum01), .b(fp4_sum23), .result(fp4_sum_all));

    // final mux and accumulation
    wire [31:0] active_prod = (mode == 2) ? fp4_sum_all : fp32_prod_standard;
    
    wire [31:0] next_acc;
    fp32_add add_acc(.a(acc_in), .b(active_prod), .result(next_acc));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_out    <= {DATA_WIDTH{1'b0}};
            weight_out <= {DATA_WIDTH{1'b0}};
            acc_out    <= {ACC_WIDTH{1'b0}};
        end else if (en) begin
            act_out    <= act_in;
            weight_out <= weight_in;
            acc_out    <= next_acc;
        end
    end

endmodule

module fp32_add (
    input wire [31:0] a,
    input wire [31:0] b,
    output reg [31:0] result
);
    wire sign_a = a[31];
    wire [7:0] exp_a = a[30:23];
    wire [23:0] mant_a = (exp_a == 0) ? 24'b0 : {1'b1, a[22:0]};
    
    wire sign_b = b[31];
    wire [7:0] exp_b = b[30:23];
    wire [23:0] mant_b = (exp_b == 0) ? 24'b0 : {1'b1, b[22:0]};
    
    reg [7:0] exp_diff;
    reg [23:0] mant_a_aligned;
    reg [23:0] mant_b_aligned;
    reg [7:0] exp_res;
    reg sign_res;
    reg [24:0] mant_sum;
    reg [4:0] shift;
    
    always @(*) begin
        result = 32'b0;
        exp_diff = 8'b0;
        mant_a_aligned = 24'b0;
        mant_b_aligned = 24'b0;
        exp_res = 8'b0;
        sign_res = 1'b0;
        mant_sum = 25'b0;
        shift = 5'b0;
        
        if (a == 0) result = b;
        else if (b == 0) result = a;
        else begin
            if (exp_a > exp_b) begin
                exp_diff = exp_a - exp_b;
                mant_a_aligned = mant_a;
                mant_b_aligned = mant_b >> exp_diff;
                exp_res = exp_a;
                sign_res = sign_a;
            end else begin
                exp_diff = exp_b - exp_a;
                mant_a_aligned = mant_a >> exp_diff;
                mant_b_aligned = mant_b;
                exp_res = exp_b;
                sign_res = sign_b;
            end
            
            if (sign_a == sign_b) begin
                mant_sum = mant_a_aligned + mant_b_aligned;
                if (mant_sum[24]) begin
                    mant_sum = mant_sum >> 1;
                    exp_res = exp_res + 1;
                end
                result = {sign_res, exp_res, mant_sum[22:0]};
            end else begin
                if (mant_a_aligned > mant_b_aligned) begin
                    mant_sum = mant_a_aligned - mant_b_aligned;
                    sign_res = sign_a;
                end else if (mant_b_aligned > mant_a_aligned) begin
                    mant_sum = mant_b_aligned - mant_a_aligned;
                    sign_res = sign_b;
                end else begin
                    mant_sum = 0;
                    sign_res = 0;
                end
                
                if (mant_sum == 0) begin
                    result = 32'b0;
                end else begin
                    if (mant_sum[23]) shift = 0;
                    else if (mant_sum[22]) shift = 1;
                    else if (mant_sum[21]) shift = 2;
                    else if (mant_sum[20]) shift = 3;
                    else if (mant_sum[19]) shift = 4;
                    else if (mant_sum[18]) shift = 5;
                    else if (mant_sum[17]) shift = 6;
                    else if (mant_sum[16]) shift = 7;
                    else if (mant_sum[15]) shift = 8;
                    else if (mant_sum[14]) shift = 9;
                    else if (mant_sum[13]) shift = 10;
                    else if (mant_sum[12]) shift = 11;
                    else if (mant_sum[11]) shift = 12;
                    else if (mant_sum[10]) shift = 13;
                    else if (mant_sum[9]) shift = 14;
                    else if (mant_sum[8]) shift = 15;
                    else if (mant_sum[7]) shift = 16;
                    else if (mant_sum[6]) shift = 17;
                    else if (mant_sum[5]) shift = 18;
                    else if (mant_sum[4]) shift = 19;
                    else if (mant_sum[3]) shift = 20;
                    else if (mant_sum[2]) shift = 21;
                    else if (mant_sum[1]) shift = 22;
                    else shift = 23;

                    mant_sum = mant_sum << shift;
                    exp_res = exp_res - shift;
                    result = {sign_res, exp_res, mant_sum[22:0]};
                end
            end
        end
    end
endmodule

// massive systolic array
module titan_x6_tensor_core_array #(
    parameter ARRAY_SIZE_X = 4,
    parameter ARRAY_SIZE_Y = 4,
    parameter DATA_WIDTH   = 16,
    parameter ACC_WIDTH    = 32
)(
    input  wire                                     clk,
    input  wire                                     rst_n,
    input  wire                                     en,
    input wire [1:0] mode, // 0: FP16, 1: FP8, 2: NVFP4
    
    // activation inputs (fed from left side of array, per row)
    input wire [(ARRAY_SIZE_Y * DATA_WIDTH)-1:0] act_in,
    
    // weight inputs (fed from top side of array, per column)
    input wire [(ARRAY_SIZE_X * DATA_WIDTH)-1:0] weight_in,
    
    // output accumulation (emerging from bottom side of array, per column)
    output wire [(ARRAY_SIZE_X * ACC_WIDTH)-1:0] acc_out,
    output wire                                     out_valid
);

    // flattened wire arrays for pe interconnections
    wire [DATA_WIDTH-1:0] act_wire   [0 : ARRAY_SIZE_Y * (ARRAY_SIZE_X + 1) - 1];
    wire [DATA_WIDTH-1:0] weight_wire[0 : (ARRAY_SIZE_Y + 1) * ARRAY_SIZE_X - 1];
    wire [ACC_WIDTH-1:0]  acc_wire   [0 : (ARRAY_SIZE_Y + 1) * ARRAY_SIZE_X - 1];

    genvar i, j;
    generate
        for (i = 0; i < ARRAY_SIZE_Y; i = i + 1) begin : g_act_init
            if (i == 0) begin
                assign act_wire[i * (ARRAY_SIZE_X + 1) + 0] = act_in[i * DATA_WIDTH +: DATA_WIDTH];
            end else begin
                reg [DATA_WIDTH-1:0] act_skew_reg [0:i-1];
                integer k;
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        for (k = 0; k < i; k = k + 1)
                            act_skew_reg[k] <= 0;
                    end else if (en) begin
                        act_skew_reg[0] <= act_in[i * DATA_WIDTH +: DATA_WIDTH];
                        for (k = 1; k < i; k = k + 1)
                            act_skew_reg[k] <= act_skew_reg[k-1];
                    end
                end
                assign act_wire[i * (ARRAY_SIZE_X + 1) + 0] = act_skew_reg[i-1];
            end
        end

        // initialize column inputs (weights) with systolic skew (delay col j by j cycles)
        for (j = 0; j < ARRAY_SIZE_X; j = j + 1) begin : g_weight_init
            if (j == 0) begin
                assign weight_wire[0 * ARRAY_SIZE_X + j] = weight_in[j * DATA_WIDTH +: DATA_WIDTH];
            end else begin
                reg [DATA_WIDTH-1:0] weight_skew_reg [0:j-1];
                integer k;
                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        for (k = 0; k < j; k = k + 1)
                            weight_skew_reg[k] <= 0;
                    end else if (en) begin
                        weight_skew_reg[0] <= weight_in[j * DATA_WIDTH +: DATA_WIDTH];
                        for (k = 1; k < j; k = k + 1)
                            weight_skew_reg[k] <= weight_skew_reg[k-1];
                    end
                end
                assign weight_wire[0 * ARRAY_SIZE_X + j] = weight_skew_reg[j-1];
            end
            assign acc_wire[0 * ARRAY_SIZE_X + j]    = {ACC_WIDTH{1'b0}};
        end

        // instantiate the 2d grid of pes
        for (i = 0; i < ARRAY_SIZE_Y; i = i + 1) begin : g_row
            for (j = 0; j < ARRAY_SIZE_X; j = j + 1) begin : g_col
                mac_pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH(ACC_WIDTH)
                ) u_pe (
                    .clk       (clk),
                    .rst_n     (rst_n),
                    .en        (en),
                    .mode      (mode),
                    // inputs from top/left
                    .act_in    (act_wire   [i * (ARRAY_SIZE_X + 1) + j]),
                    .weight_in (weight_wire[i * ARRAY_SIZE_X + j]),
                    .acc_in    (acc_wire   [i * ARRAY_SIZE_X + j]),
                    // outputs to bottom/right
                    .act_out   (act_wire   [i * (ARRAY_SIZE_X + 1) + j + 1]),
                    .weight_out(weight_wire[(i + 1) * ARRAY_SIZE_X + j]),
                    .acc_out   (acc_wire   [(i + 1) * ARRAY_SIZE_X + j])
                );
            end
        end

        // assign output accumulators (bottom of the array)
        for (j = 0; j < ARRAY_SIZE_X; j = j + 1) begin : g_acc_out
            assign acc_out[j * ACC_WIDTH +: ACC_WIDTH] = acc_wire[ARRAY_SIZE_Y * ARRAY_SIZE_X + j];
        end
    endgenerate

    reg [ARRAY_SIZE_Y-1:0] valid_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_pipe <= {ARRAY_SIZE_Y{1'b0}};
        end else begin
            valid_pipe <= {valid_pipe[ARRAY_SIZE_Y-2:0], en};
        end
    end
    
    assign out_valid = valid_pipe[ARRAY_SIZE_Y-1];

endmodule
