`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Design Name: Memory Access Stage Controller
// Module Name: memory_access
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

module memory_access#(parameter DATA_WIDTH = 32)(
    input clk,
    input rst_n,

    // current values of special purpose registers in coprocessor 0.
    input [`DATA_BUS] cp0_status,
    input [`DATA_BUS] cp0_cause,
    input [`DATA_BUS] cp0_epc,

    input wb_wb_cp0,
    input [`CP0_REG_BUS] wb_cp0_write_addr,
    input [`DATA_BUS] wb_cp0_write,

    output force_disable_mem,

    output reg [`DATA_BUS] mem_cp0_status_override,
    output reg [`DATA_BUS] mem_cp0_epc_override,
    output reg [`DATA_BUS] mem_cp0_cause_override
);

    // ==== Data forwarding ====

    always @*
    begin
        if (!rst_n)
        begin
            mem_cp0_status_override <= 0;
        end
        else
        begin
            if (wb_wb_cp0 == `REG_WB && wb_cp0_write_addr == `CP0_REG_STATUS)
                mem_cp0_status_override <= wb_cp0_write;
            else
                mem_cp0_status_override <= cp0_status;
        end
    end

    always @*
    begin
        if (!rst_n)
        begin
            mem_cp0_epc_override <= 0;
        end
        else
        begin
            if (wb_wb_cp0 == `REG_WB && wb_cp0_write_addr == `CP0_REG_EPC)
                mem_cp0_epc_override <= wb_cp0_write_addr;
            else
                mem_cp0_epc_override <= cp0_epc;
        end
    end
    
    always @*
    begin
        if (!rst_n)
        begin
            mem_cp0_cause_override <= 0;
        end
        else
        begin
            if (wb_wb_cp0 == `MEM_WRITE && wb_cp0_write_addr == `CP0_REG_CAUSE)
            begin
                mem_cp0_cause_override[9:8] <= wb_cp0_write[9:8];
                mem_cp0_cause_override[22] <= wb_cp0_write[22];
                mem_cp0_cause_override[23] <= wb_cp0_write[23];
            end
            else
            begin
                mem_cp0_cause_override <= cp0_cause;
            end
        end
    end

    exception_handler #(.DATA_WIDTH(DATA_WIDTH)) except(
        .clk(clk),
        .rst_n(rst_n),

        .cp0_status(mem_cp0_status_override),
        .cp0_cause(mem_cp0_cause_override),
        .cp0_epc(mem_cp0_epc_override),

        .wb_wb_cp0(wb_wb_cp0),
        .wb_cp0_write_addr(wb_cp0_write_addr),
        .wb_cp0_write(wb_cp0_write),

        .exception_mask(),
        .pc(),
        .exception(),

        .force_disable_mem(force_disable_mem)
    );
endmodule