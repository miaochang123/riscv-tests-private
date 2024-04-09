;-----------------------
; TEST_NAME: me_local_scratch_rw.uc
;-----------------------
BR[START_TEST#]
#include "../common/common_modules.uc"
#include "../common/local_scratch_rw_module.uc"

;--------------------------------------
; Set Up the BASE scratch address
; Each ME will use a different region
;--------------------------------------
START_TEST#:
; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[data,0]

alu_shf[cluster,0x7, AND,data,>>24]
alu_shf[me_num,0xF, AND,data,>>3]

BR[LOCAL_SCRATCH_TEST#]
nop
nop
nop
