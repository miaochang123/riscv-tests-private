 #;-----------------------  
#; TEST_NAME: tcam16.uc
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


#define zero   x0 # zero register
#define cppcmd_data_ref x3
#define count       x4
#define hart_id     x10 #hart csr register

#define data1       x11
#define data2       x12
#define data3       x13
#define data4       x14
#define expect      x15
#define expect_high x16
#define match_index x17
#define address     x19
#define wdata       x20
#define count_m32   x21
#define cl_num      x22
#define group_num   x23
#define temp_data   x24
#define temp_data_1 x25
#define expect_high_or_mask   x26
#define xfer        x27
#define temp_reg    x30
#define expect_or_mask x31



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
#; tcam lookup16
#;	First time should match 0, then 1, etc
#        ; MAtch returns   [7:0] = match
#        ; MAtch returns   [63:8] = Bit set for each entry that matches
#;---------------------------------------------     

#################test1: Set all MASK fields to all 1's ####################
lookup_mask_all_1:
    LI temp_data,0xffffffff00010002
    SD temp_data, 0x20(xfer)     
    LI temp_data,0xffffffff00040008
    SD temp_data, 0x28(xfer) 
    LI temp_data,0xffffffff00100020
    SD temp_data, 0x30(xfer)
    LI temp_data,0xffffffff00400080
    SD temp_data, 0x38(xfer)
    LI temp_data,0xffffffff01000200
    SD temp_data, 0x40(xfer)
    LI temp_data,0xffffffff04000800
    SD temp_data, 0x48(xfer)
    LI temp_data,0xffffffff10002000
    SD temp_data, 0x50(xfer)
    LI temp_data,0xffffffff40008000
    SD temp_data, 0x58(xfer)

    ADDI address, group_num,0  
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x20)  ;
    .insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
    ADD address, group_num, zero 
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;  


#; Lookup subroutine
#;-----------------------------------------------------------

start_loop1:
    LI count,0
    LI match_index,0
    LI wdata,0x1
    LI expect_or_mask,0x05050500
    LI expect_high_or_mask,0x0

    lookup_loop1:
    
        LI expect_high,0
        
        ADD temp_data,wdata,zero
        SD temp_data, 0x20(xfer) 
        
        ##write all  data to cls sram
        ADDI address, group_num,0
        LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x20)  ;
        .insn s 43,0,address,cluster_scratch_tcam_lookup16(cppcmd_data_ref)	 ;
        
        WAIT_ON_SIGNAL (SIG1_pos,1) 	;
        
        ##expect to match 0 then 1,4,then 5,8 then 9
        ADD expect,match_index,zero
        
        LI temp_data,0x8
        SLTU temp_data,match_index,temp_data ###<8  first entry
        BNEZ temp_data,skip0  
        
        LI temp_data,32  
        SLTU temp_data,match_index,temp_data #### <32
        BNEZ temp_data,less_than32_0
        
        gteq_32_0:
            LI  temp_data,32
            SUB count_m32,match_index,temp_data
            LI  temp_data,0x1
            SLL expect_high,temp_data,count_m32 
            J skip0
        
        less_than32_0:
            LI  temp_data,0x2
            SLL temp_data,temp_data,match_index
            OR  expect,expect,temp_data
                
        skip0:
            LI temp_data,0x8
            BNE count,temp_data,check_match0
            LI expect_high_or_mask,0x0a0a0a0a
            LI expect_or_mask,0x0
            J  check_match0                
        
        check_match0:
            OR expect,expect,expect_or_mask
            OR expect_high,expect_high,expect_high_or_mask

            LWU temp_data,0x20(xfer)
            BNE temp_data,expect,test_failed
            LWU temp_data,0x24(xfer)
            BNE temp_data,expect_high,test_failed 
            
            ANDI temp_data,count,0x1
            BNEZ temp_data,inc_by6  # count[0] !=0
            ADDI match_index,match_index,2
            J next_data
        
        inc_by6:
            ADDI match_index,match_index,6
        
        next_data:
            SLLI wdata,wdata,1
            ADDI count,count,1 
    LI temp_data,16
    BNE temp_data,count,lookup_loop1
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
    
    LI match_index,2
    LI expect_or_mask,0x55555500
    LI expect_high_or_mask,0x55555555
    LI wdata,0xfffffffe
    
    J start_loop2


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
            LI expect_high,0 
            ADD temp_data,wdata,zero
            SD temp_data, 0x30(xfer)  
    
            ADDI address, group_num,0
            LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x30)  ;
            .insn s 43,0,address,cluster_scratch_tcam_lookup16(cppcmd_data_ref)	 ;
    
            WAIT_ON_SIGNAL (SIG1_pos,1) 	; 
    
        ADD expect,match_index,zero 
    
        LI temp_data,0x8
        SLTU temp_data,match_index,temp_data ###<8  first entry
        BNEZ temp_data,skip2  
    
        LI temp_data,32  
        SLTU temp_data,match_index,temp_data #### <32
        BNEZ temp_data,less_than32_2
    
        gteq_32_2:
            LI  temp_data,32
            SUB count_m32,match_index,temp_data
            LI  temp_data,0x33
            SLL expect_high,temp_data,count_m32 
            J skip2  
    
        less_than32_2:
            LI  temp_data,0x33
            SLL temp_data,temp_data,match_index
            OR  expect,expect,temp_data
    
        skip2:
    
        check_match2:
            OR expect,expect,expect_or_mask
            OR expect_high,expect_high,expect_high_or_mask
        ##compare pushdata     
        LWU temp_data,0x30(xfer)
        BNE temp_data,expect,test_failed
        LWU temp_data,0x34(xfer)
        BNE temp_data,expect_high,test_failed 
    
        ADDI match_index,match_index,8
    
        next_data2:    
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
    
    LI match_index,0x2
    LI expect_or_mask,0x55555500
    LI expect_high_or_mask,0x55555555
    LI wdata,0xfffffffe

    start_loop3:
        LI count,0
          lookup_loop3: 
            LI temp_data,1
            BEQ temp_data,count,rot_data1_1
            LI temp_data,2
            BEQ temp_data,count,rot_data2_1
            LI temp_data,3
            BEQ temp_data,count,rot_data3_1
            LI temp_data,4
            BEQ temp_data,count,rot_data4_1
            LI temp_data,5
            BEQ temp_data,count,rot_data5_1
            LI temp_data,6
            BEQ temp_data,count,rot_data6_1
            LI temp_data,7
            BEQ temp_data,count,rot_data7_1
            LI temp_data,8
            BEQ temp_data,count,rot_data8_1
            LI temp_data,9
            BEQ temp_data,count,rot_data9_1
            LI temp_data,10
            BEQ temp_data,count,rot_data10_1
            LI temp_data,11
            BEQ temp_data,count,rot_data11_1
            J  send_cmd3
      
        rot_data1_1:
            LI wdata,0xfffffffd
            J  send_cmd3
    
        rot_data2_1:
            LI wdata,0xfffffffb
            J  send_cmd3
    
        rot_data3_1:
            LI wdata,0xfffffff7
            J  send_cmd3
    
        rot_data4_1:
            LI wdata,0xffffffef
            J  send_cmd3
    
        rot_data5_1:
            LI wdata,0xffffffdf
            J  send_cmd3
    
        rot_data6_1:
            LI wdata,0xffffffbf
            J  send_cmd3

        rot_data7_1:
            LI wdata,0xffffff7f
            J  send_cmd3
                     
        rot_data8_1:
            LI wdata,0xfffffeff
            J  send_cmd3

        rot_data9_1:
            LI wdata,0xfffffdff
            J  send_cmd3

        rot_data10_1:
            LI wdata,0xfffffbff
            J  send_cmd3  

        rot_data11_1:
            LI wdata,0xfffff7ff
            J  send_cmd3              

        send_cmd3:
            LI expect_high,0
            SW wdata,0x50(xfer) 
    
            ADDI address, group_num,0
            LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xb,0x50)  ;
            .insn s 43,0,address,cluster_scratch_tcam_lookup16(cppcmd_data_ref)	 ;
    
            WAIT_ON_SIGNAL (SIG1_pos,1) 	;
            #gen expectdata
            ADD expect,match_index,zero

            LI temp_data,40
            SLTU temp_data,match_index,temp_data ###<8  first entry
            BNEZ temp_data,skip3

            LI temp_data,64  
            SLTU temp_data,match_index,temp_data #### <32
            BNEZ temp_data,less_than32_3

            gteq_32_3:
                LI  expect_or_mask,0xaaaaaa00
                LI  expect_high_or_mask,0xaaaaaaaa 
                LI  temp_data,64
                SUB count_m32,match_index,temp_data
                LI  temp_data,0x33
                SLL expect_high,temp_data,count_m32 
                J skip3 

            less_than32_3:
                LI  temp_data,32
                SUB count_m32,match_index,temp_data
                LI  temp_data,0x33
                SLL temp_data,temp_data,count_m32
                OR  expect,expect,temp_data 

            skip3:
            check_match3:
                OR expect,expect,expect_or_mask
                OR expect_high,expect_high,expect_high_or_mask
            ##compare pushdata     
            LWU temp_data,0x50(xfer)
            BNE temp_data,expect,test_failed
            LWU temp_data,0x54(xfer)
            BNE temp_data,expect_high,test_failed

            ADDI match_index,match_index,8 

         
            next_data3:    
                ADDI count,count,1 
                #ADDI wdata,wdata,1 
                LI temp_data,12
            BNE temp_data,count,lookup_loop3   
##################test4: check a nomatch##################
lookup_check_no_match:
    LI temp_data,0xaaaa
    SW temp_data,0x10(xfer)

    ADDI address, group_num,0
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x10)  ;
    .insn s 43,0,address,cluster_scratch_tcam_lookup16(cppcmd_data_ref)	 ;
    
    WAIT_ON_SIGNAL (SIG1_pos,1) 	;

    LI expect,0xff
    LI expect_high,0x0

    LW temp_data,0x10(xfer)
    BNE temp_data,expect,test_failed
    LW temp_data,0x14(xfer)
    BNE temp_data,expect_high,test_failed
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

                                     
