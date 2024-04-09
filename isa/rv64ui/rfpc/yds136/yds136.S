#;-----------------------
#; TEST_NAME: yds136.uc
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
#define zero_mask               x11
#define upper_byte              x12
#define count16                 x13
#define shift_num               x14
#define expect0                 x15
#define expect1                 x16
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
#define sig_gpr                 x30
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
.equ WRITING_ME   , 4
.equ READING_ME   , 7

RVTEST_RV64U
RVTEST_CODE_BEGIN

get_core_num:
        LI temp_data , 0xff
        AND cl_num ,  a0 , temp_data  # core number
        LI temp_data , 0xf00
        AND group_num , a0 , temp_data
        SRLI group_num , group_num , 0x8 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used


# group_num : 0 -> data master  4
# group_num : 2 -> data master  7
LI temp_data , 0x0
LI zero_mask , 0x0
LI count , 0x64
LI xfer , CPP_MEM_ADDR
BEQ temp_data , group_num , cls_csrs

cls_data:
        LI xfer , CPP_MEM_ADDR
        SLLI address , group_num , 0x6
        LI temp_data , 0x6699
        LI temp_data_1 , 0x9966

        SW temp_data , 0x0(xfer)
        SW temp_data_1 , 0x4(xfer)
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
        .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)
        SLLI address , group_num , 0x6
        WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI expect0 , temp_data , 0x0
ADDI expect1 , temp_data_1 , 0x0
read_loop:
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x100) 
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)
        SLLI address , group_num , 0x6
        WAIT_ON_SIGNAL (SIG2_pos,1)
        LWU temp_data , 0x100(xfer)
        BNE expect0 , temp_data , test_failed
        LWU temp_data_1 , 0x104(xfer)
        BNE expect1 , temp_data_1 , test_failed
        ADDI count , count , -1
        BNE count , zero_mask , read_loop
J test_passed
# ME0 will do accesses to a CLS CSR
cls_csrs:
#;--------------------------------------
#; Base for Event Manager = 0x00002_0000
#;--------------------------------------
        LI address , 0x20000
        SLLI temp_data , cl_num , 0x1a
        OR address , address , temp_data
        ADDI address , address , 0x10
        ADDI temp_data_1 , address , 0x0
        LI wdata , 0x1234
        SD wdata , 0x200(xfer)
        ADDI expect0 , wdata ,0x0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x200) 
        .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)
        ADDI address , temp_data_1 , 0x0
        WAIT_ON_SIGNAL (SIG3_pos,1)

read_csr_loop:
        LI address , 0x20000
        SLLI temp_data , cl_num , 0x1a
        OR address , address , temp_data
        ADDI address , address , 0x10
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x400) 
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)
        ADDI address , temp_data_1 ,0x0
        WAIT_ON_SIGNAL (SIG4_pos,1)
        LWU temp_data , 0x400(xfer)
        BNE expect0 , temp_data , test_failed
        ADDI count , count , -1
        BNE count , zero_mask , read_csr_loop

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
