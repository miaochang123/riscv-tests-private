#;-----------------------
#; TEST_NAME: ls_bad_data_master.uc
#;     
#;  Generates illegal data_master for pushes and pulls
#;  Ensure that things do not stall	
#;-----------------------

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

#define zero                    x0 # zero register
#define cppcmd_data_ref         x3
#define count                   x4
#define hart_id                 x10 #hart csr register
#define data_mask               x11
#define upper_byte              x12
#define count16                 x13
#define shift_num               x14
#define expect                  x15
#define expect_high             x16
#define match_index             x17
#define address                 x19
#define wdata                   x20
#define count_m32               x21
#define cl_num                  x22
#define group_num               x23
#define temp_data               x24
#define temp_data_1             x25
#define expect_high_or_mask     x26
#define xfer                    x27
#define all_ones                x30
#define expect_or_mask          x31

.equ CPP_MEM_ADDR,      0xf0000000
.equ SCRATCH_SIZE_DIV8, 0x2000

RVTEST_RV64U
RVTEST_CODE_BEGIN

get_core_num:
    LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
    AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
    	
    SRLI group_num , group_num , 0x5   # group number move to  4  - F gggg # group number move to  00 0ggg 0000
    ANDI cl_num ,a0, 0xf               # core number
    OR  group_num , group_num , cl_num # set group number as ggg_cccc 
    
    LI temp_data_1 , 0x1
    BGE group_num , temp_data_1, test_passed # Only run in rfpc_cluster0 & rfpc_group0 & (core0)
    SLLI group_num , group_num, 8
    ADD address, group_num, zero

gen_good_write_info:
    LI xfer , CPP_MEM_ADDR
    LI address ,  CPP_MEM_ADDR  #load cpp mem addr
    LI temp_data , 0x6666
    SW temp_data , 0x0(xfer)    #store the add_data to cpp memory
    SW temp_data , 0x4(xfer)
    SW temp_data , 0x8(xfer)
    SW temp_data , 0xc(xfer)    # align 64

write_legal_master:
    LI cppcmd_data_ref , CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1)

gen_illegal_write_info:
    LI address ,  CPP_MEM_ADDR  #load cpp mem addr
    LI temp_data , 0xBAD
    SW temp_data , 0x0(xfer)    #store the add_data to cpp memory
    SW temp_data , 0x4(xfer)
    SW temp_data , 0x8(xfer)
    SW temp_data , 0xc(xfer)

write_illegal_master:
    LI cppcmd_data_ref , CALC_RS1(0x0,0x1,0x0,SIG1,0x0,0x4,0x3,0x0)
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1)

read_data:
    LI cppcmd_data_ref , CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x10)
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1)

compare_result:
    LI expect , 0x6666
    LI temp_data_1 , 0xBAD
    LWU temp_data , 0x10(xfer)
    BEQ temp_data , temp_data_1 , test_failed
    LWU temp_data , 0x14(xfer)
    BEQ temp_data , temp_data_1 , test_failed
    LWU temp_data , 0x18(xfer)
    BEQ temp_data , temp_data_1 , test_failed
    LWU temp_data , 0x1c(xfer)
    BEQ temp_data , temp_data_1 , test_failed


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


    
