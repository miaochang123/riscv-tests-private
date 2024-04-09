#;-----------------------
#; TEST_NAME: ring_journal.uc
#;	Runs on any # of MEs.  
#;	May need to check how much multiple MEs adds (if anything)
#; Inteneded to test ring_journal command
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
#define data0                    x11
#define ringbase_base           x12
#define ringptr_base            x13
#define zero_data               x14
#define expect                  x15
#define watermark_left          x16
#define ring1                   x17
#define address                 x19
#define size                    x20
#define offset1                 x21
#define cl_num                  x22
#define group_num               x23
#define base                    x24
#define full_empty_sts          x25
#define base1                   x26
#define xfer                    x27
#define temp_data1              x30
#define temp_data2              x31

.equ CPP_MEM_ADDR,      0xf0000000
.equ EMPTY, 0
.equ NOT_FULL_AND_NOT_EMPTY, 1
.equ FULL, 3

.equ FILTER_STATUS,0x0
.equ FILTER_MASK,0x10
.equ FILTER_MATCH,0x18

.equ RING_SIZE,            2048
.equ RING_INDEX ,           6
.equ RING_INDEX_PLUS1 ,     7
.equ RING_INDEX_PLUS2  ,    8
.equ RING_INDEX_PLUS3   ,   9
.equ RING_FULL_THRESHOLD , 1536

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
LI zero_data , 0x0

LI watermark_left , RING_SIZE
LI temp_data1 , RING_FULL_THRESHOLD
SUB watermark_left, watermark_left ,temp_data1

get_core_num:
        LI temp_data1 , 0xff
        AND cl_num ,  a0 , temp_data1
        LI temp_data1 , 0xf00
        AND group_num , a0 , temp_data1
        SRLI group_num , group_num , 0x8

LI ringbase_base , 0x10000
SLLI temp_data1 , cl_num , 26
OR ringbase_base , ringbase_base , temp_data1

LI offset1 , 0x0

LI ring1 , 0x80000
LI data0 , 0x60100
SD data0 , 0x0(xfer)

ADD address , ringbase_base , offset1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI size , RING_SIZE
SLLI data0 , group_num , 16

put_loop:   
    BEQ size , watermark_left , check_full_watermark

ret_from_watermark:
    SW data0 , 0x10(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x14(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x18(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x1c(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x20(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x24(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x28(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x2c(xfer)
    ADDI data0 , data0 , 1

ADDI address , ring1 , 0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x10) 
.insn s 43,0,address,cluster_scratch_ring_journal(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)
ADDI size , size , -8
BNE size , zero_data , put_loop

J put_size2048_ret

check_full_watermark:
#; Check that rings are "NOT empty"
    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x100(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , NOT_FULL_AND_NOT_EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

    LI temp_data1 , 0xbad
    SW temp_data1 , 0x110(xfer)
    #; Put one more on rings...Each should set Full Flag
    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110) 
    .insn s 43,0,address,cluster_scratch_ring_journal(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x120(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , FULL
    BNE full_empty_sts , temp_data1 , test_failed

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x130) 
    .insn s 43,0,address,cluster_scratch_ring_pop(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x140(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , NOT_FULL_AND_NOT_EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

    J ret_from_watermark

put_size2048_ret:
#; ****************
#; Ring should be Full now (any more PUTs should generate an overflow event)
#; ****************
    LI data0 , 0x0
    SLLI data0 , group_num , 16
    LI size , RING_SIZE
    SW data0 , 0x10(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x14(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x18(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x1c(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x20(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x24(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x28(xfer)
    ADDI data0 , data0 , 1
    SW data0 , 0x2c(xfer)
    ADDI data0 , data0 , 1   

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x10) 
    .insn s 43,0,address,cluster_scratch_ring_journal(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)
    
    LI data0 , 0x0

    J get_loop

get_loop:
    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x300) 
    .insn s 43,0,address,cluster_scratch_ring_get(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LW temp_data1 , 0x300(xfer)
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x304(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x308(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x30c(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    ADDI data0 , data0 , 0x1

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x310) 
    .insn s 43,0,address,cluster_scratch_ring_get(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LW temp_data1 , 0x310(xfer)
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x314(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x318(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x31c(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    ADDI data0 , data0 , 0x1

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x320) 
    .insn s 43,0,address,cluster_scratch_ring_get(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LW temp_data1 , 0x320(xfer)
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x324(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x328(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x32c(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    ADDI data0 , data0 , 0x1

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x330) 
    .insn s 43,0,address,cluster_scratch_ring_get(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LW temp_data1 , 0x330(xfer)
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x334(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x338(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    LW temp_data1 , 0x33c(xfer)
    ADDI data0 , data0 , 0x1
    ADDI expect , data0 , 0x0
    BNE temp_data1 , expect , test_failed
    ADDI data0 , data0 , 0x1

    #ADDI address , ring1 , 0
    #LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x340) 
    #.insn s 43,0,address,cluster_scratch_ring_get(cppcmd_data_ref)	 
    #ADDI address , address , 0x0
    #WAIT_ON_SIGNAL (SIG1_pos,1)

    #LW temp_data1 , 0x340(xfer)
    #ADDI expect , data0 , 0x0
    #BNE temp_data1 , expect , test_failed
    #LW temp_data1 , 0x344(xfer)
    #ADDI data0 , data0 , 0x1
    #ADDI expect , data0 , 0x0
    #BNE temp_data1 , expect , test_failed
    #LW temp_data1 , 0x348(xfer)
    #ADDI data0 , data0 , 0x1
    #ADDI expect , data0 , 0x0
    #BNE temp_data1 , expect , test_failed
    #LW temp_data1 , 0x34c(xfer)
    #ADDI data0 , data0 , 0x1
    #ADDI expect , data0 , 0x0
    #BNE temp_data1 , expect , test_failed
    #ADDI data0 , data0 , 0x1

    ADDI size ,size, -16
    BNE size , zero_data , get_loop

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
