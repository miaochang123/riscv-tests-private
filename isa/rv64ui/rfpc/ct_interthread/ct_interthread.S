#-----------------------
# TEST_NAME: ct_interthread.S
#		CTX0 of each ME signals CTX1 of every ME
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

LI island_id, 0x7F0000
AND island_id, island_id, a0
SRLI island_id, island_id, 0x10    # island id 

LI group_num, 0xF00           
AND group_num , group_num, a0 	
SRLI group_num , group_num , 0x5   # group number currently 4,7,8,11,12,15 group numbers used

ANDI cl_num ,a0, 0xf               # core number

OR  group_num , group_num , cl_num # set group number as ggg_cccc 

LI temp_data , 0
BEQ group_num, zero, send      # Core0 AS the master to send the signal to core1~15

LI temp_data , 1
BEQ cl_num, temp_data,  receive_and_check
J test_passed

#Island_ID       = [30:24]
#Signal Master   = [13:9]
#Signal Ref[6:3] = [8:5] Core Num
#Signal Ref[2:0] = [4:2] Signal num

send:
    LI loop_cnt, 0x4

# Use GROUP_NUM as signal
send_loop:
    SLLI temp_data, island_id, 24
    OR cpp_addr, zero, temp_data
    
    # Signal Master 4,7,8,11,12,15
    ANDI temp_data, loop_cnt, 0x2
    SRLI temp_data, temp_data, 0x1
    SLLI temp_data_1, temp_data, 0x1
    OR temp_data,temp_data, temp_data_1
    LI temp_data_1, 0xFFFC
    AND temp_data_1,loop_cnt, temp_data_1
    OR temp_data, temp_data, temp_data_1
    SLLI temp_data, temp_data, 9
    OR cpp_addr, cpp_addr, temp_data 
    
    ANDI temp_data, loop_cnt, 0x1   # Signal Me Core 1 & 9
    SLLI temp_data, temp_data, 0x3
    ADDI temp_data, temp_data, 0x1
    SLLI temp_data, temp_data, 0x5 
    OR cpp_addr, cpp_addr, temp_data
    LI temp_data, 5
    SLLI temp_data, temp_data, 2
    OR cpp_addr, cpp_addr, temp_data # Signal nunber 5
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_interthread_signal(cppcmd_data_ref)
    LI temp_data, 0xF
    BEQ loop_cnt, temp_data, test_passed
    ADDI loop_cnt, loop_cnt, 1
    J send_loop


##ME Core 1 does Receive checking
receive_and_check:
nop
nop
WAIT_ON_SIGNAL (SIG5_pos,1) # Eache Core num == 0 send signal 
nop
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
