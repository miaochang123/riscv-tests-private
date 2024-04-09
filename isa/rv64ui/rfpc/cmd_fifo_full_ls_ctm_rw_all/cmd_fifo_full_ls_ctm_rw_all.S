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


.equ SCRATCH_SIZE_DIV4,    0x4000
.equ CPP_MEM_ADDR,     0xf0000000
 
RVTEST_RV64U 
RVTEST_CODE_BEGIN

LI   xfer,          CPP_MEM_ADDR

LI   group_num,            0xe00
AND  group_num, group_num, a0
SRLI group_num, group_num, 0X9

ANDI cl_num,    a0,        0xf # core number 
LI   temp_data,            0x2
BEQ  cl_num,  temp_data,   ctm_rw

#BNE  cl_num,  temp_data,   test_passed   

LI   temp_data ,           0x1
BGE  cl_num,    temp_data, test_passed 

SLLI   address, group_num,     0xe
LI     end_count,SCRATCH_SIZE_DIV4
ADD    end_count,end_count,address

LI     temp_data, 0x1
SLLI   temp_data, temp_data, 0x1f
OR     data1, temp_data,   address

ADD temp_data, zero, data1
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x8(xfer) 

cls_write_loop:
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
LI  temp_data_1, 0x8  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x20(xfer) 
LI  temp_data_1, 0x9
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x24(xfer) 
LI  temp_data_1, 0xa
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x28(xfer) 
LI  temp_data_1, 0xb  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x2c(xfer)
LI  temp_data_1, 0xc  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x30(xfer)
LI  temp_data_1, 0xd  
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x34(xfer) 
LI  temp_data_1, 0xe
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x38(xfer) 
LI  temp_data_1, 0xf
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x3c(xfer) 

ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x4);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x8);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0xc);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x14);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1c);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x24);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x28);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x2c);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x34);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x38);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
ADDI data1,   data1,   0x40

ADD temp_data, zero, data1
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, data1
SW  temp_data, 0x8(xfer) 

BNE  address, end_count, cls_write_loop
#---------------------------------------------

SLLI   address, group_num, 0xe
LI     end_count,SCRATCH_SIZE_DIV4
ADD    end_count,end_count,address

LI     temp_data, 0x1
SLLI   temp_data, temp_data, 0x1f
OR     data1, temp_data,   address

cls_read_loop:
ADDI address, address, 0x0 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x60);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x70);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x4 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x130);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   expect, 0x0
LWU  expect, 0x50(xfer)
BNE  expect, data1, test_failed
LI   temp_data_1, 0x1
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x60(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x2
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x70(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x3
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x80(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x4
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x90(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x5
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x100(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x6
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x110(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x7
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x120(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x8
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x130(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x9
ADD  temp_data, temp_data_1,data1
 
LI   expect, 0x0
LWU  expect, 0x134(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xa
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x138(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xb
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x13c(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xc
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x140(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xd
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x144(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xe
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x148(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xf
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x14c(xfer)
BNE  expect, temp_data, test_failed

ADDI address, address, 0x20
ADDI data1,   data1,   0x40

BNE  address, end_count,  cls_read_loop

J test_passed

ctm_rw:

SLLI   address, group_num, 0xe
LI     end_count,SCRATCH_SIZE_DIV4
ADD    end_count,end_count,address


ADD temp_data, zero, address
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, address
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, address
SW  temp_data, 0x8(xfer) 

ctm_write_loop:
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
LI  temp_data_1, 0x8  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x20(xfer) 
LI  temp_data_1, 0x9
ADD temp_data, temp_data_1, address
SW  temp_data, 0x24(xfer) 
LI  temp_data_1, 0xa
ADD temp_data, temp_data_1, address
SW  temp_data, 0x28(xfer) 
LI  temp_data_1, 0xb  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x2c(xfer)
LI  temp_data_1, 0xc  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x30(xfer)
LI  temp_data_1, 0xd  
ADD temp_data, temp_data_1, address
SW  temp_data, 0x34(xfer) 
LI  temp_data_1, 0xe
ADD temp_data, temp_data_1, address
SW  temp_data, 0x38(xfer) 
LI  temp_data_1, 0xf
ADD temp_data, temp_data_1, address
SW  temp_data, 0x3c(xfer)  

ADDI address, address, 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x8);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x28);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x30);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x38);
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8

ADD temp_data, zero, address
SW  temp_data, 0x0(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, address
SW  temp_data, 0x4(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, address
SW  temp_data, 0x8(xfer) 

BNE  address, end_count, ctm_write_loop
#-------------------------------------------------
SLLI   address, group_num, 0xe
LI     end_count,SCRATCH_SIZE_DIV4
ADD    end_count,end_count,address
ADD    data1,   zero,  address 
ctm_read_loop:

ADDI address, address, 0x0 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x170);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x8 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x180);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x190);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADDI address, address, 0x8 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1a0);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

ADDI address, address, 0x8 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x1b0);
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

LI   expect, 0x0
LWU  expect, 0x170(xfer)
#                 #ceshi
#SD    expect,  0x200(xfer) 
#LI  address,   0x1000
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x200);
#.insn s 43,0,address,memory_unit_write(cppcmd_data_ref);# CPP Command read 
#WAIT_ON_SIGNAL (SIG1_pos,1);  

BNE  expect, data1, test_failed
LI   temp_data_1, 0x1
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x174(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x2
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x180(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x3
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x184(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x4
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x190(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x5
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x194(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x6
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x1a0(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x7
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x1a4(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x8
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x1b0(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0x9
ADD  temp_data, temp_data_1,data1
 
LI   expect, 0x0
LWU  expect, 0x1b4(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xa
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x1b8(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xb
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x1bc(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xc
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x1c0(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xd                        
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x1c4(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xe
ADD  temp_data, temp_data_1,data1

LI   expect, 0x0
LWU  expect, 0x1c8(xfer)
BNE  expect, temp_data, test_failed
LI   temp_data_1, 0xf
ADD  temp_data, temp_data_1,data1 

LI   expect, 0x0
LWU  expect, 0x1cc(xfer)
BNE  expect, temp_data, test_failed




ADDI address, address, 0x20
ADDI data1, data1, 0x40
BNE  address, end_count,  ctm_read_loop

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
      

