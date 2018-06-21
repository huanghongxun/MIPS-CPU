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
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 18,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3
)(
    input      clk,
    input      rst_n,
    input      flush,
    input      stall,

    input      wb_reg_in,
    output reg wb_reg_out,
    input      [DATA_WIDTH-1:0] wb_data_in,
    output reg [DATA_WIDTH-1:0] wb_data_out,
    input      [REG_ADDR_WIDTH-1:0] virtual_write_addr_in,
    output reg [REG_ADDR_WIDTH-1:0] virtual_write_addr_out,
    input      [REG_ADDR_WIDTH:0] physical_write_addr_in,
    output reg [REG_ADDR_WIDTH:0] physical_write_addr_out,
    input      [FREE_LIST_WIDTH-1:0] active_list_index_in,
    output reg [FREE_LIST_WIDTH-1:0] active_list_index_out

    );

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            wb_reg_out <= 0;
            wb_data_out <= 0;
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
                    wb_reg_out <= 0;
                    wb_data_out <= 0;
                    virtual_write_addr_out <= 0;
                    physical_write_addr_out <= 0;
                    active_list_index_out <= 0;
                end
                else
                begin
                    wb_reg_out <= wb_reg_in;
                    wb_data_out <= wb_data_in;
                    virtual_write_addr_out <= virtual_write_addr_in;
                    physical_write_addr_out <= physical_write_addr_in;
                    active_list_index_out <= active_list_index_in;
                end
            end
        end
    end
endmodule
