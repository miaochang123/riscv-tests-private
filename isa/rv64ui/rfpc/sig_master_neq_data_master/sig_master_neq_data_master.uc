// Run with 4 contexts enabled (0,2,4,6)
.num_contexts 4
.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 $xfer16 $xfer17 $xfer18 $xfer19 $xfer20 $xfer21 $xfer22 $xfer23 $xfer24 $xfer25 $xfer26 $xfer27 $xfer28 $xfer29 $xfer30 $xfer31

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

/*
.areg me_num    0
.areg cl_num    1
.areg this_ctx  2
.areg write_data 3
.areg address    4
.areg data       5

.breg expect0   0
.breg expect1   1
.breg expect2   2
.breg expect3   3
.breg expect4   4
.breg expect5   5
.breg expect6   6
.breg expect7   7
.breg expect8   8
.breg expect9   9
.breg expect10   10
.breg expect11   11
.breg expect12   12
.breg expect13   8
.breg expect14   8
.breg expect15   8
*/

#define WRITING_ME   4
#define READING_ME   7

alu_shf[write_data,--,B,READING_ME,<<16]
local_csr_wr[cmd_indirect_ref_0,write_data]  ; Set up the override SIGNAL_MASTER ID

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]
alu_shf[cl_num,0x3F, AND,me_num,>>24]
alu_shf[this_ctx,0x7, AND,me_num]
alu_shf[me_num,0xF, AND,me_num,>>3]

alu_shf[data,--,B,this_ctx,<<16]  ; Put context # into [19:16] of data
alu_shf[address,--,B,this_ctx,<<8]  ; Put context # into [11:8] of data

alu[--,me_num,-,WRITING_ME]
BEQ[writing_me_code#]
alu[--,me_num,-,READING_ME]
BEQ[reading_me_code#]
BR[test_passed#]      ; any other active MEs do nothing

writing_me_code#:

alu[$xfer0,data,+,0]
alu[$xfer1,data,+,1]
alu[$xfer2,data,+,2]
alu[$xfer3,data,+,3]
alu[$xfer4,data,+,4]
alu[$xfer5,data,+,5]
alu[$xfer6,data,+,6]
alu[$xfer7,data,+,7]
alu[$xfer8,data,+,8]
alu[$xfer9,data,+,9]
alu[$xfer10,data,+,10]
alu[$xfer11,data,+,11]
alu[$xfer12,data,+,12]
alu[$xfer13,data,+,13]
alu[$xfer14,data,+,14]
alu[$xfer15,data,+,15]
alu[$xfer16,data,+,16]
alu[$xfer17,data,+,17]
alu[$xfer18,data,+,18]
alu[$xfer19,data,+,19]
alu[$xfer20,data,+,20]
alu[$xfer21,data,+,21]
alu[$xfer22,data,+,22]
alu[$xfer23,data,+,23]
alu[$xfer24,data,+,24]
alu[$xfer25,data,+,25]
alu[$xfer26,data,+,26]
alu[$xfer27,data,+,27]
alu[$xfer28,data,+,28]
alu[$xfer29,data,+,29]
alu[$xfer30,data,+,30]
alu[$xfer31,data,+,31]

br=ctx[0,ctx0_writing_code#]

mem[write,$xfer0,address,0,8], ctx_swap[sig1]

alu[--,--,B,1]   ; Override the signal_master
mem[write,$xfer16,address,0x40,8], sig_done[sig10], indirect_ref

BR[test_passed#]

ctx0_writing_code#:

// Wait here until other Sending contexts are done...
ctx_arb[sig2,sig4,sig6]

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer0,address,0,4], sig_done[sig1], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer4,address,0x10,4], sig_done[sig2], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer8,address,0x20,4], sig_done[sig3], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer12,address,0x30,4], sig_done[sig4], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer16,address,0x40,4], sig_done[sig5], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer20,address,0x50,4], sig_done[sig6], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer24,address,0x60,4], sig_done[sig7], indirect_ref

alu[--,--,B,1]   ; Override the signal_master
cls[write,$xfer28,address,0x70,4], sig_done[sig8], indirect_ref

BR[test_passed#]

reading_me_code#:

alu[expect0,data,+,0]
alu[expect1,data,+,1]
alu[expect2,data,+,2]
alu[expect3,data,+,3]
alu[expect4,data,+,4]
alu[expect5,data,+,5]
alu[expect6,data,+,6]
alu[expect7,data,+,7]
alu[expect8,data,+,8]
alu[expect9,data,+,9]
alu[expect10,data,+,10]
alu[expect11,data,+,11]
alu[expect12,data,+,12]
alu[expect13,data,+,13]
alu[expect14,data,+,14]
alu[expect15,data,+,15]
alu[expect16,data,+,16]
alu[expect17,data,+,17]
alu[expect18,data,+,18]
alu[expect19,data,+,19]
alu[expect20,data,+,20]
alu[expect21,data,+,21]
alu[expect22,data,+,22]
alu[expect23,data,+,23]
alu[expect24,data,+,24]
alu[expect25,data,+,25]
alu[expect26,data,+,26]
alu[expect27,data,+,27]
alu[expect28,data,+,28]
alu[expect29,data,+,29]
alu[expect30,data,+,30]
alu[expect31,data,+,31]

br=ctx[0,ctx0_reading_code#]

ctx_arb[sig10]               // Sending ME will send signal when data is ready

// Signal Sending ME CTX0 to start issueing the Pulls with sig_master != data_master
immed[$xfer0,0]

; INTERTHREAD_SIG Csr	
; ME number = bits [13:9]
; Thread #  = bits [8:6] 
; Signal #  = bits [5:2]

alu_shf[signal_address,--,B,4,<<9]                        ; me_num
alu_shf[signal_address,signal_address,OR,this_ctx,<<2]    ; Use this_ctx as the signal number
alu_shf[signal_address,signal_address,OR,cl_num,<<24] ; Ths ME_island
ct[interthread_signal,--, signal_address,0, 1]

// May want to add delay here...

mem[read,$xfer0,address,0,4], sig_done[sig12]
mem[read,$xfer8,address,0x20,4], sig_done[sig13]
mem[read,$xfer16,address,0x40,4], sig_done[sig14]
mem[read,$xfer24,address,0x60,4], sig_done[sig15]
ctx_arb[sig12,sig13,sig14,sig15]
BR[check_data#]

ctx0_reading_code#:

ctx_arb[sig1]
cls[read,$xfer0,address,0,4], sig_done[sig1]

ctx_arb[sig2]
cls[read,$xfer4,address,0x10,4], sig_done[sig2]

ctx_arb[sig3]
cls[read,$xfer8,address,0x20,4], sig_done[sig3]

ctx_arb[sig4]
cls[read,$xfer12,address,0x30,4], sig_done[sig4]

ctx_arb[sig5]
cls[read,$xfer16,address,0x40,4], sig_done[sig5]

ctx_arb[sig6]
cls[read,$xfer20,address,0x50,4], sig_done[sig6]

ctx_arb[sig7]
cls[read,$xfer24,address,0x60,4], sig_done[sig7]

ctx_arb[sig8]
cls[read,$xfer28,address,0x70,4], sig_done[sig8]

ctx_arb[sig1,sig2,sig3,sig4,sig5,sig6,sig7,sig8]

check_data#:

alu[--,$xfer0,-,expect0]
BNE[test_failed#]
alu[--,$xfer1,-,expect1]
BNE[test_failed#]
alu[--,$xfer2,-,expect2]
BNE[test_failed#]
alu[--,$xfer3,-,expect3]
BNE[test_failed#]
alu[--,$xfer4,-,expect4]
BNE[test_failed#]
alu[--,$xfer5,-,expect5]
BNE[test_failed#]
alu[--,$xfer6,-,expect6]
BNE[test_failed#]
alu[--,$xfer7,-,expect7]
BNE[test_failed#]
alu[--,$xfer8,-,expect8]
BNE[test_failed#]
alu[--,$xfer9,-,expect9]
BNE[test_failed#]
alu[--,$xfer10,-,expect10]
BNE[test_failed#]
alu[--,$xfer11,-,expect11]
BNE[test_failed#]
alu[--,$xfer12,-,expect12]
BNE[test_failed#]
alu[--,$xfer13,-,expect13]
BNE[test_failed#]
alu[--,$xfer14,-,expect14]
BNE[test_failed#]
alu[--,$xfer15,-,expect15]
BNE[test_failed#]
alu[--,$xfer16,-,expect16]
BNE[test_failed#]
alu[--,$xfer17,-,expect17]
BNE[test_failed#]
alu[--,$xfer18,-,expect18]
BNE[test_failed#]
alu[--,$xfer19,-,expect19]
BNE[test_failed#]
alu[--,$xfer20,-,expect20]
BNE[test_failed#]
alu[--,$xfer21,-,expect21]
BNE[test_failed#]
alu[--,$xfer22,-,expect22]
BNE[test_failed#]
alu[--,$xfer23,-,expect23]
BNE[test_failed#]
alu[--,$xfer24,-,expect24]
BNE[test_failed#]
alu[--,$xfer25,-,expect25]
BNE[test_failed#]
alu[--,$xfer26,-,expect26]
BNE[test_failed#]
alu[--,$xfer27,-,expect27]
BNE[test_failed#]
alu[--,$xfer28,-,expect28]
BNE[test_failed#]
alu[--,$xfer29,-,expect29]
BNE[test_failed#]
alu[--,$xfer30,-,expect30]
BNE[test_failed#]
alu[--,$xfer31,-,expect31]
BNE[test_failed#]

test_passed#:
nop
nop
	ctx_arb[kill]
test_failed#:
        nop
        nop
	ctx_arb[kill]
