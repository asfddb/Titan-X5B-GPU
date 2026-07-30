// Miter: operand isolation ON vs OFF, identical stimulus and identical
// enable behaviour, so the ONLY difference is the operand clamp.
module iso_miter(
    input clk, input rst_n, input lane_active, input valid_in,
    input [1:0] rm, input [31:0] a, input [31:0] b, input [31:0] c,
    output bad);
    wire vA, vB; wire [31:0] rA, rB;
    wire iA, oA, uA, xA, iB, oB, uB, xB;
    wire dA, dB;
    titan_apex_fma_lane #(.ISOLATE(1)) uA_ (.clk(clk), .rst_n(rst_n),
        .lane_active(lane_active), .valid_in(valid_in), .rm(rm),
        .a(a), .b(b), .c(c), .valid_out(vA), .result(rA),
        .flag_invalid(iA), .flag_overflow(oA), .flag_underflow(uA),
        .flag_inexact(xA), .dbg_isolated(dA));
    titan_apex_fma_lane #(.ISOLATE(0)) uB_ (.clk(clk), .rst_n(rst_n),
        .lane_active(lane_active), .valid_in(valid_in), .rm(rm),
        .a(a), .b(b), .c(c), .valid_out(vB), .result(rB),
        .flag_invalid(iB), .flag_overflow(oB), .flag_underflow(uB),
        .flag_inexact(xB), .dbg_isolated(dB));
    assign bad = (vA ^ vB)
               | (vA & (|(rA ^ rB) | (iA^iB) | (oA^oB) | (uA^uB) | (xA^xB)));
endmodule
