#-----------------------
# TEST_NAME: xpb_rw.S
#     Reads and writes XPB registers
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
#define loop_cnt        s7


#define cl_num          a4
#define group_num       a5
#define	packet_number   a6

#define temp_data       t1
#define temp_data_1     t2
#define temp_data_2     t4
#define temp_data_3     t6

.equ CTM_SE_XPB_DEVICE_ID   , 0x10

.equ data_0 ,   0x1111
.equ data_1 ,   0x2222
.equ data_2 ,   0x3333
.equ data_3 ,   0x4444

get_core_num:
    LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
    AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
    	
    SRLI group_num , group_num , 0x5   # group number move to  4  - F gggg # group number move to  00 0ggg 0000
    ANDI cl_num ,a0, 0xf               # core number
    OR  group_num , group_num , cl_num # set group number as ggg_cccc 
    
    LI temp_data_1 , 0x1
    BGE group_num , temp_data_1, test_passed # Only run in rfpc_cluster0 & rfpc_group0 & (core0)

xpb_write:
    LI address,0xF0000000
    LI xfer, data_0
    SW xfer, 0x0(address)
    LI xfer, data_1
    SW xfer, 0x4(address)
    LI xfer, data_2
    SW xfer, 0x8(address)
    LI xfer, data_3
    SW xfer, 0xC(address)

    LI cpp_addr,  CTM_SE_XPB_DEVICE_ID    # Load the device ID
    SLLI cpp_addr, cpp_addr, 16
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write

    ADDI cpp_addr, cpp_addr, 4
    ADDI cppcmd_data_ref, cppcmd_data_ref, 4
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write

    ADDI cpp_addr, cpp_addr, 4
    ADDI cppcmd_data_ref, cppcmd_data_ref, 4
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write

    ADDI cpp_addr, cpp_addr, 4
    ADDI cppcmd_data_ref, cppcmd_data_ref, 4
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write

    WAIT_ON_SIGNAL (SIG5_pos,4)

xpb_read:
    LI cpp_addr,  CTM_SE_XPB_DEVICE_ID    # Load the device ID
    SLLI cpp_addr, cpp_addr, 16
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x4) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG2_pos,1)

    ADDI cpp_addr, cpp_addr, 4
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0xC) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG2_pos,1)

    ADDI cpp_addr, cpp_addr, 4
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x14) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG2_pos,1)


    ADDI cpp_addr, cpp_addr, 4
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x1C) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG2_pos,1)

    LI address, 0xF0000000
    LI temp_data, data_0
    LW temp_data_1, 0x4(address)
    BNE temp_data, temp_data_1, test_failed
    LI temp_data, data_1
    LW temp_data_1, 0xC(address)
    BNE temp_data, temp_data_1, test_failed
    LI temp_data, data_2
    LW temp_data_1, 0x14(address)
    BNE temp_data, temp_data_1, test_failed
    LI temp_data, data_3
    LW temp_data_1, 0x1C(address)
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
