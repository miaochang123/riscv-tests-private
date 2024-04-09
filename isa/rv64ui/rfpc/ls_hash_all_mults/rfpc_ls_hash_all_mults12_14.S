#--------------------------------
# TEST_NAME: rfpc_ls_hash_all_mults12_14.S
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
##  mult = 12
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,12
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
LI expect,0x9d358bf587f3e2b3
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
LI expect,0x7538b9999896b2e4
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x12c2e03c2d1e33d8
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xed249144eca13f96
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xd7a72663e405c7a2
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xba04b1ba62c8e6da
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x158098138de25858
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x91326046c49efe4c
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x2a7f80a42dc4a8d8
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xa9e9d98cd18e4afb
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed



##
### START of UCODE OUTPUT 
##  mult = 13
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,13
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
LI expect,0x9d358bfdf1a7d0a3
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
LI expect,0xd1a151d3dabda0ef
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xfe1d740ecb7075cc
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x1267fe6ccffc447f
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x386490ae6788e379
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x2eec7aba9b2af62f
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x1d9c0ec0c18cd7db
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xd4f06f0d6cae8bc9
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x1addcee4c42d64af
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xbe96ae74f4825c09
LD temp_data,0x90(xfer)
BNE temp_data,expect,test_failed

##
### START of UCODE OUTPUT 
##  mult = 14
ADD address, group_num, zero # set to initial value
SLLI temp_data,index_num,16
OR hash_address,address,temp_data
LI mult,14
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
LI expect,0xe961b9a587e3e2bb
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
LI expect,0x0d14c103b4da769a
LD temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xd40817119bc69ec6
LD temp_data,0x20(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x355d944c73db8f95
LD temp_data,0x30(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x1de99b889a4d8f7a
LD temp_data,0x40(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xfb084b0406f11ea0
LD temp_data,0x50(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x44da8c15a712c92f
LD temp_data,0x60(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0xf25942dd766385db
LD temp_data,0x70(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x30e5034fd6dacd00
LD temp_data,0x80(xfer)
BNE temp_data,expect,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address,base2 ,offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#
WAIT_ON_SIGNAL (SIG1_pos,1); 
LI expect,0x63b0ab1b9450e3a9
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
