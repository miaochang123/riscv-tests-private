#-----------------------
# TEST_NAME: cam8.S
#      Run on all MEs for higher coverage
#	 1) CAM_LOOKUP8_WORD_AND_ADD - no match and Insert
#	 2) CAM_LOOKUP8_WORD_AND_ADD - no match (no room to add)
#	 3) CAM_LOOKUP8_WORD - MATCH each time
# 	 4) CAM_LOOKUP8_WORD_AND_ADD - MATCH 
# 	 5) CAM_LOOKUP8_WORD - no match 
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

#define read_expect      x11
#define expect           x12
#define data_1           x13
#define count            x14
#define expect_high      x15
#define offset           x16
#define count_m32        x17
#define len              x18

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




LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADDI address, address, 0x20
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

ADDI address, address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

ADDI address, address, 0x60
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);  
###---------------------------------------------
###1)  CAM_LOOKUP8_WORD_AND_ADD - no match and Insert
###---------------------------------------------

LI count, 0
LI offset, 0

lookup8_and_insert_loop:

# insert 1st. byte
ADDI data_1, count, 1
SW data_1, 0x0(xfer)
SLLI read_expect, data_1, 24

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x8,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8_add(cppcmd_data_ref);# cam_lookup8_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADD expect, count, zero
ORI expect, expect, 0x80
LD  temp_data, 0x0(xfer) # return 64bits result
BNE temp_data, expect, test_failed
ADDI count, count, 1

# insert 2nd. byte
ADDI data_1, count, 1
SW data_1, 0x0(xfer)
SLLI temp_data, data_1, 16
OR read_expect, read_expect, temp_data

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x8,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8_add(cppcmd_data_ref);# cam_lookup8_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADD expect, count, zero
ORI expect, expect, 0x80
LD  temp_data, 0x0(xfer) # return 64bits result
BNE temp_data, expect, test_failed
ADDI count, count, 1

# insert 3rd. byte
ADDI data_1, count, 1
SW data_1, 0x0(xfer)
SLLI temp_data, data_1, 8
OR read_expect, read_expect, temp_data

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x8,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8_add(cppcmd_data_ref);# cam_lookup8_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADD expect, count, zero
ORI expect, expect, 0x80
LD  temp_data, 0x0(xfer) # return 64bits result
BNE temp_data, expect, test_failed
ADDI count, count, 1

# insert 4th. byte
ADDI data_1, count, 1
SW data_1, 0x0(xfer)
OR read_expect, read_expect, data_1

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x8,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8_add(cppcmd_data_ref);# cam_lookup8_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADD expect, count, zero
ORI expect, expect, 0x80
LD  temp_data, 0x0(xfer) # return 64bits result
BNE temp_data, expect, test_failed
ADDI count, count, 1

# Check that data was inserted
ADD address, address, offset
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# read_be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LW temp_data, 0x10(xfer)

## for debug
#SW read_expect, 0x0(xfer)
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0); # $xfer2
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# cam_lookup8_add
#
#ADD address, group_num, zero # set to initial value
#WAIT_ON_SIGNAL (SIG1_pos,1);
#
#SW temp_data, 0x10(xfer)
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); # $xfer2
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# cam_lookup8_add
#
#ADD address, group_num, zero # set to initial value
#WAIT_ON_SIGNAL (SIG1_pos,1);
## for debug

BNE temp_data, read_expect, test_failed
ADDI offset, offset, 4

LI temp_data, 0x40
BNE count, temp_data, lookup8_and_insert_loop


###---------------------------------------------
###2)  CAM_LOOKUP8_WORD_AND_ADD - no match (no room to add)
###---------------------------------------------

LI expect, 0xFF
ADDI data_1, count, 1
SW data_1, 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8_add(cppcmd_data_ref);# cam_lookup8_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LD  temp_data, 0x0(xfer) # return 64bits result
BNE temp_data, expect, test_failed


###---------------------------------------------
###3)  CAM_LOOKUP8_WORD - MATCH each time
###---------------------------------------------

# Now lets lookup8 each word that we inserted

LI count, 0
LI expect_high, 0

# MAtch returns   [7:0] = match<<2 (this is a byte_index)
# MAtch returns   [31:8] = Bit set for each byte entry that matches
lookup8_match_loop:

ADDI data_1, count, 1
SW data_1, 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8(cppcmd_data_ref);# cam_lookup8

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADD expect, count, zero
LI temp_data, 8
BLT count, temp_data, check_match0
LI temp_data, 32
SUB count_m32, count, temp_data
BLT count, temp_data, less_than32_0

gteq_32_0:
LI temp_data, 1
SLL temp_data, temp_data, count_m32
ADD expect_high, temp_data, zero
BEQZ zero, check_match0

less_than32_0:
LI temp_data, 1
SLL temp_data, temp_data, count
OR expect, expect, temp_data

check_match0:
LD  temp_data, 0x0(xfer) # return 64bits result
SLLI expect_high, expect_high, 32
ADD expect, expect, expect_high
BNE temp_data, expect, test_failed
#LW temp_data, 0x0(xfer) # low 32bit
#BNE temp_data, expect, test_failed
#LW temp_data, 0x4(xfer) # high 32bit
#BNE temp_data, expect_high, test_failed

ADDI count, count, 1

LI temp_data, 0x40
BNE count, temp_data, lookup8_match_loop


###---------------------------------------------
###4)  CAM_LOOKUP8_WORD_AND_ADD - MATCH 
###    Check that no insert is done
###---------------------------------------------

LI count, 0
LI expect_high, 0
LI len, 15

# MAtch returns   [7:0] = match<<2 (this is a byte_index)
# MAtch returns   [31:8] = Bit set for each byte entry that matches

lookup8_match2_loop:

ADDI data_1, count, 1
SW data_1, 0x0(xfer)

ANDI temp_data, len, 0x1F
SLLI temp_data, temp_data, 16
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0);
OR cppcmd_data_ref, cppcmd_data_ref, temp_data # override length
.insn s 43,0,address,cluster_scratch_cam_lookup8_add(cppcmd_data_ref);# cam_lookup8_add

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADD expect, count, zero
LW  temp_data, 0x0(xfer) # low 32bit
BNE temp_data, expect, test_failed
LW  temp_data, 0x4(xfer) # high 32bit
BNE temp_data, expect_high, test_failed

ADDI count, count, 1

LI temp_data, 0x40
BNE count, temp_data, lookup8_match2_loop

NOP
NOP
NOP
NOP
# Check that No inserts were done by reading next available location
ADDI address, address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

LD  temp_data, 0x40(xfer)
BNE temp_data, zero, test_failed


###---------------------------------------------
###5)  CAM_LOOKUP8_WORD - no match 
###	   All entries should match except for upper 8 bits
###    Check that no insert is done at end by reading next available location (should still be 0)
###---------------------------------------------

# lookup8 does not match returns 0xff
LI expect, 0xFF
SW expect, 0x0(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_cam_lookup8(cppcmd_data_ref);# cam_lookup8

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LW temp_data, 0x0(xfer)
BNE temp_data, expect, test_failed

# Check that No inserts were done by reading next available location
ADDI address, address, 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x40);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

LD  temp_data, 0x40(xfer)
BNE temp_data, zero, test_failed



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
