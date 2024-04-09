#;-----------------------
#; TEST_NAME: trng2.uc
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
.equ CPP_MEM_ADDR,      0xf0000000

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
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
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
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
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
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    # XPB write: TRNG Async Command
    LI wdata , 0x4    #  Reset the FSM
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
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
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    add_delay 100
.endm

.macro run_repeatedly
    LI wdata , 0x6
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)
    add_delay 100
.endm


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
    LI  upper_byte , 0xe0000000

LI xfer , CPP_MEM_ADDR

write_trng_lfsr_config:
    LI wdata , 0x10000aaf
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_LFSR_CFG
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

reset_entropy_generator

write_trng_async_ring:
    LI wdata , 0x87
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_RING
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

write_trng_async_test:
    LI wdata , 0x0
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_TEST
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

write_trng_whiten_control:
    LI wdata , 0x40000002
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_WHITEN_CONTROL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

write_trng_whitener_config:
    LI wdata , 0x2cc22cc2
    LI xfer , CPP_MEM_ADDR
    SW wdata , 0x0(xfer)
    ADDI address , address , TRNG_WHITEN_CONFIG
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)


load_lfsr 0x1223

load_incr 0x7c00

run_repeatedly

LI data_mask , 0x0
LI address , 6
SLLI address , address , 0x10
LI shift_num , 0x12c
LI count , 0x0 
LI xfer , CPP_MEM_ADDR
LI expect , CPP_MEM_ADDR
LI address , 6
SLLI address , address , 0x10
read_out_data:
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x1,0x100) 
    .insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)
    WAIT_ON_SIGNAL (SIG5_pos,1)
    LD temp_data , 0x100(expect)
    BEQ temp_data , data_mask , read_out_data
    ADDI count , count , 0x1
    BNE count , shift_num , read_out_data



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
