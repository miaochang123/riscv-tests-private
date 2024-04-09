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

#define exp_add_result_0 x12
#define exp_add_result_1 x13
#define exp_add_result_2 x14
#define exp_add_result_3 x15

#define cppcmd_data_ref x18
#define address   x19
#define cl_num        x20
#define group_num        x21
#define byte_len   x22
#define xfer x23
#define test_num x24
#define byte_counter x25
#define temp_data_3   x26
#define temp_data_4   x27
#define temp_data_5   x29
#define temp_data_6   x31
	
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ CRC_DATA0,    0x5566778811223344 
.equ CRC_DATA1,    0xdec001c0fefffeff
.equ CRC_DATA2,    0xfefffeffdec001c0
.equ CRC_DATA3,    0x11100121fefffeff

.equ ADD_DATA0,    0x8877665544332211  
.equ ADD_DATA1,    0xc001c0defffefffe  
.equ ADD_DATA2,    0xfffefffe4001c0de  
.equ ADD_DATA3,    0xe00ef00e6ffec0de  

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

LI xfer, CPP_MEM_ADDR 
#store the crc_data to cpp memory 
LI temp_data, CRC_DATA0
SD temp_data, 0x0(xfer)
LI temp_data, CRC_DATA1
SD temp_data, 0x8(xfer)
LI temp_data, CRC_DATA2
SD temp_data, 0x10(xfer)
LI temp_data, CRC_DATA3
SD temp_data, 0x18(xfer)
#
LI temp_data, ADD_DATA0
SD temp_data, 0x30(xfer)
LI temp_data, ADD_DATA1
SD temp_data, 0x38(xfer)
LI temp_data, ADD_DATA2
SD temp_data, 0x40(xfer)
LI temp_data, ADD_DATA3
SD temp_data, 0x48(xfer)

//----------------------------------
// TEST=1
// 32 BIT Adds
//----------------------------------
ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x20
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x40
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

#atomic_engine
#add32_1_3_4
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x2,0x34)  ;
.insn s 43,0,address,memory_unit_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x40)  ;
.insn s 43,0,address,memory_unit_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#add32_2_4_2
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x30)  ;
.insn s 43,0,address,memory_unit_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x38)  ;
.insn s 43,0,address,memory_unit_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x48)  ;
.insn s 43,0,address,memory_unit_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#expect_generation
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_0, temp_data_5, temp_data_6
##
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_1, temp_data_5, temp_data_6
##
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_2, temp_data_5, temp_data_6
##
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_3, temp_data_5, temp_data_6
#######

#bulk_engine
add32_1_3_4:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x50(xfer)
LD temp_data_4, 0x58(xfer)
LD temp_data_5, 0x60(xfer)
LD temp_data_6, 0x68(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP
NOP
NOP

add32_2_4_2:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP

//----------------------------------
// TEST=2
// 64 BIT Adds
//----------------------------------
ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x20
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x40
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

#atomic_engine
#add64_4_4
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x5,0x30)  ;
.insn s 43,0,address,memory_unit_add64(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x5,0x40)  ;
.insn s 43,0,address,memory_unit_add64(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#add64_8
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x7,0x30)  ;
.insn s 43,0,address,memory_unit_add64(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#add64_2_6
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x4,0x30)  ;
.insn s 43,0,address,memory_unit_add64(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x6,0x38)  ;
.insn s 43,0,address,memory_unit_add64(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#expect_generation
LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0
ADD exp_add_result_0, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1
ADD exp_add_result_1, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2
ADD exp_add_result_2, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3
ADD exp_add_result_3, temp_data_3, temp_data_4
NOP
NOP
NOP
#######

#bulk_engine
add64_4_4:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x50(xfer)
LD temp_data_4, 0x58(xfer)
LD temp_data_5, 0x60(xfer)
LD temp_data_6, 0x68(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP
NOP
NOP
add64_8:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP
add64_2_6:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x90)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x90(xfer)
LD temp_data_4, 0x98(xfer)
LD temp_data_5, 0xa0(xfer)
LD temp_data_6, 0xa8(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP

//----------------------------------
// TEST=3
// 32 BIT Adds (Saturate)
//----------------------------------
ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x20
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x40
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

#atomic_engine
#add32_1_3_4
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_addsat(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x2,0x34)  ;
.insn s 43,0,address,memory_unit_addsat(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x40)  ;
.insn s 43,0,address,memory_unit_addsat(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#add32_2_4_2
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x30)  ;
.insn s 43,0,address,memory_unit_addsat(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x38)  ;
.insn s 43,0,address,memory_unit_addsat(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x48)  ;
.insn s 43,0,address,memory_unit_addsat(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#expect_generation
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_0
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_0
J return_add_0

negative_add_0:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_0
J return_add_0

negative_saturate_0:
LI temp_data, 0x0
ADDI exp_add_result_0, temp_data, 0x0
J finish_add_0

positive_saturate_0:
LI temp_data, 0xffffffff
ADDI exp_add_result_0, temp_data, 0x0
J finish_add_0

return_add_0:
AND exp_add_result_0, temp_data_5, temp_data_2
finish_add_0:
AND exp_add_result_0, exp_add_result_0, temp_data_2

##

LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0
SRLI temp_data_3, temp_data_3, 0x20
SRLI temp_data_4, temp_data_4, 0x20

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_1
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_1
J return_add_1

negative_add_1:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_1
J return_add_1

negative_saturate_1:
LI temp_data, 0x0
ADDI temp_data_6, temp_data, 0x0
J finish_add_1

positive_saturate_1:
LI temp_data, 0xffffffff
ADDI temp_data_6, temp_data, 0x0
J finish_add_1

return_add_1:
AND temp_data_6, temp_data_5, temp_data_2
finish_add_1:
AND temp_data_6, temp_data_6, temp_data_2
SLLI temp_data_6, temp_data_6, 0x20
ADD exp_add_result_0, exp_add_result_0, temp_data_6
#########
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_2
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_2
J return_add_2

negative_add_2:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_2
J return_add_2

negative_saturate_2:
LI temp_data, 0x0
ADDI exp_add_result_1, temp_data, 0x0
J finish_add_2

positive_saturate_2:
LI temp_data, 0xffffffff
ADDI exp_add_result_1, temp_data, 0x0
J finish_add_2

return_add_2:
AND exp_add_result_1, temp_data_5, temp_data_2
finish_add_2:
AND exp_add_result_1, exp_add_result_1, temp_data_2

##

LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1
SRLI temp_data_3, temp_data_3, 0x20
SRLI temp_data_4, temp_data_4, 0x20

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_3
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_3
J return_add_3

negative_add_3:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_3
J return_add_3

negative_saturate_3:
LI temp_data, 0x0
ADDI temp_data_6, temp_data, 0x0
J finish_add_3

positive_saturate_3:
LI temp_data, 0xffffffff
ADDI temp_data_6, temp_data, 0x0
J finish_add_3

return_add_3:
AND temp_data_6, temp_data_5, temp_data_2
finish_add_3:
AND temp_data_6, temp_data_6, temp_data_2
SLLI temp_data_6, temp_data_6, 0x20
ADD exp_add_result_1, exp_add_result_1, temp_data_6
#########
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_4
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_4
J return_add_4

negative_add_4:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_4
J return_add_4

negative_saturate_4:
LI temp_data, 0x0
ADDI exp_add_result_2, temp_data, 0x0
J finish_add_4

positive_saturate_4:
LI temp_data, 0xffffffff
ADDI exp_add_result_2, temp_data, 0x0
J finish_add_4

return_add_4:
AND exp_add_result_2, temp_data_5, temp_data_2
finish_add_4:
AND exp_add_result_2, exp_add_result_2, temp_data_2

##

LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2
SRLI temp_data_3, temp_data_3, 0x20
SRLI temp_data_4, temp_data_4, 0x20

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_5
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_5
J return_add_5

negative_add_5:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_5
J return_add_5

negative_saturate_5:
LI temp_data, 0x0
ADDI temp_data_6, temp_data, 0x0
J finish_add_5

positive_saturate_5:
LI temp_data, 0xffffffff
ADDI temp_data_6, temp_data, 0x0
J finish_add_5

return_add_5:
AND temp_data_6, temp_data_5, temp_data_2
finish_add_5:
AND temp_data_6, temp_data_6, temp_data_2
SLLI temp_data_6, temp_data_6, 0x20
ADD exp_add_result_2, exp_add_result_2, temp_data_6
#########
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_6
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_6
J return_add_6

negative_add_6:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_6
J return_add_6

negative_saturate_6:
LI temp_data, 0x0
ADDI exp_add_result_3, temp_data, 0x0
J finish_add_6

positive_saturate_6:
LI temp_data, 0xffffffff
ADDI exp_add_result_3, temp_data, 0x0
J finish_add_6

return_add_6:
AND exp_add_result_3, temp_data_5, temp_data_2
finish_add_6:
AND exp_add_result_3, exp_add_result_3, temp_data_2

##

LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3
SRLI temp_data_3, temp_data_3, 0x20
SRLI temp_data_4, temp_data_4, 0x20

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2
ADD temp_data_5, temp_data_3, temp_data_4
SRLI temp_data, temp_data_4, 0x1f
BNEZ temp_data, negative_add_7
SRLI temp_data, temp_data_5, 0x20
BNEZ temp_data, positive_saturate_7
J return_add_7

negative_add_7:
SRLI temp_data, temp_data_5, 0x20
BEQZ temp_data, negative_saturate_7
J return_add_7

negative_saturate_7:
LI temp_data, 0x0
ADDI temp_data_6, temp_data, 0x0
J finish_add_7

positive_saturate_7:
LI temp_data, 0xffffffff
ADDI temp_data_6, temp_data, 0x0
J finish_add_7

return_add_7:
AND temp_data_6, temp_data_5, temp_data_2
finish_add_7:
AND temp_data_6, temp_data_6, temp_data_2
SLLI temp_data_6, temp_data_6, 0x20
ADD exp_add_result_3, exp_add_result_3, temp_data_6
#########

#bulk_engine
add32_1_3_4_saturate:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x50(xfer)
LD temp_data_4, 0x58(xfer)
LD temp_data_5, 0x60(xfer)
LD temp_data_6, 0x68(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP
NOP
NOP

add32_2_4_2_saturate:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP

//----------------------------------
// TEST=4
// 32 BIT Adds(Test and add)
//----------------------------------
ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x20
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
##############################
ADD address, group_num, zero
ADDI address,address, 0x40
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

LI temp_data, ADD_DATA0
SD temp_data, 0x50(xfer)
LI temp_data, ADD_DATA1
SD temp_data, 0x58(xfer)
LI temp_data, ADD_DATA2
SD temp_data, 0x60(xfer)
LI temp_data, ADD_DATA3
SD temp_data, 0x68(xfer)


#atomic_engine
#add32_1_3_4
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_test_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x2,0x34)  ;
.insn s 43,0,address,memory_unit_test_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x40)  ;
.insn s 43,0,address,memory_unit_test_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#add32_2_4_2
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x50)  ;
.insn s 43,0,address,memory_unit_test_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x58)  ;
.insn s 43,0,address,memory_unit_test_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x68)  ;
.insn s 43,0,address,memory_unit_test_add(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#expect_generation
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA0
LI temp_data_4, ADD_DATA0

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_0, temp_data_5, temp_data_6
##
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA1
LI temp_data_4, ADD_DATA1

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_1, temp_data_5, temp_data_6
##
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA2
LI temp_data_4, ADD_DATA2

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_2, temp_data_5, temp_data_6
##
LI temp_data_2, 0xffffffff
LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_5, temp_data_3, temp_data_4
AND temp_data_5, temp_data_5, temp_data_2

LI temp_data_2, 0xffffffff00000000
LI temp_data_3, CRC_DATA3
LI temp_data_4, ADD_DATA3

AND temp_data_3, temp_data_3, temp_data_2
AND temp_data_4, temp_data_4, temp_data_2

ADD temp_data_6, temp_data_3, temp_data_4
ADD exp_add_result_3, temp_data_5, temp_data_6
#######

#bulk_engine
test_add32_1_3_4:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

# check push_data
LD temp_data_3, 0x30(xfer)
LD temp_data_4, 0x38(xfer)
LD temp_data_5, 0x40(xfer)
LD temp_data_6, 0x48(xfer)
NOP
LI temp_data, CRC_DATA0
bne temp_data_3, temp_data, test_failed
NOP
LI temp_data, CRC_DATA1
bne temp_data_4, temp_data, test_failed
NOP
LI temp_data, CRC_DATA2
bne temp_data_5, temp_data, test_failed
NOP
LI temp_data, CRC_DATA3
bne temp_data_6, temp_data, test_failed
NOP
NOP
NOP
# check dcache_data
LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
NOP


test_add32_2_4_2:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x90)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

# check push_data
LD temp_data_3, 0x50(xfer)
LD temp_data_4, 0x58(xfer)
LD temp_data_5, 0x60(xfer)
LD temp_data_6, 0x68(xfer)
NOP
LI temp_data, CRC_DATA0
bne temp_data_3, temp_data, test_failed
NOP
LI temp_data, CRC_DATA1
bne temp_data_4, temp_data, test_failed
NOP
LI temp_data, CRC_DATA2
bne temp_data_5, temp_data, test_failed
NOP
LI temp_data, CRC_DATA3
bne temp_data_6, temp_data, test_failed
NOP
NOP
NOP
# check dcache_data
LD temp_data_3, 0x90(xfer)
LD temp_data_4, 0x98(xfer)
LD temp_data_5, 0xa0(xfer)
LD temp_data_6, 0xa8(xfer)
NOP
bne temp_data_3, exp_add_result_0, test_failed
NOP
bne temp_data_4, exp_add_result_1, test_failed
NOP
bne temp_data_5, exp_add_result_2, test_failed
NOP
bne temp_data_6, exp_add_result_3, test_failed
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
