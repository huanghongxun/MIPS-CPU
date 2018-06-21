`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Forwarding Unit
// Module Name: data_cache
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//   Pipeline bypass
//
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   See https://en.wikipedia.org/wiki/Classic_RISC_pipeline
// 
//////////////////////////////////////////////////////////////////////////////////


module forwarding_unit#(
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5
)(
    // feedback from decode stage
    input dec_rs_enable,
    input [REG_ADDR_WIDTH-1:0] dec_vrs_addr,
    input [REG_ADDR_WIDTH:0] dec_prs_addr,
    input [DATA_WIDTH-1:0] dec_rs_data,
    input dec_rt_enable,
    input [REG_ADDR_WIDTH-1:0] dec_vrt_addr,
    input [REG_ADDR_WIDTH:0] dec_prt_addr,
    input [DATA_WIDTH-1:0] dec_rt_data,

    // feedback from execution stage
    input exec_wb_reg,
    input exec_alu_en,
    input [REG_ADDR_WIDTH:0] exec_write_addr,
    input [DATA_WIDTH-1:0] exec_write,

    // feedback from memory access stage
    input mem_wb_reg,
    input [REG_ADDR_WIDTH:0] mem_write_addr,
    input [DATA_WIDTH-1:0] mem_write,

    // feedback from write back stage
    input wb_wb_reg,
    input [REG_ADDR_WIDTH:0] wb_write_addr,
    input [DATA_WIDTH-1:0] wb_write,

    output reg [DATA_WIDTH-1:0] dec_rs_override,
    output reg [DATA_WIDTH-1:0] dec_rt_override
    );

    always @*
    begin
        dec_rs_override <= dec_rs_data;
        dec_rt_override <= dec_rt_data;

        if (dec_rs_enable)
        begin
            if (exec_wb_reg && exec_alu_en && dec_prs_addr == exec_write_addr)
                dec_rs_override <= exec_write;
            else if (mem_wb_reg && dec_prs_addr == mem_write_addr)
                dec_rs_override <= mem_write;
            else if (wb_wb_reg && dec_prs_addr == wb_write_addr)
                dec_rs_override <= wb_write;
        end

        if (dec_rt_enable)
        begin
            if (exec_wb_reg && exec_alu_en && dec_prt_addr == exec_write_addr)
                dec_rt_override <= exec_write;
            else if (mem_wb_reg && dec_prt_addr == mem_write_addr)
                dec_rt_override <= mem_write;
            else if (wb_wb_reg && dec_prt_addr == wb_write_addr)
                dec_rt_override <= wb_write;
        end


    end

endmodule
