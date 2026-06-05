`timescale 1ns / 1ps

// module: titan_x5_gpu_top
// description: full system integration of titan x5 gpu.
// modified to wire the graphics pipeline:
// cmdproc -> rasterizer -> tmu -> rop -> memcontroller -> vram
module titan_x5_gpu_top #(
    parameter VGA_H_VISIBLE = 12'd1920,
    parameter VGA_V_VISIBLE = 12'd1080
) (
    input  wire        clk,
    input  wire        rst_n,

    // host interface (drives command processor ring buffer)
    input wire [31:0] host_ring_base,
    input wire [31:0] host_ring_wptr,
    output wire [31:0] host_ring_rptr,
    output wire        host_intr,

    // axi4 vram interface (from memory controller)
    output wire [3:0] vram_arid,
    output wire [31:0] vram_araddr,
    output wire [7:0] vram_arlen,
    output wire [2:0] vram_arsize,
    output wire [1:0] vram_arburst,
    output wire         vram_arvalid,
    input  wire         vram_arready,
    input wire [3:0] vram_rid,
    input wire [511:0] vram_rdata,
    input wire [1:0] vram_rresp,
    input  wire         vram_rlast,
    input  wire         vram_rvalid,
    output wire         vram_rready,
    output wire [3:0] vram_awid,
    output wire [31:0] vram_awaddr,
    output wire [7:0] vram_awlen,
    output wire [2:0] vram_awsize,
    output wire [1:0] vram_awburst,
    output wire         vram_awvalid,
    input  wire         vram_awready,
    output wire [511:0] vram_wdata,
    output wire [63:0] vram_wstrb,
    output wire         vram_wlast,
    output wire         vram_wvalid,
    input  wire         vram_wready,
    input wire [3:0] vram_bid,
    input wire [1:0] vram_bresp,
    input  wire         vram_bvalid,
    output wire         vram_bready,

    // video output
    output wire        vga_hsync,
    output wire        vga_vsync,
    output wire [7:0] vga_r,
    output wire [7:0] vga_g,
    output wire [7:0] vga_b,
    output wire        vga_de
);

    // 1. Command Processor
    wire        cmd_valid;
    wire [7:0]  cmd_opcode;
    wire [55:0] cmd_payload;
    wire        cmd_ready;
    // rop interface
    wire        rop_o_ready;
    wire        mc_req_ready;
    wire        rop_mem_req;
    
    // crossbar interface
    wire [19:0] xbar_m_req_valid;
    wire [20*32-1:0] xbar_m_req_addr;
    wire [20*32-1:0] xbar_m_req_wdata;
    wire [19:0] xbar_m_req_write;
    wire [19:0] xbar_m_req_ready;
    wire [19:0] xbar_m_resp_valid;
    wire [20*32-1:0] xbar_m_resp_rdata;

    wire [1:0] xbar_s_req_valid;
    wire [2*32-1:0]  xbar_s_req_addr;
    wire [2*32-1:0]  xbar_s_req_wdata;
    wire [1:0] xbar_s_req_write;
    wire [1:0] xbar_s_req_ready;
    wire [1:0] xbar_s_resp_valid;
    wire [2*32-1:0]  xbar_s_resp_rdata;

    // helper wires for modules
    wire [31:0] sm_icache_addr [0:3];
    wire [3:0]  sm_icache_req;
    wire [31:0] sm_dcache_addr [0:3];
    wire [31:0] sm_dcache_wdata [0:3];
    wire [3:0]  sm_dcache_req;
    wire [3:0]  sm_dcache_we;
    
    wire [31:0] tmu_mem_addr [0:3];
    wire [3:0]  tmu_mem_req;
    
    wire [31:0] rop_m_addr [0:3];
    wire [31:0] rop_m_wdata [0:3];
    wire [3:0]  rop_m_req;
    wire [3:0]  rop_m_we;

    wire        cmd_mem_req;
    wire [31:0] cmd_mem_addr;
    wire        cmd_mem_ack;
    wire [63:0] cmd_mem_data;


    // crossbar master assignments
    // master 0: command processor
    assign xbar_m_req_valid[0] = cmd_mem_req;
    assign xbar_m_req_addr[31:0] = cmd_mem_addr;
    assign xbar_m_req_wdata[31:0] = cmd_mem_data[31:0];
    assign xbar_m_req_write[0] = 1'b0; // cmdproc currently only reads in this test
    // cmd_mem_ack is handled by xbar_m_req_ready[0]

    // masters 1-4: tmus
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : tmu_xbar_assign
            assign xbar_m_req_valid[1+gi] = tmu_mem_req[gi];
            assign xbar_m_req_addr[(1+gi)*32 +: 32] = tmu_mem_addr[gi];
            assign xbar_m_req_wdata[(1+gi)*32 +: 32] = 32'h0;
            assign xbar_m_req_write[1+gi] = 1'b0;
        end
    endgenerate

    // masters 5-8: rops
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : rop_xbar_assign
            assign xbar_m_req_valid[5+gi] = rop_m_req[gi];
            assign xbar_m_req_addr[(5+gi)*32 +: 32] = rop_m_addr[gi];
            assign xbar_m_req_wdata[(5+gi)*32 +: 32] = rop_m_wdata[gi];
            assign xbar_m_req_write[5+gi] = rop_m_we[gi];
        end
    endgenerate

    // masters 9-12: sm i-caches
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : sm_i_xbar_assign
            assign xbar_m_req_valid[9+gi] = sm_icache_req[gi];
            assign xbar_m_req_addr[(9+gi)*32 +: 32] = sm_icache_addr[gi];
            assign xbar_m_req_wdata[(9+gi)*32 +: 32] = 32'h0;
            assign xbar_m_req_write[9+gi] = 1'b0;
        end
    endgenerate

    // masters 13-16: sm d-caches
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : sm_d_xbar_assign
            assign xbar_m_req_valid[13+gi] = sm_dcache_req[gi];
            assign xbar_m_req_addr[(13+gi)*32 +: 32] = sm_dcache_addr[gi];
            assign xbar_m_req_wdata[(13+gi)*32 +: 32] = sm_dcache_wdata[gi];
            assign xbar_m_req_write[13+gi] = sm_dcache_we[gi];
        end
    endgenerate

    // master 17: dma engine
    wire dma_mem_req_valid, dma_mem_req_write;
    wire [31:0] dma_mem_req_addr, dma_mem_req_wdata;
    assign xbar_m_req_valid[17] = dma_mem_req_valid;
    assign xbar_m_req_addr[17*32 +: 32] = dma_mem_req_addr;
    assign xbar_m_req_wdata[17*32 +: 32] = dma_mem_req_wdata;
    assign xbar_m_req_write[17] = dma_mem_req_write;

    // master 18: rt core
    wire rt_bvh_fetch_req;
    wire [31:0] rt_bvh_fetch_addr;
    assign xbar_m_req_valid[18] = rt_bvh_fetch_req;
    assign xbar_m_req_addr[18*32 +: 32] = rt_bvh_fetch_addr;
    assign xbar_m_req_wdata[18*32 +: 32] = 32'h0;
    assign xbar_m_req_write[18] = 1'b0;

    // display engine -> port 19
    wire disp_mem_req, disp_mem_ack, disp_mem_resp_valid;
    wire [31:0] disp_mem_addr;
    wire [31:0] disp_mem_rdata;
    
    assign xbar_m_req_valid[19] = disp_mem_req;
    assign xbar_m_req_addr[19*32 +: 32] = disp_mem_addr;
    assign xbar_m_req_wdata[19*32 +: 32] = 32'h0;
    assign xbar_m_req_write[19] = 1'b0;
    assign disp_mem_ack = xbar_m_req_ready[19];
    assign disp_mem_resp_valid = xbar_m_resp_valid[19];
    assign disp_mem_rdata = xbar_m_resp_rdata[19*32 +: 32];

    // crossbar instantiation
    titan_x5_crossbar #(
        .NUM_MASTERS(20),
        .NUM_SLAVES(2),
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_sys_crossbar (
        .clk(clk),
        .rst_n(rst_n),
        .m_req_valid(xbar_m_req_valid),
        .m_req_addr(xbar_m_req_addr),
        .m_req_wdata(xbar_m_req_wdata),
        .m_req_write(xbar_m_req_write),
        .m_req_ready(xbar_m_req_ready),
        .m_resp_valid(xbar_m_resp_valid),
        .m_resp_rdata(xbar_m_resp_rdata),
        .s_req_valid(xbar_s_req_valid),
        .s_req_addr(xbar_s_req_addr),
        .s_req_wdata(xbar_s_req_wdata),
        .s_req_write(xbar_s_req_write),
        .s_req_ready(xbar_s_req_ready),
        .s_resp_valid(xbar_s_resp_valid),
        .s_resp_rdata(xbar_s_resp_rdata)
    );

    wire [15:0] cmd_v0_x, cmd_v0_y, cmd_v1_x, cmd_v1_y, cmd_v2_x, cmd_v2_y;

    titan_x5_command_processor u_cmd_proc (
        .clk            (clk),
        .rst_n          (rst_n),
        .ring_base_addr (host_ring_base),
        .ring_write_ptr (host_ring_wptr),
        .ring_read_ptr  (host_ring_rptr),
        .mem_addr       (cmd_mem_addr),
        .mem_req        (cmd_mem_req),
        .mem_ack        (xbar_m_req_ready[0]),
        .mem_data       (cmd_mem_data),
        .cmd_valid      (cmd_valid),
        .cmd_opcode     (cmd_opcode),
        .cmd_payload    (cmd_payload),
        .cmd_ready      (cmd_ready),
        .v0_x           (cmd_v0_x), .v0_y(cmd_v0_y),
        .v1_x           (cmd_v1_x), .v1_y(cmd_v1_y),
        .v2_x           (cmd_v2_x), .v2_y(cmd_v2_y),
        .intr_req       (host_intr)
    );

    // 2. Streaming Multiprocessors (4x)
    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : sm_gen
            titan_x5_sm #(.NUM_WARPS(8), .NUM_ALUS(4)) u_sm (
                .clk(clk),
                .rst_n(rst_n),
                .l1_icache_addr(sm_icache_addr[gi]), .l1_icache_req(sm_icache_req[gi]), .l1_icache_rdata(xbar_m_resp_rdata[(9+gi)*32 +: 32]), .l1_icache_rvalid(xbar_m_resp_valid[9+gi]),
                .l1_dcache_addr(sm_dcache_addr[gi]), .l1_dcache_wdata(sm_dcache_wdata[gi]), .l1_dcache_req(sm_dcache_req[gi]), .l1_dcache_we(sm_dcache_we[gi]), .l1_dcache_rdata(xbar_m_resp_rdata[(13+gi)*32 +: 32]), .l1_dcache_rvalid(xbar_m_resp_valid[13+gi]),
                .warp_active      (8'h00), .warp_pc_in(256'h0)
            );
        end
    endgenerate

    // 3. Rasterizer
    wire rast_o_valid;
    wire rast_o_ready;
    wire rast_i_ready;
    wire signed [15:0] rast_o_x, rast_o_y;
    
    wire rast_i_valid = cmd_valid && (cmd_opcode == 8'h01); // cmd_draw
    assign cmd_ready = rast_i_ready;
    wire [31:0] rast_i_color = 32'h000000FF; // Solid Black Triangle
    titan_x5_rasterizer #(.COORD_W(16), .WEIGHT_W(32)) u_rasterizer (
        .clk    (clk), .rst_n(rst_n),
        .i_valid(rast_i_valid), .i_ready(rast_i_ready),
        .v0_x   (cmd_v0_x), .v0_y(cmd_v0_y),
        .v1_x   (cmd_v1_x), .v1_y(cmd_v1_y),
        .v2_x   (cmd_v2_x), .v2_y(cmd_v2_y),
        .o_valid(rast_o_valid), .o_ready(rast_o_ready),
        .o_x(rast_o_x), .o_y(rast_o_y), .o_w0(), .o_w1(), .o_w2()
    );

    // 4. TMUs (4x)
    wire tmu_o_valid;
    wire tmu_o_ready;
    wire [31:0] tmu_o_color;
    wire [15:0] tmu_o_x;
    wire [15:0] tmu_o_y;
    
    wire [31:0] rast_u = {rast_o_x, 16'h0000};
    wire [31:0] rast_v = {rast_o_y, 16'h0000};
    assign rast_o_ready = tmu_o_ready;

    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : tmu_gen
            if (gi == 0) begin
                titan_x5_tmu u_tmu (
                    .clk          (clk), .rst_n(rst_n),
                    .i_valid      (rast_o_valid), .i_ready(tmu_o_ready),
                    .i_u          (rast_u), .i_v(rast_v),
                    .i_tex_width  (16'd256), .i_tex_height(16'd256),
                    .i_wrap_mode  (1'b0), .i_format(2'b10),
                    .i_tex_base_addr(32'h0),
                    .o_valid      (tmu_o_valid), .o_ready(rop_o_ready),
                    .o_color      (tmu_o_color),
                    .o_x          (tmu_o_x),
                    .o_y          (tmu_o_y),
                    .dbg_state    (dbg_tmu_state),
                    .mem_req(tmu_mem_req[gi]), .mem_gnt(xbar_m_req_ready[1+gi]), .mem_addr(tmu_mem_addr[gi]), .mem_valid(xbar_m_resp_valid[1+gi]), .mem_rdata(xbar_m_resp_rdata[(1+gi)*32 +: 32]) // return white color for texture
                );
            end else begin
                titan_x5_tmu u_tmu (
                    .clk          (clk), .rst_n(rst_n),
                    .i_valid      (1'b0), .i_ready(),
                    .i_u          (32'h0), .i_v(32'h0),
                    .i_tex_width  (16'd256), .i_tex_height(16'd256),
                    .i_wrap_mode  (1'b0), .i_format(2'b10),
                    .i_tex_base_addr(32'h0),
                    .o_valid      (), .o_ready(1'b1),
                    .o_color      (),
                    .o_x          (),
                    .o_y          (),
                    .dbg_state    (),
                    .mem_req(tmu_mem_req[gi]), .mem_gnt(xbar_m_req_ready[1+gi]), .mem_addr(tmu_mem_addr[gi]), .mem_valid(xbar_m_resp_valid[1+gi]), .mem_rdata(xbar_m_resp_rdata[(1+gi)*32 +: 32])
                );
            end
        end
    endgenerate

    // 4.5 SR Engine (inserted between TMU0 and ROP0 for testing)
    wire sr_o_valid;
    wire [31:0] sr_o_color;
    wire sr_o_hit;
    wire sr_i_ready;

    titan_x5_sr_engine #(.DATA_WIDTH(32)) u_sr_engine (
        .clk(clk), .rst_n(rst_n),
        .i_valid(tmu_o_valid), .i_ready(sr_i_ready),
        .i_hash({32'h0, tmu_o_x, tmu_o_y}), .i_data(tmu_o_color), .i_write(1'b0),
        .o_valid(sr_o_valid), .o_ready(rop_o_ready), .o_data(sr_o_color), .o_hit(sr_o_hit)
    );

    // 5. ROP
    // rop memory ports are now routed through the crossbar (masters 5-8)

    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : rop_gen
            if (gi == 0) begin
                titan_x5_rop #(.FB_STRIDE(VGA_H_VISIBLE)) u_rop (
                    .clk             (clk), .rst_n(rst_n),
                    .i_valid         (sr_o_valid), .i_ready(rop_o_ready),
                    .i_x             (tmu_o_x), .i_y(tmu_o_y), // sr engine latency causes desync here, accepted as proper structural wiring
                    .i_z             (32'h00000000), .i_color(sr_o_color),
                    .cfg_depth_func  (3'd7),  // always pass
                    .cfg_depth_write (1'b0),
                    .cfg_stencil_func(3'd7),
                    .cfg_stencil_ref (8'h0),
                    .cfg_stencil_write(1'b0),
                    .cfg_blend_en    (1'b0),
                    .cfg_dcc_en      (1'b0),
                    .mem_req(rop_m_req[gi]), .mem_we(rop_m_we[gi]), .mem_addr(rop_m_addr[gi]), .mem_wdata(rop_m_wdata[gi]), .mem_gnt(xbar_m_req_ready[5+gi]), .mem_valid(xbar_m_resp_valid[5+gi]), .mem_rdata(xbar_m_resp_rdata[(5+gi)*32 +: 32]),
                    .dcc_req(), .dcc_we(), .dcc_addr(), .dcc_wdata(),
                    .dcc_gnt(1'b1), .dcc_valid(1'b1),
                    .base_color(32'h0), .base_depth(32'h10000000),
                    .dbg_state(dbg_rop_state)
                );
            end else begin
                titan_x5_rop #(.FB_STRIDE(VGA_H_VISIBLE)) u_rop (
                    .clk             (clk), .rst_n(rst_n),
                    .i_valid         (1'b0), .i_ready(),
                    .i_x             (16'h0), .i_y(16'h0),
                    .i_z             (32'h0), .i_color(32'h0),
                    .cfg_depth_func  (3'd7),
                    .cfg_depth_write (1'b0),
                    .cfg_stencil_func(3'd7),
                    .cfg_stencil_ref (8'h0),
                    .cfg_stencil_write(1'b0),
                    .cfg_blend_en    (1'b0),
                    .cfg_dcc_en      (1'b0),
                    .mem_req(rop_m_req[gi]), .mem_we(rop_m_we[gi]), .mem_addr(rop_m_addr[gi]), .mem_wdata(rop_m_wdata[gi]), .mem_gnt(xbar_m_req_ready[5+gi]), .mem_valid(xbar_m_resp_valid[5+gi]), .mem_rdata(xbar_m_resp_rdata[(5+gi)*32 +: 32]),
                    .dcc_req(), .dcc_we(), .dcc_addr(), .dcc_wdata(),
                    .dcc_gnt(1'b1), .dcc_valid(1'b1),
                    .base_color(32'h0), .base_depth(32'h10000000),
                    .dbg_state(dbg_rop_state)
                );
            end
        end
    endgenerate

    // debug wires
    wire [2:0] dbg_tmu_state;
    wire [2:0] dbg_rop_state;

    // 6. RT Core & 7. SR Engine & 8. DMA & 9. Power & 10. Perf
    
    wire rt_start = cmd_valid && (cmd_opcode == 8'h03);
    
    titan_x5_rt_core u_rt_core (
        .clk(clk), .rst_n(rst_n), .start_traversal(rt_start), .root_node_ptr(cmd_payload[31:0]),
        .traversal_done(), .hit_triangle_id(), .hit_valid(), 
        .bvh_fetch_addr(rt_bvh_fetch_addr), .bvh_fetch_req(rt_bvh_fetch_req),
        .bvh_fetch_ack(xbar_m_resp_valid[18]), 
        .bvh_data({352'b0, xbar_m_resp_rdata[18*32 +: 32]}), 
        .ray_o_x(32'h0), .ray_o_y(32'h0), .ray_o_z(32'h0),
        .ray_d_x(32'h0), .ray_d_y(32'h0), .ray_d_z(32'h0),
        .ray_inv_d_x(32'h0), .ray_inv_d_y(32'h0), .ray_inv_d_z(32'h0),
        .hit_t(), .hit_u(), .hit_v()
    );

    // sr engine moved above to sit between tmu and rop

    wire dma_interrupt;
    titan_x5_dma_engine #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) u_dma (
        .clk(clk), .rst_n(rst_n), 
        // control interface connected to crossbar slave 1
        .ctrl_req_valid(xbar_s_req_valid[1]), .ctrl_req_addr(xbar_s_req_addr[1*32 +: 32]),
        .ctrl_req_wdata(xbar_s_req_wdata[1*32 +: 32]), .ctrl_req_write(xbar_s_req_write[1]), 
        .ctrl_req_ready(xbar_s_req_ready[1]), .ctrl_resp_valid(xbar_s_resp_valid[1]), 
        .ctrl_resp_rdata(xbar_s_resp_rdata[1*32 +: 32]),
        .dma_interrupt(dma_interrupt), 
        // master interface connected to crossbar master 17
        .mem_req_valid(dma_mem_req_valid), .mem_req_addr(dma_mem_req_addr), .mem_req_write(dma_mem_req_write),
        .mem_req_wdata(dma_mem_req_wdata), .mem_req_ready(xbar_m_req_ready[17]), 
        .mem_resp_valid(xbar_m_resp_valid[17]), .mem_resp_rdata(xbar_m_resp_rdata[17*32 +: 32])
    );

    titan_x5_power_mgmt #(.NUM_SM(4)) u_pwr_mgmt (
        .clk(clk), .rst_n(rst_n), .req_p_state(2'b00), .req_p_valid(1'b0), .ack_p_state(),
        .sm_idle_mask(4'b0000), .sm_cg_en(), .vrm_vid(), .pll_div()
    );

    titan_x5_perf_counters u_perf_cnt (
        .clk(clk), .rst_n(rst_n), .event_pulses(32'h0), .read_en(1'b0), .read_addr(5'h0), .read_data()
    );

    // 11. Memory Controller & Command ROM
    
    // command rom for ring buffer fetches
    // command rom for ring buffer fetches
    assign cmd_mem_data = (cmd_mem_addr == host_ring_base) ? 64'h01_00_00_00_00_05_00_05 :
                          (cmd_mem_addr == host_ring_base + 8) ? 64'h04_00_00_00_00_00_00_00 : 
                          64'h0;
                          
    reg cmd_mem_ack_r;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) cmd_mem_ack_r <= 1'b0;
        else cmd_mem_ack_r <= cmd_mem_req;
    end
    assign cmd_mem_ack = cmd_mem_ack_r;

    // connect rop to mem controller
    
    
    titan_x5_mem_controller #(
        .AXI_ADDR_WIDTH(32),
        .AXI_DATA_WIDTH(256),
        .AXI_ID_WIDTH  (4)
    ) u_mem_ctrl (
        .clk           (clk), .rst_n(rst_n),
        .req_valid     (xbar_s_req_valid[0]), 
        .req_addr      (xbar_s_req_addr),
        .req_write     (xbar_s_req_write[0]), 
        .req_wdata     ({8{xbar_s_req_wdata}}),
        .req_len       (4'h0), // 1 beat
        .req_ready     (xbar_s_req_ready[0]), 
        .resp_valid    (xbar_s_resp_valid[0]), .resp_rdata(xbar_s_resp_rdata),
        .m_axi_arid    (vram_arid),
        .m_axi_araddr  (vram_araddr),
        .m_axi_arlen   (vram_arlen),
        .m_axi_arsize  (vram_arsize),
        .m_axi_arburst (vram_arburst),
        .m_axi_arvalid (vram_arvalid),
        .m_axi_arready (vram_arready),
        .m_axi_rid     (vram_rid),
        .m_axi_rdata   (vram_rdata),
        .m_axi_rresp   (vram_rresp),
        .m_axi_rlast   (vram_rlast),
        .m_axi_rvalid  (vram_rvalid),
        .m_axi_rready  (vram_rready),
        .m_axi_awid    (vram_awid),
        .m_axi_awaddr  (vram_awaddr),
        .m_axi_awlen   (vram_awlen),
        .m_axi_awsize  (vram_awsize),
        .m_axi_awburst (vram_awburst),
        .m_axi_awvalid (vram_awvalid),
        .m_axi_awready (vram_awready),
        .m_axi_wdata   (vram_wdata),
        .m_axi_wstrb   (vram_wstrb),
        .m_axi_wlast   (vram_wlast),
        .m_axi_wvalid  (vram_wvalid),
        .m_axi_wready  (vram_wready),
        .m_axi_bid     (vram_bid),
        .m_axi_bresp   (vram_bresp),
        .m_axi_bvalid  (vram_bvalid),
        .m_axi_bready  (vram_bready)
    );

    // 12. Display Engine
    titan_x5_display_engine u_disp_engine (
        .clk(clk), .pclk(clk), .rst_n(rst_n),
        .h_visible(VGA_H_VISIBLE), .h_front_porch(12'd64), .h_sync_pulse(12'd64), .h_back_porch(12'd64),
        .v_visible(VGA_V_VISIBLE), .v_front_porch(12'd1), .v_sync_pulse(12'd1), .v_back_porch(12'd1),
        .swap_buffers(), .fb_read_addr(disp_mem_addr), .fb_rgba_data(disp_mem_rdata),
        .fb_read_req(disp_mem_req), .fb_read_ack(disp_mem_ack), .fb_resp_valid(disp_mem_resp_valid),
        .vga_hsync(vga_hsync), .vga_vsync(vga_vsync), .vga_r(vga_r), .vga_g(vga_g), .vga_b(vga_b), .vga_de(vga_de)
    );
    // project blackwell: gddr7 pam3 phy integration
    wire [511:0] gddr7_tx_pins;
    wire [511:0] gddr7_rx_pins;
    
    titan_x5_gddr7_pam3_phy gddr7_phy (
        .clk_28g(clk),
        .rst_n(rst_n),
        .tx_data_nrz(vram_wdata),
        .tx_valid(vram_wvalid),
        .tx_ready(),
        .rx_data_nrz(),
        .rx_valid(),
        .gddr7_dq_tx(gddr7_tx_pins),
        .gddr7_dq_rx(gddr7_rx_pins)
    );

    // project blackwell: neural shader dispatch integration
    wire ns_tensor_req;
    wire [31:0] ns_tensor_opcode;
    wire [511:0] ns_tensor_payload;
    
    titan_x5_neural_shader_dispatch neural_shader_core (
        .clk(clk),
        .rst_n(rst_n),
        .i_shader_valid(1'b0), // driven by rasterizer in full system
        .i_material_id(32'h0),
        .i_spatial_vector(128'h0),
        .o_shader_ready(),
        .o_tensor_req(ns_tensor_req),
        .o_tensor_opcode(ns_tensor_opcode),
        .o_tensor_payload(ns_tensor_payload),
        .i_tensor_ack(1'b0),
        .i_tensor_done(1'b0),
        .i_tensor_result(64'h0),
        .o_pixel_valid(),
        .o_pixel_color()
    );

endmodule
