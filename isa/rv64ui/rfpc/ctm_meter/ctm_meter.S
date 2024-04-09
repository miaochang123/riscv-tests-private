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

#define meter_num x12
#define stc x13
#define ltc x14
#define exp_stc x15
#define exp_ltc x16
#define size x17

#define cppcmd_data_ref x18
#define address   x19
#define cl_num        x20
#define group_num        x21
#define byte_len   x22
#define xfer x23
#define test_num x24
#define byte_counter x25
#define input_color   x26
#define exp_color   x27
#define check_result   x29
#define meter_address   x31
	
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

LI xfer, CPP_MEM_ADDR 
ADD address, group_num, zero

J test_begin
//-----------------------
//ctm_meter_2698
//-----------------------
begin_ctm_meter_2698:

LI temp_data_1 , 0x3
BEQ exp_color, temp_data_1, exp_red_2698
LI temp_data_1 , 0x2
BEQ exp_color, temp_data_1, exp_red_2698
LI temp_data_1 , 0x1
BEQ exp_color, temp_data_1, exp_yellow_2698
LI temp_data_1 , 0x0
BEQ exp_color, temp_data_1, exp_green_2698


exp_red_2698:
ADDI exp_stc, stc, 0x0
ADDI exp_ltc, ltc, 0x0
J exp_finish_2698

exp_yellow_2698:
SUB  exp_stc, stc, size
ADDI exp_ltc, ltc, 0x0
J exp_finish_2698

exp_green_2698:
SUB  exp_stc, stc, size
SUB  exp_ltc, ltc, size

exp_finish_2698:
LI temp_data_1, 0xfffffffffffffff0
AND meter_address, address, temp_data_1
ADD meter_address, meter_address, meter_num
ADD meter_address, meter_address, input_color

ADDI temp_data, size, 0x0
SD temp_data, 0x20(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,meter_address,memory_unit_meter(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG5_pos,2);
NOP
#############
LI temp_data_1, 0xfffffffffffffff0
AND meter_address, address, temp_data_1
ADD meter_address, meter_address, meter_num

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,meter_address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP

LI check_result, 0x0
LD temp_data, 0x20(xfer)
ADDI temp_data_1, exp_color, 0x0
BNE temp_data, temp_data_1, check_failed_2698
NOP

LD temp_data, 0x30(xfer)
LI temp_data_1, 0xffffffff
AND temp_data, temp_data, temp_data_1
ADDI temp_data_1, exp_stc, 0x0
BNE temp_data, temp_data_1, check_failed_2698
NOP

LD temp_data, 0x30(xfer)
SRLI temp_data, temp_data, 0x20
LI temp_data_1, 0xffffffff
AND temp_data, temp_data, temp_data_1
ADDI temp_data_1, exp_ltc, 0x0
BNE temp_data, temp_data_1, check_failed_2698
NOP
J return_test
NOP

check_failed_2698:
LI check_result, 0x1
J return_test

//-----------------------
//ctm_meter_4115
//-----------------------
begin_ctm_meter_4115:

LI temp_data_1 , 0x3
BEQ exp_color, temp_data_1, exp_red_4115
LI temp_data_1 , 0x2
BEQ exp_color, temp_data_1, exp_red_4115
LI temp_data_1 , 0x1
BEQ exp_color, temp_data_1, exp_yellow_4115
LI temp_data_1 , 0x0
BEQ exp_color, temp_data_1, exp_green_4115


exp_red_4115:
ADDI exp_stc, stc, 0x0
ADDI exp_ltc, ltc, 0x0
J exp_finish_4115

exp_yellow_4115:
SUB  exp_stc, stc, size
ADDI exp_ltc, ltc, 0x0
J exp_finish_4115

exp_green_4115:
ADDI exp_stc, stc, 0x0
SUB  exp_ltc, ltc, size

exp_finish_4115:
LI temp_data_1, 0xfffffffffffffff0

AND meter_address, address, temp_data_1
ADDI meter_address, meter_address, 0x1   #4115
ADD meter_address, meter_address, meter_num
ADD meter_address, meter_address, input_color

ADDI temp_data, size, 0x0
SD temp_data, 0x20(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,meter_address,memory_unit_meter(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG5_pos,2);
NOP
#############
LI temp_data_1, 0xfffffffffffffff0
AND meter_address, address, temp_data_1
ADD meter_address, meter_address, meter_num

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,meter_address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
NOP

LI check_result, 0x0
LD temp_data, 0x20(xfer)
ADDI temp_data_1, exp_color, 0x0
BNE temp_data, temp_data_1, check_failed_4115
NOP

LD temp_data, 0x30(xfer)
LI temp_data_1, 0xffffffff
AND temp_data, temp_data, temp_data_1
ADDI temp_data_1, exp_stc, 0x0
BNE temp_data, temp_data_1, check_failed_4115
NOP

LD temp_data, 0x30(xfer)
SRLI temp_data, temp_data, 0x20
LI temp_data_1, 0xffffffff
AND temp_data, temp_data, temp_data_1
ADDI temp_data_1, exp_ltc, 0x0
BNE temp_data, temp_data_1, check_failed_4115
NOP
J return_test
NOP

check_failed_4115:
LI check_result, 0x1


return_test:
LI temp_data_2, 0x1
BEQ test_num, temp_data_2, return_test1
LI temp_data_2, 0x2
BEQ test_num, temp_data_2, return_test2
LI temp_data_2, 0x3
BEQ test_num, temp_data_2, return_test3
LI temp_data_2, 0x4
BEQ test_num, temp_data_2, return_test4
LI temp_data_2, 0x5
BEQ test_num, temp_data_2, return_test5
LI temp_data_2, 0x6
BEQ test_num, temp_data_2, return_test6
LI temp_data_2, 0x7
BEQ test_num, temp_data_2, return_test7
LI temp_data_2, 0x8
BEQ test_num, temp_data_2, return_test8
LI temp_data_2, 0x9
BEQ test_num, temp_data_2, return_test9
LI temp_data_2, 0x10
BEQ test_num, temp_data_2, return_test10
LI temp_data_2, 0x11
BEQ test_num, temp_data_2, return_test11
LI temp_data_2, 0x12
BEQ test_num, temp_data_2, return_test12
LI temp_data_2, 0x13
BEQ test_num, temp_data_2, return_test13
LI temp_data_2, 0x14
BEQ test_num, temp_data_2, return_test14
LI temp_data_2, 0x15
BEQ test_num, temp_data_2, return_test15
LI temp_data_2, 0x16
BEQ test_num, temp_data_2, return_test16
LI temp_data_2, 0x17
BEQ test_num, temp_data_2, return_test17
LI temp_data_2, 0x18
BEQ test_num, temp_data_2, return_test18
LI temp_data_2, 0x19
BEQ test_num, temp_data_2, return_test19
LI temp_data_2, 0x20
BEQ test_num, temp_data_2, return_test20
LI temp_data_2, 0x21
BEQ test_num, temp_data_2, return_test21
LI temp_data_2, 0x22
BEQ test_num, temp_data_2, return_test22
LI temp_data_2, 0x23
BEQ test_num, temp_data_2, return_test23

//----------------------
// Start some 2698 cases
//----------------------
test_begin:
# test_num=1    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000100000002
SD temp_data, 0x0(xfer)
LI temp_data, 0x0
SD temp_data, 0x8(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000100000002
BNE temp_data, temp_data_1, test_failed
NOP
LD temp_data, 0x18(xfer)
LI temp_data_1, 0x0
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x1
LI meter_num, 0x0  #[3]
LI stc, 0x2
LI ltc, 0x1
LI size, 0x1
LI input_color, 0x0 #[2:1]
LI exp_color, 0x0
NOP
J begin_ctm_meter_2698
NOP

return_test1:
BNEZ check_result, test_failed

###############
# test_num=2    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000200000004
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
ADDI address, address, 0x8
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000200000004
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x2
LI meter_num, 0x0 #[3]
LI stc, 0x1
LI ltc, 0x0
LI size, 0x1
LI input_color, 0x0 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_2698
NOP

return_test2:
BNEZ check_result, test_failed

###############
# test_num=3    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x3
LI meter_num, 0x0 #[3]
LI stc, 0x0
LI ltc, 0x0
LI size, 0x1
LI input_color, 0x0 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_2698
NOP

return_test3:
BNEZ check_result, test_failed
###############
# test_num=4    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x4
LI meter_num, 0x8 #[3]
LI stc, 0x4
LI ltc, 0x2
LI size, 0x2
LI input_color, 0x0 #[2:1]
LI exp_color, 0x0
NOP
J begin_ctm_meter_2698
NOP

return_test4:
BNEZ check_result, test_failed
###############
# test_num=5    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x5
LI meter_num, 0x8 #[3]
LI stc, 0x2
LI ltc, 0x0
LI size, 0x2
LI input_color, 0x0 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_2698
NOP

return_test5:
BNEZ check_result, test_failed
###############
# test_num=6    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x6
LI meter_num, 0x8 #[3]
LI stc, 0x0
LI ltc, 0x0
LI size, 0x2
LI input_color, 0x0 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_2698
NOP

return_test6:
BNEZ check_result, test_failed
###############
# test_num=7    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x7
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x2
LI input_color, 0x4 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_2698
NOP

return_test7:
BNEZ check_result, test_failed
###############
# test_num=8    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x8
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x2
LI input_color, 0x2 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_2698
NOP

return_test8:
BNEZ check_result, test_failed
###############
# test_num=9    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x9
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x2
LI input_color, 0x0 #[2:1]
LI exp_color, 0x0
NOP
J begin_ctm_meter_2698
NOP

return_test9:
BNEZ check_result, test_failed

//----------------------
// Start some 4115 cases
//----------------------
# test_num=10    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x10
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x3
LI input_color, 0x0 #[2:1]
LI exp_color, 0x0
NOP
J begin_ctm_meter_4115
NOP

return_test10:
BNEZ check_result, test_failed
###############
# test_num=11    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x11
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x3
LI input_color, 0x2 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_4115
NOP

return_test11:
BNEZ check_result, test_failed
###############
# test_num=12    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x12
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x3
LI input_color, 0x4 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_4115
NOP

return_test12:
BNEZ check_result, test_failed
###############
# test_num=13    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000300000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000300000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x13
LI meter_num, 0x0 #[3]
LI stc, 0x6
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_4115
NOP

return_test13:
BNEZ check_result, test_failed
###############
# test_num=14    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000300000003
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000300000003
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x14
LI meter_num, 0x0 #[3]
LI stc, 0x3
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_4115
NOP

return_test14:
BNEZ check_result, test_failed
###############
# test_num=15    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000300000007
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000300000007
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x15
LI meter_num, 0x0 #[3]
LI stc, 0x7
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_4115
NOP

return_test15:
BNEZ check_result, test_failed
###############
# test_num=16    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x16
LI meter_num, 0x0 #[3]
LI stc, 0x3
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_4115
NOP

return_test16:
BNEZ check_result, test_failed
###############
# test_num=17    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0
SD temp_data, 0x0(xfer)
LI temp_data, 0x0000000600000006
SD temp_data, 0x8(xfer)

ADD address, group_num, zero
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0
BNE temp_data, temp_data_1, test_failed
NOP
LD temp_data, 0x18(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x17
LI meter_num, 0x8  #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x3
LI input_color, 0x0 #[2:1]
LI exp_color, 0x0
NOP
J begin_ctm_meter_4115
NOP

return_test17:
BNEZ check_result, test_failed
###############
# test_num=18    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
ADDI address, address, 0x8
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x18
LI meter_num, 0x8 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x3
LI input_color, 0x2 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_4115
NOP

return_test18:
BNEZ check_result, test_failed
###############
# test_num=19    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000600000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
ADDI address, address, 0x8
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000600000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x19
LI meter_num, 0x8 #[3]
LI stc, 0x6
LI ltc, 0x6
LI size, 0x3
LI input_color, 0x4 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_4115
NOP

return_test19:
BNEZ check_result, test_failed
###############
# test_num=20    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000300000006
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
ADDI address, address, 0x8
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000300000006
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x20
LI meter_num, 0x8 #[3]
LI stc, 0x6
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_4115
NOP

return_test20:
BNEZ check_result, test_failed
###############
# test_num=21    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000300000003
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
ADDI address, address, 0x8
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000300000003
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x21
LI meter_num, 0x8 #[3]
LI stc, 0x3
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_4115
NOP

return_test21:
BNEZ check_result, test_failed
###############
# test_num=22    Initialize STC/LTC for Meter0 and Meter1
LI temp_data, 0x0000000300000007
SD temp_data, 0x0(xfer)

ADD address, group_num, zero
ADDI address, address, 0x8
# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read write data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);
ADD address, group_num, zero
LD temp_data, 0x10(xfer)
LI temp_data_1, 0x0000000300000007
BNE temp_data, temp_data_1, test_failed
NOP

LI test_num, 0x22
LI meter_num, 0x8 #[3]
LI stc, 0x7
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x1
NOP
J begin_ctm_meter_4115
NOP

return_test22:
BNEZ check_result, test_failed
###############
# test_num=23    Initialize STC/LTC for Meter0 and Meter1
LI test_num, 0x23
LI meter_num, 0x8 #[3]
LI stc, 0x3
LI ltc, 0x3
LI size, 0x4
LI input_color, 0x0 #[2:1]
LI exp_color, 0x2
NOP
J begin_ctm_meter_4115
NOP

return_test23:
BNEZ check_result, test_failed







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
