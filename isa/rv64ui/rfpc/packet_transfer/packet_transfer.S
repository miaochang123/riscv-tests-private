#-----------------------
# TEST_NAME: rfpc_packet_transfer
#     Packet alloc request and write the packet data in Me0 
#     Check the packet data in Me1
#-----------------------
	
	
#ifndef _ENV_PHYSICAL_MULTI_CORE_H

#define _ENV_PHYSICAL_MULTI_CORE_H

#include "riscv_test.h"

#include "test_macros.h"

#undef RISCV_MULTICORE_DISABLE
#define RISCV_MULTICORE_DISABLE

#endif 
#include "cpp_command_macros.h"
#include "rfpc_cmd_defines.h"
#include "rfpc_addr_defines.h"
RVTEST_RV64U
RVTEST_CODE_BEGIN

#define cpp_addr        s1
#define	cpp_rs1         s2 
#define cppcmd_data_ref s3
#define address         s4
#define xfer            s5
#define loop_cnt        s7


#define cl_num          a4
#define group_num       a5
#define	packet_number   a6

#define temp_data       t1
#define temp_data_1     t2
#define temp_data_2     t4
#define temp_data_3     t6

.equ CPP_MEM_ADDR,     0xf0000000

.equ packet_data_0 ,   0x62cfe21a
.equ packet_data_1 ,   0x9b7e4015
.equ packet_data_2 ,   0x21e6ad58
.equ packet_data_3 ,   0x8100ce22
.equ packet_data_4 ,   0x0800451a
.equ packet_data_5 ,   0x00ee9698
.equ packet_data_6 ,   0xed5911d5
.equ packet_data_7 ,   0x18559134
.equ packet_data_8 ,   0xfcae48f6
.equ packet_data_9 ,   0x3501b13c
.equ packet_data_10,   0x86149690
.equ packet_data_11,   0x6be23938
.equ packet_data_12,   0x52ec66a5
.equ packet_data_13,   0x9fafd7db
.equ packet_data_14,   0x8643f27a
.equ packet_data_15,   0x1912a8e5
.equ packet_data_16,   0x018fb8a2
.equ packet_data_17,   0xc25be93f
.equ packet_data_18,   0xd57bbfaa
.equ packet_data_19,   0xba4aaf8e
.equ packet_data_20,   0x1bfaa441
.equ packet_data_21,   0x00c86307
.equ packet_data_22,   0x8f47e984
.equ packet_data_23,   0xb9b10127
.equ packet_data_24,   0x436d87a0
.equ packet_data_25,   0x89f03df1
.equ packet_data_26,   0xe42f2722
.equ packet_data_27,   0x995a09df
.equ packet_data_28,   0x536783b5
.equ packet_data_29,   0x23092dc3
.equ packet_data_30,   0x9b3dcf23
.equ packet_data_31,   0xbc34e31b
.equ packet_data_32,   0x77ca33d4
.equ packet_data_33,   0xa4b8a4ad
.equ packet_data_34,   0xff09ad2a
.equ packet_data_35,   0xd1cc9f72
.equ packet_data_36,   0x281fe96a
.equ packet_data_37,   0x92a28e15
.equ packet_data_38,   0x2b6be31
.equ packet_data_39,   0xe1e3c895
.equ packet_data_40,   0x0ce668ee
.equ packet_data_41,   0xe04ae0d9
.equ packet_data_42,   0xc0b3c4ec
.equ packet_data_43,   0x00d62a2e
.equ packet_data_44,   0xbdff2d03
.equ packet_data_45,   0xd744e10f
.equ packet_data_46,   0xf37bc16f
.equ packet_data_47,   0xa8dee4b1
.equ packet_data_48,   0x6a212ecf
.equ packet_data_49,   0x1cbe3628
.equ packet_data_50,   0x0f094776
.equ packet_data_51,   0xb120b523
.equ packet_data_52,   0x6c6f2a88
.equ packet_data_53,   0xde5bbb97
.equ packet_data_54,   0x514eb6f0
.equ packet_data_55,   0xf29697d7
.equ packet_data_56,   0xaf167732
.equ packet_data_57,   0x296418e5
.equ packet_data_58,   0x276d4aa0
.equ packet_data_59,   0x83c49316
.equ packet_data_60,   0x0a045391
.equ packet_data_61,   0x57481c35
.equ packet_data_62,   0xd8df1384
.equ packet_data_63,   0xa549e1ca


LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5   # group number move to  4  - F gggg # group number move to  00 0ggg 0000
ANDI cl_num ,a0, 0xf               # core number
OR  group_num , group_num , cl_num # set group number as ggg_cccc 

LI temp_data_1 , 0x9
BGE group_num , temp_data_1, test_passed # Only run in rfpc_cluster0 & rfpc_group0 & (core0 and core1)

LI temp_data_1 , 0x7
BGE group_num , temp_data_1, send_packet # Only run in rfpc_cluster0 & rfpc_group0 & core1

ctm_init:
    LI address,CPP_MEM_ADDR
    LI xfer, 0x0F
    SW xfer, 0x0(address)
    LI cpp_addr, 0x00070180   ##configure owner 0 space mask
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1)
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,ct_xpb_read(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG2_pos,1)


   
alloc_packet:  # Only run in rfpc_cluster0 & rfpc_group0 & core0
    LI cpp_addr, 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_packet_alloc_poll(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1)
    LI address, CPP_MEM_ADDR
    LI packet_number, 0
    LI xfer, 0
    LW xfer, 0x0(address)
    LI temp_data_1, 0xffffffff
    AND xfer, xfer, temp_data_1
    BEQ xfer, temp_data_1, test_failed
    SRLI packet_number, xfer, 20   ## packet number
  
store_packet_to_ctm:  
    LI xfer, CPP_MEM_ADDR 
    SLLI temp_data, packet_number, 14   ## init packet number in matadata
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_1
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_2
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_3
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_4
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_5
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_6
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_7
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_8
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_9
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_10
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_11
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_12
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_13
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_14
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_15
    SW temp_data, 0x3C(xfer)

    LI cpp_addr, 0x0
    SLLI temp_data, packet_number, 8
    ADD cpp_addr, cpp_addr, temp_data
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x7,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_write(cppcmd_data_ref)	 # CPP Command write
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 # CPP Command read
    WAIT_ON_SIGNAL (SIG5_pos,2)                                  # wait twice signal

    LI temp_data, packet_data_16
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_17
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_18
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_19
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_20
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_21
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_22
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_23
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_24
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_25
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_26
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_27
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_28
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_29
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_30
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_31
    SW temp_data, 0x3C(xfer)

    
    ADDI cpp_addr, cpp_addr, 0x40
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x7,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_write(cppcmd_data_ref)	 # CPP Command write
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 # CPP Command read
    WAIT_ON_SIGNAL (SIG5_pos,2)                                  # wait twice signal

    LI temp_data, packet_data_32
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_33
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_34
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_35
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_36
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_37
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_38
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_39
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_40
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_41
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_42
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_43
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_44
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_45
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_46
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_47
    SW temp_data, 0x3C(xfer)

    ADDI cpp_addr, cpp_addr, 0x40
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x7,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_write(cppcmd_data_ref)	 # CPP Command write
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 # CPP Command read
    WAIT_ON_SIGNAL (SIG5_pos,2)                                  # wait twice signal

    LI temp_data, packet_data_48
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_49
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_50
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_51
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_52
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_53
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_54
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_55
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_56
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_57
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_58
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_59
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_60
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_61
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_62
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_63
    SW temp_data, 0x3C(xfer)

    ADDI cpp_addr, cpp_addr, 0x40
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0x7,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_write(cppcmd_data_ref)	 # CPP Command write
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 # CPP Command read
    WAIT_ON_SIGNAL (SIG5_pos,2)                                  # wait twice signal

store_packet_to_cpp_share_mem:  
    LI xfer, 0XE0000000
    SLLI temp_data, packet_number, 14   ## init packet number in matadata
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_1
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_2
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_3
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_4
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_5
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_6
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_7
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_8
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_9
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_10
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_11
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_12
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_13
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_14
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_15
    SW temp_data, 0x3C(xfer)

    ADDI xfer, xfer, 0x40
    LI temp_data, packet_data_16
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_17
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_18
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_19
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_20
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_21
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_22
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_23
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_24
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_25
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_26
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_27
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_28
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_29
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_30
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_31
    SW temp_data, 0x3C(xfer)
    
    ADDI xfer, xfer, 0x40
    LI temp_data, packet_data_32
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_33
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_34
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_35
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_36
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_37
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_38
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_39
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_40
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_41
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_42
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_43
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_44
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_45
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_46
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_47
    SW temp_data, 0x3C(xfer)

    ADDI xfer, xfer, 0x40
    LI temp_data, packet_data_48
    SW temp_data, 0x0(xfer)
    LI temp_data, packet_data_49
    SW temp_data, 0x4(xfer)
    LI temp_data, packet_data_50
    SW temp_data, 0x8(xfer)
    LI temp_data, packet_data_51
    SW temp_data, 0xC(xfer)
    LI temp_data, packet_data_52
    SW temp_data, 0x10(xfer)
    LI temp_data, packet_data_53
    SW temp_data, 0x14(xfer)
    LI temp_data, packet_data_54
    SW temp_data, 0x18(xfer)
    LI temp_data, packet_data_55
    SW temp_data, 0x1C(xfer)
    LI temp_data, packet_data_56
    SW temp_data, 0x20(xfer)
    LI temp_data, packet_data_57
    SW temp_data, 0x24(xfer)
    LI temp_data, packet_data_58
    SW temp_data, 0x28(xfer)
    LI temp_data, packet_data_59
    SW temp_data, 0x2C(xfer)
    LI temp_data, packet_data_60
    SW temp_data, 0x30(xfer)
    LI temp_data, packet_data_61
    SW temp_data, 0x34(xfer)
    LI temp_data, packet_data_62
    SW temp_data, 0x38(xfer)
    LI temp_data, packet_data_63
    SW temp_data, 0x3C(xfer)

issue_add_packet_to_ctm:
    ADDI cpp_addr, packet_number, 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_packet_add_packet(cppcmd_data_ref)	 # CPP Command add packet
    J test_passed

send_packet:  # Only run in rfpc_cluster0 & rfpc_group0 & core1
    LI cpp_addr, 6 #set the start offset:24B
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG2,0x0,0x0,0x1F,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_packet_add_thread(cppcmd_data_ref)	 # CPP Command add thread
    WAIT_ON_SIGNAL (SIG2_pos,1)   

    LI xfer, CPP_MEM_ADDR  ## load the packet number
    LD temp_data, 0x0(xfer)
    SRLI packet_number, temp_data, 14
    ANDI packet_number, packet_number, 0x3FF
    LI loop_cnt, 0
    SLLI cpp_addr, packet_number, 8

check_packet_data:
    SLLI temp_data, loop_cnt, 3
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG4,0x0,0x0,0x0,0x200) 
    OR cppcmd_data_ref, cppcmd_data_ref, temp_data
    .insn s 43,0,cpp_addr,memory_unit_read(cppcmd_data_ref)	 # CPP Command read
    WAIT_ON_SIGNAL (SIG4_pos,1)
    ADDI cpp_addr, cpp_addr, 8
    LI temp_data_1, 16
    BGE loop_cnt, temp_data_1, check_packet_data_last_128B
    LD temp_data_1, 0x0(xfer)
    LD temp_data_2, 0x200(xfer)
    BNE temp_data_1, temp_data_2, test_failed
    LI  xfer, 0xE0000000
    ADD xfer, xfer, temp_data
    LD temp_data_3, 0x0(xfer)
    BNE temp_data_3, temp_data_2, test_failed
    ADDI loop_cnt, loop_cnt, 1
    J check_packet_data	
check_packet_data_last_128B:
    LI xfer, CPP_MEM_ADDR  ## load the packet number from matadata
    ADD xfer, xfer, temp_data
    LD temp_data_2, 0x200(xfer)
    LI  xfer, 0xE0000000
    ADD xfer, xfer, temp_data
    LD temp_data_3, 0x0(xfer)
    BNE temp_data_3, temp_data_2, test_failed	
    ADDI loop_cnt, loop_cnt, 1
    LI temp_data, 32
    BLT loop_cnt, temp_data, check_packet_data
	
    
issue_free_packet:
    ADDI cpp_addr, packet_number, 0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x0) 
    .insn s 43,0,cpp_addr,memory_unit_packet_free_and_signal(cppcmd_data_ref)	 # CPP Command free packet 
    WAIT_ON_SIGNAL (SIG1_pos,1)   
    J test_passed

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
