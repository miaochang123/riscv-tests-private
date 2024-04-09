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
#define expect_low    x13
#define expect_high   x14
#define address       x15
#define address4      x16
#define address8      x17
#define ringbase_base x18
#define ringptr_base  x19
#define cl_num        x20
#define temp_data     x21
#define temp_data_1   x22
#define temp_data_2   x23
#define xfer  x27





.equ CPP_MEM_ADDR,   0xf0000000

##.equ RING_SIZE,  1024
##.equ RING_INDEX, 5
.equ RING_CONFIG, 0x00050000
.equ RING_PTR_CONFIG, 0x00100000
.equ RING2_CONFIG, 0x00050000
.equ RING2_PTR_CONFIG, 0x00400020
.equ RING2_TAILPTR_DATA, 0x8765432187654321
.equ RINGWORK_DATA0A,    0x0000022200000111
.equ RINGWORK_DATA1A,    0x0000044400000333
.equ RINGWORK_DATA2A,    0x0000066600000555
.equ RINGWORK_DATA3A,    0x0000088800000777

.equ EXPECT_WORK_TAILPTR,    0x00180000
.equ EXPECT_THREAD_TAILPTR,  0x00420020





RVTEST_RV64U
RVTEST_CODE_BEGIN



##LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
##AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
##SRLI group_num , group_num , 0x8 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
##ANDI group_num , group_num , 0xf # 
ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, RINGWORK_DATA0A
SD temp_data, 0x0(xfer)
LI temp_data, RINGWORK_DATA1A
SD temp_data, 0x8(xfer)
LI temp_data, RINGWORK_DATA2A
SD temp_data, 0x10(xfer)
LI temp_data, RINGWORK_DATA3A
SD temp_data, 0x18(xfer)
LI temp_data, RING_CONFIG
SW temp_data, 0x20(xfer)
LI temp_data, RING_PTR_CONFIG
SW temp_data, 0x28(xfer)
LI temp_data, RING2_CONFIG
SW temp_data, 0x30(xfer)
LI temp_data, RING2_PTR_CONFIG
SW temp_data, 0x38(xfer)
LI temp_data, RING2_TAILPTR_DATA
SD temp_data, 0x40(xfer)

#######################################
########workq is empty, add work to ring1
#######################################
###for ring1
LI ringbase_base, 0x00010008
LI ringptr_base , 0x00010088

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
.insn s 43,0,ringbase_base,cluster_scratch_write(cppcmd_data_ref)	 ;# cpp command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

li cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x28)  ;
.insn s 43,0,ringptr_base,cluster_scratch_write(cppcmd_data_ref)	 ;# cpp command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;


###for ring1 pull data
LI address, 0x00000004
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_ring_workq_add_work(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG3_pos,1) 	;

NOP
NOP
NOP

###read ring1 tailptr
LI address4, 0x00010088
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x100)  ;
.insn s 43,0,address4,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG3_pos,1) 	;

LI expect1, EXPECT_WORK_TAILPTR
LI temp_data_2, 0
LWU temp_data_2, 0x100(xfer)
BNE temp_data_2, expect1, test_failed

NOP
NOP
NOP

###read ring1 tailptr data
LI address8, 0x00110040
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x120)  ;
.insn s 43,0,address8,cluster_scratch_ring_read(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG3_pos,1) 	;

LI expect1, 0x00000111
LI temp_data_2, 0
LWU temp_data_2, 0x120(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000222
LI temp_data_2, 0
LWU temp_data_2, 0x124(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000333
LI temp_data_2, 0
LWU temp_data_2, 0x128(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000444
LI temp_data_2, 0
LWU temp_data_2, 0x12C(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000555
LI temp_data_2, 0
LWU temp_data_2, 0x130(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000666
LI temp_data_2, 0
LWU temp_data_2, 0x134(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000777
LI temp_data_2, 0
LWU temp_data_2, 0x138(xfer)
BNE temp_data_2, expect1, test_failed

LI expect1, 0x00000888
LI temp_data_2, 0
LWU temp_data_2, 0x13C(xfer)
BNE temp_data_2, expect1, test_failed




NOP
NOP
NOP


#######################################
########workq is empty, add thread to ring2
#######################################
###for ring2
LI ringbase_base, 0x00010010
LI ringptr_base , 0x00010090

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30)  ;
.insn s 43,0,ringbase_base,cluster_scratch_write(cppcmd_data_ref)	 ;# cpp command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x38)  ;
.insn s 43,0,ringptr_base,cluster_scratch_write(cppcmd_data_ref)	 ;# cpp command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;


###write ring2 tailptr data
LI address8, 0x00120100
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x40)  ;
.insn s 43,0,address8,cluster_scratch_ring_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG3_pos,1) 	;


###for ring2 add thread
LI address, 0x00000008
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_ring_workq_add_thread(cppcmd_data_ref)	 ;# CPP Command write

##WAIT_ON_SIGNAL (SIG3_pos,1) 	;

NOP
NOP
NOP

###for ring2 add thread +1
LI address, 0x00000008
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x1)  ;
.insn s 43,0,address,cluster_scratch_ring_workq_add_thread(cppcmd_data_ref)	 ;# CPP Command write

##WAIT_ON_SIGNAL (SIG3_pos,1) 	;

NOP
NOP
NOP


###read ring2 tailptr
LI address4, 0x00010090
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x140)  ;
.insn s 43,0,address4,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG3_pos,1) 	;

LI expect2, EXPECT_THREAD_TAILPTR
LI temp_data_2, 0
LWU temp_data_2, 0x140(xfer)
BNE temp_data_2, expect2, test_failed

NOP
NOP
NOP






NOP
NOP
NOP


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
