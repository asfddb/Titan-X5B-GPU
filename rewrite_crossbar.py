import re

new_crossbar_code = """`timescale 1ns / 1ps

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
    parameter NUM_SLAVES = 4
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
    input wire [NUM_SLAVES*DATA_WIDTH-1:0] s_resp_rdata
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
    localparam MASTER_BITS = (NUM_MASTERS > 1) ? clog2(NUM_MASTERS) : 1;

    // arbitration: basic round robin
    reg [MASTER_BITS-1:0] rr_ptr [0:NUM_SLAVES-1]; 
    reg [MASTER_BITS-1:0] grant  [0:NUM_SLAVES-1];
    reg                   grant_valid [0:NUM_SLAVES-1];

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

    // request tracking fifo per slave
    localparam FIFO_DEPTH = 16;
    localparam FIFO_BITS = clog2(FIFO_DEPTH) > 0 ? clog2(FIFO_DEPTH) : 1;
    
    reg [MASTER_BITS-1:0] req_fifo [0:NUM_SLAVES-1][0:FIFO_DEPTH-1];
    reg [FIFO_BITS:0] fifo_count [0:NUM_SLAVES-1];
    reg [FIFO_BITS-1:0] fifo_wr_ptr [0:NUM_SLAVES-1];
    reg [FIFO_BITS-1:0] fifo_rd_ptr [0:NUM_SLAVES-1];

    wire [MASTER_BITS-1:0] current_resp_master [0:NUM_SLAVES-1];

    wire [NUM_SLAVES-1:0] fifo_has_space;
    wire [NUM_SLAVES-1:0] req_accepted;
    generate
        for (gi = 0; gi < NUM_SLAVES; gi = gi + 1) begin : accept_gen
            assign fifo_has_space[gi] = (fifo_count[gi] < FIFO_DEPTH) || s_resp_valid[gi];
            assign req_accepted[gi] = grant_valid[gi] && s_req_ready[gi] && fifo_has_space[gi];
        end
    endgenerate

    integer s_idx, f_idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (s_idx = 0; s_idx < NUM_SLAVES; s_idx = s_idx + 1) begin
                fifo_count[s_idx] <= 0;
                fifo_wr_ptr[s_idx] <= 0;
                fifo_rd_ptr[s_idx] <= 0;
                for (f_idx = 0; f_idx < FIFO_DEPTH; f_idx = f_idx + 1) begin
                    req_fifo[s_idx][f_idx] <= 0;
                end
            end
        end else begin
            for (s_idx = 0; s_idx < NUM_SLAVES; s_idx = s_idx + 1) begin
                if (req_accepted[s_idx] && !s_resp_valid[s_idx]) begin
                    req_fifo[s_idx][fifo_wr_ptr[s_idx]] <= grant[s_idx];
                    fifo_wr_ptr[s_idx] <= fifo_wr_ptr[s_idx] + 1;
                    fifo_count[s_idx] <= fifo_count[s_idx] + 1;
                end else if (!req_accepted[s_idx] && s_resp_valid[s_idx]) begin
                    fifo_rd_ptr[s_idx] <= fifo_rd_ptr[s_idx] + 1;
                    fifo_count[s_idx] <= fifo_count[s_idx] - 1;
                end else if (req_accepted[s_idx] && s_resp_valid[s_idx]) begin
                    req_fifo[s_idx][fifo_wr_ptr[s_idx]] <= grant[s_idx];
                    fifo_wr_ptr[s_idx] <= fifo_wr_ptr[s_idx] + 1;
                    fifo_rd_ptr[s_idx] <= fifo_rd_ptr[s_idx] + 1;
                end
            end
        end
    end

    generate
        for (gi = 0; gi < NUM_SLAVES; gi = gi + 1) begin : resp_master_gen
            assign current_resp_master[gi] = req_fifo[gi][fifo_rd_ptr[gi]];
        end
    endgenerate

    // multiplexing
    generate
        for (gi = 0; gi < NUM_SLAVES; gi = gi + 1) begin : slave_mux
            assign s_req_valid[gi] = grant_valid[gi] && fifo_has_space[gi];
            assign s_req_addr[gi*ADDR_WIDTH +: ADDR_WIDTH] = m_req_addr[grant[gi]*ADDR_WIDTH +: ADDR_WIDTH];
            assign s_req_wdata[gi*DATA_WIDTH +: DATA_WIDTH] = m_req_wdata[grant[gi]*DATA_WIDTH +: DATA_WIDTH];
            assign s_req_write[gi] = m_req_write[grant[gi]];
        end
    endgenerate

    generate
        for (gi = 0; gi < NUM_MASTERS; gi = gi + 1) begin : master_mux
            // m_req_ready is tricky: is this master granted by its requested slave AND does the FIFO have space?
            assign m_req_ready[gi] = (grant_valid[req_dest[gi]] && grant[req_dest[gi]] == gi) ? (s_req_ready[req_dest[gi]] && fifo_has_space[req_dest[gi]]) : 1'b0;
        end
    endgenerate

    // response routing based on tracked request master id
    genvar m_idx, s_idx_gen;
    generate
        for (m_idx = 0; m_idx < NUM_MASTERS; m_idx = m_idx + 1) begin : m_resp_gen
            wire [NUM_SLAVES-1:0] resp_from_slave;
            wire [DATA_WIDTH-1:0] rdata_from_slave [0:NUM_SLAVES-1];
            
            for (s_idx_gen = 0; s_idx_gen < NUM_SLAVES; s_idx_gen = s_idx_gen + 1) begin : s_to_m
                assign resp_from_slave[s_idx_gen] = s_resp_valid[s_idx_gen] && (fifo_count[s_idx_gen] != 0) && (current_resp_master[s_idx_gen] == m_idx);
                assign rdata_from_slave[s_idx_gen] = resp_from_slave[s_idx_gen] ? s_resp_rdata[s_idx_gen*DATA_WIDTH +: DATA_WIDTH] : {DATA_WIDTH{1'b0}};
            end
            
            assign m_resp_valid[m_idx] = |resp_from_slave;
            
            if (NUM_SLAVES == 1) begin : single_slave_rdata
                assign m_resp_rdata[m_idx*DATA_WIDTH +: DATA_WIDTH] = rdata_from_slave[0];
            end else begin : multi_slave_rdata
                reg [DATA_WIDTH-1:0] temp_rdata;
                integer s;
                always @(*) begin
                    temp_rdata = 0;
                    for (s = 0; s < NUM_SLAVES; s = s + 1) begin
                        temp_rdata = temp_rdata | rdata_from_slave[s];
                    end
                end
                assign m_resp_rdata[m_idx*DATA_WIDTH +: DATA_WIDTH] = temp_rdata;
            end
        end
    endgenerate

endmodule
"""

with open('rtl/interconnect/titan_x5_crossbar.v', 'w') as f:
    f.write(new_crossbar_code)

print("Crossbar parameterized successfully with request tracking FIFO!")
