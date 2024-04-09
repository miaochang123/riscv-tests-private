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
#define expect0   x1
#define cppcmd_data_ref x3
#define count x4
#define hart_id    x10 #hart csr register

#define end_count x16

#define address   x17
#define cl_num        x18
#define group_num        x19
#define len   x20
#define mem_base   x21
#define temp_data   x2
#define temp_data_1   x5
#define temp_data_2   x6
#define xfer x26
	
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ INIT_RESIDUE_CRC32C,   0xffffffff
.equ CRC_DATA0,    0xFFFFFFFFFFFFFFFF
.equ CRC_DATA1,    0x003000FF6FFFFFFF
.equ CRC_DATA2,    0x0000012500000000
.equ CRC_DATA3,    0x0000002600000000

.equ CRC_DATA4,    0x0000011700000000
.equ CRC_DATA5,    0x0000009600000000
.equ CRC_DATA6,    0xff87b1b30a202487
.equ CRC_DATA7,    0x01710a1c000dec2a

.equ CRC_DATA8,    0x38f27a05015d4002
.equ CRC_DATA9,    0xbb884d850000000e
.equ CRC_DATA10,   0x728bc069fd5cfba4
.equ CRC_DATA11,   0x000000000ed40000

.equ CRC32C_RESULT,   0xFC1CEC17


RVTEST_RV64U
RVTEST_CODE_BEGIN
	

LI len, MEM_SIZE_DIV16
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

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x60)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
ADD address, group_num, zero # set to initial value

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x60(xfer)
LI temp_data_1, CRC_DATA3
BNE temp_data, temp_data_1, test_failed

#Test-CRC32C
#ADDI address, address, 0x1 #set low2 as 01 indicate CRC32C
LI temp_data, INIT_RESIDUE_CRC32C
SW temp_data, 0xa0(xfer) #Store thr initial residue data cpp memeory

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1f,0xa0)  ;
.insn s 43,0,address,memory_unit_crc32c(cppcmd_data_ref)	 ;# CPP Command read
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,2);
NOP
NOP
NOP
#####################################################
LI xfer, CPP_MEM_ADDR 
#store the crc_data to cpp memory 
LI temp_data, CRC_DATA4
SD temp_data, 0x20(xfer)
LI temp_data, CRC_DATA5
SD temp_data, 0x28(xfer)
LI temp_data, CRC_DATA6
SD temp_data, 0x30(xfer)
LI temp_data, CRC_DATA7
SD temp_data, 0x38(xfer)


# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x20)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x18
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x70)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
ADD address, group_num, zero # set to initial value

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x70(xfer)
LI temp_data_1, CRC_DATA7
BNE temp_data, temp_data_1, test_failed

#Test-CRC32C
#ADDI address, address, 0x1 #set low2 as 01 indicate CRC32C

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1f,0xa0)  ;
.insn s 43,0,address,memory_unit_crc32c(cppcmd_data_ref)	 ;# CPP Command read
ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,2);
NOP
NOP
NOP
#####################################################
LI xfer, CPP_MEM_ADDR 
#store the crc_data to cpp memory 
LI temp_data, CRC_DATA8
SD temp_data, 0x40(xfer)
LI temp_data, CRC_DATA9
SD temp_data, 0x48(xfer)
LI temp_data, CRC_DATA10
SD temp_data, 0x50(xfer)
LI temp_data, CRC_DATA11
SD temp_data, 0x58(xfer)

# mem[write,$xfer0,wr_address_top,<<8, wr_address_bot,4],ctx_swap[sig1]
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 3, DRef = 0	
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x10
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read


WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x80(xfer)
LI temp_data_1, CRC_DATA10
BNE temp_data, temp_data_1, test_failed

#read last write64 data
ADDI address,address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
ADD address, group_num, zero # set to initial value

WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x90(xfer)
LI temp_data_1, CRC_DATA11
BNE temp_data, temp_data_1, test_failed


#Test-CRC32C
#ADDI address, address, 0x1 #set low2 as 01 indicate CRC32C

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1b,0xa0)  ;
.insn s 43,0,address,memory_unit_crc32c(cppcmd_data_ref)	 ;# CPP Command read
ADD address, group_num, zero # set to initial value

WAIT_ON_SIGNAL (SIG5_pos,2);
LD temp_data, 0xa0(xfer)

.insn i 19, 1, temp_data, temp_data, (25 | ((-24)<<6) ) # REV25 Bits reversed
 nop
 not temp_data, temp_data
 nop
.insn i 19, 1, temp_data, temp_data, (24 | ((-24)<<6) ) # REV24 bytes swapped
 nop     

LI temp_data_1, 0xffffffff
AND temp_data, temp_data, temp_data_1
NOP
NOP
NOP
LI temp_data_1, CRC32C_RESULT
bne temp_data, temp_data_1, test_failed
NOP
NOP
NOP
######################################################
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
