#;-----------------------
#; TEST_NAME: crypto_scenario.S
#   this case is based on crypto ut case 
#   crypto_verif.crypto_aes_sm4_basic.default.s1
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
#define offset2                 x20
#define offset1                 x21
#define cl_num                  x22
#define group_num               x23
#define autopush_base           x24
#define filter_base             x25
#define base                    x26
#define xfer                    x27
#define t_data_ref              x28
#define temp_data1              x30
#define temp_data2              x31

.equ CPP_MEM_ADDR,      0xf0000000
.equ CLS_CR_BLK_CSR_XPB_DEVICE_ID, 23
.equ BASIC_CFG, 0

RVTEST_RV64U
RVTEST_CODE_BEGIN

LI xfer , CPP_MEM_ADDR
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


LI wdata , 0x55555555
SD wdata , 0x200(xfer)
LI wdata , 0x0
SD wdata , 0x208(xfer)
LI wdata , 0x55555555
SD wdata , 0x210(xfer)
LI wdata , 0x0
SD wdata , 0x218(xfer)
LI wdata , 0x55555555
SD wdata , 0x220(xfer)
LI wdata , 0x0
SD wdata , 0x228(xfer)
LI wdata , 0x55555555
SD wdata , 0x230(xfer)
LI wdata , 0x0
SD wdata , 0x238(xfer)
LI wdata , 0x55555555
SD wdata , 0x240(xfer)
LI wdata , 0x0
SD wdata , 0x248(xfer)
LI wdata , 0x55555555
SD wdata , 0x250(xfer)
LI wdata , 0x0
SD wdata , 0x258(xfer)
LI wdata , 0x55555555
SD wdata , 0x260(xfer)
LI wdata , 0x0
SD wdata , 0x268(xfer)
LI wdata , 0x55555555
SD wdata , 0x270(xfer)
LI wdata , 0x0
SD wdata , 0x278(xfer)
LI wdata , 0x55555555
SD wdata , 0x280(xfer)
LI wdata , 0x0
SD wdata , 0x288(xfer)
LI wdata , 0x55555555
SD wdata , 0x290(xfer)
LI wdata , 0x0
SD wdata , 0x298(xfer)
LI wdata , 0x55555555
SD wdata , 0x2a0(xfer)
LI wdata , 0x0
SD wdata , 0x2a8(xfer)
LI wdata , 0x55555555
SD wdata , 0x2b0(xfer)
LI wdata , 0x0
SD wdata , 0x2b8(xfer)
LI wdata , 0x55555555
SD wdata , 0x2c0(xfer)
LI wdata , 0x0
SD wdata , 0x2c8(xfer)
LI wdata , 0x55555555
SD wdata , 0x2d0(xfer)
LI wdata , 0x0
SD wdata , 0x2d8(xfer)
LI wdata , 0x55555555
SD wdata , 0x2e0(xfer)
LI wdata , 0x0
SD wdata , 0x2e8(xfer)
LI wdata , 0x55555555
SD wdata , 0x2f0(xfer)
LI wdata , 0x0
SD wdata , 0x2f8(xfer)


LI address , 0x0
LI count , 0x200
write_buf_loop:
    LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x200) 
    .insn s 43,0,address,crypto_write(cppcmd_data_ref)	 
    ADDI address , address , 0x80
    WAIT_ON_SIGNAL (SIG1_pos,1)
    ADDI count , count , -1
    BNE count , zero_data , write_buf_loop

LI wdata , 0x04f58536ccd5e7e8
SD wdata , 0x0(xfer)
LI wdata , 0x05f0f75ec281ed11
SD wdata , 0x8(xfer)
LI wdata , 0x05fed36bc01f4040
SD wdata , 0x10(xfer)
LI wdata , 0x05f29b5be01f7820
SD wdata , 0x18(xfer)
LI wdata , 0x05fea3e7e00f0a10
SD wdata , 0x20(xfer)
LI wdata , 0x05f45a4217b1819d
SD wdata , 0x28(xfer)
LI wdata , 0x06fe28cb846fffa3
SD wdata , 0x30(xfer)
LI wdata , 0x0
SD wdata , 0x38(xfer)

#crypto_write_fifo
#LI base , 0x0
#ADDI address , base , 0x0
LI address , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x6,0x0) 
.insn s 43,0,address,crypto_write_fifo(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI wdata , 0x06fe83e052cf0817
SD wdata , 0x40(xfer)
LI address , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x40) 
.insn s 43,0,address,crypto_write_fifo(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI wdata , 0x04fe8fd0c6ef1a93
SD wdata , 0x50(xfer)
LI address , 0x0
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x50) 
.insn s 43,0,address,crypto_write_fifo(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

LI count , 100
LI zero_data , 0
delay_loop:
    ADDI count , count , -1;
    BNE count , zero_data , delay_loop

LI address , 0x819d
LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0xf,0x110) 
.insn s 43,0,address,crypto_read(cppcmd_data_ref)	 
ADDI address , address , 0x0
WAIT_ON_SIGNAL (SIG1_pos,1)

Check_result:
    LI expect , 0x004f21e500000000
    LD wdata , 0x110(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x48b6dfd264b32515
    LD wdata , 0x118(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x3b6d53751d581842
    LD wdata , 0x120(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0xa4f68d14998271da
    LD wdata , 0x128(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0xfd07aa508bff0029
    LD wdata , 0x130(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0xc527c9612cd82efd
    LD wdata , 0x138(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x067c90ab8436f4ae
    LD wdata , 0x140(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x4ebff9ccb8d2658f
    LD wdata , 0x148(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x9f233157ca538029
    LD wdata , 0x150(xfer)
    BNE expect , wdata ,  test_failed

    LI expect , 0x50b1516aeb5bda4b
    LD wdata , 0x158(xfer)
    BNE expect , wdata ,  test_failed
#LI offset1 , 0x3e00
#ADD txfer , xfer, offset1
### data
#LI wdata , 0x89abcdef01234567
#SD wdata , 0x1(txfer)
#LI wdata , 0x76543210fedcba98
#SD wdata , 0x9(txfer)
#LI wdata , 0x89abcdef01234567
#SD wdata , 0x11(txfer)
#LI wdata , 0x76543210fedcba98
#SD wdata , 0x19(txfer)
#
### crypto instruction
#LI wdata , 0x01b8000000000000
#SD wdata , 0x0(xfer)
#LI wdata , 0x01b407c94c06efc0
#SD wdata , 0x8(xfer)
#LI wdata , 0x04b669f5bb85c2a2
#SD wdata , 0x10(xfer)
#LI wdata , 0x05b4b59497652500
#SD wdata , 0x18(xfer)
#LI wdata , 0x05ba1f34f00f7e00
#SD wdata , 0x20(xfer)
#LI wdata , 0x05b839f67e907e80
#SD wdata , 0x28(xfer)
#LI wdata , 0x06be4341d00f7e10
#SD wdata , 0x30(xfer)
#LI wdata , 0x04b2df2da961589f
#SD wdata , 0x38(xfer)
#
#LI wdata , 0x1
#SD wdata , 0x100(xfer)
#LI one , CLS_CR_BLK_CSR_XPB_DEVICE_ID
#SLLI address , one , 16
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x0,0x100) 
#.insn s 43,0,address,ct_xpb_write(cppcmd_data_ref)	 
#ADDI address , address , 0x0
#WAIT_ON_SIGNAL (SIG1_pos,1)
#
##LI base , 0x0
##ADDI address , base , 0x0
#LI address , 0x0
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x0) 
#.insn s 43,0,address,crypto_write_fifo(cppcmd_data_ref)	 
#ADDI address , address , 0x0
#WAIT_ON_SIGNAL (SIG1_pos,1)
#
#LI wdata , 0x01b8fe889babe491
#SD wdata , 0x40(xfer)
#LI wdata , 0x01bc0d88ca03efd0
#SD wdata , 0x48(xfer)
#LI wdata , 0x0ab8207ce5387782
#SD wdata , 0x50(xfer)
#LI wdata , 0x0
#SD wdata , 0x58(xfer)
#
#
#LI address , 0xb40a610b8200
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x2,0x40) 
#.insn s 43,0,address,crypto_write(cppcmd_data_ref)	 
#ADDI address , address , 0x0
#WAIT_ON_SIGNAL (SIG1_pos,1)
#
#LI count , 100
#LI zero_data , 0
#delay_loop:
#    ADDI count , count , -1;
#    BNE count , zero_data , delay_loop
#
#LI address , 0x369430ca7e80
#LI cppcmd_data_ref, CALC_RS1(0x0,0x0,0x0,SIG1,0x0,0x0,0x7,0x200) 
#.insn s 43,0,address,crypto_read(cppcmd_data_ref)	 
#ADDI address , address , 0x0
#WAIT_ON_SIGNAL (SIG1_pos,1)


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
