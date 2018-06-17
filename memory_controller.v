`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Memory Controller
// Module Name: memory_controller
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//   manage memory with data cache, instruction cache and flash memory.
//
//   physical address:
//   [group index | block index | block offset]
//         8             3             9
//
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module memory_controller#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16 // main memory address width
)(
    input clk,
    input rst_n,

    // inst cache
    input [ADDR_WIDTH-1:0] imem_addr,
    input imem_req_op,

    output reg [DATA_WIDTH-1:0] imem_read,
    output reg imem_read_valid,

    output reg imem_last,

    // data cache
    input [ADDR_WIDTH-1:0] dmem_addr,
    input dmem_req_op,
    input dmem_rw,

    input [DATA_WIDTH-1:0] dmem_write,
    output reg dmem_req_data, // Request data-cache to transmit data.

    output reg [DATA_WIDTH-1:0] dmem_read,
    output reg dmem_read_valid,

    output reg dmem_last,

    // flash
    input [ADDR_WIDTH-1:0] flash_addr,
    input flash_req_op,

    input [DATA_WIDTH-1:0] flash_write,
    output reg flash_req_data, // Request flash to transmit data

    output reg flash_last,

    // ram
    output reg [ADDR_WIDTH-1:0] mem_addr,
    output reg mem_req_op,
    output reg mem_rw,

    output reg [DATA_WIDTH-1:0] mem_write,
    input mem_write_req_input,

    input [DATA_WIDTH-1:0] mem_read,
    input mem_read_valid,

    input mem_last
    );

    localparam MEM_READ = 0;
    localparam MEM_WRITE = 1;

    localparam STATE_READY = 0;
    localparam STATE_INST_MEM = 1;
    localparam STATE_DATA_MEM = 2;
    localparam STATE_MEM = 3;
    localparam STATE_FLASH = 4;
    localparam STATE_VGA = 5;

    // Now which component is requesting an operation on memory.
    reg [2:0] state;

    always @*
    begin
        imem_read_valid <= 0;
        imem_last <= 0;
        imem_read <= 'bx;
        dmem_read_valid <= 0;
        dmem_req_data <= 0;
        dmem_last <= 0;
        dmem_read <= 'bx;
        flash_req_data <= 0;
        flash_last <= 0;
        mem_req_op <= 0;
        mem_addr <= 'bx;
        mem_rw <= MEM_READ;
        mem_write <= 'bx;

        case (state)
            STATE_READY: begin // no component requests occupying memory
            end
            STATE_INST_MEM: begin // inst-cache requested a read operation operation
                mem_req_op <= 1;
                mem_addr <= imem_addr;
                // instruction cache only reads data from memory
                mem_rw <= MEM_READ;

                imem_read_valid <= mem_read_valid;
                imem_last <= mem_last;
                imem_read <= mem_read;
            end
            STATE_DATA_MEM: begin // data-cache requested an operation on memory
                mem_req_op <= 1;
                mem_addr <= dmem_addr;
                mem_rw <= dmem_rw;
                mem_write <= dmem_write;

                dmem_read_valid <= mem_read_valid;
                dmem_req_data <= mem_write_req_input;
                dmem_last <= mem_last;
                dmem_read <= mem_read;
            end
            STATE_FLASH: begin // flash requested a write operation on memory
                mem_req_op <= 1;
                mem_addr <= flash_addr;
                // flash memory only writes data from memory here.
                mem_rw <= MEM_WRITE;
                mem_write <= flash_write;

                flash_req_data <= mem_write_req_input;
                flash_last <= mem_last;
            end
        endcase
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= STATE_READY;
        end
        else
        begin
            case (state)
                STATE_READY: begin
                    if (flash_req_op)
                        state <= STATE_FLASH;
                    else if (imem_req_op)
                        state <= STATE_INST_MEM;
                    else if (dmem_req_op)
                        state <= STATE_DATA_MEM;
                end
                STATE_FLASH: begin
                    if (mem_last)
                        state <= STATE_READY;
                end
                STATE_INST_MEM: begin
                    if (mem_last)
                        state <= STATE_READY;
                end
                STATE_DATA_MEM: begin
                    if (mem_last)
                        state <= STATE_READY;
                end
            endcase
        end
    end
    
endmodule
