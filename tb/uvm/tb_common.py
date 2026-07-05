# ============================================================================
# Copyright (c) 2026 Adhiraj
#
# This file is part of the Titan X5-B GPU project.
#
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
"""Shared helpers for the Titan X5 transaction-based cocotb testbenches."""

import json
import os

from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles

VECTOR_DIR = os.path.join(os.path.dirname(__file__), "..", "vectors")


async def start_clock_and_reset(dut, reset_cycles=5):
    """Start a 10 ns clock and apply an active-low reset."""
    Clock(dut.clk, 10, "ns").start()
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, reset_cycles)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)


def load_vectors(name):
    """Load an external stimulus corpus (e.g. produced by Antigravity).

    Returns the parsed JSON or None when absent/invalid. Corpora only ever
    supply *operands/patterns*; expected values always come from the local
    reference models, so a bad corpus can never inject wrong expectations.
    """
    path = os.path.join(VECTOR_DIR, name)
    if not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        import logging
        logging.getLogger("tb_common").warning(
            "Ignoring malformed vector file %s: %s", path, exc)
        return None


def deterministic_line(addr, line_bytes):
    """Deterministic pseudo-random backing-memory content for a line."""
    val = 0
    for w in range(line_bytes // 4):
        word = (0x9E3779B9 * ((addr // line_bytes) + 0x1000193 * w + 1)) & 0xFFFFFFFF
        val |= word << (32 * w)
    return val


async def wait_pulse(dut, sig, timeout=10000):
    """Wait for a single-cycle pulse on `sig`, with a cycle timeout."""
    for _ in range(timeout):
        await RisingEdge(dut.clk)
        if int(sig.value) == 1:
            return
    raise AssertionError(f"timeout waiting for {sig._name}")
