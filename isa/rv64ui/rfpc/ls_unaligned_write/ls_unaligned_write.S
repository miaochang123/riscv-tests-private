#-----------------------
# TEST_NAME: unaligned_write.S
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

#define data1            x12
#define data2            x13
#define data3            x22
#define expect           x14
#define expect1          x15
#define expect2          x16
#define expect3          x17
#define expect4          x18
#define expect5          x19
#define expect6          x20
#define mask             x21



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

LI mask, 0xFFFFFFFF

# Initialize 6 x 32 bits to 0's
LI temp_data, 0
SW temp_data, 0x0(xfer)
SW temp_data, 0x4(xfer)
SW temp_data, 0x8(xfer)
SW temp_data, 0xC(xfer)
SW temp_data, 0x10(xfer)
SW temp_data, 0x14(xfer)
SW temp_data, 0x18(xfer)
SW temp_data, 0x1c(xfer) 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x5,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

#--------------------------+---------------+---------------+---------------+---------------
#            1   1   1   1 | 1   1   1   1 | 1   1         |               |
# LE :Byte = 9   8   7   6 | 5   4   3   2 | 1   0   9   8 | 7   6   5   4 |  3   2   1   0
#     Data =        22  11 |FF  EE  DD  CC |BB  AA  99  88 |77  66      44 | 33  22  11 
#--------------------------+---------------+---------------+---------------+---------------
# Unaligned Write - length = 1
LI data1, 0x44332211
SW data1, 0x0(xfer)

ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write_le(cppcmd_data_ref);# CPP Command write le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# Unaligned Read
ADD expect1, data1, zero    #0x44332211    

ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed

# Aligned Read
SLLI expect1, data1, 8     #0x33221100
LI temp_data,0xffffffff
AND expect1,expect1,temp_data 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x10(xfer)
BNE temp_data, expect1, test_failed


LI data1, 0x99887766
SW data1, 0x4(xfer)
ADD expect1, data1, zero

LI data2, 0xDDCCBBAA
SW data2, 0x8(xfer)
ADD expect2, data2, zero

LI data3, 0x2211FFEE
SW data3, 0xC(xfer)
ADD expect3, data3, zero

# Unaligned Write - length = 3
ADDI address, address, 6
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x4);
.insn s 43,0,address,cluster_scratch_write_le(cppcmd_data_ref);# CPP Command write le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# Unaligned Readback - length = 3
ADDI address, address, 6
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x8(xfer)
BNE temp_data, expect3, test_failed

# Calculate Expected data
LI expect1, 0xBBAA9988
LI expect2, 0xFFEEDDCC
LI expect3, 0x00002211

# Aligned Readback - length = 3
ADDI address, address, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x10(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x14(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x18(xfer)
BNE temp_data, expect3, test_failed

# ------------------------
# Now lets try Big Endian
# ------------------------

# Initialize 6 x 32 bits to 0's
LI temp_data, 0
SW temp_data, 0x0(xfer)
SW temp_data, 0x4(xfer)
SW temp_data, 0x8(xfer)
SW temp_data, 0xC(xfer)
SW temp_data, 0x10(xfer)
SW temp_data, 0x14(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x5,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

#--------------------------+---------------+---------------+---------------+---------------
#            1   1   1   1 | 1   1   1   1 | 1   1         |               |
# LE :Byte = 9   8   7   6 | 5   4   3   2 | 1   0   9   8 | 7   6   5   4 |  3   2   1   0
#--------------------------+---------------+---------------+---------------+---------------
#            1   1   1   1 | 1   1   1   1 |         1   1 |               |
# BE :Byte = 6   7   8   9 | 2   3   4   5 | 8   9   0   1 | 4   5   6   7 |  0   1   2   3
#     Data =FF  EE         |BB  AA  22  11 |77  66  DD  CC |11      99  88 |     44  33  22
#--------------------------+---------------+---------------+---------------+---------------

# Unaligned Write - length = 1
LI data1, 0x44332211
SW data1, 0x0(xfer)

ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write_be(cppcmd_data_ref);# CPP Command write be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# Unaligned Readback - length = 1
ADD expect1, data1, zero     #0x44332211  

ADDI address, address, 1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# CPP Command read be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed

# Aligned Readback
SRLI expect1, data1, 8    #0x00443322
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# CPP Command read be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x10(xfer)
BNE temp_data, expect1, test_failed


LI data1, 0x99887766
SW data1, 0x4(xfer)
ADD expect1, data1, zero

LI data2, 0xDDCCBBAA
SW data2, 0x8(xfer)
ADD expect2, data2, zero

LI data3, 0x2211FFEE
SW data3, 0xC(xfer)
ADD expect3, data3, zero

# Unaligned Write - length = 3
ADDI address, address, 6
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x4);
.insn s 43,0,address,cluster_scratch_write_be(cppcmd_data_ref);# CPP Command write be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# Unaligned Readback - length = 3
ADDI address, address, 6
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x0);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# CPP Command read be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x8(xfer)
BNE temp_data, expect3, test_failed

# Calculate Expected data
LI expect1, 0x7766DDCC
LI expect2, 0xBBAA2211
LI expect3, 0xFFEE0000

# Aligned Readback - length = 3
ADDI address, address, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x2,0x10);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# CPP Command read be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x10(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x14(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0x18(xfer)
BNE temp_data, expect3, test_failed

# MORE

# Unaligned Write - length = 1
LI data1, 0x44444444
SW data1, 0x0(xfer)

ADDI address, address, 4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write_le(cppcmd_data_ref);# CPP Command write le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# Unaligned Read
ADD expect1, data1, zero

ADDI address, address, 4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read le

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x0(xfer)
BNE temp_data, expect1, test_failed

# Unaligned Write - length = 1
LI data1, 0x33333333
SW data1, 0x0(xfer)

ADDI address, address, 4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write_be(cppcmd_data_ref);# CPP Command write be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

# Unaligned Read
ADD expect1, data1, zero

ADDI address, address, 4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref);# CPP Command read be

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);

LWU temp_data, 0x10(xfer)
BNE temp_data, expect1, test_failed



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
