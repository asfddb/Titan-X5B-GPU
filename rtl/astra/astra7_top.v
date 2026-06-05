`timescale 1fs/1fs

/*
 * Module: astra7_top
 * Description: 
 *   The Top-Level Astra-7 Quantum-Photonic Holographic Architecture.
 *   Integrates the MZI Optical MAC grid, the Holographic HDC, and 
 *   the 3D Photonic TSVs.
 */

module astra7_top #(
    parameter GRID_DIM = 64,
    parameter INTENSITY_WIDTH = 16,
    parameter HV_DIM = 100000,
    parameter WDM_CHANNELS = 256
)(
    // input laser source (continuous-time analog power)
    input wire [(GRID_DIM * INTENSITY_WIDTH)-1:0] laser_power_in,
    
    // weight programming (pcm states set via thermal heaters)
    input wire [(GRID_DIM * GRID_DIM * INTENSITY_WIDTH)-1:0] pcm_weights,
    
    // 3D TSV Interconnect (Vertical Photonic Uplink/Downlink)
    input wire [(WDM_CHANNELS * INTENSITY_WIDTH)-1:0] tsv_photons_rx,
    output wire [(WDM_CHANNELS * INTENSITY_WIDTH)-1:0] tsv_photons_tx,
    
    // holographic engine pump pulse
    input  wire                  hologram_pump,
    input wire [31:0] electronic_seed,
    
    // output sensor array
    output wire [(GRID_DIM * INTENSITY_WIDTH)-1:0] optical_mac_out,
    output wire [31:0] hologram_bragg_intensity,
    output wire                  hologram_match
);

    // optical systolic array (mach-zehnder interferometers)
    // laser power flows into the array, interferes passively, and emerges instantly.
    wire [(GRID_DIM * INTENSITY_WIDTH)-1:0] mac_photodetector_out;
    
    astra7_optical_mac_grid #(
        .GRID_DIM(GRID_DIM),
        .INTENSITY_WIDTH(INTENSITY_WIDTH)
    ) u_optical_mac (
        .laser_input_intensity(laser_power_in),
        .pcm_weight_states(pcm_weights),
        .photodetector_output_intensity(mac_photodetector_out)
    );
    
    assign optical_mac_out = mac_photodetector_out;

    // 3D Free-Space Photonic TSV Interconnect
    // we shoot the output of the optical mac directly up through the silicon 
    // to the next die using WDM.
    assign tsv_photons_tx = { {(WDM_CHANNELS - GRID_DIM){16'b0}}, mac_photodetector_out };

    // holographic hyper-dimensional computing engine
    astra7_holographic_hdc #(
        .HV_DIM(HV_DIM),
        .DATA_WIDTH(32)
    ) u_holographic_hdc (
        .optical_pump_pulse(hologram_pump),
        .electronic_seed(electronic_seed),
        .bragg_diffraction_intensity(hologram_bragg_intensity),
        .is_resonant_match(hologram_match)
    );

endmodule
