#-----------------------
# TEST_NAME: l1_store_single_core.S
#     Simple single-core store/load test that runs out of lmem, then l1, then l2.
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
#include "test_macros.h"

#define core_num        x18
#define group_num       x19

RVTEST_RV64U
RVTEST_CODE_BEGIN

# a0    24:16       11:8        7:0
#       island_id   group_num   core_num
	LI group_num, 0xf00
	AND group_num, group_num, a0
	SRLI group_num, group_num, 8 #group_num
	ANDI core_num, a0, 0x7 #core_num

        /* test only runs on core 0 of group 0 */
	bnez group_num, pass
	bnez core_num, pass

	LI   x1 , 0x80  /* Count */
	LI   x2 , 0x00   /* Count */
	LI x3,  0x0001100000000000
	LI x11,  0x000000000000000
	LI x20, 0

store_code_to_cache:		
	LD   x4,    0(x11)	
	LD   x5,    8(x11)
	SD   x4,    0(x3)
	SD   x5,    8(x3)
	ADDI x2, x2, 2
	ADDI x3, x3, 16
	ADDI x11, x11, 16
	BNE x1, x2, store_code_to_cache
	
test_start_c:	
	LI   x1 , 0xff20  /* Count */
	LI   x2 , 0xff00   /* Count */
        LI x21,2
	BEQ x20,x21,loop2_a
	LI x3,  0x0001000000001000
        J cont_a
loop2_a:
	LI x3,  0x0001100000001000
cont_a:	
	ADDI x3, x3, 1024
	ADDI x0,x0,0
	ADDI x0,x0,0
	ADDI x0,x0,0
	ADDI x0,x0,0
	ADDI x0,x0,0
        /* WRite to 16 consecutive locations */

store_loop:		
	SW   x2,    0(x3)
	ADDI x2, x2, 1
	ADDI x3, x3, 4
	BNE x1, x2, store_loop

	LI x1, 0xff40 
store_loop_D:		
	SD   x2,    0(x3)
	ADDI x2, x2, 1
	ADDI x3, x3, 8
	BNE x1, x2, store_loop_D

	BEQ x20,x21,loop2_b
	LI x3,  0x0001000000001000
        J cont_b
loop2_b:
	LI x3,  0x0001100000001000
cont_b:	
	ADDI x3, x3, 1024

	/* REad back some data */
	
	LI x4,0
	LI x5,0
	LI x6,0
	LI x7,0
	LI x8,0
	LI x9,0
	LI x10,0

	LW   x4,    0(x3) 
	LW   x5,    4(x3)
	LW   x6,    8(x3)
	LW   x7,    12(x3)
	LW   x8,    16(x3)
	LW   x9,    20(x3)
	LW   x10,   24(x3)
	#
	# Use x30 as expected value
	#
	
	LI   x30 , 0xff00   /* Count */
        BNE  x4, x30, fail_temp
	ADDI x30, x30, 1
        BNE  x5, x30, fail_temp
	ADDI x30, x30, 1
        BNE  x6, x30, fail_temp
	ADDI x30, x30, 1
        BNE  x7, x30, fail_temp
	ADDI x30, x30, 1
        BNE  x8, x30, fail_temp
	ADDI x30, x30, 1
        BNE  x9, x30, fail_temp
	ADDI x30, x30, 1
        BNE  x10, x30, fail_temp

SH_SB_1:	
	/* Test SH and SB */
	LI   x2, 0x11111111
	SW   x2,    0(x3)
	LW   x4,    0(x3)  /* 0x1111_1111 */
	LI   x30, 0x11111111  
        BNE  x4, x30, fail_temp
SH_SB_2:	
	LI   x2, 0x2222
	SH   x2,    0(x3)
	LW   x4,    0(x3) /* 0x1111_2222 */
	LI   x30, 0x11112222  
        BNE  x4, x30, fail_temp

SH_SB_3:
	LI   x2, 0x33
	SB   x2,    0(x3)
	LW   x4,    0(x3)  /* 0x1111_2233 */
	LI   x30, 0x11112233  
        BNE  x4, x30, fail_temp
SH_SB_4:

	LI   x2, 0x11111111
	SW   x2,    0(x3)
	LW   x4,    0(x3)  /* 0x1111_1111 */
	LI   x30, 0x11111111  
        BNE  x4, x30, fail_temp

SH_SB_5:
	LI   x2, 0x2222
	SH   x2,    2(x3)
	LW   x4,    0(x3) /* 0x2222_1111 */
	LI   x30, 0x22221111  
        BNE  x4, x30, fail

SH_SB_6:
	LI   x2, 0x33
	SB   x2,    1(x3)
	LW   x4,    0(x3)  /* 0x2222_3311 */
	LI   x30, 0x22223311  
        BNE  x4, x30, fail_temp

SH_SB_7:
	LI   x2, 0x44
	SB   x2,    2(x3)
	LW   x4,    0(x3)  /* 0x2244_3311 */
	LI   x30, 0x22443311  
        BNE  x4, x30, fail_temp
		
SH_SB_8:
	LI   x2, 0x55
	SB   x2,    3(x3)
	LW   x4,    0(x3)  /* 0x5544_3311 */
	LI   x30, 0x55443311  
        BNE  x4, x30, fail_temp
AA:	
        BNE x20,x0,AA_L2
	ADDI x20, x20, 1
	LI x1,  0x0001000000000000
	li x2, %lo(test_start_c)
	add x1 ,x1,x2
	JALR 0(x1)
	nop
	nop
AA_L2:	
	LI x21,1
	BNE x20, x21, pass_temp
	ADDI x20, x20, 1
	LI x1,  0x0001100000000000
	li x2, %lo(test_start_c)
	add x1 ,x1,x2
	JALR 0(x1)
	nop
	nop
pass_temp:	
	li x1, %lo(pass)
	JALR 0(x1)
	nop
pass:	
#test_done:
	J end_the_test
fail:	
	J end_the_test
fail_temp:
   li x1, %lo(fail)
   JALR 0(x1)
/* tohost and fromhost variables */
   .p2align  3
   .globl tohost
tohost:
   .long 0
   .long 0


   .p2align  3
   .globl fromhost
fromhost:
   .long 0
   .long 0


end_the_test:
    addi a0, x0, 1
    lui  a1, %hi(tohost)
    addi a1, a1, %lo(tohost)
    sw   a0, 0(a1)
rv_test_loop:
    J rv_test_loop
