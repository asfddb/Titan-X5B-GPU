`timescale 1ns / 1ps

// =============================================================================
// Module: titan_x_3nm_gaafet_optimizer
// Project: Titan X5-B GPU
// License: CERN-OHL-S-2.0 (OSS) / Commercial (see LICENSE)
// Author:  Adhiraj (@asfddb)
// =============================================================================
//
//  Titan X-Infinity: 3nm GAAFET Power & Clock Optimizer
//
//  At TSMC 3nm (N3E), leakage power and thermal density are extreme.
//  This module dynamically gates the clock and applies Power Island
//  isolation to inactive SM regions to maintain the 5.5 GHz target
//  without thermal runaway.
//
// =============================================================================
//
//  BUGFIX HISTORY:
//
//  Original version used UNPACKED ARRAY PORTS, e.g.:
//
//      input wire [7:0] thermal_sensors [0:ISLAND_COUNT-1],
//      input wire [7:0] core_utilization [0:ISLAND_COUNT-1],
//
//  Yosys `read_verilog -sv` does NOT support unpacked array ports.
//  This caused the entire expanded synthesis run to fail with:
//
//      rtl/titan_x_3nm_gaafet_optimizer.v:18: ERROR: syntax error,
//      unexpected '[', expecting ')' or ',' or '='
//
//  FIX: Replace unpacked array ports with PACKED buses, and use
//  indexed part-select `[i*8 +: 8]` for per-element access. This is
//  fully synthesizable on Yosys, Verilator, Vivado, and all major
//  commercial tools.
//
//  Before:
//      thermal_sensors[i]                 // unpacked array element
//      core_utilization[i]                // unpacked array element
//
//  After:
//      thermal_sensors[i*8 +: 8]          // packed slice
//      core_utilization[i*8 +: 8]         // packed slice
//
//  API NOTE: Any module instantiating titan_x_3nm_gaafet_optimizer
//  must also update its port connections. If the parent previously
//  had individual `wire [7:0] temp_island0, temp_island1, ...;` it
//  should now concatenate them into a single packed bus:
//
//      wire [ISLAND_COUNT*8-1:0] thermal_bus;
//      genvar i;
//      generate
//          for (i = 0; i < ISLAND_COUNT; i = i + 1) begin
//              assign thermal_bus[i*8 +: 8] = thermal_per_island[i];
//          end
//      endgenerate
//
//      titan_x_3nm_gaafet_optimizer #(.ISLAND_COUNT(ISLAND_COUNT)) inst (
//          .clk_in(clk),
//          .rst_n(rst_n),
//          .thermal_sensors(thermal_bus),
//          .core_utilization(util_bus),
//          .gated_clocks(gated_clks),
//          .pwr_enables(pwr_en),
//          .throttle_global(throttle)
//      );
//
// =============================================================================

module titan_x_3nm_gaafet_optimizer #(
    parameter ISLAND_COUNT = 64
)(
    input  wire clk_in,
    input  wire rst_n,

    // thermal sensors from the physical silicon (simulated)
    // packed: 64 islands * 8 bits = 512 bits per bus
    input  wire [ISLAND_COUNT*8-1:0] thermal_sensors,

    // utilization metrics from noc (packed)
    input  wire [ISLAND_COUNT*8-1:0] core_utilization,

    // gated clocks distributed to the 2d mesh islands
    output wire [ISLAND_COUNT-1:0] gated_clocks,

    // power gating enables (0 = power down island)
    output reg  [ISLAND_COUNT-1:0] pwr_enables,

    // global throttling signal if entire wafer approaches tjunction max
    output reg  throttle_global
);

    integer i;
    reg [ISLAND_COUNT-1:0] clk_enables;

    // thermal limit for 3nm gaafet (approx 95c before throttling)
    localparam THERMAL_LIMIT  = 8'd95;
    // power down if under 5% util
    localparam UTIL_THRESHOLD = 8'd5;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            pwr_enables     <= {ISLAND_COUNT{1'b1}};
            clk_enables     <= {ISLAND_COUNT{1'b1}};
            throttle_global <= 1'b0;
        end else begin
            throttle_global <= 1'b0;

            for (i = 0; i < ISLAND_COUNT; i = i + 1) begin
                // thermal throttling: cut clock if too hot
                // NOTE: indexed part-select [i*8 +: 8] is the
                // Yosys-safe replacement for the old
                // thermal_sensors[i] unpacked array access.
                if (thermal_sensors[i*8 +: 8] >= THERMAL_LIMIT) begin
                    clk_enables[i]     <= 1'b0;
                    throttle_global    <= 1'b1; // signal global thermal pressure
                end else begin
                    // clock gating logic: enable only if utilized
                    clk_enables[i] <= (core_utilization[i*8 +: 8] > 8'd0);
                end

                // deep sleep power gating: cut vdd if idle for prolonged period
                if (core_utilization[i*8 +: 8] < UTIL_THRESHOLD &&
                    thermal_sensors[i*8 +: 8]   < 8'd50) begin
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
            // in a real 3nm physical flow, this instantiates a tsmc
            // standard cell (e.g., ckgt_n3). in the meantime, a simple
            // AND gate is used for simulation and FPGA targets.
            assign gated_clocks[g] = clk_in & clk_enables[g];
        end
    endgenerate

endmodule


// =============================================================================
// SANITY CHECK / SELF-TEST (optional, for simulation only)
// =============================================================================
//
//  To verify this module synthesizes cleanly, run:
//
//      yosys -p "
//          read_verilog -sv rtl/titan_x_3nm_gaafet_optimizer.v;
//          synth -top titan_x_3nm_gaafet_optimizer;
//          stat
//      "
//
//  Expected output: clean synth, no errors. Statistics will show
//  ~ISLAND_COUNT flip-flops for clk_enables + pwr_enables, plus
//  combinational logic for the comparisons.
//
// =============================================================================
