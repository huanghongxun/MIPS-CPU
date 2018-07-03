`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Design Name: Execution Stage Controller
// Module Name: execution
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//
// Dependencies: None
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module execution#(parameter DATA_WIDTH = 32)(
    input clk,
    input rst_n,
    input stall,

    input [`DATA_BUS] raw_inst,
    input [`INST_BUS] inst,

    input [`EX_SRC_BUS] exec_src,

    input [`ALU_OP_WIDTH-1:0] alu_op,
    input [`DATA_BUS] alu_rs,
    input [`DATA_BUS] alu_rt,

    input branch,
    input trap,

    // Interaction with coprocessor 0

    output cp0_reg_rw,
    output [`CP0_REG_BUS] cp0_reg_read_addr,
    input [`DATA_BUS] cp0_reg_read,
    output [`CP0_REG_BUS] cp0_reg_write_addr,
    output [`DATA_BUS] cp0_reg_write,

    input mem_wb_cp0,
    input [`CP0_REG_BUS] mem_cp0_write_addr,
    input [`DATA_BUS] mem_cp0_write,

    input wb_wb_cp0,
    input [`CP0_REG_BUS] wb_cp0_write_addr,
    input [`DATA_BUS] wb_cp0_write,

    output reg [`DATA_BUS] res,
    output take_branch,
    output take_trap
);
    wire [`DATA_BUS] alu_rd, move_res;
    reg [`DATA_BUS] cp0_reg_override;

    assign take_branch = exec_src == `EX_ALU && branch && alu_rd;
    assign take_trap = exec_src == `EX_ALU && trap && alu_rd;
    wire [1:0] exec_test_state;

    // Determine what data we are going to write back.
    always @*
    begin
        case (exec_src)
            `EX_NOP: res <= 0;
            `EX_ALU: res <= alu_rd;
            `EX_MOV: res <= move_res;
            default: res <= 0;
        endcase
    end

    // ==== Data forwarding ===

    always @*
    begin
        cp0_reg_override <= cp0_reg_read;
        if (mem_wb_cp0 == `REG_WB && mem_cp0_write_addr == cp0_reg_read_addr)
            cp0_reg_override <= mem_cp0_write;
        else if (wb_wb_cp0 == `REG_WB && wb_cp0_write_addr == cp0_reg_read_addr)
            cp0_reg_override <= wb_cp0_write;
    end
    
    move #(.DATA_WIDTH(DATA_WIDTH)) mov(
        .clk(clk),
        .rst_n(rst_n),

        .raw_inst(raw_inst),
        .inst(inst),
        .exec_src(exec_src),
        
        .cp0_reg_rw(cp0_reg_rw),
        .cp0_reg_read_addr(cp0_reg_read_addr),
        .cp0_reg_read(cp0_reg_override),
        .cp0_reg_write_addr(cp0_reg_write_addr),
        .cp0_reg_write(cp0_reg_write),

        .data(alu_rs),

        .res(move_res)
    );
    
    arithmetic_logic_unit #(.DATA_WIDTH(DATA_WIDTH)) alu(
        .stall(stall),
        .en(exec_src == `EX_ALU),
        .op(alu_op),
        .rs(alu_rs),
        .rt(alu_rt),
        .rd(alu_rd)
    );
endmodule