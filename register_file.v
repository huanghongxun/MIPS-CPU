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
    parameter FREE_LIST_WIDTH = 5
)(
    input clk,
    input rst_n,
    input stall_in,

    // decode
    input [`VREG_BUS] virtual_rs_addr, // the first operand register index of the inst in decode stage
    output [`DATA_BUS] virtual_rs_data, // the data of the first operand register
    input [`VREG_BUS] virtual_rt_addr, // the second operand register index of the inst in decode stage
    output [`DATA_BUS] virtual_rt_data, // the data of the second operand register
    input dec_rw, // write or read mode
    input [`VREG_BUS] virtual_rd_addr, // the result register index of the inst in decode stage

    // write back stage
    input wb_write_enable, // if the inst in write back stage writes back
    input [`PREG_BUS] wb_physical_write_addr, // the physical(allocated) result register index of the inst in wb stage.
    input [`DATA_BUS] wb_physical_write_data, // the data to write
    input [FREE_LIST_WIDTH-1:0] wb_active_list_index, // last index of active list for reverting
 
    // physical register address
    output [`PREG_BUS] physical_rs_addr, // the allocated register index of the first operand register of the inst in decode stage
    output [`PREG_BUS] physical_rt_addr, // the allocated register index of the second operand register of the inst in decode stage
    output [`PREG_BUS] physical_rd_addr, // the allocated register index of the result register of the inst in decode stage

    output [FREE_LIST_WIDTH-1:0] active_list_index,
    
    output reg stall_out // if stall decode stage
    );

    localparam FREE_LIST_SIZE = 1 << FREE_LIST_WIDTH;

    integer i;

    reg [`DATA_BUS] preg[0:`REG_SIZE + FREE_LIST_SIZE - 1];
    reg [`PREG_BUS] free_list[0:FREE_LIST_SIZE-1];
    reg [`PREG_BUS] active_list[0:FREE_LIST_SIZE-1];
    reg             active_done[0:FREE_LIST_SIZE-1];

    reg [`PREG_BUS] map_table[0:`REG_SIZE-1];
    reg [FREE_LIST_WIDTH-1:0] free_list_head;
    reg [FREE_LIST_WIDTH-1:0] free_list_tail;
    reg [FREE_LIST_WIDTH-1:0] free_list_size;
    reg [FREE_LIST_WIDTH-1:0] active_list_head;
    reg [FREE_LIST_WIDTH-1:0] active_list_tail;

    assign physical_rs_addr = map_table[virtual_rs_addr];
    assign physical_rt_addr = map_table[virtual_rt_addr];

    assign virtual_rs_data = (virtual_rs_addr == 0) ? 0 : preg[physical_rs_addr];
    assign virtual_rt_data = (virtual_rt_addr == 0) ? 0 : preg[physical_rt_addr];
    assign physical_rd_addr = (virtual_rd_addr == 0) ? 0 : free_list[free_list_head];
    assign active_list_index = active_list_tail;

    wire done;
    wire [`PREG_BUS] old_preg_addr;

    wire write_enabled = dec_rw == `MEM_WRITE && (virtual_rd_addr != 0) && !stall_in;

    assign old_preg_addr = active_list[active_list_head];
    assign done = active_done[active_list_head];

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            stall_out <= 0;
        
            active_list_head <= 0;
            active_list_tail <= 0;
            free_list_head <= 0;
            free_list_tail <= FREE_LIST_SIZE - 1;
            free_list_size <= FREE_LIST_SIZE - 1;
            for (i = 0; i < `REG_SIZE + FREE_LIST_SIZE; i = i + 1)
                preg[i] <= 0;
            for (i = 0; i < FREE_LIST_SIZE; i = i + 1)
            begin
                free_list[i] <= `REG_SIZE + i;
                active_list[i] <= 0;
                active_done[i] <= 0;
            end
            for (i = 0; i < `REG_SIZE; i = i + 1)
                map_table[i] <= i;
        end
        else
        begin
            stall_out <= 0;
        
            // perform write
            if (wb_write_enable && (wb_physical_write_addr != 0))
            begin
                preg[wb_physical_write_addr] <= wb_physical_write_data;
                active_done[wb_active_list_index] <= 1;
            end

            // if instruction writes to reg, allocate a register
            // so move one item from free list to active list.
            if (write_enabled)
            begin
                if (free_list_size == 0)
                begin
                    // if no physical register can be allocated,
                    // wait for register collection.
                    stall_out <= 1;
`ifdef DEBUG_REG
                    $display("Register file encountered lack of physical registers");
`endif
                end
                else
                begin
                    free_list_head <= free_list_head + 1;
                    active_list_tail <= active_list_tail + 1;
                    active_list[active_list_tail] <= map_table[virtual_rd_addr];
                    active_done[active_list_tail] <= 0;
                    map_table[virtual_rd_addr] <= free_list[free_list_head];
                    free_list_size <= free_list_size - 1;
                end
            end


            // if the instruction is done and committed, free the allocated register.
            if (done)
            begin
                active_list_head <= active_list_head + 1;
                active_done[active_list_head] <= 0;
                free_list[free_list_tail] <= old_preg_addr;
                free_list_tail <= free_list_tail + 1;
                free_list_size <= free_list_size + 1;
            end
        end
    end
endmodule
