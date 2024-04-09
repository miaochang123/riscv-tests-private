#-----------------------
#  TEST_NAME: me_lmecc_events
#     1) Each ME uses ECC monitor to inject single bit error into its own LM memory
#     2) Configure one CLS Ecc filter to monitor # of single bit ecc error events for that cluster
#     3) Each cluster generates 5 ECC errors
#     4) Read ECC monitor single bit ecc error count (check for 5 errors)
#     5) Read CLS ECC filter count (check for 5 events)
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
#define	filter_base     a6
#define ecc_monitor_base a7
#define LM_conf_base    s11

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

.equ FILTER_STATUS             ,  0x0
.equ FILTER_FLAGS              ,  0x8
.equ FILTER_MASK               ,  0x10
.equ FILTER_MATCH              ,  0x18
.equ FILTER_ACK                ,  0x20

.equ CPP_MEM_ADDR, 0xF0000000

Init_code:
    SRLI island_id, a0 , 16
    ANDI island_id, island_id, 0x7f

    LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
    AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
    	
    SRLI group_num , group_num , 0x8   # group number move to  4  - F gggg # group number move to  00 0ggg
    LI temp_data_1 , 0x0
    BNE group_num , temp_data_1, test_passed

    ANDI cl_num ,a0, 0xf               # core number
    LI temp_data_1 , 0x0
    BNE cl_num , temp_data_1, test_passed

    LI ecc_monitor_base, 0           #rs2[8;56] mode_address = 0
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

    LI filter_base, 0                   #rs2[8;56] mode_address = 0
    SLLI filter_base, filter_base, 56  
    LI temp_data_1, 0x20000
    OR filter_base, filter_base, temp_data_1
    SLLI temp_data_1, group_num, 0x6
    OR  filter_base, filter_base, temp_data_1

Lmem_write:     
    LI LM_conf_base, 0           #rs2[8;56] mode_address = 0
    SLLI LM_conf_base,  LM_conf_base, 56        
    SLLI temp_data_1, group_num, 0x6
    OR  LM_conf_base, LM_conf_base, temp_data_1

    LI temp_data_1, 0                
    SLLI temp_data_1, temp_data_1, 31
    OR LM_conf_base, LM_conf_base, temp_data_1

    ADDI temp_data_1, island_id, 0   #rs2[8;24]  island number
    SLLI temp_data_1, temp_data_1, 24
    OR LM_conf_base, LM_conf_base, temp_data_1

    LI temp_data_1, 0x28             #rs2[8;16] XPB Device ID 
    SLLI temp_data_1, temp_data_1, 16
    OR LM_conf_base, LM_conf_base, temp_data_1

    LI address, CPP_MEM_ADDR
    LI xfer, 0x0002
    SD xfer, 0x0(address)

    LI temp_data_1, 0 # Region MAP 0 offset             
    OR  cpp_addr, LM_conf_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0x4002
    SD xfer, 0x0(address)

    LI temp_data_1, 4 # Region MAP 1 offset             
    OR  cpp_addr, LM_conf_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0x8002
    SD xfer, 0x0(address)

    LI temp_data_1, 8 # Region MAP 2 offset             
    OR  cpp_addr, LM_conf_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0xC002
    SD xfer, 0x0(address)

    LI temp_data_1, 0xC # Region MAP 3 offset             
    OR  cpp_addr, LM_conf_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG1_pos,1)
    
    LI xfer, 0x11
    LI address, 0x80000
    SLLI temp_data_1, group_num, 8
    OR address, address, temp_data_1
    SW xfer, 0x0(address)

    ADDI address, address, 0x10
    LI xfer, 0x22
    SW xfer, 0x0(address)

    ADDI address, address, 0x10
    LI xfer, 0x33
    SW xfer, 0x0(address)

    ADDI address, address, 0x10
    LI xfer, 0x44
    SW xfer, 0x0(address)

    ADDI address, address, 0x10
    LI xfer, 0x55
    SW xfer, 0x0(address)

    ADDI address, address, 0x10
    LI xfer, 0x66
    SW xfer, 0x0(address)

    ADDI address, address, 0x10
    LI xfer, 0x77
    SW xfer, 0x0(address)

#---------------------
# Filter Type = 0
# data_source[11:0] = quadword_address[14:12] + quadword_address[8:0]
####     if ecc_event_config__use_id == 1
####        data_source[11:8] = ecc_event_config__id
####        data_source[7:5]  = ecc_event_lm  quadword_address[15:12]
####        data_source[4:0]  = quadword_address[4:0]
#### data_Event[3:0] ; Correctable error = 0xA
####---------------------

Configure_event_filter:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x30F0F
    SD xfer, 0x0(address)

    LI temp_data_1, FILTER_MASK 
    OR cpp_addr, filter_base, temp_data_1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,cluster_scratch_write(cppcmd_data_ref)	 #Configure FILTER_MASK
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,cluster_scratch_read_le(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG2_pos,1)

    LI address, CPP_MEM_ADDR
    LI xfer, 0x3                      
    SLLI xfer, xfer, 16               # ME sub id
    SLLI temp_data_1, group_num, 8    # match_data[12:8]  == quadword_address[8:4]
    OR  xfer, xfer, temp_data_1        
    ADDI xfer, xfer, 0xA              # match_data[3:0]  ==  Correctable error = 0xA
    SD xfer, 0x0(address)

    LI temp_data_1, FILTER_MATCH
    OR cpp_addr, filter_base, temp_data_1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,cluster_scratch_write(cppcmd_data_ref)	 #Configure FILTER_MATCH
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,cluster_scratch_read_le(cppcmd_data_ref)	 
    WAIT_ON_SIGNAL (SIG2_pos,1)
   

#-----------------------------------------
# ECC errors monitor code runs on  MG0 only
#-----------------------------------------
Ecc_err_monitor_code:
    LI temp_data_1, ECC_ERROR_COUNT #rs2[14;2] register address
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Write for target 15 CLS
    WAIT_ON_SIGNAL (SIG1_pos,1)

#-----------------------------------------
# Injection code: Each core generate 5 ecc error
#-----------------------------------------
Injection_ecc_err_code:
    NOP

Config_ecc_enable:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x1
    SD xfer, 0x0(address)

    LI temp_data_1, ECC_ENABLE                
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure ECC enable
    WAIT_ON_SIGNAL (SIG1_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x4) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_ENABLE
    WAIT_ON_SIGNAL (SIG2_pos,1)

Inject_eccerr_datafile_permanent:
    LI address, CPP_MEM_ADDR
    LI xfer, 0x8018                   # ECC_Delta = Bit 4 
    SD xfer, 0x10(address)

    LI temp_data_1, INJECT_DATA_PERMANENT          
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x10) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure Inject Permanent ECC DATA
    WAIT_ON_SIGNAL (SIG4_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x14) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_PERM_DATA
    WAIT_ON_SIGNAL (SIG5_pos,1)

Lmem_load_gene_ecc_srcub_writeback_operation:    
  
    LI address, 0x80000
    SLLI temp_data_1, group_num, 8
    OR address, address, temp_data_1

    LW temp_data_1, 0x0(address)
    ADDI xfer, temp_data_1, 0x0  

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    LI address, 0x80000
    SLLI temp_data_1, group_num, 8
    OR address, address, temp_data_1

    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    LI temp_data_1 ,0x1FE
    BNE xfer, temp_data_1, test_failed

Configure_ecc_inject_clear:
    LI address, CPP_MEM_ADDR
    LI temp_data_1, 0x0                  
    SD temp_data_1, 0x20(address)

    LI temp_data_1, ECC_INJECT_CLEAR         
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x20) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 # Configure ECC_INJECT_CLEAR
    WAIT_ON_SIGNAL (SIG4_pos,1)

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x24) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_INJECT_CLEAR
    WAIT_ON_SIGNAL (SIG5_pos,1)  

    LI address, 0x80000
    SLLI temp_data_1, group_num, 8
    OR address, address, temp_data_1
    ADDI address, address, 0x50

    LW temp_data_1, 0x0(address)
    ADDI xfer, temp_data_1, 0x0  

    ADDI address, address, 0x10
    LW temp_data_1, 0x0(address)
    ADD xfer, xfer, temp_data_1

    LI temp_data_1 ,0xDD
    BNE xfer, temp_data_1, test_failed


Read_ecc_monitor_error_count:
    LI temp_data_1, ECC_ERROR_COUNT         
    OR  cpp_addr, ecc_monitor_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x30) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 # Read ECC_ERROR_COUNT
    WAIT_ON_SIGNAL (SIG5_pos,1)  

    LI address, CPP_MEM_ADDR
    LW xfer, 0x30(address)
    LI temp_data_1 ,0x5
    BNE xfer, temp_data_1, test_failed

Read_filter_status:
    LI temp_data_1, FILTER_ACK        
    OR  cpp_addr, filter_base, temp_data_1

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x40) 
    .insn s 43,0,cpp_addr,cluster_scratch_read_le(cppcmd_data_ref)	 # Read FILTER_ACK
    WAIT_ON_SIGNAL (SIG5_pos,1)      
 
     
    LI address, CPP_MEM_ADDR
    LW xfer, 0x40(address)
    LI temp_data_1 ,0x5
    NOP
    BNE xfer, temp_data_1, test_failed
    J test_passed
    NOP

test_passed:
pass:
test_done:
    J test_passed
    NOP
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
