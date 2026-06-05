`timescale 1ns/1ps

module tb_nexus_hdc();

    reg clk;
    reg rst_n;
    
    // Encoder interface
    reg         enc_start;
    reg  [31:0] enc_data_in;
    wire [63:0] enc_hv_out;
    wire        enc_valid_out;
    wire        enc_done;
    
    // Associative Memory interface
    reg         cam_start_train;
    reg         cam_start_query;
    reg  [1:0]  cam_concept_id;
    wire [1:0]  cam_match_id;
    wire        cam_valid_out;
    wire        cam_done;
    
    // Instantiate Holographic Encoder
    titan_x5_holographic_encoder u_encoder (
        .clk(clk),
        .rst_n(rst_n),
        .start(enc_start),
        .data_in(enc_data_in),
        .hv_out(enc_hv_out),
        .valid_out(enc_valid_out),
        .done(enc_done)
    );
    
    // Instantiate Associative Memory (CAM)
    titan_x5_associative_memory u_cam (
        .clk(clk),
        .rst_n(rst_n),
        .start_train(cam_start_train),
        .start_query(cam_start_query),
        .concept_id(cam_concept_id),
        .hv_in(enc_hv_out),
        .match_id(cam_match_id),
        .valid_out(cam_valid_out),
        .done(cam_done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Timeout watchdog
    initial begin
        #50000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    // Test Sequence
    initial begin
        $dumpfile("waves_hdc.vcd");
        $dumpvars(0, tb_nexus_hdc);
        
        rst_n = 0;
        enc_start = 0;
        enc_data_in = 0;
        cam_start_train = 0;
        cam_start_query = 0;
        cam_concept_id = 0;
        
        #20 rst_n = 1;
        
        // -----------------------------------------------------
        // 1. Train Concept 1: "Dog" (represented by 0xDEADBEEF)
        // -----------------------------------------------------
        $display("[%0t] Training Concept 1...", $time);
        @(posedge clk);
        enc_data_in = 32'hDEADBEEF;
        enc_start = 1;
        @(posedge clk);
        enc_start = 0;
        
        // Wait for first valid output from encoder to trigger CAM
        $display("[%0t] Waiting for encoder valid out...", $time);
        while(!enc_valid_out) @(posedge clk);
        $display("[%0t] Encoder valid out detected. Starting CAM train...", $time);
        cam_concept_id = 2'd1;
        cam_start_train = 1;
        @(posedge clk);
        cam_start_train = 0;
        
        // Wait for training to finish
        $display("[%0t] Waiting for CAM done...", $time);
        while(!cam_done) @(posedge clk);
        $display("[%0t] CAM done detected.", $time);
        @(posedge clk);
        
        #50;
        
        // -----------------------------------------------------
        // 2. Train Concept 2: "Cat" (represented by 0xCAFEBABE)
        // -----------------------------------------------------
        $display("[%0t] Training Concept 2...", $time);
        @(posedge clk);
        enc_data_in = 32'hCAFEBABE;
        enc_start = 1;
        @(posedge clk);
        enc_start = 0;
        
        $display("[%0t] Waiting for encoder valid out...", $time);
        while(!enc_valid_out) @(posedge clk);
        $display("[%0t] Encoder valid out detected. Starting CAM train...", $time);
        cam_concept_id = 2'd2;
        cam_start_train = 1;
        @(posedge clk);
        cam_start_train = 0;
        
        $display("[%0t] Waiting for CAM done...", $time);
        while(!cam_done) @(posedge clk);
        $display("[%0t] CAM done detected.", $time);
        @(posedge clk);
        
        #50;
        
        // -----------------------------------------------------
        // 3. Query with Corrupted "Dog" (Noise Resilience)
        // -----------------------------------------------------
        $display("[%0t] Querying with Corrupted Concept (Noise applied)...", $time);
        @(posedge clk);
        // Flip some bits to simulate sensor noise / corruption
        enc_data_in = 32'hDEADB000; 
        enc_start = 1;
        @(posedge clk);
        enc_start = 0;
        
        $display("[%0t] Waiting for encoder valid out...", $time);
        while(!enc_valid_out) @(posedge clk);
        $display("[%0t] Encoder valid out detected. Starting CAM query...", $time);
        cam_start_query = 1;
        @(posedge clk);
        cam_start_query = 0;
        
        $display("[%0t] Waiting for CAM done...", $time);
        wait(cam_done == 1'b1);
        $display("[%0t] CAM done detected.", $time);
        @(posedge clk);
        
        $display("[%0t] Query Complete! Matched Concept ID: %d", $time, cam_match_id);
        
        if (cam_match_id == 2'd1) begin
            $display("SUCCESS: Associative Memory correctly recognized the noisy pattern as Concept 1!");
        end else begin
            $display("ERROR: Associative Memory matched wrong concept.");
        end
        
        #100;
        $display("Simulation finished. VCD generated.");
        $finish;
    end

endmodule
