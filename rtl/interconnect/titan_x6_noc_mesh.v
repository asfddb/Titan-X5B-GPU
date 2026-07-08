// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X6 GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

module titan_x6_noc_mesh #(
    parameter MESH_X = 2,
    parameter MESH_Y = 2,
    parameter FLIT_WIDTH = 64,
    parameter NUM_VCS = 2,
    parameter DEPTH = 4
)(
    input  wire clk,
    input  wire rst_n,

    // Local ports for each node in the mesh, indexed by (y * MESH_X + x)
    input  wire [MESH_X*MESH_Y*FLIT_WIDTH-1:0] local_in_flit,
    input  wire [MESH_X*MESH_Y-1:0]            local_in_valid,
    output wire [MESH_X*MESH_Y*NUM_VCS-1:0]    local_in_credit,

    output wire [MESH_X*MESH_Y*FLIT_WIDTH-1:0] local_out_flit,
    output wire [MESH_X*MESH_Y-1:0]            local_out_valid,
    input  wire [MESH_X*MESH_Y*NUM_VCS-1:0]    local_out_credit
);

    // Internal signals to connect routers
    // Ports: 0=Local, 1=North, 2=South, 3=East, 4=West
    
    wire [5*FLIT_WIDTH-1:0] router_in_flit  [0:MESH_X-1][0:MESH_Y-1];
    wire [4:0]              router_in_valid [0:MESH_X-1][0:MESH_Y-1];
    wire [5*NUM_VCS-1:0]    router_in_credit[0:MESH_X-1][0:MESH_Y-1];
    
    wire [5*FLIT_WIDTH-1:0] router_out_flit  [0:MESH_X-1][0:MESH_Y-1];
    wire [4:0]              router_out_valid [0:MESH_X-1][0:MESH_Y-1];
    wire [5*NUM_VCS-1:0]    router_out_credit[0:MESH_X-1][0:MESH_Y-1];
    
    genvar x, y;
    generate
        for (y = 0; y < MESH_Y; y = y + 1) begin : gy
            for (x = 0; x < MESH_X; x = x + 1) begin : gx
                
                // Local port connections
                localparam NODE_ID = y * MESH_X + x;
                
                assign router_in_flit[x][y][0*FLIT_WIDTH +: FLIT_WIDTH] = local_in_flit[NODE_ID*FLIT_WIDTH +: FLIT_WIDTH];
                assign router_in_valid[x][y][0] = local_in_valid[NODE_ID];
                assign local_in_credit[NODE_ID*NUM_VCS +: NUM_VCS] = router_in_credit[x][y][0*NUM_VCS +: NUM_VCS];
                
                assign local_out_flit[NODE_ID*FLIT_WIDTH +: FLIT_WIDTH] = router_out_flit[x][y][0*FLIT_WIDTH +: FLIT_WIDTH];
                assign local_out_valid[NODE_ID] = router_out_valid[x][y][0];
                assign router_out_credit[x][y][0*NUM_VCS +: NUM_VCS] = local_out_credit[NODE_ID*NUM_VCS +: NUM_VCS];
                
                // North connection (port 1) -> South port (2) of (x, y-1)
                if (y > 0) begin
                    assign router_in_flit[x][y][1*FLIT_WIDTH +: FLIT_WIDTH] = router_out_flit[x][y-1][2*FLIT_WIDTH +: FLIT_WIDTH];
                    assign router_in_valid[x][y][1] = router_out_valid[x][y-1][2];
                    assign router_out_credit[x][y][1*NUM_VCS +: NUM_VCS] = router_in_credit[x][y-1][2*NUM_VCS +: NUM_VCS];
                end else begin
                    assign router_in_flit[x][y][1*FLIT_WIDTH +: FLIT_WIDTH] = 0;
                    assign router_in_valid[x][y][1] = 0;
                    assign router_out_credit[x][y][1*NUM_VCS +: NUM_VCS] = 0;
                end
                
                // South connection (port 2) -> North port (1) of (x, y+1)
                if (y < MESH_Y-1) begin
                    assign router_in_flit[x][y][2*FLIT_WIDTH +: FLIT_WIDTH] = router_out_flit[x][y+1][1*FLIT_WIDTH +: FLIT_WIDTH];
                    assign router_in_valid[x][y][2] = router_out_valid[x][y+1][1];
                    assign router_out_credit[x][y][2*NUM_VCS +: NUM_VCS] = router_in_credit[x][y+1][1*NUM_VCS +: NUM_VCS];
                end else begin
                    assign router_in_flit[x][y][2*FLIT_WIDTH +: FLIT_WIDTH] = 0;
                    assign router_in_valid[x][y][2] = 0;
                    assign router_out_credit[x][y][2*NUM_VCS +: NUM_VCS] = 0;
                end
                
                // East connection (port 3) -> West port (4) of (x+1, y)
                if (x < MESH_X-1) begin
                    assign router_in_flit[x][y][3*FLIT_WIDTH +: FLIT_WIDTH] = router_out_flit[x+1][y][4*FLIT_WIDTH +: FLIT_WIDTH];
                    assign router_in_valid[x][y][3] = router_out_valid[x+1][y][4];
                    assign router_out_credit[x][y][3*NUM_VCS +: NUM_VCS] = router_in_credit[x+1][y][4*NUM_VCS +: NUM_VCS];
                end else begin
                    assign router_in_flit[x][y][3*FLIT_WIDTH +: FLIT_WIDTH] = 0;
                    assign router_in_valid[x][y][3] = 0;
                    assign router_out_credit[x][y][3*NUM_VCS +: NUM_VCS] = 0;
                end
                
                // West connection (port 4) -> East port (3) of (x-1, y)
                if (x > 0) begin
                    assign router_in_flit[x][y][4*FLIT_WIDTH +: FLIT_WIDTH] = router_out_flit[x-1][y][3*FLIT_WIDTH +: FLIT_WIDTH];
                    assign router_in_valid[x][y][4] = router_out_valid[x-1][y][3];
                    assign router_out_credit[x][y][4*NUM_VCS +: NUM_VCS] = router_in_credit[x-1][y][3*NUM_VCS +: NUM_VCS];
                end else begin
                    assign router_in_flit[x][y][4*FLIT_WIDTH +: FLIT_WIDTH] = 0;
                    assign router_in_valid[x][y][4] = 0;
                    assign router_out_credit[x][y][4*NUM_VCS +: NUM_VCS] = 0;
                end
                
                // Instantiate Router
                titan_x6_noc_router #(
                    .X_ID(x),
                    .Y_ID(y),
                    .FLIT_WIDTH(FLIT_WIDTH),
                    .NUM_VCS(NUM_VCS),
                    .DEPTH(DEPTH)
                ) u_router (
                    .clk(clk),
                    .rst_n(rst_n),
                    
                    .in_flit(router_in_flit[x][y]),
                    .in_valid(router_in_valid[x][y]),
                    .in_credit(router_in_credit[x][y]),
                    
                    .out_flit(router_out_flit[x][y]),
                    .out_valid(router_out_valid[x][y]),
                    .out_credit(router_out_credit[x][y])
                );
                
            end
        end
    endgenerate

endmodule
