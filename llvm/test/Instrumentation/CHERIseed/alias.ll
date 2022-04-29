; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------
; Test function aliases.

define void @func_alias_1_aliasee() addrspace(200) {
  ret void
}

define void @func_alias_2_aliasee(i8 addrspace(200)* %0) addrspace(200) {
  ret void
}

; CHECK-LABEL: @func_alias_1 = weak hidden alias void (),
; CHECK-SAME:    void ()* @func_alias_1_aliasee
@func_alias_1 = weak hidden alias void (),
  void () addrspace(200)* @func_alias_1_aliasee

; CHECK-LABEL: @func_alias_2 = weak hidden alias void (%__cheriseed_cap_t*),
; CHECK-SAME:    void (%__cheriseed_cap_t*)* @func_alias_2_aliasee
@func_alias_2 = weak hidden alias void (i32 addrspace(200)* %0),
  bitcast (void (i8 addrspace(200)* %0) addrspace(200)* @func_alias_2_aliasee to
  void (i32 addrspace(200)* %0) addrspace(200)*)

; ------------------------------------------------------------------------------
