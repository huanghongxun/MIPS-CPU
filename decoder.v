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
    parameter REG_ADDR_WIDTH = 5,
    parameter ALU_OP_WIDTH = 5
)(
    input stall,

    input [`ADDR_BUS] pc,
    input [`DATA_BUS] inst,

    output reg [`VREG_BUS] rs = 0, // register index of rs
    output reg [`VREG_BUS] rt = 0, // register index of rt
    output reg [`VREG_BUS] rd = 0, // register index of rd
    output reg rs_enable = 0, // 1 if rs is valid
    output reg rt_enable = 0, // 1 if rt is valid
    output reg [`DATA_BUS] imm = 0, // immediate for I-type instruction.
    output reg [ALU_OP_WIDTH-1:0] func = 0, // ALU operation id.
    output reg [`ADDR_BUS] addr = 0, // jump_target for J-type instruction.
    output reg [1:0] exec_src = 0, // ALU, IPU, FPU, External
    output reg b_ctrl = 0, // 1 if use immediate value instead of rt
    output reg [1:0] mem_width = 0, // 0 - word, 1 - halfword, 2 - byte
    output reg mem_rw = 0, // 1 if write mode, 0 if read mode
    output reg mem_enable = 0, // 1 if enable memory, 0 if disable memory 
    output reg sign_extend = 0, // 1 if trigger sign extend for halfword and byte.
    output reg wb_src = 0, // 1 if write back from ALU, 0 if write back from memory(load inst)
    output reg wb_reg = 0, // 1 if write to register rd.
    output reg [1:0] jump = 0, // 1 if jump to imm, 2 if jump to register rt
    output reg branch = 0 // 1 if this inst is a branch inst.
    );

    wire [5:0] op_wire = inst[31:26]; // op-code
    wire [4:0] rs_wire = inst[25:21]; // register index of rs for R/I-type instruction.
    wire [4:0] rt_wire = inst[20:16]; // register index of rt for R/I-type instruction.
    wire [4:0] rd_wire = inst[15:11]; // register index of rd for R-type instruction.
    wire [4:0] shamt_wire = inst[10:6]; // shift amount field for R-type instruction.
    wire [5:0] funct_wire = inst[5:0]; // function field for R-type instruction.
    wire [15:0] imm_wire = inst[15:0]; // immediate for arithmetic instruction, or offset for branch instructions.
    wire [25:0] addr_wire = inst[25:0]; // jump target address(instruction index) for J-type instruction.

    `define decode(rs_wire, rs_enable_wire, rt_wire, rt_enable_wire, rd_wire, func_wire, imm_wire, addr_wire, exec_src_wire, b_ctrl_wire, mem_width_wire, mem_rw_wire, mem_enable_wire, sign_extend_wire, wb_src_wire, wb_reg_wire, jump_wire, branch_wire) \
        rs = rs_wire; \
        rs_enable = rs_enable_wire; \
        rt = rt_wire; \
        rt_enable = rt_enable_wire; \
        rd = rd_wire; \
        func = func_wire; \
        imm = imm_wire; \
        addr = addr_wire; \
        exec_src = exec_src_wire; \
        b_ctrl = b_ctrl_wire; \
        mem_width = mem_width_wire; \
        mem_rw = mem_rw_wire; \
        mem_enable = mem_enable_wire; \
        sign_extend = sign_extend_wire; \
        wb_src = wb_src_wire; \
        wb_reg = wb_reg_wire; \
        jump = jump_wire; \
        branch = branch_wire

    always @(inst, pc)
    begin
        case (op_wire)
            6'b000000:
                case (funct_wire)
                    6'b000000: begin
                        // nop
                        if (rt_wire == 0 && rd_wire == 0 && shamt_wire == 0)
                        begin
                            `decode(0, `RS_DIS, 0, `RT_DIS, 0, `ALU_OP_NOP, 0, 0, `EX_NOP, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
                        end
                        else // sll
                        begin
                            `decode(rt_wire, `RS_EN, 0, `RT_DIS, rd_wire, `ALU_OP_SLL, $unsigned(shamt_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                            if (!stall)
                                $display("%x: sll, rt: %d, sa: %d, rd: %d", pc, rt_wire, shamt_wire, rd_wire);
`endif
                        end
                    end
                    6'b000010: begin // srl
                        `decode(rt_wire, `RS_EN, 0, `RT_DIS, rd_wire, `ALU_OP_SRL, $unsigned(shamt_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: srl, rt: %d, sa: %d, rd: %d", pc, rt_wire, shamt_wire, rd_wire);
`endif
                    end
                    6'b000011: begin // sra
                        `decode(rt_wire, `RS_EN, 0, `RT_DIS, rd_wire, `ALU_OP_SRA, $unsigned(shamt_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sra, rt: %d, sa: %d, rd: %d", pc, rt_wire, shamt_wire, rd_wire);
`endif
                    end
                    6'b000100: begin // sllv
                        `decode(rt_wire, `RS_EN, rs_wire, `RT_EN, rd_wire, `ALU_OP_SLL, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sllv, rt: %d, rs: %d, rd: %d", pc, rt_wire, rs_wire, rd_wire);
`endif
                    end
                    6'b000110: begin // srlv
                        `decode(rt_wire, `RS_EN, rs_wire, `RT_EN, rd_wire, `ALU_OP_SRL, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: srlv, rt: %d, rs: %d, rd: %d", pc, rt_wire, rs_wire, rd_wire);
`endif
                    end
                    6'b000111: begin // srav
                        `decode(rt_wire, `RS_EN, rs_wire, `RT_EN, rd_wire, `ALU_OP_SRA, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: srav, rt: %d, rs: %d, rd: %d", pc, rt_wire, rs_wire, rd_wire);
`endif
                    end
                    6'b001000: begin // jr
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `ALU_OP_NOP, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_REG, `BR);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: jr, rs: %d", pc, rs_wire);
`endif
                    end
                    6'b001001: begin // jalr
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 31, `ALU_OP_ADDU, (pc + 2), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_REG, `BR);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: jalr, rs: %d, dest: %x", pc, rs_wire, (pc + 2));
`endif
                    end
                    6'b010000: begin // mfhi
                        `decode(0, `RS_DIS, 0, `RT_DIS, rd_wire, `ALU_OP_MFHI, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: mfhi, rd: %d", pc, rd_wire);
`endif
                    end
                    6'b010010: begin // mflo
                        `decode(0, `RS_DIS, 0, `RT_DIS, rd_wire, `ALU_OP_MFLO, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: mflo, rd: %d", pc, rd_wire);
`endif
                    end
                    6'b011000: begin // mult
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_MUL, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: mult, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b011001: begin // multu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_MULU, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: multu, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b011010: begin // div
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_DIV, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: div, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b011011: begin // divu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_DIVU, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: divu, rs: %d, rt: %d", pc, rs_wire, rt_wire);
`endif
                    end
                    6'b100000: begin // add
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_ADD, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: add, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100001: begin // addu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_ADDU, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: addu, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100010: begin // sub
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_SUB, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sub, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100011: begin // subu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_SUBU, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: subu, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100100: begin // and
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_AND, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: and, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100101: begin // or
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_OR, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: or, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100110: begin // xor
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_XOR, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: xor, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b100111: begin // nor
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_NOR, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: nor, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b101010: begin // slt
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_SLT, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: slt, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    6'b101011: begin // sltu
                        `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, rd_wire, `ALU_OP_SLTU, 0, 0, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: sltu, rs: %d, rt: %d, rd: %d", pc, rs_wire, rt_wire, rd_wire);
`endif
                    end
                    default: begin
                        `decode(rs_wire, 0, rt_wire, 0, rd_wire, funct_wire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: unknown -> %b", pc, inst);
`endif
                    end
                endcase
            6'b000001:
                case (rt_wire)
                    5'b00000: begin // bltz
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `ALU_OP_BLT, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: bltz, rs: %d, offset: %x, dest: %x", pc, rs_wire, $signed(addr_wire), (pc + 1 + $signed(addr_wire)));
`endif
                    end
                    5'b00001: begin // bgez
                        `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `ALU_OP_BGE, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: bgez, rs: %d, offset: %x, dest: %x", pc, rs_wire, $signed(addr_wire), (pc + 1 + $signed(addr_wire)));
`endif
                    end
                    default: begin
                        // should jump to exception handler.
                        `decode(rs_wire, 0, rt_wire, 0, rd_wire, funct_wire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: unknown instruction %b", pc, inst);
`endif
                    end
                endcase
            6'b000010: begin // j
                // since address width less than 32, use pc <- addr instead of pc <- { pc[31:28], addr }.
                `decode(0, `RS_DIS, 0, `RT_DIS, 0, `ALU_OP_ADDU, 0, addr_wire, `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP, `BR);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: j, dest: %x", pc, addr_wire);
`endif
            end
            6'b000011: begin // jal
                // since address width less than 32, use pc <- addr instead of pc <- { pc[31:28], addr }.
                `decode(0, `RS_DIS, 0, `RT_DIS, 31, `ALU_OP_ADDU, (pc + 2), addr_wire, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP, `BR);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: jal, gpr[31]: %x, dest: %h", pc, (pc + 2), addr_wire);
`endif
            end
            6'b000100: begin // beq
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_BEQ, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: beq, rs: %d, rt: %d, offset: %x, dest: %x", pc, rs_wire, rt_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b000101: begin // bne
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_BNE, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: bne, rs: %d, rt: %d, offset: %x, dest: %x", pc, rs_wire, rt_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b000110: begin // blez
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `ALU_OP_BLE, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: blez, rs: %d, rt: %d, offset: %x, dest: %x", pc, rs_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b000111: begin // bgtz
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, 0, `ALU_OP_BGT, 0, (pc + 1 + $signed(addr_wire)), `EX_ALU, `B_REG, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: bgtz, rs: %d, offset: %x, dest: %x", pc, rs_wire, addr_wire, (pc + 1 + $signed(addr_wire)));
`endif
            end
            6'b001000: begin // addi
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: addi, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001001: begin // addiu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADDU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: addiu, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001010: begin // slti
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_SLT, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: slti, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001011: begin // sltiu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_SLTU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sltiu, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b001100: begin // andi
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_AND, $unsigned(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: andi, rs: %d, imm: %d, rt: %d", pc, rs_wire, $unsigned(imm_wire), rt_wire);
`endif
            end
            6'b001101: begin // ori
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_OR, $unsigned(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: ori, rs: %d, imm: %d, rt: %d", pc, rs_wire, $unsigned(imm_wire), rt_wire);
`endif
            end
            6'b001110: begin // xori
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_XOR, $unsigned(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: xori, rs: %d, imm: %d, rt: %d", pc, rs_wire, $unsigned(imm_wire), rt_wire);
`endif
            end
            6'b001111: begin // lui, load upper immediate
                `decode(0, `RS_DIS, 0, `RT_DIS, rt_wire, `ALU_OP_LU, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lui(%d) -> %d", pc, $signed(imm_wire), rt_wire);
`endif
            end
            6'b010000: begin // test instructions
                case (rs_wire)
                    0: begin
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `ALU_OP_TEST_PASS, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: test_pass(%d)", pc, $signed(imm_wire));
`endif
                    end
                    1: begin
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `ALU_OP_TEST_FAIL, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: test_fail(%d)", pc, $signed(imm_wire));
`endif
                    end
                    2: begin
                        `decode(0, `RS_DIS, 0, `RT_DIS, 0, `ALU_OP_TEST_DONE, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_DIS, `ZERO_EXT, `WB_ALU, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                        if (!stall)
                            $display("%x: test_done(%d)", pc, $signed(imm_wire));
`endif
                    end
                    default: begin
                        `decode(rs_wire, 0, rt_wire, 0, rd_wire, funct_wire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                        if (!stall)
                        $display("%x: Invalid test instruction func %d", pc, rs_wire);
`endif
                    end
                endcase
            end
            6'b100000: begin // lb
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_BYTE, `MEM_READ, `MEM_EN, `SIGN_EXT, `WB_MEM, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lb, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100001: begin // lh
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_HALF, `MEM_READ, `MEM_EN, `SIGN_EXT, `WB_MEM, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lh, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100011: begin // lw
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_READ, `MEM_EN, `SIGN_EXT, `WB_MEM, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lw, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100100: begin // lbu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_BYTE, `MEM_READ, `MEM_EN, `ZERO_EXT, `WB_MEM, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lbu, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b100101: begin // lhu
                `decode(rs_wire, `RS_EN, 0, `RT_DIS, rt_wire, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_HALF, `MEM_READ, `MEM_EN, `ZERO_EXT, `WB_MEM, `REG_WB, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: lhu, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101000: begin // sb
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_BYTE, `MEM_WRITE, `MEM_EN, `ZERO_EXT, `WB_MEM, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sb, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101001: begin // sh
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_HALF, `MEM_WRITE, `MEM_EN, `SIGN_EXT, `WB_MEM, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sh, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            6'b101011: begin // sw
                `decode(rs_wire, `RS_EN, rt_wire, `RT_EN, 0, `ALU_OP_ADD, $signed(imm_wire), 0, `EX_ALU, `B_IMM, `MEM_WORD, `MEM_WRITE, `MEM_EN, `ZERO_EXT, `WB_MEM, `REG_N, `JMP_N, `BR_N);
`ifdef DEBUG_DEC
                if (!stall)
                    $display("%x: sw, rs: %d, imm: %d, rt: %d", pc, rs_wire, $signed(imm_wire), rt_wire);
`endif
            end
            default: begin
                `decode(rs_wire, 0, rt_wire, 0, rd_wire, funct_wire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
`ifdef DEBUG_DEC
                if (!stall && op_wire != 'bx)
                    $display("%x: unknown instruction: %b", pc, inst);    
`endif
            end
        endcase
    end
endmodule
