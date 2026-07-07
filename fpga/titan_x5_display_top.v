// ============================================================================
// Copyright (c) 2026 Adhiraj
//
// This file is part of the Titan X5-B GPU project.
//
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

/*
 * Module: titan_x5_display_top
 * Description: Basys 3 "hardware hello world" - the Titan X5 display path
 *              only, sized to actually fit the xc7a35t (~2k LUT + 32 BRAM36
 *              measured; the full GPU is ~200x over budget, see
 *              docs/FPGA_PHASE1_REPORT.md).
 *
 *              A boot-time AXI writer fills the 128KB BRAM VRAM
 *              (titan_x5_vram_ctrl) with a 4bpp test pattern; a line-buffer
 *              shim turns the display engine's per-pixel 32-bit RGBA reads
 *              into 512-bit AXI line fetches through a 16-color palette.
 *
 *              Video mode: 640x400@70Hz (classic VGA planar mode timing) -
 *              640x400 at 4bpp is exactly 128,000 bytes, the largest full
 *              frame the 128KB VRAM can hold (640x480 needs 150KB).
 *
 *              Controls: btnC = reset, btnU = refill with pattern selected
 *              by sw[1:0], led[0] = fill done, led[15:12] = frame counter.
 */
module titan_x5_display_top (
    input  wire        clk_100mhz,
    input  wire [15:0] sw,
    input  wire        btnC,
    input  wire        btnU,
    output wire [15:0] led,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire        vga_hsync,
    output wire        vga_vsync
);

    // ------------------------------------------------------------------
    // Clocks: 100MHz core, 25MHz pixel (640x400@70 nominal is 25.175MHz;
    // 25.0MHz yields 69.5Hz, within monitor tolerance)
    // ------------------------------------------------------------------
    wire clk_core;
    BUFG bufg_core (.I(clk_100mhz), .O(clk_core));

    reg [1:0] pclk_div = 2'd0;
    always @(posedge clk_100mhz) pclk_div <= pclk_div + 1'b1;
    wire clk_pixel;
    BUFG bufg_pixel (.I(pclk_div[1]), .O(clk_pixel));

    // reset: btnC active high; synchronize deassertion
    reg [1:0] rst_sync = 2'b00;
    always @(posedge clk_core or posedge btnC) begin
        if (btnC) rst_sync <= 2'b00;
        else      rst_sync <= {rst_sync[0], 1'b1};
    end
    wire rst_n = rst_sync[1];

    // ------------------------------------------------------------------
    // Geometry
    // ------------------------------------------------------------------
    localparam H_VISIBLE = 12'd640;
    localparam V_VISIBLE = 12'd400;
    localparam LINES_TOTAL = 2000;          // 640*400 px / 128 px per 64B line

    // ------------------------------------------------------------------
    // AXI wires to titan_x5_vram_ctrl
    // ------------------------------------------------------------------
    wire [3:0]   vram_arid = 4'd0;
    reg  [31:0]  vram_araddr;
    wire [7:0]   vram_arlen = 8'd0;         // single beat
    wire [2:0]   vram_arsize = 3'd6;        // 64 bytes
    wire [1:0]   vram_arburst = 2'b01;
    reg          vram_arvalid;
    wire         vram_arready;
    wire [3:0]   vram_rid;
    wire [511:0] vram_rdata;
    wire [1:0]   vram_rresp;
    wire         vram_rlast;
    wire         vram_rvalid;
    wire         vram_rready = 1'b1;

    wire [3:0]   vram_awid = 4'd0;
    reg  [31:0]  vram_awaddr;
    wire [7:0]   vram_awlen = 8'd0;
    wire [2:0]   vram_awsize = 3'd6;
    wire [1:0]   vram_awburst = 2'b01;
    reg          vram_awvalid;
    wire         vram_awready;
    reg  [511:0] vram_wdata;
    wire [63:0]  vram_wstrb = {64{1'b1}};
    wire         vram_wlast = 1'b1;
    reg          vram_wvalid;
    wire         vram_wready;
    wire [3:0]   vram_bid;
    wire [1:0]   vram_bresp;
    wire         vram_bvalid;
    wire         vram_bready = 1'b1;

    titan_x5_vram_ctrl u_vram (
        .clk(clk_core), .rst_n(rst_n),
        .s_axi_awid(vram_awid), .s_axi_awaddr(vram_awaddr), .s_axi_awlen(vram_awlen),
        .s_axi_awsize(vram_awsize), .s_axi_awburst(vram_awburst),
        .s_axi_awvalid(vram_awvalid), .s_axi_awready(vram_awready),
        .s_axi_wdata(vram_wdata), .s_axi_wstrb(vram_wstrb), .s_axi_wlast(vram_wlast),
        .s_axi_wvalid(vram_wvalid), .s_axi_wready(vram_wready),
        .s_axi_bid(vram_bid), .s_axi_bresp(vram_bresp),
        .s_axi_bvalid(vram_bvalid), .s_axi_bready(vram_bready),
        .s_axi_arid(vram_arid), .s_axi_araddr(vram_araddr), .s_axi_arlen(vram_arlen),
        .s_axi_arsize(vram_arsize), .s_axi_arburst(vram_arburst),
        .s_axi_arvalid(vram_arvalid), .s_axi_arready(vram_arready),
        .s_axi_rid(vram_rid), .s_axi_rdata(vram_rdata), .s_axi_rresp(vram_rresp),
        .s_axi_rlast(vram_rlast), .s_axi_rvalid(vram_rvalid), .s_axi_rready(vram_rready)
    );

    // ------------------------------------------------------------------
    // Boot pattern writer: one 512-bit AXI write per 64-byte line.
    // Runs once out of reset and again on btnU (pattern from sw[1:0]).
    // ------------------------------------------------------------------
    reg [11:0] wr_line;                    // 0..1999
    reg [9:0]  wr_x0;                      // 0,128,...,512
    reg [8:0]  wr_y;                       // 0..399
    reg [1:0]  pattern_sel;
    reg        filling;
    reg        fill_done;
    reg        aw_done, w_done;

    // one 4-bit color index per 32-pixel group; 4 groups per 64B line
    wire [3:0] grp_x [0:3];
    reg  [3:0] grp_idx [0:3];
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : pat_gen
            assign grp_x[g] = wr_x0[9:5] + g[1:0]; // truncates to 4 bits (bars repeat)
            always @(*) begin
                case (pattern_sel)
                    2'd0: grp_idx[g] = grp_x[g] ^ wr_y[8:5];        // XOR checker
                    2'd1: grp_idx[g] = grp_x[g];                    // vertical bars
                    2'd2: grp_idx[g] = wr_y[8:5];                   // horizontal bars
                    default: grp_idx[g] = grp_x[g] + wr_y[8:5];     // diagonal
                endcase
            end
        end
    endgenerate

    integer k;
    always @(*) begin
        for (k = 0; k < 128; k = k + 1) begin
            vram_wdata[k*4 +: 4] = grp_idx[k/32];
        end
    end

    reg btnU_q1, btnU_q2, btnU_q3;
    always @(posedge clk_core) begin
        btnU_q1 <= btnU; btnU_q2 <= btnU_q1; btnU_q3 <= btnU_q2;
    end
    wire refill = btnU_q2 && !btnU_q3;

    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            wr_line     <= 12'd0;
            wr_x0       <= 10'd0;
            wr_y        <= 9'd0;
            pattern_sel <= 2'd0;
            filling     <= 1'b1;           // fill on boot
            fill_done   <= 1'b0;
            vram_awvalid<= 1'b0;
            vram_wvalid <= 1'b0;
            vram_awaddr <= 32'd0;
            aw_done     <= 1'b0;
            w_done      <= 1'b0;
        end else begin
            if (!filling) begin
                if (refill) begin
                    pattern_sel <= sw[1:0];
                    wr_line <= 12'd0; wr_x0 <= 10'd0; wr_y <= 9'd0;
                    filling <= 1'b1;
                    fill_done <= 1'b0;
                end
            end else begin
                // launch both channels for the current line
                if (!vram_awvalid && !aw_done) begin
                    vram_awaddr  <= {14'd0, wr_line, 6'd0};
                    vram_awvalid <= 1'b1;
                end
                if (!vram_wvalid && !w_done) vram_wvalid <= 1'b1;

                if (vram_awvalid && vram_awready) begin
                    vram_awvalid <= 1'b0; aw_done <= 1'b1;
                end
                if (vram_wvalid && vram_wready) begin
                    vram_wvalid <= 1'b0; w_done <= 1'b1;
                end

                if (vram_bvalid) begin      // write response = line landed
                    aw_done <= 1'b0; w_done <= 1'b0;
                    if (wr_line == LINES_TOTAL - 1) begin
                        filling   <= 1'b0;
                        fill_done <= 1'b1;
                    end else begin
                        wr_line <= wr_line + 1'b1;
                        if (wr_x0 == 10'd512) begin
                            wr_x0 <= 10'd0;
                            wr_y  <= wr_y + 1'b1;
                        end else begin
                            wr_x0 <= wr_x0 + 10'd128;
                        end
                    end
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Read shim: display engine asks for pixel N (byte addr = N<<2);
    // serve from a 512-bit line buffer (128 pixels), refetch on miss.
    // ------------------------------------------------------------------
    wire [31:0] fb_read_addr;
    wire        fb_read_req;
    reg         fb_read_ack;
    reg         fb_resp_valid;
    reg  [31:0] fb_rgba_data;

    wire [17:0] pix_idx  = fb_read_addr[19:2];   // 0..255999
    wire [10:0] pix_line = pix_idx[17:7];        // /128
    wire [6:0]  pix_off  = pix_idx[6:0];

    reg  [511:0] line_buf;
    reg  [10:0]  line_tag;
    reg          line_valid;
    reg          fetching;

    wire hit = line_valid && (line_tag == pix_line);
    wire [3:0] pix_nibble = line_buf[pix_off*4 +: 4];

    // 16-color palette -> 24-bit RGB (VGA-ish defaults, upper nibbles
    // carry the color so the Basys 3 4-bit DAC sees the full range)
    reg [23:0] pal_rgb;
    always @(*) begin
        case (pix_nibble)
            4'h0: pal_rgb = 24'h000000; 4'h1: pal_rgb = 24'h0000AA;
            4'h2: pal_rgb = 24'h00AA00; 4'h3: pal_rgb = 24'h00AAAA;
            4'h4: pal_rgb = 24'hAA0000; 4'h5: pal_rgb = 24'hAA00AA;
            4'h6: pal_rgb = 24'hAA5500; 4'h7: pal_rgb = 24'hAAAAAA;
            4'h8: pal_rgb = 24'h555555; 4'h9: pal_rgb = 24'h5555FF;
            4'hA: pal_rgb = 24'h55FF55; 4'hB: pal_rgb = 24'h55FFFF;
            4'hC: pal_rgb = 24'hFF5555; 4'hD: pal_rgb = 24'hFF55FF;
            4'hE: pal_rgb = 24'hFFFF55; 4'hF: pal_rgb = 24'hFFFFFF;
        endcase
    end

    always @(posedge clk_core or negedge rst_n) begin
        if (!rst_n) begin
            fb_read_ack   <= 1'b0;
            fb_resp_valid <= 1'b0;
            line_valid    <= 1'b0;
            line_tag      <= 11'd0;
            fetching      <= 1'b0;
            vram_arvalid  <= 1'b0;
            vram_araddr   <= 32'd0;
            fb_rgba_data  <= 32'd0;
        end else begin
            fb_resp_valid <= 1'b0;
            fb_read_ack   <= 1'b0;

            if (!fetching) begin
                if (fb_read_req && hit && !fb_resp_valid) begin
                    // registered ack+data: engine sees ack this cycle is
                    // too late, so pulse ack and data together next cycle
                    fb_read_ack   <= 1'b1;
                    fb_resp_valid <= 1'b1;
                    fb_rgba_data  <= {pal_rgb, 8'h00};
                end else if (fb_read_req && !hit) begin
                    fetching     <= 1'b1;
                    vram_araddr  <= {15'd0, pix_line, 6'd0};
                    vram_arvalid <= 1'b1;
                end
            end else begin
                if (vram_arvalid && vram_arready) vram_arvalid <= 1'b0;
                if (vram_rvalid) begin
                    line_buf   <= vram_rdata;
                    line_tag   <= pix_line;
                    line_valid <= 1'b1;
                    fetching   <= 1'b0;
                end
            end
        end
    end

    // ------------------------------------------------------------------
    // Display engine: 640x400@70Hz timing (25.175MHz nominal pclk)
    // ------------------------------------------------------------------
    wire [7:0] de_r, de_g, de_b;
    wire       de_de;
    wire       swap_unused;

    titan_x5_display_engine u_disp (
        .clk(clk_core), .pclk(clk_pixel), .rst_n(rst_n),
        .h_visible(H_VISIBLE), .h_front_porch(12'd16), .h_sync_pulse(12'd96), .h_back_porch(12'd48),
        .v_visible(V_VISIBLE), .v_front_porch(12'd12), .v_sync_pulse(12'd2),  .v_back_porch(12'd35),
        .swap_buffers(swap_unused),
        .fb_read_addr(fb_read_addr), .fb_rgba_data(fb_rgba_data),
        .fb_read_req(fb_read_req), .fb_read_ack(fb_read_ack), .fb_resp_valid(fb_resp_valid),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync),
        .vga_r(de_r), .vga_g(de_g), .vga_b(de_b), .vga_de(de_de)
    );

    assign vga_r = de_r[7:4];
    assign vga_g = de_g[7:4];
    assign vga_b = de_b[7:4];

    // ------------------------------------------------------------------
    // Status LEDs
    // ------------------------------------------------------------------
    reg [3:0] frame_cnt;
    reg vsync_q;
    always @(posedge clk_pixel or negedge rst_n) begin
        if (!rst_n) begin
            frame_cnt <= 4'd0;
            vsync_q   <= 1'b0;
        end else begin
            vsync_q <= vga_vsync;
            if (vga_vsync && !vsync_q) frame_cnt <= frame_cnt + 1'b1;
        end
    end

    assign led = {frame_cnt, 8'd0, pattern_sel, filling, fill_done};

endmodule
