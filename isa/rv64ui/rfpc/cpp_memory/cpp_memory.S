
#ifndef _ENV_PHYSICAL_MULTI_CORE_H
	
#define _ENV_PHYSICAL_MULTI_CORE_H
#include "riscv_test.h"
#include "test_macros.h"
#undef RISCV_MULTICORE_DISABLE
#define RISCV_MULTICORE_DISABLE

#endif


.equ CPP_MEM, 0xf0000000
.equ CPP_MEM_SZE_PER_CORE, 0x200	
	
RVTEST_RV64U
RVTEST_CODE_BEGIN
	
	
LI t1 , CPP_MEM # set offset to CPP MEM # the hardware divide CPP Memory space by Cores
ANDI t2 ,a0, 0xff # core number
SLLI t2 ,a0, 8 # core number
#Each Core will load the CPP_MEMORY with a pattern

li t4, CPP_MEM_SZE_PER_CORE
LI x1 , 0
store_loop:
SW t2, 0x0(t1)
addi t2,t2,4
SW t2, 0x4(t1)
addi t2,t2,4
SW t2, 0x8(t1)
addi t2,t2,4
SW t2, 0xc(t1)
addi t2,t2,4
SW t2, 0x10(t1)
addi t2,t2,4
SW t2, 0x14(t1)
addi t2,t2,4
SW t2, 0x18(t1)
addi t2,t2,4
SW t2, 0x1c(t1)
addi t2,t2,4
#SW t2, 0x20(t1)
#addi t2,t2,4
addi x1, x1,0x20
#addi t1, t1,0x24
addi t1, t1,0x20
BNE x1,t4,store_loop
	
#read back and check cpp_mem
LI x1,0
LI t1 , CPP_MEM # set offset to CPP MEM # the hardware divide CPP Memory space by Cores
ANDI t2 ,a0, 0xff # core number
SLLI t2 ,a0, 8 # core number
read_loop:
	
LW t3, 0x0(t1)
BNE t3,t2,test_failed
addi t2,t2,4
LW t3, 0x4(t1)
BNE t3,t2,test_failed
addi t2,t2,4
LW t3, 0x8(t1)
BNE t3,t2,test_failed
addi t2,t2,4
LW t3, 0xc(t1)
BNE t3,t2,test_failed
addi t2,t2,4
#LW t3, 0x10(t1)
#BNE t3,t2,test_failed
#addi t2,t2,4
addi x1,x1,0x10
#addi t1,t1,0x14
addi t1,t1,0x10
BNE x1,t4, read_loop		

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
