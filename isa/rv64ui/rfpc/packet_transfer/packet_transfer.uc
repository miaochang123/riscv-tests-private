.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15 $xfer16  $xfer17 $xfer18 $xfer19 $xfer20 $xfer21 $xfer22 $xfer23 $xfer24 $xfer25 $xfer26 $xfer27 $xfer28 $xfer29 $xfer30 $xfer31

#macro load_xfer[data]

immed[temp,(data & 0xFFFF)]
immed_w1[temp,(data>>16)]

alu[*$index++,--,B,temp]
alu[*l$index0++,--,B,temp]

#endm

#macro get_64bytes

alu[$xfer0,--,B,*l$index1++]
alu[$xfer1,--,B,*l$index1++]
alu[$xfer2,--,B,*l$index1++]
alu[$xfer3,--,B,*l$index1++]
alu[$xfer4,--,B,*l$index1++]
alu[$xfer5,--,B,*l$index1++]
alu[$xfer6,--,B,*l$index1++]
alu[$xfer7,--,B,*l$index1++]
alu[$xfer8,--,B,*l$index1++]
alu[$xfer9,--,B,*l$index1++]
alu[$xfer10,--,B,*l$index1++]
alu[$xfer11,--,B,*l$index1++]
alu[$xfer12,--,B,*l$index1++]
alu[$xfer13,--,B,*l$index1++]
alu[$xfer14,--,B,*l$index1++]
alu[$xfer15,--,B,*l$index1++]

#endm

#macro check_64bytes

alu[--,$xfer0,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer1,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer2,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer3,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer4,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer5,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer6,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer7,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer8,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer9,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer10,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer11,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer12,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer13,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer14,-,*l$index1++]
BNE[test_failed#]
alu[--,$xfer15,-,*l$index1++]
BNE[test_failed#]

#endm


load_xfer[0x62cfe21a ]
load_xfer[0x9b7e4015 ]
load_xfer[0x21e6ad58 ]
load_xfer[0x8100ce22 ]
load_xfer[0x0800451a ]
load_xfer[0x00ee9698 ]
load_xfer[0xed5911d5 ]
load_xfer[0x18559134]
load_xfer[0xfcae48f6 ]
load_xfer[0x3501b13c ]
load_xfer[0x86149690 ]
load_xfer[0x6be23938 ]
load_xfer[0x52ec66a5 ]
load_xfer[0x9fafd7db ]
load_xfer[0x8643f27a ]
load_xfer[0x1912a8e5]
load_xfer[0x018fb8a2 ]
load_xfer[0xc25be93f ]
load_xfer[0xd57bbfaa ]
load_xfer[0xba4aaf8e ]
load_xfer[0x1bfaa441 ]
load_xfer[0x00c86307 ]
load_xfer[0x8f47e984 ]
load_xfer[0xb9b10127]
load_xfer[0x436d87a0 ]
load_xfer[0x89f03df1 ]
load_xfer[0xe42f2722 ]
load_xfer[0x995a09df ]
load_xfer[0x536783b5 ]
load_xfer[0x23092dc3 ]
load_xfer[0x9b3dcf23 ]
load_xfer[0xbc34e31b]
load_xfer[0x77ca33d4 ]
load_xfer[0xa4b8a4ad ]
load_xfer[0xff09ad2a ]
load_xfer[0xd1cc9f72 ]
load_xfer[0x281fe96a ]
load_xfer[0x92a28e15 ]
load_xfer[0x2b6be317 ]
load_xfer[0xe1e3c895]
load_xfer[0x0ce668ee ]
load_xfer[0xe04ae0d9 ]
load_xfer[0xc0b3c4ec ]
load_xfer[0x00d62a2e ]
load_xfer[0xbdff2d03 ]
load_xfer[0xd744e10f ]
load_xfer[0xf37bc16f ]
load_xfer[0xa8dee4b1]
load_xfer[0x6a212ecf ]
load_xfer[0x1cbe3628 ]
load_xfer[0x0f094776 ]
load_xfer[0xb120b523 ]
load_xfer[0x6c6f2a88 ]
load_xfer[0xde5bbb97 ]
load_xfer[0x514eb6f0 ]
load_xfer[0xf29697d7]
load_xfer[0xaf167732 ]
load_xfer[0x296418e5 ]
load_xfer[0x276d4aa0 ]
load_xfer[0x83c49316 ]
load_xfer[0x0a045391 ]
load_xfer[0x57481c35 ]
load_xfer[0xd8df1384 ]
load_xfer[0xa549e1ca]

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]
alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

alu[--,me_num,-,5]
BEQ[receiving_code#]  // ME1= receive

alu[--,me_num,-,4]
BNE[test_passed#]  // ME0=send  

sending_code#:

immed[address,0]
mem[packet_alloc,$xfer0, address, 0 ,1], ctx_swap[sig1]
//mem[packet_read_packet_status,$xfer0, address, 0 ,0], ctx_swap[sig1]

immed[temp,0x1FF]
alu[buffer_credit,temp,AND,$xfer0]
immed[temp,0x7FF]
alu[packet_credit,temp,AND,$xfer0,>>9]
immed[temp,0x3FF]
alu[packet_num,temp,AND,$xfer0,>>20]

// Load CTM with the packet data
// Set bit[0]=1
// Packet # = [19:11] ????
// Byte offset = [10:0]

alu[*n$index++,--,B,packet_num] // Send packet # to next ME

alu[address,--,B,1,<<0]
alu[address,address,OR,packet_num,<<11]
immed[byte_offset,0]

get_64bytes
mem[write,$xfer0,address,0,8], ctx_swap[sig2]
alu[byte_offset,byte_offset,+,64]
get_64bytes
mem[write,$xfer0,address,byte_offset,8], ctx_swap[sig3]
alu[byte_offset,byte_offset,+,64]
get_64bytes
mem[write,$xfer0,address,byte_offset,8], ctx_swap[sig4]
alu[byte_offset,byte_offset,+,64]
get_64bytes
mem[write,$xfer0,address,byte_offset,8], ctx_swap[sig5]

immed[sig_num,1]
alu_shf[sig_gpr,0x80,OR,sig_num,<<3]		
local_csr_wr[Next_Neighbor_Signal,sig_gpr]  // Set Signal 1 in the next neighbor ME (ME1)

BR[test_passed#]

receiving_code#:

ctx_arb[sig1]   // Wait for signal from ME0 to continue
// Read packet data from CTM
alu[packet_num,--, B, *n$index++] // Receive packet # to previous ME
alu[address,--,B,1,<<0]
alu[address,address,OR,packet_num,<<11]
immed[byte_offset,0]

mem[read,$xfer0,address,0,8], ctx_swap[sig2]
alu[byte_offset,byte_offset,+,64]
check_64bytes
mem[read,$xfer0,address,byte_offset,8], ctx_swap[sig3]
alu[byte_offset,byte_offset,+,64]
check_64bytes
mem[read,$xfer0,address,byte_offset,8], ctx_swap[sig4]
alu[byte_offset,byte_offset,+,64]
check_64bytes
mem[read,$xfer0,address,byte_offset,8], ctx_swap[sig5]
check_64bytes

nop

test_passed#:
  nop
  ctx_arb[kill]  
test_failed#:
  nop 
  nop   
  nop 
  nop  
