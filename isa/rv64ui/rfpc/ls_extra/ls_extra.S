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


#define zero            x0 # zero register
#define cppcmd_data_ref x3
#define count           x4
#define hart_id         x10 #hart csr register

#define address         x17
#define cl_num          x18
#define group_num       x19
#define island_num      x20
#define island_num30    x21
#define island_num64    x22
#define temp_mi         x23
#define temp_data       x2
#define temp_data_1     x5
#define temp_data_2     x6
#define expect0         x11
#define expect1         x12
#define expect2         x13
#define expect3         x14
#define xfer            x26


.equ CPP_MEM_ADDR,       0xf0000000

.equ INIT_RESIDUE,       0x87654321
.equ AUTOPUSH_DATA0A,    0x0000000000000111
.equ AUTOPUSH_DATA1A,    0x0000000000000222
.equ AUTOPUSH_DATA2A,    0x0000000000000333
.equ AUTOPUSH_DATA3A,    0x0000000000000444


.equ DATA0B,    0x00000111
.equ DATA1B,    0x00000222
.equ DATA2B,    0x00000333
.equ DATA3B,    0x00000444


RVTEST_RV64U
RVTEST_CODE_BEGIN

##LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
##AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
##SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

SRLI island_num , a0, 0x10 #
ANDI island_num , island_num, 0x7f # island number

ANDI island_num30 , island_num, 0xf # island number[3:0]

SRLI island_num64 , island_num, 0x4 #
ANDI island_num64 , island_num64, 0x7 # island number[6:4]

                                                    
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
##OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
##SLLI group_num , group_num, 8 #each core has 256 byte of address space
	
LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, AUTOPUSH_DATA0A
SD temp_data, 0x0(xfer)
LI temp_data, AUTOPUSH_DATA1A
SD temp_data, 0x8(xfer)
LI temp_data, AUTOPUSH_DATA2A
SD temp_data, 0x10(xfer)
LI temp_data, AUTOPUSH_DATA3A
SD temp_data, 0x18(xfer)


LI address, 0x30200

##write all 8 data to cls reg
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 7, DRef = 0	
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#get expect0~3 
LI expect0, DATA0B
LI expect1, DATA1B
LI expect2, DATA2B
LI expect3, DATA3B

LI temp_mi, 0
SLLI temp_mi, island_num30, 31
SLLI island_num64, island_num64, 16
OR temp_mi, temp_mi, island_num64

OR expect0, expect0, temp_mi
OR expect1, expect1, temp_mi
OR expect2, expect2, temp_mi
OR expect3, expect3, temp_mi

#read  data
LI address, 0x30200

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 7, DRef = 0x40	
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);

#Test-autopush signal cfg
LI temp_data, INIT_RESIDUE
LWU temp_data, 0x40(xfer)
BNE temp_data, expect0, test_failed

#Test-autopush signal cfg
LWU temp_data, 0x48(xfer)
BNE temp_data, expect1, test_failed

#Test-autopush signal cfg
LWU temp_data, 0x50(xfer)
BNE temp_data, expect2, test_failed

#Test-autopush signal cfg
LWU temp_data, 0x58(xfer)
BNE temp_data, expect3, test_failed

LI address, 0x30200

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
