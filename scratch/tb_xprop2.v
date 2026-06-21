module tb;
    reg clk, rst_n;
    reg [3:0] entanglement_ready;
    reg [3:0] consume_mask;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) entanglement_ready <= 4'b1111;
        else if (|consume_mask) entanglement_ready <= entanglement_ready & ~consume_mask;
    end
    
    initial begin
        clk = 0; rst_n = 0; consume_mask = 0;
        #10 rst_n = 1;
        
        #10 consume_mask = 4'b01x0; clk = 1; #10 clk = 0;
        $display("After partial X consume_mask: %b", entanglement_ready);
        
        $finish;
    end
endmodule
