;-----------------------
; TEST_NAME: me_lmecc_events
;     1) Each ME uses ECC monitor to inject single bit error into its own LM memory
;     2) Configure one CLS Ecc filter to monitor # of single bit ecc error events for that ME
;     3) Each ME generates 5 ECC errors
;     4) Read ECC monitor single bit ecc error count (check for 5 errors)
;     5) Read CLS ECC filter count (check for 5 events)
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

.areg address            0
.areg ecc_monitor_base   1
.areg filter_base        2
.areg filter_match_data  3

.breg  me_group_num  0
.breg  island_num    1
.breg  me_num        3
.breg  me_num1_0     4

.breg  csr_data      5
.breg  read_data     6
.breg  expect        7
.breg  ctr           8

#define IMB_XPB_DEVICE_ID         10

#define ECC_INJECT_ENABLE         0x0
#define ECC_INJECT_CLEAR          0x4
#define ECC_INJECT_PERM_ECC       0x8
#define ECC_INJECT_PERM_DATA      0xC
#define ECC_INJECT_ONE_SHOT_ECC   0x10
#define ECC_INJECT_ONE_SHOT_DATA  0x14
#define ECC_SRAM_CONTROL_10       0x18
#define ECC_SRAM_CONTROL_32       0x1c
#define ECC_FIRST_ERROR           0x20
#define ECC_LAST_ERROR            0x24
#define ECC_ERROR_COUNT           0x28
#define ECC_ERROR_COUNT_RESET     0x2C
#define ECC_CLEAR_ERROR           0x38
#define ECC_GPR                   0x3C

#define FILTER_STATUS  0x0
#define FILTER_FLAGS   0x8
#define FILTER_MASK    0x10
#define FILTER_MATCH   0x18
#define FILTER_ACK     0x20
#define COMBINED_STATUS             0x800
#define COMBINED_PENDING_STATUS     0x808
#define CONFIGURATION               0x810
#define USER_EVENT                  0x400

#macro add_delay[delay_count]

immed[ctr,delay_count]
sleep_label#:
  nop
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]

#endm

// Write LM with good data... (will over write later with bad ECC)
immed[*l$index3++,0x11]  
immed[*l$index3++,0x22]  
immed[*l$index3++,0]  
immed[*l$index3++,0]  
immed[*l$index3++,0]  
immed[*l$index3++,0]  
immed[*l$index3++,0]  
immed[*l$index3++,0]  

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[island_num,0]
alu_shf[me_num,0xF, AND,island_num,>>3]
alu_shf[island_num,0x3F, AND,island_num,>>24]

alu[me_num,me_num,-,4]                ; MEs are numbered starting at 4

alu_shf[me_group_num,--,B,me_num,>>2]
alu[me_num1_0,me_num,AND,3]           ; Bottome 2 bits of me_num (or me_num within a group)
     
#define ME_DEVICE_ID              0x30
#define ME_DEVICE_ID_MG1          0x31
#define ME_DEVICE_ID_MG2          0x32
immed[ecc_monitor_base,0]
immed_w1[ecc_monitor_base,ME_DEVICE_ID]
alu_shf[ecc_monitor_base,ecc_monitor_base,OR,island_num,<<24] ; Bit[29:24]=Island number 

// 4: MG0
// 5: MG1
// 6: MG2
immed[filter_match_data,0xA] ; Correctable error = 0xA
alu[--,me_group_num,A
alu_shf[filter_match_data,filter_match_data,OR,4,<<12], predicate_cc 
alu[--,me_group_num,-,1]
alu_shf[filter_match_data,filter_match_data,OR,5,<<12], predicate_cc 
alu[--,me_group_num,-,2]
alu_shf[filter_match_data,filter_match_data,OR,6,<<12], predicate_cc 

// 0: ME0 Ustore
// 1: ME1 Ustore
// 2: ME0 LM
// 3: ME1 LM
// 4: ME2 Ustore
// 5: ME3 Ustore
// 6: ME2 LM
// 7: ME3 LM
alu[--,me_num1_0,-,0]
immed_w0[ecc_monitor_base,0x80], predicate_cc
alu_shf[filter_match_data,filter_match_data,OR,2,<<9], predicate_cc
alu[--,me_num1_0,-,1]
immed_w0[ecc_monitor_base,0xc0], predicate_cc
alu_shf[filter_match_data,filter_match_data,OR,3,<<9], predicate_cc
alu[--,me_num1_0,-,2]
immed_w0[ecc_monitor_base,0x180], predicate_cc
alu_shf[filter_match_data,filter_match_data,OR,6,<<9], predicate_cc
alu[--,me_num1_0,-,3]
immed_w0[ecc_monitor_base,0x1c0], predicate_cc
alu_shf[filter_match_data,filter_match_data,OR,7,<<9], predicate_cc

// ME Group # shift <<16
alu_shf[ecc_monitor_base,ecc_monitor_base,OR,ME_DEVICE_ID,<<16] 
alu_shf[ecc_monitor_base,ecc_monitor_base,OR,me_group_num,<<16] 

immed[filter_base,0]
immed_w1[filter_base,0x2]
alu_shf[filter_base,filter_base,OR,island_num,<<26]
alu_shf[filter_base,filter_base,OR,me_num,<<6]

;---------------------
; Filter Type = 0
; data_source[11:0] = 
;        data_source[11:8] = ecc_event_config__id
;           MG0=4, MG1=5, MG2=6
;        data_source[7:5]
;           LM_ECC: ME0=2, ME1=3, ME2=6, ME3=7
;           UStore: ME0=0, ME1=1, ME2=4, ME3=5
;        data_source[4:0] = address[4:0]
; data_Event[3:0] ; Correctable error = 0xA
;---------------------
immed[read_data,0xFE0F]
alu[read_data,read_data,OR,0,<<24] ; Shift 0 into Filter Type
alu[$xfer0,--,B,read_data]  
cls[write,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]
cls[read_le,$xfer0,filter_base,FILTER_MASK,1], ctx_swap[sig1]

; Match on event and data_source[11:5]
alu[$xfer2,--,B,filter_match_data]
cls[write,$xfer2,filter_base,FILTER_MATCH,1], ctx_swap[sig1]
cls[read_le,$xfer0,filter_base,FILTER_MATCH,1], ctx_swap[sig1]

// Enable LM_ECC
local_csr_rd[ctx_enables]
immed[csr_data,0]
alu_shf[csr_data,csr_data,OR,1,<<23]  // Enable LM     ECC
local_csr_wr[ctx_enables,csr_data]

immed[$xfer0,1]  
immed[$xfer1,0]  
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_INJECT_ENABLE,1],ctx_swap[sig6]

// ECC_INJECT_PERM_DATA
immed[read_data,0x61] ; [7:0]  ECC_Delta = Bit 13
alu[$xfer4,--,B,read_data]
immed[$xfer5,  0]  
ct[xpb_write,$xfer4,ecc_monitor_base,ECC_INJECT_PERM_DATA,1],ctx_swap[sig1]
add_delay[40]
local_csr_wr[mailbox0,3]

immed[*l$index0++,0x11]  // Writes LM with bad ECC 
immed[*l$index0++,0x22]  // Writes LM with bad ECC 
immed[*l$index0++,0x33]  // Writes LM with bad ECC 
immed[*l$index0++,0x44]  // Writes LM with bad ECC 
immed[*l$index0++,0x55]  // Writes LM with bad ECC 
immed[*l$index0++,0x66]  // Writes LM with bad ECC 

// ECC_INJECT_CLEAR
ct[xpb_write,$xfer5,ecc_monitor_base,ECC_INJECT_CLEAR,1],ctx_swap[sig1]
add_delay[20]
local_csr_wr[mailbox0,4]

immed[*l$index0++,0x77]  
immed[*l$index0++,0x88]  

//--------------------------------
// Start reading back the LM_data
//--------------------------------
alu[read_data,--,B,*l$index1++]    // Single bit Error_count++
alu[--,read_data,-,0x11]
BNE[test_failed#]
alu[read_data,--,B,*l$index1++]    // Single bit Error_count++
alu[--,read_data,-,0x22]
BNE[test_failed#]
alu[read_data,--,B,*l$index1++]    // Single bit Error_count++
alu[--,read_data,-,0x33]
BNE[test_failed#]
alu[read_data,--,B,*l$index1++]    // Single bit Error_count++
alu[--,read_data,-,0x44]
BNE[test_failed#]
alu[read_data,--,B,*l$index1++]    // Single bit Error_count++
alu[--,read_data,-,0x55]
BNE[test_failed#]

// Read ECC_Monitor ERROR_COUNT : Expect = 5
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT,1],ctx_swap[sig1]  
local_csr_wr[mailbox2,$xfer0]

alu[--,$xfer0,-,5]; Check that 5 errors were generated
BNE[test_failed#]

; Lets read the event filter count
; Read filter_Status
cls[read_le,$xfer0,filter_base,FILTER_ACK,1], ctx_swap[sig1]
local_csr_wr[mailbox1,$xfer0]

alu[--,$xfer0,-,5]   ; Check that 5 events were generated
BNE[test_failed#]

test_passed#:
        ctx_arb[kill]
        nop
        nop
        nop
        nop
test_failed#:
        nop
        nop
        ctx_arb[kill]
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
        nop
