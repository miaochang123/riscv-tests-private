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

#define exp_xor_result_0 x12
#define exp_xor_result_1 x13
#define exp_xor_result_2 x14
#define exp_xor_result_3 x15

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
SD temp_data, 0x60(xfer)
LI temp_data, ADD_DATA1
SD temp_data, 0x68(xfer)
LI temp_data, ADD_DATA2
SD temp_data, 0x70(xfer)
LI temp_data, ADD_DATA3
SD temp_data, 0x78(xfer)

//----------------------------------
// write_dcache
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
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
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
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
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
ADDI address,address, 0x60
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

//----------------------------------
// xor_caculation
//----------------------------------
#atomic_engine
#xor32_1_7
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x60)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x6,0x64)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP


#xor32_2_6
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x60)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x5,0x68)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#xor32_3_5
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x2,0x60)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x4,0x6c)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#xor32_4_4
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x60)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x70)  ;
.insn s 43,0,address,memory_unit_xor(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP

#expect_generation
LI temp_data_1, CRC_DATA0
LI temp_data_2, ADD_DATA0
XOR exp_xor_result_0, temp_data_1, temp_data_2

LI temp_data_1, CRC_DATA1
LI temp_data_2, ADD_DATA1
XOR exp_xor_result_1, temp_data_1, temp_data_2

LI temp_data_1, CRC_DATA2
LI temp_data_2, ADD_DATA2
XOR exp_xor_result_2, temp_data_1, temp_data_2

LI temp_data_1, CRC_DATA3
LI temp_data_2, ADD_DATA3
XOR exp_xor_result_3, temp_data_1, temp_data_2

######

#bulk_engine
xor32_1_7:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x80)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0x80(xfer)
LD temp_data_4, 0x88(xfer)
LD temp_data_5, 0x90(xfer)
LD temp_data_6, 0x98(xfer)
NOP
bne temp_data_3, exp_xor_result_0, test_failed
NOP
bne temp_data_4, exp_xor_result_1, test_failed
NOP
bne temp_data_5, exp_xor_result_2, test_failed
NOP
bne temp_data_6, exp_xor_result_3, test_failed
NOP
NOP
NOP

xor32_2_6:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xa0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0xa0(xfer)
LD temp_data_4, 0xa8(xfer)
LD temp_data_5, 0xb0(xfer)
LD temp_data_6, 0xb8(xfer)
NOP
bne temp_data_3, exp_xor_result_0, test_failed
NOP
bne temp_data_4, exp_xor_result_1, test_failed
NOP
bne temp_data_5, exp_xor_result_2, test_failed
NOP
bne temp_data_6, exp_xor_result_3, test_failed
NOP

xor32_3_5:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xc0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0xc0(xfer)
LD temp_data_4, 0xc8(xfer)
LD temp_data_5, 0xd0(xfer)
LD temp_data_6, 0xd8(xfer)
NOP
bne temp_data_3, exp_xor_result_0, test_failed
NOP
bne temp_data_4, exp_xor_result_1, test_failed
NOP
bne temp_data_5, exp_xor_result_2, test_failed
NOP
bne temp_data_6, exp_xor_result_3, test_failed
NOP


xor32_4_4:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xe0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0xe0(xfer)
LD temp_data_4, 0xe8(xfer)
LD temp_data_5, 0xf0(xfer)
LD temp_data_6, 0xf8(xfer)
NOP
bne temp_data_3, exp_xor_result_0, test_failed
NOP
bne temp_data_4, exp_xor_result_1, test_failed
NOP
bne temp_data_5, exp_xor_result_2, test_failed
NOP
bne temp_data_6, exp_xor_result_3, test_failed
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
