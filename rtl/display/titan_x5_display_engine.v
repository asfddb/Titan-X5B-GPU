`timescale 1ns / 1ps

/*
 * Module: titan_x5_display_engine
 * Description: Configurable VGA timing generator with 32-bit RGBA input
 * and double-buffering support.
 */
module titan_x5_display_engine (
    input  wire        clk,        // Core clock
    input  wire        pclk,       // Pixel clock
    input  wire        rst_n,
    
    // Configuration
    input  wire [11:0] h_visible,
    input  wire [11:0] h_front_porch,
    input  wire [11:0] h_sync_pulse,
    input  wire [11:0] h_back_porch,
    input  wire [11:0] v_visible,
    input  wire [11:0] v_front_porch,
    input  wire [11:0] v_sync_pulse,
    input  wire [11:0] v_back_porch,
    
    // Framebuffer Interface (runs on core clk)
    output wire        swap_buffers,
    output wire [31:0] fb_read_addr,
    input  wire [31:0] fb_rgba_data,
    output wire        fb_read_req,
    input  wire        fb_read_ack,
    
    // VGA Output
    output reg         vga_hsync,
    output reg         vga_vsync,
    output reg  [7:0]  vga_r,
    output reg  [7:0]  vga_g,
    output reg  [7:0]  vga_b,
    output reg         vga_de // Data Enable
);

    reg [11:0] h_counter;
    reg [11:0] v_counter;
    
    wire [11:0] h_total = h_visible + h_front_porch + h_sync_pulse + h_back_porch;
    wire [11:0] v_total = v_visible + v_front_porch + v_sync_pulse + v_back_porch;
    
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            h_counter <= 12'd0;
            v_counter <= 12'd0;
        end else begin
            if (h_counter == h_total - 1) begin
                h_counter <= 12'd0;
                if (v_counter == v_total - 1)
                    v_counter <= 12'd0;
                else
                    v_counter <= v_counter + 1;
            end else begin
                h_counter <= h_counter + 1;
            end
        end
    end
    
    // Hsync and Vsync generation (Active Low typically, parameterized here as Active High for simplicity)
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            vga_hsync <= 1'b0;
            vga_vsync <= 1'b0;
            vga_de    <= 1'b0;
        end else begin
            vga_hsync <= (h_counter >= h_visible + h_front_porch) && 
                         (h_counter < h_visible + h_front_porch + h_sync_pulse);
                         
            vga_vsync <= (v_counter >= v_visible + v_front_porch) && 
                         (v_counter < v_visible + v_front_porch + v_sync_pulse);
                         
            vga_de    <= (h_counter < h_visible) && (v_counter < v_visible);
        end
    end
    
    // ==========================================
    // Clock Domain Crossing (CDC) Asynchronous FIFO
    // ==========================================
    wire        fifo_full;
    wire        fifo_empty;
    wire [31:0] fifo_rdata;
    wire        fifo_rinc;
    
    titan_x5_async_fifo #(
        .DATA_WIDTH(32),
        .DEPTH_LOG2(6) // 64 entries
    ) pixel_fifo (
        .wclk(clk),
        .wrst_n(rst_n),
        .winc(fb_read_ack && !fifo_full),
        .wdata(fb_rgba_data),
        .wfull(fifo_full),
        
        .rclk(pclk),
        .rrst_n(rst_n),
        .rinc(fifo_rinc),
        .rdata(fifo_rdata),
        .rempty(fifo_empty)
    );

    // Framebuffer read address mapping (Now in core clk domain, simplified fetching)
    reg [31:0] fetch_addr;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fetch_addr <= 0;
        end else if (!fifo_full) begin
            if (fetch_addr >= (h_visible * v_visible) - 1)
                fetch_addr <= 0;
            else
                fetch_addr <= fetch_addr + 1;
        end
    end
    
    assign fb_read_addr = fetch_addr;
    assign fb_read_req  = !fifo_full;
    
    // Pixel stream from FIFO
    assign fifo_rinc = vga_de && !fifo_empty;
    
    // RGB Output (Pixel clock domain)
    always @(posedge pclk or negedge rst_n) begin
        if (!rst_n) begin
            vga_r <= 8'd0;
            vga_g <= 8'd0;
            vga_b <= 8'd0;
        end else if (vga_de && !fifo_empty) begin
            vga_r <= fifo_rdata[31:24]; // R
            vga_g <= fifo_rdata[23:16]; // G
            vga_b <= fifo_rdata[15:8];  // B
        end else begin
            vga_r <= 8'd0;
            vga_g <= 8'd0;
            vga_b <= 8'd0;
        end
    end
    
    // Double buffering support: Swap buffers at the end of the visible frame
    // Cross swap signal from pclk to clk using double-flop
    reg pclk_swap;
    reg clk_swap_q1, clk_swap_q2;
    always @(posedge pclk) pclk_swap <= (h_counter == 0 && v_counter == v_total - 1);
    always @(posedge clk) {clk_swap_q2, clk_swap_q1} <= {clk_swap_q1, pclk_swap};
    assign swap_buffers = clk_swap_q2;

endmodule
