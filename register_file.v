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


module register_file
    #(parameter SIZE = 32, parameter WIDTH = 32)
    (clk, ra, rb, a, b, rw, wn, wd);
    
    localparam W = WIDTH - 1;
    localparam POW = $clog2(WIDTH); // default 5
    localparam SZW = $clog2(SIZE); // default 5
    localparam BYTES = WIDTH / 8;
    
    input clk; // clock signal
    input [SZW - 1:0] ra; // register index of A
    input [SZW - 1:0] rb; // register index of B
    output reg [W:0] a = 0; // value of register A
    output reg [W:0] b = 0; // value of register B
    input [SZW - 1:0] rw; // register index of C
    input wn; // enable writing
    input [W:0] wd; // if wn = 1, value of C will be overriden to wd.
    
    reg [W:0] registers[0:SIZE - 1];
    integer i;
    
    initial begin
        for (i = 0; i < 32; i = i + 1)
        begin
            if (i == 29) // sp
                registers[i] = 32'h8002_03FF;
            else if (i == 31) // ra, return address
                registers[i] = 32'hDEAD_BEEF;
            else
                registers[i] = 0;
        end
    end
    
    always @(posedge clk)
    begin
        if (wn == 1) // in write mode
            if (rw != 0) // zero register cannot be written.
                registers[rw] = wd;
        a = registers[ra]; // if ra or rb equals to rw, a or b will equal to wd.
        b = registers[rb];
    end
endmodule
