`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/13 13:39:30
// Design Name: 
// Module Name: select_2to1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module selector#(parameter WIDTH = 32)(in, reget, out);
    localparam W = WIDTH - 1;
    localparam POW = $clog2(WIDTH);
    
    input [W:0] in;
    input [POW - 1:0] reget;
    output reg [W:0] out;
    
    always @*
        out = in[reget];
endmodule