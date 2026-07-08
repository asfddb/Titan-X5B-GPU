# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X6 GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

FLIT_WIDTH = 64
NUM_VCS = 2
MESH_X = 2
MESH_Y = 2

def make_flit(flit_type, vc, dx, dy, payload):
    # flit_type: 2 bits (3 for HT)
    # vc: 2 bits
    # dx: 4 bits
    # dy: 4 bits
    # payload: 52 bits
    flit = (flit_type << 62) | (vc << 60) | (dx << 56) | (dy << 52) | (payload & 0xFFFFFFFFFFFFF)
    return flit

def extract_payload(flit):
    return flit & 0xFFFFFFFFFFFFF

# Flit types (must match titan_x6_noc_router.v localparams)
TYPE_BODY = 0b00
TYPE_TAIL = 0b01
TYPE_HEAD = 0b10
TYPE_HT   = 0b11


def flit_type(flit):
    return (flit >> 62) & 0x3

@cocotb.test()
async def test_xy_routing_vc(dut):
    """Test XY routing and Virtual Channels in the 2D mesh."""
    
    clock = Clock(dut.clk, 1, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.local_in_flit.value = 0
    dut.local_in_valid.value = 0
    dut.local_out_credit.value = 0
    
    await Timer(5, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # We will send a packet from Node 0 (0,0) to Node 3 (1,1)
    # Node ID = y * MESH_X + x
    src_node = 0
    dst_x, dst_y = 1, 1
    dst_node = dst_y * MESH_X + dst_x
    
    # Send on VC0
    vc0_payload = 0xDEADBEEFCAFE
    flit_vc0 = make_flit(3, 0, dst_x, dst_y, vc0_payload)
    
    # Set up credit for the destination
    # Set all credits high initially (infinite sink)
    dut.local_out_credit.value = (1 << (MESH_X * MESH_Y * NUM_VCS)) - 1
    
    # Inject packet
    local_in_valid_val = 1 << src_node
    
    # To assign to a specific slice of local_in_flit, we need to read the whole array, modify and write
    current_flits = dut.local_in_flit.value.integer
    current_flits |= (flit_vc0 << (src_node * FLIT_WIDTH))
    
    dut.local_in_flit.value = current_flits
    dut.local_in_valid.value = local_in_valid_val
    
    await RisingEdge(dut.clk)
    
    # Wait for one cycle and de-assert valid
    dut.local_in_valid.value = 0
    
    # Wait for the packet to arrive at Node 3
    # It should take at least Manhattan distance hops (2) * Pipeline stages
    arrived = False
    for _ in range(20):
        await RisingEdge(dut.clk)
        out_valid = dut.local_out_valid.value.integer
        if (out_valid & (1 << dst_node)):
            out_flits = dut.local_out_flit.value.integer
            dst_flit = (out_flits >> (dst_node * FLIT_WIDTH)) & ((1 << FLIT_WIDTH) - 1)
            payload = extract_payload(dst_flit)
            assert payload == vc0_payload, f"Expected {hex(vc0_payload)}, got {hex(payload)}"
            arrived = True
            break
            
    assert arrived, "Packet on VC0 did not arrive at destination"
    
    # Now send another packet on VC1 from Node 2 (0, 1) to Node 1 (1, 0)
    src_node = 2
    dst_x, dst_y = 1, 0
    dst_node = dst_y * MESH_X + dst_x
    
    vc1_payload = 0xCAFEBABE1234
    flit_vc1 = make_flit(3, 1, dst_x, dst_y, vc1_payload)
    
    current_flits = 0
    current_flits |= (flit_vc1 << (src_node * FLIT_WIDTH))
    
    dut.local_in_flit.value = current_flits
    dut.local_in_valid.value = (1 << src_node)
    
    await RisingEdge(dut.clk)
    dut.local_in_valid.value = 0
    
    arrived = False
    for _ in range(20):
        await RisingEdge(dut.clk)
        out_valid = dut.local_out_valid.value.integer
        if (out_valid & (1 << dst_node)):
            out_flits = dut.local_out_flit.value.integer
            dst_flit = (out_flits >> (dst_node * FLIT_WIDTH)) & ((1 << FLIT_WIDTH) - 1)
            vc = (dst_flit >> 60) & 0x3
            assert vc == 1, f"Expected VC 1, got {vc}"
            payload = extract_payload(dst_flit)
            assert payload == vc1_payload, f"Expected {hex(vc1_payload)}, got {hex(payload)}"
            arrived = True
            break
            
    assert arrived, "Packet on VC1 did not arrive at destination"


@cocotb.test()
async def test_wormhole_no_interleave(dut):
    """Two multi-flit (HEAD/BODY/TAIL) packets contend for the SAME output port
    (the Local port of router (1,1)). A correct wormhole switch allocator must
    hold the output-port lock for one whole packet before serving the other, so
    the flits of each packet must arrive at the destination as a single
    contiguous, in-order run. A round-robin allocator with no output lock
    interleaves them (B0,C0,B1,C1,...) and this test catches that corruption.
    """

    clock = Clock(dut.clk, 1, units="ns")
    cocotb.start_soon(clock.start())

    dut.rst_n.value = 0
    dut.local_in_flit.value = 0
    dut.local_in_valid.value = 0
    dut.local_out_credit.value = 0
    await Timer(5, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Infinite sink: every local output VC always has credit.
    dut.local_out_credit.value = (1 << (MESH_X * MESH_Y * NUM_VCS)) - 1

    # Destination (1,1) -> node 3. Both packets travel exactly one hop and
    # collide on router (1,1)'s Local output, on the same VC (0).
    dst_x, dst_y = 1, 1
    dst_node = dst_y * MESH_X + dst_x

    # Packet B injected at node 1 = (1,0); Packet C injected at node 2 = (0,1).
    src_b = 1  # (1,0): routes South into (1,1) North input
    src_c = 2  # (0,1): routes East  into (1,1) West  input

    def pkt(pid):
        # 3 flits: HEAD (seq 0), BODY (seq 1), TAIL (seq 2), payload = pid<<8 | seq
        return [
            make_flit(TYPE_HEAD, 0, dst_x, dst_y, (pid << 8) | 0),
            make_flit(TYPE_BODY, 0, dst_x, dst_y, (pid << 8) | 1),
            make_flit(TYPE_TAIL, 0, dst_x, dst_y, (pid << 8) | 2),
        ]

    flits_b = pkt(0xB)
    flits_c = pkt(0xC)

    # Inject both packets flit-by-flit on consecutive cycles.
    for i in range(3):
        val = (flits_b[i] << (src_b * FLIT_WIDTH)) | (flits_c[i] << (src_c * FLIT_WIDTH))
        dut.local_in_flit.value = val
        dut.local_in_valid.value = (1 << src_b) | (1 << src_c)
        await RisingEdge(dut.clk)

    dut.local_in_valid.value = 0
    dut.local_in_flit.value = 0

    # Collect every flit that appears on the destination's Local output.
    arrivals = []  # list of (pid, seq, type)
    for _ in range(60):
        await RisingEdge(dut.clk)
        out_valid = dut.local_out_valid.value.integer
        if out_valid & (1 << dst_node):
            out_flits = dut.local_out_flit.value.integer
            f = (out_flits >> (dst_node * FLIT_WIDTH)) & ((1 << FLIT_WIDTH) - 1)
            payload = extract_payload(f)
            arrivals.append((payload >> 8, payload & 0xFF, flit_type(f)))
        if len(arrivals) >= 6:
            break

    # 1) Both 3-flit packets must fully arrive.
    assert len(arrivals) == 6, f"expected 6 flits, got {len(arrivals)}: {arrivals}"

    # 2) Each packet's flits must be a contiguous run in HEAD->BODY->TAIL order.
    #    Collapse consecutive equal pids into runs; a correct wormhole router
    #    yields exactly one run per packet (2 runs total). Interleaving yields
    #    more runs (e.g. B,C,B,C,B,C -> 6 runs).
    runs = []
    for pid, seq, typ in arrivals:
        if not runs or runs[-1][0] != pid:
            runs.append((pid, []))
        runs[-1][1].append((seq, typ))

    pids = [pid for pid, _, _ in arrivals]
    assert len(runs) == len(set(pids)), (
        f"wormhole violated: packets interleaved on shared output port. "
        f"arrival order = {[(hex(p), s) for p, s, _ in arrivals]}"
    )

    # 3) Within each run, flit order must be HEAD(seq0)->BODY(seq1)->TAIL(seq2).
    for pid, seqs in runs:
        got = [s for s, _ in seqs]
        assert got == [0, 1, 2], f"packet {hex(pid)} out of order: {got}"
        types = [t for _, t in seqs]
        assert types == [TYPE_HEAD, TYPE_BODY, TYPE_TAIL], (
            f"packet {hex(pid)} wrong flit types: {types}"
        )

