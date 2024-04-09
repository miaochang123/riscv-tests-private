;-----------------------
; TEST_NAME: ls_trng2.uc
;-----------------------
// From: verif/python_lib.hg/peripherals/xpb_trng.py
//    def standard_configuration(self, monitor_period = 100000, whitener_standard=1, backdoor=False ):
//        self.wr_lfsr_config( reseed_timer=0x1000, lfsrs = {0:("XOR",0), 1:("XOR",0), 2:("XOR",0), 3:("XOR",0) } ) # PRNGs all to be reseeded with XOR every 0x1000 cycles
//        self.reset_entropy_generator()
//        self.wr_async_ring_config( entropy_enable=True, ring_enable=True, sync_enable=True, feedback_enables=8, backdoor=backdoor )
//        self.wr_async_test( enable=False )  # Test data off - no leaking data!
//        self.wr_whitener_control(generator_timeout=0x4000, enable=1 ) # Whitener enabled, using standard path; timer at 0x4000
//       average_bit_rate = self.wr_whitener_config( self.whitener_config_standards[whitener_standard] )

// Do not need to do monitor stuff
//        self.wr_monitor_period( monitor_period  )
//        self.wr_monitor_min_ones( int(monitor_period*average_bit_rate*0.90/16/2) )
//        self.wr_monitor_max_ones( int(monitor_period*average_bit_rate*1.10/16/2) )
//        self.wr_monitor_max_run_length( max=64 ) # Chances of 64 in a row is, er, small

//        self.load_lfsr(0x123)
//        self.load_incr(0x7c00)
//        self.run_repeatedly()

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

.breg   temp        4
.breg  cl_num       6
.breg  sig_num      7
.breg  sig_gpr      8

.breg  expect       10

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

       add_delay[100]   // Not sure here
#endm

#macro run_repeatedly
       ; XPB write: TRNG Async Command
       immed[$xfer0,6]                       //Run async generator repeatedly
       ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_CMD,1],ctx_swap[sig1]

       add_delay[100]   // Not sure here
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

// initialize and kick off TRNG

//        self.wr_lfsr_config( reseed_timer=0x1000, lfsrs = {0:("XOR",0), 1:("XOR",0), 2:("XOR",0), 3:("XOR",0) } ) # PRNGs all to be reseeded with XOR every 0x1000 cycles
; XPB write: TRNG LFSR Config
immed[temp,0xAAF]
immed_w1[temp,0x1000]          // Set reseed Timer restart = 0x1000
alu[$xfer0,--,B,temp]
ct[xpb_write,$xfer0,xpb_address,TRNG_LFSR_CFG,1],ctx_swap[sig1]

//        self.reset_entropy_generator()
reset_entropy_generator()

//        self.wr_async_ring_config( entropy_enable=True, ring_enable=True, sync_enable=True, feedback_enables=8, backdoor=backdoor )
; XPB write: TRNG Async Ring
;   entropy_enable = BIT[0]
;   ring_enable    = BIT[1]
;   sync_enable    = BIT[2]
;   feedback_enables  = BIT[7:4]
immed[$xfer0,0x87]    
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_RING,1],ctx_swap[sig1]

//        self.wr_async_test( enable=False )  # Test data off - no leaking data!
; XPB write: TRNG ASYNCH TEST
immed[$xfer0,0x0]    
ct[xpb_write,$xfer0,xpb_address,TRNG_ASYNC_TEST,1],ctx_swap[sig1]

//        self.wr_whitener_control(generator_timeout=0x4000, enable=1 ) # Whitener enabled, using standard path; timer at 0x4000
// Generator_timeoust = BIT[31:16]
// Enable             = BIT[1]
; XPB write: TRNG Whitener control
immed[temp,0x0002]    
immed_w1[temp,0x4000]    
alu[$xfer0,--,B,temp]
ct[xpb_write,$xfer0,xpb_address,TRNG_WHITEN_CONTROL,1],ctx_swap[sig1]

//       average_bit_rate = self.wr_whitener_config( self.whitener_config_standards[whitener_standard] )
; XPB write: TRNG Whiten Config
immed[temp,0x2CC2]    
immed_w1[temp,0x2CC2]    
alu[$xfer0,--,B,temp]
ct[xpb_write,$xfer0,xpb_address,TRNG_WHITEN_CONFIG,1],ctx_swap[sig1]

//        self.load_lfsr(0x123)
load_lfsr[0x1223]
//        self.load_incr(0x7c00)
load_incr[0x7c00]
//        self.run_repeatedly()
run_repeatedly()

//---------------------------------------------------------------------

; READ DATA

immed[trng_base,0]
immed_w1[trng_base,0x6]
alu_shf[trng_base,trng_base,OR,cl_num,<<26]

#define NUM_RANDOMS_TO_GET	300

immed[read_loop,NUM_RANDOMS_TO_GET]
read_loop#:

  cls[read,$xfer0,trng_base,TH_TRNG_data,1], ctx_swap[sig1] 
  alu[--,$xfer0,-,0]
  BEQ[read_loop#]
  alu[*l$index0++,--,B,$xfer0]   // Save data to LM if data is non-zero
  alu[read_loop,read_loop,-,1]

BNE[read_loop#]


test_passed#:

	ctx_arb[kill]
test_failed#:
	nop
	nop
	ctx_arb[kill]
