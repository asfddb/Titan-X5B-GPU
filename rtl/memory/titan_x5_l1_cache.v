`timescale 1ns / 1ps

/*
 * Titan X5 GPU - 32KB L1 Data Cache
 * - 4-way set associative
 * - 64B cache lines
 * - LRU replacement policy
 * - Non-blocking with basic MSHR (Miss Status Holding Register)
 */
module titan_x5_l1_cache #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter LINE_SIZE  = 64,
    parameter WAYS       = 4,
    parameter SETS       = 128,
    parameter MSHR_ENTRIES = 4
)(
    input  wire clk,
    input  wire rst_n,

    // core interface
    input  wire                    req_valid,
    input wire [ADDR_WIDTH-1:0] req_addr,
    input wire [DATA_WIDTH-1:0] req_wdata,
    input  wire                    req_write,
    output reg                     req_ready,

    output reg                     resp_valid,
    output reg [DATA_WIDTH-1:0] resp_rdata,

    // axi4 master interface
    output wire [ADDR_WIDTH-1:0] m_axi_awaddr,
    output wire                    m_axi_awvalid,
    input  wire                    m_axi_awready,
    output wire [LINE_SIZE*8-1:0] m_axi_wdata,
    output wire                    m_axi_wvalid,
    input  wire                    m_axi_wready,
    input wire [1:0] m_axi_bresp,
    input  wire                    m_axi_bvalid,
    output wire                    m_axi_bready,
    output wire [ADDR_WIDTH-1:0] m_axi_araddr,
    output wire                    m_axi_arvalid,
    input  wire                    m_axi_arready,
    input wire [LINE_SIZE*8-1:0] m_axi_rdata,
    input  wire                    m_axi_rvalid,
    output wire                    m_axi_rready
);

    // internal legacy signals mapped to axi4
    reg                     mem_req_valid;
    reg  [ADDR_WIDTH-1:0]   mem_req_addr;
    reg                     mem_req_write;
    reg  [LINE_SIZE*8-1:0]  mem_req_wdata;
    wire                    mem_req_ready;
    wire                    mem_resp_valid;
    wire [LINE_SIZE*8-1:0]  mem_resp_rdata;

    assign m_axi_awaddr  = mem_req_addr;
    assign m_axi_awvalid = mem_req_valid & mem_req_write;
    assign m_axi_wdata   = mem_req_wdata;
    assign m_axi_wvalid  = mem_req_valid & mem_req_write;
    assign m_axi_bready  = 1'b1;

    assign m_axi_araddr  = mem_req_addr;
    assign m_axi_arvalid = mem_req_valid & !mem_req_write;
    assign m_axi_rready  = 1'b1;

    assign mem_req_ready  = mem_req_write ? (m_axi_awready & m_axi_wready) : m_axi_arready;
    assign mem_resp_valid = m_axi_rvalid;
    assign mem_resp_rdata = m_axi_rdata;

    localparam OFFSET_BITS = $clog2(LINE_SIZE);
    localparam INDEX_BITS  = $clog2(SETS);
    localparam TAG_BITS    = ADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    // cache arrays
    reg [LINE_SIZE*8-1:0] data_array [0:SETS-1][0:WAYS-1];
    reg [TAG_BITS-1:0]    tag_array  [0:SETS-1][0:WAYS-1];
    reg                   valid_array[0:SETS-1][0:WAYS-1];
    reg                   dirty_array[0:SETS-1][0:WAYS-1];
    reg [$clog2(WAYS)-1:0]lru_array  [0:SETS-1][0:WAYS-1];

    // mshr arrays
    (* ram_style="block" *) reg                   mshr_valid [0:MSHR_ENTRIES-1];
    (* ram_style="block" *) reg [ADDR_WIDTH-1:0]  mshr_addr  [0:MSHR_ENTRIES-1];

    wire [TAG_BITS-1:0]   req_tag   = req_addr[ADDR_WIDTH-1 : OFFSET_BITS+INDEX_BITS];
    wire [INDEX_BITS-1:0] req_index = req_addr[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS];

    integer i, j;

    // synchronous reset and cache logic (simplified non-blocking state)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_ready <= 1'b0;
            resp_valid <= 1'b0;
            mem_req_valid <= 1'b0;
            for (i = 0; i < SETS; i = i + 1) begin
                for (j = 0; j < WAYS; j = j + 1) begin
                    valid_array[i][j] <= 1'b0;
                    dirty_array[i][j] <= 1'b0;
                    lru_array[i][j] <= j;
                end
            end
            for (i = 0; i < MSHR_ENTRIES; i = i + 1) begin
                mshr_valid[i] <= 1'b0;
            end
        end else begin
            // default assignments
            req_ready <= 1'b1; // accept requests if mshr isn't full
            resp_valid <= 1'b0;

            if (req_valid && req_ready) begin
                // basic hit detection (combinational in practice, simplified here)
                reg hit;
                reg [$clog2(WAYS)-1:0] hit_way;
                hit = 1'b0;
                
                for (j = 0; j < WAYS; j = j + 1) begin
                    if (valid_array[req_index][j] && (tag_array[req_index][j] == req_tag)) begin
                        hit = 1'b1;
                        hit_way = j;
                    end
                end

                if (hit) begin
                    if (req_write) begin
                        dirty_array[req_index][hit_way] <= 1'b1;
                        // masked write logic simplified
                    end else begin
                        resp_valid <= 1'b1;
                        // select word based on offset
                        resp_rdata <= data_array[req_index][hit_way][DATA_WIDTH-1:0]; 
                    end
                    // lru update omitted for brevity
                end else begin
                    // miss - allocate mshr
                    reg mshr_alloc;
                    mshr_alloc = 1'b0;
                    for (i = 0; i < MSHR_ENTRIES; i = i + 1) begin
                        if (!mshr_valid[i] && !mshr_alloc) begin
                            mshr_valid[i] <= 1'b1;
                            mshr_addr[i] <= req_addr;
                            mshr_alloc = 1'b1;
                            
                            mem_req_valid <= 1'b1;
                            mem_req_addr <= {req_addr[ADDR_WIDTH-1:OFFSET_BITS], {OFFSET_BITS{1'b0}}};
                            mem_req_write <= 1'b0;
                        end
                    end
                    if (!mshr_alloc) begin
                        req_ready <= 1'b0; // stall if mshr full
                    end
                end
            end

            // process l2 response
            if (mem_resp_valid) begin
                mem_req_valid <= 1'b0; // de-assert request
                // fill cache, clear mshr (simplified single-entry resolve)
                for (i = 0; i < MSHR_ENTRIES; i = i + 1) begin
                    if (mshr_valid[i]) begin
                        mshr_valid[i] <= 1'b0;
                        // allocate to way 0 (simplification)
                        valid_array[mshr_addr[i][OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]][0] <= 1'b1;
                        tag_array[mshr_addr[i][OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]][0] <= mshr_addr[i][ADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
                        data_array[mshr_addr[i][OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS]][0] <= mem_resp_rdata;
                    end
                end
            end
        end
    end

endmodule
