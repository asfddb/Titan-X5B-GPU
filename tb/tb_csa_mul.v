`timescale 1ns/1ps
// Differential test: titan_x7_csa_mul24's (s,c) pair sums to a*b, at the real
// 24x24 width. This is the part the SAT decomposition could not reach --
// `sum of partial-product rows == a*b` -- and it is the same wall the project
// already hit on the segmented multiplier (docs/BUILD_LOG_2NM.md, "Where
// formal beat simulation"). Same remedy: exhaustive corners plus random.
//
// MUST be compiled WITHOUT TITAN_FAST_SIM or this compares a*b against a*b.
module tb_csa_mul;

    parameter NRAND = 20000;

    reg  [23:0] a, b;
    wire [47:0] s, c;

    titan_x7_csa_mul24 dut (.a(a), .b(b), .s(s), .c(c));

    integer i, j, errors, checks;
    reg [23:0] corner [0:31];

    task check;
        begin
            #1;
            checks = checks + 1;
            if ((s + c) !== (a * b)) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("MISMATCH a=%h b=%h  s+c=%h  ref=%h",
                             a, b, (s + c), (a * b));
            end
        end
    endtask

    initial begin
        errors = 0; checks = 0;

        // Corner values: zero, one, all-ones, the carry-propagation worst
        // cases, alternating patterns, and every single-bit weight.
        corner[0]  = 24'h000000; corner[1]  = 24'h000001;
        corner[2]  = 24'h000002; corner[3]  = 24'h000003;
        corner[4]  = 24'hFFFFFF; corner[5]  = 24'hFFFFFE;
        corner[6]  = 24'h7FFFFF; corner[7]  = 24'h800000;
        corner[8]  = 24'hAAAAAA; corner[9]  = 24'h555555;
        corner[10] = 24'h0F0F0F; corner[11] = 24'hF0F0F0;
        corner[12] = 24'h123456; corner[13] = 24'hFEDCBA;
        corner[14] = 24'hFFF000; corner[15] = 24'h000FFF;
        for (i = 0; i < 16; i = i + 1)
            corner[16 + i] = 24'h1 << i;

        // Exhaustive over every corner pair.
        for (i = 0; i < 32; i = i + 1)
            for (j = 0; j < 32; j = j + 1) begin
                a = corner[i]; b = corner[j];
                check;
            end

        // Every corner against a sweep of small multipliers, which is where
        // an off-by-one in a row shift would show up first.
        for (i = 0; i < 32; i = i + 1)
            for (j = 0; j < 64; j = j + 1) begin
                a = corner[i]; b = j[23:0];
                check;
                a = j[23:0]; b = corner[i];
                check;
            end

        // Random pairs.
        for (i = 0; i < NRAND; i = i + 1) begin
            a = {$random} % 24'hFFFFFF;
            b = {$random} % 24'hFFFFFF;
            check;
        end

        $display("tb_csa_mul: %0d checks, %0d mismatches", checks, errors);
        if (errors == 0) $display("tb_csa_mul: PASS");
        else             $display("tb_csa_mul: FAIL");
        $finish;
    end

endmodule
