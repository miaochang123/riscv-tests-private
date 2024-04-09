#-----------------------
# TEST_NAME: rfpc_ctm_rw_all.uc
#     Reads and writes unique values to entire CTM memory 
#	
#   10/11/2012: Updated to run on 8 MES (Each ME reads/writes 1/8th of CTM memory
#   12/01/2022: modified to run on rfpc with update 128 cores Each core reads/writes 1/128th of CTM memory
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
	
#define zero   x0 # zero register
#define temp_data   x5
#define temp_data_1   x6
#define temp_data_2   x7
#define temp_data_5   x8
#define temp_data_6   x9

#define exp_checksum_no_inv x12
#define exp_checksum_inv x13
#define csum_result0 x14
#define csum_result1 x15
#define csum_result2 x16
#define csum_result3 x17

#define cppcmd_data_ref x18
#define address   x19
#define cl_num        x20
#define group_num        x21
#define byte_len   x22
#define xfer x23
#define test_num x24
#define byte_counter x25
#define data_counter x26
#define actual_result x27
	
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
SLLI group_num , group_num, 10 #each core has 1024 byte of address space
	
ADD address, group_num, zero
LI xfer, CPP_MEM_ADDR 

#cpp memory finished initalized
##write_first 128byte
li csum_result0, 32
li csum_result1, 0
li csum_result2, 0x4000
initial_loop:
    add csum_result3, csum_result1, xfer
    sw csum_result2, 0x0(csum_result3)
    addi csum_result1, csum_result1, 4
    addi csum_result0, csum_result0, -1
    addi csum_result2, csum_result2, 0x10
    bne csum_result0, x0, initial_loop
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x0)  
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 # CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 
NOP
NOP
##write_second 128byte
li csum_result0, 32
li csum_result1, 0x80
li csum_result2, 0x8000
initial_loop2:
    add csum_result3, csum_result1, xfer
    sw csum_result2, 0x0(csum_result3)
    addi csum_result1, csum_result1, 4
    addi csum_result0, csum_result0, -1
    addi csum_result2, csum_result2, 0x10
    bne csum_result0, x0, initial_loop2
ADD address, group_num, zero
ADDI address,address, 0x80
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x80)  
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 # CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 
NOP
NOP



####################################

J test_begin

calc_loop:
LI temp_data_2, 0xffff
AND temp_data_1, temp_data, temp_data_2
ADD  exp_checksum_no_inv, exp_checksum_no_inv, temp_data_1
SRLI temp_data_1, exp_checksum_no_inv, 0x10
BEQZ  temp_data_1, skip_add
AND exp_checksum_no_inv, exp_checksum_no_inv, temp_data_2
ADD  exp_checksum_no_inv, exp_checksum_no_inv, temp_data_1 #add_carry

skip_add:
SRLI temp_data, temp_data, 0x10
ADDI byte_len, byte_len, -2
ADDI byte_counter, byte_counter, 2
LI temp_data_2, 0x8
BEQ byte_counter, temp_data_2, update_data
NOP
NOP
BNEZ  byte_len, calc_loop

update_data:
ADDI xfer, xfer, 0x8
LD temp_data, 0x0(xfer)
.insn i 19, 1, temp_data, temp_data, (24 | ((-24)<<6) )
LI byte_counter, 0x0
BNEZ byte_len, calc_loop
J return_test


return_test:
SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

LI temp_data_2, 0x1
BEQ test_num, temp_data_2, return_test1
LI temp_data_2, 0x2
BEQ test_num, temp_data_2, return_test2

#----------------------------------
# TEST=1
#----------------------------------
test_begin:
LI test_num, 0x1
LI byte_len, 0x7e
LI byte_counter, 0x0
LD temp_data, 0x0(xfer)
.insn i 19, 1, temp_data, temp_data, (24 | ((-24)<<6) )
LI exp_checksum_no_inv, 0x0
J calc_loop


return_test1:
#Test-CSUM16_NO_INV
LI xfer, CPP_MEM_ADDR 
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x5,0x1,0xf,0x300)  
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 
WAIT_ON_SIGNAL (SIG1_pos,1)
NOP
NOP
NOP
LD actual_result, 0x300(xfer)
LI temp_data_2, 0xffff
AND actual_result, actual_result, temp_data_2
NOP
NOP
NOP
bne actual_result, exp_checksum_no_inv, test_failed
NOP
NOP
NOP


#----------------------------------
# TEST=2
#----------------------------------
LI test_num, 0x2
LI byte_len, 0x80
LI byte_counter, 0x0

ADDI address,address, 0x80
ADDI xfer,xfer, 0x80

LD temp_data, 0x0(xfer)
.insn i 19, 1, temp_data, temp_data, (24 | ((-24)<<6) )
LI exp_checksum_no_inv, 0x0
J calc_loop


return_test2:
#Test-CSUM16_NO_INV
LI xfer, CPP_MEM_ADDR 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0xf,0x310)  
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 
WAIT_ON_SIGNAL (SIG1_pos,1)
NOP
NOP
NOP
LD actual_result, 0x310(xfer)
LI temp_data_2, 0xffff
AND actual_result, actual_result, temp_data_2
NOP
NOP
NOP
bne actual_result, exp_checksum_no_inv, test_failed
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

