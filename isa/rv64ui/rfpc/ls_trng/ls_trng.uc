;-----------------------
; TEST_NAME: trng.uc
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

.breg count         0

.breg temp          4
.breg  cl_num       6

.breg  end_loop          7
.breg  inner_loop_count  8
.breg  lm1_start      9
.breg  data_to_check 10
.breg  period       11
.breg min_ones      12
.breg max_ones      13

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

#define NUM_RANDOMS_TO_GET	40

// From peripheral_regression.py
//    def standard_configuration(self):
//        self.reset_entropy_generator()
//        self.wr_async_ring_config(0x87) # No overrides, feedback on closest tap, ring enabled, entropy feed (and synchronizer_enable)
//        self.wr_async_test(1)        Make this ON ---
//        self.wr_async_config(0xff00_0000) # Initial seed for LFSR and INCR non-zero
//        self.wr_lfsr_config((0x1000<<16)|(0x0aaf)) # PRNGs all to be reseeded with XOR every 0x1000 cycles
//        self.wr_whitener_control((0x4000<<16)|2) # Whitener enabled, using standard path; timer at 0x4000
//        self.wr_whitener_config( self.whitener_config_standards[1] )
//        period = 100000
//        self.wr_monitor_period( period  )
//        self.wr_monitor_min_ones( period/4*0.90 )
//        self.wr_monitor_max_ones( period/4*1.10 )
//        self.wr_monitor_max_run_length( (64)<<16 ) # Chances of 64 in a row is, er, small
//        self.run_repeatedly()

//    whitener_config_standards = { 1:0x83388338,
//                                  2:(3<<12)|(3<<10)|(3<<9)|(2<<6)|(2<<5)|(2<<3),
//                                  3:(3<<6)|(2<<9)
//                                  }

#macro add_delay[delay_count]

immed[ctr,delay_count]
sleep_label#:
  nop
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]

#endm

; The ME_NUM is in bits [7:3]
; CL_NUM[3:0] is in bit [28:25]
local_csr_rd[ACTIVE_CTX_STS]
immed[me_num,0]

alu_shf[cl_num,0xF, AND,me_num,>>24]
alu_shf[me_num,0xF, AND,me_num,>>3]

immed[xpb_address,0]
immed_w1[xpb_address,CLS_TRNG_XPB_DEVICE_ID]

//alu_shf[xpb_address,xpb_address,OR,1,<<31]      ; Bit[31]=12 means do XPB access
alu_shf[xpb_address,xpb_address,OR,cl_num,<<24] ; Bit[29:24]=Island number 

immed[$xfer1,0]

//        self.reset_entropy_generator()

; XPB write: TRNG Async Command
immed[$xfer0,2]  // Reset the FSM
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

add_delay[5]

; XPB write: TRNG Async Command
immed[$xfer0,1]  // Reset the async generator
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

add_delay[5]

//        self.wr_async_ring_config(0x87) # No overrides, feedback on closest tap, ring enabled, entropy feed (and synchronizer_enable)
; XPB write: TRNG Async ring
immed[$xfer0,0x87]    // Previously was 0x83 (New bit is for synchronizer_enable)
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_RING,1],ctx_swap[sig1]

//        self.wr_async_test(1)  #   NEW = 1,  OLD = 0 Test data off - no leaking data!
; XPB write: TRNG Async Test
immed[$xfer0,0x1]    
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_TEST,1],ctx_swap[sig1]

//        self.wr_async_config(0xff00_0000) # Initial seed for LFSR and INCR non-zero
; XPB write: TRNG Async Config
//immed[$xfer0,0x5555,<<16]      ; Seed value
//immed[$xfer0,0x1234]     ; ????
immed[$xfer0,0xff00,<<16]      ; 12/11/2012 NEW Seed value
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CFG,1],ctx_swap[sig1]

//        self.wr_lfsr_config((0x1000<<16)|(0x0aaf)) # PRNGs all to be reseeded with XOR every 0x1000 cycles
; XPB write: TRNG LFSR Config
immed[temp,0xAAF]
alu_shf[$xfer0,temp,OR,1,<<28]
ct[xpb_write,$xfer0,xpb_address,TRNG_LFSR_CFG,1],ctx_swap[sig1]

//        self.wr_whitener_control((0x4000<<16)|2) # Whitener enabled, using standard path; timer at 0x4000
immed[temp,0x2]
alu_shf[$xfer0,temp,OR,4,<<28]
ct[xpb_write,$xfer0,xpb_address,TRNG_WHITEN_CONTROL,1],ctx_swap[sig1]

//        self.wr_whitener_config( self.whitener_config_standards[1] ) // 1:0x83388338,
immed[temp,0x8338]
immed_w1[temp,0x8338]
alu[$xfer0,--,B,temp]
ct[xpb_write,$xfer0,xpb_address,TRNG_WHITEN_CONFIG,1],ctx_swap[sig1]


//        period = 100000 = 0x1_86A0
//        self.wr_monitor_period( period  )          100,000 = 0x186A0                // 2,000 = 0x7D0
//        self.wr_monitor_min_ones( period/4*0.90 )  100,000/4 *.9 = 22,500 = 0x57E4  //   450 =
//        self.wr_monitor_max_ones( period/4*1.10 )  100,000/4*1.1 = 27,500 = 0x6B6C  //   550 = 
//immed[period,0x86A0]
//immed_w1[period,1]
//immed[min_ones,0x57E4]
//immed[max_ones,0x6B6C]

immed[period,2000]
immed[min_ones,450]
immed[max_ones,550]


alu[$xfer0,--,B,period]
ct[xpb_write,$xfer0,xpb_address,TRNG_MON_PERIOD,1],ctx_swap[sig1]

alu[$xfer0,--,B,min_ones]
ct[xpb_write,$xfer0,xpb_address,TRNG_MON_ONES_MIN,1],ctx_swap[sig1]

alu[$xfer0,--,B,max_ones]
ct[xpb_write,$xfer0,xpb_address,TRNG_MON_ONES_MAX,1],ctx_swap[sig1]

//        self.wr_monitor_max_run_length( (64)<<16 ) # Chances of 64 in a row is, er, small
alu[$xfer0,--,B,64,<<16]
ct[xpb_write,$xfer0,xpb_address,TRNG_MON_MAX_RUN_LEN,1],ctx_swap[sig1]

//        self.run_repeatedly()
; XPB write: TRNG Async Command
immed[$xfer0,6] 
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

//---------------------------

add_delay[200]

; READ DATA

immed[trng_base,0]
immed_w1[trng_base,0x6]
alu_shf[trng_base,trng_base,OR,cl_num,<<26]

immed[read_loop,NUM_RANDOMS_TO_GET]

read_loop#:
  add_delay[15]

  cls[read,$xfer0,trng_base,TH_TRNG_data,1], ctx_swap[sig1] 
  alu[--,$xfer0,-,0]
  BEQ[read_loop#]
  alu[*l$index0++,--,B,$xfer0]   // Save data to LM if data is non-zero
  alu[read_loop,read_loop,-,1]
BNE[read_loop#]

add_delay[40]
nop
nop
; XPB read Alert Status
ct[xpb_read,$xfer0,xpb_address,TRNG_ALERT,1],ctx_swap[sig1]

// Check the data for any repeating values
immed[end_loop,NUM_RANDOMS_TO_GET]
alu[end_loop,end_loop,-,1]
immed[lm1_start,4]

local_csr_wr[active_lm_addr_0,0x000]

check_loop#:
   local_csr_wr[active_lm_addr_1,lm1_start]
   alu[inner_loop_count,end_loop,-,0]
   alu[lm1_start,lm1_start,+,4]
   alu[data_to_check,--,B,*l$index0++]

   inner_loop#:
       alu[data,--,B,*l$index1++]
       alu[--,data,-,data_to_check]
       BEQ[test_failed#]
       alu[inner_loop_count,inner_loop_count,-,1]
       BNE[inner_loop#]

   alu[end_loop,end_loop,-,1]
   BNE[check_loop#]


test_passed#:

	ctx_arb[kill]
test_failed#:
	nop
	nop
	ctx_arb[kill]
