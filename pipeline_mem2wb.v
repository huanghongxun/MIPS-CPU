`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/06/06 21:42:04
// Design Name: Pipeline Stage: Instruction Fetch to Decode
// Module Name: pipeline_fetch2dec
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

module pipeline_mem2wb #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 18,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3
)(
    input      clk,
    input      rst_n,
    input      flush,
    input      global_flush,
    input      stall,

    input      wb_reg_in,
    output reg wb_reg_out,
    input      [`DATA_BUS] reg_write_in,
    output reg [`DATA_BUS] reg_write_out,
    input      [`VREG_BUS] virtual_write_addr_in,
    output reg [`VREG_BUS] virtual_write_addr_out,
    input      [`PREG_BUS] physical_write_addr_in,
    output reg [`PREG_BUS] physical_write_addr_out,
    input      [FREE_LIST_WIDTH-1:0] active_list_index_in,
    output reg [FREE_LIST_WIDTH-1:0] active_list_index_out,
    input                  wb_cp0_in,
    output reg             wb_cp0_out,
    input      [`CP0_REG_BUS] cp0_write_addr_in,
    output reg [`CP0_REG_BUS] cp0_write_addr_out,
    input      [`DATA_BUS] cp0_write_in,
    output reg [`DATA_BUS] cp0_write_out

    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            wb_reg_out <= 0;
            reg_write_out <= 0;
            virtual_write_addr_out <= 0;
            physical_write_addr_out <= 0;
            active_list_index_out <= 0;
            wb_cp0_out <= 0;
            cp0_write_addr_out <= 0;
            cp0_write_out <= 0;
        end
        else
        begin
            if (!stall)
            begin
                if (flush || global_flush)
                begin
                    wb_reg_out <= 0;
                    reg_write_out <= 0;
                    virtual_write_addr_out <= 0;
                    physical_write_addr_out <= 0;
                    active_list_index_out <= 0;
                    wb_cp0_out <= 0;
                    cp0_write_addr_out <= 0;
                    cp0_write_out <= 0;
                end
                else
                begin
                    wb_reg_out <= wb_reg_in;
                    reg_write_out <= reg_write_in;
                    virtual_write_addr_out <= virtual_write_addr_in;
                    physical_write_addr_out <= physical_write_addr_in;
                    active_list_index_out <= active_list_index_in;
                    wb_cp0_out <= wb_cp0_in;
                    cp0_write_addr_out <= cp0_write_addr_in;
                    cp0_write_out <= cp0_write_in;
                end
            end
        end
    end
endmodule
