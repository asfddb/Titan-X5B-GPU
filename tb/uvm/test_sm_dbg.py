"""Temporary debug probe for the X7 SM front end."""
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, ClockCycles

from test_sm_x7 import enc, NOP, imem_model


@cocotb.test()
async def sm_dbg(dut):
    Clock(dut.clk, 10, "ns").start()
    dut.rst_n.value = 0
    dut.warp_active.value = 0
    dut.warp_pc_in.value = 0
    dut.imem_resp_valid.value = 0
    dut.dmem_resp_valid.value = 0
    dut.dmem_req_ready.value = 1
    dut.dbg_warp.value = 0
    dut.dbg_reg.value = 1
    await ClockCycles(dut.clk, 5)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)

    prog = {0: enc("ADD", rd=1, rs1=0, imm=5),
            4: enc("ADD", rd=2, rs1=1, imm=7)}
    cocotb.start_soon(imem_model(dut, prog))

    dut.warp_active.value = 1
    dut.dbg_reg.value = 2
    for cyc in range(40):
        await FallingEdge(dut.clk)
        dut._log.info(
            "c%02d cnt=%s rd=%s wr=%s hin=%08x iss=%s s0=%s s0w=%s s1=%s s1w=%s wbi=%s wbird=%s r2=%s",
            cyc,
            dut.ib_cnt[0].value,
            dut.ib_rd[0].value, dut.ib_wr[0].value,
            int(dut.head_inst[0].value) if dut.head_inst[0].value.is_resolvable else -1,
            dut.issueable.value,
            dut.sel0_v.value, dut.sel0_w.value,
            dut.sel1_v.value, dut.sel1_w.value,
            dut.wb_int_v.value, dut.wb_int_rd.value,
            int(dut.dbg_rdata.value) & 0xFFFFFFFF)
