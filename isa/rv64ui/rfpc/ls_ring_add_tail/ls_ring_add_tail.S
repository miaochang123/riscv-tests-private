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
#define full_empty_sts          x11
#define size                    x12
#define data2                   x13
#define zero_data               x14
#define expect                  x15
#define ring2                   x16
#define ring1                   x17
#define address                 x19
#define offset2                 x20
#define offset1                 x21
#define cl_num                  x22
#define group_num               x23
#define data1                    x24
#define temp_data               x25
#define base                    x26
#define xfer                    x27
#define ringbase_base           x30
#define ringptr_base            x31

.equ CPP_MEM_ADDR,      0xf0000000
.equ EMPTY, 0
.equ NOT_FULL_AND_NOT_EMPTY, 1
.equ FULL, 3

.equ FILTER_STATUS, 0x0
.equ FILTER_MASK, 0x10
.equ FILTER_MATCH, 0x18

.equ FIRST_ME, 0

RVTEST_RV64U
RVTEST_CODE_BEGIN
LI xfer , CPP_MEM_ADDR
LI zero_data , 0x0

get_core_num:
        LI temp_data , 0xff
        AND cl_num ,  a0 , temp_data  # core number
        LI temp_data , 0xf00
        AND group_num , a0 , temp_data
        SRLI group_num , group_num , 0x8 # X10 group numbers 16 cores per group, currently 

BEQ group_num , zero_data , continue_test
WAIT_ON_SIGNAL (SIG7_pos,1)
continue_test:

LI ringbase_base , 0x10000
SLLI temp_data , cl_num , 0x1a
OR ringbase_base , ringbase_base , temp_data

LI ringptr_base , 0x10080
SLLI temp_data , cl_num , 0x1a
OR ringptr_base , ringptr_base , temp_data

SLLI offset1 , group_num , 0x3
#; Use me_num as the BaseAddr of first ring
SLLI ring1 , group_num , 0x2
SLLI temp_data , cl_num , 0x1a
OR ring1 , ring1 , temp_data

ADDI data1 , group_num , 0x0
#; Report all events
LI temp_data , 0xf000000
OR data1 , data1 , temp_data

    
SD data1 , 0x200(xfer)
LI ringbase_base , 0x10000
ADD address , ringbase_base , offset1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x200) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

#; Initialize head  pointers to 0
#; Initialize tail pointers to the me_num

SLLI data1 , group_num , 0x10
SD data1 , 0x208(xfer)
LI ringptr_base , 0x10080
SLLI temp_data , cl_num , 0x1a
OR ringptr_base , ringptr_base , temp_data
ADD address , ringptr_base , offset1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x208) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI ringbase_base , 0x10000
ADD address , ringbase_base , offset1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x210) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU temp_data , 0x210(xfer)
SRLI full_empty_sts , temp_data , 30
BNE full_empty_sts ,zero_data , test_failed

ADDI address, ring1, 0x0 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x9,0x1,0x0,0x0) 
.insn s 43,0,address,cluster_scratch_ring_add_to_tail_ptr(cppcmd_data_ref)	 
ADDI address , address , 0x1
#WAIT_ON_SIGNAL (SIG2_pos,1)

#; Rings Should no longer be empty
LI count , 0x10
delay10:
    NOP
    ADDI count , count, -1
    BNE count, zero_data , delay10

#; Read Tail pointers - Check that tail pointer was updated correctly
ADDI expect , group_num , 0xa
SLLI expect , expect , 0x10

LI count , 0x0
LI temp_data , 0x24
ADDI address , xfer , 0x0

assign_expect_data_loop:
    BNE group_num , count , assign_zero
    SW expect , 0x220(address)
    J done_assign
assign_zero:
    SW zero_data , 0x220(address)

done_assign:
    ADDI count , count , 1
    ADDI address , address , 0x4
    BNE count , temp_data , assign_expect_data_loop

#; Check all 16 Tail pointers.
#; The one just written should have been incremented by 9
#; All the others should be "0"
read_tail_ptrs:

#SD data1 , 0x200(xfer)
LI ringptr_base , 0x10080
SLLI temp_data , cl_num , 0x1a
OR ringptr_base , ringptr_base , temp_data
ADD address , ringptr_base , 0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x15,0x300) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU data1 , 0x300(xfer)
LWU expect , 0x220(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x308(xfer)
LWU expect , 0x228(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x310(xfer)
LWU expect , 0x230(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x318(xfer)
LWU expect , 0x238(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x320(xfer)
LWU expect , 0x240(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x328(xfer)
LWU expect , 0x248(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x330(xfer)
LWU expect , 0x250(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x338(xfer)
LWU expect , 0x258(xfer)
BNE data1 , expect , test_failed

LI ringptr_base , 0x10080
SLLI temp_data , cl_num , 0x1a
OR ringptr_base , ringptr_base , temp_data
ADD address , ringptr_base , 0x40
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x15,0x340) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU data1 , 0x340(xfer)
LWU expect , 0x260(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x348(xfer)
LWU expect , 0x268(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x350(xfer)
LWU expect , 0x270(xfer)
BNE data1 , expect , test_failed

LWU data1 , 0x358(xfer)
LWU expect , 0x278(xfer)
BNE data1 , expect , test_failed

LI data1 , 0x0
SW data1 , 0x360(xfer)
LI ringptr_base , 0x10080
SLLI temp_data , cl_num , 0x1a
OR ringptr_base , ringptr_base , temp_data
ADD address , ringptr_base , offset1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x15,0x360) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
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
