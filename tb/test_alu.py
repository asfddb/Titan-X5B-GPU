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

OP_ADD  = 0
OP_SUB  = 1
OP_MUL  = 2
OP_DIV  = 3

@cocotb.test()
async def test_alu_add(dut):
    """Test the single-cycle integer pipeline (OP_ADD)"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.stall_in.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Inject ADD command
    dut.valid_in.value = 1
    dut.opcode.value = OP_ADD
    dut.src1.value = 50
    dut.src2.value = 75
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # ADD valid_out goes high exactly 3 cycles after injection (s1 -> s2 -> s3)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await cocotb.triggers.ReadOnly()
    
    assert dut.valid_out.value == 1, "Expected valid_out to be high!"
    assert dut.result_out.value == 125, f"Expected 125, got {int(dut.result_out.value)}"
    dut._log.info("ALU ADD passed assertion!")

@cocotb.test()
async def test_alu_mul(dut):
    """Test the 4-stage pipelined multiplier (OP_MUL)"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.stall_in.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Inject MUL command
    dut.valid_in.value = 1
    dut.opcode.value = OP_MUL
    dut.src1.value = 12
    dut.src2.value = 12
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # MUL valid_out goes high 4 cycles later
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await cocotb.triggers.ReadOnly()
    
    assert dut.valid_out.value == 1, "Expected valid_out to be high!"
    assert dut.result_out.value == 144, f"Expected 144, got {int(dut.result_out.value)}"
    dut._log.info("ALU MUL passed assertion!")

@cocotb.test()
async def test_alu_div(dut):
    """Test the 32-cycle iterative divider (OP_DIV)"""
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.stall_in.value = 0
    await Timer(20, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Inject DIV command
    dut.valid_in.value = 1
    dut.opcode.value = OP_DIV
    dut.src1.value = 100
    dut.src2.value = 4
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    await cocotb.triggers.ReadOnly()
    
    # DIV sets ready_out low while busy
    assert dut.ready_out.value == 0, "Divider should be busy!"
    
    # Wait for completion (up to 40 cycles)
    for _ in range(40):
        await RisingEdge(dut.clk)
        await cocotb.triggers.ReadOnly()
        if dut.valid_out.value == 1:
            break
            
    assert dut.valid_out.value == 1, "Divider failed to complete!"
    assert dut.result_out.value == 25, f"Expected 25, got {int(dut.result_out.value)}"
    assert dut.ready_out.value == 1, "Divider should be ready after completion!"
    dut._log.info("ALU DIV passed assertion!")
