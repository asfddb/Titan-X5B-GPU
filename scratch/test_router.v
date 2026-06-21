`timescale 1ns/1ps
`default_nettype none

// ==============================================================================
// Module: astra8_entanglement_router
// Project: Project Astra-8
// Description: Photonic Entanglement-Swapping Router (PESR) simulation model.
//              Simulates a centralized Spontaneous Parametric Down-Conversion
//              (SPDC) pump distributing EPR pairs and performs instantaneous
//              tensor teleportation via homodyne Bell-state measurement logic.
// ==============================================================================

module astra8_entanglement_router #(
    parameter NUM_NODES      = 4,
    parameter PAYLOAD_WIDTH  = 256,
    // Auto-derived. Override only for explicit width-padding use cases.
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

    // SPDC Pump Interface (EPR Pair Distribution)
    input  wire                                 spdc_pump_en,
    output reg  [NUM_NODES-1:0]                 entanglement_ready,

    // Teleportation Interface (Homodyne Bell-state Measurement)
    input  wire [NUM_NODES-1:0]                 bell_state_meas_req,
    input  wire [NODE_ADDR_W-1:0]               src_node,
    input  wire [NODE_ADDR_W-1:0]               dst_node,
    input  wire [PAYLOAD_WIDTH-1:0]             data_in,

    // Teleported Data Out (Flattened bus per Node) — combinational
    output wire [(NUM_NODES*PAYLOAD_WIDTH)-1:0] data_out,

    // Status / Diagnostic
    // teleport_active is HIGH on the SAME cycle data_out carries valid payload.
    output wire                                 teleport_active
);

    // --------------------------------------------------------------------------
    // Parameter Validation (Simulation Only)
    // --------------------------------------------------------------------------
    // synthesis translate_off
    initial begin
        if (NUM_NODES < 2) begin
            $display("FATAL [%m]: NUM_NODES (%0d) must be >= 2 for teleportation.", NUM_NODES);
            $finish;
        end
        if (PAYLOAD_WIDTH < 1) begin
            $display("FATAL [%m]: PAYLOAD_WIDTH (%0d) must be >= 1.", PAYLOAD_WIDTH);
            $finish;
        end
        // Ensure address width can represent all node indices [0, NUM_NODES-1]
        if (((NUM_NODES - 1) >> NODE_ADDR_W) != 0) begin
            $display("FATAL [%m]: NODE_ADDR_W (%0d) too small for NUM_NODES (%0d).", NODE_ADDR_W, NUM_NODES);
            $finish;
        end
        // Warn if address space is much larger than node count (waste)
        if ((1 << NODE_ADDR_W) > (NUM_NODES * 2)) begin
            $display("WARN [%m]: NODE_ADDR_W (%0d) is overprovisioned for NUM_NODES (%0d).", NODE_ADDR_W, NUM_NODES);
        end
    end
    // synthesis translate_on

    // --------------------------------------------------------------------------
    // Vectorized Node Decoding & Bounds-Safe Masking
    // --------------------------------------------------------------------------
    // Shift is sized to NUM_NODES bits to prevent zero-replication syntax error in Verilog-2001
    wire [NUM_NODES-1:0] src_dec = ({{NUM_NODES{1'b0}}} | 1'b1) << src_node;
    wire [NUM_NODES-1:0] dst_dec = ({{NUM_NODES{1'b0}}} | 1'b1) << dst_node;

    // Combined readiness-and-request mask, computed once for fanout.
    wire [NUM_NODES-1:0] node_ready_req = entanglement_ready & bell_state_meas_req;

    // Bitwise-reduce through masks: bounds-safe (no X on out-of-range index).
    wire src_valid = |(node_ready_req & src_dec);
    wire dst_valid = |(node_ready_req & dst_dec);

    // --------------------------------------------------------------------------
    // Teleportation Activation Logic
    // --------------------------------------------------------------------------
    // Using standard != inequality for strict synthesizability.
    wire distinct_nodes = (src_node != dst_node);
    wire teleport_valid = distinct_nodes & src_valid & dst_valid;

    // --------------------------------------------------------------------------
    // SPDC Pump + Teleport Consumption: Atomic Compose
    // --------------------------------------------------------------------------
    wire [NUM_NODES-1:0] consumed_mask = (src_dec | dst_dec) & {NUM_NODES{teleport_valid}};
    wire [NUM_NODES-1:0] pump_state    = entanglement_ready | {NUM_NODES{spdc_pump_en}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            entanglement_ready <= {NUM_NODES{1'b0}};
        end else begin
            // Atomic: replenish (or hold), then consume. Single write per cycle.
            entanglement_ready <= pump_state & ~consumed_mask;
        end
    end

    // --------------------------------------------------------------------------
    // Teleport Status — combinational, aligned with data_out
    // --------------------------------------------------------------------------
    assign teleport_active = teleport_valid;

    // --------------------------------------------------------------------------
    // Vectorized Teleportation Datapath (Combinational)
    // --------------------------------------------------------------------------
    genvar g;
    generate
        for (g = 0; g < NUM_NODES; g = g + 1) begin : gen_data_out
            assign data_out[g*PAYLOAD_WIDTH +: PAYLOAD_WIDTH] = {PAYLOAD_WIDTH{dst_dec[g] & teleport_valid}} & data_in;
        end
    endgenerate

    // --------------------------------------------------------------------------
    // Simulation-Only Telemetry & Watchdog
    // --------------------------------------------------------------------------
    // synthesis translate_off
    reg [31:0] teleport_count;
    reg [31:0] pump_count;
    reg [31:0] idle_watchdog;
    reg [31:0] watchdog_sub_counter;

    localparam [31:0] WATCHDOG_THRESHOLD = 32'd100_000;
    localparam [31:0] COUNTER_SAT        = 32'hFFFF_FFFF;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            teleport_count       <= 32'd0;
            pump_count           <= 32'd0;
            idle_watchdog        <= 32'd0;
            watchdog_sub_counter <= 32'd0;
        end else begin
            // Pump event counter (saturating)
            if (spdc_pump_en && pump_count != COUNTER_SAT) begin
                pump_count <= pump_count + 32'd1;
            end

            if (teleport_valid) begin
                // Teleport event counter (saturating)
                if (teleport_count != COUNTER_SAT)
                    teleport_count <= teleport_count + 32'd1;
                
                idle_watchdog        <= 32'd0;
                watchdog_sub_counter <= 32'd0;

                // Detailed per-teleport logging
                $display("[%0t] PESR: Teleport #%0d | src=%0d -> dst=%0d | data=0x%h",
                         $time, teleport_count + 32'd1, src_node, dst_node, data_in);
            end else begin
                // Idle watchdog counter: saturate to prevent rollover re-trigger
                if (idle_watchdog != COUNTER_SAT) begin
                    idle_watchdog <= idle_watchdog + 32'd1;
                    if (watchdog_sub_counter == WATCHDOG_THRESHOLD - 32'd1) begin
                        watchdog_sub_counter <= 32'd0;
                        $display("WARN [%m] [%0t]: No teleportation for %0d cycles. Check stimulus.",
                                 $time, idle_watchdog + 32'd1);
                    end else begin
                        watchdog_sub_counter <= watchdog_sub_counter + 32'd1;
                    end
                end
            end
        end
    end
    // synthesis translate_on

endmodule

`default_nettype wire
