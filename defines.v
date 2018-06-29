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

`define MEM_WORD 0
`define MEM_HALF 1
`define MEM_BYTE 2

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

`define JMP_REG 2
`define JMP 1
`define JMP_N 0

`define BR 1
`define BR_N 0

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
`define ALU_OP_BUS ALU_OP_WIDTH-1:0
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
//`define ALU_OP_??? 5'b00011
//`define ALU_OP_??? 5'b00100
//`define ALU_OP_??? 5'b00101
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
`define ALU_OP_LU  5'b10110
`define ALU_OP_TEST_PASS 5'b10111
`define ALU_OP_TEST_FAIL 5'b11000
`define ALU_OP_TEST_DONE 5'b11001
`define ALU_OP_BLE  5'b11010
`define ALU_OP_BGT  5'b11011
`define ALU_OP_BEQ  5'b11100
`define ALU_OP_BNE  5'b11101
`define ALU_OP_BLT  5'b11110
`define ALU_OP_BGE  5'b11111