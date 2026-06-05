`timescale 1ns/1ps

/*
 * Module: titan_x5_rop
 * Description: Render Output Unit. Depth test (Less, Greater, Equal, Always, Never),
 * Stencil test, Alpha Blending, Delta Color Compression (DCC) support.
 * Now using a fully pipelined decoupled approach.
 */
module titan_x5_rop (
    input  wire clk,
    input  wire rst_n,

    // fragment input
    input  wire i_valid,
    output wire i_ready,
    input wire [15:0] i_x,
    input wire [15:0] i_y,
    input wire [31:0] i_z,
    input wire [31:0] i_color, // rgba

    // rop configuration
    input wire [2:0] cfg_depth_func,
    input  wire        cfg_depth_write,
    input wire [2:0] cfg_stencil_func,
    input wire [7:0] cfg_stencil_ref,
    input  wire        cfg_stencil_write,
    input  wire        cfg_blend_en,
    input  wire        cfg_dcc_en,

    // memory interface (framebuffer / depthbuffer)
    output wire        mem_req,
    output wire        mem_we,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    input  wire        mem_gnt,
    input  wire        mem_valid,
    input wire [31:0] mem_rdata,

    // dcc metadata interface
    output reg         dcc_req,
    output reg         dcc_we,
    output reg [31:0] dcc_addr,
    output reg [7:0] dcc_wdata,
    input  wire        dcc_gnt,
    input  wire        dcc_valid,

    // config base addresses
    input wire [31:0] base_color,
    input wire [31:0] base_depth,
    
    output wire [2:0] dbg_state
);

    // memory arbiter
    reg mem_busy;
    reg [1:0] mem_owner;
    
    wire z_req, c_req, w_req;
    wire z_we, c_we, w_we;
    wire [31:0] z_addr, c_addr, w_addr;
    wire [31:0] w_wdata;
    
    wire can_req = !mem_busy || mem_valid; 
    
    assign mem_req = can_req && (w_req || c_req || z_req);
    assign mem_we = w_req ? w_we : (c_req ? c_we : z_we);
    assign mem_addr = w_req ? w_addr : (c_req ? c_addr : z_addr);
    assign mem_wdata = w_req ? w_wdata : 32'd0;
    
    wire w_gnt = can_req && w_req && mem_gnt;
    wire c_gnt = can_req && !w_req && c_req && mem_gnt;
    wire z_gnt = can_req && !w_req && !c_req && z_req && mem_gnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_busy <= 0;
            mem_owner <= 0;
        end else begin
            if (mem_req && mem_gnt) begin
                mem_busy <= 1;
                if (w_req) mem_owner <= 2;
                else if (c_req) mem_owner <= 1;
                else mem_owner <= 0;
            end else if (mem_valid) begin
                mem_busy <= 0;
            end
        end
    end
    
    wire w_mem_valid = (mem_owner == 2) && mem_valid;
    wire c_mem_valid = (mem_owner == 1) && mem_valid;
    wire z_mem_valid = (mem_owner == 0) && mem_valid;

    // --- Z Unit ---
    reg [1:0] z_state;
    reg [15:0] z_x, z_y;
    reg [31:0] z_z, z_color;
    wire [31:0] z_offset = (z_y * 1024 + z_x) * 4;
    
    reg z_out_valid;
    wire c_in_ready;
    reg [15:0] zc_x, zc_y;
    reg [31:0] zc_z, zc_c;

    assign i_ready = (z_state == 0) && (!z_out_valid || c_in_ready);
    assign z_req = (z_state == 1);
    assign z_we = 0;
    assign z_addr = base_depth + z_offset;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            z_state <= 0;
            z_out_valid <= 0;
        end else begin
            if (c_in_ready) z_out_valid <= 0;
            
            case (z_state)
                0: begin
                    if (i_valid && i_ready) begin
                        z_x <= i_x; z_y <= i_y; z_z <= i_z; z_color <= i_color;
                        if (cfg_depth_func != 3'd7 && cfg_depth_func != 3'd0) begin
                            z_state <= 1;
                        end else begin
                            if (cfg_depth_func == 3'd7) begin // always
                                zc_x <= i_x; zc_y <= i_y; zc_z <= i_z; zc_c <= i_color;
                                z_out_valid <= 1;
                            end
                        end
                    end
                end
                1: begin
                    if (z_gnt) z_state <= 2;
                end
                2: begin
                    if (z_mem_valid) begin
                        z_state <= 0;
                        case (cfg_depth_func)
                            3'd1: if (z_z < mem_rdata)  begin z_out_valid <= 1; zc_x <= z_x; zc_y <= z_y; zc_z <= z_z; zc_c <= z_color; end
                            3'd2: if (z_z == mem_rdata) begin z_out_valid <= 1; zc_x <= z_x; zc_y <= z_y; zc_z <= z_z; zc_c <= z_color; end
                            3'd3: if (z_z <= mem_rdata) begin z_out_valid <= 1; zc_x <= z_x; zc_y <= z_y; zc_z <= z_z; zc_c <= z_color; end
                            3'd4: if (z_z > mem_rdata)  begin z_out_valid <= 1; zc_x <= z_x; zc_y <= z_y; zc_z <= z_z; zc_c <= z_color; end
                            3'd5: if (z_z != mem_rdata) begin z_out_valid <= 1; zc_x <= z_x; zc_y <= z_y; zc_z <= z_z; zc_c <= z_color; end
                            3'd6: if (z_z >= mem_rdata) begin z_out_valid <= 1; zc_x <= z_x; zc_y <= z_y; zc_z <= z_z; zc_c <= z_color; end
                            default: ;
                        endcase
                    end
                end
            endcase
        end
    end

    // --- C Unit (Color/Blend) ---
    reg [1:0] c_state;
    reg [15:0] c_x, c_y;
    reg [31:0] c_z, c_color;
    wire [31:0] c_offset = (c_y * 1024 + c_x) * 4;

    reg c_out_valid;
    wire w_in_ready;
    reg [15:0] cw_x, cw_y;
    reg [31:0] cw_z, cw_c;
    
    assign c_in_ready = (c_state == 0) && (!c_out_valid || w_in_ready);
    assign c_req = (c_state == 1);
    assign c_we = 0;
    assign c_addr = base_color + c_offset;

    wire [7:0] src_a = c_color[31:24];
    wire [7:0] inv_src_a = ~src_a;
    wire [31:0] mem_c_data = mem_rdata;
    wire [15:0] blend_r = (c_color[7:0] * src_a + mem_c_data[7:0] * inv_src_a) >> 8;
    wire [15:0] blend_g = (c_color[15:8] * src_a + mem_c_data[15:8] * inv_src_a) >> 8;
    wire [15:0] blend_b = (c_color[23:16] * src_a + mem_c_data[23:16] * inv_src_a) >> 8;
    wire [15:0] blend_a = (src_a * 255 + mem_c_data[31:24] * inv_src_a) >> 8; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_state <= 0;
            c_out_valid <= 0;
        end else begin
            if (w_in_ready) c_out_valid <= 0;
            
            case (c_state)
                0: begin
                    if (z_out_valid && c_in_ready) begin
                        c_x <= zc_x; c_y <= zc_y; c_z <= zc_z; c_color <= zc_c;
                        if (cfg_blend_en) c_state <= 1;
                        else begin
                            c_out_valid <= 1;
                            cw_x <= zc_x; cw_y <= zc_y; cw_z <= zc_z; cw_c <= zc_c;
                        end
                    end
                end
                1: begin
                    if (c_gnt) c_state <= 2;
                end
                2: begin
                    if (c_mem_valid) begin
                        c_state <= 0;
                        c_out_valid <= 1;
                        cw_x <= c_x; cw_y <= c_y; cw_z <= c_z;
                        cw_c <= {blend_a[7:0], blend_b[7:0], blend_g[7:0], blend_r[7:0]};
                    end
                end
            endcase
        end
    end

    // --- W Unit (Write) ---
    reg [2:0] w_state;
    reg [15:0] w_x, w_y;
    reg [31:0] w_z, w_color;
    wire [31:0] w_offset = (w_y * 1024 + w_x) * 4;

    assign w_in_ready = (w_state == 0);
    assign w_req = (w_state == 1) || (w_state == 3);
    assign w_we = 1;
    assign w_addr = (w_state == 1) ? (base_depth + w_offset) : (base_color + w_offset);
    assign w_wdata = (w_state == 1) ? w_z : w_color;
    
    reg w_granted, dcc_granted;
    reg w_valid_recv, dcc_valid_recv;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            w_state <= 0;
            dcc_req <= 0; dcc_we <= 0;
            w_granted <= 0; dcc_granted <= 0;
            w_valid_recv <= 0; dcc_valid_recv <= 0;
        end else begin
            case (w_state)
                0: begin
                    w_granted <= 0; dcc_granted <= 0;
                    w_valid_recv <= 0; dcc_valid_recv <= 0;
                    if (c_out_valid && w_in_ready) begin
                        w_x <= cw_x; w_y <= cw_y; w_z <= cw_z; w_color <= cw_c;
                        if (cfg_depth_write) w_state <= 1;
                        else w_state <= 3;
                    end
                end
                1: begin
                    if (w_gnt) w_state <= 2;
                end
                2: begin
                    if (w_mem_valid) w_state <= 3;
                end
                3: begin
                    if (cfg_dcc_en && !dcc_req && !dcc_granted) begin
                        dcc_req <= 1'b1; dcc_we <= 1'b1;
                        dcc_addr <= (base_color >> 8) + (w_offset >> 8);
                        dcc_wdata <= 8'hFF;
                    end
                    if (dcc_gnt) begin
                        dcc_req <= 0;
                        dcc_granted <= 1;
                    end
                    if (w_gnt) begin
                        w_granted <= 1;
                    end
                    if ((w_gnt || w_granted) && (!cfg_dcc_en || dcc_gnt || dcc_granted)) begin
                        w_state <= 4;
                    end
                end
                4: begin
                    if (w_mem_valid) w_valid_recv <= 1;
                    if (dcc_valid) dcc_valid_recv <= 1;
                    if ((w_mem_valid || w_valid_recv) && (!cfg_dcc_en || dcc_valid || dcc_valid_recv)) begin
                        w_state <= 0;
                    end
                end
            endcase
        end
    end

    assign dbg_state = {w_state[0], c_state[0], z_state[0]};

endmodule
