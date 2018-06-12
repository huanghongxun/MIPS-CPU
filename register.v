`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/06/12 16:33:28
// Design Name: 
// Module Name: register
// Project Name: CPU
// Target Devices: Basys3
// Tool Versions: Vivado 2015.4
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module register#(parameter WIDTH = 32)(storage, set, write);
    localparam W = WIDTH - 1;
    
    output reg [W:0] storage = 0;
    input [W:0] set;
    input write;
    
    always @*
    begin
        if (write == 1)
            storage = set;
    end
    
endmodule
