;-----------------------
; TEST_NAME: me_local_scratch_rw.uc
;----------------------- 

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
#define inc_amount              x4
#define hart_id                 x10 #hart csr register
#define data_mask               x11
#define count              x12
#define len                     x13
#define trans_count                   x14
#define expect                  x15
#define expect_high             x16
#define offest                  x17
#define address                 x19
#define wdata                   x20
#define il_num                  x21 # island num
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
.equ LOCAL_SCRATCH_SIZE    ,64
.equ LOCAL_SCRATCH_COUNT_LEN_LTE_4		,16
.equ LOCAL_SCRATCH_COUNT_LEN_GT_4		,8
.equ LOCAL_SCRATCH_COUNT_LEN_GT_8		,8
.equ START_LEN  , 1
.equ END_LEN   ,  17
RVTEST_RV64U
RVTEST_CODE_BEGIN

get_core_num:
        LI temp_data , 0xff
        AND cl_num ,  a0 , temp_data  # core number
        LI temp_data , 0xf00
        AND group_num , a0 , temp_data
        SRLI group_num , group_num , 0x8 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
        SLLI address , group_num , 0x6
        LI temp_data , 0x1ff0000
        ADD il_num , temp_data , a0
        SRLI il_num , il_num , 0x10

#;------------------------------------------
#; BEGIN LOCAL_SCRATCH_RW test
#;------------------------------------------
LI temp_data , 0x1
SLLI temp_data , temp_data , 0x1a
OR address , address , temp_data
#Unique DATA for each ME
LI temp_data , 0x0
SLLI temp_data_1 , il_num , 0x1c
OR wdata , temp_data , temp_data_1
SLLI temp_data_1 , group_num , 0x18
OR wdata , wdata , temp_data_1

LI len , END_LEN

LOCAL_SCRATCH_done_read_checks:
#load_addr[return_address,LOCAL_SCRATCH_done_read_checks#]
#immed[data_ref,0]

LOCAL_SCRATCH_outer_loop:
        LI len , START_LEN
        LOCAL_SCRATCH_len_loop:
                #local_csr_wr[T_index,data_ref]	; Write T_index with data_ref (Start at either $xfer0 or $xfer1)
                LI offest , 0x0
                SLLI inc_amount , len , 0x2
                LI temp_data , 0x10
                SUB temp_data_1 , temp_data , len
                ADDI temp_data , temp_data_1 , 0x0
                SLLI offest , temp_data_1 , 0x1
                ADD offest , offest , temp_data
                LI temp_data , 0x8
                BGT len , temp_data , LOCAL_SCRATCH_set_len8_limit
                LI temp_data , 0x4
                BGT len , temp_data , LOCAL_SCRATCH_set_len4_limit
                LI trans_count , LOCAL_SCRATCH_COUNT_LEN_LTE_4
                J LOCAL_SCRATCH_set_count
        LOCAL_SCRATCH_set_len4_limit:
                LI trans_count , LOCAL_SCRATCH_COUNT_LEN_GT_4
                J LOCAL_SCRATCH_set_count
        LOCAL_SCRATCH_set_len8_limit:
                LI trans_count , LOCAL_SCRATCH_COUNT_LEN_GT_8
        LOCAL_SCRATCH_set_count:
                ADDI count , trans_count , 0x0
        LOCAL_SCRATCH_write_loop:
                ADDI temp_data , wdata , 0x0
                SW temp_data , 0x0(xfer)
                ADDI temp_data , wdata , 0x1
                SW temp_data , 0x4(xfer)
                ADDI temp_data , wdata , 0x2
                SW temp_data , 0x8(xfer)
                ADDI temp_data , wdata , 0x3
                SW temp_data , 0xc(xfer)
                ADDI temp_data , wdata , 0x4
                SW temp_data , 0x10(xfer)
                ADDI temp_data , wdata , 0x5
                SW temp_data , 0x14(xfer)
                ADDI temp_data , wdata , 0x6
                SW temp_data , 0x18(xfer)
                ADDI temp_data , wdata , 0x7
                SW temp_data , 0x1c(xfer)
                ADDI temp_data , wdata , 0x8
                SW temp_data , 0x20(xfer)
                ADDI temp_data , wdata , 0x9
                SW temp_data , 0x24(xfer)
                ADDI temp_data , wdata , 0xa
                SW temp_data , 0x28(xfer)
                ADDI temp_data , wdata , 0xb
                SW temp_data , 0x2c(xfer)
                ADDI temp_data , wdata , 0xc
                SW temp_data , 0x30(xfer)
                ADDI temp_data , wdata , 0xd
                SW temp_data , 0x34(xfer)
                ADDI temp_data , wdata , 0xe
                SW temp_data , 0x38(xfer)
                ADDI temp_data , wdata , 0xf
                SW temp_data , 0x3c(xfer)
                LI temp_data , 0x0
                SW temp_data , 0x40(xfer)
        ADDI temp_data , len , -1
        SLLI temp_data , temp_data , 0x8
        LI temp_data_1 , 0x88
        OR temp_data , temp_data , temp_data_1
