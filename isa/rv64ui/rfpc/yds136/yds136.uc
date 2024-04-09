// Test = yds136.uc
// Description: Verify that YLD bug yds136 has been fixed for Harrier
//    ME0 initializes a CLS csr and goes into loop reading CSR
//    All other MES initialize a data location and then go into loops reading data
//
.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 

#define LOOP_COUNT  100

immed[read_count,LOOP_COUNT]

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]
alu_shf[cl_num,0x3F, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

alu[--,me_num,-,4]
BEQ[cls_csrs#]

// All other MEs will do accesses to CLS memory
cls_data#:

alu_shf[base,--,B,me_num,<<6]   // Address

alu_shf[data0,--,B,me_num,<<16] // Data
alu_shf[data1,--,B,me_num,<<24] // Data
alu[$xfer0,--,B,data0]
alu[$xfer1,--,B,data1]
cls[write,$xfer0,base,0,2], ctx_swap[sig3]

read_data_loop#:

  cls[read,$xfer0,base,0,2], ctx_swap[sig3]
  alu[--,$xfer0,-,data0]
  BNE[test_failed#]
  alu[--,$xfer1,-,data1]
  BNE[test_failed#]

  alu[read_count,read_count,-,1]
  BNE[read_data_loop#]

BR[test_passed#]

// ME0 will do accesses to a CLS CSR
cls_csrs#:

;--------------------------------------
; Base for Event Manager = 0x00002_0000
;--------------------------------------
immed[base,0]
immed_w1[base,2]
alu_shf[base,base,OR,cl_num,<<26]

; YLD: Maskbits used are [19:0] and [26:24]
; TH:  Maskbits used are [23:0] and [26:24]

immed[csr_data,0x1234]
alu[$xfer0,--,B,csr_data]
immed[$xfer1,0]

cls[write,$xfer0,base,0x10,1], ctx_swap[sig3]

read_csr_loop#:

  cls[read_le,$xfer0,base,0x10,1], ctx_swap[sig3]
  alu[--,$xfer0,-,csr_data]
  BNE[test_failed#]

  alu[read_count,read_count,-,1]
  BNE[read_csr_loop#]


test_passed#:
nop
nop
	ctx_arb[kill]
test_failed#:
        nop
        nop
	ctx_arb[kill]
