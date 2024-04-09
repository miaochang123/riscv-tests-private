;-----------------------
; TEST_NAME: ct_reflect_Write.uc
;		Each ME (context 0) does 1 Cluster Target reflector write to every ME (including self)
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
alu_shf[cl_num,0x3F, AND,me_num,>>24]
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

	alu[data,--,B,me_ctx]
	alu_shf[data, data, OR, this_me, <<8]
	alu_shf[$xfer0, data, OR, me_num, <<12]
	
	alu_shf[address,--,B,me_ctx,<<7]             ; address_index = ctx << 7
	alu_shf[address,address,OR,this_me,<<2]      ; address_index =  (ctx << 7) | me_num 

	alu_shf[address,address,OR,2,<<22]            ; Select reflector

	alu_shf[address,address,OR,me_num,<<10]      ; Data Master = me_num
	alu_shf[address,address,OR,cl_num,<<24]      ; This cluster

//---------
// BUG: Overriding sig_num does not affect wakeup_Events
//    Will Use interthread to send signal to remote ME
// 	alu[ind_ref_data,--,B,me_num,<<9]    // Put sig_num in bits [12:9]  (using me_num as the signal number)
//	local_csr_wr[cmd_indirect_ref_0, ind_ref_data]
// 	alu[ind_ref_data,--,B,1,<<13]    // Bit 13 : Override SIG_NUM
//	CT[write_sig_both,$xfer0,address,0,1], ctx_swap[sig3] , indirect_ref
//---------
//	CT[write_sig_local,$xfer0,address,0,1], ctx_swap[sig3] 
	CT[reflect_write_sig_init,$xfer0,address,0,1], ctx_swap[sig3] 

	; INTERTHREAD_SIG Csr	
	; ME number = bits [13:9]
	; Thread #  = bits [8:6]
	; Signal #  = bits [5:2]

	alu_shf[address,--,B,me_ctx,<<6]             ; Thread #
	alu_shf[address,address,OR,me_num,<<9]       ; me_num
	alu_shf[address,address,OR,cl_num,<<24]      ; This cluster
	alu_shf[address,address,OR,this_me,<<2]      ; Use this_me as the signal number

	CT[interthread_signal,--,address,0,1]                 ; Send interthread signal  (No returned signal can be sent ????)
    
	alu[me_num,me_num,-,1]
	
	alu[--,me_num,-,4]
	BGE[send_loop#]
Br[test_passed#]

; CTX1 does Receive checking
receive_and_check#:

	ctx_arb[sig4,sig5,sig6,sig7,sig8,sig9,sig10,sig11,sig12,sig13,sig14,sig15]  

alu_shf[exp_data,this_ctx,OR,4,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer4]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,5,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer5]
BNE[test_failed#]


alu_shf[exp_data,this_ctx,OR,6,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer6]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,7,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer7]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,8,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer8]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,9,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer9]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,10,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer10]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,11,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer11]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,12,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer12]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,13,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer13]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,14,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer14]
BNE[test_failed#]

alu_shf[exp_data,this_ctx,OR,15,<<8]
alu_shf[exp_data,exp_data,OR,me_num,<<12]
alu[--,exp_data,-,$xfer15]
BNE[test_failed#]

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
