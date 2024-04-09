;-----------------------
; TEST_NAME: ls_bad_data_master.uc
;     
;  Generates illegal data_master for pushes and pulls
;  Ensure that things do not stall	
;-----------------------
.sig  sig1 sig2 sig3 sig4 sig5 sig6 sig7 sig8 sig9 sig10 sig11 sig12 sig13 sig14 sig15
.xfer_order $xfer0 $xfer1 $xfer2 $xfer3 $xfer4 $xfer5 $xfer6 $xfer7 $xfer8 $xfer9 $xfer10 $xfer11 $xfer12 $xfer13 $xfer14 $xfer15

.addr sig1 1
.addr sig2 2
.addr sig3 3
.addr sig4 4
.addr sig5 5
.addr sig6 6
.addr sig7 7
.addr sig8 8
.addr sig9 9
.addr sig10 10
.addr sig11 11
.addr sig12 12
.addr sig13 13
.addr sig14 14
.addr sig15 15

.areg expect0   0
.areg expect1   1
.areg expect2   2
.areg expect3   3
.areg expect4   4
.areg expect5   5
.areg expect6   6
.areg expect7   7

.areg end_count 8

.breg address   0
.breg  island_num        1
.breg  me_num        2
.breg len   3
.breg csr_data   4
.breg ctr        5

#define SCRATCH_SIZE_DIV8   0x2000

#macro add_delay[delay_count]

immed[ctr,delay_count]
sleep_label#:
  nop
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]

#endm

immed[len,15]

; The ME_NUM is in bits [7:3]
local_csr_rd[ACTIVE_CTX_STS]
immed[island_num,0]
alu_shf[me_num,0xF, AND,island_num,>>3]
alu_shf[island_num,0x3F, AND,island_num,>>24]

alu_shf[csr_data,--,B,island_num,<<24] // Island num in [29:24]
alu_shf[csr_data,csr_data,or,1,<<20] // Illegal Master # = 1
local_csr_wr[cmd_indirect_ref_0, csr_data]

// MEs are numbered 4-15
alu[me_num,me_num,-,4]

alu_shf[address,--,B,me_num,<<12]
immed[end_count, 0x40]
alu_shf[end_count,address,+,end_count]

// Good write loop
write_loop#:
	alu[$xfer0,address,+,0]
	alu[$xfer1,address,+,1]
	alu[$xfer2,address,+,2]
	alu[$xfer3,address,+,3]

	cls[write,$xfer0,address,0,4],ctx_swap[sig12], defer[1]
	alu[address,address,+,0x10]

	alu[--,address,-,end_count]
	BNE[write_loop#]

//-------------------------------
// Lets do writes with a BAD data_master
immed[$xfer0,0xBAD]
immed[$xfer1,0xBAD]
immed[$xfer2,0xBAD]
immed[$xfer3,0xBAD]

alu_shf[address,--,B,me_num,<<12]
// BAD write loop
bad_dm_write_loop#:
        alu_shf[--,--,B,1,<<1]   // Override Data_master
	cls[write,$xfer0,address,0,4],indirect_Ref   ; This does the WRITE with BAD data_master
	alu[address,address,+,0x10]

	alu[--,address,-,end_count]
	BNE[bad_dm_write_loop#]

add_delay[50]
//-------------------------------
// BAD read loop
alu_shf[address,--,B,me_num,<<12]
bad_read_loop#:

        alu_shf[--,--,B,1,<<1]   // Override Data_master
	cls[read_le,$xfer0,address,0,4],indirect_ref  ; This does READ with BAD data_master
	alu[address,address,+,0x10]

	alu[--,address,-,end_count]

	BNE[bad_read_loop#]

// Good read loop
alu_shf[address,--,B,me_num,<<12]
read_loop#:

	alu[expect0,address,+,0]
	alu[expect1,address,+,1]
	alu[expect2,address,+,2]
	alu[expect3,address,+,3]

	cls[read_le,$xfer0,address,0,4],ctx_swap[sig12],defer[1]
	alu[address,address,+,0x10]

	alu[--,$xfer0,-,expect0]
	BNE[test_failed#]
	alu[--,$xfer1,-,expect1]
	BNE[test_failed#]
	alu[--,$xfer2,-,expect2]
	BNE[test_failed#]
	alu[--,$xfer3,-,expect3]
	BNE[test_failed#]

	alu[--,address,-,end_count]

	BNE[read_loop#]

test_passed#:
        ctx_arb[kill]
        nop
        nop
test_failed#:
        nop
        nop
        ctx_arb[kill]
