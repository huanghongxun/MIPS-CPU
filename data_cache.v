`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Data Cache
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


module data_cache#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16, // main memory address width

    parameter ASSO_WIDTH = 1, // for n-way associative caching
    parameter BLOCK_OFFSET_WIDTH = 5, // width of address of a block
    parameter INDEX_WIDTH = 3,
    parameter TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - BLOCK_OFFSET_WIDTH // Upper 13 bits of the physical address (the tag) are compared to the 13 bit tag field at that cache entry.
)(
    input clk,
    input rst_n,

    // request
    input [ADDR_WIDTH-1:0] addr,
    input req_op, // 1 if we are requesting data
    input rw,

    input mem_width,
    input sign_extend,

    input [DATA_WIDTH-1:0] write,
    output reg [DATA_WIDTH-1:0] read,
    output reg read_valid,

    output ready,

    // BRAM transaction
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg mem_req_op,
    output reg mem_rw,

    input [DATA_WIDTH-1:0] mem_read,
    input mem_read_valid,

    output [DATA_WIDTH-1:0] mem_write,
    input mem_write_req_input,

    
    input mem_last
    );
/*
    // constants
    localparam ASSOCIATIVITY = 1<<ASSO_WIDTH;
    localparam BLOCK_SIZE = 1<<BLOCK_OFFSET_WIDTH;
    localparam BLOCK_INDEX = 1<<INDEX_WIDTH;

    // variable
    integer i;

    // physical memory address parsing
    wire [GROUP_INDEX_WIDTH -1:0] group_index  = addr[ADDR_WIDTH-1:BLOCK_INDEX_WIDTH+BLOCK_OFFSET_WIDTH];
    wire [BLOCK_INDEX_WIDTH -1:0] block_index  = addr[BLOCK_INDEX_WIDTH+BLOCK_OFFSET_WIDTH-1:BLOCK_OFFSET_WIDTH];
    wire [BLOCK_OFFSET_WIDTH-1:0] block_offset = addr[BLOCK_OFFSET_WIDTH-1:0];
    reg [BLOCKS_PER_GROUP_WIDTH-1:0] location;

    // registers to save operands of synchronization
    reg [GROUP_INDEX_WIDTH -1:0] group_index_reg;
    reg [BLOCK_INDEX_WIDTH -1:0] block_index_reg;
    reg [BLOCK_OFFSET_WIDTH-1:0] block_offset_reg;
    reg [BLOCK_PER_GROUP_WIDTH-1:0] location;

    reg [BLOCK_OFFSET_WIDTH-1:0] write_cnt; // block offset that we are pulling from memory. We always pull a full block from memory per miss.

    // cache storage
    reg [GROUP_INDEX_WIDTH-1:0] tags[0:(1<<BLOCK_INDEX_WIDTH)-1][0:BLOCKS_PER_GROUP-1];
    reg [DATA_WIDTH-1:0] blocks[0:(1<<BLOCK_INDEX_WIDTH)-1][0:BLOCKS_PER_GROUP-1][0:BLOCK_OFFSET-1];
    reg is_valid[0:(1<<BLOCK_INDEX_WIDTH)-1][0:BLOCKS_PER_GROUP-1];

    reg [1:0] state;
    reg [1:0] next_state;

    localparam STATE_READY = 0;
    localparam STATE_READ = 1;
    localparam STATE_WRITE = 2;
    localparam STATE_IDLE = 3;

    // determine which block is bound to the memory requested.
    always @*
    begin
        location <= 'bx;
        for (i = 0; i < BLOCKS_PER_GROUP; i = i + 1)
            if (tags[block_index][i] == group_index)
                location <= i;
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= STATE_READY;
            read_valid <= 0;
        end
        else
        begin
            case (state)
                STATE_READY: begin

                end
                STATE_READ: begin

                end
                STATE_WRITEBACK: begin
                    mem_rw <= WRITE;
                    if (mem_write_req_input)
                    begin
                        mem_write <= 
                    end
                end
            endcase
        end
    end*/
endmodule
