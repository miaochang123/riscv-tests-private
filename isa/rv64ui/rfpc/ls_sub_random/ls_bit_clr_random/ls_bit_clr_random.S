###****************************************
### TEST_NAME: bit_clr_random.S
###****************************************

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

# OK for data_rand1b2 to share register x31
#define data_rand1b2     x31

#define remainder        x21
#define four             x22
#define three            x23
#define two              x24
#define one              x25

#define expect1          x26
#define expect2          x27
#define expect3          x30
#define expect4          x31

#define mask             x1
#define sign_extend_or   x29

# sign_extend share 27
#define sign_extend      x27


.equ NUM_OPERATIONS, 20
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

RVTEST_RV64U
RVTEST_CODE_BEGIN


#LI x6, 0x6000
#ADD sign_extend_mask, zero, x6 # sign_extend_mask = 0x0000_6000
LI x6, 0xC000
ADD sign_extend_or, zero, x6
LI x6, 0xFFFF
SLLI x6, x6, 16
OR sign_extend_or, sign_extend_or, x6 # sign_extend_or = 0xFFFF_C000


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
###CLR
###****************************************

LI loop_count, NUM_OPERATIONS
clr_loop:

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
###data_rand1a      x12
###data_rand2a      x13
###data_rand3a      x14
###data_rand4a      x15
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

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

##cls[write,$xfer0,address,0,8], ctx_swap[sig1]
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
#
#ADD address, group_num, zero # set to initial value
#WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
###data_rand1b      x17
###data_rand2b      x18
###data_rand3b      x19
###data_rand4b      x20
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

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, zero,  clr_1_7
BEQ remainder, one,   clr_2_6
BEQ remainder, two,   clr_3_5
BEQ remainder, three, clr_4_4

clr_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, clr_expect

clr_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, clr_expect

clr_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 5 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, clr_expect

clr_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_clr(cppcmd_data_ref);# cls_clr for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);


clr_expect:

#cls[read_le,$xfer0,address,0,8], ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#calculate the expected values
NOT data_rand1b, data_rand1b
AND expect1, data_rand1a, data_rand1b
NOT data_rand2b, data_rand2b
AND expect2, data_rand2a, data_rand2b
NOT data_rand3b, data_rand3b
AND expect3, data_rand3a, data_rand3b
NOT data_rand4b, data_rand4b
AND expect4, data_rand4a, data_rand4b

LD  temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LD  temp_data, 0x10(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x18(xfer)
BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, clr_loop


###****************************************
###TEST_AND_CLR
###****************************************

LI loop_count, NUM_OPERATIONS
test_and_clr_loop:

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
###data_rand1a      x12
###data_rand2a      x13
###data_rand3a      x14
###data_rand4a      x15
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

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

##cls[write,$xfer0,address,0,8], ctx_swap[sig1]
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
#
#ADD address, group_num, zero # set to initial value
#WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
###data_rand1b      x17
###data_rand2b      x18
###data_rand3b      x19
###data_rand4b      x20
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

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, zero,  test_and_clr_1_7
BEQ remainder, one,   test_and_clr_2_6
BEQ remainder, two,   test_and_clr_3_5
BEQ remainder, three, test_and_clr_1_7

test_and_clr_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

BEQZ zero, test_and_clr_expect

test_and_clr_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

BEQZ zero, test_and_clr_expect

test_and_clr_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 5 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

BEQZ zero, test_and_clr_expect

test_and_clr_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_test_clr(cppcmd_data_ref);# cls_test_clr for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);


test_and_clr_expect:

#compare the returned data with the previous
LD  temp_data, 0x20(xfer)
BNE temp_data, data_rand1a, test_failed
LD  temp_data, 0x28(xfer)
BNE temp_data, data_rand2a, test_failed
LD  temp_data, 0x30(xfer)
BNE temp_data, data_rand3a, test_failed
LD  temp_data, 0x38(xfer)
BNE temp_data, data_rand4a, test_failed

#cls[read_le,$xfer0,address,0,8], ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#calculate the expected values
NOT data_rand1b, data_rand1b
AND expect1, data_rand1a, data_rand1b
NOT data_rand2b, data_rand2b
AND expect2, data_rand2a, data_rand2b
NOT data_rand3b, data_rand3b
AND expect3, data_rand3a, data_rand3b
NOT data_rand4b, data_rand4b
AND expect4, data_rand4a, data_rand4b

LD  temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LD  temp_data, 0x10(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x18(xfer)
BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, test_and_clr_loop


###****************************************
###CLR_IMM
###****************************************
#  Bits [15:14] 00 Zero extend 
#               01 Sign extend
#               10 Zero extend and duplicate (makes no sense for len=1 32 bit ops)
#               11 Sign extend and duplicate (makes no sense for len=1 32 bit ops)
# So if bit 13 and 14 are set then we will sign extend 1's

#LI loop_count, NUM_OPERATIONS
#clr_imm_loop:

###Now 1 32-bit pseudo_random_number should be created
###data_rand1a      x12
LI data_rand1a, 0xFFFFFFFFFFFFFFFF

LI xfer, CPP_MEM_ADDR

##store the random data to cpp memory
ADD temp_data, zero, data_rand1a
SD  temp_data, 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 1 32-bit pseudo_random_number should be created
###data_rand1b      x17
LI data_rand1b, 0x0000000060000010

LI mask, 0xFFFF
AND data_rand1b2, data_rand1b, mask
#SLLI rand_data1b2, rand_data1b2, 16
#override data_master/data_ref
#SLLI two, two, 3
#OR temp_data, rand_data1b2, two

# override flag, see EAS_rfpc Table 2.12
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x40,0x0,0x0);
OR cppcmd_data_ref, cppcmd_data_ref, data_rand1b2 # override rs1[15:0]
.insn s 43,0,address,cluster_scratch_clr_imm(cppcmd_data_ref);# cls_clr_imm

ADD address, group_num, zero # set to initial value
#WAIT_ON_SIGNAL (SIG1_pos,1);

SRLI sign_extend, data_rand1b, 13
ANDI sign_extend, data_rand1b, 3
LI mask, 0x3FFF
AND data_rand1b, data_rand1b, mask
AND data_rand1b2, data_rand1b, mask

BNE sign_extend, three, clr_expect_imm
OR data_rand1b2, data_rand1b, sign_extend_or


clr_expect_imm:

LI mask, 0xFFFFFFFF
NOT data_rand1b2, data_rand1b2
AND expect1, data_rand1a, data_rand1b2
AND expect1, expect1, mask

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

LW  temp_data, 0x0(xfer)
AND temp_data, temp_data, mask
BNE temp_data, expect1, test_failed

#SUB loop_count, loop_count, one
#BNE loop_count, zero, clr_imm_loop


###****************************************
###TEST_AND_CLR_IMM
###****************************************
#  Indirect length goes in bits [4:0]

#LI loop_count, NUM_OPERATIONS
#test_and_clr_imm_loop:

###Now 1 32-bit pseudo_random_number should be created
###data_rand1a      x12
LI data_rand1a, 0xFFFFFFFFFFFFFFFF

LI xfer, CPP_MEM_ADDR

##store the random data to cpp memory
ADD temp_data, zero, data_rand1a
SD  temp_data, 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 1 32-bit pseudo_random_number should be created
###data_rand1b      x17
LI data_rand1b, 0x0000000060000010

# Using length field (5 bits) as immediate data
LI mask, 0x1F
AND data_rand1b2, data_rand1b, mask
NOT data_rand1b2, data_rand1b2
LI mask, 0xFFFFFFFF
AND temp_data, data_rand1a, mask
AND expect1, temp_data, data_rand1b2

# override length
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10);
AND data_rand1b2, data_rand1b, mask
SLLI data_rand1b2, data_rand1b2, 16
OR cppcmd_data_ref, cppcmd_data_ref, data_rand1b2
.insn s 43,0,address,cluster_scratch_test_clr_imm(cppcmd_data_ref);# cls_test_clr_imm

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#compare the returned data with the previous
LI mask, 0xFFFFFFFF
LW  temp_data, 0x10(xfer)
AND temp_data, temp_data, mask
AND data_rand1a, data_rand1a, mask
BNE temp_data, data_rand1a, test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

LW  temp_data, 0x0(xfer)
AND temp_data, temp_data, mask

## for debug
#SD  expect1, 0x20(xfer)
#SD  temp_data, 0x28(xfer)
#
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
#
#ADD address, group_num, zero # set to initial value
#WAIT_ON_SIGNAL (SIG1_pos,1);


BNE temp_data, expect1, test_failed

#SUB loop_count, loop_count, one
#BNE loop_count, zero, test_and_clr_imm_loop




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
