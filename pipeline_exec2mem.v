`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/06/06 21:42:04
// Design Name: Pipeline Stage: Execution to Memory Access
// Module Name: pipeline_exec2mem
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


module pipeline_exec2mem #(
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
    input      [DATA_WIDTH-1:0] alu_res_in,
    output     [DATA_WIDTH-1:0] alu_res_out,
    input                       mem_width_in,
    output                      mem_width_out,
    input                       mem_rw_in,
    output                      mem_rw_out,
    input                       mem_enable_in,
    output                      mem_enable_out,
    input                       sign_extend_in,
    output                      sign_extend_out,
    input                       
    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin

        end
        else
        begin
            if (!stall)
            begin
                if (flush)
                begin

                end
                else
                begin

                end
            end
        end
    end
endmodule
