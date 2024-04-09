;;; a Copyright
/*
 * Copyright (C) 2009-2013,  Netronome Systems, Inc.  All rights reserved.
 *                
 */

;;; a CLS Event manager configuring macros
;;  m cls_event_filter_config( filter, mask, match, filter_type )
; Configure an event filter to a provided mask/match and filter type
#macro cls_event_filter_config( filter, mask, match, filter_type )

.begin
.reg $xfer[3]
.xfer_order $xfer
.reg addr
.sig s1

addr = 0x20000
addr = addr | (filter << 6)
$xfer[0] = mask | (filter_type << 24 )
$xfer[2] = match
cls[write, $xfer[0], addr, 0x10, 3], ctx_swap[s1]
.end
#endm ; event_filter_config

;;; a Autopush signal monitoring macros
;;  m cls_autopush_monitor_config( filter, me_num, xfer_reg, signal )
; Configure an autopush monitor for a filter with ME number, transfer register and signal
#macro cls_autopush_monitor_config( filter, me_num, ctxt_num, xfer_reg, signal )
.begin
.reg $xfer
.reg addr
.reg temp
.sig s1
addr = 0x30200
addr = addr | (filter << 3)
      ;$xfer = ((me_num+4) << 24 ) | (signal<<16) | (xfer_reg<<2) | (ctxt_num<<7) | (ctxt_num<<19)
temp = me_num + 4
temp = temp << 24
temp = temp | (signal << 16 )
temp = temp | (xfer_reg << 2 )
temp = temp | (ctxt_num << 7 )
temp = temp | (ctxt_num << 19 )
$xfer = temp
cls[write, $xfer, addr, 0, 1], ctx_swap[s1]
.end
#endm ; cls_autopush_monitor_config

;;  m cls_autopush_monitor_engage( filter )
; This macro should be called to start monitoring an event filter, after autopush_monitor_config has been
;  called once.
; The macro uses 'one shot acknowledge'
#macro cls_autopush_monitor_engage( filter )
.begin
.reg $xfer
.reg addr   
.sig s1
addr = 0x30000
addr = addr | (filter << 3)
$xfer = filter | (3<<8)
cls[write, $xfer, addr, 0, 1], ctx_swap[s1]
.end
#endm ; cls_autopush_monitor_engage

;;  m cls_autopush_user_event( event )
; This macro pushes an event into UserEvent in the CLS event manager
#macro cls_autopush_user_event( event )
.begin
.reg $xfer
.reg addr
.sig s1
addr = 0x30400
$xfer = event
cls[write, $xfer, addr, 0, 1], ctx_swap[s1]
.end
#endm ; cls_autopush_user_event
