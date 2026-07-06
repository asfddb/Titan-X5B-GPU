// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X5-B GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns/1ps
`default_nettype none

// module: astra8_entanglement_router
// project: project astra-8
// description: photonic entanglement-swapping router (pesr) simulation model.
//              simulates a centralized spontaneous parametric down-conversion
//              (SPDC) pump distributing EPR pairs and performs instantaneous
//              tensor teleportation via homodyne Bell-state measurement logic.
//
// cycle 18 changelog:
//   [OPT]  Simplified the watchdog mechanism by eliminating the secondary 
//          `watchdog_sub_counter` register, tracking both the idle time and 
//          periodic warning triggers using a single self-resetting counter.
//   [OPT]  Introduced an explicit 32-bit `safe_dst_offset` wire to handle index
//          multiplication, ensuring clean, warning-free synthesis and simulation 
//          for large node counts or payload widths.
//   [DBG]  Added simulation-only active checks for out-of-bounds or self-looping
//          teleportation requests, logging errors to accelerate stimulus debugging.

module astra8_entanglement_router #(
    parameter NUM_NODES      = 4,
    parameter PAYLOAD_WIDTH  = 256,
    // auto-derived. override only for explicit width-padding use cases.
    parameter NODE_ADDR_W    = (NUM_NODES <= 1)    ? 1 :
                               (NUM_NODES <= 2)    ? 1 :
                               (NUM_NODES <= 4)    ? 2 :
                               (NUM_NODES <= 8)    ? 3 :
                               (NUM_NODES <= 16)   ? 4 :
                               (NUM_NODES <= 32)   ? 5 :
                               (NUM_NODES <= 64)   ? 6 :
                               (NUM_NODES <= 128)  ? 7 :
                               (NUM_NODES <= 256)  ? 8 :
                               (NUM_NODES <= 512)  ? 9 :
                               (NUM_NODES <= 1024) ? 10 :
                               (NUM_NODES <= 2048) ? 11 :
                               (NUM_NODES <= 4096) ? 12 : 16
)(
    input  wire                                 clk,
    input  wire                                 rst_n,

    // spdc pump interface (epr pair distribution)
    input  wire                                 spdc_pump_en,
    output reg [NUM_NODES-1:0] entanglement_ready,

    // teleportation interface (homodyne bell-state measurement)
    input wire [NUM_NODES-1:0] bell_state_meas_req,
    input wire [NODE_ADDR_W-1:0] src_node,
    input wire [NODE_ADDR_W-1:0] dst_node,
    input wire [PAYLOAD_WIDTH-1:0] data_in,

    // teleported data out (flattened bus per node) — combinational
    output wire [(NUM_NODES*PAYLOAD_WIDTH)-1:0] data_out,

    // status / diagnostic
    // teleport_active is HIGH on the SAME cycle data_out carries valid payload.
    output wire                                 teleport_active
);

    // parameter validation (simulation only)
`ifndef SYNTHESIS
    initial begin
        if (NUM_NODES < 2) begin
            $display("FATAL [%m]: NUM_NODES (%0d) must be >= 2 for teleportation.", NUM_NODES);
            $finish;
        end
        if (PAYLOAD_WIDTH < 1) begin
            $display("FATAL [%m]: PAYLOAD_WIDTH (%0d) must be >= 1.", PAYLOAD_WIDTH);
            $finish;
        end
        // ensure address width can represent all node indices [0, num_nodes-1]
        if (((NUM_NODES - 1) >> NODE_ADDR_W) != 0) begin
            $display("FATAL [%m]: NODE_ADDR_W (%0d) too small for NUM_NODES (%0d).", NODE_ADDR_W, NUM_NODES);
            $finish;
        end
        // warn if address space is much larger than node count (waste)
        if ((1 << NODE_ADDR_W) > (NUM_NODES * 2)) begin
            $display("WARN [%m]: NODE_ADDR_W (%0d) is overprovisioned for NUM_NODES (%0d).", NODE_ADDR_W, NUM_NODES);
        end
    end
`endif

    // bounds-safe node verification & validation lookups
    wire src_in_bounds = (src_node < NUM_NODES);
    wire dst_in_bounds = (dst_node < NUM_NODES);

    // safe clamped indices for internal array/vector lookups
    wire [NODE_ADDR_W-1:0] safe_src_node = src_in_bounds ? src_node : {NODE_ADDR_W{1'b0}};
    wire [NODE_ADDR_W-1:0] safe_dst_node = dst_in_bounds ? dst_node : {NODE_ADDR_W{1'b0}};

    // explicit offset calculation is no longer needed due to generate-based multiplexing.

    // dynamic indexing is bounds-safe; returns 0 if index is out-of-bounds or invalid.
    wire src_valid = src_in_bounds & entanglement_ready[safe_src_node] & bell_state_meas_req[safe_src_node];
    wire dst_valid = dst_in_bounds & entanglement_ready[safe_dst_node] & bell_state_meas_req[safe_dst_node];

    // teleportation activation logic
    wire distinct_nodes = (safe_src_node != safe_dst_node);
    wire teleport_valid = distinct_nodes & src_valid & dst_valid;

    // spdc pump + teleport consumption: atomic compose
    wire [NUM_NODES-1:0] consumed_mask;
    generate
        genvar j;
        for (j = 0; j < NUM_NODES; j = j + 1) begin : gen_consumed_mask_bit
            assign consumed_mask[j] = teleport_valid && ((safe_src_node == j) || (safe_dst_node == j));
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            entanglement_ready <= {NUM_NODES{1'b0}};
        end else begin
            // atomic: consume then replenish (or hold). allows back-to-back transactions.
            entanglement_ready <= (entanglement_ready & ~consumed_mask) | {NUM_NODES{spdc_pump_en}};
        end
    end

    // teleport status — combinational, aligned with data_out
    assign teleport_active = teleport_valid;

    // procedural teleportation datapath (combinational demux)
    generate
        genvar i;
        for (i = 0; i < NUM_NODES; i = i + 1) begin : gen_data_out_mux
            assign data_out[i*PAYLOAD_WIDTH +: PAYLOAD_WIDTH] = 
                (teleport_valid && (safe_dst_node == i)) ? data_in : {PAYLOAD_WIDTH{1'b0}};
        end
    endgenerate

    // simulation-only telemetry, diagnostics & watchdog
`ifndef SYNTHESIS
    reg [31:0] teleport_count;
    reg [31:0] pump_count;
    reg [31:0] idle_watchdog;

    localparam [31:0] WATCHDOG_THRESHOLD = 32'd100_000;
    localparam [31:0] COUNTER_SAT        = 32'hFFFF_FFFF;

    initial begin
        teleport_count       = 32'd0;
        pump_count           = 32'd0;
        idle_watchdog        = 32'd0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            teleport_count       <= 32'd0;
            pump_count           <= 32'd0;
            idle_watchdog        <= 32'd0;
        end else begin
            // pump event counter (saturating)
            if (spdc_pump_en && pump_count != COUNTER_SAT) begin
                pump_count <= pump_count + 32'd1;
            end

            if (teleport_valid) begin
                // teleport event counter (saturating)
                if (teleport_count != COUNTER_SAT)
                    teleport_count <= teleport_count + 32'd1;
                
                idle_watchdog        <= 32'd0;

                // detailed per-teleport logging
                $display("[%0t] PESR: Teleport #%0d | src=%0d -> dst=%0d | data=0x%h",
                         $time, teleport_count + 32'd1, safe_src_node, safe_dst_node, data_in);
            end else begin
                // idle watchdog counter: reset periodically to prevent rollover/spam
                if (idle_watchdog == WATCHDOG_THRESHOLD - 32'd1) begin
                    idle_watchdog <= 32'd0;
                    $display("WARN [%m] [%0t]: No teleportation for %0d cycles. Check stimulus.",
                             $time, WATCHDOG_THRESHOLD);
                end else begin
                    idle_watchdog <= idle_watchdog + 32'd1;
                end
            end
        end
    end

    // simulation-only checks for invalid stimulus. The sensitivity list
    // includes the async reset so rst_n is used consistently as an
    // asynchronous net (mixed sync/async use trips Verilator SYNCASYNCNET);
    // the body still only checks while out of reset on clock edges.
    always @(posedge clk or negedge rst_n) begin
        if (rst_n) begin
            if (bell_state_meas_req != {NUM_NODES{1'b0}}) begin
                if (!src_in_bounds) begin
                    $display("ERROR [%m] [%0t]: Teleportation request with out-of-bounds src_node (%0d). NUM_NODES=%0d",
                             $time, src_node, NUM_NODES);
                end else if (!dst_in_bounds) begin
                    $display("ERROR [%m] [%0t]: Teleportation request with out-of-bounds dst_node (%0d). NUM_NODES=%0d",
                             $time, dst_node, NUM_NODES);
                end else if (src_node == dst_node) begin
                    if (bell_state_meas_req[safe_src_node]) begin
                        $display("ERROR [%m] [%0t]: Teleportation request with src_node == dst_node (%0d).",
                                 $time, src_node);
                    end
                end
            end
        end
    end
`endif

endmodule

`default_nettype wire
