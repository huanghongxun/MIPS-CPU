`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Move Instruction Handler
// Module Name: move
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//      in memory access stage
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module move#(
	parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter REG_ADDR_WIDTH = 5
)(
    input clk,
    input rst_n,

    input [`DATA_BUS] raw_inst,
    input [`INST_BUS] inst,

    input [`EX_SRC_BUS] exec_src,

    input [`DATA_BUS] data,

    output reg cp0_reg_rw,
    output reg [`CP0_REG_BUS] cp0_reg_read_addr,
    input [`DATA_BUS] cp0_reg_read,
    output reg [`CP0_REG_BUS] cp0_reg_write_addr,
    output reg [`DATA_BUS] cp0_reg_write,

    output reg [`DATA_BUS] res
);

    // Determine the data moved to GPR.
    always @*
    begin
        if (!rst_n)
        begin
            res <= 0;
        end
        else
        begin
            res <= 0;
            case (inst)
//              `INST_MFHI: begin
//                  res <= hi;
//              end
//              `INST_MFLO: begin
//                  res <= lo;
//              end
                `INST_MOVZ: begin
                    res <= data;
                end
                `INST_MOVN: begin
                    res <= data;
                end
                `INST_MFC0: begin
                    cp0_reg_read_addr <= raw_inst[15:11];
                    res <= cp0_reg_read;
                end
            endcase
        end
    end

    always @*
    begin
        if (!rst_n)
        begin
            cp0_reg_rw <= `MEM_READ;
            cp0_reg_write_addr <= 0;
            cp0_reg_write <= 0;
        end
        else
        begin
            if (inst == `INST_MTC0)
            begin
                cp0_reg_rw <= `MEM_WRITE;
                cp0_reg_write_addr <= raw_inst[15:11];
                cp0_reg_write <= data;
            end
            else
            begin
                cp0_reg_rw <= `MEM_READ;
                cp0_reg_write_addr <= 0;
                cp0_reg_write <= 0;
            end
        end
    end

endmodule