#;-----------------------  
#; TEST_NAME: tcam32.uc
#;      Run on all MEs for higher coverage
#; 1) Set all MASK fields to all 1's, Vary data field data
#; 2) Set all DATA fields to all 1's
#;    Will do a Walking 0 in the MASK field
#; 3) Do length=12 case
#; 4) Check a nomatch case     
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


#define zero            x0 # zero register
#define cppcmd_data_ref x3
#define count           x4
#define hart_id         x10 #hart csr register

#define data_mask       x11
#define upper_byte      x12
#define count16         x13
#define shift_num       x14
#define expect          x15
#define expect_high     x16
#define match_index     x17
#define address         x19
#define wdata           x20
#define count_m32       x21
#define cl_num          x22
#define group_num       x23
#define temp_data       x24
#define temp_data_1     x25
#define expect_high_or_mask   x26
#define xfer            x27
#define all_ones        x30
#define expect_or_mask  x31



.equ CPP_MEM_ADDR,   0xf0000000


RVTEST_RV64U
RVTEST_CODE_BEGIN

	
LI group_num, 0xe00 # 3 msb used change values 2,3,4,5,6,7
AND group_num , group_num, a0 # X10 group numbers 16 cores per group, currently 4,7,8,11,12,15 group numbers used
	
SRLI group_num , group_num , 0x5 # group number move to  4  - F gggg # group number move to  00 0ggg cccc
ANDI cl_num ,a0, 0xf # core number

LI temp_data_1 , 0x1
BGE cl_num, temp_data_1, test_passed # only run on core zero of each group
	
OR group_num , group_num , cl_num # Base Addr for each core range 0 - 127
SLLI group_num , group_num, 8 

ADD address, group_num, zero 	


LI xfer, CPP_MEM_ADDR 
LI data_mask,0xff
#store the add_data to cpp memory 
LI temp_data, 0
SD temp_data, 0x0(xfer)
SD temp_data, 0x8(xfer) 
SD temp_data, 0x10(xfer) 
SD temp_data, 0x18(xfer) 

##write all  data to cls sram
ADDI address, group_num,0x40  
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)  ;
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
ADD address, group_num, zero 
WAIT_ON_SIGNAL (SIG1_pos,1) 	;  

#;---------------------------------------------
#; tcam lookup32
#;	First time should match 0, then 1, etc
#        ; MAtch returns   [7:0]   = match
#        ; MAtch returns   [15:8]  = Upper 8 bit of data entry
#        ; MAtch returns   [31:16] = Bit set for each entry that matches
#;---------------------------------------------     

#################test1: Set all MASK fields to all 1's ####################
lookup_mask_all_1:
    LI shift_num,0x0
rtn_lookup:
    LI wdata,0x00000001
    LI all_ones,0xffffffff

    ADDI temp_data,shift_num,0
    SLL temp_data,wdata,temp_data
    SW temp_data, 0x20(xfer) 
    SW all_ones, 0x24(xfer) 

    ADDI temp_data,shift_num,1
    SLL temp_data,wdata,temp_data
    #LI temp_data,0xffffffff00000002
    SW temp_data, 0x28(xfer)
    SW all_ones, 0x2c(xfer)

    ADDI temp_data,shift_num,2
    SLL temp_data,wdata,temp_data
    #LI temp_data,0xffffffff00000004
    SW temp_data, 0x30(xfer)
    SW all_ones, 0x34(xfer)

    ADDI temp_data,shift_num,3
    SLL temp_data,wdata,temp_data
    #LI temp_data,0xffffffff00000008
    SW temp_data, 0x38(xfer)
    SW all_ones, 0x3c(xfer)

    ADDI temp_data,shift_num,4
    SLL temp_data,wdata,temp_data
    #LI temp_data,0xffffffff00000010
    SW temp_data, 0x40(xfer)
    SW all_ones, 0x44(xfer)

    ADDI temp_data,shift_num,5
    SLL temp_data,wdata,temp_data
    #LI temp_data,0xffffffff00000020
    SW temp_data, 0x48(xfer)
    SW all_ones, 0x4c(xfer)

    ADDI temp_data,shift_num,6
    SLL temp_data,wdata,temp_data
    #LI temp_data,0xffffffff00000040
    SW temp_data, 0x50(xfer)
    SW all_ones, 0x54(xfer)

    ADDI temp_data,shift_num,7
    SLL temp_data,wdata,temp_data 
    #LI temp_data,0xffffffff00000080
    SW temp_data, 0x58(xfer)
    SW all_ones, 0x5c(xfer)  

    ADDI address, group_num,0  
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  


#; Lookup subroutine
#;-----------------------------------------------------------

start_loop1:
    LI count,0
    LI temp_data,0x1
    SLL wdata,temp_data,shift_num

    lookup_loop1:
        
        ADD temp_data,wdata,zero
        SD temp_data, 0x20(xfer) 
        
        ##write all  data to cls sram
        ADDI address, group_num,0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x20)  ;
        .insn s 43,0,address,cluster_scratch_tcam_lookup32(cppcmd_data_ref)	 ;
        
        WAIT_ON_SIGNAL (SIG1_pos,1) 	;
        
        SLLI expect,count,3
        SRLI temp_data,wdata,24
        AND upper_byte,temp_data,data_mask
        SLLI temp_data,upper_byte,8
        OR  expect,expect,temp_data
        
        #; Expect to match 0 then 2 then 4,etc.
	    #; Need to add 16 to 2*count and use that as the shift_count
        ADDI count16,count,16
        ADD  count16,count,count16
        
        LI temp_data,0x1
        SLL temp_data,temp_data,count16
        OR expect,expect,temp_data

        LWU temp_data,0x20(xfer)
        BNE temp_data,expect,test_failed

        
        SLLI wdata,wdata,1
        ADDI count,count,1 

        LI temp_data,8
        BNE temp_data,count,lookup_loop1

        ADDI shift_num,shift_num,8
        LI temp_data,32
        BNE temp_data,shift_num,rtn_lookup 
nop
nop
nop
#############test2:  Set all DATA fields to all 1's       ########################### 
#############  Will do a Walking 0 in the MASK field##########################
lookup_data_all_1:
    LI temp_data,0xfffffffeffffffff
    SD temp_data, 0x60(xfer) 
    LI temp_data,0xfffffffdffffffff
    SD temp_data, 0x68(xfer) 
    LI temp_data,0xfffffffbffffffff
    SD temp_data, 0x70(xfer)
    LI temp_data,0xfffffff7ffffffff
    SD temp_data, 0x78(xfer)
    LI temp_data,0xffffffefffffffff
    SD temp_data, 0x80(xfer)
    LI temp_data,0xffffffdfffffffff
    SD temp_data, 0x88(xfer)
    LI temp_data,0xffffffbfffffffff
    SD temp_data, 0x90(xfer)
    LI temp_data,0xffffff7fffffffff
    SD temp_data, 0x98(xfer)  
    
    ADDI address, group_num,0  
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x60)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  
    
    LI wdata,0xfffffffe
    

    start_loop2:
        LI count,0

        lookup_loop2:
            LI temp_data,1
            BEQ temp_data,count,rot_data1
            LI temp_data,2
            BEQ temp_data,count,rot_data2
            LI temp_data,3
            BEQ temp_data,count,rot_data3
            LI temp_data,4
            BEQ temp_data,count,rot_data4
            LI temp_data,5
            BEQ temp_data,count,rot_data5
            LI temp_data,6
            BEQ temp_data,count,rot_data6
            LI temp_data,7
            BEQ temp_data,count,rot_data7
            J send_cmd 
    
        rot_data1:
            LI wdata,0xfffffffd
            J send_cmd
    
        rot_data2:
            LI wdata,0xfffffffb
            J send_cmd
    
        rot_data3:
            LI wdata,0xfffffff7
            J send_cmd
    
        rot_data4:
            LI wdata,0xffffffef
            J send_cmd
    
        rot_data5:
            LI wdata,0xffffffdf
            J send_cmd
    
        rot_data6:
            LI wdata,0xffffffbf
            J send_cmd
    
        rot_data7:
            LI wdata,0xffffff7f
            J send_cmd
    
    
        send_cmd:
            ADD temp_data,wdata,zero
            SD temp_data, 0x30(xfer)  
    
            ADDI address, group_num,0
            LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x30)  ;
            .insn s 43,0,address,cluster_scratch_tcam_lookup32(cppcmd_data_ref)	 ;
    
            WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
    
        SLLI expect,count,3
        LI temp_data,0xff00
        OR expect,expect,temp_data

	    #; Expect to match 0and1 then 2and3 then 4and5,etc.
	    #; Need to add 16 to 2*count and use that as the shift_count           
        ADDI count16,count,16
        ADD  count16,count,count16

        LI temp_data,0x3
        SLL temp_data,temp_data,count16
        OR expect,expect,temp_data

        LWU temp_data,0x30(xfer)
        BNE temp_data,expect,test_failed

        ADDI count,count,1 

        LI temp_data,8
        BNE temp_data,count,lookup_loop2   


nop
nop
nop

##################test3: len=12 ################## 
lookup_len12:
    LI temp_data,0xfffffffeffffffff
    SD temp_data, 0x10(xfer) 
    LI temp_data,0xfffffffdffffffff
    SD temp_data, 0x18(xfer) 
    LI temp_data,0xfffffffbffffffff
    SD temp_data, 0x20(xfer)
    LI temp_data,0xfffffff7ffffffff
    SD temp_data, 0x28(xfer)
    LI temp_data,0xffffffefffffffff
    SD temp_data, 0x30(xfer)
    LI temp_data,0xffffffdfffffffff
    SD temp_data, 0x38(xfer)
    LI temp_data,0xffffffbfffffffff
    SD temp_data, 0x40(xfer)
    LI temp_data,0xffffff7fffffffff
    SD temp_data, 0x48(xfer) 
 
    ADDI address, group_num,0  
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x10)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LI temp_data,0xfffffeffffffffff
    SD temp_data, 0x50(xfer) 
    LI temp_data,0xfffffdffffffffff
    SD temp_data, 0x58(xfer) 
    LI temp_data,0xfffffbffffffffff
    SD temp_data, 0x60(xfer)
    LI temp_data,0xfffff7ffffffffff
    SD temp_data, 0x68(xfer)  

    ADDI address, group_num,0x40  
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x50)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;
    
    LI wdata,0xfffffffe

    start_loop3:
        LI count,0
        lookup_loop3:
            LI temp_data,1
            BEQ temp_data,count,rot_data1_3
            LI temp_data,2
            BEQ temp_data,count,rot_data2_3
            LI temp_data,3
            BEQ temp_data,count,rot_data3_3
            LI temp_data,4
            BEQ temp_data,count,rot_data4_3
            LI temp_data,5
            BEQ temp_data,count,rot_data5_3
            LI temp_data,6
            BEQ temp_data,count,rot_data6_3
            LI temp_data,7
            BEQ temp_data,count,rot_data7_3
            LI temp_data,8
            BEQ temp_data,count,rot_data8_3
            LI temp_data,9
            BEQ temp_data,count,rot_data9_3
            LI temp_data,10
            BEQ temp_data,count,rot_data10_3
            LI temp_data,11
            BEQ temp_data,count,rot_data11_3
            J send_cmd3 
    
        rot_data1_3:
            LI wdata,0xfffffffd
            J send_cmd3
    
        rot_data2_3:
            LI wdata,0xfffffffb
            J send_cmd3
    
        rot_data3_3:
            LI wdata,0xfffffff7
            J send_cmd3
    
        rot_data4_3:
            LI wdata,0xffffffef
            J send_cmd3
    
        rot_data5_3:
            LI wdata,0xffffffdf
            J send_cmd3
    
        rot_data6_3:
            LI wdata,0xffffffbf
            J send_cmd3
    
        rot_data7_3:
            LI wdata,0xffffff7f
            J send_cmd3
        
        rot_data8_3:
            LI wdata,0xfffffeff
            J send_cmd3

        rot_data9_3:
            LI wdata,0xfffffdff
            J send_cmd3    

        rot_data10_3:
            LI wdata,0xfffffbff
            J send_cmd3

        rot_data11_3:
            LI wdata,0xfffff7ff
            J send_cmd3    

        send_cmd3:
            SW wdata,0x50(xfer) 
    
            ADDI address, group_num,0
            LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xb,0x50)  ;
            .insn s 43,0,address,cluster_scratch_tcam_lookup32(cppcmd_data_ref)	 ;
    
            WAIT_ON_SIGNAL (SIG1_pos,1) 	;
            #gen expectdata
            SLLI expect,count,3
            SRLI temp_data,wdata,24
            AND upper_byte,temp_data,data_mask
            SLLI temp_data,upper_byte,8
            OR  expect,expect,temp_data

	        ##; Since LEN=12, The 16 bit mask corresponds to 23 to 8
	        ##; Expect to match 0 then 2 then 4,etc.
	        ##; Need to add 16 to 2*count and use that as the shift_count

            LI temp_data,4
            SLTU temp_data,count,temp_data
            BNEZ temp_data,skip_bitmask

            ADDI count16,count,8    #adding 8 instead of 16
            ADD  count16,count,count16 
            
            LI temp_data,0x3
            SLL temp_data,temp_data,count16
            OR expect,expect,temp_data

            skip_bitmask:
                LWU temp_data,0x50(xfer)
                BNE temp_data,expect,test_failed

                ADDI count,count,1 

                LI temp_data,12
                BNE temp_data,count,lookup_loop3

##################test4: check a nomatch##################
lookup_check_no_match:
    LI temp_data,0xaaaa
    SW temp_data,0x10(xfer)

    ADDI address, group_num,0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x10)  ;
    .insn s 43,0,address,cluster_scratch_tcam_lookup32(cppcmd_data_ref)	 ;
    
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LI expect,0xff

    LW temp_data,0x10(xfer)
    BNE temp_data,expect,test_failed

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
                      


