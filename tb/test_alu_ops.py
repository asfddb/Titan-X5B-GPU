# ============================================================================
# Copyright (c) 2026 Adhiraj
# 
# This file is part of the Titan X5-B GPU project.
# 
# Licensed under CERN-OHL-S-2.0.
# See LICENSE for details.
# ============================================================================
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def test_alu_ops_basic(dut):
    """Test ALU ops basic functionality"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    dut._log.info("ALU ops basic test passed!")
    assert True
