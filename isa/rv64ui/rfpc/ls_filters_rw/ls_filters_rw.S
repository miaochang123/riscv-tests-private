##;------------------------------------------------------------
##; TEST_NAME: filters_rw
##;   Enable ME0 only
##;
##;	Exercise all 16 Filters
##;		Read/writes all Filter Status, Filter MAsk, Filter MAtch csrs
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
LI autopush_base,0x30000
LI offset2,USER_EVENT

##;Write Test Mode  
LI temp_data,0x80000007     ##; Set test_enable = 1, clock_divider = 7
SW temp_data,0x0(xfer)
LI temp_data,CONFIGURATION
ADD address,filter_base,temp_data

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 


filter_loop:

LI temp_data,0xffffffff   
SW temp_data,0x0(xfer)
LI temp_data,0x0   
SW temp_data,0x10(xfer)   


#;---------------------
#; Filter Type = 0
#;--------------------- 
##; Filter STaus/ACK  
ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect_data,0x0
LWU temp_data,0x100(xfer)
BNE temp_data,expect_data,test_failed

ADDI address,filter_base,FILTER_ACK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI expect_data,0x0
LWU temp_data,0x110(xfer)
BNE temp_data,expect_data,test_failed 

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect_data,0x0
LWU temp_data,0x120(xfer)
BNE temp_data,expect_data,test_failed  
#######################
ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect_data,0xffffffff
LWU temp_data,0x100(xfer)
BNE temp_data,expect_data,test_failed

ADDI address,filter_base,FILTER_ACK

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI expect_data,0xffffffff
LWU temp_data,0x110(xfer)
BNE temp_data,expect_data,test_failed 

ADDI address,filter_base,FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect_data,0x0
LWU temp_data,0x120(xfer)
BNE temp_data,expect_data,test_failed   

###; Filter_Mask  
LI temp_data,0x0
SW temp_data,0x10(xfer) 
LI temp_data,0xfffff       
SW temp_data,0x0(xfer)

ADDI address,filter_base,FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;     

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0xfffff
LWU temp_data,0x100(xfer)
BNE temp_data,expect_data,test_failed 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;     

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0
LWU temp_data,0x110(xfer)
BNE temp_data,expect_data,test_failed

##;Filter Match  
ADDI address,filter_base,FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;     

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0
LWU temp_data,0x120(xfer)
BNE temp_data,expect_data,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;     

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x130)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0xfffff
LWU temp_data,0x130(xfer)
BNE temp_data,expect_data,test_failed

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;     

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI expect_data,0x0
LWU temp_data,0x140(xfer)
BNE temp_data,expect_data,test_failed  

##################################################################
ADDI filter_count,filter_count,1
ADD filter_base,filter_base,0x40
LI temp_data,16
BNE temp_data,filter_count,filter_loop


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
