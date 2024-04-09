;------------------------------------------------------------
; TEST_NAME: ring_events
;   Enable ME0 and ME1
;   
;	Exercise all 8 Filters  
;	Use all 8 FilterStatus Monitors
;
; Thornham updates: Expanded to 16 Filters and Monitors
;                   Enable ME2 and ME3 also	
;------------------------------------------------------------
.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 
#define SCRATCH_BASE  0x0

#define RING_SIZE            32
#define RING_INDEX            0
#define RING_INDEX_PLUS3      3
#define RING_FULL_THRESHOLD  24

#define MASTER_FIRST  5
#define MASTER_LAST   7

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

.areg  me_num        0
.areg  ringbase_base 1
.areg  ringptr_base  2
.areg  data2         4
.areg  ret_address   5
.areg  full_empty_sts  6
.areg  base          7
.areg  filter_base      8
.areg  autopush_base   9
.areg  sig_num       10
.areg  data_ref      11
.areg  master        12
.areg  ctx_num        13
.areg  watermark_left  14
.areg  me_num_id       15

.breg  data          1
.breg  size          2
.breg  offset1       3
.breg  offset2       4
.breg  ring1         5
.breg  ring2         6
.breg  count         7
.breg  filter_count1         7
.breg  filter_count2         8
.breg  filter_count3         9
.breg  filter_count4         10
.breg  cl_num        0
.breg  temp          11

#define FILTER_STATUS    0x0
#define FILTER_MASK      0x10
#define FILTER_MATCH     0x18
#define FILTER_ACK       0x20
#define USER_EVENT       0x400
#define AUTOPUSH_SIGNAL  0x200

;
; Put and get to entire ring for size 32. Check that get data is expected.
#define EMPTY       0
#define NOT_FULL_AND_NOT_EMPTY   1
#define FULL        3

immed[$xfer1,0]

; The ME_NUM is in bits [7:3]
; CL_NUM[3:0] is in bit [28:25]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]

//alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]
// ME's are numbers fro 4 to 15
alu[me_num_id,me_num,-,4]

alu[--,me_num,-,5]
BEQ[ME1_code#]
alu[--,me_num,-,6]
BEQ[ME1_code#]
alu[--,me_num,-,7]
BEQ[ME3_code#]

br!=ctx[0, test_passed#]

immed[ringbase_base,0]
immed_w1[ringbase_base,0x1]
//alu_shf[ringbase_base,ringbase_base,OR,cl_num,<<26]

immed[ringptr_base,0x80]
immed_w1[ringptr_base,0x1]
//alu_shf[ringptr_base,ringptr_base,OR,cl_num,<<26]

;------------------------------------------------------------------
; AutoPush
immed[autopush_base,0]
immed_w1[autopush_base,0x3]
//alu_shf[autopush_base,autopush_base,OR,cl_num,<<26]

immed[filter_base,0]
immed_w1[filter_base,0x2]
//alu_shf[filter_base,filter_base,OR,cl_num,<<26]

immed[master,MASTER_FIRST]

me_filter_loop#:

immed[ctx_num,0]

filter_loop#:

	;-----------------------------------------------
	;EventFilter0
	;-----------------------------------------------
	immed[data,0xF]
	alu[$xfer0,--,B,data]  
	cls[write,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]

	; Match on 1 which is event = NOT FULL
	; Match on 0 which is event = NOT EMTY
	immed[$xfer0,1]
	cls[write,$xfer0,filter_base,FILTER_MATCH,1], ctx_swap[sig1]

	alu_shf[data_ref,--,B,ctx_num,<<5]
	immed[sig_num,1]
	immed[offset1,AUTOPUSH_SIGNAL]
	immed[offset2,USER_EVENT]

; [13:0] data_ref
; [22:16] signal_ref
; [27:24] ME/master

; AutoPush Signal 0
	
autopush_loop0#:

	;-----------------------------------------------
	; AutoPush signal register
	;-----------------------------------------------
	alu_shf[data,--,B,data_ref,<<2]          
	alu_shf[data,data,OR,sig_num,<<16]      
	alu_shf[data,data,OR,ctx_num,<<20]      
	alu_shf[$xfer0,data,OR,master,<<24]   
	cls[write,$xfer0,autopush_base,offset1,1], ctx_swap[sig5]

	;-----------------------------------------------
	; AutoPush FilterStatusMonitor 0 - Need to rewrite each time to clear out EdgeDetected bit
	;-----------------------------------------------
	alu[data,--,B,ctx_num]     ; The AutopushSignal register # to use will match the CTX that we are signalling 
	alu[--,master,-,6]
	BNE[skip#]
	alu[data,8,+,ctx_num]    ; When accessing 8-15 (master==6) Need to Put a 1 in bit three here....
skip#:				 
	alu_shf[$xfer0,data,OR,3,<<8]           ; 1/2/3 is for Type of Monitoring
	cls[write,$xfer0,autopush_base,0,1], ctx_swap[sig4]

	; User Event Register - Generate an event Event 1 (NOTFULL)
	immed[$xfer0,1]
	cls[write,$xfer0,autopush_base,offset2,1], ctx_swap[sig6], defer[2]
	alu[data_ref,data_ref,+,1]
	alu[sig_num,sig_num,+,1]

	alu[--,sig_num,-,16]     ; We will set signals 1 through 15
	BNE[autopush_loop0#]


	alu[filter_base,filter_base,+,0x40]
	alu[autopush_base,autopush_base,+,0x8]
	alu[ctx_num,ctx_num,+,1]
	alu[--,ctx_num,-,8]      ; Signal CTX 0 through 7
	BNE[filter_loop#]

	alu[master,master,+,1]
	alu[--,master,-,MASTER_LAST]
	BNE[me_filter_loop#]


immed[watermark_left,RING_SIZE]
immed[data,RING_FULL_THRESHOLD]
alu[watermark_left,watermark_left,-,data]

immed[filter_base,0]
immed_w1[filter_base,0x2]
//alu_shf[filter_base,filter_base,OR,cl_num,<<26]

immed[autopush_base,0]
immed_w1[autopush_base,0x3]
//alu_shf[autopush_base,autopush_base,OR,cl_num,<<26]

; Read all signal_registers
cls[read,$xfer0,autopush_base,offset1,8], ctx_swap[sig4]

//br!=ctx[0,test_passed#]

	; Just Clear filter count to 0
	cls[read_le,$xfer2,filter_base,FILTER_ACK,1], ctx_swap[sig1]

	;-----------------------------------------------
	; AutoPush signal register
	;-----------------------------------------------
	alu_shf[data,--,B,0,<<2]         ; Data_ref = 0
	alu_shf[data,data,OR,5,<<16]      ; Sig_num = 5
	alu_shf[data,data,OR,0,<<20]      ; CTX = 0
	alu_shf[$xfer0,data,OR, MASTER_LAST,<<24]     ; ME3 = 7 now
	cls[write,$xfer0,autopush_base,offset1,1], ctx_swap[sig5]

	;-----------------------------------------------
	; AutoPush FilterStatusMonitor 0 - Need to rewrite each time to clear out EdgeDetected bit
	;-----------------------------------------------
	immed[ctx_num,0]    
	alu[data,--,B,ctx_num]                  ; Use AutopushSignal register 0  
	alu_shf[$xfer0,data,OR,2,<<8]           ; 1/2/3 is for Type of Monitoring
	cls[write,$xfer0,autopush_base,0,1], ctx_swap[sig4]

	; User Event Register - Generate an event Event 1 (NOTFULL)
	immed[$xfer0,1]
	cls[write,$xfer0,autopush_base,offset2,1], ctx_swap[sig6]


BR[test_passed#]

; Match on 8 which is event = Underflow
; Match on 9 which is event = Overflow
; Match on 1 which is event = NOT FULL
; Match on 0 which is event = NOT EMTY

immed[data,0xF]
alu[$xfer0,--,B,data]
immed[$xfer1,0]
immed[$xfer2,1]
immed[$xfer3,8]
immed[$xfer4,9]
immed[$xfer5,0]

cls[write,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]
cls[write,$xfer1,filter_base,FILTER_MATCH,1], ctx_swap[sig1]
cls[read_le,$xfer0,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count1,--,B,$xfer0]

alu[filter_base,filter_base,+,0x40]
alu[autopush_base,autopush_base,+,0x8]

cls[write,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]
cls[write,$xfer2,filter_base,FILTER_MATCH,1], ctx_swap[sig1]
cls[read_le,$xfer0,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count2,--,B,$xfer0]

alu[filter_base,filter_base,+,0x40]
alu[autopush_base,autopush_base,+,0x8]

cls[write,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]
cls[write,$xfer3,filter_base,FILTER_MATCH,1], ctx_swap[sig1]
cls[read_le,$xfer0,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count3,--,B,$xfer0]

alu[filter_base,filter_base,+,0x40]
alu[autopush_base,autopush_base,+,0x8]

cls[write,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]
cls[write,$xfer4,filter_base,FILTER_MATCH,1], ctx_swap[sig1]
cls[read_le,$xfer0,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count4,--,B,$xfer0]


immed[ringbase_base,0]
immed_w1[ringbase_base,0x1]
//alu_shf[ringbase_base,ringbase_base,OR,cl_num,<<26]

immed[ringptr_base,0x80]
immed_w1[ringptr_base,0x1]
//alu_shf[ringptr_base,ringptr_base,OR,cl_num,<<26]

alu_shf[offset1,--,B,me_num_id,<<3]

; Use me_num as the BaseAddr of first ring
//alu_shf[ring1,--,B,cl_num,<<26]
alu_shf[ring1,--,B,me_num_id,<<2]

; Initialize RingBase CSRs
; Set size field to 0 [18:16] : Ring size = 32
alu_shf[data,--,B,me_num_id,<<RING_INDEX]
alu_shf[data,data,OR,RING_INDEX,<<16]
alu_shf[data,data,OR,0xF,<<24]           ; Report all events

alu[$xfer0,--,B,data]
immed[$xfer1,0]
cls[write,$xfer0,ringbase_base,offset1,1], ctx_swap[sig1]

; Initialize head and tail pointers to 0 
immed[$xfer0,0]
cls[write,$xfer0,ringptr_base,offset1,1], ctx_swap[sig1]

immed[data,0]
alu[data,data,OR,me_num_id,<<16]
alu[data2,data,OR,1,<<20]
immed[size,RING_SIZE]

	load_addr[ret_address,put_size32_ret#]
	BR[put_loop#]
put_size32_ret#:

; ****************
; Ring should be Full now (any more PUTs should generate an overflow event)
; ****************

	cls[put,$xfer0,ring1,0,1], ctx_swap[sig1]   ; Should generate an overflow
	cls[put,$xfer0,ring1,0,1], ctx_swap[sig1]   ; Should generate an overflow
	cls[put,$xfer0,ring1,0,1], ctx_swap[sig1]   ; Should generate an overflow
	cls[put,$xfer0,ring1,0,1], ctx_swap[sig1]   ; Should generate an overflow

	immed[data,0]
	alu[data,data,OR,me_num_id,<<16]
	immed[size,RING_SIZE]

	load_addr[ret_address,get_size32_ret#]
	BR[get_loop#]
get_size32_ret#:
	cls[get,$xfer0,ring1,0,1], ctx_swap[sig1]   ; Should generate an underflow
	cls[get,$xfer0,ring1,0,2], ctx_swap[sig1]   ; Should generate an underflow
	cls[get,$xfer0,ring1,0,4], ctx_swap[sig1]   ; Should generate an underflow

; Read Event status registers

immed[filter_base,0]
immed_w1[filter_base,0x2]
//alu_shf[filter_base,filter_base,OR,cl_num,<<26]

; Read Not Empty count
cls[read_le,$xfer0,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count1,$xfer0,-,filter_count1]
alu[--,filter_count1,-,1]
BNE[test_failed#]

alu[filter_base,filter_base,+,0x40]

; Read Not FULL count
cls[read_le,$xfer1,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count2,$xfer1,-,filter_count2]
alu[--,filter_count2,-,2]
BNE[test_failed#]

alu[filter_base,filter_base,+,0x40]

; Read Underflow count
cls[read_le,$xfer2,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count3,$xfer2,-,filter_count3]
alu[--,filter_count3,-,3]
BNE[test_failed#]

alu[filter_base,filter_base,+,0x40]

; Read Overflow count
cls[read_le,$xfer3,filter_base,FILTER_STATUS,1], ctx_swap[sig1]
alu[filter_count4,$xfer3,-,filter_count4]
alu[--,filter_count4,-,4]
BNE[test_failed#]

BR[test_passed#]

;---------------------------------------------------------------------------
check_full_watermark#:

	; Check that rings are "NOT empty"
	immed[$xfer0, 0xBAD]
	
	cls[put,$xfer0,ring1,0,1], ctx_swap[sig1]	; Put one more on rings...should set Full Flag	
	cls[pop,$xfer0,ring1,0,1], ctx_swap[sig1]	; POP one  off rings...should clear Full Flag

	BR[ret_from_watermark#]

put_loop#:
	alu[--,size,-,watermark_left]
	BEQ[check_full_watermark#], defer[3]

ret_from_watermark#:
	alu[$xfer0,--,B,data]
	alu[$xfer1, 1 ,+,data]
	alu[$xfer2, 2 ,+,data]
	alu[$xfer3, 3 ,+,data]
	alu[$xfer4, 4 ,+,data]
	alu[$xfer5, 5 ,+,data]
	alu[$xfer6, 6 ,+,data]
	alu[$xfer7, 7 ,+,data]

	cls[put,$xfer0,ring1,0,8], ctx_swap[sig1]

	alu[size,size,-,8]
	BNE[put_loop#], defer[1]
	alu[data,data,+,8]

	RTN[ret_address]

get_loop#:
	cls[get,$xfer0,ring1,0,4], ctx_swap[sig1]

	alu[--,data,-,$xfer0]
	BNE[test_failed#]

	alu[data,data,+,1]
	alu[--,data,-,$xfer1]
	BNE[test_failed#]

	alu[data,data,+,1]
	alu[--,data,-,$xfer2]
	BNE[test_failed#]

	alu[data,data,+,1]
	alu[--,data,-,$xfer3]
	BNE[test_failed#]

	alu[data,data,+,1]

	alu[size,size,-,4]
	BNE[get_loop#]
	RTN[ret_address]

;-------------------------
;-------------------------
;-------------------------
ME3_code#:
br!=ctx[0,test_passed#]

ctx_arb[sig5]
alu[--,$xfer0,-,1]
BNE[test_failed#]
BR[test_passed#]

ME1_code#:

ctx_arb[sig1]
alu[--,$xfer0,-,1]
BNE[test_failed#]

ctx_arb[sig2]
alu[--,$xfer1,-,1]
BNE[test_failed#]

ctx_arb[sig3]
alu[--,$xfer2,-,1]
BNE[test_failed#]

ctx_arb[sig4]
alu[--,$xfer3,-,1]
BNE[test_failed#]

ctx_arb[sig5]
alu[--,$xfer4,-,1]
BNE[test_failed#]

ctx_arb[sig6]
alu[--,$xfer5,-,1]
BNE[test_failed#]

ctx_arb[sig7]
alu[--,$xfer6,-,1]
BNE[test_failed#]

ctx_arb[sig8]
alu[--,$xfer7,-,1]
BNE[test_failed#]

ctx_arb[sig9]
alu[--,$xfer8,-,1]
BNE[test_failed#]

ctx_arb[sig10]
alu[--,$xfer9,-,1]
BNE[test_failed#]

ctx_arb[sig11]
alu[--,$xfer10,-,1]
BNE[test_failed#]

ctx_arb[sig12]
alu[--,$xfer11,-,1]
BNE[test_failed#]

ctx_arb[sig13]
alu[--,$xfer12,-,1]
BNE[test_failed#]

ctx_arb[sig14]
alu[--,$xfer13,-,1]
BNE[test_failed#]

ctx_arb[sig15]
alu[--,$xfer14,-,1]
BNE[test_failed#]

test_passed#:
	nop
	nop
	ctx_arb[kill]
        BR[test_passed#]
	ctx_arb[kill]
test_failed#:
	nop
	nop
	ctx_arb[kill]
