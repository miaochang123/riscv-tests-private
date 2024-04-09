#--------------------------------
# TEST_NAME: rfpc_ls_sub_random.S
# cmd: sub         6/0 
#      sub64       6/1
#      subsat      6/2
#      test_sub    22/0
#      test_sub64  22/1
#      test_subsat 22/2
#--------------------------------

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
	
#define cppcmd_data_ref x3
#define loop_count      x4 
#define group_num       x5
#define cl_num          x6
#define temp_data_1     x7 
#define address         x8
#define xfer            x9  
#define hart_id         x10 #hart csr register

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

#define  remainder     x23
#define  temp_data     x24
#define  temp_data1    x25
#define  temp_data2    x26
#define  temp_data3    x27

#define  one           x1
#define  two           x2
#define  three         x29
#define  four          x31

.equ NUM_OPERATIONS ,   20
.equ MEM_SIZE_DIV16 ,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR   ,   0xf0000000 

RVTEST_RV64U
RVTEST_CODE_BEGIN
#------------------------------------
#Set Up the BASE scratch address
#Each ME will use a different region
#------------------------------------
	
LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127

SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	
ADD address, group_num, zero


LI xfer, CPP_MEM_ADDR 
LI one ,0x1
LI two ,0x2  
LI three ,0x3 
LI four ,0x4

####################################################
# test1    32bit sub
####################################################
LI loop_count, NUM_OPERATIONS
sub32_loop:
LI data1a ,0x1111111122222222
LI data2a ,0x3333333344444444
LI data3a ,0x5555555566666666
LI data4a ,0x7777777788888888

#store the data to cpp memory 
SD data1a ,0x0(xfer)
SD data2a ,0x8(xfer)
SD data3a ,0x10(xfer)
SD data4a ,0x18(xfer)

LI data1b ,0x7777777788888888 
LI data2b ,0x1111111122222222
LI data3b ,0x5555555566666666
LI data4b ,0x3333333344444444

SD data1b ,0x20(xfer)
SD data2b ,0x28(xfer)
SD data3b ,0x30(xfer)
SD data4b ,0x38(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, one  ,  sub32_2_6
BEQ remainder, two  ,  sub32_3_5
BEQ remainder, three,  sub32_4_4  

sub32_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32_expect

sub32_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32_expect

sub32_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 5 32-bit
                                
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32_expect

sub32_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x14

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x34);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x1c

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3c);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);
#
#
sub32_expect:

#calculate the expected values
# 1
LI  temp_data,0xFFFFFFFF
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data
SUB expect1,temp_data1,temp_data2
AND expect1,expect1,temp_data        #high 32bit
OR  expect1,expect1,temp_data3       #{high,low}

#2
LI  temp_data,0xFFFFFFFF
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data 
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data
SUB expect2,temp_data1,temp_data2
AND expect2,expect2,temp_data        #high 32bit
OR  expect2,expect2,temp_data3       #{high,low} 

#3
LI  temp_data,0xFFFFFFFF
AND temp_data1,data3a,temp_data  #low 32bit
AND temp_data2,data3b,temp_data 
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data3a,temp_data
AND temp_data2,data3b,temp_data
SUB expect3,temp_data1,temp_data2    
AND expect3,expect3,temp_data        #high 32bit
OR  expect3,expect3,temp_data3       #{high,low} 

#4
LI  temp_data,0xFFFFFFFF
AND temp_data1,data4a,temp_data  #low 32bit
AND temp_data2,data4b,temp_data 
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data4a,temp_data
AND temp_data2,data4b,temp_data
SUB expect4,temp_data1,temp_data2
AND expect4,expect4,temp_data        #high 32bit
OR  expect4,expect4,temp_data3       #{high,low} 

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);                    

LD  temp_data, 0x40(xfer)
BNE temp_data, expect1, test_failed  
LD  temp_data, 0x48(xfer)
BNE temp_data, expect2, test_failed 
LD  temp_data, 0x50(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x58(xfer)
BNE temp_data, expect4, test_failed


SUB loop_count, loop_count, one
BNE loop_count, zero, sub32_loop    

NOP
NOP
NOP

####################################################
# test2    32bit sub_sat
#################################################### 
LI loop_count,NUM_OPERATIONS
sub32sat_loop:
LI data1a ,0x1111111122222222
LI data2a ,0x3333333344444444
LI data3a ,0x5555555566666666
LI data4a ,0x7777777788888888

#store the data to cpp memory 
SD data1a ,0x0(xfer)
SD data2a ,0x8(xfer)
SD data3a ,0x10(xfer)
SD data4a ,0x18(xfer)


LI data1b ,0x7777777788888888 
LI data2b ,0x1111111122222222
LI data3b ,0x5555555566666666
LI data4b ,0x3333333344444444

SD data1b ,0x20(xfer)
SD data2b ,0x28(xfer)
SD data3b ,0x30(xfer)
SD data4b ,0x38(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, one  ,  sub32sat_2_6
BEQ remainder, two  ,  sub32sat_3_5
BEQ remainder, three,  sub32sat_4_4  

sub32sat_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32sat_expect

sub32sat_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_sub(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32sat_expect

sub32sat_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 5 32-bit
                                
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32sat_expect

sub32sat_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x14

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x34);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x1c

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3c);
.insn s 43,0,address,cluster_scratch_sub_sat(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);
#
#
sub32sat_expect:

#calculate the expected values
# 1
LI  temp_data,0xFFFFFFFF
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,sub_not_sat1_0
LI  temp_data3,0x0

sub_not_sat1_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data

SUB expect1,temp_data1,temp_data2
AND expect1,expect1,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,sub_not_sat1_1
LI  expect1,0x0
 
sub_not_sat1_1:
ADDI expect1,expect1,0x0             #high 32bit   
OR  expect1,expect1,temp_data3       #{high,low}

# 2
LI  temp_data,0xFFFFFFFF
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,sub_not_sat2_0
LI  temp_data3,0x0

sub_not_sat2_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data

SUB expect2,temp_data1,temp_data2
AND expect2,expect2,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,sub_not_sat2_1
LI  expect2,0x0
 
sub_not_sat2_1:
ADDI expect2,expect2,0x0             #high 32bit 
OR  expect2,expect2,temp_data3       #{high,low} 

# 3
LI  temp_data,0xFFFFFFFF
AND temp_data1,data3a,temp_data
AND temp_data2,data3b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,sub_not_sat3_0
LI  temp_data3,0x0

sub_not_sat3_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data3a,temp_data
AND temp_data2,data3b,temp_data

SUB expect3,temp_data1,temp_data2
AND expect3,expect3,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,sub_not_sat3_1
LI  expect3,0x0
 
sub_not_sat3_1:
ADDI expect3,expect3,0x0             #high 32bit 
OR  expect3,expect3,temp_data3       #{high,low}  
# 4
LI  temp_data,0xFFFFFFFF
AND temp_data1,data4a,temp_data
AND temp_data2,data4b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,sub_not_sat4_0
LI  temp_data3,0x0

sub_not_sat4_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data4a,temp_data
AND temp_data2,data4b,temp_data

SUB expect4,temp_data1,temp_data2
AND expect4,expect4,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,sub_not_sat4_1
LI  expect4,0x0
 
sub_not_sat4_1:
ADDI expect4,expect4,0x0             #high 32bit 
OR  expect4,expect4,temp_data3       #{high,low}

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);                    

LD  temp_data, 0x40(xfer)
BNE temp_data, expect1, test_failed  
LD  temp_data, 0x48(xfer)
BNE temp_data, expect2, test_failed
LD  temp_data, 0x50(xfer)
BNE temp_data, expect3, test_failed
LD  temp_data, 0x58(xfer)
BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, sub32sat_loop  

NOP
NOP
NOP
####################################################
# test3    64bit sub
#################################################### 
LI loop_count, NUM_OPERATIONS
sub64_loop:
LI data1a ,0x1111111122222222
LI data2a ,0x3333333344444444
LI data3a ,0x5555555566666666
LI data4a ,0x7777777788888888

#store the data to cpp memory 
SD data1a ,0x0(xfer)
SD data2a ,0x8(xfer)
SD data3a ,0x10(xfer)
SD data4a ,0x18(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

LI data1b ,0x7777777788888888 
LI data2b ,0x1111111122222222
LI data3b ,0x5555555566666666
LI data4b ,0x3333333344444444

SD data1b ,0x20(xfer)
SD data2b ,0x28(xfer)
SD data3b ,0x30(xfer)
SD data4b ,0x38(xfer) 

#divide the test to 4 sets
REM remainder, loop_count, three
BEQ remainder, one  ,  sub64_2_6
BEQ remainder, two  ,  sub64_8
BEQ remainder, zero ,  sub64_4_4  

sub64_8:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x20);
.insn s 43,0,address,cluster_scratch_sub64(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, sub64_expect 

sub64_2_6:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_sub64(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_sub64(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, sub64_expect

sub64_4_4:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_sub64(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_sub64(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

sub64_expect:
#calculate the expected values
SUB expect1,data1a,data1b
SUB expect2,data2a,data2b
SUB expect3,data3a,data3b  
SUB expect4,data4a,data4b

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);                    

LD  temp_data, 0x40(xfer)
BNE temp_data, expect1, test_failed  #
LD  temp_data, 0x48(xfer)
BNE temp_data, expect2, test_failed  #
LD  temp_data, 0x50(xfer)
BNE temp_data, expect3, test_failed  #
LD  temp_data, 0x58(xfer)
BNE temp_data, expect4, test_failed  #

SUB loop_count, loop_count, one
BNE loop_count, zero, sub64_loop   


####################################################
# test4    32bit test_sub
####################################################
LI loop_count, NUM_OPERATIONS
sub32_test_loop:
LI data1a ,0x1111111122222222
LI data2a ,0x3333333344444444
LI data3a ,0x5555555566666666
LI data4a ,0x7777777788888888

#store the data to cpp memory 
SD data1a ,0x0(xfer)
SD data2a ,0x8(xfer)
SD data3a ,0x10(xfer)
SD data4a ,0x18(xfer)

LI data1b ,0x7777777788888888 
LI data2b ,0x1111111122222222
LI data3b ,0x5555555566666666
LI data4b ,0x3333333344444444

SD data1b ,0x20(xfer)
SD data2b ,0x28(xfer)
SD data3b ,0x30(xfer)
SD data4b ,0x38(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, one  ,  sub32_test_2_6
BEQ remainder, two  ,  sub32_test_3_5
BEQ remainder, three,  sub32_test_4_4  

sub32_test_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32_test_expect

sub32_test_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32_test_expect

sub32_test_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 5 32-bit
                                
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J sub32_test_expect

sub32_test_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_test_sub(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);
#
#
sub32_test_expect:

#calculate the expected values
# 1
LI  temp_data,0xFFFFFFFF
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data
SUB expect1,temp_data1,temp_data2
AND expect1,expect1,temp_data        #high 32bit
OR  expect1,expect1,temp_data3       #{high,low}

#2
LI  temp_data,0xFFFFFFFF
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data 
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data
SUB expect2,temp_data1,temp_data2
AND expect2,expect2,temp_data        #high 32bit
OR  expect2,expect2,temp_data3       #{high,low} 

#3
LI  temp_data,0xFFFFFFFF
AND temp_data1,data3a,temp_data  #low 32bit
AND temp_data2,data3b,temp_data 
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data3a,temp_data
AND temp_data2,data3b,temp_data
SUB expect3,temp_data1,temp_data2    
AND expect3,expect3,temp_data        #high 32bit
OR  expect3,expect3,temp_data3       #{high,low} 

#4
LI  temp_data,0xFFFFFFFF
AND temp_data1,data4a,temp_data  #low 32bit
AND temp_data2,data4b,temp_data 
SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data4a,temp_data
AND temp_data2,data4b,temp_data
SUB expect4,temp_data1,temp_data2
AND expect4,expect4,temp_data        #high 32bit
OR  expect4,expect4,temp_data3       #{high,low} 

#compare pushdata
LD  temp_data, 0x20(xfer)
BNE temp_data, data1a, test_failed 
LD  temp_data, 0x28(xfer)
BNE temp_data, data2a, test_failed
LD  temp_data, 0x30(xfer)
BNE temp_data, data3a, test_failed
LD  temp_data, 0x38(xfer)
BNE temp_data, data4a, test_failed

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);                    

LD  temp_data, 0x40(xfer)
BNE temp_data, expect1, test_failed  #expect4_high 
LD  temp_data, 0x48(xfer)
BNE temp_data, expect2, test_failed  #expect4_high
LD  temp_data, 0x50(xfer)
BNE temp_data, expect3, test_failed  #expect4_high
LD  temp_data, 0x58(xfer)
BNE temp_data, expect4, test_failed  #expect4_high

SUB loop_count, loop_count, one
BNE loop_count, zero, sub32_test_loop    

NOP
NOP
NOP             
#
####################################################
# test5    32bit test_subsat
#################################################### 
LI loop_count,NUM_OPERATIONS
test_subsat_loop:
LI data1a ,0x1111111122222222
LI data2a ,0x3333333344444444
LI data3a ,0x5555555566666666
LI data4a ,0x7777777788888888

#store the data to cpp memory 
SD data1a ,0x0(xfer)
SD data2a ,0x8(xfer)
SD data3a ,0x10(xfer)
SD data4a ,0x18(xfer)

LI data1b ,0x7777777799999999 
LI data2b ,0x1111111188888888
LI data3b ,0x4444444466666666
LI data4b ,0x3333333355555555

SD data1b ,0x20(xfer)
SD data2b ,0x28(xfer)
SD data3b ,0x30(xfer)
SD data4b ,0x38(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

#divide the test to 4 sets
REM remainder, loop_count, four
BEQ remainder, one  ,  test_subsat_2_6
BEQ remainder, two  ,  test_subsat_3_5
BEQ remainder, three,  test_subsat_4_4  

test_subsat_1_7:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 1 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x24);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 7 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J test_subsat_expect

test_subsat_2_6:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x28);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J test_subsat_expect

test_subsat_3_5:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x20);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 3 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xC

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x4,0x2C);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 5 32-bit
                                
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

J test_subsat_expect

test_subsat_4_4:

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30);
.insn s 43,0,address,cluster_scratch_test_subsat(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);
#
#
test_subsat_expect:

#calculate the expected values
# 1
LI  temp_data,0xFFFFFFFF
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,test_sub_not_sat1_0
LI  temp_data3,0x0

test_sub_not_sat1_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data1a,temp_data
AND temp_data2,data1b,temp_data

SUB expect1,temp_data1,temp_data2
AND expect1,expect1,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,test_sub_not_sat1_1
LI  expect1,0x0
 
test_sub_not_sat1_1:
ADDI expect1,expect1,0x0             #high 32bit   
OR  expect1,expect1,temp_data3       #{high,low}

# 2
LI  temp_data,0xFFFFFFFF
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,test_sub_not_sat2_0
LI  temp_data3,0x0

test_sub_not_sat2_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data2a,temp_data
AND temp_data2,data2b,temp_data

SUB expect2,temp_data1,temp_data2
AND expect2,expect2,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,test_sub_not_sat2_1
LI  expect2,0x0
 
test_sub_not_sat2_1:
ADDI expect2,expect2,0x0             #high 32bit 
OR  expect2,expect2,temp_data3       #{high,low} 

# 3
LI  temp_data,0xFFFFFFFF
AND temp_data1,data3a,temp_data
AND temp_data2,data3b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,test_sub_not_sat3_0
LI  temp_data3,0x0

test_sub_not_sat3_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data3a,temp_data
AND temp_data2,data3b,temp_data

SUB expect3,temp_data1,temp_data2
AND expect3,expect3,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,test_sub_not_sat3_1
LI  expect3,0x0
 
test_sub_not_sat3_1:
ADDI expect3,expect3,0x0             #high 32bit 
OR  expect3,expect3,temp_data3       #{high,low}  
# 4
LI  temp_data,0xFFFFFFFF
AND temp_data1,data4a,temp_data
AND temp_data2,data4b,temp_data

SUB temp_data3,temp_data1,temp_data2
AND temp_data3,temp_data3,temp_data  #low 32bit
SLTU temp_data,temp_data1,temp_data2
BEQZ temp_data,test_sub_not_sat4_0
LI  temp_data3,0x0

test_sub_not_sat4_0:
ADDI temp_data3,temp_data3,0x0

LI  temp_data,0xFFFFFFFF00000000
AND temp_data1,data4a,temp_data
AND temp_data2,data4b,temp_data

SUB expect4,temp_data1,temp_data2
AND expect4,expect4,temp_data        
SLTU temp_data,temp_data1,temp_data2 
BEQZ temp_data,test_sub_not_sat4_1
LI  expect4,0x0
 
test_sub_not_sat4_1:
ADDI expect4,expect4,0x0             #high 32bit 
OR  expect4,expect4,temp_data3       #{high,low}

#compare pushdata
LD  temp_data, 0x20(xfer)
BNE temp_data, data1a, test_failed 
LD  temp_data, 0x28(xfer)
BNE temp_data, data2a, test_failed
LD  temp_data, 0x30(xfer)
BNE temp_data, data3a, test_failed
LD  temp_data, 0x38(xfer)
BNE temp_data, data4a, test_failed

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);

LD   temp_data, 0x40(xfer)
BNE  temp_data, expect1, test_failed
LD   temp_data, 0x48(xfer)
BNE  temp_data, expect2, test_failed
LD   temp_data, 0x50(xfer)
BNE  temp_data, expect3, test_failed
LD   temp_data, 0x58(xfer)
BNE  temp_data, expect4, test_failed


SUB loop_count, loop_count, one
BNE loop_count, zero, test_subsat_loop  
                                         
NOP
NOP
NOP                              

#####################################################
# test6    64bit test_sub64
##################################################### 
LI loop_count, NUM_OPERATIONS
test_sub64_loop:
LI data1a ,0x1111111122222222
LI data2a ,0x3333333344444444
LI data3a ,0x5555555566666666
LI data4a ,0x7777777788888888

#store the data to cpp memory 
SD data1a ,0x10(xfer)
SD data2a ,0x18(xfer)
SD data3a ,0x20(xfer)
SD data4a ,0x28(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x10);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

LI data1b ,0x7777777788888888 
LI data2b ,0x1111111122222222
LI data3b ,0x5555555566666666
LI data4b ,0x3333333344444444

SD data1b ,0x60(xfer)
SD data2b ,0x68(xfer)
SD data3b ,0x70(xfer)
SD data4b ,0x78(xfer) 

#divide the test to 4 sets
REM remainder, loop_count, three
BEQ remainder, one  ,  test_sub64_2_6
BEQ remainder, two  ,  test_sub64_8
BEQ remainder, zero ,  test_sub64_4_4  

test_sub64_8:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x60);
.insn s 43,0,address,cluster_scratch_test_sub64(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, test_sub64_expect 

test_sub64_2_6:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_test_sub64(cppcmd_data_ref);# cls_xor for 2 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x68);
.insn s 43,0,address,cluster_scratch_test_sub64(cppcmd_data_ref);# cls_xor for 6 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

BEQZ zero, test_sub64_expect

test_sub64_4_4:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x60);
.insn s 43,0,address,cluster_scratch_test_sub64(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70);
.insn s 43,0,address,cluster_scratch_test_sub64(cppcmd_data_ref);# cls_xor for 4 32-bit

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

test_sub64_expect:

#compare pushdata
LD  temp_data, 0x60(xfer)
BNE temp_data, data1a, test_failed 
LD  temp_data, 0x68(xfer)
BNE temp_data, data2a, test_failed
LD  temp_data, 0x70(xfer)
BNE temp_data, data3a, test_failed
LD  temp_data, 0x78(xfer)
BNE temp_data, data4a, test_failed  

#calculate the expected values
SUB expect1,data1a,data1b
SUB expect2,data2a,data2b
SUB expect3,data3a,data3b  
SUB expect4,data4a,data4b

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);                    

LD  temp_data, 0x80(xfer)
BNE temp_data,expect1 , test_failed  #expect1_high
LD  temp_data, 0x88(xfer)
BNE temp_data,expect2 , test_failed  #expect2_low
LD  temp_data, 0x90(xfer)
BNE temp_data,expect3 , test_failed  #expect3_low
LD  temp_data, 0x98(xfer)
BNE temp_data,expect4 , test_failed  #expect4_low




SUB loop_count, loop_count, one
BNE loop_count, zero, test_sub64_loop 

NOP
NOP
NOP              


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
