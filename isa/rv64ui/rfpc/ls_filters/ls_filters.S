##;------------------------------------------------------------
##; TEST_NAME: filters
##;   Enable ME0 only
##;
##;	Exercise all 16 Filters
##;	Use all 16 FilterStatus Monitors
##;	
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
#define match_expect      x15
#define jump_num        x16
#define restart_value   x17
#define mask_data       x18
#define xfer            x19
#define offset2         x20


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

#############################
LI mask_data,0xffff
LI temp_data,0x0
SW temp_data,0x10(xfer)

LI filter_base,0x20000
LI filter_count,0
LI autopush_base,0X30000
LI offset2,USER_EVENT

filter_loop:

SW filter_count,0x20(xfer)
##; A different MATCHING event  
LI temp_data,0xf00
OR temp_data,temp_data,filter_count
SW temp_data,0x30(xfer)

##; Use $xfer3 as a DUMMY event that != $xfer2 (matching event)    
SLLI a_data,filter_count,4
ADD temp_data,a_data,filter_count #; Use filter_count as variable for the event SRC field                                                                                                    
SW temp_data,0x40(xfer) 

ADD match_expect,filter_count,zero

LI temp_data,0x0   #Data for writing to FILTER_STATUS 
SW temp_data,0x10(xfer)

LI temp_data,0x66666666   #Data for debug 
SW temp_data,0x260(xfer)  

#;---------------------
#; Filter Type = 0
#;---------------------  
ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI temp_data,0xf       ########???????????????????????
SW temp_data,0x0(xfer)

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI expect_data,0xf
LWU temp_data,0x0(xfer)
BNE temp_data,expect_data,test_failed 

##; Match on event me_num+1 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x180)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   


LWU temp_data,0x180(xfer)
BNE temp_data,match_expect,test_failed
 
##; User Event Register - Generate an event = me_num+1 
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI  expect_data,0x3
LWU temp_data,0x10(xfer)
BNE temp_data,expect_data,test_failed   

##; Read filter_Status   
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI  expect_data,0x1         ##; 1 event was generated
LWU temp_data,0x0(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI  expect_data,0x0         ##The read of Filter ACK should have cleared this register                                                                                                               
LWU temp_data,0x10(xfer)
BNE temp_data,expect_data,test_failed  

##for debug
LI address,0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
##;---------------------
##; Filter Type = 1 (Count16)
##;---------------------    

##; Match on event  
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

LI temp_data,0x200000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Timeout = 0  
LI timeout_val,0
SW timeout_val,0x10(xfer) 

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event  
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

#; Read filter_Status   
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x220)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

SLLI temp_data,timeout_val,29
ORI expect_data,temp_data,1   #; Count = 1   
LWU temp_data,0x220(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI  expect_data,0x0         ##The read of Filter ACK should have cleared this register                                                                                                               
LWU temp_data,0x10(xfer)
BNE temp_data,expect_data,test_failed 

#; Timeout = 1   
Timeout1:
LI timeout_val,0x1
LI restart_value,0x3f
LI jump_num,0x2
J  test_filter_type1_status

Timeout2:
LI timeout_val,0x2
LI restart_value,0x3e
LI jump_num,0x3
J  test_filter_type1_status 

Timeout3:
LI timeout_val,0x3
LI restart_value,0x3c
LI jump_num,0x4
J  test_filter_type1_status 

Timeout4:
LI timeout_val,0x4
LI restart_value,0x38
LI jump_num,0x5
J  test_filter_type1_status 

Timeout5:
LI timeout_val,0x5
LI restart_value,0x30
LI jump_num,0x6
J  test_filter_type1_status 

Timeout6:
LI timeout_val,0x6
LI restart_value,0x20
LI jump_num,0x7
J  test_filter_type1_status 

Timeout7:
LI timeout_val,0x7
LI restart_value,0x01
LI jump_num,0x8
J  test_filter_type1_status 


##for debug
LI address,100
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
###;---------------------
###; Filter Type = 2 (BITMASK32) - 32 bit bitmask of SRC_ID that matched
###;---------------------  
Filter_Type2:

LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0x400000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

#; Dummy Acknowledge to clear the status - Should change of filter type clear status ????
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Match on event me_num+1 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event 
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Expect_Data is ( 1 << filter_count) 
LI temp_data,0x1
SLL expect_data,temp_data,filter_count
LWU temp_data,0x40(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI  expect_data,0x0         ##The read of Filter ACK should have cleared this register                                                                                                               
LWU temp_data,0x110(xfer)
BNE temp_data,expect_data,test_failed    

##for debug
LI address,200
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
###;---------------------
###; Filter Type = 3
###;---------------------  
LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0x600000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Match on event 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event 
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x60)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   


## ; Event source = 0 , so bit 0 is set      Count = 1 event  
LI expect_data,0x10001
LWU temp_data,0x60(xfer)
BNE temp_data,expect_data,test_failed  

##; Verify that 4 bit counter saturates at 16 correctly 
##; More Filter Type = 3   
ADD address,autopush_base,offset2  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;     

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;     

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;    

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;     

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;    

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;     

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG6_pos,1) 	;    

##; Read filter_Status  
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x160)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

## ; Event source = 0 , so bit 0 is set      Count = 1 event  
LI expect_data,0xf0001      ##Count = 15 events (saturating value)
LWU temp_data,0x160(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0       #; The read of Filter ACK should have cleared this register
LWU temp_data,0x10(xfer)
BNE temp_data,expect_data,test_failed   

##for debug
LI address,300
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

###; Filter Type = 4   (FIRST EVENT) 
LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0x800000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Match on event 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event 
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0x240000
OR expect_data,expect_data,temp_data
LWU temp_data,0x80(xfer)
BNE temp_data,expect_data,test_failed

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x130)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0       #; The read of Filter ACK should have cleared this register
LWU temp_data,0x130(xfer)
BNE temp_data,expect_data,test_failed


#; Verify that count saturates at 3 (2 bit counter) 
##; User Event Register - Generate an event 
ADD address,autopush_base,offset2  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status   
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0x340000
OR expect_data,expect_data,temp_data
LWU temp_data,0x90(xfer)
BNE temp_data,expect_data,test_failed

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0       #; The read of Filter ACK should have cleared this register
LWU temp_data,0x140(xfer)
BNE temp_data,expect_data,test_failed 
##for debug
LI address,400
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Filter Type = 5 (LAST EVENT)  
LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0xa00000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Match on event me_num+1 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event  = me_num+1  
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0x240000
OR expect_data,expect_data,temp_data
LWU temp_data,0x110(xfer)
BNE temp_data,expect_data,test_failed

##; Verify that count saturates at 3 (2 bit counter)
##; User Event Register - Generate an event = me_num+1   
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0x340000             ## Count field should saturate at 3  
OR expect_data,expect_data,temp_data
LWU temp_data,0x120(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0       #; The read of Filter ACK should have cleared this register
LWU temp_data,0x140(xfer)
BNE temp_data,expect_data,test_failed     

##for debug
LI address,500
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
##; Filter Type = 6   (FIRST EVENT unthrottled)    
LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0xc00000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Match on event me_num+1 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event  = me_num+1  
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0x20040000
OR expect_data,expect_data,temp_data
LWU temp_data,0x90(xfer)
BNE temp_data,expect_data,test_failed

##; Verify that count saturates at 3 (2 bit counter)
##; User Event Register - Generate an event = me_num+1   
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ; 
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;      

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0xa0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0xf0040000             ## Count field should saturate at 15  
OR expect_data,expect_data,temp_data
LWU temp_data,0xa0(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0xb0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0       #; The read of Filter ACK should have cleared this register
LWU temp_data,0xb0(xfer)
BNE temp_data,expect_data,test_failed 


##for debug
LI address,600
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
##; Filter Type = 7 (LAST EVENT_unthrottled)  
LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0xe00000f       
SW temp_data,0x0(xfer)   

ADDI address,filter_base,FILTER_MASK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; Match on event me_num+1 
ADDI address,filter_base,FILTER_MATCH

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; User Event Register - Generate an event  = me_num+1  
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0x20040000
OR expect_data,expect_data,temp_data
LWU temp_data,0x140(xfer)
BNE temp_data,expect_data,test_failed

##; Verify that count saturates at 5 (4 bit counter)
##; User Event Register - Generate an event = me_num+1   
ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;    

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;     

##; Read filter_Status 
ADDI address,filter_base,FILTER_ACK  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x150)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI expect_data,filter_count,0
LI temp_data,0xf0040000             ## Count field should saturate at 15  
OR expect_data,expect_data,temp_data
LWU temp_data,0x150(xfer)
BNE temp_data,expect_data,test_failed  

ADDI address,filter_base,FILTER_FLAGS  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0xc0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0       #; The read of Filter ACK should have cleared this register
LWU temp_data,0xc0(xfer)
BNE temp_data,expect_data,test_failed   

##for debug
LI address,700
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x260)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##################################################################
ADDI filter_count,filter_count,1
ADD filter_base,filter_base,0x40
LI temp_data,16
BNE temp_data,filter_count,filter_loop


LI filter_count,0
LI expect_data,1

combined_loop:
SW filter_count,0x0(xfer)

ADD address,autopush_base,offset2

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI temp_data,COMBINED_STATUS
ADD address,filter_base,temp_data

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

LI temp_data,COMBINED_PENDING_STATUS
ADD address,filter_base,temp_data 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x130)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LWU temp_data,0x120(xfer)
BNE temp_data,expect_data,test_failed

LWU temp_data,0x130(xfer)
BNE temp_data,expect_data,test_failed  

SLLI temp_data,expect_data,1
ORI expect_data,temp_data,1

ADDI filter_count,filter_count,1
LI temp_data,16
BNE temp_data,filter_count,combined_loop 



##;Write Test Mode  

LI temp_data,0x80000007     ##; Set test_enable = 1, clock_divider = 7
SW temp_data,0x0(xfer)
LI temp_data,CONFIGURATION
ADD address,filter_base,temp_data

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI filter_base,0x20000
LI filter_count,0x0

test_loop:
LI temp_data,0xffffffff
SW temp_data,0x0(xfer)
##; FILTER STATUS is only writable in test_mode - check that we can read/write 
ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
LI expect_data,0xffffffff
LWU temp_data,0x0(xfer)
BNE expect_data,temp_data,test_failed  

ADDI filter_base,filter_base,0x40
ADDI filter_count,filter_count,1
LI temp_data,16
BNE temp_data,filter_count,test_loop  
J test_passed
######macro test_filter_type1_status##########
test_filter_type1_status:
    SLLI temp_data,timeout_val,29
    SW  temp_data,0x10(xfer)
    
    ADDI address,filter_base,FILTER_STATUS
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;    
    
    ##; NOTE: Need to get two Acknowledge as close together as possible...
    ##;       Do not want more than one clock_enable to occur between them
    ##; Acknowledge should load the up-counter restart value   
    ADDI address,filter_base,FILTER_ACK
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x210)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
       
    ##Read filter_Status
    ##Checking that Up_counter_restart_value is correct...(checking for value OR value + 1)       
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x210)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    WAIT_ON_SIGNAL (SIG2_pos,1) 	;  
    
    SLLI expect_data,timeout_val,29
    SLLI temp_data,restart_value,23    ##Upcounter restart value 
    OR expect_data,expect_data,temp_data
    
    LWU temp_data,0x210(xfer)
    BEQ temp_data,expect_data,filter_check_passed
    
    ADDI restart_value,restart_value,1
    LI temp_data,0x3f
    AND restart_value,restart_value,temp_data
    SLLI expect_data,timeout_val,29
    SLLI temp_data,restart_value,23    ##Upcounter restart value 
    OR expect_data,expect_data,temp_data  
    
    LWU temp_data,0x210(xfer)
    BNE temp_data,expect_data,test_failed 

filter_check_passed:
##; User Event Register - Generate an event
    ADD address,autopush_base,offset2

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

    LI temp_data,0x4
    SLTU temp_data,timeout_val,temp_data ###<4  
    BNEZ temp_data,skip_throttle_check

##Lets check that status gets throttled by reading FLAGS register 
    ADDI address,filter_base,FILTER_FLAGS

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x220)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    LI expect_data,0x2  ## 2 = Pending status only 
    LW temp_data,0x220(xfer)
    BNE temp_data,expect_data,test_failed

skip_throttle_check:
##; Read filter_Status  
    ADDI address,filter_base,FILTER_ACK

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x230)  ;
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LI expect_data,0x1  ## Checking that event count == 1
    LWU temp_data,0x230(xfer)
    AND temp_data,temp_data,mask_data

    BNE temp_data,expect_data,test_failed 
    

    LI temp_data,0x2
    BEQ  temp_data,jump_num,Timeout2

    LI temp_data,0x3
    BEQ  temp_data,jump_num,Timeout3  

    LI temp_data,0x4
    BEQ  temp_data,jump_num,Timeout4  

    LI temp_data,0x5
    BEQ  temp_data,jump_num,Timeout5  

    LI temp_data,0x6
    BEQ  temp_data,jump_num,Timeout6  

    LI temp_data,0x7
    BEQ  temp_data,jump_num,Timeout7  

    LI temp_data,0x8
    BEQ  temp_data,jump_num,Filter_Type2

    J test_failed            

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
