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

.equ CPP_MEM_ADDR, 0xf0000000
.equ CPP_XFER_CACHE_MEM, 0x12345678
.equ CPP_XFER_CACHE_MEM1, 0x11111111
.equ CACHEABLE_MEM_ADDR, 0x1201e00000000  # target island ID set to 1, because this is an island level test


RVTEST_RV64U
RVTEST_CODE_BEGIN

#define core_num        a4
#define group_num       a5

#define cpp_addr        s1
#define cppcmd_data_ref s2
#define address         s4

#define temp_data       t1
#define temp_data_1     t2
#define temp_data_2     t3

get_core_num:
    LI group_num, 0xf00 # mask group number
    AND group_num , group_num, a0 # X10 CSR
    SRLI group_num, group_num, 8
    BNEZ group_num, test_passed # only test group 0

    LI core_num,  0xff # mask core number
    AND core_num , core_num, a0 # X10 CSR
    BNEZ core_num, test_passed # only test core 0

cpp_write_ctm:
    # Write to base address
    LI temp_data, CPP_XFER_CACHE_MEM
    LI address, CPP_MEM_ADDR
    SW temp_data, 0x0(address)
    
    LI cpp_addr, 0x0 //ctm base addr
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)
    .insn s 43,0,cpp_addr,memory_unit_write_atomic(cppcmd_data_ref)	 ;# CPP Command write to ctm
    WAIT_ON_SIGNAL (SIG2_pos,1)

cpp_read_ctm:
    # Read back the first word
    LI cpp_addr, 0x0 //ctm base addr
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x10) 
    .insn s 43,0,cpp_addr,memory_unit_read_atomic(cppcmd_data_ref)	 ;# CPP Command read to ctm
    WAIT_ON_SIGNAL (SIG2_pos,1)
    
    LI address, CPP_MEM_ADDR 
    LW temp_data_1, 0x10(address)
    
    BNE temp_data, temp_data_1, test_failed


cache_rw_ctm:
    # Construct the Cacheable memory address
    # using: direct access (7); target island (9);  Read/Write Backing Memory (4)
    LI address, CACHEABLE_MEM_ADDR
    LI temp_data, CPP_XFER_CACHE_MEM1
    SW temp_data, 0x4(address)
    LW temp_data_1, 0x4(address)
#    nop
#    nop
#    nop
#    nop
#    nop
    
    BNE temp_data, temp_data_1, test_failed


cpp_read_back:
    # Read back the first 4 words from memory region 0x0 in CTM
    LI cpp_addr, 0x0 //ctm base addr
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x20)
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read to ctm
    WAIT_ON_SIGNAL (SIG2_pos,1)
    
    LI address, CPP_MEM_ADDR
    LW temp_data, 0x20(address)
    
    LI cpp_addr, 0x4 //ctm base addr+4
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x30)
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read to ctm
    WAIT_ON_SIGNAL (SIG2_pos,1)
    
    LI address, CPP_MEM_ADDR
    LW temp_data_1, 0x30(address)
    
    LI temp_data_2, CPP_XFER_CACHE_MEM
    BNE temp_data, temp_data_2, test_failed
    LI temp_data_2, CPP_XFER_CACHE_MEM1
    BNE temp_data_1, temp_data_2, test_failed 



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
