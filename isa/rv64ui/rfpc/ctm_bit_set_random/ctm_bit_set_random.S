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

#define exp_set_result_0 x12
#define exp_set_result_1 x13
#define exp_set_result_2 x14
#define exp_set_result_3 x15

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

.equ CLR_DATA0,    0x1122334400112233  
.equ CLR_DATA1,    0xc001c0defffefffe  
.equ CLR_DATA2,    0xfffefffe4001c0de  
.equ CLR_DATA3,    0xe00ef00e6ffec0de  

.equ CLR_DATA4,    0x0000017c0000017c  
.equ CLR_DATA5,    0x0000017c0000017c  
.equ CLR_DATA6,    0x0000017c0000017c  
.equ CLR_DATA7,    0x0000017c0000017c 

.equ CLR_DATA8,    0x0000001c0000001c  
.equ CLR_DATA9,    0x0000001c0000001c  
.equ CLR_DATA10,   0x0000001c0000001c  
.equ CLR_DATA11,   0x0000001c0000001c 



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
LI temp_data, CLR_DATA0
SD temp_data, 0x30(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x38(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0x40(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0x48(xfer)

#expect_generation
LI temp_data_3, CRC_DATA0
LI temp_data_4, CLR_DATA0
OR exp_set_result_0, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA1
LI temp_data_4, CLR_DATA1
OR exp_set_result_1, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA2
LI temp_data_4, CLR_DATA2
OR exp_set_result_2, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA3
LI temp_data_4, CLR_DATA3
OR exp_set_result_3, temp_data_3, temp_data_4
NOP
NOP
NOP
#######


//----------------------------------
// TEST=1
// 32 BIT Set
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
#set32_1_7
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x6,0x34)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#set32_2_6
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x30)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x5,0x38)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#set32_3_5
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x2,0x30)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x4,0x3c)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#set32_4_1_2_1
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x3,0x30)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x40)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x44)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x4c)  ;
.insn s 43,0,address,memory_unit_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP



#bulk_engine
bit_set_1_7:
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
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP
NOP
NOP

bit_set_2_6:
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
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

bit_set_3_5:
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
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

bit_set_4_1_2_1:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xb0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data_3, 0xb0(xfer)
LD temp_data_4, 0xb8(xfer)
LD temp_data_5, 0xc0(xfer)
LD temp_data_6, 0xc8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP



//----------------------------------
// TEST=2
// 32 BIT Set(Test and set)
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
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

LI temp_data, CLR_DATA0
SD temp_data, 0x50(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x58(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0x60(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0x68(xfer)

LI temp_data, CLR_DATA0
SD temp_data, 0x70(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x78(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0x80(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0x88(xfer)

LI temp_data, CLR_DATA0
SD temp_data, 0x90(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x98(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0xa0(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0xa8(xfer)

#atomic_engine
#test_set32_1_7
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x6,0x34)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#test_set32_2_6
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1,0x50)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x5,0x58)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#test_set32_3_5
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x2,0x70)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x4,0x7c)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
#test_set32_8
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x7,0x90)  ;
.insn s 43,0,address,memory_unit_test_set(cppcmd_data_ref)	 ;
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP



#bulk_engine
test_set32_1_7:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xb0)  ;
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
LD temp_data_3, 0xb0(xfer)
LD temp_data_4, 0xb8(xfer)
LD temp_data_5, 0xc0(xfer)
LD temp_data_6, 0xc8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP


test_set32_2_6:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xd0)  ;
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
LD temp_data_3, 0xd0(xfer)
LD temp_data_4, 0xd8(xfer)
LD temp_data_5, 0xe0(xfer)
LD temp_data_6, 0xe8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

test_set32_3_5:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xf0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

# check push_data
LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
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
LD temp_data_3, 0xf0(xfer)
LD temp_data_4, 0xf8(xfer)
LD temp_data_5, 0x100(xfer)
LD temp_data_6, 0x108(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

test_set32_8:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x110)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

# check push_data
LD temp_data_3, 0x90(xfer)
LD temp_data_4, 0x98(xfer)
LD temp_data_5, 0xa0(xfer)
LD temp_data_6, 0xa8(xfer)
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
LD temp_data_3, 0x110(xfer)
LD temp_data_4, 0x118(xfer)
LD temp_data_5, 0x120(xfer)
LD temp_data_6, 0x128(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

//----------------------------------
// TEST=3
// 32 BIT Set_imm_data_ref
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
#set32_1_7
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0x8,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0xe,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#set32_2_6
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0x9,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0xd,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#set32_3_5
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0xa,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0xc,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#set32_4_1_2_1
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0xb,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0x8,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0x9,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x20,0x8,0x17c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP

#expect_generation
LI temp_data_3, CRC_DATA0
LI temp_data_4, CLR_DATA4
OR exp_set_result_0, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA1
LI temp_data_4, CLR_DATA5
OR exp_set_result_1, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA2
LI temp_data_4, CLR_DATA6
OR exp_set_result_2, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA3
LI temp_data_4, CLR_DATA7
OR exp_set_result_3, temp_data_3, temp_data_4
NOP
NOP
NOP
#######


#bulk_engine
bit_set_imm_data_ref_1_7:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP

NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0x50(xfer)
LD temp_data_4, 0x58(xfer)
LD temp_data_5, 0x60(xfer)
LD temp_data_6, 0x68(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP
NOP
NOP

bit_set_imm_data_ref_2_6:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP

NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

bit_set_imm_data_ref_3_5:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x90)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP

NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0x90(xfer)
LD temp_data_4, 0x98(xfer)
LD temp_data_5, 0xa0(xfer)
LD temp_data_6, 0xa8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

bit_set_imm_data_ref_4_1_2_1:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xb0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP

NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0xb0(xfer)
LD temp_data_4, 0xb8(xfer)
LD temp_data_5, 0xc0(xfer)
LD temp_data_6, 0xc8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP


//----------------------------------
// TEST=4
// 32 BIT Set_imm_bytemask
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
#set32_1_7_bytemask
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x6,0x34)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#set32_2_6_bytemask
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x1,0x30)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x5,0x38)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#set32_3_5_bytemask
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x2,0x30)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x4,0x3c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#set32_4_1_2_1_bytemask
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x3,0x30)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x0,0x40)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x1,0x44)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x0,0x4c)  ;
.insn s 43,0,address,memory_unit_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP



#expect_generation
LI temp_data_3, CRC_DATA0
LI temp_data_4, CLR_DATA8
OR exp_set_result_0, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA1
LI temp_data_4, CLR_DATA9
OR exp_set_result_1, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA2
LI temp_data_4, CLR_DATA10
OR exp_set_result_2, temp_data_3, temp_data_4
##
LI temp_data_3, CRC_DATA3
LI temp_data_4, CLR_DATA11
OR exp_set_result_3, temp_data_3, temp_data_4
NOP
NOP
NOP
#######


#bulk_engine
bit_set_imm_bytemask_1_7:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0x50(xfer)
LD temp_data_4, 0x58(xfer)
LD temp_data_5, 0x60(xfer)
LD temp_data_6, 0x68(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP
NOP
NOP

bit_set_imm_bytemask_2_6:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

bit_set_imm_bytemask_3_5:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x90)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0x90(xfer)
LD temp_data_4, 0x98(xfer)
LD temp_data_5, 0xa0(xfer)
LD temp_data_6, 0xa8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

bit_set_imm_bytemask_4_1_2_1:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xb0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
NOP
LD temp_data_3, 0xb0(xfer)
LD temp_data_4, 0xb8(xfer)
LD temp_data_5, 0xc0(xfer)
LD temp_data_6, 0xc8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

//----------------------------------
// TEST=5
// 32 BIT Set(Test and set imm_bytemask)
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
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x20(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed
NOP
NOP

LI temp_data, CLR_DATA0
SD temp_data, 0x50(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x58(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0x60(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0x68(xfer)

LI temp_data, CLR_DATA0
SD temp_data, 0x70(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x78(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0x80(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0x88(xfer)

LI temp_data, CLR_DATA0
SD temp_data, 0x90(xfer)
LI temp_data, CLR_DATA1
SD temp_data, 0x98(xfer)
LI temp_data, CLR_DATA2
SD temp_data, 0xa0(xfer)
LI temp_data, CLR_DATA3
SD temp_data, 0xa8(xfer)

#atomic_engine
#test_set_imm32_1_7
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x0,0x30)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x6,0x34)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#test_set_imm32_2_6
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x1,0x50)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x5,0x58)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#test_set_imm32_3_5
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x2,0x70)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address, address, 0xc
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x4,0x7c)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP
#test_set_imm32_4_1_2_1
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x3,0x90)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address,address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x0,0xa0)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address,address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x1,0xa4)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP

ADDI address,address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x1c,0x1,0x0,0xac)  ;
.insn s 43,0,address,memory_unit_test_set_imm(cppcmd_data_ref)	 ;
NOP
NOP
NOP



#bulk_engine
test_set_imm32_1_7:
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xb0)  ;
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
LD temp_data_3, 0xb0(xfer)
LD temp_data_4, 0xb8(xfer)
LD temp_data_5, 0xc0(xfer)
LD temp_data_6, 0xc8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP


test_set_imm32_2_6:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xd0)  ;
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
LD temp_data_3, 0xd0(xfer)
LD temp_data_4, 0xd8(xfer)
LD temp_data_5, 0xe0(xfer)
LD temp_data_6, 0xe8(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

test_set_imm32_3_5:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0xf0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

# check push_data
LD temp_data_3, 0x70(xfer)
LD temp_data_4, 0x78(xfer)
LD temp_data_5, 0x80(xfer)
LD temp_data_6, 0x88(xfer)
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
LD temp_data_3, 0xf0(xfer)
LD temp_data_4, 0xf8(xfer)
LD temp_data_5, 0x100(xfer)
LD temp_data_6, 0x108(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
NOP

test_set_imm32_4_1_2_1:
ADD address, group_num, zero # set to initial value
ADDI address,address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x110)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x30	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

# check push_data
LD temp_data_3, 0x90(xfer)
LD temp_data_4, 0x98(xfer)
LD temp_data_5, 0xa0(xfer)
LD temp_data_6, 0xa8(xfer)
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
LD temp_data_3, 0x110(xfer)
LD temp_data_4, 0x118(xfer)
LD temp_data_5, 0x120(xfer)
LD temp_data_6, 0x128(xfer)
NOP
bne temp_data_3, exp_set_result_0, test_failed
NOP
bne temp_data_4, exp_set_result_1, test_failed
NOP
bne temp_data_5, exp_set_result_2, test_failed
NOP
bne temp_data_6, exp_set_result_3, test_failed
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
