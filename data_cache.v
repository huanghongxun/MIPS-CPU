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
    parameter ADDR_WIDTH = 18, // main memory address width(per byte)

    parameter ASSO_WIDTH = 1, // for n-way associative caching
    parameter BLOCK_OFFSET_WIDTH = 5, // width of address of a block
    parameter INDEX_WIDTH = 3,
    parameter TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - BLOCK_OFFSET_WIDTH // Upper 13 bits of the physical address (the tag) are compared to the 13 bit tag field at that cache entry.
)(
    input clk,
    input rst_n,

    // request
    input [`ADDR_BUS] addr,
    input enable, // 1 if we are requesting data
    input rw,
    input [1:0] mem_width,
    input sign_extend,

    input [`DATA_BUS] write,
    output reg [`DATA_BUS] read,
    output reg rw_valid = 0,

    output ready,

    // BRAM transaction
    output reg [`ADDR_BUS] mem_addr,
    output reg mem_enable,
    output reg mem_rw,

    input [`DATA_BUS] mem_read,
    input mem_read_valid,

    output reg [`DATA_BUS] mem_write,
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
    wire [ADDR_WIDTH        -3:0] addr_word = addr[ADDR_WIDTH-1:2];
    wire [TAG_WIDTH         -1:0] tag  = addr_word[ADDR_WIDTH-3:INDEX_WIDTH+BLOCK_OFFSET_WIDTH];
    wire [INDEX_WIDTH       -1:0] block_index  = addr_word[INDEX_WIDTH+BLOCK_OFFSET_WIDTH-1:BLOCK_OFFSET_WIDTH];
    wire [BLOCK_OFFSET_WIDTH-1:0] block_offset = addr_word[BLOCK_OFFSET_WIDTH-1:0];
    wire [                   1:0] word_offset = addr[1:0];
    reg  [ASSO_WIDTH        -1:0] location;
    
    // registers to save operands of synchronization
    reg                           rw_reg;
    reg  [ADDR_WIDTH        -1:0] addr_reg;
    reg  [TAG_WIDTH         -1:0] tag_reg;
    reg  [INDEX_WIDTH       -1:0] block_index_reg;
    reg  [BLOCK_OFFSET_WIDTH-1:0] block_offset_reg;
    reg  [ASSO_WIDTH        -1:0] location_reg;
    reg  [DATA_WIDTH        -1:0] write_reg;
    reg  [                   1:0] word_offset_reg;
    reg  [                   1:0] mem_width_reg;
    reg                           sign_extend_reg;

    reg [BLOCK_OFFSET_WIDTH-1:0] cnt; // block offset that we are pulling from memory. We always pull a full block from memory per miss.

    // cache storage
    reg [TAG_WIDTH-1:0] tags[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1]; // which group in memory
    reg [`DATA_BUS] blocks[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1][0:BLOCK_SIZE-1]; // cached blocks
    reg valid[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1]; // true if this cache space has stored a block.
    reg dirty[0:INDEX_SIZE-1][0:ASSOCIATIVITY-1]; // is cached block dirty.
    
    assign ready = state == STATE_READY;

    wire cache_hit = enable && valid[block_index][location] && tags[block_index][location] === tag && !rw_valid;
    wire cache_read_hit = cache_hit && rw == `MEM_READ && state == STATE_READY;
    wire cache_write_hit = cache_hit && rw == `MEM_WRITE && state == STATE_READY;
    wire cache_miss = !cache_hit && enable && !rw_valid;

    wire populate = rw_reg == `MEM_WRITE && mem_read_valid && cnt == block_offset_reg && state == STATE_POPULATE;
    wire [`DATA_BUS] populate_data = populate ? write_reg : mem_read;
        
    localparam LOCATION_X = {ASSO_WIDTH{1'bx}};
    localparam TAG_X = {TAG_WIDTH{1'bx}};

    // determine which block is bound to the memory requested.
    always @*
    begin
        location = LOCATION_X;
        for (i = 0; i < ASSOCIATIVITY; i = i + 1)
            if (tags[block_index][i] == tag)
                location = i;
        if (location === LOCATION_X)
            for (i = 0; i < ASSOCIATIVITY; i = i + 1)
                if (tags[block_index][i] === TAG_X)
                    location = i;
        if (location === LOCATION_X)
            location = 0;
    end
    
    task write_task;
        input [`ADDR_BUS] addr;
        input [INDEX_WIDTH       -1:0] block_index;
        input [BLOCK_OFFSET_WIDTH-1:0] block_offset;
        input [                   1:0] word_offset;
        input [ASSO_WIDTH        -1:0] location;
        input                    [1:0] mem_width;
    
        input [DATA_WIDTH        -1:0] write;
    
        begin
            case (mem_width)
                `MEM_BYTE: begin
                    case (word_offset)
                        0: blocks[block_index][location][block_offset][31:24] <= write[7:0];
                        1: blocks[block_index][location][block_offset][23:16] <= write[7:0];
                        2: blocks[block_index][location][block_offset][15: 8] <= write[7:0];
                        3: blocks[block_index][location][block_offset][ 7: 0] <= write[7:0];
                    endcase
`ifdef DEBUG_DATA
                    $display("Data cache write byte %h on addr %h", write[7:0], addr);
`endif
                end
                `MEM_HALF: begin
                    case (word_offset)
                        0: blocks[block_index][location][block_offset][31:16] <= write[15:0];
                        2: blocks[block_index][location][block_offset][15: 0] <= write[15:0];
                    endcase
`ifdef DEBUG_DATA
                    $display("Data cache write half %h on addr %h", write[15:0], addr);
`endif
                end
                `MEM_WORD: begin
                    blocks[block_index][location][block_offset] <= write;
`ifdef DEBUG_DATA
                    $display("Data cache write word %h on addr %h", write, addr);
`endif
                end
            endcase
        end
    endtask
    
    task read_task;
        input [`ADDR_BUS] addr;
        input [`DATA_BUS] data;
        input [           1:0] word_offset;
        input [           1:0] mem_width;
        input                  sign_extend;
        
        reg [7:0] byte;
        reg [15:0] half;
        reg [31:0] word;
        
        begin
            case (mem_width)
                `MEM_BYTE: begin
                    case (word_offset)
                        0: byte = data[31:24];
                        1: byte = data[23:16];
                        2: byte = data[15: 8];
                        3: byte = data[ 7: 0];
                        default: half = {DATA_WIDTH{1'bx}};
                    endcase
                    if (sign_extend == `SIGN_EXT)
                        read = $signed(byte);
                    else
                        read = $unsigned(byte);
`ifdef DEBUG_DATA
                    $display("Data cache read byte %h on addr %h, res %h", byte, addr, read);
`endif
                end
                `MEM_HALF: begin
                    case (word_offset)
                        0: half = data[31:16];
                        2: half = data[15: 0];
                        default: half = {DATA_WIDTH{1'bx}};
                    endcase
                    if (sign_extend == `SIGN_EXT)
                        read = $signed(half);
                    else
                        read = $unsigned(half);
`ifdef DEBUG_DATA
                    $display("Data cache read half %h on addr %h, res %h", half, addr, read);
`endif
                end
                `MEM_WORD: begin
                    read = data;
`ifdef DEBUG_DATA
                    $display("Data cache read word %h on addr %h, res %h", data, addr, read);
`endif
                end
                default: read = {DATA_WIDTH{1'bx}};
            endcase
        end
    endtask

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= STATE_READY;
            mem_enable <= `FALSE;
            
            rw_valid <= `FALSE;
            
            block_offset_reg <= 0;
            block_index_reg <= 0;
            word_offset_reg <= 0;
            tag_reg <= 0;
            mem_width_reg <= 0;
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
                    tags[i][j] <= TAG_X;
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
                        read_task(addr, blocks[block_index][location][block_offset], word_offset, mem_width, sign_extend);
                    end
                    else if (cache_write_hit)
                    begin
                        rw_reg <= `MEM_WRITE;
                        rw_valid <= `TRUE;
                        dirty[block_index][location] <= `TRUE;
                        read <= 0;
                        write_task(addr, block_index, block_offset, word_offset, location, mem_width, write);
                    end
                    else if (cache_miss)
                    begin
                        mem_enable <= `TRUE;

                        block_offset_reg <= block_offset;
                        block_index_reg <= block_index;
                        mem_width_reg <= mem_width;
                        tag_reg <= tag;
                        location_reg <= location;
                        word_offset_reg <= word_offset;
                        sign_extend_reg <= sign_extend;
                        addr_reg <= addr;
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
                            
`ifdef DEBUG_DATA
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
                            
 `ifdef DEBUG_DATA
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
                            read_task(addr_reg, populate_data, word_offset_reg, mem_width_reg, sign_extend_reg);
`ifdef DEBUG_DATA
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
                            begin
                                dirty[block_index_reg][location_reg] <= `TRUE;
                                write_task(addr_reg, block_index_reg, block_offset_reg, word_offset_reg, location_reg, mem_width_reg, write_reg);
                            end
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
