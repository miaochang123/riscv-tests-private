#;-----------------------
#; TEST_NAME: me_local_scratch_rw.uc
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
#define zero                    x0
#define cppcmd_data_ref         x3
#define count_len_loop          x4
#define hart_id                 x10 
#define data_mask               x11
#define count                   x12
#define len                     x13
#define count_load_loop         x14
#define expect                  x15
#define expect_addr             x16
#define offest                  x17
#define address                 x19
#define wdata                   x20
#define il_num                  x21 
#define cl_num                  x22
#define group_num               x23
#define temp_data               x24
#define temp_data_1             x25
#define tcount                  x26
#define xfer                    x27
#define jump_offset             x30
#define taddress                x31

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
        SRLI group_num , group_num , 0x8 
        SLLI address , group_num , 0x6
        LI temp_data , 0x1ff0000
        AND il_num , a0 , temp_data
        SRLI il_num , il_num , 0x10

LI data_mask , 0x0
LI count , 0x6
LI len , 0x1
gen_base_data:
        SLLI address , group_num , 0xb
        SLLI wdata , il_num , 0x1c
        SLLI temp_data , group_num , 0x18
        OR wdata , wdata , temp_data

        LI xfer , CPP_MEM_ADDR
        ADD xfer , xfer , address
        #ADDI xfer , xfer , 0x200 # (address + address + 0x200) for store expect value

LOCAL_SCRATCH_outer_loop:
        LI temp_data , 0x4
        LI count_load_loop , 0x8
        LI expect_addr , CPP_MEM_ADDR
        ADD expect_addr , expect_addr , address
        ADDI expect_addr , expect_addr , 0x400
        BLT len , temp_data , set_len_lte4
        BEQ len , temp_data , set_len_bgt4
        BGT len , temp_data , set_len_bgt4
        set_len_lte4:
                LI count_load_loop , 0x10
                SLL jump_offset , count_load_loop , len
                J after_set_load_loop
        set_len_bgt4:
                LI count_load_loop , 0x8
                SLL jump_offset , count_load_loop , len
                J after_set_load_loop      

        after_set_load_loop:
                ADDI taddress , address , 0x0

        LOCAL_SCRATCH_inter_loop:
        ADDI tcount , count_load_loop , 0x0
        SLL tcount , tcount , len
        #SRLI tcount , tcount , 0x1
        load_data_loop:
                SW wdata , 0x0(xfer)
                SW wdata , 0x0(expect_addr)
                ADDI wdata , wdata , 0x1
                ADDI tcount , tcount , -1
                ADDI xfer , xfer, 0x4
                ADDI expect_addr , expect_addr , 0x4
                BNE tcount , data_mask , load_data_loop

        ADDI tcount , count_load_loop , 0x0
        ADDI taddress , address , 0x0
        write_data_loop:
                LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
                LI temp_data_1 , 0xffff
                AND temp_data_1 , taddress ,  temp_data_1
                ADD cppcmd_data_ref , cppcmd_data_ref , temp_data_1 # modify data ref
                LI temp_data_1 , 0x1
                SLL temp_data_1 , temp_data_1 , len
                ADDI temp_data_1 , temp_data_1 , -1
                SLL temp_data_1 , temp_data_1 , 0x10
                ADD cppcmd_data_ref , cppcmd_data_ref , temp_data_1 # modify len
                .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
                LI temp_data_1 , 0x1
                SLL temp_data_1 , temp_data_1 , len
                SLL temp_data_1 , temp_data_1 , 0x2
                ADD taddress , temp_data_1 , taddress
                WAIT_ON_SIGNAL (SIG1_pos,1)
                ADDI tcount , tcount , -1
                BNE tcount , data_mask , write_data_loop

        ADD tcount , count_load_loop , 0x0
        SLL tcount , tcount , len
        #SRLI tcount , tcount , 0x1
        ADDI taddress , address , 0x0
        read_data_loop:
                LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x400) 
                LI temp_data_1 , 0xffff
                AND temp_data_1 , taddress , temp_data_1
                ADD cppcmd_data_ref , cppcmd_data_ref , temp_data_1 # modify data ref
                .insn s 43,0,taddress,cluster_scratch_read_le(cppcmd_data_ref)
                ADDI taddress , taddress , 0x4
                WAIT_ON_SIGNAL (SIG2_pos,1)
                ADDI tcount , tcount , -1
                BNE tcount , data_mask , read_data_loop

        ADDI tcount , count_load_loop , 0x0
        SLL tcount , tcount , len
        SRLI tcount , tcount , 0x1
        LI expect_addr , CPP_MEM_ADDR
        ADD expect_addr , expect_addr , address
        check_data_loop:
                LD expect , 0x0(expect_addr)
                LD temp_data , 0x400(expect_addr)
                BNE expect , temp_data , test_failed
                ADDI tcount , tcount , -1
                ADDI expect_addr , expect_addr , 0x8
                BNE tcount , data_mask , check_data_loop

        ADDI len , len , 0x1
        BNE len , count , LOCAL_SCRATCH_outer_loop
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
