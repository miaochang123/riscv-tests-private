; Local Scratch = 8K x 64 bits = 16K x 32
;	Address = 16 bits
;		 [15:12] = ME num
;		 [11:3]  = Index to memory  (10 bits)  2**10 = 1K
#define LOCAL_SCRATCH_SIZE    64
#define LOCAL_SCRATCH_COUNT_LEN_LTE_4		16
#define LOCAL_SCRATCH_COUNT_LEN_GT_4		8
#define LOCAL_SCRATCH_COUNT_LEN_GT_8		8

LOCAL_SCRATCH_TEST#:
;------------------------------------------
; BEGIN LOCAL_SCRATCH_RW test
;------------------------------------------

; ME num goes into bits [15:12]
alu[base,--,B,me_num,<<11]
; MRT - Island ID = 1
;alu_shf[base,base,OR,1,<<26]

; Unique DATA for each ME
immed[data, 0]
alu_shf[data,data,OR,cluster,<<28]
alu_shf[data,data,OR,me_num,<<24]
alu[data2,--,B,data]

immed[endlen,END_LEN]
load_addr[return_address,LOCAL_SCRATCH_done_read_checks#]
immed[data_ref,0]

LOCAL_SCRATCH_outer_loop#:

immed[len,START_LEN]

LOCAL_SCRATCH_len_loop#:
   local_csr_wr[T_index,data_ref]	; Write T_index with data_ref (Start at either $xfer0 or $xfer1)
   immed[offset,0]
   alu_shf[inc_amount,--,B,len,<<2]

   alu[tmp,16,-,len]

   ; The jump_offset should be (16-length)*3    : There are 3 instructions per read data
   mul_step[tmp,3], 24x8_start
   mul_step[tmp,3], 24x8_step1
   mul_step[jump_offset,--],    24x8_last

   ; Calculate the Maximum Transaction count we can do for this LENGTH, Limit trans_count to 16
   alu[--,len,-,8]
   BGT[LOCAL_SCRATCH_set_len8_limit#]
   alu[--,len,-,4]
   BGT[LOCAL_SCRATCH_set_len4_limit#]

   immed[trans_count,LOCAL_SCRATCH_COUNT_LEN_LTE_4]	; Count if LEN <= 4
   br[LOCAL_SCRATCH_set_count#]
LOCAL_SCRATCH_set_len4_limit#:
   immed[trans_count,LOCAL_SCRATCH_COUNT_LEN_GT_4]	; Count if LEN > 4 
   br[LOCAL_SCRATCH_set_count#]
LOCAL_SCRATCH_set_len8_limit#:				; Count if LEN > 8
   immed[trans_count,LOCAL_SCRATCH_COUNT_LEN_GT_8]

LOCAL_SCRATCH_set_count#:
  alu[count,--,B,trans_count]
 
  LOCAL_SCRATCH_write_loop#:

	alu[*$index++,data,+,0]
	alu[*$index++,data,+,1]
	alu[*$index++,data,+,2]
	alu[*$index++,data,+,3]
	alu[*$index++,data,+,4]
	alu[*$index++,data,+,5]
	alu[*$index++,data,+,6]
	alu[*$index++,data,+,7]
	alu[*$index++,data,+,8]
	alu[*$index++,data,+,9]
	alu[*$index++,data,+,10]
	alu[*$index++,data,+,11]
	alu[*$index++,data,+,12]
	alu[*$index++,data,+,13]
	alu[*$index++,data,+,14]
	alu[*$index++,data,+,15]
	alu[*$index++,--,B,0]

	alu[tmp,len,-,1]
	alu[tmp,--,B,tmp,<<8]           ; Length goes to bits [12:8]
  	alu[tmp,tmp,OR,1,<<7]		; 1 is for overriding Length 
  	alu[tmp,tmp,OR,1,<<3]		; 1 is for overriding data_ref
  	alu[tmp,tmp,OR,data_ref,<<16]	; data_ref goes to bits [31:16]

  	cls[write,$xfer0,base,offset,8], ctx_swap[sig1], indirect_ref

	local_csr_wr[T_index,data_ref]	; Write T_index with data_ref (Start at either $xfer0 or $xfer1)
  	alu[offset,offset,+,inc_amount]
  	alu[data,data,+,len]

  	alu[count,count,-,1]
  	BNE[LOCAL_SCRATCH_write_loop#]
 
   immed[offset,0]
   alu_shf[count,--,B,trans_count]

   LOCAL_SCRATCH_read_loop#:

	alu[tmp,len,-,1]
	alu[tmp,--,B,tmp,<<2]
	alu[tmp,tmp,+,data_ref]
	local_csr_wr[T_index,tmp]	; Write T_index with ( (LEN-1) * 4) + data_ref

	alu[tmp,len,-,1]
	alu[tmp,--,B,tmp,<<8]           ; Length goes to bits [12:8]
  	alu[tmp,tmp,OR,1,<<7]		; 1 is for overriding Length 
  	alu[tmp,tmp,OR,1,<<3]		; 1 is for overriding data_ref
  	alu[tmp,tmp,OR,data_ref,<<16]	; data_ref goes to bits [31:16]

 	cls[read,$xfer0,base,offset,8], ctx_swap[sig2], indirect_ref

	alu[expect_data,data2,+,len]
	alu[expect_data,expect_data,-,1]

        jump[jump_offset,check_read_data_32bit#], targets[check_read_data_32bit#]

  LOCAL_SCRATCH_done_read_checks#:
  	alu[offset,offset,+,inc_amount]
  	alu[data2,data2,+,len]

  	alu[count,count,-,1]
  	BNE[LOCAL_SCRATCH_read_loop#]

  alu[len,len,+,1]
  alu[--,len,-,endlen]
  BNE[LOCAL_SCRATCH_len_loop#]

alu[data_ref,data_ref,+,4]

alu[--,data_ref,-,8]
BNE[LOCAL_SCRATCH_outer_loop#]

BR[test_passed#]
;------------------------------------------
; END LOCAL_SCRATCH_RW test
;------------------------------------------
