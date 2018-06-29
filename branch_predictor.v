`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/06/26 00:58:05
// Design Name: Branch Prediction
// Module Name: branch_predictor
// Project Name: 
// Target Devices: 
// Tool Versions: 
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

module branch_predictor#(
    parameter HISTORY_WIDTH = 10,
    parameter COUNTER_WIDTH = 4,
    parameter PREDICTION = `PREDICT_LOCAL
)(
    input clk,
    input rst_n,
    
    input dec_branch,
    input exec_branch,
    input exec_take_branch
    );
    
    localparam BIMODAL_WIDTH = PREDICTION == `PREDICT_LOCAL ? COUNTER_WIDTH : HISTORY_WIDTH;
    localparam BIMODAL_SIZE = 1 << BIMODAL_WIDTH;
    localparam HISTORY_SIZE = 1 << HISTORY_WIDTH;
    
    integer i;
    
    
    // one-level branch prediction/saturating counter
    // 0 - strongly not taken
    // 1 - weakly not taken
    // 2 - weakly taken
    // 3 - strongly taken
    reg [1:0] saturating_counter[0:BIMODAL_SIZE-1]; 
    
    // two-level adaptive predictor with local history tables
    reg [COUNTER_WIDTH-1:0] history_table[0:HISTORY_SIZE-1];
    
    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            for (i = 0; i < BIMODAL_SIZE; i = i + 1)
                saturating_counter[i] <= 2;
            for (i = 0; i < HISTORY_SIZE; i = i + 1)
                history_table[i] <= 0;
        end
        else
        begin
            if (dec_branch) // fetched a branch instruction
            begin
                
            end
            
            if (exec_branch)
            begin
            end
        end
    end
endmodule
