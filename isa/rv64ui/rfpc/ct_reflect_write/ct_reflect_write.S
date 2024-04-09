#-----------------------
# TEST_NAME: ct_reflect_Write.S
#        Each ME (context 0) does 1 Cluster Target reflector write to every ME (including self)
#        Each ME must then use interthread signal to signal that data is there...
#        Each ME (context 1) than checks for correct data in transfer registers
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

#define island_id       a3
#define cl_num          a4
#define group_num       a5

#define temp_data       t1
#define temp_data_1     t2
#define loop_cnt        t4

Init:
    LI island_id, 0x7F0000
    AND island_id, island_id, a0
    SRLI island_id, island_id, 0x10    # island id 
    
    LI group_num, 0xF00           
    AND group_num , group_num, a0 	
    SRLI group_num , group_num , 0x8   # group number currently 4,7,8,11,12,15 group numbers used
    
    ANDI cl_num ,a0, 0xf               # core number
    LI loop_cnt, 0x4

    ANDI cl_num ,a0, 0xf               # core number
    
    
    ANDI temp_data , cl_num, 0x7
    BEQ temp_data, zero, Issue_reflect_write      # Each Core0 issue reflect write in every group
    
    J  receive_and_check     # Each Core1  check the result in every group

Issue_reflect_write:
    LI loop_cnt, 0x4

send_loop:
    ANDI temp_data, loop_cnt, 0x2      #Data Master 4,7,8,11,12,
    SRLI temp_data, temp_data, 0x1
    SLLI temp_data_1, temp_data, 0x1
    OR temp_data,temp_data, temp_data_1
    LI temp_data_1, 0xFFFC
    AND temp_data_1,loop_cnt, temp_data_1
    OR temp_data, temp_data, temp_data_1  # data Master 4,7,8,11,12,15

    LI xfer, 0                       
    OR xfer, xfer, group_num         # [4;4]  group_num     
    SLLI xfer, xfer, 4
    OR xfer, xfer, cl_num            # [4;0]  cl_num
    LI address, 0xF0000000
    SW xfer, 0x0(address)

    SLLI cpp_addr, island_id, 24        #reflect_remote This island
    SLLI temp_data_1, temp_data, 10     #reflect_remote Data_Master
    OR cpp_addr, cpp_addr, temp_data_1

    ANDI temp_data_1, loop_cnt, 0x1
    SLLI temp_data_1, temp_data_1, 0x3
    ORI temp_data_1, temp_data_1, 0x1
    SLLI temp_data_1, temp_data_1 , 15   #reflect_remote Data_ref[4;10] as core_num = 1 0R 9
    OR cpp_addr, cpp_addr, temp_data_1
    SLLI temp_data_1, group_num, 2 
    OR cpp_addr, cpp_addr, temp_data_1    #reflect_remote Data_ref[4;2] as group_num

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_reflect_write_sig_init(cppcmd_data_ref)
    WAIT_ON_SIGNAL (SIG3_pos, 1) ## wait the signal 3

    SLLI temp_data_1, island_id, 24      # This island
    OR cpp_addr, zero, temp_data_1
    SLLI temp_data_1, temp_data, 9       #Data_Master
    OR cpp_addr, cpp_addr, temp_data_1
   
    ANDI temp_data_1, loop_cnt, 0x1      #Core num[4;10] Core 1 & 9
    SLLI temp_data_1, temp_data_1, 0x3
    ADDI temp_data_1, temp_data_1, 0x1
    SLLI temp_data_1, temp_data_1, 0x5 
    OR cpp_addr, cpp_addr, temp_data_1

    LI temp_data, 5
    ANDI temp_data_1, group_num, 0x1
    ADD temp_data, temp_data, temp_data_1
    SLLI temp_data, temp_data, 2
    OR cpp_addr, cpp_addr, temp_data    #Signal nunber 5 0r signal number 6

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_interthread_signal(cppcmd_data_ref)
    LI temp_data, 0xF
    BEQ loop_cnt, temp_data, test_passed
    ADDI loop_cnt, loop_cnt, 1
    J send_loop

receive_and_check:
    nop
    nop
    WAIT_ON_SIGNAL (SIG5_pos,6)      # Eache Group Core= 0 send signal
    WAIT_ON_SIGNAL (SIG6_pos,6)      # Eache Group Core= 0 send signal
    LI loop_cnt, 0x0
    LI address, 0xF0000000

check_loop:
    SLLI xfer, loop_cnt, 4           # [4;4] group_num 0-7
    ANDI temp_data, loop_cnt, 1
    SLLI temp_data, temp_data, 3
    OR xfer, xfer, temp_data         # [4;0]  cl_num == 0 or 8 


    LW temp_data, 0x0(address)
    BNE temp_data, xfer, test_failed
    ADDI loop_cnt, loop_cnt, 1
    ADDI address, address, 4
    LI temp_data, 8
    BNE loop_cnt, temp_data, check_loop
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
