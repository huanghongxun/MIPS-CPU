`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen Univeristy
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/24 22:44:43
// Design Name: Register File
// Module Name: register_file
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 32 MIPS registers.
//     0: $zero
//     1: $at, reserved for assemblers to do with large constants.
//   2~3: $v0 - $v1, stores function results.
//   4~7: $a0 - $a3, pass function parameters.
//  8~15: $t0 - $t7, stores temporary variables.
// 16~23: $s0 - $s7, stores temporary variables to be stored in memory.
// 24~25: $t8 - $t9, stores extra temporary variables,
// 26-27: $k0 - $k1, for operating system kernel.
//    28: $gp, pointer to global variables.
//    29: $sp, pointer to top of the stack.
//    30: $fp, pointer to frame.
//    31: $ra: return address for function calls.
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module register_file #(
    parameter SIZE = 32,
    parameter DATA_WIDTH = 32
)(
    input clk,
    
    input [REG_ADDR_WIDTH-1:0] ra_addr,
    input [REG_ADDR_WIDTH-1:0] rb_addr,
    
    output [DATA_WIDTH-1:0] ra_data,
    output [DATA_WIDTH-1:0] rb_data,
    
    input rw,
    input [REG_ADDR_WIDTH-1:0] write_addr,
    input [DATA_WIDTH-1:0] write_data
    );
    
    localparam READ = 0;
    localparam WRITE = 1;
    
    reg [DATA_WIDTH-1:0] registers[0:SIZE - 1];
    
    assign ra_data = ra_addr == 0 ? 0 : registers[ra_addr];
    assign rb_data = rb_addr == 0 ? 0 : registers[rb_addr];
    
    always @(posedge clk)
    begin
        // zero register cannot be written
        if (rw == WRITE && write_addr != 0)
            registers[rw] = wd;
    end
endmodule
