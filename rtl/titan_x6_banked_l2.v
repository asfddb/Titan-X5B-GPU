// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X6 GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// ============================================================================
`timescale 1ns / 1ps

module titan_x6_banked_l2 #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 256,
    parameter LINE_SIZE  = 128,
    parameter WAYS       = 8,
    parameter NUM_SLICES = 16,
    parameter SLICE_SETS = 4096 // 4096 * 8 * 128 = 4MB per slice, 16 slices = 64MB
)(
    input  wire clk,
    input  wire rst_n,

    // L1 Interface (Multiplexed/Crossbar connected - per slice interface)
    input  wire [NUM_SLICES-1:0]                   req_valid,
    input  wire [NUM_SLICES*ADDR_WIDTH-1:0]        req_addr,
    input  wire [NUM_SLICES*LINE_SIZE*8-1:0]       req_wdata,
    input  wire [NUM_SLICES-1:0]                   req_write,
    output wire [NUM_SLICES-1:0]                   req_ready,

    output wire [NUM_SLICES-1:0]                   resp_valid,
    output wire [NUM_SLICES*LINE_SIZE*8-1:0]       resp_rdata,

    // memory controller interface (Per slice interface to VRAM)
    output wire [NUM_SLICES-1:0]                   mem_req_valid,
    output wire [NUM_SLICES*ADDR_WIDTH-1:0]        mem_req_addr,
    output wire [NUM_SLICES-1:0]                   mem_req_write,
    output wire [NUM_SLICES*LINE_SIZE*8-1:0]       mem_req_wdata,
    input  wire [NUM_SLICES-1:0]                   mem_req_ready,

    input  wire [NUM_SLICES-1:0]                   mem_resp_valid,
    input  wire [NUM_SLICES*LINE_SIZE*8-1:0]       mem_resp_rdata
);

    // Per-slice request holding buffer.
    //
    // The old code registered the request but exposed req_ready combinationally
    // from slice_req_ready, so it could overwrite an in-flight request while the
    // slice was still using req_addr (the slice does not latch its request and
    // needs it stable for the whole COMPARE/WRITEBACK/ALLOCATE/REFILL sequence).
    // This buffer registers each request (the intended NoC->L2 pipeline stage)
    // and holds it stable until the slice completes, giving the requester a
    // clean single-cycle ready/valid handshake with proper backpressure.
    reg  [NUM_SLICES-1:0]             hb_busy;     // holding a request
    reg  [NUM_SLICES-1:0]             hb_present;  // slice has accepted it
    reg  [NUM_SLICES*ADDR_WIDTH-1:0]  hb_addr;
    reg  [NUM_SLICES*LINE_SIZE*8-1:0] hb_wdata;
    reg  [NUM_SLICES-1:0]             hb_write;

    wire [NUM_SLICES-1:0] slice_req_ready;
    // Present the held request to the slice until it has been accepted.
    wire [NUM_SLICES-1:0] slice_req_valid = hb_busy & ~hb_present;

    // Accept a new request only when the buffer is free (registered backpressure).
    assign req_ready = ~hb_busy;

    integer k;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hb_busy    <= {NUM_SLICES{1'b0}};
            hb_present <= {NUM_SLICES{1'b0}};
            hb_write   <= {NUM_SLICES{1'b0}};
            hb_addr    <= 0;
            hb_wdata   <= 0;
        end else begin
            for (k = 0; k < NUM_SLICES; k = k + 1) begin
                if (!hb_busy[k]) begin
                    // Capture an incoming request.
                    if (req_valid[k]) begin
                        hb_busy[k]    <= 1'b1;
                        hb_present[k] <= 1'b0;
                        hb_addr[k*ADDR_WIDTH +: ADDR_WIDTH]    <= req_addr[k*ADDR_WIDTH +: ADDR_WIDTH];
                        hb_wdata[k*LINE_SIZE*8 +: LINE_SIZE*8] <= req_wdata[k*LINE_SIZE*8 +: LINE_SIZE*8];
                        hb_write[k]   <= req_write[k];
                    end
                end else begin
                    // Mark accepted the cycle the slice takes it.
                    if (slice_req_valid[k] && slice_req_ready[k]) begin
                        hb_present[k] <= 1'b1;
                    end
                    // The slice re-asserts ready when it finishes: release the buffer.
                    if (hb_present[k] && slice_req_ready[k]) begin
                        hb_busy[k]    <= 1'b0;
                        hb_present[k] <= 1'b0;
                    end
                end
            end
        end
    end

    // Slices Output Wires
    wire [NUM_SLICES-1:0]             slice_resp_valid;
    wire [NUM_SLICES*LINE_SIZE*8-1:0] slice_resp_rdata;
    
    wire [NUM_SLICES-1:0]             slice_mem_req_valid;
    wire [NUM_SLICES*ADDR_WIDTH-1:0]  slice_mem_req_addr;
    wire [NUM_SLICES-1:0]             slice_mem_req_write;
    wire [NUM_SLICES*LINE_SIZE*8-1:0] slice_mem_req_wdata;

    genvar i;
    generate
        for (i = 0; i < NUM_SLICES; i = i + 1) begin : l2_slice
            titan_x5_l2_cache #(
                .ADDR_WIDTH(ADDR_WIDTH),
                .DATA_WIDTH(DATA_WIDTH),
                .LINE_SIZE(LINE_SIZE),
                .WAYS(WAYS),
                .SETS(SLICE_SETS),
                .BANKS(4)
            ) l2_inst (
                .clk(clk),
                .rst_n(rst_n),
                
                .req_valid(slice_req_valid[i]),
                .req_addr(hb_addr[i*ADDR_WIDTH +: ADDR_WIDTH]),
                .req_wdata(hb_wdata[i*LINE_SIZE*8 +: LINE_SIZE*8]),
                .req_write(hb_write[i]),
                .req_ready(slice_req_ready[i]),
                
                .resp_valid(slice_resp_valid[i]),
                .resp_rdata(slice_resp_rdata[i*LINE_SIZE*8 +: LINE_SIZE*8]),
                
                .mem_req_valid(slice_mem_req_valid[i]),
                .mem_req_addr(slice_mem_req_addr[i*ADDR_WIDTH +: ADDR_WIDTH]),
                .mem_req_write(slice_mem_req_write[i]),
                .mem_req_wdata(slice_mem_req_wdata[i*LINE_SIZE*8 +: LINE_SIZE*8]),
                .mem_req_ready(mem_req_ready[i]), // VRAM ready is direct, assume VRAM ctrl is pipelined
                
                .mem_resp_valid(mem_resp_valid[i]),
                .mem_resp_rdata(mem_resp_rdata[i*LINE_SIZE*8 +: LINE_SIZE*8])
            );
        end
    endgenerate

    // Pipeline stage 2: Outgoing responses and mem requests
    reg [NUM_SLICES-1:0]             resp_valid_q;
    reg [NUM_SLICES*LINE_SIZE*8-1:0] resp_rdata_q;
    
    reg [NUM_SLICES-1:0]             mem_req_valid_q;
    reg [NUM_SLICES*ADDR_WIDTH-1:0]  mem_req_addr_q;
    reg [NUM_SLICES-1:0]             mem_req_write_q;
    reg [NUM_SLICES*LINE_SIZE*8-1:0] mem_req_wdata_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_valid_q <= {NUM_SLICES{1'b0}};
            resp_rdata_q <= 0;
            mem_req_valid_q <= {NUM_SLICES{1'b0}};
            mem_req_addr_q <= 0;
            mem_req_write_q <= 0;
            mem_req_wdata_q <= 0;
        end else begin
            resp_valid_q <= slice_resp_valid;
            resp_rdata_q <= slice_resp_rdata;
            
            // Assuming mem_req_ready from VRAM is backpressuring properly before we register
            // Actually, if we pipeline mem_req, we need to handle mem_req_ready carefully.
            // For now, we bypass the VRAM request pipeline to avoid handshaking breakage,
            // or we just register them directly. Let's register responses to L1 and bypass VRAM reqs.
            // VRAM requests are already heavily pipelined in VRAM controller.
        end
    end
    
    assign resp_valid = resp_valid_q;
    assign resp_rdata = resp_rdata_q;
    
    // Bypass mem_req pipeline to maintain simple handshaking with VRAM controller
    assign mem_req_valid = slice_mem_req_valid;
    assign mem_req_addr = slice_mem_req_addr;
    assign mem_req_write = slice_mem_req_write;
    assign mem_req_wdata = slice_mem_req_wdata;

endmodule
