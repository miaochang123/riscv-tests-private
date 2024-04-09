#--------------------------------
# TEST_NAME: rfpc_ls_statistic.S
# cmd: statistic            17/2 
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

#define  packet_count   x11
#define  byte_count     x12
#define  expect0        x13
#define  expect1        x14

#define  end_count      x15
#define  data_upper32   x16
#define  data_lower32   x17
#define  byte_count_inc x18

#define  byte_count_upper   x19
#define  temp_data      x20
#define  temp_data1     x21 


.equ NUM_LOOPS    ,   64
.equ CPP_MEM_ADDR ,0xf0000000 

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

ADD temp_data1,group_num,zero

SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	
ADD address, group_num, zero


LI xfer, CPP_MEM_ADDR
LI byte_count,0
LI byte_count_upper,0
ADD packet_count,temp_data1,zero
SLLI temp_data,packet_count,3
OR byte_count_upper,byte_count_upper,temp_data

SW byte_count,0x0(xfer)
SW byte_count_upper,0x4(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);  


LI end_count,NUM_LOOPS
LI byte_count_inc,1

stat_loop1:
  # Byte_count   = [34:0]
  # Packet_count = [63:35]
SD byte_count_inc,0x10(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); #override dref
#RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
#OVERRIDE(11),LENGTH(5),DATA_REF(16)
.insn s 43,0,address,cluster_scratch_statistic(cppcmd_data_ref); 
ADD address, group_num, zero
WAIT_ON_SIGNAL (SIG1_pos,1);  

ADD  byte_count,byte_count,byte_count_inc
ADDI packet_count,packet_count,1

ADD  expect0,byte_count,zero
SLLI temp_data,packet_count,3 
ADD  expect1,temp_data,zero

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1); 

LW  temp_data, 0x30(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x34(xfer)
BNE temp_data, expect1, test_failed

ADDI byte_count_inc,byte_count_inc,1

SUB temp_data,byte_count_inc,end_count 
BNE temp_data,zero,stat_loop1 
#####################################  
#CLS init new data to RAM 
LI  byte_count,0xFFFFFFFF
ADD packet_count,temp_data1,zero
SLLI temp_data,packet_count,3  
OR byte_count_upper,byte_count_upper,temp_data 

SW byte_count,0x0(xfer)
SW byte_count_upper,0x4(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);    

## Perform statistic to cause carry from bit 31 to 32  
LI byte_count_inc,4
SD byte_count_inc,0x10(xfer) 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); #override dref
#RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
#OVERRIDE(11),LENGTH(5),DATA_REF(16)
.insn s 43,0,address,cluster_scratch_statistic(cppcmd_data_ref); 
ADD address, group_num, zero
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADD  byte_count,byte_count,byte_count_inc
LI   temp_data,0xFFFFFFFF
AND  byte_count,byte_count,temp_data
LI   byte_count_upper,1
ADDI packet_count,packet_count,1  
ADD  expect0,byte_count,zero
SLLI temp_data,packet_count,3 
OR   expect1,byte_count_upper,temp_data

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1); 

LW  temp_data, 0x30(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x34(xfer)
BNE temp_data, expect1, test_failed
###############################################
# for random test,if the rv can gen random data
###############################################
LI loop_count,NUM_LOOPS 
#Generate Random data  
random_loop:
LI byte_count_inc,6
LI data_lower32,0xffffff88
LI data_upper32,88


SW data_lower32,0x0(xfer)
SW data_upper32,0x4(xfer)

#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# 
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);   

SD byte_count_inc,0x10(xfer) 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); #override dref
#RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
#OVERRIDE(11),LENGTH(5),DATA_REF(16)
.insn s 43,0,address,cluster_scratch_statistic(cppcmd_data_ref); 
ADD address, group_num, zero
WAIT_ON_SIGNAL (SIG1_pos,1); 

#Read back statistic results...Generate expected data and compare 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1); 

SRLI packet_count,data_upper32,3 
ADDI packet_count,packet_count,1

ADD  expect0,data_lower32,byte_count_inc
LI   temp_data,0x100000000     # if carry
AND  temp_data,expect0,temp_data
BNE  temp_data,zero,label_carry
LI   byte_count_upper,0
J    to_compare_expect 
label_carry:
LI   byte_count_upper,1


to_compare_expect:

LI   temp_data,0xFFFFFFFF
AND  expect0,expect0,temp_data
SLLI temp_data,packet_count,3 
ADD  expect1,temp_data,byte_count_upper  
SLLI expect1,expect1,32
OR   expect0,expect0,expect1

LD  temp_data, 0x30(xfer)
BNE temp_data, expect0, test_failed


ADDI loop_count,loop_count,-1
BNE loop_count,zero,random_loop    


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
