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
 * Titan X6 tensor core array - output-stationary systolic matmul.
 *
 * Rebuilt from the acc-forwarding prototype (which could only reduce one
 * k-term per partial-sum token, i.e. was not a true matrix multiply).
 *
 * Dataflow: activations (A rows) stream left-to-right, weights (B columns)
 * stream top-to-bottom, both with the classic diagonal skew (built into
 * this module); every PE keeps a local accumulator and computes
 *   C[i][j] += A[i][k] * B[k][j]
 * for one k per cycle. After the pipeline flushes, `drain` shifts the
 * accumulators down each column, one row per cycle (bottom row first
 * visible on acc_out even before the first drain cycle).
 *
 * PE is two-stage: S1 registers the raw product (one multiplier level),
 * S2 folds it into the accumulator - so the multiply and the accumulate
 * are separate timing paths.
 *
 * Modes (mode[1:0], fp8_fmt):
 *   0        FP16 x FP16 -> FP32 accumulate (IEEE RNE multiply)
 *   1, fmt 0 FP8 E4M3 x E4M3 -> FP32 accumulate (native, exact products,
 *            denormals supported, NaN encodings flushed to zero)
 *   1, fmt 1 FP8 E5M2 x E5M2 -> FP32 accumulate (native; Inf/NaN flushed)
 *   2        FP4 E2M1 SIMD (4 products per 16-bit lane, legacy path)
 *   3        INT8 SIMD: each 16-bit lane carries two signed int8 values,
 *            2 MACs/PE/cycle into an INT32 accumulator
 *            (a 16x16 array = 512 INT8 MACs per clock)
 *
 * The FP32 accumulator adder is the compact truncating flush-to-zero
 * adder below (not the IEEE cores in rtl/fpu) - documented, and mirrored
 * bit-exactly by the verification golden model.
 */

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

/*
 * Native FP8 multiplier -> FP32 (exact).
 * fmt 0: E4M3 (bias 7,  3-bit mantissa, e=15&m=7 is NaN -> flushed to 0)
 * fmt 1: E5M2 (bias 15, 2-bit mantissa, e=31 is Inf/NaN -> flushed to 0)
 * Denormal inputs are handled exactly (0.m x 2^(1-bias)).
 * Every representable product fits exactly in FP32 (<= 8 significant bits).
 */
module fp8_mul_to_fp32 (
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire        fmt,
    output wire [31:0] result
);
    wire sign = a[7] ^ b[7];

    // field extraction per format
    wire [4:0] ea = fmt ? {a[6:2]}       : {1'b0, a[6:3]};
    wire [4:0] eb = fmt ? {b[6:2]}       : {1'b0, b[6:3]};
    wire [2:0] fa = fmt ? {a[1:0], 1'b0} : a[2:0];   // align to 3 fraction bits
    wire [2:0] fb = fmt ? {b[1:0], 1'b0} : b[2:0];

    wire a_denorm = (ea == 5'd0);
    wire b_denorm = (eb == 5'd0);
    wire a_zero = a_denorm && (fa == 3'd0);
    wire b_zero = b_denorm && (fb == 3'd0);
    // non-finite encodings flushed to zero: E4M3 NaN (e=15,m=7), E5M2 e=31
    wire a_nonfin = fmt ? (ea == 5'd31) : (a[6:3] == 4'd15 && a[2:0] == 3'd7);
    wire b_nonfin = fmt ? (eb == 5'd31) : (b[6:3] == 4'd15 && b[2:0] == 3'd7);
    wire flush = a_zero || b_zero || a_nonfin || b_nonfin;

    // 1.3-format mantissas (denormals keep leading 0)
    wire [3:0] ma = {!a_denorm, fa};
    wire [3:0] mb = {!b_denorm, fb};
    wire [7:0] prod = ma * mb;   // fraction-of-64, in [1, 225]

    // effective unbiased exponents
    wire [4:0]        bias    = fmt ? 5'd15 : 5'd7;
    wire signed [7:0] ea_eff  = (a_denorm ? 8'sd1 : {3'b0, ea}) - {3'b0, bias};
    wire signed [7:0] eb_eff  = (b_denorm ? 8'sd1 : {3'b0, eb}) - {3'b0, bias};
    wire signed [7:0] exp_sum = ea_eff + eb_eff;

    // normalize the 8-bit product: MSB position p -> value = prod * 2^(sum-6)
    reg [2:0] p;
    integer i;
    always @(*) begin
        p = 3'd0;
        for (i = 0; i <= 7; i = i + 1)
            if (prod[i]) p = i[2:0];
    end

    wire [30:0] mant_sh = {23'b0, prod} << (5'd23 - {2'b0, p});
    wire signed [8:0] exp32 = exp_sum - 8'sd6 + {6'b0, p} + 9'sd127;

    assign result = (flush || prod == 8'd0) ? {sign, 31'b0}
                  : {sign, exp32[7:0], mant_sh[22:0]};
endmodule

// compact truncating FP32 adder (flush-to-zero, no NaN/Inf handling);
// mirrored exactly by tb/uvm/tensor_ref.py
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

/*
 * Output-stationary processing element, two pipeline stages:
 *   S1: raw product registered (multiplier timing path)
 *   S2: accumulate / drain-shift (adder timing path)
 */
module mac_pe #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 32
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   en,         // stream enable (products)
    input  wire [1:0]             mode,       // 0 FP16, 1 FP8, 2 FP4, 3 INT8
    input  wire                   fp8_fmt,    // 0 E4M3, 1 E5M2
    input  wire                   acc_clear,  // sync clear of accumulator
    input  wire                   drain,      // shift accumulators down

    input  wire [DATA_WIDTH-1:0]  act_in,
    input  wire [DATA_WIDTH-1:0]  weight_in,
    input  wire [ACC_WIDTH-1:0]   drain_in,   // accumulator of the PE above

    output reg  [DATA_WIDTH-1:0]  act_out,
    output reg  [DATA_WIDTH-1:0]  weight_out,
    output reg  [ACC_WIDTH-1:0]   acc
);

    // ---- product generation (combinational) ----
    // FP16 path (IEEE RNE multiply, exact widening to FP32)
    wire [15:0] fp16_prod;
    titan_x5_fp16_mul mul_inst (
        .a(act_in), .b(weight_in), .result(fp16_prod)
    );
    wire [31:0] fp16_prod32 = (fp16_prod[14:0] == 15'b0) ? {fp16_prod[15], 31'b0} :
                              (fp16_prod[14:10] == 5'b0) ? 32'b0 :  // f16 denorm: flush
                              {fp16_prod[15], fp16_prod[14:10] + 8'd127 - 8'd15,
                               fp16_prod[9:0], 13'b0};

    // native FP8 path
    wire [31:0] fp8_prod32;
    fp8_mul_to_fp32 fp8_m (
        .a(act_in[7:0]), .b(weight_in[7:0]), .fmt(fp8_fmt),
        .result(fp8_prod32)
    );

    // FP4 SIMD path (legacy, 4 products per lane)
    wire [31:0] fp4_prod0, fp4_prod1, fp4_prod2, fp4_prod3;
    fp4_mul_to_fp32 fp4_m0(.a(act_in[3:0]),   .b(weight_in[3:0]),   .result(fp4_prod0));
    fp4_mul_to_fp32 fp4_m1(.a(act_in[7:4]),   .b(weight_in[7:4]),   .result(fp4_prod1));
    fp4_mul_to_fp32 fp4_m2(.a(act_in[11:8]),  .b(weight_in[11:8]),  .result(fp4_prod2));
    fp4_mul_to_fp32 fp4_m3(.a(act_in[15:12]), .b(weight_in[15:12]), .result(fp4_prod3));
    wire [31:0] fp4_sum01, fp4_sum23, fp4_sum_all;
    fp32_add add_01(.a(fp4_prod0), .b(fp4_prod1), .result(fp4_sum01));
    fp32_add add_23(.a(fp4_prod2), .b(fp4_prod3), .result(fp4_sum23));
    fp32_add add_all(.a(fp4_sum01), .b(fp4_sum23), .result(fp4_sum_all));

    // INT8 SIMD path: two signed 8x8 products per lane
    wire signed [15:0] i8_p0 = $signed(act_in[7:0])  * $signed(weight_in[7:0]);
    wire signed [15:0] i8_p1 = $signed(act_in[15:8]) * $signed(weight_in[15:8]);
    wire signed [31:0] i8_pair = i8_p0 + i8_p1;

    wire [31:0] prod_mux = (mode == 2'd0) ? fp16_prod32 :
                           (mode == 2'd1) ? fp8_prod32  :
                           (mode == 2'd2) ? fp4_sum_all :
                                            i8_pair;

    // ---- stage 1: product register ----
    reg [31:0] p_reg;
    reg        pv_reg;
    reg [1:0]  mode_r;

    // ---- stage 2: accumulate (fp or int) ----
    wire [31:0] fp_acc_next;
    fp32_add add_acc(.a(acc), .b(p_reg), .result(fp_acc_next));
    wire [31:0] int_acc_next = acc + p_reg;
    wire [31:0] acc_next = (mode_r == 2'd3) ? int_acc_next : fp_acc_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_out    <= {DATA_WIDTH{1'b0}};
            weight_out <= {DATA_WIDTH{1'b0}};
            p_reg      <= 32'b0;
            pv_reg     <= 1'b0;
            mode_r     <= 2'b0;
            acc        <= {ACC_WIDTH{1'b0}};
        end else begin
            // S1: operand movement + product capture
            if (en) begin
                act_out    <= act_in;
                weight_out <= weight_in;
                p_reg      <= prod_mux;
                mode_r     <= mode;
            end
            pv_reg <= en;

            // S2: accumulator
            if (acc_clear)
                acc <= {ACC_WIDTH{1'b0}};
            else if (drain)
                acc <= drain_in;
            else if (pv_reg)
                acc <= acc_next;
        end
    end

endmodule

/*
 * The systolic array. Diagonal input skew is internal (row i's activation
 * is delayed i cycles, column j's weight j cycles). Feed A[i][k] on
 * act_in row i and B[k][j] on weight_in column j at cycle k, hold en
 * until the skew flushes (K + X + Y extra cycles of zero feed), then
 * pulse drain Y-1 times while capturing acc_out (row Y-1 appears first,
 * before the first drain pulse).
 */
module titan_x6_tensor_core_array #(
    parameter ARRAY_SIZE_X = 4,
    parameter ARRAY_SIZE_Y = 4,
    parameter DATA_WIDTH   = 16,
    parameter ACC_WIDTH    = 32
)(
    input  wire                                     clk,
    input  wire                                     rst_n,
    input  wire                                     en,
    input  wire [1:0]                               mode,     // see header
    input  wire                                     fp8_fmt,  // 0 E4M3, 1 E5M2
    input  wire                                     acc_clear,
    input  wire                                     drain,

    // activation inputs (fed from left side of array, per row)
    input wire [(ARRAY_SIZE_Y * DATA_WIDTH)-1:0] act_in,

    // weight inputs (fed from top side of array, per column)
    input wire [(ARRAY_SIZE_X * DATA_WIDTH)-1:0] weight_in,

    // accumulators of the bottom PE row (drain shifts rows down)
    output wire [(ARRAY_SIZE_X * ACC_WIDTH)-1:0] acc_out,
    output reg                                      out_valid
);

    wire [DATA_WIDTH-1:0] act_wire   [0 : ARRAY_SIZE_Y * (ARRAY_SIZE_X + 1) - 1];
    wire [DATA_WIDTH-1:0] weight_wire[0 : (ARRAY_SIZE_Y + 1) * ARRAY_SIZE_X - 1];
    wire [ACC_WIDTH-1:0]  acc_chain  [0 : (ARRAY_SIZE_Y + 1) * ARRAY_SIZE_X - 1];

    genvar i, j;
    generate
        // row inputs (activations) with systolic skew (delay row i by i cycles)
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

        // column inputs (weights) with systolic skew (delay col j by j cycles)
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
            // drain chain entry at the top of each column
            assign acc_chain[0 * ARRAY_SIZE_X + j] = {ACC_WIDTH{1'b0}};
        end

        // PE grid (output stationary; acc_chain is the drain path)
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
                    .fp8_fmt   (fp8_fmt),
                    .acc_clear (acc_clear),
                    .drain     (drain),
                    .act_in    (act_wire   [i * (ARRAY_SIZE_X + 1) + j]),
                    .weight_in (weight_wire[i * ARRAY_SIZE_X + j]),
                    .drain_in  (acc_chain  [i * ARRAY_SIZE_X + j]),
                    .act_out   (act_wire   [i * (ARRAY_SIZE_X + 1) + j + 1]),
                    .weight_out(weight_wire[(i + 1) * ARRAY_SIZE_X + j]),
                    .acc       (acc_chain  [(i + 1) * ARRAY_SIZE_X + j])
                );
            end
        end

        for (j = 0; j < ARRAY_SIZE_X; j = j + 1) begin : g_acc_out
            assign acc_out[j * ACC_WIDTH +: ACC_WIDTH] = acc_chain[ARRAY_SIZE_Y * ARRAY_SIZE_X + j];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) out_valid <= 1'b0;
        else        out_valid <= drain;
    end

endmodule
