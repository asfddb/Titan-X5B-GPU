// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module tb_titan_x6_cluster;

    reg clk;
    reg rst_n;
    
    // Die 0 Control
    reg        d0_ctrl_en;
    reg        d0_ctrl_mode;
    reg        d0_photonics_en;
    reg [31:0] d0_photonics_data;
    reg        d0_photonics_valid;
    
    // Die 1 Control
    reg        d1_ctrl_en;
    reg        d1_ctrl_mode;
    reg        d1_photonics_en;
    reg [31:0] d1_photonics_data;
    reg        d1_photonics_valid;

    // UCIe Physical Link between Die 0 and Die 1
    wire [15:0] link_d0_to_d1;
    wire [15:0] link_d1_to_d0;
    
    // Outputs
    wire         d0_tensor_valid;
    wire [511:0] d0_tensor_acc_out;
    wire         d0_hdc_match_valid;
    wire [15:0]  d0_hdc_confidence;
    wire         d0_hdc_is_match;

    wire         d1_tensor_valid;
    wire [511:0] d1_tensor_acc_out;
    wire         d1_hdc_match_valid;
    wire [15:0]  d1_hdc_confidence;
    wire         d1_hdc_is_match;

    // -------------------------------------------------------------
    // Instantiate Die 0 (Master Node)
    // -------------------------------------------------------------
    titan_x6_top u_die0 (
        .clk              (clk),
        .rst_n            (rst_n),
        .ctrl_en          (d0_ctrl_en),
        .ctrl_mode        (d0_ctrl_mode),
        .ucie_tx_lanes    (link_d0_to_d1),
        .ucie_rx_lanes    (link_d1_to_d0),
        .photonics_en     (d0_photonics_en),
        .photonics_data   (d0_photonics_data),
        .photonics_valid  (d0_photonics_valid),
        .tensor_valid     (d0_tensor_valid),
        .tensor_acc_out   (d0_tensor_acc_out),
        .hdc_match_valid  (d0_hdc_match_valid),
        .hdc_confidence   (d0_hdc_confidence),
        .hdc_is_match     (d0_hdc_is_match)
    );

    // -------------------------------------------------------------
    // Instantiate Die 1 (Slave Node)
    // -------------------------------------------------------------
    titan_x6_top u_die1 (
        .clk              (clk),
        .rst_n            (rst_n),
        .ctrl_en          (d1_ctrl_en),
        .ctrl_mode        (d1_ctrl_mode),
        .ucie_tx_lanes    (link_d1_to_d0),
        .ucie_rx_lanes    (link_d0_to_d1),
        .photonics_en     (d1_photonics_en),
        .photonics_data   (d1_photonics_data),
        .photonics_valid  (d1_photonics_valid),
        .tensor_valid     (d1_tensor_valid),
        .tensor_acc_out   (d1_tensor_acc_out),
        .hdc_match_valid  (d1_hdc_match_valid),
        .hdc_confidence   (d1_hdc_confidence),
        .hdc_is_match     (d1_hdc_is_match)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        $dumpfile("titan_x6_cluster.vcd");
        $dumpvars(0, tb_titan_x6_cluster);
        
        $display("==================================================");
        $display("   TITAN X6 INFINITY CLUSTER SIMULATION START     ");
        $display("==================================================");

        clk = 0;
        rst_n = 0;
        
        d0_ctrl_en = 0; d0_ctrl_mode = 0; d0_photonics_en = 0; d0_photonics_data = 0; d0_photonics_valid = 0;
        d1_ctrl_en = 0; d1_ctrl_mode = 0; d1_photonics_en = 0; d1_photonics_data = 0; d1_photonics_valid = 0;
        
        #20 rst_n = 1;
        #10;
        
        $display("[%0t] Reset de-asserted. Injecting Photonic Quantum state into Die 0...", $time);
        
        // Feed data to HDC on Die 0 to trigger a transmission across UCIe
        d0_photonics_en = 1;
        d0_photonics_valid = 1;
        d0_photonics_data = 32'hDEADBEEF;
        #10 d0_photonics_valid = 0;
        
        // Enable Die 1 Tensor Core to catch the incoming UCIe flit from Die 0
        d1_ctrl_en = 1; 
        d1_ctrl_mode = 0; // FP8 Matrix Math
        
        #100;
        $display("[%0t] Simulating Die-to-Die cross-fabric communication...", $time);
        
        // Wait for pipeline
        #500;
        
        $display("[%0t] Die 0 HDC Match: %b, Confidence: %0d", $time, d0_hdc_is_match, d0_hdc_confidence);
        
        #100;
        $display("==================================================");
        $display("   TITAN X6 CLUSTER SIMULATION COMPLETE           ");
        $display("==================================================");
        $finish;
    end

endmodule
