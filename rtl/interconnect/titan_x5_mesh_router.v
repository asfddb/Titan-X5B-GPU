`timescale 1ns / 1ps

/*
 * Module: titan_x5_mesh_router
 * Description: 
 *   2D Mesh NoC Router for Titan X5 GPU project.
 *   Replaces traditional AXI crossbar with a hyper-scalable NoC backbone.
 *   - Flit-based transmission
 *   - Virtual Channels (VC) support for QoS and deadlock avoidance
 *   - XY Dimension-Order Routing Algorithm
 *   - 5x5 Crossbar (Local, North, South, East, West)
 */

module titan_x5_mesh_router #(
    parameter DATA_WIDTH  = 128,
    parameter X_COORD_W   = 8,
    parameter Y_COORD_W   = 8,
    parameter VC_ID_W     = 2,
    parameter NUM_VCS     = 1 << VC_ID_W,
    parameter FLIT_TYPE_W = 2, 
    // flit types: 2'b00 = head, 2'b01 = body, 2'b10 = tail, 2'b11 = head+tail
    parameter FLIT_WIDTH  = FLIT_TYPE_W + VC_ID_W + X_COORD_W + Y_COORD_W + DATA_WIDTH,
    
    // router coordinates in the 2d mesh
    parameter [X_COORD_W-1:0] ROUTER_X_ID = 0,
    parameter [Y_COORD_W-1:0] ROUTER_Y_ID = 0
)(
    input  wire clk,
    input  wire rst_n,

    // ports: 0:local, 1:north, 2:south, 3:east, 4:west

    // ----- Port 0: Local -----
    input wire [FLIT_WIDTH-1:0] p0_in_flit,
    input  wire                  p0_in_valid,
    output wire [NUM_VCS-1:0] p0_in_ready,
    
    output wire [FLIT_WIDTH-1:0] p0_out_flit,
    output wire                  p0_out_valid,
    input wire [NUM_VCS-1:0] p0_out_ready,
    
    // ----- Port 1: North -----
    input wire [FLIT_WIDTH-1:0] p1_in_flit,
    input  wire                  p1_in_valid,
    output wire [NUM_VCS-1:0] p1_in_ready,
    
    output wire [FLIT_WIDTH-1:0] p1_out_flit,
    output wire                  p1_out_valid,
    input wire [NUM_VCS-1:0] p1_out_ready,
    
    // ----- Port 2: South -----
    input wire [FLIT_WIDTH-1:0] p2_in_flit,
    input  wire                  p2_in_valid,
    output wire [NUM_VCS-1:0] p2_in_ready,
    
    output wire [FLIT_WIDTH-1:0] p2_out_flit,
    output wire                  p2_out_valid,
    input wire [NUM_VCS-1:0] p2_out_ready,
    
    // ----- Port 3: East -----
    input wire [FLIT_WIDTH-1:0] p3_in_flit,
    input  wire                  p3_in_valid,
    output wire [NUM_VCS-1:0] p3_in_ready,
    
    output wire [FLIT_WIDTH-1:0] p3_out_flit,
    output wire                  p3_out_valid,
    input wire [NUM_VCS-1:0] p3_out_ready,
    
    // ----- Port 4: West -----
    input wire [FLIT_WIDTH-1:0] p4_in_flit,
    input  wire                  p4_in_valid,
    output wire [NUM_VCS-1:0] p4_in_ready,
    
    output wire [FLIT_WIDTH-1:0] p4_out_flit,
    output wire                  p4_out_valid,
    input wire [NUM_VCS-1:0] p4_out_ready
);

    // xy routing function
    // routes packets first along the x dimension, then y dimension.
    // prevents deadlocks in a 2d mesh grid.
    function [2:0] xy_route;
    input [X_COORD_W-1:0] src_x;
    input [Y_COORD_W-1:0] src_y;
    input [X_COORD_W-1:0] dst_x;
    input [Y_COORD_W-1:0] dst_y;
        begin
            if (dst_x > src_x)      xy_route = 3'd3; // east
            else if (dst_x < src_x) xy_route = 3'd4; // west
            else if (dst_y > src_y) xy_route = 3'd1; // north
            else if (dst_y < src_y) xy_route = 3'd2; // south
            else                    xy_route = 3'd0; // local
        end
    endfunction

    // input buffers (vc fifos) & route compute
    // instantiation for `num_vcs` fifos for each port.
    // the head flit computes the route using `xy_route()`.
    
    // switch allocation (sa) & vc allocation (va)
    // arbiters select which input vc gets access to the crossbar 
    // and which output VC it targets based on credits.
    
    // 5x5 Crossbar Switch
    // connects selected inputs to their computed outputs.
    
    // (Stubbed assignments for structural placeholder)
    assign p0_out_flit  = {FLIT_WIDTH{1'b0}};
    assign p0_out_valid = 1'b0;
    assign p0_in_ready  = {NUM_VCS{1'b1}};

    assign p1_out_flit  = {FLIT_WIDTH{1'b0}};
    assign p1_out_valid = 1'b0;
    assign p1_in_ready  = {NUM_VCS{1'b1}};

    assign p2_out_flit  = {FLIT_WIDTH{1'b0}};
    assign p2_out_valid = 1'b0;
    assign p2_in_ready  = {NUM_VCS{1'b1}};

    assign p3_out_flit  = {FLIT_WIDTH{1'b0}};
    assign p3_out_valid = 1'b0;
    assign p3_in_ready  = {NUM_VCS{1'b1}};

    assign p4_out_flit  = {FLIT_WIDTH{1'b0}};
    assign p4_out_valid = 1'b0;
    assign p4_in_ready  = {NUM_VCS{1'b1}};

endmodule
