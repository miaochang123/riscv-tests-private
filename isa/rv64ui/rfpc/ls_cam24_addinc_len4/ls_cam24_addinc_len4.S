#-----------------------
# TEST_NAME: cam24_addinc_len4.S
#      Run on all MEs for higher coverage
#	 1) CAM_LOOKUP24_WORD_AND_ADD - no match and Insert
#	 2) CAM_LOOKUP24_WORD_AND_ADD - no match (no room to add)
#	 3) CAM_LOOKUP24_WORD - MATCH each time
# 	 4) CAM_LOOKUP24_WORD_AND_ADD - MATCH 
# 	 5) CAM_LOOKUP24_WORD - no match 
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

#define zero             x0
#define cppcmd_data_ref  x3
#define temp_data        x4
#define group_num        x5
#define cl_num           x6
#define temp_data_1      x7
#define address          x8
#define xfer             x9
#define hart_id          x10

#define read_data        x11
#define expect           x12
#define data_1           x13
#define count            x14
#define override_data    x15
#define offset           x16
#define count16          x17
#define check_data       x18
#define data_byte0       x19
#define data_byte1       x20
#define data_byte2       x21
#define data_byte3       x22
#define mask             x23

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
SLLI group_num , group_num, 8 #each core has 1024 byte of address space

ADD address, group_num, zero

LI xfer, CPP_MEM_ADDR


###---------------------------------------------
### Init 16 locations to 0
###---------------------------------------------

LI temp_data, 0x0
SD temp_data, 0x0(xfer)
SD temp_data, 0x8(xfer)
SD temp_data, 0x10(xfer)
SD temp_data, 0x18(xfer)
SD temp_data, 0x20(xfer)
SD temp_data, 0x28(xfer)
SD temp_data, 0x30(xfer)
SD temp_data, 0x38(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADDI address, address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);


#SLLI temp_data, cl_num, 5
LI  temp_data,0xF00
AND temp_data,temp_data,a0
SRLI temp_data,temp_data , 4
ADD data_byte0, temp_data, zero
LI count, 0
LI offset, 0
ADDI data_byte3, data_byte0, 4
ADDI data_byte2, data_byte0, 3
ADDI data_byte1, data_byte0, 2
ADDI data_byte0, data_byte0, 1


###---------------------------------------------
###1)  CAM_LOOKUP24_WORD_AND_ADD - no match and Insert
###---------------------------------------------

lookup24_and_insert_loop:

ADD data_1, data_byte0, zero
SLLI temp_data, data_byte1, 8
OR data_1, data_1, temp_data
SLLI temp_data, data_byte2, 16
OR data_1, data_1, temp_data
SLLI temp_data, data_byte3, 24
OR data_1, data_1, temp_data

SW data_1, 0x0(xfer)

ADD check_data, data_1, zero
#	alu_shf[check_data,check_data,OR,1,<<24]   ; On add, the upper byte should get set to 1
# COMMENTED...
NOP

# Need indirect_ref to set bit 4 of length field
# Now override length
LI temp_data, 0x18 # length
ANDI temp_data, temp_data, 0x1F
SLLI temp_data, temp_data, 16

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0);
OR cppcmd_data_ref, cppcmd_data_ref, temp_data # override length
.insn s 43,0,address,cluster_scratch_cam_lookup24_add(cppcmd_data_ref);# cam_lookup24_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

# lookup24 does not match returns 0x80 OR match<<2
SLLI temp_data, count, 2
ORI expect, temp_data, 0x80
LWU temp_data, 0x0(xfer) # return 32bits result
BNE temp_data, expect, test_failed

# Check that data was inserted
ADD address, address, offset
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LWU temp_data, 0x10(xfer)
BNE temp_data, check_data, test_failed
ADDI count, count, 1
ADDI offset, offset, 4

ADDI data_byte0, data_byte0, 1
ADDI data_byte1, data_byte1, 1
ADDI data_byte2, data_byte2, 1
ADDI data_byte3, data_byte3, 1

LI temp_data, 16
BNE count, temp_data, lookup24_and_insert_loop

ADD data_1, data_byte0, zero
SLLI temp_data, data_byte1, 8
OR data_1, data_1, temp_data
SLLI temp_data, data_byte2, 16
OR data_1, data_1, temp_data
SLLI temp_data, data_byte3, 24
OR data_1, data_1, temp_data


###---------------------------------------------
###2)  CAM_LOOKUP24_WORD_AND_ADD - no match (no room to add)
###---------------------------------------------
# lookup24 does not match returns 0xff

LI expect, 0xFF
SW data_1, 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup24_add(cppcmd_data_ref);# cam_lookup24_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LWU temp_data, 0x0(xfer) # return 32bits result
BNE temp_data, expect, test_failed


###---------------------------------------------
###3)  CAM_LOOKUP24_WORD - MATCH each time
###---------------------------------------------

# Now lets lookup24 each word that we inserted
LI mask, 0xFFFF

#SLLI temp_data, cl_num, 5
LI  temp_data,0xF00
AND temp_data,temp_data,a0
SRLI temp_data,temp_data , 4
ADD data_byte0, temp_data, zero
LI count, 0
ADDI data_byte3, data_byte0, 4
ADDI data_byte2, data_byte0, 3
ADDI data_byte1, data_byte0, 2
ADDI data_byte0, data_byte0, 1

lookup24_match_loop:

ADD data_1, data_byte0, zero
SLLI temp_data, data_byte1, 8
OR data_1, data_1, temp_data
SLLI temp_data, data_byte2, 16
OR data_1, data_1, temp_data

SW data_1, 0x0(xfer)

# Now override length
LI temp_data, 0x18 # length
ANDI temp_data, temp_data, 0x1F
SLLI temp_data, temp_data, 16

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x0,0x0);
OR cppcmd_data_ref, cppcmd_data_ref, temp_data # override length
.insn s 43,0,address,cluster_scratch_cam_lookup24_add(cppcmd_data_ref);# cam_lookup24_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG6_pos,1);

LWU temp_data, 0x0(xfer)
AND read_data, temp_data, mask # Mask out upper 16 bits (only compare lower 16 bits)

# MAtch returns   [7:0] = match<<2
# MAtch returns   [15:8] = Upper 8 bit of data entry 
# MAtch returns   [31:16] = Bit set for each entry that matches
NOP
NOP
NOP
NOP

SLLI expect, count, 2
SLLI temp_data, data_byte3, 8
OR expect, expect, temp_data
#ADDI count16, count, 16
#LI temp_data, 1
#SLL temp_data, temp_data, count16
#OR expect, expect, temp_data
BNE read_data, expect, test_failed

ADDI count, count, 1

ADDI data_byte0, data_byte0, 1
ADDI data_byte1, data_byte1, 1
ADDI data_byte2, data_byte2, 1
ADDI data_byte3, data_byte3, 1

LI temp_data, 16
BNE count, temp_data, lookup24_match_loop

ADD data_1, data_byte0, zero
SLLI temp_data, data_byte1, 8
OR data_1, data_1, temp_data
SLLI temp_data, data_byte2, 16
OR data_1, data_1, temp_data


###---------------------------------------------
###4)  Readback everything to check that the increment worked
###---------------------------------------------

#SLLI temp_data, cl_num, 5
LI  temp_data,0xF00
AND temp_data,temp_data,a0
SRLI temp_data,temp_data , 4
ADD data_byte0, temp_data, zero
LI count, 0
LI offset, 0


ADDI data_byte3, data_byte0, 5 # This one should've been incremented... +5 instead of +4
ADDI data_byte2, data_byte0, 3
ADDI data_byte1, data_byte0, 2
ADDI data_byte0, data_byte0, 1

lookup24_read:

ADD data_1, data_byte0, zero
SLLI temp_data, data_byte1, 8
OR data_1, data_1, temp_data
SLLI temp_data, data_byte2, 16
OR data_1, data_1, temp_data
SLLI temp_data, data_byte3, 24
OR data_1, data_1, temp_data

SW data_1, 0x0(xfer)

ADD address, address, offset
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# cluster_scratch_read

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG6_pos,1);

LWU temp_data, 0x10(xfer)

# I don't know why, the data must be masked to 32bits, or it will cause failure???
#LI temp_data_1, 0xFFFFFFFF
#AND temp_data, temp_data, temp_data_1
#AND data_1, data_1, temp_data_1

BNE temp_data, data_1, test_failed
ADDI count, count, 1

ADDI data_byte0, data_byte0, 1
ADDI data_byte1, data_byte1, 1
ADDI data_byte2, data_byte2, 1
ADDI data_byte3, data_byte3, 1
ADDI offset, offset, 4

LI temp_data, 16
BNE count, temp_data, lookup24_read

ADD data_1, data_byte0, zero
SLLI temp_data, data_byte1, 8
OR data_1, data_1, temp_data
SLLI temp_data, data_byte2, 16
OR data_1, data_1, temp_data
SLLI temp_data, data_byte3, 24
OR data_1, data_1, temp_data



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
