`timescale 1ns/1ps

/*
 * Module: titan_x5_sr_engine
 * Description: 64-entry, 4-way set-associative cache. 32-bit tag comparison.
 * Uses FNV-64 hash output for indexing. 2-stage pipeline. Ready/valid skid buffers.
 */
module titan_x5_sr_engine #(
    parameter DATA_WIDTH = 32
) (
    input  wire                  clk,
    input  wire                  rst_n,

    // input interface
    input  wire                  i_valid,
    output wire                  i_ready,
    input wire [63:0] i_hash,
    input wire [DATA_WIDTH-1:0] i_data,
    input  wire                  i_write,

    // output interface
    output wire                  o_valid,
    input  wire                  o_ready,
    output wire [DATA_WIDTH-1:0] o_data,
    output wire                  o_hit
);

    // input skid buffer
    wire                  skid_i_valid;
    wire                  skid_i_ready;
    wire [63:0]           skid_i_hash;
    wire [DATA_WIDTH-1:0] skid_i_data;
    wire                  skid_i_write;

    titan_x5_skid_buffer #(
        .DATA_WIDTH(64 + DATA_WIDTH + 1)
    ) in_skid (
        .clk    (clk),
        .rst_n  (rst_n),
        .i_valid(i_valid),
        .i_ready(i_ready),
        .i_data ({i_write, i_hash, i_data}),
        
        .o_valid(skid_i_valid),
        .o_ready(skid_i_ready),
        .o_data ({skid_i_write, skid_i_hash, skid_i_data})
    );

    // cache storage (16 sets, 4 ways)
    reg [31:0]           tag_ram  [0:3][0:15];
    reg [DATA_WIDTH-1:0] data_ram [0:3][0:15];
    reg                  valid_ram[0:3][0:15];
    reg [1:0]            repl_way [0:15];

    integer i, j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 16; j = j + 1) begin
                    valid_ram[i][j] <= 1'b0;
                end
            end
            for (j = 0; j < 16; j = j + 1) begin
                repl_way[j] <= 2'd0;
            end
        end else begin
            if (skid_i_valid && skid_i_ready && skid_i_write) begin
                valid_ram[repl_way[skid_i_hash[3:0]]][skid_i_hash[3:0]] <= 1'b1;
                repl_way[skid_i_hash[3:0]] <= repl_way[skid_i_hash[3:0]] + 2'd1; // round-robin replacement
            end
        end
    end

    // ram writes
    always @(posedge clk) begin
        if (skid_i_valid && skid_i_ready && skid_i_write) begin
            tag_ram[repl_way[skid_i_hash[3:0]]][skid_i_hash[3:0]]  <= skid_i_hash[35:4];
            data_ram[repl_way[skid_i_hash[3:0]]][skid_i_hash[3:0]] <= skid_i_data;
        end
    end

    // stage 1: read cache 
    wire stage2_ready; 
    reg        s1_valid;
    reg [31:0] s1_tag;
    reg [31:0] s1_read_tags  [0:3];
    reg [DATA_WIDTH-1:0] s1_read_data [0:3];
    reg        s1_read_valid [0:3];
    reg        s1_is_write;

    assign skid_i_ready = !s1_valid || stage2_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 1'b0;
            s1_tag <= 32'd0;
            s1_is_write <= 1'b0;
            for (i = 0; i < 4; i = i + 1) begin
                s1_read_tags[i]  <= 32'd0;
                s1_read_data[i]  <= {DATA_WIDTH{1'b0}};
                s1_read_valid[i] <= 1'b0;
            end
        end else begin
            if (stage2_ready) begin
                s1_valid <= skid_i_valid;
                if (skid_i_valid) begin
                    s1_tag      <= skid_i_hash[35:4];
                    s1_is_write <= skid_i_write;
                    for (i = 0; i < 4; i = i + 1) begin
                        s1_read_tags[i]  <= tag_ram[i][skid_i_hash[3:0]];
                        s1_read_data[i]  <= data_ram[i][skid_i_hash[3:0]];
                        s1_read_valid[i] <= valid_ram[i][skid_i_hash[3:0]];
                    end
                end
            end else if (skid_i_valid && !s1_valid) begin
                s1_valid <= 1'b1;
                s1_tag      <= skid_i_hash[35:4];
                s1_is_write <= skid_i_write;
                for (i = 0; i < 4; i = i + 1) begin
                    s1_read_tags[i]  <= tag_ram[i][skid_i_hash[3:0]];
                    s1_read_data[i]  <= data_ram[i][skid_i_hash[3:0]];
                    s1_read_valid[i] <= valid_ram[i][skid_i_hash[3:0]];
                end
            end
        end
    end

    // stage 2: tag compare
    reg [DATA_WIDTH-1:0] s2_out_data;
    reg                  s2_out_hit;

    always @(*) begin
        s2_out_hit  = 1'b0;
        s2_out_data = {DATA_WIDTH{1'b0}};
        
        if (s1_is_write) begin
            s2_out_hit = 1'b1; // writes logically always hit
        end else begin
            if (s1_read_valid[0] && (s1_read_tags[0] == s1_tag)) begin s2_out_hit = 1'b1; s2_out_data = s1_read_data[0]; end
            else if (s1_read_valid[1] && (s1_read_tags[1] == s1_tag)) begin s2_out_hit = 1'b1; s2_out_data = s1_read_data[1]; end
            else if (s1_read_valid[2] && (s1_read_tags[2] == s1_tag)) begin s2_out_hit = 1'b1; s2_out_data = s1_read_data[2]; end
            else if (s1_read_valid[3] && (s1_read_tags[3] == s1_tag)) begin s2_out_hit = 1'b1; s2_out_data = s1_read_data[3]; end
        end
    end

    // output skid buffer
    titan_x5_skid_buffer #(
        .DATA_WIDTH(DATA_WIDTH + 1)
    ) out_skid (
        .clk    (clk),
        .rst_n  (rst_n),
        .i_valid(s1_valid),
        .i_ready(stage2_ready),
        .i_data ({s2_out_hit, s2_out_data}),
        
        .o_valid(o_valid),
        .o_ready(o_ready),
        .o_data ({o_hit, o_data})
    );

endmodule
