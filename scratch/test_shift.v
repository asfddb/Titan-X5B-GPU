`timescale 1ns/1ps
module test_shift;
    parameter NUM_NODES = 1;
    reg [0:0] src_node;
    wire [NUM_NODES-1:0] src_dec = {{(NUM_NODES-1){1'b0}}, 1'b1} << src_node;

    initial begin
        src_node = 0;
        #1;
        $display("src_node=%0d src_dec=%b (width=%0d)", src_node, src_dec, $bits(src_dec));
        $finish;
    end
endmodule
