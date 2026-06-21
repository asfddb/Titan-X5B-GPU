/*
 * Nexus Neuromorphic HDC Engine
 * Module: titan_x5_hyper_alu
 * Description: Performs operations on 1024-bit Hypervectors, processing 64 bits/cycle.
 * Operations supported:
 *  0: Binding (XOR)
 *  1: Bundling (Majority Vote of 3)
 *  2: Permutation (1-bit cyclic shift of the entire 1024-bit vector)
 */

module titan_x5_hyper_alu (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input wire [1:0] op, // 0: Bind, 1: Bundle, 2: Permute
    input wire [63:0] hv_a,
    input wire [63:0] hv_b,
    input wire [63:0] hv_c,
    output reg [63:0] hv_out,
    output reg         valid_out,
    output reg         done
);

    (* ram_style="block" *) reg [63:0] mem_a [0:15];
    (* ram_style="block" *) reg [63:0] mem_b [0:15];
    (* ram_style="block" *) reg [63:0] mem_c [0:15];

    reg [1:0]  state;
    reg [3:0]  idx;
    reg [1:0]  latched_op;

    localparam IDLE        = 2'd0;
    localparam LOAD        = 2'd1;
    localparam PROCESS     = 2'd2;
    localparam OUTPUT_LAST = 2'd3;

    wire [63:0] a_val  = mem_a[idx];
    wire [63:0] b_val  = mem_b[idx];
    wire [63:0] c_val  = mem_c[idx];
    // for 1-bit left rotate across the entire 1024-bit vector
    wire [63:0] a_prev = (idx == 4'd0) ? mem_a[15] : mem_a[idx - 1];

    reg [63:0] res;
    always @(*) begin
        case (latched_op)
            2'd0: res = a_val ^ b_val;                                      // bind
            2'd1: res = (a_val & b_val) | (b_val & c_val) | (a_val & c_val); // bundle
            2'd2: res = {a_val[62:0], a_prev[63]};                          // permute
            default: res = 64'd0;
        endcase
    end

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            idx        <= 4'd0;
            valid_out  <= 1'b0;
            done       <= 1'b0;
            hv_out     <= 64'd0;
            latched_op <= 2'd0;
            for (i = 0; i < 16; i = i + 1) begin
                mem_a[i] <= 64'd0;
                mem_b[i] <= 64'd0;
                mem_c[i] <= 64'd0;
            end
        end else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    done      <= 1'b0;
                    if (start) begin
                        state      <= LOAD;
                        latched_op <= op;
                        mem_a[0]   <= hv_a;
                        mem_b[0]   <= hv_b;
                        mem_c[0]   <= hv_c;
                        idx        <= 4'd1;
                    end
                end
                
                LOAD: begin
                    mem_a[idx] <= hv_a;
                    mem_b[idx] <= hv_b;
                    mem_c[idx] <= hv_c;
                    if (idx == 4'd15) begin
                        state <= PROCESS;
                        idx   <= 4'd0;
                    end else begin
                        idx   <= idx + 1'b1;
                    end
                end
                
                PROCESS: begin
                    hv_out    <= res;
                    valid_out <= 1'b1;
                    if (idx == 4'd15) begin
                        state <= OUTPUT_LAST;
                        done  <= 1'b1;
                    end else begin
                        idx   <= idx + 1'b1;
                        done  <= 1'b0;
                    end
                end
                
                OUTPUT_LAST: begin
                    valid_out <= 1'b0;
                    done      <= 1'b0;
                    state     <= IDLE;
                end
            endcase
        end
    end

endmodule
