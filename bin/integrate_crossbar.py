import re

def main():
    with open('rtl/titan_x5_gpu_top.v', 'r') as f:
        content = f.read()

    # We will manually perform the surgical edits using regex or string replace.
    
    # 1. Add the crossbar wires at the top of the declarations.
    # Find the block of declarations.
    decl_marker = "    wire        cmd_mem_req;"
    
    crossbar_wires = """    // Crossbar Interface
    wire [16:0] xbar_m_req_valid;
    wire [17*32-1:0] xbar_m_req_addr;
    wire [17*32-1:0] xbar_m_req_wdata;
    wire [16:0] xbar_m_req_write;
    wire [16:0] xbar_m_req_ready;
    wire [16:0] xbar_m_resp_valid;
    wire [17*32-1:0] xbar_m_resp_rdata;

    wire [0:0] xbar_s_req_valid;
    wire [31:0]  xbar_s_req_addr;
    wire [31:0]  xbar_s_req_wdata;
    wire [0:0] xbar_s_req_write;
    wire [0:0] xbar_s_req_ready;
    wire [0:0] xbar_s_resp_valid;
    wire [31:0]  xbar_s_resp_rdata;

    // Helper wires for modules
    wire [31:0] sm_icache_addr [0:3];
    wire [3:0]  sm_icache_req;
    wire [31:0] sm_dcache_addr [0:3];
    wire [31:0] sm_dcache_wdata [0:3];
    wire [3:0]  sm_dcache_req;
    wire [3:0]  sm_dcache_we;
    
    wire [31:0] tmu_mem_addr [0:3];
    wire [3:0]  tmu_mem_req;
    
    wire [31:0] rop_m_addr [0:3];
    wire [31:0] rop_m_wdata [0:3];
    wire [3:0]  rop_m_req;
    wire [3:0]  rop_m_we;
"""
    content = content.replace(decl_marker, crossbar_wires + "\n" + decl_marker)

    # 2. Assign the masters to the crossbar wires.
    # We will inject this before the Command Processor.
    assignment_block = """
    // -------------------------------------------------------------------------
    // CROSSBAR MASTER ASSIGNMENTS
    // Master 0: Command Processor
    assign xbar_m_req_valid[0] = cmd_mem_req;
    assign xbar_m_req_addr[31:0] = cmd_mem_addr;
    assign xbar_m_req_wdata[31:0] = cmd_mem_data[31:0];
    assign xbar_m_req_write[0] = 1'b0; // CmdProc currently only reads in this test
    // cmd_mem_ack is handled by xbar_m_req_ready[0]

    // Masters 1-4: TMUs
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : tmu_xbar_assign
            assign xbar_m_req_valid[1+gi] = tmu_mem_req[gi];
            assign xbar_m_req_addr[(1+gi)*32 +: 32] = tmu_mem_addr[gi];
            assign xbar_m_req_wdata[(1+gi)*32 +: 32] = 32'h0;
            assign xbar_m_req_write[1+gi] = 1'b0;
        end
    endgenerate

    // Masters 5-8: ROPs
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : rop_xbar_assign
            assign xbar_m_req_valid[5+gi] = rop_m_req[gi];
            assign xbar_m_req_addr[(5+gi)*32 +: 32] = rop_m_addr[gi];
            assign xbar_m_req_wdata[(5+gi)*32 +: 32] = rop_m_wdata[gi];
            assign xbar_m_req_write[5+gi] = rop_m_we[gi];
        end
    endgenerate

    // Masters 9-12: SM I-Caches
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : sm_i_xbar_assign
            assign xbar_m_req_valid[9+gi] = sm_icache_req[gi];
            assign xbar_m_req_addr[(9+gi)*32 +: 32] = sm_icache_addr[gi];
            assign xbar_m_req_wdata[(9+gi)*32 +: 32] = 32'h0;
            assign xbar_m_req_write[9+gi] = 1'b0;
        end
    endgenerate

    // Masters 13-16: SM D-Caches
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : sm_d_xbar_assign
            assign xbar_m_req_valid[13+gi] = sm_dcache_req[gi];
            assign xbar_m_req_addr[(13+gi)*32 +: 32] = sm_dcache_addr[gi];
            assign xbar_m_req_wdata[(13+gi)*32 +: 32] = sm_dcache_wdata[gi];
            assign xbar_m_req_write[13+gi] = sm_dcache_we[gi];
        end
    endgenerate

    // Crossbar Instantiation
    titan_x5_crossbar #(
        .NUM_MASTERS(17),
        .NUM_SLAVES(1),
        .DATA_WIDTH(32),
        .ADDR_WIDTH(32)
    ) u_sys_crossbar (
        .clk(clk),
        .rst_n(rst_n),
        .m_req_valid(xbar_m_req_valid),
        .m_req_addr(xbar_m_req_addr),
        .m_req_wdata(xbar_m_req_wdata),
        .m_req_write(xbar_m_req_write),
        .m_req_ready(xbar_m_req_ready),
        .m_resp_valid(xbar_m_resp_valid),
        .m_resp_rdata(xbar_m_resp_rdata),
        .s_req_valid(xbar_s_req_valid),
        .s_req_addr(xbar_s_req_addr),
        .s_req_wdata(xbar_s_req_wdata),
        .s_req_write(xbar_s_req_write),
        .s_req_ready(xbar_s_req_ready),
        .s_resp_valid(xbar_s_resp_valid),
        .s_resp_rdata(xbar_s_resp_rdata)
    );
"""
    cmd_proc_inst = "    titan_x5_command_processor u_cmd_proc ("
    content = content.replace(cmd_proc_inst, assignment_block + "\n" + cmd_proc_inst)

    # Replace Command processor mem_ack
    content = re.sub(r'\.mem_ack\s*\(cmd_mem_ack\)', '.mem_ack(xbar_m_req_ready[0])', content)

    # 3. Fix SM Instantiations
    sm_search = r'\.l1_icache_addr\s*\(\),\s*\.l1_icache_req\(\),\s*\.l1_icache_rdata\(32\'h0\),\s*\.l1_icache_rvalid\(1\'b1\)'
    sm_replace = '.l1_icache_addr(sm_icache_addr[gi]), .l1_icache_req(sm_icache_req[gi]), .l1_icache_rdata(xbar_m_resp_rdata[(9+gi)*32 +: 32]), .l1_icache_rvalid(xbar_m_resp_valid[9+gi])'
    content = re.sub(sm_search, sm_replace, content)

    sm_d_search = r'\.l1_dcache_addr\s*\(\),\s*\.l1_dcache_wdata\(\),\s*\.l1_dcache_req\(\),\s*\.l1_dcache_we\(\),\s*\.l1_dcache_rdata\(32\'h0\),\s*\.l1_dcache_rvalid\(1\'b1\)'
    sm_d_replace = '.l1_dcache_addr(sm_dcache_addr[gi]), .l1_dcache_wdata(sm_dcache_wdata[gi]), .l1_dcache_req(sm_dcache_req[gi]), .l1_dcache_we(sm_dcache_we[gi]), .l1_dcache_rdata(xbar_m_resp_rdata[(13+gi)*32 +: 32]), .l1_dcache_rvalid(xbar_m_resp_valid[13+gi])'
    content = re.sub(sm_d_search, sm_d_replace, content)

    # 4. Fix TMU Instantiation
    tmu_0_search = r'\.mem_req\(\),\s*\.mem_gnt\(1\'b1\),\s*\.mem_addr\(\),\s*\.mem_valid\(1\'b1\),\s*\.mem_rdata\(32\'hFFFFFFFF\)'
    tmu_0_replace = '.mem_req(tmu_mem_req[gi]), .mem_gnt(xbar_m_req_ready[1+gi]), .mem_addr(tmu_mem_addr[gi]), .mem_valid(xbar_m_resp_valid[1+gi]), .mem_rdata(xbar_m_resp_rdata[(1+gi)*32 +: 32])'
    content = re.sub(tmu_0_search, tmu_0_replace, content)
    
    tmu_n_search = r'\.mem_req\(\),\s*\.mem_gnt\(1\'b1\),\s*\.mem_addr\(\),\s*\.mem_valid\(1\'b1\),\s*\.mem_rdata\(32\'h0\)'
    tmu_n_replace = tmu_0_replace
    content = re.sub(tmu_n_search, tmu_n_replace, content)

    # 5. Fix ROP Instantiation
    # ROP 0 was hotwired to memory controller.
    rop_0_search = r'\.mem_req\(rop_mem_req\),\s*\.mem_we\(rop_mem_we\),\s*\.mem_addr\(rop_mem_addr\),\s*\.mem_wdata\(rop_mem_wdata\),\s*\.mem_gnt\(mc_req_ready\),\s*\.mem_valid\(1\'b1\),\s*\.mem_rdata\(32\'h0\)'
    rop_0_replace = '.mem_req(rop_m_req[gi]), .mem_we(rop_m_we[gi]), .mem_addr(rop_m_addr[gi]), .mem_wdata(rop_m_wdata[gi]), .mem_gnt(xbar_m_req_ready[5+gi]), .mem_valid(xbar_m_resp_valid[5+gi]), .mem_rdata(xbar_m_resp_rdata[(5+gi)*32 +: 32])'
    content = re.sub(rop_0_search, rop_0_replace, content)

    # ROP N
    rop_n_search = r'\.mem_req\(\),\s*\.mem_we\(\),\s*\.mem_addr\(\),\s*\.mem_wdata\(\),\s*\.mem_gnt\(1\'b1\),\s*\.mem_valid\(1\'b1\),\s*\.mem_rdata\(32\'h0\)'
    rop_n_replace = rop_0_replace
    content = re.sub(rop_n_search, rop_n_replace, content)

    # 6. Remove the hardcoded dummy ack for CmdProc and ROP
    # Remove: `reg cmd_mem_ack_r; always @(posedge clk) ...`
    dummy_ack_pattern = r'reg\s+cmd_mem_ack_r;\s*always\s*@\(posedge\s*clk\)\s*begin[\s\S]*?assign\s+cmd_mem_ack\s*=\s*cmd_mem_ack_r;'
    content = re.sub(dummy_ack_pattern, '', content)
    
    # 7. Wire Memory Controller to Crossbar Slave 0
    # Find `wire [255:0] rop_wdata_256 = {8{rop_mem_wdata}};` and remove it
    content = re.sub(r'wire\s*\[255:0\]\s*rop_wdata_256\s*=\s*\{8\{rop_mem_wdata\}\};', '', content)
    
    # Replace Memory Controller request inputs
    mc_req_search = r'\.req_valid\s*\(rop_mem_req\),\s*\.req_addr\s*\(rop_mem_addr\),\s*\.req_write\s*\(rop_mem_we\),\s*\.req_wdata\s*\(rop_wdata_256\),\s*\.req_len\s*\(4\'h0\),\s*\.req_ready\s*\(mc_req_ready\)'
    mc_req_replace = '.req_valid(xbar_s_req_valid[0]), .req_addr(xbar_s_req_addr), .req_write(xbar_s_req_write[0]), .req_wdata({8{xbar_s_req_wdata}}), .req_len(4\'h0), .req_ready(xbar_s_req_ready[0])'
    content = re.sub(mc_req_search, mc_req_replace, content)
    
    # Replace memory controller resp outputs
    mc_resp_search = r'\.resp_valid\s*\(\),\s*\.resp_rdata\s*\(\)'
    mc_resp_replace = '.resp_valid(xbar_s_resp_valid[0]), .resp_rdata(xbar_s_resp_rdata)'
    content = re.sub(mc_resp_search, mc_resp_replace, content)

    with open('rtl/titan_x5_gpu_top.v', 'w') as f:
        f.write(content)

    print("GPU Top updated successfully!")

if __name__ == '__main__':
    main()
