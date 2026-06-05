`timescale 1ns/1ps

module titan_x5_register_file #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS = 64, // 64 registers total
    parameter NUM_BANKS = 4  // 4 banks, so 16 registers per bank
) (
    input  wire clk,
    input  wire rst_n,
    
    // Read ports (3 per bank for FMA support)
    input  wire [NUM_BANKS-1:0]                  rd_en_0,
    input  wire [NUM_BANKS-1:0]                  rd_en_1,
    input  wire [NUM_BANKS-1:0]                  rd_en_2,
    input  wire [NUM_BANKS*4-1:0]                rd_addr_0, 
    input  wire [NUM_BANKS*4-1:0]                rd_addr_1,
    input  wire [NUM_BANKS*4-1:0]                rd_addr_2,
    output wire [NUM_BANKS*DATA_WIDTH-1:0]       rd_data_0,
    output wire [NUM_BANKS*DATA_WIDTH-1:0]       rd_data_1,
    output wire [NUM_BANKS*DATA_WIDTH-1:0]       rd_data_2,
    
    // Write ports (1 per bank)
    input  wire [NUM_BANKS-1:0]                  wr_en,
    input  wire [NUM_BANKS*4-1:0]                wr_addr,
    input  wire [NUM_BANKS*DATA_WIDTH-1:0]       wr_data
);

    localparam REGS_PER_BANK = NUM_REGS / NUM_BANKS;
    localparam ADDR_WIDTH = 4;

    genvar b;
    generate
        for (b = 0; b < NUM_BANKS; b = b + 1) begin : bank_gen
            reg [DATA_WIDTH-1:0] bank_mem [0:REGS_PER_BANK-1];
            integer i;
            
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (i = 0; i < REGS_PER_BANK; i = i + 1) begin
                        bank_mem[i] <= {DATA_WIDTH{1'b0}};
                    end
                end else if (wr_en[b]) begin
                    bank_mem[wr_addr[b*ADDR_WIDTH +: ADDR_WIDTH]] <= wr_data[b*DATA_WIDTH +: DATA_WIDTH];
                end
            end
            
            assign rd_data_0[b*DATA_WIDTH +: DATA_WIDTH] = rd_en_0[b] ? bank_mem[rd_addr_0[b*ADDR_WIDTH +: ADDR_WIDTH]] : {DATA_WIDTH{1'b0}};
            assign rd_data_1[b*DATA_WIDTH +: DATA_WIDTH] = rd_en_1[b] ? bank_mem[rd_addr_1[b*ADDR_WIDTH +: ADDR_WIDTH]] : {DATA_WIDTH{1'b0}};
            assign rd_data_2[b*DATA_WIDTH +: DATA_WIDTH] = rd_en_2[b] ? bank_mem[rd_addr_2[b*ADDR_WIDTH +: ADDR_WIDTH]] : {DATA_WIDTH{1'b0}};
        end
    endgenerate

endmodule
