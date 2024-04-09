##;----------------------------------------------------------------------------
##;TEST_NAME: ls_force_ecc.uc  
##;    Use ECC data poisoner to poison single Data bit 1 at a time (0 to 63)
##;    Use ECC data poisoner to poison single ECC  bit 1 at a time (0 to 7)
##;    Verify with data readback
##;   Read ECC single bit error count register
##;----------------------------------------------------------------------------  

#ifndef _ENV_PHYSICAL_MULTI_CORE_H

#define _ENV_PHYSICAL_MULTI_CORE_H

#include "riscv_test.h"

#include "test_macros.h"

#undef RISCV_MULTICORE_DISABLE
#define RISCV_MULTICORE_DISABLE

#endif

#include "cpp_command_macros.h"
#include "rfpc_cmd_defines.h"
#include "test_macros.h"


#define zero   x0 # zero register
#define cppcmd_data_ref x3
#define count         x4
#define hart_id       x10 #hart csr register

#define expect_data   x11
#define expect1       x12
#define expect2       x13
#define data_cmp      x14
#define xpb_base      x15
#define mask          x16
#define base          x19
#define address       x20
#define address1      x21
#define cl_num        x22
#define group_num     x23
#define temp_data     x24
#define temp_data_1   x25
#define temp_data_2   x26
#define xfer          x27
#define dataref_offset x31

.equ CPP_MEM_ADDR,   0xf0000000

.equ  FILTER_STATUS,  0x0
.equ  FILTER_MASK,    0x10
.equ  FILTER_MATCH,   0x18
.equ  CLS_ECCMON_XPB_DEVICE_ID,   0x13

.equ WR_DATA0A,    0x00000001
.equ WR_DATA1A,    0x00000000
.equ WR_DATA2A,    0x0000000f
.equ WR_DATA3A,    0x0000000a


RVTEST_RV64U
RVTEST_CODE_BEGIN

##LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
##AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
##SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number


LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
##OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
##SLLI group_num , group_num, 8 #each core has 256 byte of address space
	

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, WR_DATA0A  #0x1
SW temp_data, 0x0(xfer)
LI temp_data, WR_DATA1A  #0x0
SW temp_data, 0x4(xfer)
LI temp_data, WR_DATA2A  #0xf
SW temp_data, 0x8(xfer)
LI temp_data, WR_DATA3A  #0xa
SW temp_data, 0xC(xfer)

## XPB: Set ECC enable (address 0)  
##      write all data to ecc_mon
LI xpb_base, 0x000d0000  ##misc engine command address
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,xpb_base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;


LI temp_data,0x55555555
SW temp_data,0x40(xfer)
SW temp_data,0x44(xfer) 

LI temp_data,0xffffffff
SD temp_data,0x0(xfer)


LI temp_data,0x67
SW temp_data,0x100(xfer)
LI temp_data,0xD9
SW temp_data,0x104(xfer)
LI temp_data,0x6E
SW temp_data,0x108(xfer)
LI temp_data,0x54
SW temp_data,0x10c(xfer)
LI temp_data,0xCE
SW temp_data,0x110(xfer)
LI temp_data,0x9D
SW temp_data,0x114(xfer)
LI temp_data,0xEC
SW temp_data,0x118(xfer)
LI temp_data,0xDC
SW temp_data,0x11c(xfer)

LI temp_data,0x3B
SW temp_data,0x120(xfer)
LI temp_data,0x76
SW temp_data,0x124(xfer)
LI temp_data,0xB3
SW temp_data,0x128(xfer)
LI temp_data,0x37
SW temp_data,0x12c(xfer)
LI temp_data,0xB9
SW temp_data,0x130(xfer)
LI temp_data,0x73
SW temp_data,0x134(xfer)
LI temp_data,0xCD
SW temp_data,0x138(xfer)
LI temp_data,0xC4
SW temp_data,0x13c(xfer)

LI temp_data,0xE6
SW temp_data,0x140(xfer)
LI temp_data,0x9B
SW temp_data,0x144(xfer)
LI temp_data,0x62
SW temp_data,0x148(xfer)
LI temp_data,0x52
SW temp_data,0x14c(xfer)
LI temp_data,0x68
SW temp_data,0x150(xfer)
LI temp_data,0x64
SW temp_data,0x154(xfer)
LI temp_data,0x61
SW temp_data,0x158(xfer)
LI temp_data,0xA2
SW temp_data,0x15c(xfer)

LI temp_data,0x58
SW temp_data,0x160(xfer)
LI temp_data,0x51
SW temp_data,0x164(xfer)
LI temp_data,0xC2
SW temp_data,0x168(xfer)
LI temp_data,0x34
SW temp_data,0x16c(xfer)
LI temp_data,0x4C
SW temp_data,0x170(xfer)
LI temp_data,0x4A
SW temp_data,0x174(xfer)
LI temp_data,0x49
SW temp_data,0x178(xfer)
LI temp_data,0xA8
SW temp_data,0x17c(xfer)

LI temp_data,0xC8
SW temp_data,0x180(xfer)
LI temp_data,0x46
SW temp_data,0x184(xfer)
LI temp_data,0x38
SW temp_data,0x188(xfer)
LI temp_data,0x25
SW temp_data,0x18c(xfer)
LI temp_data,0x45
SW temp_data,0x190(xfer)
LI temp_data,0x43
SW temp_data,0x194(xfer)
LI temp_data,0xC1
SW temp_data,0x198(xfer)
LI temp_data,0x29
SW temp_data,0x19c(xfer)

LI temp_data,0x32
SW temp_data,0x1a0(xfer)
LI temp_data,0x2C
SW temp_data,0x1a4(xfer)
LI temp_data,0xA4
SW temp_data,0x1a8(xfer)
LI temp_data,0x23
SW temp_data,0x1ac(xfer)
LI temp_data,0x31
SW temp_data,0x1b0(xfer)
LI temp_data,0x2A
SW temp_data,0x1b4(xfer)
LI temp_data,0x26
SW temp_data,0x1b8(xfer)
LI temp_data,0xA1
SW temp_data,0x1bc(xfer)

LI temp_data,0x1C
SW temp_data,0x1c0(xfer)
LI temp_data,0x1A
SW temp_data,0x1c4(xfer)
LI temp_data,0x98
SW temp_data,0x1c8(xfer)
LI temp_data,0x89
SW temp_data,0x1cc(xfer)
LI temp_data,0x19
SW temp_data,0x1d0(xfer)
LI temp_data,0x91
SW temp_data,0x1d4(xfer)
LI temp_data,0x85
SW temp_data,0x1d8(xfer)
LI temp_data,0x83
SW temp_data,0x1dc(xfer)

LI temp_data,0x16
SW temp_data,0x1e0(xfer)
LI temp_data,0x15
SW temp_data,0x1e4(xfer)
LI temp_data,0x94
SW temp_data,0x1e8(xfer)
LI temp_data,0x8C
SW temp_data,0x1ec(xfer)
LI temp_data,0x13
SW temp_data,0x1f0(xfer)
LI temp_data,0x92
SW temp_data,0x1f4(xfer)
LI temp_data,0x8A
SW temp_data,0x1f8(xfer)
LI temp_data,0x86
SW temp_data,0x1fc(xfer)

LI temp_data,0x01
SW temp_data,0x200(xfer)
LI temp_data,0x02
SW temp_data,0x204(xfer)
LI temp_data,0x04
SW temp_data,0x208(xfer)
LI temp_data,0x08
SW temp_data,0x20c(xfer)
LI temp_data,0x10
SW temp_data,0x210(xfer)
LI temp_data,0x20
SW temp_data,0x214(xfer)
LI temp_data,0x40
SW temp_data,0x218(xfer)
LI temp_data,0x80
SW temp_data,0x21c(xfer)


LI count,64    ### Poison Data bits one at a time
LI dataref_offset,0x100
data_loop:
LI xfer, CPP_MEM_ADDR  
##XPB: Set ECC mode (ImjectDataOneShot address=0x14) 
LI xpb_base, 0x000d0014  ##misc engine command address
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x0,0x0)  ; #OV DR
OR cppcmd_data_ref, cppcmd_data_ref, dataref_offset # override rs1[15:0]  
.insn s 43,0,xpb_base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;   

LI address,0  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI address,0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80)  ;
#OR cppcmd_data_ref, cppcmd_data_ref, dataref_offset # override rs1[15:0]  
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI address,0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;


LI expect_data,0xffffffff
LD temp_data,0x80(xfer)
BNE temp_data,expect_data,test_failed

ADDI dataref_offset,dataref_offset,4

ADDI count,count,-1
BNEZ count,data_loop


######################
LI count,8
LI dataref_offset,0x200
ecc_loop:
LI xfer, CPP_MEM_ADDR  
##XPB: Set ECC mode (ImjectDataOneShot address=0x14) 
LI xpb_base, 0x000d0010  ##misc engine command address
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x0,0x0)  ; #OV DR
OR cppcmd_data_ref, cppcmd_data_ref, dataref_offset # override rs1[15:0]  
.insn s 43,0,xpb_base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG2_pos,1) 	;   

LI address,0  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI address,0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x80)  ;
#OR cppcmd_data_ref, cppcmd_data_ref, dataref_offset # override rs1[15:0]  
.insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

LI address,0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x40)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;


LI expect_data,0xffffffff
LD temp_data,0x80(xfer)
BNE temp_data,expect_data,test_failed

ADDI dataref_offset,dataref_offset,4

ADDI count,count,-1
BNEZ count,ecc_loop   


##XPB: Read ECC error count 
LI xpb_base, 0x000d0028  ##misc engine command address
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x60)  ;
.insn s 43,0,xpb_base,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG3_pos,1) 	;  

LI expect_data,72
LWU temp_data,0x60(xfer)
BNE temp_data,expect_data,test_failed  

NOP
NOP
NOP




test_passed:
pass:		
test_done:
  J test_passed
test_failed:		
fail:
  J test_failed

	
end_the_test:
   
rv_test_loop:
  J rv_test_loop

	
RVTEST_CODE_END

  .data
RVTEST_DATA_BEGIN

  TEST_DATA

RVTEST_DATA_END


