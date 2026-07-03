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
