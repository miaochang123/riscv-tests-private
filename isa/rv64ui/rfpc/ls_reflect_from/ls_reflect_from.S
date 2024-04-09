##;-----------------------
##; TEST_NAME: reflect_from.uc
##;  TESt in core0:roup4,group7
##;  
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


#define zero            x0 # zero register
#define cppcmd_data_ref x3
#define count       x4
#define hart_id     x10 #hart csr register

#define data1       x11
#define data2       x12
#define data3       x13
#define data4       x14
#define expect1     x15
#define expect2     x16
#define data7       x17
#define data8       x18
#define address     x19
#define address4    x20
#define address8    x21
#define cl_num      x22
#define group_num   x23
#define temp_data   x24
#define temp_data_1 x25
#define temp_data_2 x26
#define xfer        x27


.equ CPP_MEM_ADDR,   0xf0000000

#.equ LAST_ME,  15
#.equ FIRST_ME, 4
#.equ IMB_XPB_DEVICE_ID,   10

.equ WR_DATA0A,    0x44332211
.equ WR_DATA1A,    0x88776655
.equ WR_DATA2A,    0xCCBBAA99
#.equ WR_DATA3A,    0x00FFEEDD
#.equ WR_DATA4A,    0x00000000
#.equ WR_DATA5A,    0x00000000
#.equ WR_DATA6A,    0x00000000
#.equ WR_DATA7A,    0x00000000
#.equ WR_DATA8A,    0x44332211
#.equ WR_DATA9A,    0x44332211

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI group_num, 0xf00 
AND group_num , group_num, a0   ##is 0/2
SRLI group_num , group_num , 0x8 

ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
#############for judgment
LI expect1, 0x0
BEQ group_num, expect1, data_master4

LI expect2, 0x2
BEQ group_num, expect2, data_master7


data_master4:

    LI xfer, CPP_MEM_ADDR 
    #store the add_data to cpp memory 
    LI temp_data, WR_DATA0A   ##0x44332211
    SW temp_data, 0x0(xfer)
    LI temp_data, WR_DATA1A   ##0x88776655  
    SW temp_data, 0x4(xfer)
    LI temp_data, WR_DATA2A   ##0xCCBBAA99 
    SW temp_data, 0x8(xfer)
    
    LI address, 0x0001c000 ##pull from data_master=4,push to data_master=7 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_src(cppcmd_data_ref)	 ;# pull_id sig on dm4 sr1 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;                                             # no signal on push
    
    LI data1, 0x44332211
    LI temp_data_2, 0
    LI xfer, CPP_MEM_ADDR 
    LWU temp_data_2, 0x0(xfer)
    BNE temp_data_2, data1, test_failed 
    
    LI address, 0x0001c001 ##pull from data_master=4,push to data_master=7
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x4)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# pull_id sig on dm4 sr5
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;                                             # signal on push (dm=7 sr=5)
    
    LI data2, 0x88776655
    LWU temp_data_2, 0x4(xfer)
    BNE temp_data_2, data2, test_failed
    
    
    
    LI address, 0x0001c003 ##pull from data_master=4,push to data_master=7
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x8)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)	 ;# no signal in pull_id
    #WAIT_ON_SIGNAL (SIG2_pos,1) 	;                                             # signal on push (dm=7 sr=5)  



jal test_passed

NOP
NOP
NOP

NOP
NOP
NOP

#######################################
########reflect to data_master and compare push data
#######################################
data_master7:
#############for judgment
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
    
    NOP
    NOP
    NOP
    
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;
    
    LI data1, 0x44332211
    LI temp_data_2, 0
    LI xfer, CPP_MEM_ADDR 
    LWU temp_data_2, 0x0(xfer)
    BNE temp_data_2, data1, test_failed
    
    LI data2, 0x88776655
    LWU temp_data_2, 0x4(xfer)
    BNE temp_data_2, data2, test_failed
    
    LI data3, 0xCCBBAA99
    LWU temp_data_2, 0xc(xfer)
    BNE temp_data_2, data3, test_failed
    
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


