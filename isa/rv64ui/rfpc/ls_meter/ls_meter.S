##------------------------------------------------------------------------------------------
##; TEST_NAME: ls_meter.uc
##;    	
##;   07/22/2015: Test Metering command
##;
##;     +-----+-----+
##;     |  Meter    |
##;     +-----+-----+
##;     | LTC | STC |
##;     +-----+-----+
##;
##; Mode = 2698
##;  (RED)    OR Decremented STC < 0 --> RED,     else
##;  (YELLOW) OR Decremented LTC < 0 --> YELLOW (STC decremented) , else
##;                                  --> GREEN  (STC decremented, LTC decremented)
##;
##; Mode = 4115
##;  (GREEN)           AND Decremented LTC/CIR >= 0 --> GREEN (LTC/CIR decremented),     else
##;  (GREEN OR YELLOW) AND Decremented STC/EIR >= 0 --> YELLOW (STC/EIR decremented),     else
##;                                                --> RED  
##;
##; color blind mode simply means the packet is GREEN
##-------------------------------------------------------------------------------------------


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
#define temp_data       x5
#define temp_data_1     x6
#define temp_data_2     x7

#define offset          x13
#define pass_count      x14
#define exp_stc         x15
#define exp_ltc         x16
#define expect_data     x17
#define cppcmd_data_ref x18
#define address         x19
#define cl_num          x20
#define group_num       x21
#define xfer            x23

	
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

 

RVTEST_RV64U
RVTEST_CODE_BEGIN
	

LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 1024 byte of address space

LI xfer, CPP_MEM_ADDR 
ADD address, group_num, zero

##------------------------------------------------------
## cls_meter_2698 - only one meter,meter_num is ignored
##------------------------------------------------------
.macro cls_meter_2698 meter_num, stc, ltc, size, input_color, exp_color
    LI temp_data,\size
    SW temp_data,0x0(xfer)
    
    LI temp_data,\input_color
    SLLI offset,temp_data,16
    
    ADD address,group_num,offset
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
    .insn s 43,0,address,cluster_scratch_meter(cppcmd_data_ref);# CPP Command write
    WAIT_ON_SIGNAL (SIG3_pos,1); 
    
    ADD address, group_num, zero 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
    .insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# read
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    LI expect_data,\exp_color
    LWU temp_data,0x0(xfer)
    BNE temp_data,expect_data,test_failed
    
    LWU temp_data,0x20(xfer)
    BNE temp_data,exp_stc,test_failed
    
    LWU temp_data,0x24(xfer)
    BNE temp_data,exp_ltc,test_failed 
    
    ADDI pass_count,pass_count,1
.endm


##------------------------------------------------------
## cls_meter_4115 - only one meter,meter_num is ignored
##------------------------------------------------------
.macro cls_meter_4115 meter_num, stc, ltc, size, input_color, exp_color
    LI temp_data,\size
    SW temp_data,0x0(xfer)
    
    LI temp_data,\input_color
    SLLI offset,temp_data,16  

    LI temp_data,0x1
    SLLI temp_data,temp_data,18

    OR offset,offset,temp_data
    
    ADD address,group_num,offset
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
    .insn s 43,0,address,cluster_scratch_meter(cppcmd_data_ref);# CPP Command write
    WAIT_ON_SIGNAL (SIG3_pos,1); 
    
    ADD address, group_num, zero 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
    .insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);# read
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    LI expect_data,\exp_color
    LWU temp_data,0x0(xfer)
    BNE temp_data,expect_data,test_failed
    
    LWU temp_data,0x30(xfer)
    BNE temp_data,exp_stc,test_failed
    
    LWU temp_data,0x34(xfer)
    BNE temp_data,exp_ltc,test_failed 
    
    ADDI pass_count,pass_count,1
.endm  


###-------------------------------------------
### Start of test
###-------------------------------------------
LI pass_count,0

##// Initialize STC/LTC for Meter0 and Meter1 
LI temp_data,0x2   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x1   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1);

##// Packet 1:(M#=0, STC=2, LTC=1, Size=1, packet=GREEN, result=GREEN,STC=1,LTC=0)  
LI exp_stc,1
LI exp_ltc,0
cls_meter_2698 0,2,1,1,0,0

##// Packet 2: (M#=0, STC=1, LTC=0, Size=1, packet=GREEN,result=YELLOW, STC=0, LTC=0)  
LI exp_stc,0
LI exp_ltc,0
cls_meter_2698 0,1,0,1,0,1 

##// Packet 3: (M#=0, STC=0, LTC=0, Size=1, packet=GREEN, result=RED, STC=0, LTC=0)
LI exp_stc,0
LI exp_ltc,0
cls_meter_2698 0,0,0,1,0,2

##// Update STC/LTC for  Meter0  
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x6   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1); 
##//----------------------------------------------------------------
##// Run three identical cases...only difference is input Packet Color
##//---------------------------------------------------------------- 
##// Packet 4: (M#=0, STC=6, LTC=6, Size=2, packet=RED, result=RED, STC=6, LTC=6) 
LI exp_stc,6
LI exp_ltc,6
cls_meter_2698 0,6,6,2,2,2

##// Packet 5: (M#=0, STC=6, LTC=6, Size=2, packet=YELLOW, result=YELLOW, STC=4, LTC=6)  
LI exp_stc,4
LI exp_ltc,6
cls_meter_2698 0,6,6,2,1,1

##// Update STC/LTC for  Meter0 
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x6   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1); 

##// Packet 6: (M#=0, STC=6, LTC=6, Size=2, packet=GREEN, result=GREEN, STC=4, LTC=4) 
LI exp_stc,4
LI exp_ltc,4
cls_meter_2698 0,6,6,2,0,0

##//----------------------
##// Start some 4115 cases
##//----------------------  
##// Update STC/LTC for  Meter0  
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x6   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1);  

##// Packet 7: (M#=0, STC=6, LTC=6, Size=3, packet=GREEN, result=GREEN,STC=6, LTC=3) 
LI exp_stc,6
LI exp_ltc,3
cls_meter_4115 0,6,6,3,0,0

##// Update STC/LTC for  Meter0 
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x6   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1); 

##// Packet 8: (M#=0, STC=6, LTC=6, Size=3, packet=YELLOW, result=YELLOW,STC=3, LTC=6) 
LI exp_stc,3
LI exp_ltc,6
cls_meter_4115 0,6,6,3,1,1

##// Update STC/LTC for  Meter0  
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x6   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1); 

##// Packet 9: (M#=0, STC=6, LTC=6, Size=3, packet=RED, result=RED,STC=6, LTC=6)
LI exp_stc,6
LI exp_ltc,6
cls_meter_4115 0,6,6,3,2,2

##// Update STC/LTC for  Meter0  
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x3   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1);  

##// Packet 10: (M#=0, STC=6, LTC=3, Size=4, packet=GREEN, result=YELLOW,STC=2, LTC=3)
LI exp_stc,2
LI exp_ltc,3
cls_meter_4115 0,6,3,4,0,1 

##// Update STC/LTC for  Meter0 
LI temp_data,0x3   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x3   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1);

##// Packet 11: (M#=0, STC=3, LTC=3, Size=4, packet=GREEN, result=RED,STC=3, LTC=3) 
LI exp_stc,3
LI exp_ltc,3
cls_meter_4115 0,3,3,4,0,2

##---------------------------------------------------------------------------------
##// Update STC/LTC for  Meter0 
LI temp_data,0x6   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x3   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1);

##// Packet 12: (M#=0, STC=6, LTC=3, Size=3, packet=GREEN, result=GREEN,STC=3, LTC=3) 
LI exp_stc,6
LI exp_ltc,0
cls_meter_4115 0,6,3,3,0,0

##Packet 13: (M#=0, STC=3, LTC=3, Size=3, packet=GREEN, result=YELLOW,STC=3, LTC=0) 
LI exp_stc,3
LI exp_ltc,0
cls_meter_4115 0,3,3,3,0,1 

##// Update STC/LTC for  Meter0 
LI temp_data,0x3   ###short term    -meter0
SW temp_data,0x0(xfer)

LI temp_data,0x3   ###long term    -meter0
SW temp_data,0x4(xfer)  

ADD address, group_num, zero # set to initial value  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1);  

##// Packet 14: (M#=0, STC=3, LTC=3, Size= 3, packet=GREEN, result=GREEN, STC=0, LTC=0)
LI exp_stc,0
LI exp_ltc,0
cls_meter_2698 0,3,3,3,0,0

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
