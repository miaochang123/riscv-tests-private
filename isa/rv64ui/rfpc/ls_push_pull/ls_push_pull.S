#-----------------------
# TEST_NAME: rfpc_ls_push_pull.S
#-----------------------


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
	
#define zero            x0 # zero register
#define cppcmd_data_ref x3
#define result_group    x4 
#define group_num       x5
#define cl_num          x6
#define temp_data_1     x7 
#define address         x8
#define xfer            x9  
#define hart_id         x10 #hart csr register

#define expect1         x12
#define expect2         x13
#define expect3         x14
#define expect4         x15 
#define expect5         x21
#define expect6         x22
#define expect7         x23
#define expect0         x24

#define len             x16
#define temp_data       x18


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

#Subtract 8 from base address, except on ME4
#SUB result_group,group_num,0x1000
#BEQ result_group, zero , do_not_adjust
#SUB address,group_num,8

#do_not_adjust:

LI xfer, CPP_MEM_ADDR 

LI expect0,1
LI expect1,2
LI expect2,3
LI expect3,4
LI expect4,5
LI expect5,6
LI expect6,7
LI expect7,8

OR expect0,expect0,group_num
OR expect1,expect1,group_num 
OR expect2,expect2,group_num
OR expect3,expect3,group_num
OR expect4,expect4,group_num
OR expect5,expect5,group_num
OR expect6,expect6,group_num
OR expect7,expect7,group_num    



#store the data to cpp memory 
SW expect0,0x0(xfer)
SW expect1,0x4(xfer)
SW expect2,0x8(xfer)
SW expect3,0xc(xfer)
SW expect4,0x10(xfer)
SW expect5,0x14(xfer)
SW expect6,0x18(xfer)
SW expect7,0x1c(xfer)
SW expect0,0x20(xfer)
SW expect1,0x24(xfer)
SW expect2,0x28(xfer)
SW expect3,0x2c(xfer)
SW expect4,0x30(xfer)
SW expect5,0x34(xfer)
SW expect6,0x38(xfer)
SW expect7,0x3c(xfer) 

LI len    , 15 

#override length
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
SLLI len, len, 16
OR cppcmd_data_ref, cppcmd_data_ref, len
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADD address, group_num, 0x40
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# 

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

LI len    , 31
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0); 
SLLI len, len, 16
OR cppcmd_data_ref, cppcmd_data_ref, len 
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# 

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);

LW  temp_data, 0x0(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x4(xfer)
BNE temp_data, expect1, test_failed
LW  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LW  temp_data, 0xC(xfer)
BNE temp_data, expect3, test_failed  
LW  temp_data, 0x10(xfer)
BNE temp_data, expect4, test_failed
LW  temp_data, 0x14(xfer)
BNE temp_data, expect5, test_failed
LW  temp_data, 0x18(xfer)
BNE temp_data, expect6, test_failed
LW  temp_data, 0x1C(xfer)
BNE temp_data, expect7, test_failed  
LW  temp_data, 0x20(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x24(xfer)
BNE temp_data, expect1, test_failed
LW  temp_data, 0x28(xfer)
BNE temp_data, expect2, test_failed
LW  temp_data, 0x2C(xfer)
BNE temp_data, expect3, test_failed  
LW  temp_data, 0x30(xfer)
BNE temp_data, expect4, test_failed
LW  temp_data, 0x34(xfer)
BNE temp_data, expect5, test_failed
LW  temp_data, 0x38(xfer)
BNE temp_data, expect6, test_failed
LW  temp_data, 0x3C(xfer)
BNE temp_data, expect7, test_failed 


##############
LI len    , 31
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0); 
SLLI len, len, 16
OR cppcmd_data_ref, cppcmd_data_ref, len 
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# 

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);

LW  temp_data, 0x0(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x4(xfer)
BNE temp_data, expect1, test_failed
LW  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LW  temp_data, 0xC(xfer)
BNE temp_data, expect3, test_failed  
LW  temp_data, 0x10(xfer)
BNE temp_data, expect4, test_failed
LW  temp_data, 0x14(xfer)
BNE temp_data, expect5, test_failed
LW  temp_data, 0x18(xfer)
BNE temp_data, expect6, test_failed
LW  temp_data, 0x1C(xfer)
BNE temp_data, expect7, test_failed  
LW  temp_data, 0x20(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x24(xfer)
BNE temp_data, expect1, test_failed
LW  temp_data, 0x28(xfer)
BNE temp_data, expect2, test_failed
LW  temp_data, 0x2C(xfer)
BNE temp_data, expect3, test_failed  
LW  temp_data, 0x30(xfer)
BNE temp_data, expect4, test_failed
LW  temp_data, 0x34(xfer)
BNE temp_data, expect5, test_failed
LW  temp_data, 0x38(xfer)
BNE temp_data, expect6, test_failed
LW  temp_data, 0x3C(xfer)
BNE temp_data, expect7, test_failed
##################
LI len    , 31
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0); 
SLLI len, len, 16
OR cppcmd_data_ref, cppcmd_data_ref, len 
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# 

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);

LW  temp_data, 0x0(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x4(xfer)
BNE temp_data, expect1, test_failed
LW  temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LW  temp_data, 0xC(xfer)
BNE temp_data, expect3, test_failed  
LW  temp_data, 0x10(xfer)
BNE temp_data, expect4, test_failed
LW  temp_data, 0x14(xfer)
BNE temp_data, expect5, test_failed
LW  temp_data, 0x18(xfer)
BNE temp_data, expect6, test_failed
LW  temp_data, 0x1C(xfer)
BNE temp_data, expect7, test_failed  
LW  temp_data, 0x20(xfer)
BNE temp_data, expect0, test_failed
LW  temp_data, 0x24(xfer)
BNE temp_data, expect1, test_failed
LW  temp_data, 0x28(xfer)
BNE temp_data, expect2, test_failed
LW  temp_data, 0x2C(xfer)
BNE temp_data, expect3, test_failed  
LW  temp_data, 0x30(xfer)
BNE temp_data, expect4, test_failed
LW  temp_data, 0x34(xfer)
BNE temp_data, expect5, test_failed
LW  temp_data, 0x38(xfer)
BNE temp_data, expect6, test_failed
LW  temp_data, 0x3C(xfer)
BNE temp_data, expect7, test_failed

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
