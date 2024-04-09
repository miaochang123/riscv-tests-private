
#ifndef _ENV_PHYSICAL_MULTI_CORE_H	
#define _ENV_PHYSICAL_MULTI_CORE_H
#include "riscv_test.h"
#include "test_macros.h"
#undef RISCV_MULTICORE_DISABLE
#define RISCV_MULTICORE_DISABLE

#endif

	
#include "cpp_command_macros.h"
#include "rfpc_cmd_defines.h"
# CPP IMM Clr CPPX overrides (11), Action (10:6), Token (5:4), Target (3:0)


.equ CPP_MEM, 0xf0000000
#define cppcmd_data_ref x16
#define tgt_addr   	x15
	
RVTEST_RV64U
RVTEST_CODE_BEGIN
	
#SZ NOTES to self x0 = 0
#                 x1 = ra
#                 x2 = sp
#                 x3 = gp
#                 x4 = tp
#                 x5-7 = t0-t2
#                 x8 = s0
#                 x9 = s1
#                 x10-17 = a0 -a7 ,  a0 has the hart value
#                 x18-27 = s2-11
#                 x28-31 = t3-6

# hart value = {island_id << 16, group_number << 8 , core_number
# group 0 = core_num 0 - 7
# group 1 = core_num 8 - 15
# group 2 = core_num 16 - 23
# group 3 = core_num 24 - 31
# group 4 = core_num 0 - 7
# group 5 = core_num 8 - 15
# group 6 = core_num 16 - 23
# group 7 = core_num 24 - 31

sz_start_of_test:
LI t1, 0xf00 # group number
AND t1 ,t1, a0 # group number
SRLI t1 ,t1, 0x4 # group number move to bit 5
ANDI t2 ,a0, 0x07 # core number
AND t2 ,t2, t1 # Base Addr for each core range 0 - 127
SLLI t2 ,t2, 0x8 #each core has 256 byte of address space
ADD  tgt_addr, t2, x0
LI t1 , CPP_MEM # set offset to CPP MEM
	
#Each Core will load the CPP_MEMORY will pattern
	
LI x1 , 0x33221100
OR x1,x1,t2
SW x1, 0x0(t1)
LI x1 , 0x66554400
OR x1,x1,t2
SW x1, 0x4(t1)
LI x1 , 0x99887700
OR x1,x1,t2
SW x1, 0x8(t1)
LI x1 , 0xccbbaa00
OR x1,x1,t2
SW x1, 0xc(t1)
LI x1 , 0xffeedd00
OR x1,x1,t2
SW x1, 0x10(t1)
	
LI x1 , 0xffeedd00
OR x1,x1,t2
SW t1, 0x14(t1)
SW t1, 0x18(t1)
SW t1, 0x1c(t1)
SW t1, 0x20(t1)

# read back and check
	
SW t2, 0x24(t1) # t2 core number
SW t2, 0x28(t1)
SW t2, 0x2c(t1)
SW t2, 0x30(t1)
	
LI x1 , 0x33221100	
OR x1,x1,t2
	
LW x2, 0x0(t1)
LW x3, 0x4(t1)
BNE x2,x1,test_failed #1b0
LI x1 , 0x66554400	
OR x1,x1,t2
#LW x2, 0x4(t1)
BNE x3,x1,test_failed #1c0
LI x1 , 0x99887700	
OR x1,x1,t2
LWU x2, 0x8(t1)
LWU x3, 0xc(t1)
BNE x2,x1,test_failed #1e0
LI x1 , 0xccbbaa00	
OR x1,x1,t2
#LW x2, 0xc(t1)
BNE x3,x1,test_failed
LI x1 , 0xffeedd00	
OR x1,x1,t2
LWU x2, 0x10(t1)
BNE x2,x1,test_failed


CPP_EXE_WRITE:
#              nu               nu                       nu                         5               nu             nu                                         8         0
#T1 is RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),OVERRIDE(11, whrn zero lower value needed),LENGTH(5),DATA_REF(16)} # SZ FIXME move overrides to end of RS1, move signal ref to just after length
#T2 is RS2 {Mode_addr[7:0], target_addr (55:0) only 48 bits of addr is used
	
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x4,0x0)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 5, BM = 0,OVr = 0,  Length = 8, DRef = 0  * 4 bytes, sign =5, data_ref = 0
.insn s 43,0,tgt_addr,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
	
	
# read data back

li t3, 0x40  	  ;
add cppcmd_data_ref,cppcmd_data_ref , t3  			 ; # set read back data + 40, write data at 0

.insn s 43,0,tgt_addr,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG5_pos,2) 	;
	
nop
nop
nop
nop

li t1 , 0xf0000000 # set offset to CPP MEM

lw x1 ,0x0(t1) # data write to local scratch
lw x2,0x40(t1) # data read from local scratch
BNE x2,x1, test_failed
lw x1 ,0x4(t1) # data write to local scratch
lw x2,0x44(t1) # data read from local scratch
BNE x2,x1, test_failed
lw x1 ,0x8(t1) # data write to local scratch
lw x2,0x48(t1) # data read from local scratch
BNE x2,x1, test_failed
lw x1 ,0xc(t1) # data write to local scratch
lw x2,0x4c(t1) # data read from local scratch
BNE x2,x1, test_failed
lw x1 ,0x10(t1) # data write to local scratch
lw x2,0x50(t1) # data read from local scratch
BNE x2,x1, test_failed
	
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
