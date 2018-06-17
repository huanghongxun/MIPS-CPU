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


module regfile_renaming#(
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3,
    parameter CHECKPOINT_WIDTH = 2
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
 
    // reverting todo
    input create_map_checkpoint,
    input create_list_checkpoint,
    input revert,
    input [CHECKPOINT_WIDTH-1:0] revert_checkpoint,

    //
    output [REG_ADDR_WIDTH:0] physical_rs_addr,
    output [REG_ADDR_WIDTH:0] physical_rt_addr,
    output [REG_ADDR_WIDTH:0] physical_rd_addr,

    output [FREE_LIST_WIDTH-1:0] active_list_index,
    output reg [CHECKPOINT_WIDTH-1:0] checkpoint = 0,
    
    output reg stall_out
    );

    localparam REG_ADDR_SIZE = 1 << REG_ADDR_WIDTH;
    localparam FREE_LIST_SIZE = 1 << FREE_LIST_WIDTH;
    localparam CHECKPOINT = 1 << CHECKPOINT_WIDTH;


    localparam READ = 0;
    localparam WRITE = 1;

    integer i;

    reg [DATA_WIDTH-1:0] preg[0:REG_ADDR_SIZE+ (1 << FREE_LIST_WIDTH) - 1];
    reg [REG_ADDR_WIDTH:0] free_list[0:FREE_LIST_SIZE-1];
    reg [REG_ADDR_WIDTH+CHECKPOINT_WIDTH+1:0] active_list[0:FREE_LIST_SIZE-1];

    reg [REG_ADDR_WIDTH:0] map_table[0:CHECKPOINT-1][0:REG_ADDR_SIZE-1];
    reg [FREE_LIST_WIDTH-1:0] free_list_head[0:CHECKPOINT-1];
    reg [FREE_LIST_WIDTH-1:0] free_list_tail[0:CHECKPOINT-1];
    reg [FREE_LIST_WIDTH-1:0] free_list_size[0:CHECKPOINT-1];
    reg [FREE_LIST_WIDTH-1:0] active_list_head[0:CHECKPOINT-1];
    reg [FREE_LIST_WIDTH-1:0] active_list_tail[0:CHECKPOINT-1];
    reg [FREE_LIST_WIDTH-1:0] active_list_size[0:CHECKPOINT-1];
    reg [CHECKPOINT_WIDTH-1:0] used_checkpoints = 0;
    reg [CHECKPOINT_WIDTH-1:0] used_checkpoints2 = 0;

    assign physical_rs_addr = map_table[checkpoint][virtual_rs_addr];
    assign physical_rt_addr = map_table[checkpoint][virtual_rt_addr];

    assign virtual_rs_data = (virtual_rs_addr == 0) ? 0 : preg[physical_rs_addr];
    assign virtual_rt_data = (virtual_rt_addr == 0) ? 0 : preg[physical_rt_addr];
    assign physical_rd_addr = (virtual_rd_addr == 0) ? 0 : free_list[free_list_head[checkpoint]];
    assign active_list_index = active_list_tail[checkpoint];

    wire done;
    wire [REG_ADDR_WIDTH:0] old_preg_addr;
    wire [CHECKPOINT_WIDTH-1:0] active_checkpoint;

    wire commit_enabled = used_checkpoints == 0 ? 1 : 0;
    wire write_enabled = dec_rw == WRITE && (virtual_rd_addr != 0) && !stall_in;

    assign {old_preg_addr, active_checkpoint, done} = active_list[active_list_head[checkpoint]];

    always @*
    begin
        if (create_map_checkpoint)
            used_checkpoints2 <= used_checkpoints + 1;
        else
            used_checkpoints2 <= used_checkpoints;
    end
    
    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            preg[0] <= 0;
            active_list_head[checkpoint] <= 0;
            active_list_tail[checkpoint] <= 0;
            active_list_size[checkpoint] <= 0;
            free_list_head[checkpoint] <= 0;
            free_list_tail[checkpoint] <= FREE_LIST_SIZE - 1;
            free_list_size[checkpoint] <= FREE_LIST_SIZE - 1;
            for (i = 0; i < FREE_LIST_SIZE; i = i + 1)
                free_list[i] <= REG_ADDR_SIZE + i;
            for (i = 0; i < REG_ADDR_SIZE; i = i + 1)
                map_table[checkpoint][i] <= i;
        end
        else
        begin
            used_checkpoints = used_checkpoints2;

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
                free_list_head[checkpoint] <= free_list_head[checkpoint] + 1;
                active_list_tail[checkpoint] <= active_list_tail[checkpoint] + 1;
                free_list_size[checkpoint] <= free_list_size[checkpoint] - 1;
                active_list_size[checkpoint] <= active_list_size[checkpoint] + 1;
                active_list[active_list_tail[checkpoint]] <= {map_table[checkpoint][virtual_rd_addr], checkpoint, 1'b0};
                map_table[checkpoint][virtual_rd_addr] <= free_list[free_list_head[checkpoint]];
                if (active_checkpoint != checkpoint)
                begin
                    free_list_head[active_checkpoint] <= free_list_head[checkpoint] + 1;
                    active_list_tail[active_checkpoint] <= active_list_tail[checkpoint] + 1;
                    free_list_size[active_checkpoint] <= free_list_size[checkpoint] - 1;
                    active_list_size[active_checkpoint] <= active_list_size[checkpoint] + 1;
                    active_list[active_list_tail[active_checkpoint]] <= {map_table[checkpoint][virtual_rd_addr], checkpoint, 1'b0};
                    map_table[active_checkpoint][virtual_rd_addr] <= free_list[free_list_head[checkpoint]];
                end
            end

            // create a checkpoint for reverting.
            if (create_map_checkpoint)
            begin
                // we have run out of all physical registers
                if (used_checkpoints == CHECKPOINT - 1)
                begin
                    stall_out <= 1;
                end
                else // allocate a pregsiter
                begin
                    checkpoint <= checkpoint + 1;
                    for (i = 0; i < REG_ADDR_SIZE; i = i + 1)
                        map_table[checkpoint + 1][i] <= map_table[checkpoint][i];
                end

                // clone the state
                free_list_head[checkpoint + 1] <= free_list_head[checkpoint];
                free_list_tail[checkpoint + 1] <= free_list_tail[checkpoint];
                free_list_size[checkpoint + 1] <= free_list_size[checkpoint];
                active_list_head[checkpoint + 1] <= active_list_head[checkpoint];
                active_list_tail[checkpoint + 1] <= active_list_tail[checkpoint];
                active_list_size[checkpoint + 1] <= active_list_size[checkpoint];
            end

            if (revert)
            begin
                checkpoint <= revert_checkpoint;
            end

            // if the instruction is done and committed, free the allocated register.
            if (done == 1 && commit_enabled)
            begin
                active_list_head[checkpoint] <= active_list_head[checkpoint] + 1;
                active_list_size[checkpoint] <= active_list_head[checkpoint] - 1;
                active_list[active_list_head[checkpoint]][0] <= 0;
                free_list[free_list_tail[checkpoint]] <= old_preg_addr;
                free_list_tail[checkpoint] <= free_list_tail[checkpoint] + 1;
                free_list_size[checkpoint] <= free_list_size[checkpoint] + 1;
            end
        end
    end
endmodule
