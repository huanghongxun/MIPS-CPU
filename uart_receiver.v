`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 07/04/2015 12:03:40 PM
// Design Name: UART Communication - Receiver
// Module Name: uart_receiver
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


module uart_receiver#(
    parameter CLK_FREQ = 100_000_000
)(
    input clk, // 100MHz System clock
    input rst_n, //input reset 
    input RxD, // input receving data line
    output [7:0] data // output for 8 bits data
    );

    // constants
    localparam STATE_READY = 0;
    localparam STATE_RECEIVING = 0;

    localparam DATA_WIDTH = 8;
    localparam TRAN_WIDTH = DATA_WIDTH + 2; // 1 start, 8 data, 1 stop

    localparam BAUD_RATE = 9600; // baud rate
    localparam div_sample = 4; // oversampling
    localparam CNT_DIV = CLK_FREQ / (BAUD_RATE * div_sample);  // this is the number we have to divide the system clock frequency to get a frequency (div_sample) time higher than (baud_rate)
    localparam mid_sample = (div_sample/2);  // this is the middle point of a bit where you want to sample it

    
    // internal variables
    reg shift; // shift signal to trigger shifting data
    reg state, next_state; // initial state and next state variable
    reg [3:0] bit; // 4 bits counter to count up to 9 for UART receiving
    reg [1:0] samplecounter; // 2 bits sample counter to count up to 4 for oversampling
    reg [13:0] counter; // 14 bits counter to count the baud rate
    reg [TRAN_WIDTH-1:0] rxshiftreg; // bit shifting register
    reg clear_bit, inc_bit, inc_sampleclear_sample; //clear or increment the counter

    assign RxData = rxshiftreg[8:1]; // assign the RxData from the shiftregister

    // UART receiver logic
    always @(posedge clk_100MHz, negedge rst_n)
    begin 
        if (!rst_n)
        begin
            state <= STATE_READY;
            bit <= 0;
            counter <= 0;
            sample <= 0;
        end
        else
        begin
            counter <= counter + 1;
            if (counter >= CNT_DIV - 1)
            begin
                counter <= 0;
                state <= next_state;
                if (shift)
                    rxshiftreg <= {RxD, rxshiftreg[9:1]};
                if (clear_sample)
                    sample <= 0;
                if (inc_sample)
                    sample <= sample + 1;
                if (clear_bit)
                    bit <= 0;
                if (inc_bit)
                    bit <= bit + 1;
            end
        end
    end
    
    // Mealy state machine
    always @(posedge clk)
    begin 
        shift <= 0;
        clear_sample <= 0;
        inc_sample <= 0;
        clear_bit <= 0;
        inc_bit <= 0;
        next_state <= STATE_READY;
        case (state)
            STATE_READY: begin
                if (RxD)
                begin
                    // RxD needs to be low to start transmission
                    next_state <= STATE_READY;
                end
                else
                begin
                    next_state <= STATE_RECEIVING;
                    clear_bit <= 1;
                    clear_sample <= 1;
                end
            end
            STATE_RECEIVING: begin
                next_state <= STATE_RECEIVING;
                if (sample == mid_sample - 1)
                    shift <= 1; // if sample counter is 1, trigger shift 
                if (sample == div_sample - 1)
                begin // if sample counter is 3 as the sample rate used is 3
                    // Since bit have reached div_bit, we have completed receiving this byte.
                    if (bit == div_bit - 1)
                    begin
                        next_state <= STATE_READY;
                    end 
                    inc_bit <= 1; // trigger the increment bit counter if bit counter is not 9
                    clear_sample <= 1; //trigger the sample counter to reset the sample counter
                end
                else
                    inc_sample <= 1; // if sample is not equal to 3, keep counting
            end
        endcase
    end         
endmodule
