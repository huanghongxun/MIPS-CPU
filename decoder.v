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
//  00000: sll
//  00001: srl
//  00010: sra
//  00011: ???
//  00100: mfhi
//  00101: mflo
//  00110: ???
//  00111: ???
//  01000: mul
//  01001: mulu
//  01010: div
//  01011: divu
//  01100: add
//  01101: addu
//  01110: sub
//  01111: subu
//  10000: and
//  10001: or
//  10010: xor
//  10011: nor
//  10100: ???
//  10101: ???
//  10110: ???
//  10111: ???
//  11000: slt
//  11001: sltu
//  11010: lu
//  11011: ???
//  11100: beq
//  11101: bne
//  11110: blt
//  11111: bleq
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//     Instructions see http://math-atlas.sourceforge.net/devel/assembly/mips-iv.pdf
// 
//////////////////////////////////////////////////////////////////////////////////

module decoder #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 18,
    parameter REG_ADDR_WIDTH = 5,
    parameter ALU_OP_WIDTH = 5
)(
    input [ADDR_WIDTH-1:0] pc,
    input [DATA_WIDTH-1:0] inst,

    output reg [5:0] op = 0, // op-code
    output reg [REG_ADDR_WIDTH-1:0] rs = 0, // register index of rs
    output reg [REG_ADDR_WIDTH-1:0] rt = 0, // register index of rt
    output reg [REG_ADDR_WIDTH-1:0] rd = 0, // register index of rd
    output reg [15:0] imm = 0, // immediate for I-type instruction.
    output reg [ALU_OP_WIDTH-1:0] func = 0, // ALU operation id.
    output reg [25:0] addr = 0, // jump_target for J-type instruction.
    output reg b_ctrl = 0, // 1 if use immediate value instead of rt
    output reg mem_width = 0, // 1 if byte mode, 0 if word mode
    output reg mem_rw = 0, // 1 if write mode, 0 if read mode
    output reg mem_enable = 0, // 1 if enable memory, 0 if disable memory 
    output reg sign_extend = 0, // 1 if trigger sign extend for halfword and byte.
    output reg wb_src = 0, // 1 if write back from ALU, 0 if write back from memory(load inst)
    output reg wb_reg = 0, // 1 if write to register rd.
    output reg [1:0] jump = 0, // 1 if jump
    output reg branch = 0
    );

    localparam B_REG = 0;
    localparam B_IMM = 1;
    localparam MEM_WORD = 0;
    localparam MEM_BYTE = 1;
    localparam MEM_READ = 0;
    localparam MEM_WRITE = 1;
    localparam MEM_EN = 1;
    localparam MEM_DIS = 0;
    localparam SIGN_EXT = 1;
    localparam ZERO_EXT = 0;
    localparam WB_ALU = 1;
    localparam WB_MEM = 0;
    localparam REG_WB = 1;
    localparam REG_N = 0;
    localparam JMP_REG = 2;
    localparam JMP = 1;
    localparam JMP_N = 0;
    localparam BR = 1;
    localparam BN_N = 0;

    wire [5:0] op_wire = inst[31:26]; // op-code
    wire [4:0] rs_wire = inst[25:21]; // register index of rs for R/I-type instruction.
    wire [4:0] rt_wire = inst[20:16]; // register index of rt for R/I-type instruction.
    wire [4:0] rd_wire = inst[15:11]; // register index of rd for R-type instruction.
    wire [4:0] shamt_wire = inst[10:6]; // shift amount field for R-type instruction.
    wire [5:0] funct_wire = inst[5:0]; // function field for R-type instruction.
    wire [15:0] imm_wire = inst[15:0]; // immediate for I-type instruction, or offset for J-type instruction.
    wire [25:0] addr_wire = inst[25:0]; // jump target address(instruction index) for J-type instruction.

    reg [31:0] pc_reg = 0;

    `define decode(rs_wire, rt_wire, rd_wire, func_wire, imm_wire, addr_wire, b_ctrl_wire, mem_width_wire, mem_rw_wire, mem_enable_wire, sign_extend_wire, alu_wb_wire, reg_wb_wire, jump_wire, branch_wire) \
        rs = rs_wire; \
        rt = rt_wire; \
        rd = rd_wire; \
        func = func_wire; \
        imm = imm_wire; \
        addr = addr_wire; \
        b_ctrl = b_ctrl_wire; \
        mem_width = mem_width_wire; \
        mem_rw = mem_rw_wire; \
        mem_enable = mem_enable_wire; \
        sign_extend = sign_extend_wire; \
        alu_wb = alu_wb_wire; \
        reg_wb = reg_wb_wire; \
        jump = jump_wire; \
        branch = branch_wire

    always @(inst)
    begin
        op = op_wire;

        case (inst[5:0])
            6'b000000:
                case (funct_wire)
                    6'b000000: begin
                        // nop
                        if (rt_wire == 0 && rd_wire == 0 && shamt_wire == 0)
                        begin
                            `decode(rs_wire, rt_wire, rd_wire, 'b00000, shamt_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR_N);
                        end
                        else // sll
                        begin
                            `decode(rt_wire, 0, rd_wire, 'b00000, shamt_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                            $display("Decoder.sll(%d, %d) -> %d", rt_wire, shamt_wire, rd_wire);
                        end
                    end
                    6'b000010: begin // srl
                        `decode(rt_wire, 0, rd_wire, 'b00001, shamt_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.srl(%d, %d) -> %d", rt_wire, shamt_wire, rd_wire);
                    end
                    6'b000011: begin // sra
                        `decode(rt_wire, 0, rd_wire, 'b00010, shamt_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.sra(%d, %d) -> %d", rt_wire, shamt_wire, rd_wire);
                    end
                    6'b000100: begin // sllv
                        `decode(rs_wire, rt_wire, rd_wire, 'b00000, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.sllv(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b000110: begin // srlv
                        `decode(rs_wire, rt_wire, rd_wire, 'b00001, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.srlv(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b000111: begin // srav
                        `decode(rs_wire, rt_wire, rd_wire, 'b00010, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.srav(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b001000: begin // jr
                        `decode(0, rs_wire, 0, 'b00000, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_REG, BR);
                        $display("Decoder.jr(%d)", rs_wire);
                    end
                    6'b001001: begin // jalr
                        `decode(0, rs_wire, rd_wire, 'b01101, (pc + 4), 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_REG, BR);
                        $display("Decoder.jalr(32, %d) -> %d", rs_wire, rd_wire);
                    end
                    6'b010000: begin // mfhi
                        `decode(rs_wire, rt_wire, rd_wire, 'b00100, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.mfhi -> %d", rd_wire);
                    end
                    6'b010010: begin // mflo
                        `decode(rs_wire, rt_wire, rd_wire, 'b00101, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.mflo -> %d", rd_wire);
                    end
                    6'b011000: begin // mult
                        `decode(rs_wire, rt_wire, rd_wire, 'b01000, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR_N);
                        $display("Decoder.mult(%d, %d)", rs_wire, rt_wire);
                    end
                    6'b011001: begin // multu
                        `decode(rs_wire, rt_wire, rd_wire, 'b01001, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.multu(%d, %d)", rs_wire, rt_wire);
                    end
                    6'b011010: begin // div
                        `decode(rs_wire, rt_wire, rd_wire, 'b01010, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR_N);
                        $display("Decoder.div(%d, %d)", rs_wire, rt_wire);
                    end
                    6'b011011: begin // divu
                        `decode(rs_wire, rt_wire, rd_wire, 'b01011, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.divu(%d, %d)", rs_wire, rt_wire);
                    end
                    6'b100000: begin // add
                        `decode(rs_wire, rt_wire, rd_wire, 'b01100, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.add(%d, %d)", rs_wire, rt_wire);
                    end
                    6'b100001: begin // addu
                        `decode(rs_wire, rt_wire, rd_wire, 'b01101, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.addu(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b100010: begin // sub
                        `decode(rs_wire, rt_wire, rd_wire, 'b01110, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.sub(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b100011: begin // subu
                        `decode(rs_wire, rt_wire, rd_wire, 'b01111, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.subu(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b100100: begin // and
                        `decode(rs_wire, rt_wire, rd_wire, 'b10000, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.and(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b100101: begin // or
                        `decode(rs_wire, rt_wire, rd_wire, 'b10001, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.or(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b100110: begin // xor
                        `decode(rs_wire, rt_wire, rd_wire, 'b10010, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.xor(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b100111: begin // nor
                        `decode(rs_wire, rt_wire, rd_wire, 'b10011, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.nor(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b101010: begin // slt
                        `decode(rs_wire, rt_wire, rd_wire, 'b11000, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.slt(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    6'b101011: begin // sltu
                        `decode(rs_wire, rt_wire, rd_wire, 'b11001, 0, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                        $display("Decoder.sltu(%d, %d) -> %d", rs_wire, rt_wire, rd_wire);
                    end
                    default: begin
                        `decode(rs_wire, rt_wire, rd_wire, funct_wire, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
                        $display("Decoder.unknown -> %b", inst);
                    end
                endcase
            6'b000001:
                case (rt_wire)
                    5'b00000: begin // bltz
                        `decode(rs_wire, 0, 0, 'b11110, imm_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR);
                        $display("Decoder.bltz(%d, %d)", rs_wire, $signed(imm_wire));
                    end
                    5'b00001: begin // bgez
                        `decode(0, rs_wire, 0, 'b11111, imm_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR);
                        $display("Decoder.bgez(%d, %d)", rs_wire, $signed(imm_wire));
                    end
                    default:
                        $display("Decoder.unknown -> %b", inst);
                endcase
            6'b000010: begin // j
                `decode(0, 0, 0, 5'b01101, 0, addr_wire, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP, BR);
                $display("Decoder.j(%h)", addr_wire);
            end
            6'b000011: begin // jal
                `decode(0, 0, 31, 5'b01101, (pc + 4), addr_wire, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP, BR);
                $display("Decoder.jal(%h)", addr_wire);
            end
            6'b000100: begin // beq
                `decode(rs_wire, rt_wire, 0, 5'b11100, imm_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR);
                $display("Decoder.beq(%d, %d, %d)", rs_wire, rt_wire, $signed(imm_wire));
            end
            6'b000101: begin // bne
                `decode(rs_wire, rt_wire, 0, 5'b11101, imm_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR);
                $display("Decoder.bne(%d, %d, %d)", rs_wire, rt_wire, $signed(imm_wire));
            end
            6'b000110: begin // blez
                `decode(rs_wire, 0, 0, 5'b11111, imm_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR);
                $display("Decoder.blez(%d, %d)", rs_wire, $signed(imm_wire));
            end
            6'b000111: begin // bgtz
                `decode(0, rs_wire, 0, 5'b11111, imm_wire, 0, B_REG, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR);
                $display("Decoder.bgtz(%d, %d)", rs_wire, $signed(imm_wire));
            end
            6'b001000: begin // addi
                `decode(rs_wire, 0, rt_wire, 5'b01100, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.addi(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b001001: begin // addiu
                `decode(rs_wire, 0, rt_wire, 5'b01101, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.addiu(%d, %d) -> %d", rs_wire, $unsigned(imm_wire), rt_wire);
            end
            6'b001010: begin // slti
                `decode(rs_wire, 0, rt_wire, 5'b11000, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.slti(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b001011: begin // sltiu
                `decode(rs_wire, 0, rt_wire, 5'b11001, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.sltiu(%d, %d) -> %d", rs_wire, $unsigned(imm_wire), rt_wire);
            end
            6'b001100: begin // andi
                `decode(rs_wire, 0, rt_wire, 5'b10000, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.andi(%d, %d) -> %d", rs_wire, $unsigned(imm_wire), rt_wire);
            end
            6'b001101: begin // ori
                `decode(rs_wire, 0, rt_wire, 5'b10001, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.ori(%d, %d) -> %d", rs_wire, $unsigned(imm_wire), rt_wire);
            end
            6'b001110: begin // xori
                `decode(rs_wire, 0, rt_wire, 5'b10010, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.xori(%d, %d) -> %d", rs_wire, $unsigned(imm_wire), rt_wire);
            end
            6'b001111: begin // lui, load upper immediate
                `decode(0, 0, rt_wire, 5'b11010, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_DIS, ZERO_EXT, WB_ALU, REG_WB, JMP_N, BR_N);
                $display("Decoder.lui(%d) -> %d", $signed(imm_wire), rt_wire);
            end
            6'b100000: begin // lb
                `decode(rs_wire, 0, rt_wire, 5'b01100, imm_wire, 0, B_IMM, MEM_BYTE, MEM_READ, MEM_EN, SIGN_EXT, WB_MEM, REG_WB, JMP_N, BR_N);
                $display("Decoder.lb(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b100011: begin // lw
                `decode(rs_wire, 0, rt_wire, 5'b01100, imm_wire, 0, B_IMM, MEM_WORD, MEM_READ, MEM_EN, ZERO_EXT, WB_MEM, REG_WB, JMP_N, BR_N);
                $display("Decoder.lw(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b100100: begin // lbu
                `decode(rs_wire, 0, rt_wire, 5'b01100, imm_wire, 0, B_IMM, MEM_BYTE, MEM_READ, MEM_EN, ZERO_EXT, WB_MEM, REG_WB, JMP_N, BR_N);
                $display("Decoder.lbu(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b101000: begin // sb
                `decode(rs_wire, rt_wire, 0, 5'b01100, imm_wire, 0, B_IMM, MEM_BYTE, MEM_WRITE, MEM_EN, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR_N);
                $display("Decoder.sb(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b101001: begin // sh
                `decode(rs_wire, rt_wire, 0, 5'b01100, imm_wire, 0, B_IMM, MEM_WORD, MEM_WRITE, MEM_EN, SIGN_EXT, WB_MEM, REG_N, JMP_N, BR_N);
                $display("Decoder.sh(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end
            6'b101011: begin // sw
                `decode(rs_wire, rt_wire, 0, 5'b01100, imm_wire, 0, B_IMM, MEM_WORD, MEM_WRITE, MEM_EN, ZERO_EXT, WB_MEM, REG_N, JMP_N, BR_N);
                $display("Decoder.sw(%d, %d) -> %d", rs_wire, $signed(imm_wire), rt_wire);
            end

        endcase
    end
endmodule
