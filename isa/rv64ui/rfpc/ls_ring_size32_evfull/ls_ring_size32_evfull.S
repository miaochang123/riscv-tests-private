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

#define ring_status_base x12
#define data1            x13
#define data2            x14
#define xfer             x15

#define temp_data        x16

#define offset1          x17
#define offset2          x18
#define ring1            x19
#define ring2            x20

#define ring1_num        x21
#define ring2_num        x22
#define expect           x23
#define temp_data_2      x24

#define address          x25
#define autopush_base           x26
#define filter_base             x27
#define count            x28

.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ FILTER_STATUS,     0x0
.equ FILTER_MASK,       0x10
.equ FILTER_MATCH,      0x18               
.equ USER_EVENT,        0x400            
.equ AUTOPUSH_SIGNAL,   0x200

.equ EMPTY,                    0
.equ NOT_FULL_AND_NOT_EMPTY,   1
.equ FULL,                     3

.equ RING_SIZE,            32
.equ RING_INDEX,            0
.equ RING_INDEX_PLUS3,      3
.equ RING_FULL_THRESHOWD,  24

.macro add_delay delay_cnt
    LI count , \delay_cnt
    
    1:
        NOP
        ADDI count , count , -1
        BNE count , zero , 1b
.endm 


RVTEST_RV64U 
RVTEST_CODE_BEGIN

LI group_num, 0xe00
AND group_num , group_num, a0
SRLI group_num, group_num, 0X9
ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed 

LI   autopush_base,   0x30000
LI   filter_base,     0x20000
LI   ringbase_base,   0x10000
LI   ringptr_base,    0x10080
LI   ring_status_base,0x10100
LI   xfer,            CPP_MEM_ADDR

SLLI   offset1, group_num, 0x3
ORI    offset2, offset1,  0x40 

LI     ring1,  0
SLLI   temp_data, group_num, 0x2
OR     ring1,  ring1, temp_data
ORI    ring2,  ring1, 0x20

SRLI   ring1_num, ring1, 0x2
SRLI   ring2_num, ring2, 0x2

# Initialize RingBase CSRs
# Set size field to 0 [18:16] : Ring size = 32
SLLI   temp_data, group_num,RING_INDEX 
LI     temp_data_1, RING_INDEX
SLLI   data1, temp_data_1, 0x10
OR     temp_data, temp_data, data1
LI     temp_data_1, 0xf
SLLI   data1, temp_data_1, 0x18
OR     temp_data, temp_data, data1
SW     temp_data, 0x0(xfer)

ADD address, ringbase_base, offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1);

LI     temp_data_1, 1
SLLI   data1, temp_data_1,RING_INDEX_PLUS3
OR     temp_data, temp_data, data1
SW     temp_data, 0x0(xfer)

ADD address, ringbase_base, offset2 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write 
WAIT_ON_SIGNAL (SIG1_pos,1);
  
LI   temp_data, 0x0
SW  temp_data, 0x0(xfer) 
ADD address, ringptr_base, offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write 
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, ringptr_base,offset2 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write 
WAIT_ON_SIGNAL (SIG1_pos,1);


LI   temp_data, 0xf
SW  temp_data, 0x0(xfer) 

ADDI address, filter_base, FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);# CPP Command write 
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x9
SW  temp_data, 0x0(xfer) 

ADDI address, filter_base, FILTER_MATCH
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
LI   temp_data,  0x100000 
OR   data2, data1, temp_data  
LI size, RING_SIZE

put_loop:

LI  temp_data, 0x8
BEQ size, temp_data, check_full_watermark

ret_from_watermark:

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


#store the data to cpp memory
ADD temp_data, zero, data2
SW  temp_data, 0x20(xfer)
LI  temp_data_1, 0x1
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x24(xfer) 
LI  temp_data_1, 0x2
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x28(xfer)
LI  temp_data_1, 0x3
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x2c(xfer)
LI  temp_data_1, 0x4
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x30(xfer) 
LI  temp_data_1, 0x5
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x34(xfer)
LI  temp_data_1, 0x6
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x38(xfer)
LI  temp_data_1, 0x7
ADD temp_data, temp_data_1, data2
SW  temp_data, 0x3c(xfer)

ADD address, ring2,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x20);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1);  

ADDI data1, data1, 0x8
ADDI data2, data2, 0x8
LI  temp_data, 0x8
SUB size, size,temp_data
BNE size, zero, put_loop
 

#ring is full now, any more put operate will generate overflow
put_size32_ret:


LI offset2, USER_EVENT

LI  temp_data, 0xBAD
SW  temp_data, 0x100(xfer)
ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write 
ADD address, ring2,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write
ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write 
ADD address, ring2,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write
ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1);            
WAIT_ON_SIGNAL (SIG2_pos,1);
WAIT_ON_SIGNAL (SIG3_pos,1);
WAIT_ON_SIGNAL (SIG4_pos,1);
WAIT_ON_SIGNAL (SIG5_pos,1);

ADD address, ring_status_base,offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read

WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x0
LWU  temp_data, 0x0(xfer)
LI    temp_data_1,  1
SLL  expect,  temp_data_1, ring1_num
SLL  temp_data_2,  temp_data_1, ring2_num  
OR    expect,  expect, temp_data_2
SLLI  expect,  expect, 0x10
AND   temp_data, temp_data, expect
BNE temp_data, expect, test_failed 



#get ring
LI   data1,  0x0 
LI   data2, 0x0
SLLI data1, group_num , 0x10
LI   temp_data,  0x100000 
OR   data2, data1, temp_data
LI size, RING_SIZE

get_loop:
NOP
NOP
NOP

ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40);
.insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref);# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1); 

ADD address, ring2,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x70);
.insn s 43,0,address,cluster_scratch_get(cppcmd_data_ref);# CPP Command write
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

#ring2
LI   temp_data, 0x0
LWU  temp_data, 0x70(xfer)
BNE temp_data, data2, test_failed
LI   temp_data_1, 0x1
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x74(xfer)
BNE temp_data, data2, test_failed
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x78(xfer)
BNE temp_data, data2, test_failed 
ADD data2, temp_data_1,data2

LI   temp_data, 0x0
LWU  temp_data, 0x7c(xfer)
BNE temp_data, data2, test_failed 
ADD data2, temp_data_1,data2
#---------------------------------------
LI  temp_data, 0x4
SUB size, size,temp_data
BNE size, zero, get_loop   


LI    temp_data, 0X4
LI group_num, 0xf00
AND group_num , a0, group_num
SRLI group_num, group_num, 0X8
BNE  group_num, temp_data, test_passed

add_delay 99

 

ADDI address, filter_base, FILTER_STATUS 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0
LWU  temp_data, 0x90(xfer)
LI   temp_data_1, 0x14    #4mes*5=20
BNE  temp_data, temp_data_1, test_failed 

J test_passed

#check the stats of the ring
check_full_watermark:

#SRLI  temp_data,  offset1, 0xc
ADD address, ringbase_base, offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI   temp_data, 0x0
LWU  temp_data, 0x0(xfer)
SRLI  temp_data, temp_data, 0x1e
LI    expect,  NOT_FULL_AND_NOT_EMPTY
BNE temp_data, expect, test_failed

#SRLI  temp_data,  offset2, 0xc
ADD address, ringbase_base,offset2  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);
LI   temp_data, 0x0
LWU  temp_data, 0x10(xfer)
SRLI  temp_data, temp_data, 0x1e
LI    expect,  NOT_FULL_AND_NOT_EMPTY
BNE temp_data, expect, test_failed

#add one more on the ring
#ring1
LI  temp_data, 0xBAD
SW  temp_data, 0x0(xfer)

ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command put
WAIT_ON_SIGNAL (SIG1_pos,1); 

#SRLI  temp_data,  offset1, 0xc 
ADD address, ringbase_base,offset1  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x0
LWU  temp_data, 0x100(xfer)
SRLI  temp_data, temp_data, 0x1e
LI    expect,  FULL
BNE temp_data, expect, test_failed                                             
#ring2
LI  temp_data, 0xBAD 
SW  temp_data, 0x0(xfer)

ADD address, ring2,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_put(cppcmd_data_ref);# CPP Command put
WAIT_ON_SIGNAL (SIG1_pos,1); 

#SRLI  temp_data,  offset2, 0xc
ADD address, ringbase_base, offset2
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x108);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x0
LWU  temp_data, 0x108(xfer)
SRLI  temp_data, temp_data, 0x1e
LI    expect,  FULL
BNE temp_data, expect, test_failed 
#pop one more on the ring
#ring1
ADD address, ring1,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_pop(cppcmd_data_ref);# CPP Command put
WAIT_ON_SIGNAL (SIG1_pos,1);  

#SRLI  temp_data,  offset1, 0xc
ADD address, ringbase_base, offset1 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x110);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x0
LWU  temp_data, 0x110(xfer)
SRLI  temp_data, temp_data, 0x1e
LI    expect, NOT_FULL_AND_NOT_EMPTY
BNE temp_data, expect, test_failed
#ring2
ADD address, ring2,zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0);
.insn s 43,0,address,cluster_scratch_pop(cppcmd_data_ref);# CPP Command put
WAIT_ON_SIGNAL (SIG1_pos,1);  

#SRLI  temp_data,  offset2, 0xc
ADD address, ringbase_base, offset2 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x118);
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

LI   temp_data, 0x0
LWU  temp_data, 0x118(xfer)
SRLI  temp_data, temp_data, 0x1e
LI    expect, NOT_FULL_AND_NOT_EMPTY
BNE temp_data, expect, test_failed  

J ret_from_watermark

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

