`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Exception Handler
// Module Name: exception_handler
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module exception_handler#(parameter DATA_WIDTH = 32)(
    input clk,
    input rst_n,

    input [`DATA_BUS] cp0_status,
    input [`DATA_BUS] cp0_cause,
    input [`DATA_BUS] cp0_epc,

    input wb_wb_cp0,
    input [`CP0_REG_BUS] wb_cp0_write_addr,
    input [`DATA_BUS] wb_cp0_write,

    input [`EXCEPT_MASK_BUS] exception_mask,
    input [`DATA_BUS] pc,
    output reg [`DATA_BUS] exception,

    output force_disable_mem
);

    // Convert exception mask to exception id.
    always @*
    begin
        if (!rst_n)
        begin
            exception <= `EXCEPT_NONE;
        end
        else
        begin
            exception <= `EXCEPT_NONE;
            if (pc != 0)
            begin
                if ((cp0_cause[15:8] & cp0_status[15:8]) != 0 &&
                    cp0_status[1] == 0 && cp0_status[0] == 1)
                    exception <= `EXCEPT_INTERRUPT;
                else if (exception_mask[`EXCEPT_SYSCALL])
                    exception <= `EXCEPT_SYSCALL;
                else if (exception_mask[`EXCEPT_ILLEGAL])
                    exception <= `EXCEPT_ILLEGAL;
                else if (exception_mask[`EXCEPT_TRAP])
                    exception <= `EXCEPT_TRAP;
                else if (exception_mask[`EXCEPT_OVERFLOW])
                    exception <= `EXCEPT_OVERFLOW;
                else if (exception_mask[`EXCEPT_ERET])
                    exception <= `EXCEPT_ERET;
            end
        end
    end

    assign force_disable_mem = exception_mask != 0;

endmodule