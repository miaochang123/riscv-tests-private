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

#define zero             x0
#define cppcmd_data_ref  x3
#define size             x4
#define group_num        x5
#define cl_num           x6
#define temp_data        x7
#define end_count        x8

#define hart_id          x10


#define data1            x13
#define data2            x14
#define xfer             x15

#define expect           x16

#define address          x17 
#define temp_data_1      x18 

.equ SCRATCH_SIZE_DIV8,   0x2000
.equ CPP_MEM_ADDR,    0xf0000000
 
RVTEST_RV64U 
RVTEST_CODE_BEGIN

LI   xfer,          CPP_MEM_ADDR

LI   group_num,            0xe00
AND  group_num, group_num, a0
SRLI group_num, group_num, 0X9

ANDI cl_num,    a0,        0xf # core number 
LI   temp_data,           0x1
BGE  cl_num,    temp_data, test_passed 

SLLI   address, group_num, 0xa

LI  temp_data, 0xbad

SW  temp_data, 0x0(xfer)
SW  temp_data, 0x4(xfer)
SW  temp_data, 0x8(xfer)
SW  temp_data, 0xc(xfer)
SW  temp_data, 0x10(xfer)
SW  temp_data, 0x14(xfer)
SW  temp_data, 0x18(xfer)
SW  temp_data, 0x1c(xfer)
ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);  

ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD temp_data, zero, address
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, address
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, address
SW  temp_data, 0x8(xfer) 
LI  temp_data_1, 0x3  
ADD temp_data, temp_data_1, address
SW  temp_data, 0xc(xfer) 
LI  temp_data_1, 0x4
ADD temp_data, temp_data_1, address
SW  temp_data, 0x10(xfer) 
LI  temp_data_1, 0x5
ADD temp_data, temp_data_1, address
SW  temp_data, 0x14(xfer) 
LI  temp_data_1, 0x6  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x18(xfer)
LI  temp_data_1, 0x7  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x1c(xfer) 


ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x4);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x4);
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);


LI   expect, 0x0
LWU  expect, 0x4(xfer)
LI   temp_data_1, 0x1
ADD  temp_data, temp_data_1,address
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x2
ADD  temp_data, temp_data_1,address 

LI   expect, 0x0
LWU  expect, 0x8(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x3
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0xc(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x4
ADD  temp_data, temp_data_1,address 

LI   expect, 0x0
LWU  expect, 0x10(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x5
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x14(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x6
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x18(xfer)
BNE  expect, temp_data, test_failed
#-----------------------------------------------------------
LI  temp_data_1, 0x4
ADD temp_data, temp_data_1, address
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x5
ADD temp_data, temp_data_1, address
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x6
ADD temp_data, temp_data_1, address
SW  temp_data, 0x8(xfer) 
LI  temp_data_1, 0x7  
ADD temp_data, temp_data_1, address
SW  temp_data, 0xc(xfer) 
LI  temp_data_1, 0x8
ADD temp_data, temp_data_1, address
SW  temp_data, 0x10(xfer) 
LI  temp_data_1, 0x9
ADD temp_data, temp_data_1, address
SW  temp_data, 0x14(xfer) 
LI  temp_data_1, 0xa  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x18(xfer)
LI  temp_data_1, 0xb
ADD temp_data, temp_data_1, address
SW  temp_data, 0x1c(xfer) 

ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x4);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x0);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   expect, 0x0
LWU  expect, 0x0(xfer)
LI   temp_data_1, 0x5
ADD  temp_data, temp_data_1,address
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x6
ADD  temp_data, temp_data_1,address 

LI   expect, 0x0
LWU  expect, 0x4(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x7
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x8(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x8
ADD  temp_data, temp_data_1,address 

LI   expect, 0x0
LWU  expect, 0xc(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x9
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x10(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xa
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x14(xfer)
BNE  expect, temp_data, test_failed 
#--------------------------------------------
ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x4);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   expect, 0x0
LWU  expect, 0x4(xfer)
LI   temp_data_1, 0x5
ADD  temp_data, temp_data_1,address
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x6
ADD  temp_data, temp_data_1,address 

LI   expect, 0x0
LWU  expect, 0x8(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x7
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0xc(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x8
ADD  temp_data, temp_data_1,address 

LI   expect, 0x0
LWU  expect, 0x10(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x9
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x14(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xa
ADD  temp_data, temp_data_1,address

LI   expect, 0x0
LWU  expect, 0x18(xfer)
BNE  expect, temp_data, test_failed  

J    test_passed
NOP 
NOP
NOP

#passed and failed
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
      
 
