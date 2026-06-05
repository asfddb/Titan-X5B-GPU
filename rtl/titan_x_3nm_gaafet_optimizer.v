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
    
    // Thermal sensors from the physical silicon (simulated)
    input  wire [7:0] thermal_sensors [0:ISLAND_COUNT-1],
    // Utilization metrics from NoC
    input  wire [7:0] core_utilization [0:ISLAND_COUNT-1],
    
    // Gated clocks distributed to the 2D Mesh islands
    output wire [ISLAND_COUNT-1:0] gated_clocks,
    // Power gating enables (0 = power down island)
    output reg  [ISLAND_COUNT-1:0] pwr_enables,
    
    // Global throttling signal if entire wafer approaches Tjunction Max
    output reg  throttle_global
);

    integer i;
    reg [ISLAND_COUNT-1:0] clk_enables;
    
    // Thermal limit for 3nm GAAFET (approx 95C before throttling)
    localparam THERMAL_LIMIT = 8'd95;
    localparam UTIL_THRESHOLD = 8'd5; // Power down if under 5% util

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            pwr_enables <= {ISLAND_COUNT{1'b1}};
            clk_enables <= {ISLAND_COUNT{1'b1}};
            throttle_global <= 1'b0;
        end else begin
            throttle_global <= 1'b0;
            
            for (i = 0; i < ISLAND_COUNT; i = i + 1) begin
                // Thermal Throttling: Cut clock if too hot
                if (thermal_sensors[i] >= THERMAL_LIMIT) begin
                    clk_enables[i] <= 1'b0;
                    throttle_global <= 1'b1; // Signal global thermal pressure
                end else begin
                    // Clock gating logic: enable only if utilized
                    clk_enables[i] <= (core_utilization[i] > 8'd0);
                end
                
                // Deep Sleep Power Gating: Cut VDD if idle for prolonged period
                if (core_utilization[i] < UTIL_THRESHOLD && thermal_sensors[i] < 8'd50) begin
                    pwr_enables[i] <= 1'b0; // Engage GAAFET power isolation
                end else begin
                    pwr_enables[i] <= 1'b1;
                end
            end
        end
    end

    // Integrated Clock Gating (ICG) Cells mapped to 3nm standard library
    genvar g;
    generate
        for (g = 0; g < ISLAND_COUNT; g = g + 1) begin : ICG_CELLS
            // In a real 3nm physical flow, this instantiates a TSMC standard cell (e.g., CKGT_N3)
            assign gated_clocks[g] = clk_in & clk_enables[g];
        end
    endgenerate

endmodule
