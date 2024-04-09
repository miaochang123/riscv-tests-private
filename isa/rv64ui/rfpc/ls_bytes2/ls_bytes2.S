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


#define zero   x0 # zero register
#define cppcmd_data_ref x3
#define count x4
#define hart_id    x10 #hart csr register

#define expect1       x11
#define expect2       x12
#define expect3       x13
#define expect4       x14
#define offset        x15
#define end_offset    x16
#define address       x17
#define address4      x23
#define address8      x24
#define cl_num        x18
#define group_num     x19
#define temp_data     x20
#define temp_data_1   x21
#define temp_data_2   x22
#define data_bytew  x26
#define xfer  x27



.equ CPP_MEM_ADDR,   0xf0000000

.equ INIT_RESIDUE,  0x87654321
.equ WR_DATA0A,    0x00000000
.equ WR_DATA1A,    0x00000000
.equ WR_DATA2A,    0x00000000
.equ WR_DATA3A,    0x00000000
.equ WR_DATA4A,    0x00000000
.equ WR_DATA5A,    0x00000000
.equ WR_DATA6A,    0x00000000
.equ WR_DATA7A,    0x00000000
.equ WR_DATA8A,    0x55443322
.equ WR_DATA9A,    0x44332211
.equ WR_DATA10A,   0x88776655
.equ WR_DATA11A,   0xeeddccbb
.equ WR_DATA12A,   0xffeeddcc
.equ WR_DATA13A,   0xbbaa9988





RVTEST_RV64U
RVTEST_CODE_BEGIN



LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, WR_DATA0A
SW temp_data, 0x0(xfer)
LI temp_data, WR_DATA1A
SW temp_data, 0x4(xfer)
LI temp_data, WR_DATA2A
SW temp_data, 0x8(xfer)
LI temp_data, WR_DATA3A
SW temp_data, 0xC(xfer)
LI temp_data, WR_DATA4A
SW temp_data, 0x10(xfer)
LI temp_data, WR_DATA5A
SW temp_data, 0x14(xfer)
LI temp_data, WR_DATA6A
SW temp_data, 0x18(xfer)
LI temp_data, WR_DATA7A
SW temp_data, 0x1C(xfer)
LI temp_data, WR_DATA8A
SW temp_data, 0x20(xfer)
LI temp_data, WR_DATA9A
SW temp_data, 0x24(xfer)
LI temp_data, WR_DATA10A
SW temp_data, 0x28(xfer)
LI temp_data, WR_DATA11A
SW temp_data, 0x2C(xfer)
LI temp_data, WR_DATA12A
SW temp_data, 0x30(xfer)
LI temp_data, WR_DATA13A
SW temp_data, 0x34(xfer)


##;--------------------------------------
##; Set Up the BASE scratch address
##; Each ME will use a different region
##;--------------------------------------
ADD address, group_num, zero

#################write all defined data to cls sram
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;


#######################################
########Loop le write
#######################################

LI offset, 0
LI end_offset, 8
LI expect1, 0x55443322


loop_le_1:
ADD address, group_num, zero
ADD address8, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x20)  ;
.insn s 43,0,address8,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
ADD address, group_num, zero # set to initial value
ADD address4, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x100)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG3_pos,1);
LI temp_data,0
LWU temp_data, 0x100(xfer)
BNE temp_data, expect1, test_failed
ADDI offset, offset, 1
BNE end_offset, offset, loop_le_1

NOP
NOP
NOP


LI offset, 0
LI end_offset, 8
LI expect1, 0x44332211
LI expect2, 0x88776655


loop_le_2:
ADD address, group_num, zero
ADD address8, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x7,0x24)  ;
.insn s 43,0,address8,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
ADD address, group_num, zero # set to initial value
ADD address4, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x120)  ;
.insn s 43,0,address4,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG3_pos,1);
LI temp_data,0
LWU temp_data, 0x120(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x124(xfer)
BNE temp_data, expect2, test_failed
ADDI offset, offset, 1
BNE end_offset, offset, loop_le_2

NOP
NOP
NOP



#######################################
########Loop be write
#######################################

LI offset, 0
LI end_offset, 8
LI expect1, 0xeeddccbb


loop_be_1:
ADD address, group_num, zero
ADD address8, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x3,0x2C)  ;
.insn s 43,0,address8,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
ADD address, group_num, zero # set to initial value
ADD address4, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address4,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG3_pos,1);
LI temp_data,0
LWU temp_data, 0x140(xfer)
BNE temp_data, expect1, test_failed
ADDI offset, offset, 1
BNE end_offset, offset, loop_be_1

NOP
NOP
NOP


LI offset, 0
LI end_offset, 8
LI expect1, 0xffeeddcc
LI expect2, 0xbbaa9988


loop_be_2:
ADD address, group_num, zero
ADD address8, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x7,0x30)  ;
.insn s 43,0,address8,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;
ADD address, group_num, zero # set to initial value
ADD address4, address, offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x160)  ;
.insn s 43,0,address4,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG3_pos,1);
LI temp_data,0
LWU temp_data, 0x160(xfer)
BNE temp_data, expect1, test_failed
LWU temp_data, 0x164(xfer)
BNE temp_data, expect2, test_failed
ADDI offset, offset, 1
BNE end_offset, offset, loop_be_2




NOP
NOP
NOP











ADD address, group_num, zero


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
