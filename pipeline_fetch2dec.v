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


module pipeline_fetch2dec #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input clk,
    input rst_n,
    input flush,
    input stall,

    input      [`ADDR_BUS] pc_in,
    output reg [`ADDR_BUS] pc_out,
    input      [`DATA_BUS] inst_in,
    output reg [`DATA_BUS] inst_out,
    input                       bubble_in,
    output reg                  bubble_out
    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            pc_out <= 0;
            inst_out <= 0;
            bubble_out <= 0;
        end
        else
        begin
            if (!stall)
            begin
                if (flush)
                begin
                    pc_out <= 0;
                    inst_out <= 0;
                end
                else
                begin
                    pc_out <= pc_in;
                    inst_out <= inst_in;
                    bubble_out <= bubble_in;
                end
            end
        end
    end
endmodule
