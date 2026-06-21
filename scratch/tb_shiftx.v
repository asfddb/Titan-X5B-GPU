module tb;
    wire [3:0] one_vec = 1;
    wire [3:0] shift_res = one_vec << 2'b1x;
    initial begin
        #1;
        $display("shift_res = %b", shift_res);
    end
endmodule
