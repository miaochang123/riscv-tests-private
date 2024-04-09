#;-----------------------
#; TEST_NAME: trng.uc
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

.equ IMB_XPB_DEVICE_ID         , 10
.equ CLS_IM_XPB_DEVICE_ID      , 11
.equ CLS_TRNG_XPB_DEVICE_ID    , 12
.equ CLS_ECCMON_XPB_DEVICE_ID  , 13
.equ CLS_PA_XPB_DEVICE_ID      , 14
.equ TH_TRNG_data              , 0
.equ TRNG_ASYNC_RING           , 0x00
.equ TRNG_ASYNC_TEST           , 0x04
.equ TRNG_ASYNC_CMD            , 0x08
.equ TRNG_ASYNC_STATUS         , 0x0C
.equ TRNG_ASYNC_CFG            , 0x10
.equ TRNG_LFSR_CFG             , 0x20
.equ TRNG_WHITEN_CONTROL       , 0x24
.equ TRNG_WHITEN_CONFIG        , 0x28
.equ TRNG_MON_PERIOD           , 0x30
.equ TRNG_MON_ONES             , 0x34
.equ TRNG_MON_ONES_MIN         , 0x38
.equ TRNG_MON_ONES_MAX         , 0x3c
.equ TRNG_MON_MAX_RUN_LEN      , 0x40
.equ TRNG_LOCK                 , 0x50
.equ TRNG_ALERT                , 0x54
.equ CPP_MEM_ADDR              , 0xf0000000
.equ NUM_RANDOMS_TO_GET	       , 40

.macro add_delay delay_cnt
    LI count , \delay_cnt
    LI data_mask , 0x0
    1:
        NOP
        ADDI count , count , -1
        BNE count , data_mask , 1b
.endm

.macro reset_entropy_generator 
    # XPB write: TRNG Async Command
    LI wdata , 0x2    #  Reset the FSM
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_CMD
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    WAIT_ON_SIGNAL (SIG1_pos,1)
 
    add_delay 5


    # XPB write: TRNG Async Command
    LI wdata , 0x1    #  Reset the FSM
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    WAIT_ON_SIGNAL (SIG1_pos,1)

    add_delay 5

.endm

.macro load_lfsr value
    LI wdata , \value
    SLLI wdata , wdata , 0x10
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_CFG
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    WAIT_ON_SIGNAL (SIG1_pos,1)

    # XPB write: TRNG Async Command
    LI wdata , 0x3    #  Reset the FSM
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    WAIT_ON_SIGNAL (SIG1_pos,1)

    add_delay 5
.endm

.macro load_incr value
    LI wdata , \value
    SLLI wdata , wdata , 0x10
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_CFG
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    WAIT_ON_SIGNAL (SIG1_pos,1)

    # XPB write: TRNG Async Command
    LI wdata , 0x4    #  Reset the FSM
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    add_delay 5
.endm

.macro run_single
    LI wdata , 0x5
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_CMD
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    add_delay 500

.endm



RVTEST_RV64U
RVTEST_CODE_BEGIN

LI data_mask , 0x00000000
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

LI xfer , CPP_MEM_ADDR

reset_entropy_generator 

load_lfsr 0x123

load_incr 0xffc0

run_single

reset_entropy_generator

    LI wdata , 0x1
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_TEST
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    OR address , address , data_mask #Bit[31]=1 means do XPB access
    WAIT_ON_SIGNAL (SIG1_pos,1)

load_lfsr 0x123

load_incr 0xffc0

run_single

check_result:
    ### LI expect , 0x31360001
    li expect,0xe64b35543c9149bb
    LI address , 0x6
    SLLI address , address , 0x10
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)
    LI address , 0x6
    SLLI address , address , 0x10
    LD temp_data , 0x100(xfer)
    WAIT_ON_SIGNAL (SIG1_pos,1)
    BNE temp_data , expect , test_failed



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
