`timescale 1ns/1ps

module tb_titan_x5_2048();

    reg clk;
    reg rst_n;
    
    // ALU Interface
    reg valid_in;
    reg [2:0] opcode;
    reg [2047:0] src1;
    reg [2047:0] src2;
    wire [2047:0] result;
    wire valid_out;
    
    titan_x5_2048_alu u_alu_2048 (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .opcode(opcode),
        .src1(src1),
        .src2(src2),
        .result(result),
        .valid_out(valid_out)
    );
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        $dumpfile("waves_2048.vcd");
        $dumpvars(0, tb_titan_x5_2048);
        
        rst_n = 0;
        valid_in = 0;
        opcode = 0;
        src1 = 0;
        src2 = 0;
        
        #20 rst_n = 1;
        
        // ---------------------------------------------------------
        // Test 1: 2048-bit Addition
        // ---------------------------------------------------------
        #10;
        $display("[%0t] Starting 2048-bit Addition Test...", $time);
        valid_in = 1;
        opcode = 3'd0; // ADD
        
        // Load some massive real 2048-bit numbers
        src1[63:0] = 64'hFFFFFFFFFFFFFFFF;
        src1[127:64] = 64'h0000000000000000;
        src1[2047:128] = {1920{1'b0}}; // Keep upper bits 0 for easy reading
        
        src2[63:0] = 64'h0000000000000001; // Adding 1 should ripple carry
        src2[2047:64] = {1984{1'b0}};
        
        #10 valid_in = 0;
        
        // Wait for completion (34 cycles)
        wait(valid_out == 1'b1);
        @(posedge clk);
        $display("[%0t] 2048-bit Addition Complete!", $time);
        $display("Result[127:0] = 0x%x", result[127:0]);
        
        #100;
        $display("Simulation finished. VCD generated.");
        $finish;
    end

endmodule
