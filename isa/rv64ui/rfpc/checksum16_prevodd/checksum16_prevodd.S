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

#define exp_checksum_inv x12
#define exp_checksum_no_inv x13
#define csum16_result_inv   x14
#define csum16_result_no_inv x15
#define temp_data_7   x16
#define temp_data_8   x17

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

.equ CRC_DATA0,    0x8877665544332211
.equ CRC_DATA1,    0xc001c0deccbbaa99
.equ CRC_DATA2,    0xfffefffec001c0de
.equ CRC_DATA3,    0xfffefffec001c0de


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
#store the crc_data to cpp memory 
LI temp_data, CRC_DATA0
SD temp_data, 0x0(xfer)
LI temp_data, CRC_DATA1
SD temp_data, 0x8(xfer)
LI temp_data, CRC_DATA2
SD temp_data, 0x10(xfer)
LI temp_data, CRC_DATA3
SD temp_data, 0x18(xfer)


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
ADD address, group_num, zero # set to initial value

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP
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
BNEZ  byte_len, calc_loop
NOP
NOP
NOT exp_checksum_inv, exp_checksum_no_inv
AND exp_checksum_inv, exp_checksum_inv, temp_data_2
LI temp_data_2, 0x2
BEQ test_num, temp_data_2, return_test2
LI temp_data_2, 0x3
BEQ test_num, temp_data_2, return_test3
LI temp_data_2, 0x4
BEQ test_num, temp_data_2, return_test4


//----------------------------------
// TEST=2
// Even address odd length_3byte
//----------------------------------
test_begin:
LI test_num, 0x2
LI byte_len, 0x4
LI temp_data, 0x5566778811223344 #LWBE in Dcache
SLLI temp_data, temp_data, 0x8
LI temp_data_2, 0xffffffffffffff00
AND temp_data, temp_data, temp_data_2
LI exp_checksum_no_inv, 0x0
J calc_loop

return_test2:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x12,0x1,0x0,0x60)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0x60(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2     
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x12,0x1,0x0,0x50)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0x50(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP

//----------------------------------
// TEST=3
// Odd address even length_6byte
//----------------------------------
LI test_num, 0x3
LI byte_len, 0x8
LI temp_data, 0x5566778811223344 #LWBE in Dcache
LI temp_data_2, 0x00ffffffffffff00
AND temp_data, temp_data, temp_data_2
LI exp_checksum_no_inv, 0x0
J calc_loop

return_test3:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

ADD address, group_num, zero # set to initial value
ADDI address, address, 0X1 #odd address

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x15,0x1,0x0,0x80)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0x80(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2     
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x15,0x1,0x0,0x70)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0x70(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP

//----------------------------------
// TEST=4
// Odd address odd length_7byte
//----------------------------------
LI test_num, 0x4
LI byte_len, 0x8
LI temp_data, 0x5566778811223344 #LWBE in Dcache
LI temp_data_2, 0xffffffffffffff00
AND temp_data, temp_data, temp_data_2
LI exp_checksum_no_inv, 0x0
J calc_loop

return_test4:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x16,0x1,0x0,0xa0)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0xa0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed


#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x16,0x1,0x0,0x90)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0x90(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP

//----------------------------------
// TEST=1,5-8
// test_begin_long
//----------------------------------
J test_begin_long

calc_loop_long:
LI temp_data_2, 0xffff
AND temp_data_1, temp_data, temp_data_2
ADD  exp_checksum_no_inv, exp_checksum_no_inv, temp_data_1
SRLI temp_data_1, exp_checksum_no_inv, 0x10
BEQZ  temp_data_1, skip_add_long
AND exp_checksum_no_inv, exp_checksum_no_inv, temp_data_2
ADD  exp_checksum_no_inv, exp_checksum_no_inv, temp_data_1 #add_carry

skip_add_long:
SRLI temp_data, temp_data, 0x10
ADDI byte_len, byte_len, -2
ADDI byte_counter, byte_counter, 2
LI temp_data_2, 0x8
BEQ byte_counter, temp_data_2, update_data
NOP
NOP
BNEZ  byte_len, calc_loop_long

update_data:
ADDI temp_data, temp_data_3, 0
ADDI temp_data_3, temp_data_4, 0
ADDI temp_data_4, temp_data_7, 0
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long


NOP
NOP
NOT exp_checksum_inv, exp_checksum_no_inv
LI temp_data_2, 0xffff
AND exp_checksum_inv, exp_checksum_inv, temp_data_2
LI temp_data_2, 0x1
BEQ test_num, temp_data_2, return_test1
LI temp_data_2, 0x5
BEQ test_num, temp_data_2, return_test5
LI temp_data_2, 0x6
BEQ test_num, temp_data_2, return_test6
LI temp_data_2, 0x7
BEQ test_num, temp_data_2, return_test7
LI temp_data_2, 0x8
BEQ test_num, temp_data_2, return_test8

//----------------------------------
// TEST=1
// Even address even length_8byte
//----------------------------------
test_begin_long:
LI test_num, 0x1
LI byte_len, 0xa
LI byte_counter, 0x0
LI temp_data, 0x5566778811223344 #8byte
LI temp_data_3, 0xdec001c099aabbcc #8byte
LI temp_data_4, 0xfefffeffdec001c0 #8byte
LI temp_data_7, 0xfefffeffdec001c0 #8byte

SRLI temp_data_5, temp_data, 0x38
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2

SRLI temp_data_6, temp_data_3, 0x38
LI temp_data_2, 0xff
AND temp_data_6, temp_data_6, temp_data_2

SLLI temp_data, temp_data, 0x8
SLLI temp_data_3, temp_data_3, 0x8
ADD  temp_data_3, temp_data_3, temp_data_5
LI temp_data_2, 0xffffffffffff00ff
AND temp_data_3, temp_data_3, temp_data_2
SLLI temp_data_4, temp_data_4, 0x8
ADD  temp_data_4, temp_data_4, temp_data_6

LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test1:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

ADD address, group_num, zero # set to initial value

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x17,0x1,0x0,0x40)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0x40(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2 
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed


#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x17,0x1,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0x30(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2  
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP


//----------------------------------
// TEST=5
// even address even length_24byte
//----------------------------------
LI test_num, 0x5
LI byte_len, 0x1a
LI byte_counter, 0x0
LI temp_data, 0x5566778811223344 #8byte
LI temp_data_3, 0xdec001c099aabbcc #8byte
LI temp_data_4, 0xfefffeffdec001c0 #8byte
LI temp_data_7, 0xfefffeffdec001c0 #8byte

SRLI temp_data_5, temp_data, 0x38
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2

SRLI temp_data_6, temp_data_3, 0x38
LI temp_data_2, 0xff
AND temp_data_6, temp_data_6, temp_data_2

SRLI temp_data_8, temp_data_4, 0x38
LI temp_data_2, 0xff
AND temp_data_8, temp_data_8, temp_data_2

SLLI temp_data, temp_data, 0x8
SLLI temp_data_3, temp_data_3, 0x8
ADD  temp_data_3, temp_data_3, temp_data_5
SLLI temp_data_4, temp_data_4, 0x8
ADD  temp_data_4, temp_data_4, temp_data_6
SLLI temp_data_7, temp_data_7, 0x8
ADD  temp_data_7, temp_data_7, temp_data_8
LI temp_data_2, 0xff
AND temp_data_7, temp_data_7, temp_data_2


LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test5:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x17,0x1,0x2,0xc0)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0xc0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2  
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x17,0x1,0x2,0xb0)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0xb0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2  
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP


//----------------------------------
// TEST=6
// even address odd length_19byte
//----------------------------------
LI test_num, 0x6
LI byte_len, 0x14
LI byte_counter, 0x0
LI temp_data, 0x5566778811223344 #8byte
LI temp_data_3, 0xdec001c099aabbcc #8byte
LI temp_data_4, 0xfefffeffdec001c0 #8byte
LI temp_data_7, 0xfefffeffdec001c0 #8byte

SRLI temp_data_5, temp_data, 0x38
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2

SRLI temp_data_6, temp_data_3, 0x38
LI temp_data_2, 0xff
AND temp_data_6, temp_data_6, temp_data_2

SLLI temp_data, temp_data, 0x8
SLLI temp_data_3, temp_data_3, 0x8
ADD  temp_data_3, temp_data_3, temp_data_5
SLLI temp_data_4, temp_data_4, 0x8
ADD  temp_data_4, temp_data_4, temp_data_6 #only use 4byte

LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test6:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x12,0x1,0x2,0xe0)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0xe0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2 
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x12,0x1,0x2,0xd0)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0xd0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2 
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP

//----------------------------------
// TEST=7
// odd address even length_22byte
//----------------------------------
LI test_num, 0x7
LI byte_len, 0x18
LI byte_counter, 0x0

LI temp_data, 0x5566778811223344 #8byte
LI temp_data_3, 0xdec001c099aabbcc #8byte
LI temp_data_4, 0xfefffeffdec001c0 #8byte
LI temp_data_7, 0xfefffeffdec001c0 #8byte

LI temp_data_2, 0xffffffffffffff00
AND temp_data, temp_data, temp_data_2
LI temp_data_2, 0x00ffffffffffffff
AND temp_data_4, temp_data_4, temp_data_2

LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test7:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

ADD address, group_num, zero # set to initial value
ADDI address, address, 0X1 #odd address

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x15,0x1,0x2,0x50)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0x50(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2 
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x15,0x1,0x2,0xf0)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0xf0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2  
bne csum16_result_inv, exp_checksum_inv, test_failed

NOP
NOP
NOP

//----------------------------------
// TEST=8
// odd address odd length_23byte
//----------------------------------
LI test_num, 0x8
LI byte_len, 0x18
LI byte_counter, 0x0

LI temp_data, 0x5566778811223344 #8byte
LI temp_data_3, 0xdec001c099aabbcc #8byte
LI temp_data_4, 0xfefffeffdec001c0 #8byte
LI temp_data_7, 0xfefffeffdec001c0 #8byte

LI temp_data_2, 0xffffffffffffff00
AND temp_data, temp_data, temp_data_2

LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test8:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x16,0x1,0x2,0x70)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0x70(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2  
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x16,0x1,0x2,0x60)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0x60(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2
bne csum16_result_inv, exp_checksum_inv, test_failed

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
