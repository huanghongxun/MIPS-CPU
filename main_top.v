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

`include "defines.v"

module main_top(
    input clk, // 100MHz clock signal

    input [15:0] sw, // switches
    input [15:0] LED, // LEDs

    // buttons
    input btn0,
    input btn1,
    input btnL,
    input btnR,
    input btnD,

    // USB-RS232 UART interface
    input RxD,
    output TxD,

    // Quad SPI Flash
    inout [3:0] QspiDB,
    output QspiCSn,
    output QspiSCK
    );

    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 16;
    localparam REG_ADDR_WIDTH = 5;
    localparam ALU_OP_WIDTH = 5;
    localparam FREE_LIST_WIDTH = 3;
    localparam CHECKPOINT_WIDTH = 2;

    // Block memory generator

    wire bram_ena;
    wire bram_wea;
    wire [ADDR_WIDTH-1:0] bram_addra;
    wire [DATA_WIDTH-1:0] bram_dina;
    wire [DATA_WIDTH-1:0] bram_douta;

    bram_basys3 bram_internal(.clk(clk),
                              .ena(bram_ena),
                              .wea(bram_wea),
                              .addra(bram_addra),
                              .dina(bram_dina),
                              .douta(bram_douta));
    
    wire rst_n = sw[15];

    wire pipe_fetch_stall;
    wire fetch_rw;
    wire [ADDR_WIDTH-1:0] fetch_write;
    wire [ADDR_WIDTH-1:0] fetch_pc;

    wire imem_ready;
    wire [DATA_WIDTH-1:0] imem_data;
    wire imem_data_valid;

    // fetch2dec

    wire pipe_fetch_flush;
    wire pipe_decode_stall;
    wire dec_bubble;

    wire [ADDR_WIDTH-1:0] dec_pc;
    wire [DATA_WIDTH-1:0] dec_inst;
    wire [ALU_OP_WIDTH-1:0] dec_alu_op;
    wire dec_alu_en;
    wire dec_b_ctrl;
    wire [DATA_WIDTH-1:0] dec_imm;
    wire dec_wb_src;
    wire dec_wb_reg;

    // dec2exec

    wire pipe_decode_flush;
    wire pipe_exec_stall;

    wire exec_mem_width;
    wire exec_mem_rw;
    wire exec_mem_enable;
    wire exec_sign_extend;
    wire exec_wb_src;
    wire exec_wb_reg;
    wire exec_branch;
    wire [ADDR_WIDTH-1:0] exec_branch_target;

    wire [ADDR_WIDTH-1:0] exec_pc;

    wire [ALU_OP_WIDTH-1:0] alu_op;
    
    wire [DATA_WIDTH-1:0] alu_rs;
    wire [DATA_WIDTH-1:0] alu_rt;
    wire [DATA_WIDTH-1:0] alu_rd;

    // exec2mem

    wire pipe_exec_flush;
    wire pipe_mem_stall;

    wire [DATA_WIDTH-1:0] dmem_res;
    wire [DATA_WIDTH-1:0] dmem_mem_write;
    wire [DATA_WIDTH-1:0] dmem_write;
    wire dmem_req_op;
    wire dmem_mem_width;
    wire dmem_sign_extend;
    wire dmem_mem_rw;
    wire dmem_wb_src;
    wire dmem_wb_reg;
    wire dmem_done;
    
    // ram

    wire [ADDR_WIDTH-1:0] ram_addr;
    wire ram_req_op;
    wire ram_rw;
    wire [DATA_WIDTH-1:0] ram_write;
    wire ram_write_req_input;
    wire [DATA_WIDTH-1:0] ram_read;
    wire ram_read_valid;
    wire ram_last;

    // memctrl

    wire [ADDR_WIDTH-1:0] memctrl_imem_addr;
    wire memctrl_imem_req_op;
    wire [DATA_WIDTH-1:0] memctrl_imem_read;
    wire memctrl_imem_read_valid;
    wire memctrl_imem_last;

    wire [ADDR_WIDTH-1:0] memctrl_dmem_addr;
    wire memctrl_dmem_req_op;
    wire memctrl_dmem_rw;
    wire [DATA_WIDTH-1:0] memctrl_dmem_write;
    wire memctrl_dmem_req_data;
    wire [DATA_WIDTH-1:0] memctrl_dmem_read;
    wire memctrl_dmem_read_valid;
    wire memctrl_dmem_last;

    wire [ADDR_WIDTH-1:0] memctrl_flash_addr;
    wire memctrl_flash_req_op;
    wire [DATA_WIDTH-1:0] memctrl_flash_write;
    wire memctrl_flash_req_data;
    wire memctrl_flash_last;
    
    fetch_unit fetch(.clk(clk),
                     .rst_n(rst_n),
                     .stall(pipe_fetch_stall),
                     
                     .rw(fetch_rw),
                     .write(fetch_write),
                     
                     .pc(fetch_pc));

    inst_cache#(.DATA_WIDTH(DATA_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH))
                icache(.clk(clk),
                       .rst_n(rst_n),

                       // request
                       .addr(fetch_pc),
                       .req_op(flashloader_done),

                       .ready(imem_ready),
                       .data(imem_data),
                       .data_valid(imem_data_valid),
                       
                       .mem_addr(memctrl_imem_addr),
                       .mem_req_op(memctrl_imem_req_op),
                       
                       .mem_read(memctrl_imem_read),
                       .mem_read_valid(memctrl_imem_read_valid),
                       .mem_last(memctrl_imem_last));

    pipeline_fetch2dec #(.DATA_WIDTH(DATA_WIDTH),
                         .ADDR_WIDTH(ADDR_WIDTH))
                    pfd(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_fetch_flush),
                        .stall(pipe_decode_stall),
                        
                        .pc_in(fetch_pc),
                        .pc_out(dec_pc),
                        .inst_in(imem_data),
                        .inst_out(dec_inst),
                        .bubble_in(imem_data_valid),
                        .bubble_out(dec_bubble));
                            
    decoder #(.DATA_WIDTH(DATA_WIDTH),
              .ADDR_WIDTH(ADDR_WIDTH),
              .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
              .ALU_OP_WIDTH(ALU_OP_WIDTH))
                decode(.pc(dec_pc),
                        .inst(dec_inst),
                        .op(decoder_op),
                        .rs(dec_rs_addr),
                        .rt(dec_rt_addr),
                        .rd(dec_virtual_write_addr),
                        .imm(decoder_imm),
                        .func(dec_alu_op),
                        .addr(dec_addr),
                        .uses_alu(dec_alu_en),
                        .b_ctrl(dec_b_ctrl),
                        .mem_width(dec_mem_width),
                        .mem_rw(dec_mem_rw),
                        .mem_enable(dec_mem_enable),
                        .sign_extend(dec_sign_extend),
                        .wb_src(dec_wb_src),
                        .wb_reg(dec_wb_reg),
                        .jump(dec_jump),
                        .branch(dec_branch));
                          

    register_file #(.DATA_WIDTH(DATA_WIDTH),
                       .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
                       .FREE_LIST_WIDTH(FREE_LIST_WIDTH))
                    regfile(.clk(clk),
                            .rst_n(rst_n),
                            .stall_in(pipe_decode_stall),

                            .virtual_rs_addr(dec_rs_addr),
                            .virtual_rs_data(dec_rs_data),
                            .virtual_rt_addr(dec_rt_addr),
                            .virtual_rt_data(dec_rt_data),
                            .dec_rw(dec_rw),
                            .virtual_rd_addr(dec_rd_addr),
                            
                            .mem_write_enable(wb_wb_reg && !pipe_wb_flush),
                            .wb_physical_write_addr(wb_physical_write_addr),
                            .wb_physical_write_data(wb_write),
                            .wb_virtual_write_addr(wb_virtual_write_addr),
                            .wb_active_list_index(wb_active_list_index),

                            .physical_rs_addr(dec_prs_addr),
                            .physical_rt_addr(dec_prt_addr),
                            .physical_rd_addr(dec_physical_write_addr),

                            .active_list_index(dec_active_list_index),
                            
                            .stall_out(regfile_stall));

    pipeline_dec2exec #(.DATA_WIDTH(DATA_WIDTH),
                        .ADDR_WIDTH(ADDR_WIDTH),
                        .REG_ADDR_WIDTH(REG_ADDR_WIDTH),
                        .ALU_OP_WIDTH(ALU_OP_WIDTH))
                    pde(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_decode_flush),
                        .stall(pipe_exec_stall),
                        
                        .pc_in(dec_pc),
                        .pc_out(exec_pc),
                        .inst_in(dec_inst),
                        .inst_out(exec_inst),
                        .alu_op_in(dec_alu_op),
                        .alu_op_out(alu_op),
                        .alu_en_in(dec_alu_en),
                        .alu_en_out(exec_alu_en),
                        .alu_rs_in(forwarded_rs_data),
                        .alu_rs_out(alu_rs),
                        .alu_rt_in(dec_b_ctrl ? dec_imm : forwarded_rt_data),
                        .alu_rt_out(alu_rt),
                        .mem_width_in(dec_mem_width),
                        .mem_width_out(exec_mem_width),
                        .mem_rw_in(dec_mem_rw),
                        .mem_rw_out(exec_mem_rw),
                        .mem_enable_in(dec_mem_enable),
                        .mem_enable_out(exec_mem_enable),
                        .sign_extend_in(dec_sign_extend),
                        .sign_extend_out(exec_sign_extend),
                        .wb_src_in(dec_wb_src),
                        .wb_src_out(exec_wb_src),
                        .wb_reg_in(dec_wb_reg),
                        .wb_reg_out(exec_wb_reg),
                        .branch_in(dec_branch),
                        .branch_out(exec_branch),
                        .branch_target_in(dec_jump == `JMP_REG ? forwarded_rs_data[ADDR_WIDTH-1:0] : dec_addr),
                        .branch_target_out(exec_branch_target),
                        .virtual_write_addr_in(dec_virtual_write_addr),
                        .virtual_write_addr_out(exec_virtual_write_addr),
                        .physical_write_addr_in(dec_physical_write_addr),
                        .physical_write_addr_out(exec_physical_write_addr),
                        .active_list_index_in(dec_active_list_index),
                        .active_list_index_out(exec_active_list_index));
                         
    arithmetic_logic_unit #(.DATA_WIDTH(DATA_WIDTH),
                            .ALU_OP_WIDTH(ALU_OP_WIDTH))
                    alu(.pc(exec_pc),
                        .en(exec_alu_en),
                        .op(alu_op),
                        .rs(alu_rs),
                        .rt(alu_rt),
                        .rd(alu_rd),
                        .branch(alu_branch));

    pipeline_exec2mem #(.DATA_WIDTH(DATA_WIDTH),
                        .ADDR_WIDTH(ADDR_WIDTH),
                        .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                    pem(.clk(clk),
                        .rst_n(rst_n),
                        .flush(pipe_exec_flush),
                        .stall(pipe_mem_stall),
                        
                        .pc_in(exec_pc),
                        .pc_out(dmem_pc),
                        .inst_in(exec_inst),
                        .inst_out(dmem_inst),
                        .alu_res_in(alu_rd),
                        .alu_res_out(dmem_res),
                        .mem_width_in(exec_mem_width),
                        .mem_width_out(dmem_mem_width),
                        .sign_extend_in(exec_sign_extend),
                        .sign_extend_out(dmem_sign_extend),
                        .mem_rw_in(exec_mem_rw),
                        .mem_rw_out(dmem_mem_rw),
                        .mem_enable_in(exec_mem_enable),
                        .mem_enable_out(dmem_mem_enable),
                        .mem_write_in(exec_mem_),
                        .mem_write_out(dmem_mem_write),
                        .wb_src_in(exec_wb_src),
                        .wb_src_out(dmem_wb_src),
                        .wb_reg_in(exec_wb_reg),
                        .wb_reg_out(dmem_wb_reg),
                        .branch(exec_branch),
                        .branch(dmem_branch),
                        .virtual_write_addr_in(exec_virtual_write_addr),
                        .virtual_write_addr_out(dmem_virtual_write_addr),
                        .physical_write_addr_in(exec_physical_write_addr),
                        .physical_write_addr_out(dmem_physical_write_addr),
                        .active_list_index_in(exec_active_list_index),
                        .active_list_index_out(dmem_active_list_index));

    always @*
    begin
        if (dmem_wb_src == `WB_ALU)
        begin
            dmem_write <= dmem_res;
            dmem_done <= 1;
        end
        else if (dmem_wb_src == `WB_MEM)
        begin
            dmem_write <= dmem_mem_read;
            dmem_done <= dmem_mem_read_valid;
        end
    end

    bram_controller ram(.clk(clk),
                        .rst_n(rst_n),

                        .addr(ram_addr),
                        .req_op(ram_req_op),
                        .rw(ram_rw),

                        .data_write(ram_data_write),
                        .data_write_req_input(ram_data_write_req_input),

                        .data_read(ram_data_read),
                        .data_read_valid(ram_data_read_valid),

                        .last(ram_last),

                        // BRAM interface
                        .ena(bram_ena),
                        .wea(bram_wea),
                        .addra(bram_addra),
                        .dina(bram_dina),
                        .douta(bram_douta)
                        );
    
    
    data_cache #(.DATA_WIDTH(DATA_WIDTH),
                 .ADDR_WIDTH(ADDR_WIDTH))
                dcache(.clk(clk),
                       .rst_n(rst_n),
                       
                       .addr(dmem_res[ADDR_WIDTH+1:2]),
                       .req_op(dmem_req_op),
                       .rw(dmem_mem_rw),

                       .mem_width(dmem_mem_width),
                       .sign_extend(dmem_sign_extend),
                       
                       .write(dmem_mem_write),
                       .read(dmem_mem_read),
                       .read_valid(dmem_mem_read_valid),
                       
                       .ready(dmem_ready),
                       
                       .mem_addr(memctrl_dmem_addr),
                       .mem_req_op(memctrl_dmem_req_op),
                       .mem_rw(memctrl_dmem_rw),
                       
                       .mem_read(memctrl_dmem_read),
                       .mem_read_valid(memctrl_dmem_read_valid),
                       
                       .mem_write(memctrl_dmem_write),
                       .mem_write_req_input(memctrl_dmem_write_req_input),
                       
                       .mem_last(memctrl_dmem_last));

    memory_controller #(.DATA_WIDTH(DATA_WIDTH),
                        .ADDR_WIDTH(ADDR_WIDTH))
                    memctrl(.clk(clk),
                            .rst_n(rst_n),
                            
                            .imem_addr(memctrl_imem_addr),
                            .imem_req_op(memctrl_imem_req_op),
                            
                            .imem_read(memctrl_imem_read),
                            .imem_read_valid(memctrl_imem_read_valid),

                            .imem_last(memctrl_imem_last),
                            
                            .dmem_addr(memctrl_dmem_addr),
                            .dmem_req_op(memctrl_dmem_req_op),
                            .dmem_rw(memctrl_dmem_rw),

                            .dmem_write(memctrl_dmem_write),
                            .dmem_req_data(memctrl_dmem_req_data),

                            .dmem_read(memctrl_dmem_read),
                            .dmem_read_valid(memctrl_dmem_read_valid),

                            .dmem_last(memctrl_dmem_last),

                            .flash_addr(memctrl_flash_addr),
                            .flash_req_op(memctrl_flash_req_op),

                            .flash_write(memctrl_flash_write),
                            .flash_req_data(memctrl_flash_req_data),

                            .flash_last(memctrl_flash_last),

                            .mem_addr(ram_addr),
                            .mem_req_op(ram_req_op),
                            .mem_rw(ram_rw),

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
                        .stall(pipe_wb_stall),
                        
                        .wb_reg_in(dmem_wb_reg),
                        .wb_reg_out(wb_wb_reg),
                        .wb_data_in(dmem_write),
                        .wb_data_out(wb_write),
                        .virtual_write_addr_in(dmem_virtual_write_addr),
                        .virtual_write_addr_out(wb_virtual_write_addr),
                        .physical_write_addr_in(dmem_physical_write_addr),
                        .physical_write_addr_out(wb_physical_write_addr),
                        .active_list_index_in(dmem_active_list_index),
                        .active_list_index_out(wb_active_list_index));

    forwarding_unit #(.DATA_WIDTH(DATA_WIDTH),
                      .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                forward(.dec_rs_enable(dec_rs_enable),
                        .dec_rs_addr(dec_prs_addr),
                        .dec_rs_data(dec_rs_data),
                        .dec_rt_enable(dec_rt_enable),
                        .dec_rt_addr(dec_prt_addr),
                        .dec_rt_data(dec_rt_data),

                        .exec_wb_reg(exec_wb_reg),
                        .exec_uses_alu(exec_alu_en),
                        .exec_write_addr(exec_physical_write_addr),
                        .exec_write_data(alu_rd),
                        
                        .mem_wb_reg(mem_wb_reg),
                        .mem_write_addr(dmem_physical_write_addr),
                        .mem_write_data(dmem_write),

                        .wb_wb_reg(wb_wb_reg),
                        .wb_write_addr(dec_physical_write_addr),
                        .wb_write(wb_write),

                        .dec_rs_override(forwarded_rs_data),
                        .dec_rt_override(forwarded_rt_data));
    
    pipeline #(.DATA_WIDTH(DATA_WIDTH),
               .ADDR_WIDTH(ADDR_WIDTH),
               .REG_ADDR_WIDTH(REG_ADDR_WIDTH))
                ppl(.clk(clk),
                    .rst_n(rst_n),
                    
                    .flashloader_done(flashloader_done),
                    .done(done),
                    
                    .fetch_done(imem_data_valid),

                    .dec_rs_addr(dec_prs_addr),
                    .dec_rt_addr(dec_prt_addr),
                    .decode_branch(dec_branch),
                    
                    .exec_dst(exec_physical_write_addr),
                    .exec_mem_enable(exec_mem_enable),
                    .exec_wb_reg(exec_wb_reg),
                    .exec_branch(exec_branch),
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

                    .fetch_branch(fetch_rw),
                    .fetch_branch_target(fetch_write));
endmodule
