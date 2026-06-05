`timescale 1ns/1ps

/*
 * Module: titan_x5_skid_buffer
 * Description: Parameterized ready/valid skid buffer for fully registered pipeline stalls.
 */
module titan_x5_skid_buffer #(
    parameter DATA_WIDTH = 32
) (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  i_valid,
    output wire                  i_ready,
    input  wire [DATA_WIDTH-1:0] i_data,

    output wire                  o_valid,
    input  wire                  o_ready,
    output wire [DATA_WIDTH-1:0] o_data
);

    reg [DATA_WIDTH-1:0] data_reg;
    reg [DATA_WIDTH-1:0] skid_reg;
    
    reg valid_reg;
    reg skid_valid;

    assign o_valid = valid_reg;
    assign o_data  = data_reg;
    assign i_ready = !skid_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_reg  <= 1'b0;
            skid_valid <= 1'b0;
            data_reg   <= {DATA_WIDTH{1'b0}};
            skid_reg   <= {DATA_WIDTH{1'b0}};
        end else begin
            if (o_ready || !valid_reg) begin
                // Output is transferring or empty
                valid_reg <= i_valid || skid_valid;
                if (skid_valid) begin
                    data_reg   <= skid_reg;
                    skid_valid <= 1'b0;
                end else if (i_valid) begin
                    data_reg <= i_data;
                end
            end else if (i_valid && i_ready) begin
                // Output is stalled, but we can accept one more into skid
                skid_valid <= 1'b1;
                skid_reg   <= i_data;
            end
        end
    end
endmodule
