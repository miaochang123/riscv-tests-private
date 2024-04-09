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
#define work_handled            x14
#define expect                  x15
#define expect_addr             x16
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
.macro cls_init_ring ring_number, base_address, log_size
        LI xfer , CPP_MEM_ADDR
        LI temp_data , \log_size
        SLLI temp_data , temp_data , 0x10
        LI temp_data_1 , \base_address
        SRLI temp_data_1 , temp_data_1 , 0x7
        OR temp_data , temp_data , temp_data_1 # temp_data -> cls_ring_base

        SD temp_data , 0x0(xfer)

        LI taddress , \ring_number 
        LI temp_data_1 , 0x10000
        SLLI taddress , taddress , 0x3
        ADD taddress , temp_data_1 , taddress # taddress -> cls_ring_address

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
        ADDI taddress , taddress , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI temp_data , 0x0
        SD temp_data , 0x0(xfer)
        ADDI taddress , taddress , 0x80
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1,0x0)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
        ADDI taddress , taddress , 0x0
        WAIT_ON_SIGNAL (SIG2_pos,1)

.endm

#;;; a CLS Event manager configuring macros
#;;  m cls_event_filter_config( filter, mask, match, filter_type )
#; Configure an event filter to a provided mask/match and filter type
.macro cls_event_filter_config filter, mask, match, filter_type 
        LI xfer , CPP_MEM_ADDR
        LI taddress , 0x20000
        LI temp_data , \filter
        SLLI temp_data , temp_data , 0x6
        OR taddress , taddress , temp_data

        LI temp_data , \filter_type
        SLLI temp_data , temp_data , 0x18
        LI temp_data_1 , \mask
        OR temp_data , temp_data , temp_data_1
        SW temp_data , 0x0(xfer)
        LI temp_data , \match
        SW temp_data , 0x8(xfer)
        ADDI taddress , taddress , 0x10

        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x0)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
        ADDI taddress , taddress , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)
.endm # event_filter_config

#;;; a Autopush signal monitoring macros
#;;  m cls_autopush_monitor_config( filter, me_num, xfer_reg, signal )
#; Configure an autopush monitor for a filter with ME number, transfer register and signal
.macro cls_autopush_monitor_config filter, me_num, ctxt_num, xfer_reg, signal 
        LI xfer , CPP_MEM_ADDR
        LI taddress , 0x30200
        #LI temp_data , \filter
        #SLLI temp_data , temp_data , 0x3
        #OR taddress , taddress , temp_data

        #ADDI temp_data , \group_num , 0x0
        #ADDI temp_data , temp_data , 0x4
        #SLLI temp_data , temp_data , 0x18

        #LI temp_data_1 , \signal
        #SLLI temp_data_1 , temp_data_1 , 0x10
        #OR temp_data , temp_data , temp_data_1

        #LI temp_data_1 , \xfer_reg
        #SLLI temp_data_1 , temp_data_1 , 0x2
        #OR temp_data , temp_data , temp_data_1

        #LI temp_data_1 , \ctxt_num
        #SLLI temp_data_1 , temp_data_1 , 0x7
        #OR temp_data , temp_data , temp_data_1

        #LI temp_data_1 , \ctxt_num
        #SLLI temp_data_1 , temp_data_1 , 0x13
        #OR temp_data , temp_data , temp_data_1
        
        LI temp_data , \xfer_reg
        LI temp_data_1 , \signal
        SLLI temp_data_1 , temp_data_1 , 0x13
        OR temp_data , temp_data , temp_data_1
        ADDI temp_data_1 , \me_num , 0x0
        SLLI temp_data_1 , temp_data_1 , 0x1a
        OR temp_data , temp_data , temp_data_1

        SD temp_data , 0x0(xfer)
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
        ADDI taddress , taddress , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)
.endm #cls_autopush_monitor_config

#;;  m cls_autopush_monitor_engage( filter )
#; This macro should be called to start monitoring an event filter, after autopush_monitor_config has been
#;  called once.
#; The macro uses 'one shot acknowledge'
.macro cls_autopush_monitor_engage filter 
        LI xfer , CPP_MEM_ADDR
        LI taddress , 0x30000
        LI temp_data , \filter
        SLLI temp_data , temp_data , 0x3
        OR taddress , taddress , temp_data
        LI temp_data , \filter
        LI temp_data_1 , 0x3
        SLLI temp_data_1 , temp_data_1 , 0x8
        OR temp_data , temp_data , temp_data_1

        SD temp_data , 0x0(xfer)
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
        ADDI taddress , taddress , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)
.endm #; cls_autopush_monitor_engage

#;;  m cls_autopush_user_event( event )
#; This macro pushes an event into UserEvent in the CLS event manager
.macro cls_autopush_user_event event 
        LI xfer , CPP_MEM_ADDR
        LI taddress , 0x30400
        ADDI temp_data , \event , 0x0

        SW temp_data , 0x0(xfer)
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0)
        .insn s 43,0,taddress,cluster_scratch_write(cppcmd_data_ref)
        ADDI taddress , taddress , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)
.endm #; cls_autopush_user_event


RVTEST_RV64U
RVTEST_CODE_BEGIN

LI work_handled , 0x0
LI count , EVENT_SOURCE_DONE
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
        #BEQ group_num , temp_data , event_monitor
        #J test_passed

event_monitor:
        cls_event_filter_config EVENT_FILTER, EVENT_FILTER_MASK, EVENT_FILTER_MATCH, EVENT_FILTER_TYPE 
        cls_autopush_monitor_config EVENT_FILTER, group_num , 0 , DataRef , SIG7  # event_data -> DataRef
        #LI address , 0x5
        #SLLI address , address , 0x2
        
        #LI taddress , GET_ME_NUM
        #ADDI taddress , taddress , 0x4
        #SLLI taddress , taddress , 0x9
        #OR taddress , taddress , address

        #LI taddress1 , PUT_ME_NUM
        #ADDI taddress1 , taddress1 , 0x4
        #SLLI taddress1 , taddress1 , 0x9
        #OR taddress , taddress1 , address

        LI address, 0x00010000 ##pull from data_master=8,push to data_master=4
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0)  ;
        .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

        LI address, 0x0001c000 ##pull from data_master=8,push to data_master=7
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x0,0x0)  ;
        .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

        WAIT_ON_SIGNAL (SIG4_pos,1)
LI count , EVENT_SOURCE_DONE
event_loop:
        cls_autopush_monitor_engage EVENT_FILTER 
        #ctx_arb[event_sig] -> SIG7
        #WAIT_ON_SIGNAL (SIG7_pos,1)
        
        LWU temp_data , 0x400(xfer)
        SRLI temp_data , temp_data , 0x4
        LI temp_data_1 , 0xf
        AND temp_data , temp_data , temp_data_1
        ##source = ($event_data>>4) & 0xf
        #
        ##alu[--,source,-,EVENT_SOURCE_DONE]
        BNE temp_data , count , event_loop
        #BNE[event_loop#]

event_loop_done:
    J test_passed

get_entries:
        WAIT_ON_SIGNAL (SIG4_pos,1)
        WAIT_ON_SIGNAL (SIG5_pos,1)
        LI temp_data_1 , 0x1
        SLLI temp_data_1 , temp_data_1 , 0x7
        LI temp_data , 0xf
        SLLI temp_data , temp_data , 0x8
        OR temp_data , temp_data , temp_data_1

get_loop: #get_base offset 0x100
        LI taddress , 0x0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x100)
        .insn s 43,0,taddress,cluster_scratch_ring_get(cppcmd_data_ref)
        ADDI taddress , address , 0x0
        WAIT_ON_SIGNAL (SIG1_pos,1)

        LI temp_data_1 , 0x0
        LWU temp_data , 0x104(xfer)
        #BEQ temp_data , temp_data_1 , get_loop

        LI temp_data_1 , 0x1
        BEQ temp_data , temp_data_1 , pass_check1
        J test_failed

pass_check1:
        LI temp_data_1 , 0x2
        LWU temp_data , 0x108(xfer)
        BEQ temp_data , temp_data_1 , pass_check2
        J test_failed

pass_check2:
        ADDI work_handled , work_handled , 0x1
        LI temp_data , WORK_TO_DO
        #BNE work_handled , temp_data , get_loop
        J work_complete

put_entries:
        cls_init_ring 0, 0x8000, 4 
        #LI taddress , GET_ME_NUM

        #ADDI taddress , taddress , 0x4
        #SLLI taddress , taddress , 0x9
        #OR taddress , taddress , address

        #LI taddress1 , EVENT_ME_NUM
        #ADDI taddress1 , taddress1 , 0x4
        #SLLI taddress1 , taddress1 , 0x9
        #OR taddress , taddress1 , address

        LI address, 0x0001c000 ##pull from data_master=4,push to data_master=7
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x0)  ;
        .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)

        LI address, 0x00020000 ##pull from data_master=4,push to data_master=8
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x0)  ;
        .insn s 43,0,address,cluster_scratch_reflect_from_sig_dst(cppcmd_data_ref)   

        WAIT_ON_SIGNAL (SIG5_pos,1)
        LI event , EVENT_SOURCE
        SLLI event , event , 0x4
        LI temp_data_1 , EVENT_TYPE
        OR  event , event , temp_data_1 #event

        LI xfer , CPP_MEM_ADDR
        LI temp_data_1 , 0x1234
        SW temp_data_1 , 0x200(xfer)
        LI temp_data_1 , 0x1
        SW temp_data_1 , 0x204(xfer)
        LI temp_data_1 , 0x2
        SW temp_data_1 , 0x208(xfer)
        LI temp_data_1 , 0x3
        SW temp_data_1 , 0x20c(xfer)
        LI temp_data_1 , 0x4
        SW temp_data_1 , 0x210(xfer)
        LI temp_data_1 , 0x5
        SW temp_data_1 , 0x214(xfer)
        LI temp_data_1 , 0x6
        SW temp_data_1 , 0x218(xfer)
        LI temp_data_1 , 0x7
        SW temp_data_1 , 0x21c(xfer)        
        LI temp_data_1 , 0x8
        SW temp_data_1 , 0x220(xfer)
        LI temp_data_1 , 0x9
        SW temp_data_1 , 0x224(xfer)
        LI temp_data_1 , 0xa
        SW temp_data_1 , 0x228(xfer)
        LI temp_data_1 , 0xb
        SW temp_data_1 , 0x22c(xfer)
        LI temp_data_1 , 0xc
        SW temp_data_1 , 0x230(xfer)
        LI temp_data_1 , 0xd
        SW temp_data_1 , 0x234(xfer)
        LI temp_data_1 , 0xe
        SW temp_data_1 , 0x238(xfer)
        LI temp_data_1 , 0xf
        SW temp_data_1 , 0x23c(xfer)

LI work_handled , 0x0
LI count , WORK_TO_DO
put_loop:
        LI taddress , 0x0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x200)
        .insn s 43,0,taddress,cluster_scratch_ring_put(cppcmd_data_ref)
        ADDI taddress , address , 0x0

        cls_autopush_user_event event 

        WAIT_ON_SIGNAL (SIG1_pos,1)
        ADDI work_handled , work_handled , 0x1
        BNE work_handled , count , put_loop

put_loop_done:
        LI event , EVENT_SOURCE_DONE
        SLLI event , event , 0x4
        LI temp_data_1 , EVENT_TYPE
        OR event  , event , temp_data_1
        cls_autopush_user_event event 



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
