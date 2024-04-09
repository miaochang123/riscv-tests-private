//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//  FileName: interthread_self.uc    
//  Author:   kprobst      
//  Created:  09/12/01     
//
//  Description: 
//	Checks CTX_ARB signaling
//	Checks all contexts and all threads.
//	Uses interthread signalling to wakeup
// Constraints: 
//      Utilizes all 8 threads 
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

; CTX0 through 6 swaps out waiting for [1]
; CTX7 sets CTX0's signal [1] then swaps out itself waiting for [1]
; CTX0 sets CTX1's signal [1] then swaps out itself waiting for [2]
; CTX1 sets CTX2's signal [1] then swaps out itself waiting for [2]
; etc.
; CTX5 sets CTX6's signal [15], then swaps out
; CTX6 sets CTX7's signal [15], then swaps out
; CTX7 wakes up and test ends

.areg count1		2
.areg count2		3
.areg count3		4

.areg context_to_sig	6
.areg expect		7
.areg expect_wakeup	8
.areg expect_sig	9
.areg me_num            10
.areg cluster           11

.breg pass_count	0
.breg sig_num           1
.breg sig_gpr		2
.breg @abs_count	4
.breg b_csr_rd_data	5
.breg check_count	6
.breg data              7
 
; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[data,0]

alu_shf[cluster,0x3F, AND,data,>>24]
alu_shf[me_num,0xF, AND,data,>>3]

    
	br=ctx[0, ctx_CTX_A_start# ]	 
	br=ctx[1, ctx_CTX_B_start# ]	 
	br=ctx[2, ctx_CTX_C_start# ]	 
	br=ctx[3, ctx_CTX_D_start# ]	 
	br=ctx[4, ctx_CTX_E_start# ]	 
	br=ctx[5, ctx_CTX_F_start# ]	 
	br=ctx[6, ctx_CTX_G_start# ]	 
	br=ctx[7, ctx_CTX_H_start# ]	 

	; INTERTHREAD_SIG Csr	(OLD)
	; ME number = bits [11:7]
	; Thread #  = bits [6:4]
	; Signal #  = bits [3:0]

	; INTERTHREAD_SIG Csr   (NEW...05/14/2013)	
	; ME number = bits [13:9]
	; Thread #  = bits [8:6]
	; Signal #  = bits [5:2]


ctx_CTX_A_start#: 
	immed[context_to_sig,0x1]
	immed[check_count,0x3C0]
	immed[@abs_count,0x0]		; Initialize abs_count in context 0 only
 	br[start_test#]

ctx_CTX_B_start#:
	immed[context_to_sig,0x2]
	immed[check_count,0x3CF]
 	br[start_test#]

ctx_CTX_C_start#:
	immed[context_to_sig,0x3]
	immed[check_count,0x3DE]
 	br[start_test#]

ctx_CTX_D_start#:
	immed[context_to_sig,0x4]
	immed[check_count,0x3ED]
 	br[start_test#]

ctx_CTX_E_start#:
	immed[context_to_sig,0x5]
	immed[check_count,0x3FC]
 	br[start_test#]

ctx_CTX_F_start#:
	immed[context_to_sig,0x6]
	immed[check_count,0x40B]
 	br[start_test#]

ctx_CTX_G_start#:
	immed[context_to_sig,0x7]
	immed[check_count,0x41A]
 	br[start_test#]

ctx_CTX_H_start#:
	immed[context_to_sig,0x0]
	immed[check_count,0x429] 	

start_test#:

	immed[pass_count,0x0]

	immed[sig_num,0x0]
	immed[count1,0x0]
	immed[count2,0x0]
	immed[count3,0x0]
	immed_w1[expect_wakeup,0x0001]
	immed_w0[expect_wakeup,0x0000]
	immed[expect_sig,0x0001]

	immed[sig_num,0x0]
	immed[$xfer0,0]  // Init, but no data should be pulled
	immed[$xfer1,0]  // Init, but no data should be pulled

	br!=ctx[7, not_ctx7# ]	

	; Wakeup next context
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]

not_ctx7#:
 
	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig1]	
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]             
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 

	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig2]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	
	
	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig3]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig4]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]             
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]		
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig5]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig6]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,            +,@abs_count]      
	ctx_arb[sig7]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 
	
	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig8]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig9]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig10]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig11]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig12]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 	
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig13]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 

	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig14]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 
	
	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

	; SWAP out
        alu[@abs_count,1,+,@abs_count]      
	ctx_arb[sig15]
        alu[count1,@abs_count,+,count1]      
        alu[count2,@abs_count,+,count2]      
        alu[count3,@abs_count,+,count3]              
 
	local_csr_rd[Active_CTX_Wakeup_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_wakeup,-,b_csr_rd_data]
	BNE[test_failed#]

	local_csr_rd[Active_CTX_Sig_Events]
	immed[b_csr_rd_data,0x0]
	alu[--,expect_sig,-,b_csr_rd_data]
	BNE[test_failed#]

	alu[pass_count,1,+,pass_count] 


	br=ctx[7, done# ]	
	nop
	nop
 
	; Wakeup next context 
	alu[sig_num,sig_num,+,1]	
	alu_shf[sig_gpr,--,B,sig_num,<<2]			
	alu_shf[sig_gpr,sig_gpr,OR,context_to_sig,<<6]			
	alu_shf[sig_gpr,sig_gpr,OR,me_num,<<9]			
	alu_shf[sig_gpr,sig_gpr,OR,cluster,<<24]			
	ct[interthread_signal,--,sig_gpr,0,1]	

        alu[@abs_count,1,+,@abs_count]      
        ;ctx_arb[sig1]
	
done#:
  alu[--,pass_count,-,0xf]
  BNE[test_failed#]
  alu[--,count1,-,check_count]
  BNE[test_failed#]
  alu[--,count2,-,check_count]
  BNE[test_failed#]
  alu[--,count3,-,check_count]
  BNE[test_failed#]
  BR[test_passed#]
  nop
  nop
  nop

test_passed#:
ctx_arb[kill]

test_failed#:
nop
nop
nop
ctx_arb[kill]

