;-----------------------
; TEST_NAME: ring_add_tail.uc
;	Runs on any # of MEs.  Run on ALL for fuller coverage
;-----------------------
.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 
.addr sig1 1
.addr sig2 2
.addr sig3 3
.addr sig4 4
.addr sig5 5
.addr sig6 6
.addr sig7 7
.addr sig8 8
.addr sig9 9
.addr sig10 10
.addr sig11 11
.addr sig12 12
.addr sig13 13
.addr sig14 14
.addr sig15 15


.areg  ringbase_base 1
.areg  ringptr_base  2
.areg  len           3
.areg  ret_address   5
.areg  full_empty_sts  6
.areg  put_offset_reg 8
.areg  tail_offset   9
.areg  ring1         10
.areg  ring2         11
.areg  event_base      12
.areg  data          13
.areg  expect_data   0
.areg  done_offset   14
.areg  loop_count    15

.breg  data2         2
.breg  offset1       3
.breg  offset2       4
.breg  pass_fail_status  7
.breg  head_tail_ptr1   8
.breg  head_tail_ptr2   9
.breg  sig_num         11
.breg  sig_gpr         12
.breg  cl_num        13
.breg  me_num        0
.breg ctr            1

#define EMPTY       0
#define NOT_FULL_AND_NOT_EMPTY   1
#define FULL        3

#define FILTER_STATUS  0x0
#define FILTER_MASK    0x10
#define FILTER_MATCH   0x18

#define FIRST_ME   4

#macro add_delay[delay_count]

immed[ctr,delay_count]
sleep_label#:
  nop
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]

#endm

immed[pass_fail_status, 0]

; The ME_NUM is in bits [7:3]
; CL_NUM[3:0] is in bit [28:25]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]

alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

alu[me_num,me_num,-,FIRST_ME]
BEQ[continue_test#]             ; Firse ME will be 0 after this

; When running with multiple ME's, we want each ME to wait until previous one is complete
ctx_arb[sig7]

continue_Test#:

immed[ringbase_base,0]
immed_w1[ringbase_base,0x1]
alu_shf[ringbase_base,ringbase_base,OR,cl_num,<<26]

immed[ringptr_base,0x80]
immed_w1[ringptr_base,0x1]
alu_shf[ringptr_base,ringptr_base,OR,cl_num,<<26]

alu_shf[offset1,--,B,me_num,<<3]

; Use me_num as the BaseAddr of first ring
alu_shf[ring1,--,B,me_num,<<2]
alu_shf[ring1,ring1,OR,cl_num,<<26]

alu[data,--,B,me_num]
; Report all events
alu_shf[data,data,OR,0xF,<<24]
alu[$xfer0,--,B,data]
immed[$xfer1,0]

; Set size field to 0 [18:16] : Ring size = 32
cls[write,$xfer0,ringbase_base,offset1,1], ctx_swap[sig1]

; Initialize head  pointers to 0
; Initialize tail pointers to the me_num
immed[$xfer0,0]
alu[$xfer0,--,B,me_num,<<16]
cls[write,$xfer0,ringptr_base,offset1,1], ctx_swap[sig1]

; Rings Should still BE empty

cls[read_le,$xfer0,ringbase_base,offset1,1], ctx_swap[sig1] 
alu[full_empty_sts,--,B,$xfer0,>>30]
alu[--,full_empty_sts,-,EMPTY]
BNE[test_failed#]

; Adjust the Tail PTR (The amount to add will be 9 + 1 = 10)

immed[tail_offset,9]
local_csr_wr[cmd_indirect_ref_0, tail_offset]              

alu_shf[--,--,B,1,<<6]   ; Bit 6 is Override ByteMask enable
cls[add_tail,--,ring1,0] ,indirect_ref

; Rings Should no longer be empty
;cls[read_le,$xfer0,ringbase_base,offset1,1], ctx_swap[sig1] 
;alu[full_empty_sts,--,B,$xfer0,>>30]
;alu[--,full_empty_sts,-,NOT_FULL_AND_NOT_EMPTY]
;BNE[test_failed#]

add_delay[10]

; Read Tail pointers - Check that tail pointer was updated correctly
alu[expect_data,me_num,+,tail_offset]
alu[expect_data,expect_data,+,1]
alu[expect_data,--,B,expect_data,<<16]

immed[loop_count,0]
assign_expect_data_loop#:

   alu[--,me_num,-,loop_count]
   BNE[assign_zero#]
   alu[*l$index0++,--,B,expect_data]
   BR[done_assign#]
assign_zero#:
   immed[*l$index0++,0]
done_assign#:
   alu[loop_count,loop_count,+,1]
   alu[--,loop_count,-,16]
   BNE[assign_expect_data_loop#]

; Check all 16 Tail pointers.
; The one just written should have been incremented by 9
; All the others should be "0"
read_tail_ptrs#:
alu_shf[len, --, B, 15,<<8]        ; We will override the length with "16"
alu_shf[len, len, OR, 1,<<7]       ; Override length enable bit
cls[read_le,$xfer0,ringptr_base,0,1], ctx_swap[sig1], indirect_ref

alu[--,$xfer0,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer2,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer4,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer6,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer8,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer10,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer12,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer14,-,*l$index1++]
BNE[test_failed#]

alu_shf[len, --, B, 15,<<8]        ; We will override the length with "16"
alu_shf[len, len, OR, 1,<<7]       ; Override length enable bit
cls[read_le,$xfer0,ringptr_base,0x40,1], ctx_swap[sig1], indirect_ref

alu[--,$xfer0,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer2,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer4,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer6,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer8,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer10,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer12,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer14,-,*l$index1++]
BNE[test_failed#]

local_csr_wr[mailbox0,0x44]

// Set the TAIL ptr back to 0
immed[$xfer0,0]
cls[write,$xfer0,ringptr_base,offset1,1], ctx_swap[sig1]

immed[sig_num,7]
alu_shf[sig_gpr,0x80,OR,sig_num,<<3]
local_csr_wr[Next_Neighbor_Signal,sig_gpr]

test_passed#: immed[pass_fail_status,0xACE]
	      local_csr_wr[mailbox0, pass_fail_status]              
	      ctx_arb[kill]

test_failed#: 
	      immed[sig_num,7]
	      alu_shf[sig_gpr,0x80,OR,sig_num,<<3]
	      local_csr_wr[Next_Neighbor_Signal,sig_gpr]
	      immed[pass_fail_status,0xBAD]
	      local_csr_wr[mailbox0, pass_fail_status]              
	      ctx_arb[kill]
