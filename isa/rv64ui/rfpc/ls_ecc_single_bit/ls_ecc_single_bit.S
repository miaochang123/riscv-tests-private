#;-----------------------
#; TEST_NAME: ls_ecc_single_bit.uc
#;	local_scratch is pre-initialized(see nome_mei_ucode_test_lib.sv) with:
#;		64 elements of all 0's each with a single bit error in a different position
#;		64 elements of all 1's each with a single bit error in a different position
#;	Verify that all are corrected correctly
#;	Read Single Bit error event count at end of test
#;-----------------------  

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

#define expect0       x11
#define expect1       x12
#define expect2       x13
#define data_cmp      x14
#define xpb_base      x15
#define mask          x16
#define base          x19
#define address0      x20
#define address1      x21
#define cl_num        x22
#define group_num     x23
#define temp_data     x24
#define temp_data_1   x25
#define temp_data_2   x26
#define xfer  x27


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
LI temp_data, WR_DATA0A
SW temp_data, 0x0(xfer)
LI temp_data, WR_DATA1A
SW temp_data, 0x4(xfer)
LI temp_data, WR_DATA2A
SW temp_data, 0x8(xfer)
LI temp_data, WR_DATA3A
SW temp_data, 0xC(xfer)


##write all data to ecc_mon
LI xpb_base, 0x000d0000  ##misc engine command address
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0)  ;
.insn s 43,0,xpb_base,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG2_pos,1) 	;


############################################
#####initial cpp memory and to cls sram
############################################

LI address0, 0x00000000
ADDI address1, address0, 0x200

LI expect1, 0xffffffff
#######################################
########EventFilter0
#######################################
LI base, 0x00020000
ADDI base, base, FILTER_MASK
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x8)  ;
.insn s 43,0,base,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;

##; Match on event 10  which is event = Single Bit ECC error
LI base, 0x00020000
ADDI base, base, FILTER_MATCH
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0xC)  ;
.insn s 43,0,base,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;


LI count, 32
read_loop:
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x3,0x3a0)  ;
    .insn s 43,0,address0,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG3_pos,1);

    LI temp_data_1, 0
    LI expect0,     0

    LWU temp_data_1, 0x3a0(xfer)
    BNE temp_data_1, expect0, test_failed

    LWU temp_data_1, 0x3a4(xfer)
    BNE temp_data_1, expect0, test_failed

    LWU temp_data_1, 0x3a8(xfer)
    BNE temp_data_1, expect0, test_failed

    LWU temp_data_1, 0x3aC(xfer)
    BNE temp_data_1, expect0, test_failed

    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG3,0x0,0x0,0x3,0x3b0)  ;
    .insn s 43,0,address1,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
    WAIT_ON_SIGNAL (SIG3_pos,1);

    LI temp_data_1, 0
    LWU temp_data_1, 0x3b0(xfer)
    BNE temp_data_1, expect1, test_failed

    LWU temp_data_1, 0x3b4(xfer)
    BNE temp_data_1, expect1, test_failed

    LWU temp_data_1, 0x3b8(xfer)
    BNE temp_data_1, expect1, test_failed

    LWU temp_data_1, 0x3bC(xfer)
    BNE temp_data_1, expect1, test_failed

    ADDI address0, address0, 0x10
    ADDI address1, address1, 0x10

LI expect2, 1
SUB count, count, expect2
BNE count, expect0, read_loop

NOP
NOP
NOP

##;-----------------------------------------------
##; Reading EventFilter0 status
##;   Verifying that Event count = 128
##;-----------------------------------------------
LI base, 0x00020000
ADDI base, base, FILTER_STATUS

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x3c0)  ;
.insn s 43,0,base,cluster_scratch_read_le(cppcmd_data_ref)	 ;# CPP Command read
WAIT_ON_SIGNAL (SIG2_pos,1);

LI expect2, 128
LI temp_data_1, 0
LWU temp_data_1, 0x3c0(xfer)
BNE temp_data_1, expect2, test_failed

LI mask, 0xFFFF
### use xpb_read to read ECCMON reg ########################
##// XPB: READ: 0x20 First ECCError
##//   Address = [15:0], mask out compare of other bits
LI xpb_base, 0x000d0000  ##misc engine command address
ADDI xpb_base, xpb_base, 0x20

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x160)  ;
.insn s 43,0,xpb_base,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect2, 0
LI temp_data_1, 0
LWU temp_data_1, 0x160(xfer)
AND data_cmp, temp_data_1, mask
BNE data_cmp, expect2, test_failed

##// XPB: READ: 0x24 Last ECCError
##//   Address = [15:0], mask out compare of other bits
LI xpb_base, 0x000d0000  ##misc engine command address
ADDI xpb_base, xpb_base, 0x24

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x170)  ;
.insn s 43,0,xpb_base,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect2, 127
LI temp_data_1, 0
LWU temp_data_1, 0x170(xfer)
AND data_cmp, temp_data_1, mask
BNE data_cmp, expect2, test_failed


##// XPB: READ: 0x28 Error Count
##//   Single Bit Error_count [15:0]
##//   Multi Bit Error count [31:16]
LI xpb_base, 0x000d0000  ##misc engine command address
ADDI xpb_base, xpb_base, 0x28

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x180)  ;
.insn s 43,0,xpb_base,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect2, 128
LI temp_data_1, 0
LWU temp_data_1, 0x180(xfer)
BNE temp_data_1, expect2, test_failed


##// XPB: READ: 0x2c Error Count Resets
LI xpb_base, 0x000d0000  ##misc engine command address
ADDI xpb_base, xpb_base, 0x2C

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x190)  ;
.insn s 43,0,xpb_base,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect2, 128
LI temp_data_1, 0
LWU temp_data_1, 0x190(xfer)
BNE temp_data_1, expect2, test_failed


##// XPB: READ: 0x2c Error Count Resets (should be 0 now)
LI xpb_base, 0x000d0000  ##misc engine command address
ADDI xpb_base, xpb_base, 0x2C

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1a0)  ;
.insn s 43,0,xpb_base,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

LI expect2, 0
LI temp_data_1, 0
LWU temp_data_1, 0x1a0(xfer)
BNE temp_data_1, expect2, test_failed


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


