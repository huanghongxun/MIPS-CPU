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
//
//   physical address(width 16, 1 word per addr):
//   [group index | block index | block offset]
//         8             3             5

//   physical address(width 18, 1 byte per addr):
//   [group index | block index | block offset]
//         8             3             7
//
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module forwarding_unit#(
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5
)(
    input [REG_ADDR_WIDTH-1:0] dec_rs_addr;
    input [DATA_WIDTH-1:0] dec_rs_data;
    input [REG_ADDR_WIDTH-1:0] dec_rt_addr;
    input [DATA_WIDTH-1:0] dec_rt_data;

    // feedback from execution stage
    input exec_wb,
    input exec_uses_alu,
    input [REG_ADDR_WIDTH-1:0] exec_rd_addr;
    );
endmodule
