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
#define count x4
#define hart_id    x10 #hart csr register

#define expect1       x11
#define expect2       x12
#define expect3       x13
#define expect4       x14
#define expect5       x15
#define expect6       x16
#define address       x17
#define expect7      x23
#define expect8      x24
#define cl_num        x18
#define group_num     x19
#define temp_data     x20
#define temp_data_1   x21
#define temp_data_2   x22
#define data_bytew  x26
#define xfer  x27
#define mydataref   x31
#define count_dr    x2




.equ CPP_MEM_ADDR, 0xf0000000

.equ INIT_RESIDUE, 0x87654321
.equ WR_DATA0A,    0x44332211
.equ WR_DATA1A,    0x88776655
.equ WR_DATA2A,    0xCCBBAA99
.equ WR_DATA3A,    0x00FFEEDD
.equ WR_DATA4A,    0x87654321
.equ WR_DATA5A,    0xfedcba09
.equ WR_DATA6A,    0x12345678
.equ WR_DATA7A,    0x90abcdef
.equ WR_DATA8A,    0x12131415
.equ WR_DATA9A,    0x16171819
.equ WR_DATA10A,   0x1a1b1c1d
.equ WR_DATA11A,   0x10111e1f 




RVTEST_RV64U
RVTEST_CODE_BEGIN



LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	

LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data, WR_DATA0A
SW temp_data, 0x0(xfer)
LI temp_data, WR_DATA1A
SW temp_data, 0x4(xfer)
LI temp_data, WR_DATA2A
SW temp_data, 0x8(xfer)
LI temp_data, WR_DATA3A
SW temp_data, 0xC(xfer)
LI temp_data, WR_DATA4A
SW temp_data, 0x10(xfer)
LI temp_data, WR_DATA5A
SW temp_data, 0x14(xfer)
LI temp_data, WR_DATA6A
SW temp_data, 0x18(xfer)
LI temp_data, WR_DATA7A
SW temp_data, 0x1C(xfer)
LI temp_data, WR_DATA8A
SW temp_data, 0x20(xfer)
LI temp_data, WR_DATA9A
SW temp_data, 0x24(xfer)
LI temp_data, WR_DATA10A
SW temp_data, 0x28(xfer)
LI temp_data, WR_DATA11A
SW temp_data, 0x2c(xfer)

##################write all defined data to cls sram
###10111e1f 1a1b1c1d 16171819 12131415 90abcdef 12345678 fedcba09 87654321 00ffeedd ccbbaa99 88776655 44332211                          
ADD address, group_num, zero 
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xb,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

##;--------------------------------------
## LE reads  : addr 0x0~0x7  len 0~7
##;--------------------------------------
ADD address, group_num, zero
LI count,0x0
############read LE
loop_read_le:
LI count_dr,0
loop_read_le_dr:
SLLI mydataref,count_dr,2

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x0,0x0)  ;
LI temp_data,0x40
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x1,0x0)  ;
LI temp_data,0x50
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x2,0x0)  ;
LI temp_data,0x70
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x3,0x0)  ;
LI temp_data,0x90
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);              

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x4,0x0)  ;
LI temp_data,0xb0
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x5,0x0)  ;
LI temp_data,0xe0
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x6,0x0)  ;
LI temp_data,0x110
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x7,0x0)  ;
LI temp_data,0x140
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);


LI temp_data , 0x0
BEQ count, temp_data,readle0_expect 
LI temp_data , 0x1
BEQ count, temp_data,readle1_expect
LI temp_data , 0x2
BEQ count, temp_data,readle2_expect
LI temp_data , 0x3
BEQ count, temp_data,readle3_expect
LI temp_data , 0x4
BEQ count, temp_data,readle4_expect 
LI temp_data , 0x5
BEQ count, temp_data,readle5_expect
LI temp_data , 0x6
BEQ count, temp_data,readle6_expect 
LI temp_data , 0x7
BEQ count, temp_data,readle7_expect 

readle0_expect:
LI expect1, 0x44332211
LI expect2, 0x88776655
LI expect3, 0xCCBBAA99
LI expect4, 0x00FFEEDD
LI expect5, 0x87654321
LI expect6, 0xfedcba09
LI expect7, 0x12345678
LI expect8, 0x90abcdef
J  readle_compare_data

readle1_expect:
LI expect1, 0x55443322
LI expect2, 0x99887766
LI expect3, 0xddCCBBAA
LI expect4, 0x2100FFEE
LI expect5, 0x09876543
LI expect6, 0x78fedcba
LI expect7, 0xef123456
LI expect8, 0x1590abcd
J  readle_compare_data

readle2_expect:
LI expect1, 0x66554433
LI expect2, 0xAA998877
LI expect3, 0xEEDDCCBB
LI expect4, 0x432100FF
LI expect5, 0xBA098765
LI expect6, 0x5678fedc
LI expect7, 0xCDef1234
LI expect8, 0x141590ab
J  readle_compare_data

readle3_expect:
LI expect1, 0x77665544
LI expect2, 0xBBAA9988
LI expect3, 0xFFEEDDCC
LI expect4, 0x65432100
LI expect5, 0xDCBA0987
LI expect6, 0x345678fe
LI expect7, 0xABCDef12
LI expect8, 0x13141590
J  readle_compare_data 

readle4_expect:
LI expect1, 0x88776655
LI expect2, 0xCCBBAA99
LI expect3, 0x00FFEEDD
LI expect4, 0x87654321
LI expect5, 0xFEDCBA09
LI expect6, 0x12345678
LI expect7, 0x90ABCDef
LI expect8, 0x12131415
J  readle_compare_data

readle5_expect:
LI expect1, 0x99887766
LI expect2, 0xDDCCBBAA
LI expect3, 0x2100FFEE
LI expect4, 0x09876543
LI expect5, 0x78FEDCBA
LI expect6, 0xEF123456
LI expect7, 0x1590ABCD
LI expect8, 0x19121314
J  readle_compare_data   

readle6_expect:
LI expect1, 0xAA998877
LI expect2, 0xEEDDCCBB
LI expect3, 0x432100FF
LI expect4, 0xBA098765
LI expect5, 0x5678FEDC
LI expect6, 0xCDEF1234
LI expect7, 0x141590AB
LI expect8, 0x18191213
J  readle_compare_data

readle7_expect:
LI expect1, 0xBBAA9988
LI expect2, 0xFFEEDDCC
LI expect3, 0x65432100
LI expect4, 0xDCBA0987
LI expect5, 0x345678FE
LI expect6, 0xABCDEF12
LI expect7, 0x13141590
LI expect8, 0x17181912
J  readle_compare_data 



readle_compare_data:
LI xfer, CPP_MEM_ADDR 
OR xfer,xfer,mydataref 

LWU temp_data_1, 0x40(xfer)
BNE temp_data_1, expect1, test_failed 

LWU temp_data_1, 0x50(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x54(xfer)
BNE temp_data_1, expect2, test_failed

LWU temp_data_1, 0x70(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x74(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x78(xfer)
BNE temp_data_1, expect3, test_failed

LWU temp_data_1, 0x90(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x94(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x98(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0x9c(xfer)
BNE temp_data_1, expect4, test_failed
                  
LWU temp_data_1, 0xb0(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0xb4(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0xb8(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0xbc(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0xc0(xfer)
BNE temp_data_1, expect5, test_failed

LWU temp_data_1, 0xe0(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0xe4(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0xe8(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0xec(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0xf0(xfer)
BNE temp_data_1, expect5, test_failed
LWU temp_data_1, 0xf4(xfer)
BNE temp_data_1, expect6, test_failed

LWU temp_data_1, 0x110(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x114(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x118(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0x11c(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0x120(xfer)
BNE temp_data_1, expect5, test_failed
LWU temp_data_1, 0x124(xfer)
BNE temp_data_1, expect6, test_failed
LWU temp_data_1, 0x128(xfer)
BNE temp_data_1, expect7, test_failed

LWU temp_data_1, 0x140(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x144(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x148(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0x14c(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0x150(xfer)
BNE temp_data_1, expect5, test_failed
LWU temp_data_1, 0x154(xfer)
BNE temp_data_1, expect6, test_failed
LWU temp_data_1, 0x158(xfer)
BNE temp_data_1, expect7, test_failed 
LWU temp_data_1, 0x15c(xfer)
BNE temp_data_1, expect8, test_failed

LI   temp_data,0x3
ADDI count_dr,count_dr,1
BGE  temp_data,count_dr,loop_read_le_dr  

LI   temp_data,0x7
ADDI count,count,1
BGE  temp_data,count,loop_read_le

########################################
#########LWBE reads
########################################
LI xfer, CPP_MEM_ADDR  
ADD address, group_num, zero
LI count,0x0
#################write all defined data to cls sram
loop_read_be:
LI count_dr,0
loop_read_be_dr:
SLLI mydataref,count_dr,2  

##10111e1f 1a1b1c1d 16171819 12131415 90abcdef 12345678 fedcba09 87654321 00ffeedd ccbbaa99 88776655 44332211 
#1.addr 0x0  len[1:0] 00,01,10,11
ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x0,0x0)  ;
LI temp_data,0x40
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x1,0x0)  ;
LI temp_data,0x50
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x2,0x0)  ;
LI temp_data,0x70
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x3,0x0)  ;
LI temp_data,0x90
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x4,0x0)  ;
LI temp_data,0xb0
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x5,0x0)  ;
LI temp_data,0xe0
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x6,0x0)  ;
LI temp_data,0x110
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data   
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);

ADD address, group_num, count # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x7,0x0)  ;
LI temp_data,0x140
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG1_pos,1);


LI temp_data , 0x0
BEQ count, temp_data,readbe0_expect 
LI temp_data , 0x1
BEQ count, temp_data,readbe1_expect
LI temp_data , 0x2
BEQ count, temp_data,readbe2_expect
LI temp_data , 0x3
BEQ count, temp_data,readbe3_expect
LI temp_data , 0x4
BEQ count, temp_data,readbe4_expect 
LI temp_data , 0x5
BEQ count, temp_data,readbe5_expect
LI temp_data , 0x6
BEQ count, temp_data,readbe6_expect 
LI temp_data , 0x7
BEQ count, temp_data,readbe7_expect 

readbe0_expect:
LI expect1, 0x44332211
LI expect2, 0x88776655
LI expect3, 0xCCBBAA99
LI expect4, 0x00FFEEDD
LI expect5, 0x87654321
LI expect6, 0xfedcba09
LI expect7, 0x12345678
LI expect8, 0x90abcdef
J  readbe_compare_data

readbe1_expect:
LI expect1, 0x33221188
LI expect2, 0x776655cc
LI expect3, 0xbbaa9900
LI expect4, 0xffeedd87
LI expect5, 0x654321fe
LI expect6, 0xdcba0912
LI expect7, 0x34567890
LI expect8, 0xabcdef12
J  readbe_compare_data

readbe2_expect:
LI expect1, 0x22118877
LI expect2, 0x6655ccbb
LI expect3, 0xaa9900ff
LI expect4, 0xeedd8765
LI expect5, 0x4321fedc
LI expect6, 0xba091234
LI expect7, 0x567890ab
LI expect8, 0xcdef1213 
J  readbe_compare_data

readbe3_expect:
LI expect1, 0x11887766
LI expect2, 0x55ccbbaa
LI expect3, 0x9900ffee
LI expect4, 0xdd876543
LI expect5, 0x21fedcba
LI expect6, 0x09123456
LI expect7, 0x7890abcd
LI expect8, 0xef121314 
J  readbe_compare_data 

readbe4_expect:
LI expect1, 0x88776655
LI expect2, 0xccbbaa99
LI expect3, 0x00ffeedd
LI expect4, 0x87654321
LI expect5, 0xfedcba09
LI expect6, 0x12345678
LI expect7, 0x90abcdef
LI expect8, 0x12131415 
J  readbe_compare_data

readbe5_expect:
LI expect1, 0x776655cc
LI expect2, 0xbbaa9900
LI expect3, 0xffeedd87
LI expect4, 0x654321fe
LI expect5, 0xdcba0912
LI expect6, 0x34567890
LI expect7, 0xabcdef12
LI expect8, 0x13141516 
J  readbe_compare_data   

readbe6_expect:
LI expect1, 0x6655ccbb
LI expect2, 0xaa9900ff
LI expect3, 0xeedd8765
LI expect4, 0x4321fedc
LI expect5, 0xba091234
LI expect6, 0x567890ab
LI expect7, 0xcdef1213
LI expect8, 0x14151617 
J  readbe_compare_data

readbe7_expect:
LI expect1, 0x55ccbbaa
LI expect2, 0x9900ffee
LI expect3, 0xdd876543
LI expect4, 0x21fedcba
LI expect5, 0x09123456
LI expect6, 0x7890abcd
LI expect7, 0xef121314
LI expect8, 0x15161718 
J  readbe_compare_data 

readbe_compare_data:

LI xfer, CPP_MEM_ADDR 
OR xfer,xfer,mydataref 

LWU temp_data_1, 0x40(xfer)
BNE temp_data_1, expect1, test_failed 

LWU temp_data_1, 0x50(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x54(xfer)
BNE temp_data_1, expect2, test_failed

LWU temp_data_1, 0x70(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x74(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x78(xfer)
BNE temp_data_1, expect3, test_failed

LWU temp_data_1, 0x90(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x94(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x98(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0x9c(xfer)
BNE temp_data_1, expect4, test_failed
                  
LWU temp_data_1, 0xb0(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0xb4(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0xb8(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0xbc(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0xc0(xfer)
BNE temp_data_1, expect5, test_failed

LWU temp_data_1, 0xe0(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0xe4(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0xe8(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0xec(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0xf0(xfer)
BNE temp_data_1, expect5, test_failed
LWU temp_data_1, 0xf4(xfer)
BNE temp_data_1, expect6, test_failed

LWU temp_data_1, 0x110(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x114(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x118(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0x11c(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0x120(xfer)
BNE temp_data_1, expect5, test_failed
LWU temp_data_1, 0x124(xfer)
BNE temp_data_1, expect6, test_failed
LWU temp_data_1, 0x128(xfer)
BNE temp_data_1, expect7, test_failed

LWU temp_data_1, 0x140(xfer)
BNE temp_data_1, expect1, test_failed
LWU temp_data_1, 0x144(xfer)
BNE temp_data_1, expect2, test_failed
LWU temp_data_1, 0x148(xfer)
BNE temp_data_1, expect3, test_failed 
LWU temp_data_1, 0x14c(xfer)
BNE temp_data_1, expect4, test_failed
LWU temp_data_1, 0x150(xfer)
BNE temp_data_1, expect5, test_failed
LWU temp_data_1, 0x154(xfer)
BNE temp_data_1, expect6, test_failed
LWU temp_data_1, 0x158(xfer)
BNE temp_data_1, expect7, test_failed 
LWU temp_data_1, 0x15c(xfer)
BNE temp_data_1, expect8, test_failed

LI   temp_data,0x3
ADDI count_dr,count_dr,1
BGE  temp_data,count_dr,loop_read_be_dr 

LI   temp_data,0x7
ADDI count,count,1
BGE  temp_data,count,loop_read_be 



#########################################
###  Aligned Byte writes
#########################################
LI xfer, CPP_MEM_ADDR 
LI temp_data_1, 0x00000000
SW temp_data_1, 0x0(xfer)
SW temp_data_1, 0x4(xfer)
SW temp_data_1, 0x8(xfer)
SW temp_data_1, 0xC(xfer)

LI temp_data_1, 0x44332211
SW temp_data_1, 0x20(xfer) 


ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;   


ADDI address, group_num, 0

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x2,0x20)  ;
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADDI address, group_num, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x2,0x20)  ;
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;


ADDI address, group_num, 0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x40)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

ADDI address, group_num, 8
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x0,0x50)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI expect1, 0x00332211
LI expect2, 0x44332200

LI temp_data_2, 0
LWU temp_data_2, 0x40(xfer)
BNE temp_data_2, expect1, test_failed

LWU temp_data_2, 0x50(xfer)
BNE temp_data_2, expect2, test_failed


NOP
NOP
NOP

###########################################################
# UnAligned Byte writes
###########################################################
LI xfer, CPP_MEM_ADDR 
LI count,0x0
#---------------------------------------
# LE :Byte =  7  6  5  4  3  2  1  0
# BE :Byte =  4  5  6  7  0  1  2  3
#     Data = 88 77 66 55 44 33 22 11
#
# LE 5 bytes of data = 55 44 33 22 11
# LE:  XX XX 55 44    33 22 11 XX
#
# LWBE: 5 bytes of data = 44 33 22 11 88 
# LWBE: 11 88 XX XX       XX 44 33 22 
#---------------------------------------
#write8_le and read_le
loop_write8_le:    #gen addr 0x0~0x7
LI count_dr,0
loop_write8_le_dr: #gen dataref[3:2] 0x0,0x4,0x8,0xc
LI temp_data_1, 0x0
SD temp_data_1, 0x0(xfer)
SD temp_data_1, 0x8(xfer) 
SD temp_data_1, 0x10(xfer)
SD temp_data_1, 0x18(xfer)

LI temp_data_1, 0x44332211
SW temp_data_1, 0x30(xfer)

LI temp_data_1, 0x88776655
SW temp_data_1, 0x34(xfer)

LI temp_data_1, 0xCCBBAA99
SW temp_data_1, 0x38(xfer)

LI temp_data_1, 0xFFEEDD00
SW temp_data_1, 0x3C(xfer)

LI temp_data_1, 0x12131415
SW temp_data_1, 0x40(xfer)

LI temp_data_1, 0x16171819
SW temp_data_1, 0x44(xfer)

LI temp_data_1, 0x20212223
SW temp_data_1, 0x48(xfer)

LI temp_data_1, 0x24252627
SW temp_data_1, 0x4c(xfer)

LI temp_data_1, 0x28293031
SW temp_data_1, 0x50(xfer)

LI temp_data_1, 0x30313233
SW temp_data_1, 0x54(xfer)

LI temp_data_1, 0x34353637
SW temp_data_1, 0x58(xfer)

LI temp_data_1, 0x38394041
SW temp_data_1, 0x5c(xfer)

####Rewrite to 0's   
LI temp_data_1, 0x0
SD temp_data_1,0x60(xfer)
SD temp_data_1,0x70(xfer)
SD temp_data_1,0x80(xfer) 
SD temp_data_1,0x90(xfer)
SD temp_data_1,0xa0(xfer)
SD temp_data_1,0xb0(xfer)
SD temp_data_1,0xc0(xfer)
SD temp_data_1,0xd0(xfer) 
SD temp_data_1,0xe0(xfer)
SD temp_data_1,0xf0(xfer)
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
#SRLI temp_data,count_dr,1
SLLI mydataref,count_dr,2   


####write8_le len=0x0
to_write8_le:
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x0,0x0)  ;
LI temp_data,0x30
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x60)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_0_0expect
LI temp_data , 0x4
BEQ mydataref, temp_data,write8le_0_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_0_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_0_cexpect

write8le_0_0expect:
LI expect1, 0x11
LI expect2, 0x0  
J compare_write8le_0

write8le_0_4expect:
LI expect1, 0x55
LI expect2, 0x0  
J compare_write8le_0  

write8le_0_8expect:
LI expect1, 0x99
LI expect2, 0x0  
J compare_write8le_0

write8le_0_cexpect:
LI expect1, 0x00
LI expect2, 0x0  
J compare_write8le_0



compare_write8le_0:
LWU temp_data_2, 0x60(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x64(xfer)
BNE temp_data_2, expect2, test_failed
####write8_le len=0x1
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x1,0x0)  ;
LI temp_data,0x34
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data   
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x70)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);


LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_1_0expect
LI temp_data , 0x4
BEQ mydataref, temp_data,write8le_1_4expect                                     
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_1_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_1_cexpect

write8le_1_0expect:
LI expect1, 0x6655
LI expect2, 0x0  
J compare_write8le_1

write8le_1_4expect:
LI expect1, 0xaa99
LI expect2, 0x0  
J compare_write8le_1  

write8le_1_8expect:
LI expect1, 0xdd00
LI expect2, 0x0  
J compare_write8le_1

write8le_1_cexpect:
LI expect1, 0x1415
LI expect2, 0x0  
J compare_write8le_1


compare_write8le_1:   
LI temp_data_2, 0
LWU temp_data_2, 0x70(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x74(xfer)
BNE temp_data_2, expect2, test_failed

####write8_le len=0x2
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x2,0x0)  ;
LI temp_data,0x38
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x80)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_2_0expect
LI temp_data , 0x4
BEQ mydataref, temp_data,write8le_2_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_2_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_2_cexpect

write8le_2_0expect:
LI expect1, 0xbbaa99
LI expect2, 0x0  
J compare_write8le_2

write8le_2_4expect:
LI expect1, 0xeedd00
LI expect2, 0x0  
J compare_write8le_2  

write8le_2_8expect:
LI expect1, 0x131415
LI expect2, 0x0  
J compare_write8le_2

write8le_2_cexpect:
LI expect1, 0x171819
LI expect2, 0x0  
J compare_write8le_2


compare_write8le_2:    

LI temp_data_2, 0
LWU temp_data_2, 0x80(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x84(xfer)
BNE temp_data_2, expect2, test_failed

####write8_le len=0x3
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x3,0x0)  ;
LI temp_data,0x3c
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x90)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_3_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8le_3_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_3_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_3_cexpect
                              
write8le_3_0expect:
LI expect1, 0xffeedd00
LI expect2, 0x0  
J compare_write8le_3

write8le_3_4expect:
LI expect1, 0x12131415
LI expect2, 0x0  
J compare_write8le_3  

write8le_3_8expect:
LI expect1, 0x16171819
LI expect2, 0x0  
J compare_write8le_3

write8le_3_cexpect:
LI expect1, 0x20212223
LI expect2, 0x0  
J compare_write8le_3


compare_write8le_3:  

LI temp_data_2, 0
LWU temp_data_2, 0x90(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x94(xfer)
BNE temp_data_2, expect2, test_failed

####write8_le len=0x4
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x4,0x0)  ;
LI temp_data,0x40
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xa0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_4_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8le_4_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_4_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_4_cexpect
                              
write8le_4_0expect:
LI expect1, 0x12131415
LI expect2, 0x19  
J compare_write8le_4

write8le_4_4expect:
LI expect1, 0x16171819
LI expect2, 0x23  
J compare_write8le_4  

write8le_4_8expect:
LI expect1, 0x20212223
LI expect2, 0x27 
J compare_write8le_4

write8le_4_cexpect:
LI expect1, 0x24252627
LI expect2, 0x31  
J compare_write8le_4


compare_write8le_4:

LI temp_data_2, 0
LWU temp_data_2, 0xa0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xa4(xfer)
BNE temp_data_2, expect2, test_failed

####write8_le len=0x5
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x5,0x0)  ;
LI temp_data,0x44
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xb0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_5_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8le_5_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_5_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_5_cexpect
                              
write8le_5_0expect:
LI expect1, 0x16171819
LI expect2, 0x2223  
J compare_write8le_5

write8le_5_4expect:
LI expect1, 0x20212223
LI expect2, 0x2627  
J compare_write8le_5  

write8le_5_8expect:
LI expect1, 0x24252627
LI expect2, 0x3031 
J compare_write8le_5

write8le_5_cexpect:
LI expect1, 0x28293031
LI expect2, 0x3233  
J compare_write8le_5


compare_write8le_5: 

LI temp_data_2, 0
LWU temp_data_2, 0xb0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xb4(xfer)
BNE temp_data_2, expect2, test_failed

####write8_le len=0x6
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x6,0x0)  ;
LI temp_data,0x48
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xc0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);


LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_6_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8le_6_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_6_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_6_cexpect
                              
write8le_6_0expect:
LI expect1, 0x20212223
LI expect2, 0x252627
J compare_write8le_6

write8le_6_4expect:
LI expect1, 0x24252627
LI expect2, 0x293031  
J compare_write8le_6  

write8le_6_8expect:
LI expect1, 0x28293031
LI expect2, 0x313233
J compare_write8le_6

write8le_6_cexpect:
LI expect1, 0x30313233
LI expect2, 0x353637
J compare_write8le_6


compare_write8le_6:  

LI temp_data_2, 0
LWU temp_data_2, 0xc0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xc4(xfer)
BNE temp_data_2, expect2, test_failed

####write8_le len=0x7
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x7,0x0)  ;
LI temp_data,0x4c
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xd0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_7_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8le_7_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_7_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_7_cexpect
                              
write8le_7_0expect:
LI expect1, 0x24252627
LI expect2, 0x28293031
J compare_write8le_7

write8le_7_4expect:
LI expect1, 0x28293031
LI expect2, 0x30313233  
J compare_write8le_7  

write8le_7_8expect:
LI expect1, 0x30313233
LI expect2, 0x34353637
J compare_write8le_7

write8le_7_cexpect:
LI expect1, 0x34353637
LI expect2, 0x38394041
J compare_write8le_7


compare_write8le_7:

LI temp_data_2, 0
LWU temp_data_2, 0xd0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xd4(xfer)
BNE temp_data_2, expect2, test_failed


####write8_le len=0x1f
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x1f,0x0)  ;
LI temp_data,0x30
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_le(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0xe0)  ;
.insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8le_31_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8le_31_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8le_31_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8le_31_cexpect
                              
write8le_31_0expect:
LI expect1, 0x44332211
LI expect2, 0x88776655
LI expect3, 0xCCBBAA99
LI expect4, 0xFFEEDD00
LI expect5, 0x12131415
LI expect6, 0x16171819
LI expect7, 0x20212223
LI expect8, 0x24252627

J compare_write8le_31

write8le_31_4expect:
LI expect1, 0x88776655
LI expect2, 0xCCBBAA99
LI expect3, 0xFFEEDD00
LI expect4, 0x12131415
LI expect5, 0x16171819
LI expect6, 0x20212223
LI expect7, 0x24252627
LI expect8, 0x28293031   
J compare_write8le_31  

write8le_31_8expect:
LI expect1, 0xCCBBAA99
LI expect2, 0xFFEEDD00
LI expect3, 0x12131415
LI expect4, 0x16171819
LI expect5, 0x20212223
LI expect6, 0x24252627
LI expect7, 0x28293031
LI expect8, 0x30313233 
J compare_write8le_31

write8le_31_cexpect:
LI expect1, 0xFFEEDD00
LI expect2, 0x12131415
LI expect3, 0x16171819
LI expect4, 0x20212223
LI expect5, 0x24252627
LI expect6, 0x28293031
LI expect7, 0x30313233
LI expect8, 0x34353637  
J compare_write8le_31


compare_write8le_31:

LI temp_data_2, 0
LWU temp_data_2, 0xe0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xe4(xfer)
BNE temp_data_2, expect2, test_failed
LWU temp_data_2, 0xe8(xfer)
BNE temp_data_2, expect3, test_failed
LWU temp_data_2, 0xec(xfer)
BNE temp_data_2, expect4, test_failed
LWU temp_data_2, 0xf0(xfer)
BNE temp_data_2, expect5, test_failed
LWU temp_data_2, 0xf4(xfer)
BNE temp_data_2, expect6, test_failed
LWU temp_data_2, 0xf8(xfer)
BNE temp_data_2, expect7, test_failed
LWU temp_data_2, 0xfc(xfer)
BNE temp_data_2, expect8, test_failed

LI   temp_data,0x3
ADDI count_dr,count_dr,1
BGE  temp_data,count_dr,loop_write8_le_dr  


LI   temp_data,0x7
ADDI count,count,1
BGE  temp_data,count,loop_write8_le


NOP
NOP
NOP


#write8_be and read_be
loop_write8_be:    #gen addr 0x0~0x7
LI count_dr,0
loop_write8_be_dr: #gen dataref[3:2] 0x0,0x4,0x8,0xc
LI temp_data_1, 0x0
SD temp_data_1, 0x0(xfer)
SD temp_data_1, 0x8(xfer) 
SD temp_data_1, 0x10(xfer)
SD temp_data_1, 0x18(xfer)

LI temp_data_1, 0x11223344
SW temp_data_1, 0x30(xfer)

LI temp_data_1, 0x55667788
SW temp_data_1, 0x34(xfer)

LI temp_data_1, 0x99aabbcc
SW temp_data_1, 0x38(xfer)

LI temp_data_1, 0x00ddeeff
SW temp_data_1, 0x3C(xfer)

LI temp_data_1, 0x15141312
SW temp_data_1, 0x40(xfer)

LI temp_data_1, 0x19181716
SW temp_data_1, 0x44(xfer)

LI temp_data_1, 0x23222120
SW temp_data_1, 0x48(xfer)

LI temp_data_1, 0x27262524
SW temp_data_1, 0x4c(xfer)

LI temp_data_1, 0x31302928
SW temp_data_1, 0x50(xfer)

LI temp_data_1, 0x33323130
SW temp_data_1, 0x54(xfer)

LI temp_data_1, 0x37363534
SW temp_data_1, 0x58(xfer)

LI temp_data_1, 0x41403938
SW temp_data_1, 0x5c(xfer)

####Rewrite to 0's   
LI temp_data_1, 0x0
SD temp_data_1,0x60(xfer)
SD temp_data_1,0x70(xfer)
SD temp_data_1,0x80(xfer) 
SD temp_data_1,0x90(xfer)
SD temp_data_1,0xa0(xfer)
SD temp_data_1,0xb0(xfer)
SD temp_data_1,0xc0(xfer)
SD temp_data_1,0xd0(xfer) 
SD temp_data_1,0xe0(xfer)
SD temp_data_1,0xf0(xfer)
ADD address, group_num, zero # set to initial value
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
#SRLI temp_data,count_dr,1
SLLI mydataref,count_dr,2   


####write8_be len=0x0
to_write8_be:
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x0,0x0)  ;
LI temp_data,0x30
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x60)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_0_0expect
LI temp_data , 0x4
BEQ mydataref, temp_data,write8be_0_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_0_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_0_cexpect

write8be_0_0expect:
LI expect1, 0x11000000
LI expect2, 0x0  
J compare_write8be_0

write8be_0_4expect:
LI expect1, 0x55000000
LI expect2, 0x0  
J compare_write8be_0  

write8be_0_8expect:
LI expect1, 0x99000000
LI expect2, 0x0  
J compare_write8be_0

write8be_0_cexpect:
LI expect1, 0x00000000
LI expect2, 0x0  
J compare_write8be_0



compare_write8be_0:
LWU temp_data_2, 0x60(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x64(xfer)
BNE temp_data_2, expect2, test_failed
####write8_be len=0x1
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x1,0x0)  ;
LI temp_data,0x34
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data   
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x70)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);


LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_1_0expect
LI temp_data , 0x4
BEQ mydataref, temp_data,write8be_1_4expect                                     
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_1_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_1_cexpect

write8be_1_0expect:
LI expect1, 0x55660000
LI expect2, 0x0  
J compare_write8be_1

write8be_1_4expect:
LI expect1, 0x99aa0000
LI expect2, 0x0  
J compare_write8be_1  

write8be_1_8expect:
LI expect1, 0x00dd0000
LI expect2, 0x0  
J compare_write8be_1

write8be_1_cexpect:
LI expect1, 0x15140000
LI expect2, 0x0  
J compare_write8be_1


compare_write8be_1:   
LI temp_data_2, 0
LWU temp_data_2, 0x70(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x74(xfer)
BNE temp_data_2, expect2, test_failed

####write8_be len=0x2
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x2,0x0)  ;
LI temp_data,0x38
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x80)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_2_0expect
LI temp_data , 0x4
BEQ mydataref, temp_data,write8be_2_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_2_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_2_cexpect

write8be_2_0expect:
LI expect1, 0x99aabb00
LI expect2, 0x0  
J compare_write8be_2

write8be_2_4expect:
LI expect1, 0x00ddee00
LI expect2, 0x0  
J compare_write8be_2  

write8be_2_8expect:
LI expect1, 0x15141300
LI expect2, 0x0  
J compare_write8be_2

write8be_2_cexpect:
LI expect1, 0x19181700
LI expect2, 0x0  
J compare_write8be_2


compare_write8be_2:    

LI temp_data_2, 0
LWU temp_data_2, 0x80(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x84(xfer)
BNE temp_data_2, expect2, test_failed

####write8_be len=0x3
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x3,0x0)  ;
LI temp_data,0x3c
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0x90)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_3_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8be_3_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_3_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_3_cexpect
                              
write8be_3_0expect:
LI expect1, 0x00ddeeff
LI expect2, 0x0  
J compare_write8be_3

write8be_3_4expect:
LI expect1, 0x15141312
LI expect2, 0x0  
J compare_write8be_3  

write8be_3_8expect:
LI expect1, 0x19181716
LI expect2, 0x0  
J compare_write8be_3

write8be_3_cexpect:
LI expect1, 0x23222120
LI expect2, 0x0  
J compare_write8be_3


compare_write8be_3:  

LI temp_data_2, 0
LWU temp_data_2, 0x90(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0x94(xfer)
BNE temp_data_2, expect2, test_failed

####write8_be len=0x4
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x4,0x0)  ;
LI temp_data,0x40
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xa0)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_4_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8be_4_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_4_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_4_cexpect
                              
write8be_4_0expect:
LI expect1, 0x15141312
LI expect2, 0x19000000  
J compare_write8be_4

write8be_4_4expect:
LI expect1, 0x19181716
LI expect2, 0x23000000  
J compare_write8be_4  

write8be_4_8expect:
LI expect1, 0x23222120
LI expect2, 0x27000000 
J compare_write8be_4

write8be_4_cexpect:
LI expect1, 0x27262524
LI expect2, 0x31000000  
J compare_write8be_4


compare_write8be_4:

LI temp_data_2, 0
LWU temp_data_2, 0xa0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xa4(xfer)
BNE temp_data_2, expect2, test_failed

####write8_be len=0x5
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x5,0x0)  ;
LI temp_data,0x44
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xb0)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_5_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8be_5_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_5_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_5_cexpect
                              
write8be_5_0expect:
LI expect1, 0x19181716
LI expect2, 0x23220000  
J compare_write8be_5

write8be_5_4expect:
LI expect1, 0x23222120
LI expect2, 0x27260000  
J compare_write8be_5  

write8be_5_8expect:
LI expect1, 0x27262524
LI expect2, 0x31300000 
J compare_write8be_5

write8be_5_cexpect:
LI expect1, 0x31302928
LI expect2, 0x33320000  
J compare_write8be_5


compare_write8be_5: 

LI temp_data_2, 0
LWU temp_data_2, 0xb0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xb4(xfer)
BNE temp_data_2, expect2, test_failed

####write8_be len=0x6
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x6,0x0)  ;
LI temp_data,0x48
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xc0)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);


LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_6_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8be_6_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_6_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_6_cexpect
                              
write8be_6_0expect:
LI expect1, 0x23222120
LI expect2, 0x27262500
J compare_write8be_6

write8be_6_4expect:
LI expect1, 0x27262524
LI expect2, 0x31302900  
J compare_write8be_6  

write8be_6_8expect:
LI expect1, 0x31302928
LI expect2, 0x33323100
J compare_write8be_6

write8be_6_cexpect:
LI expect1, 0x33323130
LI expect2, 0x37363500
J compare_write8be_6


compare_write8be_6:  

LI temp_data_2, 0
LWU temp_data_2, 0xc0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xc4(xfer)
BNE temp_data_2, expect2, test_failed

####write8_be len=0x7
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x7,0x0)  ;
LI temp_data,0x4c
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x1,0xd0)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_7_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8be_7_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_7_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_7_cexpect
                              
write8be_7_0expect:
LI expect1, 0x27262524
LI expect2, 0x31302928
J compare_write8be_7

write8be_7_4expect:
LI expect1, 0x31302928
LI expect2, 0x33323130  
J compare_write8be_7  

write8be_7_8expect:
LI expect1, 0x33323130
LI expect2, 0x37363534
J compare_write8be_7

write8be_7_cexpect:
LI expect1, 0x37363534
LI expect2, 0x41403938
J compare_write8be_7


compare_write8be_7:

LI temp_data_2, 0
LWU temp_data_2, 0xd0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xd4(xfer)
BNE temp_data_2, expect2, test_failed


####write8_be len=0x1f
ADD address, group_num, count
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x20,0x1f,0x0)  ;
LI temp_data,0x30
ADD temp_data,temp_data,mydataref
OR cppcmd_data_ref,cppcmd_data_ref,temp_data
.insn s 43,0,address,cluster_scratch_write8_be(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;

ADD address, group_num, count #
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x7,0xe0)  ;
.insn s 43,0,address,cluster_scratch_read_be(cppcmd_data_ref)	 ;# CPP Command read

WAIT_ON_SIGNAL (SIG3_pos,1);

LI temp_data , 0x0
BEQ mydataref, temp_data,write8be_31_0expect
LI temp_data , 0x4            
BEQ mydataref, temp_data,write8be_31_4expect
LI temp_data , 0x8
BEQ mydataref, temp_data,write8be_31_8expect
LI temp_data , 0xc
BEQ mydataref, temp_data,write8be_31_cexpect
                              
write8be_31_0expect:
LI expect1, 0x11223344
LI expect2, 0x55667788
LI expect3, 0x99aabbcc
LI expect4, 0x00ddeeff
LI expect5, 0x15141312
LI expect6, 0x19181716
LI expect7, 0x23222120
LI expect8, 0x27262524

J compare_write8be_31

write8be_31_4expect:
LI expect1, 0x55667788
LI expect2, 0x99aabbcc
LI expect3, 0x00ddeeff
LI expect4, 0x15141312
LI expect5, 0x19181716
LI expect6, 0x23222120
LI expect7, 0x27262524
LI expect8, 0x31302928   
J compare_write8be_31  

write8be_31_8expect:
LI expect1, 0x99aabbcc
LI expect2, 0x00ddeeff
LI expect3, 0x15141312
LI expect4, 0x19181716
LI expect5, 0x23222120
LI expect6, 0x27262524
LI expect7, 0x31302928
LI expect8, 0x33323130 
J compare_write8be_31

write8be_31_cexpect:
LI expect1, 0x00ddeeff
LI expect2, 0x15141312
LI expect3, 0x19181716
LI expect4, 0x23222120
LI expect5, 0x27262524
LI expect6, 0x31302928
LI expect7, 0x33323130
LI expect8, 0x37363534  
J compare_write8be_31


compare_write8be_31:

LI temp_data_2, 0
LWU temp_data_2, 0xe0(xfer)
BNE temp_data_2, expect1, test_failed
LWU temp_data_2, 0xe4(xfer)
BNE temp_data_2, expect2, test_failed
LWU temp_data_2, 0xe8(xfer)
BNE temp_data_2, expect3, test_failed
LWU temp_data_2, 0xec(xfer)
BNE temp_data_2, expect4, test_failed
LWU temp_data_2, 0xf0(xfer)
BNE temp_data_2, expect5, test_failed
LWU temp_data_2, 0xf4(xfer)
BNE temp_data_2, expect6, test_failed
LWU temp_data_2, 0xf8(xfer)
BNE temp_data_2, expect7, test_failed
LWU temp_data_2, 0xfc(xfer)
BNE temp_data_2, expect8, test_failed

LI   temp_data,0x3
ADDI count_dr,count_dr,1
BGE  temp_data,count_dr,loop_write8_be_dr  


LI   temp_data,0x7
ADDI count,count,1
BGE  temp_data,count,loop_write8_be  



NOP
NOP
NOP


ADD address, group_num, zero


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
