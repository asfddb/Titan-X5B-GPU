`timescale 1ns/1ps

module tb_router_test;
    reg clk;
    reg rst_n;
    reg spdc_pump_en;
    reg [3:0] bell_state_meas_req;
    reg [1:0] src_node;
    reg [1:0] dst_node;
    reg [255:0] data_in;
    
    wire [1023:0] data_out;
    wire teleport_active;
    
    astra8_entanglement_router #(
        .NUM_NODES(4),
        .PAYLOAD_WIDTH(256)
    ) uut (
        .clk(clk),
        .rst_n(rst_n),
        .spdc_pump_en(spdc_pump_en),
        .entanglement_ready(),
        .bell_state_meas_req(bell_state_meas_req),
        .src_node(src_node),
        .dst_node(dst_node),
        .data_in(data_in),
        .data_out(data_out),
        .teleport_active(teleport_active)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        spdc_pump_en = 0;
        bell_state_meas_req = 0;
        src_node = 0;
        dst_node = 0;
        data_in = 0;

        #20 rst_n = 1;
        #10;
        
        // Test 1: SPDC pump fills entanglement_ready
        spdc_pump_en = 1;
        #10;
        spdc_pump_en = 0;
        #10;

        // Test 2: Valid teleport
        bell_state_meas_req = 4'b1111;
        src_node = 2'd0;
        dst_node = 2'd3;
        data_in = 256'hCAFE_BABE;
        #10;
        bell_state_meas_req = 4'b0000;
        #10;

        // Test 3: Run for 100,005 clock cycles (each is 10ns, so 1,000,050ns) to trigger watchdog warning
        $display("[%0t] Starting long idle phase...", $time);
        repeat (100005) @(posedge clk);
        $display("[%0t] Finished long idle phase.", $time);

        // Test 4: Perform a teleport right on a threshold-aligned cycle boundary if possible, to verify no false watchdog alarm
        spdc_pump_en = 1;
        #10;
        spdc_pump_en = 0;
        #10;
        bell_state_meas_req = 4'b1111;
        src_node = 2'd1;
        dst_node = 2'd2;
        data_in = 256'h1234_5678;
        #10;
        bell_state_meas_req = 4'b0000;
        #50;
        $finish;
    end
endmodule
