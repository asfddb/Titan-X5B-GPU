//===-- TitanX5InstrInfo.td - Target Description for TitanX5 ---*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes the Titan X5 instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

class TitanX5Inst<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  field bits<32> Inst;
  
  let Namespace = "TitanX5";
  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

//===----------------------------------------------------------------------===//
// Titan X5 Registers
//===----------------------------------------------------------------------===//

class TitanX5Reg<bits<5> Enc, string n> : Register<n> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "TitanX5";
}

// General Purpose Registers
def R0  : TitanX5Reg<0, "r0">;
def R1  : TitanX5Reg<1, "r1">;
def R2  : TitanX5Reg<2, "r2">;
def R3  : TitanX5Reg<3, "r3">;
def R4  : TitanX5Reg<4, "r4">;
def R5  : TitanX5Reg<5, "r5">;
def R6  : TitanX5Reg<6, "r6">;
def R7  : TitanX5Reg<7, "r7">;
// Skipped 8-30 for brevity in conceptual example
def R31 : TitanX5Reg<31, "r31">;

// Register class
def GPR : RegisterClass<"TitanX5", [i32], 32, (add R0, R1, R2, R3, R4, R5, R6, R7, R31)>;

//===----------------------------------------------------------------------===//
// Instruction Formats
//===----------------------------------------------------------------------===//

// R-Type: Opcode(6) | Rd(5) | Rs1(5) | Rs2(5) | Func(11)
class RType<bits<6> op, bits<11> func, dag outs, dag ins, string asmstr,
            list<dag> pattern> : TitanX5Inst<outs, ins, asmstr, pattern> {
  bits<5> rd;
  bits<5> rs1;
  bits<5> rs2;

  let Inst{31-26} = op;
  let Inst{25-21} = rd;
  let Inst{20-16} = rs1;
  let Inst{15-11} = rs2;
  let Inst{10-0}  = func;
}

// I-Type: Opcode(6) | Rd(5) | Rs1(5) | Imm(16)
class IType<bits<6> op, dag outs, dag ins, string asmstr, list<dag> pattern>
    : TitanX5Inst<outs, ins, asmstr, pattern> {
  bits<5> rd;
  bits<5> rs1;
  bits<16> imm16;

  let Inst{31-26} = op;
  let Inst{25-21} = rd;
  let Inst{20-16} = rs1;
  let Inst{15-0}  = imm16;
}

// J-Type: Opcode(6) | Target(26)
class JType<bits<6> op, dag outs, dag ins, string asmstr, list<dag> pattern>
    : TitanX5Inst<outs, ins, asmstr, pattern> {
  bits<26> target;

  let Inst{31-26} = op;
  let Inst{25-0}  = target;
}

//===----------------------------------------------------------------------===//
// ALU Instructions
//===----------------------------------------------------------------------===//

def ADD : RType<0x00, 0x001, (outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
                "add $rd, $rs1, $rs2",
                [(set i32:$rd, (add i32:$rs1, i32:$rs2))]>;

def SUB : RType<0x00, 0x002, (outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
                "sub $rd, $rs1, $rs2",
                [(set i32:$rd, (sub i32:$rs1, i32:$rs2))]>;

def AND : RType<0x00, 0x003, (outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
                "and $rd, $rs1, $rs2",
                [(set i32:$rd, (and i32:$rs1, i32:$rs2))]>;

def OR  : RType<0x00, 0x004, (outs GPR:$rd), (ins GPR:$rs1, GPR:$rs2),
                "or $rd, $rs1, $rs2",
                [(set i32:$rd, (or i32:$rs1, i32:$rs2))]>;

def ADDI : IType<0x01, (outs GPR:$rd), (ins GPR:$rs1, i32imm:$imm16),
                 "addi $rd, $rs1, $imm16",
                 [(set i32:$rd, (add i32:$rs1, imm:$imm16))]>;

//===----------------------------------------------------------------------===//
// Memory Instructions
//===----------------------------------------------------------------------===//

// Load Word
def LW : IType<0x02, (outs GPR:$rd), (ins GPR:$rs1, i32imm:$imm16),
               "lw $rd, $imm16($rs1)",
               [(set i32:$rd, (load (add i32:$rs1, imm:$imm16)))]>;

// Store Word
def SW : IType<0x03, (outs), (ins GPR:$rd, GPR:$rs1, i32imm:$imm16),
               "sw $rd, $imm16($rs1)", 
               [(store i32:$rd, (add i32:$rs1, imm:$imm16))]>;

//===----------------------------------------------------------------------===//
// Branch / Jump Instructions
//===----------------------------------------------------------------------===//

def BEQ : IType<0x04, (outs), (ins GPR:$rd, GPR:$rs1, i32imm:$imm16),
                "beq $rd, $rs1, $imm16",
                []>;

def BNE : IType<0x05, (outs), (ins GPR:$rd, GPR:$rs1, i32imm:$imm16),
                "bne $rd, $rs1, $imm16",
                []>;

def JMP : JType<0x06, (outs), (ins i32imm:$target),
                "jmp $target",
                []>;
