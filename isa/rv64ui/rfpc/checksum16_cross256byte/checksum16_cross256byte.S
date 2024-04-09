#-----------------------
# TEST_NAME: rfpc_ctm_rw_all.uc
#     Reads and writes unique values to entire CTM memory 
#	
#   10/11/2012: Updated to run on 8 MES (Each ME reads/writes 1/8th of CTM memory
#   12/01/2022: modified to run on rfpc with update 128 cores Each core reads/writes 1/128th of CTM memory
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
#include "test_macros.h"
	
#define zero   x0 # zero register
#define temp_data   x5
#define temp_data_1   x6
#define temp_data_2   x7

#define exp_checksum_inv x12
#define exp_checksum_no_inv x13
#define csum16_result_inv   x14
#define csum16_result_no_inv x15
#define data_counter x16

#define cppcmd_data_ref x18
#define address   x19
#define cl_num        x20
#define group_num        x21
#define byte_len   x22
#define xfer x23
#define test_num x24
#define byte_counter x25
#define temp_data_3   x26
#define temp_data_4   x27
#define temp_data_5   x29
#define temp_data_6   x31
	
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

.equ CRC_DATA0,      0x112233D81B800031
.equ CRC_DATA1,      0x112233FC044C0300
.equ CRC_DATA2,      0x112233F0000C0042
.equ CRC_DATA3,      0x11223395941BFD42
.equ CRC_DATA4,      0x11223384342B3D42
.equ CRC_DATA5,      0x112233AA842C1042
.equ CRC_DATA6,      0x112233D81B808121
.equ CRC_DATA7,      0x11223390840106C0
.equ CRC_DATA8,      0x1122339A240902C2
.equ CRC_DATA9,      0x112233F000012700
.equ CRC_DATA10,     0x112233F0000C0047
.equ CRC_DATA11,     0x112233F0000C0043
.equ CRC_DATA12,     0x112233F000113300
.equ CRC_DATA13,     0x112233F001211734
.equ CRC_DATA14,     0x112233F445611778
.equ CRC_DATA15,     0x112233FC14A11700
.equ CRC_DATA16,     0x112233F000411F00
.equ CRC_DATA17,     0x1122338064511DC0
.equ CRC_DATA18,     0x1122339084811DC0
.equ CRC_DATA19,     0x11223381441B0242
.equ CRC_DATA20,     0x112233FC076C0300
.equ CRC_DATA21,     0x112233F000011B10
.equ CRC_DATA22,     0x112233FC148C0300
.equ CRC_DATA23,     0x112233F0000C0040
.equ CRC_DATA24,     0x112233A0571C0040
.equ CRC_DATA25,     0x112233B2C4BC0040
.equ CRC_DATA26,     0x1122339104AB0140
.equ CRC_DATA27,     0x112233A084312843
.equ CRC_DATA28,     0x112233D007C34443
.equ CRC_DATA29,     0x112233A0843C0443
.equ CRC_DATA30,     0x112233F4400C0043
.equ CRC_DATA31,     0x112233A084312C43

.equ TEST2_DATA0,      0xD83322113100801B  
.equ TEST2_DATA1,      0xFC33221100034C04
.equ TEST2_DATA2,      0xF033221142000C00
.equ TEST2_DATA3,      0x9533221142FD1B94
.equ TEST2_DATA4,      0x84332211423D2B34
.equ TEST2_DATA5,      0xAA33221142102C84
.equ TEST2_DATA6,      0xD83322112181801B
.equ TEST2_DATA7,      0x90332211C0060184
.equ TEST2_DATA8,      0x9A332211C2020924
.equ TEST2_DATA9,      0xF033221100270100
.equ TEST2_DATA10,     0xF033221147000C00
.equ TEST2_DATA11,     0xF033221143000C00
.equ TEST2_DATA12,     0xF033221100331100
.equ TEST2_DATA13,     0xF033221134172101
.equ TEST2_DATA14,     0xF433221178176145
.equ TEST2_DATA15,     0xFC3322110017A114
.equ TEST2_DATA16,     0xF0332211001F4100
.equ TEST2_DATA17,     0x80332211C01D5164
.equ TEST2_DATA18,     0x90332211C01D8184 
.equ TEST2_DATA19,     0x8133221142021B44
.equ TEST2_DATA20,     0xFC33221100036C07
.equ TEST2_DATA21,     0xF0332211101B0100
.equ TEST2_DATA22,     0xFC33221100038C14
.equ TEST2_DATA23,     0xF033221140000C00
.equ TEST2_DATA24,     0xA033221140001C57
.equ TEST2_DATA25,     0xB23322114000BCC4
.equ TEST2_DATA26,     0x913322114001AB04
.equ TEST2_DATA27,     0xA033221143283184
.equ TEST2_DATA28,     0xD03322114344C307
.equ TEST2_DATA29,     0xA033221143043C84
.equ TEST2_DATA30,     0xF433221143000C40
.equ TEST2_DATA31,     0xA0330011432C3184  # 0xA0332211432C3184


.equ TEST3_DATA0,      0x04D8332211310080  
.equ TEST3_DATA1,      0x00FC33221100034C
.equ TEST3_DATA2,      0x94F033221142000C
.equ TEST3_DATA3,      0x349533221142FD1B
.equ TEST3_DATA4,      0x8484332211423D2B
.equ TEST3_DATA5,      0x1BAA33221142102C
.equ TEST3_DATA6,      0x84D8332211218180
.equ TEST3_DATA7,      0x2490332211C00601
.equ TEST3_DATA8,      0x009A332211C20209
.equ TEST3_DATA9,      0x00F0332211002701
.equ TEST3_DATA10,     0x00F033221147000C
.equ TEST3_DATA11,     0x00F033221143000C
.equ TEST3_DATA12,     0x01F0332211003311
.equ TEST3_DATA13,     0x45F0332211341721
.equ TEST3_DATA14,     0x14F4332211781761
.equ TEST3_DATA15,     0x00FC3322110017A1
.equ TEST3_DATA16,     0x64F0332211001F41
.equ TEST3_DATA17,     0x8480332211C01D51
.equ TEST3_DATA18,     0x4490332211C01D81 
.equ TEST3_DATA19,     0x078133221142021B
.equ TEST3_DATA20,     0x00FC33221100036C
.equ TEST3_DATA21,     0x14F0332211101B01
.equ TEST3_DATA22,     0x00FC33221100038C
.equ TEST3_DATA23,     0x57F033221140000C
.equ TEST3_DATA24,     0xC4A033221140001C
.equ TEST3_DATA25,     0x04B23322114000BC
.equ TEST3_DATA26,     0x84913322114001AB
.equ TEST3_DATA27,     0x07A0332211432831
.equ TEST3_DATA28,     0x84D03322114344C3
.equ TEST3_DATA29,     0x40A033221143043C
.equ TEST3_DATA30,     0x84F433221143000C
.equ TEST3_DATA31,     0x00A0332211432C31   # 0xA0332211432C3184

.equ TEST4_DATA0,      0x04D8332211310080  
.equ TEST4_DATA1,      0x00FC33221100034C
.equ TEST4_DATA2,      0x94F033221142000C
.equ TEST4_DATA3,      0x349533221142FD1B
.equ TEST4_DATA4,      0x8484332211423D2B
.equ TEST4_DATA5,      0x1BAA33221142102C
.equ TEST4_DATA6,      0x84D8332211218180
.equ TEST4_DATA7,      0x2490332211C00601
.equ TEST4_DATA8,      0x009A332211C20209
.equ TEST4_DATA9,      0x00F0332211002701
.equ TEST4_DATA10,     0x00F033221147000C
.equ TEST4_DATA11,     0x00F033221143000C
.equ TEST4_DATA12,     0x01F0332211003311
.equ TEST4_DATA13,     0x45F0332211341721
.equ TEST4_DATA14,     0x14F4332211781761
.equ TEST4_DATA15,     0x00FC3322110017A1
.equ TEST4_DATA16,     0x64F0332211001F41
.equ TEST4_DATA17,     0x8480332211C01D51
.equ TEST4_DATA18,     0x4490332211C01D81 
.equ TEST4_DATA19,     0x078133221142021B
.equ TEST4_DATA20,     0x00FC33221100036C
.equ TEST4_DATA21,     0x14F0332211101B01
.equ TEST4_DATA22,     0x00FC33221100038C
.equ TEST4_DATA23,     0x57F033221140000C
.equ TEST4_DATA24,     0xC4A033221140001C
.equ TEST4_DATA25,     0x04B23322114000BC
.equ TEST4_DATA26,     0x84913322114001AB
.equ TEST4_DATA27,     0x07A0332211432831
.equ TEST4_DATA28,     0x84D03322114344C3
.equ TEST4_DATA29,     0x40A033221143043C
.equ TEST4_DATA30,     0x84F433221143000C
.equ TEST4_DATA31,     0x00A0002211432C31   # 0xA0332211432C3184


RVTEST_RV64U
RVTEST_CODE_BEGIN
	

LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 10 #each core has 1024 byte of address space
	
ADD  address, group_num, zero

LI xfer, CPP_MEM_ADDR 
#store the crc_data to cpp memory 
LI temp_data, CRC_DATA0
SD temp_data, 0x0(xfer)
LI temp_data, CRC_DATA1
SD temp_data, 0x8(xfer)
LI temp_data, CRC_DATA2
SD temp_data, 0x10(xfer)
LI temp_data, CRC_DATA3
SD temp_data, 0x18(xfer)
LI temp_data, CRC_DATA4
SD temp_data, 0x20(xfer)
LI temp_data, CRC_DATA5
SD temp_data, 0x28(xfer)
LI temp_data, CRC_DATA6
SD temp_data, 0x30(xfer)
LI temp_data, CRC_DATA7
SD temp_data, 0x38(xfer)
LI temp_data, CRC_DATA8
SD temp_data, 0x40(xfer)
LI temp_data, CRC_DATA9
SD temp_data, 0x48(xfer)
LI temp_data, CRC_DATA10
SD temp_data, 0x50(xfer)
LI temp_data, CRC_DATA11
SD temp_data, 0x58(xfer)
LI temp_data, CRC_DATA12
SD temp_data, 0x60(xfer)
LI temp_data, CRC_DATA13
SD temp_data, 0x68(xfer)
LI temp_data, CRC_DATA14
SD temp_data, 0x70(xfer)
LI temp_data, CRC_DATA15
SD temp_data, 0x78(xfer)

##write
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x0)  ;
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x78
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x80)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
ADDI address,address, 0x8
WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x80(xfer)
LI temp_data_1, CRC_DATA15
BNE temp_data, temp_data_1, test_failed
NOP
NOP

#store the crc_data to cpp memory 
LI temp_data, CRC_DATA16
SD temp_data, 0x0(xfer)
LI temp_data, CRC_DATA17
SD temp_data, 0x8(xfer)
LI temp_data, CRC_DATA18
SD temp_data, 0x10(xfer)
LI temp_data, CRC_DATA19
SD temp_data, 0x18(xfer)
LI temp_data, CRC_DATA20
SD temp_data, 0x20(xfer)
LI temp_data, CRC_DATA21
SD temp_data, 0x28(xfer)
LI temp_data, CRC_DATA22
SD temp_data, 0x30(xfer)
LI temp_data, CRC_DATA23
SD temp_data, 0x38(xfer)
LI temp_data, CRC_DATA24
SD temp_data, 0x40(xfer)
LI temp_data, CRC_DATA25
SD temp_data, 0x48(xfer)
LI temp_data, CRC_DATA26
SD temp_data, 0x50(xfer)
LI temp_data, CRC_DATA27
SD temp_data, 0x58(xfer)
LI temp_data, CRC_DATA28
SD temp_data, 0x60(xfer)
LI temp_data, CRC_DATA29
SD temp_data, 0x68(xfer)
LI temp_data, CRC_DATA30
SD temp_data, 0x70(xfer)
LI temp_data, CRC_DATA31
SD temp_data, 0x78(xfer)

##write
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x0)  ;
.insn s 43,0,address,memory_unit_write(cppcmd_data_ref)	 ;# CPP Command write
WAIT_ON_SIGNAL (SIG1_pos,1) 	;

#read last write64 data
ADDI address,address, 0x78
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x90)  ;
#//IID = 0, DMster = 0, SMster = 0, SRef = 1, BM = 0,OVr = 0,  Length = 0, DRef = 0x20	
.insn s 43,0,address,memory_unit_read(cppcmd_data_ref)	 ;# CPP Command read
ADDI address,address, 0x8
WAIT_ON_SIGNAL (SIG1_pos,1);
LD temp_data, 0x90(xfer)
LI temp_data_1, CRC_DATA31
BNE temp_data, temp_data_1, test_failed
NOP
NOP


J test_begin_long

calc_loop_long:
LI temp_data_2, 0xffff
AND temp_data_1, temp_data, temp_data_2
ADD  exp_checksum_no_inv, exp_checksum_no_inv, temp_data_1
SRLI temp_data_1, exp_checksum_no_inv, 0x10
BEQZ  temp_data_1, skip_add_long
AND exp_checksum_no_inv, exp_checksum_no_inv, temp_data_2
ADD  exp_checksum_no_inv, exp_checksum_no_inv, temp_data_1 #add_carry

skip_add_long:
SRLI temp_data, temp_data, 0x10
ADDI byte_len, byte_len, -2
ADDI byte_counter, byte_counter, 2
LI temp_data_2, 0x8
BEQ byte_counter, temp_data_2, update_data
NOP
NOP
BNEZ  byte_len, calc_loop_long

update_data:
ADDI data_counter, data_counter, 1
LI temp_data_2, 1
BEQ test_num, temp_data_2, update_data_test1
LI temp_data_2, 2
BEQ test_num, temp_data_2, update_data_test2
LI temp_data_2, 3
BEQ test_num, temp_data_2, update_data_test3
LI temp_data_2, 4
BEQ test_num, temp_data_2, update_data_test4

update_data_test1:
LI temp_data_2, 1
BEQ data_counter, temp_data_2, update_data_test1_1
LI temp_data_2, 2
BEQ data_counter, temp_data_2, update_data_test1_2
LI temp_data_2, 3
BEQ data_counter, temp_data_2, update_data_test1_3
LI temp_data_2, 4
BEQ data_counter, temp_data_2, update_data_test1_4
LI temp_data_2, 5
BEQ data_counter, temp_data_2, update_data_test1_5
LI temp_data_2, 6
BEQ data_counter, temp_data_2, update_data_test1_6
LI temp_data_2, 7
BEQ data_counter, temp_data_2, update_data_test1_7
LI temp_data_2, 8
BEQ data_counter, temp_data_2, update_data_test1_8
LI temp_data_2, 9
BEQ data_counter, temp_data_2, update_data_test1_9
LI temp_data_2, 10
BEQ data_counter, temp_data_2, update_data_test1_10
LI temp_data_2, 11
BEQ data_counter, temp_data_2, update_data_test1_11
LI temp_data_2, 12
BEQ data_counter, temp_data_2, update_data_test1_12
LI temp_data_2, 13
BEQ data_counter, temp_data_2, update_data_test1_13
LI temp_data_2, 14
BEQ data_counter, temp_data_2, update_data_test1_14
LI temp_data_2, 15
BEQ data_counter, temp_data_2, update_data_test1_15
LI temp_data_2, 16
BEQ data_counter, temp_data_2, update_data_test1_16
LI temp_data_2, 17
BEQ data_counter, temp_data_2, update_data_test1_17
LI temp_data_2, 18
BEQ data_counter, temp_data_2, update_data_test1_18
LI temp_data_2, 19
BEQ data_counter, temp_data_2, update_data_test1_19
LI temp_data_2, 20
BEQ data_counter, temp_data_2, update_data_test1_20
LI temp_data_2, 21
BEQ data_counter, temp_data_2, update_data_test1_21
LI temp_data_2, 22
BEQ data_counter, temp_data_2, update_data_test1_22
LI temp_data_2, 23
BEQ data_counter, temp_data_2, update_data_test1_23
LI temp_data_2, 24
BEQ data_counter, temp_data_2, update_data_test1_24
LI temp_data_2, 25
BEQ data_counter, temp_data_2, update_data_test1_25
LI temp_data_2, 26
BEQ data_counter, temp_data_2, update_data_test1_26
LI temp_data_2, 27
BEQ data_counter, temp_data_2, update_data_test1_27
LI temp_data_2, 28
BEQ data_counter, temp_data_2, update_data_test1_28
LI temp_data_2, 29
BEQ data_counter, temp_data_2, update_data_test1_29
LI temp_data_2, 30
BEQ data_counter, temp_data_2, update_data_test1_30
LI temp_data_2, 31
BEQ data_counter, temp_data_2, update_data_test1_31
LI temp_data_2, 32
BEQ data_counter, temp_data_2, update_data_test1_32


update_data_test1_1:
LI temp_data, CRC_DATA1 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_2:
LI temp_data, CRC_DATA2 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_3:
LI temp_data, CRC_DATA3 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_4:
LI temp_data, CRC_DATA4 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_5:
LI temp_data, CRC_DATA5 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_6:
LI temp_data, CRC_DATA6 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_7:
LI temp_data, CRC_DATA7 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_8:
LI temp_data, CRC_DATA8 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_9:
LI temp_data, CRC_DATA9 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_10:
LI temp_data, CRC_DATA10 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_11:
LI temp_data, CRC_DATA11 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_12:
LI temp_data, CRC_DATA12 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_13:
LI temp_data, CRC_DATA13 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_14:
LI temp_data, CRC_DATA14 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_15:
LI temp_data, CRC_DATA15 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_16:
LI temp_data, CRC_DATA16 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_17:
LI temp_data, CRC_DATA17 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_18:
LI temp_data, CRC_DATA18 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_19:
LI temp_data, CRC_DATA19 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_20:
LI temp_data, CRC_DATA20 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_21:
LI temp_data, CRC_DATA21 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_22:
LI temp_data, CRC_DATA22 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_23:
LI temp_data, CRC_DATA23 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_24:
LI temp_data, CRC_DATA24 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_25:
LI temp_data, CRC_DATA25 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_26:
LI temp_data, CRC_DATA26 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_27:
LI temp_data, CRC_DATA27 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_28:
LI temp_data, CRC_DATA28 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_29:
LI temp_data, CRC_DATA29 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_30:
LI temp_data, CRC_DATA30 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_31:
LI temp_data, CRC_DATA31 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test1_32:
LI temp_data, 0x0 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test


###########
update_data_test2:
LI temp_data_2, 1
BEQ data_counter, temp_data_2, update_data_test2_1
LI temp_data_2, 2
BEQ data_counter, temp_data_2, update_data_test2_2
LI temp_data_2, 3
BEQ data_counter, temp_data_2, update_data_test2_3
LI temp_data_2, 4
BEQ data_counter, temp_data_2, update_data_test2_4
LI temp_data_2, 5
BEQ data_counter, temp_data_2, update_data_test2_5
LI temp_data_2, 6
BEQ data_counter, temp_data_2, update_data_test2_6
LI temp_data_2, 7
BEQ data_counter, temp_data_2, update_data_test2_7
LI temp_data_2, 8
BEQ data_counter, temp_data_2, update_data_test2_8
LI temp_data_2, 9
BEQ data_counter, temp_data_2, update_data_test2_9
LI temp_data_2, 10
BEQ data_counter, temp_data_2, update_data_test2_10
LI temp_data_2, 11
BEQ data_counter, temp_data_2, update_data_test2_11
LI temp_data_2, 12
BEQ data_counter, temp_data_2, update_data_test2_12
LI temp_data_2, 13
BEQ data_counter, temp_data_2, update_data_test2_13
LI temp_data_2, 14
BEQ data_counter, temp_data_2, update_data_test2_14
LI temp_data_2, 15
BEQ data_counter, temp_data_2, update_data_test2_15
LI temp_data_2, 16
BEQ data_counter, temp_data_2, update_data_test2_16
LI temp_data_2, 17
BEQ data_counter, temp_data_2, update_data_test2_17
LI temp_data_2, 18
BEQ data_counter, temp_data_2, update_data_test2_18
LI temp_data_2, 19
BEQ data_counter, temp_data_2, update_data_test2_19
LI temp_data_2, 20
BEQ data_counter, temp_data_2, update_data_test2_20
LI temp_data_2, 21
BEQ data_counter, temp_data_2, update_data_test2_21
LI temp_data_2, 22
BEQ data_counter, temp_data_2, update_data_test2_22
LI temp_data_2, 23
BEQ data_counter, temp_data_2, update_data_test2_23
LI temp_data_2, 24
BEQ data_counter, temp_data_2, update_data_test2_24
LI temp_data_2, 25
BEQ data_counter, temp_data_2, update_data_test2_25
LI temp_data_2, 26
BEQ data_counter, temp_data_2, update_data_test2_26
LI temp_data_2, 27
BEQ data_counter, temp_data_2, update_data_test2_27
LI temp_data_2, 28
BEQ data_counter, temp_data_2, update_data_test2_28
LI temp_data_2, 29
BEQ data_counter, temp_data_2, update_data_test2_29
LI temp_data_2, 30
BEQ data_counter, temp_data_2, update_data_test2_30
LI temp_data_2, 31
BEQ data_counter, temp_data_2, update_data_test2_31
LI temp_data_2, 32
BEQ data_counter, temp_data_2, update_data_test2_32


update_data_test2_1:
LI temp_data, TEST2_DATA1 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_2:
LI temp_data, TEST2_DATA2 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_3:
LI temp_data, TEST2_DATA3 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_4:
LI temp_data, TEST2_DATA4 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_5:
LI temp_data, TEST2_DATA5 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_6:
LI temp_data, TEST2_DATA6 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_7:
LI temp_data, TEST2_DATA7 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_8:
LI temp_data, TEST2_DATA8 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_9:
LI temp_data, TEST2_DATA9 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_10:
LI temp_data, TEST2_DATA10 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_11:
LI temp_data, TEST2_DATA11 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_12:
LI temp_data, TEST2_DATA12 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_13:
LI temp_data, TEST2_DATA13 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_14:
LI temp_data, TEST2_DATA14 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_15:
LI temp_data, TEST2_DATA15 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_16:
LI temp_data, TEST2_DATA16 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_17:
LI temp_data, TEST2_DATA17 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_18:
LI temp_data, TEST2_DATA18 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_19:
LI temp_data, TEST2_DATA19 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_20:
LI temp_data, TEST2_DATA20 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_21:
LI temp_data, TEST2_DATA21 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_22:
LI temp_data, TEST2_DATA22 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_23:
LI temp_data, TEST2_DATA23 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_24:
LI temp_data, TEST2_DATA24 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_25:
LI temp_data, TEST2_DATA25 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_26:
LI temp_data, TEST2_DATA26 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_27:
LI temp_data, TEST2_DATA27 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_28:
LI temp_data, TEST2_DATA28 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_29:
LI temp_data, TEST2_DATA29 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_30:
LI temp_data, TEST2_DATA30 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_31:
LI temp_data, TEST2_DATA31 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test2_32:
LI temp_data, 0x0 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

################

update_data_test3:
LI temp_data_2, 1
BEQ data_counter, temp_data_2, update_data_test3_1
LI temp_data_2, 2
BEQ data_counter, temp_data_2, update_data_test3_2
LI temp_data_2, 3
BEQ data_counter, temp_data_2, update_data_test3_3
LI temp_data_2, 4
BEQ data_counter, temp_data_2, update_data_test3_4
LI temp_data_2, 5
BEQ data_counter, temp_data_2, update_data_test3_5
LI temp_data_2, 6
BEQ data_counter, temp_data_2, update_data_test3_6
LI temp_data_2, 7
BEQ data_counter, temp_data_2, update_data_test3_7
LI temp_data_2, 8
BEQ data_counter, temp_data_2, update_data_test3_8
LI temp_data_2, 9
BEQ data_counter, temp_data_2, update_data_test3_9
LI temp_data_2, 10
BEQ data_counter, temp_data_2, update_data_test3_10
LI temp_data_2, 11
BEQ data_counter, temp_data_2, update_data_test3_11
LI temp_data_2, 12
BEQ data_counter, temp_data_2, update_data_test3_12
LI temp_data_2, 13
BEQ data_counter, temp_data_2, update_data_test3_13
LI temp_data_2, 14
BEQ data_counter, temp_data_2, update_data_test3_14
LI temp_data_2, 15
BEQ data_counter, temp_data_2, update_data_test3_15
LI temp_data_2, 16
BEQ data_counter, temp_data_2, update_data_test3_16
LI temp_data_2, 17
BEQ data_counter, temp_data_2, update_data_test3_17
LI temp_data_2, 18
BEQ data_counter, temp_data_2, update_data_test3_18
LI temp_data_2, 19
BEQ data_counter, temp_data_2, update_data_test3_19
LI temp_data_2, 20
BEQ data_counter, temp_data_2, update_data_test3_20
LI temp_data_2, 21
BEQ data_counter, temp_data_2, update_data_test3_21
LI temp_data_2, 22
BEQ data_counter, temp_data_2, update_data_test3_22
LI temp_data_2, 23
BEQ data_counter, temp_data_2, update_data_test3_23
LI temp_data_2, 24
BEQ data_counter, temp_data_2, update_data_test3_24
LI temp_data_2, 25
BEQ data_counter, temp_data_2, update_data_test3_25
LI temp_data_2, 26
BEQ data_counter, temp_data_2, update_data_test3_26
LI temp_data_2, 27
BEQ data_counter, temp_data_2, update_data_test3_27
LI temp_data_2, 28
BEQ data_counter, temp_data_2, update_data_test3_28
LI temp_data_2, 29
BEQ data_counter, temp_data_2, update_data_test3_29
LI temp_data_2, 30
BEQ data_counter, temp_data_2, update_data_test3_30
LI temp_data_2, 31
BEQ data_counter, temp_data_2, update_data_test3_31
LI temp_data_2, 32
BEQ data_counter, temp_data_2, update_data_test3_32


update_data_test3_1:
LI temp_data, TEST3_DATA1 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_2:
LI temp_data, TEST3_DATA2 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_3:
LI temp_data, TEST3_DATA3 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_4:
LI temp_data, TEST3_DATA4 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_5:
LI temp_data, TEST3_DATA5 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_6:
LI temp_data, TEST3_DATA6 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_7:
LI temp_data, TEST3_DATA7 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_8:
LI temp_data, TEST3_DATA8 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_9:
LI temp_data, TEST3_DATA9 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_10:
LI temp_data, TEST3_DATA10 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_11:
LI temp_data, TEST3_DATA11 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_12:
LI temp_data, TEST3_DATA12 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_13:
LI temp_data, TEST3_DATA13 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_14:
LI temp_data, TEST3_DATA14 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_15:
LI temp_data, TEST3_DATA15 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_16:
LI temp_data, TEST3_DATA16 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_17:
LI temp_data, TEST3_DATA17 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_18:
LI temp_data, TEST3_DATA18 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_19:
LI temp_data, TEST3_DATA19 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_20:
LI temp_data, TEST3_DATA20 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_21:
LI temp_data, TEST3_DATA21 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_22:
LI temp_data, TEST3_DATA22 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_23:
LI temp_data, TEST3_DATA23 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_24:
LI temp_data, TEST3_DATA24 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_25:
LI temp_data, TEST3_DATA25 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_26:
LI temp_data, TEST3_DATA26 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_27:
LI temp_data, TEST3_DATA27 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_28:
LI temp_data, TEST3_DATA28 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_29:
LI temp_data, TEST3_DATA29 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_30:
LI temp_data, TEST3_DATA30 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_31:
LI temp_data, TEST3_DATA31 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test3_32:
LI temp_data, 0x0 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

################
update_data_test4:
LI temp_data_2, 1
BEQ data_counter, temp_data_2, update_data_test4_1
LI temp_data_2, 2
BEQ data_counter, temp_data_2, update_data_test4_2
LI temp_data_2, 3
BEQ data_counter, temp_data_2, update_data_test4_3
LI temp_data_2, 4
BEQ data_counter, temp_data_2, update_data_test4_4
LI temp_data_2, 5
BEQ data_counter, temp_data_2, update_data_test4_5
LI temp_data_2, 6
BEQ data_counter, temp_data_2, update_data_test4_6
LI temp_data_2, 7
BEQ data_counter, temp_data_2, update_data_test4_7
LI temp_data_2, 8
BEQ data_counter, temp_data_2, update_data_test4_8
LI temp_data_2, 9
BEQ data_counter, temp_data_2, update_data_test4_9
LI temp_data_2, 10
BEQ data_counter, temp_data_2, update_data_test4_10
LI temp_data_2, 11
BEQ data_counter, temp_data_2, update_data_test4_11
LI temp_data_2, 12
BEQ data_counter, temp_data_2, update_data_test4_12
LI temp_data_2, 13
BEQ data_counter, temp_data_2, update_data_test4_13
LI temp_data_2, 14
BEQ data_counter, temp_data_2, update_data_test4_14
LI temp_data_2, 15
BEQ data_counter, temp_data_2, update_data_test4_15
LI temp_data_2, 16
BEQ data_counter, temp_data_2, update_data_test4_16
LI temp_data_2, 17
BEQ data_counter, temp_data_2, update_data_test4_17
LI temp_data_2, 18
BEQ data_counter, temp_data_2, update_data_test4_18
LI temp_data_2, 19
BEQ data_counter, temp_data_2, update_data_test4_19
LI temp_data_2, 20
BEQ data_counter, temp_data_2, update_data_test4_20
LI temp_data_2, 21
BEQ data_counter, temp_data_2, update_data_test4_21
LI temp_data_2, 22
BEQ data_counter, temp_data_2, update_data_test4_22
LI temp_data_2, 23
BEQ data_counter, temp_data_2, update_data_test4_23
LI temp_data_2, 24
BEQ data_counter, temp_data_2, update_data_test4_24
LI temp_data_2, 25
BEQ data_counter, temp_data_2, update_data_test4_25
LI temp_data_2, 26
BEQ data_counter, temp_data_2, update_data_test4_26
LI temp_data_2, 27
BEQ data_counter, temp_data_2, update_data_test4_27
LI temp_data_2, 28
BEQ data_counter, temp_data_2, update_data_test4_28
LI temp_data_2, 29
BEQ data_counter, temp_data_2, update_data_test4_29
LI temp_data_2, 30
BEQ data_counter, temp_data_2, update_data_test4_30
LI temp_data_2, 31
BEQ data_counter, temp_data_2, update_data_test4_31
LI temp_data_2, 32
BEQ data_counter, temp_data_2, update_data_test4_32


update_data_test4_1:
LI temp_data, TEST4_DATA1 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_2:
LI temp_data, TEST4_DATA2 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_3:
LI temp_data, TEST4_DATA3 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_4:
LI temp_data, TEST4_DATA4 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_5:
LI temp_data, TEST4_DATA5 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_6:
LI temp_data, TEST4_DATA6 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_7:
LI temp_data, TEST4_DATA7 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_8:
LI temp_data, TEST4_DATA8 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_9:
LI temp_data, TEST4_DATA9 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_10:
LI temp_data, TEST4_DATA10 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_11:
LI temp_data, TEST4_DATA11 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_12:
LI temp_data, TEST4_DATA12 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_13:
LI temp_data, TEST4_DATA13 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_14:
LI temp_data, TEST4_DATA14 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_15:
LI temp_data, TEST4_DATA15 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_16:
LI temp_data, TEST4_DATA16 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_17:
LI temp_data, TEST4_DATA17 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_18:
LI temp_data, TEST4_DATA18 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_19:
LI temp_data, TEST4_DATA19 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_20:
LI temp_data, TEST4_DATA20 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_21:
LI temp_data, TEST4_DATA21 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_22:
LI temp_data, TEST4_DATA22 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_23:
LI temp_data, TEST4_DATA23 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_24:
LI temp_data, TEST4_DATA24 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_25:
LI temp_data, TEST4_DATA25 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_26:
LI temp_data, TEST4_DATA26 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_27:
LI temp_data, TEST4_DATA27 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_28:
LI temp_data, TEST4_DATA28 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_29:
LI temp_data, TEST4_DATA29 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_30:
LI temp_data, TEST4_DATA30 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_31:
LI temp_data, TEST4_DATA31 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

update_data_test4_32:
LI temp_data, 0x0 #8byte
LI byte_counter, 0x0
BNEZ  byte_len, calc_loop_long
J return_test

################



return_test:
NOT exp_checksum_inv, exp_checksum_no_inv
LI temp_data_2, 0xffff
AND exp_checksum_inv, exp_checksum_inv, temp_data_2
LI temp_data_2, 0x1
BEQ test_num, temp_data_2, return_test1
LI temp_data_2, 0x2
BEQ test_num, temp_data_2, return_test2
LI temp_data_2, 0x3
BEQ test_num, temp_data_2, return_test3
LI temp_data_2, 0x4
BEQ test_num, temp_data_2, return_test4

//----------------------------------
// TEST=1
// even address even length_256byte
//----------------------------------

test_begin_long:
LI test_num, 0x1
LI byte_len, 0x100
LI byte_counter, 0x0
LI data_counter, 0x0
LI temp_data, CRC_DATA0 #8byte
LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test1:
#Test-CSUM16_NO_INV
ADD  address, group_num, zero
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1f,0xa0)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0xa0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2  
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed


#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1f,0xb0)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0xb0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2
bne csum16_result_inv, exp_checksum_inv, test_failed
NOP
NOP
NOP


//----------------------------------
// TEST=2
// even address odd length_253byte
//----------------------------------
LI test_num, 0x2
LI byte_len, 0xfe
LI byte_counter, 0x0
LI data_counter, 0x0
LI temp_data, TEST2_DATA0 #8byte
LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test2:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x4,0x1,0x1f,0xc0)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0xc0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2   
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x4,0x1,0x1f,0xd0)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0xd0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2  
bne csum16_result_inv, exp_checksum_inv, test_failed
NOP
NOP
NOP

//----------------------------------
// TEST=3
// odd address even length_248byte
//----------------------------------
LI test_num, 0x3
LI byte_len, 0xf8
LI byte_counter, 0x0
LI data_counter, 0x0
LI temp_data, TEST3_DATA0 #8byte
LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test3:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
ADD  address, group_num, zero
ADDI address,address, 0x1
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1e,0xe0)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0xe0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2   
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0xff,0x0,0x1e,0xf0)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0xf0(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2  
bne csum16_result_inv, exp_checksum_inv, test_failed
NOP
NOP
NOP

//----------------------------------
// TEST=4
// odd address odd length_253byte
//----------------------------------
LI test_num, 0x4
LI byte_len, 0xfe
LI byte_counter, 0x0
LI data_counter, 0x0
LI temp_data, TEST4_DATA0 #8byte
LI exp_checksum_no_inv, 0x0
J calc_loop_long

return_test4:
SRLI temp_data_5, exp_checksum_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_inv, temp_data_5, temp_data_6

SRLI temp_data_5, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff
AND temp_data_5, temp_data_5, temp_data_2
SLLI temp_data_6, exp_checksum_no_inv, 0x8
LI temp_data_2, 0xff00
AND temp_data_6, temp_data_6, temp_data_2
ADD exp_checksum_no_inv, temp_data_5, temp_data_6

#Test-CSUM16_NO_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x4,0x1,0x1f,0x100)  ;
.insn s 43,0,address,memory_unit_csum16_no_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_no_inv, 0x100(xfer)
LI temp_data_2, 0xffff
AND csum16_result_no_inv, csum16_result_no_inv, temp_data_2   
bne csum16_result_no_inv, exp_checksum_no_inv, test_failed

#Test-CSUM16_INV
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x4,0x1,0x1f,0x110)  ;
.insn s 43,0,address,memory_unit_csum16_inv(cppcmd_data_ref)	 ;

WAIT_ON_SIGNAL (SIG1_pos,1);
LD csum16_result_inv, 0x110(xfer)
LI temp_data_2, 0xffff
AND csum16_result_inv, csum16_result_inv, temp_data_2  
bne csum16_result_inv, exp_checksum_inv, test_failed
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
