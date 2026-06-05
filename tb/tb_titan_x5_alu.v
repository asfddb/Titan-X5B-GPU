`timescale 1ns/1ps

module tb_titan_x5_alu();
    reg clk;
    reg rst_n;
    reg valid_in;
    reg [4:0] opcode;
    reg [31:0] src1, src2, src3;
    wire valid_out;
    wire [31:0] result_out;

    titan_x5_alu u_alu (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .opcode(opcode),
        .src1(src1),
        .src2(src2),
        .src3(src3),
        .valid_out(valid_out),
        .result_out(result_out)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("waves.vcd");
        $dumpvars(0, tb_titan_x5_alu);

        rst_n = 0;
        valid_in = 0;
        opcode = 0;
        src1 = 0; src2 = 0; src3 = 0;
        
        #20 rst_n = 1;
        
        // Test ADD
        #10;
        valid_in = 1;
        opcode = 5'd0; // ADD
        src1 = 32'd15;
        src2 = 32'd25;
        #10 valid_in = 0;
        
        // Test FMA
        #20;
        valid_in = 1;
        opcode = 5'd21; // FMA
        src1 = 32'd10;
        src2 = 32'd5;
        src3 = 32'd7;
        #10 valid_in = 0;
        
        // Test MUL (3 cycles)
        #20;
        valid_in = 1;
        opcode = 5'd2; // MUL
        src1 = 32'd100;
        src2 = 32'd50;
        #10 valid_in = 0;
        
        #50;
        $display("ALU Testbench Complete. Wrote waves.vcd.");
        $finish;
    end
endmodule
