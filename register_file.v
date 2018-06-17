`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Register renaming for register file
// Module Name: regfile_renaming
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//
//
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   See https://en.wikipedia.org/wiki/Register_renaming
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module register_file#(
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3
)(
    input clk,
    input rst_n,
    input stall_in,

    // decode
    input [REG_ADDR_WIDTH-1:0] virtual_rs_addr,
    output [DATA_WIDTH-1:0] virtual_rs_data,
    input [REG_ADDR_WIDTH-1:0] virtual_rt_addr,
    output [DATA_WIDTH-1:0] virtual_rt_data,
    input dec_rw,
    input [REG_ADDR_WIDTH-1:0] virtual_rd_addr,

    // write back stage
    input mem_write_enable,
    input [REG_ADDR_WIDTH:0] wb_physical_write_addr,
    input [DATA_WIDTH-1:0] wb_physical_write_data,
    input [REG_ADDR_WIDTH:0] wb_virtual_write_addr,
    input [FREE_LIST_WIDTH-1:0] wb_active_list_index, // last index of active list for reverting
 
    // physical register address
    output [REG_ADDR_WIDTH:0] physical_rs_addr,
    output [REG_ADDR_WIDTH:0] physical_rt_addr,
    output [REG_ADDR_WIDTH:0] physical_rd_addr,

    output [FREE_LIST_WIDTH-1:0] active_list_index,
    
    output reg stall_out
    );

    localparam REG_ADDR_SIZE = 1 << REG_ADDR_WIDTH;
    localparam FREE_LIST_SIZE = 1 << FREE_LIST_WIDTH;

    integer i;

    reg [DATA_WIDTH-1:0] preg[0:REG_ADDR_SIZE+ (1 << FREE_LIST_WIDTH) - 1];
    reg [REG_ADDR_WIDTH:0] free_list[0:FREE_LIST_SIZE-1];
    reg [REG_ADDR_WIDTH+1:0] active_list[0:FREE_LIST_SIZE-1];

    reg [REG_ADDR_WIDTH:0] map_table[0:REG_ADDR_SIZE-1];
    reg [FREE_LIST_WIDTH-1:0] free_list_head;
    reg [FREE_LIST_WIDTH-1:0] free_list_tail;
    reg [FREE_LIST_WIDTH-1:0] free_list_size;
    reg [FREE_LIST_WIDTH-1:0] active_list_head;
    reg [FREE_LIST_WIDTH-1:0] active_list_tail;
    reg [FREE_LIST_WIDTH-1:0] active_list_size;

    assign physical_rs_addr = map_table[virtual_rs_addr];
    assign physical_rt_addr = map_table[virtual_rt_addr];

    assign virtual_rs_data = (virtual_rs_addr == 0) ? 0 : preg[physical_rs_addr];
    assign virtual_rt_data = (virtual_rt_addr == 0) ? 0 : preg[physical_rt_addr];
    assign physical_rd_addr = (virtual_rd_addr == 0) ? 0 : free_list[free_list_head];
    assign active_list_index = active_list_tail;

    wire done;
    wire [REG_ADDR_WIDTH:0] old_preg_addr;

    wire write_enabled = dec_rw == `MEM_WRITE && (virtual_rd_addr != 0) && !stall_in;

    assign {old_preg_addr, done} = active_list[active_list_head];

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            preg[0] <= 0;
            active_list_head <= 0;
            active_list_tail <= 0;
            active_list_size <= 0;
            free_list_head <= 0;
            free_list_tail <= FREE_LIST_SIZE - 1;
            free_list_size <= FREE_LIST_SIZE - 1;
            for (i = 0; i < FREE_LIST_SIZE; i = i + 1)
                free_list[i] <= REG_ADDR_SIZE + i;
            for (i = 0; i < REG_ADDR_SIZE; i = i + 1)
                map_table[i] <= i;
        end
        else
        begin
            // perform write
            if (mem_write_enable && (wb_physical_write_addr != 0))
            begin
                preg[wb_physical_write_addr] <= wb_physical_write_data;
                active_list[active_list_index][0] <= 1;
            end

            // if instruction writes to reg, allocate a register
            // so move one item from free list to active list.
            if (write_enabled)
            begin
                free_list_head <= free_list_head + 1;
                active_list_tail <= active_list_tail + 1;
                free_list_size <= free_list_size - 1;
                active_list_size <= active_list_size + 1;
                active_list[active_list_tail] <= {map_table[virtual_rd_addr], 1'b0};
                map_table[virtual_rd_addr] <= free_list[free_list_head];
            end


            // if the instruction is done and committed, free the allocated register.
            if (done)
            begin
                active_list_head <= active_list_head + 1;
                active_list_size <= active_list_head - 1;
                active_list[active_list_head][0] <= 0;
                free_list[free_list_tail] <= old_preg_addr;
                free_list_tail <= free_list_tail + 1;
                free_list_size <= free_list_size + 1;
            end
        end
    end
endmodule
