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
// Dependencies: NONE
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

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
        case(op)
            5'b00000: begin // sll
                rd = rs << rt;
                branch = 0;
                $display("ALU: %d << %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b00001: begin // srl
                rd = rs >> rt;
                branch = 0;
                $display("ALU: %d >> %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b00010: begin // sra
                rd = $signed(rs) >>> $signed(rt);
                branch = 0;
                $display("ALU: %d >>> %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b00100: begin // mfhi
                rd = hi;
                branch = 0;
                $display("ALU: hi = %d", $signed(rd));
            end
            5'b00101: begin // mflo
                rd = lo;
                branch = 0;
                $display("ALU: lo = %d", $signed(rd));
            end
            5'b01000: begin // mul
                {hi, lo} = $signed(rs) * $signed(rt);
                branch = 0;
                $display("ALU: %d * %d = %d", $signed(rs), $signed(rt), $signed({hi, lo}));
            end
            5'b01001: begin // mulu
                {hi, lo} = $unsigned(rs) * $unsigned(rt);
                branch = 0;
                $display("ALU: %d * %d = %d", $unsigned(rs), $unsigned(rt), $unsigned({hi, lo}));
            end
            5'b01010: begin // div
                lo = $signed(rs) / $signed(rt);
                hi = $signed(rs) % $signed(rt);
                branch = 0;
                $display("ALU: %d / %d = %d, %d", $signed(rs), $signed(rt), $signed(lo), $signed(hi));
            end
            5'b01011: begin // divu
                lo = $unsigned(rs) / $unsigned(rt);
                hi = $unsigned(rs) % $unsigned(rt);
                branch = 0;
                $display("ALU: %d / %d = %d, %d", $unsigned(rs), $unsigned(rt), $unsigned(lo), $unsigned(hi));
            end
            5'b01100: begin // add
                rd = $signed(rs) + $signed(rt);
                branch = 0;
                $display("ALU: %d + %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b01101: begin // addu
                rd = $unsigned(rs) + $unsigned(rt);
                branch = 0;
                $display("ALU: %d + %d = %d", $unsigned(rs), $unsigned(rt), $unsigned(rd));
            end
            5'b01110: begin // sub
                rd = $signed(rs) - $signed(rt);
                branch = 0;
                $display("ALU: %d - %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b01111: begin // subu
                rd = $unsigned(rs) - $unsigned(rt);
                branch = 0;
                $display("ALU: %d - %d = %d", $unsigned(rs), $unsigned(rt), $unsigned(rd));
            end
            5'b10000: begin // and
                rd = rs & rt;
                branch = 0;
                $display("ALU: %d & %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b10001: begin // or
                rd = rs | rt;
                branch = 0;
                $display("ALU: %d | %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b10010: begin // xor
                rd = rs ^ rt;
                branch = 0;
                $display("ALU: %d ^ %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b10011: begin // nor
                rd = ~(rs | rt);
                branch = 0;
                $display("ALU: %d ~| %d = %d", $signed(rs), $signed(rt), $signed(rd));
            end
            5'b11000: begin // slt
                rd = $signed(rs) < $signed(rt) ? 1 : 0;
                branch = 0;
                $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), rd);
            end
            5'b11001: begin // sltu
                rd = $unsigned(rs) < $unsigned(rt) ? 1 : 0;
                branch = 0;
                $display("ALU: %d < %d = %d", $unsigned(rs), $unsigned(rt), rd);
            end
            5'b11010: begin // lu
                rd = rt << 16;
                branch = 0;
                $display("ALU: %d << 16 = %d", $unsigned(rt), $unsigned(rd));
            end
            5'b11100: begin // beq
                branch = rs == rt ? 1 : 0;
                rd = 0;
                $display("ALU: %d == %d = %d", $signed(rs), $signed(rt), branch);
            end
            5'b11101: begin // bne
                branch = $signed(rs) != $signed(rt) ? 1 : 0;
                rd = 0;
                $display("ALU: %d != %d = %d", $signed(rs), $signed(rt), branch);
            end
            5'b11110: begin // blt
                branch = $signed(rs) < $signed(rt) ? 1 : 0;
                rd = 0;
                $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), branch);
            end
            5'b11111: begin // bleq
                branch = $signed(rs) <= $signed(rt) ? 1 : 0;
                rd = 0;
                $display("ALU: %d <= %d = %d", $signed(rs), $signed(rt), branch);
            end
            default: begin
                rd = 0;
                branch = 0;
                $display("ALU: unknown op %b", func);
            end
        endcase
endmodule
