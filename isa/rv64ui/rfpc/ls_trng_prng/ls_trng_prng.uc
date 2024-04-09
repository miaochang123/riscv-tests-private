;-----------------------
; TEST_NAME: ls_trng_gavin3.uc
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

.addr $xfer0 0
.addr $xfer1 1
.addr $xfer2 2
.addr $xfer3 3
.addr $xfer4 4
.addr $xfer5 5
.addr $xfer6 6
.addr $xfer7 7
.addr $xfer8 8
.addr $xfer9 9
.addr $xfer10 10
.addr $xfer11 11
.addr $xfer12 12
.addr $xfer13 13
.addr $xfer14 14
.addr $xfer15 15

.areg  me_num        0
.areg  trng_base     1
.areg  ctr           2
.areg  read_loop     3
.areg xpb_address     10
.areg data          4

.breg count         8

.breg   temp        9
.breg  cl_num       10
.breg  sig_num      11
.breg  sig_gpr      12

.breg  expect0       0
.breg  expect1       1
.breg  expect2       2
.breg  expect3       3
.breg  expect4       4
.breg  expect5       5
.breg  expect6       6
.breg  expect7       7

#define TH_TRNG_data                   0

#define TRNG_ASYNC_RING           0x00
#define TRNG_ASYNC_TEST           0x04
#define TRNG_ASYNC_CMD            0x08
#define TRNG_ASYNC_STATUS         0x0C
#define TRNG_ASYNC_CFG            0x10
#define TRNG_LFSR_CFG             0x20
#define TRNG_WHITEN_CONTROL       0x24
#define TRNG_WHITEN_CONFIG        0x28
#define TRNG_MON_PERIOD           0x30
#define TRNG_MON_ONES             0x34
#define TRNG_MON_ONES_MIN         0x38
#define TRNG_MON_ONES_MAX         0x3c
#define TRNG_MON_MAX_RUN_LEN      0x40
#define TRNG_LOCK                 0x50
#define TRNG_ALERT                0x54

#define IMB_XPB_DEVICE_ID         10
#define CLS_IM_XPB_DEVICE_ID      11
#define CLS_TRNG_XPB_DEVICE_ID    12
#define CLS_ECCMON_XPB_DEVICE_ID  13
#define CLS_PA_XPB_DEVICE_ID      14
                              
#macro add_delay[delay_count]

immed[ctr,delay_count]
sleep_label#:
  nop
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]

#endm

#macro reset_entropy_generator
       ; XPB write: TRNG Async Command
       immed[$xfer0,2]  // 2 = Reset the FSM
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

	add_delay[5]

       ; XPB write: TRNG Async Command
       immed[$xfer0,1]  // 1 = Reset the async generator
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

	add_delay[5]

#endm

#macro load_lfsr[value]
       ; XPB write: TRNG Async CFG
       immed[temp,0]
       immed_w1[temp,value]
       alu[$xfer0,--,B,temp]
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CFG,1],ctx_swap[sig1]

       ; XPB write: TRNG Async Command
       immed[$xfer0,3]                         // Load the LFSR
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

       add_delay[5]
#endm

#macro load_incr[value]
       ; XPB write: TRNG Async CFG
       immed[temp,0]
       immed_w1[temp,value]
       alu[$xfer0,--,B,temp]
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CFG,1],ctx_swap[sig1]

       ; XPB write: TRNG Async Command
       immed[$xfer0,4]                          // Load the Incrementer
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

       add_delay[5]
#endm

#macro run_single
       ; XPB write: TRNG Async Command
       immed[$xfer0,5]                       //Run async generator until incrmentor wraps to 0
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

       add_delay[500]   // Not sure here
#endm

; The ME_NUM is in bits [7:3]
; CL_NUM[3:0] is in bit [28:25]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]

// Setup to Send signal 1 to Next ME
immed[sig_num,1]
alu_shf[sig_gpr,0x80,OR,sig_num,<<3] 		

alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

immed[xpb_address,0]
immed_w1[xpb_address,CLS_TRNG_XPB_DEVICE_ID]

alu_shf[xpb_address,xpb_address,OR,1,<<31]      ; Bit[31]=12 means do XPB access
alu_shf[xpb_address,xpb_address,OR,cl_num,<<24] ; Bit[29:24]=Island number 

immed[$xfer1,0]
immed[$xfer0,0]

alu[--,me_num,-,4]
BEQ[ME0_code#]

//ME1 reads/collects the data
ME1_code#:

// Wait for signal from ME0
ctx_arb[sig1]   

; READ DATA

immed[trng_base,0]
immed_w1[trng_base,0x6]
alu_shf[trng_base,trng_base,OR,cl_num,<<26]

#define NUM_RANDOMS_TO_GET	40

immed[read_loop,NUM_RANDOMS_TO_GET]
read_loop#:

  cls[read,$xfer0,trng_base,TH_TRNG_data,1], ctx_swap[sig1] 
  alu[--,$xfer0,-,0]
  BEQ[read_loop#]
  alu[*l$index0++,--,B,$xfer0]   // Save data to LM if data is non-zero
  alu[read_loop,read_loop,-,1]

BNE[read_loop#]

immed[expect0,    0xffff]
immed_w1[expect0, 0xffff]
immed[expect1,    0x3fff]
immed_w1[expect1, 0xfff0]
immed[expect2,    0xfe00]
immed_w1[expect2, 0xffff]
immed[expect3,    0xffff]
immed_w1[expect3, 0xff1f]
immed[expect4,    0xe38f]
immed_w1[expect4, 0xfe38]
immed[expect5,    0xc7ff]
immed_w1[expect5, 0x0fff]
immed[expect6,    0x07f8]
immed_w1[expect6, 0xfffe]
immed[expect7,    0xffc0]
immed_w1[expect7, 0xc003]

alu[--,*l$index1++,-,expect0]
bne[test_failed#]
alu[--,*l$index1++,-,expect1]
bne[test_failed#]
alu[--,*l$index1++,-,expect2]
bne[test_failed#]
alu[--,*l$index1++,-,expect3]
bne[test_failed#]
alu[--,*l$index1++,-,expect4]
bne[test_failed#]
alu[--,*l$index1++,-,expect5]
bne[test_failed#]
alu[--,*l$index1++,-,expect6]
bne[test_failed#]
alu[--,*l$index1++,-,expect7]
bne[test_failed#]

immed[expect0,    0x1f81]
immed_w1[expect0, 0x3fe4]
immed[expect1,    0x1c8e]
immed_w1[expect1, 0x71c7]
immed[expect2,    0xffff]
immed_w1[expect2, 0x01ff]
immed[expect3,    0x40ff]
immed_w1[expect3, 0xff1c]
immed[expect4,    0xe3f9]
immed_w1[expect4, 0xffff]
immed[expect5,    0x7ffc]
immed_w1[expect5, 0xc83c]
immed[expect6,    0x1c6e]
immed_w1[expect6, 0xe007]
immed[expect7,    0x0f1f]
immed_w1[expect7, 0xe03c]

alu[--,*l$index1++,-,expect0]
bne[test_failed#]
alu[--,*l$index1++,-,expect1]
bne[test_failed#]
alu[--,*l$index1++,-,expect2]
bne[test_failed#]
alu[--,*l$index1++,-,expect3]
bne[test_failed#]
alu[--,*l$index1++,-,expect4]
bne[test_failed#]
alu[--,*l$index1++,-,expect5]
bne[test_failed#]
alu[--,*l$index1++,-,expect6]
bne[test_failed#]
alu[--,*l$index1++,-,expect7]
bne[test_failed#]

immed[expect0,    0x8860]
immed_w1[expect0, 0x1fe3]
immed[expect1,    0x0c7f]
immed_w1[expect1, 0x9f38]
immed[expect2,    0x5762]
immed_w1[expect2, 0x7976]
immed[expect3,    0xed8e]
immed_w1[expect3, 0x8e38]
immed[expect4,    0xfffe]
immed_w1[expect4, 0x0007]
immed[expect5,    0xff03]
immed_w1[expect5, 0xf000]
immed[expect6,    0x07e0]
immed_w1[expect6, 0xe3fe]
immed[expect7,    0xf1c0]
immed_w1[expect7, 0x1c9f]

alu[--,*l$index1++,-,expect0]
bne[test_failed#]
alu[--,*l$index1++,-,expect1]
bne[test_failed#]
alu[--,*l$index1++,-,expect2]
bne[test_failed#]
alu[--,*l$index1++,-,expect3]
bne[test_failed#]
alu[--,*l$index1++,-,expect4]
bne[test_failed#]
alu[--,*l$index1++,-,expect5]
bne[test_failed#]
alu[--,*l$index1++,-,expect6]
bne[test_failed#]
alu[--,*l$index1++,-,expect7]
bne[test_failed#]

immed[expect0,    0xe24e]
immed_w1[expect0, 0x3fff]
immed[expect1,    0x1ffc]
immed_w1[expect1, 0xc038]
immed[expect2,    0x18e0]
immed_w1[expect2, 0xe180]
immed[expect3,    0x3f3c]
immed_w1[expect3, 0x1f8c]
immed[expect4,    0x01be]
immed_w1[expect4, 0x246c]
immed[expect5,    0xe049]
immed_w1[expect5, 0xb1c7]
immed[expect6,    0x1fe0]
immed_w1[expect6, 0xf870]
immed[expect7,    0x0dc4]
immed_w1[expect7, 0x1fce]

alu[--,*l$index1++,-,expect0]
bne[test_failed#]
alu[--,*l$index1++,-,expect1]
bne[test_failed#]
alu[--,*l$index1++,-,expect2]
bne[test_failed#]
alu[--,*l$index1++,-,expect3]
bne[test_failed#]
alu[--,*l$index1++,-,expect4]
bne[test_failed#]
alu[--,*l$index1++,-,expect5]
bne[test_failed#]
alu[--,*l$index1++,-,expect6]
bne[test_failed#]
alu[--,*l$index1++,-,expect7]
bne[test_failed#]

immed[expect0,    0x89d9]
immed_w1[expect0, 0x1b93]
immed[expect1,    0x8047]
immed_w1[expect1, 0xecb2]
immed[expect2,    0x1ff6]
immed_w1[expect2, 0x80fe]
immed[expect3,    0x2043]
immed_w1[expect3, 0xbcf1]
immed[expect4,    0xbfa3]
immed_w1[expect4, 0xa487]
immed[expect5,    0xbd4b]
immed_w1[expect5, 0x47a5]
immed[expect6,    0xa89a]
immed_w1[expect6, 0xea89]
immed[expect7,    0xdb8e]
immed_w1[expect7, 0xb136]

alu[--,*l$index1++,-,expect0]
bne[test_failed#]
alu[--,*l$index1++,-,expect1]
bne[test_failed#]
alu[--,*l$index1++,-,expect2]
bne[test_failed#]
alu[--,*l$index1++,-,expect3]
bne[test_failed#]
alu[--,*l$index1++,-,expect4]
bne[test_failed#]
alu[--,*l$index1++,-,expect5]
bne[test_failed#]
alu[--,*l$index1++,-,expect6]
bne[test_failed#]
alu[--,*l$index1++,-,expect7]
bne[test_failed#]

BR[test_passed#]

// ME0 initializes and kicks off TRNG
ME0_code#:

//        # Config ring off
//        self.wr_async_ring_config( 0x0 )
; XPB write: TRNG Async Ring
immed[$xfer0,0x0]    
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_RING,1],ctx_swap[sig1]

//        # Whitener config not needed
//        self.wr_whitener_config(0)

; XPB write: TRNG Whiten Config
immed[$xfer0,0x0]    
ct[xpb_write,$xfer0,xpb_address,TRNG_WHITEN_CONFIG,1],ctx_swap[sig1]

//        # Hold in reset
//        self.wr_lfsr_config( 0x55f )
; XPB write: TRNG LFSR Config
immed[$xfer0,0x55f]    
ct[xpb_write,$xfer0,xpb_address,TRNG_LFSR_CFG,1],ctx_swap[sig1]

//        # Hold in reset, clock once
//        self.wr_lfsr_config( 0xf55f )
; XPB write: TRNG LFSR Config
immed[$xfer0,0xf55f]    
ct[xpb_write,$xfer0,xpb_address,TRNG_LFSR_CFG,1],ctx_swap[sig1]

// ?????????
//        self.sync_set("ssb",10)
// Signal next ME to begin
   immed[sig_num,1]
   alu_shf[sig_gpr,0x80,OR,sig_num,<<3]		
   local_csr_wr[Next_Neighbor_Signal,sig_gpr]

//        # Whitener control - monitor PRNG0
//        self.wr_whitener_control( 0x04000003 )
; XPB write: TRNG Whitener control
immed[temp,0x0003]    
immed_w1[temp,0x0400]    
alu[$xfer0,--,B,temp]
ct[xpb_write,$xfer0,xpb_address,TRNG_WHITEN_CONTROL,1],ctx_swap[sig1]

//        # Let LFSR 0 run
//        self.wr_lfsr_config( 0xff1 )
//        self.show_lfsr_config(expectation_text="0xff1",expectation=[(-1,0xff1)])
; XPB write: TRNG LFSR Config
immed[$xfer0,0xff1]    
ct[xpb_write,$xfer0,xpb_address,TRNG_LFSR_CFG,1],ctx_swap[sig1]

// Signal Next ME to start up
local_csr_wr[Next_Neighbor_Signal,sig_gpr]

test_passed#:

	ctx_arb[kill]
test_failed#:
	nop
	nop
	ctx_arb[kill]
