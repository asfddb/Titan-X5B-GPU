// ============================================================================
// Copyright (c) 2026 Adhiraj / [Your LLP]
// 
// This file is part of the Titan X5-B GPU project.
// 
// Dual-licensed under CERN-OHL-S-2.0 AND Commercial License.
// See LICENSE and COMMERCIAL.md for details.
// ============================================================================
`timescale 1ns/1ps

module titan_x6_ucie_phy #(
    parameter FLIT_WIDTH = 256,
    parameter NUM_LANES  = 16,
    parameter SER_RATIO  = FLIT_WIDTH / NUM_LANES
)(
    input  wire                     clk,          // high speed lane clock
    input  wire                     rst_n,        // asynchronous reset, active low
    
    // core interface (runs at full flit_width)
    input  wire                     core_tx_valid,
    input wire [FLIT_WIDTH-1:0] core_tx_flit,
    output wire                     core_tx_ready,
    
    output wire                     core_rx_valid,
    output wire [FLIT_WIDTH-1:0] core_rx_flit,
    
    // physical lanes (die-to-die interconnect)
    output wire [NUM_LANES-1:0] phy_tx_lanes,
    input wire [NUM_LANES-1:0] phy_rx_lanes
);

    // tx path: flit packing & serialization
    reg [$clog2(SER_RATIO)-1:0] tx_cnt;
    reg [FLIT_WIDTH-1:0]        tx_shift_reg;
    reg                         tx_active;

    // ready is asserted when the shift register is empty (tx_cnt == 0)
    assign core_tx_ready = (tx_cnt == 0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_cnt       <= 0;
            tx_shift_reg <= {FLIT_WIDTH{1'b0}};
            tx_active    <= 1'b0;
        end else begin
            if (tx_cnt == 0) begin
                if (core_tx_valid) begin
                    tx_shift_reg <= core_tx_flit;
                    tx_cnt       <= SER_RATIO - 1;
                    tx_active    <= 1'b1;
                end else begin
                    tx_shift_reg <= {FLIT_WIDTH{1'b0}}; // output 0s on idle
                    tx_active    <= 1'b0;
                end
            end else begin
                // shift bits right by num_lanes to expose next chunk on lsbs
                tx_shift_reg <= {{NUM_LANES{1'b0}}, tx_shift_reg[FLIT_WIDTH-1:NUM_LANES]};
                tx_cnt       <= tx_cnt - 1;
            end
        end
    end

    // drive physical lanes from the lsbs of the shift register
    assign phy_tx_lanes = tx_shift_reg[NUM_LANES-1:0];

    // rx path: flit deserialization & unpacking
    reg [$clog2(SER_RATIO)-1:0] rx_cnt;
    reg [FLIT_WIDTH-1:0]        rx_shift_reg;
    reg                         rx_valid_reg;
    reg [FLIT_WIDTH-1:0]        rx_flit_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_cnt       <= 0;
            rx_shift_reg <= {FLIT_WIDTH{1'b0}};
            rx_valid_reg <= 1'b0;
            rx_flit_reg  <= {FLIT_WIDTH{1'b0}};
        end else begin
            // shift incoming data into msbs, pushing existing data down
            rx_shift_reg <= {phy_rx_lanes, rx_shift_reg[FLIT_WIDTH-1 : NUM_LANES]};
            
            if (rx_cnt == SER_RATIO - 1) begin
                rx_cnt       <= 0;
                rx_valid_reg <= 1'b1;
                rx_flit_reg  <= {phy_rx_lanes, rx_shift_reg[FLIT_WIDTH-1 : NUM_LANES]};
            end else begin
                rx_cnt       <= rx_cnt + 1;
                rx_valid_reg <= 1'b0;
            end
        end
    end

    assign core_rx_valid = rx_valid_reg;
    assign core_rx_flit  = rx_flit_reg;

endmodule
