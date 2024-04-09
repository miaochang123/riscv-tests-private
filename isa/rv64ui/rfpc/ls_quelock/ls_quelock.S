#--------------------------------
# TEST_NAME: rfpc_ls_quelock.S
# cmd: quelock         8/0 
#      queunlock       8/1      globl
# describe: 1.core0 init queue and claim queuelock
#           2.core1-core5 claim queuelock
#           3.core6  claim queuelock,but the signal is full,so the dut will result in a rejection using the
#                                             given signal and a push of a result of either non-zero
#           4.core0-5 proceed in sequence to queue_unlock  
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
	
#define cppcmd_data_ref x2
#define expect          x3
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
#define  data2b        x16
#define  data3b        x17
#define  data4b        x18

#define  expect_low       x19
#define  expect_high       x20
#define  expect4       x22

#define  remainder     x23
#define  temp_data     x24
#define  temp_data1    x25
#define  my_signalref  x26
#define  my_datamaster x27

.globl pass_count
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


LI temp_data_1 , 0x7
BGE cl_num, temp_data_1, test_passed #  each group  use core 0-6
#OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127

SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	
ADD address, group_num, zero

LI   my_datamaster,0xf00
AND  my_datamaster,my_datamaster,a0
SRLI my_datamaster,my_datamaster,8   

LI  temp_data , 0x0
BEQ my_datamaster, temp_data,master_4 
LI  temp_data , 0x2 
BEQ my_datamaster, temp_data,master_7
LI  temp_data , 0x4 
BEQ my_datamaster, temp_data,master_8
LI  temp_data , 0x6 
BEQ my_datamaster, temp_data,master_11
LI  temp_data , 0x8 
BEQ my_datamaster, temp_data,master_12
LI  temp_data , 0xa 
BEQ my_datamaster, temp_data,master_15

J test_failed

master_4:
LI  my_datamaster,0x4
J start_test

master_7:
LI  my_datamaster,0x7 
J start_test  

master_8:
LI  my_datamaster,0x8 
J start_test  

master_11:
LI  my_datamaster,0xb
J start_test   

master_12:
LI  my_datamaster,0xc
J start_test   

master_15:
LI  my_datamaster,0xf 

start_test:
LI xfer, CPP_MEM_ADDR 


#store the data to cpp memory 
SD  data1a,0x0(xfer)

LI temp_data , 0x0
BEQ cl_num, temp_data,core_0 
LI temp_data , 0x1
BEQ cl_num, temp_data,core_1
LI temp_data , 0x2
BEQ cl_num, temp_data,core_2
LI temp_data , 0x3
BEQ cl_num, temp_data,core_3
LI temp_data , 0x4
BEQ cl_num, temp_data,core_4
LI temp_data , 0x5
BEQ cl_num, temp_data,core_5
LI temp_data , 0x6
BEQ cl_num, temp_data,core_6


##first to lock
core_0:

LI data1a,0x0 
SD data1a,0x0(xfer) 

#write data to sram      init data 0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);  


LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

LD temp_data,0x10(xfer)
BNE temp_data,data1a, test_failed 


#quelock
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1); 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

LI  expect_low ,0
LI  expect_high,0x80000000   
SLLI expect,expect_high,32
OR  expect,expect,expect_low

LD  temp_data,0x20(xfer)
BNE temp_data,expect, test_failed 


#reflect_write_remote   addr
#kestrel
# addr[31]            addr[30:24]            addr[23:16]   addr[15:12]    addr[11:0]
#  use_sr    other_sr(4bitcorenum,3bitsr)       8'b0         other_dm      other_dr

#merlin
# addr[31]            addr[30:24]            addr[23:19]   addr[18:14]    addr[13:0]
#  use_sr    other_sr(4bitcorenum,3bitsr)       5'b0         other_dm      other_dr

SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,1
LI   my_signalref,0
SLLI my_signalref,temp_data,3
LI   temp_data,0x1
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref
#reflect core_1,tell it can op                             
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);  #reflect core1
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value

###### queue_unlock
WAIT_ON_SIGNAL (SIG5_pos,6);  # wait other core1-6 complete quelock

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_unlock(cppcmd_data_ref);#unlock signal0 

.set pass_count,1

J test_passed

#####################core1**********
core_1:
WAIT_ON_SIGNAL (SIG1_pos,1);  #wait init core_0 sram_data
####queue lock
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#
ADD address, group_num, zero # set to initial value  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

expect_data1:

LI  expect_low ,0xa  # no consider master
LI  expect_high,0x90000000

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high

LD  temp_data,0x30(xfer)
BNE temp_data,expect, test_failed 

#LI address,0x85004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,-1
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x5
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref   
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core0 to tell complete quelock
 
#LI address,0x91004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,1
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x1
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core2 to start send quelock

#####wait core0 to queue_unlock(signal 0)
ADD address, group_num, zero
WAIT_ON_SIGNAL (SIG2_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG2_pos,1);

LI  expect_low ,0x2701c013  # no consider master
LI  expect_high,0xc00002e0

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data
LI  temp_data,0
ANDI temp_data,my_datamaster,0x1
SLLI temp_data,temp_data,31
OR  expect_low,expect_low,temp_data
SRLI temp_data,my_datamaster,1
OR  expect_high,expect_high,temp_data
SLLI temp_data,my_datamaster,11
OR  expect_high,expect_high,temp_data       
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high

LD  temp_data,0x10(xfer)
BNE temp_data,expect, test_failed   

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_unlock(cppcmd_data_ref);#unlock signal1 

.set pass_count,2

J test_passed  

#####################core2**********
core_2:
WAIT_ON_SIGNAL (SIG1_pos,1);  #wait core_1 complete quelock 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#
ADD address, group_num, zero # set to initial value  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

expect_data2:

LI  expect_low ,0x1300a  # no consider master
LI  expect_high,0xa0000000

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
LI  temp_data,0
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data   
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high   

LD  temp_data,0x10(xfer)
BNE temp_data,expect, test_failed  

#LI address,0x85004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,-2
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x5
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core0 to tell complete quelock 


#LI address,0x99004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,1
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x1
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core3 to start send quelock


ADD address, group_num, zero

#####wait core1 to queue_unlock (signal1)
WAIT_ON_SIGNAL (SIG3_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG3_pos,1);


LI  expect_low ,0x2e02701c  # no consider master
LI  expect_high,0xb0000000

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data
LI  temp_data,0
ANDI temp_data,my_datamaster,0x1
SLLI temp_data,temp_data,31
OR  expect_low,expect_low,temp_data
SRLI temp_data,my_datamaster,1
OR  expect_high,expect_high,temp_data      
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high

LD  temp_data,0x20(xfer)
BNE temp_data,expect, test_failed 
 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_unlock(cppcmd_data_ref);#unlock signal2 

.set pass_count,3

J test_passed   

#####################core3**********
core_3:
WAIT_ON_SIGNAL (SIG1_pos,1);   #wait core_2 complete quelock 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#
ADD address, group_num, zero # set to initial value  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);

expect_data3:

LI  expect_low ,0x1c01300a  # no consider master
LI  expect_high,0xb0000000

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
LI  temp_data,0
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data
LI  temp_data,0
ANDI temp_data,my_datamaster,0x1
SLLI temp_data,temp_data,31
OR  expect_low,expect_low,temp_data
SRLI temp_data,my_datamaster,1 
OR   expect_high,expect_high,temp_data
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high  

LD  temp_data,0x10(xfer)
BNE temp_data,expect, test_failed 


#LI address,0x85004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,-3
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x5
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core0 to tell complete quelock 

#LI address,0xa1004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,1
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x1
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core4 to start send quelock

ADD address, group_num, zero
#####wait core2 to queue_unlock (signal2) 
WAIT_ON_SIGNAL (SIG4_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG4_pos,1); 

LI  expect_low ,0x2e027  # no consider master
LI  expect_high,0xa0000000

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data    
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high

LD  temp_data,0x20(xfer)
BNE temp_data,expect, test_failed 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_unlock(cppcmd_data_ref);#unlock signal3 

J test_passed

#####################core4**********
core_4:
WAIT_ON_SIGNAL (SIG1_pos,1); #wait core_3 complete quelock  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG7,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#
ADD address, group_num, zero # set to initial value  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);


expect_data4:

LI  expect_low ,0x1c01300a  # no consider master
LI  expect_high,0xc0000270


LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
LI  temp_data,0
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data
LI  temp_data,0
ANDI temp_data,my_datamaster,0x1
SLLI temp_data,temp_data,31
OR  expect_low,expect_low,temp_data
SRLI temp_data,my_datamaster,1 
OR   expect_high,expect_high,temp_data
LI  temp_data,0
SLLI temp_data,my_datamaster,11
OR  expect_high,expect_high,temp_data 
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high  

LD  temp_data,0x10(xfer)
BNE temp_data,expect, test_failed 


#LI address,0x85004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,-4
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x5
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core0 to tell complete quelock 


#LI address,0xa9004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,1
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x1
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core5 to start send quelock


ADD address, group_num, zero
#####wait core3 to queue_unlock (signal3) 
WAIT_ON_SIGNAL (SIG7_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG7,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG7_pos,1); 

LI  expect_low ,0x2e  # no consider master
LI  expect_high,0x90000000

LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data   
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high

LD  temp_data,0x20(xfer)
BNE temp_data,expect, test_failed   

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG7,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_unlock(cppcmd_data_ref);#unlock signal4 

.set pass_count,4

J test_passed

#####################core5**********
core_5:
WAIT_ON_SIGNAL (SIG1_pos,1); #wait core_4 complete quelock  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#
ADD address, group_num, zero # set to initial value  

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG1_pos,1);


expect_data5:

LI  expect_low ,0x1c01300a  # no consider master
LI  expect_high,0xd02e0270


LI  temp_data,0
SLLI temp_data,my_datamaster,7
OR  expect_low,expect_low,temp_data
LI  temp_data,0
SLLI temp_data,my_datamaster,19
OR  expect_low,expect_low,temp_data
LI  temp_data,0
ANDI temp_data,my_datamaster,0x1
SLLI temp_data,temp_data,31
OR  expect_low,expect_low,temp_data
SRLI temp_data,my_datamaster,1 
OR   expect_high,expect_high,temp_data
LI  temp_data,0
SLLI temp_data,my_datamaster,11
OR  expect_high,expect_high,temp_data 
SLLI temp_data,my_datamaster,23
OR  expect_high,expect_high,temp_data  
SLLI expect_high,expect_high,32
OR  expect,expect_low,expect_high  

LD  temp_data,0x10(xfer)
BNE temp_data,expect, test_failed   


#LI address,0x85004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,-5
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x5
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core0 to tell complete quelock 


#LI address,0xb1004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,1
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x1
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core6 to start send quelock


ADD address, group_num, zero
#####wait core4 to queue_unlock (signal4) 
WAIT_ON_SIGNAL (SIG6_pos,1);

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x1,0x20);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG6_pos,1);

LI  expect_low ,0x0  # no consider master
LI  expect_high,0x80000000
SLLI expect_high,expect_high,32
OR  expect,expect_high,expect_low

LD  temp_data,0x20(xfer)
BNE temp_data,expect, test_failed   

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_queue_unlock(cppcmd_data_ref);#unlock queue to set the state is 0 

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG6,0x0,0x0,0x1,0x30);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);#

ADD address, group_num, zero # set to initial value
WAIT_ON_SIGNAL (SIG6_pos,1); 

LI  expect,0x0  

LD  temp_data,0x30(xfer)
BNE temp_data,expect, test_failed  

J test_passed
#####################core6********** 
core_6:
WAIT_ON_SIGNAL (SIG1_pos,1);  #wait core_5 complete quelock 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0);    //must signalref[0] = 0 ,then if error ,will have double_signal
.insn s 43,0,address,cluster_scratch_queue_lock(cppcmd_data_ref);#
ADD address, group_num, zero # set to initial value


#it will result in a rejection using the
# given signal and a push of a result of either non-zero, or optionally no data but signal and signal|1
# double_signal = push_data_fifo.data.no_split && !push_data_fifo.data.signal_ref[0]
WAIT_ON_SIGNAL (SIG2_pos,1); 
WAIT_ON_SIGNAL (SIG3_pos,1); 


#LI address,0x85004000
SLLI temp_data1,my_datamaster,14
LI   temp_data,0
ADDI temp_data,cl_num,-6
LI   my_signalref,0  
SLLI my_signalref,temp_data,3
LI   temp_data,0x5
OR   my_signalref,my_signalref,temp_data
SLLI my_signalref,my_signalref,24

LI address,0x80000000
OR address,address,temp_data1
OR address,address,my_signalref 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_reflect_write_sig_remote(cppcmd_data_ref);# reflect core0 to tell complete quelock 
ADD address, group_num, zero


J test_passed 


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
