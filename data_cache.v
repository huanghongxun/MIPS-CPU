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

`include "defines.v"

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
    input enable, // 1 if we are requesting data
    input rw,
    input mem_width,
    input sign_extend,

    input [DATA_WIDTH-1:0] write,
    output reg [DATA_WIDTH-1:0] read,
    output reg rw_valid = 0,

    output ready,

    // BRAM transaction
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg mem_enable,
    output reg mem_rw,

    input [DATA_WIDTH-1:0] mem_read,
    input mem_read_valid,

    output reg [DATA_WIDTH-1:0] mem_write,
    input mem_write_req_input,

    
    input mem_last
    );

    // constants
    localparam ASSOCIATIVITY = 1 << ASSO_WIDTH;
    localparam BLOCK_SIZE = 1 << BLOCK_OFFSET_WIDTH;
    localparam INDEX_SIZE = 1 << INDEX_WIDTH;
    localparam TAG_SIZE = 1 << TAG_WIDTH;

    // states
    localparam STATE_READY = 0; // Ready for requests.
    localparam STATE_PAUSE = 1;
    localparam STATE_POPULATE = 2; // MISS
    localparam STATE_WRITEOUT = 3; // Write dirty block back to RAM.

    // variable
    integer i, j, k;
    
    reg [1:0] state;
    reg rw_internal;

    // physical memory address parsing
    wire [TAG_WIDTH         -1:0] tag  = addr[ADDR_WIDTH-1:INDEX_WIDTH+BLOCK_OFFSET_WIDTH];
    wire [INDEX_WIDTH       -1:0] block_index  = addr[INDEX_WIDTH+BLOCK_OFFSET_WIDTH-1:BLOCK_OFFSET_WIDTH];
    wire [BLOCK_OFFSET_WIDTH-1:0] block_offset = addr[BLOCK_OFFSET_WIDTH-1:0];
    reg  [ASSO_WIDTH        -1:0] location;
    
    // registers to save operands of synchronization
    reg                           rw_reg;
`ifdef DEBUG_MODE
    reg  [ADDR_WIDTH        -1:0] addr_reg;
`endif
    reg  [TAG_WIDTH         -1:0] tag_reg;
    reg  [INDEX_WIDTH       -1:0] block_index_reg;
    reg  [BLOCK_OFFSET_WIDTH-1:0] block_offset_reg;
    reg  [ASSO_WIDTH        -1:0] location_reg;
    reg  [DATA_WIDTH        -1:0] write_reg;

    reg [BLOCK_OFFSET_WIDTH-1:0] cnt; // block offset that we are pulling from memory. We always pull a full block from memory per miss.

    // cache storage
    reg [TAG_WIDTH-1:0] tags[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1]; // which group in memory
    reg [DATA_WIDTH-1:0] blocks[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1][0:BLOCK_SIZE-1]; // cached blocks
    reg valid[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1]; // true if this cache space has stored a block.
    reg dirty[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1]; // is cached block dirty.
    
    assign ready = state == STATE_READY;

    wire cache_hit = enable && valid[block_index][location] && tags[block_index][location] == tag && !rw_valid;
    wire cache_read_hit = cache_hit && rw == `MEM_READ && state == STATE_READY;
    wire cache_write_hit = cache_hit && rw == `MEM_WRITE && state == STATE_READY;
    wire cache_miss = !cache_hit && enable && !rw_valid;

    wire populate = rw_reg == `MEM_WRITE && mem_read_valid && cnt == block_offset_reg && state == STATE_POPULATE;
    wire [DATA_WIDTH-1:0] populate_data = populate ? write_reg : mem_read;

    // determine which block is bound to the memory requested.
    always @*
    begin
        location = 'bx;
        for (i = 0; i < ASSOCIATIVITY; i = i + 1)
            if (tags[block_index][i] == tag)
                location = i;
        if (location === 'bx)
            for (i = 0; i < ASSOCIATIVITY; i = i + 1)
                if (tags[block_index][i] === 'bx)
                    location = i;
        if (location === 'bx)
            location = 0;
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= STATE_READY;
            mem_enable <= `FALSE;
            
            rw_valid <= `FALSE;
            
            block_offset_reg <= 0;
            block_index_reg <= 0;
            tag_reg <= 0;
            location_reg <= 0;
            rw_reg <= 0;
            write_reg <= 0;
            cnt <= 0;
            mem_rw <= 0;
            mem_addr <= 0;
            mem_write <= 0;
            read <= 0;
            
            for (i = 0; i < INDEX_SIZE; i = i + 1)
                for (j = 0; j < ASSOCIATIVITY; j = j + 1)
                begin
                    tags[i][j] <= 'bx;
                    valid[i][j] <= 0;
                    dirty[i][j] <= 0;
                    for (k = 0; k < BLOCK_SIZE; k = k + 1)
                        blocks[i][j][k] <= 0;
                end
        end
        else
        begin
            rw_valid <= `FALSE;

            case (state)
                STATE_READY: begin
                    if (cache_read_hit)
                    begin
                        rw_reg <= `MEM_READ;
                        rw_valid <= `TRUE;
                        block_offset_reg <= block_offset;
                        read <= blocks[block_index][location][block_offset];
`ifdef DEBUG_MODE
                        $display("Data cache read addr %x hit, data %x", addr, read);
`endif
                    end
                    else if (cache_write_hit)
                    begin
                        rw_reg <= `MEM_WRITE;
                        dirty[block_index][location] <= `TRUE;
                        read <= 0;
                        blocks[block_index][location][block_offset] <= write;
`ifdef DEBUG_MODE
                        $display("Data cache write addr %x hit, data %x", addr, write);
`endif
                    end
                    else if (cache_miss)
                    begin
                        mem_enable <= `TRUE;

                        block_offset_reg <= block_offset;
                        block_index_reg <= block_index;
                        tag_reg <= tag;
                        location_reg <= location;
`ifdef DEBUG_MODE
                        addr_reg <= addr;
`endif
                        rw_reg <= rw;
                        write_reg <= write;

                        // We are going to override one block.
                        // If this block to be overriden can be replaced safely,
                        // just populate it.
                        if (!valid[block_index][location] || !dirty[block_index][location])
                        begin
                            cnt <= 0;
                            state <= STATE_POPULATE;
                            mem_rw <= `MEM_READ;
                            mem_addr <= {tag, block_index, {BLOCK_OFFSET_WIDTH{1'b0}}};
                            
                            `ifdef DEBUG_MODE
                                $display("Data cache miss on addr %x", addr);
                            `endif
                        end
                        // Otherwise we should write back first.
                        else if (dirty[block_index][location])
                        begin
                            cnt <= 0;
                            state <= STATE_WRITEOUT;
                            mem_rw <= `MEM_WRITE;
                            mem_addr <= {tags[block_index][location], block_index, {BLOCK_OFFSET_WIDTH{1'b0}}};
                            
                            `ifdef DEBUG_MODE
                                $display("Data cache miss on addr %x", addr);
                            `endif
                        end
                    end
                end
                // Write dirty block back to memory
                STATE_WRITEOUT: begin
                    if (mem_write_req_input)
                    begin
                        mem_write <= blocks[block_index_reg][location_reg][cnt + 1];

                        cnt <= cnt + 1;
                    end
                    else
                    begin
                        if (mem_last)
                        begin
                            cnt <= 0;
                            // We have finished write dirty block back to memory,
                            // then we read the miss cache.
                            state <= STATE_POPULATE;
                            mem_enable <= `TRUE;
                            mem_rw <= `MEM_READ;
                            mem_addr <= {tag_reg, block_index_reg, {BLOCK_OFFSET_WIDTH{1'b0}}};
                            dirty[block_index_reg][location_reg] <= `FALSE;
                            mem_write <= 'bx;
                        end
                        else if (cnt == 0)
                            mem_write <= blocks[block_index_reg][location_reg][cnt];
                    end
                end

                // populate this block from memory
                STATE_POPULATE: begin
                    if (mem_read_valid)
                    begin
                        blocks[block_index_reg][location_reg][cnt] <= populate_data;

                        if (cnt == block_offset_reg && rw_reg == `MEM_READ)
                        begin
                            read <= populate_data;
`ifdef DEBUG_MODE
                            $display("Data cache populated addr %x, data %x", addr_reg, populate_data);
`endif
                        end

                        cnt <= cnt + 1;

                        if (mem_last)
                        begin
                            tags[block_index_reg][location_reg] <= tag_reg;
                            valid[block_index_reg][location_reg] <= `TRUE;
                            mem_enable <= `FALSE;

                            if (rw_reg == `MEM_WRITE)
                                dirty[block_index_reg][location_reg] <= `TRUE;
                            else
                                dirty[block_index_reg][location_reg] <= `FALSE;

                            state <= STATE_PAUSE;
                            block_offset_reg <= BLOCK_SIZE;
                        end
                    end
                end

                // wait for a clock period.
                STATE_PAUSE: begin
                    rw_valid <= `TRUE;
                    state <= STATE_READY;
                end
            endcase
        end
    end
    
endmodule
