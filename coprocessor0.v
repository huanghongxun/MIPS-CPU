`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: Coprocessor 0
// Module Name: coprocessor0
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

module coprocessor0#(
	parameter DATA_WIDTH = 32
)(
    input clk,
    input rst_n,

    input reg_we,
    input [`CP0_REG_BUS] reg_read_addr,
    output reg [`DATA_BUS] reg_read,
    input [`CP0_REG_BUS] reg_write_addr,
    input [`DATA_BUS] reg_write,

    input [5:0] hardware_int,

    input [`DATA_BUS] exception,
    input [`DATA_BUS] pc,

    output [`DATA_BUS] count,
    output [`DATA_BUS] compare,
    output [`DATA_BUS] status,
    output [`DATA_BUS] cause,
    output [`DATA_BUS] epc,
    output [`DATA_BUS] prid,
    output [`DATA_BUS] cfg,

    output reg timer_interrupt
);

    reg [`DATA_BUS] count; // r9

    reg [`DATA_BUS] compare; // r11

    // r12
    wire [3:0] status_cu = 4'b0001; // status[31:28], coprocessor usability
    reg status_rp; // status[27], reduced power mode
    reg status_re; // status[25], MSB or LSB
    reg status_bev; // status[22], Bootstrap exception vector
    reg status_ts; // status[21], TLB shutdown
    reg [7:0] status_im; // status[15:8], interrupt mask
    reg status_exl; // status[1]
    reg status_ie; // status[0]

    assign status = {status_cu, status_rp, 1'b0, status_re, 2'b00, status_bev, status_ts, 1'b0, 1'b0, 3'b000, status_im, 3'b000, 1'b0, 1'b0, 1'b0, status_exl, status_ie};

    // r13
    reg cause_bd; // cause[31]
    // reg [1:0] cause_ce; // cause[29:28]
    // reg cause_dc; // cause[27]
    // reg cause_pci; // cause[26]
    reg cause_iv; // cause[23]
    reg cause_wp; // cause[22]
    reg [5:0] cause_hardware_ip;
    reg [1:0] cause_software_ip;
    reg [4:0] cause_exc_code;

    assign cause = {cause_bd, {7{1'b0}}, cause_iv, cause_wp, {6{1'b0}}, cause_hardware_ip, cause_software_ip, 1'b0, cause_exc_code, 2'b00};

    reg [`DATA_BUS] epc; // r14

    // r15
    assign prid = 32'b00000000_00000000_0000000000_000000;

    // r16
    assign cfg = {1'b0 /* M */, {15{1'b0}} /* Impl */, 1'b1 /* BE */, 2'b00 /* AT */, 3'b000 /* AR */, 3'b000 /* MT */, 3'b000, 1'b0 /* VI */, 3'b000 /* Kseg0 */};

    task update_pc_cause;
        if (status_exl == 0)
        begin
            epc <= pc;
            cause_bd <= 0;
        end
    endtask

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            count <= 0;
        end
        else
        begin
            if (reg_we && reg_write_addr == `CP0_REG_COUNT)
                count <= reg_write;
            else
                count <= count + 1;
        end
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            compare <= 0;
        end
        else
        begin
            if (compare != 0 && count == compare)
                timer_interrupt <= `TRUE;
            
            if (reg_we && reg_write_addr == `CP0_REG_COMPARE)
            begin
                compare <= reg_write;
                timer_interrupt <= `FALSE;
            end
        end
    end

    always @(posedge clk, negedge rst_n)
    begin
        if (!rst_n)
        begin
            epc <= 0;

            status_rp <= 0;
            status_re <= 0;
            status_bev <= 0;
            status_ts <= 0;
            status_im <= 0;
            status_exl <= 0;
            status_ie <= 0;

            cause_software_ip <= 0;
            cause_hardware_ip <= 0;
            cause_iv <= 0;
            cause_wp <= 0;
        end
        else
        begin
            cause_hardware_ip <= hardware_int;

            if (reg_we)
                case (reg_write_addr)
                    `CP0_REG_EPC: begin
                        epc <= reg_write;
                    end
                    `CP0_REG_STATUS: begin
                        status_rp <= reg_write[27];
                        status_re <= reg_write[25];
                        status_bev <= reg_write[22];
                        status_ts <= reg_write[21];
                        status_ie <= reg_write[0];
                    end
                    `CP0_REG_CAUSE: begin
                        cause_software_ip <= reg_write[9:8];
                        cause_iv <= reg_write[23];
                        cause_wp <= reg_write[22];
                    end
                endcase

            status_exl <= 1;
            case (exception)
                `EXCEPT_INTERRUPT: begin
                    epc <= pc;
                    cause_bd <= 0;
                    cause_exc_code <= `CODE_INT;
                end
                `EXCEPT_SYSCALL: begin
                    update_pc_cause();
                    cause_exc_code <= `CODE_SYS;
                end
                `EXCEPT_ILLEGAL: begin
                    update_pc_cause();
                    cause_exc_code <= `CODE_RI;
                end
                `EXCEPT_TRAP: begin
                    update_pc_cause();
                    cause_exc_code <= `CODE_TRAP;
                end
                `EXCEPT_OVERFLOW: begin
                    update_pc_cause();
                    cause_exc_code <= `CODE_OVF;
                end
                `EXCEPT_ERET: begin
                    status_exl <= 0;
                end
                default: begin
                    status_exl <= 0;
                end
            endcase
        end
    end

    always @*
    begin
        if (!rst_n) reg_read <= 0;
        else
            case (reg_read_addr)
                `CP0_REG_COUNT: reg_read <= count;
                `CP0_REG_COMPARE: reg_read <= compare;
                `CP0_REG_STATUS: reg_read <= status;
                `CP0_REG_CAUSE: reg_read <= cause;
                `CP0_REG_EPC: reg_read <= epc;
                `CP0_REG_PRID: reg_read <= prid;
                `CP0_REG_CONFIG: reg_read <= cfg;
                default: reg_read <= 0;
            endcase
    end

endmodule