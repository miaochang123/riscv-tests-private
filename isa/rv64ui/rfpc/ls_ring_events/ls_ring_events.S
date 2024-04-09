#;-----------------------
#; TEST_NAME: ring_events.uc
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
#define ringbase_base           x12
#define ringptr_base            x13
#define zero_data               x14
#define expect                  x15
#define ring2                   x16
#define ring1                   x17
#define size                    x18
#define address                 x19
#define offset2                 x20
#define offset1                 x21
#define cl_num                  x22
#define group_num               x23
#define autopush_base           x24
#define filter_base             x25
#define base                    x26
#define xfer                    x27
#define t_data_ref              x28
#define temp_data1              x30
#define temp_data2              x31
## x28 - x31 need reload the value before use
.equ CPP_MEM_ADDR,      0xf0000000
.equ EMPTY, 0
.equ NOT_FULL_AND_NOT_EMPTY, 1
.equ FULL, 3

.equ FILTER_STATUS,   0x0
.equ FILTER_MASK,      0x10
.equ FILTER_MATCH,     0x18
.equ FILTER_ACK,       0x20
.equ USER_EVENT,       0x400
.equ AUTOPUSH_SIGNAL,  0x200

.equ SCRATCH_BASE,  0x0

.equ RING_SIZE,            32
.equ RING_INDEX,            0
.equ RING_INDEX_PLUS3,      3
.equ RING_FULL_THRESHOLD,  24

.equ MASTER_FIRST,  5
.equ MASTER_LAST,   7

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
LI zero_data , 0x0

get_core_num:
        LI temp_data1 , 0xff
        AND cl_num ,  a0 , temp_data1  # core number
        LI temp_data1 , 0xf00
        AND group_num , a0 , temp_data1
        SRLI group_num , group_num , 0x8 # X10 group numbers 16 cores per group, currently 

LI ringbase_base , 0x10000
LI ringptr_base , 0x10080

LI autopush_base , 0x30000
LI filter_base , 0x20000

#me_filter_loop:

filter_loop:
	#;-----------------------------------------------
	#;EventFilter0
	#;-----------------------------------------------
    LI temp_data1 , 0xf
    SW temp_data1 , 0x0(xfer)
    ADDI address , filter_base , FILTER_MASK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)  

    LI temp_data1 , 0x1
    SW temp_data1 , 0x8(xfer)
    ADDI address , filter_base , FILTER_MATCH
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x8) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI offset1 , AUTOPUSH_SIGNAL
    LI offset2 , USER_EVENT

autopush_loop0:
	#;-----------------------------------------------
	#; AutoPush signal register0
	#;-----------------------------------------------
    #;data_ref = 0x400 , master = 0x4 , master_island = 0x1 , signal_ref = 0x1
    LI temp_data1 , 0x90080400
    SD temp_data1 , 0x10(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 0
	#;-----------------------------------------------
    LI temp_data1 , 0x100
    SD temp_data1 , 0x18(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x18) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)
    
    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 1 
    #;-----------------------------------------------
    LI temp_data1 , 0x1
    SD temp_data1 , 0x20(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)
    #WAIT_ON_SIGNAL (SIG1_pos,1)#autopush signal
    

    ########################################################

	#;-----------------------------------------------
	#; AutoPush signal register1
	#;-----------------------------------------------
    #;data_ref = 0x410 , master = 0x4 , master_island = 0x1 , signal_ref = 0x2
    ADDI autopush_base , autopush_base , 0x8

    LI temp_data1 , 0x90100410
    SD temp_data1 , 0x30(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 1
	#;-----------------------------------------------
    LI temp_data1 , 0x101
    SD temp_data1 , 0x38(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x38) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 1 
    #;-----------------------------------------------	 
    LI temp_data1 , 0x1
    SD temp_data1 , 0x40(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ########################################################

	#;-----------------------------------------------
	#; AutoPush signal register2
	#;-----------------------------------------------
    #;data_ref = 0x420 , master = 0x4 , master_island = 0x1 , signal_ref = 0x3
    ADDI autopush_base , autopush_base , 0x8
    LI temp_data1 , 0x90180420
    SD temp_data1 , 0x0(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 2
	#;-----------------------------------------------
    LI temp_data1 , 0x102
    SD temp_data1 , 0x8(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 2 
    #;-----------------------------------------------	 
    LI temp_data1 , 0x1
    SD temp_data1 , 0x10(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ########################################################

	#;-----------------------------------------------
	#; AutoPush signal register3
	#;-----------------------------------------------
    #;data_ref = 0x430 , master = 0x4 , master_island = 0x1 , signal_ref = 0x4
    ADDI autopush_base , autopush_base , 0x8
    LI temp_data1 , 0x90200430
    SD temp_data1 , 0x20(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 2
	#;-----------------------------------------------
    LI temp_data1 , 0x103
    SD temp_data1 , 0x28(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x28) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 3 
    #;-----------------------------------------------	 
    LI temp_data1 , 0x1
    SD temp_data1 , 0x30(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ########################################################

	#;-----------------------------------------------
	#; AutoPush signal register4
	#;-----------------------------------------------
    #;data_ref = 0x440 , master = 0x4 , master_island = 0x1 , signal_ref = 0x5
    ADDI autopush_base , autopush_base , 0x8
    LI temp_data1 , 0x90280440
    SD temp_data1 , 0x0(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 4
	#;-----------------------------------------------
    LI temp_data1 , 0x104
    SD temp_data1 , 0x8(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 4 
    #;-----------------------------------------------	 
    LI temp_data1 , 0x1
    SD temp_data1 , 0x10(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ########################################################

	#;-----------------------------------------------
	#; AutoPush signal register5
	#;-----------------------------------------------
    #;data_ref = 0x450 , master = 0x4 , master_island = 0x1 , signal_ref = 0x6
    ADDI autopush_base , autopush_base , 0x8
    LI temp_data1 , 0x90300450
    SD temp_data1 , 0x20(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 5
	#;-----------------------------------------------
    LI temp_data1 , 0x105
    SD temp_data1 , 0x28(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x28) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 5
    #;-----------------------------------------------	 
    LI temp_data1 , 0x1
    SD temp_data1 , 0x30(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ########################################################

	#;-----------------------------------------------
	#; AutoPush signal register6
	#;-----------------------------------------------
    #;data_ref = 0x460 , master = 0x4 , master_island = 0x1 , signal_ref = 0x7
    ADDI autopush_base , autopush_base , 0x8
    LI temp_data1 , 0x90380460
    SD temp_data1 , 0x0(xfer)
    ADDI address , autopush_base , AUTOPUSH_SIGNAL
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

	#;-----------------------------------------------
	#; AutoPush FilterStatusMonitor 6
	#;-----------------------------------------------
    LI temp_data1 , 0x106
    SD temp_data1 , 0x8(xfer)
    ADDI address , autopush_base , 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #;-----------------------------------------------
	#; User Event Register - Generate an event Event 6
    #;-----------------------------------------------	 
    LI temp_data1 , 0x1
    SD temp_data1 , 0x10(xfer)
    ADDI address , autopush_base , USER_EVENT
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10) 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ########################################################

#; Match on 8 which is event = Underflow
#; Match on 9 which is event = Overflow
#; Match on 1 which is event = NOT FULL
#; Match on 0 which is event = NOT EMTY
LI filter_base , 0x20000
LI temp_data1 , 0xf
SW temp_data1 , 0x100(xfer)
LI temp_data1 , 0x0
SW temp_data1 , 0x110(xfer)
LI temp_data1 , 0x1
SW temp_data1 , 0x120(xfer)
LI temp_data1 , 0x8
SW temp_data1 , 0x130(xfer)
LI temp_data1 , 0x9
SW temp_data1 , 0x140(xfer)
LI temp_data1 , 0x0
SW temp_data1 , 0x150(xfer)

##################################
#; filter0 monitor NOT EMTY
##################################
ADDI address , filter_base , FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_STATUS
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x350) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU temp_data1 , 0x350(xfer)
SW  temp_data1 , 0x500(xfer)

##################################
#; filter1 monitor NOT FULL
##################################
LI temp_data1 , 0xf
SW temp_data1 , 0x100(xfer)
ADDI filter_base , filter_base , 0x40
ADDI address , filter_base , FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_STATUS
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x360) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU temp_data1 , 0x360(xfer)
SW  temp_data1 , 0x510(xfer)

##################################
#; filter2 monitor Underflow
##################################
LI temp_data1 , 0xf
SW temp_data1 , 0x100(xfer)
ADDI filter_base , filter_base , 0x40
ADDI address , filter_base , FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x130) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_STATUS
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x370) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LWU temp_data1 , 0x370(xfer)
SW  temp_data1 , 0x520(xfer)

##################################
#; filter3 monitor overflow
##################################
LI temp_data1 , 0xf
SW temp_data1 , 0x100(xfer)
ADDI filter_base , filter_base , 0x40
ADDI address , filter_base , FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

ADDI address , filter_base , FILTER_STATUS
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x380) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 #; Should generate an underflow
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)


LWU temp_data1 , 0x380(xfer)
SW  temp_data1 , 0x530(xfer)

##################################

LI filter_base , 0x20000
LI autopush_base , 0x30000
LI ringptr_base , 0x10080
LI ringbase_base , 0x10000


ADDI address , autopush_base , AUTOPUSH_SIGNAL
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x8,0x100) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

#; Just Clear filter count to 0
ADDI address , filter_base , FILTER_ACK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)


#; Initialize RingBase CSRs
#; Set size field to 0 [18:16] : Ring size = 32
#; Report all events

LI temp_data1 , 0xf000100
SD temp_data1 , 0x100(xfer)
ADDI address , ringbase_base , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

SD zero_data , 0x110(xfer)
ADDI address , ringptr_base , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110) 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI ring1 , 0x8000
LI ring2 , 0x0
LI size , 32
put_loop:
    LI t_data_ref , 8
    BEQ size , t_data_ref , check_full_watermark

ret_from_watermark:
    SW ring2 , 0x200(xfer)
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x204(xfer)  
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x208(xfer)
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x20c(xfer)
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x210(xfer)
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x214(xfer)  
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x218(xfer)
    ADDI ring2 , ring2 , 0x1
    SW ring2 , 0x21c(xfer)
    ADDI ring2 , ring2 , 0x1
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x200) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI size , size , -8
    BNE size , zero_data , put_loop

    J put_size32_ret

check_full_watermark:
    LI temp_data1 , 0xbad
    SW temp_data1 , 0x0(xfer)
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    #SW temp_data1 , 0x0(xfer)
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_pop(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    J ret_from_watermark

put_size32_ret:
#; ****************
#; Ring should be Full now (any more PUTs should generate an overflow event)
#; ****************
    LI temp_data1 , 0xbad
    SW temp_data1 , 0x0(xfer)
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)  #; Should generate an overflow

put_size32_ret_1:
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)  #; Should generate an overflow

put_size32_ret_2:
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)  #; Should generate an overflow

put_size32_ret_3:
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)  #; Should generate an overflow
    
put_size32_ret_4:
    LI ring2 , 0x0
    LI expect , 0x0
    LI size , 32

get_loop:
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x200) 
    .insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI count , 0x4
    delay_loop:
        ADDI count , count , -1
        BNE count ,zero_data , delay_loop
    

    LWU ring2 , 0x200(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1
    LWU ring2 , 0x204(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1
    LWU ring2 , 0x208(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1
    LWU ring2 , 0x20c(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1

    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x250) 
    .insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

LI count , 0x10
delay_loop1:
    ADDI count , count , -1
    BNE count ,zero_data , delay_loop1

    LWU ring2 , 0x250(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1
    LWU ring2 , 0x254(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1
    LWU ring2 , 0x258(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1
    LWU ring2 , 0x25c(xfer)
    BNE ring2 , expect , test_failed
    ADDI expect , expect , 1

    ADDI size , size , -8
    BNE size , zero_data , get_loop
    J get_size32_ret

get_size32_ret:
    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
    .insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref)	 #; Should generate an underflow
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x200) 
    .insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref)	 #; Should generate an underflow
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    ADDI address , ring1 , 0x0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x300) 
    .insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref)	 #; Should generate an underflow
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

#####################################
#; read event status
#####################################
    LI filter_base , 0x20000
    #; Read NOT EMTY count
    ADDI address , filter_base , FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x0(xfer)
    SW temp_data1 , 0x600(xfer)

    #; Read NOT FULL count
    ADDI filter_base , filter_base , 0x40

    ADDI address , filter_base , FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LWU temp_data1 , 0x10(xfer)
    SW temp_data1 , 0x610(xfer)

    #; Read Underflow count
    ADDI filter_base , filter_base , 0x40

    ADDI address , filter_base , FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG1_pos,1)
    LI count , 0x4
    delay_loop2:
        ADDI count , count , -1
        BNE count ,zero_data , delay_loop2
    LWU ring2 , 0x20(xfer)
    LI expect , 0x3
    BNE expect , ring2 , test_failed # gen three underflow
    SW ring2 , 0x620(xfer)

    #; Read Overflow count
    ADDI filter_base , filter_base , 0x40

    ADDI address , filter_base , FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG7,0x0,0x0,0x0,0x30) 
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 
    ADDI address , address , 0x0
    WAIT_ON_SIGNAL (SIG7_pos,1)
    #LI count , 0x4
    #delay_loop3:
    #    ADDI count , count , -1
    #    BNE count ,zero_data , delay_loop3
    LWU ring2 , 0x30(xfer)
    LI expect , 0x4
    BNE expect , ring2 , test_failed # gen three underflow
    SW ring2 , 0x630(xfer)


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
