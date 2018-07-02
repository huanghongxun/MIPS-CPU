`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Memory Controller
// Module Name: memory_controller
// Project Name: SimpleCPU
// Target Devices: Basys3
// Tool Versions: Vivado 2018.1
// Description: 
//   manage memory with data cache, instruction cache and external storage.
//
//   external storage includes flash memory, uart bus, even switches.
//
//   Priority:
//      External Storage -- high
//      Inst Cache
//      Data Cache -- low
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module memory_controller#(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16 // main memory address width
)(
    input clk,
    input rst_n,

    input force_disable, // stop writing to RAM

    // inst cache
    input [`ADDR_BUS] imem_addr,
    input imem_enable,

    output reg [`DATA_BUS] imem_read,
    output reg imem_read_valid,

    output reg imem_last,

    // data cache
    input [`ADDR_BUS] dmem_addr,
    input dmem_enable,
    input dmem_rw,

    input [`DATA_BUS] dmem_write,
    output reg dmem_req_data, // Request data-cache to transmit data.

    output reg [`DATA_BUS] dmem_read,
    output reg dmem_read_valid,

    output reg dmem_last,

    // external storage
    input [`ADDR_BUS] external_addr,
    input external_enable,
    input external_rw,
    
    input external_op_size,
    input external_finishes_op,

    input [`DATA_BUS] external_write,
    output reg external_req_data, // Request external storage to transmit data to ram
    
    output reg [`DATA_BUS] external_read,
    output reg external_read_valid, 

    output reg external_last,

    // ram
    output reg [`ADDR_BUS] mem_addr,
    output reg mem_enable,
    output reg mem_rw,
    
    output reg mem_op_size,
    output reg mem_finishes_op,

    output reg [`DATA_BUS] mem_write,
    input mem_write_req_input,

    input [`DATA_BUS] mem_read,
    input mem_read_valid,

    input mem_last
    );

    localparam STATE_READY = 0;
    localparam STATE_INST_MEM = 1;
    localparam STATE_DATA_MEM = 2;
    localparam STATE_MEM = 3;
    localparam STATE_EXTERNAL = 4;

    // Now which component is requesting an operation on memory.
    reg [2:0] state;

    always @*
    begin
        imem_read_valid <= 0;
        imem_last <= 0;
        imem_read <= 'bx;
        dmem_read_valid <= 0;
        dmem_req_data <= 0;
        dmem_last <= 0;
        dmem_read <= 'bx;
        external_read <= 'bx;
        external_read_valid <= 0;
        external_req_data <= 0;
        external_last <= 0;
        mem_enable <= 0;
        mem_addr <= 'bx;
        mem_rw <= `MEM_READ;
        mem_write <= 'bx;
        mem_op_size <= 0;
        mem_finishes_op <= 0;

        case (state)
            STATE_READY: begin // no component requests occupying memory
            end
            STATE_INST_MEM: begin // inst-cache requested a read operation operation
                mem_enable <= 1;
                mem_addr <= imem_addr;
                // instruction cache only reads data from memory
                mem_rw <= `MEM_READ;

                imem_read_valid <= mem_read_valid;
                imem_last <= mem_last;
                imem_read <= mem_read;
            end
            STATE_DATA_MEM: begin // data-cache requested an operation on memory
                mem_enable <= 1;
                mem_addr <= dmem_addr;
                mem_rw <= dmem_rw;
                mem_write <= dmem_write;

                dmem_read_valid <= mem_read_valid;
                dmem_req_data <= mem_write_req_input;
                dmem_last <= mem_last;
                dmem_read <= mem_read;
            end
            STATE_EXTERNAL: begin // external storage requested a write operation on memory
                mem_enable <= 1;
                mem_addr <= external_addr;
                // flash memory only writes data from memory here.
                mem_rw <= external_rw;
                mem_write <= external_write;
                
                mem_op_size <= external_op_size;
                mem_finishes_op <= external_finishes_op;

                external_req_data <= mem_write_req_input;
                external_last <= mem_last;
                external_read_valid <= mem_read_valid;
                external_read <= mem_read;
            end
        endcase
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            state <= STATE_READY;
        end
        else
        begin
            case (state)
                STATE_READY: begin
                    if (external_enable)
                    begin
                        state <= STATE_EXTERNAL;
`ifdef DEBUG_MEMCTRL
                        $display("memctrl: start servicing external device");
`endif
                    end
                    else if (imem_enable)
                    begin
                        state <= STATE_INST_MEM;
`ifdef DEBUG_MEMCTRL
                        $display("memctrl: start servicing instruction cache");
`endif
                    end
                    else if (dmem_enable && (!force_disable || force_disable && dmem_rw != `MEM_WRITE))
                    begin
                        state <= STATE_DATA_MEM;
`ifdef DEBUG_MEMCTRL
                        $display("memctrl: start servicing data cache");
`endif
                    end
                end
                STATE_EXTERNAL: begin
                    if (mem_last)
                    begin
                        state <= STATE_READY;
`ifdef DEBUG_MEMCTRL
                        $display("memctrl: external device finished");
`endif
                    end
                end
                STATE_INST_MEM: begin
                    if (mem_last)
                    begin
                        state <= STATE_READY;
`ifdef DEBUG_MEMCTRL
                        $display("memctrl: inst cache finished");
`endif
                    end
                end
                STATE_DATA_MEM: begin
                    if (mem_last)
                    begin
                        state <= STATE_READY;
`ifdef DEBUG_MEMCTRL
                        $display("memctrl: data cache finished");
`endif
                    end
                end
            endcase
        end
    end
    
endmodule
