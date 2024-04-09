#-----------------------
# TEST_NAME: me_lm_push_pull.uc
#     Reads and writes unique values to entire CTM memory 
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
#define lm_address      s4
#define xfer            s5
#define local_mem_addr  s6

#define island_id       a3
#define cl_num          a4
#define group_num       a5

#define temp_data       t1
#define temp_data_1     t2

Init_code:
    LI island_id, 0x7F0000
    AND island_id, island_id, a0
    SRLI island_id, island_id, 0x10    # island id 
    
    LI group_num, 0xF00           
    AND group_num , group_num, a0 	
    SRLI group_num , group_num , 0x8   # group number currently 4,7,8,11,12,15 group numbers used
    ANDI cl_num ,a0, 0xf               # core number
    SLLI local_mem_addr, cl_num , 8
    SLLI temp_data, group_num, 11
    OR local_mem_addr, local_mem_addr, temp_data # lm_addr = {group_num[3:1],cl_num[3:0],8b0}
    
Write_data_to_ctm:
    ADDI temp_data, local_mem_addr, 0
    LI xfer, 0xF0000000
    ADDI xfer, xfer, 0
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI temp_data, temp_data ,1 
    ADDI xfer, xfer, 4
    SW  temp_data, 0x0(xfer)

    ADDI cpp_addr, local_mem_addr, 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)
    .insn s 43,0,cpp_addr,memory_write(cppcmd_data_ref)
    WAIT_ON_SIGNAL (SIG1_pos,1)

Write_data_to_LM:
    ADDI cpp_addr, local_mem_addr, 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x200)
    .insn s 43,0,cpp_addr,memory_read(cppcmd_data_ref)
    WAIT_ON_SIGNAL (SIG3_pos,1)
    
    LI cpp_addr, 0xF0000000
    LI lm_address, 0x80000
    ADD lm_address, lm_address, local_mem_addr
    LWU temp_data, 0x200(cpp_addr)                # Load a word data from Cpp memory 0x200
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)                 # Store the word data to Local memory region 2

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)               

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     

    ADDI cpp_addr, cpp_addr, 0x4
    ADDI lm_address, lm_address, 0x4
    LWU temp_data, 0x200(cpp_addr)                
    LI temp_data_1, 0xACE00000
    OR temp_data, temp_data, temp_data_1
    SW temp_data, 0x0(lm_address)     



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
