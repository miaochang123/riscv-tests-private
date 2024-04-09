#define START_LEN   1
#define END_LEN     17

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

/* We will let assembler assign for now */

.areg  data          0
.areg  base          1
.areg inc_amount     2
.areg tmp            3
.areg count          4
.areg return_address 5
.areg jump_offset    6
.areg data2          7
.areg endlen         8
.areg me_and_cluster 9
.areg sig_gpr        10
.areg dma_data       11
.areg dma_address    12

.breg len         0
.breg cluster     1
.breg me_num      2
.breg offset      3
.breg expect_data 4
.breg data_ref    5
.breg trans_count 6
.breg ctr         7
.breg address     8
.breg tmp_b         9
.breg masked_data  10

#pragma addressing("32bit")
; This macro is used for CSR writes
; You must supply the CSP address and data
#macro write_cap[addr, data]
.begin

  immed[tmp, (data & 0xFFFF)]
  immed_w1[tmp, ((data >> 16) & 0xFFFF)]
  alu[$xfer0,--,B,tmp]
  immed[$xfer1,0]

  tmp = addr;

  cmd[cap, write_calc, $xfer0, tmp, 0, 1], ctx_swap[sig6]

.end
#endm

#macro add_delay[]
immed[ctr,99]
sleep_label#:
  alu[ctr,ctr,-,1]
  BNE[sleep_label#]
#endm

check_read_data_64bit#:
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]

	rtn[return_address]

check_read_data_32bit#:
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
  	alu[--,*$index--, - , expect_data]
  	BNE[test_failed#], defer[1]
	alu[expect_data,expect_data,-,1]
	rtn[return_address]

test_passed#:
	nop
	nop
	ctx_arb[kill]
test_failed#:
        nop
        nop
	ctx_arb[kill]
