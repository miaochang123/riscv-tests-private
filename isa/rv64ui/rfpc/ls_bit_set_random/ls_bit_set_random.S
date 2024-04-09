###****************************************
### TEST_NAME: bit_set_random.S
###
### set          : 2/0
### test_set     : 2/2
### set_imm      : 3/0 (len=0 or len!=0)
### test_set_imm : 3/2
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

#define count            x2
#define cppcmd_data_ref  x3
#define loop_count       x4
#define group_num        x5
#define cl_num           x6
#define temp_data_1      x7
#define address          x8
#define xfer             x9
#define hart_id          x10

#define  data1a        x11
#define  data2a        x12
#define  data3a        x13
#define  data4a        x14

#define  data1b        x15
#define  data2b        x16
#define  data3b        x17
#define  data4b        x18

#define  expect1       x19
#define  expect2       x20
#define  expect3       x21
#define  expect4       x22

#define remainder      x23
#define four           x24
#define three          x25
#define two            x26
#define one            x27 

#define  temp_data     x30
#define  mask          x31 

.equ NUM_OPERATIONS,    20
.equ MEM_SIZE_DIV16,    0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,      0xf0000000

RVTEST_RV64U
RVTEST_CODE_BEGIN


LI group_num, 0xf00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xff # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127

SLLI group_num , group_num, 8 #each core has 1024 byte of address space

ADD address, group_num, zero

LI xfer, CPP_MEM_ADDR  
LI four,  4
LI three, 3
LI two,   2
LI one,   1

NOP
NOP
NOP

###****************************************
###SET
###****************************************

LI loop_count, NUM_OPERATIONS
set_loop:

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
LI data1a, 0x2354ff2518423fab
LI data2a, 0xa1bd870012fbefff
LI data3a, 0x10000000FFFFFFFF
LI data4a, 0xeeeebbdd23000151

SUB data1a,data1a,loop_count
SUB data2a,data2a,loop_count
SUB data3a,data3a,loop_count
SUB data4a,data4a,loop_count

##store the random data to cpp memory
SD  data1a, 0x0(xfer)
SD  data2a, 0x8(xfer)
SD  data3a, 0x10(xfer)
SD  data4a, 0x18(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
LI data1b, 0xbbfdc34dc5325539
LI data2b, 0xFFFFFFFF00000010
LI data3b, 0x666b8932fdac2789
LI data4b, 0x11ff557700004345

ADD data1b,data1b,loop_count
ADD data2b,data2b,loop_count
ADD data3b,data3b,loop_count
ADD data4b,data4b,loop_count

#store the random data to cpp memory
SD  data1b, 0x20(xfer)
SD  data2b, 0x28(xfer)
SD  data3b, 0x30(xfer)
SD  data4b, 0x38(xfer)

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, zero,  set_1_7
BEQ remainder, one,   set_2_6
BEQ remainder, two,   set_3_5
BEQ remainder, three, set_4_4

set_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J set_expect

set_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J set_expect

set_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J set_expect

set_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_set(cppcmd_data_ref);

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

set_expect:

#cls[read_le,$xfer0,address,0,8], ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#calculate the expected values
OR expect1, data1a, data1b
OR expect2, data2a, data2b
OR expect3, data3a, data3b
OR expect4, data4a, data4b

LD  temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LD  temp_data, 0x10(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x18(xfer)
BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, set_loop


###****************************************
###TEST_AND_SET
###****************************************

LI loop_count, NUM_OPERATIONS
test_and_set_loop:

###Now 8 32-bit (4 64-bit) pseudo_random_number should be created

LI data1a, 0x2354ff2518423fab
LI data2a, 0xa1bd870012fbefff
LI data3a, 0x10000000FFFFFFFF
LI data4a, 0xeeeebbdd23000151

SUB data1a,data1a,loop_count
SUB data2a,data2a,loop_count
SUB data3a,data3a,loop_count
SUB data4a,data4a,loop_count  

##store the random data to cpp memory
SD  data1a, 0x0(xfer)
SD  data2a, 0x8(xfer)
SD  data3a, 0x10(xfer)
SD  data4a, 0x18(xfer)  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);


###Now 8 32-bit (4 64-bit) pseudo_random_number should be created
LI data1b, 0xbbfdc34dc5325539
LI data2b, 0xFFFFFFFF00000010
LI data3b, 0x666b8932fdac2789
LI data4b, 0x11ff557700004345  


#store the random data to cpp memory
SD  data1b, 0x20(xfer)
SD  data2b, 0x28(xfer)
SD  data3b, 0x30(xfer)
SD  data4b, 0x38(xfer)

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, zero,  test_and_set_1_7
BEQ remainder, one,   test_and_set_2_6
BEQ remainder, two,   test_and_set_3_5
BEQ remainder, three, test_and_set_1_7

test_and_set_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

BEQZ zero, test_and_set_expect

test_and_set_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

BEQZ zero, test_and_set_expect

test_and_set_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 5 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

BEQZ zero, test_and_set_expect

test_and_set_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_test_set(cppcmd_data_ref);# cls_test_clr for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);


test_and_set_expect:

#compare the returned data with the previous
LD  temp_data, 0x20(xfer)
BNE temp_data, data1a, test_failed
LD  temp_data, 0x28(xfer)
BNE temp_data, data2a, test_failed
LD  temp_data, 0x30(xfer)
BNE temp_data, data3a, test_failed
LD  temp_data, 0x38(xfer)
BNE temp_data, data4a, test_failed

#cls[read_le,$xfer0,address,0,8], ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#calculate the expected values
OR expect1, data1a, data1b
OR expect2, data2a, data2b
OR expect3, data3a, data3b
OR expect4, data4a, data4b

LD  temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LD  temp_data, 0x10(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x18(xfer)
BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, test_and_set_loop


##****************************************
##SET_IMM   len=0
###****************************************
#  Bits [15:14] 00 Zero extend 
#               01 Sign extend
#               10 Zero extend and duplicate (makes no sense for len=1 32 bit ops)
#               11 Sign extend and duplicate (makes no sense for len=1 32 bit ops)
# So if bit 13 and 14 are set then we will sign extend 1's

LI loop_count, NUM_OPERATIONS
LI count,10
set_imm_loop:

###Now 1 32-bit pseudo_random_number should be created

LI data1a ,0x0
LI data2a ,0x0
LI data3a ,0x0
LI data4a ,0x0

##store the random data to cpp memory
SW data1a ,0x0(xfer)
SW data2a ,0x4(xfer)
SW data3a ,0x8(xfer)
SW data4a ,0xC(xfer)  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 1 32-bit pseudo_random_number should be created

LI data1b ,0xf234
LI data2b ,0xf222 
LI data3b ,0xf111
LI data4b ,0xf332  

ADD data1b,data1b,count
ADD data2b,data2b,count 
ADD data3b,data3b,count 
ADD data4b,data4b,count 

#divide the test to 4 case bit[15:14] 00 01 10 11
REM remainder, loop_count, two
BEQ remainder, one,   bits_01_11  

bits_00_10: # Bits [15:14]  00/10 zero extend
LI  temp_data,0X1FFF
AND data1b,data1b,temp_data 
OR  expect1,data1a,data1b   #    bit15_13 = 000

LI  temp_data,0X3FFF
AND data2b,data2b,temp_data
LI  temp_data,0X2000
OR  data2b,data2b,temp_data   #   bit15_13 = 001
OR  expect2,data2a,data2b

LI  temp_data,0X1FFF
AND data3b,data3b,temp_data
OR  expect3,data3a,data3b 
LI  temp_data,0x8000
OR  data3b,data3b,temp_data #   bit15_13 = 100  


LI  temp_data,0X3FFF
AND data4b,data4b,temp_data
LI  temp_data,0X2000
OR  data4b,data4b,temp_data 
OR  expect4,data4a,data4b
LI  temp_data,0xA000
OR  data4b,data4b,temp_data  #  bit15_13 = 101


J   to_set_imm   

bits_01_11: # Bits [15:14] 01/11 Sign extend
LI  mask,0xffffffff
LI  temp_data,0x1FFF
AND data1b,data1b,temp_data 
OR  expect1,data1a,data1b 
LI  temp_data,0x4000
OR  data1b,data1b,temp_data # bit15_13 = 010

LI  temp_data,0X3FFF
AND data2b,data2b,temp_data
LI  temp_data,0xFFFFE000
OR  temp_data,data2b,temp_data
OR  expect2,data2a,temp_data 
LI  temp_data,0x6000        # bit15_13 = 011
OR  data2b,data2b,temp_data   

LI  temp_data,0X3FFF
AND data3b,data3b,temp_data
LI  temp_data,0xFFFFE000
OR  temp_data,data3b,temp_data
OR  expect3,data3a,temp_data  
LI  temp_data,0xE000        # bit15_13 = 111
OR  data3b,data3b,temp_data

LI  temp_data,0X1FFF
AND data4b,data4b,temp_data
OR  expect4,data4a,data4b  
LI  temp_data,0xC000
OR  data4b,data4b,temp_data # bit15_13 = 110
J   to_set_imm             

 
to_set_imm:

# override flag, see EAS_rfpc Table 2.12
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0);  #override dref and dm
OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[15:0] dr
LI   temp_data,0
SRLI temp_data,data1b,14
SLLI temp_data,temp_data,41
OR cppcmd_data_ref, cppcmd_data_ref,temp_data    # override rs1[45:41] dm 
.insn s 43,0,address,cluster_scratch_set_imm(cppcmd_data_ref);# cls_clr_imm


ADDI address,group_num , 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm   
OR cppcmd_data_ref, cppcmd_data_ref, data2b # override rs1[15:0]
LI   temp_data,0
SRLI temp_data,data2b,14
SLLI temp_data,temp_data,41
OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm  
.insn s 43,0,address,cluster_scratch_set_imm(cppcmd_data_ref); 


ADDI address,group_num , 0x8 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm   
OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[15:0]
LI   temp_data,0
SRLI temp_data,data3b,14
SLLI temp_data,temp_data,41
OR cppcmd_data_ref, cppcmd_data_ref,temp_data                   # override rs1[45:41] dm  
.insn s 43,0,address,cluster_scratch_set_imm(cppcmd_data_ref);  


ADDI address,group_num, 0xC 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm   
OR cppcmd_data_ref, cppcmd_data_ref, data4b # override rs1[15:0]
LI   temp_data,0
SRLI temp_data,data4b,14
SLLI temp_data,temp_data,41
OR cppcmd_data_ref, cppcmd_data_ref,temp_data

.insn s 43,0,address,cluster_scratch_set_imm(cppcmd_data_ref);  # override rs1[45:41] dm

ADD address, group_num, zero # set to initial value  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);



LWU temp_data, 0x40(xfer)
BNE temp_data, expect1, test_failed

LWU temp_data, 0x44(xfer)
BNE temp_data, expect2, test_failed

LWU temp_data, 0x48(xfer)
BNE temp_data, expect3, test_failed

LWU temp_data, 0x4c(xfer)
BNE temp_data, expect4, test_failed

ADDI count,count,500
ADDI loop_count, loop_count, -1
BNE loop_count, zero, set_imm_loop 

###****************************************
###SET_IMM   len!=0
###****************************************
LI loop_count,4
LI count,0x40
LI data1b,0
LI data2b,0 
LI data3b,0 
LI data4b,0 

###Now 1 32-bit pseudo_random_number should be created

LI expect1 , 0x0
LI expect2 , 0x0
LI expect3 , 0x0
LI expect4 , 0x0

SW expect1 ,0x0(xfer)
SW expect2 ,0x4(xfer)
SW expect3 ,0x8(xfer)
SW expect4 ,0xC(xfer)  

ADD address, group_num, 80 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write


WAIT_ON_SIGNAL (SIG1_pos,1);

###Now 1 32-bit pseudo_random_number should be created

LI data1b ,0x1
LI data2b ,0x10 

ADD xfer,xfer,count

set_imm1_loop:
 
SLLI  data1b,data1b,1
SRLI  data2b,data2b,1


ANDI data1b,data1b,0x1f
ANDI data2b,data2b,0x1f 


# clr_imm
ADDI address,group_num , 80 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x10);
SLLI temp_data,data1b,16
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_set_imm(cppcmd_data_ref);# cls_clr_imm

ADDI address,group_num , 84 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x14); 
SLLI temp_data,data2b,16
OR cppcmd_data_ref,cppcmd_data_ref,temp_data   
.insn s 43,0,address,cluster_scratch_set_imm(cppcmd_data_ref); 

#read_le
ADD address, group_num, 80   
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x20,0x1,0x0);
OR cppcmd_data_ref,cppcmd_data_ref,count
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

#to_expect:

OR  expect1,expect1,data1b
OR  expect2,expect2,data2b  
SLLI data1a,expect2,32
OR   data1a,data1a,expect1

#compare
#ADD xfer,xfer,count

LD  temp_data, 0x0(xfer)
BNE temp_data,data1a , test_failed  

ADDI xfer,xfer,0x10

ADDI loop_count, loop_count, -1
ADDI count,count,0x10
BNE loop_count, zero, set_imm1_loop  
                          
####****************************************
####TEST_AND_SET_IMM
####****************************************
#  Indirect length goes in bits [4:0]

LI loop_count, NUM_OPERATIONS


###Now 1 32-bit pseudo_random_number should be created
###data_rand1a      x12
LI data1a, 0x0
LI data1b, 0x0
LI count,1
LI xfer, CPP_MEM_ADDR

##store the random data to cpp memory

SD data1a , 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);
test_and_set_imm_loop: 
###Now 1 32-bit pseudo_random_number should be created

ADD data1b,data1b,count
LI mask, 0x1F
AND data1b, data1b, mask  
# override length
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x10);
SLLI temp_data, data1b, 16
OR cppcmd_data_ref, cppcmd_data_ref,temp_data 
.insn s 43,0,address,cluster_scratch_test_set_imm(cppcmd_data_ref);# cls_test_clr_imm

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

#compare the returned data with the previous

LW temp_data, 0x10(xfer)
BNE temp_data, data1a, test_failed
#expectdata


OR  data1a,data1a,data1b 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LW  temp_data, 0x20(xfer)
BNE temp_data, data1a, test_failed 


ADDI count,count,0x1 
SUB loop_count, loop_count, one
BNE loop_count, zero, test_and_set_imm_loop  

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

