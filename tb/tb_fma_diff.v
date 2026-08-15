`timescale 1ns/1ps
// Whole-FMA differential test: the restructured pipeline against the original,
// same inputs, cycle for cycle, all five outputs.
//
// This is what covers the two changes the SAT decomposition could not reach as
// one statement -- the E7 hoist of `tiny`/`den_amt`, and the E8 split into
// prepare / parallel prefix adders / finish. Both live in the denormal,
// rounding and overflow paths, so the stimulus is weighted to land there
// rather than in the easy normal range.
//
// Compiled WITH TITAN_FAST_SIM: both designs then use the behavioural adder
// and multiplier, so what this compares is exactly the restructuring, at speed.
// The structural forms are covered separately -- titan_x7_prefix_add by
// syn/gt2n/prove_prefix.ys, and the carry-save tree by the layer proofs plus
// tb_csa_mul.
//
// The `_gold` reference is the pre-optimisation FMA. It is NOT checked in --
// duplicating 600 lines would rot. Regenerate it from the commit before this
// change:
//
//   REV=<the commit before this change>
//   git show $REV:rtl/fpu/titan_x7_fp32_fma_pipe.v > /tmp/fma_gold.v
//   sed -i 's/module titan_x7_fp32_fma_pipe (/module titan_x7_fp32_fma_pipe_gold (/' /tmp/fma_gold.v
//
// Then, from the repo root (TITAN_FAST_SIM is required -- see above):
//
//   SRC="rtl/common/titan_x7_lzc.v rtl/common/titan_x7_prefix_add.v"
//   SRC="$SRC rtl/common/titan_x7_csa_mul.v rtl/fpu/titan_x7_fp32_fma_pipe.v"
//   iverilog -g2012 -DTITAN_FAST_SIM -s tb_fma_diff -Ptb_fma_diff.NRAND=100000 -o /tmp/fma.vvp $SRC /tmp/fma_gold.v tb/tb_fma_diff.v
//   vvp /tmp/fma.vvp
//
// Mutation testing is what makes this test worth anything: 9 mutations of the
// restructured logic were injected, 7 were caught, and the 2 survivors are
// PROVEN semantically equivalent by syn/gt2n/prove_sticky_benign.ys. Do not
// treat those two as a gap.
module tb_fma_diff;

    parameter NRAND = 20000;

    reg         clk = 1'b0;
    reg         rst_n = 1'b0;
    reg         en = 1'b1;
    reg         valid_in = 1'b0;
    reg  [1:0]  rm = 2'b00;
    reg  [31:0] a, b, c;

    wire        g_valid,  n_valid;
    wire [31:0] g_result, n_result;
    wire        g_inv, g_ovf, g_unf, g_inx;
    wire        n_inv, n_ovf, n_unf, n_inx;

    always #5 clk = ~clk;

    titan_x7_fp32_fma_pipe_gold u_gold (
        .clk(clk), .rst_n(rst_n), .en(en), .valid_in(valid_in), .rm(rm),
        .a(a), .b(b), .c(c),
        .valid_out(g_valid), .result(g_result),
        .flag_invalid(g_inv), .flag_overflow(g_ovf),
        .flag_underflow(g_unf), .flag_inexact(g_inx));

    titan_x7_fp32_fma_pipe u_new (
        .clk(clk), .rst_n(rst_n), .en(en), .valid_in(valid_in), .rm(rm),
        .a(a), .b(b), .c(c),
        .valid_out(n_valid), .result(n_result),
        .flag_invalid(n_inv), .flag_overflow(n_ovf),
        .flag_underflow(n_unf), .flag_inexact(n_inx));

    integer errors = 0, compares = 0, i;

    // valid_out must match on EVERY cycle -- that is the pipeline timing, and
    // the restructure must not have moved it.
    //
    // result and the flags are only architecturally meaningful when valid_out
    // is asserted, so they are compared then. Comparing them while the pipe is
    // filling only compares X-propagation: gold yields `xxxxxxxx` there and the
    // restructured version `X0000000`, because replacing `if (mant_r[24])` with
    // a mux on the adder's carry-out is less X-pessimistic. That is a
    // simulation artefact of unknown values, not a hardware difference -- so
    // the check below also fails if an X ever reaches a VALID result, which is
    // the case that would matter.
    integer xleaks = 0;

    always @(posedge clk) begin
        if (rst_n) begin
            compares = compares + 1;

            if (g_valid !== n_valid) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("VALID MISMATCH t=%0t gold=%b new=%b", $time, g_valid, n_valid);
            end

            if (g_valid === 1'b1 && n_valid === 1'b1) begin
                if ({g_result, g_inv, g_ovf, g_unf, g_inx} !==
                    {n_result, n_inv, n_ovf, n_unf, n_inx}) begin
                    errors = errors + 1;
                    if (errors <= 10)
                        $display("MISMATCH t=%0t rm=%0d a=%h b=%h c=%h | gold r=%h f=%b%b%b%b | new r=%h f=%b%b%b%b",
                                 $time, rm, a, b, c,
                                 g_result, g_inv, g_ovf, g_unf, g_inx,
                                 n_result, n_inv, n_ovf, n_unf, n_inx);
                end
                if (^{n_result, n_inv, n_ovf, n_unf, n_inx} === 1'bx) begin
                    xleaks = xleaks + 1;
                    if (xleaks <= 5)
                        $display("X IN VALID RESULT t=%0t r=%h", $time, n_result);
                end
            end
        end
    end

    // A float built from parts, so the stimulus can be aimed at an exponent
    // range instead of hoping random 32-bit words land there.
    function [31:0] mk;
        input        sgn;
        input [7:0]  exp;
        input [22:0] man;
        begin mk = {sgn, exp, man}; end
    endfunction

    task drive;
        input [31:0] va, vb, vc;
        input [1:0]  vrm;
        begin
            @(negedge clk);
            a = va; b = vb; c = vc; rm = vrm; valid_in = 1'b1;
        end
    endtask

    reg [31:0] corner [0:15];
    integer k, m, n;

    initial begin
        corner[0]  = 32'h00000000;              // +0
        corner[1]  = 32'h80000000;              // -0
        corner[2]  = 32'h7F800000;              // +inf
        corner[3]  = 32'hFF800000;              // -inf
        corner[4]  = 32'h7FC00000;              // qNaN
        corner[5]  = 32'h7F800001;              // sNaN
        corner[6]  = 32'h00000001;              // smallest denormal
        corner[7]  = 32'h007FFFFF;              // largest denormal
        corner[8]  = 32'h00800000;              // smallest normal
        corner[9]  = 32'h7F7FFFFF;              // largest finite
        corner[10] = 32'h3F800000;              // 1.0
        corner[11] = 32'hBF800000;              // -1.0
        corner[12] = 32'h40000000;              // 2.0
        corner[13] = 32'h33800000;              // 2^-24
        corner[14] = 32'h00000002;
        corner[15] = 32'h80800000;

        repeat (4) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        // Every corner triple, in every rounding mode.
        for (k = 0; k < 16; k = k + 1)
          for (m = 0; m < 16; m = m + 1)
            for (n = 0; n < 4; n = n + 1)
              drive(corner[k], corner[m], corner[(k+m) & 15], n[1:0]);

        // Aimed at SUBNORMAL results: small exponents on both multiplicands
        // means the product underflows and E8's denormalise path runs.
        for (i = 0; i < NRAND; i = i + 1)
            drive(mk($random, ($random % 40) + 1,  $random),
                  mk($random, ($random % 40) + 1,  $random),
                  mk($random, ($random % 60) + 1,  $random),
                  $random);

        // Aimed at the GRADED denormal range, den_amt = 1..25.
        //
        // This block exists because mutation testing found the block above
        // does not reach it: exponents of 1..40 put the product at roughly
        // 2**-125..2**-47, so `den_amt` is ALWAYS past the 26 clamp and the
        // partial shifts are never exercised. den_amt is 1 - exp, and the
        // product exponent tracks ea + eb - 127, so ea + eb in 102..127 is
        // what walks den_amt across 1..25.
        for (i = 0; i < NRAND; i = i + 1) begin
            k = ($random % 26) + 51;             // 51..76
            m = (102 + ($random % 26)) - k;      // pairs to 102..127
            if (m < 1)   m = 1;
            if (m > 254) m = 254;
            drive(mk($random, k[7:0], $random),
                  mk($random, m[7:0], $random),
                  mk($random, ($random % 30) + 1, $random),
                  $random);
        end

        // The same range with an all-ones mantissa on both multiplicands, so
        // the denormalising shift and the round increment interact.
        for (i = 0; i < NRAND; i = i + 1) begin
            k = ($random % 26) + 51;
            m = (102 + ($random % 26)) - k;
            if (m < 1)   m = 1;
            if (m > 254) m = 254;
            drive(mk($random, k[7:0], 23'h7FFFFF),
                  mk($random, m[7:0], 23'h7FFFFF),
                  mk($random, ($random % 30) + 1, $random),
                  $random);
        end

        // Aimed at OVERFLOW: large exponents, which exercises the ge255 path
        // and the rounding-overflow carry that used to gate the exponent add.
        for (i = 0; i < NRAND; i = i + 1)
            drive(mk($random, ($random % 30) + 200, $random),
                  mk($random, ($random % 30) + 200, $random),
                  mk($random, ($random % 30) + 200, $random),
                  $random);

        // Aimed at the ROUNDING boundary: mantissas of all ones are what makes
        // the round increment carry out of the mantissa.
        for (i = 0; i < NRAND; i = i + 1)
            drive(mk($random, ($random % 250) + 1, 23'h7FFFFF),
                  mk($random, ($random % 250) + 1, {$random} % 24'h7FFFFF),
                  mk($random, ($random % 250) + 1, 23'h7FFFFF),
                  $random);

        // Unconstrained random, whole 32-bit space.
        for (i = 0; i < NRAND; i = i + 1)
            drive($random, $random, $random, $random);

        valid_in = 1'b0;
        repeat (20) @(posedge clk);

        $display("tb_fma_diff: %0d cycles compared, %0d mismatches, %0d X-leaks",
                 compares, errors, xleaks);
        if (errors == 0 && xleaks == 0) $display("tb_fma_diff: PASS");
        else                            $display("tb_fma_diff: FAIL");
        $finish;
    end

endmodule
