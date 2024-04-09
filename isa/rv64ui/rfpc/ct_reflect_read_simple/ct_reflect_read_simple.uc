;-----------------------
; TEST_NAME: ct_reflect_read.uc
;		Each ME (context 0) does 1 Cluster Target reflector read from every ME (including self)
;		Each ME must then use interthread signal to signal that data is there...
;		Each ME (context 1) than checks for correct data in transfer registers
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

.areg  data    0
.areg  data2   1
.areg  address 2
.areg  exp_data 3
.areg  ind_ref_data 4

.breg  me_num    0
.breg expect1   1
.breg expect2   2
.breg expect3   3
.breg expect4   4
.breg expect5   5
.breg expect6   6
.breg cl_num    7
.breg me_ctx    8
.breg this_ctx   9
.breg this_me    10

;-------------------------------------
; Set Up the BASE scratch address
; Each ME will use a different region
;--------------------------------------
; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]
alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[this_ctx,0x7, AND,me_num]
alu_shf[me_num,0xF, AND,me_num,>>3]


; NN address  = [7;2]
; NN mode     = [1;9]
; Sig CTX     = [3;10] <-- old
; Sig NUM     = [4;13] <-- old
; Data Master = [4;17]
; Cluster ID  = [ 4;28] <--- OLd

; Sig CTX     = [16:14] 
; Sig NUM     = [13:10]
; Island_ID = [29:24]
; [31:30] = 0
; Use ME_NUM as signal
immed[me_ctx,0]
immed[$xfer1,0]
alu[this_me,--,B,me_num]

immed[$xfer0,0]
immed[$xfer1,0x1111]
immed[$xfer2,0x2222]
immed[$xfer3,0x3333]
immed[$xfer4,0x4444]
immed[$xfer5,0x5555]
immed[$xfer6,0x6666]
immed[$xfer7,0x7777]

	alu_shf[address,--,B,me_ctx,<<7]             ; address_index = ctx << 7
	alu_shf[address,address,OR,2,<<2]            ; address_index =  (ctx << 7) | $xfer2
	alu_shf[address,address,OR,2,<<22]            ; Select reflector
	alu_shf[address,address,OR,me_num,<<10]      ; Data Master = me_num
	alu_shf[address,address,OR,cl_num,<<24]      ; This cluster

	CT[reflect_read_sig_init,$xfer0,address,0,1], ctx_swap[sig3]     // Read $xfer2 into $xfer0  expect 0x2222

	alu_shf[address,--,B,me_ctx,<<7]             ; address_index = ctx << 7
	alu_shf[address,address,OR,5,<<2]            ; address_index =  (ctx << 7) | $xfer5
	alu_shf[address,address,OR,2,<<22]            ; Select reflector
	alu_shf[address,address,OR,me_num,<<10]      ; Data Master = me_num
	alu_shf[address,address,OR,cl_num,<<24]      ; This cluster

	CT[reflect_read_sig_init,$xfer2,address,0,1], ctx_swap[sig3]     // Read $xfer5 into $xfer2  expect 0x5555

immed[expect1,0x2222]
immed[expect2,0x5555]

alu[--,$xfer0,-,expect1]
BNE[test_failed#]
alu[--,$xfer2,-,expect2]
BNE[test_failed#]

test_passed#:
nop
nop
	ctx_arb[kill]
test_failed#:
        nop
        nop
	ctx_arb[kill]
