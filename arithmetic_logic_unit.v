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
    input stall,
    input en,
    
    input [ALU_OP_WIDTH-1:0] op,
    input [DATA_WIDTH-1:0] rs,
    input [DATA_WIDTH-1:0] rt,
    output reg [DATA_WIDTH-1:0] rd,
    output reg branch,
    output reg [1:0] test_state = 0
    );

    reg [DATA_WIDTH-1:0] hi = 0, lo = 0;
    
    always @(op, rs, rt, hi, lo, en)
    begin
        if (en)
        begin
            case(op)
                `ALU_OP_SLL: begin // sll
                    branch = 0;
                    test_state = 0;
                    rd = rs << rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d << %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_SRL: begin // srl
                    branch = 0;
                    test_state = 0;
                    rd = rs >> rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d >> %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_SRA: begin // sra
                    branch = 0;
                    test_state = 0;
                    rd = $signed(rs) >>> $signed(rt);
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d >>> %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_MFHI: begin // mfhi
                    branch = 0;
                    test_state = 0;
                    rd = hi;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: hi = %d", $signed(rd));
`endif
                end
                `ALU_OP_MFLO: begin // mflo
                    branch = 0;
                    test_state = 0;
                    rd = lo;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: lo = %d", $signed(rd));
`endif
                end
                `ALU_OP_MUL: begin // mul
                    branch = 0;
                    test_state = 0;
                    rd = 0;
                    {hi, lo} = $signed(rs) * $signed(rt);
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d * %d = %d", $signed(rs), $signed(rt), $signed({hi, lo}));
`endif
                end
                `ALU_OP_MULU: begin // mulu
                    branch = 0;
                    test_state = 0;
                    rd = 0;
                    {hi, lo} = $unsigned(rs) * $unsigned(rt);
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d * %d = %d", $unsigned(rs), $unsigned(rt), $unsigned({hi, lo}));
`endif
                end
                `ALU_OP_DIV: begin // div
                    branch = 0;
                    test_state = 0;
                    rd = 0;
                    lo = $signed(rs) / $signed(rt);
                    hi = $signed(rs) % $signed(rt);
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d / %d = %d, %d", $signed(rs), $signed(rt), $signed(lo), $signed(hi));
`endif
                end
                `ALU_OP_DIVU: begin // divu
                    branch = 0;
                    test_state = 0;
                    rd = 0;
                    lo = $unsigned(rs) / $unsigned(rt);
                    hi = $unsigned(rs) % $unsigned(rt);
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d / %d = %d, %d", $unsigned(rs), $unsigned(rt), $unsigned(lo), $unsigned(hi));
`endif
                end
                `ALU_OP_ADD: begin // add
                    branch = 0;
                    test_state = 0;
                    rd = rs + rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d + %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_ADDU: begin // addu
                    branch = 0;
                    test_state = 0;
                    rd = rs + rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d + %d = %d", $unsigned(rs), $unsigned(rt), $unsigned(rd));
`endif
                end
                `ALU_OP_SUB: begin // sub
                    branch = 0;
                    test_state = 0;
                    rd = rs - rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d - %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_SUBU: begin // subu
                    branch = 0;
                    test_state = 0;
                    rd = rs - rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d - %d = %d", $unsigned(rs), $unsigned(rt), $unsigned(rd));
`endif
                end
                `ALU_OP_AND: begin // and
                    branch = 0;
                    test_state = 0;
                    rd = rs & rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d & %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_OR: begin // or
                    branch = 0;
                    test_state = 0;
                    rd = rs | rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d | %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_XOR: begin // xor
                    branch = 0;
                    test_state = 0;
                    rd = rs ^ rt;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d ^ %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_NOR: begin // nor
                    branch = 0;
                    test_state = 0;
                    rd = ~(rs | rt);
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d ~| %d = %d", $signed(rs), $signed(rt), $signed(rd));
`endif
                end
                `ALU_OP_SLT: begin // slt
                    branch = 0;
                    test_state = 0;
                    rd = $signed(rs) < $signed(rt) ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), rd);
`endif
                end
                `ALU_OP_SLTU: begin // sltu
                    test_state = 0;
                    rd = $unsigned(rs) < $unsigned(rt) ? 1 : 0;
                    branch = 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d < %d = %d", $unsigned(rs), $unsigned(rt), rd);
`endif
                end
                `ALU_OP_LU: begin // lu
                    branch = 0;
                    test_state = 0;
                    rd = rt << 16;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d << 16 = %d", $unsigned(rt), $unsigned(rd));
`endif
                end
                `ALU_OP_BEQ: begin // beq
                    rd = 0;
                    test_state = 0;
                    branch = rs == rt ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d == %d = %d", $signed(rs), $signed(rt), branch);
`endif
                end
                `ALU_OP_BNE: begin // bne
                    rd = 0;
                    test_state = 0;
                    branch = $signed(rs) != $signed(rt) ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d != %d = %d", $signed(rs), $signed(rt), branch);
`endif
                end
                `ALU_OP_BLT: begin // bltz
                    rd = 0;
                    test_state = 0;
                    branch = $signed(rs) < $signed(rt) ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), branch);
`endif
                end
                `ALU_OP_BGE: begin // bgez
                    rd = 0;
                    test_state = 0;
                    branch = $signed(rs) >= $signed(rt) ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d > %d = %d", $signed(rs), $signed(rt), branch);
`endif
                end
                `ALU_OP_BLE: begin // blez
                    rd = 0;
                    test_state = 0;
                    branch = $signed(rs) <= $signed(rt) ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d < %d = %d", $signed(rs), $signed(rt), branch);
`endif
                end
                `ALU_OP_BGT: begin // bgtz
                    rd = 0;
                    test_state = 0;
                    branch = $signed(rs) > $signed(rt) ? 1 : 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: %d > %d = %d", $signed(rs), $signed(rt), branch);
`endif
                end
                `ALU_OP_TEST_PASS: begin
                    rd = 0;
                    branch = 0;
                    test_state = `TEST_PASS;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("Test passed: %d", $signed(rt));
`endif
                end
                `ALU_OP_TEST_FAIL: begin
                    rd = 0;
                    branch = 0;
                    test_state = `TEST_FAIL;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("Test failed: %d", $signed(rt));
`endif
                end
                `ALU_OP_TEST_DONE: begin
                    rd = 0;
                    branch = 0;
                    test_state = `TEST_DONE;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("Test done: %d", $signed(rt));
`endif
                end
                default: begin
                    rd = 0;
                    branch = 0;
                    test_state = 0;
`ifdef DEBUG_ALU
                    if (!stall)
                        $display("ALU: unknown op %b", op);
`endif
                end
            endcase
        end
        else
        begin
            rd <= 0;
            branch <= 0;
            test_state <= 0;
        end
    end
endmodule
