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
.equ CPP_MEM_ADDR,      0xf0000000

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

LI xfer , CPP_MEM_ADDR

config_xpb:
    LI temp_data , 0x2
    SW  temp_data , 0x0(xfer)
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the FSM
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x1
    SW temp_data , 0x0(xfer)
    ADDI address , address ,TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x87
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_RING
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x1
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_TEST
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0xff00
    SLLI temp_data , temp_data , 0x10
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_CFG
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)


    LI temp_data , 1 
    LI temp_data_1 , 0xAAF
    SLLI temp_data , temp_data , 0x1c
    OR temp_data , temp_data, temp_data_1
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_LFSR_CFG
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x4
    SLLI temp_data , temp_data , 0x1c
    OR temp_data , temp_data , 0x2
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_WHITEN_CONTROL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x83388338
    SW temp_data , 0x0(xfer)
    ADDI address , address , TRNG_WHITEN_CONFIG
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x7d0
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_MON_PERIOD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x1c2
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_MON_ONES_MIN
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x226
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_MON_ONES_MAX
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x40
    SLLI temp_data , temp_data , 0x10
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_MON_MAX_RUN_LEN
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data , 0x6
    SW  temp_data , 0x0(xfer)
    ADDI address , address , TRNG_ASYNC_CMD
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 ;# Reset the async generator
    LI address , CLS_TRNG_XPB_DEVICE_ID
    SLLI address , address , 0x10
    WAIT_ON_SIGNAL (SIG1_pos,1)

LI data_mask , 0x0
LI address , 6
SLLI address , address , 0x10
LI shift_num , 0x28
LI count , 0x0 
LI xfer , CPP_MEM_ADDR
LI expect , 0x300
ADD expect , expect , xfer
LI count_m32 , 0x0
read_out_data:
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)
    WAIT_ON_SIGNAL (SIG1_pos,1)
    LD temp_data , 0x0(xfer)
    LD temp_data , 0x0(xfer)
    LD temp_data , 0x0(xfer)
    BEQ temp_data , data_mask , read_out_data
    ADDI count , count , 0x1
    ADDI count_m32 , count_m32 , 0x1
    ADDI count_m32 , count_m32 , 0x1
    BNE count , shift_num , read_out_data

#LI address , 0x6
#SLLI address , address , 0x10
#LI data_mask , 0x0
#LI count , 0x0
#LI count16 , 0x28
#LI expect , 0x300
#LI xfer , CPP_MEM_ADDR
#ADD expect , expect , xfer
#read_out_data:
#    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
#    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)
#    WAIT_ON_SIGNAL (SIG1_pos,1)
#    LD temp_data , 0x0(xfer)
#    BEQ temp_data , data_mask , read_out_data
#    ADDI count , count , 1
#    SD temp_data , 0x0(expect)
#    ADDI expect , expect , 0x8
#    BNE count , count16 , read_out_data

#LI count16 , 0x2
#LI count_m32 , 0x2
#LI expect , 0x300
#ADD expect , expect , xfer
#LI data_mask , 0x0
#LI expect_or_mask , 0x1
#check_loop: #check if there are two values same
#    LD temp_data , 0x0(xfer)
#    ADD xfer , xfer , 0x8
#    ADD count_m32 , count_m32 , -1
#    ADDI address , xfer , 0x0
#    inner_loop:
#        LD expect , 0x0(address)
#        BEQ temp_data , xfer, test_failed
#        ADD address , address , 0x8
#        ADD count_m32 , count_m32 , -1
#        BNE data_mask , count_m32 , inner_loop
#    ADD count16 , count16 , -1
#    BNE count16 , expect_or_mask, check_loop



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
