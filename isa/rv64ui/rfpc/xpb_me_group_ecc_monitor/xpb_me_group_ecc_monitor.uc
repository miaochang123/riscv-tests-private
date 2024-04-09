;-----------------------
; TEST_NAME: 
;     Reads and writes XPB registers within me_groups ECC_monitor
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

.areg address     0
.areg data1       1
.areg pass_count  2
.areg address2    3
.areg ecc_monitor_base  4
.areg ecc_monitor_base1  5

.breg address_me0    0
.breg address_me1    1
.breg address_me2    2
.breg address_me3    3

.breg  end_address   4
.breg  island_num    5
.breg  me_num        6
.breg  me_id         7

.breg  ecc_address   8
.breg  csr_data      9
.breg  ret_address  10
.breg  expect       11
.breg  me2sig       12
.breg  ctr          13

#define IMB_XPB_DEVICE_ID         10
#define ME_DEVICE_ID              0x30
#define ME_DEVICE_ID_MG1          0x31

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
#define ECC_GPR                   0x3c

#macro add_delay[delay_count]

immed[ctr,delay_count]
sleep_label#:
  nop
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]

#endm

immed[pass_count,0]

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[island_num,0]
alu_shf[me_id,0xF, AND,island_num,>>3]
alu_shf[island_num,0x3F, AND,island_num,>>24]

alu[me_num,me_id,AND,3]     
immed[ecc_monitor_base,0]
immed_w1[ecc_monitor_base,ME_DEVICE_ID]
alu_shf[ecc_monitor_base,ecc_monitor_base,OR,island_num,<<24] ; Bit[29:24]=Island number 

// 0: ME0 Ustore
// 1: ME1 Ustore
// 2: ME0 LM
// 3: ME1 LM
// 4: ME2 Ustore
// 5: ME3 Ustore
// 6: ME2 LM
// 7: ME3 LM
alu[--,me_num,-,0]
immed_w0[ecc_monitor_base,0x0], predicate_cc
alu[--,me_num,-,1]
immed_w0[ecc_monitor_base,0x40], predicate_cc
alu[--,me_num,-,2]
immed_w0[ecc_monitor_base,0x100], predicate_cc
alu[--,me_num,-,3]
immed_w0[ecc_monitor_base,0x140], predicate_cc

alu_shf[ecc_monitor_base1,ecc_monitor_base,OR,ME_DEVICE_ID_MG1,<<16] 
alu_shf[ecc_monitor_base,ecc_monitor_base,OR,ME_DEVICE_ID,<<16] 

// Delaying the assertion of ustore_ecc_enable
//local_csr_rd[ctx_enables]
//immed[csr_data,0]
//alu_shf[csr_data,csr_data,OR,1,<<28]  // Enable UStore ECC
//local_csr_wr[ctx_enables,csr_data]

//local_csr_rd[misc_control]
//immed[csr_data,0]
//alu_shf[csr_data,csr_data,OR,1,<<12]  // Enable UStore ECC correction
//local_csr_wr[misc_control,csr_data]


alu[--,me_id,-,12]
BGE[test_passed#]  // ME8-11 are not used
alu[--,me_id,-,8]        // ME4-7 will inject single-bit errors to ME0-3
BGE[injection_me_code#]  // and will inject double -bit errors to self and HALT
                     
local_csr_wr[mailbox1,me_num]
local_csr_wr[mailbox1,0x44]
local_csr_wr[mailbox0,0x33]


// MEs 0-3 Wait for signal from ME4 and than execute remaing code
//     They should each encounter a UStore and a LM_ECC errors
ctx_arb[sig4]

// Move assertion of ustore_correct_enable for Ustore's having single/correctable error to here
local_csr_rd[misc_control]
immed[csr_data,0]
alu_shf[csr_data,csr_data,OR,1,<<12]  // Enable UStore ECC correction
local_csr_wr[misc_control,csr_data]

// Move assertion of ustore_ecc_enable for Ustore's having single/correctable error to here
local_csr_rd[ctx_enables]
immed[csr_data,0]
alu_shf[csr_data,csr_data,OR,1,<<28]  // Enable UStore ECC
local_csr_wr[ctx_enables,csr_data]

// There will be some ECC errors in below code...
#repeat (30)
nop 
#endloop

local_csr_wr[mailbox0,pass_count]

// How to verify I've recorded an ECC error ???

// 1) Read Ustore_Error_Status csr
// The readback value from UStore_ERROR_status CSR should be NON-ZERO
local_csr_rd[Ustore_error_Status]
immed[data1,0]
local_csr_wr[mailbox3,data1]

alu[--,data1,-,0]
BEQ[test_failed#]   

// Read ECC_Monitor ERROR_COUNT : Expect = 1
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT,1],ctx_swap[sig1]  
alu[--,$xfer0,-,1]
BNE[test_failed#]

// Read ECC_Monitor ERROR_COUNT (and reset count) : Expect = 1
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT_RESET,1],ctx_swap[sig2]
alu[--,$xfer0,-,1]
BNE[test_failed#]

// Read ECC_Monitor ERROR_COUNT : Expect = 0
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT,1],ctx_swap[sig3]
alu[--,$xfer0,-,0]
BNE[test_failed#]

// There will be some ECC errors in below code...
#repeat (50)
nop 
#endloop

//------------------
// Read FIRST ERROR : 
//------------------

; [31]: Register data is Valid
; [25]: Mulit bit error
; [24]: Single bit error
; [23:16]: ECC delta
; [15:0]: address

immed[expect,46]
alu[expect,expect,OR,0x32,<<16] // ECC_delta
alu[expect,expect,OR,1,<<24]    // Single bit error
alu[expect,expect,OR,1,<<31]    // Valid

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_FIRST_ERROR,1],ctx_swap[sig1]  
local_csr_wr[mailbox2,$xfer0]
alu[--,$xfer0,-,expect]
BNE[test_failed#]

//------------------
// Read LAST ERROR : 
//------------------
; [31]: Register data is Valid
; [25]: Mulit bit error
; [24]: Single bit error
; [23:16]: ECC delta
; [15:0]: address

immed[expect,104]
alu[expect,expect,OR,0x62,<<16] // ECC_delta
alu[expect,expect,OR,1,<<24]    // Single bit error
alu[expect,expect,OR,1,<<31]    // Valid

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_LAST_ERROR,1],ctx_swap[sig1]  
local_csr_wr[mailbox3,$xfer0]
alu[--,$xfer0,-,expect]
BNE[test_failed#]

//------------------
// Read ERROR count: 
//------------------

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT,1],ctx_swap[sig1]  
alu[--,$xfer0,-,4]
BNE[test_failed#]

// Clear ECC error count
immed[$xfer0,0]
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_CLEAR_ERROR,1],ctx_swap[sig1]  

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT,1],ctx_swap[sig1]  
alu[--,$xfer0,-,0]
BNE[test_failed#]

// There will be some ECC errors in below code...
#repeat (50)
nop 
#endloop

//------------------
// Read ERROR count: 
//------------------

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_ERROR_COUNT,1],ctx_swap[sig1]  
alu[--,$xfer0,-,3]
BNE[test_failed#]

// Check Pass_count  (Number of "pass_count=pass_count+1" that was injected)
alu[--,pass_count,-, 14]
BNE[test_failed#]

// Read back the ECC INJECT ENABLE CSR
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_INJECT_ENABLE,1],ctx_swap[sig1]  

alu[--,$xfer0,-,1]
BNE[test_failed#]

//------------------
// Read ECC_GPR: 
//------------------
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_GPR,1],ctx_swap[sig1]  
alu[--,$xfer0,-,0x55]
BNE[test_failed#]

// WRite/REad SRAM_CONTROL_10 : Bits [30:26],[14:11] are RESERVED
// WRite/REad SRAM_CONTROL_32 : Bits [31:26],[14:11] are RESERVED
immed[data1,0xffff]
immed_w1[data1,0xffff]
alu[$xfer0,--,B,data1]
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_SRAM_CONTROL_10,1],ctx_swap[sig1]
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_SRAM_CONTROL_32,1],ctx_swap[sig2]

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_SRAM_CONTROL_10,1],ctx_swap[sig1]

; New SRAM_Control_Reg expect value 9/8/2017
//immed[expect,0xffff]
//immed_w1[expect,0xBfff]
immed[expect,0x87ff]
immed_w1[expect,0x83ff]
alu[--,$xfer0,-,expect]
BNE[test_failed#]

ct[xpb_read,$xfer0,ecc_monitor_base,ECC_SRAM_CONTROL_32,1],ctx_swap[sig1]

; New SRAM_Control_Reg expect value 9/8/2017
//immed[expect,0xffff]
//immed_w1[expect,0x3fff]
immed[expect,0x87ff]
immed_w1[expect,0x03ff]

alu[--,$xfer0,-,expect]
BNE[test_failed#]

// Check error count for uncorrectable error in MG1

immed[expect,0]      // Single_bit_count = 0
immed_w1[expect,1]   // multi--bit count = 1

ct[xpb_read,$xfer0,ecc_monitor_base1,ECC_ERROR_COUNT,1],ctx_swap[sig1]  
alu[--,$xfer0,-,expect]
BNE[test_failed#]

BR[test_passed#]

//-----------------------------------------
// Injection code runs on  MG1 only
//-----------------------------------------
injection_me_code#:

alu[me2sig,me_id,-,4]   // Signal equivalent ME in MG0

// 0: 0x000: ME0 Ustore
// 1: 0x040: ME1 Ustore
// 2: 0x080: ME0 LM
// 3: 0x0c0: ME1 LM
// 4: 0x100: ME2 Ustore
// 5: 0x140: ME3 Ustore
// 6: 0x180: ME2 LM
// 7: 0x1c0: ME3 LM

immed[$xfer2,0x55]
immed[$xfer3,0x0]
ct[xpb_write,$xfer2,ecc_monitor_base,ECC_GPR,1],ctx_swap[sig6]

immed[$xfer0,  0x32] // [7:0]  ECC_Delta
immed[$xfer1,1]      // 0 = OFF, 1 = ON

//ct[xpb_write,$xfer1,ecc_monitor_base,ECC_INJECT_ENABLE,1],sig_done[sig1]  // delay till all done (this also appears to enable correction)
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_INJECT_ONE_SHOT_DATA,1],ctx_swap[sig2]

ct[xpb_read,$xfer1,ecc_monitor_base,ECC_INJECT_ONE_SHOT_DATA,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_1#]
immed[data1,46]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,50]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_1#:

immed[ecc_address,0]
immed[$xfer4,  0x75]   ; [7:0]  ECC_Delta
immed[$xfer5,  0x62]   ; [7:0]  ECC_Delta

// Inject Permanent ECC
ct[xpb_write,$xfer4,ecc_monitor_base,ECC_INJECT_PERM_DATA,1],ctx_swap[sig1]
ct[xpb_read,$xfer4,ecc_monitor_base,ECC_INJECT_PERM_DATA,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_2#]
immed[data1,90]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,94]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_2#:

// Inject Permanent ECC
ct[xpb_write,$xfer5,ecc_monitor_base,ECC_INJECT_PERM_DATA,1],ctx_swap[sig1]
ct[xpb_read,$xfer5,ecc_monitor_base,ECC_INJECT_PERM_DATA,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_3#]
immed[data1,100]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,104]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_3#:

// Clear Injection
ct[xpb_write,$xfer5,ecc_monitor_base,ECC_INJECT_CLEAR,1],ctx_swap[sig1]
ct[xpb_read,$xfer5,ecc_monitor_base,ECC_INJECT_CLEAR,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_4#]
immed[data1,110]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,114]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_4#:


immed[$xfer0,1] // [7:0]  ECC_Delta
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_INJECT_ONE_SHOT_ECC,1],ctx_swap[sig1]
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_INJECT_ONE_SHOT_ECC,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_5#]
immed[data1,164]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,168]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_5#:

immed[$xfer0,2] // [7:0]  ECC_Delta
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_INJECT_PERM_ECC,1],ctx_swap[sig1]
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_INJECT_PERM_ECC,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_6#]
immed[data1,174]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,178]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_6#:

immed[$xfer0,2] // [7:0]  ECC_Delta
ct[xpb_write,$xfer0,ecc_monitor_base,ECC_INJECT_CLEAR,1],ctx_swap[sig1]
ct[xpb_read,$xfer0,ecc_monitor_base,ECC_INJECT_CLEAR,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_7#]
immed[data1,184]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,188]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]

return_from_injection_7#:

// Inject multi-bit errors

alu[me2sig,me_id,-,0]   // Inject within this MEgroup
immed[$xfer0,3] // [7:0]  ECC_Delta
immed[$xfer1,1] 
//ct[xpb_write,$xfer1,ecc_monitor_base1,ECC_INJECT_ENABLE,1],ctx_swap[sig1]
ct[xpb_write,$xfer0,ecc_monitor_base1,ECC_INJECT_ONE_SHOT_ECC,1],ctx_swap[sig2]
ct[xpb_read,$xfer0,ecc_monitor_base1,ECC_INJECT_ONE_SHOT_ECC,1],ctx_swap[sig3]

load_addr[ret_address,return_from_injection_8#]
immed[data1,340]                   
alu_shf[$xfer2,data1,OR,1,<<31]    // ECS bit
immed[data1,344]                   
alu_shf[$xfer3,data1,OR,1,<<31]    // ECS bit
BR[inject_2_instructions#]  // FIXME: Skipping the multi-bit busting

return_from_injection_8#:

immed[$xfer1,1]      // 0 = OFF, 1 = ON
// This is really a "detect" enable, NOT an "inject" enable
ct[xpb_write,$xfer1,ecc_monitor_base,ECC_INJECT_ENABLE,1],ctx_swap[sig1]  // delay till all done (this also appears to enable correction)
ct[xpb_write,$xfer1,ecc_monitor_base1,ECC_INJECT_ENABLE,1],ctx_swap[sig1]

// Move assertion of ustore_ecc_enable for Ustore's having dual/uncorrectable error to here
local_csr_rd[ctx_enables]
immed[csr_data,0]
alu_shf[csr_data,csr_data,OR,1,<<28]  // Enable UStore ECC
local_csr_wr[ctx_enables,csr_data]

//----------------------------------------------------------
; INTERTHREAD_SIG Csr	
; ME number = bits [13:9]
; Thread #  = bits [8:6]
; Signal #  = bits [5:2]

alu[me2sig,me_id,-,4]   // Signal equivalent ME in MG0

alu_shf[address,--,B, 0,<<6]                 ; Thread # = 0
alu_shf[address,address,OR,island_num,<<24]  ; This cluster
alu_shf[address,address,OR, 4,<<2]           ; signal number = 4

alu_shf[address2,address,OR,me2sig,<<9]      
CT[interthread_signal,--,address2,0,1]       ; Send interthread signal 

add_delay[40]

;Make sure the multi-bit error is in below code

#repeat (40)
nop 
#endloop

BR[test_passed#]

inject_2_instructions#:

//--------------------------
// WRite a NOP to 1st address
//immed[data1,0x0300]
//immed_w1[data1,0x00c0]
//alu[$xfer0,--,B,data1]
//immed[$xfer1,0x00f0]
//--------------------------

//--------------------------
// WRite  "alu[pass_count,pass_count,+,1] " to 1st address
// 00A0 802C 0402 common_code
//	alu[pass_count,pass_count,+,1]
//
immed[data1,0x0402]
immed_w1[data1,0x802c]
alu[$xfer0,--,B,data1]
immed[$xfer1,0x00a0]
//--------------------------

immed[address,0x0 ]                 // Select Ustore_address
alu_shf[address,--,B,address,>>2]     
alu_shf[address,address,OR,2,<<9]    // Select CSR  

alu[address2,address,OR,me2sig,<<12] 
cls[reflect_from_sig_src,$xfer2,address2,0,1],ctx_swap[sig8]


immed[address,0x4 ]                 // Select Ustore_data_lower
alu_shf[address,--,B,address,>>2]     
alu_shf[address,address,OR,2,<<9]    // Select CSR  
  
alu[address2,address,OR,me2sig,<<12]  
cls[reflect_from_sig_src,$xfer0,address2,0,1],ctx_swap[sig8]

immed[address,0x8 ]                 // Select Ustore_data_upper
alu_shf[address,--,B,address,>>2]     
alu_shf[address,address,OR,2,<<9]    // Select CSR  
  
alu[address2,address,OR,me2sig,<<12] 
cls[reflect_from_sig_src,$xfer1,address2,0,1],ctx_swap[sig8]

//--------------------------
// WRite  "alu[pass_count,pass_count,+,1] " to 2nd address
//--------------------------

immed[address,0x0 ]                 // Select Ustore_address
alu_shf[address,--,B,address,>>2]     
alu_shf[address,address,OR,2,<<9]    // Select CSR  

alu[address2,address,OR,me2sig,<<12]  
cls[reflect_from_sig_src,$xfer3,address2,0,1],ctx_swap[sig8]

immed[address,0x4 ]                 // Select Ustore_data_lower
alu_shf[address,--,B,address,>>2]     
alu_shf[address,address,OR,2,<<9]    // Select CSR  
  
alu[address2,address,OR,me2sig,<<12]  
cls[reflect_from_sig_src,$xfer0,address2,0,1],ctx_swap[sig8]

immed[address,0x8 ]                 // Select Ustore_data_upper
alu_shf[address,--,B,address,>>2]     
alu_shf[address,address,OR,2,<<9]    // Select CSR  
  
alu[address2,address,OR,me2sig,<<12]  
cls[reflect_from_sig_src,$xfer1,address2,0,1],ctx_swap[sig8]

rtn[ret_address]
nop
nop
nop

test_passed#:
        ctx_arb[kill]
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
