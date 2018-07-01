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

module exception_handler#(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 16,

    parameter BLOCK_OFFSET_WIDTH = 5
)(
    input clk,
    input rst_n,
    input pipe_decode_stall,
    input pipe_exec_stall,

    input cp0_reg_epc,

    output reg [`ADDR_BUS] fetch_write,

    output stall,
    output flush
);

    always @*
    begin
        if (!rst_n)
        begin
            stall <= 0;
            flush <= 0;
            fetch_write <= 0;
        end
        else
        begin
            if (exception != `EXCEPT_NONE)
            begin
                stall <= 0;
                flush <= 1;
                fetch_write <= 0;
                case (exception)
                    `EXCEPT_INTERRUPT: begin
                        fetch_write <= `EXCEPT_INTERRUPT_ADDR;
                    end
                    `EXCEPT_SYSCALL: begin
                        fetch_write <= `EXCEPT_SYSCALL_ADDR;
                    end
                    `EXCEPT_ILLEGAL: begin
                        fetch_write <= `EXCEPT_ILLEGAL_ADDR;
                    end
                    `EXCEPT_TRAP: begin
                        fetch_write <= `EXCEPT_TRAP_ADDR;
                    end
                    `EXCEPT_OVERFLOW: begin
                        fetch_write <= `EXCEPT_OVERFLOW_ADDR;
                    end
                    `EXCEPT_ERET: begin
                        fetch_write <= cp0_reg_epc;
                    end
                endcase
            end
            else
            begin
                stall <= 0;
                flush <= 0;
                fetch_write <= 0;
            end
        end
    end

endmodule