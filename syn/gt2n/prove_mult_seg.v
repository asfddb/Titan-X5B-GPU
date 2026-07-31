// All three segmentation modes against direct multiplication.
module mult_seg_equiv(input [23:0] a, input [23:0] b,
                      output diff_full, output diff_half, output diff_tile);
    wire [47:0]  full;
    wire [95:0]  half;   // 4 x 24
    wire [191:0] tile;   // 16 x 12
    titan_apex_mult_seg u(.a(a), .b(b), .mode(2'd0),
                          .full(full), .half(half), .tile(tile));

    // FULL: the exact 24x24 product
    assign diff_full = |(full ^ (a * b));

    // HALF: quadrant (I,J) is the 12x12 product of a's I-th half by b's J-th
    wire [23:0] ah0 = a[11:0],  ah1 = a[23:12];
    wire [23:0] bh0 = b[11:0],  bh1 = b[23:12];
    assign diff_half =
        |(half[0*24 +: 24] ^ (ah0 * bh0)) |
        |(half[1*24 +: 24] ^ (ah0 * bh1)) |
        |(half[2*24 +: 24] ^ (ah1 * bh0)) |
        |(half[3*24 +: 24] ^ (ah1 * bh1));

    // TILE: each 6x6 slice product
    wire [11:0] t_ref [0:15];
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gi
            for (j = 0; j < 4; j = j + 1) begin : gj
                assign t_ref[i*4+j] = a[i*6 +: 6] * b[j*6 +: 6];
            end
        end
    endgenerate
    wire [15:0] tmis;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gm
            assign tmis[i] = |(tile[i*12 +: 12] ^ t_ref[i]);
        end
    endgenerate
    assign diff_tile = |tmis;
endmodule
