// ============================================================================
// TITAN X-INFINITY WAFER-SCALE ENGINE (WSE)
// Generated Grid: 16 x 16 (256 Cores)
// Architecture: X/Y Addressed 2D Mesh NoC
// ============================================================================
`timescale 1ns/1ps

module titan_x_infinity_wse (
    input  wire clk,
    input  wire rst_n,
    input  wire [256-1:0] defect_fuses,
    
    input  wire [1023:0] io_in_top,
    output wire [1023:0] io_out_top,
    input  wire [1023:0] io_in_bottom,
    output wire [1023:0] io_out_bottom,
    input  wire [1023:0] io_in_left,
    output wire [1023:0] io_out_left,
    input  wire [1023:0] io_in_right,
    output wire [1023:0] io_out_right
);

    // NoC Interconnect Wires
    wire [63:0] n_out_r0_c0, s_out_r0_c0, e_out_r0_c0, w_out_r0_c0;
    wire [63:0] n_out_r0_c1, s_out_r0_c1, e_out_r0_c1, w_out_r0_c1;
    wire [63:0] n_out_r0_c2, s_out_r0_c2, e_out_r0_c2, w_out_r0_c2;
    wire [63:0] n_out_r0_c3, s_out_r0_c3, e_out_r0_c3, w_out_r0_c3;
    wire [63:0] n_out_r0_c4, s_out_r0_c4, e_out_r0_c4, w_out_r0_c4;
    wire [63:0] n_out_r0_c5, s_out_r0_c5, e_out_r0_c5, w_out_r0_c5;
    wire [63:0] n_out_r0_c6, s_out_r0_c6, e_out_r0_c6, w_out_r0_c6;
    wire [63:0] n_out_r0_c7, s_out_r0_c7, e_out_r0_c7, w_out_r0_c7;
    wire [63:0] n_out_r0_c8, s_out_r0_c8, e_out_r0_c8, w_out_r0_c8;
    wire [63:0] n_out_r0_c9, s_out_r0_c9, e_out_r0_c9, w_out_r0_c9;
    wire [63:0] n_out_r0_c10, s_out_r0_c10, e_out_r0_c10, w_out_r0_c10;
    wire [63:0] n_out_r0_c11, s_out_r0_c11, e_out_r0_c11, w_out_r0_c11;
    wire [63:0] n_out_r0_c12, s_out_r0_c12, e_out_r0_c12, w_out_r0_c12;
    wire [63:0] n_out_r0_c13, s_out_r0_c13, e_out_r0_c13, w_out_r0_c13;
    wire [63:0] n_out_r0_c14, s_out_r0_c14, e_out_r0_c14, w_out_r0_c14;
    wire [63:0] n_out_r0_c15, s_out_r0_c15, e_out_r0_c15, w_out_r0_c15;
    wire [63:0] n_out_r1_c0, s_out_r1_c0, e_out_r1_c0, w_out_r1_c0;
    wire [63:0] n_out_r1_c1, s_out_r1_c1, e_out_r1_c1, w_out_r1_c1;
    wire [63:0] n_out_r1_c2, s_out_r1_c2, e_out_r1_c2, w_out_r1_c2;
    wire [63:0] n_out_r1_c3, s_out_r1_c3, e_out_r1_c3, w_out_r1_c3;
    wire [63:0] n_out_r1_c4, s_out_r1_c4, e_out_r1_c4, w_out_r1_c4;
    wire [63:0] n_out_r1_c5, s_out_r1_c5, e_out_r1_c5, w_out_r1_c5;
    wire [63:0] n_out_r1_c6, s_out_r1_c6, e_out_r1_c6, w_out_r1_c6;
    wire [63:0] n_out_r1_c7, s_out_r1_c7, e_out_r1_c7, w_out_r1_c7;
    wire [63:0] n_out_r1_c8, s_out_r1_c8, e_out_r1_c8, w_out_r1_c8;
    wire [63:0] n_out_r1_c9, s_out_r1_c9, e_out_r1_c9, w_out_r1_c9;
    wire [63:0] n_out_r1_c10, s_out_r1_c10, e_out_r1_c10, w_out_r1_c10;
    wire [63:0] n_out_r1_c11, s_out_r1_c11, e_out_r1_c11, w_out_r1_c11;
    wire [63:0] n_out_r1_c12, s_out_r1_c12, e_out_r1_c12, w_out_r1_c12;
    wire [63:0] n_out_r1_c13, s_out_r1_c13, e_out_r1_c13, w_out_r1_c13;
    wire [63:0] n_out_r1_c14, s_out_r1_c14, e_out_r1_c14, w_out_r1_c14;
    wire [63:0] n_out_r1_c15, s_out_r1_c15, e_out_r1_c15, w_out_r1_c15;
    wire [63:0] n_out_r2_c0, s_out_r2_c0, e_out_r2_c0, w_out_r2_c0;
    wire [63:0] n_out_r2_c1, s_out_r2_c1, e_out_r2_c1, w_out_r2_c1;
    wire [63:0] n_out_r2_c2, s_out_r2_c2, e_out_r2_c2, w_out_r2_c2;
    wire [63:0] n_out_r2_c3, s_out_r2_c3, e_out_r2_c3, w_out_r2_c3;
    wire [63:0] n_out_r2_c4, s_out_r2_c4, e_out_r2_c4, w_out_r2_c4;
    wire [63:0] n_out_r2_c5, s_out_r2_c5, e_out_r2_c5, w_out_r2_c5;
    wire [63:0] n_out_r2_c6, s_out_r2_c6, e_out_r2_c6, w_out_r2_c6;
    wire [63:0] n_out_r2_c7, s_out_r2_c7, e_out_r2_c7, w_out_r2_c7;
    wire [63:0] n_out_r2_c8, s_out_r2_c8, e_out_r2_c8, w_out_r2_c8;
    wire [63:0] n_out_r2_c9, s_out_r2_c9, e_out_r2_c9, w_out_r2_c9;
    wire [63:0] n_out_r2_c10, s_out_r2_c10, e_out_r2_c10, w_out_r2_c10;
    wire [63:0] n_out_r2_c11, s_out_r2_c11, e_out_r2_c11, w_out_r2_c11;
    wire [63:0] n_out_r2_c12, s_out_r2_c12, e_out_r2_c12, w_out_r2_c12;
    wire [63:0] n_out_r2_c13, s_out_r2_c13, e_out_r2_c13, w_out_r2_c13;
    wire [63:0] n_out_r2_c14, s_out_r2_c14, e_out_r2_c14, w_out_r2_c14;
    wire [63:0] n_out_r2_c15, s_out_r2_c15, e_out_r2_c15, w_out_r2_c15;
    wire [63:0] n_out_r3_c0, s_out_r3_c0, e_out_r3_c0, w_out_r3_c0;
    wire [63:0] n_out_r3_c1, s_out_r3_c1, e_out_r3_c1, w_out_r3_c1;
    wire [63:0] n_out_r3_c2, s_out_r3_c2, e_out_r3_c2, w_out_r3_c2;
    wire [63:0] n_out_r3_c3, s_out_r3_c3, e_out_r3_c3, w_out_r3_c3;
    wire [63:0] n_out_r3_c4, s_out_r3_c4, e_out_r3_c4, w_out_r3_c4;
    wire [63:0] n_out_r3_c5, s_out_r3_c5, e_out_r3_c5, w_out_r3_c5;
    wire [63:0] n_out_r3_c6, s_out_r3_c6, e_out_r3_c6, w_out_r3_c6;
    wire [63:0] n_out_r3_c7, s_out_r3_c7, e_out_r3_c7, w_out_r3_c7;
    wire [63:0] n_out_r3_c8, s_out_r3_c8, e_out_r3_c8, w_out_r3_c8;
    wire [63:0] n_out_r3_c9, s_out_r3_c9, e_out_r3_c9, w_out_r3_c9;
    wire [63:0] n_out_r3_c10, s_out_r3_c10, e_out_r3_c10, w_out_r3_c10;
    wire [63:0] n_out_r3_c11, s_out_r3_c11, e_out_r3_c11, w_out_r3_c11;
    wire [63:0] n_out_r3_c12, s_out_r3_c12, e_out_r3_c12, w_out_r3_c12;
    wire [63:0] n_out_r3_c13, s_out_r3_c13, e_out_r3_c13, w_out_r3_c13;
    wire [63:0] n_out_r3_c14, s_out_r3_c14, e_out_r3_c14, w_out_r3_c14;
    wire [63:0] n_out_r3_c15, s_out_r3_c15, e_out_r3_c15, w_out_r3_c15;
    wire [63:0] n_out_r4_c0, s_out_r4_c0, e_out_r4_c0, w_out_r4_c0;
    wire [63:0] n_out_r4_c1, s_out_r4_c1, e_out_r4_c1, w_out_r4_c1;
    wire [63:0] n_out_r4_c2, s_out_r4_c2, e_out_r4_c2, w_out_r4_c2;
    wire [63:0] n_out_r4_c3, s_out_r4_c3, e_out_r4_c3, w_out_r4_c3;
    wire [63:0] n_out_r4_c4, s_out_r4_c4, e_out_r4_c4, w_out_r4_c4;
    wire [63:0] n_out_r4_c5, s_out_r4_c5, e_out_r4_c5, w_out_r4_c5;
    wire [63:0] n_out_r4_c6, s_out_r4_c6, e_out_r4_c6, w_out_r4_c6;
    wire [63:0] n_out_r4_c7, s_out_r4_c7, e_out_r4_c7, w_out_r4_c7;
    wire [63:0] n_out_r4_c8, s_out_r4_c8, e_out_r4_c8, w_out_r4_c8;
    wire [63:0] n_out_r4_c9, s_out_r4_c9, e_out_r4_c9, w_out_r4_c9;
    wire [63:0] n_out_r4_c10, s_out_r4_c10, e_out_r4_c10, w_out_r4_c10;
    wire [63:0] n_out_r4_c11, s_out_r4_c11, e_out_r4_c11, w_out_r4_c11;
    wire [63:0] n_out_r4_c12, s_out_r4_c12, e_out_r4_c12, w_out_r4_c12;
    wire [63:0] n_out_r4_c13, s_out_r4_c13, e_out_r4_c13, w_out_r4_c13;
    wire [63:0] n_out_r4_c14, s_out_r4_c14, e_out_r4_c14, w_out_r4_c14;
    wire [63:0] n_out_r4_c15, s_out_r4_c15, e_out_r4_c15, w_out_r4_c15;
    wire [63:0] n_out_r5_c0, s_out_r5_c0, e_out_r5_c0, w_out_r5_c0;
    wire [63:0] n_out_r5_c1, s_out_r5_c1, e_out_r5_c1, w_out_r5_c1;
    wire [63:0] n_out_r5_c2, s_out_r5_c2, e_out_r5_c2, w_out_r5_c2;
    wire [63:0] n_out_r5_c3, s_out_r5_c3, e_out_r5_c3, w_out_r5_c3;
    wire [63:0] n_out_r5_c4, s_out_r5_c4, e_out_r5_c4, w_out_r5_c4;
    wire [63:0] n_out_r5_c5, s_out_r5_c5, e_out_r5_c5, w_out_r5_c5;
    wire [63:0] n_out_r5_c6, s_out_r5_c6, e_out_r5_c6, w_out_r5_c6;
    wire [63:0] n_out_r5_c7, s_out_r5_c7, e_out_r5_c7, w_out_r5_c7;
    wire [63:0] n_out_r5_c8, s_out_r5_c8, e_out_r5_c8, w_out_r5_c8;
    wire [63:0] n_out_r5_c9, s_out_r5_c9, e_out_r5_c9, w_out_r5_c9;
    wire [63:0] n_out_r5_c10, s_out_r5_c10, e_out_r5_c10, w_out_r5_c10;
    wire [63:0] n_out_r5_c11, s_out_r5_c11, e_out_r5_c11, w_out_r5_c11;
    wire [63:0] n_out_r5_c12, s_out_r5_c12, e_out_r5_c12, w_out_r5_c12;
    wire [63:0] n_out_r5_c13, s_out_r5_c13, e_out_r5_c13, w_out_r5_c13;
    wire [63:0] n_out_r5_c14, s_out_r5_c14, e_out_r5_c14, w_out_r5_c14;
    wire [63:0] n_out_r5_c15, s_out_r5_c15, e_out_r5_c15, w_out_r5_c15;
    wire [63:0] n_out_r6_c0, s_out_r6_c0, e_out_r6_c0, w_out_r6_c0;
    wire [63:0] n_out_r6_c1, s_out_r6_c1, e_out_r6_c1, w_out_r6_c1;
    wire [63:0] n_out_r6_c2, s_out_r6_c2, e_out_r6_c2, w_out_r6_c2;
    wire [63:0] n_out_r6_c3, s_out_r6_c3, e_out_r6_c3, w_out_r6_c3;
    wire [63:0] n_out_r6_c4, s_out_r6_c4, e_out_r6_c4, w_out_r6_c4;
    wire [63:0] n_out_r6_c5, s_out_r6_c5, e_out_r6_c5, w_out_r6_c5;
    wire [63:0] n_out_r6_c6, s_out_r6_c6, e_out_r6_c6, w_out_r6_c6;
    wire [63:0] n_out_r6_c7, s_out_r6_c7, e_out_r6_c7, w_out_r6_c7;
    wire [63:0] n_out_r6_c8, s_out_r6_c8, e_out_r6_c8, w_out_r6_c8;
    wire [63:0] n_out_r6_c9, s_out_r6_c9, e_out_r6_c9, w_out_r6_c9;
    wire [63:0] n_out_r6_c10, s_out_r6_c10, e_out_r6_c10, w_out_r6_c10;
    wire [63:0] n_out_r6_c11, s_out_r6_c11, e_out_r6_c11, w_out_r6_c11;
    wire [63:0] n_out_r6_c12, s_out_r6_c12, e_out_r6_c12, w_out_r6_c12;
    wire [63:0] n_out_r6_c13, s_out_r6_c13, e_out_r6_c13, w_out_r6_c13;
    wire [63:0] n_out_r6_c14, s_out_r6_c14, e_out_r6_c14, w_out_r6_c14;
    wire [63:0] n_out_r6_c15, s_out_r6_c15, e_out_r6_c15, w_out_r6_c15;
    wire [63:0] n_out_r7_c0, s_out_r7_c0, e_out_r7_c0, w_out_r7_c0;
    wire [63:0] n_out_r7_c1, s_out_r7_c1, e_out_r7_c1, w_out_r7_c1;
    wire [63:0] n_out_r7_c2, s_out_r7_c2, e_out_r7_c2, w_out_r7_c2;
    wire [63:0] n_out_r7_c3, s_out_r7_c3, e_out_r7_c3, w_out_r7_c3;
    wire [63:0] n_out_r7_c4, s_out_r7_c4, e_out_r7_c4, w_out_r7_c4;
    wire [63:0] n_out_r7_c5, s_out_r7_c5, e_out_r7_c5, w_out_r7_c5;
    wire [63:0] n_out_r7_c6, s_out_r7_c6, e_out_r7_c6, w_out_r7_c6;
    wire [63:0] n_out_r7_c7, s_out_r7_c7, e_out_r7_c7, w_out_r7_c7;
    wire [63:0] n_out_r7_c8, s_out_r7_c8, e_out_r7_c8, w_out_r7_c8;
    wire [63:0] n_out_r7_c9, s_out_r7_c9, e_out_r7_c9, w_out_r7_c9;
    wire [63:0] n_out_r7_c10, s_out_r7_c10, e_out_r7_c10, w_out_r7_c10;
    wire [63:0] n_out_r7_c11, s_out_r7_c11, e_out_r7_c11, w_out_r7_c11;
    wire [63:0] n_out_r7_c12, s_out_r7_c12, e_out_r7_c12, w_out_r7_c12;
    wire [63:0] n_out_r7_c13, s_out_r7_c13, e_out_r7_c13, w_out_r7_c13;
    wire [63:0] n_out_r7_c14, s_out_r7_c14, e_out_r7_c14, w_out_r7_c14;
    wire [63:0] n_out_r7_c15, s_out_r7_c15, e_out_r7_c15, w_out_r7_c15;
    wire [63:0] n_out_r8_c0, s_out_r8_c0, e_out_r8_c0, w_out_r8_c0;
    wire [63:0] n_out_r8_c1, s_out_r8_c1, e_out_r8_c1, w_out_r8_c1;
    wire [63:0] n_out_r8_c2, s_out_r8_c2, e_out_r8_c2, w_out_r8_c2;
    wire [63:0] n_out_r8_c3, s_out_r8_c3, e_out_r8_c3, w_out_r8_c3;
    wire [63:0] n_out_r8_c4, s_out_r8_c4, e_out_r8_c4, w_out_r8_c4;
    wire [63:0] n_out_r8_c5, s_out_r8_c5, e_out_r8_c5, w_out_r8_c5;
    wire [63:0] n_out_r8_c6, s_out_r8_c6, e_out_r8_c6, w_out_r8_c6;
    wire [63:0] n_out_r8_c7, s_out_r8_c7, e_out_r8_c7, w_out_r8_c7;
    wire [63:0] n_out_r8_c8, s_out_r8_c8, e_out_r8_c8, w_out_r8_c8;
    wire [63:0] n_out_r8_c9, s_out_r8_c9, e_out_r8_c9, w_out_r8_c9;
    wire [63:0] n_out_r8_c10, s_out_r8_c10, e_out_r8_c10, w_out_r8_c10;
    wire [63:0] n_out_r8_c11, s_out_r8_c11, e_out_r8_c11, w_out_r8_c11;
    wire [63:0] n_out_r8_c12, s_out_r8_c12, e_out_r8_c12, w_out_r8_c12;
    wire [63:0] n_out_r8_c13, s_out_r8_c13, e_out_r8_c13, w_out_r8_c13;
    wire [63:0] n_out_r8_c14, s_out_r8_c14, e_out_r8_c14, w_out_r8_c14;
    wire [63:0] n_out_r8_c15, s_out_r8_c15, e_out_r8_c15, w_out_r8_c15;
    wire [63:0] n_out_r9_c0, s_out_r9_c0, e_out_r9_c0, w_out_r9_c0;
    wire [63:0] n_out_r9_c1, s_out_r9_c1, e_out_r9_c1, w_out_r9_c1;
    wire [63:0] n_out_r9_c2, s_out_r9_c2, e_out_r9_c2, w_out_r9_c2;
    wire [63:0] n_out_r9_c3, s_out_r9_c3, e_out_r9_c3, w_out_r9_c3;
    wire [63:0] n_out_r9_c4, s_out_r9_c4, e_out_r9_c4, w_out_r9_c4;
    wire [63:0] n_out_r9_c5, s_out_r9_c5, e_out_r9_c5, w_out_r9_c5;
    wire [63:0] n_out_r9_c6, s_out_r9_c6, e_out_r9_c6, w_out_r9_c6;
    wire [63:0] n_out_r9_c7, s_out_r9_c7, e_out_r9_c7, w_out_r9_c7;
    wire [63:0] n_out_r9_c8, s_out_r9_c8, e_out_r9_c8, w_out_r9_c8;
    wire [63:0] n_out_r9_c9, s_out_r9_c9, e_out_r9_c9, w_out_r9_c9;
    wire [63:0] n_out_r9_c10, s_out_r9_c10, e_out_r9_c10, w_out_r9_c10;
    wire [63:0] n_out_r9_c11, s_out_r9_c11, e_out_r9_c11, w_out_r9_c11;
    wire [63:0] n_out_r9_c12, s_out_r9_c12, e_out_r9_c12, w_out_r9_c12;
    wire [63:0] n_out_r9_c13, s_out_r9_c13, e_out_r9_c13, w_out_r9_c13;
    wire [63:0] n_out_r9_c14, s_out_r9_c14, e_out_r9_c14, w_out_r9_c14;
    wire [63:0] n_out_r9_c15, s_out_r9_c15, e_out_r9_c15, w_out_r9_c15;
    wire [63:0] n_out_r10_c0, s_out_r10_c0, e_out_r10_c0, w_out_r10_c0;
    wire [63:0] n_out_r10_c1, s_out_r10_c1, e_out_r10_c1, w_out_r10_c1;
    wire [63:0] n_out_r10_c2, s_out_r10_c2, e_out_r10_c2, w_out_r10_c2;
    wire [63:0] n_out_r10_c3, s_out_r10_c3, e_out_r10_c3, w_out_r10_c3;
    wire [63:0] n_out_r10_c4, s_out_r10_c4, e_out_r10_c4, w_out_r10_c4;
    wire [63:0] n_out_r10_c5, s_out_r10_c5, e_out_r10_c5, w_out_r10_c5;
    wire [63:0] n_out_r10_c6, s_out_r10_c6, e_out_r10_c6, w_out_r10_c6;
    wire [63:0] n_out_r10_c7, s_out_r10_c7, e_out_r10_c7, w_out_r10_c7;
    wire [63:0] n_out_r10_c8, s_out_r10_c8, e_out_r10_c8, w_out_r10_c8;
    wire [63:0] n_out_r10_c9, s_out_r10_c9, e_out_r10_c9, w_out_r10_c9;
    wire [63:0] n_out_r10_c10, s_out_r10_c10, e_out_r10_c10, w_out_r10_c10;
    wire [63:0] n_out_r10_c11, s_out_r10_c11, e_out_r10_c11, w_out_r10_c11;
    wire [63:0] n_out_r10_c12, s_out_r10_c12, e_out_r10_c12, w_out_r10_c12;
    wire [63:0] n_out_r10_c13, s_out_r10_c13, e_out_r10_c13, w_out_r10_c13;
    wire [63:0] n_out_r10_c14, s_out_r10_c14, e_out_r10_c14, w_out_r10_c14;
    wire [63:0] n_out_r10_c15, s_out_r10_c15, e_out_r10_c15, w_out_r10_c15;
    wire [63:0] n_out_r11_c0, s_out_r11_c0, e_out_r11_c0, w_out_r11_c0;
    wire [63:0] n_out_r11_c1, s_out_r11_c1, e_out_r11_c1, w_out_r11_c1;
    wire [63:0] n_out_r11_c2, s_out_r11_c2, e_out_r11_c2, w_out_r11_c2;
    wire [63:0] n_out_r11_c3, s_out_r11_c3, e_out_r11_c3, w_out_r11_c3;
    wire [63:0] n_out_r11_c4, s_out_r11_c4, e_out_r11_c4, w_out_r11_c4;
    wire [63:0] n_out_r11_c5, s_out_r11_c5, e_out_r11_c5, w_out_r11_c5;
    wire [63:0] n_out_r11_c6, s_out_r11_c6, e_out_r11_c6, w_out_r11_c6;
    wire [63:0] n_out_r11_c7, s_out_r11_c7, e_out_r11_c7, w_out_r11_c7;
    wire [63:0] n_out_r11_c8, s_out_r11_c8, e_out_r11_c8, w_out_r11_c8;
    wire [63:0] n_out_r11_c9, s_out_r11_c9, e_out_r11_c9, w_out_r11_c9;
    wire [63:0] n_out_r11_c10, s_out_r11_c10, e_out_r11_c10, w_out_r11_c10;
    wire [63:0] n_out_r11_c11, s_out_r11_c11, e_out_r11_c11, w_out_r11_c11;
    wire [63:0] n_out_r11_c12, s_out_r11_c12, e_out_r11_c12, w_out_r11_c12;
    wire [63:0] n_out_r11_c13, s_out_r11_c13, e_out_r11_c13, w_out_r11_c13;
    wire [63:0] n_out_r11_c14, s_out_r11_c14, e_out_r11_c14, w_out_r11_c14;
    wire [63:0] n_out_r11_c15, s_out_r11_c15, e_out_r11_c15, w_out_r11_c15;
    wire [63:0] n_out_r12_c0, s_out_r12_c0, e_out_r12_c0, w_out_r12_c0;
    wire [63:0] n_out_r12_c1, s_out_r12_c1, e_out_r12_c1, w_out_r12_c1;
    wire [63:0] n_out_r12_c2, s_out_r12_c2, e_out_r12_c2, w_out_r12_c2;
    wire [63:0] n_out_r12_c3, s_out_r12_c3, e_out_r12_c3, w_out_r12_c3;
    wire [63:0] n_out_r12_c4, s_out_r12_c4, e_out_r12_c4, w_out_r12_c4;
    wire [63:0] n_out_r12_c5, s_out_r12_c5, e_out_r12_c5, w_out_r12_c5;
    wire [63:0] n_out_r12_c6, s_out_r12_c6, e_out_r12_c6, w_out_r12_c6;
    wire [63:0] n_out_r12_c7, s_out_r12_c7, e_out_r12_c7, w_out_r12_c7;
    wire [63:0] n_out_r12_c8, s_out_r12_c8, e_out_r12_c8, w_out_r12_c8;
    wire [63:0] n_out_r12_c9, s_out_r12_c9, e_out_r12_c9, w_out_r12_c9;
    wire [63:0] n_out_r12_c10, s_out_r12_c10, e_out_r12_c10, w_out_r12_c10;
    wire [63:0] n_out_r12_c11, s_out_r12_c11, e_out_r12_c11, w_out_r12_c11;
    wire [63:0] n_out_r12_c12, s_out_r12_c12, e_out_r12_c12, w_out_r12_c12;
    wire [63:0] n_out_r12_c13, s_out_r12_c13, e_out_r12_c13, w_out_r12_c13;
    wire [63:0] n_out_r12_c14, s_out_r12_c14, e_out_r12_c14, w_out_r12_c14;
    wire [63:0] n_out_r12_c15, s_out_r12_c15, e_out_r12_c15, w_out_r12_c15;
    wire [63:0] n_out_r13_c0, s_out_r13_c0, e_out_r13_c0, w_out_r13_c0;
    wire [63:0] n_out_r13_c1, s_out_r13_c1, e_out_r13_c1, w_out_r13_c1;
    wire [63:0] n_out_r13_c2, s_out_r13_c2, e_out_r13_c2, w_out_r13_c2;
    wire [63:0] n_out_r13_c3, s_out_r13_c3, e_out_r13_c3, w_out_r13_c3;
    wire [63:0] n_out_r13_c4, s_out_r13_c4, e_out_r13_c4, w_out_r13_c4;
    wire [63:0] n_out_r13_c5, s_out_r13_c5, e_out_r13_c5, w_out_r13_c5;
    wire [63:0] n_out_r13_c6, s_out_r13_c6, e_out_r13_c6, w_out_r13_c6;
    wire [63:0] n_out_r13_c7, s_out_r13_c7, e_out_r13_c7, w_out_r13_c7;
    wire [63:0] n_out_r13_c8, s_out_r13_c8, e_out_r13_c8, w_out_r13_c8;
    wire [63:0] n_out_r13_c9, s_out_r13_c9, e_out_r13_c9, w_out_r13_c9;
    wire [63:0] n_out_r13_c10, s_out_r13_c10, e_out_r13_c10, w_out_r13_c10;
    wire [63:0] n_out_r13_c11, s_out_r13_c11, e_out_r13_c11, w_out_r13_c11;
    wire [63:0] n_out_r13_c12, s_out_r13_c12, e_out_r13_c12, w_out_r13_c12;
    wire [63:0] n_out_r13_c13, s_out_r13_c13, e_out_r13_c13, w_out_r13_c13;
    wire [63:0] n_out_r13_c14, s_out_r13_c14, e_out_r13_c14, w_out_r13_c14;
    wire [63:0] n_out_r13_c15, s_out_r13_c15, e_out_r13_c15, w_out_r13_c15;
    wire [63:0] n_out_r14_c0, s_out_r14_c0, e_out_r14_c0, w_out_r14_c0;
    wire [63:0] n_out_r14_c1, s_out_r14_c1, e_out_r14_c1, w_out_r14_c1;
    wire [63:0] n_out_r14_c2, s_out_r14_c2, e_out_r14_c2, w_out_r14_c2;
    wire [63:0] n_out_r14_c3, s_out_r14_c3, e_out_r14_c3, w_out_r14_c3;
    wire [63:0] n_out_r14_c4, s_out_r14_c4, e_out_r14_c4, w_out_r14_c4;
    wire [63:0] n_out_r14_c5, s_out_r14_c5, e_out_r14_c5, w_out_r14_c5;
    wire [63:0] n_out_r14_c6, s_out_r14_c6, e_out_r14_c6, w_out_r14_c6;
    wire [63:0] n_out_r14_c7, s_out_r14_c7, e_out_r14_c7, w_out_r14_c7;
    wire [63:0] n_out_r14_c8, s_out_r14_c8, e_out_r14_c8, w_out_r14_c8;
    wire [63:0] n_out_r14_c9, s_out_r14_c9, e_out_r14_c9, w_out_r14_c9;
    wire [63:0] n_out_r14_c10, s_out_r14_c10, e_out_r14_c10, w_out_r14_c10;
    wire [63:0] n_out_r14_c11, s_out_r14_c11, e_out_r14_c11, w_out_r14_c11;
    wire [63:0] n_out_r14_c12, s_out_r14_c12, e_out_r14_c12, w_out_r14_c12;
    wire [63:0] n_out_r14_c13, s_out_r14_c13, e_out_r14_c13, w_out_r14_c13;
    wire [63:0] n_out_r14_c14, s_out_r14_c14, e_out_r14_c14, w_out_r14_c14;
    wire [63:0] n_out_r14_c15, s_out_r14_c15, e_out_r14_c15, w_out_r14_c15;
    wire [63:0] n_out_r15_c0, s_out_r15_c0, e_out_r15_c0, w_out_r15_c0;
    wire [63:0] n_out_r15_c1, s_out_r15_c1, e_out_r15_c1, w_out_r15_c1;
    wire [63:0] n_out_r15_c2, s_out_r15_c2, e_out_r15_c2, w_out_r15_c2;
    wire [63:0] n_out_r15_c3, s_out_r15_c3, e_out_r15_c3, w_out_r15_c3;
    wire [63:0] n_out_r15_c4, s_out_r15_c4, e_out_r15_c4, w_out_r15_c4;
    wire [63:0] n_out_r15_c5, s_out_r15_c5, e_out_r15_c5, w_out_r15_c5;
    wire [63:0] n_out_r15_c6, s_out_r15_c6, e_out_r15_c6, w_out_r15_c6;
    wire [63:0] n_out_r15_c7, s_out_r15_c7, e_out_r15_c7, w_out_r15_c7;
    wire [63:0] n_out_r15_c8, s_out_r15_c8, e_out_r15_c8, w_out_r15_c8;
    wire [63:0] n_out_r15_c9, s_out_r15_c9, e_out_r15_c9, w_out_r15_c9;
    wire [63:0] n_out_r15_c10, s_out_r15_c10, e_out_r15_c10, w_out_r15_c10;
    wire [63:0] n_out_r15_c11, s_out_r15_c11, e_out_r15_c11, w_out_r15_c11;
    wire [63:0] n_out_r15_c12, s_out_r15_c12, e_out_r15_c12, w_out_r15_c12;
    wire [63:0] n_out_r15_c13, s_out_r15_c13, e_out_r15_c13, w_out_r15_c13;
    wire [63:0] n_out_r15_c14, s_out_r15_c14, e_out_r15_c14, w_out_r15_c14;
    wire [63:0] n_out_r15_c15, s_out_r15_c15, e_out_r15_c15, w_out_r15_c15;

    // Core Instantiations
    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd0)
    ) u_core_r0_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[0]),
        .noc_in_n(io_in_top[63:0]), .noc_in_s(n_out_r1_c0), .noc_in_e(w_out_r0_c1), .noc_in_w(io_in_left[63:0]),
        .noc_out_n(n_out_r0_c0), .noc_out_s(s_out_r0_c0), 
        .noc_out_e(e_out_r0_c0), .noc_out_w(w_out_r0_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd0)
    ) u_core_r0_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[1]),
        .noc_in_n(io_in_top[127:64]), .noc_in_s(n_out_r1_c1), .noc_in_e(w_out_r0_c2), .noc_in_w(e_out_r0_c0),
        .noc_out_n(n_out_r0_c1), .noc_out_s(s_out_r0_c1), 
        .noc_out_e(e_out_r0_c1), .noc_out_w(w_out_r0_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd0)
    ) u_core_r0_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[2]),
        .noc_in_n(io_in_top[191:128]), .noc_in_s(n_out_r1_c2), .noc_in_e(w_out_r0_c3), .noc_in_w(e_out_r0_c1),
        .noc_out_n(n_out_r0_c2), .noc_out_s(s_out_r0_c2), 
        .noc_out_e(e_out_r0_c2), .noc_out_w(w_out_r0_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd0)
    ) u_core_r0_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[3]),
        .noc_in_n(io_in_top[255:192]), .noc_in_s(n_out_r1_c3), .noc_in_e(w_out_r0_c4), .noc_in_w(e_out_r0_c2),
        .noc_out_n(n_out_r0_c3), .noc_out_s(s_out_r0_c3), 
        .noc_out_e(e_out_r0_c3), .noc_out_w(w_out_r0_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd0)
    ) u_core_r0_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[4]),
        .noc_in_n(io_in_top[319:256]), .noc_in_s(n_out_r1_c4), .noc_in_e(w_out_r0_c5), .noc_in_w(e_out_r0_c3),
        .noc_out_n(n_out_r0_c4), .noc_out_s(s_out_r0_c4), 
        .noc_out_e(e_out_r0_c4), .noc_out_w(w_out_r0_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd0)
    ) u_core_r0_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[5]),
        .noc_in_n(io_in_top[383:320]), .noc_in_s(n_out_r1_c5), .noc_in_e(w_out_r0_c6), .noc_in_w(e_out_r0_c4),
        .noc_out_n(n_out_r0_c5), .noc_out_s(s_out_r0_c5), 
        .noc_out_e(e_out_r0_c5), .noc_out_w(w_out_r0_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd0)
    ) u_core_r0_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[6]),
        .noc_in_n(io_in_top[447:384]), .noc_in_s(n_out_r1_c6), .noc_in_e(w_out_r0_c7), .noc_in_w(e_out_r0_c5),
        .noc_out_n(n_out_r0_c6), .noc_out_s(s_out_r0_c6), 
        .noc_out_e(e_out_r0_c6), .noc_out_w(w_out_r0_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd0)
    ) u_core_r0_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[7]),
        .noc_in_n(io_in_top[511:448]), .noc_in_s(n_out_r1_c7), .noc_in_e(w_out_r0_c8), .noc_in_w(e_out_r0_c6),
        .noc_out_n(n_out_r0_c7), .noc_out_s(s_out_r0_c7), 
        .noc_out_e(e_out_r0_c7), .noc_out_w(w_out_r0_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd0)
    ) u_core_r0_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[8]),
        .noc_in_n(io_in_top[575:512]), .noc_in_s(n_out_r1_c8), .noc_in_e(w_out_r0_c9), .noc_in_w(e_out_r0_c7),
        .noc_out_n(n_out_r0_c8), .noc_out_s(s_out_r0_c8), 
        .noc_out_e(e_out_r0_c8), .noc_out_w(w_out_r0_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd0)
    ) u_core_r0_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[9]),
        .noc_in_n(io_in_top[639:576]), .noc_in_s(n_out_r1_c9), .noc_in_e(w_out_r0_c10), .noc_in_w(e_out_r0_c8),
        .noc_out_n(n_out_r0_c9), .noc_out_s(s_out_r0_c9), 
        .noc_out_e(e_out_r0_c9), .noc_out_w(w_out_r0_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd0)
    ) u_core_r0_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[10]),
        .noc_in_n(io_in_top[703:640]), .noc_in_s(n_out_r1_c10), .noc_in_e(w_out_r0_c11), .noc_in_w(e_out_r0_c9),
        .noc_out_n(n_out_r0_c10), .noc_out_s(s_out_r0_c10), 
        .noc_out_e(e_out_r0_c10), .noc_out_w(w_out_r0_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd0)
    ) u_core_r0_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[11]),
        .noc_in_n(io_in_top[767:704]), .noc_in_s(n_out_r1_c11), .noc_in_e(w_out_r0_c12), .noc_in_w(e_out_r0_c10),
        .noc_out_n(n_out_r0_c11), .noc_out_s(s_out_r0_c11), 
        .noc_out_e(e_out_r0_c11), .noc_out_w(w_out_r0_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd0)
    ) u_core_r0_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[12]),
        .noc_in_n(io_in_top[831:768]), .noc_in_s(n_out_r1_c12), .noc_in_e(w_out_r0_c13), .noc_in_w(e_out_r0_c11),
        .noc_out_n(n_out_r0_c12), .noc_out_s(s_out_r0_c12), 
        .noc_out_e(e_out_r0_c12), .noc_out_w(w_out_r0_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd0)
    ) u_core_r0_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[13]),
        .noc_in_n(io_in_top[895:832]), .noc_in_s(n_out_r1_c13), .noc_in_e(w_out_r0_c14), .noc_in_w(e_out_r0_c12),
        .noc_out_n(n_out_r0_c13), .noc_out_s(s_out_r0_c13), 
        .noc_out_e(e_out_r0_c13), .noc_out_w(w_out_r0_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd0)
    ) u_core_r0_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[14]),
        .noc_in_n(io_in_top[959:896]), .noc_in_s(n_out_r1_c14), .noc_in_e(w_out_r0_c15), .noc_in_w(e_out_r0_c13),
        .noc_out_n(n_out_r0_c14), .noc_out_s(s_out_r0_c14), 
        .noc_out_e(e_out_r0_c14), .noc_out_w(w_out_r0_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd0)
    ) u_core_r0_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[15]),
        .noc_in_n(io_in_top[1023:960]), .noc_in_s(n_out_r1_c15), .noc_in_e(io_in_right[63:0]), .noc_in_w(e_out_r0_c14),
        .noc_out_n(n_out_r0_c15), .noc_out_s(s_out_r0_c15), 
        .noc_out_e(e_out_r0_c15), .noc_out_w(w_out_r0_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd1)
    ) u_core_r1_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[16]),
        .noc_in_n(s_out_r0_c0), .noc_in_s(n_out_r2_c0), .noc_in_e(w_out_r1_c1), .noc_in_w(io_in_left[127:64]),
        .noc_out_n(n_out_r1_c0), .noc_out_s(s_out_r1_c0), 
        .noc_out_e(e_out_r1_c0), .noc_out_w(w_out_r1_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd1)
    ) u_core_r1_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[17]),
        .noc_in_n(s_out_r0_c1), .noc_in_s(n_out_r2_c1), .noc_in_e(w_out_r1_c2), .noc_in_w(e_out_r1_c0),
        .noc_out_n(n_out_r1_c1), .noc_out_s(s_out_r1_c1), 
        .noc_out_e(e_out_r1_c1), .noc_out_w(w_out_r1_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd1)
    ) u_core_r1_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[18]),
        .noc_in_n(s_out_r0_c2), .noc_in_s(n_out_r2_c2), .noc_in_e(w_out_r1_c3), .noc_in_w(e_out_r1_c1),
        .noc_out_n(n_out_r1_c2), .noc_out_s(s_out_r1_c2), 
        .noc_out_e(e_out_r1_c2), .noc_out_w(w_out_r1_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd1)
    ) u_core_r1_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[19]),
        .noc_in_n(s_out_r0_c3), .noc_in_s(n_out_r2_c3), .noc_in_e(w_out_r1_c4), .noc_in_w(e_out_r1_c2),
        .noc_out_n(n_out_r1_c3), .noc_out_s(s_out_r1_c3), 
        .noc_out_e(e_out_r1_c3), .noc_out_w(w_out_r1_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd1)
    ) u_core_r1_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[20]),
        .noc_in_n(s_out_r0_c4), .noc_in_s(n_out_r2_c4), .noc_in_e(w_out_r1_c5), .noc_in_w(e_out_r1_c3),
        .noc_out_n(n_out_r1_c4), .noc_out_s(s_out_r1_c4), 
        .noc_out_e(e_out_r1_c4), .noc_out_w(w_out_r1_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd1)
    ) u_core_r1_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[21]),
        .noc_in_n(s_out_r0_c5), .noc_in_s(n_out_r2_c5), .noc_in_e(w_out_r1_c6), .noc_in_w(e_out_r1_c4),
        .noc_out_n(n_out_r1_c5), .noc_out_s(s_out_r1_c5), 
        .noc_out_e(e_out_r1_c5), .noc_out_w(w_out_r1_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd1)
    ) u_core_r1_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[22]),
        .noc_in_n(s_out_r0_c6), .noc_in_s(n_out_r2_c6), .noc_in_e(w_out_r1_c7), .noc_in_w(e_out_r1_c5),
        .noc_out_n(n_out_r1_c6), .noc_out_s(s_out_r1_c6), 
        .noc_out_e(e_out_r1_c6), .noc_out_w(w_out_r1_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd1)
    ) u_core_r1_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[23]),
        .noc_in_n(s_out_r0_c7), .noc_in_s(n_out_r2_c7), .noc_in_e(w_out_r1_c8), .noc_in_w(e_out_r1_c6),
        .noc_out_n(n_out_r1_c7), .noc_out_s(s_out_r1_c7), 
        .noc_out_e(e_out_r1_c7), .noc_out_w(w_out_r1_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd1)
    ) u_core_r1_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[24]),
        .noc_in_n(s_out_r0_c8), .noc_in_s(n_out_r2_c8), .noc_in_e(w_out_r1_c9), .noc_in_w(e_out_r1_c7),
        .noc_out_n(n_out_r1_c8), .noc_out_s(s_out_r1_c8), 
        .noc_out_e(e_out_r1_c8), .noc_out_w(w_out_r1_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd1)
    ) u_core_r1_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[25]),
        .noc_in_n(s_out_r0_c9), .noc_in_s(n_out_r2_c9), .noc_in_e(w_out_r1_c10), .noc_in_w(e_out_r1_c8),
        .noc_out_n(n_out_r1_c9), .noc_out_s(s_out_r1_c9), 
        .noc_out_e(e_out_r1_c9), .noc_out_w(w_out_r1_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd1)
    ) u_core_r1_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[26]),
        .noc_in_n(s_out_r0_c10), .noc_in_s(n_out_r2_c10), .noc_in_e(w_out_r1_c11), .noc_in_w(e_out_r1_c9),
        .noc_out_n(n_out_r1_c10), .noc_out_s(s_out_r1_c10), 
        .noc_out_e(e_out_r1_c10), .noc_out_w(w_out_r1_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd1)
    ) u_core_r1_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[27]),
        .noc_in_n(s_out_r0_c11), .noc_in_s(n_out_r2_c11), .noc_in_e(w_out_r1_c12), .noc_in_w(e_out_r1_c10),
        .noc_out_n(n_out_r1_c11), .noc_out_s(s_out_r1_c11), 
        .noc_out_e(e_out_r1_c11), .noc_out_w(w_out_r1_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd1)
    ) u_core_r1_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[28]),
        .noc_in_n(s_out_r0_c12), .noc_in_s(n_out_r2_c12), .noc_in_e(w_out_r1_c13), .noc_in_w(e_out_r1_c11),
        .noc_out_n(n_out_r1_c12), .noc_out_s(s_out_r1_c12), 
        .noc_out_e(e_out_r1_c12), .noc_out_w(w_out_r1_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd1)
    ) u_core_r1_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[29]),
        .noc_in_n(s_out_r0_c13), .noc_in_s(n_out_r2_c13), .noc_in_e(w_out_r1_c14), .noc_in_w(e_out_r1_c12),
        .noc_out_n(n_out_r1_c13), .noc_out_s(s_out_r1_c13), 
        .noc_out_e(e_out_r1_c13), .noc_out_w(w_out_r1_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd1)
    ) u_core_r1_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[30]),
        .noc_in_n(s_out_r0_c14), .noc_in_s(n_out_r2_c14), .noc_in_e(w_out_r1_c15), .noc_in_w(e_out_r1_c13),
        .noc_out_n(n_out_r1_c14), .noc_out_s(s_out_r1_c14), 
        .noc_out_e(e_out_r1_c14), .noc_out_w(w_out_r1_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd1)
    ) u_core_r1_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[31]),
        .noc_in_n(s_out_r0_c15), .noc_in_s(n_out_r2_c15), .noc_in_e(io_in_right[127:64]), .noc_in_w(e_out_r1_c14),
        .noc_out_n(n_out_r1_c15), .noc_out_s(s_out_r1_c15), 
        .noc_out_e(e_out_r1_c15), .noc_out_w(w_out_r1_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd2)
    ) u_core_r2_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[32]),
        .noc_in_n(s_out_r1_c0), .noc_in_s(n_out_r3_c0), .noc_in_e(w_out_r2_c1), .noc_in_w(io_in_left[191:128]),
        .noc_out_n(n_out_r2_c0), .noc_out_s(s_out_r2_c0), 
        .noc_out_e(e_out_r2_c0), .noc_out_w(w_out_r2_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd2)
    ) u_core_r2_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[33]),
        .noc_in_n(s_out_r1_c1), .noc_in_s(n_out_r3_c1), .noc_in_e(w_out_r2_c2), .noc_in_w(e_out_r2_c0),
        .noc_out_n(n_out_r2_c1), .noc_out_s(s_out_r2_c1), 
        .noc_out_e(e_out_r2_c1), .noc_out_w(w_out_r2_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd2)
    ) u_core_r2_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[34]),
        .noc_in_n(s_out_r1_c2), .noc_in_s(n_out_r3_c2), .noc_in_e(w_out_r2_c3), .noc_in_w(e_out_r2_c1),
        .noc_out_n(n_out_r2_c2), .noc_out_s(s_out_r2_c2), 
        .noc_out_e(e_out_r2_c2), .noc_out_w(w_out_r2_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd2)
    ) u_core_r2_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[35]),
        .noc_in_n(s_out_r1_c3), .noc_in_s(n_out_r3_c3), .noc_in_e(w_out_r2_c4), .noc_in_w(e_out_r2_c2),
        .noc_out_n(n_out_r2_c3), .noc_out_s(s_out_r2_c3), 
        .noc_out_e(e_out_r2_c3), .noc_out_w(w_out_r2_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd2)
    ) u_core_r2_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[36]),
        .noc_in_n(s_out_r1_c4), .noc_in_s(n_out_r3_c4), .noc_in_e(w_out_r2_c5), .noc_in_w(e_out_r2_c3),
        .noc_out_n(n_out_r2_c4), .noc_out_s(s_out_r2_c4), 
        .noc_out_e(e_out_r2_c4), .noc_out_w(w_out_r2_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd2)
    ) u_core_r2_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[37]),
        .noc_in_n(s_out_r1_c5), .noc_in_s(n_out_r3_c5), .noc_in_e(w_out_r2_c6), .noc_in_w(e_out_r2_c4),
        .noc_out_n(n_out_r2_c5), .noc_out_s(s_out_r2_c5), 
        .noc_out_e(e_out_r2_c5), .noc_out_w(w_out_r2_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd2)
    ) u_core_r2_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[38]),
        .noc_in_n(s_out_r1_c6), .noc_in_s(n_out_r3_c6), .noc_in_e(w_out_r2_c7), .noc_in_w(e_out_r2_c5),
        .noc_out_n(n_out_r2_c6), .noc_out_s(s_out_r2_c6), 
        .noc_out_e(e_out_r2_c6), .noc_out_w(w_out_r2_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd2)
    ) u_core_r2_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[39]),
        .noc_in_n(s_out_r1_c7), .noc_in_s(n_out_r3_c7), .noc_in_e(w_out_r2_c8), .noc_in_w(e_out_r2_c6),
        .noc_out_n(n_out_r2_c7), .noc_out_s(s_out_r2_c7), 
        .noc_out_e(e_out_r2_c7), .noc_out_w(w_out_r2_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd2)
    ) u_core_r2_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[40]),
        .noc_in_n(s_out_r1_c8), .noc_in_s(n_out_r3_c8), .noc_in_e(w_out_r2_c9), .noc_in_w(e_out_r2_c7),
        .noc_out_n(n_out_r2_c8), .noc_out_s(s_out_r2_c8), 
        .noc_out_e(e_out_r2_c8), .noc_out_w(w_out_r2_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd2)
    ) u_core_r2_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[41]),
        .noc_in_n(s_out_r1_c9), .noc_in_s(n_out_r3_c9), .noc_in_e(w_out_r2_c10), .noc_in_w(e_out_r2_c8),
        .noc_out_n(n_out_r2_c9), .noc_out_s(s_out_r2_c9), 
        .noc_out_e(e_out_r2_c9), .noc_out_w(w_out_r2_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd2)
    ) u_core_r2_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[42]),
        .noc_in_n(s_out_r1_c10), .noc_in_s(n_out_r3_c10), .noc_in_e(w_out_r2_c11), .noc_in_w(e_out_r2_c9),
        .noc_out_n(n_out_r2_c10), .noc_out_s(s_out_r2_c10), 
        .noc_out_e(e_out_r2_c10), .noc_out_w(w_out_r2_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd2)
    ) u_core_r2_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[43]),
        .noc_in_n(s_out_r1_c11), .noc_in_s(n_out_r3_c11), .noc_in_e(w_out_r2_c12), .noc_in_w(e_out_r2_c10),
        .noc_out_n(n_out_r2_c11), .noc_out_s(s_out_r2_c11), 
        .noc_out_e(e_out_r2_c11), .noc_out_w(w_out_r2_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd2)
    ) u_core_r2_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[44]),
        .noc_in_n(s_out_r1_c12), .noc_in_s(n_out_r3_c12), .noc_in_e(w_out_r2_c13), .noc_in_w(e_out_r2_c11),
        .noc_out_n(n_out_r2_c12), .noc_out_s(s_out_r2_c12), 
        .noc_out_e(e_out_r2_c12), .noc_out_w(w_out_r2_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd2)
    ) u_core_r2_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[45]),
        .noc_in_n(s_out_r1_c13), .noc_in_s(n_out_r3_c13), .noc_in_e(w_out_r2_c14), .noc_in_w(e_out_r2_c12),
        .noc_out_n(n_out_r2_c13), .noc_out_s(s_out_r2_c13), 
        .noc_out_e(e_out_r2_c13), .noc_out_w(w_out_r2_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd2)
    ) u_core_r2_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[46]),
        .noc_in_n(s_out_r1_c14), .noc_in_s(n_out_r3_c14), .noc_in_e(w_out_r2_c15), .noc_in_w(e_out_r2_c13),
        .noc_out_n(n_out_r2_c14), .noc_out_s(s_out_r2_c14), 
        .noc_out_e(e_out_r2_c14), .noc_out_w(w_out_r2_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd2)
    ) u_core_r2_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[47]),
        .noc_in_n(s_out_r1_c15), .noc_in_s(n_out_r3_c15), .noc_in_e(io_in_right[191:128]), .noc_in_w(e_out_r2_c14),
        .noc_out_n(n_out_r2_c15), .noc_out_s(s_out_r2_c15), 
        .noc_out_e(e_out_r2_c15), .noc_out_w(w_out_r2_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd3)
    ) u_core_r3_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[48]),
        .noc_in_n(s_out_r2_c0), .noc_in_s(n_out_r4_c0), .noc_in_e(w_out_r3_c1), .noc_in_w(io_in_left[255:192]),
        .noc_out_n(n_out_r3_c0), .noc_out_s(s_out_r3_c0), 
        .noc_out_e(e_out_r3_c0), .noc_out_w(w_out_r3_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd3)
    ) u_core_r3_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[49]),
        .noc_in_n(s_out_r2_c1), .noc_in_s(n_out_r4_c1), .noc_in_e(w_out_r3_c2), .noc_in_w(e_out_r3_c0),
        .noc_out_n(n_out_r3_c1), .noc_out_s(s_out_r3_c1), 
        .noc_out_e(e_out_r3_c1), .noc_out_w(w_out_r3_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd3)
    ) u_core_r3_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[50]),
        .noc_in_n(s_out_r2_c2), .noc_in_s(n_out_r4_c2), .noc_in_e(w_out_r3_c3), .noc_in_w(e_out_r3_c1),
        .noc_out_n(n_out_r3_c2), .noc_out_s(s_out_r3_c2), 
        .noc_out_e(e_out_r3_c2), .noc_out_w(w_out_r3_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd3)
    ) u_core_r3_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[51]),
        .noc_in_n(s_out_r2_c3), .noc_in_s(n_out_r4_c3), .noc_in_e(w_out_r3_c4), .noc_in_w(e_out_r3_c2),
        .noc_out_n(n_out_r3_c3), .noc_out_s(s_out_r3_c3), 
        .noc_out_e(e_out_r3_c3), .noc_out_w(w_out_r3_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd3)
    ) u_core_r3_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[52]),
        .noc_in_n(s_out_r2_c4), .noc_in_s(n_out_r4_c4), .noc_in_e(w_out_r3_c5), .noc_in_w(e_out_r3_c3),
        .noc_out_n(n_out_r3_c4), .noc_out_s(s_out_r3_c4), 
        .noc_out_e(e_out_r3_c4), .noc_out_w(w_out_r3_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd3)
    ) u_core_r3_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[53]),
        .noc_in_n(s_out_r2_c5), .noc_in_s(n_out_r4_c5), .noc_in_e(w_out_r3_c6), .noc_in_w(e_out_r3_c4),
        .noc_out_n(n_out_r3_c5), .noc_out_s(s_out_r3_c5), 
        .noc_out_e(e_out_r3_c5), .noc_out_w(w_out_r3_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd3)
    ) u_core_r3_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[54]),
        .noc_in_n(s_out_r2_c6), .noc_in_s(n_out_r4_c6), .noc_in_e(w_out_r3_c7), .noc_in_w(e_out_r3_c5),
        .noc_out_n(n_out_r3_c6), .noc_out_s(s_out_r3_c6), 
        .noc_out_e(e_out_r3_c6), .noc_out_w(w_out_r3_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd3)
    ) u_core_r3_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[55]),
        .noc_in_n(s_out_r2_c7), .noc_in_s(n_out_r4_c7), .noc_in_e(w_out_r3_c8), .noc_in_w(e_out_r3_c6),
        .noc_out_n(n_out_r3_c7), .noc_out_s(s_out_r3_c7), 
        .noc_out_e(e_out_r3_c7), .noc_out_w(w_out_r3_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd3)
    ) u_core_r3_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[56]),
        .noc_in_n(s_out_r2_c8), .noc_in_s(n_out_r4_c8), .noc_in_e(w_out_r3_c9), .noc_in_w(e_out_r3_c7),
        .noc_out_n(n_out_r3_c8), .noc_out_s(s_out_r3_c8), 
        .noc_out_e(e_out_r3_c8), .noc_out_w(w_out_r3_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd3)
    ) u_core_r3_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[57]),
        .noc_in_n(s_out_r2_c9), .noc_in_s(n_out_r4_c9), .noc_in_e(w_out_r3_c10), .noc_in_w(e_out_r3_c8),
        .noc_out_n(n_out_r3_c9), .noc_out_s(s_out_r3_c9), 
        .noc_out_e(e_out_r3_c9), .noc_out_w(w_out_r3_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd3)
    ) u_core_r3_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[58]),
        .noc_in_n(s_out_r2_c10), .noc_in_s(n_out_r4_c10), .noc_in_e(w_out_r3_c11), .noc_in_w(e_out_r3_c9),
        .noc_out_n(n_out_r3_c10), .noc_out_s(s_out_r3_c10), 
        .noc_out_e(e_out_r3_c10), .noc_out_w(w_out_r3_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd3)
    ) u_core_r3_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[59]),
        .noc_in_n(s_out_r2_c11), .noc_in_s(n_out_r4_c11), .noc_in_e(w_out_r3_c12), .noc_in_w(e_out_r3_c10),
        .noc_out_n(n_out_r3_c11), .noc_out_s(s_out_r3_c11), 
        .noc_out_e(e_out_r3_c11), .noc_out_w(w_out_r3_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd3)
    ) u_core_r3_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[60]),
        .noc_in_n(s_out_r2_c12), .noc_in_s(n_out_r4_c12), .noc_in_e(w_out_r3_c13), .noc_in_w(e_out_r3_c11),
        .noc_out_n(n_out_r3_c12), .noc_out_s(s_out_r3_c12), 
        .noc_out_e(e_out_r3_c12), .noc_out_w(w_out_r3_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd3)
    ) u_core_r3_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[61]),
        .noc_in_n(s_out_r2_c13), .noc_in_s(n_out_r4_c13), .noc_in_e(w_out_r3_c14), .noc_in_w(e_out_r3_c12),
        .noc_out_n(n_out_r3_c13), .noc_out_s(s_out_r3_c13), 
        .noc_out_e(e_out_r3_c13), .noc_out_w(w_out_r3_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd3)
    ) u_core_r3_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[62]),
        .noc_in_n(s_out_r2_c14), .noc_in_s(n_out_r4_c14), .noc_in_e(w_out_r3_c15), .noc_in_w(e_out_r3_c13),
        .noc_out_n(n_out_r3_c14), .noc_out_s(s_out_r3_c14), 
        .noc_out_e(e_out_r3_c14), .noc_out_w(w_out_r3_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd3)
    ) u_core_r3_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[63]),
        .noc_in_n(s_out_r2_c15), .noc_in_s(n_out_r4_c15), .noc_in_e(io_in_right[255:192]), .noc_in_w(e_out_r3_c14),
        .noc_out_n(n_out_r3_c15), .noc_out_s(s_out_r3_c15), 
        .noc_out_e(e_out_r3_c15), .noc_out_w(w_out_r3_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd4)
    ) u_core_r4_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[64]),
        .noc_in_n(s_out_r3_c0), .noc_in_s(n_out_r5_c0), .noc_in_e(w_out_r4_c1), .noc_in_w(io_in_left[319:256]),
        .noc_out_n(n_out_r4_c0), .noc_out_s(s_out_r4_c0), 
        .noc_out_e(e_out_r4_c0), .noc_out_w(w_out_r4_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd4)
    ) u_core_r4_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[65]),
        .noc_in_n(s_out_r3_c1), .noc_in_s(n_out_r5_c1), .noc_in_e(w_out_r4_c2), .noc_in_w(e_out_r4_c0),
        .noc_out_n(n_out_r4_c1), .noc_out_s(s_out_r4_c1), 
        .noc_out_e(e_out_r4_c1), .noc_out_w(w_out_r4_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd4)
    ) u_core_r4_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[66]),
        .noc_in_n(s_out_r3_c2), .noc_in_s(n_out_r5_c2), .noc_in_e(w_out_r4_c3), .noc_in_w(e_out_r4_c1),
        .noc_out_n(n_out_r4_c2), .noc_out_s(s_out_r4_c2), 
        .noc_out_e(e_out_r4_c2), .noc_out_w(w_out_r4_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd4)
    ) u_core_r4_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[67]),
        .noc_in_n(s_out_r3_c3), .noc_in_s(n_out_r5_c3), .noc_in_e(w_out_r4_c4), .noc_in_w(e_out_r4_c2),
        .noc_out_n(n_out_r4_c3), .noc_out_s(s_out_r4_c3), 
        .noc_out_e(e_out_r4_c3), .noc_out_w(w_out_r4_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd4)
    ) u_core_r4_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[68]),
        .noc_in_n(s_out_r3_c4), .noc_in_s(n_out_r5_c4), .noc_in_e(w_out_r4_c5), .noc_in_w(e_out_r4_c3),
        .noc_out_n(n_out_r4_c4), .noc_out_s(s_out_r4_c4), 
        .noc_out_e(e_out_r4_c4), .noc_out_w(w_out_r4_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd4)
    ) u_core_r4_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[69]),
        .noc_in_n(s_out_r3_c5), .noc_in_s(n_out_r5_c5), .noc_in_e(w_out_r4_c6), .noc_in_w(e_out_r4_c4),
        .noc_out_n(n_out_r4_c5), .noc_out_s(s_out_r4_c5), 
        .noc_out_e(e_out_r4_c5), .noc_out_w(w_out_r4_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd4)
    ) u_core_r4_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[70]),
        .noc_in_n(s_out_r3_c6), .noc_in_s(n_out_r5_c6), .noc_in_e(w_out_r4_c7), .noc_in_w(e_out_r4_c5),
        .noc_out_n(n_out_r4_c6), .noc_out_s(s_out_r4_c6), 
        .noc_out_e(e_out_r4_c6), .noc_out_w(w_out_r4_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd4)
    ) u_core_r4_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[71]),
        .noc_in_n(s_out_r3_c7), .noc_in_s(n_out_r5_c7), .noc_in_e(w_out_r4_c8), .noc_in_w(e_out_r4_c6),
        .noc_out_n(n_out_r4_c7), .noc_out_s(s_out_r4_c7), 
        .noc_out_e(e_out_r4_c7), .noc_out_w(w_out_r4_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd4)
    ) u_core_r4_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[72]),
        .noc_in_n(s_out_r3_c8), .noc_in_s(n_out_r5_c8), .noc_in_e(w_out_r4_c9), .noc_in_w(e_out_r4_c7),
        .noc_out_n(n_out_r4_c8), .noc_out_s(s_out_r4_c8), 
        .noc_out_e(e_out_r4_c8), .noc_out_w(w_out_r4_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd4)
    ) u_core_r4_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[73]),
        .noc_in_n(s_out_r3_c9), .noc_in_s(n_out_r5_c9), .noc_in_e(w_out_r4_c10), .noc_in_w(e_out_r4_c8),
        .noc_out_n(n_out_r4_c9), .noc_out_s(s_out_r4_c9), 
        .noc_out_e(e_out_r4_c9), .noc_out_w(w_out_r4_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd4)
    ) u_core_r4_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[74]),
        .noc_in_n(s_out_r3_c10), .noc_in_s(n_out_r5_c10), .noc_in_e(w_out_r4_c11), .noc_in_w(e_out_r4_c9),
        .noc_out_n(n_out_r4_c10), .noc_out_s(s_out_r4_c10), 
        .noc_out_e(e_out_r4_c10), .noc_out_w(w_out_r4_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd4)
    ) u_core_r4_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[75]),
        .noc_in_n(s_out_r3_c11), .noc_in_s(n_out_r5_c11), .noc_in_e(w_out_r4_c12), .noc_in_w(e_out_r4_c10),
        .noc_out_n(n_out_r4_c11), .noc_out_s(s_out_r4_c11), 
        .noc_out_e(e_out_r4_c11), .noc_out_w(w_out_r4_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd4)
    ) u_core_r4_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[76]),
        .noc_in_n(s_out_r3_c12), .noc_in_s(n_out_r5_c12), .noc_in_e(w_out_r4_c13), .noc_in_w(e_out_r4_c11),
        .noc_out_n(n_out_r4_c12), .noc_out_s(s_out_r4_c12), 
        .noc_out_e(e_out_r4_c12), .noc_out_w(w_out_r4_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd4)
    ) u_core_r4_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[77]),
        .noc_in_n(s_out_r3_c13), .noc_in_s(n_out_r5_c13), .noc_in_e(w_out_r4_c14), .noc_in_w(e_out_r4_c12),
        .noc_out_n(n_out_r4_c13), .noc_out_s(s_out_r4_c13), 
        .noc_out_e(e_out_r4_c13), .noc_out_w(w_out_r4_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd4)
    ) u_core_r4_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[78]),
        .noc_in_n(s_out_r3_c14), .noc_in_s(n_out_r5_c14), .noc_in_e(w_out_r4_c15), .noc_in_w(e_out_r4_c13),
        .noc_out_n(n_out_r4_c14), .noc_out_s(s_out_r4_c14), 
        .noc_out_e(e_out_r4_c14), .noc_out_w(w_out_r4_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd4)
    ) u_core_r4_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[79]),
        .noc_in_n(s_out_r3_c15), .noc_in_s(n_out_r5_c15), .noc_in_e(io_in_right[319:256]), .noc_in_w(e_out_r4_c14),
        .noc_out_n(n_out_r4_c15), .noc_out_s(s_out_r4_c15), 
        .noc_out_e(e_out_r4_c15), .noc_out_w(w_out_r4_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd5)
    ) u_core_r5_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[80]),
        .noc_in_n(s_out_r4_c0), .noc_in_s(n_out_r6_c0), .noc_in_e(w_out_r5_c1), .noc_in_w(io_in_left[383:320]),
        .noc_out_n(n_out_r5_c0), .noc_out_s(s_out_r5_c0), 
        .noc_out_e(e_out_r5_c0), .noc_out_w(w_out_r5_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd5)
    ) u_core_r5_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[81]),
        .noc_in_n(s_out_r4_c1), .noc_in_s(n_out_r6_c1), .noc_in_e(w_out_r5_c2), .noc_in_w(e_out_r5_c0),
        .noc_out_n(n_out_r5_c1), .noc_out_s(s_out_r5_c1), 
        .noc_out_e(e_out_r5_c1), .noc_out_w(w_out_r5_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd5)
    ) u_core_r5_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[82]),
        .noc_in_n(s_out_r4_c2), .noc_in_s(n_out_r6_c2), .noc_in_e(w_out_r5_c3), .noc_in_w(e_out_r5_c1),
        .noc_out_n(n_out_r5_c2), .noc_out_s(s_out_r5_c2), 
        .noc_out_e(e_out_r5_c2), .noc_out_w(w_out_r5_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd5)
    ) u_core_r5_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[83]),
        .noc_in_n(s_out_r4_c3), .noc_in_s(n_out_r6_c3), .noc_in_e(w_out_r5_c4), .noc_in_w(e_out_r5_c2),
        .noc_out_n(n_out_r5_c3), .noc_out_s(s_out_r5_c3), 
        .noc_out_e(e_out_r5_c3), .noc_out_w(w_out_r5_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd5)
    ) u_core_r5_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[84]),
        .noc_in_n(s_out_r4_c4), .noc_in_s(n_out_r6_c4), .noc_in_e(w_out_r5_c5), .noc_in_w(e_out_r5_c3),
        .noc_out_n(n_out_r5_c4), .noc_out_s(s_out_r5_c4), 
        .noc_out_e(e_out_r5_c4), .noc_out_w(w_out_r5_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd5)
    ) u_core_r5_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[85]),
        .noc_in_n(s_out_r4_c5), .noc_in_s(n_out_r6_c5), .noc_in_e(w_out_r5_c6), .noc_in_w(e_out_r5_c4),
        .noc_out_n(n_out_r5_c5), .noc_out_s(s_out_r5_c5), 
        .noc_out_e(e_out_r5_c5), .noc_out_w(w_out_r5_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd5)
    ) u_core_r5_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[86]),
        .noc_in_n(s_out_r4_c6), .noc_in_s(n_out_r6_c6), .noc_in_e(w_out_r5_c7), .noc_in_w(e_out_r5_c5),
        .noc_out_n(n_out_r5_c6), .noc_out_s(s_out_r5_c6), 
        .noc_out_e(e_out_r5_c6), .noc_out_w(w_out_r5_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd5)
    ) u_core_r5_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[87]),
        .noc_in_n(s_out_r4_c7), .noc_in_s(n_out_r6_c7), .noc_in_e(w_out_r5_c8), .noc_in_w(e_out_r5_c6),
        .noc_out_n(n_out_r5_c7), .noc_out_s(s_out_r5_c7), 
        .noc_out_e(e_out_r5_c7), .noc_out_w(w_out_r5_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd5)
    ) u_core_r5_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[88]),
        .noc_in_n(s_out_r4_c8), .noc_in_s(n_out_r6_c8), .noc_in_e(w_out_r5_c9), .noc_in_w(e_out_r5_c7),
        .noc_out_n(n_out_r5_c8), .noc_out_s(s_out_r5_c8), 
        .noc_out_e(e_out_r5_c8), .noc_out_w(w_out_r5_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd5)
    ) u_core_r5_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[89]),
        .noc_in_n(s_out_r4_c9), .noc_in_s(n_out_r6_c9), .noc_in_e(w_out_r5_c10), .noc_in_w(e_out_r5_c8),
        .noc_out_n(n_out_r5_c9), .noc_out_s(s_out_r5_c9), 
        .noc_out_e(e_out_r5_c9), .noc_out_w(w_out_r5_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd5)
    ) u_core_r5_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[90]),
        .noc_in_n(s_out_r4_c10), .noc_in_s(n_out_r6_c10), .noc_in_e(w_out_r5_c11), .noc_in_w(e_out_r5_c9),
        .noc_out_n(n_out_r5_c10), .noc_out_s(s_out_r5_c10), 
        .noc_out_e(e_out_r5_c10), .noc_out_w(w_out_r5_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd5)
    ) u_core_r5_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[91]),
        .noc_in_n(s_out_r4_c11), .noc_in_s(n_out_r6_c11), .noc_in_e(w_out_r5_c12), .noc_in_w(e_out_r5_c10),
        .noc_out_n(n_out_r5_c11), .noc_out_s(s_out_r5_c11), 
        .noc_out_e(e_out_r5_c11), .noc_out_w(w_out_r5_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd5)
    ) u_core_r5_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[92]),
        .noc_in_n(s_out_r4_c12), .noc_in_s(n_out_r6_c12), .noc_in_e(w_out_r5_c13), .noc_in_w(e_out_r5_c11),
        .noc_out_n(n_out_r5_c12), .noc_out_s(s_out_r5_c12), 
        .noc_out_e(e_out_r5_c12), .noc_out_w(w_out_r5_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd5)
    ) u_core_r5_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[93]),
        .noc_in_n(s_out_r4_c13), .noc_in_s(n_out_r6_c13), .noc_in_e(w_out_r5_c14), .noc_in_w(e_out_r5_c12),
        .noc_out_n(n_out_r5_c13), .noc_out_s(s_out_r5_c13), 
        .noc_out_e(e_out_r5_c13), .noc_out_w(w_out_r5_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd5)
    ) u_core_r5_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[94]),
        .noc_in_n(s_out_r4_c14), .noc_in_s(n_out_r6_c14), .noc_in_e(w_out_r5_c15), .noc_in_w(e_out_r5_c13),
        .noc_out_n(n_out_r5_c14), .noc_out_s(s_out_r5_c14), 
        .noc_out_e(e_out_r5_c14), .noc_out_w(w_out_r5_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd5)
    ) u_core_r5_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[95]),
        .noc_in_n(s_out_r4_c15), .noc_in_s(n_out_r6_c15), .noc_in_e(io_in_right[383:320]), .noc_in_w(e_out_r5_c14),
        .noc_out_n(n_out_r5_c15), .noc_out_s(s_out_r5_c15), 
        .noc_out_e(e_out_r5_c15), .noc_out_w(w_out_r5_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd6)
    ) u_core_r6_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[96]),
        .noc_in_n(s_out_r5_c0), .noc_in_s(n_out_r7_c0), .noc_in_e(w_out_r6_c1), .noc_in_w(io_in_left[447:384]),
        .noc_out_n(n_out_r6_c0), .noc_out_s(s_out_r6_c0), 
        .noc_out_e(e_out_r6_c0), .noc_out_w(w_out_r6_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd6)
    ) u_core_r6_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[97]),
        .noc_in_n(s_out_r5_c1), .noc_in_s(n_out_r7_c1), .noc_in_e(w_out_r6_c2), .noc_in_w(e_out_r6_c0),
        .noc_out_n(n_out_r6_c1), .noc_out_s(s_out_r6_c1), 
        .noc_out_e(e_out_r6_c1), .noc_out_w(w_out_r6_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd6)
    ) u_core_r6_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[98]),
        .noc_in_n(s_out_r5_c2), .noc_in_s(n_out_r7_c2), .noc_in_e(w_out_r6_c3), .noc_in_w(e_out_r6_c1),
        .noc_out_n(n_out_r6_c2), .noc_out_s(s_out_r6_c2), 
        .noc_out_e(e_out_r6_c2), .noc_out_w(w_out_r6_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd6)
    ) u_core_r6_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[99]),
        .noc_in_n(s_out_r5_c3), .noc_in_s(n_out_r7_c3), .noc_in_e(w_out_r6_c4), .noc_in_w(e_out_r6_c2),
        .noc_out_n(n_out_r6_c3), .noc_out_s(s_out_r6_c3), 
        .noc_out_e(e_out_r6_c3), .noc_out_w(w_out_r6_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd6)
    ) u_core_r6_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[100]),
        .noc_in_n(s_out_r5_c4), .noc_in_s(n_out_r7_c4), .noc_in_e(w_out_r6_c5), .noc_in_w(e_out_r6_c3),
        .noc_out_n(n_out_r6_c4), .noc_out_s(s_out_r6_c4), 
        .noc_out_e(e_out_r6_c4), .noc_out_w(w_out_r6_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd6)
    ) u_core_r6_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[101]),
        .noc_in_n(s_out_r5_c5), .noc_in_s(n_out_r7_c5), .noc_in_e(w_out_r6_c6), .noc_in_w(e_out_r6_c4),
        .noc_out_n(n_out_r6_c5), .noc_out_s(s_out_r6_c5), 
        .noc_out_e(e_out_r6_c5), .noc_out_w(w_out_r6_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd6)
    ) u_core_r6_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[102]),
        .noc_in_n(s_out_r5_c6), .noc_in_s(n_out_r7_c6), .noc_in_e(w_out_r6_c7), .noc_in_w(e_out_r6_c5),
        .noc_out_n(n_out_r6_c6), .noc_out_s(s_out_r6_c6), 
        .noc_out_e(e_out_r6_c6), .noc_out_w(w_out_r6_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd6)
    ) u_core_r6_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[103]),
        .noc_in_n(s_out_r5_c7), .noc_in_s(n_out_r7_c7), .noc_in_e(w_out_r6_c8), .noc_in_w(e_out_r6_c6),
        .noc_out_n(n_out_r6_c7), .noc_out_s(s_out_r6_c7), 
        .noc_out_e(e_out_r6_c7), .noc_out_w(w_out_r6_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd6)
    ) u_core_r6_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[104]),
        .noc_in_n(s_out_r5_c8), .noc_in_s(n_out_r7_c8), .noc_in_e(w_out_r6_c9), .noc_in_w(e_out_r6_c7),
        .noc_out_n(n_out_r6_c8), .noc_out_s(s_out_r6_c8), 
        .noc_out_e(e_out_r6_c8), .noc_out_w(w_out_r6_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd6)
    ) u_core_r6_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[105]),
        .noc_in_n(s_out_r5_c9), .noc_in_s(n_out_r7_c9), .noc_in_e(w_out_r6_c10), .noc_in_w(e_out_r6_c8),
        .noc_out_n(n_out_r6_c9), .noc_out_s(s_out_r6_c9), 
        .noc_out_e(e_out_r6_c9), .noc_out_w(w_out_r6_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd6)
    ) u_core_r6_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[106]),
        .noc_in_n(s_out_r5_c10), .noc_in_s(n_out_r7_c10), .noc_in_e(w_out_r6_c11), .noc_in_w(e_out_r6_c9),
        .noc_out_n(n_out_r6_c10), .noc_out_s(s_out_r6_c10), 
        .noc_out_e(e_out_r6_c10), .noc_out_w(w_out_r6_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd6)
    ) u_core_r6_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[107]),
        .noc_in_n(s_out_r5_c11), .noc_in_s(n_out_r7_c11), .noc_in_e(w_out_r6_c12), .noc_in_w(e_out_r6_c10),
        .noc_out_n(n_out_r6_c11), .noc_out_s(s_out_r6_c11), 
        .noc_out_e(e_out_r6_c11), .noc_out_w(w_out_r6_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd6)
    ) u_core_r6_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[108]),
        .noc_in_n(s_out_r5_c12), .noc_in_s(n_out_r7_c12), .noc_in_e(w_out_r6_c13), .noc_in_w(e_out_r6_c11),
        .noc_out_n(n_out_r6_c12), .noc_out_s(s_out_r6_c12), 
        .noc_out_e(e_out_r6_c12), .noc_out_w(w_out_r6_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd6)
    ) u_core_r6_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[109]),
        .noc_in_n(s_out_r5_c13), .noc_in_s(n_out_r7_c13), .noc_in_e(w_out_r6_c14), .noc_in_w(e_out_r6_c12),
        .noc_out_n(n_out_r6_c13), .noc_out_s(s_out_r6_c13), 
        .noc_out_e(e_out_r6_c13), .noc_out_w(w_out_r6_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd6)
    ) u_core_r6_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[110]),
        .noc_in_n(s_out_r5_c14), .noc_in_s(n_out_r7_c14), .noc_in_e(w_out_r6_c15), .noc_in_w(e_out_r6_c13),
        .noc_out_n(n_out_r6_c14), .noc_out_s(s_out_r6_c14), 
        .noc_out_e(e_out_r6_c14), .noc_out_w(w_out_r6_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd6)
    ) u_core_r6_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[111]),
        .noc_in_n(s_out_r5_c15), .noc_in_s(n_out_r7_c15), .noc_in_e(io_in_right[447:384]), .noc_in_w(e_out_r6_c14),
        .noc_out_n(n_out_r6_c15), .noc_out_s(s_out_r6_c15), 
        .noc_out_e(e_out_r6_c15), .noc_out_w(w_out_r6_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd7)
    ) u_core_r7_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[112]),
        .noc_in_n(s_out_r6_c0), .noc_in_s(n_out_r8_c0), .noc_in_e(w_out_r7_c1), .noc_in_w(io_in_left[511:448]),
        .noc_out_n(n_out_r7_c0), .noc_out_s(s_out_r7_c0), 
        .noc_out_e(e_out_r7_c0), .noc_out_w(w_out_r7_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd7)
    ) u_core_r7_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[113]),
        .noc_in_n(s_out_r6_c1), .noc_in_s(n_out_r8_c1), .noc_in_e(w_out_r7_c2), .noc_in_w(e_out_r7_c0),
        .noc_out_n(n_out_r7_c1), .noc_out_s(s_out_r7_c1), 
        .noc_out_e(e_out_r7_c1), .noc_out_w(w_out_r7_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd7)
    ) u_core_r7_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[114]),
        .noc_in_n(s_out_r6_c2), .noc_in_s(n_out_r8_c2), .noc_in_e(w_out_r7_c3), .noc_in_w(e_out_r7_c1),
        .noc_out_n(n_out_r7_c2), .noc_out_s(s_out_r7_c2), 
        .noc_out_e(e_out_r7_c2), .noc_out_w(w_out_r7_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd7)
    ) u_core_r7_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[115]),
        .noc_in_n(s_out_r6_c3), .noc_in_s(n_out_r8_c3), .noc_in_e(w_out_r7_c4), .noc_in_w(e_out_r7_c2),
        .noc_out_n(n_out_r7_c3), .noc_out_s(s_out_r7_c3), 
        .noc_out_e(e_out_r7_c3), .noc_out_w(w_out_r7_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd7)
    ) u_core_r7_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[116]),
        .noc_in_n(s_out_r6_c4), .noc_in_s(n_out_r8_c4), .noc_in_e(w_out_r7_c5), .noc_in_w(e_out_r7_c3),
        .noc_out_n(n_out_r7_c4), .noc_out_s(s_out_r7_c4), 
        .noc_out_e(e_out_r7_c4), .noc_out_w(w_out_r7_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd7)
    ) u_core_r7_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[117]),
        .noc_in_n(s_out_r6_c5), .noc_in_s(n_out_r8_c5), .noc_in_e(w_out_r7_c6), .noc_in_w(e_out_r7_c4),
        .noc_out_n(n_out_r7_c5), .noc_out_s(s_out_r7_c5), 
        .noc_out_e(e_out_r7_c5), .noc_out_w(w_out_r7_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd7)
    ) u_core_r7_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[118]),
        .noc_in_n(s_out_r6_c6), .noc_in_s(n_out_r8_c6), .noc_in_e(w_out_r7_c7), .noc_in_w(e_out_r7_c5),
        .noc_out_n(n_out_r7_c6), .noc_out_s(s_out_r7_c6), 
        .noc_out_e(e_out_r7_c6), .noc_out_w(w_out_r7_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd7)
    ) u_core_r7_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[119]),
        .noc_in_n(s_out_r6_c7), .noc_in_s(n_out_r8_c7), .noc_in_e(w_out_r7_c8), .noc_in_w(e_out_r7_c6),
        .noc_out_n(n_out_r7_c7), .noc_out_s(s_out_r7_c7), 
        .noc_out_e(e_out_r7_c7), .noc_out_w(w_out_r7_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd7)
    ) u_core_r7_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[120]),
        .noc_in_n(s_out_r6_c8), .noc_in_s(n_out_r8_c8), .noc_in_e(w_out_r7_c9), .noc_in_w(e_out_r7_c7),
        .noc_out_n(n_out_r7_c8), .noc_out_s(s_out_r7_c8), 
        .noc_out_e(e_out_r7_c8), .noc_out_w(w_out_r7_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd7)
    ) u_core_r7_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[121]),
        .noc_in_n(s_out_r6_c9), .noc_in_s(n_out_r8_c9), .noc_in_e(w_out_r7_c10), .noc_in_w(e_out_r7_c8),
        .noc_out_n(n_out_r7_c9), .noc_out_s(s_out_r7_c9), 
        .noc_out_e(e_out_r7_c9), .noc_out_w(w_out_r7_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd7)
    ) u_core_r7_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[122]),
        .noc_in_n(s_out_r6_c10), .noc_in_s(n_out_r8_c10), .noc_in_e(w_out_r7_c11), .noc_in_w(e_out_r7_c9),
        .noc_out_n(n_out_r7_c10), .noc_out_s(s_out_r7_c10), 
        .noc_out_e(e_out_r7_c10), .noc_out_w(w_out_r7_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd7)
    ) u_core_r7_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[123]),
        .noc_in_n(s_out_r6_c11), .noc_in_s(n_out_r8_c11), .noc_in_e(w_out_r7_c12), .noc_in_w(e_out_r7_c10),
        .noc_out_n(n_out_r7_c11), .noc_out_s(s_out_r7_c11), 
        .noc_out_e(e_out_r7_c11), .noc_out_w(w_out_r7_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd7)
    ) u_core_r7_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[124]),
        .noc_in_n(s_out_r6_c12), .noc_in_s(n_out_r8_c12), .noc_in_e(w_out_r7_c13), .noc_in_w(e_out_r7_c11),
        .noc_out_n(n_out_r7_c12), .noc_out_s(s_out_r7_c12), 
        .noc_out_e(e_out_r7_c12), .noc_out_w(w_out_r7_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd7)
    ) u_core_r7_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[125]),
        .noc_in_n(s_out_r6_c13), .noc_in_s(n_out_r8_c13), .noc_in_e(w_out_r7_c14), .noc_in_w(e_out_r7_c12),
        .noc_out_n(n_out_r7_c13), .noc_out_s(s_out_r7_c13), 
        .noc_out_e(e_out_r7_c13), .noc_out_w(w_out_r7_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd7)
    ) u_core_r7_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[126]),
        .noc_in_n(s_out_r6_c14), .noc_in_s(n_out_r8_c14), .noc_in_e(w_out_r7_c15), .noc_in_w(e_out_r7_c13),
        .noc_out_n(n_out_r7_c14), .noc_out_s(s_out_r7_c14), 
        .noc_out_e(e_out_r7_c14), .noc_out_w(w_out_r7_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd7)
    ) u_core_r7_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[127]),
        .noc_in_n(s_out_r6_c15), .noc_in_s(n_out_r8_c15), .noc_in_e(io_in_right[511:448]), .noc_in_w(e_out_r7_c14),
        .noc_out_n(n_out_r7_c15), .noc_out_s(s_out_r7_c15), 
        .noc_out_e(e_out_r7_c15), .noc_out_w(w_out_r7_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd8)
    ) u_core_r8_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[128]),
        .noc_in_n(s_out_r7_c0), .noc_in_s(n_out_r9_c0), .noc_in_e(w_out_r8_c1), .noc_in_w(io_in_left[575:512]),
        .noc_out_n(n_out_r8_c0), .noc_out_s(s_out_r8_c0), 
        .noc_out_e(e_out_r8_c0), .noc_out_w(w_out_r8_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd8)
    ) u_core_r8_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[129]),
        .noc_in_n(s_out_r7_c1), .noc_in_s(n_out_r9_c1), .noc_in_e(w_out_r8_c2), .noc_in_w(e_out_r8_c0),
        .noc_out_n(n_out_r8_c1), .noc_out_s(s_out_r8_c1), 
        .noc_out_e(e_out_r8_c1), .noc_out_w(w_out_r8_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd8)
    ) u_core_r8_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[130]),
        .noc_in_n(s_out_r7_c2), .noc_in_s(n_out_r9_c2), .noc_in_e(w_out_r8_c3), .noc_in_w(e_out_r8_c1),
        .noc_out_n(n_out_r8_c2), .noc_out_s(s_out_r8_c2), 
        .noc_out_e(e_out_r8_c2), .noc_out_w(w_out_r8_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd8)
    ) u_core_r8_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[131]),
        .noc_in_n(s_out_r7_c3), .noc_in_s(n_out_r9_c3), .noc_in_e(w_out_r8_c4), .noc_in_w(e_out_r8_c2),
        .noc_out_n(n_out_r8_c3), .noc_out_s(s_out_r8_c3), 
        .noc_out_e(e_out_r8_c3), .noc_out_w(w_out_r8_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd8)
    ) u_core_r8_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[132]),
        .noc_in_n(s_out_r7_c4), .noc_in_s(n_out_r9_c4), .noc_in_e(w_out_r8_c5), .noc_in_w(e_out_r8_c3),
        .noc_out_n(n_out_r8_c4), .noc_out_s(s_out_r8_c4), 
        .noc_out_e(e_out_r8_c4), .noc_out_w(w_out_r8_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd8)
    ) u_core_r8_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[133]),
        .noc_in_n(s_out_r7_c5), .noc_in_s(n_out_r9_c5), .noc_in_e(w_out_r8_c6), .noc_in_w(e_out_r8_c4),
        .noc_out_n(n_out_r8_c5), .noc_out_s(s_out_r8_c5), 
        .noc_out_e(e_out_r8_c5), .noc_out_w(w_out_r8_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd8)
    ) u_core_r8_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[134]),
        .noc_in_n(s_out_r7_c6), .noc_in_s(n_out_r9_c6), .noc_in_e(w_out_r8_c7), .noc_in_w(e_out_r8_c5),
        .noc_out_n(n_out_r8_c6), .noc_out_s(s_out_r8_c6), 
        .noc_out_e(e_out_r8_c6), .noc_out_w(w_out_r8_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd8)
    ) u_core_r8_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[135]),
        .noc_in_n(s_out_r7_c7), .noc_in_s(n_out_r9_c7), .noc_in_e(w_out_r8_c8), .noc_in_w(e_out_r8_c6),
        .noc_out_n(n_out_r8_c7), .noc_out_s(s_out_r8_c7), 
        .noc_out_e(e_out_r8_c7), .noc_out_w(w_out_r8_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd8)
    ) u_core_r8_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[136]),
        .noc_in_n(s_out_r7_c8), .noc_in_s(n_out_r9_c8), .noc_in_e(w_out_r8_c9), .noc_in_w(e_out_r8_c7),
        .noc_out_n(n_out_r8_c8), .noc_out_s(s_out_r8_c8), 
        .noc_out_e(e_out_r8_c8), .noc_out_w(w_out_r8_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd8)
    ) u_core_r8_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[137]),
        .noc_in_n(s_out_r7_c9), .noc_in_s(n_out_r9_c9), .noc_in_e(w_out_r8_c10), .noc_in_w(e_out_r8_c8),
        .noc_out_n(n_out_r8_c9), .noc_out_s(s_out_r8_c9), 
        .noc_out_e(e_out_r8_c9), .noc_out_w(w_out_r8_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd8)
    ) u_core_r8_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[138]),
        .noc_in_n(s_out_r7_c10), .noc_in_s(n_out_r9_c10), .noc_in_e(w_out_r8_c11), .noc_in_w(e_out_r8_c9),
        .noc_out_n(n_out_r8_c10), .noc_out_s(s_out_r8_c10), 
        .noc_out_e(e_out_r8_c10), .noc_out_w(w_out_r8_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd8)
    ) u_core_r8_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[139]),
        .noc_in_n(s_out_r7_c11), .noc_in_s(n_out_r9_c11), .noc_in_e(w_out_r8_c12), .noc_in_w(e_out_r8_c10),
        .noc_out_n(n_out_r8_c11), .noc_out_s(s_out_r8_c11), 
        .noc_out_e(e_out_r8_c11), .noc_out_w(w_out_r8_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd8)
    ) u_core_r8_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[140]),
        .noc_in_n(s_out_r7_c12), .noc_in_s(n_out_r9_c12), .noc_in_e(w_out_r8_c13), .noc_in_w(e_out_r8_c11),
        .noc_out_n(n_out_r8_c12), .noc_out_s(s_out_r8_c12), 
        .noc_out_e(e_out_r8_c12), .noc_out_w(w_out_r8_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd8)
    ) u_core_r8_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[141]),
        .noc_in_n(s_out_r7_c13), .noc_in_s(n_out_r9_c13), .noc_in_e(w_out_r8_c14), .noc_in_w(e_out_r8_c12),
        .noc_out_n(n_out_r8_c13), .noc_out_s(s_out_r8_c13), 
        .noc_out_e(e_out_r8_c13), .noc_out_w(w_out_r8_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd8)
    ) u_core_r8_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[142]),
        .noc_in_n(s_out_r7_c14), .noc_in_s(n_out_r9_c14), .noc_in_e(w_out_r8_c15), .noc_in_w(e_out_r8_c13),
        .noc_out_n(n_out_r8_c14), .noc_out_s(s_out_r8_c14), 
        .noc_out_e(e_out_r8_c14), .noc_out_w(w_out_r8_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd8)
    ) u_core_r8_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[143]),
        .noc_in_n(s_out_r7_c15), .noc_in_s(n_out_r9_c15), .noc_in_e(io_in_right[575:512]), .noc_in_w(e_out_r8_c14),
        .noc_out_n(n_out_r8_c15), .noc_out_s(s_out_r8_c15), 
        .noc_out_e(e_out_r8_c15), .noc_out_w(w_out_r8_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd9)
    ) u_core_r9_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[144]),
        .noc_in_n(s_out_r8_c0), .noc_in_s(n_out_r10_c0), .noc_in_e(w_out_r9_c1), .noc_in_w(io_in_left[639:576]),
        .noc_out_n(n_out_r9_c0), .noc_out_s(s_out_r9_c0), 
        .noc_out_e(e_out_r9_c0), .noc_out_w(w_out_r9_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd9)
    ) u_core_r9_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[145]),
        .noc_in_n(s_out_r8_c1), .noc_in_s(n_out_r10_c1), .noc_in_e(w_out_r9_c2), .noc_in_w(e_out_r9_c0),
        .noc_out_n(n_out_r9_c1), .noc_out_s(s_out_r9_c1), 
        .noc_out_e(e_out_r9_c1), .noc_out_w(w_out_r9_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd9)
    ) u_core_r9_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[146]),
        .noc_in_n(s_out_r8_c2), .noc_in_s(n_out_r10_c2), .noc_in_e(w_out_r9_c3), .noc_in_w(e_out_r9_c1),
        .noc_out_n(n_out_r9_c2), .noc_out_s(s_out_r9_c2), 
        .noc_out_e(e_out_r9_c2), .noc_out_w(w_out_r9_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd9)
    ) u_core_r9_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[147]),
        .noc_in_n(s_out_r8_c3), .noc_in_s(n_out_r10_c3), .noc_in_e(w_out_r9_c4), .noc_in_w(e_out_r9_c2),
        .noc_out_n(n_out_r9_c3), .noc_out_s(s_out_r9_c3), 
        .noc_out_e(e_out_r9_c3), .noc_out_w(w_out_r9_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd9)
    ) u_core_r9_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[148]),
        .noc_in_n(s_out_r8_c4), .noc_in_s(n_out_r10_c4), .noc_in_e(w_out_r9_c5), .noc_in_w(e_out_r9_c3),
        .noc_out_n(n_out_r9_c4), .noc_out_s(s_out_r9_c4), 
        .noc_out_e(e_out_r9_c4), .noc_out_w(w_out_r9_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd9)
    ) u_core_r9_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[149]),
        .noc_in_n(s_out_r8_c5), .noc_in_s(n_out_r10_c5), .noc_in_e(w_out_r9_c6), .noc_in_w(e_out_r9_c4),
        .noc_out_n(n_out_r9_c5), .noc_out_s(s_out_r9_c5), 
        .noc_out_e(e_out_r9_c5), .noc_out_w(w_out_r9_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd9)
    ) u_core_r9_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[150]),
        .noc_in_n(s_out_r8_c6), .noc_in_s(n_out_r10_c6), .noc_in_e(w_out_r9_c7), .noc_in_w(e_out_r9_c5),
        .noc_out_n(n_out_r9_c6), .noc_out_s(s_out_r9_c6), 
        .noc_out_e(e_out_r9_c6), .noc_out_w(w_out_r9_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd9)
    ) u_core_r9_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[151]),
        .noc_in_n(s_out_r8_c7), .noc_in_s(n_out_r10_c7), .noc_in_e(w_out_r9_c8), .noc_in_w(e_out_r9_c6),
        .noc_out_n(n_out_r9_c7), .noc_out_s(s_out_r9_c7), 
        .noc_out_e(e_out_r9_c7), .noc_out_w(w_out_r9_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd9)
    ) u_core_r9_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[152]),
        .noc_in_n(s_out_r8_c8), .noc_in_s(n_out_r10_c8), .noc_in_e(w_out_r9_c9), .noc_in_w(e_out_r9_c7),
        .noc_out_n(n_out_r9_c8), .noc_out_s(s_out_r9_c8), 
        .noc_out_e(e_out_r9_c8), .noc_out_w(w_out_r9_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd9)
    ) u_core_r9_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[153]),
        .noc_in_n(s_out_r8_c9), .noc_in_s(n_out_r10_c9), .noc_in_e(w_out_r9_c10), .noc_in_w(e_out_r9_c8),
        .noc_out_n(n_out_r9_c9), .noc_out_s(s_out_r9_c9), 
        .noc_out_e(e_out_r9_c9), .noc_out_w(w_out_r9_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd9)
    ) u_core_r9_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[154]),
        .noc_in_n(s_out_r8_c10), .noc_in_s(n_out_r10_c10), .noc_in_e(w_out_r9_c11), .noc_in_w(e_out_r9_c9),
        .noc_out_n(n_out_r9_c10), .noc_out_s(s_out_r9_c10), 
        .noc_out_e(e_out_r9_c10), .noc_out_w(w_out_r9_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd9)
    ) u_core_r9_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[155]),
        .noc_in_n(s_out_r8_c11), .noc_in_s(n_out_r10_c11), .noc_in_e(w_out_r9_c12), .noc_in_w(e_out_r9_c10),
        .noc_out_n(n_out_r9_c11), .noc_out_s(s_out_r9_c11), 
        .noc_out_e(e_out_r9_c11), .noc_out_w(w_out_r9_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd9)
    ) u_core_r9_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[156]),
        .noc_in_n(s_out_r8_c12), .noc_in_s(n_out_r10_c12), .noc_in_e(w_out_r9_c13), .noc_in_w(e_out_r9_c11),
        .noc_out_n(n_out_r9_c12), .noc_out_s(s_out_r9_c12), 
        .noc_out_e(e_out_r9_c12), .noc_out_w(w_out_r9_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd9)
    ) u_core_r9_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[157]),
        .noc_in_n(s_out_r8_c13), .noc_in_s(n_out_r10_c13), .noc_in_e(w_out_r9_c14), .noc_in_w(e_out_r9_c12),
        .noc_out_n(n_out_r9_c13), .noc_out_s(s_out_r9_c13), 
        .noc_out_e(e_out_r9_c13), .noc_out_w(w_out_r9_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd9)
    ) u_core_r9_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[158]),
        .noc_in_n(s_out_r8_c14), .noc_in_s(n_out_r10_c14), .noc_in_e(w_out_r9_c15), .noc_in_w(e_out_r9_c13),
        .noc_out_n(n_out_r9_c14), .noc_out_s(s_out_r9_c14), 
        .noc_out_e(e_out_r9_c14), .noc_out_w(w_out_r9_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd9)
    ) u_core_r9_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[159]),
        .noc_in_n(s_out_r8_c15), .noc_in_s(n_out_r10_c15), .noc_in_e(io_in_right[639:576]), .noc_in_w(e_out_r9_c14),
        .noc_out_n(n_out_r9_c15), .noc_out_s(s_out_r9_c15), 
        .noc_out_e(e_out_r9_c15), .noc_out_w(w_out_r9_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd10)
    ) u_core_r10_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[160]),
        .noc_in_n(s_out_r9_c0), .noc_in_s(n_out_r11_c0), .noc_in_e(w_out_r10_c1), .noc_in_w(io_in_left[703:640]),
        .noc_out_n(n_out_r10_c0), .noc_out_s(s_out_r10_c0), 
        .noc_out_e(e_out_r10_c0), .noc_out_w(w_out_r10_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd10)
    ) u_core_r10_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[161]),
        .noc_in_n(s_out_r9_c1), .noc_in_s(n_out_r11_c1), .noc_in_e(w_out_r10_c2), .noc_in_w(e_out_r10_c0),
        .noc_out_n(n_out_r10_c1), .noc_out_s(s_out_r10_c1), 
        .noc_out_e(e_out_r10_c1), .noc_out_w(w_out_r10_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd10)
    ) u_core_r10_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[162]),
        .noc_in_n(s_out_r9_c2), .noc_in_s(n_out_r11_c2), .noc_in_e(w_out_r10_c3), .noc_in_w(e_out_r10_c1),
        .noc_out_n(n_out_r10_c2), .noc_out_s(s_out_r10_c2), 
        .noc_out_e(e_out_r10_c2), .noc_out_w(w_out_r10_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd10)
    ) u_core_r10_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[163]),
        .noc_in_n(s_out_r9_c3), .noc_in_s(n_out_r11_c3), .noc_in_e(w_out_r10_c4), .noc_in_w(e_out_r10_c2),
        .noc_out_n(n_out_r10_c3), .noc_out_s(s_out_r10_c3), 
        .noc_out_e(e_out_r10_c3), .noc_out_w(w_out_r10_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd10)
    ) u_core_r10_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[164]),
        .noc_in_n(s_out_r9_c4), .noc_in_s(n_out_r11_c4), .noc_in_e(w_out_r10_c5), .noc_in_w(e_out_r10_c3),
        .noc_out_n(n_out_r10_c4), .noc_out_s(s_out_r10_c4), 
        .noc_out_e(e_out_r10_c4), .noc_out_w(w_out_r10_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd10)
    ) u_core_r10_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[165]),
        .noc_in_n(s_out_r9_c5), .noc_in_s(n_out_r11_c5), .noc_in_e(w_out_r10_c6), .noc_in_w(e_out_r10_c4),
        .noc_out_n(n_out_r10_c5), .noc_out_s(s_out_r10_c5), 
        .noc_out_e(e_out_r10_c5), .noc_out_w(w_out_r10_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd10)
    ) u_core_r10_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[166]),
        .noc_in_n(s_out_r9_c6), .noc_in_s(n_out_r11_c6), .noc_in_e(w_out_r10_c7), .noc_in_w(e_out_r10_c5),
        .noc_out_n(n_out_r10_c6), .noc_out_s(s_out_r10_c6), 
        .noc_out_e(e_out_r10_c6), .noc_out_w(w_out_r10_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd10)
    ) u_core_r10_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[167]),
        .noc_in_n(s_out_r9_c7), .noc_in_s(n_out_r11_c7), .noc_in_e(w_out_r10_c8), .noc_in_w(e_out_r10_c6),
        .noc_out_n(n_out_r10_c7), .noc_out_s(s_out_r10_c7), 
        .noc_out_e(e_out_r10_c7), .noc_out_w(w_out_r10_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd10)
    ) u_core_r10_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[168]),
        .noc_in_n(s_out_r9_c8), .noc_in_s(n_out_r11_c8), .noc_in_e(w_out_r10_c9), .noc_in_w(e_out_r10_c7),
        .noc_out_n(n_out_r10_c8), .noc_out_s(s_out_r10_c8), 
        .noc_out_e(e_out_r10_c8), .noc_out_w(w_out_r10_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd10)
    ) u_core_r10_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[169]),
        .noc_in_n(s_out_r9_c9), .noc_in_s(n_out_r11_c9), .noc_in_e(w_out_r10_c10), .noc_in_w(e_out_r10_c8),
        .noc_out_n(n_out_r10_c9), .noc_out_s(s_out_r10_c9), 
        .noc_out_e(e_out_r10_c9), .noc_out_w(w_out_r10_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd10)
    ) u_core_r10_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[170]),
        .noc_in_n(s_out_r9_c10), .noc_in_s(n_out_r11_c10), .noc_in_e(w_out_r10_c11), .noc_in_w(e_out_r10_c9),
        .noc_out_n(n_out_r10_c10), .noc_out_s(s_out_r10_c10), 
        .noc_out_e(e_out_r10_c10), .noc_out_w(w_out_r10_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd10)
    ) u_core_r10_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[171]),
        .noc_in_n(s_out_r9_c11), .noc_in_s(n_out_r11_c11), .noc_in_e(w_out_r10_c12), .noc_in_w(e_out_r10_c10),
        .noc_out_n(n_out_r10_c11), .noc_out_s(s_out_r10_c11), 
        .noc_out_e(e_out_r10_c11), .noc_out_w(w_out_r10_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd10)
    ) u_core_r10_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[172]),
        .noc_in_n(s_out_r9_c12), .noc_in_s(n_out_r11_c12), .noc_in_e(w_out_r10_c13), .noc_in_w(e_out_r10_c11),
        .noc_out_n(n_out_r10_c12), .noc_out_s(s_out_r10_c12), 
        .noc_out_e(e_out_r10_c12), .noc_out_w(w_out_r10_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd10)
    ) u_core_r10_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[173]),
        .noc_in_n(s_out_r9_c13), .noc_in_s(n_out_r11_c13), .noc_in_e(w_out_r10_c14), .noc_in_w(e_out_r10_c12),
        .noc_out_n(n_out_r10_c13), .noc_out_s(s_out_r10_c13), 
        .noc_out_e(e_out_r10_c13), .noc_out_w(w_out_r10_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd10)
    ) u_core_r10_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[174]),
        .noc_in_n(s_out_r9_c14), .noc_in_s(n_out_r11_c14), .noc_in_e(w_out_r10_c15), .noc_in_w(e_out_r10_c13),
        .noc_out_n(n_out_r10_c14), .noc_out_s(s_out_r10_c14), 
        .noc_out_e(e_out_r10_c14), .noc_out_w(w_out_r10_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd10)
    ) u_core_r10_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[175]),
        .noc_in_n(s_out_r9_c15), .noc_in_s(n_out_r11_c15), .noc_in_e(io_in_right[703:640]), .noc_in_w(e_out_r10_c14),
        .noc_out_n(n_out_r10_c15), .noc_out_s(s_out_r10_c15), 
        .noc_out_e(e_out_r10_c15), .noc_out_w(w_out_r10_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd11)
    ) u_core_r11_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[176]),
        .noc_in_n(s_out_r10_c0), .noc_in_s(n_out_r12_c0), .noc_in_e(w_out_r11_c1), .noc_in_w(io_in_left[767:704]),
        .noc_out_n(n_out_r11_c0), .noc_out_s(s_out_r11_c0), 
        .noc_out_e(e_out_r11_c0), .noc_out_w(w_out_r11_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd11)
    ) u_core_r11_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[177]),
        .noc_in_n(s_out_r10_c1), .noc_in_s(n_out_r12_c1), .noc_in_e(w_out_r11_c2), .noc_in_w(e_out_r11_c0),
        .noc_out_n(n_out_r11_c1), .noc_out_s(s_out_r11_c1), 
        .noc_out_e(e_out_r11_c1), .noc_out_w(w_out_r11_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd11)
    ) u_core_r11_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[178]),
        .noc_in_n(s_out_r10_c2), .noc_in_s(n_out_r12_c2), .noc_in_e(w_out_r11_c3), .noc_in_w(e_out_r11_c1),
        .noc_out_n(n_out_r11_c2), .noc_out_s(s_out_r11_c2), 
        .noc_out_e(e_out_r11_c2), .noc_out_w(w_out_r11_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd11)
    ) u_core_r11_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[179]),
        .noc_in_n(s_out_r10_c3), .noc_in_s(n_out_r12_c3), .noc_in_e(w_out_r11_c4), .noc_in_w(e_out_r11_c2),
        .noc_out_n(n_out_r11_c3), .noc_out_s(s_out_r11_c3), 
        .noc_out_e(e_out_r11_c3), .noc_out_w(w_out_r11_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd11)
    ) u_core_r11_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[180]),
        .noc_in_n(s_out_r10_c4), .noc_in_s(n_out_r12_c4), .noc_in_e(w_out_r11_c5), .noc_in_w(e_out_r11_c3),
        .noc_out_n(n_out_r11_c4), .noc_out_s(s_out_r11_c4), 
        .noc_out_e(e_out_r11_c4), .noc_out_w(w_out_r11_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd11)
    ) u_core_r11_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[181]),
        .noc_in_n(s_out_r10_c5), .noc_in_s(n_out_r12_c5), .noc_in_e(w_out_r11_c6), .noc_in_w(e_out_r11_c4),
        .noc_out_n(n_out_r11_c5), .noc_out_s(s_out_r11_c5), 
        .noc_out_e(e_out_r11_c5), .noc_out_w(w_out_r11_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd11)
    ) u_core_r11_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[182]),
        .noc_in_n(s_out_r10_c6), .noc_in_s(n_out_r12_c6), .noc_in_e(w_out_r11_c7), .noc_in_w(e_out_r11_c5),
        .noc_out_n(n_out_r11_c6), .noc_out_s(s_out_r11_c6), 
        .noc_out_e(e_out_r11_c6), .noc_out_w(w_out_r11_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd11)
    ) u_core_r11_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[183]),
        .noc_in_n(s_out_r10_c7), .noc_in_s(n_out_r12_c7), .noc_in_e(w_out_r11_c8), .noc_in_w(e_out_r11_c6),
        .noc_out_n(n_out_r11_c7), .noc_out_s(s_out_r11_c7), 
        .noc_out_e(e_out_r11_c7), .noc_out_w(w_out_r11_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd11)
    ) u_core_r11_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[184]),
        .noc_in_n(s_out_r10_c8), .noc_in_s(n_out_r12_c8), .noc_in_e(w_out_r11_c9), .noc_in_w(e_out_r11_c7),
        .noc_out_n(n_out_r11_c8), .noc_out_s(s_out_r11_c8), 
        .noc_out_e(e_out_r11_c8), .noc_out_w(w_out_r11_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd11)
    ) u_core_r11_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[185]),
        .noc_in_n(s_out_r10_c9), .noc_in_s(n_out_r12_c9), .noc_in_e(w_out_r11_c10), .noc_in_w(e_out_r11_c8),
        .noc_out_n(n_out_r11_c9), .noc_out_s(s_out_r11_c9), 
        .noc_out_e(e_out_r11_c9), .noc_out_w(w_out_r11_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd11)
    ) u_core_r11_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[186]),
        .noc_in_n(s_out_r10_c10), .noc_in_s(n_out_r12_c10), .noc_in_e(w_out_r11_c11), .noc_in_w(e_out_r11_c9),
        .noc_out_n(n_out_r11_c10), .noc_out_s(s_out_r11_c10), 
        .noc_out_e(e_out_r11_c10), .noc_out_w(w_out_r11_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd11)
    ) u_core_r11_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[187]),
        .noc_in_n(s_out_r10_c11), .noc_in_s(n_out_r12_c11), .noc_in_e(w_out_r11_c12), .noc_in_w(e_out_r11_c10),
        .noc_out_n(n_out_r11_c11), .noc_out_s(s_out_r11_c11), 
        .noc_out_e(e_out_r11_c11), .noc_out_w(w_out_r11_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd11)
    ) u_core_r11_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[188]),
        .noc_in_n(s_out_r10_c12), .noc_in_s(n_out_r12_c12), .noc_in_e(w_out_r11_c13), .noc_in_w(e_out_r11_c11),
        .noc_out_n(n_out_r11_c12), .noc_out_s(s_out_r11_c12), 
        .noc_out_e(e_out_r11_c12), .noc_out_w(w_out_r11_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd11)
    ) u_core_r11_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[189]),
        .noc_in_n(s_out_r10_c13), .noc_in_s(n_out_r12_c13), .noc_in_e(w_out_r11_c14), .noc_in_w(e_out_r11_c12),
        .noc_out_n(n_out_r11_c13), .noc_out_s(s_out_r11_c13), 
        .noc_out_e(e_out_r11_c13), .noc_out_w(w_out_r11_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd11)
    ) u_core_r11_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[190]),
        .noc_in_n(s_out_r10_c14), .noc_in_s(n_out_r12_c14), .noc_in_e(w_out_r11_c15), .noc_in_w(e_out_r11_c13),
        .noc_out_n(n_out_r11_c14), .noc_out_s(s_out_r11_c14), 
        .noc_out_e(e_out_r11_c14), .noc_out_w(w_out_r11_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd11)
    ) u_core_r11_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[191]),
        .noc_in_n(s_out_r10_c15), .noc_in_s(n_out_r12_c15), .noc_in_e(io_in_right[767:704]), .noc_in_w(e_out_r11_c14),
        .noc_out_n(n_out_r11_c15), .noc_out_s(s_out_r11_c15), 
        .noc_out_e(e_out_r11_c15), .noc_out_w(w_out_r11_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd12)
    ) u_core_r12_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[192]),
        .noc_in_n(s_out_r11_c0), .noc_in_s(n_out_r13_c0), .noc_in_e(w_out_r12_c1), .noc_in_w(io_in_left[831:768]),
        .noc_out_n(n_out_r12_c0), .noc_out_s(s_out_r12_c0), 
        .noc_out_e(e_out_r12_c0), .noc_out_w(w_out_r12_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd12)
    ) u_core_r12_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[193]),
        .noc_in_n(s_out_r11_c1), .noc_in_s(n_out_r13_c1), .noc_in_e(w_out_r12_c2), .noc_in_w(e_out_r12_c0),
        .noc_out_n(n_out_r12_c1), .noc_out_s(s_out_r12_c1), 
        .noc_out_e(e_out_r12_c1), .noc_out_w(w_out_r12_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd12)
    ) u_core_r12_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[194]),
        .noc_in_n(s_out_r11_c2), .noc_in_s(n_out_r13_c2), .noc_in_e(w_out_r12_c3), .noc_in_w(e_out_r12_c1),
        .noc_out_n(n_out_r12_c2), .noc_out_s(s_out_r12_c2), 
        .noc_out_e(e_out_r12_c2), .noc_out_w(w_out_r12_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd12)
    ) u_core_r12_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[195]),
        .noc_in_n(s_out_r11_c3), .noc_in_s(n_out_r13_c3), .noc_in_e(w_out_r12_c4), .noc_in_w(e_out_r12_c2),
        .noc_out_n(n_out_r12_c3), .noc_out_s(s_out_r12_c3), 
        .noc_out_e(e_out_r12_c3), .noc_out_w(w_out_r12_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd12)
    ) u_core_r12_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[196]),
        .noc_in_n(s_out_r11_c4), .noc_in_s(n_out_r13_c4), .noc_in_e(w_out_r12_c5), .noc_in_w(e_out_r12_c3),
        .noc_out_n(n_out_r12_c4), .noc_out_s(s_out_r12_c4), 
        .noc_out_e(e_out_r12_c4), .noc_out_w(w_out_r12_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd12)
    ) u_core_r12_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[197]),
        .noc_in_n(s_out_r11_c5), .noc_in_s(n_out_r13_c5), .noc_in_e(w_out_r12_c6), .noc_in_w(e_out_r12_c4),
        .noc_out_n(n_out_r12_c5), .noc_out_s(s_out_r12_c5), 
        .noc_out_e(e_out_r12_c5), .noc_out_w(w_out_r12_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd12)
    ) u_core_r12_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[198]),
        .noc_in_n(s_out_r11_c6), .noc_in_s(n_out_r13_c6), .noc_in_e(w_out_r12_c7), .noc_in_w(e_out_r12_c5),
        .noc_out_n(n_out_r12_c6), .noc_out_s(s_out_r12_c6), 
        .noc_out_e(e_out_r12_c6), .noc_out_w(w_out_r12_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd12)
    ) u_core_r12_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[199]),
        .noc_in_n(s_out_r11_c7), .noc_in_s(n_out_r13_c7), .noc_in_e(w_out_r12_c8), .noc_in_w(e_out_r12_c6),
        .noc_out_n(n_out_r12_c7), .noc_out_s(s_out_r12_c7), 
        .noc_out_e(e_out_r12_c7), .noc_out_w(w_out_r12_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd12)
    ) u_core_r12_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[200]),
        .noc_in_n(s_out_r11_c8), .noc_in_s(n_out_r13_c8), .noc_in_e(w_out_r12_c9), .noc_in_w(e_out_r12_c7),
        .noc_out_n(n_out_r12_c8), .noc_out_s(s_out_r12_c8), 
        .noc_out_e(e_out_r12_c8), .noc_out_w(w_out_r12_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd12)
    ) u_core_r12_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[201]),
        .noc_in_n(s_out_r11_c9), .noc_in_s(n_out_r13_c9), .noc_in_e(w_out_r12_c10), .noc_in_w(e_out_r12_c8),
        .noc_out_n(n_out_r12_c9), .noc_out_s(s_out_r12_c9), 
        .noc_out_e(e_out_r12_c9), .noc_out_w(w_out_r12_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd12)
    ) u_core_r12_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[202]),
        .noc_in_n(s_out_r11_c10), .noc_in_s(n_out_r13_c10), .noc_in_e(w_out_r12_c11), .noc_in_w(e_out_r12_c9),
        .noc_out_n(n_out_r12_c10), .noc_out_s(s_out_r12_c10), 
        .noc_out_e(e_out_r12_c10), .noc_out_w(w_out_r12_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd12)
    ) u_core_r12_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[203]),
        .noc_in_n(s_out_r11_c11), .noc_in_s(n_out_r13_c11), .noc_in_e(w_out_r12_c12), .noc_in_w(e_out_r12_c10),
        .noc_out_n(n_out_r12_c11), .noc_out_s(s_out_r12_c11), 
        .noc_out_e(e_out_r12_c11), .noc_out_w(w_out_r12_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd12)
    ) u_core_r12_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[204]),
        .noc_in_n(s_out_r11_c12), .noc_in_s(n_out_r13_c12), .noc_in_e(w_out_r12_c13), .noc_in_w(e_out_r12_c11),
        .noc_out_n(n_out_r12_c12), .noc_out_s(s_out_r12_c12), 
        .noc_out_e(e_out_r12_c12), .noc_out_w(w_out_r12_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd12)
    ) u_core_r12_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[205]),
        .noc_in_n(s_out_r11_c13), .noc_in_s(n_out_r13_c13), .noc_in_e(w_out_r12_c14), .noc_in_w(e_out_r12_c12),
        .noc_out_n(n_out_r12_c13), .noc_out_s(s_out_r12_c13), 
        .noc_out_e(e_out_r12_c13), .noc_out_w(w_out_r12_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd12)
    ) u_core_r12_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[206]),
        .noc_in_n(s_out_r11_c14), .noc_in_s(n_out_r13_c14), .noc_in_e(w_out_r12_c15), .noc_in_w(e_out_r12_c13),
        .noc_out_n(n_out_r12_c14), .noc_out_s(s_out_r12_c14), 
        .noc_out_e(e_out_r12_c14), .noc_out_w(w_out_r12_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd12)
    ) u_core_r12_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[207]),
        .noc_in_n(s_out_r11_c15), .noc_in_s(n_out_r13_c15), .noc_in_e(io_in_right[831:768]), .noc_in_w(e_out_r12_c14),
        .noc_out_n(n_out_r12_c15), .noc_out_s(s_out_r12_c15), 
        .noc_out_e(e_out_r12_c15), .noc_out_w(w_out_r12_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd13)
    ) u_core_r13_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[208]),
        .noc_in_n(s_out_r12_c0), .noc_in_s(n_out_r14_c0), .noc_in_e(w_out_r13_c1), .noc_in_w(io_in_left[895:832]),
        .noc_out_n(n_out_r13_c0), .noc_out_s(s_out_r13_c0), 
        .noc_out_e(e_out_r13_c0), .noc_out_w(w_out_r13_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd13)
    ) u_core_r13_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[209]),
        .noc_in_n(s_out_r12_c1), .noc_in_s(n_out_r14_c1), .noc_in_e(w_out_r13_c2), .noc_in_w(e_out_r13_c0),
        .noc_out_n(n_out_r13_c1), .noc_out_s(s_out_r13_c1), 
        .noc_out_e(e_out_r13_c1), .noc_out_w(w_out_r13_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd13)
    ) u_core_r13_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[210]),
        .noc_in_n(s_out_r12_c2), .noc_in_s(n_out_r14_c2), .noc_in_e(w_out_r13_c3), .noc_in_w(e_out_r13_c1),
        .noc_out_n(n_out_r13_c2), .noc_out_s(s_out_r13_c2), 
        .noc_out_e(e_out_r13_c2), .noc_out_w(w_out_r13_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd13)
    ) u_core_r13_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[211]),
        .noc_in_n(s_out_r12_c3), .noc_in_s(n_out_r14_c3), .noc_in_e(w_out_r13_c4), .noc_in_w(e_out_r13_c2),
        .noc_out_n(n_out_r13_c3), .noc_out_s(s_out_r13_c3), 
        .noc_out_e(e_out_r13_c3), .noc_out_w(w_out_r13_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd13)
    ) u_core_r13_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[212]),
        .noc_in_n(s_out_r12_c4), .noc_in_s(n_out_r14_c4), .noc_in_e(w_out_r13_c5), .noc_in_w(e_out_r13_c3),
        .noc_out_n(n_out_r13_c4), .noc_out_s(s_out_r13_c4), 
        .noc_out_e(e_out_r13_c4), .noc_out_w(w_out_r13_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd13)
    ) u_core_r13_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[213]),
        .noc_in_n(s_out_r12_c5), .noc_in_s(n_out_r14_c5), .noc_in_e(w_out_r13_c6), .noc_in_w(e_out_r13_c4),
        .noc_out_n(n_out_r13_c5), .noc_out_s(s_out_r13_c5), 
        .noc_out_e(e_out_r13_c5), .noc_out_w(w_out_r13_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd13)
    ) u_core_r13_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[214]),
        .noc_in_n(s_out_r12_c6), .noc_in_s(n_out_r14_c6), .noc_in_e(w_out_r13_c7), .noc_in_w(e_out_r13_c5),
        .noc_out_n(n_out_r13_c6), .noc_out_s(s_out_r13_c6), 
        .noc_out_e(e_out_r13_c6), .noc_out_w(w_out_r13_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd13)
    ) u_core_r13_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[215]),
        .noc_in_n(s_out_r12_c7), .noc_in_s(n_out_r14_c7), .noc_in_e(w_out_r13_c8), .noc_in_w(e_out_r13_c6),
        .noc_out_n(n_out_r13_c7), .noc_out_s(s_out_r13_c7), 
        .noc_out_e(e_out_r13_c7), .noc_out_w(w_out_r13_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd13)
    ) u_core_r13_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[216]),
        .noc_in_n(s_out_r12_c8), .noc_in_s(n_out_r14_c8), .noc_in_e(w_out_r13_c9), .noc_in_w(e_out_r13_c7),
        .noc_out_n(n_out_r13_c8), .noc_out_s(s_out_r13_c8), 
        .noc_out_e(e_out_r13_c8), .noc_out_w(w_out_r13_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd13)
    ) u_core_r13_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[217]),
        .noc_in_n(s_out_r12_c9), .noc_in_s(n_out_r14_c9), .noc_in_e(w_out_r13_c10), .noc_in_w(e_out_r13_c8),
        .noc_out_n(n_out_r13_c9), .noc_out_s(s_out_r13_c9), 
        .noc_out_e(e_out_r13_c9), .noc_out_w(w_out_r13_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd13)
    ) u_core_r13_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[218]),
        .noc_in_n(s_out_r12_c10), .noc_in_s(n_out_r14_c10), .noc_in_e(w_out_r13_c11), .noc_in_w(e_out_r13_c9),
        .noc_out_n(n_out_r13_c10), .noc_out_s(s_out_r13_c10), 
        .noc_out_e(e_out_r13_c10), .noc_out_w(w_out_r13_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd13)
    ) u_core_r13_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[219]),
        .noc_in_n(s_out_r12_c11), .noc_in_s(n_out_r14_c11), .noc_in_e(w_out_r13_c12), .noc_in_w(e_out_r13_c10),
        .noc_out_n(n_out_r13_c11), .noc_out_s(s_out_r13_c11), 
        .noc_out_e(e_out_r13_c11), .noc_out_w(w_out_r13_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd13)
    ) u_core_r13_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[220]),
        .noc_in_n(s_out_r12_c12), .noc_in_s(n_out_r14_c12), .noc_in_e(w_out_r13_c13), .noc_in_w(e_out_r13_c11),
        .noc_out_n(n_out_r13_c12), .noc_out_s(s_out_r13_c12), 
        .noc_out_e(e_out_r13_c12), .noc_out_w(w_out_r13_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd13)
    ) u_core_r13_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[221]),
        .noc_in_n(s_out_r12_c13), .noc_in_s(n_out_r14_c13), .noc_in_e(w_out_r13_c14), .noc_in_w(e_out_r13_c12),
        .noc_out_n(n_out_r13_c13), .noc_out_s(s_out_r13_c13), 
        .noc_out_e(e_out_r13_c13), .noc_out_w(w_out_r13_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd13)
    ) u_core_r13_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[222]),
        .noc_in_n(s_out_r12_c14), .noc_in_s(n_out_r14_c14), .noc_in_e(w_out_r13_c15), .noc_in_w(e_out_r13_c13),
        .noc_out_n(n_out_r13_c14), .noc_out_s(s_out_r13_c14), 
        .noc_out_e(e_out_r13_c14), .noc_out_w(w_out_r13_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd13)
    ) u_core_r13_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[223]),
        .noc_in_n(s_out_r12_c15), .noc_in_s(n_out_r14_c15), .noc_in_e(io_in_right[895:832]), .noc_in_w(e_out_r13_c14),
        .noc_out_n(n_out_r13_c15), .noc_out_s(s_out_r13_c15), 
        .noc_out_e(e_out_r13_c15), .noc_out_w(w_out_r13_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd14)
    ) u_core_r14_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[224]),
        .noc_in_n(s_out_r13_c0), .noc_in_s(n_out_r15_c0), .noc_in_e(w_out_r14_c1), .noc_in_w(io_in_left[959:896]),
        .noc_out_n(n_out_r14_c0), .noc_out_s(s_out_r14_c0), 
        .noc_out_e(e_out_r14_c0), .noc_out_w(w_out_r14_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd14)
    ) u_core_r14_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[225]),
        .noc_in_n(s_out_r13_c1), .noc_in_s(n_out_r15_c1), .noc_in_e(w_out_r14_c2), .noc_in_w(e_out_r14_c0),
        .noc_out_n(n_out_r14_c1), .noc_out_s(s_out_r14_c1), 
        .noc_out_e(e_out_r14_c1), .noc_out_w(w_out_r14_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd14)
    ) u_core_r14_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[226]),
        .noc_in_n(s_out_r13_c2), .noc_in_s(n_out_r15_c2), .noc_in_e(w_out_r14_c3), .noc_in_w(e_out_r14_c1),
        .noc_out_n(n_out_r14_c2), .noc_out_s(s_out_r14_c2), 
        .noc_out_e(e_out_r14_c2), .noc_out_w(w_out_r14_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd14)
    ) u_core_r14_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[227]),
        .noc_in_n(s_out_r13_c3), .noc_in_s(n_out_r15_c3), .noc_in_e(w_out_r14_c4), .noc_in_w(e_out_r14_c2),
        .noc_out_n(n_out_r14_c3), .noc_out_s(s_out_r14_c3), 
        .noc_out_e(e_out_r14_c3), .noc_out_w(w_out_r14_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd14)
    ) u_core_r14_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[228]),
        .noc_in_n(s_out_r13_c4), .noc_in_s(n_out_r15_c4), .noc_in_e(w_out_r14_c5), .noc_in_w(e_out_r14_c3),
        .noc_out_n(n_out_r14_c4), .noc_out_s(s_out_r14_c4), 
        .noc_out_e(e_out_r14_c4), .noc_out_w(w_out_r14_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd14)
    ) u_core_r14_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[229]),
        .noc_in_n(s_out_r13_c5), .noc_in_s(n_out_r15_c5), .noc_in_e(w_out_r14_c6), .noc_in_w(e_out_r14_c4),
        .noc_out_n(n_out_r14_c5), .noc_out_s(s_out_r14_c5), 
        .noc_out_e(e_out_r14_c5), .noc_out_w(w_out_r14_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd14)
    ) u_core_r14_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[230]),
        .noc_in_n(s_out_r13_c6), .noc_in_s(n_out_r15_c6), .noc_in_e(w_out_r14_c7), .noc_in_w(e_out_r14_c5),
        .noc_out_n(n_out_r14_c6), .noc_out_s(s_out_r14_c6), 
        .noc_out_e(e_out_r14_c6), .noc_out_w(w_out_r14_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd14)
    ) u_core_r14_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[231]),
        .noc_in_n(s_out_r13_c7), .noc_in_s(n_out_r15_c7), .noc_in_e(w_out_r14_c8), .noc_in_w(e_out_r14_c6),
        .noc_out_n(n_out_r14_c7), .noc_out_s(s_out_r14_c7), 
        .noc_out_e(e_out_r14_c7), .noc_out_w(w_out_r14_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd14)
    ) u_core_r14_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[232]),
        .noc_in_n(s_out_r13_c8), .noc_in_s(n_out_r15_c8), .noc_in_e(w_out_r14_c9), .noc_in_w(e_out_r14_c7),
        .noc_out_n(n_out_r14_c8), .noc_out_s(s_out_r14_c8), 
        .noc_out_e(e_out_r14_c8), .noc_out_w(w_out_r14_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd14)
    ) u_core_r14_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[233]),
        .noc_in_n(s_out_r13_c9), .noc_in_s(n_out_r15_c9), .noc_in_e(w_out_r14_c10), .noc_in_w(e_out_r14_c8),
        .noc_out_n(n_out_r14_c9), .noc_out_s(s_out_r14_c9), 
        .noc_out_e(e_out_r14_c9), .noc_out_w(w_out_r14_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd14)
    ) u_core_r14_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[234]),
        .noc_in_n(s_out_r13_c10), .noc_in_s(n_out_r15_c10), .noc_in_e(w_out_r14_c11), .noc_in_w(e_out_r14_c9),
        .noc_out_n(n_out_r14_c10), .noc_out_s(s_out_r14_c10), 
        .noc_out_e(e_out_r14_c10), .noc_out_w(w_out_r14_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd14)
    ) u_core_r14_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[235]),
        .noc_in_n(s_out_r13_c11), .noc_in_s(n_out_r15_c11), .noc_in_e(w_out_r14_c12), .noc_in_w(e_out_r14_c10),
        .noc_out_n(n_out_r14_c11), .noc_out_s(s_out_r14_c11), 
        .noc_out_e(e_out_r14_c11), .noc_out_w(w_out_r14_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd14)
    ) u_core_r14_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[236]),
        .noc_in_n(s_out_r13_c12), .noc_in_s(n_out_r15_c12), .noc_in_e(w_out_r14_c13), .noc_in_w(e_out_r14_c11),
        .noc_out_n(n_out_r14_c12), .noc_out_s(s_out_r14_c12), 
        .noc_out_e(e_out_r14_c12), .noc_out_w(w_out_r14_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd14)
    ) u_core_r14_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[237]),
        .noc_in_n(s_out_r13_c13), .noc_in_s(n_out_r15_c13), .noc_in_e(w_out_r14_c14), .noc_in_w(e_out_r14_c12),
        .noc_out_n(n_out_r14_c13), .noc_out_s(s_out_r14_c13), 
        .noc_out_e(e_out_r14_c13), .noc_out_w(w_out_r14_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd14)
    ) u_core_r14_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[238]),
        .noc_in_n(s_out_r13_c14), .noc_in_s(n_out_r15_c14), .noc_in_e(w_out_r14_c15), .noc_in_w(e_out_r14_c13),
        .noc_out_n(n_out_r14_c14), .noc_out_s(s_out_r14_c14), 
        .noc_out_e(e_out_r14_c14), .noc_out_w(w_out_r14_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd14)
    ) u_core_r14_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[239]),
        .noc_in_n(s_out_r13_c15), .noc_in_s(n_out_r15_c15), .noc_in_e(io_in_right[959:896]), .noc_in_w(e_out_r14_c14),
        .noc_out_n(n_out_r14_c15), .noc_out_s(s_out_r14_c15), 
        .noc_out_e(e_out_r14_c15), .noc_out_w(w_out_r14_c15)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd0), .CORE_Y(16'd15)
    ) u_core_r15_c0 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[240]),
        .noc_in_n(s_out_r14_c0), .noc_in_s(io_in_bottom[63:0]), .noc_in_e(w_out_r15_c1), .noc_in_w(io_in_left[1023:960]),
        .noc_out_n(n_out_r15_c0), .noc_out_s(s_out_r15_c0), 
        .noc_out_e(e_out_r15_c0), .noc_out_w(w_out_r15_c0)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd1), .CORE_Y(16'd15)
    ) u_core_r15_c1 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[241]),
        .noc_in_n(s_out_r14_c1), .noc_in_s(io_in_bottom[127:64]), .noc_in_e(w_out_r15_c2), .noc_in_w(e_out_r15_c0),
        .noc_out_n(n_out_r15_c1), .noc_out_s(s_out_r15_c1), 
        .noc_out_e(e_out_r15_c1), .noc_out_w(w_out_r15_c1)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd2), .CORE_Y(16'd15)
    ) u_core_r15_c2 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[242]),
        .noc_in_n(s_out_r14_c2), .noc_in_s(io_in_bottom[191:128]), .noc_in_e(w_out_r15_c3), .noc_in_w(e_out_r15_c1),
        .noc_out_n(n_out_r15_c2), .noc_out_s(s_out_r15_c2), 
        .noc_out_e(e_out_r15_c2), .noc_out_w(w_out_r15_c2)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd3), .CORE_Y(16'd15)
    ) u_core_r15_c3 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[243]),
        .noc_in_n(s_out_r14_c3), .noc_in_s(io_in_bottom[255:192]), .noc_in_e(w_out_r15_c4), .noc_in_w(e_out_r15_c2),
        .noc_out_n(n_out_r15_c3), .noc_out_s(s_out_r15_c3), 
        .noc_out_e(e_out_r15_c3), .noc_out_w(w_out_r15_c3)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd4), .CORE_Y(16'd15)
    ) u_core_r15_c4 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[244]),
        .noc_in_n(s_out_r14_c4), .noc_in_s(io_in_bottom[319:256]), .noc_in_e(w_out_r15_c5), .noc_in_w(e_out_r15_c3),
        .noc_out_n(n_out_r15_c4), .noc_out_s(s_out_r15_c4), 
        .noc_out_e(e_out_r15_c4), .noc_out_w(w_out_r15_c4)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd5), .CORE_Y(16'd15)
    ) u_core_r15_c5 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[245]),
        .noc_in_n(s_out_r14_c5), .noc_in_s(io_in_bottom[383:320]), .noc_in_e(w_out_r15_c6), .noc_in_w(e_out_r15_c4),
        .noc_out_n(n_out_r15_c5), .noc_out_s(s_out_r15_c5), 
        .noc_out_e(e_out_r15_c5), .noc_out_w(w_out_r15_c5)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd6), .CORE_Y(16'd15)
    ) u_core_r15_c6 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[246]),
        .noc_in_n(s_out_r14_c6), .noc_in_s(io_in_bottom[447:384]), .noc_in_e(w_out_r15_c7), .noc_in_w(e_out_r15_c5),
        .noc_out_n(n_out_r15_c6), .noc_out_s(s_out_r15_c6), 
        .noc_out_e(e_out_r15_c6), .noc_out_w(w_out_r15_c6)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd7), .CORE_Y(16'd15)
    ) u_core_r15_c7 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[247]),
        .noc_in_n(s_out_r14_c7), .noc_in_s(io_in_bottom[511:448]), .noc_in_e(w_out_r15_c8), .noc_in_w(e_out_r15_c6),
        .noc_out_n(n_out_r15_c7), .noc_out_s(s_out_r15_c7), 
        .noc_out_e(e_out_r15_c7), .noc_out_w(w_out_r15_c7)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd8), .CORE_Y(16'd15)
    ) u_core_r15_c8 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[248]),
        .noc_in_n(s_out_r14_c8), .noc_in_s(io_in_bottom[575:512]), .noc_in_e(w_out_r15_c9), .noc_in_w(e_out_r15_c7),
        .noc_out_n(n_out_r15_c8), .noc_out_s(s_out_r15_c8), 
        .noc_out_e(e_out_r15_c8), .noc_out_w(w_out_r15_c8)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd9), .CORE_Y(16'd15)
    ) u_core_r15_c9 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[249]),
        .noc_in_n(s_out_r14_c9), .noc_in_s(io_in_bottom[639:576]), .noc_in_e(w_out_r15_c10), .noc_in_w(e_out_r15_c8),
        .noc_out_n(n_out_r15_c9), .noc_out_s(s_out_r15_c9), 
        .noc_out_e(e_out_r15_c9), .noc_out_w(w_out_r15_c9)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd10), .CORE_Y(16'd15)
    ) u_core_r15_c10 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[250]),
        .noc_in_n(s_out_r14_c10), .noc_in_s(io_in_bottom[703:640]), .noc_in_e(w_out_r15_c11), .noc_in_w(e_out_r15_c9),
        .noc_out_n(n_out_r15_c10), .noc_out_s(s_out_r15_c10), 
        .noc_out_e(e_out_r15_c10), .noc_out_w(w_out_r15_c10)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd11), .CORE_Y(16'd15)
    ) u_core_r15_c11 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[251]),
        .noc_in_n(s_out_r14_c11), .noc_in_s(io_in_bottom[767:704]), .noc_in_e(w_out_r15_c12), .noc_in_w(e_out_r15_c10),
        .noc_out_n(n_out_r15_c11), .noc_out_s(s_out_r15_c11), 
        .noc_out_e(e_out_r15_c11), .noc_out_w(w_out_r15_c11)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd12), .CORE_Y(16'd15)
    ) u_core_r15_c12 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[252]),
        .noc_in_n(s_out_r14_c12), .noc_in_s(io_in_bottom[831:768]), .noc_in_e(w_out_r15_c13), .noc_in_w(e_out_r15_c11),
        .noc_out_n(n_out_r15_c12), .noc_out_s(s_out_r15_c12), 
        .noc_out_e(e_out_r15_c12), .noc_out_w(w_out_r15_c12)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd13), .CORE_Y(16'd15)
    ) u_core_r15_c13 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[253]),
        .noc_in_n(s_out_r14_c13), .noc_in_s(io_in_bottom[895:832]), .noc_in_e(w_out_r15_c14), .noc_in_w(e_out_r15_c12),
        .noc_out_n(n_out_r15_c13), .noc_out_s(s_out_r15_c13), 
        .noc_out_e(e_out_r15_c13), .noc_out_w(w_out_r15_c13)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd14), .CORE_Y(16'd15)
    ) u_core_r15_c14 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[254]),
        .noc_in_n(s_out_r14_c14), .noc_in_s(io_in_bottom[959:896]), .noc_in_e(w_out_r15_c15), .noc_in_w(e_out_r15_c13),
        .noc_out_n(n_out_r15_c14), .noc_out_s(s_out_r15_c14), 
        .noc_out_e(e_out_r15_c14), .noc_out_w(w_out_r15_c14)
    );

    titan_x_wse_sm #(
        .CORE_X(16'd15), .CORE_Y(16'd15)
    ) u_core_r15_c15 (
        .clk(clk), .rst_n(rst_n), .is_defective(defect_fuses[255]),
        .noc_in_n(s_out_r14_c15), .noc_in_s(io_in_bottom[1023:960]), .noc_in_e(io_in_right[1023:960]), .noc_in_w(e_out_r15_c14),
        .noc_out_n(n_out_r15_c15), .noc_out_s(s_out_r15_c15), 
        .noc_out_e(e_out_r15_c15), .noc_out_w(w_out_r15_c15)
    );

    // Edge I/O Assignments
    assign io_out_top[63:0] = n_out_r0_c0;
    assign io_out_bottom[63:0] = s_out_r15_c0;
    assign io_out_top[127:64] = n_out_r0_c1;
    assign io_out_bottom[127:64] = s_out_r15_c1;
    assign io_out_top[191:128] = n_out_r0_c2;
    assign io_out_bottom[191:128] = s_out_r15_c2;
    assign io_out_top[255:192] = n_out_r0_c3;
    assign io_out_bottom[255:192] = s_out_r15_c3;
    assign io_out_top[319:256] = n_out_r0_c4;
    assign io_out_bottom[319:256] = s_out_r15_c4;
    assign io_out_top[383:320] = n_out_r0_c5;
    assign io_out_bottom[383:320] = s_out_r15_c5;
    assign io_out_top[447:384] = n_out_r0_c6;
    assign io_out_bottom[447:384] = s_out_r15_c6;
    assign io_out_top[511:448] = n_out_r0_c7;
    assign io_out_bottom[511:448] = s_out_r15_c7;
    assign io_out_top[575:512] = n_out_r0_c8;
    assign io_out_bottom[575:512] = s_out_r15_c8;
    assign io_out_top[639:576] = n_out_r0_c9;
    assign io_out_bottom[639:576] = s_out_r15_c9;
    assign io_out_top[703:640] = n_out_r0_c10;
    assign io_out_bottom[703:640] = s_out_r15_c10;
    assign io_out_top[767:704] = n_out_r0_c11;
    assign io_out_bottom[767:704] = s_out_r15_c11;
    assign io_out_top[831:768] = n_out_r0_c12;
    assign io_out_bottom[831:768] = s_out_r15_c12;
    assign io_out_top[895:832] = n_out_r0_c13;
    assign io_out_bottom[895:832] = s_out_r15_c13;
    assign io_out_top[959:896] = n_out_r0_c14;
    assign io_out_bottom[959:896] = s_out_r15_c14;
    assign io_out_top[1023:960] = n_out_r0_c15;
    assign io_out_bottom[1023:960] = s_out_r15_c15;
    assign io_out_left[63:0] = w_out_r0_c0;
    assign io_out_right[63:0] = e_out_r0_c15;
    assign io_out_left[127:64] = w_out_r1_c0;
    assign io_out_right[127:64] = e_out_r1_c15;
    assign io_out_left[191:128] = w_out_r2_c0;
    assign io_out_right[191:128] = e_out_r2_c15;
    assign io_out_left[255:192] = w_out_r3_c0;
    assign io_out_right[255:192] = e_out_r3_c15;
    assign io_out_left[319:256] = w_out_r4_c0;
    assign io_out_right[319:256] = e_out_r4_c15;
    assign io_out_left[383:320] = w_out_r5_c0;
    assign io_out_right[383:320] = e_out_r5_c15;
    assign io_out_left[447:384] = w_out_r6_c0;
    assign io_out_right[447:384] = e_out_r6_c15;
    assign io_out_left[511:448] = w_out_r7_c0;
    assign io_out_right[511:448] = e_out_r7_c15;
    assign io_out_left[575:512] = w_out_r8_c0;
    assign io_out_right[575:512] = e_out_r8_c15;
    assign io_out_left[639:576] = w_out_r9_c0;
    assign io_out_right[639:576] = e_out_r9_c15;
    assign io_out_left[703:640] = w_out_r10_c0;
    assign io_out_right[703:640] = e_out_r10_c15;
    assign io_out_left[767:704] = w_out_r11_c0;
    assign io_out_right[767:704] = e_out_r11_c15;
    assign io_out_left[831:768] = w_out_r12_c0;
    assign io_out_right[831:768] = e_out_r12_c15;
    assign io_out_left[895:832] = w_out_r13_c0;
    assign io_out_right[895:832] = e_out_r13_c15;
    assign io_out_left[959:896] = w_out_r14_c0;
    assign io_out_right[959:896] = e_out_r14_c15;
    assign io_out_left[1023:960] = w_out_r15_c0;
    assign io_out_right[1023:960] = e_out_r15_c15;
endmodule
