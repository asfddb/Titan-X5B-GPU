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
 * Module: titan_x5_noc_router
 * Description: 5-port (N/E/S/W/Local) wormhole router for the 2D mesh NoC.
 *
 *  - XY dimension-order routing (X fully, then Y): deadlock-free for
 *    unicast traffic on a mesh.
 *  - 2 virtual channels per input port. VCs are traffic classes (VC0 =
 *    requests, VC1 = responses/invalidations): a packet never changes VC,
 *    so MESI request/response dependencies cannot deadlock each other.
 *  - Credit-based flow control per (port, VC); input buffers hold
 *    BUF_DEPTH flits per VC.
 *  - Wormhole switching: an output port is held by the winning (input,VC)
 *    from head flit to tail flit; round-robin arbitration between packets.
 *  - One register stage at every output (flit-level pipelining): the
 *    router adds exactly one cycle per hop and the arb/route logic is the
 *    only combinational depth between flit registers.
 *
 * Flit format (FLIT_W = PAYLOAD_W + 12):
 *   [PAYLOAD_W+11]            head
 *   [PAYLOAD_W+10]            tail   (single-flit packet: head & tail)
 *   [PAYLOAD_W+9 : PAYLOAD_W+5]  dest x (5 bits)
 *   [PAYLOAD_W+4 : PAYLOAD_W]    dest y (5 bits)
 *   [PAYLOAD_W-1 : 0]         payload
 *
 * Port order: 0 = North (y-1), 1 = East (x+1), 2 = South (y+1),
 *             3 = West (x-1), 4 = Local.
 */
module titan_x5_noc_router #(
    parameter X_ID      = 0,
    parameter Y_ID      = 0,
    parameter PAYLOAD_W = 64,
    parameter N_VC      = 2,
    parameter BUF_DEPTH = 4,          // flits per input VC buffer
    parameter FLIT_W    = PAYLOAD_W + 12
)(
    input  wire                    clk,
    input  wire                    rst_n,

    // input links (flit + valid + vc, credit return per vc)
    input  wire [5*FLIT_W-1:0]     in_flit,
    input  wire [4:0]              in_valid,
    input  wire [5*N_VC-1:0]       in_vc,        // one-hot VC of each flit
    output wire [5*N_VC-1:0]       in_credit,    // credit return pulses

    // output links
    output reg  [5*FLIT_W-1:0]     out_flit,
    output reg  [4:0]              out_valid,
    output reg  [5*N_VC-1:0]       out_vc,
    input  wire [5*N_VC-1:0]       out_credit    // credits from neighbours
);

    localparam P_N = 0, P_E = 1, P_S = 2, P_W = 3, P_L = 4;
    localparam PTR_W = 3;   // fits 0..9 (5 ports x 2 VCs)

    genvar gp, gv;
    integer i, v;

    // ------------------------------------------------------------------
    // input buffers: FIFO per (port, VC)
    // ------------------------------------------------------------------
    reg [FLIT_W-1:0] buf_mem  [0:5*N_VC*BUF_DEPTH-1];
    reg [2:0]        buf_rd   [0:5*N_VC-1];
    reg [2:0]        buf_wr   [0:5*N_VC-1];
    reg [2:0]        buf_cnt  [0:5*N_VC-1];

    wire [FLIT_W-1:0] head_flit [0:5*N_VC-1];
    wire              head_vld  [0:5*N_VC-1];

    generate
        for (gp = 0; gp < 5; gp = gp + 1) begin : g_hf_p
            for (gv = 0; gv < N_VC; gv = gv + 1) begin : g_hf_v
                localparam IDX = gp*N_VC + gv;
                assign head_flit[IDX] =
                    buf_mem[IDX*BUF_DEPTH + {29'b0, buf_rd[IDX]}];
                assign head_vld[IDX] = (buf_cnt[IDX] != 3'd0);
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // route computation (XY) on each buffered head flit
    // ------------------------------------------------------------------
    function [2:0] xy_route;
        input [4:0] dx;
        input [4:0] dy;
        begin
            if (dx > X_ID[4:0])      xy_route = P_E[2:0];
            else if (dx < X_ID[4:0]) xy_route = P_W[2:0];
            else if (dy > Y_ID[4:0]) xy_route = P_S[2:0];
            else if (dy < Y_ID[4:0]) xy_route = P_N[2:0];
            else                     xy_route = P_L[2:0];
        end
    endfunction

    wire [2:0] req_port [0:5*N_VC-1];
    generate
        for (gp = 0; gp < 5; gp = gp + 1) begin : g_rt_p
            for (gv = 0; gv < N_VC; gv = gv + 1) begin : g_rt_v
                localparam IDX = gp*N_VC + gv;
                assign req_port[IDX] =
                    xy_route(head_flit[IDX][PAYLOAD_W+9 -: 5],
                             head_flit[IDX][PAYLOAD_W+4 -: 5]);
            end
        end
    endgenerate

    // ------------------------------------------------------------------
    // allocation: wormhole state is per (output, VC) so a stalled packet
    // on one VC never blocks the other VC of the same physical link -
    // flits of different VCs interleave on the wire (true VC switching,
    // which is what makes the request/response deadlock split work)
    // ------------------------------------------------------------------
    reg           olock   [0:5*N_VC-1];   // (out*N_VC+vc) held by a packet
    reg [2:0]     owner   [0:5*N_VC-1];   // input PORT holding it
    reg [2:0]     rr      [0:5*N_VC-1];   // round-robin over input ports
    reg [PTR_W:0] vrr     [0:4];          // per-output round-robin over VCs
    reg [2:0]     ocredit [0:5*N_VC-1];   // credits toward neighbour

    // stage A: per (output, VC) candidate input port
    reg [2:0] vc_cand     [0:5*N_VC-1];
    reg       vc_cand_vld [0:5*N_VC-1];

    reg [3:0] cand;
    reg [3:0] gi;
    always @(*) begin
        for (i = 0; i < 5*N_VC; i = i + 1) begin : vc_alloc
            vc_cand[i]     = 3'd0;
            vc_cand_vld[i] = 1'b0;
            if (ocredit[i] != 3'd0) begin
                if (olock[i]) begin
                    // wormhole hold: only the owning input port may send
                    if (head_vld[{29'b0, owner[i]}*N_VC + i % N_VC] &&
                        req_port[{29'b0, owner[i]}*N_VC + i % N_VC] == (i/N_VC)) begin
                        vc_cand[i]     = owner[i];
                        vc_cand_vld[i] = 1'b1;
                    end
                end else begin
                    // round-robin over the 5 input ports on this VC
                    for (gi = 0; gi < 5; gi = gi + 1) begin
                        cand = {1'b0, rr[i]} + gi;
                        if (cand >= 4'd5) cand = cand - 4'd5;
                        if (!vc_cand_vld[i] &&
                            head_vld[{28'b0, cand}*N_VC + i % N_VC] &&
                            req_port[{28'b0, cand}*N_VC + i % N_VC] == (i/N_VC) &&
                            head_flit[{28'b0, cand}*N_VC + i % N_VC][PAYLOAD_W+11]) begin
                            vc_cand[i]     = cand[2:0];
                            vc_cand_vld[i] = 1'b1;
                        end
                    end
                end
            end
        end
    end

    // stage B: per output, pick a VC (round-robin) -> final grant
    reg [PTR_W:0] grant_vc  [0:4];        // winning VC on each output
    reg [2:0]     grant_in  [0:4];        // winning input port
    reg           grant_vld [0:4];

    reg [PTR_W+1:0] vc_i;
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            grant_vc[i]  = {(PTR_W+1){1'b0}};
            grant_in[i]  = 3'd0;
            grant_vld[i] = 1'b0;
            for (gi = 0; gi < N_VC; gi = gi + 1) begin
                vc_i = {1'b0, vrr[i]} + gi;
                if (vc_i >= N_VC) vc_i = vc_i - N_VC;
                if (!grant_vld[i] && vc_cand_vld[i*N_VC + vc_i]) begin
                    grant_vc[i]  = vc_i[PTR_W:0];
                    grant_in[i]  = vc_cand[i*N_VC + vc_i];
                    grant_vld[i] = 1'b1;
                end
            end
        end
    end

    // pop strobes (an input VC can win at most one output per cycle,
    // because a head's route is unique)
    reg [5*N_VC-1:0] pop;
    always @(*) begin
        pop = {(5*N_VC){1'b0}};
        for (i = 0; i < 5; i = i + 1)
            if (grant_vld[i])
                pop[grant[i]] = 1'b1;
    end

    assign in_credit = pop;   // registered externally? pulses are 1 cycle

    // ------------------------------------------------------------------
    // sequential: buffers, allocation state, output registers, credits
    // ------------------------------------------------------------------
    wire [FLIT_W-1:0] in_flit_a  [0:4];
    wire [N_VC-1:0]   in_vc_a    [0:4];
    generate
        for (gp = 0; gp < 5; gp = gp + 1) begin : g_ina
            assign in_flit_a[gp] = in_flit[gp*FLIT_W +: FLIT_W];
            assign in_vc_a[gp]   = in_vc[gp*N_VC +: N_VC];
        end
    endgenerate

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 5*N_VC; i = i + 1) begin
                buf_rd[i]  <= 3'd0;
                buf_wr[i]  <= 3'd0;
                buf_cnt[i] <= 3'd0;
                ocredit[i] <= BUF_DEPTH[2:0];
            end
            for (i = 0; i < 5; i = i + 1) begin
                olock[i] <= 1'b0;
                owner[i] <= {(PTR_W+1){1'b0}};
                rr[i]    <= {(PTR_W+1){1'b0}};
            end
            out_valid <= 5'b0;
            out_vc    <= {(5*N_VC){1'b0}};
            out_flit  <= {(5*FLIT_W){1'b0}};
        end else begin
            // 1. accept incoming flits into per-VC FIFOs
            for (i = 0; i < 5; i = i + 1) begin
                if (in_valid[i]) begin
                    for (v = 0; v < N_VC; v = v + 1) begin
                        if (in_vc_a[i][v]) begin
                            buf_mem[(i*N_VC+v)*BUF_DEPTH
                                    + {29'b0, buf_wr[i*N_VC+v]}]
                                <= in_flit_a[i];
                            buf_wr[i*N_VC+v] <=
                                (buf_wr[i*N_VC+v] == BUF_DEPTH-1)
                                ? 3'd0 : buf_wr[i*N_VC+v] + 3'd1;
                        end
                    end
                end
            end

            // 2. per-output: launch granted flits
            for (i = 0; i < 5; i = i + 1) begin
                if (grant_vld[i]) begin
                    out_flit[i*FLIT_W +: FLIT_W] <= head_flit[grant[i]];
                    out_valid[i] <= 1'b1;
                    out_vc[i*N_VC +: N_VC] <=
                        {{(N_VC-1){1'b0}}, 1'b1} << (grant[i] % N_VC);
                    // wormhole lock follows head/tail
                    olock[i] <= !head_flit[grant[i]][PAYLOAD_W+10]; // !tail
                    owner[i] <= grant[i];
                    if (!olock[i])
                        rr[i] <= (grant[i] == 5*N_VC-1)
                                 ? {(PTR_W+1){1'b0}} : grant[i] + 1'b1;
                end else begin
                    out_valid[i] <= 1'b0;
                    out_vc[i*N_VC +: N_VC] <= {N_VC{1'b0}};
                end
            end

            // 3. FIFO pops + credit bookkeeping
            for (i = 0; i < 5*N_VC; i = i + 1) begin
                // count: +push -pop
                case ({in_valid[i/N_VC] && in_vc_a[i/N_VC][i%N_VC], pop[i]})
                    2'b10: buf_cnt[i] <= buf_cnt[i] + 3'd1;
                    2'b01: buf_cnt[i] <= buf_cnt[i] - 3'd1;
                    default: ;
                endcase
                if (pop[i])
                    buf_rd[i] <= (buf_rd[i] == BUF_DEPTH-1)
                                 ? 3'd0 : buf_rd[i] + 3'd1;
            end

            // 4. output credits: spend on launch, recover on return
            for (i = 0; i < 5; i = i + 1) begin
                for (v = 0; v < N_VC; v = v + 1) begin
                    case ({grant_vld[i] && (grant[i] % N_VC) == v,
                           out_credit[i*N_VC+v]})
                        2'b10: ocredit[i*N_VC+v] <= ocredit[i*N_VC+v] - 3'd1;
                        2'b01: ocredit[i*N_VC+v] <= ocredit[i*N_VC+v] + 3'd1;
                        default: ;
                    endcase
                end
            end
        end
    end

endmodule
