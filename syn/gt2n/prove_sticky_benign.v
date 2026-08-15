// M3: `<` vs `<=` in the sticky compare. The design also ORs den_shifted[0],
// which IS src[d], so the extra term the mutation adds is already present.
module sticky_equiv(input [25:0] src, input [4:0] d, input e7st, output diff);
    wire [25:0] sh = src >> d;
    reg lt_or, le_or; integer j;
    always @(*) begin
        lt_or = 1'b0; le_or = 1'b0;
        for (j = 0; j < 26; j = j + 1) begin
            if (j <  d) lt_or = lt_or | src[j];
            if (j <= d) le_or = le_or | src[j];
        end
    end
    wire st_lt = e7st | lt_or | sh[0];
    wire st_le = e7st | le_or | sh[0];
    assign diff = (d <= 5'd26) ? (st_lt != st_le) : 1'b0;
endmodule

// M4: clamping den_amt to 25 vs 26. Everything past 25 has already left the
// 26-bit vector, and the bit that lands in sh[0] is ORed into sticky either
// way, so (mant_d, rb, st) are identical.
module clamp_equiv(input [25:0] src, input e7st, output diff);
    wire [25:0] sh25 = src >> 5'd25;
    wire [25:0] sh26 = src >> 5'd26;
    reg or25, or26; integer j;
    always @(*) begin
        or25 = 1'b0; or26 = 1'b0;
        for (j = 0; j < 26; j = j + 1) begin
            if (j < 25) or25 = or25 | src[j];
            if (j < 26) or26 = or26 | src[j];
        end
    end
    assign diff = (sh25[25:2] != sh26[25:2])
                | (sh25[1]    != sh26[1])
                | ((e7st|or25|sh25[0]) != (e7st|or26|sh26[0]));
endmodule
