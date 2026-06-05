`timescale 1ns/1ps

module astra8_top #(
    parameter GRID_DIM = 16,
    parameter DATA_WIDTH = 32,
    parameter NUM_NODES = 4
)(
    input  wire clk,
    input  wire rst_n,

    // wetware interface
    input wire [(GRID_DIM*GRID_DIM)-1:0] quantum_thermal_noise,
    
    // metamaterial interface
    input wire [31:0] acoustic_wave_freq,
    input wire [(GRID_DIM*GRID_DIM*2)-1:0] logic_reconfiguration,
    
    // quantum teleportation fabric
    input wire [31:0] teleport_target,
    input wire [DATA_WIDTH-1:0] teleport_payload,
    input  wire trigger_teleport,
    
    // outputs
    output wire [DATA_WIDTH-1:0] rx_teleport_payload,
    output wire [31:0] wetware_glial_tide
);

    // mas fabric (morphogenetic astroglial syncytium)
    wire [(GRID_DIM*GRID_DIM*2)-1:0] glial_gradients;
    
    astra8_mas_wetware #(
        .GRID_X(GRID_DIM),
        .GRID_Y(GRID_DIM),
        .DATA_WIDTH(8)
    ) u_mas_wetware (
        .clk(clk),
        .rst_n(rst_n),
        .enable_slow_tick(1'b1),
        .stimulus_inject(quantum_thermal_noise),
        .routing_modulations(glial_gradients)
    );

    // ptm-bisl (programmable topological metamaterial)
    wire [DATA_WIDTH-1:0] topological_mesh_out;
    wire [(GRID_DIM*GRID_DIM*2)-1:0] lattice_state;
    
    astra8_topological_metamaterial #(
        .LATTICE_NODES(GRID_DIM*GRID_DIM),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_ptm_bisl (
        .clk(clk),
        .rst_n(rst_n),
        .acoustic_wave_freq(acoustic_wave_freq[7:0]),
        .lattice_config_data(logic_reconfiguration),
        .lattice_config_en(1'b1),
        .data_in_a(teleport_payload),
        .data_in_b(teleport_payload),
        .data_out(topological_mesh_out),
        .lattice_state(lattice_state)
    );

    // pesr (photonic entanglement-swapping router)
    wire [NUM_NODES-1:0] ready_vec;
    wire [(NUM_NODES*DATA_WIDTH)-1:0] data_out_flat;
    
    astra8_entanglement_router #(
        .NUM_NODES(NUM_NODES),
        .PAYLOAD_WIDTH(DATA_WIDTH)
    ) u_pesr_fabric (
        .clk(clk),
        .rst_n(rst_n),
        .spdc_pump_en(1'b1),
        .entanglement_ready(ready_vec),
        .bell_state_meas_req({NUM_NODES{trigger_teleport}}),
        .src_node(2'd0),
        .dst_node(teleport_target[1:0]),
        .data_in(topological_mesh_out),
        .data_out(data_out_flat)
    );

    // output assignment
    assign rx_teleport_payload = data_out_flat[teleport_target[1:0] * DATA_WIDTH +: DATA_WIDTH];
    assign wetware_glial_tide = { 24'b0, glial_gradients[7:0] };

endmodule
