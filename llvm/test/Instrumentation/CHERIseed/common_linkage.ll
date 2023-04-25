; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Regression for 'common' linkage: shadow capabilitites should not have that.
; Use 'weak' linkage instead. When a definition other than 'common' is present,
; it will be chosen by the linker instead. See -fcommon compiler option.

; CHECK: @__cheriseed_shadowed_global_global_common_linkage = common
; CHECK: @global_common_linkage = weak global
@global_common_linkage = common addrspace(200) global i8 0, align 1

; ------------------------------------------------------------------------------
