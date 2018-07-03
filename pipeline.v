`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/24 14:07:49
// Design Name: Pipeline Controller
// Module Name: pipeline
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
//   See https://en.wikipedia.org/wiki/Classic_RISC_pipeline
//   https://www.cs.cmu.edu/afs/cs/academic/class/15740-f97/public/info/pipeline-slide.pdf
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module pipeline#(parameter DATA_WIDTH = 32)(
    input clk,
    input rst_n,

    input external_done, // if the external storage has completed operation
    input done, // if a done signal has been signaled.
    
    input regfile_stall,

    // ======= Previous Instruction Feedback ========
    // fetch
    input fetch_done,

    // decode
    input dec_rs_enable,
    input [`PREG_BUS] dec_rs_addr,
    input dec_rt_enable,
    input [`PREG_BUS] dec_rt_addr,
    input decode_branch,

    // execute
    input [`PREG_BUS] exec_physical_write_addr,
    input exec_mem_enable,
    input exec_wb_reg,
    input exec_take_branch,
    input [`DATA_BUS] exec_branch_target,

    // memory access
    input mem_done,

    
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

    output reg global_flush,

    // ======= Control Hazards ========
    output reg fetch_branch,
    output reg [`DATA_BUS] fetch_branch_target,

    // ======= Exception Handler ========
    
    input [`DATA_BUS] exception,
    input [`DATA_BUS] mem_cp0_epc
    );

    reg fetch_load;
    reg [`DATA_BUS] fetch_addr;
    reg fetch_flush_data;
    reg fetch_flush_control;
    assign fetch_flush = fetch_flush_data || fetch_flush_control;

    wire executing = external_done && !done;

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

            if (exec_take_branch || !fetch_done)
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
            
            if (exec_take_branch)
                decode_flush <= 1;

            // If previous instruction is loading data from memory
            // we should insert a bubble to wait for data ready.
            // See Solution B: https://en.wikipedia.org/wiki/Classic_RISC_pipeline
            if (exec_wb_reg && exec_mem_enable && (
                (dec_rs_addr == exec_physical_write_addr && dec_rs_enable) ||
                (dec_rt_addr == exec_physical_write_addr && dec_rt_enable)))
            begin
                decode_stall <= 1;
                decode_flush <= 1;
            end

            // Stall if next stage is stalling
            if (exec_stall || regfile_stall)
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
        fetch_branch <= exec_take_branch || fetch_load;
        if (exec_take_branch)
            fetch_branch_target <= exec_branch_target;
        else
            fetch_branch_target <= fetch_addr;
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
            if (exec_take_branch && !fetch_done)
            begin
                fetch_flush_control <= 1;
            end
            else if (fetch_flush_control && fetch_done)
            begin
                // instruction from memory is ready, then we flush fetch
                fetch_flush_control <= 0;
            end
        end
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            global_flush <= 0;
            fetch_load <= 0;
            fetch_addr <= 'bx;
        end
        else
        begin
            global_flush <= 0;
            if (exception != `EXCEPT_NONE)
            begin
                global_flush <= 1;
                fetch_load <= 1;
                case (exception)
                    `EXCEPT_INTERRUPT: begin
                        fetch_addr <= `EXCEPT_INTERRUPT_ADDR;
                    end
                    `EXCEPT_SYSCALL: begin
                        fetch_addr <= `EXCEPT_SYSCALL_ADDR;
                    end
                    `EXCEPT_ILLEGAL: begin
                        fetch_addr <= `EXCEPT_ILLEGAL_ADDR;
                    end
                    `EXCEPT_TRAP: begin
                        fetch_addr <= `EXCEPT_TRAP_ADDR;
                    end
                    `EXCEPT_OVERFLOW: begin
                        fetch_addr <= `EXCEPT_OVERFLOW_ADDR;
                    end
                    `EXCEPT_ERET: begin
                        fetch_addr <= mem_cp0_epc;
                    end
                    default: begin
                        fetch_addr <= 0;
                    end
                endcase
            end
            else if (fetch_stall && exec_take_branch)
            begin
                fetch_load <= 1;
                fetch_addr <= exec_branch_target;
            end
            else if (fetch_load && !fetch_stall)
            begin
                fetch_load <= 0;
                fetch_addr <= 'bx;
            end
        end
    end
endmodule
