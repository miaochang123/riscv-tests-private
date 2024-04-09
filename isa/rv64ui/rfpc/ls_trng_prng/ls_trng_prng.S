#;-----------------------
#; TEST_NAME: trng_prng.uc
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

LI xfer , CPP_MEM_ADDR
LI address , CLS_TRNG_XPB_DEVICE_ID
SLLI address , address , 0x10
LI sig_gpr , 0x1
SLLI sig_gpr , sig_gpr , 0x3
OR sig_gpr , sig_gpr , 0x80
get_core_num:
        LI temp_data , 0xff
        AND cl_num ,  a0 , temp_data  # core number
        LI temp_data , 0xf00
        AND group_num , a0 , temp_data
        SRLI group_num , group_num , 0x8 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used

chose_group:
        LI temp_data , 0x0
        BEQ temp_data , group_num , ME0_code

ME1_code:
        WAIT_ON_SIGNAL(SIG7_pos,1)
        LI data_mask , 0x0
        LI shift_num , 0x28
        LI count , 0x0 
        LI xfer , CPP_MEM_ADDR
        LI expect , CPP_MEM_ADDR
        ADDI expect , expect , 0x200
        read_out_data:
                LI address , 6
                SLLI address , address , 0x10
                LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
                .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)
                WAIT_ON_SIGNAL (SIG1_pos,1)
                LD temp_data , 0x0(xfer)
                #BEQ temp_data , data_mask , read_out_data //rtl bug can not use an address for many time in a short time
                ADDI count , count , 0x1
                SD temp_data , 0x0(expect)
                ADDI expect , expect , 0x8
                BNE count , shift_num , read_out_data
                
        LI address , CPP_MEM_ADDR
        LI temp_data , 0x0
        LD temp_data_1 , 0x200(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xffffffffffffffff
        LD temp_data_1 , 0x208(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x0
        LD temp_data_1 , 0x210(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xff8ffffffffe07ff
        LD temp_data_1 , 0x218(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xfffff1c7ffffffc0
        LD temp_data_1 , 0x220(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x07fffffe3fe3ffff
        LD temp_data_1 , 0x228(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xf03f03ffffc71c71
        LD temp_data_1 , 0x230(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xfffe000001fff8ff
        LD temp_data_1 , 0x238(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xfff1ffc0ffffc0ff
        LD temp_data_1 , 0x240(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x0
        LD temp_data_1 , 0x248(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x38fffe38f8007ff8
        LD temp_data_1 , 0x250(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x00c7fc7fc7fc83f0
        LD temp_data_1 , 0x258(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x7e07e7638e38e391
        LD temp_data_1 , 0x260(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x80000000e03fffff
        LD temp_data_1 , 0x268(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xf81e3fffffe3881f
        LD temp_data_1 , 0x270(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xffff00371ffffc7f
        LD temp_data_1 , 0x278(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x701fffe079078fff
        LD temp_data_1 , 0x280(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x0
        LD temp_data_1 , 0x288(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x1c4ec40ffc00e38d
        LD temp_data_1 , 0x290(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x8fe3f8001c0781e3
        LD temp_data_1 , 0x298(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xff03c47103fc710c
        LD temp_data_1 , 0x2a0(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0x06e3e00693e7018f
        LD temp_data_1 , 0x2a8(address)
        BNE temp_data , temp_data_1 , test_failed

        LI temp_data , 0xcdf320f20f2ecaec
        LD temp_data_1 , 0x2b0(address)
        BNE temp_data , temp_data_1 , test_failed

        #LI temp_data , 0x07e0e3fe
        #LWU temp_data_1 , 0x258(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0xf1c01c9f
        #LWU temp_data_1 , 0x25c(address)
        #BNE temp_data , temp_data_1 , test_failed

        #LI temp_data , 0xe24e3fff
        #LWU temp_data_1 , 0x260(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x1ffcc038
        #LWU temp_data_1 , 0x264(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x18e0e180
        #LWU temp_data_1 , 0x268(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x3f3c1f8c
        #LWU temp_data_1 , 0x26c(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x01be246c
        #LWU temp_data_1 , 0x270(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0xe049b1c7
        #LWU temp_data_1 , 0x274(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x1fe0f870
        #LWU temp_data_1 , 0x278(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x0dc41fce
        #LWU temp_data_1 , 0x27c(address)
        #BNE temp_data , temp_data_1 , test_failed

        #LI temp_data , 0x89d91b93
        #LWU temp_data_1 , 0x280(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x8047ecb2
        #LWU temp_data_1 , 0x284(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x1ff680fe
        #LWU temp_data_1 , 0x288(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0x2043bcf1
        #LWU temp_data_1 , 0x28c(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0xbfa3a487
        #LWU temp_data_1 , 0x290(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0xbd4b47a5
        #LWU temp_data_1 , 0x294(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0xa89aea89
        #LWU temp_data_1 , 0x298(address)
        #BNE temp_data , temp_data_1 , test_failed
        #LI temp_data , 0xdb8eb136
        #LWU temp_data_1 , 0x29c(address)
        #BNE temp_data , temp_data_1 , test_failed
        J test_passed

ME0_code:
        LI wdata , 0x0
        SD wdata , 0x0(xfer)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        ADDI address , address , TRNG_ASYNC_RING
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
        .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI wdata , 0x0
        SD wdata , 0x0(xfer)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        ADDI address , address , TRNG_WHITEN_CONFIG
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
        .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI wdata , 0x55f
        SD wdata , 0x0(xfer)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        ADDI address , address , TRNG_LFSR_CFG
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
        .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI wdata , 0xf55f
        SD wdata , 0x0(xfer)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        ADDI address , address , TRNG_LFSR_CFG
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
        .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)


        LI address, 0x0001c003 ##pull from data_master=4,push to data_master=7
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG7,0x0,0x0,0x0,0x8)  ;
        .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)
        
        LI wdata , 0x04000003
        SD wdata , 0x0(xfer)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        ADDI address , address , TRNG_WHITEN_CONTROL
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
        .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI wdata , 0xff1
        SD wdata , 0x0(xfer)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        ADDI address , address , TRNG_LFSR_CFG
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
        .insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)
        LI address , CLS_TRNG_XPB_DEVICE_ID
        SLLI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

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
