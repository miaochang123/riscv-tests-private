#--------------------------------
# TEST_NAME: rfpc_ls_add32/64_immed_random.S
# cmd: add_imm            5/0 
#      addsat_imm         5/2
#      test_add_imm      21/0
#      test_addsat_imm   21/2
#      add64_imm          5/1 
#      test_add64_imm    21/1 
#--------------------------------

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
	
#define cppcmd_data_ref x3
#define loop_count      x4 
#define group_num       x5
#define cl_num          x6
#define temp_data_1     x7 
#define address         x8
#define xfer            x9  
#define hart_id         x10 #hart csr register

#define  data1a        x11
#define  data2a        x12
#define  data3a        x13
#define  data4a        x14

#define  data1b        x15
#define  data2b        x16
#define  data3b        x17
#define  data4b        x18

#define  expect1       x19
#define  expect2       x20
#define  expect3       x21
#define  expect4       x22

#define remainder      x23
#define four           x24
#define three          x25
#define two            x26
#define one            x27 

#define  temp_data     x30
#define  mask          x31


.equ NUM_OPERATIONS ,   20
.equ MEM_SIZE_DIV16 ,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR   ,   0xf0000000 

RVTEST_RV64U
RVTEST_CODE_BEGIN
#------------------------------------
#Set Up the BASE scratch address
#Each ME will use a different region
#------------------------------------
	
LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127

SLLI group_num , group_num, 8 #each core has 1024 byte of address space
	
ADD address, group_num, zero


LI xfer, CPP_MEM_ADDR 
LI mask,0xffffffff
LI one,1
LI two,2
LI three,3
LI four,4


####################################################
# test1    32bit add_imm
####################################################
LI loop_count, NUM_OPERATIONS 
add32_imm_loop:
    LI data1a ,0xffffffff
    LI data2a ,0x22222222
    LI data3a ,0x3333ffff
    LI data4a ,0xffff4444
    
    #store the data to cpp memory 
    SW data1a ,0x0(xfer)
    SW data2a ,0x4(xfer)
    SW data3a ,0x8(xfer)
    SW data4a ,0xC(xfer)
    
    LI data1b ,0xf777   
    LI data2b ,0xf222 
    LI data3b ,0xf111
    LI data4b ,0xffff
    
    
    #write data to sram
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
    
    ADD address, group_num, zero # set to initial value
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    #divide the test to 4 case bit[15:14] 00 01 10 11
    REM remainder, loop_count, two
    BEQ remainder, one,   bits_01_11
    #BEQ remainder, one,bits_00_10   
    
    bits_00_10: # Bits [15:14]  00/10 zero extend
        LI  temp_data,0X1FFF
        AND data1b,data1b,temp_data 
        ADD expect1,data1a,data1b   #    bit15_13 = 000
        AND expect1,expect1,mask
        
        LI  temp_data,0X3FFF
        AND data2b,data2b,temp_data
        LI  temp_data,0X2000
        OR  data2b,data2b,temp_data   #   bit15_13 = 001
        ADD expect2,data2a,data2b 
        AND expect2,expect2,mask 
        
        LI  temp_data,0X1FFF
        AND data3b,data3b,temp_data
        ADD expect3,data3a,data3b
        AND expect3,expect3,mask 
        LI  temp_data,0x8000
        OR  data3b,data3b,temp_data #   bit15_13 = 100  
        
        LI  temp_data,0X3FFF
        AND data4b,data4b,temp_data
        LI  temp_data,0X2000
        OR  data4b,data4b,temp_data 
        ADD expect4,data4a,data4b 
        AND expect4,expect4,mask 
        LI  temp_data,0xA000
        OR  data4b,data4b,temp_data  #  bit15_13 = 101
        
        J   to_add_imm
    
    
    bits_01_11: # Bits [15:14] 01/11 Sign extend    
        LI  temp_data,0X1FFF
        AND data1b,data1b,temp_data 
        ADD expect1,data1a,data1b 
        AND expect1,expect1,mask  
        LI  temp_data,0x4000
        OR  data1b,data1b,temp_data # bit15_13 = 010
        
        LI  temp_data,0X3FFF
        AND data2b,data2b,temp_data
        LI  temp_data,0xFFFFE000
        OR  temp_data,data2b,temp_data
        ADD expect2,data2a,temp_data
        AND expect2,expect2,mask
        LI  temp_data,0x6000        # bit15_13 = 011
        OR  data2b,data2b,temp_data 
        
        LI  temp_data,0X3FFF
        AND data3b,data3b,temp_data
        LI  temp_data,0xFFFFE000
        OR  temp_data,data3b,temp_data
        ADD expect3,data3a,temp_data
        AND expect3,expect3,mask
        LI  temp_data,0xE000        # bit15_13 = 111
        OR  data3b,data3b,temp_data
        
        LI  temp_data,0X1FFF
        AND data4b,data4b,temp_data
        ADD expect4,data4a,data4b 
        AND expect4,expect4,mask 
        LI  temp_data,0xC000
        OR  data4b,data4b,temp_data # bit15_13 = 110
        J   to_add_imm
    
    
    to_add_imm:
        # override flag, see EAS_rfpc Table 2.12
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data1b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm  
        .insn s 43,0,address,cluster_scratch_add_imm(cppcmd_data_ref);
        
        ADDI address,group_num , 0x4 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm   
        OR cppcmd_data_ref, cppcmd_data_ref, data2b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data2b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm  
        .insn s 43,0,address,cluster_scratch_add_imm(cppcmd_data_ref); 
        
        ADDI address,group_num , 0x8 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm   
        OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data3b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                   # override rs1[45:41] dm  
        .insn s 43,0,address,cluster_scratch_add_imm(cppcmd_data_ref); 
        
        ADDI address,group_num, 0xC 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref  and dm   
        OR cppcmd_data_ref, cppcmd_data_ref, data4b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data4b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data
        .insn s 43,0,address,cluster_scratch_add_imm(cppcmd_data_ref);  # override rs1[45:41] dm
        
        ADD address, group_num, zero # set to initial value
        
        
        
        #read the operation data in sram addr to compare with expected data
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40);
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
        
        ADD address, group_num, zero # set to initial value            
        WAIT_ON_SIGNAL (SIG1_pos,1);                    
        
        LWU  temp_data, 0x40(xfer)
        BNE temp_data, expect1, test_failed
        LWU  temp_data, 0x44(xfer)
        BNE temp_data, expect2, test_failed
        LWU  temp_data, 0x48(xfer)
        BNE temp_data, expect3, test_failed
        LWU  temp_data, 0x4c(xfer)
        BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, add32_imm_loop   

NOP
NOP
NOP
##################################################################
# test2    32bit add_sat_imm     byte_mask decide saturation limit
##################################################################

LI loop_count, NUM_OPERATIONS 
add32_sat_imm_loop:

    REM remainder, loop_count, four
    BEQ remainder, two,   add_sat_data_other
    
    LI data1a ,0xffffffff
    LI data2a ,0x22222222
    LI data3a ,0x3333ffff
    LI data4a ,0xffff4444
    LI data1b ,0xd777   
    LI data2b ,0x0222 
    LI data3b ,0x1111
    LI data4b ,0xffff  
    J  wirte_sram
    
    add_sat_data_other : 
        LI data1a ,0xffff
        LI data2a ,0x2222
        LI data3a ,0xeeeeffff
        LI data4a ,0xffff
        LI data1b ,0xd777   
        LI data2b ,0x0222 
        LI data3b ,0x1111
        LI data4b ,0xffff  
    
    wirte_sram:
        #store the data to cpp memory 
        SW data1a ,0x0(xfer)
        SW data2a ,0x4(xfer)
        SW data3a ,0x8(xfer)
        SW data4a ,0xC(xfer)
        
        #write data to sram
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
        .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
        
        ADD address, group_num, zero # set to initial value
        WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    ##divide the test to 4 case bit[15:14] 00 01 10 11
    REM remainder, loop_count, two
    BEQ remainder, one,   satbits_01_11  
    
    satbits_00_10:
        #calculate the expected values
        LI   temp_data,0x1FFF
        AND  data1b,data1b,temp_data   #    bit15_13 = 000 
        ADD  expect1,data1a,data1b     #  a+b   limit=3fff
        LI   temp_data,0x1fffc0000
        AND  temp_data,temp_data,expect1 #if expect1>0x3fff
        BEQZ temp_data,add_not_sat1_0 
        LI   expect1,0x3ffff
    
    add_not_sat1_0:
        ADDI expect1,expect1,0x0 
           
        LI   temp_data,0x3FFF
        AND  data2b,data2b,temp_data
        LI   temp_data,0X2000
        OR   data2b,data2b,temp_data      #    bit15_13 = 001  
        ADD  expect2,data2a,data2b
        LI   temp_data,0x1ffc00000
        AND  temp_data,temp_data,expect2 #if expect1>0x3ffff
        BEQZ temp_data,add_not_sat2_0 
        LI   expect2,0x3fffff
    
    add_not_sat2_0:
        ADDI expect2,expect2,0x0  
  
        LI   temp_data,0x1FFF
        AND  data3b,data3b,temp_data
        ADD  expect3,data3a,data3b
        LI   temp_data,0x100000000
        AND  temp_data,temp_data,expect3 #if expect1>0xffffffff
        BEQZ temp_data,add_not_sat3_0 
        LI   expect3,0xffffffff
    
    add_not_sat3_0:
        ADDI expect3,expect3,0x0
            
        LI   temp_data,0x3FFF
        AND  data4b,data4b,temp_data
        LI   temp_data,0X2000
        OR   data4b,data4b,temp_data
        ADD  expect4,data4a,data4b
        LI   temp_data,0x100000000
        AND  temp_data,temp_data,expect4 #if expect1>0xffffffff
        BEQZ temp_data,add_not_sat4_0 
        LI   expect4,0xffffffff
    
    add_not_sat4_0:
        ADDI expect4,expect4,0x0  
        LI  temp_data,0xA000
        OR  data4b,data4b,temp_data 
        J   to_addsat_imm
    
    satbits_01_11:
        #calculate the expected values
        LI   temp_data,0x1FFF
        AND  data1b,data1b,temp_data 
        ADD  expect1,data1a,data1b   #    bit15_13 = 010 
        LI   temp_data,0x1fffc0000
        AND  temp_data,temp_data,expect1 #if expect1>0x3fff
        BEQZ temp_data,add_not_sat1_1 
        LI   expect1,0x3ffff
    
    add_not_sat1_1:
        ADDI expect1,expect1,0x0 
        
        LI   temp_data,0x3FFF
        AND  data2b,data2b,temp_data
        LI   temp_data,0xFFFFE000
        OR   temp_data,data2b,mask 
        ADD  expect2,data2a,temp_data
        LI   temp_data,0x1ffc00000
        AND  temp_data,temp_data,expect2 #if expect1>0x3ffff
        BEQZ temp_data,add_not_sat2_1 
        LI   expect2,0x3fffff 
    
    add_not_sat2_1:
        ADDI expect2,expect2,0x0
        LI   temp_data,0x6000        
        OR   data2b,data2b,temp_data
        
        LI   temp_data,0x1FFF
        AND  data3b,data3b,temp_data
        ADD  expect3,data3a,data3b
        LI   temp_data,0x100000000
        AND  temp_data,temp_data,expect3 #if expect1>0xffffffff
        BEQZ temp_data,add_not_sat3_1 
        LI   expect3,0xffffffff
    
    add_not_sat3_1:
        ADDI expect3,expect3,0x0 
        LI  temp_data,0xC000
        OR  data3b,data3b,temp_data
        
        LI   temp_data,0x3FFF
        AND  data4b,data4b,temp_data
        LI   temp_data,0xFFFFE000
        OR   temp_data,data4b, temp_data
        ADD  expect4,data4a,temp_data
        LI   temp_data,0x100000000
        AND  temp_data,temp_data,expect4 #if expect1>0xffffffff
        BEQZ temp_data,add_not_sat4_1 
        LI   expect4,0xffffffff
    
    add_not_sat4_1:
        ADDI expect4,expect4,0x0  
        LI  temp_data,0xE000
        OR  data4b,data4b,temp_data 
        
        J   to_addsat_imm  
    
    
    to_addsat_imm: 
        # override flag, see EAS_rfpc Table 2.12
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x51,0x25,0x0,0x0); #override dref and dm and bytemask 0x1 :sat limit 3ffff 
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data1b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm
        .insn s 43,0,address,cluster_scratch_addsat_imm(cppcmd_data_ref);
        
        ADDI address,group_num , 0x4 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x51,0x25,0x0,0x0); #override dref and dm  and bytemask 0x50 :sat limit 3fffff  
        OR cppcmd_data_ref, cppcmd_data_ref, data2b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data2b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm
        .insn s 43,0,address,cluster_scratch_addsat_imm(cppcmd_data_ref); 
        
        ADDI address,group_num , 0x8 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref and dm
        OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data3b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm
        .insn s 43,0,address,cluster_scratch_addsat_imm(cppcmd_data_ref); 
        
        ADDI address,group_num, 0xC 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref and dm
        OR cppcmd_data_ref, cppcmd_data_ref, data4b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data4b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm
        .insn s 43,0,address,cluster_scratch_addsat_imm(cppcmd_data_ref);
        
        ADD address, group_num, zero # set to initial value
        
        
        #read the operation data in sram addr to compare with expected data
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40);
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
        
        ADD address, group_num, zero # set to initial value            
        WAIT_ON_SIGNAL (SIG1_pos,1);                    
        
        LWU  temp_data, 0x40(xfer)
        BNE temp_data, expect1, test_failed
        LWU  temp_data, 0x44(xfer)
        BNE temp_data, expect2, test_failed
        LWU  temp_data, 0x48(xfer)
        BNE temp_data, expect3, test_failed
        LWU  temp_data, 0x4c(xfer)
        BNE temp_data, expect4, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero, add32_sat_imm_loop  

NOP
NOP
NOP                             


####################################################
# test3    32bit test_add_imm
####################################################

add32_test_add_imm_loop:
    LI data1a ,0xffffffff
    LI data2a ,0x22222222
    LI data3a ,0x33333333
    LI data4a ,0x44444444
    
    #store the data to cpp memory 
    SW data1a ,0x0(xfer)
    SW data2a ,0x4(xfer)
    SW data3a ,0x8(xfer)
    SW data4a ,0xC(xfer)
    
    LI data1b ,0xd777   
    LI data2b ,0x0222 
    LI data3b ,0x1111
    LI data4b ,0x0232    
    #write data to sram
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
    
    ADD address, group_num, zero # set to initial value
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    add32_test_add_imm_expect:
        #calculate the expected values
        LI   temp_data,0xFFFFFFFF
        ANDI data1b ,data1b,0x1F
        ADD  expect1,data1a,data1b
        AND  expect1,expect1,temp_data
        
        ANDI data2b ,data2b,0x1F
        ADD  expect2,data2a,data2b
        AND  expect2,expect2,temp_data
        
        ANDI data3b ,data3b,0x1F   
        ADD  expect3,data3a,data3b
        AND  expect3,expect3,temp_data
        
        ANDI data4b ,data4b,0x1F 
        ADD  expect4,data4a,data4b
        AND  expect4,expect4,temp_data
        
        #test_add_imm
        # override flag, see EAS_rfpc Table 2.12
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); #
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        SLLI data1b,data1b,16
        OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[20:16] len
        .insn s 43,0,address,cluster_scratch_test_add_imm(cppcmd_data_ref);
        WAIT_ON_SIGNAL (SIG1_pos,1); 
        
        ADDI address,group_num , 0x4
        SLLI data2b,data2b,16
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x14); 
        OR cppcmd_data_ref, cppcmd_data_ref, data2b # override rs1[20:16] len
        .insn s 43,0,address,cluster_scratch_test_add_imm(cppcmd_data_ref); 
        WAIT_ON_SIGNAL (SIG1_pos,1); 
        
        ADDI address,group_num , 0x8 
        SLLI data3b,data3b,16
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18); 
        OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[20:16] len
        .insn s 43,0,address,cluster_scratch_test_add_imm(cppcmd_data_ref);
        WAIT_ON_SIGNAL (SIG1_pos,1); 
        
        ADDI address,group_num, 0xC 
        SLLI data4b,data4b,16
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1C); 
        OR cppcmd_data_ref, cppcmd_data_ref, data4b # override rs1[20:16] len 
        .insn s 43,0,address,cluster_scratch_test_add_imm(cppcmd_data_ref); 
        WAIT_ON_SIGNAL (SIG1_pos,1); 
        
        #compare pushdata
        LWU  temp_data, 0x0(xfer)
        BNE temp_data, data1a, test_failed 
        LWU  temp_data, 0x4(xfer)
        BNE temp_data, data2a, test_failed
        LWU  temp_data, 0x8(xfer)
        BNE temp_data, data3a, test_failed
        LWU  temp_data, 0xC(xfer)
        BNE temp_data, data4a, test_failed  
        
        ADD address, group_num, zero # set to initial value
        
        #read the operation data in sram addr to compare with expected data
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40);
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
        
        ADD address, group_num, zero # set to initial value            
        WAIT_ON_SIGNAL (SIG1_pos,1);                    
        
        LW  temp_data, 0x40(xfer)
        BNE temp_data, expect1, test_failed
        LW  temp_data, 0x44(xfer)
        BNE temp_data, expect2, test_failed
        LW  temp_data, 0x48(xfer)
        BNE temp_data, expect3, test_failed
        LW  temp_data, 0x4c(xfer)
        BNE temp_data, expect4, test_failed

####################################################
# test4    32bit test_addsat_imm
####################################################

addsat_test_add_imm_loop:
    LI data1a ,0xffffffff
    LI data2a ,0x22222222
    LI data3a ,0xeeeeffff
    LI data4a ,0x44444444
    
    #store the data to cpp memory 
    SW data1a ,0x0(xfer)
    SW data2a ,0x4(xfer)
    SW data3a ,0x8(xfer)
    SW data4a ,0xC(xfer)
    
    LI data1b ,0xd777   
    LI data2b ,0x0222 
    LI data3b ,0x1111
    LI data4b ,0x0232      
    #write data to sram
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
    
    ADD address, group_num, zero # set to initial value
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    addsat_test_add_imm_expect:
    #calculate the expected values
    LI   temp_data,0xFFFFFFFF
    ANDI data1b ,data1b,0x1F
    ADD  expect1,data1a,data1b
    LI   temp_data,0x100000000
    AND  temp_data,temp_data,expect1
    BEQZ temp_data,add_not_sat1_2
    LI   expect1,0xffffffff 
    add_not_sat1_2:
    ADDI expect1,expect1,0x0
    
    LI   temp_data,0xFFFFFFFF
    ANDI data2b ,data2b,0x1F
    ADD  expect2,data2a,data2b
    LI   temp_data,0x100000000
    AND  temp_data,temp_data,expect2
    BEQZ temp_data,add_not_sat2_2
    LI   expect2,0xffffffff 
    add_not_sat2_2:
    ADDI expect2,expect2,0x0
    
    LI   temp_data,0xFFFFFFFF
    ANDI data3b ,data3b,0x1F   
    ADD  expect3,data3a,data3b
    LI   temp_data,0x100000000
    AND  temp_data,temp_data,expect3  
    BEQZ temp_data,add_not_sat3_2
    LI   expect3,0xffffffff 
    add_not_sat3_2:
    ADDI expect3,expect3,0x0
    
    LI   temp_data,0xFFFFFFFF
    ANDI data4b ,data4b,0x1F 
    ADD  expect4,data4a,data4b
    LI   temp_data,0x100000000
    AND  temp_data,temp_data,expect4 
    BEQZ temp_data,add_not_sat4_2
    LI   expect4,0xffffffff 
    add_not_sat4_2:
    ADDI expect4,expect4,0x0
    
    #sub_imm
    # override flag, see EAS_rfpc Table 2.12
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); 
    #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
    #OVERRIDE(8),LENGTH(5),DATA_REF(16)
    SLLI data1b,data1b,16
    OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[20:16] len
    .insn s 43,0,address,cluster_scratch_test_addsat_imm(cppcmd_data_ref);
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    ADDI address,group_num , 0x4
    SLLI data2b,data2b,16
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x14); 
    OR cppcmd_data_ref, cppcmd_data_ref, data2b # override rs1[20:16] len
    .insn s 43,0,address,cluster_scratch_test_addsat_imm(cppcmd_data_ref);
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    ADDI address,group_num , 0x8 
    SLLI data3b,data3b,16
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18);
    OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[20:16] len
    .insn s 43,0,address,cluster_scratch_test_addsat_imm(cppcmd_data_ref); 
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    ADDI address,group_num, 0xC 
    SLLI data4b,data4b,16
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x1C); 
    OR cppcmd_data_ref, cppcmd_data_ref, data4b # override rs1[20:16] len
    .insn s 43,0,address,cluster_scratch_test_addsat_imm(cppcmd_data_ref);
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    #compare pushdata
    LWU  temp_data, 0x0(xfer)
    BNE temp_data, data1a, test_failed 
    LWU  temp_data, 0x4(xfer)
    BNE temp_data, data2a, test_failed
    LWU  temp_data, 0x8(xfer)
    BNE temp_data, data3a, test_failed
    LWU  temp_data, 0xC(xfer)
    BNE temp_data, data4a, test_failed  
    
    ADD address, group_num, zero # set to initial value
    
    #read the operation data in sram addr to compare with expected data
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40);
    .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
    
    ADD address, group_num, zero # set to initial value            
    WAIT_ON_SIGNAL (SIG1_pos,1);                    
    
    LWU temp_data, 0x40(xfer)
    BNE temp_data, expect1, test_failed
    LWU temp_data, 0x44(xfer)
    BNE temp_data, expect2, test_failed
    LWU temp_data, 0x48(xfer)
    BNE temp_data, expect3, test_failed
    LWU temp_data, 0x4c(xfer)
    BNE temp_data, expect4, test_failed


LI mask, 0x3fff
LI one ,1
LI two ,2
LI three,3
LI four ,4 
#####################################################
# test5    64bit add_imm
####################################################
LI loop_count, NUM_OPERATIONS
add64_imm_loop:
    LI data1a ,0xffffffffffffffff
    #LI data2a ,0xffffffff
    LI data3a ,0x4444444411111111
    #LI data4a ,0x44444444
    
    #store the data to cpp memory 
    SD data1a ,0x0(xfer)
    #SW data2a ,0x4(xfer)
    SD data3a ,0x8(xfer)
    #SW data4a ,0xc(xfer)
    
    LI data1b ,0xf434   
    LI data3b ,0x0565 
    #write data to sram
    
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
    
    ADD address, group_num, zero # set to initial value
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    
    REM remainder, loop_count, four
    BEQ remainder, one,   bits_01
    BEQ remainder, two,   bits_10
    BEQ remainder, three, bits_11
    
    bits_00:  #No sign extension here
        AND data1b,data1b,mask
        AND data3b,data3b,mask
        ADD expect1,data1a,data1b 
        ADD expect3,data3a,data3b
    
    J   to_add64_imm 
    
    bits_01: # Bits [15:14] 01 Sign extend 
        LI  temp_data,0X1FFF
        AND data1b,data1b,temp_data 
        LI  temp_data,0x4000
        OR  data1b,data1b,temp_data    #no sign   bit15_13=010
        AND data2b,data1b,mask 
        ADD expect1,data1a,data2b
        
        LI  temp_data,0X3FFF
        AND data3b,data3b,temp_data 
        LI  temp_data,0x6000
        OR  data3b,data3b,temp_data    #sign   bit15_13=011 
        AND data4b,data3b,mask 
        LI  temp_data,0xFFFFFFFFFFFFC000
        OR  data4b,data4b,temp_data  
        ADD expect3,data3a,data4b
    
    J   to_add64_imm
    
    bits_10: # Bits [15:14] 10 Zero extend and duplicate (makes no sense for len=1 32 bit 
        LI  temp_data,0X1FFF
        AND data1b,data1b,temp_data
        LI  temp_data,0x8000
        OR  data1b,data1b,temp_data    #   bit15_13=100
        AND data2b,data1b,mask 
        SLLI temp_data,data2b,32
        OR  data2b,data2b,temp_data
        ADD expect1,data1a,data2b
        
        LI  temp_data,0X3FFF
        AND data3b,data3b,temp_data
        LI  temp_data,0xa000
        OR  data3b,data3b,temp_data    #   bit15_13=101 
        AND data4b,data3b,mask 
        SLLI temp_data,data4b,32
        OR  data4b,data4b,temp_data   
        ADD expect3,data3a,data4b
        
    J   to_add64_imm 
    
    bits_11: # Bits [15:14] 11 sign extend and duplicate (makes no sense for len=1 32 bit 
        LI  temp_data,0X1FFF
        AND data1b,data1b,temp_data 
        LI  temp_data,0xC000
        OR  data1b,data1b,temp_data    #   bit15_13=110
        AND data2b,data1b,mask 
        SLLI temp_data,data2b,32
        OR  data2b,data2b,temp_data
        ADD expect1,data1a,data2b
        
        LI  temp_data,0X3FFF
        AND data3b,data3b,temp_data
        LI  temp_data,0xE000
        OR  data3b,data3b,temp_data    #   bit15_13=111 
        AND data4b,data3b,mask 
        LI  temp_data,0xFFFFC000
        OR  data4b,data4b,temp_data
        SLLI temp_data,data4b,32
        OR  data4b,data4b,temp_data   
        ADD expect3,data3a,data4b
    
    J   to_add64_imm 
    
    to_add64_imm: 
        # override flag, see EAS_rfpc Table 2.12
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref and dm
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data1b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm
        .insn s 43,0,address,cluster_scratch_add64_imm(cppcmd_data_ref);# cls_clr_imm
        
        ADDI address,group_num , 0x8 
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x24,0x0,0x0); #override dref and dm
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[15:0]
        LI   temp_data,0
        SRLI temp_data,data3b,14
        SLLI temp_data,temp_data,41
        OR cppcmd_data_ref, cppcmd_data_ref,temp_data                    # override rs1[45:41] dm
        .insn s 43,0,address,cluster_scratch_add64_imm(cppcmd_data_ref);# cls_clr_imm 
               
        ADD address, group_num, zero # set to initial value
        #read the operation data in sram addr to compare with expected data
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50);
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
        
        ADD address, group_num, zero # set to initial value            
        WAIT_ON_SIGNAL (SIG1_pos,1);    
        
        LD  temp_data, 0x50(xfer)
        BNE temp_data, expect1, test_failed
        LD  temp_data, 0x58(xfer)
        BNE temp_data, expect3, test_failed

SUB loop_count, loop_count, one
BNE loop_count, zero,add64_imm_loop   

NOP
NOP
NOP


####################################################
# test6    64bit test_add64_imm
####################################################

add64_test_add_imm_loop:
    LI data1a ,0x234ff478f123f456
    LI data3a ,0xffffffffffffeccc
    
    #store the data to cpp memory 
    SD data1a ,0x0(xfer)
    SD data3a ,0x8(xfer)
    
    LI data1b ,0xf434   
    LI data3b ,0x0565  
    #write data to sram

    ADD address, group_num, zero # set to initial value
    #slli address, address, 2
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x0);
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref);#
    
    #ADD address, group_num, zero # set to initial value
    WAIT_ON_SIGNAL (SIG1_pos,1); 
    
    add64_test_add_imm_expect:

        ANDI data1b ,data1b,0x1F
        ADD expect1,data1a,data1b

        ANDI data3b ,data3b,0x1F
        ADD expect3,data3a,data3b

        #test_add64_imm
        # override flag, see EAS_rfpc Table 2.12

        ADD address, group_num, zero # set to initial value
        #slli address, address, 2
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); //override byte mask
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        SLLI data1b,data1b,16
        OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[28:21]  byte mask
        .insn s 43,0,address,cluster_scratch_test_add64_imm(cppcmd_data_ref);
        WAIT_ON_SIGNAL (SIG1_pos,1); 

        ADD address, group_num, zero # set to initial value
        ADDI address, address, 8
        #slli address, address, 2
        #ADDI address,group_num , 0x20
        SLLI data3b,data3b,16
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18); 
        OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[28:21]  byte mask
        .insn s 43,0,address,cluster_scratch_test_add64_imm(cppcmd_data_ref); 
        WAIT_ON_SIGNAL (SIG1_pos,1);

        #compare pushdata
        LD  temp_data, 0x10(xfer)
        BNE temp_data, data1a, test_failed 
        LD  temp_data, 0x18(xfer)
        BNE temp_data, data3a, test_failed

        ADD address, group_num, zero # set to initial value
        
        #read the operation data in sram addr to compare with expected data
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50);
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
        
        ADD address, group_num, zero # set to initial value            
        WAIT_ON_SIGNAL (SIG1_pos,1);                    
        
        LD  temp_data, 0x50(xfer)
        BNE temp_data, expect1, test_failed
        LD  temp_data, 0x58(xfer)
        BNE temp_data, expect3, test_failed 
    /*
        #calculate the expected values
        LI   temp_data,0xFFFFFFFF
        ANDI data1b ,data1b,0x1F
        ADD expect1,data1a,data1b 
        
        ANDI data3b ,data3b,0x1F
        ADD expect3,data3a,data3b
        
        #test_add64_imm
        # override flag, see EAS_rfpc Table 2.12
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x10); 
        #RS1 {Island_ID(7 or 0),data_master(5 or 0 ),(signal_master(5 or 0),Signal_ref(7 or 3),Byte_Mask(8 or 0),
        #OVERRIDE(8),LENGTH(5),DATA_REF(16)
        SLLI data1b,data1b,16
        OR cppcmd_data_ref, cppcmd_data_ref, data1b # override rs1[20:16]  len
        .insn s 43,0,address,cluster_scratch_test_add64_imm(cppcmd_data_ref);
        WAIT_ON_SIGNAL (SIG1_pos,1); 
        
        ADDI address,group_num , 0x8
        SLLI data3b,data3b,16
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x18); 
        OR cppcmd_data_ref, cppcmd_data_ref, data3b # override rs1[20:16]  len 
        .insn s 43,0,address,cluster_scratch_test_add64_imm(cppcmd_data_ref); 
        WAIT_ON_SIGNAL (SIG1_pos,1); 
        
        
        #compare pushdata
        LD  temp_data, 0x20(xfer)
        BNE temp_data, data1a, test_failed 
        LD  temp_data, 0x28(xfer)
        BNE temp_data, data3a, test_failed
        
        ADD address, group_num, zero # set to initial value
        
        #read the operation data in sram addr to compare with expected data
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x50);
        .insn s 43,0,address,cluster_scratch_read_le(cppcmd_data_ref);# CPP Command read
        
        ADD address, group_num, zero # set to initial value            
        WAIT_ON_SIGNAL (SIG1_pos,1);                    
        
        LD  temp_data, 0x50(xfer)
        BNE temp_data, expect1, test_failed
        LD  temp_data, 0x58(xfer)
        BNE temp_data, expect3, test_failed  
*/

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
