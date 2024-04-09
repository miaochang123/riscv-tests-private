#-----------------------------------------------------------------------------------------
# TEST_NAME: rw_all.S
#     Reads and writes unique values to entire local_Scratch array
#
#   7/6/2023: Updata to run on 4 groups  (Each ME reads/writes 1/4th of CLS memory) 
#             Notice:  in kestrel,the size of CLS memory is 32KB,but in merlin, it is 64KB
#             each group: address 0x0000 ~ 0x07ff 
#                                 0x0800 ~ 0x0fff 
#                                 0x1000 ~ 0x17ff 
#                                 0x1800 ~ 0x1fff 
#             use core0 ,group_num:4,7,8,11     configured by nome_rfpc_util.sv
#-----------------------------------------------------------------------------------------


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

#define expect0          x11
#define expect1          x12
#define expect2          x13
#define expect3          x14
#define expect4          x15
#define expect5          x16
#define expect6          x17
#define expect7          x18
#define expect8          x19
#define expect9          x20
#define expect10         x21
#define expect11         x22
#define expect12         x23
#define expect13         x24
#define expect14         x25
#define expect15         x26
#define end_count        x27
#define len              x31



.equ CPP_MEM_ADDR,   0xf0000000
.equ SCRATCH_SIZE_DIV4, 0x4000

RVTEST_RV64U
RVTEST_CODE_BEGIN


LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 10 #   each group has 16384 bytes 

ADD address, group_num, zero

LI xfer, CPP_MEM_ADDR

#-----------------------

LI end_count, SCRATCH_SIZE_DIV4
ADD end_count, address, end_count


write_loop:

ADDI temp_data, address, 0
SW temp_data, 0x0(xfer)
ADDI temp_data, address, 1
SW temp_data, 0x4(xfer)
ADDI temp_data, address, 2
SW temp_data, 0x8(xfer)
ADDI temp_data, address, 3
SW temp_data, 0xC(xfer)
ADDI temp_data, address, 4
SW temp_data, 0x10(xfer)
ADDI temp_data, address, 5
SW temp_data, 0x14(xfer)
ADDI temp_data, address, 6
SW temp_data, 0x18(xfer)
ADDI temp_data, address, 7
SW temp_data, 0x1C(xfer)
ADDI temp_data, address, 8
SW temp_data, 0x20(xfer)
ADDI temp_data, address, 9
SW temp_data, 0x24(xfer)
ADDI temp_data, address, 10
SW temp_data, 0x28(xfer)
ADDI temp_data, address, 11
SW temp_data, 0x2C(xfer)
ADDI temp_data, address, 12
SW temp_data, 0x30(xfer)
ADDI temp_data, address, 13
SW temp_data, 0x34(xfer)
ADDI temp_data, address, 14
SW temp_data, 0x38(xfer)
ADDI temp_data, address, 15
SW temp_data, 0x3C(xfer)

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0xf,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write

WAIT_ON_SIGNAL (SIG3_pos,1);

ADDI address, address, 0x40
BNE address, end_count, write_loop

ADDI temp_data, address, 0
SW temp_data, 0x0(xfer)
ADDI temp_data, address, 1
SW temp_data, 0x4(xfer)
ADDI temp_data, address, 2
SW temp_data, 0x8(xfer)

ADD address, group_num, zero # set to initial value


read_loop:

ADDI expect0, address, 0
ADDI expect1, address, 1
ADDI expect2, address, 2
ADDI expect3, address, 3
ADDI expect4, address, 4
ADDI expect5, address, 5
ADDI expect6, address, 6
ADDI expect7, address, 7
ADDI expect8, address, 8
ADDI expect9, address, 9
ADDI expect10, address, 10
ADDI expect11, address, 11
ADDI expect12, address, 12
ADDI expect13, address, 13
ADDI expect14, address, 14
ADDI expect15, address, 15

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0xf,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# read_le

WAIT_ON_SIGNAL (SIG3_pos,1);

ADDI address, address, 0x40

LWU temp_data, 0x0(xfer)
BNE temp_data, expect0, test_failed
LWU temp_data, 0x4(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x8(xfer)
BNE temp_data, expect2, test_failed
LWU temp_data, 0xC(xfer)
BNE temp_data, expect3, test_failed
LWU temp_data, 0x10(xfer)
BNE temp_data, expect4, test_failed
LWU temp_data, 0x14(xfer)
BNE temp_data, expect5, test_failed
LWU temp_data, 0x18(xfer)
BNE temp_data, expect6, test_failed
LWU temp_data, 0x1C(xfer)
BNE temp_data, expect7, test_failed
LWU temp_data, 0x20(xfer)
BNE temp_data, expect8, test_failed
LWU temp_data, 0x24(xfer)
BNE temp_data, expect9, test_failed
LWU temp_data, 0x28(xfer)
BNE temp_data, expect10, test_failed
LWU temp_data, 0x2C(xfer)
BNE temp_data, expect11, test_failed
LWU temp_data, 0x30(xfer)
BNE temp_data, expect12, test_failed
LWU temp_data, 0x34(xfer)
BNE temp_data, expect13, test_failed
LWU temp_data, 0x38(xfer)
BNE temp_data, expect14, test_failed
LWU temp_data, 0x3C(xfer)
BNE temp_data, expect15, test_failed

BNE address, end_count, read_loop

#ADDI expect0, address, 0
#ADDI expect1, address, 1
#ADDI expect2, address, 2



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
