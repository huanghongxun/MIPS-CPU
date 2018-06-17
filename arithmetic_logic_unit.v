`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/06/12 20:04:40
// Design Name: Arithmetic and Logic Unit
// Module Name: arithmetic_logic_unit
// Project Name: CPU
// Target Devices: Basys3
// Tool Versions: Vivado 2015.4
// Description: Simple Arithmetic Logic Unit
// 
// Dependencies: NONE
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

// WIDTH - register width, 8, 16, 32 or 64
module arithmetic_logic_unit #(
    parameter DATA_WIDTH = 32,
    parameter ALU_OP_WIDTH = 5
)(
    input [ALU_OP_WIDTH-1:0] op,
    input [DATA_WIDTH-1:0] rs,
    input [DATA_WIDTH-1:0] rt,
    output reg [DATA_WIDTH-1:0] rd,
    output reg branch
    );

    reg [DATA_WIDTH-1:0] hi = 0, lo = 0;
    
    always @*
    begin
        rd <= 0;
        branch <= 0;
        case(op)
            `ALU_OP_SLL: begin // sll
                rd <= rs << rt;
                $display("ALU: %d << %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_SRL: begin // srl
                rd <= rs >> rt;
                $display("ALU: %d >> %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_SRA: begin // sra
                rd <= $signed(rs) >>> $signed(rt);
                $display("ALU: %d >>> %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_MFHI: begin // mfhi
                rd <= hi;
                $display("ALU: hi = %d", $signed(rd));
            end
            `ALU_OP_MFLO: begin // mflo
                rd <= lo;
                $display("ALU: lo = %d", $signed(rd));
            end
            `ALU_OP_MUL: begin // mul
                {hi, lo} <= $signed(rs) * $signed(rt);
                $display("ALU: %d * %d = %d", $signed(rs), $signed(rt), $signed({hi, lo}));
            end
            `ALU_OP_MULU: begin // mulu
                {hi, lo} <= $unsigned(rs) * $unsigned(rt);
                $display("ALU: %d * %d = %d", $unsigned(rs), $unsigned(rt), $unsigned({hi, lo}));
            end
            `ALU_OP_DIV: begin // div
                lo <= $signed(rs) / $signed(rt);
                hi <= $signed(rs) % $signed(rt);
                $display("ALU: %d / %d = %d, %d", $signed(rs), $signed(rt), $signed(lo), $signed(hi));
            end
            `ALU_OP_DIVU: begin // divu
                lo <= $unsigned(rs) / $unsigned(rt);
                hi <= $unsigned(rs) % $unsigned(rt);
                $display("ALU: %d / %d = %d, %d", $unsigned(rs), $unsigned(rt), $unsigned(lo), $unsigned(hi));
            end
            `ALU_OP_ADD: begin // add
                rd <= $signed(rs) + $signed(rt);
                $display("ALU: %d + %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_ADDU: begin // addu
                rd <= $unsigned(rs) + $unsigned(rt);
                $display("ALU: %d + %d = %d", $unsigned(rs), $unsigned(rt), $unsigned(rd));
            end
            `ALU_OP_SUB: begin // sub
                rd <= $signed(rs) - $signed(rt);
                $display("ALU: %d - %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_SUBU: begin // subu
                rd <= $unsigned(rs) - $unsigned(rt);
                $display("ALU: %d - %d = %d", $unsigned(rs), $unsigned(rt), $unsigned(rd));
            end
            `ALU_OP_AND: begin // and
                rd <= rs & rt;
                $display("ALU: %d & %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_OR: begin // or
                rd <= rs | rt;
                $display("ALU: %d | %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_XOR: begin // xor
                rd <= rs ^ rt;
                $display("ALU: %d ^ %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_NOR: begin // nor
                rd <= ~(rs | rt);
                $display("ALU: %d ~| %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            `ALU_OP_SLT: begin // slt
                rd <= $signed(rs) < $signed(rt) ? 1 : 0;
                $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), rd);
            end
            `ALU_OP_SLTU: begin // sltu
                rd = $unsigned(rs) < $unsigned(rt) ? 1 : 0;
                branch = 0;
                $display("ALU: %d < %d = %d", $unsigned(rs), $unsigned(rt), rd);
            end
            `ALU_OP_LU: begin // lu
                rd <= rt << 16;
                $display("ALU: %d << 16 = %d", $unsigned(rt), $unsigned(rd));
            end
            `ALU_OP_BEQ: begin // beq
                branch <= rs == rt ? 1 : 0;
                $display("ALU: %d == %d = %d", $signed(rs), $signed(rt), branch);
            end
            `ALU_OP_BNE: begin // bne
                branch <= $signed(rs) != $signed(rt) ? 1 : 0;
                $display("ALU: %d != %d = %d", $signed(rs), $signed(rt), branch);
            end
            `ALU_OP_BLT: begin // bltz
                branch <= $signed(rs) < $signed(rt) ? 1 : 0;
                $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), branch);
            end
            `ALU_OP_BGE: begin // bgez
                branch <= $signed(rs) >= $signed(rt) ? 1 : 0;
                $display("ALU: %d > %d = %d", $signed(rs), $signed(rt), branch);
            end
            `ALU_OP_BLE: begin // blez
                branch <= $signed(rs) <= $signed(rt) ? 1 : 0;
                $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), branch);
            end
            `ALU_OP_BGT: begin // bgtz
                branch <= $signed(rs) > $signed(rt) ? 1 : 0;
                $display("ALU: %d > %d = %d", $signed(rs), $signed(rt), branch);
            end
            default:
                $display("ALU: unknown op %b", op);
        endcase
    end
endmodule
