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
#define cppcmd_data_ref x3
#define cppcmd_imm_ref x4
#define cppcmd_data_read x5

#define sign_extend_mask x10
#define sign_extend_or x11


#define address_add4   x21
#define address_add8   x22
#define address_add12   x23
#define address   x17
#define cl_num        x18
#define group_num        x19
#define temp_data   x2
#define temp_data_1   x6
#define temp_data_2   x7
#define temp_data_3   x8
#define xfer x26



.equ CPP_MEM_ADDR,   0xf0000000

.equ INIT_RESIDUE,  0x8765432187654321

.equ ADD_DATA0A,    0x00010001
.equ ADD_DATA1A,    0x00020002
.equ ADD_DATA2A,    0x00030003
.equ ADD_DATA3A,    0x00040004
.equ ADD_DATA4A,    0x00000005
.equ ADD_DATA5A,    0x00000000
.equ ADD_DATA6A,    0x00001ffe
.equ ADD_DATA7A,    0x00000000


.equ EXPECT0,    0x0002000200010009
.equ EXPECT1,    0x0004000800030007
.equ EXPECT2,    0xffffffffffffe009
.equ EXPECT3,    0xffffe00300000000




RVTEST_RV64U
RVTEST_CODE_BEGIN



LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 256 byte of address space
	

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, ADD_DATA0A
SW temp_data, 0x0(xfer)
LI temp_data, ADD_DATA1A
SW temp_data, 0x4(xfer)
LI temp_data, ADD_DATA2A
SW temp_data, 0x8(xfer)
LI temp_data, ADD_DATA3A
SW temp_data, 0xC(xfer)
LI temp_data, ADD_DATA4A
SW temp_data, 0x10(xfer)
LI temp_data, ADD_DATA5A
SW temp_data, 0x14(xfer)
LI temp_data, ADD_DATA6A
SW temp_data, 0x18(xfer)
LI temp_data, ADD_DATA7A
SW temp_data, 0x1C(xfer)



ADD address, group_num, zero
##write all 4*32 data to cls sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 7, DRef = 0	
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#1st 32bits data  #// no sign extend, no duplicate
ADD address, group_num, zero # set to initial value
LI cppcmd_imm_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x40,0x0,0x8)  ;
.insn s 43,0,address,cluster_scratch_add64_imm(cppcmd_imm_ref)	 ;# CPP Command read

#2nd 32bits data  #// no sign extend, duplicate
ADD address, group_num, zero # set to initial value
ADDI address_add4, address, 8 # set to initial value
LI cppcmd_imm_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x40,0x0,0x8004)  ;
.insn s 43,0,address_add4,cluster_scratch_add64_imm(cppcmd_imm_ref)	 ;# CPP Command read

#3rd 32bits data  #// sign extend, no duplicatea
ADD address, group_num, zero # set to initial value
ADDI address_add8, address, 16 # set to initial value
LI cppcmd_imm_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x40,0x0,0x6004)  ;
.insn s 43,0,address_add8,cluster_scratch_add64_imm(cppcmd_imm_ref)	 ;# CPP Command read

#4th 32bits data  #// sign extend, duplicatea;and high32 with carry
ADD address, group_num, zero # set to initial value
ADDI address_add12, address, 24 # set to initial value
LI cppcmd_imm_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x40,0x0,0xe002)  ;
.insn s 43,0,address_add12,cluster_scratch_add64_imm(cppcmd_imm_ref)	 ;# CPP Command read




#read_le n*32bits data
ADD address, group_num, zero # set to initial value
LI cppcmd_data_read, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_read)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);




#####################################Test 64 BIT Adds imm
#Test-ADD64
LI temp_data, INIT_RESIDUE
LD temp_data, 0x40(xfer)
LI temp_data_2, EXPECT0
BNE temp_data, temp_data_2, test_failed

#Test-ADD64
LD temp_data, 0x48(xfer)
LI temp_data_2, EXPECT1
BNE temp_data, temp_data_2, test_failed

#Test-ADD64
LD temp_data, 0x50(xfer)
LI temp_data_2, EXPECT2
BNE temp_data, temp_data_2, test_failed

#Test-ADD64
LD temp_data, 0x58(xfer)
LI temp_data_2, EXPECT3
BNE temp_data, temp_data_2, test_failed



ADD address, group_num, zero # set to initial value
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
