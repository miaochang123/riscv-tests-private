#-----------------------------------
# TEST_NAME: l1_store.S
# modified from group version of test to
# run on all cores and groups within island
# all groups and core clear status location Cache loaded
# Group0,core0 loads the instructions from
# Lmem to CTM memory thru the cache and then set location Cache loaded to 1
# others wait for Cache loaded to be 1 before starting test
# the group and core number is used to sub divide CTM memory space so each core as
# its own space
# simple read write test with varing data stores is performed

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
//ADD base_address, base_address, group_num
//ADDI base_address, base_address, 16
//SLLI base_address, base_address, 7
//ADD  base_address, base_address, ctm_base_address
ANDI lmem_data_base , a0, 0x7
ADDI lmem_data_base, lmem_data_base, 1
SLLI lmem_data_base, lmem_data_base, 10 // after instruction code
/* each core has 512B of space for data
   shared instruction first 32K byte */
	
/*ADD loop_count, loop_count, base_address
*/
LI   tst_count, 0x0  /* the test run three times */
LI   data0, 0x0000000000000000 // bypass L1
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
	
	SD   x0,    0(working_address) /* write zero to instr cache ready */
	LI loop_count, 0x80
	LI   delta , 0x0
	LI working_address,  0x0001100000000000 //start addres of code in ctm mem, bypass l1
	LI lmem_address,    0x000000000000000   // start of code in lmem

store_code_to_cache:		
	LD   data0,    0(lmem_address)	
	LD   data1,    8(lmem_address)
	SD   data0,    0(working_address)
	SD   data1,    8(working_address)
	ADDI delta, delta, 2
	ADDI lmem_address, lmem_address, 16
	ADDI working_address, working_address, 16
	BNE delta, loop_count, store_code_to_cache
//sz add instruction code read back check here
	LI loop_count, 0x80
	LI   delta , 0x0
	LI working_address,  0x0001100000000000 //start addres of code in ctm mem, bypass l1
	LI lmem_address,    0x000000000000000   // start of code in lmem
code_readback:	
	LD   data0,    0(lmem_address)
	LD   data1,    0(working_address)
	BNE data0, data1, fail_temp
	
	ADDI delta, delta, 1
	ADDI lmem_address, lmem_address, 8
	ADDI working_address, working_address, 8
	BNE delta, loop_count, code_readback
	
	LI   data0, 0x0000100000000000 // bypass L1
	ADD  working_address, ctm_base_address, data0
	ADDI working_address, working_address, -8
        SD   delta,    0(working_address) /* write non zero to instr cache ready */

	
/* loop until working_addr not equal to zero*/
wait_loading_cache:
	LI data0, 0
	LI loop_count, 0x80
wait_loop:
	ADDI data0, data0, 1
	BNE loop_count, data0, wait_loop
wait_loading_cache_a:
	LD   data0,    0(working_address)
	BEQ data0,x0,wait_loading_cache_a

/*
	loop_cnt_intr
	    for LMEM  jalr to LMEM Start address
	       for DATA LMEM  data address base of 0 plus core offset
	       for DATA L1
	       for DATA L2
	    for L1    jalr to L1 start address
	    for L2    jalr to L2 start address
*/
test_start_c:
	ADDI working_address,lmem_data_base, 0 /* LMEM DATA space */
	LI   data1 , 0xff20  /* Count */
	LI   data0 , 0xff00   /* Count */
        LI cache_count,2
	//sz could add LMEM as data if 0, lmem, 1 L1, 2 L2
	BEQ tst_delta,x0, cont_a
	LI tst_count,1 
	BEQ tst_count,tst_delta,loop2_a
	LI  working_address,  0x0001000000000000
	ADD working_address, working_address, base_address  /*l1 data address */
	
        J cont_a
loop2_a:
	LI  working_address,  0x0001000000000000
	ADD working_address,working_address, base_address /* l2 data address */
cont_a:	
       
store_loop:		
	SW   data0,    0( working_address)
	ADDI data0, data0, 1
	ADDI working_address, working_address,  4
	BNE data1, data0, store_loop

	LI data1, 0xff40 
store_loop_D:		
	SD   data0,    0( working_address)
	ADDI data0, data0, 1
	ADDI working_address, working_address, 8
	BNE data1, data0, store_loop_D

	ADDI working_address,lmem_data_base, 0 /* LMEM DATA space */
	BEQ tst_delta,x0, cont_b
	BEQ tst_count, tst_delta, loop2_b
	LI  working_address,  0x0001000000000000
	ADD working_address, working_address, base_address  /*l1  data address */
        J cont_b
loop2_b:
	LI  working_address,  0x0001000000000000
	ADD working_address, working_address, base_address //l2 data address
cont_b:	

	ADDI tst_delta, tst_delta, 1
	/* REad back some data */
	
	LI data0,0
	LI data1,0
	LI data2,0
	LI data3,0
	LI data4,0
	LI data5,0

	LW   data0,    0(working_address) 
	LW   data1,    4(working_address)
	LW   data2,    8(working_address)
	LW   data3,    12(working_address)
	LW   data4,    16(working_address)
	LW   data5,    20(working_address)
	LW   data6,   24(working_address)
	#
	# Use delta as expected value
	#
	
	LI   delta , 0xff00   
        BNE  data0, delta, fail_temp
	ADDI delta, delta, 1
        BNE  data1, delta, fail_temp
	ADDI delta, delta, 1
        BNE  data2, delta, fail_temp
	ADDI delta, delta, 1
        BNE  data3, delta, fail_temp
	ADDI delta, delta, 1
        BNE  data4, delta, fail_temp
	ADDI delta, delta, 1
        BNE  data5, delta, fail_temp
	ADDI delta, delta, 1
        BNE  data6, delta, fail_temp

SH_SB_1:	
	/* Test SH and SB */
	LI   data2, 0x1111111100000000
	LI   data1, 0x0
	ADD  data0, data2, core_num
	SD   data0,    0(working_address)
	LD   data1,    0(working_address)  /* 0x1111_1111 */
	ADDI   delta, data0, 0  
        BNE  data1, delta, fail_temp
SH_SB_2:	
	LI   data0, 0x2222
	LI   data1, 0x0
	SH   data0,    4(working_address)
	LD   data1,    0(working_address) /* 0x1111_2222 */
	LI   delta, 0x1111222200000000  
	ADD  delta, delta, core_num
        BNE  data1, delta, fail_temp

SH_SB_3:
	LI   data0, 0x33
	LI   data1, 0x0
	SB   data0,    4(working_address)
	LD   data1,    0(working_address)  /* 0x1111_2233 */
	
	LI   delta, 0x1111223300000000
	ADD  delta, delta, core_num
        BNE  data1, delta, fail_temp
SH_SB_4:

	LI   data0, 0x11111111
	LI   data1, 0x0
	SW   data0,    4(working_address)
 	LD   data1,    0(working_address)  /* 0x1111_1111 */
	LI   delta,0x1111111100000000
	ADD  delta, delta, core_num
        BNE  data1, delta, fail_temp

zSH_SB_5:
	LI   data0, 0x2222
	LI   data1, 0x0
	SH   data0,    6(working_address)
	LD   data1,    0(working_address) /* 0x2222_1111 */
	LI   delta,0x2222111100000000
	ADD  delta, delta, core_num
        BNE  data1, delta, fail_temp

SH_SB_6:
	LI   data0, 0x33
	LI   data1, 0x0
	SB   data0,    5(working_address)
	LD   data1,    0(working_address)  /* 0x2222_3311 */
	LI   delta, 0x2222331100000000
	ADD  delta, delta, core_num  
        BNE  data1, delta, fail_temp

SH_SB_7:
	LI   data0, 0x44
	LI   data1, 0x0
	SB   data0,    6(working_address)
	LD   data1,    0(working_address)  /* 0x2244_3311 */
	LI   delta, 0x2244331100000000
	ADD  delta, delta, core_num  
        BNE  data1, delta, fail_temp
		
SH_SB_8:
	LI   data0, 0x55
	LI   data1, 0x0
	SB   data0,    7(working_address)
	LD   data1,    0(working_address)  /* 0x5544_3311 */
	LI   delta, 0x5544331100000000
	ADD  delta, delta, core_num
        BNE  data1, delta, fail_temp

SH_SB_9:
	/* rotate each cache so different core owns 8 bytes of cache line. 16 byte read write test, force write owner swap every operation
	*/
#	LI data0, 0X00FFFFFFFFFFFFC00 /* address mask */
#	AND working_address, working_address, data0
#	LI data0, 0x20000
#	ADDI data2, core_num, -1
#	ADD working_address, working_address, data0
#	ANDI data1, data2, 0xF8
#	ADD working_address, working_address, data1
#	ANDI data1, data2, 0x7
#	SLLI data1, data1, 7
#	ADD working_address, working_address, data1 /* working address [9:3] = core num [2:0], core num [6:3] */
#	SLLI data0, core_num, 48
SH_SB_9A:
#	SD data0, 0(working_address)
#	LD data1, 0(working_address)
#        BNE  data1, data0, fail_temp
SH_SB_9B:
#	LI data0 , 0x76543210
#	ADD delta, data1, data0
#	SW data0, 0(working_address)
#	LD data1, 0(working_address)
#        BNE  data1, delta, fail_temp /* core_num,000000,76543210 */
	
	
AA:	
        BNE cache_delta,x0,AA_L2
	ADDI cache_delta, cache_delta, 1
	LI data0,  0x0001000000000000
	li data1, %lo(test_start_c)
	add data0 ,data0,data1
	JALR 0(data0)
	nop
	nop
AA_L2:	//bypass L1 test L2  //sz change to L1, issue with running on L2  
	BEQ cache_delta, cache_count, pass_temp
	ADDI cache_delta, cache_delta, 1
	LI data0,  0x0001000000000000
	li data1, %lo(test_start_c)
	add data0 ,data0,data1
	JALR 0(data0)
	nop
	nop
pass_temp:	
	li data0, %lo(pass)
	JALR 0(data0)
	nop
pass:	
#test_done:
	J pass
fail:
	j fail
	//J end_the_test
fail_temp:
   li data0, %lo(fail)
   JALR 0(data0)
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
