;-----------------------
; TEST_NAME: me_lm_push_pull.uc
;     Reads and writes unique values to entire CTM memory 
;	
; 
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

.areg expect   0
.areg me_num   8

.breg  me_ctx       1
.breg lm_address    4
.breg lm_data_ref   5
.breg lm_data_ref2  6
.breg mem_address   7
.breg ace      8

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]
alu_shf[me_ctx,0x7, AND,me_num]
alu_shf[me_num,0xF, AND,me_num,>>3]

// MEs are numbered 4-15
alu[me_num,me_num,-,4]

immed[ace,0xACE]
alu_shf[ace,--,B,ace,<<20]

// CTX0 = 0  
// CTX1 = 64 
// CTX2 = 128 
// CTX3 = 192 
// CTX4 = 256 
// CTX5 = 320
// CTX6 = 384 
// CTX7 = 448

alu_shf[lm_address,--,B,me_ctx,<<8]

alu_shf[lm_data_ref,lm_address,or,1,<<11]      // Select LM 

alu_shf[mem_address,lm_address,or,me_num,<<12]
local_csr_wr[active_lm_Addr_0,lm_address]

alu[$xfer0,mem_address,+,0]
alu[$xfer1,mem_address,+,1]
alu[$xfer2,mem_address,+,2]
alu[$xfer3,mem_address,+,3]
alu[$xfer4,mem_address,+,4]
alu[$xfer5,mem_address,+,5]
alu[$xfer6,mem_address,+,6]
alu[$xfer7,mem_address,+,7]
alu[$xfer8,mem_address,+,8]
alu[$xfer9,mem_address,+,9]
alu[$xfer10,mem_address,+,10]
alu[$xfer11,mem_address,+,11]
alu[$xfer12,mem_address,+,12]
alu[$xfer13,mem_address,+,13]
alu[$xfer14,mem_address,+,14]
alu[$xfer15,mem_address,+,15]
alu[expect,mem_address,+,0]
alu[expect,expect,OR,ace]

// Write data from xfer_outs to CTM
mem[write,$xfer0,mem_address,0,8],ctx_swap[sig12]

// Read from CTM into Local Memory
// OVerride full data_ref [5:3] = 1, data_Ref [31:16]
alu_shf[--,0x8,OR,lm_data_ref,<<16]
mem[read,$xfer0,mem_address,0,8],ctx_swap[sig12],indirect_ref

// Update data
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]
alu[*l$index0++, ace, OR , *l$index0]

// Write from Local Memory back to CTM
// OVerride full data_ref [5:3] = 1, data_Ref [31:16]
alu_shf[--,0x8,OR,lm_data_ref,<<16]
mem[write,$xfer0,mem_address,0,8],ctx_swap[sig12],indirect_ref

// Read data from CTM to xfer registers
mem[read,$xfer0,mem_address,0,8],ctx_swap[sig12]


alu[--,expect,-,$xfer0]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer1]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer2]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer3]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer4]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer5]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer6]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer7]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer8]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer9]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer10]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer11]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer12]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer13]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer14]
BNE[test_failed#]
alu[expect,expect,+,1]

alu[--,expect,-,$xfer15]
BNE[test_failed#]
alu[expect,expect,+,1]

test_passed#:
        ctx_arb[kill]
test_failed#:
        nop
        nop
        ctx_arb[kill]
