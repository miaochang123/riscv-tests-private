;-----------------------
; TEST_NAME: ct_interthread.uc
;		CTX0 of each ME signals CTX1 of every ME
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

.breg  me_num    0
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

 br=ctx[0, send#] 
 br[receive_and_check#]

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

send#:

; Use ME_NUM as signal
immed[me_ctx,1]
immed[$xfer1,0]
alu[this_me,--,B,me_num]
immed[me_num,15] // 4,5,6,7,8,9,10,11,12,13,14,15
send_loop#:

	; INTERTHREAD_SIG Csr	
	; ME number = bits [13:9]
	; Thread #  = bits [8:6]
	; Signal #  = bits [5:2]

	alu_shf[address,--,B,me_ctx,<<6]             ; Thread #
	alu_shf[address,address,OR,me_num,<<9]       ; me_num
	alu_shf[address,address,OR,cl_num,<<24]      ; This cluster
	alu_shf[address,address,OR,this_me,<<2]          ; Use this_me as the signal number

;	CT[interthread_signal,$xfer0,address,0,1]    ; Send interthread signal 
	CT[interthread_signal,--,address,0,1]    ; Send interthread signal 
    
	alu[me_num,me_num,-,1]
	
	alu[--,me_num,-,4]
	BGE[send_loop#]
Br[test_passed#]

; CTX1 does Receive checking
receive_and_check#:

	ctx_arb[sig4,sig5,sig6,sig7,sig8,sig9,sig10,sig11,sig12,sig13,sig14,sig15]  

nop
nop
nop

test_passed#:
nop
nop
	ctx_arb[kill]
test_failed#:
        nop
        nop
	ctx_arb[kill]
