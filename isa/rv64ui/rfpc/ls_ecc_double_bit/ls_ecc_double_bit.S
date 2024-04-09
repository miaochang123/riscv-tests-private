#;-----------------------
#; TEST_NAME: ls_ecc_double_bit.uc
#;      ME0 will read bad ECC data from the cluster local scratch
#;      ME0 should halt and ME1 should get an autopush signal
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


#define zero   x0 # zero register
#define cppcmd_data_ref x3
#define count         x4
#define hart_id       x10 #hart csr register

#define expect        x11
#define xfer          x12
#define expect2       x13
#define data_cmp      x14
#define xpb_base      x15
#define mask          x16
#define base          x19
#define address       x20
#define address1      x21
#define cl_num        x22
#define group_num     x23
#define temp_data     x24
#define temp_data_1   x25
#define temp_data_2   x26

#define my_datamaster x30
#define interrupt_base x31


.equ CPP_MEM_ADDR,   0xf0000000

.equ  FILTER_STATUS,  0x0
.equ  FILTER_MASK,    0x10
.equ  FILTER_MATCH,   0x18
.equ  CLS_ECCMON_XPB_DEVICE_ID,   0x13


.equ INTERRUPT_STATUS_MID  , 0x20
.equ INTERRUPT_MID		   , 0x28
.equ INTERRUPT_STATUS_HIGH , 0x30
.equ INTERRUPT_HIGH		   , 0x38
.equ INTERRUPT_CONFIG	   , 0x40
.equ INTERRUPT_EVENT_CONFIG0	   , 0x50
.equ INTERRUPT_EVENT_CONFIG1	   , 0x58
.equ INTERRUPT_CAPTURE_TIMER_STATUS, 0x70
.equ INTERRUPT_CAPTURE_TIMER_VALUE , 0x78


.equ WR_DATA0A,    0x00000001
.equ WR_DATA1A,    0x00000000
.equ WR_DATA2A,    0x0000000f
.equ WR_DATA3A,    0x0000000a


RVTEST_RV64U
RVTEST_CODE_BEGIN

LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number


LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 256 byte of address space
	

LI xfer, CPP_MEM_ADDR


#; ME0 will set up event filter
#;   ME0 will generate a uncorrectable error 
#;   ME1 will get siganlled and check filter status  
LI   my_datamaster,0xf00
AND  my_datamaster,my_datamaster,a0
SRLI my_datamaster,my_datamaster,8 

LI  temp_data , 0x0
BEQ my_datamaster, temp_data,master_4 
LI  temp_data , 0x2 
BEQ my_datamaster, temp_data,master_7


master_4:


#store the add_data to cpp memory 
LI temp_data, 0x1
SW temp_data, 0x0(xfer)
LI temp_data, 0x3
SW temp_data, 0x4(xfer)
LI temp_data, 0x1
SW temp_data, 0x8(xfer)
LI temp_data, WR_DATA3A
SW temp_data, 0xC(xfer)


##write all data to ecc_mon

##XPB: Set ECC enable (address 0) 
LI base, 0x000d0000  ##misc engine command address
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;

##XPB: Set ECC mode (ImjectECCOneShot address=0x10) 
LI base,0x000d0010
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x4)  ;
.insn s 43,0,base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##XPB: Clear Error count
LI base,0x000d0020
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x8)  ;
.insn s 43,0,base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#;-----------------------------------------------
#;EventFilter0
#;-----------------------------------------------   
LI base,0x20000
LI interrupt_base,0x50000

LI temp_data,0x10000
SW temp_data,0x20(xfer)
LI temp_data,0xAAAAAAAA
SW temp_data,0x30(xfer) 

ADDI address,interrupt_base,INTERRUPT_HIGH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

ADDI address,interrupt_base,INTERRUPT_EVENT_CONFIG1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

ADDI address,interrupt_base,INTERRUPT_CAPTURE_TIMER_STATUS
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI temp_data,0xf
SW temp_data,0x40(xfer)

ADDI address,base,FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

##; Match on event 11  which is event = Multi Bit ECC error 
LI temp_data,0xb
SW temp_data,0x50(xfer)

ADDI address,base,FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  


##; AutoPush
##; [13:0] data_ref          [15:0]
##; [22:16] signal_ref       [25:19]
##; [27:24] ME/master        [30:26]


##; AutoPush Signal 0 
##;	Send Data ref2, Signal=3 to ME1(master 7)


LI temp_data,0x1c180002   ##Send Data ref2, Signal=3 to ME1(master 7)
SD temp_data,0x10(xfer)

LI address,0x30200
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##; AutoPush FilterStatusMonitor 0 
##;Use autopush  Signal register 0 
LI temp_data,0x100
SD temp_data,0x20(xfer) 

LI address,0x30000
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI temp_data,0x1111
SW temp_data,0x30(xfer)
LI temp_data,0x2222
SW temp_data,0x34(xfer)  
LI temp_data,0x1111
SW temp_data,0x38(xfer)  
LI temp_data,0x2222
SW temp_data,0x3c(xfer)  

ADD address,group_num,zero
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x30)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

LI expect,0x1111

ADD address,group_num,zero
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

LWU temp_data,0x40(xfer)
BEQ temp_data,expect,test_failed ##; The ME should halt when I try to use the bad data   
#; Should not return to here  
J test_failed



###################################
master_7:

###; ME1 should get autopushed signal 3 on a double bit error  
WAIT_ON_SIGNAL (SIG3_pos,1) 	;  
##;-----------------------------------------------
##; Reading EventFilter0 status
##;   Verifying that Event count = 1
##;-----------------------------------------------  

LI address,0x20000
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI expect,0x1
LW temp_data,0x10(xfer)
BNE temp_data,expect,test_failed

##Check that Interrupt status was generated for ME0 which is bit 16
#in merlin, has no function  
#LI address,0x50030
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
#.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
#WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
#
#LI expect,0x10000
#LWU temp_data,0x20(xfer)
#BNE temp_data,expect,test_failed




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


