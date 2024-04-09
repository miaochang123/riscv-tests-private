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
#define temp_data_1      x7
#define ringbase_base    x8
#define base             x9
#define hart_id          x10

#define upper_byte       x12
#define data1            x13
#define data2            x14
#define xfer             x15

#define temp_data        x16


#define ring1            x19
#define island_num       x20


#define expect           x23

#define address          x25

.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ EMPTY,                    0
.equ NOT_FULL_AND_NOT_EMPTY,   1
.equ FULL,                     3

.equ RING_SIZE,            512

.equ CT_TARGET_14_OFFSET,    56    // CT

.equ IMB_XPB_DEVICE_ID,         10
.equ CTM_CFG_DEVICE_ID,    6
.equ MISC_ENGINE_CFG_DEVICE_ID,    8
.equ ARM_ISLAND_0,      1
.equ PCI_ISLAND_0,      4
.equ PCI_ISLAND_1,      5
.equ PCI_ISLAND_2,      6
.equ PCI_ISLAND_3,      7
.equ NBI_ISLAND_0,      8
.equ NBI_ISLAND_1,      9
.equ CRYPTO_ISLAND_0,  12
.equ CRYPTO_ISLAND_1,  13
.equ ME_ISLAND_0,      32
.equ ME_ISLAND_1,      33
.equ ME_ISLAND_2,      34
.equ ME_ISLAND_3,      35
.equ ME_ISLAND_4,      36
.equ ME_ISLAND_5,      37
.equ ME_ISLAND_6,      38
.equ ILA_ISLAND_0,     48
.equ ILA_ISLAND_1,     49

.equ MU_EXTERNAL_ISLAND_0,  24
.equ MU_EXTERNAL_ISLAND_1,  25 
.equ MU_EXTERNAL_ISLAND_2,  26 
.equ MU_INTERNAL_ISLAND_0,  28 
.equ MU_INTERNAL_ISLAND_1,  29 


RVTEST_RV64U 
RVTEST_CODE_BEGIN

LI   xfer,            CPP_MEM_ADDR

LI   group_num, 0xe00
AND  group_num , group_num, a0
SRLI group_num,  group_num, 0x9

LI   temp_data_1 , 0x1
BGE  group_num, temp_data_1, test_passed

ANDI cl_num ,a0,   0xf # core number
LI   temp_data_1 , 0x1
BGE  cl_num,    temp_data_1, test_passed

SLLI   ring1,     group_num, 0xa

LI     temp_data, 0x0
SLLI   temp_data, group_num, 0x10
LI     temp_data_1, 0x0
SLLI   temp_data_1, temp_data_1, 0x1c
OR     temp_data,   temp_data, temp_data_1  
SW     temp_data, 0x0(xfer)

LI     temp_data, 0x0
SLLI   temp_data, group_num, 0x10
LI     temp_data_1, 0x2
OR     temp_data,  temp_data_1,temp_data  
SW     temp_data, 0x4(xfer)

LI     temp_data, 0x0
LI     temp_data_1, 0x1
SLLI   temp_data, temp_data_1, 0x1f
SW     temp_data, 0x8(xfer)

LI     temp_data, 0x0 
SW     temp_data, 0xc(xfer)

SLLI  address, group_num, 0xa
LI    cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

SLLI  address, group_num, 0xa
LI    cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x10);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

SLLI  address, group_num, 0xa
LI    cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x0,0x0);
.insn s 43,0,address,memory_unit_rd_qdesc(cppcmd_data_ref);# CPP Command write



LI   data1,  0x0 
SLLI data1, group_num , 0x10
LI   size,  RING_SIZE

put_loop:

ADD temp_data, zero, data1
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x8(xfer) 
LI  temp_data_1, 0x3  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0xc(xfer) 
LI  temp_data_1, 0x4
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x10(xfer) 
LI  temp_data_1, 0x5
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x14(xfer) 
LI  temp_data_1, 0x6  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x18(xfer)
LI  temp_data_1, 0x7  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x1c(xfer) 

SLLI  ring1,     ring1,    0x8
ADDI  address,   ring1,    0x0    
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,memory_unit_put(cppcmd_data_ref);# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1);
WAIT_ON_SIGNAL (SIG1_pos,1);
ADDI data1, data1, 0x8

LI  temp_data, 0x8
SUB size, size, temp_data
BNE size, temp_data, put_loop

ADD temp_data, zero, data1
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x8(xfer) 
LI  temp_data_1, 0x3  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0xc(xfer) 
LI  temp_data_1, 0x4
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x10(xfer) 
LI  temp_data_1, 0x5
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x14(xfer) 
LI  temp_data_1, 0x6  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x18(xfer)
LI  temp_data_1, 0x7  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x1c(xfer) 

SLLI  ring1,     ring1,    0x8
ADDI  address,   ring1,    0x0    
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x0);
.insn s 43,0,address,memory_unit_put(cppcmd_data_ref);# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1);
WAIT_ON_SIGNAL (SIG1_pos,1);   

#get ring
LI   data1,  0x0 
SLLI data1, group_num , 0x10
LI   size, RING_SIZE

get_loop:
NOP
NOP
NOP
SLLI  ring1,     ring1,    0x8
ADDI  address,   ring1,    0x0 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x40);
.insn s 43,0,address,memory_unit_get(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

#ring1
LI   temp_data, 0x0
LWU  temp_data, 0x40(xfer)
BNE temp_data, data1, test_failed
LI   temp_data_1, 0x1
ADD data1, temp_data_1,data1 

LI   temp_data, 0x0
LWU  temp_data, 0x44(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x48(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x4c(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x50(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x54(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x58(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x5c(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1


LI  temp_data, 0x8
SUB size, size,temp_data
BNE size, temp_data, get_loop 

SLLI  ring1,     ring1,    0x8
ADDI  address,   ring1,    0x0 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x5,0x40);
.insn s 43,0,address,memory_unit_get(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

#ring1
LI   temp_data, 0x0
LWU  temp_data, 0x40(xfer)
BNE temp_data, data1, test_failed
LI   temp_data_1, 0x1
ADD data1, temp_data_1,data1 

LI   temp_data, 0x0
LWU  temp_data, 0x44(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x48(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x4c(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x50(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x54(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1


J test_passed


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


