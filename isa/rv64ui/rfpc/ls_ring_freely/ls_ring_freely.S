#;-----------------------
#; TEST_NAME: ring_freely.uc
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
#define ring2                   x16
#define ring1                   x17
#define address                 x19
#define offset2                 x20
#define offset1                 x21
#define cl_num                  x22
#define group_num               x23
#define base                    x24
#define full_empty_sts          x25
#define base1                    x26
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

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
LI zero_data , 0x0

get_core_num:
        LI temp_data1 , 0xff
        AND cl_num ,  a0 , temp_data1
        LI temp_data1 , 0xf00
        AND group_num , a0 , temp_data1
        SRLI group_num , group_num , 0x8

LI base , 0x20000
SLLI temp_data1 , cl_num , 26
OR base , base , temp_data1

BNE group_num , zero_data , setup_event_filter
LI count , 0xff
delay_loop:
    ADDI count , count , -1
    BNE zero_data , count , delay_loop

J continue_test
#; Only ME0 should write to event Filter
setup_event_filter:
	#;-----------------------------------------------
	#;EventFilter0
	#;-----------------------------------------------
    LI temp_data1 , 0xF
    SD temp_data1 , 0x0(xfer)
    ADDI address , base , FILTER_MASK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data1 , 0x8
    SD temp_data1 , 0x8(xfer)
    ADDI address , base , FILTER_MATCH
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

continue_test:
LI ringbase_base , 0x10000
SLLI temp_data1 , cl_num , 26
OR ringbase_base , ringbase_base , temp_data1

LI ringptr_base , 0x10080
SLLI temp_data1 , cl_num , 26
OR ringptr_base , ringptr_base , temp_data1

SLLI offset1 , group_num , 0x3
LI temp_data1 , 0x1
SLLI temp_data1 , temp_data1 , 0x6
OR offset2 , offset1 , temp_data1

size32:
#; Use me_num as the BaseAddr of first ring
    SLLI ring1 , cl_num , 26
    SLLI temp_data1 , group_num , 2
    OR ring1 , ring1 , temp_data1
    LI temp_data1 , 1
    SLLI temp_data1 , temp_data1 , 5
    OR ring2 , ring1 , temp_data1
    
    ADDI temp_data1 , group_num , 0x0
    #; Report all events
    LI temp_data2 , 0xf
    SLLI temp_data2 , temp_data2 , 24
    OR temp_data1 , temp_data1 , temp_data2
    
    ADDI data0 , temp_data1 , 0x0

    SD temp_data1 , 0x300(xfer)
    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x300) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data1 , 0x1
    SLLI temp_data1 , temp_data1 , 3
    OR temp_data1 , temp_data1 , data0
    SD temp_data1 , 0x308(xfer)
    ADD address , ringbase_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x308) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI temp_data1 , 0x0
    SD temp_data1 , 0x310(xfer)
    ADD address , ringptr_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x310) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADD address , ringptr_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x310) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

#; Rings Should be empty
    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x318) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x318(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

    ADD address , ringbase_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x320) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x320(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

#; Do a GEtFreely with Empty ring (should return 0's)
    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x330) 
    .insn s 43,0,address,cluster_scratch_get_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring2 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x340) 
    .insn s 43,0,address,cluster_scratch_get_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x330(xfer)
    BNE temp_data1 , zero_data , test_failed
    LWU temp_data1 , 0x334(xfer)
    BNE temp_data1 , zero_data , test_failed

    LWU temp_data1 , 0x340(xfer)
    BNE temp_data1 , zero_data , test_failed
    LWU temp_data1 , 0x344(xfer)
    BNE temp_data1 , zero_data , test_failed

    LI temp_data1 , 0xaaaa
    LI temp_data2 , 0xbbbb
    SD temp_data1 , 0x350(xfer)
    SD temp_data2 , 0x358(xfer)

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x350) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring2 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x358) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)
    #; Do a GEtFreely (len=2) with only 1 element on each ring

    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x360) 
    .insn s 43,0,address,cluster_scratch_get_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring2 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x370) 
    .insn s 43,0,address,cluster_scratch_get_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x360(xfer)
    LI expect , 0xaaaa
    BNE temp_data1 , expect , test_failed
    LWU temp_data1 , 0x364(xfer)
    BNE temp_data1 , zero_data , test_failed

    LWU temp_data1 , 0x370(xfer)
    LI expect , 0xbbbb
    BNE temp_data1 , expect , test_failed
    LWU temp_data1 , 0x374(xfer)
    BNE temp_data1 , zero_data , test_failed

#; Rings Should be empty
    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x380) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x380(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

    ADD address , ringbase_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x390) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x390(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

#; May want to check that no events were generated
#
#;-----------------------
#; Repeat for POP_Freely
#;-----------------------
#; Do a POPFreely with Empty ring (should return 0's)
#; Do a GEtFreely with Empty ring (should return 0's)
    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x3a0) 
    .insn s 43,0,address,cluster_scratch_pop_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring2 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x3b0) 
    .insn s 43,0,address,cluster_scratch_pop_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x3a0(xfer)
    BNE temp_data1 , zero_data , test_failed
    LWU temp_data1 , 0x3a4(xfer)
    BNE temp_data1 , zero_data , test_failed

    LWU temp_data1 , 0x3b0(xfer)
    BNE temp_data1 , zero_data , test_failed
    LWU temp_data1 , 0x3b4(xfer)
    BNE temp_data1 , zero_data , test_failed
#; May want to check that no events were generated
#; Put one item on each ring   
    LI temp_data1 , 0xcccc
    LI temp_data2 , 0xdddd
    SW temp_data1 , 0x3c0(xfer)
    SW temp_data2 , 0x3c4(xfer)
    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3c0) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring2 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3c4) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)
#; Do a POPFreely (len=3) with only 1 element on each ring    
    ADDI address , ring1 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x3c8) 
    .insn s 43,0,address,cluster_scratch_pop_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x3c8(xfer)
    LI expect , 0xcccc
    BNE temp_data1 , expect , test_failed
    LWU temp_data1 , 0x3cc(xfer)
    BNE temp_data1 , zero_data , test_failed
    LWU temp_data1 , 0x3d0(xfer)
    BNE temp_data1 , zero_data , test_failed

    ADDI address , ring2 , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x3d4) 
    .insn s 43,0,address,cluster_scratch_pop_safe(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x3d4(xfer)
    LI expect , 0xdddd
    BNE temp_data1 , expect , test_failed
    LWU temp_data1 , 0x3d8(xfer)
    BNE temp_data1 , zero_data , test_failed
    LWU temp_data1 , 0x3dc(xfer)
    BNE temp_data1 , zero_data , test_failed

    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3e0) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x3e0(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

    ADD address , ringbase_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3e4) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x3e4(xfer)
    SRLI full_empty_sts , temp_data1 , 30
    LI temp_data1 , EMPTY
    BNE full_empty_sts , temp_data1 , test_failed

#;-----------------------------------------------
#; Reading EventFilter0 status
#;   Verifying that no underflow events occurred
#;-----------------------------------------------
LI base , 0x20000
ADDI address , base , FILTER_STATUS
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x3f0) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU temp_data1 , 0x3f0(xfer)
BNE temp_data1 , zero_data , test_failed

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
