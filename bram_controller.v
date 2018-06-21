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
    input enable, // 1 to start an operation, 0 to keep disabled
    input rw, // 1 to write, 0 to read
    
    input op_size, // 0 if operate on a block, 1 if terminates operation when finishes_op = 1
    input finishes_op, // 1 if operation terminates.
    
    input [DATA_WIDTH-1:0] data_write,
    output reg data_write_req_input,

    output reg [DATA_WIDTH-1:0] data_read,
    output reg data_read_valid,

    output reg finished,

    // BRAM interface
    output reg ena = 0,
    output reg wea = 0,
    output reg [ADDR_WIDTH-1:0] addra,
    output reg [DATA_WIDTH-1:0] dina,
    input [DATA_WIDTH-1:0] douta
    );

    // constants
    localparam BLOCK_SIZE = 1<<BLOCK_OFFSET_WIDTH;

    localparam STATE_READY = 0;
    localparam STATE_READ = 2;
    localparam STATE_READ_FINISH = 7;
    localparam STATE_WRITE = 9;
    localparam STATE_WAIT = 15;
    
    localparam OP_SIZE_BLOCK = 0;
    localparam OP_SIZE_USER = 1;

    // variables
    reg [3:0] state, next_state;
    reg [BLOCK_OFFSET_WIDTH-1:0] cnt;
    reg [5:0] delay_cnt;
    reg increasing_addr_delay;

    task wait_for;
        input [2:0] _next_state;
        input [5:0] delay;
        input increasing_addr;

        begin
            state <= STATE_WAIT;
            next_state <= _next_state;
            delay_cnt <= delay - 1;
            increasing_addr_delay <= increasing_addr;
        end
    endtask

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            ena <= 0;
            addra <= 0;
            wea <= 0;
            dina <= 0;

            data_read <= 0;
            data_write_req_input <= 0;
            data_read_valid <= 0;
            finished <= 0;
            cnt <= 0;
            
            delay_cnt <= 0;
            increasing_addr_delay <= 0;
            next_state <= STATE_READY;

            state <= STATE_READY;
        end
        else
        begin
            case (state)
                STATE_READY: begin
                    data_read_valid <= 0;
                    ena <= 0;
                    if (enable)
                    begin
                        if (rw == `MEM_WRITE)
                        begin
                            cnt <= 0;
                            ena <= 1;
                            wea <= `MEM_WRITE;
                            addra <= addr;
                            // We write data in advance since
                            // writing memory is operated next clock period
                            dina <= data_write;
                            data_write_req_input <= 1; // we are requesting data to write
                            state <= STATE_WRITE;
`ifdef DEBUG_BRAM
                            $display("bram: write");
`endif
                        end
                        else if (rw == `MEM_READ)
                        begin
                            cnt <= 0;
                            ena <= 1;
                            wea <= `MEM_READ;
                            addra <= addr;
                            
                            // bram generator requires 3 clock period to extract data.
                            wait_for(STATE_READ, 3, `TRUE);
`ifdef DEBUG_BRAM
                            $display("bram: read");
`endif
                        end
                    end
                end
                STATE_READ: begin
                    data_read_valid <= 1;
                    data_read <= douta;
                    addra <= addra + 1;
                    cnt <= cnt + 1;
                    if (op_size == OP_SIZE_USER && finishes_op)
                    begin
                        // user requires termination of operation.
                        // we have finished sending a block of data
                        finished <= 1;
                        // reserve one clock period to let cache respond the change of "finished"
                        wait_for(STATE_READY, 1, `FALSE);
                    end
                    else if (cnt == BLOCK_SIZE - 1)
                    begin
                        wait_for(STATE_READ_FINISH, 1, `FALSE);
                    end
                    else
                        // continue reading and sending data
                        finished <= 0;
                end
                STATE_READ_FINISH: begin
                    data_read_valid <= 1;
                    data_read <= douta;
                    finished <= 1;
                    wait_for(STATE_READY, 1, `FALSE);
                end
                STATE_WRITE: begin
                    dina <= data_write;
                    addra <= addra + 1;
                    cnt <= cnt + 1;
                    if (cnt == BLOCK_SIZE - 1 || op_size == OP_SIZE_USER && finishes_op)
                    begin
                        // we have finished writing a block of data
                        finished <= 1;
                        data_write_req_input <= 0;

                        // wait for last word of data writing
                        wait_for(STATE_READY, 1, `FALSE);
                    end
                    else
                        finished <= 0;
                end
                STATE_WAIT: begin
                    finished <= 0;
                    delay_cnt <= delay_cnt - 1;
                    data_read <= douta;
                    if (increasing_addr_delay)
                    begin
                        addra <= addra + 1;
                        cnt <= cnt + 1;
                    end
                    if (delay_cnt == 0)
                        state <= next_state;
                end
            endcase
        end
    end
endmodule