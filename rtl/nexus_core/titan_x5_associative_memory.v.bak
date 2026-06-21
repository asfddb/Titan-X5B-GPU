/*
 * Nexus Neuromorphic HDC Engine
 * Module: titan_x5_associative_memory
 * Description: Content-Addressable Memory (CAM) for 1024-bit Hypervectors.
 * Stores up to 4 concepts and computes Hamming Distance over 16 cycles to find closest match.
 */

module titan_x5_associative_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start_train,
    input  wire        start_query,
    input wire [1:0] concept_id,
    input wire [63:0] hv_in,
    output reg [1:0] match_id,
    output reg         valid_out,
    output reg         done
);

    reg [63:0] concepts_0 [0:15];
    reg [63:0] concepts_1 [0:15];
    reg [63:0] concepts_2 [0:15];
    reg [63:0] concepts_3 [0:15];

    reg [1:0]  state;
    reg [3:0]  idx;
    reg [1:0]  train_id;

    reg [10:0] dist_0, dist_1, dist_2, dist_3;

    localparam IDLE    = 2'd0;
    localparam TRAIN   = 2'd1;
    localparam QUERY   = 2'd2;
    localparam COMPARE = 2'd3;

    function [6:0] popcount64;
    input [63:0] val;
        integer i;
        begin
            popcount64 = 0;
            for (i = 0; i < 64; i = i + 1) begin
                popcount64 = popcount64 + val[i];
            end
        end
    endfunction

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            idx       <= 4'd0;
            valid_out <= 1'b0;
            done      <= 1'b0;
            match_id  <= 2'd0;
            train_id  <= 2'd0;
            dist_0    <= 11'd0;
            dist_1    <= 11'd0;
            dist_2    <= 11'd0;
            dist_3    <= 11'd0;
            for (i = 0; i < 16; i = i + 1) begin
                concepts_0[i] <= 64'd0;
                concepts_1[i] <= 64'd0;
                concepts_2[i] <= 64'd0;
                concepts_3[i] <= 64'd0;
            end
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    done      <= 1'b0;
                    idx       <= 4'd0;
                    if (start_train) begin
                        state    <= TRAIN;
                        train_id <= concept_id;
                        case (concept_id)
                            2'd0: concepts_0[0] <= hv_in;
                            2'd1: concepts_1[0] <= hv_in;
                            2'd2: concepts_2[0] <= hv_in;
                            2'd3: concepts_3[0] <= hv_in;
                        endcase
                        idx <= 4'd1;
                    end else if (start_query) begin
                        state  <= QUERY;
                        dist_0 <= popcount64(hv_in ^ concepts_0[0]);
                        dist_1 <= popcount64(hv_in ^ concepts_1[0]);
                        dist_2 <= popcount64(hv_in ^ concepts_2[0]);
                        dist_3 <= popcount64(hv_in ^ concepts_3[0]);
                        idx    <= 4'd1;
                    end
                end
                
                TRAIN: begin
                    case (train_id)
                        2'd0: concepts_0[idx] <= hv_in;
                        2'd1: concepts_1[idx] <= hv_in;
                        2'd2: concepts_2[idx] <= hv_in;
                        2'd3: concepts_3[idx] <= hv_in;
                    endcase
                    if (idx == 4'd15) begin
                        state     <= IDLE;
                        done      <= 1'b1;
                        valid_out <= 1'b1;
                    end else begin
                        idx <= idx + 1'b1;
                    end
                end
                
                QUERY: begin
                    dist_0 <= dist_0 + popcount64(hv_in ^ concepts_0[idx]);
                    dist_1 <= dist_1 + popcount64(hv_in ^ concepts_1[idx]);
                    dist_2 <= dist_2 + popcount64(hv_in ^ concepts_2[idx]);
                    dist_3 <= dist_3 + popcount64(hv_in ^ concepts_3[idx]);
                    if (idx == 4'd15) begin
                        state <= COMPARE;
                    end else begin
                        idx <= idx + 1'b1;
                    end
                end
                
                COMPARE: begin
                    // find lowest hamming distance
                    if (dist_0 <= dist_1 && dist_0 <= dist_2 && dist_0 <= dist_3)
                        match_id <= 2'd0;
                    else if (dist_1 <= dist_0 && dist_1 <= dist_2 && dist_1 <= dist_3)
                        match_id <= 2'd1;
                    else if (dist_2 <= dist_0 && dist_2 <= dist_1 && dist_2 <= dist_3)
                        match_id <= 2'd2;
                    else
                        match_id <= 2'd3;
                    
                    valid_out <= 1'b1;
                    done      <= 1'b1;
                    state     <= IDLE;
                end
            endcase
        end
    end

endmodule
