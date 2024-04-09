#-----------------------
# TEST_NAME: l2_xpb_rw.S
#     Reads and writes l2 cache XPB registers
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

#define core_num        a4
#define group_num       a5
#define wait_cycle      a6

#define cpp_addr        s1
#define cppcmd_data_ref s2
#define address         s4

#define temp_data       t1
#define temp_data_1     t2



.equ XPB_DID_RFPC_L2CACHE_CFG , 0x80
.equ TCACHE_INITIALIZATION_STATUS, 0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ data_1, 1
.equ data_2, 0xf

get_core_num:
    LI group_num, 0xf00 # mask group number
    AND group_num , group_num, a0 # X10 CSR
    SRLI group_num, group_num, 8
    BNEZ group_num, test_passed # only test group 0

    LI core_num,  0xff # mask core number
    AND core_num , core_num, a0 # X10 CSR
    BNEZ core_num, test_passed # only test core 0

LI temp_data_1, data_1
LI wait_cycle, 30 # wait after resetn
wait_cycles:
    SUB  wait_cycle, wait_cycle, temp_data_1
    BNEZ wait_cycle, wait_cycles


l2_init_xpb_read:
    LI cpp_addr, XPB_DID_RFPC_L2CACHE_CFG # load the device ID
    SLLI cpp_addr, cpp_addr, 16
    ORI cpp_addr, cpp_addr, TCACHE_INITIALIZATION_STATUS
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG2_pos,1)

LI address, CPP_MEM_ADDR
LW temp_data, 0x0(address) 
LI temp_data_1, data_2
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

