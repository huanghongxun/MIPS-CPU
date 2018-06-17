`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 07/04/2018 11:29:02 AM
// Design Name: UART transmitter
// Module Name: transmitter
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

module uart_transmitter#(
    parameter CLK_FREQ = 100000000
)(
    input clk, // 100MHz System clock
    input rst_n, // reset signal

    input transmit, // btn signal to trigger the UART communication
    input [7:0] data, // data transmitted
    output reg TxD // Transmitter serial output. TxD will be held high during reset, or when no transmissions aretaking place. 
    );

    // constants
    localparam STATE_READY = 0; // keep waiting until transmit signal was triggered.
    localparam STATE_TRANSMIT = 1; // transmitting data, load = 1, shift = clear = 0

    localparam DATA_WIDTH = 8;
    localparam TRAN_WIDTH = DATA_WIDTH + 2;

    localparam BAUD_RATE = 9600;
    localparam CNT_DIV = CLK_FREQ / BAUD_RATE;

    // variables
    reg [3:0] bit; // 4 bits counter to count up to TRAN_WIDTH
    reg [13:0] counter; // 14 bits counter to count the baud rate = 9600, counter = clock / baud rate = 10416
    reg state, next_state; // initial & next state variable
    // 10 bits needed to be shifted out during transmission.
    // The least significant bit is initialized with the binary value 0 (a start bit) A binary value �1� is introduced in the most significant bit 
    reg [TRAN_WIDTH-1:0] data;
    reg shift; // shift signal to start bit shifting in UART
    reg load; // load signal to start loading the data into rightshift register and add start and stop bit
    reg clear; // clear signal to start reset the bit for UART transmission

    // UART transmission logic
    always @(posedge clk, negedge rst_n) 
    begin 
        if (!rst_n)
        begin
            state <= STATE_READY;
            counter <= 0;
            bit <= 0;
        end
        else
        begin
            counter <= counter + 1;
            if (counter >= CNT_DIV)
            begin
                state <= next_state;
                counter <= 0;
                if (load)
                    data <= {1'b1, data, 1'b0}; // load the data to be transmitted if load is asserted, add start 0 and stop 1 bits.
                if (clear)
                    bit <= 0;
                if (shift) 
                    bit <= bit + 1;
            end
        end
    end 

    // Mealy state machine
    always @(posedge clk) //trigger by positive edge of clock, 
    begin
        load <= 0;
        shift <= 0;
        clear <= 0;
        TxD <= 1;
        case (state)
            STATE_READY: begin
                if (transmit)
                begin
                    next_state <= STATE_TRANSMIT; // Move to transmit state
                    load <= 1; // set load to 1 to prepare to load the data
                    shift <= 0; // set shift to 0 so no shift ready yet
                    clear <= 0; // set clear to 0 to avoid clear any counter
                end 
                else
                begin
                    next_state <= 0; // next state is back to idle state
                    TxD <= 1; 
                end
            end
            STATE_TRANSMIT: begin
                // if we have completed current transmission
                if (bit >= TRAN_WIDTH)
                begin
                    next_state <= STATE_READY; // set next_state back to 0 to idle state
                    clear <= 1; // clear all counters
                end 
                else
                begin
                    next_state <= STATE_TRANSMIT; // keep transmit state
                    TxD <= data[bit]; // output TxD
                    shift <= 1; // continue shifting the data
                end
            end
            default:
                next_state <= STATE_READY;                      
        endcase
    end

endmodule