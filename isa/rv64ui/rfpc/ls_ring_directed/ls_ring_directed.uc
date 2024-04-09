;-----------------------
; TEST_NAME: ring_size2048.uc
;	Runs on any # of MEs.  Run on ALL for fuller coverage
;     Each Me is allocated two rings
;     This is limited to the first 2 MEs
;	Each ME fills each of it's two rings up (PUTs) and reads back (GETs)
;		As it is filling up the ring, we will check the full/empty status at the full_watermark
;-----------------------
.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7
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

.addr $xfer0 0
.addr $xfer1 1
.addr $xfer2 2
.addr $xfer3 3
.addr $xfer4 4
.addr $xfer5 5
.addr $xfer6 6
.addr $xfer7 7

.areg  me_num          0
.areg  ringbase_base   1
.areg  ringptr_base    2
.areg  ret_address     5
.areg  full_empty_sts  6
.areg  base            7
.areg  watermark_left  8

.breg  data          1
.breg  size          2
.breg  offset        3
.breg  ring          5
.breg  cl_num        0

#define EMPTY       0
#define NOT_FULL_AND_NOT_EMPTY   1
#define FULL        3

#define RING_SIZE            2048
#define RING_INDEX            6
#define RING_INDEX_PLUS1      7
#define RING_INDEX_PLUS2      8
#define RING_INDEX_PLUS3      9
#define RING_FULL_THRESHOLD  1536

immed[watermark_left,RING_SIZE]
immed[data,RING_FULL_THRESHOLD]
alu[watermark_left,watermark_left,-,data]

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]

alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

; ME's are numbered 4 - 15
alu[me_num,me_num,-,4]

alu[--,me_num,-,0]
BNE[test_passed#]

immed[ringbase_base,0]
immed_w1[ringbase_base,0x1]
alu_shf[ringbase_base,ringbase_base,OR,cl_num,<<26]
alu_shf[offset,--,B,me_num,<<3]
immed[offset,0]

; Use me_num as the BaseAddr of the ring
;;alu_shf[ring,--,B,cl_num,<<26]
;;alu_shf[ring,ring,OR,me_num,<<2]
immed[ring,0]

; Initialize RingBase CSRs
; Set size field to 7 [18:16] : Ring size = 2048
;;alu_shf[data,--,B,me_num,<<RING_INDEX]
immed[data,0x100]
alu_shf[data,data,OR,RING_INDEX,<<16]
alu[$xfer0,--,B,data]
immed[$xfer1,0]
cls[write,$xfer0,ringbase_base,offset,1], ctx_swap[sig1]

; Initialize head and tail pointers to 0 for both rings
;;immed[$xfer0,0]
;;cls[write,$xfer0,ringptr_base,offset,1], ctx_swap[sig1]

immed[data,0]
alu[data,data,OR,me_num,<<16]
immed[size,RING_SIZE]

	load_addr[ret_address,put_size2048_ret#]
	BR[put_loop#]
put_size2048_ret#:

; ****************
; Ring should be Full now (any more PUTs should generate an overflow event)
; ****************

	immed[data,0]
	alu[data,data,OR,me_num,<<16]
	immed[size,RING_SIZE]
	alu[$xfer0,--,B,data]
	alu[$xfer1, 1 ,+,data]
	alu[$xfer2, 2 ,+,data]
	alu[$xfer3, 3 ,+,data]
	alu[$xfer4, 4 ,+,data]
	alu[$xfer5, 5 ,+,data]
	alu[$xfer6, 6 ,+,data]
	alu[$xfer7, 7 ,+,data]
	cls[journal,$xfer0,ring,0,8], ctx_swap[sig1]
        
	immed[data,0]
	alu[data,data,OR,me_num,<<16]
	immed[size,RING_SIZE]

	load_addr[ret_address,get_size2048_ret#]
	BR[get_loop#]
get_size2048_ret#:
BR[test_passed#]


check_full_watermark#:

	; Check that rings are "NOT empty"
	cls[read_le,$xfer0,ringbase_base,offset,1], ctx_swap[sig1]
	alu[full_empty_sts,--,B,$xfer0,>>30]
	alu[--,full_empty_sts,-,NOT_FULL_AND_NOT_EMPTY]
	BNE[test_failed#]

	immed[$xfer0, 0xBAD]

	; Put one more on rings...Each should set Full Flag
	cls[journal,$xfer0,ring,0,1], ctx_swap[sig1]
	; Check that rings are "FULL"
	cls[read_le,$xfer0,ringbase_base,offset,1], ctx_swap[sig1]
	alu[full_empty_sts,--,B,$xfer0,>>30]
	alu[--,full_empty_sts,-,FULL]
	BNE[test_failed#]

	; POP one  off rings...Each should clear Full Flag
	cls[pop,$xfer0,ring,0,1], ctx_swap[sig1]

	; Check that rings are "NOT empty"
	cls[read_le,$xfer0,ringbase_base,offset,1], ctx_swap[sig1]
	alu[full_empty_sts,--,B,$xfer0,>>30]
	alu[--,full_empty_sts,-,NOT_FULL_AND_NOT_EMPTY]
	BNE[test_failed#]

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

	cls[journal,$xfer0,ring,0,8], ctx_swap[sig1]

	alu[size,size,-,8]
	BNE[put_loop#], defer[1]
	alu[data,data,+,8]

	RTN[ret_address]

get_loop#:
	cls[get,$xfer0,ring,0,4], ctx_swap[sig1]
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

test_passed#:

	ctx_arb[kill]
test_failed#:
	nop
	nop
	ctx_arb[kill]
