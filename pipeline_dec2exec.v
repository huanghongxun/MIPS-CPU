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


module pipeline_dec2exec #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5)
    (
    input clk,
    input rst_n,
    input flush,
    input stall,
    
    input      [ADDR_WIDTH-1:0] pc_in,
    output reg [ADDR_WIDTH-1:0] pc_out,
    input      [DATA_WIDTH-1:0] inst_in,
    output reg [DATA_WIDTH-1:0] inst_out,
    input      [           4:0] alu_op_in,
    output     [           4:0] alu_op_out,
    input      [DATA_WIDTH-1:0] alu_rs_in,
    output reg [DATA_WIDTH-1:0] alu_rs_out,
    input      [DATA_WIDTH-1:0] alu_rt_in,
    output reg [DATA_WIDTH-1:0] alu_rt_out, // must process b_ctrl
    input      [           2:0] mem_mask_in,
    output     [           2:0] mem_mask_out,
    input      [           2:0] wb_mask_in,
    output     [           2:0] wb_mask_out,

    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            pc_out = 0;
            inst_out = 0;
            alu_op_out = 0;
            alu_rs_out = 0;
            alu_rt_out = 0;
            mem_mask_out = 0;
            wb_mask_out = 0;
        end
        else
        begin
            if (!stall)
            begin
                if (flush)
                begin
                    pc_out = 0;
                    inst_out = 0;
                    alu_op_out = 0;
                    alu_rs_out = 0;
                    alu_rt_out = 0;
                    mem_mask_out = 0;
                    wb_mask_out = 0;
                end
                else
                begin
                    pc_out = pc_in;
                    inst_out = inst_in;
                    alu_op_out = alu_op_in;
                    alu_rs_out = alu_rs_in;
                    alu_rt_out = alu_rt_in;
                    mem_mask_out = mem_mask_in;
                    wb_mask_out = wb_mask_in;
                end
            end
        end
    end
endmodule
