#-----------------------
# TEST_NAME: ctm_read_perf.S
#     Reads and writes unique values to entire CTM memory 
# Plusargs to pass 
#   --runarg=+MAILBOX2=0 (Length)       Default = 0 ( 1 x 64 bits)
#   --runarg=+MAILBOX3=6 (Num_contexts) Default = 8 (not implemented yet)
# 
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

#define zero            x0
#define cppcmd_rs1      x3
#define base_address    t0
#define loop_count      x16
#define address         x17
#define core_num        x18
#define group_num       x19
#define xferw           x26
#define xferr           x27

.equ MEM_SIZE_DIV128,   0x400
.equ MEM_SIZE_DIV16,    0x2000
.equ CPP_MEM_ADDR,      0xf0000000
.equ TEST_DATA0,        0x7766554433221100
.equ TEST_DATA1,        0x0011223344556677
.equ TEST_DATA2,        0x3322110077665544
.equ TEST_DATA3,        0x4455667700112233
.equ TEST_DATA4,        0x1100332255447766
.equ TEST_DATA5,        0x6677445522330011
.equ TEST_DATA6,        0x0011223344556677
.equ TEST_DATA7,        0x7766554433221100
.equ TEST_DATA8,        0xfedcba9876543210
.equ TEST_DATA9,        0x0123456789abcdef
.equ TEST_DATAa,        0x76543210fedcba98
.equ TEST_DATAb,        0x89abcdef01234567
.equ TEST_DATAc,        0x32107654ba98fedc
.equ TEST_DATAd,        0xcdef89ab45670123
.equ TEST_DATAe,        0xefcdab8967452301
.equ TEST_DATAf,        0x1023547698badcfe

RVTEST_RV64U
RVTEST_CODE_BEGIN

# a0    24:16       11:8        7:0
#       island_id   group_num   core_num
LI group_num, 0xf00
AND group_num, group_num, a0
SRLI group_num, group_num, 8 #group_num
ANDI core_num, a0, 0x7 #core_num

SLLI base_address, core_num, 4
ADD base_address, base_address, group_num
SLLI base_address, base_address, 10

LI loop_count, MEM_SIZE_DIV128
ADD loop_count, loop_count, base_address

ADD address, base_address, zero

LI xferw, CPP_MEM_ADDR
LI xferr, CPP_MEM_ADDR
ADDI xferr, xferr, 0x80

LI t1, TEST_DATA0
SD t1, 0x00(xferw)
LI t1, TEST_DATA1
SD t1, 0x08(xferw)
LI t1, TEST_DATA2
SD t1, 0x10(xferw)
LI t1, TEST_DATA3
SD t1, 0x18(xferw)
LI t1, TEST_DATA4
SD t1, 0x20(xferw)
LI t1, TEST_DATA5
SD t1, 0x28(xferw)
LI t1, TEST_DATA6
SD t1, 0x30(xferw)
LI t1, TEST_DATA7
SD t1, 0x38(xferw)
LI t1, TEST_DATA8
SD t1, 0x40(xferw)
LI t1, TEST_DATA9
SD t1, 0x48(xferw)
LI t1, TEST_DATAa
SD t1, 0x50(xferw)
LI t1, TEST_DATAb
SD t1, 0x58(xferw)
LI t1, TEST_DATAc
SD t1, 0x60(xferw)
LI t1, TEST_DATAd
SD t1, 0x68(xferw)
LI t1, TEST_DATAe
SD t1, 0x70(xferw)
LI t1, TEST_DATAf
SD t1, 0x78(xferw)

read_write_loop:
    LI cppcmd_rs1, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0xf,0x0)
    .insn s 43,0,address,memory_unit_write(cppcmd_rs1)
    WAIT_ON_SIGNAL (SIG5_pos,1)

    LI cppcmd_rs1, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0xf,0x80)
    .insn s 43,0,address,memory_unit_read(cppcmd_rs1)
    WAIT_ON_SIGNAL (SIG5_pos,1)
    
    LI t1, TEST_DATA0
    LD t2, 0x00(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA1
    LD t2, 0x08(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA2
    LD t2, 0x10(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA3
    LD t2, 0x18(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA4
    LD t2, 0x20(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA5
    LD t2, 0x28(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA6
    LD t2, 0x30(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA7
    LD t2, 0x38(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA8
    LD t2, 0x40(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATA9
    LD t2, 0x48(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATAa
    LD t2, 0x50(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATAb
    LD t2, 0x58(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATAc
    LD t2, 0x60(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATAd
    LD t2, 0x68(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATAe
    LD t2, 0x70(xferr)
    BNE t1, t2, test_failed
    LI t1, TEST_DATAf
    LD t2, 0x78(xferr)
    BNE t1, t2, test_failed

    ADDI address, address, 0x80
    BNE address, loop_count, read_write_loop



test_passed:
pass:		
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

