`timescale 1ns/1ps

/*
 * Titan X-Infinity: 3nm GAAFET Power & Clock Optimizer
 * 
 * At TSMC 3nm (N3E), leakage power and thermal density are extreme.
 * This module dynamically gates the clock and applies Power Island
 * isolation to inactive SM regions to maintain the 5.5 GHz target
 * without thermal runaway.
 */
module titan_x_3nm_gaafet_optimizer #(
    parameter ISLAND_COUNT = 64
)(
    input  wire clk_in,
    input  wire rst_n,
    
    // thermal sensors from the physical silicon (simulated)
    input wire [7:0] thermal_sensors [0:ISLAND_COUNT-1],
    // utilization metrics from noc
    input wire [7:0] core_utilization [0:ISLAND_COUNT-1],
    
    // gated clocks distributed to the 2d mesh islands
    output wire [ISLAND_COUNT-1:0] gated_clocks,
    // power gating enables (0 = power down island)
    output reg [ISLAND_COUNT-1:0] pwr_enables,
    
    // global throttling signal if entire wafer approaches tjunction max
    output reg  throttle_global
);

    integer i;
    reg [ISLAND_COUNT-1:0] clk_enables;
    
    // thermal limit for 3nm gaafet (approx 95c before throttling)
    localparam THERMAL_LIMIT = 8'd95;
    localparam UTIL_THRESHOLD = 8'd5; // power down if under 5% util

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            pwr_enables <= {ISLAND_COUNT{1'b1}};
            clk_enables <= {ISLAND_COUNT{1'b1}};
            throttle_global <= 1'b0;
        end else begin
            throttle_global <= 1'b0;
            
            for (i = 0; i < ISLAND_COUNT; i = i + 1) begin
                // thermal throttling: cut clock if too hot
                if (thermal_sensors[i] >= THERMAL_LIMIT) begin
                    clk_enables[i] <= 1'b0;
                    throttle_global <= 1'b1; // signal global thermal pressure
                end else begin
                    // clock gating logic: enable only if utilized
                    clk_enables[i] <= (core_utilization[i] > 8'd0);
                end
                
                // deep sleep power gating: cut vdd if idle for prolonged period
                if (core_utilization[i] < UTIL_THRESHOLD && thermal_sensors[i] < 8'd50) begin
                    pwr_enables[i] <= 1'b0; // engage gaafet power isolation
                end else begin
                    pwr_enables[i] <= 1'b1;
                end
            end
        end
    end

    // integrated clock gating (icg) cells mapped to 3nm standard library
    genvar g;
    generate
        for (g = 0; g < ISLAND_COUNT; g = g + 1) begin : ICG_CELLS
            // in a real 3nm physical flow, this instantiates a tsmc standard cell (e.g., ckgt_n3)
            assign gated_clocks[g] = clk_in & clk_enables[g];
        end
    endgenerate

endmodule
