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
#define mydataref       x13
#define count_dr       x14
#define index_num     x15
#define hash_address  x16
#define address       x17
#define offset        x18
#define mydata        x19
#define cl_num        x20
#define group_num     x21
#define temp_data     x23
#define temp_data_1   x24
#define mydata1       x25
#define xfer          x27
#define expect3       x30 
#define loop_count    x31



.equ CPP_MEM_ADDR,   0xf0000000


.equ INIT_DATA0A,     0x2222222211111111 ##mask=0001 aligned 64-bit
.equ INIT_DATA1A,     0x4444444433333333 ##mask=0010 aligned 64-bit
.equ INIT_DATA2A,     0x6666666655555555 ##mask=0100 aligned 64-bit
.equ INIT_DATA3A,     0x8888888877777777 ##mask=1000 aligned 64-bit
.equ INIT_DATA4A,     0x99999999 ##mask=0011 aligned 32-bit
.equ INIT_DATA5A,     0xaaaaaaaa ##mask=0110 not aligned 32-bit
.equ INIT_DATA6A,     0xbbbbbbbb ##mask=1100 aligned 32-bit
.equ INIT_DATA7A,     0xcccccccc ##mask=0111 not aligned 32-bit
.equ INIT_DATA8A,     0xdddddddd ##mask=1110 aligned 32-bit
.equ INIT_DATA9A,     0x33333333 ##mask=1010 not aligned,96-bit
.equ INIT_DATA10A,    0x55555555 ##mask=1010 not aligned,96-bit
.equ INIT_DATA11A,    0x77777777 ##mask=1010 not aligned,96-bit
.equ INIT_DATA12A,    0x99999999 ##mask=0001 aligned,32-bit

.equ INIT_DATA0B,     0x1111112222222211
.equ INIT_DATA1B,     0x3333443344443344
.equ INIT_DATA2B,     0x5566555566556666
.equ INIT_DATA3B,     0x8877777777888888
.equ INIT_DATA4B,     0xffff9999
.equ INIT_DATA5B,     0xffaaaaff
.equ INIT_DATA6B,     0xbbbbffff
.equ INIT_DATA7B,     0xffcccccc
.equ INIT_DATA8B,     0xddddddff
.equ INIT_DATA9B,     0x33ff33ff
.equ INIT_DATA10B,    0x55ff55ff
.equ INIT_DATA11B,    0x77ff77ff
.equ INIT_DATA12B,    0xffffff89 ##not match



RVTEST_RV64U
RVTEST_CODE_BEGIN



LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number
LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 #each core has 256 byte of address space


LI xfer, CPP_MEM_ADDR 
#store the add_data to cpp memory 
LI temp_data,0x0
SD temp_data,0x0(xfer)
SD temp_data,0x8(xfer) 
SD temp_data,0x10(xfer)
SD temp_data,0x18(xfer)

#######################################
########write initial data to sram
#######################################
ADD address, group_num, zero

LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write

WAIT_ON_SIGNAL (SIG1_pos,1) 	;   

LI loop_count,0
LI offset,0x0 


cmp_wr_loop:                          
    LI count_dr,0x0 
    LI temp_data,0x0
    BEQ temp_data,loop_count,check_cmp_rw_xfer
    LI temp_data,0x1 
    BEQ temp_data,loop_count,return1
    LI temp_data,0x2 
    BEQ temp_data,loop_count,return2
    LI temp_data,0x3 
    BEQ temp_data,loop_count,return3  
    LI temp_data,0x4 
    BEQ temp_data,loop_count,return4 

return1:
    LI offset,0x4
    J  check_cmp_rw_xfer

return2:
    LI offset,0x8
    J  check_cmp_rw_xfer

return3:
    LI offset,0xc
    J  check_cmp_rw_xfer 

return4:
    SLLI mydataref,count_dr,2

    LI xfer, CPP_MEM_ADDR 
    OR xfer,xfer,mydataref    

    LI offset,0x10
    LI temp_data,0
    SD temp_data,0x20(xfer)
    SD temp_data,0x28(xfer)
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x3,0x0)  ;
    LI temp_data,0x20
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
    
    LI offset,0x14
    LI mydata ,0x03020100
    LI mydata1,0x83828180 
    
    SW mydata ,0x30(xfer)
    SW mydata1,0x34(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x1,0x0)  ;
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
     
    #; CMP_RW - Match Byte 0 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI  expect2,0
    ADD expect2,expect2,mydata1
    
    LI mydata ,0x06050400
    LI mydata1,0x86858480
    SW mydata ,0x30(xfer)
    SW mydata1,0x34(xfer)   
      
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x1,0x21,0x1,0x0)  ; #Bytemask = 1 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x34(xfer)
    BNE temp_data, expect2, test_failed 
    
    #; CMP_RW - Match Byte 1 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI  expect2,0
    ADD expect2,expect2,mydata1
    
    LI mydata ,0x09080407
    LI mydata1,0x89888487
    SW mydata ,0x40(xfer)
    SW mydata1,0x44(xfer)   
      
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x2,0x21,0x1,0x0)  ; #Bytemask = 2 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x44(xfer)
    BNE temp_data, expect2, test_failed   
    
    #; CMP_RW - Match Byte 2
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI  expect2,0
    ADD expect2,expect2,mydata1
    
    LI mydata ,0x0C080B0A
    LI mydata1,0x8C888B8A
    SW mydata ,0x50(xfer)
    SW mydata1,0x54(xfer)   
      
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x4,0x21,0x1,0x0)  ; #Bytemask = 4 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x54(xfer)
    BNE temp_data, expect2, test_failed 
    
    
    #; CMP_RW - Match Byte 3
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI  expect2,0
    ADD expect2,expect2,mydata1
    
    LI mydata ,0x0c0f0e0d
    LI mydata1,0x8c8f8e8d
    SW mydata ,0x60(xfer)
    SW mydata1,0x64(xfer)   
      
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x8,0x21,0x1,0x0)  ; #Bytemask = 4 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x64(xfer)
    BNE temp_data, expect2, test_failed 
    
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI  expect2,0
    ADD expect2,expect2,mydata1 
     
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x20,0x1,0x0)  ; #Bytemask = 4 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x80
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data   
    .insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
        
    
    LWU temp_data,0x80(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x84(xfer)
    BNE temp_data, expect2, test_failed

##;----------------------------------------------------------
##; Check that we mis-match on each combination of byte_masks
##;---------------------------------------------------------- 
    LI mydata ,0xffffffff
    LI mydata1,0x0 
    
    SW mydata ,0x30(xfer)
    SW mydata1,0x34(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x1,0x0)  ;
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
     
    #; CMP_RW - Match Byte 0 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI  expect2,0
    ADD expect2,expect2,mydata1
    
    LI mydata ,0xffffffee
    LI mydata1,0x00000011
    SW mydata ,0x30(xfer)
    SW mydata1,0x34(xfer)   
 
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x1,0x21,0x1,0x0)  ; #Bytemask =  
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;

    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x34(xfer)
    BNE temp_data, expect2, test_failed     


    #; CMP_RW - Match Byte 1 
    
    LI mydata ,0xffffeeff
    LI mydata1,0x00001100
    SW mydata ,0x50(xfer)
    SW mydata1,0x54(xfer)    

     ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x2,0x21,0x1,0x0)  ; #Bytemask =  
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;

    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x34(xfer)
    BNE temp_data, expect2, test_failed  

    #; CMP_RW - Match Byte 2 
    
    LI mydata ,0xffeeffff
    LI mydata1,0x00110000
    SW mydata ,0x70(xfer)
    SW mydata1,0x74(xfer)    

     ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x4,0x21,0x1,0x0)  ; #Bytemask =  4
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x70
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;

    LWU temp_data,0x70(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x74(xfer)
    BNE temp_data, expect2, test_failed   

    #; CMP_RW - Match Byte 3 
    
    LI mydata ,0xeeffffff
    LI mydata1,0x11000000
    SW mydata ,0x90(xfer)
    SW mydata1,0x94(xfer)    

    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x8,0x21,0x1,0x0)  ; #Bytemask =  8
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x90
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	;

    LWU temp_data,0x90(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0x94(xfer)
    BNE temp_data, expect2, test_failed

    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x1,0x0)  ; #Bytemask =  8
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0xb0
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data  
    .insn s 43,0,address,cluster_scratch_read(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LWU temp_data,0xb0(xfer)
    BNE temp_data, expect1, test_failed  
    LWU temp_data,0xb4(xfer)
    BNE temp_data, expect2, test_failed  

##; Add more length cases here 


 
    ADDI count_dr,count_dr,1
    LI temp_data,0x4 
    BNE count_dr,temp_data,return4        
    
    J test_passed 

check_cmp_rw_xfer:
##;----------------------------------------------------------
##; Check that we can match on each combination of byte_masks
##    override dr,bytemask
##;---------------------------------------------------------- 
    SLLI mydataref,count_dr,2
    LI mydata,0x03020100
    SD mydata,0x20(xfer)
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
    ###############################
    ##CMP_RW - Match Byte 0 
    LI xfer, CPP_MEM_ADDR 
    OR xfer,xfer,mydataref 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x06050400
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x1,0x21,0x0,0x0)  ; #Bytemask = 1 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed 
    
    ##############################
    ##CMP_RW - Match Byte 1 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x09080407
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x2,0x21,0x0,0x0)  ; #Bytemask = 2 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed  
    #############################
    ##CMP_RW - Match Byte 2 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x0c080b0a
    SD mydata,0x50(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x4,0x21,0x0,0x0)  ; #Bytemask = 4 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed  
    
    #############################
    ##CMP_RW - Match Byte 3 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x0c0f0e0d
    SD mydata,0x60(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x8,0x21,0x0,0x0)  ; #Bytemask = 8 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed 
    
    #############################
    ##CMP_RW - Match Bytes 0 and 1
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x11100e0d
    SD mydata,0x70(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x3,0x21,0x0,0x70)  ; #Bytemask = 3 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x70
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x70(xfer)
    BNE temp_data, expect1, test_failed 
    
    #############################
    ##CMP_RW - Match Bytes 0 and 2
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x1310120d
    SD mydata,0x80(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x5,0x21,0x0,0x0)  ; #Bytemask = 5 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x80
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x80(xfer)
    BNE temp_data, expect1, test_failed 
    
    #############################
    ##CMP_RW - Match Bytes 0 and 3
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x1315140d
    SD mydata,0x90(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x9,0x21,0x0,0x0)  ; #Bytemask = 9 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x90
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x90(xfer)
    BNE temp_data, expect1, test_failed 
    
    #############################
    ##CMP_RW - Match Bytes 1 and 2
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x17151416
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x6,0x21,0x0,0x0)  ; #Bytemask = 6 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 1 and 3
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x17191418
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xa,0x21,0x0,0x0)  ; #Bytemask = 10 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 2 and 3
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x17191b1a
    SD mydata,0x50(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xc,0x21,0x0,0x0)  ; #Bytemask = 12 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0, 1 and 2 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x1c191b1a
    SD mydata,0x60(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x7,0x21,0x0,0x0)  ; #Bytemask = 7 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0, 1 and 3 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x1c1d1b1a
    SD mydata,0x70(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xb,0x21,0x0,0x0)  ; #Bytemask = 11 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x70
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x70(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0, 2 and 3 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x1c1d1e1a
    SD mydata,0x80(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xd,0x21,0x0,0x0)  ; #Bytemask = 13 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x80
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x80(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 1, 2 and 3 
    LI  expect1,0
    ADD expect1,expect1,mydata
    LI mydata,0x1c1d1e1f
    SD mydata,0x90(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xe,0x21,0x0,0x0)  ; #Bytemask = 14 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x90
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LW temp_data,0x90(xfer)
    BNE temp_data, expect1, test_failed
    
    ##;----------------------------------------------------------
    ##; Check that we mis-match on each combination of byte_masks
    ##;----------------------------------------------------------
    LI mydata,0xffffffff
    SD mydata,0x20(xfer)
    LI  expect1,0
    ADD expect1,expect1,mydata 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x20,0x0,0x0)  ;
    LI temp_data,0x20
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;   
    ###############################
    ##CMP_RW - Match Byte 0 
    LI mydata,0xffffffee
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x1,0x21,0x0,0x0)  ; #Bytemask = 1 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed 
    
    ##############################
    ##CMP_RW - Match Byte 1 
    LI mydata,0xffffeeff
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x2,0x21,0x0,0x0)  ; #Bytemask = 2 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed  
    #############################
    ##CMP_RW - Match Byte 2 
    LI mydata,0xffeeffff
    SD mydata,0x50(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x4,0x21,0x0,0x0)  ; #Bytemask = 4 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed  
    
    #############################
    ##CMP_RW - Match Byte 3 
    LI mydata,0xeeffffff
    SD mydata,0x60(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x8,0x21,0x0,0x0)  ; #Bytemask = 8 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed 
    
    #############################
    ##CMP_RW - Match Bytes 0 and 1
    LI mydata,0xffffffee
    SD mydata,0x70(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x3,0x21,0x0,0x0)  ; #Bytemask = 3 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x70
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x70(xfer)
    BNE temp_data, expect1, test_failed 
    ###------
    LI mydata,0xffffeeff
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x3,0x21,0x0,0x0)  ; #Bytemask = 3 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0 and 2
    LI mydata,0xffffffee
    SD mydata,0x80(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x5,0x21,0x0,0x0)  ; #Bytemask = 5 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x80
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x80(xfer)
    BNE temp_data, expect1, test_failed 
    ##-------
    LI mydata,0xffeeffff
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x5,0x21,0x0,0x0)  ; #Bytemask = 5 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0 and 3
    LI mydata,0xffffffee
    SD mydata,0x90(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x9,0x21,0x0,0x0)  ; #Bytemask = 9 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x90
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x90(xfer)
    BNE temp_data, expect1, test_failed 
    ##----
    LI mydata,0xeeffffff
    SD mydata,0x60(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x9,0x21,0x0,0x0)  ; #Bytemask = 9 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 1 and 2
    LI mydata,0xffffeeff
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x6,0x21,0x0,0x0)  ; #Bytemask = 6 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed
    
    ##----
    LI mydata,0xffeeffff
    SD mydata,0x20(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x6,0x21,0x0,0x0)  ; #Bytemask = 6 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x20
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x20(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 1 and 3
    LI mydata,0xffffeeff
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xa,0x21,0x0,0x0)  ; #Bytemask = 10 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed
    ##----
    LI mydata,0xeeffffff
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xa,0x21,0x0,0x0)  ; #Bytemask = 10 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 2 and 3
    LI mydata,0xffeeffff
    SD mydata,0x50(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xc,0x21,0x0,0x0)  ; #Bytemask = 12 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed
    ##-----
    LI mydata,0xeeffffff
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xc,0x21,0x0,0x0)  ; #Bytemask = 12 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0, 1 and 2
    LI mydata,0xffffffee
    SD mydata,0x60(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x7,0x21,0x0,0x0)  ; #Bytemask = 7 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xffffeeff
    SD mydata,0x20(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x7,0x21,0x0,0x0)  ; #Bytemask = 7 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x20
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x20(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xffeeffff
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0x7,0x21,0x0,0x0)  ; #Bytemask = 7 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0, 1 and 3 
    LI mydata,0xffffffee
    SD mydata,0x70(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xb,0x21,0x0,0x0)  ; #Bytemask = 11 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x70
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x70(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xffffeeff
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xb,0x21,0x0,0x0)  ; #Bytemask = 11 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xeeffffff
    SD mydata,0x50(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xb,0x21,0x0,0x0)  ; #Bytemask = 11 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 0, 2 and 3 
    LI mydata,0xffffffee
    SD mydata,0x80(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xd,0x21,0x0,0x0)  ; #Bytemask = 13 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x80
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x80(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xffeeffff
    SD mydata,0x50(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xd,0x21,0x0,0x0)  ; #Bytemask = 13 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x50
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x50(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xeeffffff
    SD mydata,0x60(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xd,0x21,0x0,0x0)  ; #Bytemask = 13 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x60
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x60(xfer)
    BNE temp_data, expect1, test_failed
    
    #############################
    ##CMP_RW - Match Bytes 1, 2 and 3 
    LI mydata,0xffffeeff
    SD mydata,0x90(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xe,0x21,0x0,0x0)  ; #Bytemask = 14 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x90
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x90(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xffeeffff
    SD mydata,0x30(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xe,0x21,0x0,0x0)  ; #Bytemask = 14 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x30
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x30(xfer)
    BNE temp_data, expect1, test_failed
    
    ##--
    LI mydata,0xeeffffff
    SD mydata,0x40(xfer) 
    
    ADD address, group_num, offset
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG5,0xe,0x21,0x0,0x0)  ; #Bytemask = 14 
    ###Island_ID,Data_Master,Signal_Master,Signal_Ref,Byte_Mask,Override,Length,Data_Ref
    LI temp_data,0x40
    ADD temp_data,temp_data,mydataref
    OR cppcmd_data_ref,cppcmd_data_ref,temp_data 
    .insn s 43,0,address,cluster_scratch_cmp_rw(cppcmd_data_ref)	 ;
    WAIT_ON_SIGNAL (SIG5_pos,1) 	; 
    
    LWU temp_data,0x40(xfer)
    BNE temp_data, expect1, test_failed
    
    ADDI count_dr,count_dr,1
    LI temp_data,0x4 
    BNE count_dr,temp_data,check_cmp_rw_xfer
    
    ADDI loop_count,loop_count,1
    LI temp_data,0x4
    BNE loop_count,temp_data,cmp_wr_loop



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
