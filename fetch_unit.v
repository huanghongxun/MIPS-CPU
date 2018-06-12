`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/24 14:07:49
// Design Name: Program Counter
// Module Name: program_counter
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module program_counter(
    input clk,
    input stall,
    input busy,
    output reg [31:0] pc = 32'h8001_FFFC,
    output reg [2:0] access_size = 0,
    input jmp, // 1 if J-type instruction is invoked.
    input [25:0] jmp_addr,
    input branch,
    input [15:0] offset
    );

    wire [31:0] offset_sign_extended = {{14{offset[15]}}, {offset[15:0]}, 2'b00}; // sign extended offset for I branch instructions.
    
    always @(posedge clk)
    begin
        if (stall == 0 && busy == 0)
        begin
            if (jmp != 1 && branch != 1)
                pc = pc + 4;
            else if (branch == 1)
            begin
                pc = (pc + 4) + offset_sign_extended;
                $display("PC branch %h", pc);
            end
            else if (jmp == 1)
            begin
                pc = {pc[31:28], jmp_addr, 2'b00}; // (pc & 32'hf000_0000) + (jmp_addr << 2)
                $display("PC jump %h", pc);
            end
            // no else
        end // busy or stall
        else if (jmp == 1)
        begin
            pc = {pc[31:28], jmp_addr, 2'b00}; // (pc & 32'hf000_0000) + (jmp_addr << 2)
            $display("PC jump %h", pc);
        end
        else if (branch == 1)
        begin
            pc = (pc + 4) + offset_sign_extended;
            $display("PC branch %h", pc);
        end
    end
endmodule
