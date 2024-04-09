#ifndef _ENV_PHYSICAL_MULTI_CORE_H
	
#define _ENV_PHYSICAL_MULTI_CORE_H
#include "riscv_test.h"
#include "test_macros.h"
#undef RISCV_MULTICORE_DISABLE
#define RISCV_MULTICORE_DISABLE

#endif

#include "cpp_command_macros.h"
#include "rfpc_cmd_defines.h"
#include "test_macros.h"

#define zero             x0
#define cppcmd_data_ref  x3
#define loop_count       x4
#define group_num        x5
#define cl_num           x6
#define temp_data_1      x7
#define address          x8
#define xfer             x9
#define hart_id          x10

#define data_rand1a      x12
#define data_rand2a      x13
#define data_rand3a      x14
#define data_rand4a      x15

#define temp_data        x16

#define data_rand1b      x17
#define data_rand2b      x18
#define data_rand3b      x19
#define data_rand4b      x20

#define remainder        x21
#define four             x22
#define three            x23
#define two              x24
#define one              x25

#define expect1          x26
#define expect2          x27
#define expect3          x30
#define expect4          x31


.equ NUM_OPERATIONS, 20
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

RVTEST_RV64U 
RVTEST_CODE_BEGIN

LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 1024 byte of address space

ADD address, group_num, zero


LI four,  4
LI three, 3
LI two,   2
LI one,   1

NOP
NOP
NOP

###****************************************
###XOR
###****************************************

LI loop_count, NUM_OPERATIONS
xor_loop:

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
LI data_rand1a, 0xFFFFFFFFFFFFFFFF
LI data_rand2a, 0xFFFFFFFFFFFFFFFF
LI data_rand3a, 0xFFFFFFFFFFFFFFFF
LI data_rand4a, 0xFFFFFFFFFFFFFFFF

LI xfer, CPP_MEM_ADDR

##store the random data to cpp memory
ADD temp_data, zero, data_rand1a
SD  temp_data, 0x0(xfer)
ADD temp_data, zero, data_rand2a
SD  temp_data, 0x8(xfer)
ADD temp_data, zero, data_rand3a
SD  temp_data, 0x10(xfer)
ADD temp_data, zero, data_rand4a
SD  temp_data, 0x18(xfer)

#LD data_rand2a,0x0(xfer)
#LD data_rand2a,0x8(xfer)
#LD data_rand3a,0x10(xfer)
#LD data_rand4a,0x18(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
LI data_rand1b, 0x0000000100000001
LI data_rand2b, 0xFFFFFFFF00000010
LI data_rand3b, 0xFFFFFFFF00000100
LI data_rand4b, 0xFFFFFFFF00001000

#store the random data to cpp memory
ADD temp_data, zero, data_rand1b
SD  temp_data, 0x20(xfer)
ADD temp_data, zero, data_rand2b
SD  temp_data, 0x28(xfer)
ADD temp_data, zero, data_rand3b
SD  temp_data, 0x30(xfer)
ADD temp_data, zero, data_rand4b
SD  temp_data, 0x38(xfer)

#LD data_rand1b,0x20(xfer)
#LD data_rand2b,0x28(xfer)
#LD data_rand3b,0x30(xfer)
#LD data_rand4b,0x38(xfer)

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, zero,  xor_1_7
BEQ remainder, one,   xor_2_6
BEQ remainder, two,   xor_3_5
BEQ remainder, three, xor_4_4

xor_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, xor_expect

xor_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, xor_expect

xor_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 5 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, xor_expect

xor_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_xor(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);


xor_expect:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);

#calculate the expected values

XOR expect1, data_rand1a, data_rand1b
XOR expect2, data_rand2a, data_rand2b
XOR expect3, data_rand3a, data_rand3b
XOR expect4, data_rand4a, data_rand4b

LD  temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LD  temp_data, 0x10(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x18(xfer)
BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, xor_loop

test_passed:
pass:		
test_done:
  J test_passed
test_failed:		
fail:
  J test_failed

	
end_the_test:
   
rv_test_loop:
  J rv_test_loop

	
RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END      



