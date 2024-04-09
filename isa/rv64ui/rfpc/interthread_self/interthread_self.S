#--------------------------------------------------------------------
#  FileName: interthread_self.S   
#  Author:   Leo     
#  Created:  19/04/2023
#  Description: 
#    Checks waiting signaling
#    Checks all contexts and all cores.
#    Uses interthread signalling to wakeup
# Constraints: 
#      Utilizes all 8 Core
#--------------------------------------------------------------------



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
#define sig_num         s6
#define check_count     s7
#define check_data      s8

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
    
    LI check_count, 0
    LI sig_num, 0

    LI temp_data , 7
    BNE cl_num, temp_data, start_test       # core 7 send inter-thread signal to core 0
    
    LI cpp_addr,  0xE0004000                # set the shared memory to did the count
    LI temp_data, 0 
    SD temp_data, 0x0(cpp_addr)
    ADDI sig_num, sig_num, 1
   
    LI island_id, 0 
    SLLI  cpp_addr, island_id, 24      # island id = 0
    LI temp_data, 0x4                 
    SLLI temp_data, temp_data, 0x9
    OR cpp_addr, cpp_addr, temp_data   # data_master = 4
    LI temp_data, 0x0
    SLLI temp_data, temp_data, 0x5 
    OR cpp_addr, cpp_addr, temp_data    # core num = 0
    LI temp_data, 0x1                      
    SLLI temp_data, temp_data, 0x2
    OR cpp_addr, cpp_addr, temp_data   # signal num = 1
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_interthread_signal(cppcmd_data_ref)
    
    
start_test:
    LI sig_num, 1
    LI check_count, 0
    LI check_data, 0
    
#Island_ID       = [30:24]
#Signal Master   = [13:9]
#Signal Ref[6:3] = [8:5] Core Num
#Signal Ref[2:0] = [4:2] Signal num

waiting_signal_loop:
    LI temp_data, 1
    BEQ temp_data, sig_num, waiting_signal_1
    LI temp_data, 2
    BEQ temp_data, sig_num, waiting_signal_2
    LI temp_data, 3
    BEQ temp_data, sig_num, waiting_signal_3
    LI temp_data, 4
    BEQ temp_data, sig_num, waiting_signal_4
    LI temp_data, 5
    BEQ temp_data, sig_num, waiting_signal_5
    LI temp_data, 6
    BEQ temp_data, sig_num, waiting_signal_6
    LI temp_data, 7
    BEQ temp_data, sig_num, waiting_signal_7

waiting_signal_1:
    WAIT_ON_SIGNAL (SIG1_pos, 1) ## wait the signal 1
    J sending_signal

waiting_signal_2:
    WAIT_ON_SIGNAL (SIG2_pos, 1) ## wait the signal 2
    J sending_signal

waiting_signal_3:
    WAIT_ON_SIGNAL (SIG3_pos, 1) ## wait the signal 3
    J sending_signal

waiting_signal_4:
    WAIT_ON_SIGNAL (SIG4_pos, 1) ## wait the signal 4
    J sending_signal

waiting_signal_5:
    WAIT_ON_SIGNAL (SIG5_pos, 1) ## wait the signal 5
    J sending_signal

waiting_signal_6:
    WAIT_ON_SIGNAL (SIG6_pos, 1) ## wait the signal 6
    J sending_signal

waiting_signal_7:
    WAIT_ON_SIGNAL (SIG7_pos, 1) ## wait the signal 7
    LI temp_data, 0
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 1
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 2
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 3
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 4
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 5
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 6
    BEQ cl_num, temp_data, sending_signal
    ADDI check_data, check_data, 7
    LI temp_data, 7
    BEQ cl_num, temp_data, sending_signal
    J test_failed

sending_signal:
    LI cpp_addr, 0xE0004000
    LD temp_data, 0x0(cpp_addr)
    ADDI temp_data, temp_data, 1
    ADD check_count, check_count, temp_data
    SD temp_data, 0x0(cpp_addr)

    LI temp_data, 14
    ADD temp_data_1,cl_num, sig_num
    BEQ temp_data_1, temp_data , check_counting_data

    LI island_id, 0 
    SLLI  cpp_addr, island_id, 24      # island id = 0
    LI temp_data, 0x4                 
    SLLI temp_data, temp_data, 0x9
    OR cpp_addr, cpp_addr, temp_data   # data_master = 4
    ADDI temp_data, cl_num, 0x1
    ANDI temp_data, temp_data, 0x7                      
    SLLI temp_data, temp_data, 0x5
    OR cpp_addr, cpp_addr, temp_data   # core num = cur_core num +1 
    ADDI temp_data, cl_num, 1
    SRLI temp_data, temp_data, 3
    ANDI  temp_data, temp_data, 1
    ADD temp_data, temp_data, sig_num    # when core num =7 then the signal num +1 
    SLLI temp_data, temp_data, 2
    OR cpp_addr, cpp_addr, temp_data # Signal nunber 1~7
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,0,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_interthread_signal(cppcmd_data_ref)
    LI temp_data, 7
    BEQ sig_num, temp_data, check_counting_data
    ADDI sig_num, sig_num, 1
    J waiting_signal_loop

check_counting_data:
    ADDI temp_data, check_data , 0xAF
    BNE temp_data,  check_count, test_failed
        

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
