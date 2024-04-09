;-----------------------
; TEST_NAME: ring_journal.uc
;	Runs on any # of MEs.  
;	May need to check how much multiple MEs adds (if anything)
; Inteneded to test ring_journal command
;-----------------------

.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 
#define SCRATCH_BASE  0x0

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
;
.areg  me_num        0
.areg  ringbase_base 1
.areg  ringptr_base  2
.areg  data2         4
.areg  ret_address   5
.areg  full_empty_sts  6
.areg  base          7

.breg  data          1
.breg  size          2
.breg  offset1       3
.breg  offset2       4
.breg  ring1         5
.breg  ring2         6
.breg  cl_num        0


#define EMPTY       0
#define NOT_FULL_AND_NOT_EMPTY   1
#define FULL        3

#define FILTER_STATUS  0x0
#define FILTER_MASK    0x10
#define FILTER_MATCH   0x18


; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]

alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

; ME's are numbered 4 - 15
alu[me_num,me_num,-,4]

; Setup EVENT FILTER
immed[base,0]
immed_w1[base,0x2]
alu_shf[base,base,OR,cl_num,<<26]

alu[--,me_num,-,0]
BEQ[setup_event_filter#]

; If not ME0 then setup a delay loop before continueing
immed[data,0xFF]
delay_loop#:
	alu[data,data,-,1]
	BNE[delay_loop#]

BR[continue_test#]

; Only ME0 should write to event Filter
setup_event_filter#:

	;-----------------------------------------------
	;EventFilter0
	;-----------------------------------------------
	immed[data,0xF]
	alu[$xfer0,--,B,data]
	cls[write,$xfer0,base,FILTER_MASK,1], ctx_swap[sig1]

	; Filter on overflow
	immed[$xfer0,0x9]
	cls[write,$xfer0,base,FILTER_MATCH,1], ctx_swap[sig1]

continue_test#:

immed[ringbase_base,0]
immed_w1[ringbase_base,0x1]
alu_shf[ringbase_base,ringbase_base,OR,cl_num,<<26]

immed[ringptr_base,0x80]
immed_w1[ringptr_base,0x1]
alu_shf[ringptr_base,ringptr_base,OR,cl_num,<<26]

alu_shf[offset1,--,B,me_num,<<3]
alu_shf[offset2,offset1,OR,1,<<6]

size32#:
; Use me_num as the BaseAddr of first ring
	alu_shf[ring1,--,B,cl_num,<<26]
	alu_shf[ring1,ring1,OR,me_num,<<2]
	alu_shf[ring2,ring1,OR,1,<<5]

	alu[data,--,B,me_num]
	; Report all events
	alu_shf[data,data,OR,0xF,<<24]
	alu[$xfer0,--,B,data]
	immed[$xfer1,0]
	; Set size field to 0 [18:16] : Ring size = 32
	cls[write,$xfer0,ringbase_base,offset1,1], ctx_swap[sig1]

	; OR a 1 into bit3 of BaseAddr for the 2nd ring
	alu_shf[data,data,OR,1,<<3]
	alu[$xfer0,--,B,data]
	cls[write,$xfer0,ringbase_base,offset2,1], ctx_swap[sig1]

	; Initialize head and tail pointers to 0 for both rings
	immed[$xfer0,0]
	cls[write,$xfer0,ringptr_base,offset1,1],ctx_swap[sig2]
	cls[write,$xfer0,ringptr_base,offset2,1],ctx_swap[sig2]



	immed[data,0]
	alu[data,data,OR,me_num,<<16]
	alu[data2,data,OR,1,<<20]
	immed[size,36]

	load_addr[ret_address,put_size32_ret#]
	BR[put_loop#]
put_size32_ret#:

;-----------------------------------------------
; Reading EventFilter0 status
;   Verifying that no overflow events occurred
;-----------------------------------------------
;immed[base,0]
;immed_w1[base,0x2]

cls[read_le,$xfer0,base,FILTER_STATUS,1], ctx_swap[sig1]
alu[--,$xfer0,-,0]
BNE[test_failed#]

	immed[data,35]
	alu[data,data,OR,me_num,<<16]
	alu[data2,data,OR,1,<<20]
	immed[size,32]

	load_addr[ret_address,pop_size32_ret#]
	BR[pop_loop#]
pop_size32_ret#:


BR[test_passed#]

put_loop#:
	alu[$xfer0,--,B,data]
	alu[$xfer4,--,B,data2]
	alu[data,data,+,1]
	alu[data2,data2,+,1]
	alu[$xfer1,--,B,data]
	alu[$xfer5,--,B,data2]
	alu[data,data,+,1]
	alu[data2,data2,+,1]
	alu[$xfer2,--,B,data]
	alu[$xfer6,--,B,data2]
	alu[data,data,+,1]
	alu[data2,data2,+,1]
	alu[$xfer3,--,B,data]
	alu[$xfer7,--,B,data2]

; JOURNAL
	cls[journal,$xfer0,ring1,0,4],ctx_swap[sig2]
	cls[journal,$xfer4,ring2,0,4],ctx_swap[sig2]

	alu[size,size,-,4]
	BNE[put_loop#], defer[2]
	alu[data,data,+,1]
	alu[data2,data2,+,1]

	RTN[ret_address]

pop_loop#:
; POP
	cls[pop,$xfer0,ring1,0,4],ctx_swap[sig2]
	cls[pop,$xfer4,ring2,0,4],ctx_swap[sig2]
	alu[--,data,-,$xfer3]
	BNE[test_failed#]
	alu[--,data2,-,$xfer7]
	BNE[test_failed#], defer[2]
	alu[data,data,-,1]
	alu[data2,data2,-,1]

	alu[--,data,-,$xfer2]
	BNE[test_failed#]
	alu[--,data2,-,$xfer6]
	BNE[test_failed#], defer[2]
	alu[data,data,-,1]
	alu[data2,data2,-,1]

	alu[--,data,-,$xfer1]
	BNE[test_failed#]
	alu[--,data2,-,$xfer5]
	BNE[test_failed#], defer[2]
	alu[data,data,-,1]
	alu[data2,data2,-,1]

	alu[--,data,-,$xfer0]
	BNE[test_failed#]
	alu[--,data2,-,$xfer4]
	BNE[test_failed#], defer[2]
	alu[data,data,-,1]
	alu[data2,data2,-,1]

	alu[size,size,-,4]
	BNE[pop_loop#]
	RTN[ret_address]

test_passed#:
	ctx_arb[kill]
test_failed#:
	nop
	nop
	ctx_arb[kill]
