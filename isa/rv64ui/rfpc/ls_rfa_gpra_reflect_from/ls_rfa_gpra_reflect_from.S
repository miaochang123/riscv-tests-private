##;-----------------------
##; TEST_NAME: lsreflect_rfa_gpra_from.uc
##;  TESt requires all 8 core's to be running with group4&7
##; Need to add: ME0 refects_from self to each other ME   (pulls from SELF (SRC)...Pushes to others (DST) )
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
#define data7       x17
#define data8       x18
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


.equ WR_DATA0A,    0x44332211
.equ WR_DATA1A,    0x88776655
.equ WR_DATA2A,    0xCCBBAA99
.equ WR_DATA3A,    0x00FFEEDD
.equ WR_DATA4A,    0x12344321
.equ WR_DATA5A,    0x56788765
.equ WR_DATA6A,    0x9abccba9
.equ WR_DATA7A,    0xdef00fed


RVTEST_RV64U
RVTEST_CODE_BEGIN

LI group_num, 0xf00 
AND group_num , group_num, a0   ##is 0/2
SRLI group_num , group_num , 0x8 
ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 8 #>=3 not used
BGE cl_num, temp_data_1, test_passed # 


#############for judgment

LI expect1, 0x0
BEQ group_num, expect1, data_master4

LI expect2, 0x2
BEQ group_num, expect2, data_master7


#############for cluster0.group0.cpp_mem0
data_master4:

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, WR_DATA0A
SW temp_data, 0x0(xfer)
LI temp_data, WR_DATA1A
SW temp_data, 0x4(xfer)
LI temp_data, WR_DATA2A
SW temp_data, 0x8(xfer)
LI temp_data, WR_DATA3A
SW temp_data, 0xC(xfer)
LI temp_data, WR_DATA4A
SW temp_data, 0x10(xfer)
LI temp_data, WR_DATA5A
SW temp_data, 0x14(xfer)
LI temp_data, WR_DATA6A
SW temp_data, 0x18(xfer)
LI temp_data, WR_DATA7A
SW temp_data, 0x1C(xfer)


LI temp_data_1 , 0
BEQ cl_num, temp_data_1, data_master4_core0 # 
	
LI temp_data_1 , 1
BEQ cl_num, temp_data_1, data_master4_core1 # 
	
LI temp_data_1 , 2
BEQ cl_num, temp_data_1, data_master4_core2 # 
	
LI temp_data_1 , 3
BEQ cl_num, temp_data_1, data_master4_core3 # 

LI temp_data_1 , 4
BEQ cl_num, temp_data_1, data_master4_core4 # 
	
LI temp_data_1 , 5
BEQ cl_num, temp_data_1, data_master4_core5 # 
	
LI temp_data_1 , 6
BEQ cl_num, temp_data_1, data_master4_core6 # 
	
LI temp_data_1 , 7
BEQ cl_num, temp_data_1, data_master4_core7 # 


data_master4_core0:
    LI address, 0x8501C000 ##pull from data_master=4,push to data_master=7  use_signal_ref=5 core0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;

jal test_passed
 

data_master4_core1:
    LI address, 0x8501C001 ##pull from data_master=4,push to data_master=7  use_signal_ref=5 core0  dr 4
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x4)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
    #LI temp_data_1 , 1
    #BEQ cl_num, temp_data_1, test_passed # 
jal test_passed
 	

data_master4_core2:
    LI address, 0x8501C002 ##pull from data_master=4,push to data_master=7  use_signal_ref=5 core0  dr 8
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x8)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
jal test_passed
 

data_master4_core3:
    LI address, 0x8501C003 ##pull from data_master=4,push to data_master=7  use_signal_ref=5 core0  dr 0xc
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0xC)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
jal test_passed
  

data_master4_core4:
    LI address, 0x8501C004 ##pull from data_master=4,push to data_master=7   use_signal_ref=5 core0  dr 0x10
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
    #LI temp_data_1 , 0
    #BEQ cl_num, temp_data_1, test_passed # 
jal test_passed


data_master4_core5:
    LI address, 0x8501C005 ##pull from data_master=4,push to data_master=7   use_signal_ref=5 core0  dr 0x14
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x14)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
    #LI temp_data_1 , 1
    #BEQ cl_num, temp_data_1, test_passed # 
jal test_passed	

data_master4_core6:
    LI address, 0x8501C006 ##pull from data_master=4,push to data_master=7   use_signal_ref=5 core0   dr 0x18
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x18)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;
jal test_passed

data_master4_core7:
    LI address, 0x8501C007 ##pull from data_master=4,push to data_master=7    use_signal_ref=5 core0    dr 0x1c
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x1C)  ;
    .insn s 43,0,address,cluster_scratch_reflect_from_sig_both(cppcmd_data_ref)	 ;# cpp command write
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;


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
#############for cluster0.group2.cpp_mem1
data_master7:
    LI temp_data_1 , 0
    BEQ cl_num, temp_data_1, data_master7_core0 # 
	
    LI temp_data_1 , 1
    BEQ cl_num, temp_data_1,  test_passed# 
	
    LI temp_data_1 , 2
    BEQ cl_num, temp_data_1,  test_passed# 
	
    LI temp_data_1 , 3
    BEQ cl_num, temp_data_1,  test_passed# 

    LI temp_data_1 , 4
    BEQ cl_num, temp_data_1,  test_passed# 
	
    LI temp_data_1 , 5
    BEQ cl_num, temp_data_1,  test_passed# 
	
    LI temp_data_1 , 6
    BEQ cl_num, temp_data_1,  test_passed# 
	
    LI temp_data_1 , 7
    BEQ cl_num, temp_data_1,  test_passed# 


    data_master7_core0: 
        WAIT_ON_SIGNAL (SIG5_pos,7) 	;  ##each core need wait for signal_ref 5
        WAIT_ON_SIGNAL (SIG5_pos,1) 	;
NOP
NOP
NOP

    LI data1, 0x44332211
    LI temp_data_2, 0
    LI xfer, CPP_MEM_ADDR 
    LWU temp_data_2, 0x0(xfer)
    BNE temp_data_2, data1, test_failed
    
    LI data2, 0x88776655
    LWU temp_data_2, 0x4(xfer)
    BNE temp_data_2, data2, test_failed
    
    LI data3, 0xCCBBAA99
    LWU temp_data_2, 0x8(xfer)
    BNE temp_data_2, data3, test_failed
    
    LI data4, 0x00FFEEDD
    LWU temp_data_2, 0xC(xfer)
    BNE temp_data_2, data4, test_failed
    
                                                    
    LI data1, 0x12344321
    LWU temp_data_2, 0x10(xfer)
    BNE temp_data_2, data1, test_failed
    
    LI data2, 0x56788765
    LWU temp_data_2, 0x14(xfer)
    BNE temp_data_2, data2, test_failed
    
    LI data3, 0x9abccba9
    LWU temp_data_2, 0x18(xfer)
    BNE temp_data_2, data3, test_failed
    
    LI data4, 0xdef00fed
    LWU temp_data_2, 0x1C(xfer)
    BNE temp_data_2, data4, test_failed

 






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


