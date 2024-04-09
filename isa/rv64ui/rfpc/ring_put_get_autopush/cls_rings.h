;;; a Copyright
/*
 * Copyright (C) 2009-2013,  Netronome Systems, Inc.  All rights reserved.
 *                
 */

;;; a Macros
    ;; m cls_init_ring( ring_number, base_address, log_size  )
#macro cls_init_ring( ring_number, base_address, log_size  )
    .begin
    .sig s0, s1
    .reg $cls_ring_base, $cls_ring_ptrs, cls_ring_address
    $cls_ring_base = ((log_size<<16) | ((base_address>>7)<<0) )
    $cls_ring_ptrs = 0
    cls_ring_address = (0x10000 + (ring_number<<3))
    cls[ write, $cls_ring_base, cls_ring_address,   0, 1], sig_done[s0] ; s0 is not required here, but the assembler throws a dumb warning
    cls_ring_address = cls_ring_address + 128
    cls[ write, $cls_ring_ptrs, cls_ring_address, 0, 1], ctx_swap[s1]
    .io_completed $cls_ring_base, s0
    .end
#endm
