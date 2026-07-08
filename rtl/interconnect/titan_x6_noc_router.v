// ============================================================================
// Copyright (c) 2026 Adhiraj
// 
// This file is part of the Titan X6 GPU project.
// 
// Licensed under CERN-OHL-S-2.0.
// See LICENSE for details.
// ============================================================================
`timescale 1ns / 1ps

module titan_x6_noc_router #(
    parameter X_ID = 0,
    parameter Y_ID = 0,
    parameter FLIT_WIDTH = 64,
    parameter NUM_VCS = 2,
    parameter DEPTH = 4
)(
    input  wire clk,
    input  wire rst_n,

    // Ports: 0=Local, 1=North, 2=South, 3=East, 4=West
    input  wire [5*FLIT_WIDTH-1:0] in_flit,
    input  wire [4:0]              in_valid,
    output wire [5*NUM_VCS-1:0]    in_credit,

    output wire [5*FLIT_WIDTH-1:0] out_flit,
    output reg  [4:0]              out_valid,
    input  wire [5*NUM_VCS-1:0]    out_credit
);

    // Flit types
    localparam TYPE_BODY = 2'b00;
    localparam TYPE_TAIL = 2'b01;
    localparam TYPE_HEAD = 2'b10;
    localparam TYPE_HT   = 2'b11; // Head + Tail

    genvar p, v, op, ip;

    // ---------------------------------------------------------
    // Input Buffers (FIFOs for each VC of each Port)
    // ---------------------------------------------------------
    wire [FLIT_WIDTH-1:0] buf_dout [0:4][0:NUM_VCS-1];
    wire [4:0] buf_empty [0:NUM_VCS-1];
    wire [4:0] buf_full  [0:NUM_VCS-1];
    reg  [4:0] buf_rd    [0:NUM_VCS-1];

    generate
        for (p = 0; p < 5; p = p + 1) begin : ports
            wire [FLIT_WIDTH-1:0] in_flit_p = in_flit[p*FLIT_WIDTH +: FLIT_WIDTH];
            wire [1:0] in_vc = in_flit_p[61:60];
            
            for (v = 0; v < NUM_VCS; v = v + 1) begin : vcs
                wire wr = in_valid[p] && (in_vc == v);
                
                // Simple shift register FIFO for high frequency
                reg [FLIT_WIDTH-1:0] fifo [0:DEPTH-1];
                reg [$clog2(DEPTH+1)-1:0] count;
                reg [$clog2(DEPTH)-1:0] head, tail;

                always @(posedge clk or negedge rst_n) begin
                    if (!rst_n) begin
                        count <= 0;
                        head <= 0;
                        tail <= 0;
                    end else begin
                        // Pure write: only accept when there is a free slot.
                        // Credit flow control should prevent overrun, but this
                        // guard makes silent FIFO overflow/corruption impossible.
                        if (wr && !buf_rd[v][p] && (count < DEPTH)) begin
                            fifo[tail] <= in_flit_p;
                            tail <= (tail + 1) % DEPTH;
                            count <= count + 1;
                        end else if (!wr && buf_rd[v][p]) begin
                            head <= (head + 1) % DEPTH;
                            count <= count - 1;
                        end else if (wr && buf_rd[v][p]) begin
                            fifo[tail] <= in_flit_p;
                            tail <= (tail + 1) % DEPTH;
                            head <= (head + 1) % DEPTH;
                        end
                    end
                end

                assign buf_dout[p][v] = fifo[head];
                assign buf_empty[v][p] = (count == 0);
                assign buf_full[v][p]  = (count == DEPTH);
                
                // Credit generation
                assign in_credit[p*NUM_VCS + v] = buf_rd[v][p];
            end
        end
    endgenerate

    // ---------------------------------------------------------
    // Route Compute & VC state
    // ---------------------------------------------------------
    // For each input port and VC, keep track of destination port
    reg [2:0] route_port [0:4][0:NUM_VCS-1];
    reg [4:0] packet_active [0:NUM_VCS-1];

    integer i, j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<NUM_VCS; i=i+1) packet_active[i] <= 5'b0;
            for (i=0; i<5; i=i+1)
                for (j=0; j<NUM_VCS; j=j+1)
                    route_port[i][j] <= 3'd0;
        end else begin
            for (i = 0; i < 5; i = i + 1) begin
                for (j = 0; j < NUM_VCS; j = j + 1) begin
                    if (!buf_empty[j][i] && !packet_active[j][i]) begin
                        // Head flit -> compute route
                        if (buf_dout[i][j][63:62] == TYPE_HEAD || buf_dout[i][j][63:62] == TYPE_HT) begin
                            if (buf_dout[i][j][59:56] > X_ID) route_port[i][j] <= 3;      // East
                            else if (buf_dout[i][j][59:56] < X_ID) route_port[i][j] <= 4; // West
                            else if (buf_dout[i][j][55:52] > Y_ID) route_port[i][j] <= 2; // South
                            else if (buf_dout[i][j][55:52] < Y_ID) route_port[i][j] <= 1; // North
                            else route_port[i][j] <= 0;                // Local
                            
                            packet_active[j][i] <= 1'b1;
                        end
                    end
                    // Clear active state on tail
                    if (buf_rd[j][i]) begin
                        if (buf_dout[i][j][63:62] == TYPE_TAIL || buf_dout[i][j][63:62] == TYPE_HT) begin
                            packet_active[j][i] <= 1'b0;
                        end
                    end
                end
            end
        end
    end

    // ---------------------------------------------------------
    // Switch Allocator & Crossbar Traversal (Pipelined)
    // ---------------------------------------------------------
    // To hit 1.5 GHz, we should pipeline this.
    // Stage SA: Request output ports, grant one input port per output port.
    // We arbitrate across VCs and input ports.
    
    // Credit tracking for downstream router
    reg [$clog2(DEPTH+1)-1:0] tx_credits [0:4][0:NUM_VCS-1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<5; i=i+1)
                for (j=0; j<NUM_VCS; j=j+1)
                    tx_credits[i][j] <= DEPTH;
        end else begin
            for (i=0; i<5; i=i+1) begin
                for (j=0; j<NUM_VCS; j=j+1) begin
                    if (out_credit[i*NUM_VCS + j] && !(out_valid[i] && (out_flit[i*FLIT_WIDTH + 60 +: 2] == j))) 
                        tx_credits[i][j] <= tx_credits[i][j] + 1;
                    else if (!out_credit[i*NUM_VCS + j] && (out_valid[i] && (out_flit[i*FLIT_WIDTH + 60 +: 2] == j))) 
                        tx_credits[i][j] <= tx_credits[i][j] - 1;
                end
            end
        end
    end

    // Arbitration logic
    reg [2:0] grant_port [0:4];
    reg [1:0] grant_vc   [0:4];
    reg       grant_val  [0:4];
    reg       grant_head [0:4]; // granted flit is a HEAD (acquire output lock)
    reg       grant_tail [0:4]; // granted flit is a TAIL (release output lock)

    reg [2:0] rr_ptr [0:4]; // Round robin pointer for each output port

    // ---------------------------------------------------------
    // Wormhole output-port locks.
    // Once an output port grants the HEAD of a packet, it is locked to that
    // (input port, VC) and serves ONLY that packet until its TAIL flit is sent.
    // Without this lock the round-robin allocator interleaves flits from
    // different packets on a shared output port, corrupting both.
    // ---------------------------------------------------------
    reg       lock_val  [0:4];
    reg [2:0] lock_port [0:4];
    reg [1:0] lock_vc   [0:4];

    always @(*) begin
        for (i=0; i<NUM_VCS; i=i+1) buf_rd[i] = 5'b0;

        for (i=0; i<5; i=i+1) begin
            grant_val[i]  = 1'b0;
            grant_port[i] = 0;
            grant_vc[i]   = 0;
            grant_head[i] = 1'b0;
            grant_tail[i] = 1'b0;
        end

        for (i=0; i<5; i=i+1) begin // For each output port i
            if (lock_val[i]) begin
                // Output locked: serve only the locked packet's stream.
                reg [2:0] lp;
                reg [1:0] lv;
                lp = lock_port[i];
                lv = lock_vc[i];
                if (packet_active[lv][lp] && !buf_empty[lv][lp] && (tx_credits[i][lv] > 0)) begin
                    grant_val[i]  = 1'b1;
                    grant_port[i] = lp;
                    grant_vc[i]   = lv;
                    buf_rd[lv][lp] = 1'b1;
                    grant_head[i] = (buf_dout[lp][lv][63:62] == TYPE_HEAD);
                    grant_tail[i] = (buf_dout[lp][lv][63:62] == TYPE_TAIL);
                end
            end else begin
                // Output free: round-robin arbitration, but a packet may only
                // START on a HEAD or HT flit (never mid-stream on BODY/TAIL).
                for (j=0; j<5; j=j+1) begin // Look at each input port
                    reg [2:0] check_port;
                    reg [1:0] ftype;
                    check_port = (rr_ptr[i] + j) % 5;

                    if (!grant_val[i]) begin
                        // Try to grant to VC 0 then VC 1
                        integer v_idx;
                        for (v_idx=0; v_idx<NUM_VCS; v_idx=v_idx+1) begin
                            if (!grant_val[i]) begin
                                if (packet_active[v_idx][check_port] && !buf_empty[v_idx][check_port]) begin
                                    if (route_port[check_port][v_idx] == i) begin
                                        if (tx_credits[i][v_idx] > 0) begin
                                            ftype = buf_dout[check_port][v_idx][63:62];
                                            if (ftype == TYPE_HEAD || ftype == TYPE_HT) begin
                                                grant_val[i]  = 1'b1;
                                                grant_port[i] = check_port;
                                                grant_vc[i]   = v_idx;
                                                buf_rd[v_idx][check_port] = 1'b1;
                                                // HEAD acquires the lock; HT is a
                                                // complete single-flit packet (no lock).
                                                grant_head[i] = (ftype == TYPE_HEAD);
                                                grant_tail[i] = 1'b0;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0; i<5; i=i+1) begin
                rr_ptr[i]   <= 0;
                lock_val[i]  <= 1'b0;
                lock_port[i] <= 0;
                lock_vc[i]   <= 0;
            end
        end else begin
            for (i=0; i<5; i=i+1) begin
                if (grant_val[i]) begin
                    if (grant_head[i]) begin
                        // Multi-flit packet begins: lock the output to it.
                        lock_val[i]  <= 1'b1;
                        lock_port[i] <= grant_port[i];
                        lock_vc[i]   <= grant_vc[i];
                    end else if (grant_tail[i]) begin
                        // Packet ends: release the output.
                        lock_val[i]  <= 1'b0;
                    end
                    // Advance round-robin only when the output is free (i.e. we
                    // just started a new packet), so fairness rotates per packet.
                    if (!lock_val[i]) begin
                        rr_ptr[i] <= (grant_port[i] + 1) % 5;
                    end
                end
            end
        end
    end

    // Pipeline Stage 3: Crossbar Flops (ST)
    reg [FLIT_WIDTH-1:0] out_flit_q [0:4];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 5'b0;
            for (i=0; i<5; i=i+1) out_flit_q[i] <= 0;
        end else begin
            for (i=0; i<5; i=i+1) begin
                out_valid[i] <= grant_val[i];
                if (grant_val[i]) begin
                    out_flit_q[i] <= buf_dout[grant_port[i]][grant_vc[i]];
                end
            end
        end
    end

    generate
        for (op = 0; op < 5; op = op + 1) begin : assign_out
            assign out_flit[op*FLIT_WIDTH +: FLIT_WIDTH] = out_flit_q[op];
        end
    endgenerate

endmodule
