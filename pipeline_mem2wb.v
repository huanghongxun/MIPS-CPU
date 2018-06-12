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


module pipeline_mem2wb #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5)
    (
    input                       clk,
    input                       rst_n,
    input                       flush,
    input                       stall,

    input                       wb_in,
    output                      wb_out,
    input      [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out,
    input      
    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            wb_out = 0;
            data_out = 0;
        end
        else
        begin
            if (!stall)
            begin
                if (flush)
                begin
                    wb_out = 0;
                    data_out = 0;
                end
                else
                begin
                    wb_out = wb_in;
                    data_out = data_in;
                    
                end
            end
        end
    end
endmodule
