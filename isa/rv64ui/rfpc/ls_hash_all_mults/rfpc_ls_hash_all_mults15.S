#--------------------------------
# TEST_NAME: rfpc_ls_hash_all_mults15.S
# cmd: hash_mask            8/2 
#      hash_mask_clear      8/3
#      hash_mask_withpush   26/0
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
##  mult = 15
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,15
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
LI expect,0xe961b9adf1b7d0ab
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
LI expect,0xa98d2949f6f16491
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x38d783237da8d8d2
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xca1efb645086f47c
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xf22a2d4519c0aba1
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x6fe08004ff130e55
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x4cc61ac6eb7c46ac
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xb79b4d96de53f05e
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x00474d0f3f330177
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x74cfdce3b15cf55b
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed


##
### START of UCODE OUTPUT 
##  mult = 1
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,1
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
LI expect,0x8f1317131
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
LI expect,0x1efc76cb6608c32b
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xa2026d73c8082275
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x609359de21698c57
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x51138da4dbb49696
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xcdb247b2767c91fa
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x38915fbff8a8077b
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x118a2fbd92b3d2dd
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x43b46aa76777b0b0
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x36008086a75c979d
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed  

##
### START of UCODE OUTPUT 
##  mult = 2
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,2
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
LI expect,0x7454325087754329
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
LI expect,0xc249e61b086f155e
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x88170e6c98bec97f
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x47a933fe9d4e47bd
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x749e86822671fa95
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x1856760ceba77975
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x61d7dd6a9e36198f
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x3723026d887edccf
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x698ca70c7580191f
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xeb2685e9c78e283d
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed         

##
### START of UCODE OUTPUT 
##  mult = 4
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,4
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
LI expect,0x402744b15651abb3
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
LI expect,0x525645394c172144
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xdd0afb436fb7e997
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xb24c8cf0030f4720
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xfb0a603ae07826b5
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x226255087b180336
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xbf84886cd3102a64
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xa8b97235406361bf
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x3ac07b1b2f5e49ff
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xf19dda78f95b15b8
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed

##
### START of UCODE OUTPUT 
##  mult = 5
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,5
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
LI expect,0x402744b9200599a3
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
LI expect,0xf6cfad730e3c334f
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x31d56f7189d9af83
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x4d0fe3d820523cc9
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x14c9d6f763f5026e
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xb68a9e0882fa13c3
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xb7981ebf9f7ea5e7
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xed7b7d7ee853143a
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x0a62355bc6b78588
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xe6e2ad80dc57034a
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
