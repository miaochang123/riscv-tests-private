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
#define expect0   x1
#define cppcmd_data_ref x3
#define count x4
#define hart_id    x10 #hart csr register

#define end_count x16

#define address   x17
#define cl_num        x18
#define group_num        x19
#define len   x20
#define mem_base   x21
#define temp_data   x2
#define temp_data_1   x5
#define temp_data_2   x6
#define xfer x26
	
.equ MEM_SIZE_DIV16,   0x2000
.equ MEM_SIZE_DIV128,   0x400
.equ CPP_MEM_ADDR,   0xf0000000

	
RVTEST_RV64U
RVTEST_CODE_BEGIN
	

LI x6, 0x8877665544332211

LI x20, 0x7788556633441122  # swap bytes within each half-word
LI x21, 0x6655887722114433  # swap lower and upper half-words within each lower and upper word
LI x22, 0x5566778811223344  # swap lower and upper half-words within each lower and upper word and swap bytes within each half-word
LI x23, 0x4433221188776655  # swap lower and upper words
LI x24, 0x3344112277885566  # swap lower and upper words and bytes within each half-word
LI x25, 0x2211443366558877  # swap lower and upper words and lower and upper half-words within each word
LI x26, 0x1122334455667788  # reverse bytes in 64-bit double-word

.insn i 19, 1,  x7,   x6, (8  | ((-24)<<6) )   # SWAP8   swap bytes			    
.insn i 19, 1,  x8,   x6, (16 | ((-24)<<6) )   # SWAP16  swap half-words		    
.insn i 19, 1,  x9,   x6, (24 | ((-24)<<6) )   # SWAP24  swap half-words and bytes	    
.insn i 19, 1,  x10,  x6, (32 | ((-24)<<6) )   # SWAP32  swap words			    
.insn i 19, 1,  x11,  x6, (40 | ((-24)<<6) )   # SWAP40  swap words and bytes		    
.insn i 19, 1,  x12,  x6, (48 | ((-24)<<6) )   # REV16   swap words and half-words	    
.insn i 19, 1,  x13,  x6, (56 | ((-24)<<6) )   # REV8    swap words and half-words and bytes

BNE x7, x20, fail
BNE x8, x21, fail
BNE x9, x22, fail
BNE x10, x23, fail
BNE x11, x24, fail
BNE x12, x25, fail
BNE x13, x26, fail

LI x6, 0x8877665544332211

LI x20, 0x11ee66aa22cc4488  # reverse bits in each byte
LI x21, 0xee11aa66cc228844  # swap bytes within each half-word and reverse bits in each byte
LI x22, 0x66aa11ee448822cc  # swap lower and upper half-words within each lower and upper word and reverse bits in each byte
LI x23, 0xaa66ee118844cc22  # swap lower and upper half-words within each lower and upper word and swap bytes within each half-word and reverse bits in each byte
LI x24, 0x22cc448811ee66aa  # swap lower and upper words and reverse bits in each byte
LI x25, 0xcc228844ee11aa66  # swap lower and upper words and bytes within each half-word and reverse bits in each byte
LI x26, 0x448822cc66aa11ee  # swap lower and upper words and lower and upper half-words within each word and reverse bits in each byte
LI x27, 0x8844cc22aa66ee11  # reverse bytes in 64-bit double-word and reverse bits in each byte

.insn i 19, 1,  x7,   x6, (1  | ((-24)<<6) )   # REV1   reverse bits in bytes
.insn i 19, 1,  x8,   x6, (9  | ((-24)<<6) )   # SWAP9  swap bytes, and reverse bits in bytes
.insn i 19, 1,  x9,   x6, (17 | ((-24)<<6) )   # SWAP17 swap half-words, and reverse bits in bytes
.insn i 19, 1,  x10,  x6, (25 | ((-24)<<6) )   # SWAP25 swap half-words and bytes, and reverse bits in bytes
.insn i 19, 1,  x11,  x6, (33 | ((-24)<<6) )   # SWAP33 swap words, and reverse bits in bytes
.insn i 19, 1,  x12,  x6, (41 | ((-24)<<6) )   # SWAP41 swap words and bytes, and reverse bits in bytes
.insn i 19, 1,  x13,  x6, (49 | ((-24)<<6) )   # REV17  swap words and half-words, and reverse bits in bytes
.insn i 19, 1,  x14,  x6, (57 | ((-24)<<6) )   # REV    swap words and half-words and bytes, and reverse bits in bytes

BNE x7, x20, fail
BNE x8, x21, fail
BNE x9, x22, fail
BNE x10, x23, fail
BNE x11, x24, fail
BNE x12, x25, fail
BNE x13, x26, fail
BNE x14, x27, fail
	
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
