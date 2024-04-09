#-----------------------
# TEST_NAME: ct_reflect_read.uc
#        Each ME does 2 Cluster Target reflector read from self-me and only run in group0
#        Each ME must then use interthread signal to signal that data is there...
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


### Read $xfer2 into $xfer0  expect 0x2222
### Read $xfer5 into $xfer2  expect 0x5555
Begine_reflect_read:
    LI island_id, 0x7F0000
    AND island_id, island_id, a0
    SRLI island_id, island_id, 0x10    # island id 
    
    LI group_num, 0xF00           
    AND group_num , group_num, a0 	
    SRLI group_num , group_num , 0x5   # group number currently 4,7,8,11,12,15 group numbers used
    
    ANDI cl_num ,a0, 0xf               # core number    
    
Init_CPP_Memory:
    LI address, 0XF0000000
    LI xfer, 0x0
    SW xfer, 0x0(address)
    LI xfer, 0x1111
    SW xfer, 0x4(address)
    LI xfer, 0x2222
    SW xfer, 0x8(address)
    LI xfer, 0x3333
    SW xfer, 0xC(address)
    LI xfer, 0x4444
    SW xfer, 0x10(address)
    LI xfer, 0x5555
    SW xfer, 0x14(address)
    LI xfer, 0x6666
    SW xfer, 0x18(address)
    LI xfer, 0x7777
    SW xfer, 0x1C(address)

Issue_reflect_read0:                   ##Read $xfer2 into $xfer0  expect 0x2222
    SLLI temp_data, island_id, 24      # This island
    OR cpp_addr, zero, temp_data
    LI temp_data, 0x4                  #Data Master 4,7,8,11,12,15 
    SLLI temp_data, temp_data, 10
    OR cpp_addr, cpp_addr,temp_data  

    SLLI temp_data, cl_num, 14         #Core number 
    OR cpp_addr, cpp_addr,temp_data  

    LI temp_data, 0x2                  #Data ref[10;0]
    SLLI  temp_data,  temp_data, 2
    OR cpp_addr, cpp_addr,temp_data      
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_reflect_read_sig_init(cppcmd_data_ref)
     WAIT_ON_SIGNAL (SIG3_pos, 1) ## wait the signal 3

Issue_reflect_read1:                   ##Read $xfer5 into $xfer2  expect 0x5555
    SLLI temp_data, island_id, 24      # This island
    OR cpp_addr, zero, temp_data

    LI temp_data, 0x4                  #Data Master 4,7,8,11,12,15 
    SLLI temp_data, temp_data, 10
    OR cpp_addr, cpp_addr,temp_data  

    SLLI temp_data, cl_num, 14         #Core number 
    OR cpp_addr, cpp_addr,temp_data  

    LI temp_data, 0x5                  #Data ref[10;0]
    SLLI  temp_data,  temp_data, 2
    OR cpp_addr, cpp_addr,temp_data      
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x8)
    .insn s 43,0,cpp_addr,ct_reflect_read_sig_init(cppcmd_data_ref)
     WAIT_ON_SIGNAL (SIG3_pos, 1) ## wait the signal 3

Check_result:
    LW temp_data, 0x0(address)
    LI temp_data_1, 0x2222
    BNE temp_data, temp_data_1, test_failed

    LW temp_data, 0x8(address)
    LI temp_data_1, 0x5555
    BNE temp_data, temp_data_1, test_failed




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
