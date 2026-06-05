`timescale 1ns / 1ps

/*
 * Module: titan_x5_power_mgmt
 * Description: DVFS controller (P0-P3 states) and per-SM clock gating logic.
 */
module titan_x5_power_mgmt #(
    parameter NUM_SM = 4 // Number of Streaming Multiprocessors
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // DVFS Request Interface
    input  wire [1:0]  req_p_state,    // 0: P0 (Max), 1: P1, 2: P2, 3: P3 (Min)
    input  wire        req_p_valid,
    output reg         ack_p_state,
    
    // Clock gating interface
    input  wire [NUM_SM-1:0] sm_idle_mask,
    output reg  [NUM_SM-1:0] sm_cg_en, // Clock Gate Enable (1 = Active, 0 = Gated)
    
    // Output voltage/freq controls to PLL/VRM
    output reg  [7:0]  vrm_vid,
    output reg  [7:0]  pll_div
);

    // P-State mappings
    localparam V_P0 = 8'hFF; localparam F_P0 = 8'h01; // Max Voltage/Freq
    localparam V_P1 = 8'hC0; localparam F_P1 = 8'h02;
    localparam V_P2 = 8'h80; localparam F_P2 = 8'h04;
    localparam V_P3 = 8'h40; localparam F_P3 = 8'h08; // Min Voltage/Freq

    reg [1:0] current_p_state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_p_state <= 2'b00; // Start at P0
            vrm_vid <= V_P0;
            pll_div <= F_P0;
            ack_p_state <= 1'b0;
            sm_cg_en <= {NUM_SM{1'b1}};
        end else begin
            // DVFS Handling
            if (req_p_valid) begin
                current_p_state <= req_p_state;
                case (req_p_state)
                    2'b00: begin vrm_vid <= V_P0; pll_div <= F_P0; end
                    2'b01: begin vrm_vid <= V_P1; pll_div <= F_P1; end
                    2'b10: begin vrm_vid <= V_P2; pll_div <= F_P2; end
                    2'b11: begin vrm_vid <= V_P3; pll_div <= F_P3; end
                endcase
                ack_p_state <= 1'b1;
            end else begin
                ack_p_state <= 1'b0;
            end
            
            // SM Clock Gating: Gate clock if SM is idle
            // sm_cg_en is 1 when active (not gated)
            sm_cg_en <= ~sm_idle_mask;
        end
    end

endmodule
