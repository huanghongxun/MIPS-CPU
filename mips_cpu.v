`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Sun Yat-sen University
// Engineer: Yuhui Huang
// 
// Create Date: 2018/05/25 00:13:18
// Design Name: MIPS CPU
// Module Name: mips_cpu
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

module mips_cpu #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,
    parameter REG_ADDR_WIDTH = 5,
    parameter FREE_LIST_WIDTH = 3,
    parameter ASSO_WIDTH = 1, // for n-way associative caching
    parameter BLOCK_OFFSET_WIDTH = 5, // width of address of a block
    parameter INDEX_WIDTH = 3,
    parameter TAG_WIDTH = ADDR_WIDTH - INDEX_WIDTH - BLOCK_OFFSET_WIDTH // Upper 13 bits of the physical address (the tag) are compared to the 13 bit tag field at that cache entry.
)(
    input clk, // 100MHz clock signal
    input rst_n,
    
    // Interface with external device
    input [`ADDR_BUS] external_addr,
    input external_enable,
    input external_rw,
    input external_op_size,
    input external_finishes_op,
    input [`DATA_BUS] external_write,
    output external_req_data,
    output [`DATA_BUS] external_read, // output data that external devices read
    output external_read_valid, // true if external devices could read data.
    output external_last,
    input external_done,
    
    // block memory generator
    output bram_ena,
    output bram_wea,
    output [`ADDR_BUS] bram_addra,
    output [`DATA_BUS] bram_dina,
    input [`DATA_BUS] bram_douta
    );

    wire pipe_fetch_stall;
    wire fetch_rw;
    wire [`ADDR_BUS] fetch_write;
    wire [`ADDR_BUS] fetch_pc;

    wire imem_ready;
    wire [`DATA_BUS] imem_data;
    wire imem_data_valid;

    wire pipe_global_flush;

    // fetch2dec

    wire pipe_fetch_flush;
    wire pipe_decode_stall;
    wire dec_bubble;

    wire [`ADDR_BUS] dec_pc;
    wire [`DATA_BUS] dec_raw_inst;
    wire [`VREG_BUS] dec_vrs_addr;
    wire [`VREG_BUS] dec_vrt_addr;
    wire [`DATA_BUS] dec_rs_data;
    wire [`DATA_BUS] dec_rt_data;
    wire [`VREG_BUS] dec_virtual_write_addr;
    wire [`PREG_BUS] dec_prs_addr;
    wire [`PREG_BUS] dec_prt_addr;
    wire [`PREG_BUS] dec_physical_write_addr;
    wire [`INST_BUS] dec_inst;
    wire [`ALU_OP_BUS] dec_exec_op;
    wire [FREE_LIST_WIDTH-1:0] dec_active_list_index;
    wire dec_rs_enable;
    wire dec_rt_enable;
    wire [1:0] dec_exec_src;
    wire dec_b_ctrl;
    wire dec_mem_enable;
    wire [`DATA_BUS] dec_imm;
    wire dec_wb_src;
    wire dec_wb_reg;
    wire dec_branch, dec_trap, dec_illegal;
    wire [1:0] dec_jump;
    wire [`ADDR_BUS] dec_branch_target;
    
    wire regfile_stall;

    // dec2exec

    wire pipe_decode_flush;
    wire pipe_exec_stall;

    wire [`DATA_BUS] exec_raw_inst;
    wire [`INST_BUS] exec_inst;
    wire exec_mem_enable;
    wire [1:0] exec_exec_src;
    wire exec_wb_src;
    wire exec_wb_reg;
    wire exec_branch, exec_trap, exec_illegal;
    wire [`ADDR_BUS] exec_branch_target;
    
    wire [`VREG_BUS] exec_virtual_write_addr;
    wire [`PREG_BUS] exec_physical_write_addr;
    wire [FREE_LIST_WIDTH-1:0] exec_active_list_index;

    wire [`ADDR_BUS] exec_pc;

    wire [`ALU_OP_WIDTH-1:0] exec_alu_op;
    wire [`DATA_BUS] exec_alu_rs;
    wire [`DATA_BUS] exec_alu_rt;
    wire [`DATA_BUS] exec_res;
    
    wire [`DATA_BUS] exec_mem_write;
    
    wire [`DATA_BUS] forwarded_rs_data;
    wire [`DATA_BUS] forwarded_rt_data;
    wire [`DATA_BUS] mem_cp0_status;
    wire [`DATA_BUS] mem_cp0_cause;
    wire [`DATA_BUS] mem_cp0_epc;

    wire exec_wb_cp0;
    wire [`CP0_REG_BUS] exec_cp0_write_addr;
    wire [`DATA_BUS] exec_cp0_write;
    
    wire exec_take_branch;
    wire exec_take_trap;
    wire [1:0] exec_test_state;

    // exec2mem

    wire pipe_exec_flush;
    wire pipe_mem_stall;

    wire [`DATA_BUS] dmem_res;
    wire [`DATA_BUS] dmem_mem_write;
    wire [`DATA_BUS] dmem_mem_read;
    wire [`DATA_BUS] dmem_mem_read_raw;
    reg  [`DATA_BUS] dmem_write;
    wire [3:0] dmem_mem_sel;
    wire dmem_mem_enable;
    wire dmem_mem_rw;
    wire dmem_wb_src;
    wire dmem_wb_reg;
    wire dmem_ready;
    wire dmem_branch;
    wire dmem_mem_rw_valid;
    reg dmem_done;

    wire force_disable_mem;

    wire dmem_wb_cp0;
    wire [`CP0_REG_BUS] dmem_cp0_write_addr;
    wire [`DATA_BUS] dmem_cp0_write;
    
    wire [`VREG_BUS] dmem_virtual_write_addr;
    wire [`PREG_BUS] dmem_physical_write_addr;
    wire [FREE_LIST_WIDTH-1:0] dmem_active_list_index;
    
    // mem2wb
    
    wire pipe_mem_flush;
    wire pipe_wb_stall;
    
    wire wb_wb_reg;
    wire [`PREG_BUS] wb_physical_write_addr;
    wire [`VREG_BUS] wb_virtual_write_addr;
    wire [`DATA_BUS] wb_write;
    wire [FREE_LIST_WIDTH-1:0] wb_active_list_index;

    wire wb_wb_cp0;
    wire [`CP0_REG_BUS] wb_cp0_write_addr;
    wire [`DATA_BUS] wb_cp0_write;
    
    wire pipe_wb_flush;
    
    // coprocessor0
    wire [`CP0_REG_BUS] cp0_reg_read_addr;
    wire [`DATA_BUS] cp0_reg_read;

    wire [`DATA_BUS] cp0_count, cp0_compare, cp0_status, cp0_cause, cp0_epc, cp0_prid, cp0_cfg;
    wire cp0_timer_interrupt;
    
    // ram

    wire [`ADDR_BUS] ram_addr;
    wire ram_enable;
    wire ram_rw;
    wire ram_op_size;
    wire ram_finishes_op;
    wire [`DATA_BUS] ram_write;
    wire ram_write_req_input;
    wire [`DATA_BUS] ram_read;
    wire ram_read_valid;
    wire ram_last;

    // memctrl

    wire [`ADDR_BUS] memctrl_imem_addr;
    wire memctrl_imem_enable;
    wire [`DATA_BUS] memctrl_imem_read;
    wire memctrl_imem_read_valid;
    wire memctrl_imem_last;

    wire [`ADDR_BUS] memctrl_dmem_addr;
    wire memctrl_dmem_enable;
    wire memctrl_dmem_rw;
    wire [`DATA_BUS] memctrl_dmem_write;
    wire memctrl_dmem_req_data;
    wire [`DATA_BUS] memctrl_dmem_read;
    wire memctrl_dmem_read_valid;
    wire memctrl_dmem_last;
    
    wire done = exec_inst == `INST_TEST_DONE;
    
    fetch_unit fetch(.clk(clk),
                     .rst_n(rst_n),
                     .stall(pipe_fetch_stall),
                     
                     .rw(fetch_rw),
                     .write(fetch_write),
                     
                     .pc(fetch_pc));

    inst_cache#(.DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .ASSO_WIDTH(ASSO_WIDTH),
                .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH),
                .INDEX_WIDTH(INDEX_WIDTH),
                .TAG_WIDTH(TAG_WIDTH))
                icache(.clk(clk),
                       .rst_n(rst_n),

                       // request
                       .addr(fetch_pc),
                       .enable(external_done),

                       .ready(imem_ready),
                       .data(imem_data),
                       .data_valid(imem_data_valid),
                       
                       .mem_addr(memctrl_imem_addr),
                       .mem_enable(memctrl_imem_enable),
                       
                       .mem_read(memctrl_imem_read),
                       .mem_read_valid(memctrl_imem_read_valid),
                       .mem_last(memctrl_imem_last));

    pipeline_fetch2dec #(.DATA_WIDTH(DATA_WIDTH),
                         .ADDR_WIDTH(ADDR_WIDTH))
                    pfd(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_fetch_flush),
                        .global_flush(pipe_global_flush),
                        .stall(pipe_decode_stall),
                        
                        .pc_in(fetch_pc),
                        .pc_out(dec_pc),
                        .inst_in(imem_data),
                        .inst_out(dec_raw_inst),
                        .bubble_in(imem_data_valid),
                        .bubble_out(dec_bubble));
                            
    decoder #(.DATA_WIDTH(DATA_WIDTH),
              .ADDR_WIDTH(ADDR_WIDTH),
              .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                decode(.stall(pipe_decode_stall),
                        .pc(dec_pc),
                        .raw_inst(dec_raw_inst),
                        .rs_enable(dec_rs_enable),
                        .rs_addr(dec_vrs_addr),
                        .rt_enable(dec_rt_enable),
                        .rt_addr(dec_vrt_addr),
                        .wb_reg(dec_wb_reg), // rd_enable
                        .rd_addr(dec_virtual_write_addr),
                        .imm(dec_imm),
                        .inst(dec_inst),
                        .exec_op(dec_exec_op),
                        .addr(dec_branch_target),
                        .exec_src(dec_exec_src),
                        .b_ctrl(dec_b_ctrl),
                        .mem_enable(dec_mem_enable),
                        .wb_src(dec_wb_src),
                        .jump(dec_jump),
                        .branch(dec_branch),
                        .trap(dec_trap),
                        .illegal(dec_illegal));
                          

    register_file #(.DATA_WIDTH(DATA_WIDTH),
                       .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
                       .FREE_LIST_WIDTH(FREE_LIST_WIDTH))
                    regfile(.clk(clk),
                            .rst_n(rst_n),
                            .stall_in(pipe_decode_stall),

                            .virtual_rs_addr(dec_vrs_addr),
                            .virtual_rs_data(dec_rs_data),
                            .virtual_rt_addr(dec_vrt_addr),
                            .virtual_rt_data(dec_rt_data),
                            .dec_rw(dec_wb_reg),
                            .virtual_rd_addr(dec_virtual_write_addr),
                            
                            .wb_write_enable(wb_wb_reg && !pipe_wb_flush),
                            .wb_physical_write_addr(wb_physical_write_addr),
                            .wb_physical_write_data(wb_write),
                            .wb_active_list_index(wb_active_list_index),

                            .physical_rs_addr(dec_prs_addr),
                            .physical_rt_addr(dec_prt_addr),
                            .physical_rd_addr(dec_physical_write_addr),

                            .active_list_index(dec_active_list_index),
                            
                            .stall_out(regfile_stall));

    pipeline_dec2exec #(.DATA_WIDTH(DATA_WIDTH),
                        .ADDR_WIDTH(ADDR_WIDTH),
                        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
                        .FREE_LIST_WIDTH(FREE_LIST_WIDTH))
                    pde(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_decode_flush),
                        .global_flush(pipe_global_flush),
                        .stall(pipe_exec_stall),
                        
                        .pc_in(dec_pc),
                        .pc_out(exec_pc),
                        .raw_inst_in(dec_raw_inst),
                        .raw_inst_out(exec_raw_inst),
                        .inst_in(dec_inst),
                        .inst_out(exec_inst),
                        .alu_op_in(dec_exec_op),
                        .alu_op_out(exec_alu_op),
                        .exec_src_in(dec_exec_src),
                        .exec_src_out(exec_exec_src),
                        .alu_rs_in(forwarded_rs_data),
                        .alu_rs_out(exec_alu_rs),
                        .alu_rt_in(dec_b_ctrl ? dec_imm : forwarded_rt_data),
                        .alu_rt_out(exec_alu_rt),
                        .mem_enable_in(dec_mem_enable),
                        .mem_enable_out(exec_mem_enable),
                        .mem_write_in(forwarded_rt_data),
                        .mem_write_out(exec_mem_write),
                        .wb_src_in(dec_wb_src),
                        .wb_src_out(exec_wb_src),
                        .wb_reg_in(dec_wb_reg),
                        .wb_reg_out(exec_wb_reg),
                        .branch_in(dec_branch),
                        .branch_out(exec_branch),
                        .trap_in(dec_trap),
                        .trap_out(exec_trap),
                        .illegal_in(dec_illegal),
                        .illegal_out(exec_illegal),
                        .branch_target_in(dec_jump == `JUMP_REG ? forwarded_rs_data[`ADDR_BUS] : dec_branch_target),
                        .branch_target_out(exec_branch_target),
                        .virtual_write_addr_in(dec_virtual_write_addr),
                        .virtual_write_addr_out(exec_virtual_write_addr),
                        .physical_write_addr_in(dec_physical_write_addr),
                        .physical_write_addr_out(exec_physical_write_addr),
                        .active_list_index_in(dec_active_list_index),
                        .active_list_index_out(exec_active_list_index));
    
    execution #(.DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH),
                .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                exe(.clk(clk),
                    .rst_n(rst_n),
                    
                    .raw_inst(exec_raw_inst),
                    .inst(exec_inst),
                    .exec_src(exec_exec_src),
                    .alu_op(exec_alu_op),
                    .alu_rs(exec_alu_rs),
                    .alu_rt(exec_alu_rt),

                    .branch(exec_branch),
                    .trap(exec_trap),
                
                    .cp0_reg_rw(exec_wb_cp0),
                    .cp0_reg_read_addr(cp0_reg_read_addr),
                    .cp0_reg_read(cp0_reg_read),
                    .cp0_reg_write_addr(exec_cp0_write_addr),
                    .cp0_reg_write(exec_cp0_write),

                    .mem_wb_cp0(dmem_wb_cp0),
                    .mem_cp0_write_addr(dmem_cp0_write_addr),
                    .mem_cp0_write(dmem_cp0_write),

                    .wb_wb_cp0(wb_wb_cp0),
                    .wb_cp0_write_addr(wb_cp0_write_addr),
                    .wb_cp0_write(wb_cp0_write),
                    
                    .res(exec_res),
                    .take_branch(exec_take_branch),
                    .take_trap(exec_take_trap));

    pipeline_exec2mem #(.DATA_WIDTH(DATA_WIDTH),
                        .ADDR_WIDTH(ADDR_WIDTH),
                        .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                    pem(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_exec_flush),
                        .global_flush(pipe_global_flush),
                        .stall(pipe_mem_stall),
                        
                        .raw_inst_in(exec_raw_inst),
                        .inst_in(exec_inst),
                        .alu_res_in(exec_res),
                        .alu_res_out(dmem_res),
                        .mem_sel_out(dmem_mem_sel),
                        .mem_rw_out(dmem_mem_rw),
                        .mem_enable_in(exec_mem_enable),
                        .mem_enable_out(dmem_mem_enable),
                        .mem_write_in(exec_mem_write),
                        .mem_write_out(dmem_mem_write),
                        .mem_read_in(dmem_mem_read_raw),
                        .mem_read_out(dmem_mem_read),
                        .wb_src_in(exec_wb_src),
                        .wb_src_out(dmem_wb_src),
                        .wb_reg_in(exec_wb_reg),
                        .wb_reg_out(dmem_wb_reg),
                        .branch_in(exec_branch),
                        .branch_out(dmem_branch),
                        .virtual_write_addr_in(exec_virtual_write_addr),
                        .virtual_write_addr_out(dmem_virtual_write_addr),
                        .physical_write_addr_in(exec_physical_write_addr),
                        .physical_write_addr_out(dmem_physical_write_addr),
                        .active_list_index_in(exec_active_list_index),
                        .active_list_index_out(dmem_active_list_index),
                        .wb_cp0_in(exec_wb_cp0),
                        .wb_cp0_out(dmem_wb_cp0),
                        .cp0_write_addr_in(exec_cp0_write_addr),
                        .cp0_write_addr_out(dmem_cp0_write_addr),
                        .cp0_write_in(exec_cp0_write),
                        .cp0_write_out(dmem_cp0_write));

    always @* // select which value should we write back to register file.
    begin
        if (dmem_wb_src == `WB_ALU) // if this instruction writes the value calculated back to register.
        begin
            dmem_write <= dmem_res; // ALU result passed through pipeline.
            dmem_done <= 1;
        end
        else // if this instruction is load-like inst.
        begin
            dmem_write <= dmem_mem_read; // write the value read from memory.
            dmem_done <= dmem_mem_rw_valid; // we write the value if memory signals that the value is valid.
        end
    end

    memory_access #(.DATA_WIDTH(DATA_WIDTH),
                    .ADDR_WIDTH(ADDR_WIDTH),
                    .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                    mem(.clk(clk),
                        .rst_n(rst_n),

                        .cp0_status(cp0_status),
                        .cp0_cause(cp0_cause),
                        .cp0_epc(cp0_epc),

                        .wb_wb_cp0(wb_wb_cp0),
                        .wb_cp0_write_addr(wb_cp0_write_addr),
                        .wb_cp0_write(wb_cp0_write),

                        .force_disable_mem(force_disable_mem)
                    );

    bram_controller ram(.clk(clk),
                        .rst_n(rst_n),

                        .addr(ram_addr),
                        .enable(ram_enable),
                        .rw(ram_rw),
                        
                        .op_size(ram_op_size),
                        .finishes_op(ram_finishes_op),

                        .data_write(ram_write),
                        .data_write_req_input(ram_write_req_input),

                        .data_read(ram_read),
                        .data_read_valid(ram_read_valid),

                        .finished(ram_last),

                        // BRAM interface
                        .ena(bram_ena),
                        .wea(bram_wea),
                        .addra(bram_addra),
                        .dina(bram_dina),
                        .douta(bram_douta)
                        );
    
    
    data_cache #(.DATA_WIDTH(DATA_WIDTH),
                 .ADDR_WIDTH(ADDR_WIDTH),
                 .ASSO_WIDTH(ASSO_WIDTH),
                 .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH),
                 .INDEX_WIDTH(INDEX_WIDTH),
                 .TAG_WIDTH(TAG_WIDTH))
                dcache(.clk(clk),
                       .rst_n(rst_n),
                       
                       .addr(dmem_res[DATA_WIDTH-1:2]),
                       .enable(dmem_mem_enable),
                       .rw(dmem_mem_rw),

                       .write(dmem_mem_write),
                       .mem_sel(dmem_mem_sel),

                       .read(dmem_mem_read_raw),
                       .rw_valid(dmem_mem_rw_valid),
                       
                       .ready(dmem_ready), // for memory prediction
                       
                       .mem_addr(memctrl_dmem_addr),
                       .mem_enable(memctrl_dmem_enable),
                       .mem_rw(memctrl_dmem_rw),
                       
                       .mem_read(memctrl_dmem_read),
                       .mem_read_valid(memctrl_dmem_read_valid),
                       
                       .mem_write(memctrl_dmem_write),
                       .mem_write_req_input(memctrl_dmem_req_data),
                       
                       .mem_last(memctrl_dmem_last));

    memory_controller #(.DATA_WIDTH(DATA_WIDTH),
                        .ADDR_WIDTH(ADDR_WIDTH))
                    memctrl(.clk(clk),
                            .rst_n(rst_n),
                            .force_disable(force_disable_mem),
                            
                            .imem_addr(memctrl_imem_addr),
                            .imem_enable(memctrl_imem_enable),
                            
                            .imem_read(memctrl_imem_read),
                            .imem_read_valid(memctrl_imem_read_valid),

                            .imem_last(memctrl_imem_last),
                            
                            .dmem_addr(memctrl_dmem_addr),
                            .dmem_enable(memctrl_dmem_enable),
                            .dmem_rw(memctrl_dmem_rw),

                            .dmem_write(memctrl_dmem_write),
                            .dmem_req_data(memctrl_dmem_req_data),

                            .dmem_read(memctrl_dmem_read),
                            .dmem_read_valid(memctrl_dmem_read_valid),

                            .dmem_last(memctrl_dmem_last),

                            .external_addr(external_addr),
                            .external_enable(external_enable),
                            .external_rw(external_rw),
                            
                            .external_op_size(external_op_size),
                            .external_finishes_op(external_finishes_op),

                            .external_read(external_read),
                            .external_read_valid(external_read_valid),
                            .external_write(external_write),
                            .external_req_data(external_req_data),

                            .external_last(external_last),

                            .mem_addr(ram_addr),
                            .mem_enable(ram_enable),
                            .mem_rw(ram_rw),
                            
                            .mem_op_size(ram_op_size),
                            .mem_finishes_op(ram_finishes_op),

                            .mem_write(ram_write),
                            .mem_write_req_input(ram_write_req_input),

                            .mem_read(ram_read),
                            .mem_read_valid(ram_read_valid),

                            .mem_last(ram_last)
                    );

    pipeline_mem2wb #(.DATA_WIDTH(DATA_WIDTH),
                      .ADDR_WIDTH(ADDR_WIDTH))
                    pmw(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_wb_flush),
                        .global_flush(pipe_global_flush),
                        .stall(pipe_wb_stall),
                        
                        .wb_reg_in(dmem_wb_reg),
                        .wb_reg_out(wb_wb_reg),
                        .reg_write_in(dmem_write),
                        .reg_write_out(wb_write),
                        .virtual_write_addr_in(dmem_virtual_write_addr),
                        .virtual_write_addr_out(wb_virtual_write_addr),
                        .physical_write_addr_in(dmem_physical_write_addr),
                        .physical_write_addr_out(wb_physical_write_addr),
                        .active_list_index_in(dmem_active_list_index),
                        .active_list_index_out(wb_active_list_index),
                        .wb_cp0_in(dmem_wb_cp0),
                        .wb_cp0_out(wb_wb_cp0),
                        .cp0_write_addr_in(dmem_cp0_write_addr),
                        .cp0_write_addr_out(wb_cp0_write_addr),
                        .cp0_write_in(dmem_cp0_write),
                        .cp0_write_out(wb_cp0_write));

    coprocessor0 #(.DATA_WIDTH(DATA_WIDTH),
                   .ADDR_WIDTH(ADDR_WIDTH))
                cp0(.clk(clk),
                    .rst_n(rst_n),
                    
                    .reg_we(exec_wb_cp0),
                    .reg_read_addr(cp0_reg_read_addr),
                    .reg_read(cp0_reg_read),
                    .reg_write_addr(exec_cp0_write_addr),
                    .reg_write(exec_cp0_write),
                    
                    .count(cp0_count),
                    .compare(cp0_compare),
                    .status(cp0_status),
                    .cause(cp0_cause),
                    .epc(cp0_epc),
                    .prid(cp0_prid),
                    .cfg(cp0_cfg),
                    
                    .timer_interrupt(cp0_timer_interrupt));

    forwarding_unit #(.DATA_WIDTH(DATA_WIDTH),
                      .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                forward(.dec_rs_enable(dec_rs_enable),
                        .dec_prs_addr(dec_prs_addr),
                        .dec_rs_data(dec_rs_data),
                        .dec_rt_enable(dec_rt_enable),
                        .dec_prt_addr(dec_prt_addr),
                        .dec_rt_data(dec_rt_data),

                        .exec_wb_reg(exec_wb_reg),
                        .exec_exec_src(exec_exec_src),
                        .exec_write_addr(exec_physical_write_addr),
                        .exec_write(exec_res),
                        
                        .mem_wb_reg(dmem_wb_reg),
                        .mem_write_addr(dmem_physical_write_addr),
                        .mem_write(dmem_write),

                        .wb_wb_reg(wb_wb_reg),
                        .wb_write_addr(wb_physical_write_addr),
                        .wb_write(wb_write),

                        .dec_rs_override(forwarded_rs_data),
                        .dec_rt_override(forwarded_rt_data));
    
    pipeline #(.DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH),
               .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                ppl(.clk(clk),
                    .rst_n(rst_n),
                    
                    .external_done(external_done),
                    .done(done),
                    
                    .regfile_stall(regfile_stall),
                    
                    .fetch_done(imem_data_valid),

                    .dec_rs_addr(dec_prs_addr),
                    .dec_rt_addr(dec_prt_addr),
                    .decode_branch(dec_branch),
                    
                    .exec_physical_write_addr(exec_physical_write_addr),
                    .exec_mem_enable(exec_mem_enable),
                    .exec_wb_reg(exec_wb_reg),
                    .exec_take_branch(exec_take_branch),
                    .exec_branch_target(exec_branch_target),
                    
                    .mem_done(dmem_done),
                    
                    .fetch_stall(pipe_fetch_stall),
                    .fetch_flush(pipe_fetch_flush),

                    .decode_stall(pipe_decode_stall),
                    .decode_flush(pipe_decode_flush),

                    .exec_stall(pipe_exec_stall),
                    .exec_flush(pipe_exec_flush),

                    .mem_stall(pipe_mem_stall),
                    .mem_flush(pipe_mem_flush),

                    .wb_stall(pipe_wb_stall),
                    .wb_flush(pipe_wb_flush),

                    .global_flush(pipe_global_flush),

                    .fetch_branch(fetch_rw),
                    .fetch_branch_target(fetch_write));
endmodule
