##;------------------------------------------------------------
##; TEST_NAME: ls_filters_throttle
##;   Enable ME0 only
##;
##; Original test has T_CLK = 2xP_CLK
##; Need to adjust throttling to take T_CLK = P_CLK into account	
##;------------------------------------------------------------   
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
#define cppcmd_data_ref x1
#define filter_count    x2
#define hart_id         x10 #hart csr register

#define address         x3
#define cl_num          x4
#define group_num       x5
#define filter_base     x6
#define autopush_base   x7
#define timeout_val     x8
#define a_data          x9
#define temp_data       x11
#define temp_data_1     x12
#define temp_data_2     x13
#define expect_data     x14
#define match_expect    x15
#define jump_num        x16
#define restart_value   x17
#define mask            x18
#define xfer            x19
#define offset2         x20
#define autopush_offset x21
#define offset3         x22
#define offset1         x23
#define sig_state       x24

.equ CPP_MEM_ADDR,       0xf0000000

.equ RING_SIZE          ,32
.equ RING_INDEX         ,0
.equ RING_INDEX_PLUS3   ,3
.equ RING_FULL_THRESHOLD,24 

.equ FILTER_STATUS  ,0x0
.equ FILTER_FLAGS   ,0x8
.equ FILTER_MASK    ,0x10
.equ FILTER_MATCH   ,0x18
.equ FILTER_ACK     ,0x20
.equ COMBINED_STATUS        ,0x800
.equ COMBINED_PENDING_STATUS,0x808
.equ CONFIGURATION          ,0x810
.equ USER_EVENT             ,0x400


RVTEST_RV64U
RVTEST_CODE_BEGIN

##LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
##AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
##SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number
                                                    
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
##OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
##SLLI group_num , group_num, 8 #each core has 256 byte of address space
	
LI xfer, CPP_MEM_ADDR 

LI filter_base,0x20000
LI filter_count,0
LI autopush_base,0x30000 
LI autopush_offset,0x0

LI offset1,0x200
LI offset2,0x400

##// NEW: This "should" slow down the clock_enable used for throttling
LI offset3,CONFIGURATION
LI temp_data,0x1
SW temp_data,0x0(xfer) # clock_divid config setting for throttling,  1= every 32 clocks, 0=every 16 clocks

ADD address,filter_base,offset3
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

filter_loop:
    LI temp_data,0x2
    SW temp_data,0x20(xfer) 
    LI temp_data,0x0       ##Data for writing to FILTER_STATUS 
    SW temp_data,0x0(xfer) 

##;-----------------------------------------------
##; AutoPush signal register
##;----------------------------------------------- 
## dataref=0,signal number=4,signal core0  datamaster=4
##
    LI temp_data,0x10200000
    SD temp_data,0x0(xfer)

    ADD address,autopush_base,offset1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##;-----------------------------------------------
##; AutoPush FilterStatusMonitor 0 - Need to rewrite each time to clear out EdgeDetected bit
##;-----------------------------------------------  
    LI temp_data,0x300  # Use  AutopushSignal register #0, 1/2/3 is for Type of Monitoring 
    SD temp_data,0x0(xfer)
    
    ADD address,autopush_base,autopush_offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

##;---------------------
##; Filter Type = 1 (Count16)
##;---------------------   
##; Match on event 2
    ADD address,filter_base,FILTER_MATCH
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	; 
    
###filter_type1
    LI temp_data,0x200000f  
    SD temp_data,0x0(xfer) 
    
    ADD address,filter_base,FILTER_MASK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	; 
    
##Timeout = 4  
    LI temp_data,0x80000000
    SW temp_data,0x10(xfer) 
    
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
    
##; Read filter_Status (ACK will load the upcounter  
    ADD address,filter_base,FILTER_ACK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
    
##; User Event Register - Generate an event  
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;
    
##; Read filter_Flags and Status   
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    ADD address,filter_base,FILTER_ACK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x60)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;
    
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x70)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG3_pos,1) 	; 

##; generate expect data and compare  
    LI expect_data,0x2  ##pending_status=1,status=0
    LW temp_data,0x50(xfer)
    BNE expect_data,temp_data,test_failed
    LI expect_data,0x0  ##pending_status=0,status=0
    LW temp_data,0x70(xfer)  
    BNE expect_data,temp_data,test_failed   

    LI mask,0xffff
    LI expect_data,0x2
    
    LWU temp_data,0x60(xfer)
    AND temp_data,temp_data,mask
    BNE expect_data,temp_data,test_failed   
    
    LI temp_data,20
    J add_delay

######################################################################## 
##; TEST2 - Reset upcounter, check that autopush occurrs when counter hits 0 
test2:
    ADD address,filter_base,FILTER_ACK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x50)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
##; User Event Register - Generate an event    
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
##; Read Status without ACK  
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x70)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

##; generate expect data and compare
    LI mask,0xffff
    LI expect_data,0x1    ##; Counted 1 events 
    LWU temp_data,0x80(xfer)
    AND temp_data,temp_data,mask
    BNE expect_data,temp_data,test_failed  
    
    LI expect_data,0x2    ## Pending status = 1, status = 0
    LWU temp_data,0x70(xfer)
    BNE expect_data,temp_data,test_failed  
    
    WAIT_ON_SIGNAL (SIG4_pos,1) 	;  
    ##; Autopushed into Data_ref 0  
    LI mask,0xffff
    LI expect_data,0x1    ##; Counted 1 events 
    LWU temp_data,0x0(xfer)
    AND temp_data_1,temp_data,mask
    BNE expect_data,temp_data_1,test_failed
    
    LI mask,0x1f800000
    LI expect_data,0x0     ##Bits [28:23] should be 0 
    AND temp_data_1,temp_data,mask
    BNE expect_data,temp_data_1,test_failed  ##; Upcounter should be 0 

############################################################################################
##; TEST3 - Reset upcounter, check that autopush occurrs when counter > Override_count  
##;-----------------------------------------------
##; AutoPush FilterStatusMonitor 0 - Need to rewrite each time to clear out EdgeDetected bit
##;-----------------------------------------------  

test3:
    LI temp_data,0x300  # Use  AutopushSignal register #0, 1/2/3 is for Type of Monitoring 
    SD temp_data,0x0(xfer)
    
    ADD address,autopush_base,autopush_offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
##; Timeout = 5  
    LI temp_data,0xa0020000   #Timeout = 5  , Override Count 2
    SW temp_data,0x10(xfer) 
    
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
##; Read filter_Status (ACK will load the upcounter  
    ADD address,filter_base,FILTER_ACK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
    
##; User Event Register - Generate an event  
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;   
    
##; Read filter_Flags and Status  
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0xa0)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0xb0)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
##; The 3rd event should generate the autopush  
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
    WAIT_ON_SIGNAL (SIG4_pos,1) 	; 
    
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0xc0)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG3_pos,1) 	;

##; generate expect data and compare
    LI expect_data,0x2    ##;Pending status = 1, status = 0  
    LWU temp_data,0xa0(xfer)
    BNE expect_data,temp_data,test_failed  
    
    LI expect_data,0x0    ##;Pending status = 0, status = 0  
    LWU temp_data,0xc0(xfer)
    BNE expect_data,temp_data,test_failed
    
    LI mask,0xffff
    LI expect_data,0x2          ##; Counted 2 events  
    LWU temp_data,0xb0(xfer)
    AND temp_data,temp_data,mask
    BNE expect_data,temp_data,test_failed
    
    LI expect_data,0x3          ##; Counted 3 events  
    LWU temp_data,0x0(xfer)
    AND temp_data_1,temp_data,mask
    BNE expect_data,temp_data_1,test_failed  
    
    #LI expect_data,0x0     ##Bits [28:23] should not be 0 
    LI mask,0x1f800000
    AND temp_data_1,temp_data,mask
    BEQZ temp_data_1,test_failed  ##; Upcounter should not be 0
        
############################################################    
##;TEST4 - Check that Throttling gets disabled after 32 events 
test4:
##; Timeout = 7  
    LI temp_data,0xe0240000   #Timeout = 7  , Override Count 36
    SW temp_data,0x10(xfer) 
    
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    ADD address,filter_base,FILTER_ACK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
##; User Event Register - Generate an event 
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ; 
    WAIT_ON_SIGNAL (SIG5_pos,7) 	;  
    
    
##; Read filter_Flags and Status  
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
    
    LI expect_data,0x3    ##;Pending status = 1, status = 1  
    LWU temp_data,0x80(xfer)
    BNE expect_data,temp_data,test_failed  
    
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;   
    
##; Read filter_Flags and Status  
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; generate expect data and compare
    LI expect_data,0x3    ##;Pending status = 1, status = 1  
    LWU temp_data,0x90(xfer)
    BNE expect_data,temp_data,test_failed  
############################################################################
##; TEST5 - Now lets do a Test using FilterType Bitmask16 (type 3)  
##Clear out to 0, so false filter assert doesn't happen when switching types
test5:
    LI temp_data,0
    SW temp_data,0x10(xfer)
                                            
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;   
    
##;-----------------------------------------------
##; AutoPush FilterStatusMonitor 0 - Need to rewrite each time to clear out EdgeDetected bit
##;-----------------------------------------------      
    LI temp_data,0x300  # Use  AutopushSignal register #0, 1/2/3 is for Type of Monitoring 
    SD temp_data,0x0(xfer)
    
    ADD address,autopush_base,autopush_offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    
###filter_type3
    LI temp_data,0x600000f  
    SD temp_data,0x0(xfer) 
    
    ADD address,filter_base,FILTER_MASK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;
    
##; Timeout = 5  Override Count=2
    LI temp_data,0xa0200000
    SW temp_data,0x10(xfer) 
    
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
    
##; Read filter_Status (ACK will load the upcounter  
    ADD address,filter_base,FILTER_ACK
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
##; User Event Register - Generate an event 
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;
    
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;
    
##; Read filter_Flags and Status  
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    ADD address,filter_base,FILTER_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0xa0)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
##; The 3rd event should generate the autopush 
    ADD address,autopush_base,offset2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
    WAIT_ON_SIGNAL (SIG4_pos,1) 	;
    
    ADD address,filter_base,FILTER_FLAGS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x90)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;


##; generate expect data and compare
    LI expect_data,0x2    ##;Pending status = 1, status = 0  
    LWU temp_data,0x40(xfer)
    BNE expect_data,temp_data,test_failed  
    
    LI expect_data,0x0    ##;Pending status = 0, status = 0  
    LWU temp_data,0x90(xfer)
    BNE expect_data,temp_data,test_failed   
    
    LI mask,0xf
    LI expect_data,0x2          ##; Counted 2 events  
    LWU temp_data,0xa0(xfer)
    SRLI temp_data,temp_data,16
    AND temp_data,temp_data,mask
    BNE expect_data,temp_data,test_failed
    
    LI expect_data,0x3          ##; Counted 3 events  
    LWU temp_data,0x0(xfer)
    SRLI temp_data_1,temp_data,16
    AND temp_data_1,temp_data_1,mask
    BNE expect_data,temp_data_1,test_failed  
    
    #LI expect_data,0x0     ##Bits [28:23] should not be 0 
    LI mask,0x1f800000
    AND temp_data_1,temp_data,mask
    BEQZ temp_data_1,test_failed  ##; Upcounter should not be 0
    
    ADDI filter_count,filter_count,1
    ADDI filter_base,filter_base,0x40
    ADDI autopush_offset,autopush_offset,0x8
    LI temp_data,16
    BNE temp_data,filter_count,filter_loop

J test_passed


#####  macro add_delay[count]
add_delay:
    ADDI temp_data,temp_data,-1
    BNEZ temp_data,add_delay
    J test2 



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
