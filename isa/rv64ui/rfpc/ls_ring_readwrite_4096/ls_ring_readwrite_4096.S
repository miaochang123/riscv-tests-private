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
#define ringptr_base     x9
#define hart_id          x10

#define data1            x13
#define data2            x14
#define xfer             x15

#define temp_data        x16

#define offset1          x17
#define offset2          x18
#define ring1            x19
#define ring1_rw         x20

#define ring_rw_offset   x22
#define expect           x23
#define temp_data_2      x24

#define address          x25

.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ EMPTY,                    0
.equ NOT_FULL_AND_NOT_EMPTY,   1
.equ FULL,                     3

.equ RING_SIZE,           4096
.equ RING_INDEX,            7
.equ RING_INDEX_PLUS3,      10
.equ RING_INDEX_PLUS2,      9
.equ RING_INDEX_PLUS2,      8
.equ RING_FULL_THRESHOWD, 3072



RVTEST_RV64U 
RVTEST_CODE_BEGIN

LI group_num, 0xe00
AND group_num , group_num, a0
SRLI group_num, group_num, 0X9
ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed 


SLLI temp_data_1, cl_num, 0x1a
LI   ringbase_base,   0x10000
OR   ringbase_base, ringbase_base, temp_data_1
LI   ringptr_base,    0x10080
OR   ringptr_base, ringptr_base, temp_data_1

LI   xfer,            CPP_MEM_ADDR

SLLI   offset1, group_num, 0x3

SLLI   ring1,  cl_num, 0x1a
SLLI   temp_data, group_num, 0x10
OR     ring1_rw,  ring1, temp_data  
SLLI   temp_data, group_num, 0x2
OR     ring1,  ring1, temp_data

# Initialize RingBase CSRs
# Set size field to 0 [18:16] : Ring size = 32
SLLI   temp_data, group_num,RING_INDEX 
LI     temp_data_1, RING_INDEX
SLLI   data1, temp_data_1, 0x10
OR     temp_data, temp_data, data1
SW     temp_data, 0x0(xfer)

ADD address, ringbase_base, offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x0
SW  temp_data, 0x0(xfer) 
ADD address, ringptr_base, offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write 
WAIT_ON_SIGNAL (SIG1_pos,1);

NOP
NOP
NOP

###****************************************
###RING
###****************************************

LI   data1,  0x0 
SLLI data1, group_num , 0x10
LI   temp_data,  0xf0000000 
OR   data2, data1, temp_data
LI size, RING_SIZE
LI ring_rw_offset, 0

put_loop:

#store the data to cpp memory
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

ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, ring1_rw, ring_rw_offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x7,0x30);
.insn s 43,0,address,cluster_scratch_ring_read(cppcmd_data_ref);# CPP Command write

ADD temp_data, zero, data2
SW  temp_data, 0x50(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x54(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x58(xfer)
LI  temp_data_1, 0x3
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x5c(xfer)
LI  temp_data_1, 0x4
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x60(xfer) 
LI  temp_data_1, 0x5
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x64(xfer)
LI  temp_data_1, 0x6
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x68(xfer)
LI  temp_data_1, 0x7
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x6c(xfer)

WAIT_ON_SIGNAL (SIG4_pos,1); 

#compare
LI   temp_data, 0x0
LWU  temp_data, 0x30(xfer)

                 #ceshi
#SD    temp_data,  0x120(xfer) 
#LI  address,   0x1000
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120);
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command read 
#WAIT_ON_SIGNAL (SIG1_pos,1); 

BNE temp_data, data1, test_failed
LI   temp_data_1, 0x1
ADD data1, temp_data_1,data1 

LI   temp_data, 0x0
LWU  temp_data, 0x34(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x38(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1 

LI   temp_data, 0x0
LWU  temp_data, 0x3c(xfer)
BNE temp_data, data1, test_failed
ADD data1, temp_data_1,data1

LI   temp_data, 0x0
LWU  temp_data, 0x40(xfer)
BNE temp_data, data1, test_failed
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

 ADD address, ring1_rw, ring_rw_offset 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x7,0x50);
.insn s 43,0,address,cluster_scratch_ring_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG5_pos,1); 


#------------------------ 

ADDI data2, data2, 0x8
ADDI ring_rw_offset, ring_rw_offset,0x20
LI  temp_data, 0x8
SUB size, size,temp_data
BNE size, zero, put_loop
 


#get ring

LI   data1,  0x0 
SLLI data1, group_num , 0x10
LI   temp_data,  0xf0000000 
OR   data2, data1, temp_data
LI size, RING_SIZE
LI ring_rw_offset, 0 

get_loop:
NOP
NOP
NOP

ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x80);
.insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x100);
.insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

#ring1
LI   temp_data, 0x0
LWU  temp_data, 0x80(xfer)

                 #ceshi
#SD    temp_data,  0x120(xfer) 
#LI  address,   0x1000
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x120);
#.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command read 
#WAIT_ON_SIGNAL (SIG1_pos,1); 

BNE temp_data, data2, test_failed
LI   temp_data_1, 0x1
ADD data2, temp_data_1,data2 

LI   temp_data, 0x0
LWU  temp_data, 0x84(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x88(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2 

LI   temp_data, 0x0
LWU  temp_data, 0x8c(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x100(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x104(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2 

LI   temp_data, 0x0
LWU  temp_data, 0x108(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x10c(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2
#---------------------------------------
LI  temp_data, 0x8
SUB size, size,temp_data
BNE size, zero, get_loop 

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
