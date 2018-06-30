`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/06/06 21:42:04
// Design Name: Pipeline Stage: Execution to Memory Access
// Module Name: pipeline_exec2mem
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

module pipeline_exec2mem #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3
)(
    input clk,
    input rst_n,
    input flush,
    input stall,
    
    input      [`DATA_BUS] raw_inst_in,
    input      [`INST_BUS] inst_in,
    input      [`DATA_BUS] alu_res_in, // Arithmetic result or memory address
    output reg [`DATA_BUS] alu_res_out,
    output reg       [3:0] mem_sel_out,
    input                  mem_rw_in,
    output reg             mem_rw_out,
    input                  mem_enable_in,
    output reg             mem_enable_out,
    input      [`DATA_BUS] mem_write_in,
    output reg [`DATA_BUS] mem_write_out,
    input      [`DATA_BUS] mem_read_in,
    output reg [`DATA_BUS] mem_read_out,
    input                  wb_src_in,
    output reg             wb_src_out,
    input                  wb_reg_in,
    output reg             wb_reg_out,
    input                  branch_in,
    output reg             branch_out,
    input      [`VREG_BUS] virtual_write_addr_in,
    output reg [`VREG_BUS] virtual_write_addr_out,
    input      [`PREG_BUS] physical_write_addr_in,
    output reg [`PREG_BUS] physical_write_addr_out,
    input      [FREE_LIST_WIDTH-1:0] active_list_index_in,
    output reg [FREE_LIST_WIDTH-1:0] active_list_index_out
    );

    reg [`INST_BUS] inst;

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            inst <= 0;
            alu_res_out <= 0;
            mem_enable_out <= 0;
            wb_src_out <= 0;
            wb_reg_out <= 0;
            branch_out <= 0;
            virtual_write_addr_out <= 0;
            physical_write_addr_out <= 0;
            active_list_index_out <= 0;
        end
        else
        begin
            if (!stall)
            begin
                if (flush)
                begin
                    inst <= 0;
                    alu_res_out <= 0;
                    mem_enable_out <= 0;
                    wb_src_out <= 0;
                    wb_reg_out <= 0;
                    branch_out <= 0;
                    virtual_write_addr_out <= 0;
                    physical_write_addr_out <= 0;
                    active_list_index_out <= 0;
                end
                else
                begin
                    inst <= inst_in;
                    alu_res_out <= alu_res_in;
                    mem_enable_out <= mem_enable_in;
                    wb_src_out <= wb_src_in;
                    wb_reg_out <= wb_reg_in;
                    branch_out <= branch_in;
                    virtual_write_addr_out <= virtual_write_addr_in;
                    physical_write_addr_out <= physical_write_addr_in;
                    active_list_index_out <= active_list_index_in;
                end
            end
        end
    end

    always @*
    begin
        mem_rw_out <= `MEM_READ;
        mem_sel_out <= 0;
        mem_read_out <= 0;
        mem_write_out <= 0;
        case (inst)
            `INST_LB: begin
                mem_rw_out <= `MEM_READ;
                case (alu_res_in[1:0])
                    0: mem_read_out <= $signed(mem_read_in[31:24]);
                    1: mem_read_out <= $signed(mem_read_in[23:16]);
                    2: mem_read_out <= $signed(mem_read_in[15: 8]);
                    3: mem_read_out <= $signed(mem_read_in[ 7: 0]);
                endcase
            end
            `INST_LBU: begin
                mem_rw_out <= `MEM_READ;
                case (alu_res_in[1:0])
                    0: mem_read_out <= $unsigned(mem_read_in[31:24]);
                    1: mem_read_out <= $unsigned(mem_read_in[23:16]);
                    2: mem_read_out <= $unsigned(mem_read_in[15: 8]);
                    3: mem_read_out <= $unsigned(mem_read_in[ 7: 0]);
                endcase
            end
            `INST_LH: begin
                mem_rw_out <= `MEM_READ;
                case (alu_res_in[1:0])
                    0: mem_read_out <= $signed(mem_read_in[31:16]);
                    2: mem_read_out <= $signed(mem_read_in[15: 0]);
                endcase
            end
            `INST_LHU: begin
                mem_rw_out <= `MEM_READ;
                case (alu_res_in[1:0])
                    0: mem_read_out <= $unsigned(mem_read_in[31:16]);
                    2: mem_read_out <= $unsigned(mem_read_in[15: 0]);
                endcase
            end
            `INST_LW: begin
                mem_rw_out <= `MEM_READ;
                mem_read_out <= mem_read_in;
            end
            `INST_LWL: begin
                mem_rw_out <= `MEM_READ;
                case (alu_res_in[1:0])
                    0: mem_read_out <= mem_read_in;
                    1: mem_read_out <= {mem_read_in[23:0], mem_write_in[ 7:0]};
                    2: mem_read_out <= {mem_read_in[15:0], mem_write_in[15:0]};
                    3: mem_read_out <= {mem_read_in[ 7:0], mem_write_in[23:0]};
                endcase
            end
            `INST_LWR: begin
                mem_rw_out <= `MEM_READ;
                case (alu_res_in[1:0])
                    0: mem_read_out <= {mem_write_in[31: 8], mem_read_in[31:24]};
                    1: mem_read_out <= {mem_write_in[31:16], mem_read_in[31:16]};
                    2: mem_read_out <= {mem_write_in[31:24], mem_read_in[31: 8]};
                    3: mem_read_out <= mem_read_in;
                endcase
            end
            `INST_SB: begin
                mem_rw_out <= `MEM_WRITE;
                mem_write_out <= {4{mem_write_in[7:0]}};
                case (alu_res_in[1:0])
                    0: mem_sel_out <= 4'b1000;
                    1: mem_sel_out <= 4'b0100;
                    2: mem_sel_out <= 4'b0010;
                    3: mem_sel_out <= 4'b0001;
                endcase
            end
            `INST_SH: begin
                mem_rw_out <= `MEM_WRITE;
                mem_write_out <= {2{mem_write_in[15:0]}};
                case (alu_res_in[1:0])
                    0: mem_sel_out <= 4'b1100;
                    2: mem_sel_out <= 4'b0011;
                endcase
            end
            `INST_SW: begin
                mem_rw_out <= `MEM_WRITE;
                mem_write_out <= mem_write_in;
                mem_sel_out <= 4'b1111;
            end
            `INST_SWL: begin
                mem_rw_out <= `MEM_WRITE;
                case (alu_res_in[1:0])
                    0: begin
                        mem_sel_out <= 4'b1111;
                        mem_write_out <= mem_write_in;
                    end
                    1: begin
                        mem_sel_out <= 4'b0111;
                        mem_write_out <= {{ 8{1'b0}}, mem_write_in[31: 8]};
                    end
                    2: begin
                        mem_sel_out <= 4'b0011;
                        mem_write_out <= {{16{1'b0}}, mem_write_in[31:16]};
                    end
                    3: begin
                        mem_sel_out <= 4'b0001;
                        mem_write_out <= {{24{1'b0}}, mem_write_in[31:24]};
                    end
                endcase
            end
            `INST_SWR: begin
                mem_rw_out <= `MEM_WRITE;
                case (alu_res_in[1:0])
                    0: begin
                        mem_sel_out <= 4'b1000;
                        mem_write_out <= {mem_write_in[ 7:0], {24{1'b0}}};
                    end
                    1: begin
                        mem_sel_out <= 4'b1100;
                        mem_write_out <= {mem_write_in[15:0], {16{1'b0}}};
                    end
                    2: begin
                        mem_sel_out <= 4'b1110;
                        mem_write_out <= {mem_write_in[23:0], { 8{1'b0}}};
                    end
                    3: begin
                        mem_sel_out <= 4'b1111;
                        mem_write_out <= mem_write_in;
                    end
                endcase
            end
        endcase
    end
    
endmodule
