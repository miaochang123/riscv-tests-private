#ifndef _ENV_PHYSICAL_MULTI_CORE_H

#define _ENV_PHYSICAL_MULTI_CORE_H
#include "riscv_test.h"
#include "test_macros.h"
#undef RISCV_MULTICORE_DISABLE
#define RISCV_MULTICORE_DISABLE
#endif
#include "cpp_command_macros.h"
#include "rfpc_cmd_defines.h"
#include "rfpc_addr_defines.h"
RVTEST_RV64U
RVTEST_CODE_BEGIN


#define cpp_addr        s1
#define	cpp_rs1         s2 
#define cppcmd_data_ref s3
#define address         s4
#define xfer            s5
#define loop_cnt        s6


#define cl_num          a4
#define group_num       a5
#define	packet_number   a6

#define temp_data_1     t1
#define temp_data_2     t2
#define temp_data_3     t4
#define temp_data_4     t6

.equ CPP_MEM_ADDR, 0xF0000000
.equ IMB_XPB_DEVICE_ID, 0xA
.equ CLS_TARGET_15_OFFSET, 0x3C
.equ IMB_PA_SELECT_0, 0x6C

Init_code:
    LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
    AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
    	
    SRLI group_num , group_num , 0x5   # group number move to  4  - F gggg # group number move to  00 0ggg 0000
    ANDI cl_num ,a0, 0xf               # core number
    OR  group_num , group_num , cl_num # set group number as ggg_cccc 

    LI temp_data_1 , 0x7
    BGE group_num , temp_data_1, test_passed
    
    LI temp_data_1 , 0x1
    BGE group_num , temp_data_1, run_test 

xpb_imb_write:                      # Only run in core 0
    LI address,CPP_MEM_ADDR
    LI xfer, 0x0
    SD xfer, 0x0(address)            ##configure target_Address_Mode_Config = 0

    LI cpp_addr, 0                   #rs2[8;56] mode_address = 0
    SLLI cpp_addr,  cpp_addr, 56        

    LI temp_data_1, 0                #rs2[1;31] means do XPB global access
    SLLI temp_data_1, temp_data_1, 31
    OR cpp_addr, cpp_addr, temp_data_1

    LI temp_data_1, 0                #rs2[8;24]  island number
    SLLI temp_data_1, temp_data_1, 24
    OR cpp_addr, cpp_addr, temp_data_1

    LI temp_data_1,IMB_XPB_DEVICE_ID #rs2[8;16] XPB Device ID 
    SLLI temp_data_1, temp_data_1, 16
    OR cpp_addr, cpp_addr, temp_data_1

    LI temp_data_1, CLS_TARGET_15_OFFSET #rs2[14;2] register address
    OR cpp_addr, cpp_addr, temp_data_1


    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# Write for target 15 CLS
    WAIT_ON_SIGNAL (SIG1_pos,1)
 

    LI address,CPP_MEM_ADDR
    LI xfer, 0x430C30
    SW xfer, 0x0(address)            ##configure IMB Performance analyze 
   
    LI temp_data_1, 0xFFFFFFFFFFFF0000
    AND cpp_addr, cpp_addr, temp_data_1

    LI temp_data_1, IMB_PA_SELECT_0 #rs2[14;2] register address
    OR cpp_addr, cpp_addr, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# Write for IMB Performance analyzer selects
    WAIT_ON_SIGNAL (SIG3_pos,1)
   
run_test:
    LI loop_cnt, 50
loop:
    LI address, CPP_MEM_ADDR
    ADDI temp_data_1, loop_cnt, 0 
    ADDI temp_data_2, loop_cnt, 1 
    SLLI temp_data_2, temp_data_2, 32
    OR xfer, temp_data_2, temp_data_1
    SD xfer, 0x0(address)           
   
    LI cpp_addr, 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x0) 
    .insn s 43,0,cpp_addr,cluster_scratch_write(cppcmd_data_ref)	 ;# Write for IMB Performance analyzer selects
    WAIT_ON_SIGNAL (SIG3_pos,1)
    NOP
    NOP
    NOP
    ADDI loop_cnt, loop_cnt , -2
    BNE loop_cnt, zero, loop

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
