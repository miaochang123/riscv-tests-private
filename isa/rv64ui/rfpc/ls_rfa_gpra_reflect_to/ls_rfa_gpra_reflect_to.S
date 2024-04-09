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


#define zero   x0 # zero register
#define cppcmd_data_ref x3
#define count x4
#define hart_id    x10 #hart csr register

#define data1       x11
#define data2       x12
#define data3       x13
#define data4       x14
#define expect1     x15
#define expect2     x16
#define expect3     x17
#define expect4     x18
#define address       x19
#define address4      x20
#define address8      x21
#define cl_num        x22
#define group_num     x23
#define temp_data     x24
#define temp_data_1   x25
#define temp_data_2   x26
#define xfer  x27


.equ CPP_MEM_ADDR,   0xf0000000


#.equ WR_DATA0A,    0x44332211
#.equ WR_DATA1A,    0x88776655
#.equ WR_DATA2A,    0xCCBBAA99
#.equ WR_DATA3A,    0x00FFEEDD
#.equ WR_DATA4A,    0x12344321
#.equ WR_DATA5A,    0x56788765
#.equ WR_DATA6A,    0x9abccba9
#.equ WR_DATA7A,    0xdef00fed





RVTEST_RV64U
RVTEST_CODE_BEGIN

LI group_num, 0xf00 
AND group_num , group_num, a0   ##is 0/2
SRLI group_num , group_num , 0x8 
ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 1 #>=1 not used
BGE cl_num, temp_data_1, test_passed # 


LI xfer, CPP_MEM_ADDR
#############for judgment
LI expect1, 0x0
BEQ group_num, expect1, data_master4

LI expect2, 0x2
BEQ group_num, expect2, data_master7


#############for cluster0.group0.cpp_mem0
data_master4:
    LI temp_data,100

    wait_master7_init:
        ADDI temp_data,temp_data,-1
        BNEZ temp_data,wait_master7_init

    ###############len=0#################
    LI address, 0x0001c004 ##pull from data_master=7,push to data_master=4; dataref=0x10
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_dst(cppcmd_data_ref)	 ;## no signal on pull_id ,pulldata from dm7 
                                                                            # signal on push(dm=4,sr=1) 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI data1, 0
    LWU data1, 0x0(xfer)
    LI expect4, 0x12345678 
    BNE data1, expect4, test_failed

    ############len=2################
    LI address, 0x0001c005 ##pull from data_master=7,push to data_master=4; dataref=0x14
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x10)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_dst(cppcmd_data_ref)	 ;## no signal on pull_id ,pulldata from dm7 
                                                                            # signal on push(dm=4,sr=1) 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LWU data1, 0x10(xfer)
    LI expect4, 0x9abcdef0 
    BNE data1, expect4, test_failed 
    LWU data1, 0x14(xfer)
    LI expect4, 0x55667788 
    BNE data1, expect4, test_failed
    LWU data1, 0x18(xfer)
    LI expect4, 0x11223344
    BNE data1, expect4, test_failed

    ###########len=3################
    LI address, 0x0001c006 ##pull from data_master=7,push to data_master=4; dataref=0x18
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_dst(cppcmd_data_ref)	 ;## no signal on pull_id ,pulldata from dm7 
                                                                            # signal on push(dm=4,sr=1) 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LWU data1, 0x50(xfer)
    LI expect4, 0x55667788 
    BNE data1, expect4, test_failed
    LWU data1, 0x54(xfer)
    LI expect4, 0x11223344 
    BNE data1, expect4, test_failed
    LWU data1, 0x58(xfer)
    LI expect4, 0xccddeeff 
    BNE data1, expect4, test_failed
    LWU data1, 0x5c(xfer)
    LI expect4, 0x9900aabb 
    BNE data1, expect4, test_failed
JAL test_passed


NOP
NOP
NOP


#######################################
########reflect to data_master and compare push data
#######################################
#############for cluster0.group2.cpp_mem1
data_master7:

LI temp_data,0x9abcdef012345678  ##data for master4
SD temp_data,0x10(xfer)

LI temp_data,0x1122334455667788  ##data for master4
SD temp_data,0x18(xfer)

LI temp_data,0x9900aabbccddeeff  ##data for master4
SD temp_data,0x20(xfer) 

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


