; RUN: opt -passes=cheriseed -S < %s | FileCheck %s
; RUN: opt -cheriseed -S < %s | FileCheck %s

; ------------------------------------------------------------------------------
; Make sure the final IR does not have 'addrspace(200)' in it.

; CHECK-NOT: addrspace(200)

; ------------------------------------------------------------------------------

; There is no 'sanitize_cheriseed' attribute.
@NoSanitizeGlobal = external global [0 x i64], align 8, !cheriseed !0
@NoSanitizeGlobalAS200 = extern_weak addrspace(200) constant [0 x i64], align 8, !cheriseed !0

; CHECK-LABEL: @use_linker_symbol
define void @use_linker_symbol() {
; CHECK-NEXT:  %"CHERIseed Alloca Insertion Point"
; CHECK-NEXT:  %1 = alloca %__cheriseed_cap_t, align 16
; CHECK-NEXT:  %2 = bitcast [0 x i64]* @NoSanitizeGlobal to i8*
  %1 = bitcast [0 x i64]* @NoSanitizeGlobal to i8*
; CHECK-NEXT:  %3 = call %__cheriseed_cap_t* @__cheriseed_ddc_get(%__cheriseed_cap_t* %1)
; CHECK-NEXT:  %4 = call %__cheriseed_cap_t* @__cheriseed_address_set(%__cheriseed_cap_t* %3,
; CHECK-SAME:     %__cheriseed_cap_t* %3, i64 ptrtoint ([0 x i64]* @NoSanitizeGlobalAS200 to i64))
  %2 = bitcast [0 x i64] addrspace(200)* @NoSanitizeGlobalAS200 to i8 addrspace(200)*
; CHECK-NEXT:  ret void
  ret void
}

!0 = !{!"no_sanitize"}
