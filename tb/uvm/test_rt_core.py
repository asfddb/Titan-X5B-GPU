# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""titan_x5_rt_core system tests: full BVH traversal over random scenes.

A Python memory model serves 384-bit BVH nodes on the tagged fetch port
(pipelined, configurable latency, optional request-ready stalls). Batches
of rays are pushed through all 8 ray slots concurrently and every result
is compared BIT-EXACTLY against rt_ref.traverse (which mirrors the exact
traversal order, pruning and fixed-point arithmetic of the RTL).

Also measures the node-fetch issue rate while the engine is saturated to
back the one-ray-box-test-per-clock throughput claim.
"""

import random

import cocotb
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles

from tb_common import start_clock_and_reset
from rt_ref import fx, fx_to_f, fx_inv_dir, build_bvh, node_to_bits, traverse

T_INF = 0x7FFFFFFF


def make_scene(rng, n_tris, spread=25.0):
    tris = []
    for tid in range(1, n_tris + 1):
        c = [rng.uniform(-spread, spread) for _ in range(3)]
        verts = []
        for _ in range(3):
            verts.append(tuple(fx(c[i] + rng.uniform(-3, 3)) for i in range(3)))
        tris.append((tid, verts[0], verts[1], verts[2]))
    return tris


def make_rays(rng, tris, n_rays, spread=25.0):
    rays = []
    for _ in range(n_rays):
        o = tuple(fx(rng.uniform(-2 * spread, 2 * spread)) for _ in range(3))
        if rng.random() < 0.8:
            tgt = rng.choice(tris)
            centre = tuple((tgt[1][i] + tgt[2][i] + tgt[3][i]) // 3
                           for i in range(3))
            d = tuple(fx((fx_to_f(centre[i]) - fx_to_f(o[i])) / 16.0)
                      for i in range(3))
        else:
            d = tuple(fx(rng.uniform(-4, 4)) for _ in range(3))
        d = tuple(c if abs(c) >= 64 else c + fx(0.3) for c in d)
        inv = tuple(fx_inv_dir(c) for c in d)
        rays.append((o, d, inv))
    return rays


class NodeMemory:
    """Pipelined tagged BVH node server."""

    def __init__(self, dut, nodes, latency=2, stall_prob=0.0, rng=None):
        self.dut = dut
        self.bits = {addr: node_to_bits(n) for addr, n in nodes.items()}
        self.latency = latency
        self.stall_prob = stall_prob
        self.rng = rng or random.Random(1)
        self.fetches = 0
        self.stop = False

    async def run(self):
        dut = self.dut
        pending = []  # (due, tag, data)
        cycle = 0
        dut.node_req_ready.value = 1
        dut.node_rsp_valid.value = 0
        while not self.stop:
            await FallingEdge(dut.clk)
            # sample request in the middle of the cycle
            if int(dut.node_req_valid.value) and int(dut.node_req_ready.value):
                addr = int(dut.node_req_addr.value)
                tag = int(dut.node_req_tag.value)
                assert addr in self.bits, f"fetch of unknown node {addr:#x}"
                pending.append((cycle + self.latency, tag, self.bits[addr]))
                self.fetches += 1
            await RisingEdge(dut.clk)
            cycle += 1
            # drive response for this cycle
            if pending and pending[0][0] <= cycle:
                _, tag, data = pending.pop(0)
                dut.node_rsp_valid.value = 1
                dut.node_rsp_tag.value = tag
                dut.node_rsp_data.value = data
            else:
                dut.node_rsp_valid.value = 0
            # next-cycle request ready
            dut.node_req_ready.value = \
                0 if self.rng.random() < self.stall_prob else 1


async def run_batch(dut, nodes, root, rays, latency=2, stall_prob=0.0,
                    seed=1):
    """Push a batch of rays through the core, return {ray_id: result}."""
    rng = random.Random(seed)
    mem = NodeMemory(dut, nodes, latency, stall_prob, rng)
    mem_task = cocotb.start_soon(mem.run())

    results = {}

    async def collect():
        while len(results) < len(rays):
            await FallingEdge(dut.clk)
            if int(dut.res_valid.value):
                rid = int(dut.res_ray_id.value)
                assert rid not in results, f"duplicate result for ray {rid}"
                results[rid] = (int(dut.res_hit.value),
                                int(dut.res_tri_id.value),
                                int(dut.res_t.value),
                                int(dut.res_u.value),
                                int(dut.res_v.value))

    col = cocotb.start_soon(collect())

    sent = 0
    idle_cycles = 0
    while sent < len(rays):
        # sample ray_ready mid-cycle (settled) and drive before the next
        # rising edge: guarantees the handshake the DUT actually sees
        await FallingEdge(dut.clk)
        if int(dut.ray_ready.value):
            o, d, inv = rays[sent]
            dut.ray_valid.value = 1
            dut.ray_id.value = sent
            dut.ray_root_ptr.value = root
            for pfx, vec in (("ray_o", o), ("ray_d", d), ("ray_inv_d", inv)):
                for ax, val in zip("xyz", vec):
                    getattr(dut, f"{pfx}_{ax}").value = val & 0xFFFFFFFF
            sent += 1
        else:
            dut.ray_valid.value = 0
    await FallingEdge(dut.clk)
    dut.ray_valid.value = 0

    # wait for all results (bounded)
    for _ in range(200000):
        if len(results) == len(rays):
            break
        await ClockCycles(dut.clk, 10)
        idle_cycles += 10
    mem.stop = True
    col.kill()
    mem_task.kill()
    dut.node_rsp_valid.value = 0
    assert len(results) == len(rays), \
        f"only {len(results)}/{len(rays)} rays completed (deadlock?)"
    return results, mem.fetches


def check_results(rays, nodes, root, results):
    mism = 0
    hits = 0
    for rid, (o, d, inv) in enumerate(rays):
        exp = traverse(nodes, root, o, d, inv)
        got = results[rid]
        e_hit, e_tid, e_t, e_u, e_v = exp
        g_hit, g_tid, g_t, g_u, g_v = got
        ok = (g_hit == int(e_hit) and g_tid == e_tid and g_t == (e_t & 0xFFFFFFFF)
              and g_u == (e_u & 0xFFFFFFFF) and g_v == (e_v & 0xFFFFFFFF))
        if not ok:
            mism += 1
            print(f"ray {rid}: got hit={g_hit} tri={g_tid} t={g_t:#x} "
                  f"u={g_u:#x} v={g_v:#x} | exp hit={e_hit} tri={e_tid} "
                  f"t={e_t:#x} u={e_u:#x} v={e_v:#x}")
        if g_hit:
            hits += 1
    assert mism == 0, f"{mism}/{len(rays)} rays mismatched the golden model"
    return hits


@cocotb.test()
async def test_single_triangle(dut):
    """Smallest possible BVH: one leaf, one ray, known answer."""
    dut.ray_valid.value = 0
    dut.node_rsp_valid.value = 0
    dut.node_req_ready.value = 1
    dut.node_rsp_tag.value = 0
    dut.node_rsp_data.value = 0
    await start_clock_and_reset(dut)
    tri = (1,
           (fx(0), fx(0), fx(5)), (fx(4), fx(0), fx(5)), (fx(0), fx(4), fx(5)))
    nodes, root = build_bvh([tri])
    d = (fx(0), fx(0), fx(1))
    rays = [((fx(1), fx(1), fx(0)), d, tuple(fx_inv_dir(c) for c in d))]
    results, _ = await run_batch(dut, nodes, root, rays)
    hits = check_results(rays, nodes, root, results)
    assert hits == 1
    t = results[0][2]
    assert abs(fx_to_f(t) - 5.0) < 0.01, f"t={fx_to_f(t)}"


@cocotb.test()
async def test_random_scenes_bitexact(dut):
    """Random scenes/rays, exact vs golden traversal; varied mem latency."""
    dut.ray_valid.value = 0
    dut.node_rsp_valid.value = 0
    dut.node_req_ready.value = 1
    dut.node_rsp_tag.value = 0
    dut.node_rsp_data.value = 0
    await start_clock_and_reset(dut)
    rng = random.Random(0x5EED)

    for scene_i, (n_tris, n_rays, lat, stall) in enumerate(
            [(64, 48, 2, 0.0), (128, 48, 3, 0.2), (200, 32, 1, 0.0)]):
        tris = make_scene(rng, n_tris)
        nodes, root = build_bvh(tris)
        rays = make_rays(rng, tris, n_rays)
        results, fetches = await run_batch(
            dut, nodes, root, rays, latency=lat, stall_prob=stall,
            seed=scene_i + 7)
        hits = check_results(rays, nodes, root, results)
        dut._log.info(f"scene {scene_i}: {n_tris} tris, {n_rays} rays, "
                      f"{hits} hits, {fetches} node fetches")
        assert hits > 0, "scene produced no hits at all"


@cocotb.test()
async def test_throughput_saturated(dut):
    """With all 8 ray slots busy and an unstalled 1-cycle memory, the core
    must sustain a high node-test issue rate (target ~1/cycle)."""
    dut.ray_valid.value = 0
    dut.node_rsp_valid.value = 0
    dut.node_req_ready.value = 1
    dut.node_rsp_tag.value = 0
    dut.node_rsp_data.value = 0
    await start_clock_and_reset(dut)
    rng = random.Random(0xFA57)
    tris = make_scene(rng, 256)
    nodes, root = build_bvh(tris)
    rays = make_rays(rng, tris, 64)

    mem = NodeMemory(dut, nodes, latency=1, stall_prob=0.0)
    mem_task = cocotb.start_soon(mem.run())

    results = {}

    async def collect():
        while True:
            await FallingEdge(dut.clk)
            if int(dut.res_valid.value):
                results[int(dut.res_ray_id.value)] = True

    col = cocotb.start_soon(collect())

    # keep every slot fed
    sent = 0
    cycles = 0
    busy_cycles = 0
    issues = 0
    while len(results) < len(rays) and cycles < 100000:
        await FallingEdge(dut.clk)
        cycles += 1
        if int(dut.busy.value) and sent == len(rays):
            busy_cycles += 1
            if int(dut.node_req_valid.value) and int(dut.node_req_ready.value):
                issues += 1
        if sent < len(rays) and int(dut.ray_ready.value):
            o, d, inv = rays[sent]
            dut.ray_valid.value = 1
            dut.ray_id.value = sent
            dut.ray_root_ptr.value = root
            for pfx, vec in (("ray_o", o), ("ray_d", d), ("ray_inv_d", inv)):
                for ax, val in zip("xyz", vec):
                    getattr(dut, f"{pfx}_{ax}").value = val & 0xFFFFFFFF
            sent += 1
        else:
            dut.ray_valid.value = 0

    mem.stop = True
    col.kill()
    mem_task.kill()
    assert len(results) == len(rays), \
        f"only {len(results)}/{len(rays)} rays completed"
    rate = mem.fetches / max(cycles, 1)
    dut._log.info(f"saturated throughput: {mem.fetches} fetches in {cycles} "
                  f"cycles = {rate:.2f} node tests/cycle")
    # with 8 rays resident and a 1-cycle memory the engine should stay busy;
    # the hard II=1 property of the box pipe is proven in test_rt_box
    assert rate > 0.5, f"issue rate {rate:.2f} too low for saturated engine"
