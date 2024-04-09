################################################
##TEST_NAME: csr_rw
##	Only run on one ME.
##  TEST Ring\EventManager\AutoPush\Hash Registers
################################################  

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
#define count           x4
#define hart_id         x10 #hart csr register

#define address         x16
#define address4        x17
#define cl_num          x18
#define group_num       x19
#define data_f          x23
#define data_op         x24
#define temp_data       x20
#define temp_data_1     x21
#define temp_data_2     x22
#define expect0         x11
#define expect1         x12
#define offset          x13
#define end_offset      x14
#define xfer            x26



.equ CPP_MEM_ADDR   ,    0xf0000000

.equ INIT_RESIDUE   ,    0x87654321
.equ AUTOPUSH_DATA0A,    0xffffffffffffffff
.equ AUTOPUSH_DATA1A,    0xffffffffffffffff

.equ DATA_ALLF,    0xffffffff

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

#store the add_data to cpp memory 
LI temp_data, AUTOPUSH_DATA0A
SD temp_data, 0x0(xfer)
LI temp_data, 0x0
SD temp_data, 0x8(xfer)


#######################################
## Base for Rings = 0x00001_0000
#######################################



##------------------------------------
## RingBase
##------------------------------------
## Bit  [29] is reserved 
## Bits [23:19] are reserved
## Bits [15:9] are reserved

LI data_f , DATA_ALLF
LI data_op, 0xdfffffff
AND expect1 , data_f , data_op
LI data_op, 0xff07ffff
AND expect1, expect1 , data_op
LI data_op, 0xdfff01ff
AND expect1, expect1 , data_op

LI expect0, 0

LI offset , 0
LI end_offset , 0x80
 
ring_base:    
    ##write all data to cls reg
    LI address, 0x10000
    ADD address,address,offset
    ##write 1 to reg bit
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;    
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x100);
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	;
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LI temp_data,0
    LWU temp_data, 0x100(xfer)
    BNE temp_data, expect1, test_failed

    LI temp_data_2, INIT_RESIDUE
    LWU temp_data_2, 0x104(xfer)
    BNE temp_data_2, expect0, test_failed

    ##write 0 to reg bit
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;    
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x110);
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	;
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LI temp_data,0
    LWU temp_data, 0x110(xfer)
    BNE temp_data, expect0, test_failed

    LI temp_data_2, INIT_RESIDUE
    LWU temp_data_2, 0x114(xfer)
    BNE temp_data_2, expect0, test_failed  

    ADDI offset, offset, 0x8
    BNE end_offset, offset, ring_base

NOP
NOP
NOP

##------------------------------------
## Ring ptr
##------------------------------------  
## Ring ptr valid bits are 
##	[28:16] and [12:0] - OLD
LI data_f , DATA_ALLF
LI data_op , 0x1fff1fff
AND expect1, data_op , data_f

LI expect0, 0

LI offset , 0
#LI offset , 0x80
LI end_offset , 0x80

ring_ptr:
  LI address ,0x10080 
  ##write all data to cls reg 
  ADD address,address,offset
  # set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x200)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data, INIT_RESIDUE
  LWU temp_data, 0x200(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x204(xfer)
  BNE temp_data_2, expect0, test_failed

    # reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8);
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x210)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data, INIT_RESIDUE
  LWU temp_data, 0x210(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x214(xfer)
  BNE temp_data_2, expect0, test_failed

  ADDI offset, offset, 0x8
  BNE end_offset, offset, ring_ptr

NOP
NOP
NOP


##########################################
## Base for AutoPush = 0x00003_0000
##########################################


##------------------------------------
## Filter Status Monitor
##------------------------------------
## Valid RW  bits  for Filter Monitor are [9:8],[3:0] 
##  bits[17:16] Are write to clear

LI expect1, 0x30f

LI expect0, 0

LI offset , 0
LI end_offset , 0x80

filter_monitor:
  LI address , 0x30000
  ADD address , address , offset

  ##write all data to cls reg
  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x100)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x100(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x104(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x110)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x110(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x114(xfer)
  BNE temp_data_2, expect0, test_failed

  ADDI offset, offset, 0x8
  BNE end_offset, offset, filter_monitor

NOP
NOP
NOP

##------------------------------------
## AutoPush_signal
##------------------------------------
##; Valid RW  bits  for AutoPush_signal are
##;	 [27:24],[22:16],[13:0]
##; New [31:28] = Master_island[3:0]
##; New [15:14] = Master_island[5:4]
##; If write all 0's , Master_Island field will be set to Current Island #
## for merlin
##   Valid RW  bits  for AutoPush_signal are 
##    [34:31],[30:26],[25:19],[18:16],[15:0]
##  New [34:31] = Master_island[3:0]
##  New [18:16] = Master_island[6:4]
##  If write all 0's , Master_Island field will be set to Current Island #

LI expect1, 0xffffffff  
LI expect0, 0x7

LI offset , 0
LI offset , 0x200
LI end_offset , 0x280

autopush_signal:
  LI address , 0x30000
  ADD address , address , offset

  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x200)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI expect1, 0xffffffff 
  LI expect0, 0x7
  LI temp_data,0
  LWU temp_data, 0x200(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x204(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x210)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI expect1, 0x80000000
  LI expect0, 0x0
  LI temp_data,0
  LWU temp_data, 0x210(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x214(xfer)
  BNE temp_data_2, expect0, test_failed
  
  ADDI offset, offset, 0x8
  BNE end_offset, offset, autopush_signal

NOP
NOP
NOP
##------------------------------------
## Write Alert Config
##------------------------------------
### Bits  [31:24] are reserved 
### Bit [7] is reserved
 
LI expect1, 0xffff7f  
LI expect0, 0x0

WriteAlertConfig :
  LI address , 0x30600

  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x230)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x230(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x234(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x240)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x240(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x244(xfer)
  BNE temp_data_2, expect0, test_failed  

NOP
NOP
NOP  

##------------------------------------
## VFTranslation
##------------------------------------
### Bits [31:26] are reserved 
### Bits [15:12] are reserved
### Bits [3:2] are reserved  
LI expect1, 0x3ff0ff3  
LI expect0, 0x0

VFTranslation:
  LI address , 0x30620

  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x260)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

  LI temp_data,0
  LWU temp_data, 0x260(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x264(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x270)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x270(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x274(xfer)
  BNE temp_data_2, expect0, test_failed  

NOP
NOP
NOP                               

##;--------------------------------------
##; Base for Hash = 0x00004_0000
##;--------------------------------------
LI address, 0x40000

##write all data to cls reg
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 31, DRef = 0	
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

##// HashMultiply - 
##// 11/09/2016 - FIX - There is only one HASH_MULT... NOT one for each index....
##; YLD:    Valid RW  bits  for Hash Mulitply are [3:0]
##; TH      Valid RW  bits  for Hash Mulitply are [8:0]
##; TH-C0   Valid RW  bits  for Hash Mulitply are [9:0]
LI expect1, 0x3FF
LI expect0, 0

LI offset, 0

hash_multiply:
  LI address , 0x40000
  ADD address , address , offset
  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x50)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x50(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x54(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x60)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x60(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x64(xfer)
  BNE temp_data_2, expect0, test_failed    

NOP
NOP
NOP

##;--------------------------------------
##; Base for Event Manager = 0x00002_0000
##;--------------------------------------
LI expect1, 0x0fffffff
LI expect0, 0

LI offset , 0
LI offset , 0x10
LI end_offset , 0x210 
LI address, 0x20000
##------------------
## Maskbits used are [24:0] and [27:25]  from merlin  design/event_bus.hg/cdl/src/event_filter.cdl 
## no newer EAS of event_manager,need update 25/6/2023 
##------------------
event_mask:
  LI address, 0x20000 
  ADD address , address , offset
  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

  LI temp_data,0
  LWU temp_data, 0x80(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x84(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x90)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x90(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x94(xfer)
  BNE temp_data_2, expect0, test_failed
  
  ADDI offset, offset, 0x40
  BNE end_offset, offset,event_mask   

NOP
NOP
NOP

LI expect1, 0x01ffffff
LI expect0, 0

LI offset , 0
LI offset , 0x18
LI end_offset , 0x218 
LI address, 0x20000 
event_match:
  LI address, 0x20000 
  ADD address , address , offset
  #set reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x500)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	; 

  LI temp_data,0
  LWU temp_data, 0x500(xfer)
  BNE temp_data, expect1, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x504(xfer)
  BNE temp_data_2, expect0, test_failed

  #reset reg
  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x8)  ;
  .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x510)  ;
  .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command write
  WAIT_ON_SIGNAL (SIG1_pos,1) 	;

  LI temp_data,0
  LWU temp_data, 0x510(xfer)
  BNE temp_data, expect0, test_failed

  LI temp_data_2, INIT_RESIDUE
  LWU temp_data_2, 0x514(xfer)
  BNE temp_data_2, expect0, test_failed
  
  ADDI offset, offset, 0x40
  BNE end_offset, offset,event_match 



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
