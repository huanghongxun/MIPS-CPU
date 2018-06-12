`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/24 14:07:49
// Design Name: Hazard Detection Unit
// Module Name: hazard_detection_unit
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//   prediction: 0 - predict not taken
//               1 - branch likely
//               2 - branch delay slot
//               3 - branch prediction
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//   See https://en.wikipedia.org/wiki/Classic_RISC_pipeline
// 
// 
//////////////////////////////////////////////////////////////////////////////////


module hazard_detection_unit#(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5
    )(
    input clk,
    input rst_n,

    input flash_loader_done, // if the flashloader has completed operation
    input done, // if a done signal has been signaled.

    // ======= Previous Instruction Feedback ========
    // fetch
    input fetch_done,

    // decode
    input decode_rs,
    input decode_rt,
    input decode_branch,

    // execute
    input [REG_ADDR_WIDTH-1:0] exec_dst,
    input exec_mem_enable,
    input exec_reg_wb,
    input exec_branch,
    input [ADDR_WIDTH-1:0] exec_branch_target,

    // memory access
    input mem_done,

    // write back
    input wb_enable,

    
    // ======= Data Hazards ========
    // fetch
    output reg fetch_stall,
    output     fetch_flush,

    // decode
    output reg decode_stall,
    output reg decode_flush,

    // execute
    output reg exec_stall,
    output reg exec_flush,

    // memory access
    output reg mem_stall,
    output reg mem_flush,

    // write back
    output reg wb_stall,
    output reg wb_flush,

    // ======= Control Hazards ========
    output reg fetch_branch,
    output reg fetch_branch_target
    );

    reg fetch_load;
    reg [ADDR_WIDTH-1:0] fetch_addr;
    reg fetch_flush_data;
    reg fetch_flush_control;
    assign fetch_flush = fetch_flush_data || fetch_flush_control;

    wire executing = flash_loader_done && !done;

    // ===================
    // Data Hazards
    // ===================

    // fetch
    always @*
    begin
        fetch_stall <= 0;
        fetch_flush_data <= 0;

        if (executing)
        begin
            // If does not finish fetching next instruction or
            // next stage is stalling,
            // We stall this fetch stage.
            if (decode_stall || !fetch_done)
                fetch_stall <= 1;

            if (exec_branch || !fetch_done)
                fetch_flush_data <= 1;
        end
        else
        begin
            fetch_stall <= 1;
            fetch_flush_data <= 1;
        end
    end

    // decode
    always @*
    begin
        decode_stall <= 0;
        decode_flush <= 0;

        if (executing)
        begin   
            // If this instruction is a branch operation,
            // wait until the next instruction has been read from memory successfully.
            if (decode_branch && !fetch_done)
            begin
                decode_stall <= 1;
                decode_flush <= 1;
            end

            // If previous instruction is loading data from memory
            // we should insert a bubble to wait for data ready.
            // See Solution B: https://en.wikipedia.org/wiki/Classic_RISC_pipeline
            if (exec_reg_wb && exec_mem_enable && (
                (decode_rs == exec_dst && decode_rs != 0) ||
                (decode_rt == exec_dst && decode_rt != 0)))
            begin
                decode_stall <= 1;
                decode_flush <= 1;
            end

            // Stall if next stage is stalling
            if (exec_stall)
                decode_stall <= 1;
        end
        else
        begin
            decode_stall <= 1;
            decode_flush <= 1;
        end
    end

    // execution
    always @*
    begin
        exec_stall <= 0;
        exec_flush <= 0;

        if (executing)
        begin
            // Stall if next stage is stalling
            if (mem_stall)
                exec_stall <= 1;
        end
        else
        begin
            exec_stall <= 1;
            exec_flush <= 1;
        end
    end

    // memory access
    always @*
    begin
        mem_stall <= 0;
        mem_flush <= 0;

        if (executing)
        begin
            // wait for current operations on memory
            if (!mem_done)
            begin
                mem_stall <= 1;
                mem_flush <= 1;
            end

            // Stall if next stage is stalling
            if (wb_stall)
                mem_stall <= 1;
        end
        else
        begin
            mem_stall <= 1;
            mem_flush <= 1;
        end
    end

    // write back
    always @*
    begin
        wb_stall <= 0;
        wb_flush <= 0;

        if (executing)
        begin
            // nothing
        end
        else
        begin
            wb_stall <= 1;
            wb_flush <= 1;
        end
    end

    // ===============
    // Control Hazards
    // ===============

    always @*
    begin
        // predict not taken
        fetch_branch = exec_branch || fetch_load;
        if (exec_branch)
            fetch_branch_target = exec_branch_target;
        else
            fetch_branch_target = fetch_addr;
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            fetch_flush_control <= 0;
        end
        else
        begin
            // only execute the inst if the branch is not taken,
            // if the branch is taken, the instruction is flushed,
            // and one cycle's opportunity to finish an instruction is lost.
            if (exec_branch && !fetch_done)
                fetch_flush_control <= 1;
            else if (fetch_flush_control && fetch_done)
            // instruction from memory is ready, then we flush fetch
                fetch_flush_control <= 0;
        end
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            fetch_load <= 0;
            fetch_addr <= 'bx;
        end
        begin
            if (fetch_stall && exec_branch)
            begin
                fetch_load <= 1;
                fetch_addr <= exec_branch_target;
            end
            else if (fetch_load && !fetch_stall)
            begin
                fetch_load <= 0;
            end
        end
    end
endmodule
