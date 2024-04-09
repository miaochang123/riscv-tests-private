#;-----------------------
#; TEST_NAME: ring_put_get_autopush.S
#;----------------------- 

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
#define zero                    x0
#define cppcmd_data_ref         x3
#define count_len_loop          x4
#define hart_id                 x10 
#define data_mask               x11
#define count                   x12
#define len                     x13
#define wdata                   x14
#define waddr                   x15
#define expect                  x16
#define event_data              x17
#define address                 x19
#define event                   x20
#define il_num                  x21 
#define cl_num                  x22
#define group_num               x23
#define temp_data               x24
#define temp_data_1             x25
#define tcount                  x26
#define xfer                    x27
#define taddress1               x30
#define taddress                x31

.equ CPP_MEM_ADDR,      0xf0000000
.equ WORK_TO_DO , 6
.equ PUT_ME_NUM    , 0 # data master 4
.equ GET_ME_NUM    , 2 # data master 7
.equ EVENT_ME_NUM  , 4 # data master 8
.equ EVENT_SOURCE      , 1
.equ EVENT_SOURCE_DONE , 2
.equ EVENT_TYPE , 1
.equ EVENT_FILTER , 1
.equ EVENT_FILTER_MASK  , 0xf
.equ EVENT_FILTER_MATCH , 0x1
.equ EVENT_FILTER_TYPE  , 5
.equ DataRef , 0x400
.equ FILTER_STATUS  ,0x0
.equ FILTER_FLAGS   ,0x8
.equ FILTER_MASK    ,0x10
.equ FILTER_MATCH   ,0x18
.equ FILTER_ACK     ,0x20



RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
get_core_num:
        LI temp_data , 0xff
        AND cl_num ,  a0 , temp_data  # core number
        LI temp_data , 0xf00
        AND group_num , a0 , temp_data
        SRLI group_num , group_num , 0x8 
        SLLI address , group_num , 0x6
        LI temp_data , 0x1ff0000
        AND il_num , a0 , temp_data
        SRLI il_num , il_num , 0x10

alloc_job:
        LI temp_data , PUT_ME_NUM
        BEQ group_num , temp_data , put_entries
        LI temp_data , GET_ME_NUM
        BEQ group_num , temp_data , get_entries
        LI temp_data , EVENT_ME_NUM
        J event_monitor
        BEQ group_num , temp_data , event_monitor
        J test_passed

put_entries: #use 0x300 CPP
#init cls ring
# ring_num:0, cls_ring_base_address:0x8000 , log_size:4
LI waddr , 0x10000
LI wdata , 0x4080
SW wdata , 0x300(xfer)
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x300) 
.insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) #RingBase0
ADDI waddr , waddr , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI waddr , 0x10080
LI wdata , 0x0
SW wdata , 0x300(xfer)
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x300)
.insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) #RingPtrs0
ADDI waddr , waddr , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

#LI address, 0x0001c000 ##pull from data_master=4,push to data_master=7
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x300)  
#.insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

LI address, 0x00020000 ##pull from data_master=4,push to data_master=8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x300)  
.insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

LI xfer , CPP_MEM_ADDR  ##data for ring put
LI temp_data_1 , 0x1234
SW temp_data_1 , 0x300(xfer)
LI temp_data_1 , 0x1
SW temp_data_1 , 0x304(xfer)
LI temp_data_1 , 0x2
SW temp_data_1 , 0x308(xfer)
LI temp_data_1 , 0x3
SW temp_data_1 , 0x30c(xfer)
LI temp_data_1 , 0x4
SW temp_data_1 , 0x310(xfer)
LI temp_data_1 , 0x5
SW temp_data_1 , 0x314(xfer)
LI temp_data_1 , 0x6
SW temp_data_1 , 0x318(xfer)
LI temp_data_1 , 0x7
SW temp_data_1 , 0x31c(xfer)        
LI temp_data_1 , 0x8
SW temp_data_1 , 0x320(xfer)
LI temp_data_1 , 0x9
SW temp_data_1 , 0x324(xfer)
LI temp_data_1 , 0xa
SW temp_data_1 , 0x328(xfer)
LI temp_data_1 , 0xb
SW temp_data_1 , 0x32c(xfer)
LI temp_data_1 , 0xc
SW temp_data_1 , 0x330(xfer)
LI temp_data_1 , 0xd
SW temp_data_1 , 0x334(xfer)
LI temp_data_1 , 0xe
SW temp_data_1 , 0x338(xfer)
LI temp_data_1 , 0xf
SW temp_data_1 , 0x33c(xfer)

WAIT_ON_SIGNAL (SIG5_pos,1) #wait event monitor ready
LI data_mask , 0x0
put_loop:
        #LI waddr , 0x0
        LI waddr , 0x4000
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x300)
        .insn s 43,0,waddr,cluster_scratch_ring_put(cppcmd_data_ref)
        ADDI waddr , waddr , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)

LI address, 0x0001c000 ##pull from data_master=4,push to data_master=7
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x300)  
.insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

        LI wdata , 0x11
        SD wdata , 0x350(xfer)
        LI taddress , 0x30400
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x350)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref) #CLsAutoEvent
        ADDI waddr , waddr , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI waddr , 0x4000
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x320)
        .insn s 43,0,waddr,cluster_scratch_ring_put(cppcmd_data_ref)
        ADDI waddr , waddr , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI wdata , 0x11
        SD wdata , 0x350(xfer)
        LI taddress , 0x30400
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x350)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref) #CLsAutoEvent
        ADDI waddr , waddr , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)
        
LI wdata , 0x21
SW wdata , 0x350(xfer)
LI waddr , 0x30400
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x350)
.insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) #CLsAutoEvent
ADDI waddr , waddr , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)  

J test_passed

get_entries:
###get from ring0
WAIT_ON_SIGNAL (SIG4_pos,1)  #wait put ring ready
WAIT_ON_SIGNAL (SIG5_pos,1)  #wait event monitor ready
LI count , 0x0
LI data_mask , 0x0
get_loop:  #store in cpp mem offset 0x100
        LI waddr , 0x4000
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x100)
        .insn s 43,0,waddr,cluster_scratch_ring_get(cppcmd_data_ref)
        ADDI waddr , waddr , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)     
        
        ADDI count , count , 0x1
        
        LWU temp_data , 0x100(xfer)
        ADDI address , xfer , 0x100
        BEQ temp_data , data_mask , get_loop
        
        LI temp_data_1 , 0x1234
        #LWU temp_data , 0x100(xfer)
        BEQ temp_data , temp_data_1 , test_passed
        J test_failed
#LI temp_data_1 , 0x1
#BEQ temp_data , temp_data_1 , test_passed
#J test_failed

event_monitor: #filter0,  # use address 0x200
LI waddr , 0x20018 # FILTER_MATCH
LI wdata , 0x1
SW wdata , 0x200(xfer)
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x200)
.insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) # EventFilterMatch
ADDI waddr , waddr , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI waddr , 0x20010 # FILTER_MASK
LI wdata , 0xa00000f
SW wdata , 0x200(xfer)
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x200)
.insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) # EventFilterMask
ADDI waddr , waddr , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI waddr , 0x30200
LI wdata , 0x80000400 #DatRef , bit31 MasterIsland
LI temp_data , 0x8 #DataMaster = 8
SLLI temp_data , temp_data , 0x1a
OR wdata , wdata , temp_data
LI temp_data , SIG7
SLLI temp_data , temp_data , 0x13
OR wdata , wdata , temp_data
SD wdata , 0x200(xfer)
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x200)
.insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) # ClsAutoSignal
ADDI waddr , waddr , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI address, 0x00010000 ##pull from data_master=8,push to data_master=4
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x200)  ;
.insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

LI address, 0x0001c000 ##pull from data_master=8,push to data_master=7
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x200)  ;
.insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

WAIT_ON_SIGNAL (SIG4_pos,1) 

LI count , EVENT_SOURCE_DONE
LI address , 0xe0000000
LI expect , 0x21
event_loop:
        LI wdata , 0x300
        LI waddr , 0x30000
        SD wdata , 0x200(xfer)
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x200)
        .insn s 43,0,waddr,cluster_scratch_write(cppcmd_data_ref) # ClsAutoSignal
        ADDI waddr , waddr , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)

    LI count, 0x20
    delay_loop:
        ADDI count, count, -1
        BNE count , zero , delay_loop
        #WAIT_ON_SIGNAL (SIG7_pos,1)
        LD temp_data , 0x400(address)
        #LI xfer , 0xe0000000
        #LD expect , 0x400(xfer)
        #LD tcount , 0x410(xfer)
        #SRLI temp_data , temp_data , 0x4
        LI temp_data_1 , 0xff
        AND temp_data , temp_data , temp_data_1
        BNE temp_data , expect , event_loop

J test_passed

NOP
NOP
NOP

work_complete:

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
