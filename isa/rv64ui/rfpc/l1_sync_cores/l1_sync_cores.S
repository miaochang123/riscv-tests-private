#-----------------------------------
# TEST_NAME: l1_sync_cores.S
# all cores wire zero to same address
# non zero cores delay loop
# cores zero writes 0x80 to same address
# after delay loop cores read same address and if 0x80 jump to pass
# all core will loop on read for 100 loop count if don't read 0x80 jump to fail
# this test is to check release logic in L1 and L2 cache
# when core zero writes 0x80 to address other read owners should receive release to invalidate local cover

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
/* register x0 - x31
   x0 = 0
   t0-2 = x5-7
   a0-7 =x10-17 */
#define zero            x0 /* ok*/
#define base_address    x28 
#define working_address x3 
#define ctm_base_address x4
#define lmem_data_base x5
#define hart_reg x10
#define data6      x11
#define cache_delta      x12
#define cache_count      x13
#define tst_delta      x14
#define tst_count      x15
#define loop_count      x16
#define address         x17
#define core_num        x18
#define group_num       x19
#define delta           x26
#define lmem_address    x27
#define data0    x20
#define data1    x21
#define data2    x22
#define data3    x23
#define data4    x24
#define data5    x25

	
RVTEST_RV64U
RVTEST_CODE_BEGIN

	
# a0    24:16       11:8        7:0
#       island_id   group_num   core_num
# ext_core_num = bundle(group_numbe[3:0],core_num[2:0] ,
# 0 to 127, the core with the ISLAND 
	
LI group_num, 0xf00
AND group_num, group_num, hart_reg
SRLI group_num, group_num, 5 #group_num aligns to bit3
ANDI core_num, a0, 0x7 #core_num
ADD  core_num, group_num, core_num /* extened core number within island */
ADDI core_num, core_num, 1
SLLI data0, core_num, 10
LI ctm_base_address,  0x0001000000010000
ADDI base_address, data0, 0
ANDI lmem_data_base , a0, 0x7
ADDI lmem_data_base, lmem_data_base, 1
SLLI lmem_data_base, lmem_data_base, 10 // after instruction code
/* each core has 512B of space for data
   shared instruction first 32K byte */
	
/*ADD loop_count, loop_count, base_address
*/
	
LI   tst_count, 0x0  /* the test run three times */
LI   data0, 0x0000100000000000 // bypass L1
ADD  working_address, ctm_base_address, data0
ADDI working_address, working_address, -8
SD   x0,    0(working_address) /* write zero to instr cache ready */
LD   data0,    0(working_address) /* write zero to instr cache ready */
//WRITE_CACHE_LOAD_READY:	
//	J WRITE_CACHE_LOAD_READY
LI   tst_delta, 0
LI cache_delta,0
check_core_num:	
LI data0, 1
LI lmem_address,    0x000000000000000   // start of code in lmem
BNE  core_num, data0, wait_loading_cache /* core zero loads instruction cache */

	LI loop_count, 0x80
	LI   delta , 0x0
delay_loop_1:	
	ADDI delta, delta, 1
	BNE delta, loop_count, delay_loop_1
//sz core0 writes 0x80 to sync address
	LI loop_count, 0x80
	SD   loop_count,    0(working_address) /* write 0x80 to instr cache ready */
wait_loading_cache:
	
	LI   delta , 0x0
	LI loop_count, 0x80
	LI data0, 0x80
delta_loop_2:	
	LD   data1,    0(working_address)
	BEQ data0, data1, pass
	ADDI delta, delta, 1
	BNE loop_count, delta, delta_loop_2
	J fail
	
pass:	
#test_done:
	J pass
fail:
	j fail
	//J end_the_test
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
