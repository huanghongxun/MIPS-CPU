`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: 
// Module Name: main_top
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


module main_top(
    input flash_cs,
    input flash_sdi,
    input flash_sdo,
    input flash_wp,
    input flash_hld,
    input flash_sck
    );
                          
    fetch_unit fetch(.clk(clk),
                            .stall(stall),
                            .busy(mem_busy),
                            .pc(pc),
                            .rw(pc_rw),
                            .access_size(pc_access_size),
                            .enable(pc_enable),
                            .jmp_addr(alu_jmp_target),
                            .jmp(jmp),
                            .branch(alu_branch),
                            .branch_addr(alu_imm));

    pipeline_fetch2dec pfd(.clk(clk),
                           .rst_n(rst_n),
                           .flush(hazard_fetch_flush),
                           .stall(hazard_decode_stall),
                           
                           .pc_in())
                            
    decoder decode(.inst(decoder_inst),
                         .op(decoder_op),
                         .rs(decoder_rs),
                         .rt(decoder_rt),
                         .rd(decoder_rd),
                         .imm(decoder_imm),
                         .func(decoder_func),
                         .addr(decoder_addr),
                         .b_ctrl(decoder_b_ctrl),
                         .mem_width(decoder_mem_width),
                         .mem_rw(decoder_mem_rw),
                         .mem_enable(decoder_mem_enable),
                         .sign_extend(decoder_sign_extend),
                         .alu_wb(decoder_alu_wb),
                         .reg_wb(decoder_reg_wb),
                         .jump(decoder_jump));

    pipeline_dec2exec
                         
    arithmetic_logic_unit alu(.func(alu_func),
                              .rs(alu_rs),
                              .rt(alu_rt),
                              .rd(alu_rd),
                              .branch(alu_branch));

    memory#(ROM_FILE) ram(.clk(clk),
                          .addr(addr),
                          .din(din),
                          .dout(mem_dout),
                          .access_size(pc_access_size),
                          .rw(mem_rw),
                          .busy(mem_busy),
                          .enable(pc_enable));
                          
    register_file regfile(.clk(clk),
                             .ra(decoder_rs),
                             .rb(decoder_rt),
                             .a(reg_a),
                             .b(reg_b),
                             .rw(decoder_rd),
                             .wn(decoder_reg_wb),
                             .wd(mem_dout));
                         
    assign alu_rs = alu_s1val;
    assign alu_rt = decoder_b_ctrl == 1 ? alu_offset_se : alu_s2val;

    hazard_detection_unit#()
endmodule
