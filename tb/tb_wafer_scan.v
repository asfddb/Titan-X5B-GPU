`timescale 1ns/1ps

module tb_wafer_scan();
    reg clk;
    reg rst_n;
    reg [256-1:0] defect_fuses;
    
    reg  [1023:0] io_in_top;
    wire [1023:0] io_out_top;
    reg  [1023:0] io_in_bottom;
    wire [1023:0] io_out_bottom;
    reg  [1023:0] io_in_left;
    wire [1023:0] io_out_left;
    reg  [1023:0] io_in_right;
    wire [1023:0] io_out_right;

    titan_x_infinity_wse u_wse (
        .clk(clk), .rst_n(rst_n), .defect_fuses(defect_fuses),
        .io_in_top(io_in_top), .io_out_top(io_out_top),
        .io_in_bottom(io_in_bottom), .io_out_bottom(io_out_bottom),
        .io_in_left(io_in_left), .io_out_left(io_out_left),
        .io_in_right(io_in_right), .io_out_right(io_out_right)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 0;
        defect_fuses = 0;
        io_in_top = 0; io_in_bottom = 0; io_in_left = 0; io_in_right = 0;
        #20 rst_n = 1;
        
        $display("Starting Single-Core Diagnostic Scan...");
        // Scanning Core (0, 0)
        io_in_top[63:0] = {16'd0, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 0, io_out_bottom[31:0]);
        // Scanning Core (1, 0)
        io_in_top[63:0] = {16'd1, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 0, io_out_bottom[95:64]);
        // Scanning Core (2, 0)
        io_in_top[63:0] = {16'd2, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 0, io_out_bottom[159:128]);
        // Scanning Core (3, 0)
        io_in_top[63:0] = {16'd3, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 0, io_out_bottom[223:192]);
        // Scanning Core (4, 0)
        io_in_top[63:0] = {16'd4, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 0, io_out_bottom[287:256]);
        // Scanning Core (5, 0)
        io_in_top[63:0] = {16'd5, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 0, io_out_bottom[351:320]);
        // Scanning Core (6, 0)
        io_in_top[63:0] = {16'd6, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 0, io_out_bottom[415:384]);
        // Scanning Core (7, 0)
        io_in_top[63:0] = {16'd7, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 0, io_out_bottom[479:448]);
        // Scanning Core (8, 0)
        io_in_top[63:0] = {16'd8, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 0, io_out_bottom[543:512]);
        // Scanning Core (9, 0)
        io_in_top[63:0] = {16'd9, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 0, io_out_bottom[607:576]);
        // Scanning Core (10, 0)
        io_in_top[63:0] = {16'd10, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 0, io_out_bottom[671:640]);
        // Scanning Core (11, 0)
        io_in_top[63:0] = {16'd11, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 0, io_out_bottom[735:704]);
        // Scanning Core (12, 0)
        io_in_top[63:0] = {16'd12, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 0, io_out_bottom[799:768]);
        // Scanning Core (13, 0)
        io_in_top[63:0] = {16'd13, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 0, io_out_bottom[863:832]);
        // Scanning Core (14, 0)
        io_in_top[63:0] = {16'd14, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 0, io_out_bottom[927:896]);
        // Scanning Core (15, 0)
        io_in_top[63:0] = {16'd15, 16'd0, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 0, io_out_bottom[991:960]);
        // Scanning Core (0, 1)
        io_in_top[63:0] = {16'd0, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 1, io_out_bottom[31:0]);
        // Scanning Core (1, 1)
        io_in_top[63:0] = {16'd1, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 1, io_out_bottom[95:64]);
        // Scanning Core (2, 1)
        io_in_top[63:0] = {16'd2, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 1, io_out_bottom[159:128]);
        // Scanning Core (3, 1)
        io_in_top[63:0] = {16'd3, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 1, io_out_bottom[223:192]);
        // Scanning Core (4, 1)
        io_in_top[63:0] = {16'd4, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 1, io_out_bottom[287:256]);
        // Scanning Core (5, 1)
        io_in_top[63:0] = {16'd5, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 1, io_out_bottom[351:320]);
        // Scanning Core (6, 1)
        io_in_top[63:0] = {16'd6, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 1, io_out_bottom[415:384]);
        // Scanning Core (7, 1)
        io_in_top[63:0] = {16'd7, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 1, io_out_bottom[479:448]);
        // Scanning Core (8, 1)
        io_in_top[63:0] = {16'd8, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 1, io_out_bottom[543:512]);
        // Scanning Core (9, 1)
        io_in_top[63:0] = {16'd9, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 1, io_out_bottom[607:576]);
        // Scanning Core (10, 1)
        io_in_top[63:0] = {16'd10, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 1, io_out_bottom[671:640]);
        // Scanning Core (11, 1)
        io_in_top[63:0] = {16'd11, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 1, io_out_bottom[735:704]);
        // Scanning Core (12, 1)
        io_in_top[63:0] = {16'd12, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 1, io_out_bottom[799:768]);
        // Scanning Core (13, 1)
        io_in_top[63:0] = {16'd13, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 1, io_out_bottom[863:832]);
        // Scanning Core (14, 1)
        io_in_top[63:0] = {16'd14, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 1, io_out_bottom[927:896]);
        // Scanning Core (15, 1)
        io_in_top[63:0] = {16'd15, 16'd1, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 1, io_out_bottom[991:960]);
        // Scanning Core (0, 2)
        io_in_top[63:0] = {16'd0, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 2, io_out_bottom[31:0]);
        // Scanning Core (1, 2)
        io_in_top[63:0] = {16'd1, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 2, io_out_bottom[95:64]);
        // Scanning Core (2, 2)
        io_in_top[63:0] = {16'd2, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 2, io_out_bottom[159:128]);
        // Scanning Core (3, 2)
        io_in_top[63:0] = {16'd3, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 2, io_out_bottom[223:192]);
        // Scanning Core (4, 2)
        io_in_top[63:0] = {16'd4, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 2, io_out_bottom[287:256]);
        // Scanning Core (5, 2)
        io_in_top[63:0] = {16'd5, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 2, io_out_bottom[351:320]);
        // Scanning Core (6, 2)
        io_in_top[63:0] = {16'd6, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 2, io_out_bottom[415:384]);
        // Scanning Core (7, 2)
        io_in_top[63:0] = {16'd7, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 2, io_out_bottom[479:448]);
        // Scanning Core (8, 2)
        io_in_top[63:0] = {16'd8, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 2, io_out_bottom[543:512]);
        // Scanning Core (9, 2)
        io_in_top[63:0] = {16'd9, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 2, io_out_bottom[607:576]);
        // Scanning Core (10, 2)
        io_in_top[63:0] = {16'd10, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 2, io_out_bottom[671:640]);
        // Scanning Core (11, 2)
        io_in_top[63:0] = {16'd11, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 2, io_out_bottom[735:704]);
        // Scanning Core (12, 2)
        io_in_top[63:0] = {16'd12, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 2, io_out_bottom[799:768]);
        // Scanning Core (13, 2)
        io_in_top[63:0] = {16'd13, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 2, io_out_bottom[863:832]);
        // Scanning Core (14, 2)
        io_in_top[63:0] = {16'd14, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 2, io_out_bottom[927:896]);
        // Scanning Core (15, 2)
        io_in_top[63:0] = {16'd15, 16'd2, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 2, io_out_bottom[991:960]);
        // Scanning Core (0, 3)
        io_in_top[63:0] = {16'd0, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 3, io_out_bottom[31:0]);
        // Scanning Core (1, 3)
        io_in_top[63:0] = {16'd1, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 3, io_out_bottom[95:64]);
        // Scanning Core (2, 3)
        io_in_top[63:0] = {16'd2, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 3, io_out_bottom[159:128]);
        // Scanning Core (3, 3)
        io_in_top[63:0] = {16'd3, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 3, io_out_bottom[223:192]);
        // Scanning Core (4, 3)
        io_in_top[63:0] = {16'd4, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 3, io_out_bottom[287:256]);
        // Scanning Core (5, 3)
        io_in_top[63:0] = {16'd5, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 3, io_out_bottom[351:320]);
        // Scanning Core (6, 3)
        io_in_top[63:0] = {16'd6, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 3, io_out_bottom[415:384]);
        // Scanning Core (7, 3)
        io_in_top[63:0] = {16'd7, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 3, io_out_bottom[479:448]);
        // Scanning Core (8, 3)
        io_in_top[63:0] = {16'd8, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 3, io_out_bottom[543:512]);
        // Scanning Core (9, 3)
        io_in_top[63:0] = {16'd9, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 3, io_out_bottom[607:576]);
        // Scanning Core (10, 3)
        io_in_top[63:0] = {16'd10, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 3, io_out_bottom[671:640]);
        // Scanning Core (11, 3)
        io_in_top[63:0] = {16'd11, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 3, io_out_bottom[735:704]);
        // Scanning Core (12, 3)
        io_in_top[63:0] = {16'd12, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 3, io_out_bottom[799:768]);
        // Scanning Core (13, 3)
        io_in_top[63:0] = {16'd13, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 3, io_out_bottom[863:832]);
        // Scanning Core (14, 3)
        io_in_top[63:0] = {16'd14, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 3, io_out_bottom[927:896]);
        // Scanning Core (15, 3)
        io_in_top[63:0] = {16'd15, 16'd3, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 3, io_out_bottom[991:960]);
        // Scanning Core (0, 4)
        io_in_top[63:0] = {16'd0, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 4, io_out_bottom[31:0]);
        // Scanning Core (1, 4)
        io_in_top[63:0] = {16'd1, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 4, io_out_bottom[95:64]);
        // Scanning Core (2, 4)
        io_in_top[63:0] = {16'd2, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 4, io_out_bottom[159:128]);
        // Scanning Core (3, 4)
        io_in_top[63:0] = {16'd3, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 4, io_out_bottom[223:192]);
        // Scanning Core (4, 4)
        io_in_top[63:0] = {16'd4, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 4, io_out_bottom[287:256]);
        // Scanning Core (5, 4)
        io_in_top[63:0] = {16'd5, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 4, io_out_bottom[351:320]);
        // Scanning Core (6, 4)
        io_in_top[63:0] = {16'd6, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 4, io_out_bottom[415:384]);
        // Scanning Core (7, 4)
        io_in_top[63:0] = {16'd7, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 4, io_out_bottom[479:448]);
        // Scanning Core (8, 4)
        io_in_top[63:0] = {16'd8, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 4, io_out_bottom[543:512]);
        // Scanning Core (9, 4)
        io_in_top[63:0] = {16'd9, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 4, io_out_bottom[607:576]);
        // Scanning Core (10, 4)
        io_in_top[63:0] = {16'd10, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 4, io_out_bottom[671:640]);
        // Scanning Core (11, 4)
        io_in_top[63:0] = {16'd11, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 4, io_out_bottom[735:704]);
        // Scanning Core (12, 4)
        io_in_top[63:0] = {16'd12, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 4, io_out_bottom[799:768]);
        // Scanning Core (13, 4)
        io_in_top[63:0] = {16'd13, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 4, io_out_bottom[863:832]);
        // Scanning Core (14, 4)
        io_in_top[63:0] = {16'd14, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 4, io_out_bottom[927:896]);
        // Scanning Core (15, 4)
        io_in_top[63:0] = {16'd15, 16'd4, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 4, io_out_bottom[991:960]);
        // Scanning Core (0, 5)
        io_in_top[63:0] = {16'd0, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 5, io_out_bottom[31:0]);
        // Scanning Core (1, 5)
        io_in_top[63:0] = {16'd1, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 5, io_out_bottom[95:64]);
        // Scanning Core (2, 5)
        io_in_top[63:0] = {16'd2, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 5, io_out_bottom[159:128]);
        // Scanning Core (3, 5)
        io_in_top[63:0] = {16'd3, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 5, io_out_bottom[223:192]);
        // Scanning Core (4, 5)
        io_in_top[63:0] = {16'd4, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 5, io_out_bottom[287:256]);
        // Scanning Core (5, 5)
        io_in_top[63:0] = {16'd5, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 5, io_out_bottom[351:320]);
        // Scanning Core (6, 5)
        io_in_top[63:0] = {16'd6, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 5, io_out_bottom[415:384]);
        // Scanning Core (7, 5)
        io_in_top[63:0] = {16'd7, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 5, io_out_bottom[479:448]);
        // Scanning Core (8, 5)
        io_in_top[63:0] = {16'd8, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 5, io_out_bottom[543:512]);
        // Scanning Core (9, 5)
        io_in_top[63:0] = {16'd9, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 5, io_out_bottom[607:576]);
        // Scanning Core (10, 5)
        io_in_top[63:0] = {16'd10, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 5, io_out_bottom[671:640]);
        // Scanning Core (11, 5)
        io_in_top[63:0] = {16'd11, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 5, io_out_bottom[735:704]);
        // Scanning Core (12, 5)
        io_in_top[63:0] = {16'd12, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 5, io_out_bottom[799:768]);
        // Scanning Core (13, 5)
        io_in_top[63:0] = {16'd13, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 5, io_out_bottom[863:832]);
        // Scanning Core (14, 5)
        io_in_top[63:0] = {16'd14, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 5, io_out_bottom[927:896]);
        // Scanning Core (15, 5)
        io_in_top[63:0] = {16'd15, 16'd5, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 5, io_out_bottom[991:960]);
        // Scanning Core (0, 6)
        io_in_top[63:0] = {16'd0, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 6, io_out_bottom[31:0]);
        // Scanning Core (1, 6)
        io_in_top[63:0] = {16'd1, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 6, io_out_bottom[95:64]);
        // Scanning Core (2, 6)
        io_in_top[63:0] = {16'd2, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 6, io_out_bottom[159:128]);
        // Scanning Core (3, 6)
        io_in_top[63:0] = {16'd3, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 6, io_out_bottom[223:192]);
        // Scanning Core (4, 6)
        io_in_top[63:0] = {16'd4, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 6, io_out_bottom[287:256]);
        // Scanning Core (5, 6)
        io_in_top[63:0] = {16'd5, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 6, io_out_bottom[351:320]);
        // Scanning Core (6, 6)
        io_in_top[63:0] = {16'd6, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 6, io_out_bottom[415:384]);
        // Scanning Core (7, 6)
        io_in_top[63:0] = {16'd7, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 6, io_out_bottom[479:448]);
        // Scanning Core (8, 6)
        io_in_top[63:0] = {16'd8, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 6, io_out_bottom[543:512]);
        // Scanning Core (9, 6)
        io_in_top[63:0] = {16'd9, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 6, io_out_bottom[607:576]);
        // Scanning Core (10, 6)
        io_in_top[63:0] = {16'd10, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 6, io_out_bottom[671:640]);
        // Scanning Core (11, 6)
        io_in_top[63:0] = {16'd11, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 6, io_out_bottom[735:704]);
        // Scanning Core (12, 6)
        io_in_top[63:0] = {16'd12, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 6, io_out_bottom[799:768]);
        // Scanning Core (13, 6)
        io_in_top[63:0] = {16'd13, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 6, io_out_bottom[863:832]);
        // Scanning Core (14, 6)
        io_in_top[63:0] = {16'd14, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 6, io_out_bottom[927:896]);
        // Scanning Core (15, 6)
        io_in_top[63:0] = {16'd15, 16'd6, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 6, io_out_bottom[991:960]);
        // Scanning Core (0, 7)
        io_in_top[63:0] = {16'd0, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 7, io_out_bottom[31:0]);
        // Scanning Core (1, 7)
        io_in_top[63:0] = {16'd1, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 7, io_out_bottom[95:64]);
        // Scanning Core (2, 7)
        io_in_top[63:0] = {16'd2, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 7, io_out_bottom[159:128]);
        // Scanning Core (3, 7)
        io_in_top[63:0] = {16'd3, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 7, io_out_bottom[223:192]);
        // Scanning Core (4, 7)
        io_in_top[63:0] = {16'd4, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 7, io_out_bottom[287:256]);
        // Scanning Core (5, 7)
        io_in_top[63:0] = {16'd5, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 7, io_out_bottom[351:320]);
        // Scanning Core (6, 7)
        io_in_top[63:0] = {16'd6, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 7, io_out_bottom[415:384]);
        // Scanning Core (7, 7)
        io_in_top[63:0] = {16'd7, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 7, io_out_bottom[479:448]);
        // Scanning Core (8, 7)
        io_in_top[63:0] = {16'd8, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 7, io_out_bottom[543:512]);
        // Scanning Core (9, 7)
        io_in_top[63:0] = {16'd9, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 7, io_out_bottom[607:576]);
        // Scanning Core (10, 7)
        io_in_top[63:0] = {16'd10, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 7, io_out_bottom[671:640]);
        // Scanning Core (11, 7)
        io_in_top[63:0] = {16'd11, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 7, io_out_bottom[735:704]);
        // Scanning Core (12, 7)
        io_in_top[63:0] = {16'd12, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 7, io_out_bottom[799:768]);
        // Scanning Core (13, 7)
        io_in_top[63:0] = {16'd13, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 7, io_out_bottom[863:832]);
        // Scanning Core (14, 7)
        io_in_top[63:0] = {16'd14, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 7, io_out_bottom[927:896]);
        // Scanning Core (15, 7)
        io_in_top[63:0] = {16'd15, 16'd7, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 7, io_out_bottom[991:960]);
        // Scanning Core (0, 8)
        io_in_top[63:0] = {16'd0, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 8, io_out_bottom[31:0]);
        // Scanning Core (1, 8)
        io_in_top[63:0] = {16'd1, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 8, io_out_bottom[95:64]);
        // Scanning Core (2, 8)
        io_in_top[63:0] = {16'd2, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 8, io_out_bottom[159:128]);
        // Scanning Core (3, 8)
        io_in_top[63:0] = {16'd3, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 8, io_out_bottom[223:192]);
        // Scanning Core (4, 8)
        io_in_top[63:0] = {16'd4, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 8, io_out_bottom[287:256]);
        // Scanning Core (5, 8)
        io_in_top[63:0] = {16'd5, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 8, io_out_bottom[351:320]);
        // Scanning Core (6, 8)
        io_in_top[63:0] = {16'd6, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 8, io_out_bottom[415:384]);
        // Scanning Core (7, 8)
        io_in_top[63:0] = {16'd7, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 8, io_out_bottom[479:448]);
        // Scanning Core (8, 8)
        io_in_top[63:0] = {16'd8, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 8, io_out_bottom[543:512]);
        // Scanning Core (9, 8)
        io_in_top[63:0] = {16'd9, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 8, io_out_bottom[607:576]);
        // Scanning Core (10, 8)
        io_in_top[63:0] = {16'd10, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 8, io_out_bottom[671:640]);
        // Scanning Core (11, 8)
        io_in_top[63:0] = {16'd11, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 8, io_out_bottom[735:704]);
        // Scanning Core (12, 8)
        io_in_top[63:0] = {16'd12, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 8, io_out_bottom[799:768]);
        // Scanning Core (13, 8)
        io_in_top[63:0] = {16'd13, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 8, io_out_bottom[863:832]);
        // Scanning Core (14, 8)
        io_in_top[63:0] = {16'd14, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 8, io_out_bottom[927:896]);
        // Scanning Core (15, 8)
        io_in_top[63:0] = {16'd15, 16'd8, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 8, io_out_bottom[991:960]);
        // Scanning Core (0, 9)
        io_in_top[63:0] = {16'd0, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 9, io_out_bottom[31:0]);
        // Scanning Core (1, 9)
        io_in_top[63:0] = {16'd1, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 9, io_out_bottom[95:64]);
        // Scanning Core (2, 9)
        io_in_top[63:0] = {16'd2, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 9, io_out_bottom[159:128]);
        // Scanning Core (3, 9)
        io_in_top[63:0] = {16'd3, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 9, io_out_bottom[223:192]);
        // Scanning Core (4, 9)
        io_in_top[63:0] = {16'd4, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 9, io_out_bottom[287:256]);
        // Scanning Core (5, 9)
        io_in_top[63:0] = {16'd5, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 9, io_out_bottom[351:320]);
        // Scanning Core (6, 9)
        io_in_top[63:0] = {16'd6, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 9, io_out_bottom[415:384]);
        // Scanning Core (7, 9)
        io_in_top[63:0] = {16'd7, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 9, io_out_bottom[479:448]);
        // Scanning Core (8, 9)
        io_in_top[63:0] = {16'd8, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 9, io_out_bottom[543:512]);
        // Scanning Core (9, 9)
        io_in_top[63:0] = {16'd9, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 9, io_out_bottom[607:576]);
        // Scanning Core (10, 9)
        io_in_top[63:0] = {16'd10, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 9, io_out_bottom[671:640]);
        // Scanning Core (11, 9)
        io_in_top[63:0] = {16'd11, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 9, io_out_bottom[735:704]);
        // Scanning Core (12, 9)
        io_in_top[63:0] = {16'd12, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 9, io_out_bottom[799:768]);
        // Scanning Core (13, 9)
        io_in_top[63:0] = {16'd13, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 9, io_out_bottom[863:832]);
        // Scanning Core (14, 9)
        io_in_top[63:0] = {16'd14, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 9, io_out_bottom[927:896]);
        // Scanning Core (15, 9)
        io_in_top[63:0] = {16'd15, 16'd9, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 9, io_out_bottom[991:960]);
        // Scanning Core (0, 10)
        io_in_top[63:0] = {16'd0, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 10, io_out_bottom[31:0]);
        // Scanning Core (1, 10)
        io_in_top[63:0] = {16'd1, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 10, io_out_bottom[95:64]);
        // Scanning Core (2, 10)
        io_in_top[63:0] = {16'd2, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 10, io_out_bottom[159:128]);
        // Scanning Core (3, 10)
        io_in_top[63:0] = {16'd3, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 10, io_out_bottom[223:192]);
        // Scanning Core (4, 10)
        io_in_top[63:0] = {16'd4, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 10, io_out_bottom[287:256]);
        // Scanning Core (5, 10)
        io_in_top[63:0] = {16'd5, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 10, io_out_bottom[351:320]);
        // Scanning Core (6, 10)
        io_in_top[63:0] = {16'd6, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 10, io_out_bottom[415:384]);
        // Scanning Core (7, 10)
        io_in_top[63:0] = {16'd7, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 10, io_out_bottom[479:448]);
        // Scanning Core (8, 10)
        io_in_top[63:0] = {16'd8, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 10, io_out_bottom[543:512]);
        // Scanning Core (9, 10)
        io_in_top[63:0] = {16'd9, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 10, io_out_bottom[607:576]);
        // Scanning Core (10, 10)
        io_in_top[63:0] = {16'd10, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 10, io_out_bottom[671:640]);
        // Scanning Core (11, 10)
        io_in_top[63:0] = {16'd11, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 10, io_out_bottom[735:704]);
        // Scanning Core (12, 10)
        io_in_top[63:0] = {16'd12, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 10, io_out_bottom[799:768]);
        // Scanning Core (13, 10)
        io_in_top[63:0] = {16'd13, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 10, io_out_bottom[863:832]);
        // Scanning Core (14, 10)
        io_in_top[63:0] = {16'd14, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 10, io_out_bottom[927:896]);
        // Scanning Core (15, 10)
        io_in_top[63:0] = {16'd15, 16'd10, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 10, io_out_bottom[991:960]);
        // Scanning Core (0, 11)
        io_in_top[63:0] = {16'd0, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 11, io_out_bottom[31:0]);
        // Scanning Core (1, 11)
        io_in_top[63:0] = {16'd1, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 11, io_out_bottom[95:64]);
        // Scanning Core (2, 11)
        io_in_top[63:0] = {16'd2, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 11, io_out_bottom[159:128]);
        // Scanning Core (3, 11)
        io_in_top[63:0] = {16'd3, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 11, io_out_bottom[223:192]);
        // Scanning Core (4, 11)
        io_in_top[63:0] = {16'd4, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 11, io_out_bottom[287:256]);
        // Scanning Core (5, 11)
        io_in_top[63:0] = {16'd5, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 11, io_out_bottom[351:320]);
        // Scanning Core (6, 11)
        io_in_top[63:0] = {16'd6, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 11, io_out_bottom[415:384]);
        // Scanning Core (7, 11)
        io_in_top[63:0] = {16'd7, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 11, io_out_bottom[479:448]);
        // Scanning Core (8, 11)
        io_in_top[63:0] = {16'd8, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 11, io_out_bottom[543:512]);
        // Scanning Core (9, 11)
        io_in_top[63:0] = {16'd9, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 11, io_out_bottom[607:576]);
        // Scanning Core (10, 11)
        io_in_top[63:0] = {16'd10, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 11, io_out_bottom[671:640]);
        // Scanning Core (11, 11)
        io_in_top[63:0] = {16'd11, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 11, io_out_bottom[735:704]);
        // Scanning Core (12, 11)
        io_in_top[63:0] = {16'd12, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 11, io_out_bottom[799:768]);
        // Scanning Core (13, 11)
        io_in_top[63:0] = {16'd13, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 11, io_out_bottom[863:832]);
        // Scanning Core (14, 11)
        io_in_top[63:0] = {16'd14, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 11, io_out_bottom[927:896]);
        // Scanning Core (15, 11)
        io_in_top[63:0] = {16'd15, 16'd11, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 11, io_out_bottom[991:960]);
        // Scanning Core (0, 12)
        io_in_top[63:0] = {16'd0, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 12, io_out_bottom[31:0]);
        // Scanning Core (1, 12)
        io_in_top[63:0] = {16'd1, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 12, io_out_bottom[95:64]);
        // Scanning Core (2, 12)
        io_in_top[63:0] = {16'd2, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 12, io_out_bottom[159:128]);
        // Scanning Core (3, 12)
        io_in_top[63:0] = {16'd3, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 12, io_out_bottom[223:192]);
        // Scanning Core (4, 12)
        io_in_top[63:0] = {16'd4, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 12, io_out_bottom[287:256]);
        // Scanning Core (5, 12)
        io_in_top[63:0] = {16'd5, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 12, io_out_bottom[351:320]);
        // Scanning Core (6, 12)
        io_in_top[63:0] = {16'd6, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 12, io_out_bottom[415:384]);
        // Scanning Core (7, 12)
        io_in_top[63:0] = {16'd7, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 12, io_out_bottom[479:448]);
        // Scanning Core (8, 12)
        io_in_top[63:0] = {16'd8, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 12, io_out_bottom[543:512]);
        // Scanning Core (9, 12)
        io_in_top[63:0] = {16'd9, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 12, io_out_bottom[607:576]);
        // Scanning Core (10, 12)
        io_in_top[63:0] = {16'd10, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 12, io_out_bottom[671:640]);
        // Scanning Core (11, 12)
        io_in_top[63:0] = {16'd11, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 12, io_out_bottom[735:704]);
        // Scanning Core (12, 12)
        io_in_top[63:0] = {16'd12, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 12, io_out_bottom[799:768]);
        // Scanning Core (13, 12)
        io_in_top[63:0] = {16'd13, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 12, io_out_bottom[863:832]);
        // Scanning Core (14, 12)
        io_in_top[63:0] = {16'd14, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 12, io_out_bottom[927:896]);
        // Scanning Core (15, 12)
        io_in_top[63:0] = {16'd15, 16'd12, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 12, io_out_bottom[991:960]);
        // Scanning Core (0, 13)
        io_in_top[63:0] = {16'd0, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 13, io_out_bottom[31:0]);
        // Scanning Core (1, 13)
        io_in_top[63:0] = {16'd1, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 13, io_out_bottom[95:64]);
        // Scanning Core (2, 13)
        io_in_top[63:0] = {16'd2, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 13, io_out_bottom[159:128]);
        // Scanning Core (3, 13)
        io_in_top[63:0] = {16'd3, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 13, io_out_bottom[223:192]);
        // Scanning Core (4, 13)
        io_in_top[63:0] = {16'd4, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 13, io_out_bottom[287:256]);
        // Scanning Core (5, 13)
        io_in_top[63:0] = {16'd5, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 13, io_out_bottom[351:320]);
        // Scanning Core (6, 13)
        io_in_top[63:0] = {16'd6, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 13, io_out_bottom[415:384]);
        // Scanning Core (7, 13)
        io_in_top[63:0] = {16'd7, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 13, io_out_bottom[479:448]);
        // Scanning Core (8, 13)
        io_in_top[63:0] = {16'd8, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 13, io_out_bottom[543:512]);
        // Scanning Core (9, 13)
        io_in_top[63:0] = {16'd9, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 13, io_out_bottom[607:576]);
        // Scanning Core (10, 13)
        io_in_top[63:0] = {16'd10, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 13, io_out_bottom[671:640]);
        // Scanning Core (11, 13)
        io_in_top[63:0] = {16'd11, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 13, io_out_bottom[735:704]);
        // Scanning Core (12, 13)
        io_in_top[63:0] = {16'd12, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 13, io_out_bottom[799:768]);
        // Scanning Core (13, 13)
        io_in_top[63:0] = {16'd13, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 13, io_out_bottom[863:832]);
        // Scanning Core (14, 13)
        io_in_top[63:0] = {16'd14, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 13, io_out_bottom[927:896]);
        // Scanning Core (15, 13)
        io_in_top[63:0] = {16'd15, 16'd13, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 13, io_out_bottom[991:960]);
        // Scanning Core (0, 14)
        io_in_top[63:0] = {16'd0, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 14, io_out_bottom[31:0]);
        // Scanning Core (1, 14)
        io_in_top[63:0] = {16'd1, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 14, io_out_bottom[95:64]);
        // Scanning Core (2, 14)
        io_in_top[63:0] = {16'd2, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 14, io_out_bottom[159:128]);
        // Scanning Core (3, 14)
        io_in_top[63:0] = {16'd3, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 14, io_out_bottom[223:192]);
        // Scanning Core (4, 14)
        io_in_top[63:0] = {16'd4, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 14, io_out_bottom[287:256]);
        // Scanning Core (5, 14)
        io_in_top[63:0] = {16'd5, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 14, io_out_bottom[351:320]);
        // Scanning Core (6, 14)
        io_in_top[63:0] = {16'd6, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 14, io_out_bottom[415:384]);
        // Scanning Core (7, 14)
        io_in_top[63:0] = {16'd7, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 14, io_out_bottom[479:448]);
        // Scanning Core (8, 14)
        io_in_top[63:0] = {16'd8, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 14, io_out_bottom[543:512]);
        // Scanning Core (9, 14)
        io_in_top[63:0] = {16'd9, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 14, io_out_bottom[607:576]);
        // Scanning Core (10, 14)
        io_in_top[63:0] = {16'd10, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 14, io_out_bottom[671:640]);
        // Scanning Core (11, 14)
        io_in_top[63:0] = {16'd11, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 14, io_out_bottom[735:704]);
        // Scanning Core (12, 14)
        io_in_top[63:0] = {16'd12, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 14, io_out_bottom[799:768]);
        // Scanning Core (13, 14)
        io_in_top[63:0] = {16'd13, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 14, io_out_bottom[863:832]);
        // Scanning Core (14, 14)
        io_in_top[63:0] = {16'd14, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 14, io_out_bottom[927:896]);
        // Scanning Core (15, 14)
        io_in_top[63:0] = {16'd15, 16'd14, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 14, io_out_bottom[991:960]);
        // Scanning Core (0, 15)
        io_in_top[63:0] = {16'd0, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 0, 15, io_out_bottom[31:0]);
        // Scanning Core (1, 15)
        io_in_top[63:0] = {16'd1, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 1, 15, io_out_bottom[95:64]);
        // Scanning Core (2, 15)
        io_in_top[63:0] = {16'd2, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 2, 15, io_out_bottom[159:128]);
        // Scanning Core (3, 15)
        io_in_top[63:0] = {16'd3, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 3, 15, io_out_bottom[223:192]);
        // Scanning Core (4, 15)
        io_in_top[63:0] = {16'd4, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 4, 15, io_out_bottom[287:256]);
        // Scanning Core (5, 15)
        io_in_top[63:0] = {16'd5, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 5, 15, io_out_bottom[351:320]);
        // Scanning Core (6, 15)
        io_in_top[63:0] = {16'd6, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 6, 15, io_out_bottom[415:384]);
        // Scanning Core (7, 15)
        io_in_top[63:0] = {16'd7, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 7, 15, io_out_bottom[479:448]);
        // Scanning Core (8, 15)
        io_in_top[63:0] = {16'd8, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 8, 15, io_out_bottom[543:512]);
        // Scanning Core (9, 15)
        io_in_top[63:0] = {16'd9, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 9, 15, io_out_bottom[607:576]);
        // Scanning Core (10, 15)
        io_in_top[63:0] = {16'd10, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 10, 15, io_out_bottom[671:640]);
        // Scanning Core (11, 15)
        io_in_top[63:0] = {16'd11, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 11, 15, io_out_bottom[735:704]);
        // Scanning Core (12, 15)
        io_in_top[63:0] = {16'd12, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 12, 15, io_out_bottom[799:768]);
        // Scanning Core (13, 15)
        io_in_top[63:0] = {16'd13, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 13, 15, io_out_bottom[863:832]);
        // Scanning Core (14, 15)
        io_in_top[63:0] = {16'd14, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 14, 15, io_out_bottom[927:896]);
        // Scanning Core (15, 15)
        io_in_top[63:0] = {16'd15, 16'd15, 32'h0000CAFE};
        #500; // Hold inputs steady
        io_in_top[63:0] = 0;
        $display("SCAN_RESULT: Core (%0d, %0d) responded with payload %x on bottom edge.", 15, 15, io_out_bottom[991:960]);

        $display("SCAN_COMPLETE");
        $finish;
    end
endmodule
