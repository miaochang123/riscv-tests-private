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
#define count x4
#define hart_id    x10 #hart csr register

#define expect1      x11
#define expect2      x12
#define expect_low   x13
#define expect_high  x14
#define index_num     x15
#define hash_address  x16
#define address       x17
#define base          x23
#define base2         x24
#define cl_num        x18
#define address4      x25
#define temp_data     x20
#define temp_data_1   x21
#define temp_data_2   x22
#define mult  x26
#define xfer  x27



.equ CPP_MEM_ADDR,   0xf0000000

.equ NUM_INDEXESR,   16
.equ HASH_BASE_HIGH,   0x4
.equ HASH_BASE_LOW0,   0x0
.equ HASH_BASE_LOW1,   0x100
.equ HASH_BASE_LOW2,   0x200
.equ HASH_BASE_LOW3,   0x300
.equ HASH_BASE_LOW4,   0x400
.equ HASH_BASE_LOW5,   0x500
.equ HASH_BASE_LOW6,   0x600
.equ HASH_BASE_LOW7,   0x700

.equ HASH_MULT     ,   0x0
.equ HASH_INDEX_LOW,   0x10
.equ HASH_INDEX_HIGH,  0x18
.equ HASH_INDEX_BOTH,  0x800




.equ WR_DATA0A,    0x87654321
.equ WR_DATA1A,    0x00000000
.equ WR_DATA2A,    0xffffffff
.equ WR_DATA3A,    0xffffffff
.equ WR_DATA4A,    0x00000000
.equ WR_DATA5A,    0x00000000



RVTEST_RV64U
RVTEST_CODE_BEGIN



##LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
##AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
##SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
##OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
##SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, HASH_MULT 
SW temp_data, 0x0(xfer)
LI temp_data, HASH_INDEX_LOW
SW temp_data, 0x4(xfer)
LI temp_data, HASH_INDEX_HIGH
SW temp_data, 0x8(xfer)
LI temp_data, HASH_INDEX_BOTH
SW temp_data, 0xC(xfer)
LI temp_data, WR_DATA0A
SW temp_data, 0x10(xfer)
LI temp_data, WR_DATA1A
SW temp_data, 0x14(xfer)
LI temp_data, WR_DATA2A
SW temp_data, 0x18(xfer)
LI temp_data, WR_DATA3A
SW temp_data, 0x1C(xfer)
LI temp_data, WR_DATA4A
SW temp_data, 0x20(xfer)
LI temp_data, WR_DATA5A
SW temp_data, 0x24(xfer)



##;--------------------------------------
##; Set Up the BASE scratch address
##; Each ME will use a different region
##;--------------------------------------
LI address, 0x04004000

####write all defined data to cls sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI index_num, 0
##LI hash_offset, 0x100

##;--------------------------------------
##; Base for HASH = 0x00004_0000
##;--------------------------------------
LI address, 0x04000000
LI base, 0x00040000
OR base, base, address

LI address, 0x04000000
LI base2, 0x00040800
OR base2, base2, address

LI mult, 0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,base,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100)  ;
.insn s 43,0,base,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data,0
LWU temp_data, 0x100(xfer)
BNE temp_data, mult, test_failed

####################loop label
hash_index_loop_mult0:    
LI address, 0x04004000
SLLI index_num, index_num, 16
OR hash_address, address, index_num

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x18)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask_clear(cppcmd_data_ref) ;# CPP Command read

WAIT_ON_SIGNAL (SIG2_pos,1);

LI expect_high, 0x00000000
LI expect_low,  0x87654321

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x120)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data_2, 0
LWU temp_data_2, 0x120(xfer)
BNE temp_data_2, expect_low, test_failed

LWU temp_data_2, 0x124(xfer)
BNE temp_data_2, expect_high, test_failed


NOP
NOP
NOP

#######################################
########do_hash2
#######################################
LI  expect1, 8
SRLI index_num, index_num, 16
BGE index_num, expect1, do_hash2

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x140(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x144)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x144(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash2:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0xba659e81
LI expect_low,  0x2423d120
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x160)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x160(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x164(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash3
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash3

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x170)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x170(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x174)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x174(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash3:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x4eddf941
LI expect_low,  0x2e666461
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x180)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x180(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x184(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash4
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash4

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x190)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x190(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x194)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x194(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash4:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x9fd036f6
LI expect_low,  0x0234f7be
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x1a0)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x1a0(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x1a4(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash5
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash5

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1b0)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x1b0(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1b4)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x1b4(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash5:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0xbed03b69
LI expect_low,  0x5839b24d
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x1c0)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x1c0(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x1c4(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash6
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash6

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1d0)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x1d0(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1d4)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x1d4(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash6:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x595a8cb2
LI expect_low,  0x8f9e810f
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x1e0)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x1e0(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x1e4(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash7
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash7

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1f0)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x1f0(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1f4)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x1f4(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash7:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x308dc96c
LI expect_low,  0xb4c688f8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x200)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x200(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x204(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash8
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash8

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x210)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x210(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x214)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x214(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash8:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x544820f6
LI expect_low,  0x3a83a758
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x220)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x220(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x224(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash9
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash9

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x230)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x230(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x234)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x234(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash9:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x731624e7
LI expect_low,  0x8e9e7cc7
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x240)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x240(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x244(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP

#######################################
########do_hash10
#######################################
LI  expect1, 8
BGE index_num, expect1, do_hash10

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x250)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x250(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x254)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x254(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP


do_hash10:
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18)  ;
##LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x140)  ;
.insn s 43,0,hash_address,cluster_scratch_hash_mask(cppcmd_data_ref) ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI expect_high, 0x217ff77e
LI expect_low,  0x8250816f
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x260)  ;
.insn s 43,0,base2,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
LI temp_data_2, 0
LWU temp_data_2, 0x260(xfer)
BNE temp_data_2, expect_low, test_failed
LWU temp_data_2, 0x264(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP




#######################################
########done_hash
#######################################
LI  expect1, 8
BGE index_num, expect1, done_hash

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_LOW 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x280)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x280(xfer)
BNE temp_data_2, expect_low, test_failed

LI  address4, 0x04040000
ADDI address4, base, HASH_INDEX_HIGH 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x284)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data_2, 0
LWU temp_data_2, 0x284(xfer)
BNE temp_data_2, expect_high, test_failed

NOP
NOP
NOP






done_hash:
ADDI base, base, 0x0100
ADDI base2, base2, 8
ADDI index_num, index_num, 1
LI  expect2, NUM_INDEXESR
BNE index_num, expect2, hash_index_loop_mult0




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
