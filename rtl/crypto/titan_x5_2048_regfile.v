`timescale 1ns/1ps

/*
 * Titan X5 GPU Coprocessor - 2048-bit Register File
 * 
 * Features:
 * - 8 x 2048-bit registers
 * - 2 asynchronous read ports, 1 synchronous write port
 * - Synthesizable as LUTRAM or Block RAM depending on constraints
 */
module titan_x5_2048_regfile (
    input  wire clk,
    input  wire rst_n,
    
    input wire [2:0] rd_addr1,
    output wire [2047:0] rd_data1,
    
    input wire [2:0] rd_addr2,
    output wire [2047:0] rd_data2,
    
    input  wire wr_en,
    input wire [2:0] wr_addr,
    input wire [2047:0] wr_data
);

    integer i;
    (* ram_style="block" *) reg [2047:0] registers [0:7];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 2048'd0;
            end
        end else begin
            if (wr_en) begin
                registers[wr_addr] <= wr_data;
            end
        end
    end

    assign rd_data1 = registers[rd_addr1];
    assign rd_data2 = registers[rd_addr2];

endmodule
