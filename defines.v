`define XILINX_SIM
`ifdef XILINX_SIM

`define DEBUG_ALU
`define DEBUG_INST
`define DEBUG_DATA
`define DEBUG_ALU
`define DEBUG_DEC
`define DEBUG_BRAM
`define DEBUG_MEMCTRL
`define DEBUG_REG

`define DEBUG_MODE

`ifdef DEBUG_MODE
    `define DEBUG 1
`else
    `define DEBUG 0
`endif

`endif

`define TRUE 1
`define FALSE 0

/**************
 *            *
 *   Decode   *
 *            *
 **************/

`define RS_EN 1
`define RS_DIS 0

`define RT_EN 1
`define RT_DIS 0

`define EX_NOP 0
`define EX_ALU 1
`define EX_IPU 2
`define EX_FPU 3

`define B_REG 0
`define B_IMM 1

`define MEM_WORD 2'b00
`define MEM_HALF 2'b01
`define MEM_BYTE 2'b10

`define MEM_READ 0
`define MEM_WRITE 1

`define MEM_EN 1
`define MEM_DIS 0

`define SIGN_EXT 1
`define ZERO_EXT 0

`define WB_ALU 0
`define WB_MEM 1

`define REG_WB 1
`define REG_N 0

`define JUMP_REG 2
`define JUMP 1
`define JUMP_N 0

`define BR 1
`define BR_N 0

`define TRAP 1
`define TRAP_N 0

`define TEST_PASS 0
`define TEST_FAIL 1
`define TEST_DONE 2

/*****************
 *               *
 *      Bus      *
 *               *
 *****************/
`define DATA_BUS DATA_WIDTH-1:0
`define ADDR_BUS ADDR_WIDTH-1:0
`define VREG_BUS REG_ADDR_WIDTH-1:0
`define PREG_BUS REG_ADDR_WIDTH:0

/******************
 *                *
 *   Prediction   *
 *                *
 ******************/
 
`define PREDICT_BIMODAL 0
`define PREDICT_LOCAL 1
`define PREDICT_GSHARE 2

/**************************
 *                        *
 *   Exec Stage Op-code   *
 *                        *
 **************************/

`define ALU_OP_WIDTH 5
`define ALU_OP_BUS `ALU_OP_WIDTH-1:0

`define IPU_OP_MFHI 5'b00100
`define IPU_OP_MTHI 5'b00101
`define IPU_OP_MFLO 5'b00110
`define IPU_OP_MTLO 5'b00111
`define IPU_OP_MUL  5'b01000
`define IPU_OP_MULU 5'b01001
`define IPU_OP_DIV  5'b01010
`define IPU_OP_DIVU 5'b01011

`define FPU_OP_ADDS 5'b00001
`define FPU_OP_SUBS 5'b00010
`define FPU_OP_MULS 5'b00011
`define FPU_OP_DIVS 5'b00100
`define FPU_OP_SQRTS 5'b00101
`define FPU_OP_ROUNDS 5'b00110
`define FPU_OP_TRUNCS 5'b00111
`define FPU_OP_CEILS 5'b01110
`define FPU_OP_FLOORS 5'b01111

`define FPU_OP_CEQS 5'b01000
`define FPU_OP_CNES 5'b01001
`define FPU_OP_CLTS 5'b01010
`define FPU_OP_CLES 5'b01011
`define FPU_OP_CGTS 5'b01100
`define FPU_OP_CGES 5'b01101

//`define FPU_OP_ADDD 5'b10001
//`define FPU_OP_SUBD 5'b10010
//`define FPU_OP_MULD 5'b10011
//`define FPU_OP_DIVD 5'b10100
//`define FPU_OP_SQRTD 5'b10101
//`define FPU_OP_ROUNDD 5'b10110
//`define FPU_OP_TRUNCD 5'b10111
//`define FPU_OP_CEILD 5'b11110
//`define FPU_OP_FLOORD 5'b11111

`define FPU_OP_CEQD 5'b11000
`define FPU_OP_CNED 5'b11001
`define FPU_OP_CLTD 5'b11010
`define FPU_OP_CLED 5'b11011
`define FPU_OP_CGTD 5'b11100
`define FPU_OP_CGED 5'b11101
    
`define ALU_OP_NOP  5'b00000
`define ALU_OP_SLL  5'b00000
`define ALU_OP_SRL  5'b00001
`define ALU_OP_SRA  5'b00010
//`define ALU_OP_?? 5'b00011
//`define ALU_OP_?? 5'b00100
//`define ALU_OP_?? 5'b00101
`define ALU_OP_MFHI 5'b00110
`define ALU_OP_MFLO 5'b00111
`define ALU_OP_MUL  5'b01000
`define ALU_OP_MULU 5'b01001
`define ALU_OP_DIV  5'b01010
`define ALU_OP_DIVU 5'b01011
`define ALU_OP_ADD  5'b01100
`define ALU_OP_ADDU 5'b01101
`define ALU_OP_SUB  5'b01110
`define ALU_OP_SUBU 5'b01111
`define ALU_OP_AND  5'b10000
`define ALU_OP_OR   5'b10001
`define ALU_OP_XOR  5'b10010
`define ALU_OP_NOR  5'b10011
`define ALU_OP_SLT  5'b10100
`define ALU_OP_SLTU 5'b10101
`define ALU_OP_LU   5'b10110
//`define ALU_OP_?? 5'b10111
//`define ALU_OP_?? 5'b11000
//`define ALU_OP_?? 5'b11001
`define ALU_OP_LE   5'b11010
`define ALU_OP_GT   5'b11011
`define ALU_OP_EQ   5'b11100
`define ALU_OP_NE   5'b11101
`define ALU_OP_LT   5'b11110
`define ALU_OP_GE   5'b11111


/********************
 *                  *
 *   Instructions   *
 *                  *
 ********************/

`define INST_WIDTH 7
`define INST_BUS `INST_WIDTH-1:0

`define INST_ADDS 7'b1000001
`define INST_SUBS 7'b1000010
`define INST_MULS 7'b1000011
`define INST_DIVS 7'b1000100
`define INST_SQRTS 7'b1000101
`define INST_ROUNDS 7'b1000110
`define INST_TRUNCS 7'b1000111
`define INST_CEILS 7'b1001110
`define INST_FLOORS 7'b1001111

`define INST_CEQS 7'b1001000
`define INST_CNES 7'b1001001
`define INST_CLTS 7'b1001010
`define INST_CLES 7'b1001011
`define INST_CGTS 7'b1001100
`define INST_CGES 7'b1001101

//`define INST_ADDD 7'b1010001
//`define INST_SUBD 7'b1010010
//`define INST_MULD 7'b1010011
//`define INST_DIVD 7'b1010100
//`define INST_SQRTD 7'b1010101
//`define INST_ROUNDD 7'b1010110
//`define INST_TRUNCD 7'b1010111
//`define INST_CEILD 7'b1011110
//`define INST_FLOORD 7'b1011111

`define INST_CEQD 7'b1011000
`define INST_CNED 7'b1011001
`define INST_CLTD 7'b1011010
`define INST_CLED 7'b1011011
`define INST_CGTD 7'b1011100
`define INST_CGED 7'b1011101
    
`define INST_NOP  7'b0000000

`define INST_SLL  7'b0000000
`define INST_SRL  7'b0000001
`define INST_SRA  7'b0000010

//`define INST_??? 7'b0000011
//`define INST_??? 7'b0000100
//`define INST_??? 7'b0000101

`define INST_MFHI 7'b0000110
`define INST_MFLO 7'b0000111
`define INST_MUL  7'b0001000
`define INST_MULU 7'b0001001
`define INST_DIV  7'b0001010
`define INST_DIVU 7'b0001011

`define INST_ADD  7'b0001100
`define INST_ADDU 7'b0001101
`define INST_SUB  7'b0001110
`define INST_SUBU 7'b0001111
`define INST_AND  7'b0010000
`define INST_OR   7'b0010001
`define INST_XOR  7'b0010010
`define INST_NOR  7'b0010011

`define INST_SLT  7'b0010100
`define INST_SLTU 7'b0010101

`define INST_LU   7'b0010110

`define INST_TEST_PASS 7'b0010111
`define INST_TEST_FAIL 7'b0011000
`define INST_TEST_DONE 7'b0011001

`define INST_BLE  7'b0011010
`define INST_BGT  7'b0011011
`define INST_BEQ  7'b0011100
`define INST_BNE  7'b0011101
`define INST_BLT  7'b0011110
`define INST_BGE  7'b0011111

`define INST_LB   7'b0100000
`define INST_LBU  7'b0100001
`define INST_LH   7'b0100010
`define INST_LHU  7'b0100011
`define INST_LW   7'b0100100
`define INST_LWL  7'b0100101
`define INST_LWR  7'b0100110

`define INST_SB   7'b0101000
`define INST_SH   7'b0101001
`define INST_SW   7'b0101010
`define INST_SWL  7'b0101011
`define INST_SWR  7'b0101100

`define INST_J    7'b0101101
`define INST_JAL  7'b0101110
`define INST_JR   7'b0101111
`define INST_JALR 7'b0100111

`define INST_TEQ  7'b0110000
`define INST_TGE  7'b0110001
`define INST_TGEU 7'b0110010
`define INST_TLT  7'b0110011
`define INST_TLTU 7'b0110100
`define INST_TNE  7'b0110101

`define INST_MTC0 7'b0111110
`define INST_MFC0 7'b0111111