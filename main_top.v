`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: MIPS CPU top module
// Module Name: main_top
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

`include "defines.v"

module main_top(
    input clk, // 100MHz clock signal

    input [15:0] sw, // switches
    input [15:0] LED, // LEDs

    // buttons
    input btn0,
    input btn1,
    input btnL,
    input btnR,
    input btnD,

    // USB-RS232 UART interface
    input RxD,
    output TxD
    );
    
    localparam DATA_WIDTH = 32;
    localparam BRAM_ADDR_WIDTH = 16;
    localparam DATA_PER_BYTE_WIDTH = 2;
    localparam FREE_LIST_WIDTH = 3;
    localparam BLOCK_OFFSET_WIDTH = 5;

    wire rst_n = sw[15];
    
    wire bram_ena;
    wire bram_wea;
    wire [`BRAM_ADDR_BUS] bram_addra;
    wire [`DATA_BUS] bram_dina;
    wire [`DATA_BUS] bram_douta;

    wire [`DATA_BUS] ram_addr;
    wire ram_enable;
    wire ram_rw;
    wire ram_op_size;
    wire ram_finishes_op;
    wire [`DATA_BUS] ram_write;
    wire ram_write_req_input;
    wire [`DATA_BUS] ram_read;
    wire ram_read_valid;
    wire ram_last;
    
    wire [7:0] receive_data;
    wire receive_last;
    wire [7:0] transmit_data;
    wire transmit;
    
    /*bram_basys3 bram(
        .clka(clk),
        .ena(bram_ena),
        .wea(bram_wea),
        .addra(bram_addra),
        .dina(bram_dina),
        .douta(bram_douta)
    );*/

    bram_controller #(.DATA_WIDTH(DATA_WIDTH),
                      .BRAM_ADDR_WIDTH(BRAM_ADDR_WIDTH),
                      .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH))
                    ram(
        .clk(clk),
        .rst_n(rst_n),

        .addr(ram_addr),
        .enable(ram_enable),
        .rw(ram_rw),
        
        .op_size(ram_op_size),
        .finishes_op(ram_finishes_op),

        .data_write(ram_write),
        .data_write_req_input(ram_write_req_input),

        .data_read(ram_read),
        .data_read_valid(ram_read_valid),

        .finished(ram_last),

        // BRAM interface
        .ena(bram_ena),
        .wea(bram_wea),
        .addra(bram_addra),
        .dina(bram_dina),
        .douta(bram_douta)
    );

    mips_cpu #(.DATA_WIDTH(DATA_WIDTH),
               .DATA_PER_BYTE_WIDTH(DATA_PER_BYTE_WIDTH),
               .FREE_LIST_WIDTH(FREE_LIST_WIDTH),
               
               .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH))
        uut(.clk(clk),
            .rst_n(rst_n),
            
            // Interface with external device
            .external_addr(),
            .external_enable(),
            .external_rw(),
            .external_op_size(),
            .external_finishes_op(),
            .external_write(),
            .external_req_data(),
            .external_read(), // output data that external devices read
            .external_read_valid(), // true if external devices could read data.
            .external_last(),
            .external_done(),

            // Interface with RAM controller
            .ram_addr(ram_addr),
            .ram_enable(ram_enable),
            .ram_rw(ram_rw),
            
            .ram_op_size(ram_op_size),
            .ram_finishes_op(ram_finishes_op),

            .ram_write(ram_write),
            .ram_write_req_input(ram_write_req_input),

            .ram_read(ram_read),
            .ram_read_valid(ram_read_valid),

            .ram_last(ram_last));
            
    uart_receiver receiver(.clk(clk), .rst_n(rst_n), .RxD(RxD), .data(receive_data), .data_last(receive_last));
    uart_transmitter transmitter(.clk(clk), .rst_n(rst_n), .transmit(transmit), .data(transmit_data), .TxD(TxD));
    
endmodule
