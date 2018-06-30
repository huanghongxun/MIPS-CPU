`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Decoder
// Module Name: decoder
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2015.4
// Description: Translate original instruction into ALU op-code.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//     Instructions see http://math-atlas.sourceforge.net/devel/assembly/mips-iv.pdf
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module decoder #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 18,
    parameter REG_ADDR_WIDTH = 5
)(
    input stall,

    input [`ADDR_BUS] pc,
    input [`DATA_BUS] raw_inst,

    output reg [`VREG_BUS] rs, // register index of rs
    output reg [`VREG_BUS] rt, // register index of rt
    output reg [`VREG_BUS] rd, // register index of rd
    output reg rs_enable, // 1 if rs is valid
    output reg rt_enable, // 1 if rt is valid
    output reg [`DATA_BUS] imm, // immediate for I-type instruction.
    output reg [`INST_WIDTH-1:0] inst,
    output reg [`ALU_OP_WIDTH-1:0] exec_op, // ALU operation id.
    output reg [`ADDR_BUS] addr, // jump_target for J-type instruction.
    output reg [1:0] exec_src, // ALU, IPU, FPU, External
    output reg b_ctrl, // 1 if use immediate value instead of rt
    output reg mem_enable, // 1 if enable memory, 0 if disable memory 
    output reg wb_src, // 1 if write back from ALU, 0 if write back from memory(load inst)
    output reg wb_reg, // 1 if write to register rd.
    output [1:0] jump, // 1 if jump to imm, 2 if jump to register rt
    output branch, // 1 if this inst is a branch inst.
    output trap // 1 if this inst is a trap inst.
    );

    wire [5:0] op_wire = raw_inst[31:26]; // op-code
    wire [4:0] rs_wire = raw_inst[25:21]; // register index of rs for R/I-type instruction.
    wire [4:0] rt_wire = raw_inst[20:16]; // register index of rt for R/I-type instruction.
    wire [4:0] rd_wire = raw_inst[15:11]; // register index of rd for R-type instruction.
    wire [4:0] shamt_wire = raw_inst[10:6]; // shift amount field for R-type instruction.
    wire [5:0] funct_wire = raw_inst[5:0]; // function field for R-type instruction.
    wire [15:0] imm_wire = raw_inst[15:0]; // immediate for arithmetic instruction, or offset for branch instructions.
    wire [25:0] addr_wire = raw_inst[25:0]; // jump target address(instruction index) for J-type instruction.

    `define decode(rs_wire, rs_enable_wire, rt_wire, rt_enable_wire, rd_wire, wb_reg_wire, inst_wire, exec_op_wire, imm_wire, addr_wire, exec_src_wire, b_ctrl_wire, mem_enable_wire, wb_src_wire) \
        rs = rs_wire; \
        rs_enable = rs_enable_wire; \
        rt = rt_wire; \
        rt_enable = rt_enable_wire; \
        rd = rd_wire; \
        wb_reg = wb_reg_wire; \
        inst = inst_wire; \
        exec_op = exec_op_wire; \
        imm = imm_wire; \
        addr = addr_wire; \
        exec_src = exec_src_wire; \
        b_ctrl = b_ctrl_wire; \
        mem_enable = mem_enable_wire; \
        wb_src = wb_src_wire

    always @(raw_inst, pc)
    begin
        case (op_wire)
            6'b000000:
                case (funct_wire)
                    6'b000000: begin
                        // nop
                        if (rt_wire == 0 && rd_wire == 0 && shamt_wire == 0)
                        begin
                            `decode(0, `RS_DIS, 0, `RT_DIS, 0, `REG_N, `INST_NOP, `ALU_OP_NOP, 0, 0, `EX_NOP, `B_REG, `MEM_DIS, `WB_ALU);
                        end
                        else // sll
                        begin
                            `decode(rt_wire, `RS_EN, 0, `RT_DIS, rd_wire, `REG_WB, `INST_SLL, `ALU_OP_SLL, $unsigned(shamt_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                            if (!stall)
                                $display("%x: sll, rt: %d, sa: %d, rd: %d", pc, rt_wire, shamt_wire, rd_wire);
`endif
                        end
                    end
                    6'b000010: begin // srl
                        `decode(rt_wire, `RS_EN, 0, `RT_DIS, rd_wire, `REG_WB, `INST_SRL, `ALU_OP_SRL, $unsigned(shamt_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: srl, rt: %d, sa: %d, rd: %d", pc, rt_wire, shamt_wire, rd_wire);
`endif
                    end
                    6'b000011: begin // sra
                        `decode(rt_wire, `RS_EN, 0, `RT_DIS, rd_wire, `REG_WB, `INST_SRA, `ALU_OP_SRA, $unsigned(shamt_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sra, rt: %d, sa: %d, rd: %d", pc, rt_wire, shamt_wire, rd_wire);
`endif
                    end
                    6'b000100: begin // sllv
                        `decode(rt_wire, `RS_EN, rs_wire, `RT_EN, rd_wire, `REG_WB, `INST_SLL, `ALU_OP_SLL, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sllv, rt: %d, rs: %d, rd: %d", pc, rt_wire, rs_wire, rd_wire);
`endif
                    end
                    6'b000110: begin // srlv
                        `decode(rt_wire, `RS_EN, rs_wire, `RT_EN, rd_wire, `REG_WB, `INST_SRL, `ALU_OP_SRL, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: srlv, rt: %d, rs: %d, rd: %d", pc, rt_wire, rs_wire, rd_wire);
`endif
                    end
                    6'b000111: begin // srav
                        `decode(rt_wire, `RS_EN, rs_wire, `RT_EN, rd_wire, `REG_WB, `INST_SRA, `ALU_OP_SRA, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: srav, rt: %d, rs: %d, rd: %d", pc, rt_wire, rs_wire, rd_wire);
`endif
                    end
                    6'b001000: begin // jr
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_JR, `ALU_OP_NOP, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: jr, rs: %d", pc, rs_wire);
`endif
                    end
                    6'b001001: begin // jalr
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 31, `REG_WB, `INST_JALR, `ALU_OP_ADDU, (pc + 2), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: jalr, rs: %d, dest: %x", pc, rs_wire, (pc + 2));
`endif
                    end
                    6'b001100: begin // syscall
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `REG_N, `INST_SYSCALL, `ALU_OP_NOP, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: syscall", pc);
`endif
                    end
                    6'b010000: begin // mfhi
                        `decode(0, `RS_DIS, 0, `RT_DIS, rd_wire, `REG_WB, `INST_MFHI, `ALU_OP_MFHI, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: mfhi, rd: %d", pc, rd_wire);
`endif
                    end
                    6'b010010: begin // mflo
                        `decode(0, `RS_DIS, 0, `RT_DIS, rd_wire, `REG_WB, `INST_MFLO, `ALU_OP_MFLO, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: mflo, rd: %d", pc, rd_wire);
`endif
                    end
                    6'b011000: begin // mult
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_MUL, `ALU_OP_MUL, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: mult, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b011001: begin // multu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_MULU, `ALU_OP_MULU, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: multu, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b011010: begin // div
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_DIV, `ALU_OP_DIV, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: div, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b011011: begin // divu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_DIVU, `ALU_OP_DIVU, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: divu, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b100000: begin // add
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_ADD, `ALU_OP_ADD, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: add, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100001: begin // addu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_ADDU, `ALU_OP_ADDU, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: addu, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100010: begin // sub
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_SUB, `ALU_OP_SUB, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sub, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100011: begin // subu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_SUBU, `ALU_OP_SUBU, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: subu, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100100: begin // and
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_AND, `ALU_OP_AND, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: and, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100101: begin // or
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_OR, `ALU_OP_OR, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: or, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100110: begin // xor
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_XOR, `ALU_OP_XOR, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: xor, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100111: begin // nor
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_NOR, `ALU_OP_NOR, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: nor, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b101010: begin // slt
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_SLT, `ALU_OP_SLT, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: slt, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b101011: begin // sltu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `REG_WB, `INST_SLTU, `ALU_OP_SLTU, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sltu, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b110000: begin // TGE
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_TGE, `ALU_OP_EQ, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tge, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    6'b110001: begin // TGEU
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_TGEU, `ALU_OP_EQ, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tgeu, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    6'b110010: begin // TLT
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_TLT, `ALU_OP_EQ, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tlt, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    6'b110011: begin // TLTU
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_TLTU, `ALU_OP_EQ, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tltu, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    6'b110100: begin // TEQ
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_TEQ, `ALU_OP_EQ, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: teq, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    6'b110110: begin // TNE
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_TNE, `ALU_OP_EQ, 0, 0, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tne, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    default: begin
                        `decode(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: unknown -> %b", pc, raw_inst);
`endif
                    end
                endcase
            6'b000001:
                case (rt_wire)
                    5'b00000: begin // bltz
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_BLTZ, `ALU_OP_LT, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: bltz, rs: %d, offset: %x, dest: %x", pc, rs_wire, $signed(addr_wire), (pc + 1 + $signed(addr_wire)));
`endif
                    end
                    5'b00001: begin // bgez
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_BGEZ, `ALU_OP_GE, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: bgez, rs: %d, offset: %x, dest: %x", pc, rs_wire, $signed(addr_wire), (pc + 1 + $signed(addr_wire)));
`endif
                    end
                    default: begin
                        // should jump to exception handler.
                        `decode(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: unknown instruction %b", pc, raw_inst);
`endif
                    end
                endcase
            6'b000001: begin // regimm
                case (rt_wire)
                    5'b01000: begin // tgei
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_TGE, `ALU_OP_GE, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tgei, rs: %d, imm: %d", pc, rs_wire, $signed(imm_wire));
`endif
                    end
                    5'b01001: begin // tgeiu
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_TGEU, `ALU_OP_GEU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tgeiu, rs: %d, imm: %d", pc, rs_wire, $signed(imm_wire));
`endif
                    end
                    5'b01010: begin // tlti
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_TLT, `ALU_OP_LT, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tlti, rs: %d, imm: %d", pc, rs_wire, $signed(imm_wire));
`endif
                    end
                    5'b01011: begin // tltiu
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_TLTU, `ALU_OP_LTU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tltiu, rs: %d, imm: %d", pc, rs_wire, $signed(imm_wire));
`endif
                    end
                    5'b01100: begin // teqi
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_TEQ, `ALU_OP_EQ, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: teqi, rs: %d, imm: %d", pc, rs_wire, $signed(imm_wire));
`endif
                    end
                    5'b01110: begin // tnei
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_TNE, `ALU_OP_NE, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: tnei, rs: %d, imm: %d", pc, rs_wire, $signed(imm_wire));
`endif
                    end
                    default: begin
                        // should jump to exception handler.
                        `decode(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: unknown instruction %b", pc, raw_inst);
`endif
                    end
                endcase
            end
            6'b000010: begin // j
                // since address width less than 32, use pc <- addr instead of pc <- { pc[31:28], addr }.
                `decode(0, `RS_DIS, 0, `RT_DIS, 0, `REG_N, `INST_J, `ALU_OP_ADDU, 0, addr_wire, `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: j, dest: %x", pc, addr_wire);
`endif
            end
            6'b000011: begin // jal
                // since address width less than 32, use pc <- addr instead of pc <- { pc[31:28], addr }.
                `decode(0, `RS_DIS, 0, `RT_DIS, 31, `REG_WB, `INST_JAL, `ALU_OP_ADDU, (pc + 2), addr_wire, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: jal, gpr[31]: %x, dest: %h", pc, (pc + 2), addr_wire);
`endif
            end
            6'b000100: begin // beq
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_BEQ, `ALU_OP_EQ, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: beq, rs: %d, rt: %d, offset: %x, dest: %x", pc, rs_wire, rt_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b000101: begin // bne
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_BNE, `ALU_OP_NE, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: bne, rs: %d, rt: %d, offset: %x, dest: %x", pc, rs_wire, rt_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b000110: begin // blez
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_BLEZ, `ALU_OP_LE, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: blez, rs: %d, rt: %d, offset: %x, dest: %x", pc, rs_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b000111: begin // bgtz
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_BGTZ, `ALU_OP_GT, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: bgtz, rs: %d, offset: %x, dest: %x", pc, rs_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b001000: begin // addi
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_ADD, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: addi, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001001: begin // addiu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_ADDU, `ALU_OP_ADDU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: addiu, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001010: begin // slti
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_SLT, `ALU_OP_SLT, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: slti, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001011: begin // sltiu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_SLTU, `ALU_OP_SLTU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sltiu, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001100: begin // andi
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_AND, `ALU_OP_AND, $unsigned(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: andi, rs: %d, imm: %d, rt: %d", pc, rs_wire, $unsigned(imm_wire), rt_wire);
`endif
            end
            6'b001101: begin // ori
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_OR, `ALU_OP_OR, $unsigned(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: ori, rs: %d, imm: %d, rt: %d", pc, rs_wire, $unsigned(imm_wire), rt_wire);
`endif
            end
            6'b001110: begin // xori
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_XOR, `ALU_OP_XOR, $unsigned(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: xori, rs: %d, imm: %d, rt: %d", pc, rs_wire, $unsigned(imm_wire), rt_wire);
`endif
            end
            6'b001111: begin // lui, load upper immediate
                `decode(0, `RS_DIS, 0, `RT_DIS, rt_wire, `REG_WB, `INST_LU, `ALU_OP_LU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lui(%d) -> %d", pc, $signed(imm_wire), rt_wire);
`endif
            end
            6'b010000: begin // interaction with coprocessor0
                case (rs_wire)
                    5'b00000: begin // mfc0 rt, rd
                        `decode(0, `RS_DIS, 0, `RS_DIS, rd_wire, `REG_WB, `INST_MFC0, `ALU_OP_NOP, 0, 0, `EX_ALU, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: mfc0, rt: %d, rd: %d", pc, rt_wire, rd_wire);
`endif
                    end
                    5'b00100: begin // mtc0
                        `decode(rt_wire, `RS_EN, 0, `RT_DIS, 0, `REG_N, `INST_MTC0, `ALU_OP_NOP, 0, 0, `EX_ALU, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: mtc0, rt: %d, rd: %d", pc, rt_wire, rd_wire);
`endif
                    end
                    5'b10000: begin
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `REG_N, `INST_TEST_PASS, `ALU_OP_NOP, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: test_pass(%d)", pc, $signed(imm_wire));
`endif
                    end
                    5'b10001: begin
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `REG_N, `INST_TEST_FAIL, `ALU_OP_NOP, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: test_fail(%d)", pc, $signed(imm_wire));
`endif
                    end
                    5'b10010: begin
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `REG_N, `INST_TEST_DONE, `ALU_OP_NOP, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_DIS, `WB_ALU);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: test_done(%d)", pc, $signed(imm_wire));
`endif
                    end
                    default: begin
                        `decode(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                        $display("%x: unknown instruction: %b", pc, raw_inst);
`endif
                    end
                endcase
            end
            6'b100000: begin // lb
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_LB, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lb, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100001: begin // lh
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_LH, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lh, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100010: begin // lwl
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rt_wire, `REG_WB, `INST_LWL, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lwl, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100011: begin // lw
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_LW, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lw, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100100: begin // lbu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_LBU, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lbu, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100101: begin // lhu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `REG_WB, `INST_LHU, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lhu, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100110: begin // lwr
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rt_wire, `REG_WB, `INST_LWR, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lwr, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101000: begin // sb
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_SB, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sb, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101001: begin // sh
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_SH, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sh, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101010: begin // swl
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_SWL, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: swl, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101011: begin // sw
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_SW, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sw, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101110: begin // swr
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `REG_N, `INST_SWR, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_EN, `WB_MEM);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: swr, base: %d, offset: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            default: begin
                `decode(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                if (!stall && op_wire != 'bx)
                    $display("%x: unknown instruction: %b", pc, raw_inst);    
`endif
            end
        endcase
    end

    assign jump = (inst == `INST_JR || inst == `INST_JALR) ? `JUMP_REG : ((inst == `INST_J || inst == `INST_JAL) ? `JUMP : `JUMP_N);
    assign branch = inst == `INST_J || inst == `INST_JR || inst == `INST_JAL || inst == `INST_JALR
               || inst == `INST_BGEZ || inst == `INST_BLTZ || inst == `INST_BGTZ || inst == `INST_BLEZ || inst == `INST_BEQ || inst == `INST_BNE;
    assign trap = inst == `INST_TGE || inst == `INST_TGEU || inst == `INST_TLT || inst == `INST_TLTU || inst == `INST_TEQ || inst == `INST_TNE;
endmodule
