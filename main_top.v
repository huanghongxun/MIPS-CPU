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
    localparam ADDR_WIDTH = 16;
    localparam REG_ADDR_WIDTH = 5;
    localparam ALU_OP_WIDTH = 5;
    localparam FREE_LIST_WIDTH = 3;

    wire rst_n = sw[15];
    
    wire bram_ena;
    wire bram_wea;
    wire [`ADDR_BUS] bram_addra;
    wire [`DATA_BUS] bram_dina;
    wire [`DATA_BUS] bram_douta;
    
    wire [7:0] receive_data;
    wire receive_last;
    wire [7:0] transmit_data;
    wire transmit;
    
    /*bram_basys3 bram(.clka(clk),
                              .ena(bram_ena),
                              .wea(bram_wea),
                              .addra(bram_addra),
                              .dina(bram_dina),
                              .douta(bram_douta));
    */
    mips_cpu #(.DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH),
               .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
               .ALU_OP_WIDTH(ALU_OP_WIDTH),
               .FREE_LIST_WIDTH(FREE_LIST_WIDTH))
        uut(.clk(clk),
            .rst_n(rst_n),
            
            .bram_ena(bram_ena),
            .bram_wea(bram_wea),
            .bram_addra(bram_addra),
            .bram_dina(bram_dina),
            .bram_douta(bram_douta),
            
            
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
            .external_done());
            
    uart_receiver receiver(.clk(clk), .rst_n(rst_n), .RxD(RxD), .data(receive_data), .data_last(receive_last));
    uart_transmitter transmitter(.clk(clk), .rst_n(rst_n), .transmit(transmit), .data(transmit_data), .TxD(TxD));
    
endmodule
