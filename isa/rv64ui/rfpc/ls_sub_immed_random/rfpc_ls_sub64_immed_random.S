#--------------------------------
# TEST_NAME: rfpc_ls_sub64_immed_random.S
# cmd: sub64_imm         7/1 
#      test_sub64_imm   23/0
#--------------------------------

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
	
#define cppcmd_data_ref x3
#define loop_count      x4 
#define group_num       x5
#define cl_num          x6
#define temp_data_1     x7 
#define address         x8
#define xfer            x9  
#define hart_id         x10 #hart csr register

#define  data1a        x11
#define  data2a        x12
#define  data3a        x13
#define  data4a        x14

#define  data1b        x15
#define  data1b2       x16
#define  data3b        x17
#define  data3b2       x18

#define  expect1       x19
#define  expect2       x20
#define  expect3       x21
#define  expect4       x22


#define  temp_data     x23
#define  mask          x24
#define  remainder     x25
#define  four          x26
#define  three         x27
#define  two           x30
#define  one           x31 


.equ NUM_OPERATIONS ,   20
.equ MEM_SIZE_DIV16 ,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR   ,   0xf0000000 

RVTEST_RV64U
RVTEST_CODE_BEGIN
#------------------------------------
#Set Up the BASE scratch address
#Each ME will use a different region
#------------------------------------
	
LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127

SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	
ADD address, group_num, zero


LI xfer, CPP_MEM_ADDR 
LI mask, 0x3fff
LI one ,1
LI two ,2
LI three,3
LI four ,4 
####################################################
# test1    64bit sub_imm
####################################################
LI loop_count, NUM_OPERATIONS
sub64_imm_loop:
LI data1a ,0xffffffffffffffff
#LI data2a ,0xffffffff
LI data3a ,0x4444444411111111
#LI data4a ,0x44444444

#store the data to cpp memory 
SD data1a ,0x0(xfer)
#SW data2a ,0x4(xfer)
SD data3a ,0x8(xfer)
#SW data4a ,0xc(xfer)

LI data1b ,0xf434   
LI data3b ,0x0565 
#write data to sram

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 


REM remainder, loop_count, four
BEQ remainder, one,   bits_01
BEQ remainder, two,   bits_10
BEQ remainder, three, bits_11

bits_00:  #No sign extension here
AND data1b,data1b,mask
AND data3b,data3b,mask
SUB expect1,data1a,data1b 
SUB expect3,data3a,data3b

J   to_sub64_imm 

bits_01: # Bits [15:14] 01 Sign extend 
LI  temp_data,0X1FFF
AND data1b,data1b,temp_data 
LI  temp_data,0x4000
OR  data1b,data1b,temp_data    #no sign   bit15_13=010
AND data1b2,data1b,mask 
SUB expect1,data1a,data1b2

LI  temp_data,0X3FFF
AND data3b,data3b,temp_data 
LI  temp_data,0x6000
OR  data3b,data3b,temp_data    #sign   bit15_13=011 
AND data3b2,data3b,mask 
LI  temp_data,0xFFFFFFFFFFFFC000
OR  data3b2,data3b2,temp_data  
SUB expect3,data3a,data3b2

J   to_sub64_imm

bits_10: # Bits [15:14] 10 Zero extend and duplicate (makes no sense for len=1 32 bit 
LI  temp_data,0X1FFF
AND data1b,data1b,temp_data
LI  temp_data,0x8000
OR  data1b,data1b,temp_data    #   bit15_13=100
AND data1b2,data1b,mask 
SLLI temp_data,data1b2,32
OR  data1b2,data1b2,temp_data
SUB expect1,data1a,data1b2

LI  temp_data,0X3FFF
AND data3b,data3b,temp_data
LI  temp_data,0xa000
OR  data3b,data3b,temp_data    #   bit15_13=101 
AND data3b2,data3b,mask 
SLLI temp_data,data3b2,32
OR  data3b2,data3b2,temp_data   
SUB expect3,data3a,data3b2

J   to_sub64_imm 

bits_11: # Bits [15:14] 11 sign extend and duplicate (makes no sense for len=1 32 bit 
LI  temp_data,0X1FFF
AND data1b,data1b,temp_data 
LI  temp_data,0xC000
OR  data1b,data1b,temp_data    #   bit15_13=110
AND data1b2,data1b,mask 
SLLI temp_data,data1b2,32
OR  data1b2,data1b2,temp_data
SUB expect1,data1a,data1b2

LI  temp_data,0X3FFF
AND data3b,data3b,temp_data
LI  temp_data,0xE000
OR  data3b,data3b,temp_data    #   bit15_13=111 
AND data3b2,data3b,mask 
LI  temp_data,0xFFFFC000
OR  data3b2,data3b2,temp_data
SLLI temp_data,data3b2,32
OR  data3b2,data3b2,temp_data   
SUB expect3,data3a,data3b2

J   to_sub64_imm 

to_sub64_imm:

# override flag, see EAS_rfpc Table 2.12
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x40,0x0,0x0); #override dref
#RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
#OVERRIDE(11),LENGTH(5),DATA_REF(16)
OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[15:0]
.insn s 43,0,address,cluster_scratch_sub64_imm(cppcmd_data_ref);# cls_clr_imm

ADDI address,group_num , 0x8 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x40,0x0,0x0); #override dref
#RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
#OVERRIDE(11),LENGTH(5),DATA_REF(16)
OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[15:0]
.insn s 43,0,address,cluster_scratch_sub64_imm(cppcmd_data_ref);# cls_clr_imm 


ADD address, group_num, zero # set to initial value
#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);    

LD  temp_data, 0x50(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x58(xfer)
BNE temp_data, expect3, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero,sub64_imm_loop   

NOP
NOP
NOP


####################################################
# test2    64bit test_sub64_imm
####################################################

sub64_test_sub_imm_loop:
LI data1a ,0x234ff478f123f456
LI data3a ,0x4444444411111111

#store the data to cpp memory 
SD data1a ,0x0(xfer)
SD data3a ,0x8(xfer)

LI data1b ,0xf434   
LI data3b ,0x0565  
#write data to sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

sub64_test_sub_imm_expect:
#calculate the expected values
LI   temp_data,0xFFFFFFFF
ANDI data1b ,data1b,0x1F
SUB expect1,data1a,data1b 

ANDI data3b ,data3b,0x1F
SUB expect3,data3a,data3b

#test_sub64_imm
# override flag, see EAS_rfpc Table 2.12
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); #override dref
#RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
#OVERRIDE(11),LENGTH(5),DATA_REF(16)
SLLI data1b,data1b,16
OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[20:16]
.insn s 43,0,address,cluster_scratch_test_sub64_imm(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address,group_num , 0x8
SLLI data3b,data3b,16
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18); #override dref
OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[15:0]
.insn s 43,0,address,cluster_scratch_test_sub64_imm(cppcmd_data_ref); 
WAIT_ON_SIGNAL (SIG1_pos,1); 


#compare pushdata
LD  temp_data, 0x20(xfer)
BNE temp_data, data1a, test_failed 
LD  temp_data, 0x28(xfer)
BNE temp_data, data3a, test_failed

ADD address, group_num, zero # set to initial value

#read the operation data in sram addr to compare with expected data
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

ADD address, group_num, zero # set to initial value            
WAIT_ON_SIGNAL (SIG1_pos,1);                    

LD  temp_data, 0x50(xfer)
BNE temp_data, expect1, test_failed
LD  temp_data, 0x58(xfer)
BNE temp_data, expect3, test_failed

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
