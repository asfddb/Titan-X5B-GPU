// (1 << down) - 1  ==  ~(~0 << down)   for the PE's 137-bit sticky mask.
module mask_equiv #(parameter W = 137)(input [6:0] down, output diff);
    wire [W-1:0] old_mask = ({{(W-1){1'b0}}, 1'b1} << down) - {{(W-1){1'b0}}, 1'b1};
    wire [W-1:0] new_mask = ~({W{1'b1}} << down);
    assign diff = |(old_mask ^ new_mask);
endmodule
