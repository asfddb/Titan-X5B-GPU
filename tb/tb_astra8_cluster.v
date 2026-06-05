`timescale 1ns/1ps

module tb_astra8_cluster;

    reg clk;
    reg rst_n;

    // Metamaterial
    reg [31:0] acoustic_wave_freq;
    reg [511:0] logic_reconfiguration;

    // Wetware
    reg [255:0] quantum_thermal_noise;
    
    // Teleportation
    reg [31:0] teleport_target;
    reg [31:0] teleport_payload;
    reg trigger_teleport;
    
    wire [31:0] rx_teleport_payload;
    wire [31:0] wetware_glial_tide;

    astra8_top #(
        .GRID_DIM(16),
        .DATA_WIDTH(32),
        .NUM_NODES(4)
    ) u_godhead (
        .clk(clk),
        .rst_n(rst_n),
        .quantum_thermal_noise(quantum_thermal_noise),
        .acoustic_wave_freq(acoustic_wave_freq),
        .logic_reconfiguration(logic_reconfiguration),
        .teleport_target(teleport_target),
        .teleport_payload(teleport_payload),
        .trigger_teleport(trigger_teleport),
        .rx_teleport_payload(rx_teleport_payload),
        .wetware_glial_tide(wetware_glial_tide)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("astra8_cluster.vcd");
        $dumpvars(0, tb_astra8_cluster);
        
        $display("==================================================");
        $display("   ASTRA-8 GODHEAD MULTIVERSE SIMULATION START    ");
        $display("==================================================");

        clk = 0;
        rst_n = 0;
        acoustic_wave_freq = 0;
        logic_reconfiguration = 0;
        quantum_thermal_noise = 0;
        teleport_target = 0;
        teleport_payload = 0;
        trigger_teleport = 0;

        #20 rst_n = 1;
        
        // 1. Inject Acoustic Wave to rewire Topological Insulator
        #10;
        $display("[%0t] Hitting PTM-BISL with 4096 GHz Acoustic Resonance...", $time);
        acoustic_wave_freq = 32'h0000_1000; 
        logic_reconfiguration = {512{1'b1}}; 
        
        // 2. Allow Biological Wetware to drift
        #100;
        $display("[%0t] Inducing Quantum Thermal Noise into MAS Fabric...", $time);
        quantum_thermal_noise = 256'hDEADBEEF_CAFEBABE;
        
        // 3. Teleport Tensor
        #50;
        $display("[%0t] Performing Bell-State Measurement. Teleporting Payload [0xFAFAFAFA] to Node 3...", $time);
        teleport_target = 3;
        teleport_payload = 32'hFAFAFAFA;
        trigger_teleport = 1;
        #10 trigger_teleport = 0;
        
        #100;
        $display("[%0t] RX Payload Received: 0x%h", $time, rx_teleport_payload);
        $display("[%0t] Wetware Glial Tide Factor: %0d", $time, wetware_glial_tide);
        
        $display("==================================================");
        $display("   ASTRA-8 SIMULATION COMPLETE                    ");
        $display("==================================================");
        $finish;
    end

endmodule
