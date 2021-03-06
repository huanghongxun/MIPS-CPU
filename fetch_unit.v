`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/24 14:07:49
// Design Name: Instruction Fetch Unit
// Module Name: fetch_unit
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

`include "defines.v"

module fetch_unit #(parameter DATA_WIDTH = 32)(
    input clk,
    input rst_n,
    input stall,
    
    input rw,
    input [`DATA_BUS] write,
    output reg [`DATA_BUS] pc
    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            pc <= 0;
        end
        else
        begin
            if (!stall)
            begin
                if (rw == `MEM_WRITE)
                begin
                    pc <= write;
                end
                else
                begin
                    pc <= pc + 4;
                end
            end
        end
    end
endmodule
