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

module pipeline_dec2exec #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3
)(
    input clk,
    input rst_n,
    input flush,
    input stall,
    
    input      [`ADDR_BUS] pc_in,
    output reg [`ADDR_BUS] pc_out,
    input      [`DATA_BUS] raw_inst_in,
    output reg [`DATA_BUS] raw_inst_out,
    input      [`INST_BUS] inst_in,
    output reg [`INST_BUS] inst_out,
    input      [`ALU_OP_BUS] alu_op_in,
    output reg [`ALU_OP_BUS] alu_op_out,
    input            [1:0] exec_src_in,
    output reg       [1:0] exec_src_out,
    input      [`DATA_BUS] alu_rs_in,
    output reg [`DATA_BUS] alu_rs_out,
    input      [`DATA_BUS] alu_rt_in,
    output reg [`DATA_BUS] alu_rt_out, // must process b_ctrl
    input                  mem_rw_in,
    output reg             mem_rw_out,
    input                  mem_enable_in,
    output reg             mem_enable_out,
    input      [`DATA_BUS] mem_write_in,
    output reg [`DATA_BUS] mem_write_out,
    input                  wb_src_in,
    output reg             wb_src_out,
    input                  wb_reg_in,
    output reg             wb_reg_out,
    input                  branch_in,
    output reg             branch_out,
    input      [`ADDR_BUS] branch_target_in,
    output reg [`ADDR_BUS] branch_target_out,
    input      [`VREG_BUS] virtual_write_addr_in,
    output reg [`VREG_BUS] virtual_write_addr_out,
    input      [`PREG_BUS] physical_write_addr_in,
    output reg [`PREG_BUS] physical_write_addr_out,
    input      [FREE_LIST_WIDTH-1:0] active_list_index_in,
    output reg [FREE_LIST_WIDTH-1:0] active_list_index_out
    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            pc_out <= 0;
            inst_out <= 0;
            alu_op_out <= 0;
            exec_src_out <= 0;
            alu_rs_out <= 0;
            alu_rt_out <= 0;
            inst_out <= 0;
            mem_rw_out <= 0;
            mem_enable_out <= 0;
            mem_write_out <= 0;
            wb_src_out <= 0;
            wb_reg_out <= 0;
            branch_out <= 0;
            branch_target_out <= 0;
            virtual_write_addr_out <= 0;
            physical_write_addr_out <= 0;
            active_list_index_out <= 0;
        end
        else
        begin
            if (!stall)
            begin
                if (flush)
                begin
                    pc_out <= 0;
                    inst_out <= 0;
                    alu_op_out <= 0;
                    exec_src_out <= 0;
                    alu_rs_out <= 0;
                    alu_rt_out <= 0;
                    inst_out <= 0;
                    mem_rw_out <= 0;
                    mem_enable_out <= 0;
                    mem_write_out <= 0;
                    wb_src_out <= 0;
                    wb_reg_out <= 0;
                    branch_out <= 0;
                    branch_target_out <= 0;
                    virtual_write_addr_out <= 0;
                    physical_write_addr_out <= 0;
                    active_list_index_out <= 0;
                end
                else
                begin
                    pc_out <= pc_in;
                    inst_out <= inst_in;
                    alu_op_out <= alu_op_in;
                    exec_src_out <= exec_src_in;
                    alu_rs_out <= alu_rs_in;
                    alu_rt_out <= alu_rt_in;
                    inst_out <= inst_in;
                    mem_rw_out <= mem_rw_in;
                    mem_enable_out <= mem_enable_in;
                    mem_write_out <= mem_write_in;
                    wb_src_out <= wb_src_in;
                    wb_reg_out <= wb_reg_in;
                    branch_out <= branch_in;
                    branch_target_out <= branch_target_in;
                    virtual_write_addr_out <= virtual_write_addr_in;
                    physical_write_addr_out <= physical_write_addr_in;
                    active_list_index_out <= active_list_index_in;
                end
            end
        end
    end
endmodule
