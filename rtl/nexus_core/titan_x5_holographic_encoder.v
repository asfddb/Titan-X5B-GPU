/*
 * Nexus Neuromorphic HDC Engine
 * Module: titan_x5_holographic_encoder
 * Description: Maps a 32-bit input vector into a 1024-bit orthogonal Hypervector.
 * Processed over 16 clock cycles (64 bits per cycle) using a seeded LFSR.
 */

module titan_x5_holographic_encoder (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [31:0] data_in,
    output reg  [63:0] hv_out,
    output reg         valid_out,
    output reg         done
);

    reg [3:0]  cycle_cnt;
    reg        active;
    reg [63:0] lfsr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active    <= 1'b0;
            cycle_cnt <= 4'd0;
            hv_out    <= 64'd0;
            valid_out <= 1'b0;
            done      <= 1'b0;
            lfsr      <= 64'd0;
        end else begin
            if (start) begin
                active    <= 1'b1;
                cycle_cnt <= 4'd0;
                // Initialize LFSR seed based on input data
                lfsr      <= {32'hA5A5A5A5 ^ data_in, data_in};
                valid_out <= 1'b0;
                done      <= 1'b0;
            end else if (active) begin
                // Output current LFSR value
                hv_out    <= lfsr;
                valid_out <= 1'b1;
                
                // Shift LFSR for next cycle (Galois configuration)
                // Polynomial: x^64 + x^63 + x^61 + x^60 + 1
                lfsr <= {lfsr[0], lfsr[63:1]} ^ (lfsr[0] ? 64'hD800000000000000 : 64'h0);
                
                if (cycle_cnt == 4'd15) begin
                    active <= 1'b0;
                    done   <= 1'b1;
                end else begin
                    cycle_cnt <= cycle_cnt + 1'b1;
                    done      <= 1'b0;
                end
            end else begin
                valid_out <= 1'b0;
                done      <= 1'b0;
            end
        end
    end

endmodule
