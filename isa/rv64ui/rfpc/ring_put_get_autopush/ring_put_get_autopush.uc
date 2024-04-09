;;; a Defines - WORK_LENGTH must be 6 for this test
#define WORK_TO_DO  6

#define PUT_ME_NUM    0
#define EVENT_ME_NUM  2
#define GET_ME_NUM    4
 
;; i Local scratch
#include "cls_rings.h"
#include "cls_events_autopush.h"
    
;;; a Documentation

// Basic workq test
//  1. initialize all MES in the island running the test
//  2. Set up the workq with work
//  3. Add thread to queue, and get work
//  4. Handle the work, repeat at 3
//  5. If the work supplied is done, then test passed

#define EVENT_SOURCE      1
#define EVENT_SOURCE_DONE 2
#define EVENT_TYPE 1
#define EVENT_FILTER 1
#define EVENT_FILTER_MASK  (0xf)
#define EVENT_FILTER_MATCH (0x1)
#define EVENT_FILTER_TYPE  (5)

;;; a Globals
.reg me_num, ctxt_num, island, address, address1, address2
.reg @work_handled

    .sig s1 s2 s3 s4 s5
    .addr s1 1
    .addr s2 2
    .addr s3 3
    .addr s4 4
    .addr s5 5

;;; a The test code

    immed[@work_handled,0]
    
    local_csr_rd[ ACTIVE_CTX_STS ]
    immed[ ctxt_num, 0 ]
    me_num = 15 & (ctxt_num>>3)
    me_num = me_num - 4
    island = 127 & (ctxt_num>>24)
    ctxt_num = ctxt_num & 7
    local_csr_wr[ MAILBOX0, me_num ]

    alu[--,me_num,-,PUT_ME_NUM]
    BEQ[put_entries#]

    alu[--,me_num,-,GET_ME_NUM]
    BEQ[get_entries#]

    alu[--,me_num,-,EVENT_ME_NUM]
    beq[event_monitor#]

    BR[ test_passed#]
//-------------------------------------
event_monitor#:
    .begin
    .reg volatile $event_data
    .sig volatile event_sig
    .reg source

    cls_event_filter_config( EVENT_FILTER, EVENT_FILTER_MASK, EVENT_FILTER_MATCH, EVENT_FILTER_TYPE )
    cls_autopush_monitor_config( EVENT_FILTER, me_num, 0, &$event_data, &event_sig )

    ; INTERTHREAD_SIG Csr	
  ; ME number = bits [13:9]
  ; Thread #  = bits [8:6]
  ; Signal #  = bits [5:2]

  alu_shf[address,--,B,5,<<2]              ; signal_number=5
//  alu_shf[address,address,OR,island,<<24]      ; Island number
  alu_shf[address1,address,OR,(GET_ME_NUM+4),<<9]       ; me_num
  alu_shf[address2,address,OR,(PUT_ME_NUM+4),<<9]       ; me_num

  CT[interthread_signal, -- ,address1,0,1]    ; Send interthread signal 
  CT[interthread_signal, -- ,address2,0,1]    ; Send interthread signal 

    local_csr_wr[mailbox2, 0x8]
    ctx_arb[s4]              // Wait for PUT ME to finish Init
    local_csr_wr[mailbox3, 0x8]

event_loop#:
    cls_autopush_monitor_engage( EVENT_FILTER )
    ctx_arb[event_sig]
    source = ($event_data>>4) & 0xf

    alu[--,source,-,EVENT_SOURCE_DONE]
    BNE[event_loop#]
    .end

event_loop_done#:
    br[test_passed#]

get_entries#:
    .begin
    .reg event
    .reg ring_address
    .reg len16
    .reg $work[16]
    .xfer_order $work

    ctx_arb[s4,s5]              // Wait for PUT and EVENT MES to finish their init first
    local_csr_wr[mailbox2, 0x8]
    local_csr_wr[mailbox3, 0x8]

    ring_address = 0
    len16 = (1<<7)|((0xf)<<8)

get_loop#:

    alu[ --, --, B, len16 ]
    cls[ring_get, $work[0], ring_address, 0, 8], indirect_ref, ctx_swap[s1]
    
    alu[--,$work[1],-,0]      
    beq[get_loop#]       // If work[1]==0, branch to get_loop...dont understand

    alu[--,$work[1],-,1] // Check some data     
    beq[pass_check1#]      
    br[test_failed#]      

pass_check1#:
    alu[--,$work[2],-,2] // Check some data       
    beq[pass_check2#]      
    br[test_failed#]      

pass_check2#:
    alu[@work_handled,@work_handled,+,1]
    alu[--,@work_handled,-,WORK_TO_DO]
    bne[get_loop#]
    br[work_complete#]

    .end

put_entries#:
    .begin
    .reg event
    .reg ring_address
    .reg len16
    .sig s1 
    .reg $work[16]
    .xfer_order $work

    cls_init_ring( 0, 0x8000, 4 )

    ; INTERTHREAD_SIG Csr	
  ; ME number = bits [13:9]
  ; Thread #  = bits [8:6]
  ; Signal #  = bits [5:2]

  alu_shf[address,--,B,4,<<2]              ; signal_number=4
//  alu_shf[address,address,OR,island,<<24]      ; Island number
  alu_shf[address1,address,OR,(GET_ME_NUM+4),<<9]       ; me_num
  alu_shf[address2,address,OR,(EVENT_ME_NUM+4),<<9]     ; me_num

  CT[interthread_signal, -- ,address1,0,1]    ; Send interthread signal 
  CT[interthread_signal, -- ,address2,0,1]    ; Send interthread signal 
 
    local_csr_wr[mailbox2, 0x8]
    ctx_arb[s5]                  // Wait for EVENT ME to finish init
    local_csr_wr[mailbox3, 0x8]

    event = (EVENT_SOURCE<<4) | (EVENT_TYPE<<0)
    ring_address = 0
    len16 = (1<<7)|((0xf)<<8)

    $work[0] = 0x1234
    $work[1] = 0x1
    $work[2] = 0x2
    $work[3] = 0x3
    $work[4] = 0x4
    $work[5] = 0x5
    $work[6] = 0x6
    $work[7] = 0x7
    $work[8] = 0x8
    $work[9] = 0x9
    $work[10] = 0xa
    $work[11] = 0xb
    $work[12] = 0xc
    $work[13] = 0xd
    $work[14] = 0xe
    $work[15] = 0xf

put_loop#:

    alu[ --, --, B, len16 ]
    cls[ring_put, $work[0], ring_address, 0, 8], indirect_ref, sig_done[s1]
    cls_autopush_user_event( event )
    ctx_arb[s1]

    alu[@work_handled,@work_handled,+,1]
    alu[--,@work_handled,-,WORK_TO_DO]
    bne[put_loop#]


put_loop_done#:
    event = (EVENT_SOURCE_DONE<<4) | (EVENT_TYPE<<0)
    cls_autopush_user_event( event )
   
    .end
    
;;; a The end
work_complete#:  

test_passed#:

test_passed_all_contexts_finished#:
        local_csr_wr[mailbox0, 0x11]
	local_csr_wr[mailbox1, 0x22]
	local_csr_wr[mailbox2, 0x33]
	local_csr_wr[mailbox3, 0x44]
	ctx_arb[bpt]
	nop
	nop
	nop
	nop
   
    ;; b The end

test_failed#:

    me_ctxt = 0xfa17
    local_csr_wr[mailbox0, me_ctxt]
    me_ctxt = (me_num<<16) | ctxt_num
    local_csr_wr[mailbox1, me_ctxt]
    ctx_arb[bpt]
    nop
    nop
    nop
    nop
