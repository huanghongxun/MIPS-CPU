`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/26 23:37:13
// Design Name: memory
// Module Name: memory
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


module memory#(parameter SIZE = 1024, parameter START_ADDR = 32'h8002_0000, parameter INITIAL_SNAP = "")(
    input clk,
    input [31:0] addr,
    input [31:0] din,
    output reg [31:0] dout, 
    output reg [31:0] pc,
    input [1:0] access_size,
    input rw, // 1 for writing, 0 for reading
    output reg busy,
    input enable
    );
    
    reg [7:0] mem[0:SIZE]; // per byte
    reg [31:0] cur_din;
    wire [5:0] cycles_remaining = 0; 
    reg [7:0] cycle_counter = 0;
    reg operating;
    reg [31:0] cur_addr = 'hffff; // current address, increment by 1 after each cycle
    reg cur_rw = 0; // rw status for cycles to come
    
    wire busy_wire = cycle_counter > 1;
    wire output_wire = cycle_counter != 0;
    
    initial begin
        if (INITIAL_SNAP != "")
            $readmemh(INITIAL_SNAP, mem);
    end
    
    always @(posedge clk or addr or enable or rw)
    begin
        if (busy_wire == 1)
            cur_addr = cur_addr + 4;
        else if (enable == 1)
            cur_addr = addr - START_ADDR;
            
        if (busy_wire == 0 && enable == 1)
        begin
            case (access_size)
                3'b000: cycle_counter = 1; // word
                3'b001: cycle_counter = 4; // 4 words
                3'b010: cycle_counter = 8; // 8 words
                3'b011: cycle_counter = 16; // 16 words
                3'b100: cycle_counter = 1; // byte
                3'b101: cycle_counter = 1; // half word
                default: cycle_counter = 0;
            endcase
            
            cur_rw = rw;
        end
        else
        begin
            cycle_counter = cycle_counter == 0 ? 0 : cycle_counter - 1;
            cur_rw = rw;
        end
        
        // read mode
        if (output_wire == 1 && cur_rw == 0)
        begin
            if (access_size == 3'b100)
                dout = mem[cur_addr];
            else if (access_size == 3'b101)
                dout = {mem[cur_addr], mem[cur_addr + 1]};
            else
                dout = {mem[cur_addr], mem[cur_addr + 1], mem[cur_addr + 2], mem[cur_addr + 3]};
                
            pc = cur_addr + START_ADDR;
        end
        else
            dout = 'bx;
            
        // write mode
        if (output_wire == 1 && cur_rw == 1)
        begin
            if (access_size == 3'b100)
                mem[cur_addr] = cur_din[7:0];
            else if (access_size == 3'b101)
                {mem[cur_addr], mem[cur_addr + 1]} = cur_din[15:0];
            else
                {mem[cur_addr], mem[cur_addr + 1], mem[cur_addr + 2], mem[cur_addr + 3]} = cur_din[31:0];
        end
        
        busy = busy_wire;
        cur_din = din;
    end
    
endmodule
