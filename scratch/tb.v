module tb;
    parameter N = 4;
    wire [N-1:0] src_dec = ( {N{1'b0}} | 1'b1 ) << 2;
    
    initial begin
        #1;
        $display("src_dec = %b", src_dec);
        $finish;
    end
endmodule
