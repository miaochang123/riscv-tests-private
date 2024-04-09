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
#define data_mask               x11
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
#define data                    x24
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

LI base , 0x20000
SLLI temp_data , cl_num , 0x18
OR base, base , temp_data

#Setup EVENT FILTER



BEQ group_num , zero_data , setup_event_filter
#If not ME0 then setup a delay loop before continueing
LI count, 0xff
delay_loop:
    ADDI count, count, -1
    BEQ count , zero_data , delay_loop
J continue_test

#Only ME0 should write to event Filter
setup_event_filter:
	#;-----------------------------------------------
	#;EventFilter0
	#;-----------------------------------------------
    LI data , 0xf
    SD data , 0x0(xfer)
    ADDI address, base, FILTER_MASK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #; Filter on overflow
    LI data , 0x9
    SD data , 0x10(xfer)
    ADDI address, base, FILTER_MATCH
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

continue_test:
    LI ringbase_base , 0x10000
    SLLI temp_data , cl_num , 0x1a
    OR ringbase_base , ringbase_base , temp_data

    LI ringptr_base , 0x10080
    SLLI temp_data , cl_num , 0x1a
    OR ringptr_base , ringptr_base , temp_data

    SLLI offset1 , group_num , 0x3
    LI temp_data , 0x1
    SLLI temp_data , temp_data , 0x6
    OR offset2 , offset1 , temp_data

size32:
#; Use me_num as the BaseAddr of first ring
    
    #SLLI ring1 , group_num , 0x1a
    #SLLI temp_data , group_num , 0x2
    #OR ring1 , ring1 , temp_data
    #LI temp_data , 0x1
    #SLLI temp_data , temp_data , 0x5
    #OR ring2 , ring1 , temp_data
    ADDI temp_data , group_num, 0x1
    SLLI ring1 , temp_data , 0xa
    ADDI ring2 , ring1 , 0x20

    ADD data , group_num , 0x0
    #; Report all events
    LI temp_data , 0xf
    SLLI temp_data , temp_data , 0x18
    OR data , data , temp_data
    SRLI temp_data , ring1 , 0x7
    OR data , data , temp_data

    SW data , 0x20(xfer)
    LI temp_data , 0x0
    SW temp_data , 0x24(xfer)
    
    ADD address , ringbase_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #LI temp_data , 0x1
    #SLLI temp_data , temp_data , 0x3
    #OR data ,data , temp_data
    LI temp_data , 0xf
    SLLI temp_data , temp_data , 0x18
    OR data , data , temp_data
    SRLI temp_data , ring2 , 0x7
    OR data , data , temp_data

    SW data , 0x30(xfer)
    LI temp_data , 0x0
    SW temp_data , 0x24(xfer)

    ADD address , ringbase_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #Initialize head and tail pointers to 0 for both rings
    LI data, 0x0
    SW data , 0x40(xfer)
    ADD address , ringptr_base , offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x40) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG2_pos,1)

    ADD address , ringptr_base , offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x40) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG2_pos,1)

    LI data , 0x0
    SLLI temp_data , group_num , 0x10
    OR data , temp_data , data

    LI temp_data , 0x1
    SLLI temp_data , temp_data , 0x14
    OR data2 , data , temp_data

    LI size , 0x24
    #load_addr[ret_address,put_size32_ret#]
    J put_loop

put_size32_ret:
#;-----------------------------------------------
#; Reading EventFilter0 status
#;   Verifying that no overflow events occurred
#;-----------------------------------------------
    LI base , 0x20000
    ADD address , base , FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU data , 0x50(xfer)
    BNE data , zero_data , test_failed

    LI data , 0x23
    SLLI temp_data , group_num , 0x10
    OR data , data , temp_data
    LI temp_data , 0x1
    SLLI temp_data , temp_data , 0x14
    OR data2 , data , temp_data
    LI size , 0x20
    #load_addr[ret_address,pop_size32_ret#]
    J pop_loop

pop_size32_ret:
    J test_passed

put_loop:
#for ring1
    SW data , 0x100(xfer)
    ADDI data , data , 0x1
    SW data , 0x104(xfer)
    ADDI data , data , 0x1
    SW data , 0x108(xfer)
    ADDI data , data , 0x1
    SW data , 0x10c(xfer)
#for ring1
    SW data2 , 0x150(xfer)
    ADDI data2 , data2 , 0x1
    SW data2 , 0x154(xfer)
    ADDI data2 , data2 , 0x1
    SW data2 , 0x158(xfer)
    ADDI data2 , data2 , 0x1
    SW data2 , 0x15c(xfer) 
#; JOURNAL
    ADDI address, ring1, 0x0 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x100) 
    .insn s 43,0,address,cluster_scratch_ring_journal(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG2_pos,1) 

    ADDI address, ring2, 0x0 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x150) 
    .insn s 43,0,address,cluster_scratch_ring_journal(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG2_pos,1)

    ADDI size , size , -4
    ADDI data , data , 0x1
    ADDI data2 , data2 , 0x1
    
    BNE size , zero_data , put_loop
    ADDI data , data , -1
    ADDI data2 , data2 , -1
    #RTN[ret_address]
    J put_size32_ret

pop_loop:
#; POP
    ADDI address, ring1, 0x0 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x200) 
    .insn s 43,0,address,cluster_scratch_ring_pop(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG2_pos,1) 

    ADDI address, ring2, 0x0 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x250) 
    .insn s 43,0,address,cluster_scratch_ring_pop(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG2_pos,1)

    LWU temp_data , 0x20c(xfer)
    BNE temp_data , data , test_failed
    LWU temp_data , 0x25c(xfer)
    BNE temp_data , data2 , test_failed
    ADDI data , data , -1
    ADDI data2 , data2 , -1

    LWU temp_data , 0x208(xfer)
    BNE temp_data , data , test_failed
    LWU temp_data , 0x258(xfer)
    BNE temp_data , data2 , test_failed
    ADDI data , data , -1
    ADDI data2 , data2 , -1

    LWU temp_data , 0x204(xfer)
    BNE temp_data , data , test_failed
    LWU temp_data , 0x254(xfer)
    BNE temp_data , data2 , test_failed
    ADDI data , data , -1
    ADDI data2 , data2 , -1

    LWU temp_data , 0x200(xfer)
    BNE temp_data , data , test_failed
    LWU temp_data , 0x250(xfer)
    BNE temp_data , data2 , test_failed
    ADDI data , data , -1
    ADDI data2 , data2 , -1

    ADDI size , size , -4
    BNE size , zero_data , pop_loop

    J pop_size32_ret

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

  #.data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END
