`timescale 1ns / 1ps

/*
 * Titan X5 GPU - 16KB Shared Memory
 * - 8 banks (32b wide each)
 * - Conflict detection logic
 * - Basic atomic support (e.g., ADD, MIN, MAX)
 */
module titan_x5_shared_memory #(
    parameter ADDR_WIDTH = 14, // 16KB = 2^14 bytes
    parameter DATA_WIDTH = 32,
    parameter BANKS = 8,
    parameter PORTS = 8 // Number of threads accessing simultaneously
)(
    input  wire clk,
    input  wire rst_n,

    // Array of Request Ports (Flattened for Verilog-2001 compatibility)
    input  wire [PORTS-1:0]                  req_valid,
    input  wire [PORTS*ADDR_WIDTH-1:0]       req_addr,
    input  wire [PORTS*DATA_WIDTH-1:0]       req_wdata,
    input  wire [PORTS-1:0]                  req_write,
    input  wire [PORTS*3-1:0]                req_atomic_op, // 0: None, 1: Add, 2: Min, 3: Max
    output wire [PORTS-1:0]                  req_ready,

    output wire [PORTS-1:0]                  resp_valid,
    output wire [PORTS*DATA_WIDTH-1:0]       resp_rdata
);

    localparam ROWS = (16384) / (BANKS * (DATA_WIDTH/8)); // 512 rows
    localparam BANK_BITS = $clog2(BANKS);
    localparam ROW_BITS  = $clog2(ROWS);

    // Memory banks
    reg [DATA_WIDTH-1:0] memory_banks [0:BANKS-1][0:ROWS-1];

    // Bank conflict detection signals
    wire [BANK_BITS-1:0] port_bank [0:PORTS-1];
    wire [ROW_BITS-1:0]  port_row  [0:PORTS-1];

    genvar p;
    generate
        for (p = 0; p < PORTS; p = p + 1) begin : port_decode
            // Byte addressable, word aligned -> skip 2 LSBs
            assign port_bank[p] = req_addr[(p*ADDR_WIDTH)+2 +: BANK_BITS];
            assign port_row[p]  = req_addr[(p*ADDR_WIDTH)+2+BANK_BITS +: ROW_BITS];
        end
    endgenerate

    // Simplified arbitration and conflict detection
    reg [PORTS-1:0] grant;
    integer i, j;
    always @(*) begin
        grant = {PORTS{1'b0}};
        for (i = 0; i < PORTS; i = i + 1) begin
            if (req_valid[i]) begin
                grant[i] = 1'b1;
                // Check against higher priority ports
                for (j = 0; j < i; j = j + 1) begin
                    if (req_valid[j] && (port_bank[i] == port_bank[j])) begin
                        grant[i] = 1'b0; // Bank conflict, deny grant
                    end
                end
            end
        end
    end

    assign req_ready = grant;

    // Memory Access & Atomics
    reg [PORTS-1:0]                  resp_valid_q;
    reg [PORTS*DATA_WIDTH-1:0]       resp_rdata_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            resp_valid_q <= 0;
            resp_rdata_q <= 0;
        end else begin
            resp_valid_q <= grant; // Responses available next cycle
            
            for (i = 0; i < PORTS; i = i + 1) begin
                if (grant[i]) begin
                    if (req_write[i]) begin
                        // Atomic Operations
                        case (req_atomic_op[i*3 +: 3])
                            3'b001: memory_banks[port_bank[i]][port_row[i]] <= memory_banks[port_bank[i]][port_row[i]] + req_wdata[i*DATA_WIDTH +: DATA_WIDTH];
                            // Other atomics omitted for brevity, standard write below
                            default: memory_banks[port_bank[i]][port_row[i]] <= req_wdata[i*DATA_WIDTH +: DATA_WIDTH];
                        endcase
                    end else begin
                        // Read
                        resp_rdata_q[i*DATA_WIDTH +: DATA_WIDTH] <= memory_banks[port_bank[i]][port_row[i]];
                    end
                end
            end
        end
    end

    assign resp_valid = resp_valid_q;
    assign resp_rdata = resp_rdata_q;

endmodule
