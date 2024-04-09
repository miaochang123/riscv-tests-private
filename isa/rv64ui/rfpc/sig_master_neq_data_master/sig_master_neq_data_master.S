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
#define address1                x12
#define address2                x13
#define shift_num               x14
#define expect                  x15
#define actual                  x16
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
#define taddress                x30
#define expect_or_mask          x31
.equ WRITING_ME   , 0
.equ READING_ME   , 2
.equ CPP_MEM_ADDR,   0xf0000000

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
get_core_num:
        LI temp_data , 0xff
        AND cl_num ,  a0 , temp_data  # core number
        LI temp_data , 0xf00
        AND group_num , a0 , temp_data
        SRLI group_num , group_num , 0x8 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used

LI address , 0x0
chose_group:
        LI temp_data , WRITING_ME
        BEQ temp_data , group_num , writing_me_code
        LI temp_data , READING_ME 
        BEQ temp_data , group_num , reading_me_code
        J test_passed

writing_me_code:
        LI count , 0x20
        LI xfer , CPP_MEM_ADDR
        LI data_mask , 0x0
        LI wdata , 0xabcd1000
        writing_loop:
                SW wdata , 0x0(xfer)
                ADDI xfer , xfer , 0x4
                ADDI count , count , -1
                ADDI wdata , wdata , 0x1
                BNE count , data_mask , writing_loop

ctx0_writing_code:
        ADDI taddress , address , 0x0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x0)  #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x10) #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x20) #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x30)  #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x40)  #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x50)  #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x60)  #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x7,SIG1,0x0,0x8,0x3,0x70)  #override signal master to 7
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)	 
        ADDI taddress , taddress , 0x10
        #WAIT_ON_SIGNAL (SIG1_pos,1)

        LI address, 0x0001c003 ##pull from data_master=4,push to data_master=7
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG7,0x0,0x0,0x0,0x8)  ;
        .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

J test_passed

reading_me_code:
        WAIT_ON_SIGNAL(SIG7_pos,1)
        LI count , 0x20
        LI address , CPP_MEM_ADDR
        LI data_mask , 0x0
        LI  wdata , 0xabcd1000
        reading_loop:
                SW wdata , 0x200(address)
                ADDI address , address , 0x4
                ADDI count , count , -1
                ADDI wdata , wdata , 0x1
                BNE count , data_mask , reading_loop
        
        li address, 0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x300)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x310)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x320)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x330)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x340)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x350)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x360)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x370)  
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
        ADDI address , address , 0x10
        WAIT_ON_SIGNAL (SIG1_pos,1)

LI data_mask , 0x0
LI count , 0x20
LI address1 , CPP_MEM_ADDR
LI address2 , CPP_MEM_ADDR
ADDI address2 , address2 , 0x200
ADDI address1 , address1 , 0x300
check_data:
        LWU expect , 0x0(address2)
        LWU actual , 0x0(address1)
        BNE expect , actual , test_failed
        ADDI address1 , address1 , 0x4
        ADDI address2 , address2 , 0x4
        ADDI count , count , -1
        BNE count , data_mask , check_data

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
