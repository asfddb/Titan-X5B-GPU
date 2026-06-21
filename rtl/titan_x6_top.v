// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x6_top #(
    parameter TENSOR_DIM = 16,
    parameter DATA_WIDTH = 8,
    parameter ACC_WIDTH  = 32,
    parameter FLIT_WIDTH = 256,
    parameter NUM_LANES  = 16,
    parameter HV_DIM     = 512
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // control interface (simplified mapped registers)
    input  wire                     ctrl_en,
    input  wire                     ctrl_mode, // 0 = FP8, 1 = INT4

    // external chiplet interface (ucie)
    output wire [NUM_LANES-1:0] ucie_tx_lanes,
    input wire [NUM_LANES-1:0] ucie_rx_lanes,

    // photonic sensor interface
    input  wire                     photonics_en,
    input wire [31:0] photonics_data,
    input  wire                     photonics_valid,

    // status / output
    output wire                     tensor_valid,
    output wire [511:0] tensor_acc_out,
    output wire                     hdc_match_valid,
    output wire [15:0] hdc_confidence,
    output wire                     hdc_is_match
);

    // ucie phy instantiation (die-to-die fabric)
    wire                  core_rx_valid;
    wire [FLIT_WIDTH-1:0] core_rx_flit;
    wire                  core_tx_ready;
    
    // for this super-node, we loop back the tensor core output into the tx if needed,
    // but for simplicity in this top level, we tie TX to a dummy stream or forward HDC results.
    wire                  core_tx_valid = hdc_match_valid;
    wire [FLIT_WIDTH-1:0] core_tx_flit  = { {(FLIT_WIDTH-16){1'b0}}, hdc_confidence };

    titan_x6_ucie_phy #(
        .FLIT_WIDTH(FLIT_WIDTH),
        .NUM_LANES(NUM_LANES)
    ) u_ucie_phy (
        .clk            (clk),
        .rst_n          (rst_n),
        .core_tx_valid  (core_tx_valid),
        .core_tx_flit   (core_tx_flit),
        .core_tx_ready  (core_tx_ready),
        .core_rx_valid  (core_rx_valid),
        .core_rx_flit   (core_rx_flit),
        .phy_tx_lanes   (ucie_tx_lanes),
        .phy_rx_lanes   (ucie_rx_lanes)
    );

    // tensor core array (ai matrix compute)
    // we feed the tensor core activations and weights directly from the ucie rx flit!
    // flit is 256 bits: lower 128 = activations, upper 128 = weights.
    wire [(TENSOR_DIM * DATA_WIDTH)-1:0] tc_act_in    = core_rx_flit[127:0];
    wire [(TENSOR_DIM * DATA_WIDTH)-1:0] tc_weight_in = core_rx_flit[255:128];
    
    titan_x6_tensor_core_array #(
        .ARRAY_SIZE_X(TENSOR_DIM),
        .ARRAY_SIZE_Y(TENSOR_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_tensor_core (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (ctrl_en & core_rx_valid), // only compute when we receive a valid flit
        .mode       (ctrl_mode),
        .act_in     (tc_act_in),
        .weight_in  (tc_weight_in),
        .acc_out    (tensor_acc_out),
        .out_valid  (tensor_valid)
    );

    // neuromorphic hdc engine (physics compute)
    // the hdc compares incoming photonic data against a target hypervector.
    // for this integration, we use the tensor core's output (512 bits) as the reference hypervector!
    // this allows ai models to generate dynamic similarity targets.
    
    titan_x6_hdc_photonics #(
        .DATA_WIDTH(32),
        .HV_DIM(HV_DIM),
        .METRIC_WIDTH(16)
    ) u_hdc_engine (
        .clk                (clk),
        .rst_n              (rst_n),
        .photonics_en       (photonics_en),
        .data_in            (photonics_data),
        .data_valid         (photonics_valid),
        .ref_hv             (tensor_acc_out), // dynamic tensor core target
        .match_valid        (hdc_match_valid),
        .confidence_metric  (hdc_confidence),
        .is_match           (hdc_is_match)
    );

endmodule
