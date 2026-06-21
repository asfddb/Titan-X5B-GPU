// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1fs/1fs // femtosecond timescale for optical simulation

/*
 * Module: astra7_optical_mac_grid
 * Description: 
 *   Simulates a monolithic grid of Mach-Zehnder Interferometers (MZIs) and 
 *   Micro-Ring Resonators (MRR) for computing Matrix-Vector Multiplications 
 *   instantaneously in the optical domain.
 *   Unlike electronic MACs, there are no clocked sequential multipliers.
 *   Inputs are continuous-time light intensities. Weights are Phase-Change 
 *   Material (PCM) refractive index shifts.
 */

module astra7_optical_mac_grid #(
    parameter GRID_DIM = 64, // 64x64 optical array
    parameter INTENSITY_WIDTH = 16 // 16-bit analog intensity approximation
)(
    // in an optical chip, there is no master clock for the mac array! 
    // inference occurs continuously.
    
    // light source input (lasers injected at the edge waveguides)
    input wire [(GRID_DIM * INTENSITY_WIDTH)-1:0] laser_input_intensity,
    
    // phase-change material states (programmed slowly via heater electrodes)
    input wire [(GRID_DIM * GRID_DIM * INTENSITY_WIDTH)-1:0] pcm_weight_states,
    
    // photodetector outputs (currents generated at the far end of the waveguide)
    output wire [(GRID_DIM * INTENSITY_WIDTH)-1:0] photodetector_output_intensity
);

    // continuous-time analog simulation (discrete approximation for verilog)
    genvar i, j;
    generate
        for (i = 0; i < GRID_DIM; i = i + 1) begin : g_row
            // the accumulated light intensity exiting the row
            wire [INTENSITY_WIDTH*2-1:0] optical_interference_sum;
            
            // generate the passive interference sum for this row across all columns
            // this happens instantly (0 delay in ideal simulation)
            wire [INTENSITY_WIDTH*2-1:0] partial_interference [0:GRID_DIM];
            assign partial_interference[0] = {INTENSITY_WIDTH*2{1'b0}};
            
            for (j = 0; j < GRID_DIM; j = j + 1) begin : g_col
                wire [INTENSITY_WIDTH-1:0] light_in = laser_input_intensity[j * INTENSITY_WIDTH +: INTENSITY_WIDTH];
                wire [INTENSITY_WIDTH-1:0] pcm_phase = pcm_weight_states[(i * GRID_DIM + j) * INTENSITY_WIDTH +: INTENSITY_WIDTH];
                
                // mzi interference equation (approximated as multiplication for integer simulation)
                // in reality: i_out = i_in * cos^2(delta_phi / 2)
                wire [INTENSITY_WIDTH*2-1:0] interference = light_in * pcm_phase; 
                
                // photons accumulate constructively in the waveguide
                assign partial_interference[j+1] = partial_interference[j] + interference;
            end
            
            // the photodiode converts the final accumulated photons back to an electrical signal
            // saturation logic for the photodiode
            assign photodetector_output_intensity[i * INTENSITY_WIDTH +: INTENSITY_WIDTH] = 
                (partial_interference[GRID_DIM] > {INTENSITY_WIDTH{1'b1}}) ? 
                {INTENSITY_WIDTH{1'b1}} : partial_interference[GRID_DIM][INTENSITY_WIDTH-1:0];
        end
    endgenerate

endmodule
