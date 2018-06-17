`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Block Memory Controller
// Module Name: bram_controller
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//
//   physical address(width 16, 1 word per addr):
//   [group index | block index | block offset]
//         8             3             5
//
//   BRAM controller allows reading or writing a block of data per operation.
//   This can make instruction cache and data cache more easier to be implemented.
// 
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module bram_controller#(
	parameter DATA_WIDTH = 32,
	parameter ADDR_WIDTH = 16,

    parameter BLOCK_OFFSET_WIDTH = 5
)(
    input clk,
    input rst_n,
    
    input [ADDR_WIDTH-1:0] addr,
    input req_op, // 1 to start an operation, 0 to keep disabled
    input rw, // 1 to write, 0 to read
    
    input [DATA_WIDTH-1:0] data_write,
    output data_write_req_input,

    output [DATA_WIDTH-1:0] data_read,
    output reg data_read_valid,

    output finished,

    // BRAM interface
    output reg ena = 0,
    output reg wea = 0,
    output reg [ADDR_WIDTH-1:0] addra,
    output reg [DATA_WIDTH-1:0] dina,
    input reg [DATA_WIDTH-1:0] douta
    );

    // constants
    localparam BLOCK_SIZE = 1<<BLOCK_OFFSET_WIDTH;

    localparam STATE_READY = 0;
    localparam STATE_READ0 = 1;
    localparam STATE_READ1 = 2;
    localparam STATE_WRITE0 = 3;
    localparam STATE_WRITE1 = 4;
    localparam STATE_WAIT = 5;

    // variables
    reg [2:0] state, next_state;
    reg [BLOCK_OFFSET_WIDTH-1:0] cnt;
    reg [5:0] delay_cnt;

    task wait_for;
        input [2:0] _next_state;
        input [5:0] delay;

        begin
            state <= STATE_WAIT;
            next_state <= _next_state;
            delay_cnt <= delay - 1;
        end
    endtask

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            ena <= 0;
            addra <= 0;

            data_read <= 0;
            data_write_req_input <= 0;
            data_valid <= 0;
            finished <= 0;
            
            delay_cnt <= 0;

            state <= STATE_READY;
        end
        else
        begin
            case (state)
                STATE_READY: begin
                    data_valid <= 0;
                    ena <= 0;
                    if (req_op)
                    begin
                        if (rw == `MEM_WRITE)
                            state <= STATE_WRITE0;
                        else if (rw == `MEM_READ)
                            state <= STATE_READ0;
                    end
                end
                STATE_READ0: begin // prepare for reading data from memory
                    cnt <= 0;
                    ena <= 1;
                    wea <= `MEM_READ;
                    addra <= addr;
                    state <= STATE_READ1;
                end
                STATE_READ1: begin
                    data_valid <= 1;
                    data_read <= douta;
                    addra <= addra + 1;
                    cnt <= cnt + 1;
                    if (cnt == BLOCK_SIZE - 1)
                    begin
                        // we have finished sending a block of data
                        finished <= 1;
                        // reserve one clock period to let cache respond the change of "finished"
                        wait_for(STATE_READY, 1);
                    end
                    else
                        // continue reading and sending data
                        finished <= 0;
                end
                STATE_WRITE0: begin // prepare for writing data to memory
                    cnt <= 0;
                    ena <= 1;
                    wea <= `MEM_WRITE;
                    addra <= addr;
                    // We write data in advance since
                    // writing memory is operated next clock period
                    dina <= data_write;
                    data_write_req_input <= 1; // we are requesting data to write
                    state <= STATE_WRITE1;
                end
                STATE_WRITE1: begin
                    dina <= data_write;
                    addra <= addra + 1;
                    cnt <= cnt + 1;
                    if (cnt == BLOCK_SIZE - 1)
                    begin
                        // we have finished writing a block of data
                        finished <= 1;
                        data_write_req_input <= 0;

                        // wait for last word of data writing
                        wait_for(STATE_READY, 1);
                    end
                    else
                        finished <= 0;
                end
                STATE_WAIT: begin
                    finished <= 0;
                    delay_cnt <= delay_cnt - 1;
                    if (delay_cnt == 0)
                        state <= next_state;
                end
            endcase
        end
    end
endmodule