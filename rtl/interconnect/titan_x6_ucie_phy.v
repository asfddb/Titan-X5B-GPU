`timescale 1ns/1ps

module titan_x6_ucie_phy #(
    parameter FLIT_WIDTH = 256,
    parameter NUM_LANES  = 16,
    parameter SER_RATIO  = FLIT_WIDTH / NUM_LANES
)(
    input  wire                     clk,          // High speed lane clock
    input  wire                     rst_n,        // Asynchronous reset, active low
    
    // Core Interface (Runs at full FLIT_WIDTH)
    input  wire                     core_tx_valid,
    input  wire [FLIT_WIDTH-1:0]    core_tx_flit,
    output wire                     core_tx_ready,
    
    output wire                     core_rx_valid,
    output wire [FLIT_WIDTH-1:0]    core_rx_flit,
    
    // Physical Lanes (Die-to-Die Interconnect)
    output wire [NUM_LANES-1:0]     phy_tx_lanes,
    input  wire [NUM_LANES-1:0]     phy_rx_lanes
);

    // ---------------------------------------------------------
    // TX Path: Flit Packing & Serialization
    // ---------------------------------------------------------
    reg [$clog2(SER_RATIO)-1:0] tx_cnt;
    reg [FLIT_WIDTH-1:0]        tx_shift_reg;
    reg                         tx_active;

    // Ready is asserted when the shift register is empty (tx_cnt == 0)
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
                    tx_shift_reg <= {FLIT_WIDTH{1'b0}}; // Output 0s on idle
                    tx_active    <= 1'b0;
                end
            end else begin
                // Shift bits right by NUM_LANES to expose next chunk on LSBs
                tx_shift_reg <= {{NUM_LANES{1'b0}}, tx_shift_reg[FLIT_WIDTH-1:NUM_LANES]};
                tx_cnt       <= tx_cnt - 1;
            end
        end
    end

    // Drive physical lanes from the LSBs of the shift register
    assign phy_tx_lanes = tx_shift_reg[NUM_LANES-1:0];

    // ---------------------------------------------------------
    // RX Path: Flit Deserialization & Unpacking
    // ---------------------------------------------------------
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
            // Shift incoming data into MSBs, pushing existing data down
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
