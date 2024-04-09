##;-----------------------
##; TEST_NAME: reflect_to.uc
##;    run on group4 and group4  
##;	 
##;	Try several lengths     - DONE - len=1 and len=4
##;-----------------------  

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


#define zero         x0 # zero register
#define cppcmd_data_ref x3
#define count        x4
#define hart_id      x10 #hart csr register

#define data1         x11
#define data2         x12
#define data3         x13
#define data4         x14
#define expect1       x15
#define expect2       x16
#define expect3       x17
#define expect4       x18
#define address       x19
#define expect5       x20
#define expect6       x21
#define cl_num        x22
#define group_num     x23
#define temp_data     x24
#define temp_data_1   x25
#define temp_data_2   x26
#define xfer          x27

.equ CPP_MEM_ADDR,   0xf0000000


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
    LI temp_data,1000
    
    wait_dm7_init:
        ADDI temp_data,temp_data,-1
        BNEZ temp_data,wait_dm7_init
         
    ###len=0
    LI address, 0x0001C000 ##pull from data_master=7,push to data_master=4;
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_dst(cppcmd_data_ref)	 ;# no signal on pull_id ,pulldata from dm7 
                                                                                  # signal on push(dm=4,sr=1) 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI data1, 0
    LWU data1, 0x0(xfer)
    LI expect4, 0x55555555 ##data from master7
    BNE data1, expect4, test_failed
        
    LI address, 0x0001C001 ##pull from data_master=7,push to data_master=4;
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x4)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_both(cppcmd_data_ref)	 ; # signal on pullid(dm7,sr5)
                                                                                   # signal on push(dm=4,sr=5) 
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
    
    LI expect5, 0x66666666
    LWU data1, 0x4(xfer)
    BNE data1, expect5, test_failed
    
    
    LI address, 0x0001C004 ##pull from data_master=7,push to data_master=4;
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_src(cppcmd_data_ref)	 ;# signal on pullid(dm7,sr2)  
                                                                                  # no signal on push
    
    LI temp_data,1000
    wait_delay:
        ADDI temp_data,temp_data,-1
        BNEZ temp_data,wait_delay
    
    LI expect6, 0x99999999 
    LWU data3, 0x10(xfer)
    BNE data3, expect6, test_failed
    
    #####################################len=3########################
    LI address, 0x0001C000 ##pull from data_master=7,push to data_master=4;
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x10)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_dst(cppcmd_data_ref)	 ;# no signal on pull_id ,pulldata from dm7 
                                                                                  # signal on push(dm=4,sr=1) 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI data1, 0
    LWU data1, 0x10(xfer)
    LI expect4, 0x55555555 ##data from master7
    BNE data1, expect4, test_failed
    LWU data1, 0x14(xfer)
    LI expect4, 0x66666666 ##data from master7
    BNE data1, expect4, test_failed
    LWU data1, 0x18(xfer)
    LI expect4, 0x77777777 ##data from master7
    BNE data1, expect4, test_failed
    LWU data1, 0x1c(xfer)
    LI expect4, 0x88888888 ##data from master7
    BNE data1, expect4, test_failed
    
    LI address, 0x0001C004 ##pull from data_master=7,push to data_master=4;dr 0x10
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x3,0x20)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_both(cppcmd_data_ref)	 ; # signal on pullid(dm7,sr5)
                                                                                   # signal on push(dm=4,sr=5) 
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
    
    LI expect5, 0x99999999
    LWU data1, 0x20(xfer)
    BNE data1, expect5, test_failed
    LI expect5, 0xaaaaaaaa
    LWU data1, 0x24(xfer)
    BNE data1, expect5, test_failed
    LI expect5, 0xbbbbbbbb
    LWU data1, 0x28(xfer)
    BNE data1, expect5, test_failed
    LI expect5, 0xcccccccc
    LWU data1, 0x2c(xfer)
    BNE data1, expect5, test_failed
    

    
    LI address, 0x0001C008 ##pull from data_master=7,push to data_master=4;dr 0x20
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x30)  ;
    .insn s 43,0,address,cluster_scratch_reflect_to_sig_src(cppcmd_data_ref)	 ;# signal on pullid(dm7,sr2)  
                                                                                  # no signal on push
    
    LI temp_data,1000
    wait_delay1:
        ADDI temp_data,temp_data,-1
        BNEZ temp_data,wait_delay1
                                     
    
    LI expect6, 0xdddddddd 
    LWU data3, 0x30(xfer)
    BNE data3, expect6, test_failed
    LI expect6, 0xeeeeeeee 
    LWU data3, 0x34(xfer)
    BNE data3, expect6, test_failed
    LI expect6, 0xffffffff 
    LWU data3, 0x38(xfer)
    BNE data3, expect6, test_failed
    LI expect6, 0x12345678 
    LWU data3, 0x3c(xfer)
    BNE data3, expect6, test_failed
    
    

JAL test_passed


NOP
NOP
NOP


#######################################
########reflect to data_master and compare push data
#######################################
#############for cluster0.group2.cpp_mem1
data_master7:

    LI temp_data,0x6666666655555555
    SD temp_data,0x0(xfer)
    LI temp_data,0x8888888877777777
    SD temp_data,0x8(xfer)
    LI temp_data,0xaaaaaaaa99999999
    SD temp_data,0x10(xfer)
    LI temp_data,0xccccccccbbbbbbbb
    SD temp_data,0x18(xfer) 
    LI temp_data,0xeeeeeeeedddddddd
    SD temp_data,0x20(xfer)
    LI temp_data,0x12345678ffffffff
    SD temp_data,0x28(xfer) 


    WAIT_ON_SIGNAL (SIG5_pos,1) 	;

NOP
NOP
NOP

    WAIT_ON_SIGNAL (SIG2_pos,1) 	;

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


