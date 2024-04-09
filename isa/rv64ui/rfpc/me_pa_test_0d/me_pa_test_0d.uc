.addr $xfer0           0
.addr $xfer1           1
.addr $xfer2           2
.addr $xfer3           3
.addr $xfer4           4
.addr $xfer5           5
.addr $xfer6           6
.addr $xfer7           7
.addr $xfer8           8
.addr $xfer9           9
.addr $xfer10          10
.addr $xfer11          11
.addr $xfer12          12
.addr $xfer13          13
.addr $xfer14          14
.addr $xfer15          15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 

#define IMB_XPB_DEVICE_ID         10
#define IMB_PA_SELECT_0          0x6C
#define CLS_TARGET_15_OFFSET     60    // CLS

.areg me_num       1
.areg island_num   2
.areg data         3
.areg address      4

.breg count        0
local_csr_rd[active_ctx_sts] 
immed[me_num,0x0]
 
alu_shf[island_num,0x3F,AND,me_num,>>24]
alu_shf[me_num,0xF,AND,me_num,>>3]

alu[me_num,me_num,-,4]
BNE[test_passed#]       // Only ME0

alu_shf[address,--,B,island_num,<<24]       ; Bit[29:24]=Island number 
alu_shf[address,address,OR,IMB_XPB_DEVICE_ID,<<16]
alu_shf[address,address,OR,1,<<31]          ; Bit[31]=12 means do XPB access

BR!=ctx[0,run_test#]

// Configure the target_address_mode_config registers
; XPB: Write to IMB target_Address_Mode_Config
// [12]   40/32 bit mode
// [11:6] Island 1
// [5:0]  Island 0

immed[$xfer0,0]                                                       ; 32 bit mode
immed[$xfer1,0]
ct[xpb_write,$xfer0,address,CLS_TARGET_15_OFFSET,1],ctx_swap[sig1]    ;  Write for target 15 CLS

alu[data,--,B,0xD]
alu[data,data,OR,0xD,<<6]                                           
alu[data,data,OR,0xD,<<12]                                                                
alu[$xfer0,data,OR,4,<<20]                                                  
ct[xpb_write,$xfer0,address,IMB_PA_SELECT_0,1],ctx_swap[sig1]   

run_test#:

immed[address,0]
immed[count,50]

loop#:
ctx_arb[voluntary]
alu[$xfer0,--,B,count]
alu[$xfer1,1,+,count]
nop
nop
cls[write,$xfer0,address,0,2],ctx_swap[sig1]  
nop
nop
nop
alu[count,count,-,2]
BNE[loop#]

test_passed#:

	nop
	nop
	nop

        ctx_arb[kill]
test_failed#:
	nop
	nop
	nop

        ctx_arb[kill]
	nop
	nop
	nop
