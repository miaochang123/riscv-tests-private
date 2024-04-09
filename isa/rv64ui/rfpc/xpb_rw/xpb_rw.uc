;-----------------------
; TEST_NAME: xpb_rw.uc
;     Reads and writes XPB registers
;	
;   10/11/2012:
;
; 01/16/2023 Modified to use kestrel ct commands xpb_write and xpb_read 
;-----------------------
//.num_contexts 4
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

.areg address        0
.areg data1  1
.areg data2  2
.areg data3  3
.areg data4  4

.breg  cl_num        1
.breg  me_num        2

#define IMB_XPB_DEVICE_ID         10
#define CLS_IM_XPB_DEVICE_ID      11
#define CLS_TRNG_XPB_DEVICE_ID    12
#define CLS_ECCMON_XPB_DEVICE_ID  13
#define CLS_PA_XPB_DEVICE_ID      14


; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[cl_num,0]
alu_shf[me_num,0xF, AND,cl_num,>>3]
alu_shf[cl_num,0xF, AND,cl_num,>>24]

// MEs are numbered 4-15
alu[me_num,me_num,-,4]
immed[data1,0x1111]
immed[data2,0x2222]
immed[data3,0x3333]
immed[data4,0x4444]
alu[$xfer0,--,B,data1]
alu[$xfer1,--,B,data2]
alu[$xfer2,--,B,data3]
alu[$xfer3,--,B,data4]

immed[address,0]
immed_w1[address,IMB_XPB_DEVICE_ID]
//immed_w1[address,CLS_ECCMON_XPB_DEVICE_ID]

alu_shf[address,address,OR,1,<<31]      ; Bit[31]=12 means do XPB access
//alu_shf[address,address,OR,cl_num,<<24] ; Bit[29:24]=Island number 

ct[xpb_write,$xfer0,address,0,1],ctx_swap[sig1]
ct[xpb_write,$xfer1,address,4,1],ctx_swap[sig2]
ct[xpb_write,$xfer2,address,8,1],ctx_swap[sig3]
ct[xpb_write,$xfer3,address,12,1],ctx_swap[sig4]

ct[xpb_read,$xfer0,address,0,1],ctx_swap[sig5]
ct[xpb_read,$xfer2,address,4,1],ctx_swap[sig6]
ct[xpb_read,$xfer4,address,8,1],ctx_swap[sig7]
ct[xpb_read,$xfer6,address,12,1],ctx_swap[sig8]

alu[--,$xfer0,-,data1]
BNE[test_failed#]
alu[--,$xfer2,-,data2]
BNE[test_failed#]
alu[--,$xfer4,-,data3]
BNE[test_failed#]
alu[--,$xfer6,-,data4]
BNE[test_failed#]


test_passed#:
        ctx_arb[kill]
test_failed#:
        nop
        nop
        ctx_arb[kill]
