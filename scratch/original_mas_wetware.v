`timescale 1ns / 1ps
`default_nettype none

/*
 * Module: astra8_mas_wetware
 * Description: 
 *   Morphogenetic Astroglial Syncytium (MAS) Fabric.
 *   Simulates a slow-time, biological "wetware" cellular automata grid overlay.
 *   Computes continuous Reaction-Diffusion (RD) equations using minimal-bitwidth 
 *   adders and arithmetic shifts. The chemical gradients (U, V) drift across 
 *   the logic fabric, dynamically altering routing tables.
 *
 *   - Cycle 16 Optimization:
 *     * Optimized Reaction-Diffusion calculation trees by replacing conditional negation logic
 *       for `u_quarter` and `v_quarter` (using explicit negative multiplexers and sub-tree routing)
 *       to completely eliminate the synthesized negator/subtractor blocks.
 *     * Cleaned up manual concatenation padding rules by leveraging Verilog-2001 implicit
 *       zero-extension rules for unsigned assignments to wider signed targets.
 *
 *   - Cycle 15 Optimization & Compliance:
 *     * Fixed direct memory array part-selects/bit-selects (e.g. chem_u[gi][...] or chem_u[i][...])
 *       which are illegal/non-standard in pure Verilog-2001. Local wires are now instantiated
 *       within generate loops to extract clean 1D vectors before slicing/indexing.
 *     * Optimized the critical path of the Reaction-Diffusion accumulation trees. Regrouped positive
 *       and negative terms into highly balanced binary adder/subtractor trees, reducing the calculation
 *       logic depth for new_u_calc from 4 down to 3, minimizing LUT delay and improving Fmax.
 *     * Localized the sequential loop iterator `i_seq` to the named block `seq_update` inside the
 *       always block to prevent duplicate declarations and namespace pollution.
 *     * Replaced variable-replicated bitwise masking in next state generation with clean, robust
 *       ternary operators (`? :`), eliminating compile warnings and improving DSP/LUT mapping.
 *     * Cleaned up nested replication brackets to conform to standard Verilog-2001 specifications.
 */

module astra8_mas_wetware #(
    parameter GRID_X        = 8,
    parameter GRID_Y        = 8,
    parameter DATA_WIDTH    = 8, // Requires DATA_WIDTH >= 4
    parameter D_U_SHIFT     = 2, // Base diffusion rate for U (shift right)
    parameter D_V_SHIFT     = 1, // Base diffusion rate for V (shift right)
    parameter [DATA_WIDTH-1:0] FEED_RATE  = 10,
    parameter [DATA_WIDTH-1:0] DECAY_RATE = 2,
    parameter BOUNDARY_MODE = 0  // 0: Neumann (zero-flux reflective), 1: Toroidal (wrap-around)
)(
    input  wire                               clk,
    input  wire                               rst_n,
    input  wire                               enable_slow_tick, // Pulse for slow-time evolution
    
    // Perturbation / Stimulus injection (1 bit per cell)
    input  wire [(GRID_X*GRID_Y)-1:0]         stimulus_inject,
    
    // Output chemical modulations to alter routing tables dynamically
    // (Provides 2 bits per grid cell)
    output wire [(GRID_X*GRID_Y*2)-1:0]       routing_modulations
);

    // --- Synthesis-Time Parameter Validation ---
    // These generate errors during elaboration if constraints are violated.
    generate
        if (DATA_WIDTH < 4) begin : gen_chk_dw
            // synopsys translate_off
            initial $display("ERROR: DATA_WIDTH must be >= 4, got %0d", DATA_WIDTH);
            // synopsys translate_on
            PARAMETER_ERROR_DATA_WIDTH_TOO_SMALL invalid_param();
        end
        if (GRID_X < 1 || GRID_Y < 1) begin : gen_chk_grid
            PARAMETER_ERROR_GRID_DIMENSION_ZERO invalid_param();
        end
        if (D_U_SHIFT >= DATA_WIDTH || D_V_SHIFT >= DATA_WIDTH) begin : gen_chk_shift
            PARAMETER_ERROR_SHIFT_EXCEEDS_DATAWIDTH invalid_param();
        end
        if (BOUNDARY_MODE != 0 && BOUNDARY_MODE != 1) begin : gen_chk_bm
            PARAMETER_ERROR_INVALID_BOUNDARY_MODE invalid_param();
        end
    endgenerate

    // Chemical concentration registers (Activator U, Inhibitor V)
    reg [DATA_WIDTH-1:0] chem_u [0:(GRID_X*GRID_Y)-1];
    reg [DATA_WIDTH-1:0] chem_v [0:(GRID_X*GRID_Y)-1];

    // Combinational next-state arrays
    wire [DATA_WIDTH-1:0] next_chem_u [0:(GRID_X*GRID_Y)-1];
    wire [DATA_WIDTH-1:0] next_chem_v [0:(GRID_X*GRID_Y)-1];

    // Internal calculation width mathematically guaranteed to prevent ANY intermediate overflow:
    // Laplacian max magnitude = 4 * (2^DW - 1) requires DW+2 bits unsigned, +1 for sign = DW+3.
    // Reaction accumulation adds 2 more bits of headroom = DW+5.
    localparam CALC_WIDTH = DATA_WIDTH + 5;

    // Globally zero-extended constants (always non-negative, stored in signed wires for arithmetic)
    wire signed [CALC_WIDTH-1:0] global_decay = DECAY_RATE;
    wire signed [CALC_WIDTH-1:0] global_feed  = FEED_RATE;

    // --- Global Pre-computation of Extracted & Shifted Nets ---
    // Single globally visible definition per cell eliminates redundant fanout in the netlist.
    wire signed [CALC_WIDTH-1:0] chem_u_ext [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_v_ext [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_u_x4  [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_v_x4  [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_u_half [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_v_half [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_u_quarter [0:(GRID_X*GRID_Y)-1];
    wire signed [CALC_WIDTH-1:0] chem_v_quarter [0:(GRID_X*GRID_Y)-1];

    genvar gi;
    generate
        for (gi = 0; gi < GRID_X*GRID_Y; gi = gi + 1) begin : gen_ext
            // Assign array elements to local 1D wires to ensure strict Verilog-2001 compliance
            // (no direct bit/part-selects on 2D memory arrays).
            wire [DATA_WIDTH-1:0] u_curr = chem_u[gi];
            wire [DATA_WIDTH-1:0] v_curr = chem_v[gi];

            // Implicit zero-extension into signed calc width. Values are always non-negative;
            // the signed wire type is solely for correct signed arithmetic downstream.
            assign chem_u_ext[gi] = u_curr;
            assign chem_v_ext[gi] = v_curr;
            
            // x4: shift left by 2 via structural concatenation (zero-fill LSBs)
            assign chem_u_x4[gi]  = {u_curr, 2'b00};
            assign chem_v_x4[gi]  = {v_curr, 2'b00};
            
            // /2: shift right by 1 via structural slice (discard LSB)
            assign chem_u_half[gi] = u_curr[DATA_WIDTH-1:1];
            assign chem_v_half[gi] = v_curr[DATA_WIDTH-1:1];
            
            // /4: shift right by 2 via structural slice (discard 2 LSBs)
            assign chem_u_quarter[gi] = u_curr[DATA_WIDTH-1:2];
            assign chem_v_quarter[gi] = v_curr[DATA_WIDTH-1:2];
        end
    endgenerate

    genvar x, y;
    generate
        for (y = 0; y < GRID_Y; y = y + 1) begin : gen_y
            for (x = 0; x < GRID_X; x = x + 1) begin : gen_x
                localparam i         = y * GRID_X + x;
                
                // Boundary conditions: Neumann (self-reflection) or Toroidal (wrap-around)
                localparam up_idx    = (y > 0)          ? (i - GRID_X) : (BOUNDARY_MODE ? (i + GRID_X*(GRID_Y-1)) : i);
                localparam down_idx  = (y < GRID_Y - 1) ? (i + GRID_X) : (BOUNDARY_MODE ? (i - GRID_X*(GRID_Y-1)) : i);
                localparam left_idx  = (x > 0)          ? (i - 1)      : (BOUNDARY_MODE ? (i + (GRID_X-1)) : i);
                localparam right_idx = (x < GRID_X - 1) ? (i + 1)      : (BOUNDARY_MODE ? (i - (GRID_X-1)) : i);
                
                // Declare local 1-D wires to read memory arrays compliant with Verilog-2001
                wire [DATA_WIDTH-1:0] u_c_val  = chem_u[i];
                wire [DATA_WIDTH-1:0] v_c_val  = chem_v[i];
                wire [DATA_WIDTH-1:0] u_up_val = chem_u[up_idx];
                wire [DATA_WIDTH-1:0] u_dn_val = chem_u[down_idx];
                wire [DATA_WIDTH-1:0] u_lf_val = chem_u[left_idx];
                wire [DATA_WIDTH-1:0] u_rt_val = chem_u[right_idx];
                
                wire [DATA_WIDTH-1:0] v_up_val = chem_v[up_idx];
                wire [DATA_WIDTH-1:0] v_dn_val = chem_v[down_idx];
                wire [DATA_WIDTH-1:0] v_lf_val = chem_v[left_idx];
                wire [DATA_WIDTH-1:0] v_rt_val = chem_v[right_idx];

                // --- Fetch Global Pre-computed Wires (signed calc-width) ---
                wire signed [CALC_WIDTH-1:0] u_c_ext = chem_u_ext[i];
                wire signed [CALC_WIDTH-1:0] u_u_ext = chem_u_ext[up_idx];
                wire signed [CALC_WIDTH-1:0] u_d_ext = chem_u_ext[down_idx];
                wire signed [CALC_WIDTH-1:0] u_l_ext = chem_u_ext[left_idx];
                wire signed [CALC_WIDTH-1:0] u_r_ext = chem_u_ext[right_idx];

                wire signed [CALC_WIDTH-1:0] v_c_ext = chem_v_ext[i];
                wire signed [CALC_WIDTH-1:0] v_u_ext = chem_v_ext[up_idx];
                wire signed [CALC_WIDTH-1:0] v_d_ext = chem_v_ext[down_idx];
                wire signed [CALC_WIDTH-1:0] v_l_ext = chem_v_ext[left_idx];
                wire signed [CALC_WIDTH-1:0] v_r_ext = chem_v_ext[right_idx];

                wire signed [CALC_WIDTH-1:0] u_c_x4 = chem_u_x4[i];
                wire signed [CALC_WIDTH-1:0] v_c_x4 = chem_v_x4[i];

                wire signed [CALC_WIDTH-1:0] u_half    = chem_u_half[i];
                wire signed [CALC_WIDTH-1:0] u_quarter = chem_u_quarter[i];
                wire signed [CALC_WIDTH-1:0] v_half    = chem_v_half[i];
                wire signed [CALC_WIDTH-1:0] v_quarter = chem_v_quarter[i];

                // ===================================================================
                // LAPLACIAN: Discrete 2D Laplacian = sum(neighbors) - 4*center
                // Balanced depth-2 adder tree: (up+down) + (left+right)
                // ===================================================================
                wire signed [CALC_WIDTH-1:0] lap_u_pair_ud = u_u_ext + u_d_ext;
                wire signed [CALC_WIDTH-1:0] lap_u_pair_lr = u_l_ext + u_r_ext;
                wire signed [CALC_WIDTH-1:0] laplacian_u   = (lap_u_pair_ud + lap_u_pair_lr) - u_c_x4;
                
                wire signed [CALC_WIDTH-1:0] lap_v_pair_ud = v_u_ext + v_d_ext;
                wire signed [CALC_WIDTH-1:0] lap_v_pair_lr = v_l_ext + v_r_ext;
                wire signed [CALC_WIDTH-1:0] laplacian_v   = (lap_v_pair_ud + lap_v_pair_lr) - v_c_x4;
                
                // ===================================================================
                // NON-LINEAR WETWARE PHYSICS
                // ===================================================================
                
                // Micro-turbulence: XOR of neighbor LSBs breaks static symmetry
                wire micro_turbulence = u_up_val[0] ^ u_dn_val[0]
                                       ^ v_lf_val[0] ^ v_rt_val[0];
                
                // Viscous friction: U/V MSB misalignment or micro-turbulence → extra damping
                wire viscous_friction = (u_c_val[DATA_WIDTH-1] ^ v_c_val[DATA_WIDTH-1])
                                       | micro_turbulence;
                wire signed [CALC_WIDTH-1:0] diff_u_base   = laplacian_u >>> D_U_SHIFT;
                wire signed [CALC_WIDTH-1:0] diff_u_damped = diff_u_base >>> 2;
                wire signed [CALC_WIDTH-1:0] diff_u        = viscous_friction ? diff_u_damped : diff_u_base;
                
                // Chaotic spark: coincidence of neighbor LSBs
                wire chaotic_spark = u_lf_val[0] & u_rt_val[0];
                
                // V surge: U dominance or chaotic spark → doubled V diffusion (catalytic effect)
                wire v_surge = (u_c_val[DATA_WIDTH-1] & u_c_val[DATA_WIDTH-2]) | chaotic_spark;
                wire signed [CALC_WIDTH-1:0] diff_v_base    = laplacian_v >>> D_V_SHIFT;
                wire signed [CALC_WIDTH-1:0] diff_v_boosted = diff_v_base << 1;
                wire signed [CALC_WIDTH-1:0] diff_v         = v_surge ? diff_v_boosted : diff_v_base;
                
                // ===================================================================
                // REACTION TERMS
                // ===================================================================
                
                // Fast bitwise activation: U is "active" when either of its top 2 bits are set (~25% threshold)
                wire u_is_active = u_c_val[DATA_WIDTH-1] | u_c_val[DATA_WIDTH-2];
                
                // Wetware coupling: resource bridge via bitwise AND of U & V concentrations
                wire [DATA_WIDTH-1:0] u_and_v = u_c_val & v_c_val;
                wire signed [CALC_WIDTH-1:0] wetware_drain_u     = u_and_v[DATA_WIDTH-1:2];
                wire signed [CALC_WIDTH-1:0] wetware_coupling_uv = u_and_v[DATA_WIDTH-1:1];
                
                // Collapse dynamics: V high + U low → V aggressively drains U
                wire u_collapse = v_c_val[DATA_WIDTH-1] & ~u_c_val[DATA_WIDTH-1];
                wire signed [CALC_WIDTH-1:0] collapse_drain = u_collapse ? u_half : $signed({CALC_WIDTH{1'b0}});
                
                // Stimulus injection: stimulus active -> global_feed, else 0
                wire signed [CALC_WIDTH-1:0] stim_val = stimulus_inject[i] ? global_feed : $signed({CALC_WIDTH{1'b0}});
                
                // ===================================================================
                // BALANCED ACCUMULATION TREES (Depth-3 Balanced Trees)
                // ===================================================================
                
                // U channel: We avoid an explicit negation adder for u_quarter.
                // If U is active, u_quarter is added to the positive terms.
                // If U is inactive, u_quarter is added to the negative terms.
                wire signed [CALC_WIDTH-1:0] u_pos_term = u_is_active ? u_quarter : $signed({CALC_WIDTH{1'b0}});
                wire signed [CALC_WIDTH-1:0] u_neg_term = u_is_active ? $signed({CALC_WIDTH{1'b0}}) : u_quarter;

                wire signed [CALC_WIDTH-1:0] u_pos_p1  = u_c_ext + stim_val;
                wire signed [CALC_WIDTH-1:0] u_pos_p2  = diff_u + u_pos_term;
                wire signed [CALC_WIDTH-1:0] u_pos_sum = u_pos_p1 + u_pos_p2;

                // Drains (decay + self-damping) and gains (current + coupling) balanced separately.
                wire signed [CALC_WIDTH-1:0] u_neg_p1  = v_half + wetware_drain_u;
                wire signed [CALC_WIDTH-1:0] u_neg_p2  = collapse_drain + u_neg_term;
                wire signed [CALC_WIDTH-1:0] u_neg_sum = u_neg_p1 + u_neg_p2;

                wire signed [CALC_WIDTH-1:0] new_u_calc = u_pos_sum - u_neg_sum;
                    
                // V channel: coupling_uv is a positive U→V transfer, not a drain.
                // Drains (decay + self-damping) and gains (current + coupling) balanced separately.
                wire signed [CALC_WIDTH-1:0] v_pos_p1  = v_c_ext + u_half;
                wire signed [CALC_WIDTH-1:0] v_pos_p2  = wetware_coupling_uv + diff_v;
                wire signed [CALC_WIDTH-1:0] v_pos_sum = v_pos_p1 + v_pos_p2;

                wire signed [CALC_WIDTH-1:0] v_neg_sum = v_quarter + global_decay;

                wire signed [CALC_WIDTH-1:0] new_v_calc = v_pos_sum - v_neg_sum;
                
                // ===================================================================
                // PURE SATURATION MUXES (Standard compliant and highly optimized)
                // Underflow (negative) → clamp to 0. Overflow (> 2^DW-1) → clamp to all-1s.
                // ===================================================================
                wire u_underflow = new_u_calc[CALC_WIDTH-1];
                wire u_overflow  = ~u_underflow & (|new_u_calc[CALC_WIDTH-2 : DATA_WIDTH]);
                
                assign next_chem_u[i] = u_underflow ? {DATA_WIDTH{1'b0}} :
                                        u_overflow  ? {DATA_WIDTH{1'b1}} :
                                                      new_u_calc[DATA_WIDTH-1:0];
                                        
                wire v_underflow = new_v_calc[CALC_WIDTH-1];
                wire v_overflow  = ~v_underflow & (|new_v_calc[CALC_WIDTH-2 : DATA_WIDTH]);
                
                assign next_chem_v[i] = v_underflow ? {DATA_WIDTH{1'b0}} :
                                        v_overflow  ? {DATA_WIDTH{1'b1}} :
                                                      new_v_calc[DATA_WIDTH-1:0];
            end
        end
    endgenerate

    // ===================================================================
    // SEQUENTIAL STATE UPDATE
    // ===================================================================
    always @(posedge clk or negedge rst_n) begin : seq_update
        integer i_seq;
        if (!rst_n) begin
            for (i_seq = 0; i_seq < GRID_X*GRID_Y; i_seq = i_seq + 1) begin
                // Pseudo-random patterned seed using modular fold for full grid coverage.
                // The fold `(i_seq & 7) ^ ((i_seq >> 3) & 3)` ensures cross-nibble variation
                // so even tiny grids (2×2, 3×3) get diverse initial conditions.
                // Edge case: 1×1 grid (cell 0) → fold = 0, no match below → explicit
                // fallthrough seeds cell 0 with a mid-range U to bootstrap dynamics.
                if (((i_seq & 7) == 5) || (((i_seq & 7) ^ ((i_seq >> 3) & 3)) == 3)) begin
                    chem_u[i_seq] <= {DATA_WIDTH{1'b1}};
                    chem_v[i_seq] <= {DATA_WIDTH{1'b0}};
                end else if (((i_seq & 7) == 2) || (((i_seq & 7) ^ ((i_seq >> 3) & 3)) == 6)) begin
                    chem_u[i_seq] <= {DATA_WIDTH{1'b0}};
                    chem_v[i_seq] <= {DATA_WIDTH{1'b1}};
                end else if (i_seq == 0) begin
                    // Guarantee cell 0 always has a nonzero seed. Critical for 1×1 grids
                    // where no other seed condition matches. For larger grids this is
                    // a harmless additional low-amplitude perturbation at the origin.
                    chem_u[i_seq] <= {1'b0, {(DATA_WIDTH-1){1'b1}}}; // Half-scale U seed
                    chem_v[i_seq] <= {DATA_WIDTH{1'b0}};
                end else begin
                    chem_u[i_seq] <= {DATA_WIDTH{1'b0}};
                    chem_v[i_seq] <= {DATA_WIDTH{1'b0}};
                end
            end
        end else if (enable_slow_tick) begin
            for (i_seq = 0; i_seq < GRID_X*GRID_Y; i_seq = i_seq + 1) begin
                chem_u[i_seq] <= next_chem_u[i_seq];
                chem_v[i_seq] <= next_chem_v[i_seq];
            end
        end
    end

    // ===================================================================
    // OUTPUT: Routing modulations derived from MSBs of U and V per cell
    // ===================================================================
    genvar g;
    generate
        for (g = 0; g < GRID_X*GRID_Y; g = g + 1) begin : gen_modulations
            wire [DATA_WIDTH-1:0] u_g = chem_u[g];
            wire [DATA_WIDTH-1:0] v_g = chem_v[g];
            assign routing_modulations[g*2 +: 2] = {u_g[DATA_WIDTH-1], v_g[DATA_WIDTH-1]};
        end
    endgenerate

endmodule

`default_nettype wire
