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
 * Titan X5 GPU - Parameterized Crossbar
 * - N Masters, M Slaves
 * - Round-robin arbitration
 * - AXI-Lite compatible interfaces (simplified request/response)
 */
module titan_x5_crossbar #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter NUM_MASTERS = 4,
    parameter NUM_SLAVES = 4,
    parameter MASTER_BITS = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1
)(
    input wire clk,
    input wire rst_n,

    // master interfaces
    input wire [NUM_MASTERS-1:0] m_req_valid,
    input wire [NUM_MASTERS*ADDR_WIDTH-1:0] m_req_addr,
    input wire [NUM_MASTERS*DATA_WIDTH-1:0] m_req_wdata,
    input wire [NUM_MASTERS-1:0] m_req_write,
    output wire [NUM_MASTERS-1:0] m_req_ready,

    output wire [NUM_MASTERS-1:0] m_resp_valid,
    output wire [NUM_MASTERS*DATA_WIDTH-1:0] m_resp_rdata,

    // slave interfaces
    output wire [NUM_SLAVES-1:0] s_req_valid,
    output wire [NUM_SLAVES*ADDR_WIDTH-1:0] s_req_addr,
    output wire [NUM_SLAVES*DATA_WIDTH-1:0] s_req_wdata,
    output wire [NUM_SLAVES-1:0] s_req_write,
    input wire [NUM_SLAVES-1:0] s_req_ready,

    input wire [NUM_SLAVES-1:0] s_resp_valid,
    input wire [NUM_SLAVES*DATA_WIDTH-1:0] s_resp_rdata,
    
    output wire [NUM_SLAVES*MASTER_BITS-1:0] s_req_id,
    input wire [NUM_SLAVES*MASTER_BITS-1:0] s_resp_id
);

    function integer clog2;
        input integer value;
        begin
            value = value - 1;
            for (clog2 = 0; value > 0; clog2 = clog2 + 1)
                value = value >> 1;
        end
    endfunction

    localparam SLAVE_BITS = (NUM_SLAVES > 1) ? clog2(NUM_SLAVES) : 1;

    // arbitration: basic round robin
    (* ram_style="block" *) reg [MASTER_BITS-1:0] rr_ptr [0:NUM_SLAVES-1]; 
    (* ram_style="block" *) reg [MASTER_BITS-1:0] grant  [0:NUM_SLAVES-1];
    (* ram_style="block" *) reg                   grant_valid [0:NUM_SLAVES-1];

    integer s, m, check_idx;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (s = 0; s < NUM_SLAVES; s = s + 1) begin
                rr_ptr[s] <= 0;
            end
        end else begin
            for (s = 0; s < NUM_SLAVES; s = s + 1) begin
                if (grant_valid[s] && s_req_ready[s]) begin
                    if (rr_ptr[s] == NUM_MASTERS - 1)
                        rr_ptr[s] <= 0;
                    else
                        rr_ptr[s] <= rr_ptr[s] + 1;
                end
            end
        end
    end

    // combinational arbitration logic
    wire [SLAVE_BITS-1:0] req_dest [0:NUM_MASTERS-1]; 
    
    genvar gi;
    generate
        for (gi = 0; gi < NUM_MASTERS; gi = gi + 1) begin : dest_gen
            if (NUM_SLAVES > 1) begin
                assign req_dest[gi] = m_req_addr[gi*ADDR_WIDTH + ADDR_WIDTH - 1 : gi*ADDR_WIDTH + ADDR_WIDTH - SLAVE_BITS];
            end else begin
                assign req_dest[gi] = 0;
            end
        end
    endgenerate

    always @(*) begin
        for (s = 0; s < NUM_SLAVES; s = s + 1) begin
            grant[s] = 0;
            grant_valid[s] = 1'b0;
            
            for (m = 0; m < NUM_MASTERS; m = m + 1) begin
                check_idx = rr_ptr[s] + m;
                if (check_idx >= NUM_MASTERS) check_idx = check_idx - NUM_MASTERS;
                if (!grant_valid[s] && m_req_valid[check_idx] && req_dest[check_idx] == s) begin
                    grant[s] = check_idx;
                    grant_valid[s] = 1'b1;
                end
            end
        end
    end

    // pipelined multiplexing to slaves
    reg [NUM_SLAVES-1:0] s_req_valid_q;
    reg [NUM_SLAVES*ADDR_WIDTH-1:0] s_req_addr_q;
    reg [NUM_SLAVES*DATA_WIDTH-1:0] s_req_wdata_q;
    reg [NUM_SLAVES-1:0] s_req_write_q;
    reg [NUM_SLAVES*MASTER_BITS-1:0] s_req_id_q;

    integer pipe_gi;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_req_valid_q <= 0;
            s_req_addr_q <= 0;
            s_req_wdata_q <= 0;
            s_req_write_q <= 0;
            s_req_id_q <= 0;
        end else begin
            for (pipe_gi = 0; pipe_gi < NUM_SLAVES; pipe_gi = pipe_gi + 1) begin
                if (s_req_ready[pipe_gi] || !s_req_valid_q[pipe_gi]) begin
                    s_req_valid_q[pipe_gi] <= grant_valid[pipe_gi];
                    if (grant_valid[pipe_gi]) begin
                        s_req_addr_q[pipe_gi*ADDR_WIDTH +: ADDR_WIDTH] <= m_req_addr[grant[pipe_gi]*ADDR_WIDTH +: ADDR_WIDTH];
                        s_req_wdata_q[pipe_gi*DATA_WIDTH +: DATA_WIDTH] <= m_req_wdata[grant[pipe_gi]*DATA_WIDTH +: DATA_WIDTH];
                        s_req_write_q[pipe_gi] <= m_req_write[grant[pipe_gi]];
                        s_req_id_q[pipe_gi*MASTER_BITS +: MASTER_BITS] <= grant[pipe_gi];
                    end
                end
            end
        end
    end

    assign s_req_valid = s_req_valid_q;
    assign s_req_addr = s_req_addr_q;
    assign s_req_wdata = s_req_wdata_q;
    assign s_req_write = s_req_write_q;
    assign s_req_id = s_req_id_q;

    generate
        for (gi = 0; gi < NUM_MASTERS; gi = gi + 1) begin : master_mux
            assign m_req_ready[gi] = (grant_valid[req_dest[gi]] && grant[req_dest[gi]] == gi) ? (s_req_ready[req_dest[gi]] || !s_req_valid_q[req_dest[gi]]) : 1'b0;
        end
    endgenerate

    // response routing based on s_resp_id (pipelined)
    reg [NUM_MASTERS-1:0] m_resp_valid_q;
    reg [NUM_MASTERS*DATA_WIDTH-1:0] m_resp_rdata_q;

    integer m_idx_pipe, s_idx_pipe;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            m_resp_valid_q <= 0;
            m_resp_rdata_q <= 0;
        end else begin
            for (m_idx_pipe = 0; m_idx_pipe < NUM_MASTERS; m_idx_pipe = m_idx_pipe + 1) begin
                reg valid_this_cycle;
                reg [DATA_WIDTH-1:0] data_this_cycle;
                valid_this_cycle = 0;
                data_this_cycle = 0;
                for (s_idx_pipe = 0; s_idx_pipe < NUM_SLAVES; s_idx_pipe = s_idx_pipe + 1) begin
                    if (s_resp_valid[s_idx_pipe] && (s_resp_id[s_idx_pipe*MASTER_BITS +: MASTER_BITS] == m_idx_pipe)) begin
                        valid_this_cycle = 1;
                        data_this_cycle = data_this_cycle | s_resp_rdata[s_idx_pipe*DATA_WIDTH +: DATA_WIDTH];
                    end
                end
                m_resp_valid_q[m_idx_pipe] <= valid_this_cycle;
                if (valid_this_cycle) begin
                    m_resp_rdata_q[m_idx_pipe*DATA_WIDTH +: DATA_WIDTH] <= data_this_cycle;
                end
            end
        end
    end

    assign m_resp_valid = m_resp_valid_q;
    assign m_resp_rdata = m_resp_rdata_q;

endmodule

/*
 * Titan X5 GPU - Coherent Crossbar (MESI snooping bus)
 *
 * Connects NUM_MASTERS caching L1s to one L2. Transactions are serialized:
 * the arbiter grants one master, broadcasts a snoop to all other masters,
 * collects their responses, sources the data (dirty snoop copy wins over
 * L2), and finally responds to the granted master.
 *
 * Transaction types (shared encoding with titan_x5_l1_cache):
 *   BUS_RD   (0): read line.  shared=1 if any other L1 holds it.
 *                 A dirty (M) snoop hit supplies the data and is also
 *                 written through to L2 so memory stays clean.
 *   BUS_RDX  (1): read line for ownership; other copies invalidate. A dirty
 *                 snoop hit supplies data directly (no L2 update needed -
 *                 the requester immediately owns the line as M).
 *   BUS_UPGR (2): upgrade S->M; other copies invalidate; no data returned.
 *   BUS_WB   (3): write back a dirty line to L2 (no snoop, no response;
 *                 the grant is the completion).
 *
 * Deadlock safety: L1s answer snoops whenever they are not mid-transaction
 * on the bus, and the bus never snoops the master it granted.
 */
module titan_x5_coherent_xbar #(
    parameter NUM_MASTERS = 4,
    parameter ADDR_WIDTH  = 32,
    parameter LINE_BYTES  = 128,
    parameter MASTER_BITS = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1
)(
    input  wire                                clk,
    input  wire                                rst_n,

    // master (L1 bus-side) ports
    input  wire [NUM_MASTERS-1:0]              m_req_valid,
    output reg  [NUM_MASTERS-1:0]              m_req_ready,   // 1-cycle grant
    input  wire [NUM_MASTERS*2-1:0]            m_req_type,
    input  wire [NUM_MASTERS*ADDR_WIDTH-1:0]   m_req_addr,
    input  wire [NUM_MASTERS*LINE_BYTES*8-1:0] m_req_wdata,
    output reg  [NUM_MASTERS-1:0]              m_resp_valid,  // 1-cycle pulse
    output reg  [LINE_BYTES*8-1:0]             m_resp_rdata,  // shared data bus
    output reg                                 m_resp_shared,

    // snoop broadcast to masters
    output reg  [NUM_MASTERS-1:0]              snp_req_valid,
    output reg  [1:0]                          snp_req_type,
    output reg  [ADDR_WIDTH-1:0]               snp_req_addr,
    input  wire [NUM_MASTERS-1:0]              snp_resp_valid,
    input  wire [NUM_MASTERS-1:0]              snp_resp_hit,
    input  wire [NUM_MASTERS-1:0]              snp_resp_dirty,
    input  wire [NUM_MASTERS*LINE_BYTES*8-1:0] snp_resp_data,

    // L2 (next-level) port
    output reg                                 l2_req_valid,
    input  wire                                l2_req_ready,
    output reg                                 l2_req_write,
    output reg  [ADDR_WIDTH-1:0]               l2_req_addr,
    output reg  [LINE_BYTES*8-1:0]             l2_req_wdata,
    input  wire                                l2_resp_valid,
    input  wire [LINE_BYTES*8-1:0]             l2_resp_rdata
);

    localparam BUS_RD   = 2'd0;
    localparam BUS_RDX  = 2'd1;
    localparam BUS_UPGR = 2'd2;
    localparam BUS_WB   = 2'd3;

    localparam X_IDLE     = 3'd0;
    localparam X_SNOOP    = 3'd1;
    localparam X_L2WR     = 3'd2;  // BusWB: write dirty evict to L2
    localparam X_L2WR_SNP = 3'd3;  // write dirty snoop data through to L2
    localparam X_L2RD     = 3'd4;  // fetch line from L2
    localparam X_RESP     = 3'd5;

    reg [2:0]                  state;
    reg [MASTER_BITS-1:0]      grant;
    reg [MASTER_BITS-1:0]      rr_ptr;
    reg [1:0]                  cur_type;
    reg [ADDR_WIDTH-1:0]       cur_addr;
    reg [LINE_BYTES*8-1:0]     cur_wdata;
    reg [NUM_MASTERS-1:0]      snp_pending;
    reg                        hit_acc;
    reg                        dirty_acc;
    reg [LINE_BYTES*8-1:0]     dirty_data;
    reg                        l2_accepted;
    reg                        l2_wr_pending; // write accepted, waiting for L2 to drain

    // round-robin arbitration (combinational, from rr_ptr)
    integer k;
    reg                   arb_valid;
    reg [MASTER_BITS-1:0] arb_grant;
    reg [MASTER_BITS-1:0] arb_idx;
    always @(*) begin
        arb_valid = 1'b0;
        arb_grant = {MASTER_BITS{1'b0}};
        for (k = NUM_MASTERS - 1; k >= 0; k = k - 1) begin
            arb_idx = rr_ptr + k[MASTER_BITS-1:0]; // wraps naturally for pow2
            if (m_req_valid[arb_idx]) begin
                arb_valid = 1'b1;
                arb_grant = arb_idx;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= X_IDLE;
            grant         <= {MASTER_BITS{1'b0}};
            rr_ptr        <= {MASTER_BITS{1'b0}};
            m_req_ready   <= {NUM_MASTERS{1'b0}};
            m_resp_valid  <= {NUM_MASTERS{1'b0}};
            m_resp_rdata  <= {LINE_BYTES*8{1'b0}};
            m_resp_shared <= 1'b0;
            snp_req_valid <= {NUM_MASTERS{1'b0}};
            snp_req_type  <= BUS_RD;
            snp_req_addr  <= {ADDR_WIDTH{1'b0}};
            snp_pending   <= {NUM_MASTERS{1'b0}};
            hit_acc       <= 1'b0;
            dirty_acc     <= 1'b0;
            dirty_data    <= {LINE_BYTES*8{1'b0}};
            l2_req_valid  <= 1'b0;
            l2_req_write  <= 1'b0;
            l2_req_addr   <= {ADDR_WIDTH{1'b0}};
            l2_req_wdata  <= {LINE_BYTES*8{1'b0}};
            l2_accepted   <= 1'b0;
            l2_wr_pending <= 1'b0;
            cur_type      <= BUS_RD;
            cur_addr      <= {ADDR_WIDTH{1'b0}};
            cur_wdata     <= {LINE_BYTES*8{1'b0}};
        end else begin
            m_req_ready  <= {NUM_MASTERS{1'b0}};
            m_resp_valid <= {NUM_MASTERS{1'b0}};

            case (state)
                X_IDLE: begin
                    if (arb_valid) begin
                        grant     <= arb_grant;
                        rr_ptr    <= arb_grant + 1'b1;
                        cur_type  <= m_req_type[arb_grant*2 +: 2];
                        cur_addr  <= m_req_addr[arb_grant*ADDR_WIDTH +: ADDR_WIDTH];
                        cur_wdata <= m_req_wdata[arb_grant*LINE_BYTES*8 +: LINE_BYTES*8];
                        m_req_ready[arb_grant] <= 1'b1;
                        hit_acc   <= 1'b0;
                        dirty_acc <= 1'b0;
                        if (m_req_type[arb_grant*2 +: 2] == BUS_WB) begin
                            l2_accepted   <= 1'b0;
                            l2_wr_pending <= 1'b0;
                            state <= X_L2WR;
                        end else begin
                            snp_req_type <= m_req_type[arb_grant*2 +: 2];
                            snp_req_addr <= m_req_addr[arb_grant*ADDR_WIDTH +: ADDR_WIDTH];
                            snp_pending  <= {NUM_MASTERS{1'b1}} & ~({{NUM_MASTERS-1{1'b0}}, 1'b1} << arb_grant);
                            snp_req_valid<= {NUM_MASTERS{1'b1}} & ~({{NUM_MASTERS-1{1'b0}}, 1'b1} << arb_grant);
                            state <= X_SNOOP;
                        end
                    end
                end

                X_SNOOP: begin
                    for (k = 0; k < NUM_MASTERS; k = k + 1) begin
                        if (snp_pending[k] && snp_resp_valid[k]) begin
                            snp_pending[k]   <= 1'b0;
                            snp_req_valid[k] <= 1'b0;
                            if (snp_resp_hit[k])   hit_acc   <= 1'b1;
                            if (snp_resp_dirty[k]) begin
                                dirty_acc  <= 1'b1;
                                dirty_data <= snp_resp_data[k*LINE_BYTES*8 +: LINE_BYTES*8];
                            end
                        end
                    end
                    if (snp_pending == {NUM_MASTERS{1'b0}}) begin
                        if (cur_type == BUS_UPGR) begin
                            m_resp_shared <= 1'b0;
                            state <= X_RESP;
                        end else if (dirty_acc) begin
                            m_resp_rdata  <= dirty_data;
                            m_resp_shared <= 1'b1;
                            if (cur_type == BUS_RD) begin
                                // write dirty copy through to L2 (stays clean)
                                l2_accepted   <= 1'b0;
                                l2_wr_pending <= 1'b0;
                                state <= X_L2WR_SNP;
                            end else begin
                                state <= X_RESP; // RdX: requester owns as M
                            end
                        end else begin
                            m_resp_shared <= hit_acc;
                            l2_accepted   <= 1'b0;
                            state <= X_L2RD;
                        end
                    end
                end

                X_L2WR: begin
                    // phase 1: valid until accepted; phase 2: wait for the L2
                    // to return to ready (write fully processed; the L2 uses
                    // live address/data, so both are held stable throughout)
                    l2_req_write <= 1'b1;
                    l2_req_addr  <= cur_addr;
                    l2_req_wdata <= cur_wdata;
                    if (!l2_accepted) begin
                        l2_req_valid <= 1'b1;
                        if (l2_req_valid && l2_req_ready) begin
                            l2_req_valid <= 1'b0;
                            l2_accepted  <= 1'b1;
                            l2_wr_pending<= 1'b1;
                        end
                    end else if (l2_wr_pending && l2_req_ready) begin
                        l2_wr_pending <= 1'b0;
                        l2_req_write  <= 1'b0;
                        state <= X_IDLE;
                    end
                end

                X_L2WR_SNP: begin
                    l2_req_write <= 1'b1;
                    l2_req_addr  <= cur_addr;
                    l2_req_wdata <= dirty_data;
                    if (!l2_accepted) begin
                        l2_req_valid <= 1'b1;
                        if (l2_req_valid && l2_req_ready) begin
                            l2_req_valid <= 1'b0;
                            l2_accepted  <= 1'b1;
                            l2_wr_pending<= 1'b1;
                        end
                    end else if (l2_wr_pending && l2_req_ready) begin
                        l2_wr_pending <= 1'b0;
                        l2_req_write  <= 1'b0;
                        state <= X_RESP;
                    end
                end

                X_L2RD: begin
                    l2_req_write <= 1'b0;
                    l2_req_addr  <= cur_addr;
                    if (!l2_accepted) begin
                        l2_req_valid <= 1'b1;
                        if (l2_req_valid && l2_req_ready) begin
                            l2_req_valid <= 1'b0;
                            l2_accepted  <= 1'b1;
                        end
                    end else if (l2_resp_valid) begin
                        m_resp_rdata <= l2_resp_rdata;
                        state <= X_RESP;
                    end
                end

                X_RESP: begin
                    m_resp_valid[grant] <= 1'b1;
                    state <= X_IDLE;
                end

                default: state <= X_IDLE;
            endcase
        end
    end

endmodule
