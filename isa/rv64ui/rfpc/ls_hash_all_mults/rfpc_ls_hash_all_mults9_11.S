#--------------------------------
# TEST_NAME: rfpc_ls_hash_all_mults9_11.S
# cmd: hash_mask            8/2 
#      hash_mask_clear      8/3
#      
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
	
#define  cppcmd_data_ref x3

#define  group_num       x5
#define  cl_num          x6
#define  temp_data_1     x7 
#define  address         x8
#define  xfer            x9  
#define  hart_id         x10 #hart csr register

#define  data1a          x11
#define  index_num       x12
#define  offset          x13
#define  expect          x14

#define  hash_offset     x15
#define  base            x16
#define  mult            x17   
#define  base2           x18

#define  hash_address   x19
#define  temp_data      x20


.equ CPP_MEM_ADDR   ,0xf0000000
.equ HASH_BASE_HIGH ,0x4
.equ HASH_BASE_LOW0 ,0x0

.equ HASH_MULT      ,0x0
.equ HASH_INDEX_BOTH,0x800

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
LI data1a,0x87654321
SD data1a,0x0(xfer)
#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);  

SRLI temp_data,group_num,12
ADD index_num,temp_data, zero    ###index_num is 0,1,2,3,4,5
LI hash_offset,0x100

###############################
# base for hash = 0x00004_0000
###############################

LI base,0x40000    #   {HASH_BASE_HIGH,HASH_BASE_LOW0}
SLLI temp_data,cl_num,26

OR base2,base,temp_data
OR base,base,temp_data 

LI offset,HASH_INDEX_BOTH
ADD base2,base2,offset
SLLI offset,index_num,3

###  Insert Program output here **** 


##
### START of UCODE OUTPUT 
##  mult = 9
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,9
SD mult,0x0(xfer)

ADDI address,base ,HASH_MULT 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address,base ,HASH_MULT 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,base,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);  

LI data1a,0xffffffff
SD data1a,0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask_clear(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xdd12cf4c20933831
LD temp_data,0x0(xfer)
BNE temp_data,expect,test_failed

SD data1a,0x0(xfer) 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x39928a6bb289508b
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x6dca760c8aa1f83a
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x3ffb446acec7f4e1
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x7dbecbfddfc97781
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x55d4a3006fac7416
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x92954fc0a65a7547
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x28013dce164e4d2e
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x530b911865ed5197
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x6e7483728f89c8de
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed



##
### START of UCODE OUTPUT 
##  mult = 10
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,10
SD mult,0x0(xfer)

ADDI address,base ,HASH_MULT 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address,base ,HASH_MULT 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,base,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);  

LI data1a,0xffffffff
SD data1a,0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask_clear(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xa946fd1456d70a29
LD temp_data,0x0(xfer)
BNE temp_data,expect,test_failed

SD data1a,0x0(xfer) 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xe5271abbdcee86fe
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x47df1513da171330
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x18c12e4a72e03f0b
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x5833c0db220c1b82
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x803092bef2779c99
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xcbd3cd15c0c46bb3
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x0ea8101e0c83433c
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x79335cb3771af838
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xb352861def5b777e
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed

##
### START of UCODE OUTPUT 
##  mult = 11
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,11
SD mult,0x0(xfer)

ADDI address,base ,HASH_MULT 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address,base ,HASH_MULT 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,base,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);  

LI data1a,0xffffffff
SD data1a,0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask_clear(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xa946fd1c20833839
LD temp_data,0x0(xfer)
BNE temp_data,expect,test_failed

SD data1a,0x0(xfer) 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x41bef2f19ec594f5
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xab0081213c795524
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xe782416251bd44e2
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xb7f07616a1813f59
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x14d859be0b958c6c
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xc3cf5bc68caae430
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x4b6a1f55a4b336b9
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x499112f39ef3344f
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xa42df1e5ca57618c
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed 




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
