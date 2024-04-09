#-----------------------
# TEST_NAME: read_write.S
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

#define expect           x12
#define data_1           x13
#define count            x14
#define expect1          x19
#define expect2          x20
#define expect3          x21
#define expect4          x22
#define expect5          x23
#define expect6          x24
#define mask             x25


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

#-----------------------


LI data_1, 0x44332211
SW data_1, 0x0(xfer)
LI data_1, 0x88776655
SW data_1, 0x4(xfer)
LI data_1, 0xCCBBAA99
SW data_1, 0x8(xfer)
LI data_1, 0x00FFEEDD
SW data_1, 0xC(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# LE reads
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x8);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

ADDI address, address, 2
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LI expect1, 0x44332211
LI expect2, 0x88776655
LI expect3, 0x55443322
LI expect4, 0x99887766
LI expect5, 0x66554433
LI expect6, 0xAA998877

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x8(xfer)
BNE temp_data, expect3, test_failed
LWU temp_data, 0xC(xfer)
BNE temp_data, expect4, test_failed
LWU temp_data, 0x10(xfer)
BNE temp_data, expect5, test_failed
LWU temp_data, 0x14(xfer)
BNE temp_data, expect6, test_failed

# LWBE reads

ADDI address, address, 2
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# read_be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1,0x8);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# read_be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG5_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# read_be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG6_pos,1);

LI expect1, 0x22118877
LI expect2, 0x6655CCBB
LI expect3, 0x33221188
LI expect4, 0x776655CC
LI expect5, 0x44332211
LI expect6, 0x88776655

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x8(xfer)
BNE temp_data, expect3, test_failed
LWU temp_data, 0xC(xfer)
BNE temp_data, expect4, test_failed
LWU temp_data, 0x10(xfer)
BNE temp_data, expect5, test_failed
LWU temp_data, 0x14(xfer)
BNE temp_data, expect6, test_failed

#---------------------
# Rewrite to 0's
#---------------------

LI temp_data, 0
SW temp_data, 0x0(xfer)
SW temp_data, 0x4(xfer)
SW temp_data, 0x8(xfer)
SW temp_data, 0xC(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#---------------------
# Aligned Byte writes
#---------------------

LI data_1, 0x44332211
SW data_1, 0x0(xfer)

# Byte writes
# LE
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x0);
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref);# CPP Command write byte le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# LWBE
ADDI address, address, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x0);
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref);# CPP Command write byte be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

ADDI address, address, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x4);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LI expect1, 0x00332211
LI expect2, 0x44332200

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect2, test_failed

#---------------------
# Rewrite to 0's
#---------------------

LI temp_data, 0
SW temp_data, 0x0(xfer)
SW temp_data, 0x4(xfer)
SW temp_data, 0x8(xfer)
SW temp_data, 0xC(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

#---------------------
# UnAligned Byte writes
#---------------------

LI data_1, 0x44332211
SW data_1, 0x0(xfer)
LI data_1, 0x88776655
SW data_1, 0x4(xfer)

#---------------------------------------
# LE :Byte =  7  6  5  4  3  2  1  0
# BE :Byte =  4  5  6  7  0  1  2  3
#     Data = 88 77 66 55 44 33 22 11
#
# LE 5 bytes of data = 55 44 33 22 11
# LE:  XX XX 55 44    33 22 11 XX
#
# LWBE: 5 bytes of data = 44 33 22 11 88 
# LWBE: 11 88 XX XX       XX 44 33 22 
#---------------------------------------

# LE
ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x4,0x0);
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref);# CPP Command write byte le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# LWBE
ADDI address, address, 9
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x4,0x0);
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref);# CPP Command write byte be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

ADDI address, address, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x1,0x8);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1);

LI expect1, 0x33221100
LI expect2, 0x00005544
LI expect3, 0x00443322
LI expect4, 0x11880000

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x8(xfer)
BNE temp_data, expect3, test_failed
LWU temp_data, 0xC(xfer)
BNE temp_data, expect4, test_failed

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
