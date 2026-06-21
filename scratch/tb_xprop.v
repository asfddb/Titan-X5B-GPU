module tb;
    reg clk, rst_n;
    reg [3:0] entanglement_ready;
    wire [3:0] consume_mask;
    reg [1:0] src_node;
    
    wire [3:0] one_vec = 1;
    wire [3:0] src_dec = one_vec << src_node;
    assign consume_mask = src_dec; // simplified
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) entanglement_ready <= 4'b1111;
        else if (|consume_mask) entanglement_ready <= entanglement_ready & ~consume_mask;
    end
    
    initial begin
        clk = 0; rst_n = 0; src_node = 0;
        #10 rst_n = 1;
        
        #10 src_node = 2'b01; clk = 1; #10 clk = 0;
        $display("After valid src_node: %b", entanglement_ready);
        
        #10 src_node = 2'bx; clk = 1; #10 clk = 0;
        $display("After X src_node: %b", entanglement_ready);
        
        $finish;
    end
endmodule
