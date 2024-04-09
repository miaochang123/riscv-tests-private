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

.equ MEM_SIZE_DIV128,   0x400
.equ MEM_SIZE_DIV16,    0x2000
.equ CPP_MEM_ADDR,      0xf0000000

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

read_loop:
    LI cppcmd_rs1, CALC_RS1(0x0,0x0,0x0,SIG5,0x0,0x0,0xf,0x0)
    .insn s 43,0,address,memory_unit_read(cppcmd_rs1)
    WAIT_ON_SIGNAL (SIG5_pos,1)
    ADDI address, address, 0x40
    BNE address, loop_count, read_loop


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

