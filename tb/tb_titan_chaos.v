`timescale 1ns/1ps

module tb_titan_chaos();
    reg clk;
    reg rst_n;
    reg [3:0] defect_fuses;
    
    reg  [63:0] io_in_top;
    wire [63:0] io_out_top;
    reg  [63:0] io_in_bottom;
    wire [63:0] io_out_bottom;
    
    reg  [63:0] io_in_left;
    wire [63:0] io_out_left;
    reg  [63:0] io_in_right;
    wire [63:0] io_out_right;

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
        defect_fuses = 4'b0000;
        io_in_top = 0; io_in_bottom = 0; io_in_left = 0; io_in_right = 0;
        #20 rst_n = 1;
        
        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9c02b0d9a7734ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 0, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4cf73eb3c32998d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8183c14cecc8954e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha7fed7e85f592242;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h091b5a6bfa92ae89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbbaedacef3ff1e24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 5, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9621e418fcfed5cf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 6, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he12f6cc5fbc9d949;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 7, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69382052ecf5f579;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 8, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8598ef5fe9eccfd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 9, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0ee0b8d1d9136f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 10, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h747f4658d60ccddf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 11, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed4ea3ff3e59a174;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 12, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ed82af04f8429f6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 13, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h770326df43e74592;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 14, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fb1549bf550842a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 15, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15b87fc38f0cf20b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 16, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab46e681771b5e41;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 17, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8933238e86b1fdd8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 18, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ec602532b88ef2d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 19, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0787be4c3f75965d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 20, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8fc0409a8ee11264;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 21, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2533d7c4cf47c6eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 22, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb0fabec9a2c50ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 23, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64ad400ba03844cf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 24, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31b42d133ad54cc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 25, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h302e51e06ec85f29;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 26, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3bcd900048aa5a88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 27, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb288084b522f10bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 28, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc60c0d7b6715afba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 29, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf267cea312f1035c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 30, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed1f87e3fa0c4ce5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 31, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1c5bd28c3170cbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 32, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha18bedff61970b6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 33, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0dc4967d644afed3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 34, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd7970ac728d35d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 35, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h353808957435d951;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 36, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7da8dfad54ae9ca1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 37, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h6b9a16635a38812c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 38, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a834dd77ea88cc8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 39, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2225a108d6885e2d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 40, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5194cd1fe2d33667;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 41, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e5d7ce81d6eee8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 42, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0ed4b97bc9a2d13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 43, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0cfd5317aea8a23;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 44, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49fb5b2c76a635c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 45, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c5c65af83dedcd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 46, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef223f36e9758885;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 47, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8d54e9445bd6ca7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 48, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5faa1293246468bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 49, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfbd84f4ee462ed31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 50, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h54d032d5fd05c46f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 51, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78387749b6132143;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 52, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a9bcfe89d0c1dfc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 53, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7906743a91039c4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 54, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8576fce7a66ba081;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 55, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h5b1cddba56d010af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 56, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41ef81996cba0421;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 57, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c989542b00aa36b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 58, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdadce40042ce4446;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 59, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a3254a5d7b5838a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 60, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7cb1dc5dd64e673d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 61, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he56ec680309d90bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 62, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20bd8459e3103a33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 63, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h734f35e8a6387734;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 64, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h67a5a071b1c0a7cf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 65, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6bf9cea392c67c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 66, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d9c00d58b15ed6d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 67, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h367c90d4c47ca35d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 68, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h163b2779d79702a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 69, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04d3b02f92881439;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 70, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b5870aa40ea873e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 71, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3614de28dee37afb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 72, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a2f27f4342af76c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 73, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c4a860060a49008;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 74, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2989eab1752a11d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 75, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7753c11251d1f6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 76, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11e20388dbe4d6fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 77, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd9f1c1fb1f3b6634;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 78, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h71e74c4799d484e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 79, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd49f8de0fd3208f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 80, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h300ba9bafb6045da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 81, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33252c534def8fb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 82, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha8ad5138837ba2c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 83, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h089e447473d6b17e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 84, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3250519712ba683e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 85, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h3f14328a19080701;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 86, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h4bbb2624f615b986;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 87, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62ed6a49cfe8195d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 88, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a3e965f31749587;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 89, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87ffb693ddbe7e09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 90, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd8cfdf5c0567cde;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 91, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb05093148cedff46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 92, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ae60cf7166b6d28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 93, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1368938e58b1674;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 94, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he299293e32821fb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 95, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h619965db5158fa27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 96, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he46ac463d7a4bc08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 97, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hcab3286d9ab9b33a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 98, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7dd1f96163e956f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 99, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4b37ab92ce6cdb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 100, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec039d4716427ed5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 101, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99ee0a9a537e6d88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 102, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9604173858523a52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 103, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f89c76535d8c286;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 104, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1a9fb038fbbd4dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 105, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74a260ea8d5f2fe8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 106, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h239ca4d3ea029475;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 107, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8140ed928060d86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 108, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h291ce7c306a77606;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 109, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36c5f9268baaf061;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 110, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8548c25f36168b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 111, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha42b0f509bd57ccd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 112, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2bb6ffb5d90244b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 113, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h669b3a148362f7b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 114, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h106668d5c5b1fc22;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 115, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd45bb353b49ed742;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 116, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2e962defb67e8567;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 117, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9390f17f435c2e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 118, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9691c12e53e18deb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 119, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h953543cd1983c62e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 120, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h765b427c4acd0bbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 121, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4fcbf6b1b1107e6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 122, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1bafd0a281e0fd1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 123, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h731f6513fe3569c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 124, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1565cf3e96e665df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 125, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h203d5063622f5d64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 126, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86462c973a234ccb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 127, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hb9ae98da65ce5de0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 128, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2447f88580611bc1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 129, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h863df63637d7b645;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 130, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6caa03e51fcde160;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 131, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he13bf548b8a1562a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 132, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h00c8ca1bf7c30630;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 133, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcaca73cb864fe581;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 134, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h574e7b093a71d7be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 135, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h818b63ef45580feb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 136, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hb984350eac6d5fed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 137, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac832eb5267af82e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 138, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'ha3dd64b594a5a751;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 139, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9399f9304f0c969a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 140, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'heabb876db1194bbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 141, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50305418a25bffe5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 142, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h96680a18ebef166b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 143, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he06eecbb3e3c38d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 144, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ecff83b5029a7d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 145, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h063f5c62b58c6d48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 146, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf45136e0d2cc138;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 147, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4710c33cea27505;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 148, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06526f95525e652e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 149, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70fc9760f5768efb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 150, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c61dc3694df9e78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 151, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02143d3d94605ea1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 152, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf420a605185c426b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 153, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04f72aa7f2e156d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 154, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heac545035dd4fb89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 155, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea9ab94651c94ac4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 156, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06f8de2898adfe90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 157, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ea8c184a20ab6cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 158, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd672e4e20b161922;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 159, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf008517be89a2ba3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 160, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h812fc44108fc8125;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 161, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfdd5044be500f8c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 162, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf62ec6b81945f3aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 163, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd13ca24dc575d7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 164, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc28d6433ee329818;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 165, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee2304933e4c6f08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 166, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f454ce0fc63c614;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 167, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd9978a5a728170f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 168, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2544bd989a5a273c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 169, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc543a159c56975e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 170, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a729216365b7d0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 171, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf11d80978f1ef6c5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 172, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h2f132d3cadc17bd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 173, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hcd6c3ff616209668;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 174, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3e467c28306a3d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 175, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2551630de6323027;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 176, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10cfe1cca36d0a81;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 177, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a7758bb6a1418fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 178, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfbefbeb726fc5260;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 179, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a05c1cbb72b4936;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 180, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h80bc7d824abc1cc4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 181, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c5bab4517d92d4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 182, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ae7782012d0db02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 183, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44d2e68d07de18b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 184, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heeecc3172023b1cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 185, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35056c3eff10885b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 186, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h380f0cefa435147f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 187, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ef393d10ba32b89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 188, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h451eda3d2f12279f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 189, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h93fce3ff8a759a4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 190, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8dba20df0a65aa1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 191, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h82d8a41074c306de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 192, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0a86fcf3e1ebe13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 193, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h981b96456afea6d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 194, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h057e68bbca7dc6cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 195, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h52d50a394bbdafc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 196, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43acfc2417438069;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 197, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5f154aa1e414d24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 198, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2620c0b27a3e8f13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 199, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb76c060f188d5ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 200, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5738e4c207246631;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 201, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha069e3945fbf5bf9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 202, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h454880ebe8a9019f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 203, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44ff7878fd583f7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 204, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23f8d51f413798d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 205, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha460ada3414dbad5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 206, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h122d9d410d281cf5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 207, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c6070decf75fc72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 208, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f2779755f22a935;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 209, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h284bf92abea6ed06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 210, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c245d04477342b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 211, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fd7f893a3c8a311;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 212, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ead91fb5164e8dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 213, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38e2419aee453084;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 214, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a12bcd5a1cebf5a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 215, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd353cbf47517559;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 216, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc8d42c0544567ee8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 217, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb6ddbad8373b724;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 218, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb61c98234bfe6ffe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 219, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96168539e3608234;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 220, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc93de32e5873ce76;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 221, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e0bb6dee8d16cce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 222, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3cdc4f08c27d974;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 223, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8adda10b704a76cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 224, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec194dfec64b2411;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 225, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hf244c751a4b54084;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 226, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57ce30a435a4c16f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 227, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9268b1e52e667a7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 228, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h106a632284c2cfd1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 229, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa77dc09136385d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 230, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h8c22f3ea15dfce5c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 231, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0591d5d267505578;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 232, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h721b1a668684d353;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 233, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d7a570be90dceb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 234, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7e83247f976c0a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 235, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d5b3f1a40597a33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 236, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4f552aa13042085;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 237, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbf6b798300786e14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 238, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3e4c9468fa13975;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 239, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h45819449467f4149;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 240, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4c1448a3a661901;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 241, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc154c994858fb185;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 242, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5766cb3db7318b39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 243, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hfab8385c86de5eb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 244, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h553d2ebbad83570f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 245, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd675958ae1c05822;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 246, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc4c1eb5d45b4af83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 247, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ae3582c78234464;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 248, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e35d4ec1833d53c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 249, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc44378f385ed5c77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 250, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83b7a4a84c78fc27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 251, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4dd0b5790bf1e003;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 252, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb183c34b70df64fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 253, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24082c41e7bd1356;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 254, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hcf45f82135c58f32;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 255, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee0a6d5f9ce384e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 256, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99dbfedd83e895b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 257, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbe05d6649436be6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 258, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a7a601bd6fac782;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 259, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h1f50f0f74532f05d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 260, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2931936a6b399f3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 261, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56ce02247fd7de4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 262, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5163e63a72193a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 263, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h80d4b51db458d901;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 264, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hed1b16c7de60c9e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 265, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h05f637ab56206f6d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 266, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbf736a9b81fd315a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 267, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f096ad21ef3351e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 268, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e0080e09b2a493c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 269, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h26ac04b11d59c420;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 270, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc32859a3854c1e77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 271, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h625351c7dc601d56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 272, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h658001d4e998c0ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 273, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7d04c48ac23674e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 274, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hecec546990d30e62;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 275, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd76e3de03145dda5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 276, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac52cf662a411153;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 277, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h907f3eaf255390ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 278, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58a00b5a84302e0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 279, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h651f0ee762607565;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 280, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6515ffe0a4b34c9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 281, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21929a8d87f2acc0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 282, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e21affeffa928d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 283, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfc6c4da5c290303;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 284, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bc6d20828c9e67c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 285, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h7ac80aa71b1c1fb8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 286, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9644d3d4652668e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 287, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2398bfbdfa35a572;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 288, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h722a1067582192ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 289, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9be56e5d5b577214;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 290, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h210f2ba7e383bc9b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 291, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe7d649fdc19917e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 292, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5178accb4815be37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 293, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb7f2b3b9c838f92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 294, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d30f1a423b22509;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 295, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf84bcf3ed58cdd6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 296, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h467ea2072decace6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 297, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65293d5a9e500b70;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 298, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6501e0bd428fcd19;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 299, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hede37e49f2aa6cab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 300, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h628276dac4bff6ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 301, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54d7257d082529f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 302, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9616ce22a49f1060;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 303, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h93514933c44014a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 304, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7cc3c107fdc0efbc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 305, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h022c5d5c17b4d3a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 306, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h048a2befbe7bbd7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 307, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49ea83dc0c1e8443;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 308, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31e9bc54fad2affa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 309, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88c85941f1e9a963;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 310, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c497c81b85abc74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 311, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ae6f35da7ebb970;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 312, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6dc0278e52419088;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 313, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha18a162397fc82c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 314, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4403da41c7bae594;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 315, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he3d43b423105ba72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 316, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32e5cad1e0ec66e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 317, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e155dc899956514;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 318, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f83450874b9b428;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 319, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab56162425897100;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 320, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hf8d1512f02fb2774;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 321, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf95f4bed6d0b391d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 322, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1b792c97db2f5c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 323, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe02214be27ca05d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 324, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d935069ad126303;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 325, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94217eda69112708;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 326, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36fed68a66762ab8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 327, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec3c30cb6460b73f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 328, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'habf7fa83da194f55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 329, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc2a6f28aba0321be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 330, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ab844454a9ca843;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 331, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ced63748516f097;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 332, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6fdf6b19272f7b3e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 333, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbade9141ffcac055;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 334, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc337a5bf7fdaa40;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 335, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h900c2b117145e2c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 336, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1512e3e89fb3d83a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 337, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb98ebe328ce9583a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 338, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hbce010859b9710d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 339, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h800e21afc51842f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 340, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02931bfd533d0250;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 341, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45cd347acd35aae4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 342, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h526b0fa8ac9b284c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 343, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h132294121366d4c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 344, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h726eb3e431c95499;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 345, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha66fd075c8a3cf85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 346, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa70842bac85da00;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 347, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h828ec013ed9e6b52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 348, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13a8b1fd0955a527;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 349, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5e060b53919ea1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 350, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ec9020c85ffa711;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 351, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71f4087fc2e39884;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 352, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h446c10777b6bdaef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 353, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h36021a29f03624c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 354, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf23c89a00d0adaa2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 355, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0eed05a0dd944c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 356, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7f39cced64df27f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 357, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4df30a22d3b53e18;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 358, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h862abf11ce609364;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 359, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76f2127f4a536f02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 360, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba826e465b2c5d2d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 361, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36235847485e82ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 362, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb64089b5d4df319c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 363, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h17be9615653d663c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 364, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88c63f0dad1e10c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 365, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1fd532d8c25ad8b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 366, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84cb6f2a645c0530;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 367, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a2aa1fdc6d03ee9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 368, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ab695d3c2df0573;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 369, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4c816c604bc7002;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 370, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0cd0977e16a65e79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 371, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23590ec02d451819;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 372, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52c7765305f73571;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 373, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf498e766a6cde1d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 374, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde07f2901a2cf510;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 375, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h162355d4f4c7da45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 376, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbfc92542469e08ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 377, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea75ee72c400b757;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 378, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd90829f6589d357;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 379, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65e038bfddc025c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 380, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5cad0af4e6e305b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 381, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7962f762927192cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 382, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ef939294d10f00e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 383, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h114d6f329b3f9de8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 384, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h516779d8c4f8a0b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 385, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h192cf5b44203ea26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 386, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d9dd19713202834;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 387, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed497e226b172cac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 388, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52a2b648a78427d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 389, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f27199d65b6165b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 390, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had4b8aac356ef3ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 391, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcea48f9b266ea03c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 392, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05b61e9ac37a8469;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 393, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0244209b15db33c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 394, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5891c55084a63b6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 395, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd474c2500fd93c7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 396, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d13d251a3a90435;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 397, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4628b7f4dc2e1fdd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 398, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c308cf7f908ff40;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 399, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f3d0a431f50cc37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 400, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ea958af19a9db85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 401, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h280de1ae1c9bd5db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 402, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcde6bcb377522151;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 403, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbae72bfc888257a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 404, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbff5c6729da7c654;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 405, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc11fd59c3d0fcd9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 406, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b583523c3541235;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 407, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76dcfe7809dc944d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 408, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a675aaeb827fbd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 409, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd82ac598aba01d05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 410, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb8c4b03728c350e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 411, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ed0e9554d5f9c45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 412, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a5f7ab8ff4a9422;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 413, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h870073982c0cdeba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 414, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49caf283797feb00;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 415, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2fb502ef9ebe0c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 416, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha7d7fd296d7e2e98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 417, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1793f7ba3a288b06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 418, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d926d6b4dd679d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 419, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he17b2457e0b710dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 420, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66e4a692f08de4ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 421, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4db98df43254a644;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 422, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h126f7b4462af357b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 423, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he87f22658a119b49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 424, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb44b64cab316170;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 425, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1c9079c8773c990;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 426, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8988bf3aea7b876e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 427, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5c38e378d4b8317;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 428, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6e7b1de3a67027d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 429, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a6ac6dd7f1dce79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 430, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h2d898dbcaf901608;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 431, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f4a74314100a263;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 432, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2340b21649dfdf85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 433, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac098e3e83485fd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 434, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1a9396a23a8ad3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 435, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3be7be4f13c866aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 436, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8ac18dce9d4b590;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 437, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h97ff15219c85620e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 438, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc113996cdc9411b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 439, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h571854c5b3da3afb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 440, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bd14d06b2520687;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 441, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha34d8a6e980977b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 442, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c813267c65b5951;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 443, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc237c9d89c540e81;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 444, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb57f2cbd7dbf1777;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 445, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb221db671cd8dd6f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 446, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had8b4f6cf36fc4ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 447, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc8cac0d5d3a1c152;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 448, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h431667b5178fe12d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 449, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha42ada4c4445a5c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 450, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e3e93c27370de42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 451, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21d9430955d4c1ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 452, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1dcde70df6f1a9e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 453, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8726f7eb86521a93;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 454, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff7ca3b0effc9671;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 455, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h441733bc9a52755d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 456, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3721a00b6d33c30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 457, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf02b4fd479b70680;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 458, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9b41eb27c1e7ce9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 459, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4312005d1a9d92b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 460, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5de369021a8ec0a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 461, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1977b0c2b42cd168;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 462, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc353af271b67c21c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 463, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hedaa5ff616b6ed31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 464, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c4ab7e012698132;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 465, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58b1f6fb4f137992;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 466, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf480839644c49da1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 467, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84f1b16020d3a592;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 468, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53364272c43d94c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 469, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56ce88cc4257ebe6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 470, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h829bc8e68c8f2fad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 471, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd5b1b8c5a0b3eef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 472, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1cdea2138155f89f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 473, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdca551c08ac5c675;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 474, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0545892d4bc6ff43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 475, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b286be7f79e8998;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 476, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7eda80d7be5731f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 477, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5722e1e6daf2e802;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 478, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c9f7dcba5b32476;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 479, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54f93926c1018cf9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 480, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb4cddb0e6f2493e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 481, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c69006b46fd9774;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 482, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h7449a092f49800af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 483, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h929ef792b05e8e5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 484, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7376c8a6cf856bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 485, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf848566f7d5661ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 486, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29bfbaa2634204ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 487, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6424f87c30bb56ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 488, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h319f20e1e9230c33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 489, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd79e1fc4a956df3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 490, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he84d9a320cc65b66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 491, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'he3428ba8678f01d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 492, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hb16e350d98f35655;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 493, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdec855d710a71091;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 494, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1df3b9ca8d16e01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 495, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf9d85f962c83c31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 496, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6953e8d2f20321d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 497, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he57d8e829aefd7e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 498, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1364a1a3b78c013c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 499, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h138e0b51795b5465;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 500, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6958d6bfcb3b4c7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 501, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a7541882f499cdd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 502, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc73ac751c8f23345;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 503, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e1dad64d59be223;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 504, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h936f9269c9ab32a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 505, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54f69032b0b41d51;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 506, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b80f4a2ada8253e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 507, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92e2e3ac8094b4e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 508, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96e735b44296b03f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 509, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h6d5eed1a11fbb17a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 510, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h652d3bb3613bef5c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 511, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0ea2edbfc2ddcb1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 512, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf43cecbc86d56575;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 513, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d80750ce8e1242e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 514, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4723d7411e095309;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 515, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a397f42d26abfeb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 516, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d0580978509f9f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 517, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h706a012db18d0cfc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 518, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h34013baa9e87b37c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 519, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54693b1d0b8b533b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 520, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf597385767a5d827;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 521, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb319d5b6b5bb7697;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 522, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h06577b6c06d321e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 523, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92b0fc291ac0a092;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 524, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha65a48502f444a56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 525, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2b74c79bdc80e89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 526, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a5e41c709c07943;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 527, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2d4baf7b009d51c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 528, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf98c3144e4fb693a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 529, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hd7edb0864f748108;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 530, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfff7ef89dd16313d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 531, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c180c0a530afbd9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 532, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9b4f09e246b6c98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 533, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcbcf96948bf3da6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 534, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h9f0d8ce120a20ed7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 535, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hadfb67255ed0633a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 536, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef4b010b63eaffa5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 537, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha34712e625ba2c25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 538, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf59e95aed999d149;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 539, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe26ef5dc8b2cda4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 540, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8becd805df4a9ebf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 541, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h717d8466fc2c432b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 542, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfc14d7fc7e22d120;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 543, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb90c88a2098e35b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 544, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8a9ed67103b6b78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 545, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a2a7c3e8f8689b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 546, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha86e1e35b5e7ffc7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 547, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ba669503b090183;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 548, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b4144abca4451b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 549, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h712c806bc92a1f31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 550, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h025e62eea41ee794;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 551, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hf454e5f45b08b7ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 552, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3709c80ca630c412;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 553, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96181e6649b22d67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 554, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f00da0e38dcfc25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 555, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94f83f79c361606a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 556, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha27cb62afb0b19d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 557, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc256372e64cf5aef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 558, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h915fcc752595c8f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 559, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h914e4da5f7c623b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 560, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha71c7b7632935c09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 561, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd6b840d16508b736;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 562, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h97108ac43ab06b36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 563, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hb0c376fb3e9ec138;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 564, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d10e02bba75e1dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 565, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha06af848e5691fcc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 566, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h03224b24dd171d63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 567, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bb4616e97b5cd36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 568, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0af1e272c0f5cf16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 569, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h89b5cb986048e62c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 570, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f1ec1aa9601bb52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 571, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0999c7a533b4f962;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 572, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haece07853e68926e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 573, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05ed67fc2dad350f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 574, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8df2c4eacb2027f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 575, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc65d52ea813c15bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 576, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3c30671e7afc1d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 577, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h163d51b70213e3e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 578, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6d0d58557b9529c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 579, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h722ea5e9a831d1c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 580, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he3f475cf7262ddea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 581, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4e37c29ebbcbe43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 582, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf4f77b676749fcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 583, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2dd92ed9ab79dcc3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 584, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9b2b297d49e3e3d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 585, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h40b67f31a6f75221;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 586, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec08bc99fdd907f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 587, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb856103f68de368e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 588, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf2bffeb365ba7c11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 589, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c2a6930bda850a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 590, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb6f00e3da3d16222;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 591, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3418324a366a9a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 592, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd02fbd8a3d1e359b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 593, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h810d5caba4794ef8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 594, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd266ad1123e17805;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 595, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a7714d3b39e1368;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 596, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ea0901947c87e2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 597, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11761eadecd0e051;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 598, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f753174bda4cb9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 599, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc665af639c8aba30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 600, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78952127d804249c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 601, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha48b8ce9405a1659;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 602, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf421880366eaba7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 603, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h301f18f0657580a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 604, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc922d17296fb9af5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 605, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha8cb7a7b5533d48b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 606, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hf503dca44dee49e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 607, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fabfbae77a5ab62;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 608, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8fca6f4da0bb9dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 609, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f4e84dd64131b62;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 610, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc58ee1d56961a4ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 611, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc86d75d35168fe8f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 612, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04828108c0da42f5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 613, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd21d472f77ebe8f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 614, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd5b78d11f46144f5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 615, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ab8b63251d65770;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 616, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba4b735d53a838e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 617, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h46f6914218ab6d88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 618, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf40c4a450571bb1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 619, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51a25731140ada72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 620, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha49a369237724957;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 621, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fcb796d4137a8d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 622, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0986830446606cac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 623, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha84da75fa19a5ccc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 624, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8de079f8310b24f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 625, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc42e92debf3f9acc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 626, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2bd109f6363a44a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 627, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h8bbb2002b2e21646;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 628, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbab0a2a1a5c74c6a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 629, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc84cfa10f52464a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 630, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9eb1935cb131c339;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 631, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1931e7c3366e77b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 632, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4af7efe303f72fcd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 633, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4fffba15def1b14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 634, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc34f126165c8e383;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 635, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h962557c493f6483d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 636, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35ff7d90c65195a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 637, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf588b29d543c00a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 638, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd71176e56d29a77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 639, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd55a6b255d5b5e20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 640, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4574fc6ee78a3123;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 641, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ee555ece7336f40;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 642, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9309d4804042f085;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 643, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c34009ce1c839ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 644, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96bec6c2ed950a83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 645, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac10185e871658b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 646, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3528a833ae08daea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 647, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc52060df55be1c77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 648, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb6a51665624f6ad1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 649, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd33528a2a9536ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 650, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc39d8d82269784a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 651, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h715a5c9683e262e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 652, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d30649cb48421d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 653, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e86d2e7c58d0232;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 654, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0295ffffe139303;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 655, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f75c9ce4bdd540f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 656, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb343a31490e2ada2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 657, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5143d7ff58eeddff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 658, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdaa5459a22f31339;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 659, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35cddb4d5d04b266;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 660, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hfe20e43b605c1704;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 661, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05b1bc779449dcbc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 662, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0bed307a0b03659d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 663, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6bbbbe97ede3e182;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 664, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3894adcd4f6e980b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 665, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d6de9efd3149928;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 666, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1de5175b599a1fc0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 667, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hceb045c91165399a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 668, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef4333d1c185874e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 669, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h7734b97adf442627;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 670, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef70bbd4b069357f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 671, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h0811f9c88358d636;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 672, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc093f76d72495384;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 673, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hbc7e5cedc3a1d890;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 674, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79360acdc7b8373a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 675, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc8f77f999ae2e6d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 676, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2163dd9e9de8e70a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 677, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfb07d08264e2346;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 678, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1fb6eeded9f6070b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 679, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35d40a02fbd5097f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 680, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hdfcc40ceadbc5d06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 681, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h416332e7f6251ad3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 682, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he53c66cc4a80988f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 683, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ea347f1ae197fe1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 684, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd95c036bdb3dc952;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 685, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1cb05f1642f665c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 686, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7cffedb5ad1559c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 687, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha75ffcde145812b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 688, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4259d5ab57aedad3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 689, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h119fe096b87915c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 690, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf25eddb629611079;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 691, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha53bb1e3116d89f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 692, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd38e7505d11ccb66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 693, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce01e828539fefb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 694, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h932a47d146019b68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 695, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f9f1d0a4d86a419;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 696, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd21bce7d1428c53b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 697, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1581963fb0ea6114;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 698, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd07956fa4529e52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 699, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb44efae2ad804788;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 700, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc208b59a4e11a7e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 701, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h00d185cf70d48a70;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 702, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b28262defa68a16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 703, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h924e02f20a339334;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 704, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3dd6bb79bc199b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 705, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb1b3e0389989751e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 706, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha58b07ff6af0997d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 707, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h116967c563cb68b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 708, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h428e6e32b537590f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 709, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h507ba561a7316e42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 710, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bf680e7c1f6970a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 711, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd24d375da0fef45c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 712, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3834855397bf7305;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 713, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb445041de67591f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 714, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b8b24ad0dd5542b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 715, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h5ba96438f99ca765;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 716, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3df838980b3cc865;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 717, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h0fed4c8c5104d667;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 718, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7099b8528dbf1ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 719, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heacfb9dc15d2d680;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 720, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5443b39a87f3be9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 721, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h5cd73a8f553e5acf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 722, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h603c0a5de4f143f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 723, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee5802999b5c38dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 724, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0713d9207323e32c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 725, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7bb54a4c21adfbbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 726, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f1dc51e4cc064c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 727, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'haa2c0fe7a85fec04;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 728, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfbfa3576b72d0b93;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 729, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha84e012ad2277281;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 730, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ffde74baaa23c50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 731, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02129bf3729b3893;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 732, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0055520cf1cfc86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 733, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0923ace5280752e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 734, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha04b689782ce1689;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 735, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h017c070407427f31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 736, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h4b3cf4be25b9b37b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 737, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d28a363d43184a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 738, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6359e82c22077a05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 739, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hefdbfdce8a40c92f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 740, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h800325d39401fdab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 741, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd19eebbde65b41e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 742, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcec0e9a13dd11a63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 743, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h700cdd5a75df265b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 744, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fb2a3b4fb6ff13d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 745, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0a12f74f9b245fff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 746, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb31af9da86051753;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 747, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c8de10df81a543b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 748, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71976ab3ad01e5f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 749, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a4f8dfe53846a73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 750, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h869501e9a84b9a57;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 751, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8bfd9b58c1a946b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 752, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9534f4f0f16ccf51;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 753, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc70073750c1c0df1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 754, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36332ce18da1bcea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 755, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9425675511d72442;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 756, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e20e0dade3a4206;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 757, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0386fefa66c0df2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 758, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h130a5e04b0a69074;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 759, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7709a4ee251c37eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 760, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15d1a4ee0715db80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 761, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h469f757d94e9ae5f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 762, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h334c39adb210e3fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 763, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24fc6cd6f1f9a092;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 764, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb87ad8a2dd231e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 765, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9fcece77e36199fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 766, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0256de8a59a47429;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 767, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde6eed6fc1fa14ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 768, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h74acf85f582e4895;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 769, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he27c8d61c427e07b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 770, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d6a78a141969e2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 771, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h62f2e982c8e372f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 772, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b884b484d46fa2c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 773, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2904452f0d3a2b82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 774, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74e3086ebedeed3e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 775, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15d65af34dc3ebba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 776, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c2df922eb7a204a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 777, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4789d94ea67d4c0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 778, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77585638772dd6e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 779, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78e20e8f353f5940;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 780, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h26be2ed95590b9c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 781, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf354b6defc03d826;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 782, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hedafea807708bc3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 783, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f01f2df624f9b9b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 784, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ab403a7e3ee734e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 785, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hba28b14467ec72bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 786, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd1df120f08d5520;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 787, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h80afeb38e84d33bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 788, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h4d4f00105198d157;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 789, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he6b734bc896082af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 790, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hae51e6973543a2d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 791, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd70e7fd8ca34a732;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 792, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4ea36b50f2b0446;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 793, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e6d2db4c1fdffc8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 794, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4c6f3df60212078;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 795, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b20a27eef9534b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 796, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf82cbb0ee6f74193;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 797, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5593475542f8a8ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 798, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6c6982897d70a996;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 799, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4264a2b393d0e75c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 800, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf847a6477e5f6a2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 801, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e3338575abe4f7f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 802, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ff647a5daab286b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 803, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha176d3660e771db6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 804, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e451cfcda322e8e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 805, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1dd4d78ae4208410;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 806, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e098cf72afe4690;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 807, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d1917d13b59a0a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 808, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9b2f26e788e3151d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 809, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d23e75393d19da8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 810, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7be89b05da852ffe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 811, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c2847dbbd6c0dc1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 812, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2b934ae8da5a581;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 813, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe357325794aa915;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 814, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41ada1fdc7fe4aa7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 815, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd70a87c4d55934d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 816, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h119250121a039a89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 817, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6bdf99174d66d6f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 818, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab3305f0bc1ada88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 819, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9848bef3e7fbce10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 820, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb51f22b0595f87a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 821, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf2b6e066bb9039e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 822, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0948702640e5370c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 823, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6347c043beeddf96;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 824, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef3c2f14e9c500ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 825, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfaede48d28d4c535;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 826, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd446f21272a38abf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 827, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h691b443deb540461;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 828, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h08e831799ef0239e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 829, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he646b06e4907a531;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 830, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbb650993eae167d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 831, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h838cc95e663973dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 832, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b9350b3c4e89dbd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 833, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ad65cd56d0434bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 834, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h91b41a9434591e23;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 835, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90f70cef9df826b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 836, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'ha69f0fc3b0417164;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 837, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4c72bb297e027778;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 838, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0912bd923c5340d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 839, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb44622b4cc1fd3ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 840, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2c86e860416a6bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 841, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f2ccedaacd25c96;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 842, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0a49fb95e390d15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 843, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h657eed6849fdd158;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 844, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hbdf149a64220678b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 845, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2abd86a275f32499;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 846, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf350d88cf77b99fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 847, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c04cb8bb764bf55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 848, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c96767079c6e30f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 849, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f137d881a452a32;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 850, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6da03e6ee375bd47;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 851, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc53eb21fe369604;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 852, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43633edf7436e99d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 853, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7aca390beb18e6d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 854, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he704edde99b04b41;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 855, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ec11af0f526247b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 856, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4804d1c288b2fd3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 857, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h9f501d3255650bc4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 858, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b5896b49930e880;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 859, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc339a11a9ffe85c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 860, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h1ffe91adfc50baba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 861, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13eb4ae9155e0fc4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 862, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h7b971d3af216d178;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 863, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h05df3b6b05ac7ee9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 864, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50308f8cab65f649;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 865, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a3b5e319cec81de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 866, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hadbfd2c5ad028b05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 867, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce7f040c59e1f66f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 868, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h975a105c6e127d02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 869, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h920df192aefa8777;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 870, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e04d2940fffeb01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 871, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15670b4157c112a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 872, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2bfc39c5f49b3ebd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 873, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9fa15d0f0b161d4a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 874, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd2f32408edb36507;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 875, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h764d6c7c917f00dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 876, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d767700ba1d593d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 877, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcbc0fb98adeda083;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 878, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2b8e273081d8811;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 879, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h784c70c479f27de9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 880, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h419d3cf6ea5073d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 881, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf047afe905aa0fa5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 882, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf304ce7f14f0dfce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 883, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h488d2f3d6982a64f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 884, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9bf3a2cd09598923;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 885, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hbba14a51e52661a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 886, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e073d4202d0bc39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 887, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa7b6a003b8166b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 888, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha94840f94acf60dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 889, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hfe8f5882f1c22e82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 890, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h280375f117c0b630;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 891, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha92d72e74c0def6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 892, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ea16af561566389;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 893, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2addabebd18b4bc7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 894, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02a73927086bb6b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 895, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8e81e841b0a2a04;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 896, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h27cde55ad4014a47;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 897, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7382423d6e77a832;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 898, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe426e3af910781d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 899, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ebecc1d545f373b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 900, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb41b4878b3e761be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 901, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3cdba623a0bd579;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 902, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29bd05753c576126;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 903, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h9248aaebf6ca348f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 904, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bc0bbaf499970b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 905, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43f2d047c71d4c63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 906, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8173de7844e522fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 907, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h233d0dea4d89ed40;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 908, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h048f889928e7b128;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 909, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10058307c7ee9e9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 910, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88b5da772b132877;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 911, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde30ea57d33aadbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 912, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hddb8d0be629731aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 913, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc34424979676c626;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 914, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9327686d61a2ca48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 915, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5810989ca4106fcd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 916, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h81c4bc28cfdcff2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 917, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h488be893fe870080;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 918, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60c5bca5e43c9c2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 919, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb504d14010b129e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 920, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1bfc9e68beb50c06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 921, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hae6cfc5edaf6b244;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 922, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ac1e38db3a90b5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 923, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc62bc1fd10382c0a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 924, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd6c4a0355398d1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 925, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1bd31140c75f8640;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 926, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2361c6e1e76e9636;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 927, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hb1fb80d09f678e90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 928, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5ccecd4d84eaa71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 929, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h557ce10e383e5e6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 930, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce8f0a22f9688a1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 931, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbba2159c5b02ed5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 932, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94121f27e36e0a47;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 933, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb58816f1d76da10f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 934, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6d7e1b41005d850;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 935, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4e519919c8af7bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 936, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h12f40a0ea1cbe175;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 937, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h424894a307844e46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 938, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2d29eb810e77e07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 939, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hde313a90ebc226b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 940, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc07581d80f6eb9a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 941, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d31509fbc45df03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 942, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1b0b97243f7af431;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 943, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb59ea0fdbba2310a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 944, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1385e9dad8e7f302;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 945, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8fb1f4be6dafcd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 946, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd335fe7436ab7bba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 947, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8471e4b040b83c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 948, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85ec321084773ef9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 949, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h243cbd4ec5f596da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 950, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3dea1bcee5df6b93;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 951, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd23c07b90035932e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 952, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1afa30c427bfb402;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 953, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90b28e97e8932723;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 954, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h2de65b765aa3bf45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 955, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c3f9a271df937d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 956, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h8956baf62aa07603;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 957, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafb0d3e1abee90e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 958, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h058f0613ef338c1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 959, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h1c12d35be958ecf0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 960, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1476bb69b99d48ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 961, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57f7f4b9f12d2224;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 962, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0145adf207b5a82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 963, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7fb3e6eb97fcd06f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 964, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65a961c2bdc64d72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 965, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha24daed247ec1b09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 966, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3b591e831bf0646;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 967, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h942e52fe8316ff02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 968, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha200a1058f8eb30c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 969, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6097a3cd0cc2ebd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 970, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1477a29a2cb67903;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 971, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99b01ac4d90eeb49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 972, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf553080877b4dd52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 973, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h39861648bb67da22;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 974, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc62775b19ff44417;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 975, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h5eed97e7500eec6a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 976, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5a9c3a75cc7fe79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 977, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h222f913a81226b2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 978, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd735ced8cf95c886;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 979, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e2c04cd04f286a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 980, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd221cd781b9f4e30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 981, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he86d035af92d745c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 982, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5cac73d44c2c36c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 983, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb6016299efae0599;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 984, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3abb99c964a5eace;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 985, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h654c091b7e7a2fab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 986, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09087743f7f3480e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 987, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h8939011c940d13c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 988, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha226bd4a3e94a81b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 989, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8213e770da0a3276;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 990, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf120c87e42ce6d58;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 991, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21b5992be29c2300;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 992, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09edb6b52bb9757f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 993, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65fdcec9b10df860;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 994, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h515697479ddefef4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 995, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h93873558f62d4567;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 996, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8834af9f18430967;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 997, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2fc4ad9f80c9bd6d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 998, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3325431c550b4a93;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 999, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h48ffffa379613928;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1000, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5dad067f242dc9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1001, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47044ecf4cdd63b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1002, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h491339bed87df830;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1003, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he6b293f11a32bb4a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1004, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfca5bce4cd607497;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1005, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd22bea6e2cf3c6ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1006, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5eff534c6a9e4e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1007, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc915afae8617b662;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1008, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3a7796fe9587428;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1009, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbffae1a1a14f629d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1010, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he58c2e60d7e23b91;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1011, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7b61b8b9e5b3ac1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1012, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb9d1f97034f2109;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1013, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd53020d71a3bc79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1014, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he57a7e3bf2bd5a0c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1015, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5dfa47c7cfd15f3c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1016, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbcd19826137860f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1017, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2239c9fa4ce202e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1018, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66a5368e5b443bc2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1019, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'ha2a4cf2ce4f3d833;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1020, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83f794794fcd42a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1021, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e97eb0e7daa645d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1022, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd553a828e5c1b1c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1023, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77cc11b91fc0c9bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1024, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcef57c534df45ad7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1025, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7657ed3d708fef0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1026, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heae325e6a74600bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1027, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hea008b70498886fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1028, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h782c8d63d5c3584f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1029, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7265f89e2486cd9b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1030, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1c6dd6e39a24d51;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1031, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f2b3fc03d686547;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1032, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab31a3102723fdca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1033, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6edd8d0f92cb3e5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1034, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h198f378cbcd3f747;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1035, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5d093972513a8b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1036, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ad337eb009813c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1037, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hedbf22f7a562ad9b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1038, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha258b6d8d183df66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1039, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he591838f02106189;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1040, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf676ca91eb596e2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1041, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0489f76acde7991;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1042, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14dd2c537338ed7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1043, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5cb6cecb23229fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1044, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h023cc8687a508be3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1045, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc8153250376356e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1046, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e223ba24f51858e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1047, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf159bb2d2e851273;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1048, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h818c6bed216b5b00;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1049, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d60fcca8e6a077f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1050, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf801780d2835c87e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1051, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a693e5323576439;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1052, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d661a5b1e447b1d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1053, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'heaed90c1865036b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1054, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0bc8d0f7da55855;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1055, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e8d17e2f195bbc7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1056, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3405d8df5777f051;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1057, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h611f3cb4194651df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1058, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5357348a8247ce8e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1059, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33c48ecf951f7730;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1060, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf06b04cf81422ee3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1061, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0bd13fee60f1dbeb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1062, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d8cd920c9d86502;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1063, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8c1ecd332260b0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1064, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0418a7b989a1de3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1065, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdd2a124c6d678fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1066, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h393b7acf8c161622;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1067, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7830c89cf12b35dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1068, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hbe23c67955c0e45c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1069, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hebd057e1b90c016b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1070, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h5dce9d699b69a5f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1071, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he9a923c514884412;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1072, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f71892ae630cb1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1073, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ba7253cc1b92b74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1074, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfbc8aa41c1a19c59;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1075, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf327a810b872188;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1076, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e1f3bab4b70fce2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1077, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f16c4a4497a3751;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1078, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fb7124b5a1d1b17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1079, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc923ece6e3a3a5a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1080, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2059558a9ba183a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1081, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h020dfb1ae361f647;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1082, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8361f728f321b71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1083, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb3b3920eba500fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1084, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbff49bf0b0b5ac09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1085, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heee871ffc5bd1691;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1086, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c8f8fb6d546c4ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1087, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h011a973bd9d256cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1088, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5caa1d1fc9d30805;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1089, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h861fe388f4c50eba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1090, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha27bf5fb58b7eb32;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1091, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h545a204485e91ef8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1092, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h280fb908a8a1cad1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1093, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbcdb328e0e49e4d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1094, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h460c6aefe9264403;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1095, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c0763cfdac45d7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1096, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcca1d6ae0ee97af3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1097, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09e729d9cda1a137;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1098, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea05c43212aed1a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1099, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7bf6818aac15e122;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1100, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5cf3fdc2c0a9f5f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1101, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59f17647769b24b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1102, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e47405d564f6deb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1103, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5472c39f250561f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1104, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0447ac8448d5598f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1105, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h554c78fd2f266767;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1106, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fa8a589b87d012e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1107, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h54394d4c9a251e94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1108, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb61677c2a71edefb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1109, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83dfbd56df0cda24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1110, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d1663a7938158fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1111, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2edee272f8015356;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1112, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha5a7d250261fad85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1113, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8058144430ed0794;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1114, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2587a2d14ae6902b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1115, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59c5662bb6eb6b83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1116, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d1e64c3fa8db4ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1117, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c98b1990f39d867;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1118, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3ee4fea72b9bbee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1119, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50d417e7efae4f59;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1120, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2fd8345a84b926a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1121, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a2ccdaf09e41e2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1122, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfad851f0ae962a2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1123, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h111611acec2f613b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1124, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3797fcbc61d272e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1125, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h536e92b5605d387b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1126, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h12d41ec905d5e505;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1127, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6278a595009cfbc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1128, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5aad20259f869d67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1129, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c0f85a7a806f829;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1130, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60ea5ecd86fe6839;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1131, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h949d1088cdace950;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1132, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf2ce9054072f6aff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1133, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa68a3da6f5d2c37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1134, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc239d7d817b58c1d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1135, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a20781513b1057a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1136, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11a588ead979f191;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1137, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b101f24ef315ef4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1138, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d9e4933aef6f007;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1139, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ff39035d5b57f73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1140, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1527ab65a93d417d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1141, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3df30e8a0c92cee9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1142, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a62e19603db977e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1143, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbaa120f62460f8fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1144, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5805f7d34dae07db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1145, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85ac653f85b4057e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1146, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87a32ccda68af8bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1147, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f35ea03b9d49481;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1148, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h9a4bb7d0a7c0e63b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1149, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b3e4e405682450b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1150, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f603d91e8e74b05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1151, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ee0d0f6fe611797;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1152, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h63a98804cd21cdd9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1153, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a721952c16cfecb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1154, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h980d9e34558aa0b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1155, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcce747618948062f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1156, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62bab637c4ea1b8f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1157, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d2ba39e8cdf62d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1158, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6f04f107df166c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1159, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h30583ccc25de7c50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1160, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8cbed95d74c92d3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1161, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77103ea8ef0545b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1162, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h65cc2550b1e02bf2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1163, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce56e7fe535915ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1164, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ec2de9645522fc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1165, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3a09907f427f476;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1166, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2195d74dda8c8992;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1167, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h958ec7f8823e144d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1168, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h08ad3649a04e96c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1169, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfdc6902d28f66d06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1170, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e06794bef8ce4b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1171, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc07a183aaff03d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1172, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h00f46a7c2e1291a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1173, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92fa75608ae72440;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1174, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb1171f8927f5402;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1175, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31e818876500cd27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1176, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14ab7a6689f2b0ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1177, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6a8bdad9ea7da4a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1178, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd70fc1855ff8b2d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1179, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h18e4284313b7f825;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1180, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha687e01eadc55495;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1181, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b1cb218fdb3e4be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1182, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd090399dacb962ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1183, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h198559bd22981609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1184, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h929ea457f930097d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1185, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb52a2d6a9830c869;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1186, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c850bff20f9eb45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1187, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h950045f03a9f26d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1188, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2cbbaa0f2a25e86c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1189, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha735e68fd86c8b6f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1190, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h17fc993a9850cbe8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1191, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fe9a20c163ad00b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1192, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea30dd14230c0c4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1193, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he299564de4194224;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1194, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he72bc89543a920a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1195, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ef7c8177283cb0f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1196, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h63394adc44e6c267;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1197, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec092ec46478eac7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1198, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha01cbbe806030c99;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1199, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba411bd57198d6e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1200, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e019fd4c1d42342;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1201, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19b3ab186c85c9be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1202, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc865a7d13bf0a9cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1203, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fa1053cb3c6dfcc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1204, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h923d02e0715e6c32;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1205, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd83fa2bd969bef4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1206, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha220ee8aa5943618;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1207, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'habcc1a5b9c8ef5d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1208, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h995eb4ee1cab9155;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1209, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a0ba7d3c4c04280;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1210, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1bdcfb0dec836a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1211, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h409e85bbaac30f61;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1212, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he715228ab583de2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1213, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h73f68e0a68cc0e48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1214, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfde870e98df498aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1215, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2d6b1b7d7cc66d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1216, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4be5844cd1ce1058;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1217, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47d1e1894f35d29c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1218, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b3048bb262b5c24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1219, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75340a231e4f142a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1220, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8f5058dd3334d47f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1221, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0beca89f97561dde;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1222, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2eaadf9480d7312;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1223, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a04cca8f012e85a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1224, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h63f11a2b55ee2ddb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1225, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb8c20e171adff58;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1226, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b3d660bf16432cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1227, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h73cf3e68d6ca34c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1228, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78bcc77a3da6dada;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1229, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he36c7a1585cc106e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1230, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he247826718132226;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1231, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84cfd540fb5cd675;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1232, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd511ef0f17096cd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1233, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfeed0a31b3ee45f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1234, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h0996d5fea7af9985;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1235, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6c1f018fccf24c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1236, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0dabcbe14a2aaee1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1237, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79526844cfeb5356;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1238, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e25b6d5fde7aa07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1239, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61220217712b5ed1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1240, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71227b0dfefba800;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1241, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74e98c7493602864;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1242, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'habbf39c8e8f7ac89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1243, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h368138014dbf6dd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1244, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h967e2496602da159;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1245, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h763c59b11f55e063;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1246, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3f351fe7b2ee558;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1247, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bd2a0dbc75336ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1248, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0c1479995ebf656;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1249, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h120712f9dfd90b51;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1250, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb919b4e63bd32491;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1251, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45a1642e6b3659c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1252, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d932416133c350f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1253, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h295f6af6e6dd2e80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1254, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb640d4a1713ba9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1255, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h57039f532b321c20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1256, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7a6e80da7578a83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1257, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc02001d77ee3e316;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1258, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4aa1cbb7f97d7677;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1259, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc1453d229f7a8ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1260, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha75cf4b57ac70a32;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1261, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20b63f1916d9f909;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1262, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h211cc617a79b2d14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1263, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3d3c6e145af0c8e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1264, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09de99c1cc7f7f2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1265, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6770e3cbfaacb9a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1266, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haac7f2a35fe201c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1267, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hc1aa490ba7b1f133;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1268, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h598c17bf6db4fc58;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1269, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fc8511bcabc0c48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1270, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h12859a78f28a2c27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1271, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h73f7896c9ffe00a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1272, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdaf8b5fbbb937483;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1273, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb6e2d9ad2fb3cf38;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1274, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha55a49442473fb1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1275, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ad398c04e82a8fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1276, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc3ef7af1545b14f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1277, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc570e350d8821db3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1278, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ce33ba060e0980d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1279, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7673f67edfdc4403;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1280, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heea406a48310c1aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1281, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d08d62b004494e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1282, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55ed0077e1d0c3d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1283, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h553f7b5fae9e39f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1284, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab813ee83abf4e3e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1285, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6fcb8be608b91501;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1286, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a8cfea637b7a334;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1287, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he67adbeb4ee56aae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1288, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2e1a21e1f61ae73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1289, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47ca13f97fd8bf1f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1290, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2653a4e1d7b216d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1291, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5a53feb7241bad1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1292, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29f9a0441f87f1e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1293, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24b4d1d054844ec4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1294, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha93c726a34cab392;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1295, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h158a7922552bfce8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1296, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0061f373cb090b61;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1297, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88af2b14ca0fa7c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1298, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b0b6dcfb58860e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1299, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he40d3bdaf78ee59a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1300, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5535fbeb0a046045;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1301, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0bcaa4e307fd5c0e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1302, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hddb16df2070eb5ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1303, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h817679410d0ba554;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1304, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hc75dac53a314e474;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1305, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h42ed069f6c97b705;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1306, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2ed69f6a43c8969;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1307, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba4bf15512f8f661;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1308, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hf101abb3b98515bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1309, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf55db4018758f1bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1310, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70013f6772cf5faf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1311, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6206c63159909f2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1312, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h764db9641856f0fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1313, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3122c71aad3a2cef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1314, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37a3f594589d8a88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1315, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2892b49f15d50bb7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1316, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36415f838b741f3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1317, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90315885aa82f599;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1318, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe7c1f1dfcd8c135;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1319, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h73a4542bb3243008;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1320, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf803123a772a4609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1321, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h027745a2b04c38e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1322, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h31ce0e2a0515a816;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1323, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c3faa9b30cb6311;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1324, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9d2bdbbca1aa5cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1325, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h42e2455bd52cd3a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1326, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb28293de89c4f26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1327, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc5e505ec043cba9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1328, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h7015f53968789448;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1329, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he96f34c637bc2624;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1330, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1dd606b8bd67de24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1331, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5cbe73797c9306ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1332, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd151aa557398c623;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1333, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10b634255d05fe3f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1334, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbcf7051f55713242;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1335, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha05d9f5519eb34ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1336, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h087ab67deee4447f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1337, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85355056afc00909;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1338, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec36f43bce09fa1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1339, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h832f91abebcf29f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1340, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h598cda2140f69566;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1341, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h889e22af8301d1ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1342, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hedb9fe46ec3a5121;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1343, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd1ee656655cca5e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1344, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha467768bcb13be3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1345, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h0a8f5ec2492e6969;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1346, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bcb87ef67f29b6f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1347, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9bb7e6c5b2a2e4e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1348, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1050c0615d8fa531;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1349, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04fc7238b1f764c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1350, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83f142674e4cac94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1351, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he01686d127d6a14b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1352, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06568866f6618ce4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1353, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36f51b0432a62e0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1354, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb2af4193cc2de71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1355, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h493f23202ace458c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1356, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfc53cfea9bd560b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1357, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9edecc5e88cd0c72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1358, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'ha5b30251d5356803;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1359, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hb719e1e0f558d4e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1360, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a7a9d9d22b6c270;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1361, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcff162649bdb30df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1362, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9451e444da3ad26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1363, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf219bbc95f60bf98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1364, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h403ef5b5b7510570;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1365, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45d74e686f34c7b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1366, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h430e4c3608578b63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1367, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9841937d60d043f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1368, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h046437acb3eb0661;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1369, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h5b4de951405ca11e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1370, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha5843cf716d066da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1371, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d09729a2df0b1a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1372, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09649fae0d695fb1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1373, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0de6570b7b88b5bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1374, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h862b7727e10282ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1375, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2596360eb6042681;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1376, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h663304228b0b67bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1377, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf9566ab4a6e87e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1378, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdae38588a947a033;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1379, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7084c8c9dabe557;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1380, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h542692c022d2effc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1381, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cba3707a12300c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1382, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8cbf21556e1724b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1383, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd17dafa1f09a6326;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1384, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4275daec674629d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1385, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19438eebd61cbb90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1386, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa725db97e661e36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1387, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55422da728f002db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1388, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h312a61e78e709e15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1389, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19aebd3840eb9143;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1390, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hfb4f0535a25d8b1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1391, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef70274a2a6c9464;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1392, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h019324522232e386;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1393, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1f6bf0cfc864d7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1394, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b0839728feb1b46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1395, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h251eb5d171a3b4ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1396, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71c09f5b953dc006;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1397, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2bbfebb6e1529d0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1398, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3aad982cbdb56226;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1399, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfc440c2547afad4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1400, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h12b63913bb76bd95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1401, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3fa4b7176256946f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1402, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8489509e2173ae5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1403, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf2a3d9394dd9aab2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1404, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he75e01e44470a072;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1405, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd244e8d153ce9ffa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1406, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h011ee737067a89fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1407, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h91103de141e675a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1408, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hedfadb5f50ff3a2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1409, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6989e869c124949b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1410, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b9aaabaa8c9782e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1411, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde93e42b151f6b83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1412, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h933c22838b082ffc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1413, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28585a4eef62983d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1414, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h072b49da56b9d14c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1415, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf07d7ef8b720be89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1416, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4c468339025fddd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1417, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h9262d17c99420b98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1418, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2f85a4774f168577;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1419, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44ac8f4a4b20ec1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1420, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed26b3820702badd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1421, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20775e85f08adfa2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1422, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9474421b15e878d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1423, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h020a9d14f223d649;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1424, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3704e0c8c2f3a9e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1425, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b532a274b01dee4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1426, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he12f1646aeb7fad8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1427, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2cdf30b006795c9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1428, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbf76cbc70a4c63f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1429, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57618074004b8fde;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1430, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5c2543ebed77623;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1431, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h67dde0797b99c18f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1432, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd917c835712deb8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1433, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83f6a9df254b96cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1434, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc7c4926cc868ead;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1435, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98bc0bef43d61f08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1436, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hdf11f6852204972b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1437, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf791fad19557812;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1438, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h947d14c5bcfc0328;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1439, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02965a88392ad2d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1440, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcbc9f155827d1fc1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1441, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd1fa1857858421e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1442, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79414eaa9901a4c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1443, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88e9196dbb33c95c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1444, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hbd5cae7d2df4e982;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1445, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd4b0db0254b3ef87;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1446, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h08b5750d50e31b45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1447, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f9e4a1dcea7fef5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1448, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha40bade30c3178c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1449, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd1e78c6724bde6ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1450, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ebf962b9e34ba5c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1451, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h558cf30e1439286b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1452, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf586f3e0021068bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1453, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he64e5ac332089f03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1454, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5be65c424f5917f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1455, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d6a5b08b42d218b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1456, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb45f2f1756a6f305;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1457, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h289b3a6a271306cf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1458, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h875f98f58f50366a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1459, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3c3ff67813f173e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1460, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23ffa6355544312c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1461, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe61525c5d4ca8fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1462, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h555e1deae826a24b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1463, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h251c87b9f308c93f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1464, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd4ab5154bf26a801;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1465, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0516af2e763c03b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1466, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h387948c0a979f22a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1467, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd63e1d1cd989f898;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1468, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haeef18053dca80fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1469, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3087e4866f502c84;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1470, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h531ba97bbb5a072d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1471, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02efc232088d0df9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1472, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h438fadd19e3c0159;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1473, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h3ca0d8e2a42d95cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1474, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h651bbd82933cedac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1475, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h164f3337e853bc31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1476, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ab0f0cd04746fda;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1477, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha175478f5c5a2ff4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1478, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h67bd2bf4a5580807;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1479, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha83fbaa83c744955;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1480, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hf923d61f867c5e41;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1481, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h528ef99e391d43a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1482, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a964e37528b7571;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1483, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h07e221c3d50dd7df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1484, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h171272b428174713;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1485, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d68372d68255d28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1486, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4ee61ba71ae47a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1487, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84328465421fbd04;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1488, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e6cff4c716f1445;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1489, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h8f72a875b21719d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1490, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc908b50e7c0b46c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1491, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6132ec8518259499;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1492, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8bf0ccd1deefdf26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1493, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3198d58496dd36cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1494, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30d47c64d2763c24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1495, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb30bb0a6acfa70ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1496, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7caca3959c0fd30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1497, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'ha4df9eb60001f940;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1498, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc90ef80fecf86c12;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1499, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h26e87d5bfd181833;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1500, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac52aac0d0d7328a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1501, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h6537a2e81d8009ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1502, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57358072a0fd955d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1503, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda2f8d77eb5ac73c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1504, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8aebf017d3ee20b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1505, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h6b5b109115e5575c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1506, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8f7e5613e448e13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1507, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc988cabd35ff0c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1508, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b489da049e12620;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1509, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcba3376d1c2b6743;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1510, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde5aaeb0e27e0884;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1511, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5845f9dce1a8cca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1512, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a2b571c787bd053;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1513, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0907b3446f3122ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1514, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h779484a7ed500857;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1515, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb246dc264104e54b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1516, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfeb6d3512a689712;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1517, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h5d32f35229dc7e2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1518, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd76c584419be37b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1519, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc76e6757659ab70;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1520, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d020438233d7435;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1521, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f9ddf20f0d18a0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1522, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5017d6a7c345cb0c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1523, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8929d158867ba3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1524, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha93b702d75c83668;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1525, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19079cc434b27321;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1526, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d4bc4b25ba74237;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1527, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffff1200932dc7d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1528, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h81409e1417ff6709;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1529, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d41712320d39dad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1530, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb77ff91db0b7de22;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1531, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heff2e5e84ae1761d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1532, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e252b61af331338;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1533, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9476390450b756b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1534, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b6f0a05f7e64234;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1535, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe7ca4dd2aee9e5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1536, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f630617d237bf7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1537, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hfa1ce2bc00f31750;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1538, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd07146a274f78c1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1539, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51cac173f1effd05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1540, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec44eea7676600ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1541, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h46f4d71ac953ee50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1542, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78fcff7904370719;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1543, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6bd75deae7f67499;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1544, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9483e2e95d48a41a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1545, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he84ba1d04b2b6c97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1546, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0b1857c60aabf56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1547, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2854f404a206966d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1548, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54191ae78b072ecc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1549, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h48255fdeda92ce45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1550, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fb29c24d7806d4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1551, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha9277db1b44f4f92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1552, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h72d42343308c6c4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1553, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he9db039931641ccd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1554, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53db6ff5b36f6b7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1555, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1195ec50606a2412;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1556, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha16af1645bf319e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1557, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3156ace2c99643fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1558, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2de96f2fbb446fca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1559, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0634f1ce3332b28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1560, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b52f6b74def62db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1561, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1974fff7df486b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1562, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'he7b92c82c80e3c33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1563, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d2a9f0e0e2f14ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1564, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7dddb9dfa4acf895;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1565, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cc1df9ba9839c7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1566, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7ee807f1d9d809e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1567, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb98ff8eca7375a26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1568, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h2bae64bf136d9394;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1569, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h477005475fc4d69c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1570, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h250eae97bc6983bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1571, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd7e030ef08ffd1ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1572, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5e497da04f16e63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1573, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5d6e128371320c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1574, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha85780d21c854be1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1575, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha264a1dadb473d50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1576, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h720f1211c33643ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1577, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h722c75c322b2911d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1578, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9137224ee45df62a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1579, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8203399a2eb20f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1580, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f304e27030a9661;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1581, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haee24da59f85472f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1582, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04b02af2546aa360;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1583, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba421ec8fa32b9e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1584, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd815145c0471acd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1585, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c55ae8d42c62891;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1586, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h210a3d4b580372a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1587, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3dc328cfe43cec28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1588, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb54c92394c08e68f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1589, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h258315c253b55a11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1590, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b4bc2d8d32a3a51;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1591, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a224025f41147ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1592, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64011ea4e820c466;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1593, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1925fbfbbdcddef9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1594, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff4b4db11b4709e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1595, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6871ea61e497966a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1596, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea1a00bc8b772b9b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1597, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfbe5e53253f31a48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1598, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92172392b2d973f5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1599, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1d3e380398fc02a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1600, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19ec4803a45b6e75;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1601, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c359cf278951135;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1602, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h950aa0bff7114cca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1603, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h809458f1e34ad076;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1604, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hb59161d6a8f800b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1605, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5554efbc79122f9c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1606, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f386e80cf2f29a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1607, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15a99733a95ad108;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1608, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha10c850ffa72eabb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1609, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c66291cef6ae630;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1610, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0541a20b31b56fa2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1611, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd1ed8ea1bdb5502c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1612, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2db48b545381c2ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1613, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37186601ac746655;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1614, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0532b12e8920a283;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1615, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32879743dcc7e5a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1616, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2dd0d79432776f41;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1617, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba63c6da14cc2045;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1618, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66aa055cd8eab019;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1619, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0f6553f72e96bf7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1620, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc194dd9fc0fa9a85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1621, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1cdc304d266535d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1622, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd893be84a70cc967;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1623, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h554a4e612b38d6c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1624, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha62eb7ba03b1c988;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1625, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hfb87376a2d2109e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1626, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09079076776bd57c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1627, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0aee115728cfe48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1628, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7e81445b09ef68c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1629, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h800c2f2efab78fb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1630, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14b94c63ee21e572;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1631, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8393522c656627b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1632, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6160be5aca0bc931;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1633, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3578b9ae184e3ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1634, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc30982df4267cac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1635, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6a2d1f4dce7d0c19;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1636, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1a056ecb49516669;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1637, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab5e67875df2d0a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1638, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha3ec09e4ab2ff690;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1639, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa3e4a8449f6951e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1640, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5978b3a0c643e24c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1641, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbf6c832db48eb5c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1642, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62d9d05849b4e030;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1643, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2397a112b5978b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1644, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79112d5a319b91a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1645, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf327ec74afa0e126;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1646, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h16897b1bd1ab97bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1647, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h8d9a3fbbcb0bff08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1648, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d5c6e4b9d11ed70;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1649, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9b3e545d6cda0ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1650, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5682f553d794a8f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1651, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24a06269432ba10a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1652, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37046645bf9437de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1653, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86b13841e9ab15d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1654, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h078a2297168356ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1655, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4963431729df9e8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1656, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e080ce9654f0593;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1657, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he79b480b168ec880;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1658, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h7806cdf9c0ac75e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1659, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60c2016f7984f565;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1660, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h6a5fca2373b92c6d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1661, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1eef378de04cdab0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1662, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8afc4242d041de6e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1663, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9217a4916fcfdf7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1664, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2787174d0e7c6f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1665, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h48a2aeccf40c15ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1666, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d5428dac2089609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1667, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e4cf843d5a09cec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1668, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86835851f58f397b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1669, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd293b59b680afdc1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1670, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5aa5e0f93f470ac0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1671, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44678410fece5097;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1672, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'heee4b8381a5a055b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1673, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3874f7ac6f214b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1674, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d8839f898bc8632;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1675, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha74e700877200af1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1676, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f2377bf841dd605;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1677, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fcb5f8974fd4f71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1678, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hf11c2e00d5fdf7b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1679, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61e4438740ca98d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1680, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h679eb5e9ed2394de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1681, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hf22886aa9f3bbb3e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1682, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h27024f0f6eb17bcc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1683, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56ccf86e9eb6d460;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1684, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcde4aa285a49fe76;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1685, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbfa4cf1f03315f05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1686, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h26e85e4a58ff7a80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1687, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d4ec5d773a66e7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1688, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'haa43b1af5af6fc8c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1689, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38dc197ec72636aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1690, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3765dd26c3764ba4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1691, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h991fabe813bbc0d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1692, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd0962e6bc143e25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1693, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h300936b6a38dfb86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1694, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0eb795fb6de33c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1695, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h137b7eb7994e58c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1696, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7ab91870dbcaf63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1697, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h637ace399205bbb7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1698, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6563b26be4e2f71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1699, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd37fd0af36a5ec34;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1700, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h95b0f91c7c402145;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1701, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc272d9623a1cad4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1702, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47d0809842285ccf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1703, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc8d7a26e3d684f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1704, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4143cede8da0324;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1705, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1915af78ed65a408;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1706, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e2c8b34eb9c3292;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1707, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e072fcc79ca0588;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1708, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h26f9006c20fa478f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1709, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a9aed14d9ccf79d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1710, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h083bf1009c2c3db1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1711, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3aed46a3968fa9ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1712, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d4657e92f473c5e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1713, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44dac0801270488f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1714, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5014260a52f366f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1715, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f4abdfbd4eb1ded;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1716, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36bf41df1fe7daa7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1717, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h633526a6bef57911;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1718, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd553ffce3056a3c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1719, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e343a8b089d57a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1720, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32d465ca35afa3c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1721, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hdd11dd843da625ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1722, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38ae1da7b06fc16f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1723, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13cbf08c55b17a03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1724, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4b8efed426dc89a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1725, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55f604ecb620e017;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1726, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h0fbbea39433837ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1727, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8cb44119873da781;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1728, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2208c3ad9dab44c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1729, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h692202f191b90bfb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1730, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hedfe1c16f4bc1827;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1731, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha814fcdc0c8759bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1732, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6fbaaed1874e5b3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1733, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd14d5822268193fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1734, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb39bc82b7dbb383b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1735, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb62fd61ae343fe7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1736, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd0419dae7ca6a0c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1737, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h176583b48ea3283c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1738, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1372a65b59d317e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1739, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1dcba0c9697d2400;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1740, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65ca28e58d74d660;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1741, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a63a5141adf5a5c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1742, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hedc139c381e3e025;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1743, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haebb6703a4d47b5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1744, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h36b01d90f60fe21d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1745, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a42891cc5e35599;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1746, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ff425e1f3661a2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1747, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a4fbc804fc24e50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1748, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h03de01372c1884c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1749, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h192b71b524d9a032;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1750, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd61a1353a34e82a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1751, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec221e70f39fed27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1752, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0679681c4726f0a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1753, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1713192e3d888658;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1754, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdce47d82e3412074;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1755, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47112dcfdf6491e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1756, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd143eea73f416374;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1757, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2aff951e3edaa57;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1758, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h155d3e18d8640888;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1759, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h400f0c2953cbf79e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1760, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77d37ae4a448b872;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1761, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h135151cadcb59697;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1762, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d2aa9c774d7f156;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1763, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h635e295f26683ddf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1764, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20f70cbb70759429;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1765, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7a93cf67138dee7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1766, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd657b399bf854915;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1767, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf06b151d91705f92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1768, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h238c857665501df5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1769, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d68218a5aceb43b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1770, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1be7763818961c76;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1771, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa487c9be66f564c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1772, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64bfae69f219d3a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1773, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb18b1052cfeea0ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1774, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50ad0a5dcc172fd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1775, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92de67b13bbffc82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1776, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcfddcd6e5ec4f97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1777, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he36c7b20e15b0d63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1778, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he18fa84ddcd79f8d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1779, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7371d6d93514c609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1780, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h08547a169a7972ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1781, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a61dc4555dbbc48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1782, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee766695e204c9f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1783, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb60ed970c45dc35e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1784, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h12b49ddc73270f66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1785, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc79015f54b9f92ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1786, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc084b5f65085316;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1787, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3206b3e3d2877b63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1788, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6968af7bc3f6b179;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1789, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ecd9e5419e30899;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1790, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h34f3c32fb7553554;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1791, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha6cf38d759ed0623;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1792, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61cdda431329bc98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1793, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'he09b9309c5143354;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1794, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h587a2fcd9684147f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1795, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa7d2ea8306ab476;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1796, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd6d4f4a73daccf4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1797, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h67c2ef6347ba9e89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1798, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d9db550e6c288b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1799, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a2a586616e36df1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1800, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3d427297af77c7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1801, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff904cf17a8b52e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1802, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0f917ceaa91b4fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1803, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d8f6f715b03a9cf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1804, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9dd803f0b8f540a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1805, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90223c1785e178d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1806, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ae12cbb7211b6d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1807, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba14915878fe7298;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1808, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h983437b610e6503d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1809, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'he0c731f63099cae2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1810, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b07a0124700647d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1811, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c5c1f89fa7c5c17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1812, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h00efe30b8ea642e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1813, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e4b403d1f84e708;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1814, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0106ad613bfea36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1815, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d1ad8549f80ce6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1816, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1fff9e539f079132;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1817, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb933c818b61f598;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1818, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9207f186330b76d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1819, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74aec9bcdfb2bf1f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1820, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52e07ea3dbe0eb5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1821, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e6d46fee580f417;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1822, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbb83887c8bf2819;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1823, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb71a181bb2c99f53;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1824, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hb5b444c65a243efa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1825, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44fadd312bf75011;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1826, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b9483ca5c6c771b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1827, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2df4bbd39de38b45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1828, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0ad386404ddb049;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1829, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6508df3ddac50892;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1830, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09c4c465bd145e19;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1831, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h288487f27ffeac7f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1832, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e6306499322036c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1833, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb05c6deac5ccba6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1834, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc2496cb115319069;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1835, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd6d7a0ec5950011e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1836, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc940725c30c932d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1837, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hebe9c13722f46d3f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1838, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hda705c3e7b011d13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1839, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h319569adfc597140;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1840, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2da202869cd8998d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1841, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h852ae5c404341137;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1842, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5b4aa7aac456b74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1843, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0e410c3207937cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1844, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc80902209d055231;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1845, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea023b94cf7bce21;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1846, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h81f8ace286102b2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1847, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d3d0fd45b1309d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1848, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h550cae0f7eb19068;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1849, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5105833fe3ec7363;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1850, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc840d86610f63aa2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1851, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57a8e8cf234ff2b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1852, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45c739fe17ff8c02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1853, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffdd08835c44bfce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1854, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04b87824b908bc7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1855, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h541d502e63fd6b76;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1856, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43d2c3999c6ac4bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1857, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ae5464edf79b011;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1858, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdbe9605527e138f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1859, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h485017f2b646e207;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1860, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf32709ff46d99be2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1861, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h070cc3cbef5086f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1862, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e28507f02ebc970;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1863, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ecbda4ff75fb510;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1864, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0face08dd3fae5a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1865, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb87bd977b2166185;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1866, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69e20f06fa6df4c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1867, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa74a5553fd0f0b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1868, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2683707263b9e5ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1869, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1034454b78f91bc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1870, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4cda750d2e6e3e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1871, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he308f4d0e8395f6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1872, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd84ff6f0d37867d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1873, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h337e2e0e846b3742;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1874, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f7517541a12ca61;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1875, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc30523a988f28385;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1876, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09401e328f2c61b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1877, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd26082cbe92d4025;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1878, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6f38f24dd595265;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1879, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h47ebbb3aa543a4f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1880, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b1ada898948d8c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1881, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h292c35f70bffd1e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1882, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfbbad9bc2b508270;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1883, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h605de303e7f141a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1884, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8abbdd6cd748b338;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1885, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b9d6ed8d0416f21;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1886, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had4f4541b90f59e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1887, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he517741e31849c7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1888, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9e740c454bbab65;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1889, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87199b6364d6cd54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1890, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69c310dbddeac3ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1891, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7824ed5bd81f8e95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1892, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe4fc3fb21ef0828;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1893, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f5880f87e46ba48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1894, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d0f460f3b3317be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1895, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c7f2e66ec5a9cc6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1896, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18d931aaddcaef63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1897, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0fdc8a42f3b3e24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1898, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6580ccf4cf0911a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1899, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9b94ebbdda1fc9e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1900, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he831fd0fde40fe34;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1901, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha951144033823423;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1902, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf035c3b628963c26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1903, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he649df5bc020f5c5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1904, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7db52adac6c775d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1905, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc09b7771ab72b0d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1906, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0013091d878e21e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1907, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h8578d785cedb5a25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1908, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd964c161f2cdfe08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1909, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56c4c7e3cdd19d86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1910, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc604a3377059296b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1911, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86f1f9abfeeb7f89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1912, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50a456a807e2fbbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1913, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7d552d16f157eb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1914, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b7e46fa54610f68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1915, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha1911236cff2d915;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1916, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1613d2ee49ba3e3f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1917, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23cbb38f18b71594;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1918, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0cfc5df0c2993fe2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1919, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9806da08de387786;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1920, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h98bc5177cbe9db08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1921, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b525135f815563d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1922, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19696dfe3fa93f4c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1923, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h438adc3dc4891003;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1924, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hab6d41bb6377fa48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1925, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdc1dcd578ed3bbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1926, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5ca8496d595bcd9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1927, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1828ba369642d382;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1928, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65075e1fc16f8e82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1929, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35621e15e2a25b17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1930, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fd7aee69a75bdcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1931, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09b2aa947a4db01a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1932, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd6c091c2b5513607;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1933, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf503512e63a68a4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1934, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hc8732d8fb5f0db73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1935, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h6864182e0ce12ecf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1936, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c0b1c96adeb4a0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1937, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a71fac985d76290;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1938, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f2dd8447da5ebb8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1939, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa1e852713471e6e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1940, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bb82c8e47a7339f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1941, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha75f96d2a0b8eafc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1942, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h91132229deb556de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1943, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e409ac737cb660f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1944, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e685e84889a5f05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1945, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9239a26f073d264d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1946, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ef906e74f0c4efd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1947, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb1ec0f0da193643;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1948, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1eca2e11d06d49d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1949, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f994f38a01469d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1950, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e9e9165d43bee9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1951, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h0101bd74b320ef7f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1952, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90740c6232386d03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1953, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1206b3bd4128abca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1954, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04640c1a8c05d038;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1955, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f76f3a567f4c976;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1956, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7db30ab9b894092e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1957, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hebb18f4f42b30f8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1958, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6737913ca0b8cae7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1959, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3a4821230ee4aa8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1960, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1cb91c4a13c7d20d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1961, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc43fb7070b02c8a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1962, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfed602f1bc60c65b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1963, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f90c30ca473a87b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1964, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf124cd1b5585a99c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1965, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0a4c9bbbb39a32cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1966, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0000db2bb1421172;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1967, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbed0a82b89b60f81;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1968, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc21bed8b159da78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1969, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ebbb0104a539c7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1970, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h556af307f867a6eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1971, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0103a4e8b53ee37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1972, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c9008cecf632618;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1973, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h575d04a3047ba808;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1974, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d9bbf771f4f7970;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1975, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e56478a3066fd51;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1976, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71bd9eb3aae019cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1977, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h422b09926d5d9181;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1978, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a9e0475e02d1b66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1979, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61f008c879f5a741;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1980, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd4fe5283f640723;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1981, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60893caa8b37dcc1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1982, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a8ae671f40a45f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1983, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h16507e3a0f8aef71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1984, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2461f4d7f0e9a729;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1985, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc2f83d53f85f56ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1986, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'he82341fa38fac175;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1987, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h723c2b23ea60a32e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1988, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57745837e8b57c7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1989, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e00e81c7389a35d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1990, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he60abdb8a1dd32b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1991, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h07cd9e94b6b522bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1992, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2ecd706f896453f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1993, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he951003c5e6fc4e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1994, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h320b6cfd6a6390f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1995, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hd664d834580a1880;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1996, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha15c0c07e142b6db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1997, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee10ae2eac1d71ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1998, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2c06ac02d7ef747;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 1999, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30d08b8e72388db4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2000, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f17e462a2ceb9b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2001, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h906e810862c0e45d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2002, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32f71d5e17f5bb08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2003, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h7d3c1a638fbf7d5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2004, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09929debc8bf5b31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2005, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc471de66c0f4f891;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2006, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3c7f47fc654b37f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2007, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had7a062da3af1bf2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2008, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4444f43244d6274c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2009, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b3d3e4d6b53e310;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2010, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd0ff5b5eb668f68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2011, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10745798db5ac43a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2012, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf9e301aff93db48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2013, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a3c0e73596f8741;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2014, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3998dd212aaf497f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2015, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc131dd81f59d605;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2016, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafba1bb354f1d853;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2017, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc618a4d15ee18b89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2018, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haafa1653f5635907;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2019, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he12542ec015c2af9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2020, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79697c3cf3eb55ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2021, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ed078c9aa7b40fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2022, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14b13d447b9d289b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2023, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66079df46a01b82c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2024, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a91de68e6085bc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2025, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41b3614cd40ec250;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2026, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c06b9bbbd76a881;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2027, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b6978b47f2443da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2028, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb3e85e6c6b83b19;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2029, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f0bd43c276b1524;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2030, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70dbbd8af31ef720;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2031, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f228b1a360fc9ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2032, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9f5c20dd810d4fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2033, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc48c316cbaeb35c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2034, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a62f6364b41a289;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2035, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71a3c749a8da6404;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2036, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h032bbdcd3c296e26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2037, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h947c10831a487a67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2038, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d60f96ed5e8ad5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2039, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h82a6593b02cfa9d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2040, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha5b4557b50129327;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2041, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44e01f535ef29487;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2042, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h658cc17829c6c570;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2043, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e58cd3b150ce10a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2044, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h536909739bbc6e75;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2045, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1eda16fd0cb9cb5a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2046, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d658821b1d6354e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2047, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc750f241593fbe14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2048, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4678bb90f1215746;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2049, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ddf025d2ecea9a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2050, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f49acf090b79cc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2051, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41df3da366d02df1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2052, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c876125444e7110;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2053, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74b3beeba51c4008;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2054, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he377bdb6809d464b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2055, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56cf912b0ead2b9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2056, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9802d0be2c9a936;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2057, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbf1930317c5313f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2058, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h275a20e199b7fe8d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2059, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h601d239bb28eb528;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2060, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc186be811b5c321d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2061, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd4d6b26eecee3a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2062, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8d9357698c0d0bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2063, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he139e5ef5c1cfbe8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2064, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31e0ab39db218c69;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2065, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e38937e63592405;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2066, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hce25a45093bcdb4a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2067, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bb934dc25ad3e1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2068, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb093097e8f43c497;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2069, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h499d44dfe16b8944;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2070, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3d28c1f028a1e46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2071, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h683a5ff9e589e856;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2072, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d1392d86814f92b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2073, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d41097a225f2c11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2074, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99fd1f9c935f230a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2075, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52034f89b4f8ea20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2076, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25070efc20ad93ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2077, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd39b08875a6ded2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2078, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa1d94b802df9c0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2079, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hee5149ce0d306acc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2080, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1aedc721bbb1aec6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2081, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he6ba16f04a3914ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2082, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h967cfd540c41f5d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2083, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb64c67fe9efad220;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2084, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6faaf5c3cdfbfaa9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2085, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e8673cb1ad40e42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2086, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4447025964fc527;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2087, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd376e84d27aac2ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2088, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc95c622a231ddc1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2089, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0de6f0236889325;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2090, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5af7265fb359840;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2091, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha5a8f4dfdef12c02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2092, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf93d4bbdada63af0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2093, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hf4cea6fcc3cf57c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2094, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6bf48bd18a9eee97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2095, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda3b1cc9d29d4a11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2096, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b7e6119e881e62d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2097, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h684113e7d7fcfe3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2098, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f88e61d4616054a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2099, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6a771428691e749;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2100, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e1ef38672241349;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2101, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5cb209ecd786fc67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2102, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06e84cfd7df26a8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2103, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15e6e9cab6f266de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2104, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b4100831a2a1234;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2105, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4fefdcb788a1c469;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2106, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79e35df7f985ce0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2107, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84627c8ae286aadb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2108, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5f6a2a039a0cb77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2109, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hc13374a724eb19f6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2110, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0df5e56a815899e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2111, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he97b04cfddc1f3db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2112, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hd7e292d68faab9eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2113, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbba2ff810b699c07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2114, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h531373d86e28c2ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2115, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2fca3e67e7c02fa9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2116, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7401fef98ae65700;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2117, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75bf4e371280e2e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2118, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h741121091cdcaabb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2119, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5baa092ebed326b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2120, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5f36af44e6c1909;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2121, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d28bcf0a587f25f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2122, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf963c1292f94a818;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2123, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ff3a9eae8b8f42f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2124, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f10dc89105f46a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2125, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h160412b2b268930c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2126, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6c26a313af9c69fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2127, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a37ce68b437ddec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2128, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9273dc1d19f0790;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2129, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb36528857cc39644;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2130, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd1d6fee2b6eec88b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2131, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d5cf95ee010ac02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2132, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1986a2e880ab632e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2133, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea71715709688f96;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2134, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9eddf22d53b13eb9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2135, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e24efa37a548d54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2136, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1a89676c95608ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2137, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f23d81f6999ae85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2138, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h3dfdbbc075baac24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2139, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8f09c4278d9df1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2140, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60fb5c565480f71a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2141, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62c5d8d8f6b0094a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2142, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd96b4b11964a0c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2143, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd388b748545f0d80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2144, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb08bbc912d0c30c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2145, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he22bdb31b449fde5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2146, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd3766b8fc8fefc3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2147, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc2040062139e9fb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2148, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f5f452d36d425d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2149, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c07d958d73b53fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2150, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd45f89689bd8ecc0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2151, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8cfa343324a6009;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2152, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20f01ef3ea138360;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2153, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ac21bec4a4bcd24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2154, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h974c995f2cab56b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2155, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10edf0112089afb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2156, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a5f9c23ffa5056f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2157, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6b406d00b0ed79b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2158, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d39d725fc94aa63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2159, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h80bd2d42ea950873;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2160, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5aa5f76d3f10e7f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2161, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7502574d055e1a73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2162, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4047cdea0cab671;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2163, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa72b9d23fd2dc5f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2164, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11100bbe0fe4490d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2165, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fdcc89ee19cd890;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2166, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb749de699bace3e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2167, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h275c0c9784c5d250;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2168, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h61be7e958fb5c5e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2169, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53551face3462b12;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2170, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h89dd8059c17f62cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2171, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77433ceb0f2c97ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2172, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h0b77eb481826a515;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2173, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f204e25e9966fad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2174, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h8e4d03325bfe1633;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2175, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h12db838c107eb641;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2176, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b939c3f803ab61e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2177, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85e4a628a1677acc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2178, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2592297a2c759c97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2179, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d3ee49de88f1fed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2180, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h25f76ab0e92adc1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2181, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6411c5e9f3aebe9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2182, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee37449dcca61122;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2183, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed112fc245d59f1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2184, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41e4eb17314f5d77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2185, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h99526be746009681;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2186, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92bad65cee1f2fbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2187, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h60daba1a053fd50d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2188, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc45f230875850be6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2189, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h937c9a8cdf83b910;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2190, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77d8b661430e64d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2191, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'ha712129c11ae5575;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2192, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d09ea57afee84c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2193, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2df3d3691b16226b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2194, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h39a9a601c4057d82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2195, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd1e39ed22f0379a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2196, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a352e61ff7dd68b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2197, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda1458aa50537b13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2198, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94bdbe5d9ef9e215;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2199, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56a1186182496f63;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2200, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2322c2706951b7a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2201, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43165a3f21068024;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2202, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ff5d662d9a3d07b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2203, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d2ba23354936567;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2204, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb440438d9db1adbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2205, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ba4588f45140c9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2206, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb4fe47f1637dd49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2207, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6722e9697a46ef10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2208, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fd8725cefb064b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2209, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bf24b4f85fc6489;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2210, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfc499705aad5c89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2211, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4eb189c9d9fa7e98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2212, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7cf972aa838c61ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2213, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef30957097d8ee26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2214, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76447f2de8c18225;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2215, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hd7090c3cfbd43f1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2216, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb46c16366e9dd270;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2217, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd8585f901a18d14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2218, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31353367526aa194;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2219, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3906ac9abdb45516;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2220, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf74c2f3eada0ee5c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2221, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h27d0bc64412cbecc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2222, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1178a82da8ae3fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2223, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h409efbf6d35bedf0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2224, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9182550f6d46897;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2225, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02a144c40aeb8ee2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2226, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h180c8e43c3599be4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2227, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hbcb1d8aec6ae69ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2228, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc270a0a6d792f196;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2229, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc8b556b72736c19;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2230, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h565f68c1cde57aca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2231, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0aed0b0484493687;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2232, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd60b4a84792d2014;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2233, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h34c67f476a76cb48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2234, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25c45e4663bb5b02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2235, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66491b92f1a5bd55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2236, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h56b7fcbbdd89b82e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2237, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h348b9f3524d0ec0f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2238, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cb4b3c645ff90f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2239, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h53824a081cfaf135;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2240, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd95c7fc9804ab3d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2241, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h753114ef3b13c804;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2242, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87e5445d79b204dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2243, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf19d79fc8986d995;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2244, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h1bc5cf577e55fdf6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2245, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha7db034bd8113e46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2246, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7dd5e82fe40d600e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2247, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2aa0af79d25c0087;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2248, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc20fa5e0001d1f3c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2249, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0bb1b101444f805;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2250, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf24c11719e97a8d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2251, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h131e91a95b2c066b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2252, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a51b07877514133;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2253, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hda04eda91384dc4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2254, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9509ae909234bc71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2255, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54da8393943169f5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2256, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd56acaf90c7313b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2257, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h75fc06b1feda3eef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2258, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49e2af597a9f9abb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2259, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b01c391a0a81c16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2260, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed603a42b9ac87bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2261, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd723bd870623cebd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2262, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he7e29fa205b1e6f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2263, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2881e23f19005563;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2264, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h265d2967b6f9bfe1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2265, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hae4998d7c9f1b5d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2266, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1b1c57cc8ffb1e20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2267, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ad176e26d8059c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2268, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3692c72e932fef9e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2269, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71c5eb5de9f88c29;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2270, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8a7c9be5579b548c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2271, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a4518b8aa08416d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2272, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hcc838a579c6d11f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2273, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3a2bfd1003864e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2274, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hed6f82f6a834492c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2275, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25c7dc5ea9f6f0e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2276, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5aa8c8f6e378dae8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2277, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0a1b5c91c3c9b182;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2278, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb84f8e91a83f2c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2279, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb08b5133de899e03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2280, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14a55a132fa47fe0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2281, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbddd352a93127cc2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2282, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h252cf8d086b73a00;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2283, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0eb78d3274d799a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2284, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9fb0b8d9af1a1807;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2285, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8661e2920fa26d26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2286, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h72e48c96bf8a31a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2287, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0629b341306b2258;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2288, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f137e52650098c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2289, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ccfde5d25706f2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2290, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4c6da1fe62b0d8d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2291, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23e4a52b0dde67b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2292, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30bb6baf39260d95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2293, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33ec678a7dc51faa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2294, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e125a5c2f4a4562;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2295, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h73296ee1d58bd2dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2296, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h485ddb6e182f5554;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2297, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbec768205facf7dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2298, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he63df5fdd2fee256;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2299, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d46c794aac5397d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2300, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h810bc863f73a05e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2301, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h698c9abda609be68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2302, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafd628e266ce73a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2303, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc87c98f184862ce6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2304, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc338655415da47d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2305, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe78e2ad6724a713;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2306, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h3bb81f1966a93a75;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2307, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf19867f021fa19c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2308, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h22f99aa686a29f0c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2309, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fefe2f20123b0d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2310, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2b5d3dad0d66540;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2311, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51943b9f8822f235;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2312, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h197023e3340e25c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2313, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31314f33baa8d472;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2314, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc10e94cff500c249;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2315, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f0fbe07d7045491;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2316, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h380bae62797a81bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2317, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd4fc8eef1e29cf54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2318, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h92d689c0bf56ec7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2319, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a6e3a2f89830fca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2320, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h929c5332c1737126;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2321, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e96021b4eac3da2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2322, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c3bbc58d2958454;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2323, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d4321d93cb2aedd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2324, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32d552b50a1d0861;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2325, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2e17615ccf838bc2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2326, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4585052e75225764;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2327, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbbd035bf7652003f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2328, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha71644c52877f4b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2329, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5e6502a9a27aea6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2330, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd15f1e2f44b3b7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2331, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28d7516245e41fbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2332, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h54a64daa37188a39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2333, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19408a04b74c0c7b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2334, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5d3dd1246f93b36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2335, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h96af40a3c2520c07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2336, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3e0a9533ecc52be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2337, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b8427759c14400f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2338, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a0be965076678a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2339, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa1ace5e8072777d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2340, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2092c818f188bd9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2341, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23bad28ad0827a0c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2342, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8cdeee8ec2253f16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2343, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1df6511755786fa0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2344, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b920ed47b0c25f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2345, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ddc0d74470bb5cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2346, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h46b86af647486377;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2347, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h753f32cc086ec6ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2348, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2355c44e73e7ef82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2349, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21733521b6303918;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2350, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h67a508f915277a88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2351, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3bd042bdf7d715a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2352, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a3fe2e727f24ee6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2353, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25ee657892e985a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2354, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc909410203e4d56c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2355, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h380aa3f4d781685e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2356, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfa5da3c9eee6ffb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2357, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e1a6994fb1959b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2358, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a81d612a7665fb6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2359, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc03038662a887435;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2360, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0af123517d689b54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2361, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h616898c69f02c894;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2362, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h9c1d1dcec55a7b56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2363, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50a0e37def68450d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2364, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cfaa5e4994276d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2365, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde8cdd26eac7c516;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2366, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h628403d6f44c961d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2367, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9ee64eeec18fef1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2368, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb406ebd7b5e44cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2369, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hf05b0a9077a9cbe2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2370, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0eb61fd64bb8715;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2371, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4482cfeb89ab5e06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2372, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f89b3402f8890d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2373, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd1be00ec8f0fcce3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2374, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h42c4ec3211e8d0d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2375, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61a0dc794d4a81d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2376, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h1bfce0b9d840ce4a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2377, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h480800e48e69392e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2378, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a31f0e8443c9584;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2379, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ee49d0e9f9cae7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2380, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9d5edc721692857;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2381, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc82a6c4ee3f1575c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2382, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8dc2116c38979553;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2383, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h12f9b9834dbd5ed5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2384, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3bcadd8dc6f10c4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2385, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc37c9f54a3a202df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2386, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h144616e8236442c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2387, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f8d897684362b7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2388, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha1937fe25c2317f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2389, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d691d3160bd325d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2390, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h179138f67e18eae4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2391, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he11924a37ca6a725;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2392, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f11ad08460a194c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2393, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfdb81c7f73f47c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2394, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h652aad761758b77a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2395, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h93959e90eddf3ebd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2396, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7777e8097d5f46b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2397, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h821cda0150de1e12;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2398, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3a3f1a513ad1422;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2399, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf384430eed701460;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2400, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5b9d6fc604454aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2401, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b399ab6aa2b26b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2402, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3db711950706c54a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2403, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7434b5f798f182e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2404, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98189efdc76877fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2405, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64d5a8ba94f68498;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2406, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98a1de37180536b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2407, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e21e899f4b1418d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2408, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hc96bd0fa0d161fbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2409, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h536344d61a0336c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2410, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe5d06797c39c895;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2411, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcba427d3168f8287;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2412, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h173d298175b8dbcf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2413, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc51ccfd3c6e366d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2414, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h9e2bdba330840fc2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2415, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e326432234abf85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2416, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha7d30d1fc06646d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2417, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61c929792b18eaf9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2418, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e4f72d2981cee62;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2419, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0e3a7e1ae194414;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2420, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6c2beaab4a402c1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2421, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1496188ca368ba74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2422, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54d481051be19105;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2423, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61c56f13b16183b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2424, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he9438853cdf01cec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2425, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41e4c7b3ce2d4bb1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2426, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd41baad95d4b7d36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2427, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf84a70780351d23e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2428, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9625275e3c422f3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2429, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7da28ecc312d2029;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2430, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h196afe46412d9310;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2431, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ca688124fe663c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2432, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h268631cf44c71de0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2433, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ce3e7ffbc1d4459;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2434, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf29fd4ea7aa36b09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2435, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb73dc467784d6b09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2436, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c0a4ca0e083deea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2437, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19032801164fd26e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2438, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h561d4d4615946cd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2439, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fc2c922968aaeab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2440, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hd54fece424eda604;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2441, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h81966038a04371fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2442, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c3454553496ff17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2443, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfcbe79ebd2160e0a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2444, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4f1e0e6f2a72993;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2445, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h064993fc0da37817;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2446, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h059f5df49c36a6b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2447, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5dc231e3e8fe29f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2448, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ef24898b08866f5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2449, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h07555e65aaa25fc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2450, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e9b7c6a4156cc1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2451, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0107a51c97ffc8a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2452, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef8767053a575638;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2453, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a577411c4fdbc1d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2454, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1ff984fe66cc312a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2455, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdc8b1e7ad608c49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2456, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79ae9182e298f534;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2457, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19e5e6b8ad057a46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2458, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h6b70f81641c4da5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2459, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37783c73157bc586;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2460, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb8eb65b3d7a593b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2461, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3449681eff350fe7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2462, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa68375097738f80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2463, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c4e284d0c1aece9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2464, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h136bd8171a8290e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2465, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he6e7d7096353582e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2466, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6a6687d22f3fc01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2467, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8dd41591c387e27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2468, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fedc14f036f9f86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2469, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b434cb180d64865;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2470, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79533d09c32423e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2471, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hb60bca5aa9e66684;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2472, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb47d80422bb56583;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2473, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h698a844a43fd753d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2474, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb169ecc8c7fe74b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2475, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he46a73f17862f3a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2476, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0419894b933b9207;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2477, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he11506e22da2773e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2478, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h527fd62f20f78aa7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2479, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25a110e47111c3de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2480, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'ha0e0d6cc6165d7df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2481, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe8aa6ded7ea64b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2482, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he798f533cf0e267f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2483, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37a4e02bf8bd5abd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2484, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h26aa76e2379c568d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2485, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5a28ec934e12856;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2486, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba21ac3242e607b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2487, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h003d96512d230746;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2488, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e470bca59897bfb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2489, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1b8613f87faa0653;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2490, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6331507999235cc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2491, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9b77ff6cdfe31c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2492, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1989aed569fa9544;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2493, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h013e034a67e46ba4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2494, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h4ab239c743ee56d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2495, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5b5cc053f418ec7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2496, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hc84ccc6d7efdf171;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2497, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he58056d1ba8a6886;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2498, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01a78e8593d6a1bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2499, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4dc185874e9ec2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2500, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e9bfa0c79874515;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2501, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe853965239df3c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2502, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h900b5610f5e8c6cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2503, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hea32cfb5115b6587;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2504, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1fe7fc3ec0fd6e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2505, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2517fc3abe54d007;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2506, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa0e1e6ef5274fc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2507, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9839292e55764753;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2508, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5781dc1fce5cc0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2509, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h238b879050049f95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2510, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d491dd6ae516111;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2511, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ee2f309567d6b01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2512, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1491f9ba3249c42c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2513, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c60b83ff391279f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2514, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6777753b346c410;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2515, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4345092f64ff885e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2516, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87f17edecc6ee93c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2517, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ddcfb152652ce71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2518, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff9cb52d6a239db7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2519, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb12c3df5fe64266a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2520, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52c90ce546c0068f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2521, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1daf82a55ccebc2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2522, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h831d8f2bc8ad170c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2523, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4d37cf798b7439b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2524, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf97b6d078c1efd74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2525, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haee626fc985209e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2526, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h3136d0142ceda7b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2527, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba84159b7f5aa419;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2528, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'he94050cb8e28c164;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2529, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5af27c1ae8fdf7ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2530, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fb41ae6e53efa1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2531, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5150206acd5faca4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2532, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a4ca151d0be0172;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2533, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha011fbd50c9cb7fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2534, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a71cf581c52eea2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2535, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4fec7a6c6415bcb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2536, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19a232d8e9ce9719;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2537, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb27970f7018cd4bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2538, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7fa62db234c1bfb3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2539, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc6656875881f1de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2540, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f9a36da1a201d50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2541, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha244acd0f9b8a4d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2542, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'he07f6061cece6d6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2543, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20d7e8745dbf9392;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2544, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hebcc4b07c7777943;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2545, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28f711b284b9a8c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2546, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c3ca447c18caa99;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2547, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h343b2f392c7b0a17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2548, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h97bcecb6d051a7a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2549, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h289c923249590ee2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2550, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bb77c8a8ef9cf8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2551, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4f76ffbad919268;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2552, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3fd08aa5440c1087;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2553, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ab24fcf947040a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2554, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h7a27cff7f64d1018;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2555, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he90b3c7e9cb04c1f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2556, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5159974db370ff68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2557, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e156af725780d5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2558, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9eefd1a165992754;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2559, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h829b4af51fddccc7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2560, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f6ec59ee0dc7cb7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2561, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19de6d34716bf692;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2562, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he81a82bfa018b37a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2563, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd0362c27a78e31d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2564, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'habdb9926ca719039;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2565, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b5f52421e007eca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2566, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fc8a5fdac3862a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2567, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c0faf15af566b8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2568, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hece531e0942f7370;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2569, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h640c8dc2b04e2e9c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2570, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6279e10629a3209;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2571, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0bb305cfbfe845e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2572, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h80eadccb7a005452;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2573, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7299355a43129c7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2574, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a26f126bb2aacb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2575, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b2c8732c4d35665;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2576, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a14fccae66275ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2577, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1fad8596be3ac402;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2578, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h95111edfa75d484f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2579, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd011485d2419d82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2580, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h87009f3dbc8e70de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2581, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc152263ab01683c5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2582, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5aa9c7f3920ab97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2583, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hcb06eb797eb774c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2584, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e30e7085ac5bcc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2585, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31adc0191c73e6bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2586, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb78be74411ac8bd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2587, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h809f9ac154d87e35;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2588, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7dd40b2181d97a97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2589, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h200503e3d60a2069;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2590, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2231c1c5f00b880;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2591, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64bcde2476b2a42f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2592, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9dbc82b5b7b2daa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2593, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92e56f23a26626b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2594, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h459a54c49df56401;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2595, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h896db4d361e7b7f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2596, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h3847cfab7799480a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2597, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac3c558c75e58543;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2598, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ff848b6a3c557ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2599, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac878b401e8fe0b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2600, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdaa8fdff731e4ec5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2601, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06bb29562332f961;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2602, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h72fe892af45cec44;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2603, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ab904fb918fcd3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2604, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he118fb02f2a2a9f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2605, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4142c86f3a2f2461;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2606, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58fa64fe13117394;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2607, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfc448ccc26ef3988;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2608, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45a6ba74d8a0a4b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2609, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf3103067f694813;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2610, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d1ebd6fc59feaec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2611, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haeed08112b829641;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2612, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5c84981f93c2ce8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2613, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9f1e7fc8ae1722b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2614, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff2600e48e6792de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2615, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6598ccb4151d4a30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2616, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h616a3f770c02c25f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2617, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hedbdd3127c014b08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2618, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e6996a86c1ae529;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2619, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9218ddfe5de8a49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2620, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd465ebe54605181b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2621, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b8cf68fa5e5b5f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2622, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0f88f42b949be2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2623, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce0db9a3d1919328;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2624, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8291d1db1a3662fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2625, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h202069941ea2eb84;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2626, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc557a143867fe0e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2627, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h195137dbdacc838c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2628, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61f38c07878378d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2629, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50c107bf2089c65b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2630, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd9b4b671401f4a34;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2631, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h2c1bf7288c03bf03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2632, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3bc4c2bb314c1557;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2633, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53b723ea9229a056;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2634, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h935f3198e6a172da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2635, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0bb8b1e282f5e78b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2636, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b9ac3a0c595fdf5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2637, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36b4e3515af5518c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2638, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c2c1eb3954c0eec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2639, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc19567f9ca4d8445;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2640, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hf611e289bcb57dde;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2641, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2198933d6b7e1d25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2642, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3ccdec53919daa0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2643, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7996c2b48320ad81;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2644, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1dafa4cc9d1b615f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2645, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0323f401fd24d36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2646, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5ecfdd3e854acde;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2647, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd9dd4e9088cd23c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2648, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6935865e6c0af03c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2649, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6f5a480b24147de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2650, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2725d21519bfda8b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2651, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h691a5c16b9340360;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2652, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hd8b5e5841929e26f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2653, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76eb6d671296d1e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2654, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heab4b70d0010add3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2655, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h67c130bd8bbb38a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2656, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba4dcbdaef3bf68d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2657, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc8bd0ce6c5bb80e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2658, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6bd7fac5d2d41df7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2659, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d4967db55cb0392;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2660, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h4242a499318b0f4f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2661, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a8bc799cb3b8dc6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2662, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e639dca4cd9c6ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2663, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7bcc81b20b3e88f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2664, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h5c2df8a684ad7628;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2665, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4cb6021a0d460623;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2666, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ab9c16ef3fdfea0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2667, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b837a342b341206;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2668, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ef559f0e424e3af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2669, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf02614a7ba728082;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2670, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29f57fd4b728affe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2671, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e61f75791d45d20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2672, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e3f76e23d1c638b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2673, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8de003deb4432b4f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2674, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71af9279f5ab8bbc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2675, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he565c5477eb22935;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2676, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf39f579e19ebfd3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2677, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa05c6d31a82e1f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2678, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h837d63056552b34f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2679, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h4c3233b955ebe162;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2680, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he26c195e14b26a0e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2681, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h602f0972577421d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2682, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6b58976f089aefc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2683, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'he8bb3ced925c7904;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2684, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b0e7f6568cdeeba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2685, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5be85216762b8f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2686, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hbb176a635da03e8e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2687, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h266c4a6a7cca5a15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2688, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he81e5f94a520bf50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2689, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h281a1c22d869170b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2690, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h012d7ae77317c597;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2691, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f17dd015215daf0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2692, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h616dabc094cecc40;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2693, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h0382037c8c09aea5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2694, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb5855dc172bcfdac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2695, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc4b22c86bba1b059;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2696, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8c74ec0b05e4bb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2697, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had412fe36d9bd2bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2698, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2fba281ab7867884;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2699, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4efff61dbb03a850;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2700, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h75dee61e4893a355;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2701, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hcc3ca2c8be8c1a1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2702, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1585caa5cf75452;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2703, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h23a9b5b3174229ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2704, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h714c13a8f8a836df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2705, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he52e51c3348ff5b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2706, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c4247bb979ca5fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2707, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h89432042fb645005;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2708, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e4958176de6ba60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2709, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6dbc1b4d514bd9bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2710, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h48d78034a25411df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2711, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a2429e18c452f7b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2712, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9718b8d7aeda2b43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2713, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5cfa598cc95a41da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2714, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62275502e017fd7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2715, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54166d91aa4bd4d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2716, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b26a59b41ddf88a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2717, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ec66a394fa3d418;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2718, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a5c16bfc3c9ad1f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2719, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9e690179e6ef118;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2720, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf6b7151a02557c5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2721, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ba4ea8b6123d891;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2722, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57cafb7b67b8faaf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2723, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbfea5f1086e04106;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2724, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he81ece925604ee3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2725, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9630b8b0c529f56f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2726, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf16b8235cd1f71e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2727, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h192d9249da36c0e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2728, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hcbca7eeb71f8a1db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2729, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe268ed7bee160d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2730, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc7f0dc4e1d8554fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2731, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e5fef9fc39156dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2732, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc63d0a2f8a70123;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2733, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hacf5a0a2dad91efe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2734, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf480a2d229d86c0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2735, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ba413454dd4d849;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2736, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0516eab7fffd0a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2737, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbedc8af811f104ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2738, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a83ed0c52b85736;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2739, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h858a846ca3cf3531;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2740, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea2922aa35659675;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2741, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49112ae8170e7165;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2742, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7748ee9708140957;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2743, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd965b454ad2a3358;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2744, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h16c01a456c6f1ac7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2745, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfdd5218a6e6cadc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2746, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a13c4ab846a35d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2747, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77ce9a720b4c72f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2748, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20d17169cb026251;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2749, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66e002f0e1603aad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2750, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd41330eb61b656d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2751, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc26d1427a7af389b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2752, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe15138a85621d74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2753, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb5e22f1dbea08d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2754, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ab9eaec99364214;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2755, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h4f1162e07f58d2a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2756, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h936b30e0112d9675;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2757, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24b3aa2c8141dee4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2758, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f40af1bf425b784;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2759, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb7af91a83f6991c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2760, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h371acaab9c0105ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2761, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h499375b80bbdd390;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2762, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd4be2492d096a87b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2763, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha13ff6169abac14a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2764, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5c48aa31b8e6170;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2765, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8fff5a7bb9ac7d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2766, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h2742e74c526f353a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2767, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h72c01f4fe28d9e43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2768, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5953095cd967e99a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2769, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc64347095cfe725b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2770, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h088cab53ed17eaa6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2771, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h39c04cf429354325;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2772, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0303cf11310ab34;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2773, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf1d9d04688603a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2774, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac7e698626270f24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2775, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2695de6e506d8575;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2776, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc64a6b7f22c996dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2777, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3eb27c1de31a02e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2778, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba541ba323ea57d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2779, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8712d95c80a51d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2780, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h1ab27e4a040a9052;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2781, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0fe44cded4b8f28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2782, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h014d8ce30a1d94a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2783, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd54b7eaea7dce32d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2784, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha60dc331d943e3f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2785, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1c9fd2c14af19d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2786, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d6bcac08908ffd5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2787, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1814595f1e1644b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2788, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b598d96bc0628c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2789, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb4388167787dce2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2790, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4cb95b37cfe71e86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2791, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7f00677c351944b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2792, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h03de728b1397f341;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2793, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdda0509e912ee25a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2794, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he3330e7bc7022fd5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2795, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70668ab872bf88f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2796, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e0be5fae9c56262;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2797, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6551f4b9ebe4c2f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2798, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h507ea859ecdda28b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2799, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h051d598c0c1d81a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2800, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a95f89b7a5a2e79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2801, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he611698812221038;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2802, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1eb5e7fc13d81ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2803, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h47d877ec31d07900;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2804, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7f3bf6c836c0f4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2805, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc1e620f88f78083;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2806, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hb1b7d911e9c47330;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2807, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h020ebced1a3177e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2808, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h316af474f3ae24b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2809, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef273866569b8aec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2810, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h34e531d9f4d2176f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2811, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88b3ccc4c44a7273;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2812, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e01462275a7e05b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2813, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14faff849bd756d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2814, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fc657f0160c98e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2815, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55ddeb6d82ec2046;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2816, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha236e26bc317d047;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2817, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d4d81529a7af7e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2818, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e59c2cee90de8d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2819, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c8f0230b0921289;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2820, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he958d83f7552d02a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2821, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf92ad415fe8165da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2822, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c4c03a82008af79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2823, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbf7ded6868d15ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2824, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32667013f75e6b53;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2825, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h22596b0adfa05c73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2826, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he101b293723f816c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2827, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d1886d0b678f81a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2828, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h9aecb0c517608c8d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2829, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h875690e1ee9e08ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2830, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha757587d8340f804;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2831, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha38205b2d8f9be83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2832, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71643053a41611e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2833, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24c6c98469e06042;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2834, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfeb68788c59cc57;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2835, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8238d68fe5582cd0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2836, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68437208b62a17e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2837, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa78f4fde330c794;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2838, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf3750905a38c70a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2839, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h729df13b6cfdb773;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2840, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h299d10b50b00f14a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2841, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66a79dbe5027b585;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2842, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e55e2d2c426d0a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2843, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h436890dbcab1c896;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2844, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6658c1a02befc9f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2845, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb78d712d81adec53;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2846, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5721bcd2fbc3939;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2847, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02d48d0d384e4d98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2848, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a79cdac5f43f95a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2849, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3b0f68ee55b8d5e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2850, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h13576f3adbd683e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2851, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76b5f1e713aae535;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2852, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h979d7b036d00db38;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2853, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h960b715e743f24b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2854, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0958dcde1fac4a7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2855, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19297779ac603f36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2856, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8232289c903576ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2857, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hefd528f4aa5b0d7b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2858, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d7ab39ce252cf1f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2859, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52a7876ff8bc0daa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2860, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he01453e997d9f375;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2861, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha1aa514ea523a278;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2862, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0eaf9ce54830e393;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2863, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0057f179840cbaca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2864, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2751dc2f53aa19c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2865, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b35b320d319486e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2866, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he43ac4a7206a0bac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2867, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4296237134c6c57a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2868, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20d28c3a664256ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2869, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h696f53974ba3ca2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2870, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9cf13a1e6737d4f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2871, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdd42ba3f29bbb83;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2872, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h076d58f13609f911;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2873, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5825156cadcb4563;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2874, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2f48718814b4eb37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2875, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h117458219e4a8e0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2876, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h91d49449072f68d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2877, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e2c4664ca287f92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2878, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59732f3ec62d49a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2879, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h177f9c4b16e00e65;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2880, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37915540365654ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2881, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff80ce2cbd96d16b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2882, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h691e79aaac1b4382;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2883, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb81019d6dc5b0041;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2884, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he3bfec0d694b0187;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2885, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5908c775efc6a501;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2886, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a9d1c92107c2179;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2887, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h52a6b67592f98cd9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2888, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5dac55fb8deaf0c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2889, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2745c6b4c36a3a01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2890, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hd850d4d03a8b4df5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2891, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f73d0571737cdca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2892, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2305b9bb5f17524b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2893, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74166461c077ee18;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2894, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had41d7d9405742cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2895, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3cdebdbd24adeccb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2896, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f36c6dcce12ee21;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2897, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'ha08de4e264b75ab4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2898, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c840447ebee21db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2899, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h073dd22b13e07199;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2900, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h80886fb2d86e174b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2901, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2817bae5132032fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2902, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e8dcf3bd550cf03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2903, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h822bd797216a67c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2904, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc444edbf292da68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2905, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59ead7723c8ede14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2906, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ea298df5546285c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2907, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd1e3254fce85e626;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2908, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60da7aa22f445fc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2909, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcc87abccb06ee86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2910, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha0e4e0547d18e710;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2911, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f92e304215160b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2912, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05b43f9125c1ce33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2913, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a9a4a3517ade900;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2914, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1a7849611967882;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2915, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb382a0a74929fed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2916, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h62ca1747ae04a923;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2917, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda001859159cfde8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2918, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h219a80a304dda6c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2919, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2f50afdd6359d6ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2920, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8175de20841f9d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2921, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafd6e66877abad6f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2922, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8aaf961f59b3647f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2923, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90034cb53c4af344;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2924, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd39d0e8626fd1263;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2925, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7425819463dfe27c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2926, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85082a6049e8f6de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2927, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a29dfa01ef2aa10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2928, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h41c9e66c3a077062;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2929, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc8465e3c3799682;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2930, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf2b9f787e30ec29b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2931, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c79f66205daff35;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2932, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hcc1b52d7f722b014;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2933, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cf676fe64d63ee2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2934, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hdc381833e51539a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2935, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd84298d4bb5fb115;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2936, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ae16bcfc24e3b2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2937, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b72cd24b6b9f3f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2938, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfcc724617fe43fab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2939, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h868b8b036b10d6bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2940, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4b73ba4a54f40de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2941, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc064c9cf62a2d12e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2942, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h79bfe73950ac7ed7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2943, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0eaca992bcd9f5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2944, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h0e42d08946cf6eab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2945, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0e3ef1d0fc385a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2946, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d09483a23419691;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2947, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5f22c32751caaae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2948, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h917bab81ecfd5c37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2949, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he09ee19004b44dcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2950, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef585070dbfba850;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2951, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11eaba55b0908d79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2952, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38f9b39f26c6d884;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2953, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f4e9e6d2a7babd6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2954, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a19ae7f2ef9f6f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2955, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h542490766ab6d5f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2956, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8afb6b7acb904fc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2957, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h2827a34448235fbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2958, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac9b25d5e4b22b44;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2959, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f3119b0f22bb44d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2960, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc355b0baebf460a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2961, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9c7bbd27021ac57;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2962, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ab16078ca715176;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2963, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h3950b8577eca0b82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2964, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h780776e70cf6c73b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2965, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74d360dba905ec95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2966, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4a9fec157a40dec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2967, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h60122d97802a9a66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2968, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18e8c41c7d5f89a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2969, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h734c94ecb77b2a1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2970, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf52daf214e4d23f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2971, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb2ed20659188ce9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2972, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76aa4b725490c39f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2973, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h295ec6be65ad7491;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2974, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a9a9206732a7cef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2975, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2d61f4125ce204d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2976, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h602d17b9882cc37b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2977, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfe809857badf2ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2978, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h0d8aa975806ce250;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2979, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab3978c25fe9c1a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2980, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d1ecad2451548b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2981, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44ffd26ed525c581;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2982, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fb3dd60a4c201cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2983, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd35755cef60b0097;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2984, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e55c1265c015fa5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2985, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3dc9af4b56eb4d97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2986, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h653fd004e5f67df4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2987, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78a1bfe744eaeed8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2988, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h762d56394d5c28f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2989, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc59ae86abb0153a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2990, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he28a7c597bfa1fff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2991, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58e93e65a7005b39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2992, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5272aafe6a6a9e2d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2993, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hc1c0acb76b94a14c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2994, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfdbed411616dab61;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2995, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcf54d07eb7c768c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2996, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa0d72b03f9f42c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2997, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15b8e7f7343fd4ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2998, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5cd2158e64acfa4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 2999, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h450e5814207ff272;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3000, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd7363c92da66ac0f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3001, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbc3bdb3e46b3932;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3002, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f3489025513a492;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3003, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h589e1ad1099eef91;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3004, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6faa998c51e09529;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3005, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5787d12fc0fe7f2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3006, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50e4c4b2a7b9a059;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3007, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc67f651cb58ad56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3008, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafc82bd02351a942;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3009, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd698f2a40fe923f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3010, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b6083f110a4b601;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3011, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfae04f87efbb7a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3012, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h544a6df94ebb15f6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3013, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he14e7da4ce6b0a60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3014, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ddf948fe878194d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3015, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h093298d9af5c86f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3016, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ffa6cbb9ba608ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3017, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h85f0f35d2a7e9818;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3018, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb89aaa462d579d3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3019, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd491de4bd797c93e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3020, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8656103dbb047936;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3021, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc38fb9b174c3318e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3022, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h110712e2d5c06b3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3023, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c1c6bf270b48df2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3024, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9336d09f905ca0a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3025, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ea7f58594b4dc33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3026, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a7b4177b5908e38;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3027, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7f380a9162b5b81;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3028, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h631c105460178c67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3029, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e5ba2b771d3987f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3030, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'he56c76d10333c26a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3031, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68c9bc9f64dda55d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3032, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf48ba514091b84f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3033, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hfded4d1ac6c7c0bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3034, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hc06040cd43717bc0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3035, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbfdc58b1406cb361;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3036, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7bc53786355a7f54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3037, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56b25305ba41900e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3038, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f6a1c3a541beef9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3039, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13e10cf93e50a518;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3040, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h529586c46b66f904;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3041, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9618d5a4c9b2da9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3042, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb22b8f5e938d8c30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3043, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d489f03091ea096;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3044, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9cfab50fce52b89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3045, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14055f4191d5c0d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3046, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd41d4a3333768e4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3047, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h4ce2802ddec7a6d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3048, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d707ba16f0ae00f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3049, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85c1fc3c9d55d26e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3050, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28503cdd0fb72011;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3051, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44fab656986369df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3052, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54ba42b465b47453;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3053, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he69b6e77aeb1d58c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3054, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h071193c30ab9e748;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3055, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc2b4e84c48811b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3056, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha58de01f07895502;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3057, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c5e507cef48584c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3058, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32819cf37be23b42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3059, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h03c49736a878b9ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3060, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hcc7b13557983d848;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3061, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a3ea49d71fc37b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3062, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8bb680730cb1e399;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3063, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f854bea87ad8067;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3064, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h905ae780dc112ef6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3065, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffafc35cf733d383;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3066, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd8ec5c89787cb0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3067, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h718b81b527e1897f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3068, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b3b82909b551666;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3069, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0d8a5798bf239748;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3070, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0bc0d3165ed1ca4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3071, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb659da2de358c92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3072, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hff51d63b59b659eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3073, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f7ba2cb0dd31b6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3074, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbf695933fd2ba7af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3075, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h986c8841a4a49487;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3076, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5099431865e6d1b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3077, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h741ae1c317d2f832;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3078, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4429fc2df85612a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3079, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba33f85a08fba382;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3080, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b74bc20484eaac5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3081, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha5dbc5be8172f728;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3082, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha76d67eb231f7a8a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3083, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4f2a5b23fc9ee54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3084, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7bc27de46529d73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3085, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha8f2567a12a3f4c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3086, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he6a2707e7b5f0b0e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3087, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hadf94991100a2d9c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3088, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc93c8f52e659503;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3089, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e8674f99abf5349;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3090, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85ed2f1b7bc02b14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3091, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4dfe0eb6ff61c35d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3092, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98ea26496ed81f60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3093, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e5d0e68a4759f69;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3094, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32aa2f23770dfbdd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3095, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2598882138f5f910;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3096, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hebc5a6bc1deabf0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3097, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf33c2d4256855e4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3098, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fa693b54593b222;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3099, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2a05108c19719ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3100, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15af2f47d7933609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3101, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd05ea661263cc17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3102, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he33ebffe7dc08b11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3103, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc19e6c83e8f82c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3104, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha915a480c5a63528;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3105, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h0048f26357de4626;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3106, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc93cb7f7ac7d5d04;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3107, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h2496e8f2592ed3bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3108, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a7e16b2c64033e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3109, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57d021ef7e0b2711;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3110, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0288d576eb58e3a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3111, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6e10a3f81fa551c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3112, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc98a76713bb1b1e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3113, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d24057dd1651172;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3114, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b07162e5919dfbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3115, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5d9c62fc26ad9bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3116, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h801799c6d8f5edce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3117, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f59bbca4939b8d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3118, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d55dcd3ba8bd5a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3119, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e93c981f2f30bd0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3120, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf657acb3b9bc3bae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3121, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h97f1d46b363e9586;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3122, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4654a7e0c96d36fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3123, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he38dc0c0c84652fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3124, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24aa04cf31b154c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3125, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hf79e2c4108fdcf6a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3126, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e3587698f8dd623;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3127, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d543e3a081fb33c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3128, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h095eb249b614e9d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3129, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3458d0765a4754f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3130, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h33df09182f7f2399;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3131, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h328f8638c9f09161;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3132, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h811552bd7f468677;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3133, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d7680d9eccda1e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3134, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a82eb72a7789111;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3135, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdb2135bb9857a39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3136, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc2226e9df7e46c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3137, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53ea54e607de69d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3138, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1f2fcde5ff21edfb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3139, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e0863eaf48bbacb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3140, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcea4e38ea349d18;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3141, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9fa685db2cb96d1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3142, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd68afffdc6efc4c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3143, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9dfdb1c9ece66bda;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3144, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d2bd99916e74ec5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3145, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb29d1cabdb16d5e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3146, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hca386b1caca89ad4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3147, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84dcb9d167b7f7bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3148, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44487060f5e338b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3149, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78fb9cfc43bcbe24;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3150, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3d7a10d7419e03d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3151, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he99305a4f779b107;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3152, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e361ca40eb29df9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3153, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76cfe913ef890784;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3154, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1edcedccbedf090b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3155, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h849743876ec927c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3156, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa4357895c7f03b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3157, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h42a3e7eadaa945b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3158, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda992810170721f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3159, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8bce887dc489903a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3160, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ec8120223ed1a6f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3161, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2122883dd9cae291;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3162, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd9051fcc2205791;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3163, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf851974c958e0262;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3164, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8181ca65a6a94328;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3165, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c889d6fba06606c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3166, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99ce4d2d98adbeb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3167, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb376c41e00cb53df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3168, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b8d3de81095ed39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3169, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43268dabe54136af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3170, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc81ee552554330a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3171, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h256467e9105dc077;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3172, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd4af1fb75875ce7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3173, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f6f6f2cd4b6e7f4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3174, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffed429bf04f7303;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3175, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e14febc0eca2ca3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3176, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h998b1fd2fb72cee9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3177, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e660d0bf9cacf2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3178, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18a8bc41e907660c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3179, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h353add81d0e17c1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3180, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3de2d7d2235c443;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3181, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5eec33d63bbaeba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3182, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h12753fc8f6e219eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3183, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36cd90f86ec6690c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3184, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h40fe5a67e3612d1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3185, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6952c0f6b5337d37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3186, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b628a0ed3af8659;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3187, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fc0da6bbe5517ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3188, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5f011299810de985;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3189, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbf5e113a36858bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3190, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d76c1b70a0a030f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3191, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h063a768750c10db7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3192, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4b55ebaa90e7550;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3193, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1809c80c6507b512;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3194, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h531c09c32f49bb72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3195, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfc868735431735dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3196, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77b71f5a85215edf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3197, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3011cd64460dfae2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3198, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cfef340b1260559;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3199, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98d667bc14bc0d91;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3200, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29bbe7901fd7e904;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3201, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e31b7f7b148b051;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3202, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h915637b5a75b0376;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3203, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90139d82d42951c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3204, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5656b8e49fbe5d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3205, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33690521a067aff2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3206, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h73b3ec7fe4a7fd2c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3207, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab0533c4be06a430;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3208, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fdc3c79ee387ae6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3209, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5269410532f9451e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3210, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4410e22a81923fb9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3211, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c3b809d0f84e781;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3212, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b6a5aa36177c261;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3213, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha8327714817984d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3214, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd179f8b5562538dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3215, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa62ca3b6c176a25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3216, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb78113a81aba3bac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3217, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b7ae4a31c85dcee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3218, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7fed551a591c42f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3219, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h531fbdf1d38f21a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3220, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b88c249eaf1f55a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3221, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7363213aaecdb39f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3222, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4938ec9432b4e361;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3223, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc03c01a086a8cbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3224, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2e81db132da5142;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3225, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd86348e8d5998868;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3226, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1141caaed69d9c0a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3227, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0571941787fefab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3228, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc640e05f6d0bfd17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3229, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd48e0c59c88405a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3230, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4fdbe2b2d90173e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3231, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h34b2142780afb7da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3232, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he9dea08cbf6ec14e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3233, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h065aa37a8660c3c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3234, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hc9f7b5a366c9e3b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3235, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3c9be04f745b27f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3236, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd991d293d46d2fac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3237, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a4bf54c21bf7c9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3238, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff364017fbfb6bc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3239, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13f4edba127eec3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3240, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb5594849bf0682b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3241, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he5817b47d6a240db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3242, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h98580d95340855ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3243, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d699c41e068ece2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3244, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h314388728dcfd6e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3245, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd90cf16cc37d1f36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3246, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd3eb79427ec994d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3247, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b9417221d7fe9ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3248, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h972ae915e695de11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3249, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01a85eaa37bfd28d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3250, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c879e6cc37cf56d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3251, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bf4d98e216c55c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3252, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h1d23fe409567559e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3253, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h3b7ebb82577fca2d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3254, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h82f0abb3662e4d9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3255, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6287d6978e9c04a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3256, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0d85ff71f80b685;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3257, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09604972ad6fb5b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3258, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d8756faf7f98e82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3259, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f47d6b340d708b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3260, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1b97126fd9f1e60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3261, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2521c807ebd66a44;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3262, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3490551508786541;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3263, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he83aae354ba2ecbd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3264, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h16909f00840e2a5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3265, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef6fc18b41cf5b0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3266, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h138d707943d2adfc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3267, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56c801127d69c721;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3268, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h488db7eb6c9237e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3269, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85a919030f523b9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3270, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea90155f5c4a3268;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3271, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc77993b3d38061a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3272, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76db22d1ec9a8693;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3273, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ca1fee40a3d3b15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3274, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h467632504f34835b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3275, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79216af93c378648;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3276, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2231b26702f3369;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3277, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66c2eea6031d5a8a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3278, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h007f9726d3a37422;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3279, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd7a3e9be6a5d9013;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3280, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h640f2980c1e25fbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3281, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfdcc18dc2dde9247;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3282, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11c1c7bc02492102;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3283, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21ff48653a798f64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3284, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9310d46b95ac34d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3285, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h245ff6c8467294e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3286, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h592f4ae7e1bc12bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3287, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f4ca3887b6fd490;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3288, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0269e58910ad5680;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3289, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h925fb8a4e90c8443;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3290, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c3e65d292a76807;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3291, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8142108c03e4e933;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3292, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hc2373109e2183075;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3293, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18a5239f7cca1442;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3294, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5c388ea30d26f84;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3295, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h166f447579a0539d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3296, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69ed8d042bfd080e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3297, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6f6b5f75b0028d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3298, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'he1f66ea7621a8437;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3299, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9b943d8cff88bb18;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3300, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde1c6de4c16192a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3301, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf7a9ec81016e519;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3302, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he9763c3258768d86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3303, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2b0fd442a57e64b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3304, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e247e40a457e51d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3305, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb75557b2d268fe6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3306, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75e87fcdf1fdc9bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3307, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0e09ec1fb6b0fcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3308, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h93b0983652794f78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3309, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he121f240598acbfb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3310, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hc5f482f2de5137e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3311, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe1df9d7094b1f7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3312, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'habd3c9ed65c5206a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3313, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd69698d13723525;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3314, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3141459e9f1f99cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3315, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6852831e21a9bcac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3316, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2756a6fc43f9ab30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3317, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59a82e7469fe61e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3318, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he553c9cecae1e912;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3319, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha90f05114d5e72f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3320, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h762195883ec58ced;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3321, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66e76f1282743c90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3322, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h496a04307ad897f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3323, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h46a55271387d65e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3324, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e12a671a062c58e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3325, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01aec3a1bb32c2b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3326, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h043197d9936275cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3327, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1de14a153ce7ea28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3328, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb167f14356389666;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3329, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h051af425d81a5474;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3330, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b73fa3eaf51dca6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3331, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h4f385ce943fbb27f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3332, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4c7b1641684e006;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3333, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hae016e755019696f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3334, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h7d1474966fbad976;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3335, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h89ee23d4da22a32e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3336, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfe38a51a6389eb9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3337, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4eefdeda3d7ab2a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3338, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h274ed19c62fc6cf8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3339, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbbd74b831a4a2209;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3340, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9322e77c0632ce45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3341, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5adff1f08baf5db2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3342, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36fafaad58eef42b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3343, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h2183ce92f1e82442;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3344, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2da86f1a00dbd8f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3345, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e503e0ebf18768e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3346, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d17d53a1637b626;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3347, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68b43dcd6f97dc20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3348, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32f83905f236ef3c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3349, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9cd10af95c09350e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3350, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fcab4f759187e0d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3351, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba32041b17190c72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3352, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h946d32f6611a0974;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3353, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haddda357ef368fc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3354, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac4e8d3992ad0377;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3355, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h214c31d2a4d2ec97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3356, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf35e4983ab8caca9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3357, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d984abc0a89c29b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3358, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a7a2fc0d20ddf86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3359, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdff5a476288b5d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3360, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3a16a18457683a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3361, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75f632222e18a03f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3362, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2bb5ce72c01d2ef0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3363, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff6cd643fd496687;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3364, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h9a098b96e9f2b392;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3365, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb74bdf1f5489ceb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3366, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab1482a0901f9d08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3367, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa723e3d9c592032;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3368, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hae19ed81b397ca16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3369, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b594c1a3acd4156;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3370, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h11a12b817f93b60e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3371, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e6e37619ae1dda1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3372, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8038f1f6077c4be3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3373, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a8c012194a0a3da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3374, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd1062a86b446bc8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3375, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87f8a5f3028c015b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3376, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05358eb3ca2c4b8a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3377, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff160c3248a618ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3378, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h443e1ec08064a94d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3379, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75fe0377ab19f893;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3380, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d35a6015aa61cad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3381, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3a708e525774840;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3382, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2898d7e219dd1f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3383, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e11159893dc8f7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3384, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h056c21143ae8aa79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3385, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h469885acc59957c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3386, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18601cc5ff77782d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3387, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h752c83f16ead7055;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3388, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd5e7bf5ce13e5b91;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3389, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea18de13f6e4eda8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3390, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb41d0dc46ddfbb30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3391, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ca9a2940a45855a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3392, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f28ba1be581dac1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3393, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he97ed2c5afa00a43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3394, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66940db4336c1bb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3395, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c31e477a4aa8d64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3396, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6228c961ec84dcef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3397, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9811813564fdef50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3398, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88e46f1e786ddd04;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3399, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2e8d573030a2a43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3400, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf2e540f41a89d39c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3401, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9bb60652b0d5b2b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3402, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h03f23a593b8f9b82;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3403, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h97987499531fa905;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3404, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h48ff369181dc8a9e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3405, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2b9e8ee209e9aaa4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3406, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a0c79b7f1e78aed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3407, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab2af04f2872a7dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3408, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a6e1c1a3c1d750a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3409, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9dc1385ec3e6e3d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3410, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76202749e9c4780c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3411, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hda3549a4f9be60ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3412, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc23edeb2f198a0e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3413, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h754a4f4a4acb3ed5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3414, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he093b049e8142a10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3415, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda495824c41e60ed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3416, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1412e9e8cdceb2d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3417, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h22497617693e127f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3418, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he40559f96f0e68dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3419, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h515964e09d16ee85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3420, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f1ad3ab2647c900;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3421, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdafd42813c91ac80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3422, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha718f6def725b307;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3423, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0a1732b8612ef2ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3424, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b648f3bb3190abd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3425, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha863ca8cab726ee6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3426, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a2749af354c135d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3427, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h09969c4151add8d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3428, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h122231a0023e256e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3429, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha48c811f8d3d5f10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3430, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23dbda0fa5c1228d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3431, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1480aeb12e0ab33e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3432, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1c0e53ab0e927a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3433, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b6aba7b5c2398fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3434, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffdf4bf43b0529b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3435, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c50867e6f590f12;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3436, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7823076f47819e9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3437, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he25df14556e9004d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3438, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb31898e8da821cba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3439, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5569c391883ac4f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3440, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0798d770d2ad4b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3441, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9536ddd529fa1570;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3442, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h446b1e56b51cdfe1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3443, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79de266854f329aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3444, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d5e2c59977c0734;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3445, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a69b4265c9b7903;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3446, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h81e18f8897150106;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3447, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0c01430e4ac8912;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3448, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd0c06b88be7bb05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3449, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64c324158e31da88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3450, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h120c212fcce92327;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3451, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24244514d45fa0bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3452, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h662407853114ea02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3453, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb561be9e5218b44;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3454, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0def1766431b17e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3455, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ceccc1ca620451f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3456, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fa351be8b702b68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3457, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5de93e6707d09a95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3458, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h024f6c238ac56f78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3459, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85549bd261d888d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3460, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h814e72b675196208;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3461, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71bb86cc74258fcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3462, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c3da44769423755;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3463, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4980bd16d3071e08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3464, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf69f66e22f4dd1d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3465, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc456c02b5dc3be1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3466, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f99c154980b80a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3467, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h129743a092fb290a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3468, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h396bd26498487e2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3469, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05285c95d6d71045;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3470, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1c1eb52f8a8fce8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3471, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha15d454c53c6bb46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3472, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd7e71070e18dd609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3473, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he04d397d966a85c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3474, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4cfcdeb6bba43eb6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3475, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74972c7c9f6415bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3476, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf15b988be42438b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3477, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30520cee17d569e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3478, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hae4a47a39023252d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3479, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef6fca6fb556f872;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3480, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c01d9ae97625616;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3481, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h440644b67d0c287b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3482, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h757e59491973f876;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3483, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba498ef97bba2343;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3484, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h81eb4e3e0ff278c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3485, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'habe1026e5d5b5423;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3486, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h93c835303570d5f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3487, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h57a48c34689f313e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3488, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7aa00e0bdf9d91da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3489, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd309b87f9bd23ae4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3490, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbcb90a6543718b7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3491, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h3f5b96d9b0b4b223;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3492, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b9f0c1f221185d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3493, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hee279fa2819687e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3494, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4cddb125e7a6c05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3495, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbbc7bd626fcbcdbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3496, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b56e35c9afb016a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3497, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hadaaab35efbfc009;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3498, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h354537cb19990f7d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3499, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h045a6714aca15a07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3500, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h490413d651c7e168;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3501, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58ede7de30fa4bc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3502, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hacb0133a2bb10fa7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3503, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9bd3d849b37b1f29;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3504, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he51e7d43a81b65de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3505, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hb2b31d678027cf22;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3506, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h493b318cd9a05fdf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3507, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4cbc335efb95ca2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3508, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h08642ba75a8f1e50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3509, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb488a2b5c4fed5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3510, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha149eca5981a3922;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3511, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c9ee18732e7f2fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3512, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0271c9557dbd6455;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3513, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b70669afe722b16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3514, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h8b1c89a73c20d90a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3515, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0e07339292f3db3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3516, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hace84be7d0675981;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3517, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb3a0c085de2fd8d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3518, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc35243068a91955d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3519, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e24ba2f889f3439;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3520, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2faf364e574917ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3521, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4c45671a5f4f99c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3522, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d89f99995dd724e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3523, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h9424303a5b46c550;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3524, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h146b6122cd2b987a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3525, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc4a0c5eac580972b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3526, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd47bf1be670d8d8c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3527, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01f2b1b3e92fe39b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3528, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68b4cb7875fa3b16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3529, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10f03709117bf3c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3530, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h388383c94b665840;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3531, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h12410ebdceeb1c71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3532, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6b28642a485b740;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3533, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde5776375a18f0ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3534, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafaa6d436ff64c4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3535, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h342a78ff8396a3d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3536, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h87209fb38440b132;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3537, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78f20772f5a40a14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3538, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he28790967c45bd87;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3539, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94565cc1a685b769;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3540, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9da17154704f8e9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3541, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h887301a5f3f35669;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3542, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h571bf2d72666ab57;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3543, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f0f091e3275cdca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3544, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6af8b4854ca8c7e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3545, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0d199bcbd96f3a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3546, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6fad2868b3c4be46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3547, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20255b580e9767c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3548, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e9c361389203046;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3549, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfefdf46c942645a3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3550, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h52a1276e6fbfb8c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3551, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06937d6fd2a31c2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3552, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9187ad4c3df61356;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3553, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0427cbf1aa1419da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3554, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2bfbcb41c7408873;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3555, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7551c5950f743db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3556, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h72835628415fff64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3557, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h050ae96d7239feff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3558, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf16e1d4dfb5fb433;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3559, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba45333574c464f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3560, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e5c3e225b250591;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3561, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he59d5f1195b49203;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3562, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h10c9967376694d49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3563, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fc2d20b94a65760;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3564, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h22b50f9320a314f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3565, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94c67587dcf406f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3566, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe659eabc4549cfc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3567, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1aae9521e5478b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3568, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76cb500d479d179c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3569, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88e161e1b844d94f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3570, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd0dab1b8d15cbe9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3571, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff54060277e94799;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3572, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33c592e936ae96d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3573, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e3b715fedf79cf8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3574, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a2dbc616eded6fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3575, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h34906dc8e26dd551;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3576, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2f02e431cac0b92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3577, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hca3bda954a240834;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3578, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h993e8e044300fbfc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3579, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85fdbfa36eac1348;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3580, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37e47e770ab2f12d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3581, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h4e1ac4933b6d8106;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3582, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcbe6c6f3c6f43385;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3583, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e7009773fbf3d60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3584, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha13db88056fe757f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3585, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfdbcd403f9b45316;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3586, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbbdfb6c15b5a5590;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3587, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c52d6f3e42efcee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3588, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0d7f2826e866c4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3589, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf23b003bb8f599c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3590, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c21fd10042b0584;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3591, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h766767ffce0e6ebb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3592, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a20f2c40a8d3cf1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3593, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3273da028495e843;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3594, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ba74b04f3da626d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3595, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ef9a472bb039553;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3596, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38d2a7661f23c0b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3597, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4751153aaa8c81b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3598, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4827fc1bbff901e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3599, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70abe78187738d78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3600, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h1ad9e5c8ecae5006;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3601, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfb330e2ed5a9e57b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3602, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9e3ddb04d243e68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3603, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7491d72c29527773;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3604, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5dc76a2b30fbd170;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3605, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h094747bfb8f0c7b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3606, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h08b3963c3600e919;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3607, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h39b3f2fec5cc9860;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3608, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h924ce168b2e5368b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3609, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b732ea78be5cb72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3610, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha0bf44a71f8594b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3611, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d8c883a9a82e53b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3612, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha53442c6059c419d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3613, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e56edf179e9c4f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3614, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d81de26999e462d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3615, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb815e3e647678f37;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3616, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfc8a49c47ef6864f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3617, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9694a06fe63457cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3618, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ae7de08d4dbedab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3619, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49a77fb7fb120be2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3620, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2624090a33853a45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3621, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h921a8d18e587b2e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3622, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b692776267c6101;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3623, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had643a6e89aa6210;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3624, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf0736b7d1b1b61a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3625, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc20ee968895debb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3626, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h889b704b7cb66237;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3627, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he36ac59fd5a8173d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3628, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19ed07c1857529c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3629, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8bf5ced7d016d3fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3630, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3476faac48bbb495;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3631, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3bd4540e99288e84;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3632, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h9d19bfff19695d00;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3633, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfc7b45545327534b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3634, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfef691655b0174a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3635, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8bc17aa4edad261;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3636, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8f215292ad686d3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3637, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a72701d1e25bf5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3638, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc8a3b4ddc39e2dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3639, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4fa3bf90797f5088;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3640, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86f651c176848f62;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3641, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b55315eed7f65aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3642, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f06372ef8aba0ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3643, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1513d1aea7521469;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3644, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d24bd2df5855422;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3645, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e57745f4fd6c73d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3646, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0359ee9280070bcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3647, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd89c4042f4783b2d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3648, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a9924b933f0a2d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3649, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09695f0135d34273;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3650, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hccccb1424ca28470;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3651, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1b89fc465686821;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3652, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h282bac3e7738d1c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3653, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29b55ad989ade381;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3654, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h820ca85b979b7a90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3655, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8aa26c7d9b891c86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3656, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hb6d60d05bb1036f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3657, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99068e48d519f2a6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3658, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18f05c6ecf0a126d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3659, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62e86f9fd0f10496;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3660, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a23f639a3cc7f3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3661, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8486629a2eb5d904;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3662, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2336b04bbdabcb9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3663, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c2686b4731e414d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3664, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1fd3b00dec87b760;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3665, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc488a188509cb743;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3666, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h68d1e9369b205487;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3667, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha985f3ef479dbf55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3668, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1efbd13760fad86;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3669, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1a7c84edcae643f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3670, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h515ddabe9a53cde4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3671, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23a847affeb23cb9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3672, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hbbc8cabf320a60ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3673, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35f5beeed729ffa7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3674, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha1becd20a9bf25bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3675, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h024e879306782c65;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3676, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he804059826bcb616;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3677, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h551e88d977ff349f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3678, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4dc21493f79eefcd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3679, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h812419e33d55406a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3680, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h956ff91216697037;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3681, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc72f18322f36a6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3682, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h518d0f39b21bf674;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3683, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd37804db8c43be97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3684, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f37537b054ce9f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3685, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf171b39979778a7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3686, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8aba429a3472a46d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3687, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab78d9385a2bdf77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3688, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57167b1d0f8159f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3689, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1eea6ca5b4e4fbd8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3690, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4a90eeadaca09ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3691, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd943659bb834f886;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3692, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2da648c25b687e52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3693, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa243fef3dfc366c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3694, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h222cad596dba1136;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3695, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h63901742bf5d4bbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3696, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55d45c11bb3e8ff2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3697, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5665e3f7c5804f3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3698, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h505cdb44caf5945e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3699, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h037c60bb743ba758;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3700, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28bf7709dc2741db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3701, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76cf3ec716b03201;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3702, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h588815d9afbef7e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3703, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba46b8eadcb72251;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3704, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h501dfb0975f7ace5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3705, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36fb8d039aee4c90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3706, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ad34bfa62e34927;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3707, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h93cbb8cf90146119;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3708, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6876c5292901b523;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3709, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98072efe055b229b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3710, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h72115f2abf77f0c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3711, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde6c02a9477d29b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3712, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ebd412a06e8ec92;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3713, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he042ae41f6bdd128;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3714, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f3c156191e53d56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3715, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d086122183948c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3716, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8f23ce47efa8345;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3717, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf347b3f0aaa1f5bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3718, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h124158763f8ae917;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3719, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f6f884813180f77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3720, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53b78922dd154977;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3721, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3714b7ec950917b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3722, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b44dbde6243f5e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3723, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h67d39830c71d7e7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3724, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h3b147bba9778fe23;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3725, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h071d18af87a86d29;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3726, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e15ef8a45fd5598;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3727, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3406fdfdb647305;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3728, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc21c4b2f352d852;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3729, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f64eaec8683bd14;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3730, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6dcd9ce4842d9c03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3731, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4ff76baed7967dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3732, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a4c690aa1edcfb7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3733, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79d50e74d2283193;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3734, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5262d495711d1bc4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3735, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb741e8f108b071fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3736, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf62f106fec844202;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3737, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h499536dd47fcecd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3738, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0a4f4da1fcf0b3d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3739, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h495d6401f62406f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3740, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h2b8664122e3795a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3741, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hf4650d560e9928d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3742, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h4022c0104cb2ea10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3743, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he09249badf198260;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3744, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a34902c5db00c31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3745, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28af8a4e332ebf4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3746, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4144f7126aab1160;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3747, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcdbcd3171e65b4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3748, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b4131d817834469;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3749, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66664f17b8c9fc35;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3750, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8898b57c8a7bfbad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3751, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68c0ceb51d17876c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3752, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6af9ed019614a5fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3753, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a10902a7e127489;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3754, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b064eba1dd18c97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3755, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2665a43c53829c53;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3756, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h524ded36f28d3063;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3757, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfea1396b04256f55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3758, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h5552eb5c95a02178;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3759, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffac06321a07c8ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3760, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e572dda811bdc29;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3761, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he52b53e8487e668d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3762, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h16bc39de66219520;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3763, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13da4dbe0be6bbff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3764, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h49b9a5d31eb6be71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3765, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h790d9c12d2670535;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3766, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2f3bd14fad4ef754;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3767, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heea65d3a50e8b9d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3768, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0379ca923e8fe5ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3769, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h906b7ffe3a9117de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3770, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hcb5266e0c1bf9ca3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3771, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c7eeaafcffd7b0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3772, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfcd310c48d71314a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3773, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda02c7cbed05a59a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3774, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13fd96f092a91ea1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3775, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8dbee6023a67f508;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3776, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdae07e67a587a298;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3777, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a397744eca76a60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3778, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31b99f831236f240;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3779, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7868eb8d026423e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3780, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9dda5bf96ea74918;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3781, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78f71f1f3573e77d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3782, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0db6269106962b76;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3783, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ac5df03e84c1824;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3784, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a7a969017cbd09e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3785, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ce264cd3c074dcf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3786, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf772beb9c388dee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3787, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc108b732163e5bf8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3788, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf995904d37ae947d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3789, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2225e2e6113254c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3790, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h574389508d60c864;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3791, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h582f89d535d46cbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3792, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a9439d7d6618a5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3793, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h7341007c7fa9c07e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3794, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h045a444e33d5952f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3795, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3962f4d7e7792db3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3796, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff261bd436f2dbd1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3797, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28e287258d6a0d5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3798, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2453628df05997a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3799, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h180d0e54295af340;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3800, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h78d3b218be158afc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3801, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6df0d5c4725715ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3802, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20249134426b3487;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3803, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e9c1fb1e6297a91;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3804, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc967d234fa7e187d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3805, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b4671393ce17f01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3806, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88e5a4773a1fe65a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3807, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc71b9f052e2adbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3808, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6b079003c474fea4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3809, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h717a2fb15a0ef62d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3810, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59d10189b1242f01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3811, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h030bbe9bc50f29f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3812, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58126a6e7eb56189;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3813, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2744188089379200;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3814, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had56407924f63171;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3815, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h29f1ff41873d6542;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3816, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2aa0d596c5194d66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3817, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb63b7db7866f709d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3818, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3374921aa92dd7aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3819, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7af6608533a0f9e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3820, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b225adb2244f952;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3821, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f0a96ce5a250cfd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3822, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd0295283a0fc6ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3823, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d8603890abd9606;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3824, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c5a8e66661bd110;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3825, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb11ef76063e9fcf1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3826, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d92bd7f9f35f10d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3827, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h25cb66b1a92ca9c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3828, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h427dd20be612a805;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3829, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1aa32fe76ed20677;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3830, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11b316cf1d626695;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3831, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hba5b928c9eb03b9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3832, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf552a89901d1273f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3833, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a8c0c5761803dec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3834, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h798273825f81e385;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3835, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fc756813bb9ad70;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3836, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h509c2c6ebeda064d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3837, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h43a7324e68c0dc67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3838, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcaa5550d4b72e728;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3839, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he03eecca344efe06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3840, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc53a70d3f9ccc20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3841, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8ff0d48e22bace8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3842, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6d88e51654229bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3843, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0409fca2477cb337;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3844, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h10ebbbd87565be68;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3845, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h789d26f781b291b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3846, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h72d7ac94ae740450;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3847, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha30a1324f6121efc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3848, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf34076ab46d1ab8e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3849, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf56dde0133852ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3850, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21ff978a55dab4e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3851, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01b1a9ee71532e18;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3852, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha79c914a13f926c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3853, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h417ba39aad7074a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3854, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h98062002c9da4c15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3855, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69cc33741fc88af6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3856, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8bcad17fff9a842d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3857, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65ed28f8f370bec0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3858, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ac4ada9c02bb528;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3859, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4753980228ba0c5c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3860, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21b1056652398dc1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3861, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28d87bff6ed4a4b6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3862, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he97712ce237f37c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3863, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h549400995891de9e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3864, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4cf5eab4af32dae1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3865, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19ef4afc5194d601;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3866, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55342667b2121fd2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3867, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd19fb10e78ff6564;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3868, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafdf62f1c9061ed8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3869, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56c27e78ad011044;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3870, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8782087679a6481f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3871, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc68047948308f89e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3872, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h862fb4dbcb5a2826;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3873, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64833c4d5c8ec29e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3874, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haeb7b62dc77d930e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3875, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6cd7e134ad5d0e53;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3876, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1e72ddb915efc406;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3877, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h4812da962514f0d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3878, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7df2ade44a7c7f88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3879, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5dc10a1ecd4f8ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3880, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71d9db670959f4a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3881, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd665900a1ada89e5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3882, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa5d5a5eb0b8ba6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3883, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd7831ceb3665bc81;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3884, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd958caec31518d5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3885, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a427aecfd2b6caf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3886, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf8d2b29c3d3063e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3887, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6716367cfef64582;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3888, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e48f7a06ced66da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3889, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1bf8595f9e7ba165;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3890, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2794f76c6a30b3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3891, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he09fd5903b3ec876;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3892, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb4c69c5d93b099b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3893, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he90b2b610f11b95e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3894, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc2e4449d8ac810a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3895, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h2168cfc9cc49a3bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3896, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h162acf3d626fd765;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3897, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8889b6206bae16b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3898, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h97863db22ca67f67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3899, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2429748a0b6ad4c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3900, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h27ba949dff62c260;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3901, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h37c98001e36b263e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3902, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d9ca7a6769379e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3903, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha26a6b36cbfead0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3904, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h811d6b93147af25a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3905, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h5aa305f787291598;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3906, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30ba16f4b1748011;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3907, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h604d2e22449baa58;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3908, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e6208485fd87ffb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3909, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0fb24d47e75e6b50;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3910, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h46cf9edf3b53289a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3911, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0f2aa55b4040ca0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3912, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'he3d4c225354ee0b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3913, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc8e7a332d700c122;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3914, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3155677665a1124;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3915, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcbfe7c00fc0c12f6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3916, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4774e536f452f314;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3917, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he0b115945260ac39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3918, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9369ed99c35159c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3919, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11878edf483c6535;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3920, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h603546d928910f11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3921, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hcb0de28d3ea83da0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3922, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7527f45663f13137;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3923, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74c91470cd7296ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3924, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc475321ad70b8ba1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3925, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3a978eb6ebb1199;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3926, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h051898d78a3dba80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3927, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h05bdf1e07dae8f4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3928, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha59640a9cf20da2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3929, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8bc9aa82c3e840d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3930, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he2428fe2e3fd222d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3931, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h42900304d2c06974;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3932, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h725bc644eb58a291;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3933, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf83576d1ae8de38;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3934, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c495a70201792c5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3935, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2c25d11208b4b93d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3936, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1b00d19cac6cd46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3937, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he3f01f65abe617fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3938, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff1ce3d529d4c1ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3939, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b3c34fa7ece5f6e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3940, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h396bb7ffd9e51c74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3941, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbea20985afd8274a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3942, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe43552c3bb4d70d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3943, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b054a71bc5221d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3944, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h27af846b483a4ccf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3945, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5fcc674ed942e05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3946, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6351e5fbcaf2c015;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3947, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d70169f4ebf695f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3948, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ac57fad5e3ae916;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3949, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84a531c19dec0e12;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3950, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6221b811c282f812;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3951, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h0ea856ec3dcaf1bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3952, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7561cece68188f01;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3953, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd780390bd62ba36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3954, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h92607b88e7977600;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3955, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5410ce2de908c8a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3956, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e921c847ba0218b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3957, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'ha69d6d02673e6991;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3958, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hf0cbcd796e395975;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3959, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h24402e47724f5bb3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3960, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5551c82ec2df7835;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3961, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he2d90163b56e39be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3962, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77402d3f9e27425e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3963, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h49e3cb34a3f34364;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3964, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88cb4431ae9c2df6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3965, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcaba824237ca7b9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3966, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haf181321d3068ea8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3967, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0025863dafe7065;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3968, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h2a9f356620db8368;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3969, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h542a23f5c0725a64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3970, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1673e9efa54f48ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3971, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7a243b91f4c63e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3972, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab8aae75410bd359;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3973, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6a26ffa63950e0f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3974, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2328c55643f2274c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3975, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b928547cf1f8191;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3976, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h800dc7c03347bb91;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3977, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43b6c9679f45bbea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3978, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h981ebce9df0bde90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3979, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53fc6e5d395b30d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3980, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a9ea8597cd8992d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3981, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d7e476255369da8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3982, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'ha29d8cb3be63178e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3983, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hdeb9550ac2b1ad3b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3984, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5aaf0ad335b64e49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3985, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb5c10cef9d8b219e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3986, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb21753a83aab4445;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3987, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb234d54eaf9842b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3988, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d6d32e043194d4f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3989, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2aa20eeb06e842e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3990, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h50b9487531642fec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3991, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8ab6716da6c27208;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3992, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h013525c3f3a54c13;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3993, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f2fe3cbae7a0a0b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3994, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69ee88b528e43bd5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3995, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0874c81aae6bfa96;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3996, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h832eece44ab3a156;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3997, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e58f807a256b57d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3998, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h14e3f4398e267b4b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 3999, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8359ffd6b5c2ecbc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4000, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fd859668c764bee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4001, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c080122c59b565b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4002, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hcf9c4606aed0e75c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4003, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3689871cf629dc27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4004, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb8050608eb352a5a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4005, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h5410b0e97856b596;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4006, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a42f9b4e6c4998f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4007, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3a3fd19a7c1e0cf3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4008, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2043b6310e3ddc30;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4009, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d841fff516628ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4010, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6199dd8d7fd3b2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4011, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8caf0bb641be9019;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4012, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h77e3b0791ce325f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4013, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h26acdac1143a8146;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4014, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5d363ea625847cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4015, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d36c9fcb9d3a9fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4016, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h452edd634551e4a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4017, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h522fec42b6465ae1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4018, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8d96889d2fe83175;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4019, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbce83177e470f43d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4020, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbda1ea2a3aa822be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4021, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc2e2bf36c43456ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4022, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h066341a3204771c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4023, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30ad072e5400444f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4024, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc788eb675912b79f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4025, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e7f3c62a05bcb46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4026, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdde0c10216a22cc9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4027, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd4290dbd5326ce41;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4028, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha20c104ccf0bf8cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4029, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h357ca060a73f9886;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4030, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8d446548f2987fa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4031, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1a74a065e5b3720;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4032, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h92357bf5eb24fbdf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4033, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3b0a8fefa52175d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4034, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20f8bc3400c57308;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4035, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h67d1e000dd944631;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4036, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6324fdc4753fb1e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4037, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h928c8b8180d50ee0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4038, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd635d309e9b7fee7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4039, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcdf8a9821875a20e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4040, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c9a6338eeac45b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4041, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5794783fb0f5ced0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4042, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3020f413eb6d9588;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4043, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d778be216cf214b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4044, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f7d60e236832190;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4045, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0db02f47a1ff4698;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4046, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h9b935d75ed687df8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4047, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ec6b5a109339213;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4048, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h973e98048b3b3535;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4049, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h81e410fa0b8f0200;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4050, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf6db6ead14ddab94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4051, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6456a73c472c8276;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4052, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h64a78080741a6e09;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4053, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had2f502ba93c9cb6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4054, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b3bc79d7cea8f10;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4055, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hae20ea8e3b0351da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4056, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2af7297d11a9945e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4057, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8855bcaa8ef5c60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4058, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8820203105fe30e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4059, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha58e2a989c91c798;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4060, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3392909880e99a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4061, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a67386598fc537a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4062, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3718d4f9a00e26b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4063, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57162425cc8172c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4064, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hb4dd48e31fd0ded5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4065, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h63d1fb76239880f6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4066, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e1cf460696a4ace;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4067, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69f662eac9bf7bf4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4068, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ec772ad6e47392a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4069, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f0f0b401f532d19;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4070, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf42a1bd382c66629;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4071, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11ea0366342d837d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4072, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h729215a5133a9755;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4073, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36fd70cb8eb20ad3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4074, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1babc71f66e0343;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4075, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h851ed9bdb421c115;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4076, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd4f7b66435629463;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4077, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h979e869d95088376;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4078, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33044dfb37582122;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4079, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h937a74b93efe99a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4080, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbdd881874f0a6171;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4081, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hadb30429bb62f383;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4082, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c55d0e157e5bd33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4083, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74d6fb4fea90bcb8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4084, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4704f439fb843c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4085, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd60e868b6c8c80ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4086, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e16caa88cc43dce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4087, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2f905244ad554c15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4088, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h27b7b6b44b7361a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4089, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he6ded481509bff78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4090, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5c164bc594fe5b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4091, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf787caa063a1ff1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4092, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86696257a6076f45;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4093, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7b8779cf5f176ba0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4094, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb56189c22bc96a25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4095, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bb711797f8c3a88;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4096, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfce7b0a94b3f3798;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4097, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hf761353f758e4633;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4098, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdcf97d61cefd3507;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4099, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a27b09465d23d16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4100, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0bd5427ad854a84b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4101, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h5946b12bdadb8904;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4102, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f35837888fe4bad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4103, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9e74833062ee181;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4104, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13056353827f64e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4105, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf59fbe6bd02c5a3e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4106, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c0d8b14aae3266f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4107, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h66645b4652bcae33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4108, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6df004aaf9466b87;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4109, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70ad8de70a2146ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4110, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75165e4d096c1f44;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4111, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h394f794cbaab2c64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4112, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h39277c973628610f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4113, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha13bfbf9fa06447a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4114, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc4f5d3f7af8059ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4115, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'he03fe6d8b62671e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4116, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1a428646d6779f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4117, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2862c9cec884acba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4118, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7d68d519a132795;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4119, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b2571a2fb77cec0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4120, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57d08254f3336cb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4121, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'he0a8b09fa0c50bba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4122, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hebfb47a5ccbf3d3f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4123, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8551715c6a57d6ce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4124, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09cc8284eac813b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4125, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38736bb052528a54;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4126, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha1c5c222d37b1989;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4127, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0d90aa335e5fb42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4128, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96112d90a8700955;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4129, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e32ed9a83132af0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4130, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h6a0685b644c85257;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4131, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bef69211a700dbe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4132, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4bf5668d17fe3a40;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4133, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c1e298d4131e3ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4134, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06cc551f5601597e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4135, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha39ec163624002b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4136, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2a907a9d08d824f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4137, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1cdd1e153cdcce03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4138, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71010352369c3fd9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4139, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fa881a8649946c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4140, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7da85dc909b13e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4141, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc0c7cc3c3c4a7dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4142, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbffcfaf6720def56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4143, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h669ef74aadd0df6a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4144, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7d95403c63e8ea9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4145, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h058a3958a7752496;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4146, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb9ca569cab7cd58;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4147, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6a7b296799be062c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4148, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heecccfc4e240eeb2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4149, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h015b8d442def8811;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4150, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbb6eb18f727d2515;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4151, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c79070e2c573fa4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4152, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h913ce0a9a3435b39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4153, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5c382009a835c610;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4154, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb284ad8d2f0ccaa1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4155, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7746aacf35ab16c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4156, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc01832120c64a3e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4157, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h981aafb8248b4d33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4158, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f93ccab9e13cc43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4159, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9896863d30a8249a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4160, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h88cc7db29d231359;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4161, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hc079994d4db517dc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4162, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0486e7080a2c4979;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4163, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3b75f92a9c496ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4164, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h361d86d76f404fef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4165, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1512a226547cfca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4166, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h748a26287e1e53b4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4167, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf561f6f427cfa65;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4168, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2518c299c2b844d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4169, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hca2499081c1361c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4170, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0913af2be7c93f90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4171, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5c2f3aaf80ec6c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4172, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7f0365e117806b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4173, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7502488bb126e1cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4174, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b8bf263ec71941b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4175, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hedb067cf9144a947;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4176, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b4baaee2dd133e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4177, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8730306793db9daa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4178, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hef40269cc9f2eecc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4179, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3b80fd258e3130b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4180, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5589b9c6f1cb2473;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4181, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6784712dec750f56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4182, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h49e6ea5c71099f0c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4183, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13b1ae5e25ae53b3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4184, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04684bf19d031838;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4185, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5a757e12fca9fe9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4186, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ca647d7b72b7a5a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4187, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3bdd736c13f48b1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4188, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h1c3fdbcaa829f0d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4189, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6389627399e1ea77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4190, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h3528c8a9d920a149;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4191, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55abc2ccc44dea80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4192, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76e5a22624df8228;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4193, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5733b60ae1ca1f52;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4194, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7324dd443733379e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4195, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he4e443ad1bda3035;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4196, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4e0686dcf055433f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4197, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6aa0bfeda02c9f46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4198, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0afcc4b556666e32;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4199, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h21c290e9eb7d0943;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4200, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h82a253bd07c784cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4201, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d58d2db28e085e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4202, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h448edbee93f9269b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4203, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc2685595e7f87777;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4204, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha0d0be8658fce690;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4205, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h986e91a5b03ae259;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4206, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h491115fff3d06f3f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4207, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68d4bef4fbaac08a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4208, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc45bf9496507061a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4209, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4f178c9f7c01221;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4210, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d35f65e5e356404;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4211, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda7d421c2e4be1d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4212, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28700502894c8e3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4213, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc63c10b108fbb60f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4214, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47ab82db205e6645;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4215, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc8151168413a1e1a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4216, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha2b6a6b149d92a64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4217, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hffc3d8dfcd1badb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4218, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b61ef8185b0a77d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4219, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b25597d7a0ff7c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4220, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44df4ecebd8bf970;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4221, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7266d2c01dbcee6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4222, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h096b490e4d0bcae0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4223, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8dd4726c7a07b7c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4224, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee6d96d2d6e14296;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4225, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c4289c4f45e44e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4226, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd0af4c6c4cdf00de;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4227, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcbbbaa4b72902283;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4228, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c05e7b9b66c31a0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4229, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45afd271b15a421b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4230, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1638996b821b3d6a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4231, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4334ea09b2cacdc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4232, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h2091579ad85d9557;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4233, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b0a98575806e0a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4234, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h283085db9731bcb8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4235, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcec3de7b8270709a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4236, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2b4feaea1fd3d05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4237, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hd1695a913ac26204;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4238, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h849b2545bbf9d282;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4239, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h559689d1534cba94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4240, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h720afb6885df284e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4241, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38024cf8d16e9e55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4242, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3cb94d1eef3b1b06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4243, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75d8c2c8d5fc5d31;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4244, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57bb0be0d278298f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4245, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f55be92de60b383;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4246, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h38a885bc6961b7cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4247, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he3c52df7da6f1fc2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4248, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e25c8ec0530d303;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4249, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a47f638ed045451;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4250, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4a80ca83198384e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4251, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdfc10ad3e629b0cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4252, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h388ff8e1a1b28c72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4253, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h4e42bc781611064c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4254, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf4bb5461377b1390;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4255, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43ce56d5e0ee7b6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4256, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32c7be320e3d0a8a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4257, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h03263aadbef67cca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4258, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51181dfe4a4a3836;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4259, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31226e5d75965f8a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4260, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h02644613958026e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4261, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h04393da514fbc700;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4262, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4fa9901f8684368;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4263, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda1c95ceaba4c18e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4264, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f36610c7a8de50d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4265, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55f6ca93d1647c07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4266, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d094564b1c27321;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4267, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8403a93be3fa9a2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4268, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8327be78175b8a98;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4269, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h894ce801ca661619;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4270, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e7b11fc0b43a887;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4271, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a9f0acf9051052d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4272, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h419754d98df4c4ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4273, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5b6458e2b2b8113;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4274, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f61caaf66e55a39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4275, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h94f7e6a25a55dc7b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4276, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc4f616296cabd83e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4277, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf34efff63a1f9ab7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4278, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e9f1507be5b38f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4279, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h03246e32413bc43b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4280, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h536d3c5b273d8d4e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4281, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0a9be4f20074b3d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4282, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f022da91852e2cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4283, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf060cb968777be6e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4284, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3d740120b7f64b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4285, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a9e9c975e97bf5a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4286, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdf3b204b496c4549;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4287, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0da0664ab7342f28;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4288, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h17e5eaebe0e52a25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4289, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9bc794ac704b68bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4290, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0adf2dd08a73f9ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4291, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafa5974ded53d2d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4292, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h165568e91b804cab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4293, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf95a5df44048ffcb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4294, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01dc960561024120;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4295, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h111178ffef4a16ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4296, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f9c14573f68b521;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4297, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h614ab3075d30707f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4298, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7de50906a0bfc268;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4299, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf600efa9b5682ae1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4300, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1449c4476c7d8eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4301, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c002a2bd22917a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4302, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h233bd4d766b59ffe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4303, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5db89a217e5bc44f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4304, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h42eb0e8a31ba3686;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4305, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e824da1bd82a9eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4306, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09e22c90d8fb9626;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4307, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13f54071530dfff3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4308, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h826d6aa590f673f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4309, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h48979b7a030833aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4310, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he30344fb546dfa74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4311, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1882db4a79557bb6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4312, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h91513fbb81b975e6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4313, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47f57fb887f7c67e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4314, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e71f1c8711e9f99;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4315, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd90a4afbd169e7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4316, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h88390da4f382832c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4317, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h46d47b5c980d15a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4318, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff8a16a145c210fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4319, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4608870111c85a66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4320, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hf74ec25b979119fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4321, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha7d3b0cd3917f6e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4322, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hafd66beadd9b8462;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4323, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc077d1912136498e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4324, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4473662cf466ae5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4325, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1bc4a8018fa09d2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4326, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6eeed7d15ee4ce99;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4327, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2bf61f20c8bc883;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4328, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ffad0b9d41285bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4329, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1532b99eedc470aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4330, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68bcd5a7417a77b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4331, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbe6c6c94caa191c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4332, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1885255269469f3a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4333, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hca4c23a786a10647;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4334, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h97f5eb5c05650d5e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4335, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1a686def5c06223a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4336, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdef24b6bc65dbd05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4337, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd01321fad34a0122;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4338, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ad502ef1d67ab21;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4339, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0b1a08e9338d6463;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4340, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha853b8da8605be7e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4341, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d14f95ee8779b3e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4342, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a3b7d6d8f8b8af6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4343, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h121f984236654280;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4344, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd48b1d6b50278de3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4345, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfde93ae05f63e437;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4346, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c2b11927213cfb5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4347, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h953890aa7703c0db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4348, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h12899e6e2e7057c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4349, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd5b3eb123a89ab0c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4350, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h565ae0ae981ca4a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4351, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heabecbd03f9953b8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4352, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf60937b848ddcd76;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4353, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb39069dcc171fd1f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4354, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2434bcfdfdd09c11;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4355, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11ae8221b335bb7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4356, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h8decc14dee26b4cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4357, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0dc5c0f268ce5143;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4358, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8fc2883fc9e5bb90;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4359, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9932bea2ba311a4f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4360, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f739f83b076ec55;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4361, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h89e19169833361ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4362, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6c4d16b358a0be1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4363, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h600fbe698f3e34ee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4364, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h95da42fdf161c596;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4365, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h45130930a8d7b781;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4366, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h069c9f13b8065629;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4367, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e31ddff295df5e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4368, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h720becd67eb81583;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4369, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hfc073c5be4421e49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4370, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfadb5b4c46d2ccbc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4371, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h417af8e48b1cedf7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4372, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h15950b41ca531324;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4373, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1868321794c3bb8f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4374, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf60080b5a6cafa43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4375, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h026343111f36224c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4376, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8aaa8037f712d997;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4377, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h412daa356a1fb0aa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4378, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd9c8cd0a2a5e06e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4379, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h954931d64a87e5f2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4380, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ef293a24c870cb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4381, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h31b05b3c0e4830e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4382, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea67b075315d8c95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4383, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h522ac6942c10b3b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4384, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee3223a90a32f6c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4385, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6812b57103ab31f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4386, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h958caf2a575f7144;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4387, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h44a2f58234f86046;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4388, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbadfe8b741570b62;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4389, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5bb8bca6ef5317c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4390, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59d6537364a919f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4391, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3560b14e6d7aadf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4392, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6c9b426a4077baf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4393, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha376e7eef870c3d9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4394, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h8e3123c3552f142b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4395, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h117bd74527e326c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4396, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h07b132abf42bc7e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4397, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9ef2129526d65000;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4398, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h978aa2b6613650c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4399, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd3d9a4d5e449481a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4400, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58a9a807c795a7b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4401, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6655693d45afe0a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4402, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbf36a5e9d1faf8e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4403, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc82403e492fe4b43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4404, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'he790cc4b52871b48;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4405, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ff3af81987df91b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4406, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha41ccb1aa0df0ad9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4407, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7205453758993904;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4408, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09047cea05362d95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4409, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3d15c5e4b8e950b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4410, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb73a4066f7327047;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4411, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2998996df7c8b63d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4412, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h301b58145633d14d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4413, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa088d4d4a4bd720;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4414, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54b1226198cd7386;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4415, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e3255935eb2f89d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4416, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f1da180eed27746;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4417, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb31e16d4bc292c1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4418, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1b5fbaf5eb63193c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4419, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he7cec8b4b6da334f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4420, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd07f64d757259a9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4421, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53f8b9282c910501;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4422, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9566e4d50e44ec8c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4423, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6e57f8706ce4a71;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4424, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69169f78c8519b3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4425, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4c8b948ba2f671f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4426, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h566bed9b65f9e6c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4427, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf86a2a8f39548557;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4428, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h20e7d6260c6a53ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4429, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h63faacc6d323f55c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4430, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h431d0b831bfabfef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4431, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'heda288a2f2ce3315;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4432, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7704d6e503a222cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4433, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ba6e4b58756ee1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4434, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b94d8c2d95a9640;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4435, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h0ffe062999009609;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4436, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h062b0719db34d6bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4437, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h732c6efc3dd1485e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4438, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb6b2a3f78841535c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4439, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75be19778a71c708;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4440, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a01aa7de7568307;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4441, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbbdb78b4eb7b7e1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4442, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce96dfc070dbfc20;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4443, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h0166c7f72cccb18a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4444, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h85ca30e8049af87c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4445, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c6612631c9e2865;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4446, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf988a87f0e198267;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4447, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haaa2de6b2108310a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4448, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha71e20ae7602fd06;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4449, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h473341e056345cc2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4450, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4133654628b15a0f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4451, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6dac6bc9ea7ca97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4452, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h896ab945553bb0ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4453, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83b11893926a0d15;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4454, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcd21bfabd2c6afe8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4455, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hfef2a51c69542978;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4456, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hab4a8479c63f361f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4457, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h35f4d03fd4286253;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4458, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ef1910c12708f22;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4459, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79110ed9b8ea020e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4460, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1fc9aeb642e7a2ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4461, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha98182918b9e9a03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4462, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1f9ca9ba667cef5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4463, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4c0bc1ae1d297f05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4464, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h39a1f1b900760c5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4465, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he64cdec19071b0c3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4466, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d4339c7657ac98d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4467, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70ebde70e4060f2c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4468, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h74702d7aa33acef5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4469, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d849fe2cc40a3b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4470, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd6b14531104d4aea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4471, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c834028bc5fac78;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4472, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h749cabe59f0ecbd6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4473, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb6dacababa9468a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4474, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff9987588523bb1d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4475, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h79b4f4dee6bf5116;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4476, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7c92735f2f7489a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4477, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbda7aa07b501a504;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4478, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9d217e11c3e3268e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4479, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd995f22035caf2df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4480, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd49604f46c098735;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4481, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hc5c20fbdc502705c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4482, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd970cdbdb445293e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4483, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hefc348d642b7782e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4484, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ab06b80b10279f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4485, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd37b4a80160ad470;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4486, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h065204e4aac74886;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4487, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8604a6253191418d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4488, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7a6151be3dcba1cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4489, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hf8a302313e9daf94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4490, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h80c438a045b20fd1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4491, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he08d6f9bee3d2768;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4492, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h265311193ba49c94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4493, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd09aa46b2162e7a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4494, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99f866e70b811c56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4495, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha3e8968a74fbbfb3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4496, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6c0729ec7c785444;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4497, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdae3bc74aede67b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4498, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf3e7030dd4cb276f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4499, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8f7315b05e1880c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4500, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he068eeb5bf1fbc9c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4501, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6ad7780311de340;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4502, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had7f834813d37715;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4503, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcfca54074547b2ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4504, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1ca2a4b59aed4706;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4505, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec7fdc37470c376c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4506, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b841e9ef5ce63ab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4507, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6327fee75793f743;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4508, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9708092884186db;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4509, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36af6c38c65937d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4510, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b31364390ee1bf6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4511, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbaf394e414f3e992;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4512, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25061af51c96c51f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4513, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ff63fc51e4379da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4514, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h858630ff102b5936;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4515, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3706275c3ba66aa2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4516, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h11cece77b8c9cde7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4517, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he39d915aaa772cdd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4518, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96787f83c7f5768c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4519, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h6c9de38bf63b5182;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4520, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1af05c1eaa5d9a85;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4521, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h61964522d9d67ce1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4522, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h125069e263ea0215;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4523, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf617e0f85c1e52a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4524, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c77a467b69d427d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4525, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h9a535ca0044fe81a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4526, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc58a9d2f648fce42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4527, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h532494fa8460d8fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4528, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h0e8bd9eaa77b6402;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4529, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h072928fc2ed9d805;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4530, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h16330e031d8baf66;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4531, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb53e8c34f7aa115a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4532, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h390374b9e69af416;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4533, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc740eb2fc5abe605;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4534, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heeb9e26b233ddfaf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4535, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84f615454cb0afc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4536, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h527200a0ce5dbced;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4537, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90339e4d319bc295;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4538, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfcc824c847ecf0d5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4539, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7efdb6b7180f5e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4540, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf7921c9b626722bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4541, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf33ca62eaa2f7a65;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4542, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfff363cccd2f9b4d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4543, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8c67a41ab97eb9c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4544, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he61b1d09042c8759;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4545, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3360b9781cfa5df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4546, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hae3c2c67c615d808;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4547, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2de5e2b962e3a7ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4548, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h7531a0cc80e96b1c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4549, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h65af0fbfc80e2375;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4550, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6ea2bfc349c3b728;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4551, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5eac02d0f558fd4c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4552, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hdf9902efbac2d460;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4553, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he561d7bdd828b9f3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4554, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4d571ff490a0d7fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4555, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h1f4058bd52d4ebf7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4556, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1ca24f758c0e0031;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4557, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h69adae3d0ad859ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4558, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'hb9d0dd7baac95ed6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4559, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0c6444657f10b08;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4560, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h3abc92b2a9e0c6e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4561, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0dee1065a458535d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4562, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f33dc7d7f29ecf5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4563, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96ebceea8ba6f4e9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4564, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h8c13246eb206d7c7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4565, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e0462e35043a22c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4566, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h989f562c0a3464a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4567, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h310e87eb272abba9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4568, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc25183165d2a6a60;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4569, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83270080670cde02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4570, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8b109a5337774fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4571, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55ae5c74be6a92ba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4572, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2752ac32aeadcde0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4573, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7e492aadcd5c512d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4574, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6db38f74842f213f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4575, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9a080f5ef7a7c474;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4576, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4178d1ea6dc17c9a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4577, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8a38ce7be657c8c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4578, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77b4f0391772c2fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4579, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hc6ac1e82115df455;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4580, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce7f5821849397a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4581, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04dba5eea67491d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4582, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ee20914c36bd58b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4583, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h645bb22fa76f13f8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4584, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7cd6131720d402fd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4585, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1404a183f04b005d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4586, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5d6ec637b6300f6c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4587, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef288b542b0cbeb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4588, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he1ffd9ed7cff2880;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4589, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h407b919f5716ffe0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4590, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb596c61cd4d30e05;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4591, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hec074b8c1e39ffa2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4592, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h837676b29fccfabd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4593, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6c47d88b7222e3a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4594, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h48410111554ae06c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4595, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6affe788984c49a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4596, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e39f528549bcfa4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4597, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33cf28499927a097;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4598, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd5424dd10535641;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4599, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d160b12d3eaf9e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4600, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83126330795eaecf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4601, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6412f03eeda43081;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4602, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78dcd40e3bb47132;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4603, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h259ef0220e419c7f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4604, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4ee8ecb2bea4dcb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4605, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h35f6f0fdf3ec4e61;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4606, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h1332280c0bdc57ad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4607, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h912fb7ba7a11e321;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4608, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h123fcc25fc818eed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4609, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h746a679c3c13f12d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4610, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h166c8a8bc062271f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4611, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0865a47ff5fd5318;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4612, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc850a4fa7bf14010;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4613, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h06de4290266c732a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4614, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h1cf91c2028f63761;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4615, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he9ed31f507c01fcf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4616, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7af20597a34584b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4617, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h86406199ae5719c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4618, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h880eb7a3ff867f9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4619, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h916959c8b54b1d2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4620, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf9b4b3c13709d94b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4621, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b749519a05d260c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4622, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h01c67561d3b9bc8f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4623, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc94f9300f378da23;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4624, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h3408b034b6e30de9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4625, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1d1a7b3d2893db7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4626, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf1d043fdad8a6d6e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4627, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54215335dc1dc2b5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4628, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2b555a6492db9451;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4629, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf58c59e224665f07;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4630, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hb093c3fcae05f7ac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4631, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76b3b02e5c7483eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4632, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda4a0275126027c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4633, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ffeed8842e0c727;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4634, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc33741c7e6a7a978;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4635, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd57af3a89aaf593e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4636, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4fa0bdb235310d95;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4637, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac8ef3cef75c38ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4638, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76bd4998a3231ae3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4639, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h16231b3f333644ff;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4640, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2bac6bc1858e08e7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4641, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6def5e19860d5cc0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4642, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c55811f0c7742c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4643, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb3a58f5be12d9ae1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4644, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h424bffc666d91801;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4645, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2a0248e2aaebe0ec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4646, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb4fbe6a709d4454b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4647, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hccb7d9d12fd10ae4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4648, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9310db8f5b54929;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4649, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9427435ac5c87cef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4650, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h76bf8c07de20ee3d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4651, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0715c3ea91f66528;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4652, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h04c6012a461321b0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4653, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c9936cd22bb01b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4654, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h9a3bde5aa6c8e3c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4655, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha482f7c3526ff599;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4656, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he8e6d0df0701724f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4657, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84a1de798a418194;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4658, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h22e9e690aac3ed72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4659, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c32586694b31e9b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4660, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84f5cb610ee4c25f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4661, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h435ed2a394aee984;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4662, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b545db619862d96;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4663, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b506e716c8416cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4664, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h99f7a9817e3e010b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4665, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b9f6382a63aea49;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4666, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h960d0b2afbc14591;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4667, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0556249b31154ffd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4668, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2987721d360b4765;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4669, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hcb07dab69c22e915;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4670, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6e03a581d6bdf073;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4671, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h476051e304586be1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4672, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0b0085dc6caaeb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4673, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f2e4a8c27325661;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4674, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef755e7ae1a145cc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4675, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2343ba99ebc50ecd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4676, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h5f394a5baa14852c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4677, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78b5b36e958abae0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4678, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd901d0df39fe3518;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4679, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha7fc5b47e123cff8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4680, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc58f4964a019dbf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4681, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hca2133ba4357c78b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4682, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb6bb6bac0906a61a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4683, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde1e141d6267bc97;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4684, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7826d32a138b484c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4685, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4381e23d690b6207;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4686, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb97680b346374686;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4687, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h22c6bafb50dad0f5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4688, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51e9ec65861123ae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4689, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h710e230e7495e011;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4690, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc357b0625fe1eb75;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4691, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'hd758fbdd0f600e9f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4692, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbb0a043c66473a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4693, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h19e9a835ac6fd249;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4694, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha287ce2ec7c22782;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4695, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdda4213841386f42;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4696, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf779d912fa1ee844;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4697, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h53f2f4d70c24e424;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4698, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfe56585e7f3fc054;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4699, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hacaee3c6a836ed1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4700, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h84218d7c2fa665d2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4701, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd9b9ee0d4ef25e64;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4702, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9e45ff27bfa7ac17;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4703, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf28fcb0ee67e23d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4704, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h567835c4482a13bf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4705, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4930a36a5bb8e291;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4706, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1286071f5220284;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4707, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2764556b84b4ea7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4708, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4f516cb0e91be3f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4709, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3c4f41a92186bfed;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4710, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7852c24019777fa6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4711, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h940ba9dc54571708;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4712, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcc68bad49a46f2cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4713, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h896ab1d5e38d0997;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4714, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h56f5d265c6fa2ae8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4715, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h6208eef8ed3c0a26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4716, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd6d2d595bedd123e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4717, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h847faa072f7000df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4718, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h54c5126aafa12817;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4719, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc9c19d7a1895a8a5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4720, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h373f6c65569fee8e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4721, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96c80acd67120e03;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4722, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0848d1574318dce6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4723, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hda3541e8ffe2550d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4724, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h932f6c0d8997c7a8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4725, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68831c10a8ef1293;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4726, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h034a54a53ca2c75f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4727, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h13baebda4e3b34c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4728, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h32a86ae70cb8755a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4729, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2d0fc6de54840cd5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4730, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc7f9b66960e7f1e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4731, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2f542cf9c9462aaa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4732, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8e783b6010a078a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4733, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56d1829c3eff7092;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4734, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha9c645638bf52c47;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4735, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h553eb8bfb3f77496;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4736, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7ab146cefb07e563;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4737, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h880235bece3f67a2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4738, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f8e401b31cd790c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4739, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9823021f835318e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4740, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h295f79cd02e6b9d6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4741, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5e7c1cd3bb62ca44;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4742, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1c93edcc6084252c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4743, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hb1e19678f02ed6ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4744, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56b37e23d16f5d2c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4745, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h88334da7305f840e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4746, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h168d0ad46a49c7f7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4747, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2e2ce5177e880653;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4748, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h40c01d882a3d8a5d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4749, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hea8a3f58c980848b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4750, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h39c90053729aa5eb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4751, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb0e3f5203651243b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4752, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d8ee073c4657801;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4753, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3f0acdc366a4052a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4754, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf221f04110e324e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4755, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hddac4ce5da8646cf;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4756, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5d764c1ed52014f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4757, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h42137d3ea28615e8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4758, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef90f7e63813ed25;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4759, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee9e8dbe484970d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4760, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h58f0b36e8b9c54c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4761, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb001161d25bfa668;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4762, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee078d5ae8e3b037;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4763, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h75f6d1d0ce55105d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4764, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3006a886d3787600;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4765, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28a28798fd198296;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4766, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfcf2cac57f5c2605;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4767, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haac780de0f42901b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4768, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5eeeb30b9bf516bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4769, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6d054b65d44e11bc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4770, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h667822650c09f942;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4771, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h727613f619b9d9a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4772, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbc908fe605fbd6e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4773, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'heaadc647d7d62c9c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4774, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h07ab21f9dbbd37b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4775, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c285d59a0237332;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4776, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haa90162dc3d1263a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4777, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd938258023ed69c9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4778, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc043dc3fb8e4bb39;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4779, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h851bbbef3d340b56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4780, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7bac1615a47a2a94;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4781, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h77a090388f238c7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4782, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b86bc1752a73572;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4783, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h119dc69df9a0cb2e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4784, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h89615d04ac4a3dab;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4785, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h92c1e4b2ab8e1bc4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4786, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2ae0b9b869eb62a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4787, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h09de2025e9a68624;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4788, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb40fdeb764413b36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4789, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e149547b2fdc152;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4790, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8996c860cfb16ca7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4791, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa797753c6287398;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4792, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h5df876dd6eee88fc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4793, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h67446c2769e3a5b1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4794, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd4358a4bedb712fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4795, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce99641f97c1e1fb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4796, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h845c910d18418564;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4797, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h43e0ebd117fda204;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4798, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9c2a36281d78c778;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4799, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h83bc2a1671eb1b16;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4800, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc6cf4d7916bcdb9d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4801, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb145ef59b0ee1976;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4802, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd2f8e62b9cd50a4f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4803, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3ad2904d63d2dccc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4804, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2ebc8ad84a51281;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4805, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b576dd62c3fc49e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4806, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h7b620b03f0c87c80;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4807, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h843049cac16274b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4808, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd7e43cba76280103;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4809, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha17529bf29c7c485;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4810, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h082d4661908d4f3c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4811, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc1092c5730dd115b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4812, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8127df2e12119064;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4813, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'had534d24697acc74;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4814, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hed5528e2dd32f929;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4815, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h894d58cb37fe0198;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4816, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h890cc7190b0dc6d7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4817, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ab1ebc40653b240;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4818, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h739e4b58ef49adf7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4819, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h261c82a27df2ecc6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4820, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h916da4915c391288;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4821, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hacfc43c7f37fb9ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4822, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h2055aaa03f2bf301;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4823, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3b4e95860ec27960;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4824, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f14ca3f25373658;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4825, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7bc03f31669f3ea;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4826, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59f135ac48fe52dd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4827, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5fa63dcc69caa1a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4828, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd6848516be73af1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4829, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3d5eeb1696619226;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4830, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6bdaefde6d723d7a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4831, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70c3f86d0b7b0751;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4832, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbceb77f1d6c0f4d0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4833, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h91ac0b35fc100cd0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4834, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdbb93265066ac201;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4835, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hbd1d56e8b1a79138;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4836, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56a74f858a7f0fd7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4837, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h296ee0ead126d6d8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4838, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62ddd5c3711e4ee0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4839, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h979d477862db3503;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4840, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h70adf883375d9bfc;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4841, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb9f9a9ac426249a7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4842, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h440997cebabac4f9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4843, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb1474c944f90a2f1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4844, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h501fd41d9480af2f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4845, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h438670a4f14f134e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4846, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90c724152da9ffee;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4847, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h56c49f1a76ff240c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4848, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7be9278cec4a67ca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4849, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1caf0e8e40331523;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4850, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h48e493d5468578c6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4851, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h85f41af56e69c1e2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4852, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h16fd022bcaf6ef77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4853, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6914437be18c418c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4854, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3d4305e69f51ead;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4855, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h382d1a54e5539ad2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4856, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf93f9334e3e7e56;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4857, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd8e405873e0a1d1e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4858, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hee27863c69bb1f6b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4859, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h9460f93f70ee3339;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4860, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haac12a99977a0a72;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4861, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'ha9b0cc58cc7ed7e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4862, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8ba4856735c30c02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4863, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23185eb94541f3b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4864, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcf81a8dd481e8a0f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4865, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc84b781ab1da098b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4866, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h371c7951c2906a79;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4867, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h27faa60afa38d3af;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4868, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h641527b03b38416d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4869, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h40786bb254aec450;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4870, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd9e146f6594e1b57;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4871, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h47d1a2bf8b8dc0cb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4872, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'hf9b7d28b05712584;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4873, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h71373f2133f96254;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4874, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8dae2a8e01d5c7a1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4875, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h23e3f3b66e52bdb0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4876, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6f77750d2c1f8bd3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4877, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9de91a807cf7dcf6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4878, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h68fba73158ff410a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4879, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb2f65b734eee1c8;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4880, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h3f327afa2e5ca471;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4881, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h59f64cc99ff991c4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4882, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h28d6b2d34dc8cfaa;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4883, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h96004852473ef086;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4884, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1b2600cbe933bfec;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4885, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f4dde41400128e0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4886, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a6d4f6c9cc313fe;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4887, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7c545197490b84e1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4888, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62f1ffa2e33bebca;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4889, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb2a76238f200e13b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4890, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5987f368501c4da;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4891, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hce8c070ad6348322;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4892, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4b1747385925e17b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4893, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3544fcb18cc5b910;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4894, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e80d6812f1662cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4895, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he99243ea9eb35755;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4896, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hddafab9ac8e7cc29;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4897, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h002954794c3f50c0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4898, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h50be01e5e9bd59b2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4899, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62a807e8625b5562;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4900, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51e9a4972d409fba;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4901, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0c224660bbe83346;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4902, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e3a1fd19d0fa618;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4903, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h20750b534131c121;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4904, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h68dc1e41ca489005;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4905, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf564a832bbcede3f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4906, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h9f244dfdeafe890c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4907, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'ha4088e95fd6dd044;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4908, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3255de82ccf753ef;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4909, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8e809b61fc6fdfc5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4910, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hf66a6e7d7a301b77;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4911, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hde10234240c51a67;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4912, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h242245d4f382b750;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4913, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h90d53dd470533ac5;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4914, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f3d12647f92f364;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4915, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha253d9ecd1ce6938;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4916, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0429ad95a9788360;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4917, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdb3f8ae843c0b6b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4918, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h144b0bb011fc55f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4919, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd1;
        io_in_top = 64'h1bbfb2fd2e865e2a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4920, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd648cc51d7dedbe9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4921, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h40ebbebd7f9f8c36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4922, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h411e2917d4dc29b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4923, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h651c41881dca8a36;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4924, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h054c0cdbc4d84138;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4925, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9716c0d98b4d4cbb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4926, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h55a888444a5f564c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4927, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf0189a97f27c4aae;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4928, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h505408ebe08cd809;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4929, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h33a8481361545109;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4930, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7656f57d1468fb73;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4931, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf5e9b81ae2cb6b46;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4932, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h706754f01169880b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4933, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h8b88aa8a525abe27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4934, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hb7698a66bdf1bcce;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4935, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3039564f3ae9d66b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4936, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf8c3c0968ee35674;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4937, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h222fd26ddda71cc4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4938, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1f9a8ce71d382e1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4939, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3703b42d3c4a3b26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4940, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'haddc7417f67ec930;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4941, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hee27e0df2a2fcbad;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4942, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6fe9fb52145be748;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4943, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h36b39fa8fc2fb35f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4944, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc3f6bf38bb0a2561;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4945, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdd5d170b1da969b7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4946, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hdc523c2e7b45f7f6;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4947, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'hd6eabcc20aaffcb4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4948, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4574033590378d22;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4949, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h62834e6c3ac6bc26;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4950, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd8;
        io_in_top = 64'h4ae3fd9e73c5bce2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4951, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h178554b0d44b0445;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4952, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h9f56309faa4511a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4953, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7f232441434088e3;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4954, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h4df5b8eb649e41f0;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4955, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'heb9bf1f483b2c8e4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4956, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h568619dc8dfc3571;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4957, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd83491f199d5f24c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4958, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hd85d6d91517a31d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4959, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5a8e23630c5ac209;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4960, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc334befa5f2d2094;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4961, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hff9da18bf411d4bb;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4962, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5b7e7da576b075a4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4963, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h6969761e30422a5b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4964, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfa3c27afe5eaa444;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4965, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0ea1c2bbe5425f4f;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4966, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc5f82e75b9cb1a33;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4967, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1570b8e6667c0f2b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4968, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h78599f0d90cfd12d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4969, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h1e4ad0fead9a393a;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4970, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h7d9e9e0d9cf91ca9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4971, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h57744629e6186f1b;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4972, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf25fa8a1bdb6093d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4973, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hac6b62642c382928;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4974, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h39ec535a4ddf24be;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4975, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h25420d374200a0df;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4976, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h076449e9f8b27b7c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4977, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hf76fb6f7e9e492a9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4978, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc0e8ed6254365025;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4979, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h0e705843796a4122;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4980, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h1a462ca32bdad6c2;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4981, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h30ebca6480ac14d4;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4982, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hfd1e692876e7216c;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4983, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4d3b8412471a4d1;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4984, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hef750b99f693ea27;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4985, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hcb31771f1617a6b9;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4986, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'he178df255eca91bd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4987, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h5ba095a4eb983c43;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4988, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6f23464c356cde7;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4989, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h3e7bbb032577da89;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4990, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h896c8ee15bf4cbac;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4991, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd4;
        io_in_top = 64'h8fbe13b6bdc86a02;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4992, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha6f6fed1fabf6826;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4993, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'ha4d0e444ca95b044;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4994, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'hc459f29e2f348496;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4995, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h18ffbebe4bd93283;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4996, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h51287b07609d03cd;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4997, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd2;
        io_in_top = 64'h36b2ddf07271119e;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4998, defect_fuses, io_out_bottom);

        @(posedge clk);
        defect_fuses = 4'd0;
        io_in_top = 64'h367e97e7e7d07d1d;
        #30;
        $display("TEST_ID:%d FUSES:%d OUT:%x", 4999, defect_fuses, io_out_bottom);


        $display("CHAOS_TEST_COMPLETE");
        $finish;
    end
endmodule
