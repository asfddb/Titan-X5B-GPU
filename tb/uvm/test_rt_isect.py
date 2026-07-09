import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer

def float_to_q16(val):
    return int(val * 65536.0) & 0xFFFFFFFF

def q16_to_float(val):
    if val & 0x80000000:
        val = val - 0x100000000
    return val / 65536.0

@cocotb.test()
async def test_ray_isect(dut):
    clock = Clock(dut.clk, 2, units="ns") # 500 MHz
    cocotb.start_soon(clock.start())
    
    dut.rst_n.value = 0
    dut.valid_in.value = 0
    dut.tag_in.value = 0
    
    await Timer(10, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # Ray origin: (0, 0, 0)
    # Ray dir: (0, 0, 1)
    dut.ray_o_x.value = float_to_q16(0.0)
    dut.ray_o_y.value = float_to_q16(0.0)
    dut.ray_o_z.value = float_to_q16(0.0)
    dut.ray_d_x.value = float_to_q16(0.0)
    dut.ray_d_y.value = float_to_q16(0.0)
    dut.ray_d_z.value = float_to_q16(1.0)
    
    # Triangle: (-1, -1, 5), (1, -1, 5), (0, 1, 5)
    dut.v0_x.value = float_to_q16(-1.0)
    dut.v0_y.value = float_to_q16(-1.0)
    dut.v0_z.value = float_to_q16(5.0)
    
    dut.v1_x.value = float_to_q16(1.0)
    dut.v1_y.value = float_to_q16(-1.0)
    dut.v1_z.value = float_to_q16(5.0)
    
    dut.v2_x.value = float_to_q16(0.0)
    dut.v2_y.value = float_to_q16(1.0)
    dut.v2_z.value = float_to_q16(5.0)
    
    dut.valid_in.value = 1
    dut.tag_in.value = 42
    
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    
    # Wait for latency (14 cycles)
    for i in range(20):
        await RisingEdge(dut.clk)
        if dut.valid_out.value == 1:
            is_hit = dut.is_hit.value
            t = q16_to_float(int(dut.t_out.value))
            u = q16_to_float(int(dut.u_out.value))
            v = q16_to_float(int(dut.v_out.value))
            tag = int(dut.tag_out.value)
            
            dut._log.info(f"Result -> Hit: {is_hit}, t: {t}, u: {u}, v: {v}, tag: {tag}")
            assert tag == 42, "Tag mismatch!"
            assert is_hit == 1, "Should be a hit!"
            # Expected intersection at z=5
            assert abs(t - 5.0) < 0.1, f"Expected t=5.0, got {t}"
            return
            
    assert False, "Pipeline did not output valid result within expected latency!"
