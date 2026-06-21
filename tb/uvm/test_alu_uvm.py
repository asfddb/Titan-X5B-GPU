import cocotb
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.clock import Clock
import pyuvm
from pyuvm import *
import random

# Opcodes
OP_ADD  = 0
OP_SUB  = 1
OP_MUL  = 2
OP_DIV  = 3
OP_AND  = 5
OP_OR   = 6
OP_XOR  = 7

class AluSeqItem(uvm_sequence_item):
    def __init__(self, name="AluSeqItem", opcode=0, src1=0, src2=0):
        super().__init__(name)
        self.opcode = opcode
        self.src1 = src1
        self.src2 = src2
        self.result = 0

    def randomize(self):
        self.opcode = random.choice([OP_ADD, OP_SUB, OP_MUL, OP_DIV, OP_AND, OP_OR, OP_XOR])
        self.src1 = random.randint(0, 0xFFFFFFFF)
        self.src2 = random.randint(0, 0xFFFFFFFF)
        if self.opcode == OP_DIV and self.src2 == 0:
            self.src2 = 1 # avoid division by zero

class AluSeq(uvm_sequence):
    async def body(self):
        for _ in range(100):
            item = AluSeqItem("item")
            await self.start_item(item)
            item.randomize()
            await self.finish_item(item)

class AluDriver(uvm_driver):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    def connect_phase(self):
        self.dut = cocotb.top
        self.writeback_schedule = {} # cycle_num -> True
        
    async def run_phase(self):
        self.dut.valid_in.value = 0
        self.dut.stall_in.value = 0
        cycle = 0
        
        # Start a parallel task to track time
        cocotb.start_soon(self.track_cycles())
        
        while True:
            item = await self.seq_item_port.get_next_item()
            
            # Determine latency of current instruction
            latency = 0
            if item.opcode in [OP_ADD, OP_SUB, OP_AND, OP_OR, OP_XOR]:
                latency = 3
            elif item.opcode == OP_MUL:
                latency = 4
            elif item.opcode == OP_DIV:
                latency = 34 # Approximate worst-case or assume variable
            else:
                latency = 6 # FP
            
            # Wait until ready_out is 1 AND no structural writeback collision
            while True:
                if self.dut.ready_out.value == 1:
                    if item.opcode == OP_DIV:
                        break # Division blocks ready_out anyway
                    target_cycle = self.current_cycle + latency
                    if target_cycle not in self.writeback_schedule:
                        self.writeback_schedule[target_cycle] = True
                        break
                
                self.dut.valid_in.value = 0
                await RisingEdge(self.dut.clk)
            
            self.dut.valid_in.value = 1
            self.dut.opcode.value = item.opcode
            self.dut.src1.value = item.src1
            self.dut.src2.value = item.src2
            self.dut.src3.value = 0
            
            self.ap.write(item)

            await RisingEdge(self.dut.clk)
            self.dut.valid_in.value = 0
            self.seq_item_port.item_done()

    async def track_cycles(self):
        self.current_cycle = 0
        while True:
            await RisingEdge(self.dut.clk)
            self.current_cycle += 1
            # Clean up old schedule
            if (self.current_cycle - 10) in self.writeback_schedule:
                del self.writeback_schedule[self.current_cycle - 10]

class AluMonitor(uvm_monitor):
    def build_phase(self):
        self.ap = uvm_analysis_port("ap", self)

    def connect_phase(self):
        self.dut = cocotb.top

    async def run_phase(self):
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.valid_out.value == 1:
                item = AluSeqItem("res_item")
                item.result = int(self.dut.result_out.value)
                self.ap.write(item)

class AluScoreboard(uvm_component):
    def build_phase(self):
        self.exp_fifo = uvm_tlm_analysis_fifo("exp_fifo", self)
        self.act_fifo = uvm_tlm_analysis_fifo("act_fifo", self)
        
        self.expected_results = []
        self.matched_count = 0
        self.error_count = 0

    def connect_phase(self):
        pass

    def check_phase(self):
        if len(self.expected_results) > 0:
            self.logger.error(f"{len(self.expected_results)} results were dropped or not matched!")
            self.error_count += len(self.expected_results)
            
        if self.error_count == 0:
            self.logger.info(f"TEST PASSED: {self.matched_count} matches.")
        else:
            self.logger.error(f"TEST FAILED: {self.error_count} errors.")
            if self.error_count > 0:
                raise Exception("Scoreboard found mismatches or dropped transactions.")

    async def run_phase(self):
        cocotb.start_soon(self.get_expected())
        cocotb.start_soon(self.check_actual())

    async def get_expected(self):
        while True:
            exp_item = await self.exp_fifo.get()
            op = exp_item.opcode
            s1 = exp_item.src1
            s2 = exp_item.src2
            
            exp_res = 0
            if op == OP_ADD:
                exp_res = (s1 + s2) & 0xFFFFFFFF
            elif op == OP_SUB:
                exp_res = (s1 - s2) & 0xFFFFFFFF
            elif op == OP_MUL:
                exp_res = (s1 * s2) & 0xFFFFFFFF
            elif op == OP_DIV:
                if s2 != 0:
                    exp_res = int(s1 // s2) & 0xFFFFFFFF
                else:
                    exp_res = 0xFFFFFFFF
            elif op == OP_AND:
                exp_res = (s1 & s2) & 0xFFFFFFFF
            elif op == OP_OR:
                exp_res = (s1 | s2) & 0xFFFFFFFF
            elif op == OP_XOR:
                exp_res = (s1 ^ s2) & 0xFFFFFFFF
            else:
                continue

            self.expected_results.append((op, s1, s2, exp_res))

    async def check_actual(self):
        while True:
            act_item = await self.act_fifo.get()
            act_res = act_item.result
            
            found = False
            for i, (op, s1, s2, exp) in enumerate(self.expected_results):
                if exp == act_res:
                    found = True
                    self.expected_results.pop(i)
                    self.matched_count += 1
                    self.logger.info(f"MATCH: Op={op} src1={hex(s1)} src2={hex(s2)} res={hex(act_res)}")
                    break
            
            if not found:
                self.logger.error(f"MISMATCH or UNEXPECTED RESULT: {hex(act_res)}")
                self.error_count += 1

class AluAgent(uvm_agent):
    def build_phase(self):
        self.seqr = uvm_sequencer("seqr", self)
        self.drv = AluDriver("drv", self)
        self.mon = AluMonitor("mon", self)

    def connect_phase(self):
        self.drv.seq_item_port.connect(self.seqr.seq_item_export)

class AluEnv(uvm_env):
    def build_phase(self):
        self.agent = AluAgent("agent", self)
        self.sb = AluScoreboard("sb", self)

    def connect_phase(self):
        self.agent.drv.ap.connect(self.sb.exp_fifo.analysis_export)
        self.agent.mon.ap.connect(self.sb.act_fifo.analysis_export)

@pyuvm.test()
class AluTest(uvm_test):
    def build_phase(self):
        self.env = AluEnv("env", self)

    async def run_phase(self):
        self.raise_objection()
        
        dut = cocotb.top
        clock = Clock(dut.clk, 10, units="ns")
        cocotb.start_soon(clock.start())
        
        dut.rst_n.value = 0
        dut.valid_in.value = 0
        dut.stall_in.value = 0
        dut.opcode.value = 0
        dut.src1.value = 0
        dut.src2.value = 0
        dut.src3.value = 0
        
        await ClockCycles(dut.clk, 5)
        dut.rst_n.value = 1
        await ClockCycles(dut.clk, 5)

        seq = AluSeq("seq")
        await seq.start(self.env.agent.seqr)
        
        await ClockCycles(dut.clk, 100) # Wait for pipeline to flush
        
        self.drop_objection()
