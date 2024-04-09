#-----------------------
# TEST_NAME: 
#     Reads and writes XPB registers within me_groups ECC_monitor
#    
# 
#-----------------------

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


#define island_id       a3
#define cl_num          a4
#define group_num       a5
#define	packet_number   a6
#define ecc_monitor_base a7

#define temp_data_1     t1
#define temp_data_2     t2
#define temp_data_3     t4
#define temp_data_4     t6


.macro macro_inject_instructions 

.endm

.equ IMB_XPB_DEVICE_ID, 0xA
.equ ME_DEVICE_ID, 0x25

.equ ECC_ENABLE                ,  0x0
.equ ECC_INJECT_CLEAR          ,  0x4
.equ INJECT_ECC_PERMANENT      ,  0x8
.equ INJECT_DATA_PERMANENT     ,  0xC
.equ INJECT_ECC_ONE_SHOT       ,  0x10
.equ INJECT_DATA_ONE_SHOT      ,  0x14
.equ ECC_SRAM_CONTROL_10       ,  0x18
.equ ECC_SRAM_CONTROL_32       ,  0x1c
.equ ECC_FIRST_ERROR           ,  0x20
.equ ECC_LAST_ERROR            ,  0x24
.equ ECC_ERROR_COUNT           ,  0x28
.equ ECC_ERROR_COUNT_RESET     ,  0x2C
.equ ECC_CLEAR_ERROR           ,  0x38
.equ ECC_GPR                   ,  0x3c

.equ CPP_MEM_ADDR, 0xF0000000

Init_code:
    SRLI island_id, a0 , 16
    ANDI island_id, island_id, 0x7f

    LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
    AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
    	
    SRLI group_num , group_num , 0x5   # group number move to  4  - F gggg # group number move to  00 0ggg 0000
    ANDI cl_num ,a0, 0xf               # core number
    OR  group_num , group_num , cl_num # set group number as ggg_cccc 

    LI temp_data_1 , 0xF
    BGE group_num , temp_data_1, test_passed

    LI ecc_monitor_base, 0                   #rs2[8;56] mode_address = 0
    SLLI ecc_monitor_base,  ecc_monitor_base, 56        

    LI temp_data_1, 0                #rs2[1;31] means do XPB global access
    SLLI temp_data_1, temp_data_1, 31
    OR ecc_monitor_base, ecc_monitor_base, temp_data_1

    ADDI temp_data_1, island_id, 0   #rs2[8;24]  island number
    SLLI temp_data_1, temp_data_1, 24
    OR ecc_monitor_base, ecc_monitor_base, temp_data_1

    LI temp_data_1, ME_DEVICE_ID     #rs2[8;16] XPB Device ID 
    SLLI temp_data_1, temp_data_1, 16
    OR ecc_monitor_base, ecc_monitor_base, temp_data_1
    LI temp_data_1 , 0x7
    BGE group_num , temp_data_1, Injection_ecc_err_code


#-----------------------------------------
# ECC errors monitor code runs on  MG0 only
#-----------------------------------------
Ecc_err_monitor_code:
    ###LI temp_data_1, ECC_ERROR_COUNT #rs2[14;2] register address
    ###OR  cpp_addr, ecc_monitor_base, temp_data_1


    ###LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    ###.insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Write for target 15 CLS
    ###WAIT_ON_SIGNAL (SIG1_pos,1)
    
    J test_passed
#-----------------------------------------
# Injection code runs on  MG1 only
#-----------------------------------------
Injection_ecc_err_code:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x55
    SD xfer, 0x0(address)
   
    LI temp_data_1, ECC_GPR              
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Write the GPR register =0x55
    WAIT_ON_SIGNAL (SIG1_pos,1)

Inject_eccerr_datafile_one_shot:   
    LI address, CPP_MEM_ADDR
    LI xfer, 0x8006          #Need to confirm the ecc delta data 
    SD xfer, 0x8(address)
  
    LI temp_data_1, INJECT_DATA_ONE_SHOT           
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x8) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure one shot data file error 
    WAIT_ON_SIGNAL (SIG2_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0xC) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read the ECC_Delta
    WAIT_ON_SIGNAL (SIG3_pos,1)
    J Config_ecc_enable

Inject_eccerr_datafile_permanent:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x75
    SD xfer, 0x10(address)

    LI temp_data_1, INJECT_DATA_PERMANENT          
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x10) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure Inject Permanent ECC DATA
    WAIT_ON_SIGNAL (SIG4_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x14) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_PERM_DATA
    WAIT_ON_SIGNAL (SIG5_pos,1)

Inject_ecc_clear:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x62
    SD xfer, 0x20(address)

    LI temp_data_1, ECC_INJECT_CLEAR            
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure Inject ECC clear
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x24) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_CLEAR
    WAIT_ON_SIGNAL (SIG2_pos,1)

Inject_eccerr_eccfile_one_shot:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x1
    SD xfer, 0x30(address)

    LI temp_data_1, INJECT_ECC_ONE_SHOT             
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure Inject one shot ecc
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x34) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_ONE_SHOT_ECC
    WAIT_ON_SIGNAL (SIG2_pos,1)

Inject_eccerr_eccfile_permanment:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x2
    SD xfer, 0x40(address)

    LI temp_data_1, INJECT_ECC_PERMANENT             
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure Inject one shot ecc
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x44) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_ONE_SHOT_ECC
    WAIT_ON_SIGNAL (SIG2_pos,1)

Config_ecc_enable:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x1
    SD xfer, 0x50(address)

    LI temp_data_1, ECC_ENABLE                
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure ECC enable
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x54) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_ENABLE
    WAIT_ON_SIGNAL (SIG2_pos,1)


    LI ecc_monitor_base, 0                   #rs2[8;56] mode_address = 0
    SLLI ecc_monitor_base,  ecc_monitor_base, 56        

    LI temp_data_1, 0                #rs2[1;31] means do XPB access (not using in misc?)
    SLLI temp_data_1, temp_data_1, 31
    OR ecc_monitor_base, ecc_monitor_base, temp_data_1

    ADDI temp_data_1, island_id, 0   #rs2[8;24]  island number
    SLLI temp_data_1, temp_data_1, 24
    OR ecc_monitor_base, ecc_monitor_base, temp_data_1

    LI temp_data_1, 0x28             #rs2[8;16] XPB Device ID 
    SLLI temp_data_1, temp_data_1, 16
    OR ecc_monitor_base, ecc_monitor_base, temp_data_1

    LI address, CPP_MEM_ADDR
    LI xfer, 0x0002
    SD xfer, 0x0(address)

    LI temp_data_1, 0 # Region MAP 0 offset             
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0x4002
    SD xfer, 0x0(address)

    LI temp_data_1, 4 # Region MAP 1 offset             
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0x8002
    SD xfer, 0x0(address)

    LI temp_data_1, 8 # Region MAP 2 offset             
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0xC002
    SD xfer, 0x0(address)

    LI temp_data_1, 0xC # Region MAP 3 offset             
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)



    LI address, 0x0
    LD xfer, 0x50(address)

    LI address, 0x40000
    LD xfer, 0x50(address)

    LI address, 0x80000
    LD xfer, 0x50(address)

    LI address, 0xC0000
    LD xfer, 0x50(address)
    
    LI xfer, 0xFF00EE00CC00BB00
    LI address, 0x80000
    SD xfer, 0x0(address)

    LI address, 0x80000
    LD xfer, 0x0(address)
  

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
