#;-----------------------
#; TEST_NAME: crypto_scenario2.S
#   this case is based on crypto ut case 
#   crypto_verif.cryp_sm4_spec.default.s1
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

#define zero                    x0 # zero register
#define cppcmd_data_ref         x3
#define count                   x4
#define hart_id                 x10 #hart csr register
#define full_empty_sts          x11
#define one                     x12
#define ringptr_base            x13
#define zero_data               x14
#define expect                  x15
#define wdata                   x16
#define txfer                   x17
#define size                    x18
#define address                 x19
#define var                     x20
#define offset1                 x21
#define cl_num                  x22
#define group_num               x23
#define ctm_base                x24
#define filter_base             x25
#define base                    x26
#define xfer                    x27
#define t_data_ref              x28
#define temp_data1              x30
#define temp_data2              x31

.equ CPP_MEM_ADDR,      0xf0000000
.equ CTM_BASE_ADDR,     0x200000000
.equ CLS_CR_BLK_CSR_XPB_DEVICE_ID, 23
.equ BASIC_CFG, 0

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
LI ctm_base , CTM_BASE_ADDR
LI zero_data , 0x0

get_core_num:
        LI temp_data1 , 0xff
        AND cl_num ,  a0 , temp_data1
        LI temp_data1 , 0xf00
        AND group_num , a0 , temp_data1
        SRLI group_num , group_num , 0x8

BNE group_num , zero_data , test_passed

LI wdata , 0x1
SD wdata , 0x100(xfer)
LI one , CLS_CR_BLK_CSR_XPB_DEVICE_ID
SLLI address , one , 16
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
.insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

//prepare data for crypto dma transfer
LI wdata, 0x89ABCDEF01234567
SD wdata, 0x0(xfer)
LI wdata, 0x76543210FEDCBA98
SD wdata, 0x8(xfer)
LI wdata, 0x89ABCDEF01234567
SD wdata, 0x10(xfer)
LI wdata, 0x76543210FEDCBA98
SD wdata, 0x18(xfer)
LI wdata, 0x89ABCDEF01234567
SD wdata, 0x20(xfer)
LI wdata, 0x76543210FEDCBA98
SD wdata, 0x28(xfer)
LI wdata, 0xD206965E681EDF34
SD wdata, 0x30(xfer)
LI wdata, 0x536E424686B3E94F
SD wdata, 0x38(xfer)

LI address, 0x200000000
// write data to cls memory
LI cppcmd_data_ref , CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0)
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
ADDI address, address, 0x20 
WAIT_ON_SIGNAL (SIG1_pos,1)

LI cppcmd_data_ref , CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x20)
.insn s 43,0,address,cluster_scratch_write(cppcmd_data_ref)	 ;# CPP Command write
ADD address, address, zero 
WAIT_ON_SIGNAL (SIG1_pos,1)



// LI address , 0x0
// LI count , 0x200
// write_buf_loop:
//     LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x200) 
//     .insn s 43,0,address,crypto_write(cppcmd_data_ref)	 
//     ADDI address , address , 0x80
//     WAIT_ON_SIGNAL (SIG1_pos,1)
//     ADDI count , count , -1
//     BNE count , zero_data , write_buf_loop

LI wdata , 0x01c8000200000000
SD wdata , 0x0(xfer)
// LI wdata , 0x01c003F84E0614A0
//              01c207F84E0714A0
LI wdata , 0x01c207F8000714A0
SD wdata , 0x8(xfer)
LI wdata , 0x04CEC4D48CE4c794
SD wdata , 0x10(xfer)
LI wdata , 0x05C83442D3A5E380
SD wdata , 0x18(xfer)
LI wdata , 0x05CE1FA8900FA500
SD wdata , 0x20(xfer)
LI wdata , 0x05C8FB8CA590A580
SD wdata , 0x28(xfer)
LI wdata , 0x06c2472C700FA510
SD wdata , 0x30(xfer)
LI wdata , 0x04CBA91644CB7C69
SD wdata , 0x38(xfer)

#crypto_write_fifo
#LI base , 0x0
#ADDI address , base , 0x0
LI address , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0) 
.insn s 43,0,address,crypto_write_fifo(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)


LI wdata, 0x01C0000000040000
SD wdata , 0x40(xfer)
LI wdata, 0x01C80FB1000394B0
SD wdata , 0x48(xfer)
LI wdata, 0x0AC0708450319312
SD wdata , 0x50(xfer)
LI wdata, 0x0
SD wdata , 0x58(xfer)
LI address , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x3,0x40) 
.insn s 43,0,address,crypto_write_fifo(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI count , 100
LI zero_data , 0
delay_loop:
    ADDI count , count , -1;
    BNE count , zero_data , delay_loop

LI address , 0xA580
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x1,0x100) 
.insn s 43,0,address,crypto_read(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

Check_result:
    LI expect , 0xD206965E681EDF34
    LD wdata , 0x100(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x536E424686B3E94F
    LD wdata , 0x108(xfer)
    BNE expect , wdata ,  test_failed

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
